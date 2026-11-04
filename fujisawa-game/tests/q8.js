(async()=>{const D=window.__dbg;let bad=0,ex=[];const t0=performance.now();
// verify: no two runs on same line+direction overlap in position while either is moving
const byL=new Map();
for(let t=6*3600;t<23*3600;t+=15){const act=D.RUNS.filter(r=>r.tStart<=t&&r.tEnd>=t);const g=new Map();
 for(const r of act){const st=D.runState(r,t);const k=st.l.key+st.d;if(!g.has(k))g.set(k,[]);g.get(k).push([r,st]);}
 for(const [k,a] of g){for(let i=0;i<a.length;i++)for(let j=i+1;j<a.length;j++){const [r1,s1]=a[i],[r2,s2]=a[j];const len=(r1.spec.n*r1.spec.len+r2.spec.n*r2.spec.len)/2;if((s1.dwell&&s1.e.pass!==undefined)||(s2.dwell&&s2.e.pass!==undefined))continue;if(Math.abs(s1.s-s2.s)<len-5){bad++;if(ex.length<8)ex.push(`${k} ${Math.floor(t/3600)}:${Math.floor(t%3600/60)} ${r1.type}${r1.dest} ${r2.type}${r2.dest} ${s1.dwell?'D':'M'}${s2.dwell?'D':'M'} ${s1.name||''}${s2.name||''} ds=${(s1.s-s2.s).toFixed(0)}`);}}}}
return 'overlaps(sample×15s)='+bad+'\n'+ex.join('\n');})()
