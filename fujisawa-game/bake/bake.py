# Bake real map data (OSM + GSI DEM) into fujisawa-data.bin (gzip) for the game.
import pickle, math, json, struct, gzip, sys, os, glob, collections
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

SP=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAT0,LON0,MX,MZ=35.3389,139.4874,90807,110940
X0,X1,Z0,Z1=-8840,4780,-10100,5400
G=5.0; NX=int((X1-X0)/G)+1; NZ=int((Z1-Z0)/G)+1
CH=320; CNX=math.ceil((X1-X0)/CH); CNZ=math.ceil((Z1-Z0)/CH)
def L(lat,lon): return ((lon-LON0)*MX,-(lat-LAT0)*MZ)
def inv(x,z): return (LAT0-z/MZ, LON0+x/MX)

print('grid',NX,NZ,flush=True)
D=pickle.load(open(os.path.join(SP,'bake','osm.pkl'),'rb'))
nodes=D['nodes'];ways=D['ways'];rels=D['rels'];pois=D['pois']
print('loaded',len(nodes),len(ways),flush=True)

# ---------------- DEM ----------------
def mosaic(kind,z):
    fs=glob.glob(os.path.join(SP,'dem',kind+'_*.png'))
    if not fs: return None
    xy=[tuple(map(int,os.path.basename(f)[len(kind)+1:-4].split('_'))) for f in fs]
    xs=[a for a,b in xy];ys=[b for a,b in xy];tx0,ty0=min(xs),min(ys)
    W=(max(xs)-tx0+1)*256;H=(max(ys)-ty0+1)*256
    arr=np.full((H,W),np.nan,np.float32)
    for f,(tx,ty) in zip(fs,xy):
        try: a=np.array(Image.open(f).convert('RGB')).astype(np.int64)
        except Exception: continue
        if a.shape[:2]!=(256,256): continue
        a=a;v=a[...,0]*65536+a[...,1]*256+a[...,2]
        h=np.where(v<2**23,v,v-2**24)*0.01;h=np.where(v==2**23,np.nan,h)
        arr[(ty-ty0)*256:(ty-ty0+1)*256,(tx-tx0)*256:(tx-tx0+1)*256]=h
    return arr,tx0,ty0,z
def sample(m,lat,lon):
    arr,tx0,ty0,z=m;n=2**z
    px=(lon+180)/360*n;r=np.radians(lat);py=(1-np.log(np.tan(r)+1/np.cos(r))/np.pi)/2*n
    fx=(px-tx0)*256-0.5;fy=(py-ty0)*256-0.5
    ix=np.floor(fx).astype(int);iy=np.floor(fy).astype(int);ax=fx-ix;ay=fy-iy
    H,W=arr.shape;ix=np.clip(ix,0,W-2);iy=np.clip(iy,0,H-2)
    a=arr[iy,ix];b=arr[iy,ix+1];c=arr[iy+1,ix];d=arr[iy+1,ix+1]
    out=(a*(1-ax)+b*ax)*(1-ay)+(c*(1-ax)+d*ax)*ay
    # where any corner nan, use nearest non-nan
    near=arr[np.clip(np.round(fy).astype(int),0,H-1),np.clip(np.round(fx).astype(int),0,W-1)]
    return np.where(np.isnan(out),near,out)
xs=X0+np.arange(NX)*G;zs=Z0+np.arange(NZ)*G
XX,ZZ=np.meshgrid(xs,zs)
LAT=LAT0-ZZ/MZ;LON=LON0+XX/MX
dem=None
for kind,z in [('dem5a_png',15),('dem5b_png',15),('dem_png',14)]:
    m=mosaic(kind,z)
    if m is None: continue
    s=sample(m,LAT,LON)
    dem=s if dem is None else np.where(np.isnan(dem),s,dem)
    print(kind,'nan frac',np.isnan(dem).mean(),flush=True)
nan=np.isnan(dem)
# sea = large connected nan region touching the south edge (plus areas <= 0 connected to it)
lab,nl=ndimage.label(nan)
south=set(np.unique(lab[-1,:]))-{0}
sea=np.isin(lab,list(south))
# small inland nan holes: fill by nearest valid
hole=nan&~sea
if hole.any():
    idx=ndimage.distance_transform_edt(np.isnan(np.where(sea,0,dem)),return_distances=False,return_indices=True)
    dem=np.where(hole,dem[idx[0],idx[1]],dem)
dist=ndimage.distance_transform_edt(sea)*G
dem=np.where(sea,-0.6-np.minimum(dist,800)*0.018-np.maximum(dist-800,0)*0.004,dem)
dem=np.where(~sea&(dem<0.15),0.15,dem)
print('dem range',np.nanmin(dem),np.nanmax(dem),flush=True)

