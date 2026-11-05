# 藤沢市全域: PLATEAU の全建物（LOD1 外形+実測高さ、LOD2 があれば屋根・壁）をチャンク(320 m)単位に、
# 航空写真(シームレス空中写真 z17 ≈1 m/px)を 4×4 チャンク(1280 m)ブロックの JPEG に、
# OSM の街の細部（信号・横断歩道・バス停・店舗・自販機・街路樹…）を点のリストにまとめる。
# usage: python3 bake_city.py RAW_DIR OUT_DIR
import sys,os,glob,json,struct,gzip,io,math,pickle
import numpy as np
from PIL import Image
sys.path.insert(0,os.path.join(os.path.dirname(__file__),'..','places'))
RAW,OUT=sys.argv[1],sys.argv[2];os.makedirs(os.path.join(OUT,'city'),exist_ok=True)
src=open(os.path.join(os.path.dirname(__file__),'..','places','bake_places.py')).read().replace('main()\n','')
sys.argv=[sys.argv[0],RAW,OUT];exec(src)          # parse_mesh, tri3, photo helpers, G, PLACES
X0,Z0,CH,CNX,CNZ=-11720,-23540,320,83,98
pcs=[(G(v[1],v[2]),v[3]) for v in PLACES.values()]
def in_place(x,z):return any((x-c[0])**2+(z-c[1])**2<r*r for c,r in pcs)
cache=os.path.join(RAW,'city_bldg.pkl')
if os.path.exists(cache):B=pickle.load(open(cache,'rb'))
else:
    B=[]
    for fn in sorted(glob.glob(os.path.join(RAW,'gml','f*.gml'))):
        b=parse_mesh(fn,lambda x,z:not in_place(x,z));B+=b;print(os.path.basename(fn),len(b),len(B),flush=True)
    pickle.dump(B,open(cache,'wb'),protocol=4)
