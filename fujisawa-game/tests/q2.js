(async()=>{const D=window.__dbg;const res=[];const P=D.P;
for(const S of D.STATIONS){const l=S.l,name=S.st[0];
  for(const dirWant of [1,-1]){
  // find a run stopping here moving in that direction
  let run=null,ev=null;for(const r of D.RUNS){if(r.tStart<10*3600)continue;for(const e of r.tl){if(e.k==='dwell'&&e.name===name&&e.l===l&&!e.last&&e.d===dirWant){run=r;ev=e;break;}}if(run)break;}
  if(!run){for(const r of D.RUNS){if(r.tStart<10*3600)continue;for(const e of r.tl){if(e.k==='dwell'&&e.name===name&&e.l===l&&e.d===dirWant){run=r;ev=e;break;}}if(run)break;}}
  if(!run){res.push([l.key,name,dirWant,'NO RUN']);continue;}
  D.setClock(ev.t0+3);D.updateTrains();
  const ps=run.poses[Math.floor(run.poses.length/2)];
  D.warp(ps.x,ps.z);D.updateChunks(ps.x,ps.z,6);D.updateChunks(ps.x,ps.z,6);
  D.board(run,Math.floor(run.poses.length/2));D.updateTrains();
  const b=D.alight();
  const y=P.y;const top=ps.y+1.1;
  // try boarding back from where we stand
  D.update(0.016);const fb=D.findBoardable();
  res.push([l.key,name,dirWant,run.type,(y-ps.y).toFixed(2),b.ok?'side':'plat', fb&&fb.r===run?'reboard':'NOBOARD']);
  }}
return res.map(r=>r.join(' ')).join('\n');})()