# coast z per x column (first sea from north with a long run)
coast=np.zeros(NX,np.float32)
for i in range(NX):
    col=sea[:,i];z=None
    run=0
    for j in range(NZ):
        if col[j]:
            run+=1
            if run>=40: z=j-run+1;break
        else: run=0
    coast[i]=Z0+(z if z is not None else NZ-1)*G

# ---------------- helpers ----------------
def wpts(refs):
    p=[nodes.get(r) for r in refs]
    if any(q is None for q in p): return None
    return p
def rings_from_rel(mem,role):
    segs=[]
    for t,ref,r in mem:
        if t=='way' and (r==role or (role=='outer' and r=='')) and ref in ways:
            segs.append(list(ways[ref][1]))
    rings=[]
    while segs:
        cur=segs.pop()
        changed=True
        while cur[0]!=cur[-1] and changed:
            changed=False
            for k,s in enumerate(segs):
                if s[0]==cur[-1]: cur+=s[1:];segs.pop(k);changed=True;break
                if s[-1]==cur[-1]: cur+=s[::-1][1:];segs.pop(k);changed=True;break
                if s[-1]==cur[0]: cur=s+cur[1:];segs.pop(k);changed=True;break
                if s[0]==cur[0]: cur=s[::-1]+cur[1:];segs.pop(k);changed=True;break
        if cur[0]==cur[-1] and len(cur)>=4: rings.append(cur)
    return rings
def areas():
    for wid,(tg,refs) in ways.items():
        if tg and len(refs)>=4 and refs[0]==refs[-1]: yield ('w',wid,tg,[refs])
    for rid,(tg,mem) in rels.items():
        if tg.get('type') in ('multipolygon','boundary') and tg.get('type')=='multipolygon':
            rg=rings_from_rel(mem,'outer')
            if rg: yield ('r',rid,tg,rg)
def area_xy(p):
    a=0;cx=0;cz=0
    for i in range(len(p)-1):
        x0,z0=p[i];x1,z1=p[i+1];c=x0*z1-x1*z0;a+=c;cx+=(x0+x1)*c;cz+=(z0+z1)*c
    if abs(a)<1e-9: return 0,p[0][0],p[0][1]
    return a/2,cx/(3*a),cz/(3*a)
def dp(pts,eps):
    if len(pts)<3: return pts
    a=np.array(pts);s=a[0];e=a[-1];d=e-s;L2=(d**2).sum()
    if L2<1e-12: dd=np.sqrt(((a-s)**2).sum(1))
    else:
        t=np.clip(((a-s)@d)/L2,0,1);pr=s+t[:,None]*d;dd=np.sqrt(((a-pr)**2).sum(1))
    i=int(np.argmax(dd))
    if dd[i]>eps: return dp(pts[:i+1],eps)[:-1]+dp(pts[i:],eps)
    return [pts[0],pts[-1]]

# ---------------- landcover raster ----------------
LC=Image.new('L',(NX,NZ),0);dr=ImageDraw.Draw(LC)
def topx(p): return [((x-X0)/G,(z-Z0)/G) for x,z in p]
def lc_class(tg):
    lu=tg.get('landuse');na=tg.get('natural');le=tg.get('leisure');am=tg.get('amenity')
    if na=='water' or tg.get('waterway')=='riverbank' or lu in('reservoir','basin') or 'water' in tg and na!='wetland': return 1,9
    if na in('beach','sand'): return 5,8
    if am in('school','university','college','kindergarten') or lu=='education': return 7,5
    if am=='parking': return 8,6
    if am=='grave_yard' or lu=='cemetery': return 11,5
    if le in('pitch','track','stadium'): return 13,6
    if le in('park','garden','playground','golf_course','nature_reserve','recreation_ground','common','dog_park'): return 3,5
    if lu in('forest',) or na in('wood',): return 2,4
    if na in('scrub','heath','grassland','wetland'): return 10,3
    if lu in('grass','village_green','recreation_ground','meadow'): return 3 if lu!='meadow' else 4,3
    if lu in('farmland','orchard','farmyard','greenhouse_horticulture','vineyard','plant_nursery','allotments'): return 4,3
    if lu in('commercial','retail','industrial','construction','brownfield','garages'): return 6,2
    if lu=='railway': return 8,2
    if lu in('residential',): return 0,1
    return None
draw=[]
for kind,i,tg,rings in areas():
    if 'building' in tg: continue
    c=lc_class(tg)
    if c is None: continue
    for r in rings:
        p=wpts(r)
        if p: a,_,_=area_xy(p);draw.append((c[1],-abs(a),c[0],p))
draw.sort(key=lambda d:(d[0],d[1]))  # priority, then big first
for pr,na,cls,p in draw: dr.polygon(topx(p),fill=cls)
# waterway lines
for wid,(tg,refs) in ways.items():
    if not tg: continue
    ww=tg.get('waterway')
    if ww in('river','canal','stream','drain','ditch') and tg.get('tunnel') not in('yes','culvert'):
        p=wpts(refs)
        if not p: continue
        w={'river':14,'canal':6,'stream':3,'drain':2,'ditch':1.5}[ww]/G
        dr.line(topx(p),fill=1,width=max(1,int(round(w))))
