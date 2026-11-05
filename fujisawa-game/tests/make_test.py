# index.html にデバッグ用フック window.__dbg を足した tests/test.html を作る（公開版には入れない）
import os
d=os.path.dirname(os.path.abspath(__file__))
s=open(os.path.join(d,'..','index.html'),encoding='utf-8').read()
hook="window.__dbg={P,cam,RUNS,ACTIVE,STATIONS,PLATBUILT,LINES,ZONES,ENTRANCES,INDOOR,CHUNKS,warp,doAct,board,alight,updateTrains,update,updateChunks,standY,findBoardable,findEntrance,nowT,departures,runState,zoneAt,indoorAt,camera,setClock:t=>{CLOCK=t},getClock:()=>CLOCK,META,heightAt,groundAt,updateStationBoard,renderer,setTime:i=>{timeIdx=i;timeT=1;fromT=null;applyTime(0.01);},HOLES,passOff,stationTracks,TRACKS,PLATS,ROADS};"
s=s.replace("$('loading').hidden=true;started=true;","$('loading').hidden=true;started=true;"+hook,1)
open(os.path.join(d,'test.html'),'w',encoding='utf-8').write(s);print('tests/test.html')
