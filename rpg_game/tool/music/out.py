import os; os.chdir(os.path.dirname(os.path.abspath(__file__))); exec(open('gen.py').read())
import json,random,re,os
import pathlib
ROOT=str(pathlib.Path(__file__).resolve().parents[2]/'assets/questions/music')+'/'
os.makedirs(ROOT,exist_ok=True)
ROUTES=[('fu','譜と音の道','up'),('chou','調と音階の道','left'),('waon','和音の道','right'),('yougo','音楽用語の道','down')]
def num(s):
    m=re.fullmatch(r'(-?\d+)(?:/(\d+))?',s)
    return None if not m else int(m[1])/(int(m[2]) if m[2] else 1)
counter={}
dart=[]
KNOWN=['slime','goblin','bat','ghost','eraser','crayon','sticky','pencil','stubpencil','pen','ruler','triangle','protractor','compass','stapler','marker','page','mechpencil','scissors','binder','book']
BOSS={'fu':'golem','chou':'dragon','waon':'knight','yougo':'dragon'}
for ri,(rid,_,_) in enumerate(ROUTES):
    i=0
    for r_,a,qs in AREAS:
        if r_!=rid: continue
        a['look']=BOSS[rid] if a['boss'] else KNOWN[(i*2+ri*5)%len(KNOWN)]
        i+=1
for rid,rname,rdir in ROUTES:
    areas=[(a,qs) for r,a,qs in AREAS if r==rid]
    for k,(a,qs) in enumerate(areas,1):
        sid=f'music_{rid}_{k:02d}'
        out=[]
        for n,q in enumerate(qs,1):
            qid=f'mus_{rid}{k:02d}_{n:03d}'
            ch=[q['a']]+q['w']; assert len(set(ch))==4,(qid,ch)
            o=ch[:]; random.Random(qid).shuffle(o)
            if all(num(x) is not None for x in ch): o=sorted(ch,key=num)
            d=dict(id=qid,category=CAT[q['c']],prompt=q['p'])
            if q['s']: d['sentence']=q['s']
            d.update(choices=o,answerIndex=o.index(q['a']),explanation=q['e'])
            out.append(d)
        json.dump(dict(setId=sid,worldId='music',origin='original',version=1,questions=out),open(ROOT+sid+'.json','w'),ensure_ascii=False,indent=2)
    dart.append((rid,rname,rdir,areas))
def s(x): return x.replace("\\","\\\\").replace("'","\\'")
L=["// このファイルは問題データと同時に自動生成しています（手で直すときは生成元も直す）。",
"// 番外編「音楽の虹」：楽典ミニテスト対策プリント（作成：瀬川 嘉寿馬）の範囲をもとにした問題。",
"import '../models/question.dart';","import '../models/stage.dart';","import 'route_world.dart';","",
"class MusicCatalog {","  const MusicCatalog._();","","  static const worldId = 'music';","","  static const routes = <RouteSpec>["]
for rid,rname,rdir,areas in dart:
    L.append("    RouteSpec(")
    L.append(f"      info: RouteInfo('{rid}', '{rname}', '{rdir}'),")
    L.append("      timeLimitSeconds: 25,")
    L.append("      secondary: QuestionCategory.thinking,")
    L.append("      areas: [")
    for a,_ in areas:
        L.append("        RouteArea(")
        for key in ['theme','section','place','enemy','look']:
            L.append(f"            {key}: '{s(a[key])}',")
        L.append(f"            color: 0x{a['color']:08X},")
        for key in ['description','intro','defeat']:
            L.append(f"            {key}: '{s(a[key])}',")
        if a['boss']: L.append("            boss: true,")
        L[-1]=L[-1].rstrip(',')+')' if False else L[-1]
        L.append("        ),")
    L.append("      ],")
    L.append("    ),")
L+=["  ];","","  static final stages = <StageDef>[...RouteWorldBuilder.build(worldId, routes)];","}",""]
open(str(pathlib.Path(__file__).resolve().parents[2]/'lib/src/data/music_catalog.dart'),'w').write('\n'.join(L))
print(len(os.listdir(ROOT)),'sets')