lc=np.array(LC,np.uint8)
lc=np.where(sea,1,lc).astype(np.uint8)
# beaches: low land next to the sea without other class
print('landcover hist',np.bincount(lc.ravel(),minlength=14),flush=True)
# rivers / ponds: lower ground under inland water so you can swim, keep water level
water_in=(lc==1)&~sea

# ---------------- railways & lines ----------------
LINES={
 'jr':(['東海道'],['貨物','新幹線'],[[35.3240,139.3300],[35.3300,139.3900],[35.3306,139.4073],[35.3340,139.4250],[35.3365,139.4473],[35.3378,139.4650],[35.3389,139.4874],[35.3405,139.5000],[35.3440,139.5110],[35.3490,139.5220],[35.3540,139.5313],[35.3610,139.5420],[35.3700,139.5520]],
       ['茅ヶ崎','辻堂','藤沢','大船']),
 'odn':(['小田急'],[],[[35.3393,139.4870],[35.3412,139.4861],[35.3440,139.4845],[35.3494,139.4803],[35.3560,139.4775],[35.3612,139.4747],[35.3700,139.4720],[35.3780,139.4693],[35.3870,139.4680],[35.3961,139.4669],[35.4086,139.4658],[35.4250,139.4630],[35.4400,139.4600]],
       ['藤沢','藤沢本町','善行','六会日大前','湘南台','長後']),
 'ods':(['小田急'],[],None,['藤沢','本鵠沼','鵠沼海岸','片瀬江ノ島']),
 'eno':(['江ノ島電鉄','江ノ電'],[],[[35.3386,139.4893],[35.3375,139.4882],[35.3360,139.4872],[35.3349,139.4864],[35.3330,139.4853],[35.3313,139.4845],[35.3290,139.4843],[35.3265,139.4844],[35.3230,139.4852],[35.3190,139.4860],[35.3160,139.4865],[35.3120,139.4870],[35.3095,139.4876],[35.3089,139.4880],[35.3083,139.4898],[35.3075,139.4910],[35.3071,139.4917],[35.3067,139.4945],[35.3066,139.4975],[35.3066,139.5004],[35.3063,139.5050],[35.3060,139.5098],[35.3085,139.5200],[35.3120,139.5300],[35.3160,139.5400]],
       ['藤沢','石上','柳小路','鵠沼','湘南海岸公園','江ノ島','腰越','鎌倉高校前','七里ヶ浜']),
 'mono':(['モノレール'],[],[[35.3103,139.4885],[35.3115,139.4905],[35.3135,139.4930],[35.3160,139.4960],[35.3180,139.4985],[35.3210,139.5030],[35.3237,139.5065],[35.3290,139.5110],[35.3340,139.5160],[35.3410,139.5230],[35.3480,139.5280],[35.3530,139.5320]],
       ['湘南江の島','目白山下','片瀬山','西鎌倉','湘南深沢','湘南町屋','富士見町','大船']),
}
railways=[]
for wid,(tg,refs) in ways.items():
    if tg and tg.get('railway') in('rail','narrow_gauge','light_rail','monorail','tram') :
        p=wpts(refs)
        if p: railways.append((wid,tg,p))
print('rail ways',len(railways),collections.Counter(tg.get('name') for _,tg,_ in railways).most_common(25),flush=True)
pickle.dump({'railways':railways},open(os.path.join(SP,'bake','rails.pkl'),'wb'))
stations=[]
for nid,tg in pois:
    if tg.get('railway') in('station','halt') or tg.get('public_transport')=='station':
        if nid in nodes: stations.append((tg.get('name'),tg.get('operator'),tg.get('railway'),nodes[nid]))
for wid,(tg,refs) in ways.items():
    if tg and (tg.get('railway')=='station' or tg.get('public_transport')=='station') and tg.get('name'):
        p=wpts(refs)
        if p: a,cx,cz=area_xy(p+[p[0]]);stations.append((tg.get('name'),tg.get('operator'),'stationarea',(cx,cz)))
json.dump([(s[0],s[1],s[2],[round(s[3][0],1),round(s[3][1],1)]) for s in stations],open(os.path.join(SP,'bake','stations.json'),'w'),ensure_ascii=False)
np.save(os.path.join(SP,'bake','dem.npy'),dem.astype(np.float32));np.save(os.path.join(SP,'bake','lc.npy'),lc);np.save(os.path.join(SP,'bake','sea.npy'),sea);np.save(os.path.join(SP,'bake','coast.npy'),coast)
print('stage1 done',flush=True)
