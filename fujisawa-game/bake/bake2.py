# Stage 2: lines (snapped to OSM tracks), buildings, roads, LOD, landmarks -> fujisawa-data.bin
import pickle, math, json, struct, gzip, os, collections, sys
import numpy as np
SP=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B=os.path.join(SP,'bake')
LAT0,LON0,MX,MZ=35.3389,139.4874,90807,110940
X0,X1,Z0,Z1=-8840,4780,-10100,5400
G=5.0; NX=int((X1-X0)/G)+1; NZ=int((Z1-Z0)/G)+1
CH=320; CNX=math.ceil((X1-X0)/CH); CNZ=math.ceil((Z1-Z0)/CH)
def L(lat,lon): return ((lon-LON0)*MX,-(lat-LAT0)*MZ)
D=pickle.load(open(os.path.join(B,'osm.pkl'),'rb'))
nodes=D['nodes'];ways=D['ways'];rels=D['rels'];pois=D['pois']
dem=np.load(os.path.join(B,'dem.npy'));lc=np.load(os.path.join(B,'lc.npy'));coast=np.load(os.path.join(B,'coast.npy'))
railways=pickle.load(open(os.path.join(B,'rails.pkl'),'rb'))['railways']
stations=json.load(open(os.path.join(B,'stations.json')))
def H(x,z):
    fx=(x-X0)/G;fz=(z-Z0)/G;i=int(min(max(fx,0),NX-2));j=int(min(max(fz,0),NZ-2));ax=min(max(fx-i,0),1);az=min(max(fz-j,0),1)
    return (dem[j,i]*(1-ax)+dem[j,i+1]*ax)*(1-az)+(dem[j+1,i]*(1-ax)+dem[j+1,i+1]*ax)*az
def wpts(refs):
    p=[nodes.get(r) for r in refs]
    return None if any(q is None for q in p) else p

# ---------- lines ----------
CFG=json.load(open(os.path.join(B,'lines_cfg.json')))
def chaikin(p,it):
    for _ in range(it):
        o=[p[0]]
        for a,b in zip(p[:-1],p[1:]): o+= [[a[0]*.75+b[0]*.25,a[1]*.75+b[1]*.25],[a[0]*.25+b[0]*.75,a[1]*.25+b[1]*.75]]
        o.append(p[-1]);p=o
    return p
def resample(p,step):
    out=[p[0]];acc=0;i=0;cur=list(p[0])
    segs=list(zip(p[:-1],p[1:]))
    rem=step
    for a,b in segs:
        dx=b[0]-a[0];dz=b[1]-a[1];l=math.hypot(dx,dz);t=0
        while l-t>=rem:
            t+=rem;out.append([a[0]+dx*t/l,a[1]+dz*t/l]);rem=step
        rem-=(l-t)
    if math.hypot(out[-1][0]-p[-1][0],out[-1][1]-p[-1][1])>1: out.append(list(p[-1]))
    return out

