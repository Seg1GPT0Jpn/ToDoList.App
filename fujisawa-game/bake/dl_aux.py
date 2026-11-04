import json,os,subprocess,math,concurrent.futures as cf
st=json.load(open('ext/ext_stations.json'))
def tile(lat,lon,z):
    n=2**z;x=(lon+180)/360*n;r=math.radians(lat);y=(1-math.log(math.tan(r)+1/math.cos(r))/math.pi)/2*n;return int(x),int(y)
def inside(la,lo): return 35.290<=la<=35.431 and 139.389<=lo<=139.541
jobs=[]
# coarse DEM (z14) over the whole extended area
x0,y0=tile(35.55,139.36,14);x1,y1=tile(35.27,139.65,14)
for x in range(x0,x1+1):
    for y in range(y0,y1+1): jobs.append(('dem/dem_png_%d_%d.png'%(x,y),'https://cyberjapandata.gsi.go.jp/xyz/dem_png/14/%d/%d.png'%(x,y)))
t15=set();t16=set()
for nm,(la,lo) in st.items():
    if inside(la,lo): continue
    for dla in (-0.007,0,0.007):
        for dlo in (-0.008,0,0.008):
            t15.add(tile(la+dla,lo+dlo,15));t16.add(tile(la+dla,lo+dlo,16))
            for e in (-0.0035,0.0035):
                t16.add(tile(la+dla+e,lo+dlo+e,16));t16.add(tile(la+dla-e,lo+dlo+e,16))
for x,y in t15:
    for k in ('dem5a_png','dem5b_png'): jobs.append(('dem/%s_%d_%d.png'%(k,x,y),'https://cyberjapandata.gsi.go.jp/xyz/%s/15/%d/%d.png'%(k,x,y)))
for x,y in t16: jobs.append(('gsiv/%d_%d.pbf'%(x,y),'https://cyberjapandata.gsi.go.jp/xyz/experimental_bvmap/16/%d/%d.pbf'%(x,y)))
jobs=[j for j in jobs if not os.path.exists(j[0])]
print(len(jobs),flush=True)
def get(j):
    fn,u=j;r=subprocess.run(['curl','-sS','-m','60','-o',fn,'-w','%{http_code}',u],capture_output=True,text=True)
    if r.stdout.strip()!='200' and os.path.exists(fn): os.remove(fn)
with cf.ThreadPoolExecutor(4) as ex: list(ex.map(get,jobs))
print('DONE',flush=True)
