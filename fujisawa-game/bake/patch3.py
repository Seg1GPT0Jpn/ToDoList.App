p='bake/bake3.py';s=open(p).read()
def R(a,b):
    global s
    assert a in s,a[:80];s=s.replace(a,b,1)
# ---- GSI building classes ----
R("blds=[]\n","""blds=[]
import glob as _g
import mapbox_vector_tile as MVT
GSI=collections.defaultdict(list);GPOLY=[]
for f in _g.glob(os.path.join(SP,'gsiv','*.pbf')):
    tx,ty=map(int,os.path.basename(f)[:-4].split('_'))
    try: d=MVT.decode(open(f,'rb').read(),default_options={'y_coord_down':True})
    except Exception: continue
    lay=d.get('building')
    if not lay: continue
    ext=lay.get('extent',4096);n=2**16
    def toW(px,py):
        lon=(tx+px/ext)/n*360-180;lat=math.degrees(math.atan(math.sinh(math.pi*(1-2*(ty+py/ext)/n))));return L(lat,lon)
    for ft in lay['features']:
        code=ft['properties'].get('ftCode');g=ft['geometry']
        polys=[g['coordinates']] if g['type']=='Polygon' else (g['coordinates'] if g['type']=='MultiPolygon' else [])
        for poly in polys:
            ring=[toW(x,y) for x,y in poly[0]]
            if len(ring)<3: continue
            xs=[q[0] for q in ring];zs=[q[1] for q in ring]
            idx=len(GPOLY);GPOLY.append((code,ring,min(xs),max(xs),min(zs),max(zs)))
            for i in range(int(min(xs)//50),int(max(xs)//50)+1):
                for j in range(int(min(zs)//50),int(max(zs)//50)+1): GSI[(i,j)].append(idx)
print('gsi polys',len(GPOLY),collections.Counter(g[0] for g in GPOLY),flush=True)
def pip(x,z,r):
    c=False;n=len(r)
    for i in range(n):
        ax,az=r[i];bx,bz=r[i-1]
        if (az>z)!=(bz>z) and x<(bx-ax)*(z-az)/(bz-az)+ax: c=not c
    return c
def gsi_code(cx,cz,q):
    cand=GSI.get((int(cx//50),int(cz//50)),[]);best=None
    for i in cand:
        code,ring,x0,x1,z0,z1=GPOLY[i]
        if x0-1<=cx<=x1+1 and z0-1<=cz<=z1+1 and pip(cx,cz,ring): return code
    # vote by vertices inside
    votes=collections.Counter()
    for x,z in q[::max(1,len(q)//6)]:
        for i in GSI.get((int(x//50),int(z//50)),[]):
            code,ring,x0,x1,z0,z1=GPOLY[i]
            if x0<=x<=x1 and z0<=z<=z1 and pip(x,z,ring): votes[code]+=1
    return votes.most_common(1)[0][0] if votes else None
GC_STATS=collections.Counter()
""")
R("""    incore=any(math.hypot(cx-c[0][0],cz-c[0][1])<c[1] for c in CORES)
    if h is None and lv is not None: h=lv*3.2+0.6
    if h is None:""","""    incore=any(math.hypot(cx-c[0][0],cz-c[0][1])<c[1] for c in CORES)
    if h is None and lv is not None: h=lv*3.2+0.6
    gc=gsi_code(cx,cz,q);GC_STATS[gc]+=1
    # footprint elongation (slab apartments are long and thin)
    xs=[t[0] for t in q];zs=[t[1] for t in q]
    ext=max(max(xs)-min(xs),max(zs)-min(zs),1)
    if h is None and gc is not None and kind not in(5,7,8):
        if gc==3103: h=45+min(A,2500)/2500*25+r*8
        elif gc==3102:
            if A<100: h=7.5+r*2
            elif A<300: h=9.5+r*4+(4 if incore else 0)
            elif A<900: h=(12+r*10) if not incore else 16+r*20
            elif A<3000: h=(14+r*12) if not incore else 20+r*22
            else: h=11+r*8
            if kind==3: h=min(h,9+r*6)
        elif gc==3101:
            h=3.5+r if A<40 else (6.0+r*1.3 if A<260 else (7.5+r*2 if A<800 else 9+r*3))
        elif gc in(3111,3112): h=3.6 if gc==3111 else 5;kind=7
    if h is None:""")
R("    blds.append((cx,cz,q,h,minh or 0,roof,kind,bid,A,tg.get('name')))","""    if gc in(3102,3103) and kind in(0,9) and h>8: kind=1 if kind==0 else kind
    if gc in(3102,3103) and roof==1 and kind!=5: roof=0
    if gc in(3111,3112) and kind==7: roof=2
    blds.append((cx,cz,q,h,minh or 0,roof,kind,bid,A,tg.get('name')))""")
