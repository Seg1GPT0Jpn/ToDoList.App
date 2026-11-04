import json,os,subprocess,time,math
st=json.load(open('ext_stations.json'))
UA="fujisawa-3d-builder/1.0 (personal hobby project)"
def inside(la,lo): return 35.290<=la<=35.431 and 139.389<=lo<=139.541
def get(b,fn,depth=0):
    if os.path.exists(fn) and os.path.getsize(fn)>100: return
    url="https://api.openstreetmap.org/api/0.6/map?bbox=%.4f,%.4f,%.4f,%.4f"%b
    for a in range(4):
        r=subprocess.run(["curl","-sS","-m","300","-A",UA,"-o",fn+".part","-w","%{http_code}",url],capture_output=True,text=True);code=r.stdout.strip()
        if code=="200": os.rename(fn+".part",fn);return
        if code in("400","509") and depth<3:
            x0,y0,x1,y1=b;xm=(x0+x1)/2;ym=(y0+y1)/2
            for k,bb in enumerate([(x0,y0,xm,ym),(xm,y0,x1,ym),(x0,ym,xm,y1),(xm,ym,x1,y1)]): get(bb,fn.replace(".xml","_%d.xml"%k),depth+1)
            open(fn,"w").write("<split/>");return
        time.sleep(5*(a+1))
    print("FAIL",b,flush=True)
# tile grid of 0.005 deg, union of cells within 650 m of any outside station
cells=set()
for nm,(la,lo) in st.items():
    if inside(la,lo): continue
    for dla in range(-2,3):
        for dlo in range(-2,3):
            la2=la+dla*0.0029;lo2=lo+dlo*0.0036
            if math.hypot(dla*0.0029*111000,dlo*0.0036*90800)<700 and not inside(la2,lo2): cells.add((math.floor(lo2/0.005),math.floor(la2/0.005)))
print(len(cells),flush=True)
for i,(cx,cy) in enumerate(sorted(cells)):
    get((cx*0.005,cy*0.005,cx*0.005+0.005,cy*0.005+0.005),"s_%d_%d.xml"%(cx,cy));time.sleep(0.3)
    if i%20==0: print('done',i,flush=True)
print("ALL DONE",flush=True)
