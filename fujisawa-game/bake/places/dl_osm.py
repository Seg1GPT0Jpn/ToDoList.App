import os,subprocess,time,math,sys
UA="fujisawa-3d-builder/1.0 (personal hobby project)"
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
boxes=[(35.372,139.432,35.408,139.492),(35.333,139.463,35.356,139.496),(35.457,139.608,35.474,139.635),(35.394,139.524,35.408,139.545),(35.462,139.450,35.478,139.472),(35.402,139.586,35.416,139.606)]
cells=set()
for la0,lo0,la1,lo1 in boxes:
    for cy in range(math.floor(la0/0.005),math.floor(la1/0.005)+1):
        for cx in range(math.floor(lo0/0.005),math.floor(lo1/0.005)+1): cells.add((cx,cy))
print(len(cells),flush=True)
for i,(cx,cy) in enumerate(sorted(cells)):
    get((cx*0.005,cy*0.005,cx*0.005+0.005,cy*0.005+0.005),"osm/p_%d_%d.xml"%(cx,cy));time.sleep(0.2)
print("ALL DONE",flush=True)