R("print('buildings',len(blds)","print('gsi match',GC_STATS.most_common());print('buildings',len(blds)")
# ---- lane offsets per sample from the real tracks ----
R("    lines_out[key]={'pts':[[round(float(x),1),round(float(z),1)] for x,z in C2],'flags':[int(f) for f in F2]}","""    single=key in('eno','mono');OFF=[]
    for i in range(len(C2)):
        j=min(i+1,len(C2)-1);h=max(i-1,0);tx,tz=C2[j]-C2[h];l=math.hypot(tx,tz) or 1;tx/=l;tz/=l;nx,nz=-tz,tx
        x,z=C2[i];cand=[]
        for a1 in range(int(x//20)-1,int(x//20)+2):
            for b1 in range(int(z//20)-1,int(z//20)+2): cand+=gh2.get((a1,b1),[])
        lo=None;hi=None
        if cand:
            c=AP[cand];dx=c[:,0]-x;dz=c[:,1]-z;al=dx*tx+dz*tz;of=dx*nx+dz*nz;par=np.abs(c[:,2]*tx+c[:,3]*tz)>0.85
            m=par&(np.abs(al)<3)&(np.abs(of)<7.5)
            o=of[m]
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
    lines_out[key]={'pts':[[round(float(x),1),round(float(z),1)] for x,z in C2],'flags':[int(f) for f in F2],'offs':[[round(float(a),2),round(float(b),2)] for a,b in O3]}""")
# ---- platforms & tracks export ----
R("# ---------- landmarks by name ----------","""# ---------- platforms ----------
RPG=collections.defaultdict(list)
for wid,tg,p in railways:
    for x,z in p[::2]: RPG[(int(x//30),int(z//30))].append((x,z))
def near_rail(x,z,r=25):
    for i in range(int(x//30)-1,int(x//30)+2):
        for j in range(int(z//30)-1,int(z//30)+2):
            for a,b in RPG.get((i,j),[]):
                if abs(a-x)<r and abs(b-z)<r: return True
    return False
plats=[]
def isplat(tg): return tg and (tg.get('railway')=='platform' or (tg.get('public_transport')=='platform' and tg.get('bus')!='yes' and tg.get('highway')!='platform' and (tg.get('train')=='yes' or tg.get('railway')=='platform' or tg.get('monorail')=='yes' or tg.get('light_rail')=='yes')))
def buffer_line(p,w):
    L2=[];R2=[]
    for i in range(len(p)):
        a=p[max(0,i-1)];b=p[min(len(p)-1,i+1)];dx=b[0]-a[0];dz=b[1]-a[1];l=math.hypot(dx,dz) or 1;nx,nz=-dz/l,dx/l
        L2.append((p[i][0]+nx*w,p[i][1]+nz*w));R2.append((p[i][0]-nx*w,p[i][1]-nz*w))
    return L2+R2[::-1]
for wid,(tg,refs) in ways.items():
    if not isplat(tg) or tg.get('area:highway'): continue
    p=wpts(refs)
    if not p or len(p)<2: continue
    if refs[0]==refs[-1] and len(p)>=4: poly=p[:-1]
    else:
        w=num(tg.get('width')) or 3.0;poly=buffer_line(p,w/2)
    cx=sum(q[0] for q in poly)/len(poly);cz=sum(q[1] for q in poly)/len(poly)
    if not near_rail(cx,cz,30): continue
    a,_,_=area_xy(poly+[poly[0]])
    if a<0: poly=poly[::-1]
    plats.append(dp(poly+[poly[0]],0.2)[:-1])
for rid,(tg,mem) in rels.items():
    if tg.get('type')=='multipolygon' and isplat(tg):
        for r in rings_from_rel(mem):
            p=wpts(r)
            if p:
                a,_,_=area_xy(p)
                plats.append((p[:-1] if a>0 else p[::-1][:-1]))
print('platforms',len(plats),flush=True)
tracks=[]
for wid,tg,p in railways:
    if tg.get('railway') in('rail','narrow_gauge','light_rail') and tg.get('tunnel') not in('yes','building_passage'):
        tracks.append((1 if tg.get('bridge') in('yes','viaduct') else 0,dp(p,0.15) if len(p)>2 else p))
print('tracks',len(tracks),flush=True)

# ---------- landmarks by name ----------""")
R("put('coast',","""pb=bytearray()
for poly in plats:
    if len(poly)<3 or len(poly)>2000: continue
    pb+=struct.pack('<H',len(poly))
    for x,z in poly: pb+=struct.pack('<hh',int(round((x-CX)*2)),int(round((z-CZ)*2)))
put('plats',bytes(pb))
tb=bytearray()
for fl,q in tracks:
    tb+=struct.pack('<BH',fl,len(q))
    for x,z in q: tb+=struct.pack('<hh',int(round((x-CX)*2)),int(round((z-CZ)*2)))
put('tracks',bytes(tb))
put('coast',""")
R("'nroads':len(roads),","'nroads':len(roads),'nplats':len([p for p in plats if 3<=len(p)<=2000]),'ntracks':len(tracks),")
open(p,'w').write(s);print('patched')