seen=set();chunks={}
for b in B:
    if b['id'] in seen:continue
    seen.add(b['id']);c=b['foot'].mean(0);ci=int((c[0]-X0)//CH);cj=int((c[1]-Z0)//CH)
    if 0<=ci<CNX and 0<=cj<CNZ:chunks.setdefault(cj*CNX+ci,[]).append(b)
print('buildings',len(seen),'chunks',len(chunks),flush=True)
blob=io.BytesIO();idx=[]
for key in sorted(chunks):
    ci,cj=key%CNX,key//CNX;cx,cz=X0+(ci+0.5)*CH,Z0+(cj+0.5)*CH;o=blob.tell()
    for b in chunks[key]:
        F=np.round((b['foot']-[cx,cz])*10).astype(np.int16)
        blob.write(struct.pack('<HBHHh',len(F),b['st'],b['use'],int(max(0,min(65535,(b['z1']-b['z0'])*10))),int(round(b['z0']*10))));blob.write(F.tobytes())
        for lst in (b['roof'],b['wall']):
            A=np.array(lst).reshape(-1,3) if lst else np.zeros((0,3))
            if len(A):A=np.round((A-[cx,b['z0'],cz])*10).astype(np.int16)
            blob.write(struct.pack('<I',len(A)//3));blob.write(A.astype(np.int16).tobytes())
    idx.append([key,o,blob.tell()-o,len(chunks[key])])
# ---------- photo blocks ----------
tiles={}
for fn in glob.glob(os.path.join(RAW,'photo17','*.jpg')):
    x,y=map(int,os.path.basename(fn)[:-4].split('_'));tiles[(x,y)]=fn
def tilef17(lat,lon):
    n=2**17;x=(lon+180)/360*n;r=np.radians(lat);y=(1-np.log(np.tan(r)+1/np.cos(r))/np.pi)/2*n;return x,y
blocks=[];BS=4*CH;NP=1280
for bj in range(0,CNZ,4):
    for bi in range(0,CNX,4):
        x0,z0=X0+bi*CH,Z0+bj*CH;xs=x0+(np.arange(NP)+0.5)*BS/NP;zs=z0+(np.arange(NP)+0.5)*BS/NP
        X,Z=np.meshgrid(xs,zs);LON=X/MX+LON0;LAT=-Z/MZ+LAT0;tx,ty=tilef17(LAT,LON)
        need={(int(a),int(b)) for a,b in zip(tx[::64,::64].ravel(),ty[::64,::64].ravel())}
        have=[t for t in need if t in tiles]
        if len(have)<0.3*len(need):continue
        tx0,ty0=int(tx.min()),int(ty.min());tx1,ty1=int(tx.max()),int(ty.max())
        mos=np.zeros(((ty1-ty0+1)*256,(tx1-tx0+1)*256,3),np.uint8);cov=np.zeros(((ty1-ty0+1),(tx1-tx0+1)),bool)
        for x in range(tx0,tx1+1):
            for y in range(ty0,ty1+1):
                fn=tiles.get((x,y))
                if fn:
                    try:mos[(y-ty0)*256:(y-ty0+1)*256,(x-tx0)*256:(x-tx0+1)*256]=np.asarray(Image.open(fn).convert('RGB'));cov[y-ty0,x-tx0]=True
                    except Exception:pass
        u=np.clip(((tx-tx0)*256).astype(int),0,mos.shape[1]-1);v=np.clip(((ty-ty0)*256).astype(int),0,mos.shape[0]-1)
        img=mos[v,u].astype(np.float32);img=np.clip((img-128)*1.08+132,0,255).astype(np.uint8)
        name='city/b_%d_%d.jpg'%(bi//4,bj//4);Image.fromarray(img).save(os.path.join(OUT,name),quality=72,optimize=True,progressive=True)
        blocks.append([bi//4,bj//4,name])
print('photo blocks',len(blocks),flush=True)
# ---------- OSM street detail ----------
pois=[]
try:
    sys.path.insert(0,RAW);os.chdir(RAW)
    import xml.etree.ElementTree as ET
    seen_n=set()
    for fn in glob.glob('osm/*.xml'):
        try:r=ET.parse(fn).getroot()
        except Exception:continue
        for n in r.findall('node'):
            i=n.get('id')
            if i in seen_n:continue
            tg={t.get('k'):t.get('v') for t in n.findall('tag')}
            if not tg:continue
            seen_n.add(i);x,z=G(float(n.get('lat')),float(n.get('lon')))
            if not(X0<x<X0+CNX*CH and Z0<z<Z0+CNZ*CH):continue
            nm=tg.get('name','');br=tg.get('brand',tg.get('brand:ja',''))
            t=None
            if tg.get('highway')=='traffic_signals':t='sig'
            elif tg.get('highway')=='crossing' or tg.get('footway')=='crossing':t='cross'
            elif tg.get('highway')=='bus_stop':t='bus'
            elif tg.get('amenity')=='vending_machine':t='vend'
            elif tg.get('natural')=='tree':t='tree'
            elif tg.get('amenity')=='post_box':t='post'
            elif tg.get('amenity')=='telephone':t='tel'
            elif tg.get('amenity')=='bicycle_parking':t='bike'
            elif ('shop' in tg or tg.get('amenity') in ('restaurant','fast_food','cafe','bank','pharmacy','pub','bar','karaoke_box','post_office','clinic','dentist','fuel','atm','cinema','library','police')) and (nm or br):t='shop'
            if t:pois.append([t,round(x,1),round(z,1),nm[:24],br[:24],tg.get('shop') or tg.get('amenity') or ''])
except Exception as e:print('poi err',e)
print('pois',len(pois),flush=True)
meta={'chunks':idx,'blocks':blocks,'pois':pois}
mj=json.dumps(meta,ensure_ascii=False,separators=(',',':')).encode();head=struct.pack('<4sI',b'FCT1',len(mj))+mj
while len(head)%4:head+=b' '
open(os.path.join(OUT,'fujisawa-city.wasm'),'wb').write(gzip.compress(head+blob.getvalue(),9))
print('city file MB',os.path.getsize(os.path.join(OUT,'fujisawa-city.wasm'))/1e6)
