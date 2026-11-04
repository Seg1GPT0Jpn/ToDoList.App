import math,os,subprocess,concurrent.futures as cf,sys,json
from places import PLACES
def tile(lat,lon,z):
    n=2**z;x=(lon+180)/360*n;r=math.radians(lat);y=(1-math.log(math.tan(r)+1/math.cos(r))/math.pi)/2*n;return x,y
extra=json.load(open('extra_places.json')) if os.path.exists('extra_places.json') else {}
P={**PLACES,**extra}
jobs=set()
for k,v in P.items():
    _,lat,lon,rad=v[:4];rad+=60
    x0,y0=tile(lat+rad/110940,lon-rad/90807,18);x1,y1=tile(lat-rad/110940,lon+rad/90807,18)
    for x in range(int(x0),int(x1)+1):
        for y in range(int(y0),int(y1)+1):jobs.add((x,y))
jobs=[j for j in jobs if not os.path.exists('photo/%d_%d.jpg'%j)]
print(len(jobs),flush=True)
def get(j):
    fn='photo/%d_%d.jpg'%j
    for a in range(3):
        r=subprocess.run(['curl','-sS','-m','60','-o',fn,'-w','%{http_code}','https://cyberjapandata.gsi.go.jp/xyz/seamlessphoto/18/%d/%d.jpg'%j],capture_output=True,text=True)
        if r.stdout.strip()=='200':return
    if os.path.exists(fn):os.remove(fn)
with cf.ThreadPoolExecutor(6) as ex:list(ex.map(get,jobs))
print('done',flush=True)
