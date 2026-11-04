# bake4: Fujisawa + station areas along Odakyu / Sotetsu / Blue line / JR.
# Detail (5 m) only in "detail chunks"; coarse 30 m DEM elsewhere.
import pickle, math, json, struct, gzip, os, glob, collections, heapq, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
import xml.etree.ElementTree as ET
import mapbox_vector_tile as MVT

SP=os.path.dirname(os.path.dirname(os.path.abspath(__file__)));B=os.path.join(SP,'bake')
LAT0,LON0,MX,MZ=35.3389,139.4874,90807,110940
def L(lat,lon): return ((lon-LON0)*MX,-(lat-LAT0)*MZ)
CH=320;G=5.0
X0=-8840-320*9;Z0=-10100-320*42       # aligned with the old Fujisawa grid
X1=14800;Z1=7700
CNX=math.ceil((X1-X0)/CH);CNZ=math.ceil((Z1-Z0)/CH)
FW=(-8840,4780,-10100,5400)            # Fujisawa full-detail area
print('chunks',CNX,CNZ,flush=True)

# ---------------- OSM: merge Fujisawa pickle + station tiles + route relations ----------------
D=pickle.load(open(os.path.join(B,'osm.pkl'),'rb'))
nodes=D['nodes'];ways=D['ways'];rels=D['rels'];pois=D['pois']
KEEP_W=('building','highway','railway','landuse','natural','leisure','waterway','water','amenity','public_transport','man_made','tourism','historic','place','bridge')
def parse(f):
    for ev,el in ET.iterparse(f):
        t=el.tag
        if t=='node':
            i=int(el.get('id'))
            if i not in nodes: nodes[i]=((float(el.get('lon'))-LON0)*MX,-(float(el.get('lat'))-LAT0)*MZ)
            tg={c.get('k'):c.get('v') for c in el.findall('tag')}
            if tg and ('name' in tg or tg.get('railway') in('subway_entrance','train_station_entrance') or tg.get('entrance')): pois.append((i,tg))
            el.clear()
        elif t=='way':
            i=int(el.get('id'))
            if i not in ways:
                tg={c.get('k'):c.get('v') for c in el.findall('tag')}
                ways[i]=(tg if tg else None,[int(n.get('ref')) for n in el.findall('nd')])
            el.clear()
        elif t=='relation':
            i=int(el.get('id'));tg={c.get('k'):c.get('v') for c in el.findall('tag')}
            mem=[(m.get('type'),int(m.get('ref')),m.get('role')) for m in el.findall('member')]
            if i not in rels or len(mem)>len(rels[i][1]): rels[i]=(tg,mem)
            el.clear()
for f in sorted(glob.glob(os.path.join(SP,'ext','s_*.xml'))):
    if os.path.getsize(f)>200: parse(f)
for f in sorted(glob.glob(os.path.join(SP,'ext','rel_*.xml'))): parse(f)
# entrances inside Fujisawa tiles were not kept by parse_osm: rescan quickly
for f in sorted(glob.glob(os.path.join(SP,'osm','t_*.xml'))):
    if os.path.getsize(f)<200: continue
    for ev,el in ET.iterparse(f):
        if el.tag=='node':
            for c in el.findall('tag'):
                if c.get('k')=='railway' and c.get('v') in('subway_entrance','train_station_entrance'):
                    pois.append((int(el.get('id')),{c2.get('k'):c2.get('v') for c2 in el.findall('tag')}));break
        el.clear()
print('osm',len(nodes),len(ways),len(rels),flush=True)
def wpts(refs):
    p=[nodes.get(r) for r in refs]
    return None if any(q is None for q in p) else p
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
def num(v):
    try: return float(str(v).replace('m','').strip().split(';')[0])
    except: return None
def rings_from_rel(mem):
    segs=[list(ways[ref][1]) for t,ref,r in mem if t=='way' and r in('outer','') and ref in ways]
    rings=[]
    while segs:
        cur=segs.pop();ch=True
        while cur[0]!=cur[-1] and ch:
            ch=False
            for k,s in enumerate(segs):
                if s[0]==cur[-1]: cur+=s[1:];segs.pop(k);ch=True;break
                if s[-1]==cur[-1]: cur+=s[::-1][1:];segs.pop(k);ch=True;break
                if s[-1]==cur[0]: cur=s+cur[1:];segs.pop(k);ch=True;break
                if s[0]==cur[0]: cur=s[::-1]+cur[1:];segs.pop(k);ch=True;break
        if cur[0]==cur[-1] and len(cur)>=4: rings.append(cur)
    return rings
def pip(x,z,r):
    c=False;n=len(r)
    for i in range(n):
        ax,az=r[i];bx,bz=r[i-1]
        if (az>z)!=(bz>z) and x<(bx-ax)*(z-az)/(bz-az)+ax: c=not c
    return c

# ---------------- line definitions (route relations) ----------------
def relpath(rid): return os.path.join(SP,'ext','rel_%d.xml'%rid)
def rel_info(rid):
    t=ET.parse(relpath(rid)).getroot();nd={n.get('id'):n for n in t.iter('node')}
    for r in t.iter('relation'):
        tg={c.get('k'):c.get('v') for c in r.findall('tag')}
        if tg.get('type')!='route': continue
        stops=[];wl=[]
        for m in r.findall('member'):
            if m.get('type')=='node' and m.get('role','').startswith('stop') and m.get('ref') in nd:
                n=nd[m.get('ref')];nm={c.get('k'):c.get('v') for c in n.findall('tag')}.get('name','').replace('駅','')
                stops.append((nm,L(float(n.get('lat')),float(n.get('lon')))))
            if m.get('type')=='way' and m.get('role','') in('',): wl.append(int(m.get('ref')))
        return stops,wl
    return [],[]
