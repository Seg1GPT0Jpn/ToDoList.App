import rzip,sys,os
from places import *
U={'f':"https://assets.cms.plateau.reearth.io/assets/f6/937d63-b787-4319-a5a5-bedcafde2cc7/14205_fujisawa-shi_city_2025_citygml_1_op.zip",
   'y':"https://assets.cms.plateau.reearth.io/assets/04/96d45a-a30b-4c9f-88c0-c1323b5a0f86/14100_yokohama-shi_city_2024_citygml_2_op.zip"}
want={'f':set(sys.argv[1].split(',')) if len(sys.argv)>1 else set(),'y':set()}
for k,v in PLACES.items():
    if v[4] in want: want[v[4]]|=meshes(v[1],v[2],v[3])
for c,u in U.items():
    z=rzip.open_zip(u)
    for i in z.infolist():
        if i.filename.startswith('udx/bldg/') and i.filename.endswith('.gml'):
            m=i.filename.split('/')[-1][:8]
            if m in want[c] and not os.path.exists('gml/'+c+m+'.gml'):
                open('gml/'+c+m+'.gml','wb').write(z.read(i));print(c,m,i.file_size,flush=True)
