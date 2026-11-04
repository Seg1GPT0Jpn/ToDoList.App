# Parse all downloaded OSM tiles into a compact pickle: nodes (x,z), ways (tags, refs), relations.
import glob, pickle, sys, os
import xml.etree.ElementTree as ET
LAT0,LON0,MX,MZ=35.3389,139.4874,90807,110940
OSM=sys.argv[1]; OUT=sys.argv[2]
KEEP_W=('building','highway','railway','landuse','natural','leisure','waterway','water','amenity','public_transport','man_made','tourism','historic','place','bridge')
nodes={}; ways={}; rels={}; pois=[]
files=[f for f in sorted(glob.glob(os.path.join(OSM,'t_*.xml'))) if os.path.getsize(f)>200]
for fi,f in enumerate(files):
    for ev,el in ET.iterparse(f):
        t=el.tag
        if t=='node':
            i=int(el.get('id'))
            if i not in nodes:
                lat=float(el.get('lat'));lon=float(el.get('lon'))
                nodes[i]=((lon-LON0)*MX,-(lat-LAT0)*MZ)
            tg={c.get('k'):c.get('v') for c in el.findall('tag')}
            if 'name' in tg and (tg.get('railway') in ('station','halt') or tg.get('public_transport')=='station' or 'tourism' in tg or 'historic' in tg or 'amenity' in tg or 'leisure' in tg or 'natural' in tg or 'man_made' in tg):
                pois.append((i,tg))
            el.clear()
        elif t=='way':
            i=int(el.get('id'))
            if i not in ways:
                tg={c.get('k'):c.get('v') for c in el.findall('tag')}
                if any(k in tg for k in KEEP_W) or 'name' in tg:
                    ways[i]=(tg,[int(n.get('ref')) for n in el.findall('nd')])
                else:
                    ways[i]=(None,[int(n.get('ref')) for n in el.findall('nd')])
            el.clear()
        elif t=='relation':
            i=int(el.get('id'))
            tg={c.get('k'):c.get('v') for c in el.findall('tag')}
            mem=[(m.get('type'),int(m.get('ref')),m.get('role')) for m in el.findall('member')]
            if i not in rels: rels[i]=(tg,mem)
            else:
                # merge members (map call may return partial relation per tile? keep longest)
                if len(mem)>len(rels[i][1]): rels[i]=(tg,mem)
            el.clear()
    if fi%20==0: print(fi,len(files),len(nodes),len(ways),flush=True)
pickle.dump({'nodes':nodes,'ways':ways,'rels':rels,'pois':pois},open(OUT,'wb'),protocol=4)
print('nodes',len(nodes),'ways',len(ways),'rels',len(rels),'pois',len(pois))