EN={'茅ヶ崎':'Chigasaki','辻堂':'Tsujidō','藤沢':'Fujisawa','大船':'Ōfuna','戸塚':'Totsuka','横浜':'Yokohama','藤沢本町':'Fujisawa-honmachi','善行':'Zengyō','六会日大前':'Mutsuai-Nichidaimae','湘南台':'Shōnandai','長後':'Chōgo','高座渋谷':'Kōza-Shibuya','桜ヶ丘':'Sakuragaoka','大和':'Yamato','鶴間':'Tsuruma','南林間':'Minami-Rinkan','中央林間':'Chūō-Rinkan','東林間':'Higashi-Rinkan','相模大野':'Sagami-Ōno','本鵠沼':'Hon-kugenuma','鵠沼海岸':'Kugenuma-kaigan','片瀬江ノ島':'Katase-Enoshima',
 '平沼橋':'Hiranumabashi','西横浜':'Nishi-Yokohama','天王町':'Tennōchō','星川':'Hoshikawa','和田町':'Wadamachi','上星川':'Kami-Hoshikawa','西谷':'Nishiya','鶴ヶ峰':'Tsurugamine','二俣川':'Futamatagawa','希望ヶ丘':'Kibōgaoka','三ツ境':'Mitsukyō','瀬谷':'Seya','相模大塚':'Sagami-Ōtsuka','さがみ野':'Sagamino','かしわ台':'Kashiwadai','海老名':'Ebina',
 'ゆめが丘':'Yumegaoka','いずみ中央':'Izumi-chūō','いずみ野':'Izumino','弥生台':'Yayoidai','緑園都市':'Ryokuentoshi','南万騎が原':'Minami-Makigahara',
 '下飯田':'Shimo-iida','立場':'Tateba','中田':'Nakada','踊場':'Odoriba','舞岡':'Maioka','下永谷':'Shimo-nagaya','上永谷':'Kami-nagaya','港南中央':'Kōnan-chūō','上大岡':'Kami-ōoka','弘明寺':'Gumyōji','蒔田':'Maita','吉野町':'Yoshinochō','阪東橋':'Bandōbashi','伊勢佐木長者町':'Isezakichōjamachi','関内':'Kannai','桜木町':'Sakuragichō','高島町':'Takashimachō',
 '石上':'Ishigami','柳小路':'Yanagikōji','鵠沼':'Kugenuma','湘南海岸公園':'Shōnan-kaigan-kōen','江ノ島':'Enoshima','腰越':'Koshigoe','鎌倉高校前':'Kamakura-kōkōmae','七里ヶ浜':'Shichirigahama',
 '湘南江の島':'Shōnan-Enoshima','目白山下':'Mejiroyama-shita','片瀬山':'Kataseyama','西鎌倉':'Nishi-Kamakura','湘南深沢':'Shōnan-fukasawa','湘南町屋':'Shōnan-machiya','富士見町':'Fujimichō'}
LDEF={
 'jr':  {'rels':[12014184,12014185],'st':['茅ヶ崎','辻堂','藤沢','大船','戸塚','横浜'],'ends':[(35.3270,139.3620),(35.4712,139.6420)],'pair':4.6},
 'odn': {'rels':[21267161,21267162],'st':['藤沢','藤沢本町','善行','六会日大前','湘南台','長後','高座渋谷','桜ヶ丘','大和','鶴間','南林間','中央林間','東林間','相模大野'],'ends':[None,None],'pair':4.6},
 'ods': {'rels':[21267160],'st':['藤沢','本鵠沼','鵠沼海岸','片瀬江ノ島'],'ends':[None,None],'pair':4.6},
 'sot': {'rels':[10358686,10358687,9561109,9561111],'st':['横浜','平沼橋','西横浜','天王町','星川','和田町','上星川','西谷','鶴ヶ峰','二俣川','希望ヶ丘','三ツ境','瀬谷','大和','相模大塚','さがみ野','かしわ台','海老名'],'ends':[None,None],'pair':4.6},
 'izm': {'rels':[9561172,10358978],'st':['湘南台','ゆめが丘','いずみ中央','いずみ野','弥生台','緑園都市','南万騎が原','二俣川'],'ends':[None,None],'pair':4.6},
 'blu': {'rels':[7732276,1905261],'st':['湘南台','下飯田','立場','中田','踊場','戸塚','舞岡','下永谷','上永谷','港南中央','上大岡','弘明寺','蒔田','吉野町','阪東橋','伊勢佐木長者町','関内','桜木町','高島町','横浜'],'ends':[None,None],'pair':4.6},
}
OLD=json.load(open(os.path.join(B,'lines_cfg.json')))
railways=[]
for wid,(tg,refs) in ways.items():
    if tg and tg.get('railway') in('rail','narrow_gauge','light_rail','monorail','tram','subway'):
        p=wpts(refs)
        if p: railways.append((wid,tg,p))
