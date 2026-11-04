# 15カ所の「詳細エリア」データを作る: 航空写真(国土地理院 シームレス空中写真 z18)をゲーム座標に貼り直したJPEGと、
# PLATEAU の建物(LOD1 の外形と実測高さ、LOD2 があれば屋根・壁の3D形状)をまとめたバイナリ。
# usage: python3 bake_places.py RAW_DIR OUT_DIR
import sys,os,math,json,struct,gzip,glob,io
import numpy as np
from PIL import Image
from lxml import etree
import mapbox_earcut as earcut
from places import PLACES,meshes
RAW,OUT=sys.argv[1],sys.argv[2]
LAT0,LON0,MX,MZ=35.3389,139.4874,90807,110940
G=lambda lat,lon:((lon-LON0)*MX,-(lat-LAT0)*MZ)
os.makedirs(OUT,exist_ok=True)
def tilef(lat,lon,z=18):
    n=2**z;x=(lon+180)/360*n;r=np.radians(lat);y=(1-np.log(np.tan(r)+1/np.cos(r))/np.pi)/2*n;return x,y
# ---------- photo ----------
def bake_photo(key,lat,lon,R):
    cx,cz=G(lat,lon);px=max(0.5,2*R/2048);N=int(math.ceil(2*R/px))
    xs=cx-R+(np.arange(N)+0.5)*px;zs=cz-R+(np.arange(N)+0.5)*px
    X,Z=np.meshgrid(xs,zs);LON=X/MX+LON0;LAT=-Z/MZ+LAT0
    tx,ty=tilef(LAT,LON);tx0,ty0=int(tx.min()),int(ty.min());tx1,ty1=int(tx.max()),int(ty.max())
    mos=np.zeros(((ty1-ty0+1)*256,(tx1-tx0+1)*256,3),np.float32)
    for x in range(tx0,tx1+1):
        for y in range(ty0,ty1+1):
            fn=os.path.join(RAW,'photo','%d_%d.jpg'%(x,y))
            if os.path.exists(fn):mos[(y-ty0)*256:(y-ty0+1)*256,(x-tx0)*256:(x-tx0+1)*256]=np.asarray(Image.open(fn).convert('RGB'),np.float32)
    u=(tx-tx0)*256-0.5;v=(ty-ty0)*256-0.5;u0=np.clip(np.floor(u).astype(int),0,mos.shape[1]-2);v0=np.clip(np.floor(v).astype(int),0,mos.shape[0]-2);fu=(u-u0)[...,None];fv=(v-v0)[...,None]
    img=mos[v0,u0]*(1-fu)*(1-fv)+mos[v0,u0+1]*fu*(1-fv)+mos[v0+1,u0]*(1-fu)*fv+mos[v0+1,u0+1]*fu*fv
    # gentle grade: aerial photos are hazy; lift contrast a little so they sit with the rendered scene
    img=np.clip((img-128)*1.08+128+4,0,255).astype(np.uint8)
    Image.fromarray(img).save(os.path.join(OUT,key+'.jpg'),quality=80,optimize=True,progressive=True)
    return {'x0':cx-R,'z0':cz-R,'size':N*px,'px':px,'n':N}
# ---------- PLATEAU ----------
NS={'gml':'http://www.opengis.net/gml','bldg':'http://www.opengis.net/citygml/building/2.0'}
def poslist(t):
    a=np.array(t.split(),float).reshape(-1,3);return a
def tri3(rings):
    ext=rings[0];P=np.vstack(rings);# Newell normal
    n=np.zeros(3)
    for i in range(len(ext)):
        a=ext[i];b=ext[(i+1)%len(ext)];n+=[(a[1]-b[1])*(a[2]+b[2]),(a[2]-b[2])*(a[0]+b[0]),(a[0]-b[0])*(a[1]+b[1])]
    if np.linalg.norm(n)<1e-9:return [],n
    k=int(np.argmax(np.abs(n)));ax=[i for i in range(3) if i!=k]
    ends=np.cumsum([len(r) for r in rings]).astype(np.uint32)
    try:idx=earcut.triangulate_float64(P[:,ax],ends)
    except Exception:return [],n
    return [P[idx[i:i+3]] for i in range(0,len(idx),3)],n/np.linalg.norm(n)
def ring_local(pl):
    # posList lat lon h -> game x,y,z (metres)
    x=(pl[:,1]-LON0)*MX;z=-(pl[:,0]-LAT0)*MZ;return np.stack([x,pl[:,2],z],1)
