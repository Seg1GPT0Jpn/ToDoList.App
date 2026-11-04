p='bake/bake3.py';s=open(p).read()
def R(a,b):
    global s
    assert a in s,a[:80];s=s.replace(a,b,1)
R("    blds.append((cx,cz,q,h,minh or 0,roof,kind,bid,A,tg.get('name')))","    blds.append([cx,cz,q,h,minh or 0,roof,kind,bid,A,tg.get('name'),gc,(num(tg.get('height')) is not None or lv is not None),lv])")
R("print('gsi match',GC_STATS.most_common());","""# --- post pass: consistent heights inside apartment complexes, calibration from tagged neighbours ---
CPX=[];CG=collections.defaultdict(list)
for wid,(tg,refs) in ways.items():
    if tg and tg.get('landuse')=='residential' and (tg.get('name') or tg.get('residential')=='apartments') and len(refs)>=4 and refs[0]==refs[-1]:
        pp=wpts(refs)
        if not pp: continue
        xs=[t[0] for t in pp];zs=[t[1] for t in pp];k=len(CPX);CPX.append((pp,min(xs),max(xs),min(zs),max(zs)))
        for i in range(int(min(xs)//100),int(max(xs)//100)+1):
            for j in range(int(min(zs)//100),int(max(zs)//100)+1): CG[(i,j)].append(k)
TAG=collections.defaultdict(list)
for b in blds:
    if b[11] and b[12] and b[10]==3102: TAG[(int(b[0]//250),int(b[1]//250))].append(b[12])
groups=collections.defaultdict(list)
for b in blds:
    if b[11] or b[10] not in(3102,3103): continue
    cx,cz=b[0],b[1]
    for k in CG.get((int(cx//100),int(cz//100)),[]):
        pp,x0,x1,z0,z1=CPX[k]
        if x0<=cx<=x1 and z0<=cz<=z1 and pip(cx,cz,pp): groups[k].append(b);break
    else:
        lv=[]
        for i in range(int(cx//250)-1,int(cx//250)+2):
            for j in range(int(cz//250)-1,int(cz//250)+2): lv+=TAG.get((i,j),[])
        if len(lv)>=3 and b[8]>150:
            med=sorted(lv)[len(lv)//2];b[3]=max(b[3]*0.4+ (med*3.2+0.6)*0.6,7.5)
for k,g in groups.items():
    big=[b for b in g if b[8]>=250 and b[10]==3102]
    if not big: continue
    hs=sorted(b[3] for b in big);med=hs[len(hs)//2]
    # complexes: slabs share a height; tall towers (3103) stay tall
    floors=max(4,round((med-0.6)/3.0))
    for b in big: b[3]=floors*3.0+0.6+(hash(b[7])%3-1)*0.0
print('complexes',len(groups))
print('gsi match',GC_STATS.most_common());""")
R("    for (cx,cz,q,h,minh,roof,kind,bid,A,nm) in lst:","    for (cx,cz,q,h,minh,roof,kind,bid,A,nm,*_rest) in lst:")
R("for b in blds:\n    i=int((b[0]-X0)//LG)","for b in blds:\n    i=int((b[0]-X0)//LG)")
open(p,'w').write(s);print('ok')