print('railways',len(railways),flush=True)
def build_line(key,way_ids,stations,ends,pair,single=False):
    sel=set(w for w in way_ids if w in ways)
    adj=collections.defaultdict(list);wtag={}
    for wid in sel:
        tg,refs=ways[wid];tg=tg or {}
        fl=2 if tg.get('tunnel') in('yes','building_passage') or tg.get('railway')=='subway' and tg.get('bridge') not in('yes','viaduct') and tg.get('layer') not in('1','2') else (1 if tg.get('bridge') in('yes','viaduct') else 0)
        if tg.get('railway')=='subway' and tg.get('tunnel')!='yes' and tg.get('bridge') not in('yes','viaduct') and tg.get('layer','0').startswith('-')==False and tg.get('location')!='underground': fl=0 if tg.get('tunnel')=='no' else fl
        for u,v in zip(refs[:-1],refs[1:]):
            if u in nodes and v in nodes:
                d=math.hypot(nodes[u][0]-nodes[v][0],nodes[u][1]-nodes[v][1]);adj[u].append((v,d));adj[v].append((u,d));wtag[(u,v)]=fl;wtag[(v,u)]=fl
    gnodes=list(adj.keys());GA=np.array([nodes[n] for n in gnodes])
    def nn(x,z):
        d=np.hypot(GA[:,0]-x,GA[:,1]-z);i=int(np.argmin(d));return gnodes[i]
    targets=[]
    if ends[0]: targets.append(L(*ends[0]))
    targets+=[s[1] for s in stations]
    if ends[1]: targets.append(L(*ends[1]))
    tn=[nn(x,z) for x,z in targets]
    route=[tn[0]]
    for a_,b_ in zip(tn[:-1],tn[1:]):
        dist={a_:0};prev={};pq=[(0,a_)]
        while pq:
            d,u=heapq.heappop(pq)
            if u==b_: break
            if d>dist.get(u,1e18): continue
            for v,w in adj[u]:
                nd2=d+w
                if nd2<dist.get(v,1e18): dist[v]=nd2;prev[v]=u;heapq.heappush(pq,(nd2,v))
        if b_!=a_ and b_ not in prev:
            print('NO ROUTE',key,flush=True)
            if len(route)==1: route=[b_]
            continue
        seg=[];u=b_
        while u!=a_: seg.append(u);u=prev[u]
        route+=seg[::-1]
    coords=[nodes[n] for n in route];fl=[wtag.get((u,v),0) for u,v in zip(route[:-1],route[1:])]
    dens=[];dfl=[]
    for (a1,b1),f in zip(zip(coords[:-1],coords[1:]),fl):
        l=math.hypot(b1[0]-a1[0],b1[1]-a1[1]);n=max(1,int(l/2))
        for k in range(n): dens.append((a1[0]+(b1[0]-a1[0])*k/n,a1[1]+(b1[1]-a1[1])*k/n));dfl.append(f)
    dens.append(coords[-1]);dfl.append(fl[-1] if fl else 0)
    S=[dens[0]];SF=[dfl[0]];acc=0
    for i in range(1,len(dens)):
        acc+=math.hypot(dens[i][0]-dens[i-1][0],dens[i][1]-dens[i-1][1])
        if acc>=10: S.append(dens[i]);SF.append(dfl[i]);acc=0
    if math.hypot(S[-1][0]-dens[-1][0],S[-1][1]-dens[-1][1])>3: S.append(dens[-1]);SF.append(dfl[-1])
    S=np.array(S)
    # parallel tracks: the line's own ways + all railways nearby of the same kind
    allp=[]
    srcs=[ways[w][1] for w in sel]
    for refs in srcs:
        p=wpts(refs)
        if not p: continue
        for a1,b1 in zip(p[:-1],p[1:]):
            l=math.hypot(b1[0]-a1[0],b1[1]-a1[1]);n=max(1,int(l/2));tx=(b1[0]-a1[0])/(l or 1);tz=(b1[1]-a1[1])/(l or 1)
            for k in range(n): allp.append((a1[0]+(b1[0]-a1[0])*k/n,a1[1]+(b1[1]-a1[1])*k/n,tx,tz))
    AP=np.array(allp);gh2=collections.defaultdict(list)
    for i,(x,z,_,_) in enumerate(AP): gh2[(int(x//20),int(z//20))].append(i)
    def near_pts(x,z):
        cand=[]
        for a1 in range(int(x//20)-1,int(x//20)+2):
            for b1 in range(int(z//20)-1,int(z//20)+2): cand+=gh2.get((a1,b1),[])
        return cand
    C=S.copy()
    for i in range(len(S)):
        j=min(i+1,len(S)-1);h=max(i-1,0);tx,tz=S[j]-S[h];l=math.hypot(tx,tz) or 1;tx/=l;tz/=l;nx,nz=-tz,tx
        x,z=S[i];cand=near_pts(x,z)
        if not cand: continue
        c=AP[cand];dx=c[:,0]-x;dz=c[:,1]-z;al=dx*tx+dz*tz;of=dx*nx+dz*nz;par=np.abs(c[:,2]*tx+c[:,3]*tz)>0.85
        m=par&(np.abs(al)<2.5)&(np.abs(of)<pair)
        if m.sum():
            o=of[m];lo=min(o.min(),0);hi=max(o.max(),0)
            if hi-lo<8: C[i]=[x+nx*(lo+hi)/2,z+nz*(lo+hi)/2]
    C2=C.copy()
    for i in range(len(C)):
        a1=max(0,i-2);b1=min(len(C),i+3);C2[i]=C[a1:b1].mean(0)
    F=np.array(SF);F2=F.copy()
    for i in range(len(F)):
        a1=max(0,i-1);b1=min(len(F),i+2);F2[i]=np.bincount(F[a1:b1]).argmax()
    OFF=[]
    for i in range(len(C2)):
        j=min(i+1,len(C2)-1);h=max(i-1,0);tx,tz=C2[j]-C2[h];l=math.hypot(tx,tz) or 1;tx/=l;tz/=l;nx,nz=-tz,tx
        x,z=C2[i];cand=near_pts(x,z);lo=hi=None
        if cand:
            c=AP[cand];dx=c[:,0]-x;dz=c[:,1]-z;al=dx*tx+dz*tz;of=dx*nx+dz*nz;par=np.abs(c[:,2]*tx+c[:,3]*tz)>0.85
            o=of[par&(np.abs(al)<3)&(np.abs(of)<7.5)]
            if len(o):
                neg=o[o<-0.6];pos=o[o>0.6];mid=o[np.abs(o)<=0.6]
                lo=float(neg.max()) if len(neg) else None;hi=float(pos.min()) if len(pos) else None
                if single and len(mid): lo=lo if lo is not None and len(pos) else None;hi=hi if hi is not None and len(neg) else None
        if lo is None and hi is None: lo,hi=(0,0) if single else (-1.9,1.9)
        elif lo is None: lo=(0 if single else hi-3.8)
        elif hi is None: hi=(0 if single else lo+3.8)
        OFF.append([lo,hi])
    OFF=np.array(OFF);O2=OFF.copy()
    for i in range(len(OFF)):
        a1=max(0,i-3);b1=min(len(OFF),i+4);O2[i]=np.median(OFF[a1:b1],axis=0)
    O3=O2.copy()
    for i in range(len(O2)):
        a1=max(0,i-2);b1=min(len(O2),i+3);O3[i]=O2[a1:b1].mean(0)
    print(key,'pts',len(C2),'km',round(len(C2)/100,1),'bridge',int((F2==1).sum()),'tunnel',int((F2==2).sum()),flush=True)
    return {'pts':[[round(float(x),1),round(float(z),1)] for x,z in C2],'flags':[int(f) for f in F2],'offs':[[round(float(a),2),round(float(b),2)] for a,b in O3]}
lines_out={};ST={}
for key,d in LDEF.items():
    wl=[];stops={}
    for rid in d['rels']:
        s,w=rel_info(rid);wl+=w
        for nm,p in s: stops.setdefault(nm,p)
    stl=[(nm,stops[nm]) for nm in d['st'] if nm in stops]
    missing=[nm for nm in d['st'] if nm not in stops]
    if missing: print('missing stops',key,missing)
    lines_out[key]=build_line(key,wl,stl,d['ends'],d['pair'])
    ST[key]=[[nm,EN.get(nm,nm),round(p[0],1),round(p[1],1),True] for nm,p in stl]
# Enoden / monorail from the Fujisawa railways (name match)
for key,inc in (('eno',['江ノ島電鉄','江ノ電']),('mono',['モノレール'])):
    wl=[wid for wid,tg,p in railways if any(s in ((tg.get('name') or '')+'|'+(tg.get('operator') or '')) for s in inc)]
    old=json.load(open(os.path.join(B,'stations.json')))
    stl=[]
    for nm,en,la,lo in OLD[key]['st']:
        rx,rz=L(la,lo);best=None
        for s in old:
            if (s[0] or '').replace('駅','')!=nm: continue
            d=math.hypot(s[3][0]-rx,s[3][1]-rz)+(0 if s[1] and inc[0][:2] in s[1] else 400)
            if best is None or d<best[0]: best=(d,s[3])
        stl.append((nm,tuple(best[1]) if best else (rx,rz)))
    ends=[None,(35.3150,139.5380)] if key=='eno' else [None,None]
    lines_out[key]=build_line(key,wl,stl,ends,3,single=True)
    ST[key]=[[nm,EN.get(nm,nm),round(p[0],1),round(p[1],1),True] for nm,p in stl]

# ---------------- detail chunks ----------------
def chunk_of(x,z): return int((x-X0)//CH),int((z-Z0)//CH)
detail=set()
for i in range(CNX):
    for j in range(CNZ):
        cx=X0+(i+0.5)*CH;cz=Z0+(j+0.5)*CH
        if FW[0]-CH/2<=cx<=FW[1]+CH/2 and FW[2]-CH/2<=cz<=FW[3]+CH/2: detail.add((i,j))
extst=[]
for key,sts in ST.items():
    for nm,en,x,z,_ in sts:
        if not(FW[0]<=x<=FW[1] and FW[2]<=z<=FW[3]): extst.append((x,z))
for x,z in extst:
    for i in range(CNX):
        for j in range(CNZ):
            cx=X0+(i+0.5)*CH;cz=Z0+(j+0.5)*CH
            if math.hypot(cx-x,cz-z)<620: detail.add((i,j))
print('detail chunks',len(detail),flush=True)
DET=np.zeros((CNZ,CNX),np.uint8)
for i,j in detail: DET[j,i]=1

# ---------------- DEM ----------------
TC={}
def load_tile(kind,z,x,y):
    k=(kind,z,x,y)
    if k in TC: return TC[k]
    f=os.path.join(SP,'dem','%s_%d_%d.png'%(kind,x,y));a=None
    if os.path.exists(f):
        try:
            im=np.array(Image.open(f).convert('RGB')).astype(np.int64)
            if im.shape[:2]==(256,256):
                v=im[...,0]*65536+im[...,1]*256+im[...,2];h=np.where(v<2**23,v,v-2**24)*0.01;a=np.where(v==2**23,np.nan,h).astype(np.float32)
        except Exception: a=None
    TC[k]=a;return a
def sample(kind,z,lat,lon):
    n=2**z;px=(lon+180)/360*n*256-0.5;r=np.radians(lat);py=(1-np.log(np.tan(r)+1/np.cos(r))/np.pi)/2*n*256-0.5
    out=np.full(lat.shape,np.nan,np.float32)
    ix=np.floor(px).astype(np.int64);iy=np.floor(py).astype(np.int64);ax=(px-ix).astype(np.float32);ay=(py-iy).astype(np.float32)
    def val(X,Y):
        res=np.full(X.shape,np.nan,np.float32);tx=X//256;ty=Y//256
        for (a,b) in set(zip(tx.ravel().tolist(),ty.ravel().tolist())):
            t=load_tile(kind,z,a,b)
            if t is None: continue
            m=(tx==a)&(ty==b);res[m]=t[Y[m]-b*256,X[m]-a*256]
        return res
    v00=val(ix,iy);v10=val(ix+1,iy);v01=val(ix,iy+1);v11=val(ix+1,iy+1)
    out=(v00*(1-ax)+v10*ax)*(1-ay)+(v01*(1-ax)+v11*ax)*ay
    near=np.where(np.isnan(v00),np.where(np.isnan(v11),v10,v11),v00)
    return np.where(np.isnan(out),near,out)
def inv(x,z): return LAT0-z/MZ, LON0+x/MX
# coarse 30 m
CG=30;CNXg=int((X1-X0)/CG)+1;CNZg=int((Z1-Z0)/CG)+1
xs=X0+np.arange(CNXg)*CG;zs=Z0+np.arange(CNZg)*CG;XX,ZZ=np.meshgrid(xs,zs);la,lo=inv(XX,ZZ)
coarse=sample('dem_png',14,la,lo)
f5=sample('dem5a_png',15,la,lo);coarse=np.where(np.isnan(f5),coarse,f5)
nan=np.isnan(coarse);lab,_=ndimage.label(nan);south=set(np.unique(lab[-1,:]))-{0}
seaC=np.isin(lab,list(south))
hole=nan&~seaC
if hole.any():
    idx=ndimage.distance_transform_edt(np.isnan(np.where(seaC,0,coarse)),return_distances=False,return_indices=True);coarse=np.where(hole,coarse[idx[0],idx[1]],coarse)
distC=ndimage.distance_transform_edt(seaC)*CG
coarse=np.where(seaC,-0.6-np.minimum(distC,800)*0.018-np.maximum(distC-800,0)*0.004,coarse)
coarse=np.where(~seaC&(coarse<0.15),0.15,coarse)
print('coarse',coarse.shape,np.nanmin(coarse),np.nanmax(coarse),flush=True)
def coarse_at(x,z):
    fx=np.clip((x-X0)/CG,0,CNXg-1.001);fz=np.clip((z-Z0)/CG,0,CNZg-1.001);i=fx.astype(int);j=fz.astype(int);ax=fx-i;az=fz-j
    return (coarse[j,i]*(1-ax)+coarse[j,i+1]*ax)*(1-az)+(coarse[j+1,i]*(1-ax)+coarse[j+1,i+1]*ax)*az
def sea_at(x,z):
    i=np.clip(np.round((x-X0)/CG).astype(int),0,CNXg-1);j=np.clip(np.round((z-Z0)/CG).astype(int),0,CNZg-1);return seaC[j,i]
N1=CH//int(G)+1
CHDEM={};CHSEA={}
for (i,j) in sorted(detail):
    xs=X0+i*CH+np.arange(N1)*G;zs=Z0+j*CH+np.arange(N1)*G;XX,ZZ=np.meshgrid(xs,zs);la,lo=inv(XX,ZZ)
    h=sample('dem5a_png',15,la,lo)
    for kind in('dem5b_png',):
        if np.isnan(h).any(): h2=sample(kind,15,la,lo);h=np.where(np.isnan(h),h2,h)
    if np.isnan(h).any(): h2=sample('dem_png',14,la,lo);h=np.where(np.isnan(h),h2,h)
    sea=np.isnan(h)&sea_at(XX,ZZ)
    c=coarse_at(XX,ZZ)
    h=np.where(np.isnan(h),c,h)
    h=np.where(sea,np.minimum(c,-0.6),h)
    CHDEM[(i,j)]=h.astype(np.float32);CHSEA[(i,j)]=sea
print('chunk dem done',flush=True)

# ---------------- land cover per chunk ----------------
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
AREAS=[]
def areas():
    for wid,(tg,refs) in ways.items():
        if tg and len(refs)>=4 and refs[0]==refs[-1]: yield wid,tg,[refs]
    for rid,(tg,mem) in rels.items():
        if tg.get('type')=='multipolygon':
            rg=rings_from_rel(mem)
            if rg: yield rid,tg,rg
LCG=collections.defaultdict(list)
for aid,tg,rings in areas():
    if 'building' in tg: continue
    c=lc_class(tg)
    if c is None: continue
    for r in rings:
        p=wpts(r)
        if not p: continue
        a,_,_=area_xy(p);xs=[q[0] for q in p];zs=[q[1] for q in p]
        k=len(AREAS);AREAS.append((c[1],-abs(a),c[0],p))
        for i in range(int((min(xs)-X0)//CH),int((max(xs)-X0)//CH)+1):
            for j in range(int((min(zs)-Z0)//CH),int((max(zs)-Z0)//CH)+1):
                if (i,j) in detail: LCG[(i,j)].append(k)
WWL=collections.defaultdict(list)
for wid,(tg,refs) in ways.items():
    if not tg: continue
    ww=tg.get('waterway')
    if ww in('river','canal','stream','drain','ditch') and tg.get('tunnel') not in('yes','culvert'):
        p=wpts(refs)
        if not p: continue
        w={'river':14,'canal':6,'stream':3,'drain':2,'ditch':1.5}[ww]
        for i,j in set(((int((x-X0)//CH),int((z-Z0)//CH)) for x,z in p)):
            for di in(-1,0,1):
                for dj in(-1,0,1):
                    if (i+di,j+dj) in detail: WWL[(i+di,j+dj)].append((w,p))
CHLC={}
for (i,j) in sorted(detail):
    ox=X0+i*CH-G/2;oz=Z0+j*CH-G/2
    im=Image.new('L',(N1,N1),0);dr=ImageDraw.Draw(im)
    lst=sorted((AREAS[k] for k in LCG.get((i,j),[])),key=lambda d:(d[0],d[1]))
    for pr,na,cls,p in lst: dr.polygon([((x-ox)/G,(z-oz)/G) for x,z in p],fill=cls)
    for w,p in WWL.get((i,j),[]): dr.line([((x-ox)/G,(z-oz)/G) for x,z in p],fill=1,width=max(1,int(round(w/G))))
    a=np.array(im,np.uint8);a=np.where(CHSEA[(i,j)],1,a);CHLC[(i,j)]=a.astype(np.uint8)
print('landcover done',flush=True)

# ---------------- GSI building classes ----------------
GSI=collections.defaultdict(list);GPOLY=[]
for f in glob.glob(os.path.join(SP,'gsiv','*.pbf')):
    tx,ty=map(int,os.path.basename(f)[:-4].split('_'))
    try: d=MVT.decode(open(f,'rb').read(),default_options={'y_coord_down':True})
    except Exception: continue
    lay=d.get('building')
    if not lay: continue
    ext=lay.get('extent',4096);n=2**16
    for ft in lay['features']:
        code=ft['properties'].get('ftCode');g=ft['geometry']
        polys=[g['coordinates']] if g['type']=='Polygon' else (g['coordinates'] if g['type']=='MultiPolygon' else [])
        for poly in polys:
            ring=[]
            for px,py in poly[0]:
                lon=(tx+px/ext)/n*360-180;lat=math.degrees(math.atan(math.sinh(math.pi*(1-2*(ty+py/ext)/n))));ring.append(L(lat,lon))
            if len(ring)<3: continue
            xs=[q[0] for q in ring];zs=[q[1] for q in ring];idx=len(GPOLY);GPOLY.append((code,ring,min(xs),max(xs),min(zs),max(zs)))
            for a in range(int(min(xs)//50),int(max(xs)//50)+1):
                for b in range(int(min(zs)//50),int(max(zs)//50)+1): GSI[(a,b)].append(idx)
print('gsi',len(GPOLY),flush=True)
def gsi_code(cx,cz,q):
    for i in GSI.get((int(cx//50),int(cz//50)),[]):
        code,ring,x0,x1,z0,z1=GPOLY[i]
        if x0-1<=cx<=x1+1 and z0-1<=cz<=z1+1 and pip(cx,cz,ring): return code
    votes=collections.Counter()
    for x,z in q[::max(1,len(q)//6)]:
        for i in GSI.get((int(x//50),int(z//50)),[]):
            code,ring,x0,x1,z0,z1=GPOLY[i]
            if x0<=x<=x1 and z0<=z<=z1 and pip(x,z,ring): votes[code]+=1
    return votes.most_common(1)[0][0] if votes else None

# ---------------- schools ----------------
SCH=[]
for aid,tg,rings in areas():
    am=tg.get('amenity')
    if am in('school','college','university','kindergarten') or tg.get('landuse')=='education':
        for r in rings:
            p=wpts(r)
            if not p: continue
            nm=tg.get('name') or ''
            kind=3 if am=='university' or '大学' in nm else (2 if '高等学校' in nm or '高校' in nm else (1 if '中学' in nm else (0 if '小学' in nm else (4 if am=='kindergarten' or '幼稚園' in nm or '保育' in nm else 2))))
            xs=[q[0] for q in p];zs=[q[1] for q in p]
            SCH.append((nm,kind,p,min(xs),max(xs),min(zs),max(zs)))
SCG=collections.defaultdict(list)
for k,s in enumerate(SCH):
    for a in range(int(s[3]//100),int(s[4]//100)+1):
        for b in range(int(s[5]//100),int(s[6]//100)+1): SCG[(a,b)].append(k)
def school_at(x,z):
    for k in SCG.get((int(x//100),int(z//100)),[]):
        s=SCH[k]
        if s[3]<=x<=s[4] and s[5]<=z<=s[6] and pip(x,z,s[2]): return k
    return -1
print('schools',len(SCH),collections.Counter(s[1] for s in SCH),flush=True)

# ---------------- buildings ----------------
CORES=[(L(35.3389,139.4874),380),(L(35.3365,139.4473),260),(L(35.3961,139.4669),280),(L(35.3540,139.5313),330),(L(35.3306,139.4073),260),(L(35.4659,139.6223),700),(L(35.4012,139.5344),400),(L(35.4632,139.5313),300),(L(35.4710,139.4610),300),(L(35.5327,139.4366),400),(L(35.4524,139.3922),400),(L(35.3913,139.6000),400),(L(35.4440,139.6350),400)]
KIND={'house':0,'detached':0,'residential':1,'apartments':1,'terrace':1,'dormitory':1,'commercial':2,'retail':2,'office':2,'hotel':2,'supermarket':2,'industrial':3,'warehouse':3,'factory':3,'school':4,'university':4,'college':4,'kindergarten':4,'hospital':4,'public':4,'civic':4,'government':4,'train_station':10,'transportation':10,'shrine':5,'temple':5,'church':5,'religious':5,'garage':6,'garages':6,'shed':6,'hut':6,'carport':6,'roof':7,'greenhouse':8,'parking':3,'stadium':4,'sports_hall':11,'gymnasium':11}
def hh(x):
    x=int(x)&0xffffffff;x=((x>>16)^x)*0x45d9f3b&0xffffffff;x=((x>>16)^x)*0x45d9f3b&0xffffffff;x=(x>>16)^x;return (x&0xffff)/65535
def is_detail_pt(x,z):
    i,j=chunk_of(x,z);return (i,j) in detail
blds=[];seen_b=set()
def add_building(bid,tg,p):
    if bid in seen_b: return
    seen_b.add(bid)
    if tg.get('building')=='no' or tg.get('building:part'): return
    if tg.get('location')=='underground' or (num(tg.get('layer')) or 0)<0: return
    a,cx,cz=area_xy(p);A=abs(a)
    if A<8 or not is_detail_pt(cx,cz): return
    if a<0: p=p[::-1]
    q=dp(p[:-1]+[p[0]],0.35)[:-1]
    if len(q)<3: return
    if len(q)>250: q=q[::max(1,len(q)//250)]
    bt=tg.get('building','yes');kind=KIND.get(bt,9)
    nm=tg.get('name') or ''
    if '体育館' in nm: kind=11
    if '駅' in nm and kind==9: kind=10
    h=num(tg.get('height'));lv=num(tg.get('building:levels'))
    r=hh(bid);incore=any(math.hypot(cx-c[0][0],cz-c[0][1])<c[1] for c in CORES)
    if h is None and lv is not None: h=lv*3.2+0.6
    gc=gsi_code(cx,cz,q)
    if h is None and gc is not None and kind not in(5,7,8):
        if gc==3103: h=45+min(A,2500)/2500*25+r*8
        elif gc==3102:
            if A<100: h=7.5+r*2
            elif A<300: h=9.5+r*4+(4 if incore else 0)
            elif A<900: h=(12+r*10) if not incore else 16+r*20
            elif A<3000: h=(14+r*12) if not incore else 20+r*22
            else: h=11+r*8
            if kind==3: h=min(h,9+r*6)
        elif gc==3101: h=3.5+r if A<40 else (6.0+r*1.3 if A<260 else (7.5+r*2 if A<800 else 9+r*3))
        elif gc in(3111,3112): h=3.6 if gc==3111 else 5;kind=7
    if h is None:
        if kind==6: h=3+r
        elif kind==7: h=5
        elif kind==8: h=3.2
        elif kind==5: h=8+4*r
        elif kind==0: h=6.2+r*1.2
        elif kind==3: h=8+6*r
        elif kind in(4,11): h=12+6*r
        elif A<90: h=5.6+r*1.4
        elif A<220: h=6.4+r*1.6 if not incore else 9+r*12
        elif A<600: h=(9+r*6) if not incore else 16+r*22
        elif A<2500: h=(11+r*8) if not incore else 22+r*26
        else: h=14+r*8 if not incore else 24+r*20
    h=max(2.5,min(h,250))
    minh=num(tg.get('min_height'))
    if minh is None and tg.get('building:min_level') is not None: minh=(num(tg.get('building:min_level')) or 0)*3.2
    roof=0
    if kind in(0,1,9) and A<230 and h<=9.5 and tg.get('roof:shape')!='flat': roof=1
    if tg.get('roof:shape') in('gabled','hipped'): roof=1
    if kind==5 and A<900: roof=1
    if kind==7: roof=2
    if gc in(3102,3103) and kind in(0,9) and h>8: kind=1
    if gc in(3102,3103) and roof==1 and kind!=5: roof=0
    if gc in(3111,3112) and kind==7: roof=2
    sk=school_at(cx,cz)
    if sk>=0 and kind in(0,1,9,4) and A>=200: kind=4
    if sk>=0 and kind==4 and h<9: h=max(h,3*3.7+0.6) if A>350 else h
    blds.append([cx,cz,q,h,minh or 0,roof,kind,bid,A,nm,gc,(num(tg.get('height')) is not None or lv is not None),lv,sk])
for wid,(tg,refs) in ways.items():
    if tg and 'building' in tg and len(refs)>=4 and refs[0]==refs[-1]:
        p=wpts(refs)
        if p: add_building(wid,tg,p)
for rid,(tg,mem) in rels.items():
    if tg.get('type')=='multipolygon' and 'building' in tg:
        for r in rings_from_rel(mem):
            p=wpts(r)
            if p: add_building(rid*7+len(r),tg,p)
# consistent heights inside apartment complexes
CPX=[];CGr=collections.defaultdict(list)
for wid,(tg,refs) in ways.items():
    if tg and tg.get('landuse')=='residential' and (tg.get('name') or tg.get('residential')=='apartments') and len(refs)>=4 and refs[0]==refs[-1]:
        pp=wpts(refs)
        if not pp: continue
        xs=[t[0] for t in pp];zs=[t[1] for t in pp];k=len(CPX);CPX.append((pp,min(xs),max(xs),min(zs),max(zs)))
        for a in range(int(min(xs)//100),int(max(xs)//100)+1):
            for b in range(int(min(zs)//100),int(max(zs)//100)+1): CGr[(a,b)].append(k)
groups=collections.defaultdict(list)
for b in blds:
    if b[11] or b[10] not in(3102,3103): continue
    for k in CGr.get((int(b[0]//100),int(b[1]//100)),[]):
        pp,x0,x1,z0,z1=CPX[k]
        if x0<=b[0]<=x1 and z0<=b[1]<=z1 and pip(b[0],b[1],pp): groups[k].append(b);break
for k,g in groups.items():
    big=[b for b in g if b[8]>=250 and b[10]==3102]
    if not big: continue
    hs=sorted(b[3] for b in big);med=hs[len(hs)//2];floors=max(4,round((med-0.6)/3.0))
    for b in big: b[3]=floors*3.0+0.6
print('buildings',len(blds),collections.Counter(b[6] for b in blds),flush=True)

# ---------------- roads ----------------
RC={'motorway':1,'trunk':1,'motorway_link':1,'trunk_link':1,'primary':2,'primary_link':2,'secondary':3,'secondary_link':3,'tertiary':4,'tertiary_link':4,'unclassified':5,'residential':5,'living_street':6,'service':6,'pedestrian':7,'footway':8,'path':8,'cycleway':8,'steps':8,'track':8,'bridleway':8}
DW={1:16,2:13,3:10,4:8,5:5,6:4,7:5,8:2.2}
roads=[];names=[''];nidx={}
def clip_to_detail(p):
    out=[];cur=[]
    for i in range(len(p)):
        ok=is_detail_pt(*p[i]) or (i>0 and is_detail_pt(*p[i-1])) or (i<len(p)-1 and is_detail_pt(*p[i+1]))
        if ok: cur.append(p[i])
        elif cur:
            if len(cur)>=2: out.append(cur)
            cur=[]
    if len(cur)>=2: out.append(cur)
    return out
for wid,(tg,refs) in ways.items():
    if not tg or 'highway' not in tg or tg.get('area')=='yes': continue
    c=RC.get(tg['highway'])
    if not c: continue
    p=wpts(refs)
    if not p or len(p)<2: continue
    w=num(tg.get('width'))
    if w is None:
        ln=num(tg.get('lanes'));w=(ln*3.1+1.5) if ln and c<=5 else DW[c]
    w=max(1.5,min(w,40))
    fl=(1 if tg.get('bridge') in('yes','viaduct','boardwalk') else 0)|(2 if tg.get('tunnel') in('yes','building_passage') else 0)|(4 if tg['highway']=='steps' else 0)
    nm=tg.get('name') or tg.get('ref') or ''
    if c>4: nm=''
    for part in clip_to_detail(p):
        if nm and nm not in nidx: nidx[nm]=len(names);names.append(nm)
        q=dp(part,0.3) if len(part)>2 else part
        roads.append((c,fl,int(num(tg.get('layer')) or 0),nidx.get(nm,0),w,q))
print('roads',len(roads),flush=True)

# ---------------- platforms, other tracks, entrances, station buildings ----------------
RPG=collections.defaultdict(list)
for wid,tg,p in railways:
    for x,z in p[::2]: RPG[(int(x//30),int(z//30))].append((x,z))
def near_rail(x,z,r=25):
    for i in range(int(x//30)-1,int(x//30)+2):
        for j in range(int(z//30)-1,int(z//30)+2):
            for a,b in RPG.get((i,j),[]):
                if abs(a-x)<r and abs(b-z)<r: return True
    return False
def isplat(tg): return tg and (tg.get('railway')=='platform' or (tg.get('public_transport')=='platform' and tg.get('bus')!='yes' and tg.get('highway')!='platform' and (tg.get('train')=='yes' or tg.get('subway')=='yes' or tg.get('railway')=='platform' or tg.get('monorail')=='yes' or tg.get('light_rail')=='yes')))
def buffer_line(p,w):
    L2=[];R2=[]
    for i in range(len(p)):
        a=p[max(0,i-1)];b=p[min(len(p)-1,i+1)];dx=b[0]-a[0];dz=b[1]-a[1];l=math.hypot(dx,dz) or 1;nx,nz=-dz/l,dx/l
        L2.append((p[i][0]+nx*w,p[i][1]+nz*w));R2.append((p[i][0]-nx*w,p[i][1]-nz*w))
    return L2+R2[::-1]
plats=[];seenp=set()
for wid,(tg,refs) in ways.items():
    if not isplat(tg) or tg.get('area:highway'): continue
    p=wpts(refs)
    if not p or len(p)<2: continue
    if refs[0]==refs[-1] and len(p)>=4: poly=p[:-1]
    else: poly=buffer_line(p,(num(tg.get('width')) or 3.0)/2)
    cx=sum(q[0] for q in poly)/len(poly);cz=sum(q[1] for q in poly)/len(poly)
    if not near_rail(cx,cz,30) or not is_detail_pt(cx,cz): continue
    a,_,_=area_xy(poly+[poly[0]])
    if a<0: poly=poly[::-1]
    plats.append(dp(poly+[poly[0]],0.2)[:-1])
for rid,(tg,mem) in rels.items():
    if tg.get('type')=='multipolygon' and isplat(tg):
        for r in rings_from_rel(mem):
            p=wpts(r)
            if p:
                a,cx,cz=area_xy(p)
                if is_detail_pt(cx,cz): plats.append(p[:-1] if a>0 else p[::-1][:-1])
tracks=[]
for wid,tg,p in railways:
    if tg.get('railway') in('rail','narrow_gauge','light_rail') and tg.get('tunnel') not in('yes','building_passage'):
        for part in clip_to_detail(p): tracks.append((1 if tg.get('bridge') in('yes','viaduct') else 0,dp(part,0.15) if len(part)>2 else part))
ents=[]
for nid,tg in pois:
    if tg.get('railway') in('subway_entrance','train_station_entrance') and nid in nodes:
        x,z=nodes[nid]
        if is_detail_pt(x,z): ents.append((x,z,tg.get('name') or tg.get('ref') or ''))
ents=list({(round(x),round(z)):(x,z,n) for x,z,n in ents}.values())
print('platforms',len(plats),'tracks',len(tracks),'entrances',len(ents),flush=True)

# ---------------- landmarks (reuse names) ----------------
WANT=json.load(open(os.path.join(B,'landmarks_want.json')))
named=collections.defaultdict(list)
for nid,tg in pois:
    if nid in nodes and tg.get('name'): named[tg['name']].append(nodes[nid])
for wid,(tg,refs) in ways.items():
    if tg and tg.get('name') and len(refs)>=2:
        p=wpts(refs)
        if p:
            if refs[0]==refs[-1] and len(p)>=4: a,cx,cz=area_xy(p)
            else: cx=sum(q[0] for q in p)/len(p);cz=sum(q[1] for q in p)/len(p)
            named[tg['name']].append((cx,cz))
LMK={}
for key,(cands,lat,lon) in WANT.items():
    rx,rz=L(lat,lon);best=None
    for nm in cands:
        for pt in named.get(nm,[]):
            d=math.hypot(pt[0]-rx,pt[1]-rz)
            if d<2500 and (best is None or d<best[0]): best=(d,pt)
    if best is None:
        for nm2,pts2 in named.items():
            if any(c in nm2 for c in cands):
                for pt in pts2:
                    d=math.hypot(pt[0]-rx,pt[1]-rz)
                    if d<2500 and (best is None or d<best[0]): best=(d,pt)
    LMK[key]=[round(best[1][0],1),round(best[1][1],1)] if best else None

# ---------------- LOD 40 m ----------------
LG=40;LNX=math.ceil((X1-X0)/LG);LNZ=math.ceil((Z1-Z0)/LG)
cov=np.zeros((LNZ,LNX));hsum=np.zeros((LNZ,LNX))
for b in blds:
    i=int((b[0]-X0)//LG);j=int((b[1]-Z0)//LG)
    if 0<=i<LNX and 0<=j<LNZ: cov[j,i]+=b[8];hsum[j,i]+=b[8]*b[3]
hav=np.where(cov>0,hsum/np.maximum(cov,1),0)
lodc=np.clip(np.sqrt(np.minimum(cov/(LG*LG),1))*255,0,255).astype(np.uint8);lodh=np.clip(hav,0,255).astype(np.uint8)
# coast per 10 m column from the coarse sea mask
coast=[]
for x in np.arange(X0,X1,10):
    i=int(round((x-X0)/CG));col=seaC[:,min(i,CNXg-1)];zc=None;run=0
    for j in range(CNZg):
        if col[j]:
            run+=1
            if run>=8: zc=j-run+1;break
        else: run=0
    coast.append(Z0+(zc if zc is not None else CNZg-1)*CG)
coast=np.array(coast,np.float32)

# ---------------- write ----------------
out=bytearray();sec={}
def align():
    while len(out)%4: out.append(0)
def put(name,b): align();sec[name]=[len(out),len(b)];out.extend(b)
dl=sorted(detail,key=lambda t:(t[1],t[0]))
CIDX=np.full(CNX*CNZ,-1,np.int32)
for k,(i,j) in enumerate(dl): CIDX[j*CNX+i]=k
put('cidx',CIDX.tobytes())
dem_lo=bytearray();dem_hi=bytearray();lcb=bytearray()
for (i,j) in dl:
    q=np.round(CHDEM[(i,j)]*5).astype(np.int32);pred=np.zeros_like(q);pred[1:,1:]=q[1:,:-1]+q[:-1,1:]-q[:-1,:-1];pred[0,1:]=q[0,:-1];pred[1:,0]=q[:-1,0]
    r=(q-pred).astype(np.int16);dem_lo+=(r&0xff).astype(np.uint8).tobytes();dem_hi+=((r>>8)&0xff).astype(np.uint8).tobytes();lcb+=CHLC[(i,j)].tobytes()
put('dem',bytes(dem_lo)+bytes(dem_hi));put('lc',bytes(lcb))
qc=np.round(coarse*5).astype(np.int32);pc=np.zeros_like(qc);pc[1:,1:]=qc[1:,:-1]+qc[:-1,1:]-qc[:-1,:-1];pc[0,1:]=qc[0,:-1];pc[1:,0]=qc[:-1,0];rc=(qc-pc).astype(np.int16)
put('coarse',(rc&0xff).astype(np.uint8).tobytes()+((rc>>8)&0xff).astype(np.uint8).tobytes())
put('lodc',lodc.tobytes());put('lodh',lodh.tobytes())
chunks=collections.defaultdict(list)
for b in blds:
    i,j=chunk_of(b[0],b[1])
    if (i,j) in detail: chunks[(i,j)].append(b)
bb=bytearray();offs=[]
for (i,j) in dl:
    offs.append(len(bb));ox=X0+i*CH;oz=Z0+j*CH
    for (cx,cz,q,h,minh,roof,kind,bid,A,nm,gc,tagged,lv,sk) in chunks[(i,j)]:
        P=[(int(round((x-ox)*4)),int(round((z-oz)*4))) for x,z in q];Q=[P[0]]
        for a1,b1 in zip(P,P[1:]+[P[0]]):
            dx=b1[0]-a1[0];dz=b1[1]-a1[1];k=max(1,math.ceil(max(abs(dx),abs(dz))/127))
            for t in range(1,k+1): Q.append((a1[0]+round(dx*t/k),a1[1]+round(dz*t/k)))
        Q=Q[:-1]
        if len(Q)>255 or len(Q)<3: continue
        bb+=struct.pack('<BBHBhhh',len(Q),roof|(min(kind,15)<<2) if kind<16 else roof,int(round(min(h,6500)*10)),int(round(min(minh,255))),Q[0][0],Q[0][1],sk)
        bb[-10]=roof  # flags byte: roof bits only (kind stored separately below)
        bb+=struct.pack('<B',kind)
        for a1,b1 in zip(Q[:-1],Q[1:]): bb+=struct.pack('<bb',b1[0]-a1[0],b1[1]-a1[1])
offs.append(len(bb))
put('boffs',np.array(offs,np.uint32).tobytes());put('blds',bytes(bb))
CX=(X0+X1)/2;CZ=(Z0+Z1)/2
def pk(x,z): return struct.pack('<ii',int(round((x-CX)*4)),int(round((z-CZ)*4)))
rb=bytearray()
for c,fl,layer,ni,w,q in roads:
    rb+=struct.pack('<BBbBHH',c,fl,max(-8,min(7,layer)),int(round(w*5)),ni,len(q))
    for x,z in q: rb+=struct.pack('<hh',int(round((x-CX)*2)),int(round((z-CZ)*2)))
put('roads',bytes(rb))
pb=bytearray();npl=0
for poly in plats:
    if 3<=len(poly)<=2000:
        npl+=1;pb+=struct.pack('<H',len(poly))
        for x,z in poly: pb+=struct.pack('<hh',int(round((x-CX)*2)),int(round((z-CZ)*2)))
put('plats',bytes(pb))
tb=bytearray()
for fl,q in tracks:
    tb+=struct.pack('<BH',fl,len(q))
    for x,z in q: tb+=struct.pack('<hh',int(round((x-CX)*2)),int(round((z-CZ)*2)))
put('tracks',bytes(tb))
put('coast',coast.tobytes())
schools=[{'name':s[0],'kind':s[1],'pts':[[round(x,1),round(z,1)] for x,z in s[2][::max(1,len(s[2])//40)]]} for s in SCH]
meta={'world':[X0,Z0,X1,Z1],'grid':[G,N1],'coarse':[CNXg,CNZg,CG],'lod':[LNX,LNZ,LG],'chunk':[CH,CNX,CNZ],'ndetail':len(dl),'roadOrigin':[CX,CZ],'nroads':len(roads),'nplats':npl,'ntracks':len(tracks),
      'names':names,'lines':lines_out,'stations':ST,'landmarks':LMK,'schools':schools,'entrances':[[round(x,1),round(z,1),n] for x,z,n in ents],'sections':sec,'fujisawa':list(FW)}
mj=json.dumps(meta,ensure_ascii=False,separators=(',',':')).encode('utf-8')
blob=struct.pack('<4sI',b'FJS2',len(mj))+mj
while len(blob)%4: blob+=b' '
final=blob+bytes(out)
open(os.path.join(SP,'fujisawa-data2.bin'),'wb').write(gzip.compress(final,9))
print('raw',len(final),'gz',os.path.getsize(os.path.join(SP,'fujisawa-data2.bin')),{k:v[1] for k,v in sec.items()})
