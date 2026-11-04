(async()=>{const D=window.__dbg;const out=[];
const t=12*3600;for(const n of ['藤沢','湘南台','長後','善行']){out.push(n+': '+D.departures(n,t,8).map(o=>require=`${Math.floor(o.dep/3600)}:${String(Math.floor(o.dep%3600/60)).padStart(2,'0')} ${o.type} ${o.dest} (${o.line}, 次${o.via})`).join(' | '));}
// ride a 快速急行 from 藤沢 and log the stations where speed=0
const r=D.RUNS.find(r=>r.type==='快速急行'&&r.dest==='新宿'&&r.tStart>t);const seen=[];let last=null;
for(let tt=r.tStart;tt<r.tEnd;tt+=5){const s=D.runState(r,tt);if(s.dwell&&s.name!==last){seen.push(s.name+'@'+Math.floor(tt%3600/60));last=s.name;}if(!s.dwell)last=null;}
out.push('快速急行: '+seen.join(' → '));
const r2=D.RUNS.find(r=>r.type==='ロマンスカー'&&r.dest==='新宿');const seen2=[];last=null;for(let tt=r2.tStart;tt<r2.tEnd;tt+=5){const s=D.runState(r2,tt);if(s.dwell&&s.name!==last){seen2.push(s.name);last=s.name;}if(!s.dwell)last=null;}out.push('RC: '+seen2.join(' → ')+'  '+((r2.tEnd-r2.tStart)/60).toFixed(0)+'min');
return out.join('\n');})()