def parse_mesh(fn,keep):
    out=[]
    for ev,el in etree.iterparse(fn,tag='{%s}Building'%NS['bldg']):
        b={'id':el.get('{%s}id'%NS['gml'])}
        def tx(path):
            r=el.find(path,NS);return r.text if r is not None else None
        h=tx('bldg:measuredHeight');b['h']=float(h) if h else -1
        s=tx('bldg:storeysAboveGround');b['st']=int(s) if s and int(s)<200 else 0
        u=tx('bldg:usage');b['use']=int(u) if u and u.isdigit() else 0
        # LOD1 footprint = lowest horizontal face of lod1Solid
        foot=None;zmin=None;zmax=None
        for pl in el.iterfind('bldg:lod1Solid//gml:posList',NS):
            a=poslist(pl.text)
            if zmin is None or a[:,2].min()<zmin:zmin=a[:,2].min()
            if zmax is None or a[:,2].max()>zmax:zmax=a[:,2].max()
            if np.ptp(a[:,2])<0.01 and (foot is None or a[0,2]<foot[0,2]):foot=a
        if foot is None:
            for pl in el.iterfind('bldg:lod0RoofEdge//gml:posList',NS):foot=poslist(pl.text);break
            for pl in el.iterfind('bldg:lod0FootPrint//gml:posList',NS):foot=poslist(pl.text);break
        if foot is None:el.clear();continue
        F=ring_local(foot)[:-1]
        c=F[:,[0,2]].mean(0)
        if not keep(c[0],c[1]):el.clear();continue
        b['foot']=F[:,[0,2]];b['z0']=zmin if zmin is not None else 0;b['z1']=zmax if zmax is not None else (b['z0']+max(b['h'],3))
        roof=[];wall=[]
        for kind,lst in (('RoofSurface',roof),('WallSurface',wall),('OuterCeilingSurface',roof),('OuterFloorSurface',roof)):
            for surf in el.iterfind('.//bldg:%s'%kind,NS):
                for poly in surf.iterfind('.//gml:Polygon',NS):
                    rings=[ring_local(poslist(p.text))[:-1] for p in poly.iterfind('.//gml:posList',NS)]
                    rings=[r for r in rings if len(r)>=3]
                    if not rings:continue
                    t,n=tri3(rings);lst+=t
        if roof:
            zs=[p[:,1].min() for p in roof+wall];b['z0']=min(b['z0'],min(zs)) if wall else b['z0']
        b['roof']=roof;b['wall']=wall
        out.append(b);el.clear()
        while el.getprevious() is not None: del el.getparent()[0]
    return out
def main():
    meta={'places':[]};blobs=[];seen=set()
    centers=[(k,)+G(v[1],v[2])+(v[3],) for k,v in PLACES.items()]
    for key,(name,lat,lon,rad,city) in PLACES.items():
        cx,cz=G(lat,lon);R=rad+60
        ph=bake_photo(key,lat,lon,R)
        keep=lambda x,z:(x-cx)**2+(z-cz)**2<rad*rad
        files=[os.path.join(RAW,'gml',city+m+'.gml') for m in sorted(meshes(lat,lon,rad))]
        blds=[]
        for fn in files:
            if os.path.exists(fn):blds+=parse_mesh(fn,keep)
        blds=[b for b in blds if b['id'] not in seen];seen|={b['id'] for b in blds}
        buf=io.BytesIO();nl2=0;ntri=0
        for b in blds:
            F=np.round((b['foot']-[cx,cz])*10).astype(np.int16)
            # drop duplicate consecutive points
            buf.write(struct.pack('<HBHHh',len(F),b['st'],b['use'],int(max(0,min(65535,(b['z1']-b['z0'])*10))),int(round(b['z0']*10))))
            buf.write(F.tobytes())
            for lst in (b['roof'],b['wall']):
                A=np.array(lst).reshape(-1,3) if lst else np.zeros((0,3))
                if len(A):A=np.round((A-[cx,b['z0'],cz])*10).astype(np.int16)
                buf.write(struct.pack('<I',len(A)//3));buf.write(A.astype(np.int16).tobytes());ntri+=len(A)//3
            if b['roof']:nl2+=1
        d=buf.getvalue();blobs.append(d)
        meta['places'].append({'key':key,'name':name,'cx':round(cx,1),'cz':round(cz,1),'r':rad,'photo':{'file':'places/'+key+'.jpg',**{k:round(v,2) for k,v in ph.items()}},'nb':len(blds),'bytes':len(d)})
        print(key,name,'bldgs',len(blds),'lod2',nl2,'tris',ntri,'bytes',len(d),'photo px',ph['n'],flush=True)
    mj=json.dumps(meta,ensure_ascii=False).encode()
    head=struct.pack('<4sI',b'FPL1',len(mj))+mj
    while len(head)%4:head+=b' '
    open(os.path.join(OUT,'fujisawa-places.wasm'),'wb').write(gzip.compress(head+b''.join(blobs),9))
    print('total',os.path.getsize(os.path.join(OUT,'fujisawa-places.wasm')))
main()