import heapq
OPS={'jr':'東日本','odn':'小田急','ods':'小田急','eno':'江ノ島電鉄','mono':'モノレール'}
ENDS={'jr':[(35.3290,139.3905),(35.3600,139.5395)],'odn':[None,(35.4285,139.4620)],'ods':[None,None],'eno':[None,(35.3150,139.5380)],'mono':[None,None]}
EXC={'jr':['貨物','新幹線','横須賀','根岸','相模','いずみ野'],'odn':[],'ods':[],'eno':[],'mono':[]}
lines_out={};ST={}
for key,cfg in CFG.items():
    inc=cfg['inc'];exc=EXC[key]
    sel=[];named=[]
    for wid,tg,p in railways:
        nm=(tg.get('name') or '')+'|'+(tg.get('operator') or '')
        if any(s in nm for s in inc) and not any(s in nm for s in exc): sel.append(wid);named+=p
    NP=np.array(named)
    # include unnamed tracks lying along the named ones
    cell=25;gh=collections.defaultdict(list)
    for i,(x,z) in enumerate(named): gh[(int(x//cell),int(z//cell))].append(i)
    def close(x,z,r):
        c0,c1=int(x//cell),int(z//cell)
        for i in range(c0-1,c0+2):
            for j in range(c1-1,c1+2):
                for k in gh.get((i,j),[]):
                    if math.hypot(named[k][0]-x,named[k][1]-z)<r: return True
        return False
    for wid,tg,p in railways:
        if tg.get('name') or wid in sel: continue
        if all(close(x,z,25) for x,z in p[::max(1,len(p)//6)]): sel.append(wid)
    selset=set(sel)
    adj=collections.defaultdict(list)
    wtag={}
    for wid,(tg,refs) in ways.items():
        if wid not in selset: continue
        fl=2 if (tg or {}).get('tunnel') in('yes','building_passage') else (1 if (tg or {}).get('bridge') in('yes','viaduct') else 0)
        for u,v in zip(refs[:-1],refs[1:]):
            if u in nodes and v in nodes:
                d=math.hypot(nodes[u][0]-nodes[v][0],nodes[u][1]-nodes[v][1])
                adj[u].append((v,d));adj[v].append((u,d));wtag[(u,v)]=fl;wtag[(v,u)]=fl
    gnodes=list(adj.keys());GA=np.array([nodes[n] for n in gnodes])
    def nearest_node(x,z):
        d=np.hypot(GA[:,0]-x,GA[:,1]-z);i=int(np.argmin(d));return gnodes[i],float(d[i])
    # stations: prefer the right operator
    res=[]
    for nm,en,lat,lon in cfg['st']:
        rx,rz=L(lat,lon);best=None
        for s in stations:
            if (s[0] or '').replace('駅','')!=nm: continue
            pen=0 if (s[1] and OPS[key] in s[1]) else (300 if s[1] is None else 3000)
            d=math.hypot(s[3][0]-rx,s[3][1]-rz)+pen
            if d<4000 and (best is None or d<best[0]): best=(d,s[3])
        x,z=(best[1] if best else (rx,rz));res.append([nm,en,round(x,1),round(z,1),bool(best)])
    ST[key]=res
    targets=[]
    e0,e1=ENDS[key]
    if e0: targets.append(L(*e0))
    targets+= [(r[2],r[3]) for r in res]
    if e1: targets.append(L(*e1))
    tn=[nearest_node(x,z)[0] for x,z in targets]
    route=[tn[0]]
    for a_,b_ in zip(tn[:-1],tn[1:]):
        dist={a_:0};prev={};pq=[(0,a_)]
        while pq:
            d,u=heapq.heappop(pq)
            if u==b_: break
            if d>dist.get(u,1e18): continue
            for v,w in adj[u]:
                nd=d+w
                if nd<dist.get(v,1e18): dist[v]=nd;prev[v]=u;heapq.heappush(pq,(nd,v))
        if b_ not in prev and b_!=a_:
            print('NO ROUTE',key,a_,b_)
            if len(route)==1: route=[b_]
            continue
        seg=[];u=b_
        while u!=a_: seg.append(u);u=prev[u]
        route+=seg[::-1]
    coords=[nodes[n] for n in route];fl=[wtag.get((u,v),0) for u,v in zip(route[:-1],route[1:])]
    # densify with flags
    dens=[];dfl=[]
    for (a1,b1),f in zip(zip(coords[:-1],coords[1:]),fl):
        l=math.hypot(b1[0]-a1[0],b1[1]-a1[1]);n=max(1,int(l/2))
        for k in range(n): dens.append((a1[0]+(b1[0]-a1[0])*k/n,a1[1]+(b1[1]-a1[1])*k/n));dfl.append(f)
    dens.append(coords[-1]);dfl.append(fl[-1] if fl else 0)
    # resample at 10 m
    S=[dens[0]];SF=[dfl[0]];acc=0
    for i in range(1,len(dens)):
        acc+=math.hypot(dens[i][0]-dens[i-1][0],dens[i][1]-dens[i-1][1])
        if acc>=10: S.append(dens[i]);SF.append(dfl[i]);acc=0
    if math.hypot(S[-1][0]-dens[-1][0],S[-1][1]-dens[-1][1])>3: S.append(dens[-1]);SF.append(dfl[-1])
    S=np.array(S)
    # centreline between parallel tracks of the same line
    allp=[]
    for wid in sel:
        tg,refs=ways[wid];p=wpts(refs)
        if p:
            for a1,b1 in zip(p[:-1],p[1:]):
                l=math.hypot(b1[0]-a1[0],b1[1]-a1[1]);n=max(1,int(l/2));tx=(b1[0]-a1[0])/(l or 1);tz=(b1[1]-a1[1])/(l or 1)
                for k in range(n): allp.append((a1[0]+(b1[0]-a1[0])*k/n,a1[1]+(b1[1]-a1[1])*k/n,tx,tz))
    AP=np.array(allp);gh2=collections.defaultdict(list)
    for i,(x,z,_,_) in enumerate(AP): gh2[(int(x//20),int(z//20))].append(i)
    C=S.copy()
    for i in range(len(S)):
        j=min(i+1,len(S)-1);h=max(i-1,0);tx,tz=S[j]-S[h];l=math.hypot(tx,tz) or 1;tx/=l;tz/=l;nx,nz=-tz,tx
        x,z=S[i];cand=[]
        for a1 in range(int(x//20)-1,int(x//20)+2):
            for b1 in range(int(z//20)-1,int(z//20)+2): cand+=gh2.get((a1,b1),[])
        if not cand: continue
        c=AP[cand];dx=c[:,0]-x;dz=c[:,1]-z;al=dx*tx+dz*tz;of=dx*nx+dz*nz;par=np.abs(c[:,2]*tx+c[:,3]*tz)>0.85
        m=par&(np.abs(al)<2.5)&(np.abs(of)<cfg.get('pair',4.6))
        if m.sum():
            o=of[m];lo=min(o.min(),0);hi=max(o.max(),0)
            if hi-lo<8: C[i]=[x+nx*(lo+hi)/2,z+nz*(lo+hi)/2]
    C2=C.copy()
    for i in range(len(C)):
        a1=max(0,i-2);b1=min(len(C),i+3);C2[i]=C[a1:b1].mean(0)
    F=np.array(SF);F2=F.copy()
    for i in range(len(F)):
        a1=max(0,i-1);b1=min(len(F),i+2);F2[i]=np.bincount(F[a1:b1]).argmax()
    lines_out[key]={'pts':[[round(float(x),1),round(float(z),1)] for x,z in C2],'flags':[int(f) for f in F2]}
    print(key,'pts',len(C2),'len',round(len(C2)*10),'bridge',int((F2==1).sum()),'tunnel',int((F2==2).sum()),[(r[0],r[4]) for r in res if not r[4]],flush=True)
# ---------- buildings ----------
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
CORES=[(L(35.3389,139.4874),380),(L(35.3365,139.4473),260),(L(35.3961,139.4669),280),(L(35.3540,139.5313),330),(L(35.3306,139.4073),260)]
KIND={'house':0,'detached':0,'residential':1,'apartments':1,'terrace':1,'dormitory':1,'commercial':2,'retail':2,'office':2,'hotel':2,'supermarket':2,'industrial':3,'warehouse':3,'factory':3,'school':4,'university':4,'college':4,'kindergarten':4,'hospital':4,'public':4,'civic':4,'government':4,'train_station':4,'transportation':4,'shrine':5,'temple':5,'church':5,'religious':5,'garage':6,'garages':6,'shed':6,'hut':6,'carport':6,'roof':7,'greenhouse':8,'parking':3,'stadium':4,'sports_hall':4}
def hh(x):  # stable hash 0..1
    x=int(x)&0xffffffff;x=((x>>16)^x)*0x45d9f3b&0xffffffff;x=((x>>16)^x)*0x45d9f3b&0xffffffff;x=(x>>16)^x;return (x&0xffff)/65535
blds=[]
def add_building(bid,tg,p):
    if tg.get('building')=='no' or tg.get('building:part'): return
    if tg.get('location')=='underground' or (num(tg.get('layer')) or 0)<0: return
    a,cx,cz=area_xy(p);A=abs(a)
    if A<8: return
    if a<0: p=p[::-1]
    q=dp(p[:-1]+[p[0]],0.35)[:-1]
    if len(q)<3: return
    if len(q)>250: q=q[::max(1,len(q)//250)]
    bt=tg.get('building','yes');kind=KIND.get(bt,9)
    h=num(tg.get('height'));lv=num(tg.get('building:levels'))
    r=hh(bid)
    incore=any(math.hypot(cx-c[0][0],cz-c[0][1])<c[1] for c in CORES)
    if h is None and lv is not None: h=lv*3.2+0.6
    if h is None:
        if kind==6: h=3+r
        elif kind==7: h=5
        elif kind==8: h=3.2
        elif kind==5: h=8+4*r
        elif kind==0: h=6.2+r*1.2
        elif kind==3: h=8+6*r
        elif kind==4: h=12+6*r
        elif A<90: h=5.6+r*1.4
        elif A<220: h=6.4+r*1.6 if not incore else 9+r*12
        elif A<600: h=(9+r*6) if not incore else 16+r*22
        elif A<2500: h=(11+r*8) if not incore else 22+r*26
        else: h=14+r*8 if not incore else 24+r*20
    h=max(2.5,min(h,180))
    minh=num(tg.get('min_height'))
    if minh is None and tg.get('building:min_level') is not None: minh=(num(tg.get('building:min_level')) or 0)*3.2
    roof=0
    if kind in(0,1,9) and A<230 and h<=9.5 and tg.get('roof:shape') not in('flat',): roof=1
    if tg.get('roof:shape') in('gabled','hipped'): roof=1
    if kind==5 and A<900: roof=1
    if kind==7: roof=2
    blds.append((cx,cz,q,h,minh or 0,roof,kind,bid,A,tg.get('name')))
for wid,(tg,refs) in ways.items():
    if tg and 'building' in tg and len(refs)>=4 and refs[0]==refs[-1]:
        p=wpts(refs)
        if p: add_building(wid,tg,p)
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
        if cur[0]==cur[-1] and len(cur)>=4: rings.append(cur)
    return rings
for rid,(tg,mem) in rels.items():
    if tg.get('type')=='multipolygon' and 'building' in tg:
        for r in rings_from_rel(mem):
            p=wpts(r)
            if p: add_building(rid*7+len(r),tg,p)
print('buildings',len(blds),collections.Counter(b[6] for b in blds),flush=True)

# ---------- roads ----------
RC={'motorway':1,'trunk':1,'motorway_link':1,'trunk_link':1,'primary':2,'primary_link':2,'secondary':3,'secondary_link':3,'tertiary':4,'tertiary_link':4,'unclassified':5,'residential':5,'living_street':6,'service':6,'pedestrian':7,'footway':8,'path':8,'cycleway':8,'steps':8,'track':8,'bridleway':8}
DW={1:16,2:13,3:10,4:8,5:5,6:4,7:5,8:2.2}
roads=[];names=['']
nidx={}
for wid,(tg,refs) in ways.items():
    if not tg or 'highway' not in tg or tg.get('area')=='yes': continue
    c=RC.get(tg['highway'])
    if not c: continue
    if tg['highway']=='service' and tg.get('service') in('parking_aisle','driveway'): c=6
    p=wpts(refs)
    if not p or len(p)<2: continue
    w=num(tg.get('width'))
    if w is None:
        ln=num(tg.get('lanes'));w=(ln*3.1+1.5) if ln and c<=5 else DW[c]
    w=max(1.5,min(w,40))
    fl=(1 if tg.get('bridge') in('yes','viaduct','boardwalk') else 0)|(2 if tg.get('tunnel') in('yes','building_passage') else 0)|(4 if tg['highway']=='steps' else 0)
    nm=tg.get('name') or tg.get('ref') or ''
    if c>4: nm=''
    if nm and nm not in nidx: nidx[nm]=len(names);names.append(nm)
    q=dp(p,0.3) if len(p)>2 else p
    roads.append((c,fl,int(num(tg.get('layer')) or 0),nidx.get(nm,0),w,q))
print('roads',len(roads),collections.Counter(r[0] for r in roads),flush=True)

# ---------- landmarks by name ----------
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
            if d<2500 and (best is None or d<best[0]): best=(d,pt,nm)
    if best is None:
        for nm2,pts2 in named.items():
            if any(c in nm2 for c in cands):
                for pt in pts2:
                    d=math.hypot(pt[0]-rx,pt[1]-rz)
                    if d<2500 and (best is None or d<best[0]): best=(d,pt,nm2)
    LMK[key]=[round(best[1][0],1),round(best[1][1],1)] if best else None
    print('LM',key,best[2] if best else None,round(best[0]) if best else None)

# ---------- LOD cells (40 m) ----------
LG=40;LNX=math.ceil((X1-X0)/LG);LNZ=math.ceil((Z1-Z0)/LG)
cov=np.zeros((LNZ,LNX));hs=np.zeros((LNZ,LNX))
for b in blds:
    i=int((b[0]-X0)//LG);j=int((b[1]-Z0)//LG)
    if 0<=i<LNX and 0<=j<LNZ: cov[j,i]+=b[8];hs[j,i]+=b[8]*b[3]
hav=np.where(cov>0,hs/np.maximum(cov,1),0)
lodc=np.clip(np.sqrt(np.minimum(cov/(LG*LG),1))*255,0,255).astype(np.uint8)
lodh=np.clip(hav,0,255).astype(np.uint8)

# ---------- write binary ----------
out=bytearray()
def align():
    while len(out)%4: out.append(0)
sec={}
def put(name,b):
    align();sec[name]=[len(out),len(b)];out.extend(b)
q=np.round(dem*5).astype(np.int32);pred=np.zeros_like(q);pred[1:,1:]=q[1:,:-1]+q[:-1,1:]-q[:-1,:-1];pred[0,1:]=q[0,:-1];pred[1:,0]=q[:-1,0]
r=(q-pred).astype(np.int16);put('dem',(r&0xff).astype(np.uint8).tobytes()+((r>>8)&0xff).astype(np.uint8).tobytes())
put('lc',lc.astype(np.uint8).tobytes())
put('lodc',lodc.tobytes());put('lodh',lodh.tobytes())
# buildings per chunk
chunks=[[] for _ in range(CNX*CNZ)]
for b in blds:
    i=int((b[0]-X0)//CH);j=int((b[1]-Z0)//CH)
    if 0<=i<CNX and 0<=j<CNZ: chunks[j*CNX+i].append(b)
bb=bytearray();offs=[]
for ci,lst in enumerate(chunks):
    offs.append(len(bb));i=ci%CNX;j=ci//CNX;ox=X0+i*CH;oz=Z0+j*CH
    for (cx,cz,q,h,minh,roof,kind,bid,A,nm) in lst:
        P=[(int(round((x-ox)*4)),int(round((z-oz)*4))) for x,z in q]
        Q=[P[0]]
        for a1,b1 in zip(P,P[1:]+[P[0]]):
            dx=b1[0]-a1[0];dz=b1[1]-a1[1];k=max(1,math.ceil(max(abs(dx),abs(dz))/127))
            for t in range(1,k+1): Q.append((a1[0]+round(dx*t/k),a1[1]+round(dz*t/k)))
        Q=Q[:-1]
        if len(Q)>255 or len(Q)<3: continue
        bb+=struct.pack('<BBHBhh',len(Q),roof|(kind<<2),int(round(min(h,6500)*10)),int(round(min(minh,255))),Q[0][0],Q[0][1])
        for a1,b1 in zip(Q[:-1],Q[1:]): bb+=struct.pack('<bb',b1[0]-a1[0],b1[1]-a1[1])
offs.append(len(bb))
put('boffs',np.array(offs,np.uint32).tobytes());put('blds',bytes(bb))
rb=bytearray()
CX=(X0+X1)/2;CZ=(Z0+Z1)/2
for c,fl,layer,ni,w,q in roads:
    rb+=struct.pack('<BBbBHH',c,fl,max(-8,min(7,layer)),int(round(w*5)),ni,len(q))
    for x,z in q: rb+=struct.pack('<hh',int(round((x-CX)*2)),int(round((z-CZ)*2)))
put('roads',bytes(rb))
put('coast',np.round(coast[::2]).astype(np.float32).tobytes())
meta={'grid':[NX,NZ,G,X0,Z0],'lod':[LNX,LNZ,LG],'chunk':[CH,CNX,CNZ],'roadOrigin':[CX,CZ],'nroads':len(roads),'names':names,'lines':lines_out,'stations':ST,'landmarks':LMK,'sections':sec}
mj=json.dumps(meta,ensure_ascii=False,separators=(',',':')).encode('utf-8')
blob=struct.pack('<4sI',b'FJSW',len(mj))+mj
while len(blob)%4: blob+=b' '
# fix offsets relative to after header
final=blob+bytes(out)
hdr=len(blob)
meta['hdr']=hdr
open(os.path.join(SP,'fujisawa-data.bin'),'wb').write(gzip.compress(final,9))
print('raw',len(final),'gz',os.path.getsize(os.path.join(SP,'fujisawa-data.bin')),'hdr',hdr,{k:v[1] for k,v in sec.items()})
