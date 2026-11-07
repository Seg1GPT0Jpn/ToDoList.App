
/* ================= player (1.7 m tall) ================= */
const player=new THREE.Group();scene.add(player);
const limbs={};
(function makePlayer(){
  const skin=M('#f1c9a5'),shirt=M('#1fa39a'),pants=M('#2b3e5e'),capM=M('#ff8a3c'),dark=M('#1b1f24');
  const add=(geo,mat,x,y,z,sx=1,sy=1,sz=1,parent=player)=>{const m=new THREE.Mesh(geo,mat);m.position.set(x,y,z);m.scale.set(sx,sy,sz);m.castShadow=true;parent.add(m);return m;};
  add(new THREE.CapsuleGeometry(0.18,0.42,4,12),shirt,0,1.2,0,1.15,1,0.8);
  add(SPH,skin,0,1.6,0,0.24,0.27,0.25);
  add(new THREE.SphereGeometry(0.5,16,8,0,Math.PI*2,0,Math.PI/2),capM,0,1.66,0,0.26,0.2,0.27);
  add(new THREE.CylinderGeometry(0.5,0.5,0.03,16),capM,0,1.67,0.08,0.22,1,0.2);
  add(SPH,dark,-0.05,1.62,0.115,0.03,0.035,0.02);add(SPH,dark,0.05,1.62,0.115,0.03,0.035,0.02);
  for(const s of [-1,1]){const lg=new THREE.Group();lg.position.set(0.1*s,0.88,0);player.add(lg);add(new THREE.CapsuleGeometry(0.075,0.7,3,8),pants,0,-0.42,0,1,1,1,lg);add(BOX,M('#ffffff'),0,-0.88,0.04,0.12,0.08,0.26,lg);limbs['l'+s]=lg;
    const ar=new THREE.Group();ar.position.set(0.26*s,1.42,0);player.add(ar);add(new THREE.CapsuleGeometry(0.055,0.5,3,8),shirt,0,-0.3,0,1,1,1,ar);add(SPH,skin,0,-0.62,0,0.1,0.1,0.1,ar);limbs['a'+s]=ar;}
  const sh=add(new THREE.CircleGeometry(0.4,16).rotateX(-Math.PI/2),new THREE.MeshBasicMaterial({color:0x000000,transparent:true,opacity:0.18,depthWrite:false}),0,0.04,0);sh.castShadow=false;
})();
const P={x:0,y:5,z:0,vy:0,face:-0.1,onGround:false,fly:false,walk:0,swim:false,ride:null,view:0};
const cam={yaw:Math.PI-0.1,pitch:0.12,dist:4.6,tx:0,ty:0,tz:0};
let ff=1;

/* ================= input ================= */
const keys={};
addEventListener('keydown',e=>{keys[e.code]=true;if(e.repeat)return;
  if(e.code==='KeyF')toggleFly();if(e.code==='KeyT')cycleTime();if(e.code==='KeyM')toggleMap();if(e.code==='KeyH')$('help').hidden=!$('help').hidden;
  if(e.code==='KeyE')doAct();if(e.code==='KeyV')toggleView();if(e.code==='KeyX')toggleFF();
  if(e.code==='Escape'&&!$('mapOv').hidden)toggleMap();
  if(['Space','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code))e.preventDefault();});
addEventListener('keyup',e=>{keys[e.code]=false;});
addEventListener('blur',()=>{for(const k in keys)keys[k]=false;});
let drag=null;const joy={id:null,x:0,y:0,dx:0,dy:0};const pts=new Map();let pinch0=0,pinchDist=7;let touchDash=false,touchJump=false,touchDown=false;
canvas.addEventListener('pointerdown',e=>{canvas.focus();canvas.setPointerCapture(e.pointerId);
  if(e.pointerType==='touch'&&e.clientX<innerWidth*0.45&&joy.id===null&&!P.ride){joy.id=e.pointerId;joy.x=e.clientX;joy.y=e.clientY;joy.dx=joy.dy=0;const j=$('joy');j.hidden=false;j.style.left=e.clientX+'px';j.style.top=e.clientY+'px';j.firstChild.style.transform='';return;}
  pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
  if(pts.size===2){const a=[...pts.values()];pinch0=Math.hypot(a[0].x-a[1].x,a[0].y-a[1].y);pinchDist=cam.dist;drag=null;}
  else if(pts.size===1)drag={id:e.pointerId,x:e.clientX,y:e.clientY};});
canvas.addEventListener('pointermove',e=>{
  if(e.pointerId===joy.id){let dx=e.clientX-joy.x,dy=e.clientY-joy.y;const L0=Math.hypot(dx,dy),R=50;if(L0>R){dx*=R/L0;dy*=R/L0;}joy.dx=dx/R;joy.dy=dy/R;$('joy').firstChild.style.transform=`translate(${dx}px,${dy}px)`;return;}
  if(!pts.has(e.pointerId))return;pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
  if(pts.size===2&&pinch0){const a=[...pts.values()];const d=Math.hypot(a[0].x-a[1].x,a[0].y-a[1].y);cam.dist=clamp(pinchDist*pinch0/Math.max(d,1),1.5,600);return;}
  if(drag&&drag.id===e.pointerId){const dx=e.clientX-drag.x,dy=e.clientY-drag.y;drag.x=e.clientX;drag.y=e.clientY;cam.yaw-=dx*0.006;cam.pitch=clamp(cam.pitch+dy*0.005,-0.3,1.5);}});
const endPtr=e=>{if(e.pointerId===joy.id){joy.id=null;joy.dx=joy.dy=0;$('joy').hidden=true;}pts.delete(e.pointerId);if(pts.size<2)pinch0=0;if(drag&&drag.id===e.pointerId)drag=null;};
canvas.addEventListener('pointerup',endPtr);canvas.addEventListener('pointercancel',endPtr);
canvas.addEventListener('wheel',e=>{e.preventDefault();cam.dist=clamp(cam.dist*(1+Math.sign(e.deltaY)*0.12),1.5,600);},{passive:false});
const hold=(id,set)=>{const b=$(id);b.addEventListener('pointerdown',e=>{e.preventDefault();set(true);});for(const ev of ['pointerup','pointercancel','pointerleave'])b.addEventListener(ev,()=>set(false));};
hold('tJump',v=>touchJump=v);hold('tDown',v=>touchDown=v);
$('tDash').addEventListener('click',()=>{touchDash=!touchDash;$('tDash').classList.toggle('on',touchDash);});
$('bFly').addEventListener('click',toggleFly);$('bTime').addEventListener('click',cycleTime);$('bMap').addEventListener('click',toggleMap);$('bClose').addEventListener('click',toggleMap);
$('act').addEventListener('click',doAct);$('bView').addEventListener('click',toggleView);$('bFF').addEventListener('click',toggleFF);
$('bQual').textContent=QHIGH?'画質: 高':'画質: 軽';$('bQual').addEventListener('click',()=>{try{localStorage.setItem('fq',QHIGH?'l':'h');}catch(e){}location.reload();});
$('bHelp').addEventListener('click',()=>{$('help').hidden=!$('help').hidden;if(isTouch&&!$('help').hidden)toast('左側ドラッグで移動<small>右側ドラッグで視点・2本指でズーム</small>',3);});
if(isTouch){document.body.classList.add('touch');$('touchBtns').hidden=false;$('help').hidden=true;}

function toggleFly(){if(P.ride)return;P.fly=!P.fly;$('bFly').classList.toggle('on',P.fly);$('tDown').hidden=!P.fly;$('tJump').textContent=P.fly?'上昇':'ジャンプ';toast(P.fly?'飛行モード<small>SPACE 上昇 / C 下降 / SHIFT 高速</small>':'歩きモード',1.6);if(P.fly){P.vy=0;P.y+=3;cam.dist=Math.max(cam.dist,30);}else cam.dist=Math.min(cam.dist,6);}
let toastT=0;function toast(html,sec=2){const t=$('toast');t.innerHTML=html;t.style.opacity=1;toastT=sec;}
function toggleView(){if(!P.ride)return;P.view=(P.view+1)%2;$('bView').classList.toggle('on',P.view===1);}
function toggleFF(){if(!P.ride)return;ff=ff===1?6:1;$('bFF').classList.toggle('on',ff>1);}

/* ================= stations / boarding ================= */
const typeName=r=>r.type==='ロマンスカー'?'特急ロマンスカー':r.type;
const lineShort=r=>{const k=r.tl[0].l.key;return k==='odn'||k==='ods'?'小田急線':k==='sot'||k==='izm'?'相鉄線':r.tl[0].l.short;};
function enName(l,n){const s=l.stByName.get(n);return s?s[1]:'';}
function nearestPlatPoint(x,z,y,maxD){let best=null;
  for(const q of PLATBUILT){if(Math.abs(q.top-y)>4)continue;if(Math.hypot(q.x-x,q.z-z)>Math.max(q.a1-q.a0,40)/2+maxD+40)continue;
    if(q.b){const b=q.b;const p=b.pts,n=p.length/2;
      if(inPolyF(x,z,p))return{x,z,y:q.top,d:0};
      for(let i=0,j=n-1;i<n;j=i++){const ax=p[j*2],az=p[j*2+1],dx=p[i*2]-ax,dz=p[i*2+1]-az;const l2=dx*dx+dz*dz||1e-9;let t=((x-ax)*dx+(z-az)*dz)/l2;t=clamp(t,0,1);const qx=ax+dx*t,qz=az+dz*t;const d=Math.hypot(x-qx,z-qz);
        if(d<maxD&&(!best||d<best.d)){const vx=q.x-qx,vz=q.z-qz,vl=Math.hypot(vx,vz)||1;let ix=qx+vx/vl*1.2,iz=qz+vz/vl*1.2;if(!inPolyF(ix,iz,p)){ix=qx+vx/vl*0.4;iz=qz+vz/vl*0.4;}best={x:ix,z:iz,y:q.top,d};}}}
    else{const dx=x-q.x,dz=z-q.z;const a=dx*q.ux+dz*q.uz,w=-dx*q.uz+dz*q.ux;const ca=clamp(a,q.a0+1,q.a1-1),cw=clamp(w,q.w0+0.6,q.w1-0.6);const d=Math.hypot(a-ca,w-cw);
      if(d<maxD&&(!best||d<best.d))best={x:q.x+q.ux*ca-q.uz*cw,z:q.z+q.uz*ca+q.ux*cw,y:q.top,d};}}
  return best;}
function onPlatform(){for(const b of collNear(P.x,P.z)){if(b.plat&&Math.abs(P.y-b.y1)<0.35&&insideColl(b,P.x,P.z))return true;}
  for(const q of PLATBUILT){if(q.b||Math.abs(P.y-q.top)>0.4)continue;const dx=P.x-q.x,dz=P.z-q.z;const a=dx*q.ux+dz*q.uz,w=-dx*q.uz+dz*q.ux;if(a>q.a0&&a<q.a1&&w>q.w0-0.5&&w<q.w1+0.5)return true;}return false;}
let actTarget=null,entTarget=null;
function findBoardable(){
  if(P.fly)return null;let best=null,bd=1e9;const onPl=onPlatform();
  for(const r of ACTIVE){const st=r.st;if(!st.dwell||st.left<=2||st.last||!r.poses)continue;
    for(let i=0;i<r.poses.length;i++){const ps=r.poses[i];const dx=P.x-ps.x,dz=P.z-ps.z;const c=Math.cos(-ps.ry),s=Math.sin(-ps.ry);
      const along=dx*c+dz*s,lat=-dx*s+dz*c;if(Math.abs(along)<r.spec.len/2+2&&Math.abs(lat)<(onPl||Math.abs(P.y-(ps.y+1.0))<0.8?16:7)&&Math.abs(P.y-(ps.y+1.0))<4.5){const d=Math.abs(lat);if(d<bd){bd=d;best={r,i};}}}}
  return best;}
function findEntrance(){if(P.fly)return null;
  for(const e of ENTRANCES){if(Math.hypot(P.x-e.x,P.z-e.z)<5&&Math.abs(P.y-e.y)<3)return{e,down:true};}
  const Z=zoneAt(P.x,P.z,P.y);if(Z&&Math.abs(P.y-Z.floorC)<0.6&&Math.hypot(P.x-Z.conc.cx,P.z-Z.conc.cz)<6){const e=ENTRANCES.find(q=>q.zone===Z);if(e)return{e,down:false};}
  return null;}
function stopWait(){if(!waiting)return;waiting=false;ff=1;$('bWait').classList.remove('on');$('bWait').textContent='次の電車まで時間を進める';}
function doAct(){
  stopWait();
  if(P.ride){const r=P.ride.r;const st=r.st;if(!st||!st.dwell){toast('走行中は降りられません',1.2);return;}alight();return;}
  if(actTarget){board(actTarget.r,actTarget.i);return;}
  if(entTarget){const {e,down}=entTarget;if(down){const Z=e.zone;P.x=Z.conc.cx;P.z=Z.conc.cz;P.y=Z.floorC+0.05;toast(Z.name+'駅 地下コンコース',1.6);}else{P.x=e.x;P.z=e.z;P.y=standY(e.x,e.z,e.y+2)+0.05;toast(e.name+'駅 地上出口',1.6);}P.vy=0;cam.dist=Math.min(cam.dist,5);for(let k=0;k<3;k++)updateChunks(P.x,P.z,2);}
}
function board(r,i){$('stBox').hidden=true;$('waitBar').hidden=true;P.ride={r,i};player.visible=false;P.fly=false;$('bFly').classList.remove('on');cam.dist=Math.max(cam.dist,30);cam.pitch=0.25;$('rideBar').hidden=false;$('trainBox').hidden=false;
  toast(`${typeName(r)} ${r.dest}行に乗車<small>V 前面展望 / X 早送り / 停車中に E で降車</small>`,2.6);}
function alight(){const r=P.ride.r,ps=r.poses[P.ride.i];const c=Math.cos(-ps.ry),s=Math.sin(-ps.ry);let best=null;
  for(const sd of [-1,1])for(let d=1.8;d<=8;d+=0.4){const x=ps.x-s*sd*d,z=ps.z+c*sd*d;const g=standY(x,z,ps.y+3);const ok=g>ps.y+0.5&&g<ps.y+2.2;const sc=(ok?100:0)-Math.abs(g-(ps.y+1.1))*8-d*0.3;if(!best||sc>best.sc)best={x,z,g,sc,ok};}
  if(!best.ok){const np=nearestPlatPoint(ps.x,ps.z,ps.y+1.2,30);if(np)best={x:np.x,z:np.z,g:np.y};}
  const name=r.st&&r.st.name;exitRide();P.x=best.x;P.z=best.z;P.y=best.g+0.05;P.vy=0;toast((name?name+'で':'')+'降車しました',1.4);return best;}
function exitRide(){P.ride=null;ff=1;$('bFF').classList.remove('on');P.view=0;$('bView').classList.remove('on');player.visible=true;cam.dist=4.6;$('rideBar').hidden=true;$('trainBox').hidden=true;}
function updateRideHUD(){
  const r=P.ride.r,st=r.st;const l=st.l;$('tBand').style.background=TYPECOL[r.type]||l.color;$('tLine').textContent=`${lineShort(r)}　${typeName(r)}`;$('tDest').textContent=r.dest+' 行';
  if(st.dwell){$('tLbl').textContent=st.last?'終点':'ただいま';$('tNext').textContent=st.name;$('tNextEn').textContent=enName(l,st.name);}
  else{const n=nextStopOf(r,st.idx);$('tLbl').textContent='次は';$('tNext').textContent=n?n.name:'—';$('tNextEn').textContent=n?enName(n.l,n.name):'';}
  const stops=[...r.stops];$('tSpd').textContent=`${Math.round(st.v*3.6)} km/h　${fmt(CLOCK)}`+(ff>1?'　早送り ×'+ff:'')+(st.dwell?(st.last?'　E で降車':'　停車中 — E で降車'):'')+`\n停車駅：${stops.join('・')}`;
}

/* station departure board (from the timetable) */
let stTimer=0,waiting=false;
function nearbyStation(){let best=null;for(const S of STATIONS){const d=Math.hypot(P.x-S.p.x,P.z-S.p.z);if(d<160&&(!best||d<best.d))best={d,name:S.st[0]};}return best;}
function departures(name,from,max=6){const out=[];const t0=from;
  for(const r of RUNS){if(r.tEnd<t0||r.tStart>t0+3600*2)continue;if(!r.stops.has(name))continue;
    for(const e of r.tl){if(e.k!=='dwell'||e.name!==name||e.last)continue;const dep=e.t0+e.T;if(dep<t0)continue;
      const dirN=nextStopOf(r,r.tl.indexOf(e));out.push({r,dep,arr:e.t0,e,line:lineShort(r),type:r.type,dest:r.dest,via:dirN?dirN.name:''});break;}}
  out.sort((a,b)=>a.dep-b.dep);return out.slice(0,max);}
const nowT=()=>{const t=CLOCK%86400;return t<4*3600?t+86400:t;};
function updateStationBoard(dt){
  stTimer-=dt;if(stTimer>0)return;stTimer=0.5;
  const box=$('stBox'),wb=$('waitBar');
  if(P.ride||P.fly){box.hidden=true;wb.hidden=true;return;}
  const ns=nearbyStation();if(!ns){box.hidden=true;wb.hidden=true;stopWait();return;}
  const rows=departures(ns.name,nowT(),6);
  $('sName').textContent=ns.name+'駅　'+fmt(CLOCK);$('sBand').style.background=rows[0]?(rows[0].e.l.color):'#888';
  $('sRows').innerHTML=rows.map(o=>`<div><span><b style="color:${TYPECOL[o.type]||'#fff'}">${o.type==='ロマンスカー'?'特急RC':o.type}</b>　${o.dest}　<small style="opacity:.6">${o.line}・次 ${o.via}</small></span><i>${fmt(o.dep)}${o.arr<=nowT()?' 停車中':''}</i></div>`).join('')||'<div><span>本日の運転は終了しました</span></div>';
  box.hidden=false;wb.hidden=!!actTarget||!rows.length;
}
$('bWait').addEventListener('click',()=>{const ns=nearbyStation();if(!ns)return;const t=nowT();const rows=departures(ns.name,t+1,3).filter(o=>o.arr>t+5);if(!rows.length){toast('この先の電車はありません',1.5);return;}
  const o=rows[0];const jump=Math.max(0,o.arr-40-t);CLOCK+=jump;toast(`${fmt(o.arr)} 着　${o.type} ${o.dest}行<small>${o.line}・ホームでお待ちください</small>`,2.6);stTimer=0;});

/* ================= time of day ================= */
const TIMES=[
  {label:'☀ 昼',top:'#3f93e0',hor:'#d4ebf7',bot:'#9cc7e0',fog:'#cfe4f2',sun:'#fff4e0',si:3.1,hs:'#cfe3ff',hg:'#a39a8a',hi:0.95,dir:[0.5,0.62,0.6],glow:0.6,win:0,beam:0,stars:0,far:'#ffffff',sea:'#3a9ad3',exp:1.05,cloud:0.3,fogN:3500,fogF:80000},
  {label:'🌇 夕',top:'#3d4f8f',hor:'#ffb069',bot:'#d98a60',fog:'#eaa57a',sun:'#ffb070',si:1.9,hs:'#ffc89a',hg:'#5a4a5a',hi:0.65,dir:[-0.99,0.06,-0.03],glow:1.6,win:0.55,beam:0.05,stars:0.1,far:'#d8a0a8',sea:'#5a7fb0',exp:1.0,cloud:0.5,fogN:2500,fogF:60000},
  {label:'🌙 夜',top:'#050a1c',hor:'#18264a',bot:'#0c1630',fog:'#121d38',sun:'#9fb4ff',si:0.32,hs:'#3a4a85',hg:'#10141f',hi:0.32,dir:[0.4,0.7,0.4],glow:0.1,win:1.3,beam:0.16,stars:1,far:'#3a4060',sea:'#16304f',exp:1.15,cloud:0.05,fogN:1500,fogF:40000},
];
let timeIdx=0,timeT=1,fromT=null;const curT={};
{const h=CLOCK/3600;timeIdx=h>=6&&h<16.5?0:h>=16.5&&h<18?1:2;}
function cycleTime(){fromT={...curT};timeIdx=(timeIdx+1)%TIMES.length;timeT=0;$('bTime').textContent=TIMES[timeIdx].label;toast(['昼','夕暮れ','夜'][timeIdx]+'<small>空の明るさだけ変わります（時刻表の時刻はそのまま）</small>',1.6);}
const _c1=new THREE.Color(),_c2=new THREE.Color(),_sd=new THREE.Vector3(0,1,0);
function applyTime(dt){
  const to=TIMES[timeIdx];timeT=Math.min(1,timeT+dt/2.2);const f=fromT||to;const k=smooth(0,1,timeT);
  const C=(n)=>{_c1.set(f[n]);_c2.set(to[n]);return _c1.clone().lerp(_c2,k);};const N=(n)=>lerp(f[n],to[n],k);
  for(const n of ['top','hor','bot','fog','sun','hs','hg','far','sea'])curT[n]='#'+C(n).getHexString();
  for(const n of ['si','hi','glow','win','beam','stars','exp','cloud','fogN','fogF'])curT[n]=N(n);
  curT.dir=[0,1,2].map(i=>lerp(f.dir[i],to.dir[i],k));if(timeT>=1)fromT=null;
  skyMat.uniforms.top.value.set(curT.top);skyMat.uniforms.hor.value.set(curT.hor);skyMat.uniforms.bot.value.set(curT.bot);skyMat.uniforms.sunCol.value.set(curT.sun);skyMat.uniforms.glow.value=curT.glow;
  scene.fog.color.set(curT.fog);scene.fog.near=curT.fogN;scene.fog.far=curT.fogF;farScene.fog.color.set(curT.fog);farScene.fog.near=curT.fogN*1.2;farScene.fog.far=curT.fogF*1.5;
  sun.color.set(curT.sun);sun.intensity=curT.si;hemi.color.set(curT.hs);hemi.groundColor.set(curT.hg);hemi.intensity=curT.hi;farSun.color.set(curT.sun);farSun.intensity=curT.si*0.8;farHemi.color.set(curT.hs);farHemi.groundColor.set(curT.hg);farHemi.intensity=curT.hi;
  _sd.set(...curT.dir).normalize();skyMat.uniforms.sunDir.value.copy(_sd);sunGlow.position.copy(camera.position).addScaledVector(_sd,250000);sunGlow.material.color.set(curT.sun);sunGlow.visible=timeIdx!==2||timeT<1;farSun.position.copy(_sd).multiplyScalar(1000);
  for(const m of WINMATS)m.emissiveIntensity=curT.win;winTrainMat.emissiveIntensity=curT.win*0.9;
  if(NIGHT.beam)NIGHT.beam.opacity=curT.beam;if(NIGHT.lamp)NIGHT.lamp.emissiveIntensity=0.2+curT.win*1.5;stars.material.opacity=curT.stars;
  for(const m of FARMATS)m.color.set(curT.far);FARMATS.sea.color.set(curT.sea);seaMat.color.set(curT.sea);renderer.toneMappingExposure=curT.exp;
  FARMATS.cloud.emissiveIntensity=curT.cloud;FARMATS.cloud.color.set(timeIdx===1?'#ffd6c0':'#ffffff');
}

/* ================= physics ================= */
const PR=0.35;
function inHoles(b,x,z){if(!b.holes)return false;for(const h of b.holes){const f=[];for(const q of h)f.push(q[0],q[1]);if(inPolyF(x,z,f))return true;}return false;}
function baseGround(x,z,feet){const Z=zoneAt(x,z,feet);if(Z)return Z.y0+0.5;const g=groundAt(x,z);if(feet<g-2.5){const ly=lineYAt(x,z,30);return ly?Math.min(feet,ly.y+0.2):-1e4;}return g;}
const SAFE={x:0,y:0,z:0};
function standY(x,z,feet){let g=baseGround(x,z,feet);for(const b of collNear(x,z)){if(feet>=b.y1-(b.plat?1.3:0.5)&&b.y1>g&&insideColl(b,x,z)&&!inHoles(b,x,z))g=b.y1;}return g;}
function pushPoly(b){const p=b.pts,n=p.length/2;let best=1e9,bx=0,bz=0;
  for(let i=0,j=n-1;i<n;j=i++){const ax=p[j*2],az=p[j*2+1],cx=p[i*2],cz=p[i*2+1];const dx=cx-ax,dz=cz-az;const l2=dx*dx+dz*dz||1e-9;let t=((P.x-ax)*dx+(P.z-az)*dz)/l2;t=t<0?0:t>1?1:t;const qx=ax+dx*t,qz=az+dz*t;const d=Math.hypot(P.x-qx,P.z-qz);if(d<best){best=d;bx=qx;bz=qz;}}
  const inside=inPolyF(P.x,P.z,p);
  if(inside){const dx=bx-P.x,dz=bz-P.z,l=Math.hypot(dx,dz)||1e-6;P.x=bx+dx/l*PR;P.z=bz+dz/l*PR;}
  else if(best<PR){const dx=P.x-bx,dz=P.z-bz,l=Math.hypot(dx,dz)||1e-6;P.x=bx+dx/l*PR;P.z=bz+dz/l*PR;}}
function collide(){
  for(let it=0;it<2;it++)for(const b of collNear(P.x,P.z)){
    if(P.y>=b.y1-(b.plat?1.3:0.45)||P.y+1.7<b.y0)continue;
    if(b.holes)continue; // floor slabs with stair openings never push sideways
    if(b.t===1){if(P.x<b.x0-PR||P.x>b.x1+PR||P.z<b.z0-PR||P.z>b.z1+PR)continue;pushPoly(b);continue;}
    const dx=P.x-b.cx,dz=P.z-b.cz;let lx=dx*b.c+dz*b.s,lz=-dx*b.s+dz*b.c;const ex=b.hw+PR,ez=b.hd+PR;
    if(Math.abs(lx)<ex&&Math.abs(lz)<ez){if(ex-Math.abs(lx)<ez-Math.abs(lz))lx=Math.sign(lx||1)*ex;else lz=Math.sign(lz||1)*ez;
      P.x=b.cx+lx*b.c-lz*b.s;P.z=b.cz+lx*b.s+lz*b.c;}}
}
/* ceiling above the player's head (indoor floors, slabs) */
function ceilAbove(x,z,y){let c=1e9;for(const b of collNear(x,z)){if(b.y0>y+1.2&&b.y0<c&&insideColl(b,x,z)&&!inHoles(b,x,z))c=b.y0;}return c;}
function indoorAt(x,z,y){for(const R of INDOOR){const dx=x-R.cx,dz=z-R.cz;const lx=dx*R.c+dz*R.s,lz=-dx*R.s+dz*R.c;if(Math.abs(lx)<R.hl&&Math.abs(lz)<R.hw&&y>R.y0-0.3&&y<R.y1)return R;}return null;}
function update(dt){
  if(P.ride){rideUpdate(dt);return;}
  let ix=0,iz=0;
  if(keys.KeyW||keys.ArrowUp)iz+=1;if(keys.KeyS||keys.ArrowDown)iz-=1;if(keys.KeyA||keys.ArrowLeft)ix-=1;if(keys.KeyD||keys.ArrowRight)ix+=1;
  if(joy.id!==null){ix+=joy.dx;iz-=joy.dy;}
  const il=Math.hypot(ix,iz);if(il>1){ix/=il;iz/=il;}
  const fx=-Math.sin(cam.yaw),fz=-Math.cos(cam.yaw),rx=Math.cos(cam.yaw),rz=-Math.sin(cam.yaw);
  const mx=fx*iz+rx*ix,mz=fz*iz+rz*ix;const dash=keys.ShiftLeft||keys.ShiftRight||touchDash;
  let sp=P.fly?(dash?260:55):(dash?6.5:2.0); // walk ≈ 7 km/h, run ≈ 23 km/h: the town at its real sizeif(P.swim)sp*=0.4;
  P.x+=mx*sp*dt;P.z+=mz*sp*dt;
  P.x=clamp(P.x,KB.x0,KB.x1);P.z=clamp(P.z,KB.z0,KB.z1); // the whole prefecture is walkable
  const moving=Math.hypot(mx,mz)>0.05;
  if(moving){const target=Math.atan2(mx,mz);let d=target-P.face;d=Math.atan2(Math.sin(d),Math.cos(d));P.face+=d*Math.min(1,dt*12);}
  if(!P.fly)collide();
  const g=standY(P.x,P.z,P.y);
  if(P.fly){const up=(keys.Space||touchJump)?1:0,dn=(keys.KeyC||keys.ControlLeft||keys.KeyQ||touchDown)?1:0;P.y+=(up-dn)*(dash?150:30)*dt;P.y=clamp(P.y,g,2500);P.swim=false;P.onGround=P.y<=g+0.01;}
  else{
    P.vy-=22*dt;P.y+=P.vy*dt;const ce=ceilAbove(P.x,P.z,P.y);if(P.y+1.75>ce&&P.vy>0){P.y=ce-1.75;P.vy=0;}
    const inZ=zoneAt(P.x,P.z,P.y);const wa=inZ?null:waterAt(P.x,P.z);const deck=deckAt(P.x,P.z);
    if(wa!==null&&g<wa-1.2&&P.y<=wa-1.25+0.02&&(deck===null||P.y<deck-0.5)){P.swim=true;P.y=wa-1.25;P.vy=Math.max(P.vy,0);P.onGround=true;}
    else if(P.y<=g){P.y=g;P.vy=0;P.onGround=true;P.swim=false;}
    else{P.onGround=P.y-g<0.05;if(wa===null||g>=wa-1.2)P.swim=false;}
    if((keys.Space||touchJump)&&P.onGround){P.vy=P.swim?4.5:7.4;P.onGround=false;}
    if(P.onGround){SAFE.x=P.x;SAFE.y=P.y;SAFE.z=P.z;}
    if(P.y<-300){P.x=SAFE.x;P.y=SAFE.y+0.5;P.z=SAFE.z;P.vy=0;toast('元の場所に戻りました',1.2);}
  }
  player.position.set(P.x,P.y,P.z);player.rotation.y=P.face;
  P.walk+=dt*(moving?(dash?14:8.5):0);const sw=moving&&!P.fly?Math.sin(P.walk)*(dash?0.85:0.55):0;
  limbs['l1'].rotation.x=sw;limbs['l-1'].rotation.x=-sw;limbs['a1'].rotation.x=-sw*0.8;limbs['a-1'].rotation.x=sw*0.8;
  limbs['a1'].rotation.z=P.fly?-1.2:0.05;limbs['a-1'].rotation.z=P.fly?1.2:-0.05;
  player.rotation.x=P.fly&&moving?0.5:P.swim?1.2:0;
  orbitCamera(dt,P.x,P.y+1.45,P.z,8);
  actTarget=findBoardable();entTarget=actTarget?null:findEntrance();const a=$('act');
  if(actTarget){a.hidden=false;const r=actTarget.r;a.textContent=`E  ${typeName(r)} ${r.dest}行に乗る`;}
  else if(entTarget){a.hidden=false;a.textContent=entTarget.down?`E  ${entTarget.e.name}駅（地下）へ降りる`:`E  地上の出口へ`;}
  else a.hidden=true;
}
function orbitCamera(dt,tx,ty,tz,k){
  cam.tx=lerp(cam.tx,tx,Math.min(1,dt*k));cam.ty=lerp(cam.ty,ty,Math.min(1,dt*k*0.8));cam.tz=lerp(cam.tz,tz,Math.min(1,dt*k));
  const R=P.ride?null:indoorAt(P.x,P.z,P.y+0.5);const dist=R?Math.min(cam.dist,4.2):cam.dist;
  let cx=cam.tx+Math.sin(cam.yaw)*Math.cos(cam.pitch)*dist,cy=cam.ty+Math.sin(cam.pitch)*dist,cz=cam.tz+Math.cos(cam.yaw)*Math.cos(cam.pitch)*dist;
  if(R){const ce=Math.min(ceilAbove(P.x,P.z,P.y),R.y1);cy=Math.min(cy,ce-0.25);
    const dx=cx-R.cx,dz=cz-R.cz;let lx=dx*R.c+dz*R.s,lz=-dx*R.s+dz*R.c;lx=clamp(lx,-R.hl+0.3,R.hl-0.3);lz=clamp(lz,-R.hw+0.3,R.hw-0.3);cx=R.cx+lx*R.c-lz*R.s;cz=R.cz+lx*R.s+lz*R.c;
    cy=Math.max(cy,P.y+0.6);}
  else{const Z=zoneAt(P.x,P.z,P.y);const deep=!P.ride&&P.y<groundAt(P.x,P.z)-2.5&&ceilAbove(P.x,P.z,P.y)<1e8;if(deep&&!Z){const ce=ceilAbove(P.x,P.z,P.y);cy=Math.min(cy,P.y+4,ce-0.25);}else if(!Z)cy=Math.max(cy,groundAt(cx,cz)+0.6,SEA+0.5);}
  camera.position.set(cx,cy,cz);camera.lookAt(cam.tx,cam.ty,cam.tz);
}
function rideUpdate(dt){
  const r=P.ride.r;if(!r.st||nowT()>r.tEnd||!r.poses){const b=alight();toast('終点です。ご乗車ありがとうございました',2);return;}
  const ps=r.poses[P.ride.i];P.x=ps.x;P.z=ps.z;P.y=ps.y+1.1;player.position.set(P.x,P.y,P.z);
  const st=r.st;const l=st.l;
  if(P.view===1){const lead=r.poses[0];const sc=lead.sc;const d=st.d;const s1=sc+d*(r.spec.len/2+0.4),s2=sc+d*90;const side=-d;const f=l.path.at(s1,l.path.laneOff(s1,side)),ah=l.path.at(s2,l.path.laneOff(s2,side));
    const yb=l.mono?lead.y:l.path.py(s1);const yb2=l.mono?lead.y:l.path.py(s2);camera.position.set(f.x,yb+(l.mono?2.4:2.6)+0.2,f.z);camera.lookAt(ah.x,yb2+2.2,ah.z);}
  else{orbitCamera(dt,P.x,P.y+1.5,P.z,6);}
  const a=$('act');a.hidden=!st.dwell;a.textContent='E  降りる';
  updateRideHUD();
}

/* ================= HUD ================= */
const STCITY={};
for(const n of ['横浜','平沼橋','西横浜','天王町','星川','和田町','上星川','西谷','鶴ヶ峰','二俣川','希望ヶ丘','三ツ境','瀬谷','南万騎が原','緑園都市','弥生台','いずみ野','いずみ中央','ゆめが丘','下飯田','立場','中田','踊場','戸塚','舞岡','下永谷','上永谷','港南中央','上大岡','弘明寺','蒔田','吉野町','阪東橋','伊勢佐木長者町','関内','桜木町','高島町'])STCITY[n]='横浜市';
for(const n of ['大和','鶴間','南林間','中央林間','相模大塚','高座渋谷','桜ヶ丘'])STCITY[n]='大和市';
for(const n of ['東林間','相模大野'])STCITY[n]='相模原市';for(const n of ['さがみ野','かしわ台','海老名'])STCITY[n]='海老名市';
for(const n of ['大船','西鎌倉','湘南深沢','湘南町屋','富士見町','腰越','鎌倉高校前','七里ヶ浜','片瀬山'])STCITY[n]='鎌倉市';STCITY['茅ヶ崎']='茅ヶ崎市';
function areaAt2(x,z){
  if(!inWorld(x,z))return kanaArea(x,z);
  if(inPoly(x,z,CITY)||(z>coastZ(x)-50&&x>-6000&&x<3000&&z>-2000))return areaAt(x,z);
  let best=null;for(const S of STATIONS){const d=Math.hypot(x-S.p.x,z-S.p.z);if(!best||d<best.d)best={d,S};}
  if(best&&best.d<2500){const n=best.S.st[0];return{city:STCITY[n]||'',name:n+(best.d<400?'駅前':'駅周辺'),en:best.S.st[1]};}
  return areaAt(x,z);
}
let lastArea='',lastNear='',areaTimer=0,started=false;
function updateArea(dt){
  areaTimer-=dt;if(areaTimer>0)return;areaTimer=0.4;
  const a=areaAt2(P.x,P.z);const key=a.city+a.name;
  if(key!==lastArea){lastArea=key;$('aCity').textContent=a.city||'海上';$('aName').textContent=a.name;$('aEn').textContent=a.en;if(started&&!P.ride)toast(a.name+'<small>'+String(a.en).toUpperCase()+'</small>',2.2);}
  let near=null,bd=1e9;for(const m of LM){const d=Math.hypot(P.x-m.x,P.z-m.z);if(d<m.r+20&&d<bd){bd=d;near=m;}}
  if(!near){const R=indoorAt(P.x,P.z,P.y+0.5);if(R&&R.name)near={name:R.name};}
  if(!near){const Z=zoneAt(P.x,P.z,P.y);if(Z)near={name:Z.name+'駅（地下）'};}
  if(!near){for(const ri of ROADCH.get(chKey(P.x,P.z))||[]){const r=ROADS[ri];if(r.name&&r.path.near(P.x,P.z).d<r.w/2+4){near={name:r.name};break;}}}
  if(!near&&waterAt(P.x,P.z)!==null&&rawH(P.x,P.z)>0)near={name:'川・池'};
  const nn=near?near.name:'';if(nn!==lastNear){lastNear=nn;const el=$('aNear');el.hidden=!nn;el.textContent=nn;}
  $('aScale').textContent=`${fmt(CLOCK)}　標高 ${P.y.toFixed(0)} m`;
}

/* ================= map ================= */
let mapImg=null;const MS=0.06;
function bakeMap(){
  const {nx,nz,mapCols}=terrainInfo;const base=document.createElement('canvas');base.width=nx+1;base.height=nz+1;base.getContext('2d').putImageData(new ImageData(mapCols,nx+1,nz+1),0,0);
  const W=Math.round((WORLD.x1-WORLD.x0)*MS),H=Math.round((WORLD.z1-WORLD.z0)*MS);const c=document.createElement('canvas');c.width=W;c.height=H;const x=c.getContext('2d');
  x.imageSmoothingEnabled=true;x.drawImage(base,0,0,W,H);
  const T=(px,pz)=>[(px-WORLD.x0)*MS,(pz-WORLD.z0)*MS];
  const stroke=(path,w,col,dash)=>{x.beginPath();path.pts.forEach((p,i)=>{const [a,b]=T(p[0],p[1]);i?x.lineTo(a,b):x.moveTo(a,b);});x.lineWidth=Math.max(1,w*MS);x.strokeStyle=col;x.setLineDash(dash||[]);x.lineCap='round';x.lineJoin='round';x.stroke();x.setLineDash([]);};
  for(const c of [4,3,2,1])for(const r of ROADS){if(r.c!==c||(r.fl&2))continue;stroke(r.path,c<=2?30:20,c<=2?'#ffe9a8':'#fbfaf6');}
  for(const k in LINES){const l=LINES[k];stroke(l.path,44,'#1b1f24');stroke(l.path,26,l.color,l.mono?[5,4]:null);}
  x.beginPath();CITY.forEach((p,i)=>{const [a,b]=T(p[0],p[1]);i?x.lineTo(a,b):x.moveTo(a,b);});x.closePath();x.lineWidth=2;x.strokeStyle='rgba(214,57,47,.75)';x.setLineDash([8,5]);x.stroke();x.setLineDash([]);
  for(const S of STATIONS){const [a,b]=T(S.p.x,S.p.z);x.beginPath();x.arc(a,b,3.5,0,7);x.fillStyle='#fff';x.fill();x.lineWidth=1.6;x.strokeStyle='#1b1f24';x.stroke();}
  mapImg=c;buildMapOverlay();
}
const miniCtx=$('miniCv').getContext('2d');
/* ---------- map tiles from 地理院地図 (標準地図), drawn under the game's own overlays ---------- */
const GTILE=new Map();let gtileDirty=0;
function gtile(z,x,y){const k=z+'/'+x+'/'+y;let im=GTILE.get(k);if(!im){im=new Image();im.crossOrigin='anonymous';im.onload=()=>{im.ok=1;gtileDirty=1;};im.src=`${GSI}std/${z}/${x}/${y}.png`;GTILE.set(k,im);
    if(GTILE.size>900){for(const kk of GTILE.keys()){GTILE.delete(kk);if(GTILE.size<700)break;}}}return im.ok?im:null;}
/* draw the tiles covering the game rectangle [gx0,gx1]×[gz0,gz1] with toPx:(x,z)->[u,v] at a zoom suited to mpp (metres per pixel) */
function drawGsi(c,gx0,gz0,gx1,gz1,toPx,mpp){const [la1,lo0]=g2ll(gx0,gz0),[la0,lo1]=g2ll(gx1,gz1);const z=clamp(Math.round(Math.log2(40075016*Math.cos(LAT0*Math.PI/180)/256/mpp)),6,17);
  const tx0=Math.floor(lon2t(lo0,z)),tx1=Math.floor(lon2t(lo1,z)),ty0=Math.floor(lat2t(la1,z)),ty1=Math.floor(lat2t(la0,z));if((tx1-tx0+1)*(ty1-ty0+1)>160)return;
  for(let y=ty0;y<=ty1;y++)for(let x=tx0;x<=tx1;x++){const im=gtile(z,x,y);const a=toPx((t2lon(x,z)-LON0)*MX,-(t2lat(y,z)-LAT0)*MZ),b=toPx((t2lon(x+1,z)-LON0)*MX,-(t2lat(y+1,z)-LAT0)*MZ);
    if(im)c.drawImage(im,a[0],a[1],b[0]-a[0]+0.6,b[1]-a[1]+0.6);else{const p=z>6?gtile(z-1,x>>1,y>>1):null;if(p){const sx=(x&1)*128,sy=(y&1)*128;c.drawImage(p,sx,sy,128,128,a[0],a[1],b[0]-a[0]+0.6,b[1]-a[1]+0.6);}}}}
function drawLinesOn(c,toPx,w){c.lineCap='round';c.lineJoin='round';for(const kk in LINES){const l=LINES[kk];c.beginPath();l.path.pts.forEach((p,i)=>{const q=toPx(p[0],p[1]);i?c.lineTo(q[0],q[1]):c.moveTo(q[0],q[1]);});c.lineWidth=w+2.5;c.strokeStyle='rgba(255,255,255,.9)';c.setLineDash([]);c.stroke();c.lineWidth=w;c.strokeStyle=l.color;c.setLineDash(l.mono?[6,4]:[]);c.stroke();c.setLineDash([]);}}
function drawMini(){
  const c=miniCtx,S=340,span=P.fly?Math.max(4000,(P.y-standY(P.x,P.z,P.y))*6):P.ride?2600:900;const sc=S/span;const toPx=(x,z)=>[S/2+(x-P.x)*sc,S/2+(z-P.z)*sc];
  c.save();c.fillStyle='#bfe0f2';c.fillRect(0,0,S,S);c.imageSmoothingEnabled=true;
  drawGsi(c,P.x-span*0.75,P.z-span*0.75,P.x+span*0.75,P.z+span*0.75,toPx,span/S);
  drawLinesOn(c,toPx,Math.max(3,Math.min(7,6*sc*4)));
  for(const r of ACTIVE){if(!r.poses)continue;const ps=r.poses[(r.poses.length/2)|0];const q=toPx(ps.x,ps.z);if(q[0]>0&&q[0]<S&&q[1]>0&&q[1]<S){c.beginPath();c.arc(q[0],q[1],6,0,7);c.fillStyle=TYPECOL[r.type]&&r.type!=='各停'&&r.type!=='普通'?TYPECOL[r.type]:r.tl[0].l.color;c.fill();c.lineWidth=2;c.strokeStyle='#fff';c.stroke();}}
  c.restore();
  c.save();c.translate(S/2,S/2);c.rotate(-cam.yaw+Math.PI);c.beginPath();c.moveTo(0,0);c.arc(0,0,70,-Math.PI/2-0.45,-Math.PI/2+0.45);c.closePath();c.fillStyle='rgba(255,154,60,.18)';c.fill();c.restore();
  c.save();c.translate(S/2,S/2);c.rotate(-P.face+Math.PI);c.beginPath();c.moveTo(0,-15);c.lineTo(10,11);c.lineTo(0,5);c.lineTo(-10,11);c.closePath();c.fillStyle='#ff9a3c';c.fill();c.lineWidth=3;c.strokeStyle='#fff';c.stroke();c.restore();
  const sl=span>8000?5000:span>2000?1000:100;const ml=sl*sc;c.fillStyle='rgba(16,40,58,.8)';c.fillRect(S/2-ml/2,S-40,ml,7);c.font='800 20px sans-serif';c.textAlign='center';c.fillStyle='#fff';c.strokeStyle='rgba(16,40,58,.8)';c.lineWidth=4;const tl=sl>=1000?sl/1000+' km':sl+' m';c.strokeText(tl,S/2,S-48);c.fillText(tl,S/2,S-48);
}
/* ---------- the big map: all of Kanagawa, drag to pan, wheel / pinch / buttons to zoom, tap to warp ---------- */
const MAPV={cx:(KB.x0+KB.x1)/2,cz:(KB.z0+KB.z1)/2,span:KB.x1-KB.x0};
function buildMapOverlay(){
  const chips=$('chips');chips.innerHTML='';
  const view=(n,f)=>{const b=document.createElement('button');b.className='btn';b.type='button';b.textContent=n;b.addEventListener('click',()=>{f();drawBigMap();});chips.appendChild(b);};
  view('神奈川県全体',()=>{MAPV.cx=(KB.x0+KB.x1)/2;MAPV.cz=(KB.z0+KB.z1)/2;MAPV.span=KB.x1-KB.x0;});view('藤沢市',()=>{MAPV.cx=-600;MAPV.cz=-3000;MAPV.span=16000;});view('現在地',()=>{MAPV.cx=P.x;MAPV.cz=P.z;MAPV.span=3000;});
  view('＋',()=>{MAPV.span=Math.max(400,MAPV.span/1.6);});view('－',()=>{MAPV.span=Math.min(KB.x1-KB.x0,MAPV.span*1.6);});
  const list=[...LM.filter(m=>m.travel&&!m.station),...LM.filter(m=>m.travel&&m.station)];
  for(const d of list){const b=document.createElement('button');b.className='btn'+(d.station?' st':'');b.type='button';b.textContent=d.name;b.addEventListener('click',()=>{warp(d.x,d.z,d.station);toggleMap();});chips.appendChild(b);}
  for(const t of KANA_TOWNS){if(t[0]==='藤沢市')continue;const b=document.createElement('button');b.className='btn';b.type='button';b.textContent=t[0];b.addEventListener('click',()=>{const p=L(t[2],t[3]);warp(p[0],p[1]);toggleMap();});chips.appendChild(b);}
  const cv=$('mapCv');let drag=null,moved=0;const pts=new Map();let pinch=0,span0=0;
  const toWorld=(e)=>{const r=cv.getBoundingClientRect();const k=MAPV.span/r.width;return[MAPV.cx+(e.clientX-r.left-r.width/2)*k,MAPV.cz+(e.clientY-r.top-r.height/2)*k];};
  cv.addEventListener('pointerdown',e=>{cv.setPointerCapture(e.pointerId);pts.set(e.pointerId,[e.clientX,e.clientY]);if(pts.size===2){const a=[...pts.values()];pinch=Math.hypot(a[0][0]-a[1][0],a[0][1]-a[1][1]);span0=MAPV.span;drag=null;}else{drag=[e.clientX,e.clientY];moved=0;}});
  cv.addEventListener('pointermove',e=>{if(!pts.has(e.pointerId))return;pts.set(e.pointerId,[e.clientX,e.clientY]);
    if(pts.size===2&&pinch){const a=[...pts.values()];const d=Math.hypot(a[0][0]-a[1][0],a[0][1]-a[1][1]);MAPV.span=clamp(span0*pinch/Math.max(d,1),400,KB.x1-KB.x0);moved=99;drawBigMap();return;}
    if(drag){const r=cv.getBoundingClientRect();const k=MAPV.span/r.width;const dx=e.clientX-drag[0],dy=e.clientY-drag[1];moved+=Math.abs(dx)+Math.abs(dy);MAPV.cx-=dx*k;MAPV.cz-=dy*k;drag=[e.clientX,e.clientY];drawBigMap();}});
  const up=e=>{const was=pts.size;pts.delete(e.pointerId);if(pts.size<2)pinch=0;if(drag&&was===1&&moved<6){const [wx,wz]=toWorld(e);warp(wx,wz);toggleMap();}drag=null;};
  cv.addEventListener('pointerup',up);cv.addEventListener('pointercancel',()=>{pts.clear();drag=null;});
  cv.addEventListener('wheel',e=>{e.preventDefault();const [wx,wz]=toWorld(e);const f=e.deltaY>0?1.25:0.8;const ns=clamp(MAPV.span*f,400,KB.x1-KB.x0);MAPV.cx=wx+(MAPV.cx-wx)*ns/MAPV.span;MAPV.cz=wz+(MAPV.cz-wz)*ns/MAPV.span;MAPV.span=ns;drawBigMap();},{passive:false});
  setInterval(()=>{if(gtileDirty&&!$('mapOv').hidden){gtileDirty=0;drawBigMap();}},400);
}
function drawBigMap(){
  const cv=$('mapCv');const w=Math.min(innerWidth-40,1100),h=Math.min(innerHeight*0.62,w*0.75);const dpr=Math.min(devicePixelRatio,2);if(cv.width!==Math.round(w*dpr)||cv.height!==Math.round(h*dpr)){cv.width=w*dpr;cv.height=h*dpr;}cv.style.width=w+'px';cv.style.height=h+'px';
  const x=cv.getContext('2d');x.setTransform(dpr,0,0,dpr,0,0);const k=w/MAPV.span;const T=(px,pz)=>[w/2+(px-MAPV.cx)*k,h/2+(pz-MAPV.cz)*k];
  x.fillStyle='#bfe0f2';x.fillRect(0,0,w,h);const hw=MAPV.span/2,hh=hw*h/w;drawGsi(x,MAPV.cx-hw,MAPV.cz-hh,MAPV.cx+hw,MAPV.cz+hh,T,MAPV.span/w);
  drawLinesOn(x,T,Math.max(2.5,Math.min(6,k*40)));
  x.textAlign='center';x.textBaseline='middle';
  if(k>0.02){x.font=`700 ${clamp(k*200,10,14)}px "M PLUS Rounded 1c",sans-serif`;const seen=new Set();for(const S of STATIONS){const n=S.st[0];if(seen.has(n))continue;seen.add(n);const [u,v]=T(S.p.x,S.p.z);if(u<-20||v<-20||u>w+20||v>h+20)continue;
    x.beginPath();x.arc(u,v,4,0,7);x.fillStyle='#fff';x.fill();x.lineWidth=2;x.strokeStyle='#10283a';x.stroke();x.lineWidth=3;x.strokeStyle='rgba(255,255,255,.95)';x.strokeText(n,u,v-12);x.fillStyle='#10283a';x.fillText(n,u,v-12);}}
  else{x.font='800 13px "M PLUS Rounded 1c",sans-serif';for(const t of KANA_TOWNS){const p=L(t[2],t[3]);const [u,v]=T(p[0],p[1]);x.lineWidth=4;x.strokeStyle='rgba(16,40,58,.55)';x.strokeText(t[0],u,v);x.fillStyle='#fff';x.fillText(t[0],u,v);}}
  const sl=MAPV.span>40000?10000:MAPV.span>8000?2000:MAPV.span>2000?500:100;const km=sl*k;x.fillStyle='rgba(16,40,58,.85)';x.fillRect(12,h-18,km,5);x.font='800 11px sans-serif';x.textAlign='left';x.fillText(sl>=1000?sl/1000+' km':sl+' m',12,h-26);
  x.font='500 10px sans-serif';x.textAlign='right';x.fillStyle='rgba(16,40,58,.8)';x.fillText('地理院地図（国土地理院）',w-8,h-8);
  const [u,v]=T(P.x,P.z);x.save();x.translate(u,v);x.rotate(-P.face+Math.PI);x.beginPath();x.moveTo(0,-11);x.lineTo(8,9);x.lineTo(0,4);x.lineTo(-8,9);x.closePath();x.fillStyle='#ff3c6a';x.fill();x.lineWidth=2;x.strokeStyle='#fff';x.stroke();x.restore();
}
function toggleMap(){const o=$('mapOv');o.hidden=!o.hidden;if(!o.hidden)drawBigMap();else canvas.focus();}
function warp(x,z,station){if(P.ride)exitRide();P.x=clamp(x,KB.x0,KB.x1);P.z=clamp(z,KB.z0,KB.z1);let y=null;
  if(station){let best=null;for(const q of PLATBUILT){const d=Math.hypot(q.x-P.x,q.z-P.z);if(d<350&&(!best||d<best.d))best={d,q};}
    if(best){const q=best.q;P.x=q.x;P.z=q.z;y=q.top+0.05;cam.yaw=Math.atan2(q.uz,-q.ux)+Math.PI/2;}}
  for(let k=0;k<4;k++)updateChunks(P.x,P.z,1);P.y=y??(standY(P.x,P.z,999)+(P.fly?30:0.1));for(let k=0;k<6;k++)collide();P.vy=0;cam.tx=P.x;cam.ty=P.y;cam.tz=P.z;}

/* ================= loop ================= */
let last=performance.now(),elapsed=0,miniT=0;
function frame(now){
  const dt=Math.min(0.05,(now-last)/1000);last=now;elapsed+=dt;
  CLOCK+=dt*ff;if(CLOCK>=86400+4*3600)CLOCK-=86400;
  applyTime(dt);
  updateTrains();for(const c of CARS)c.update(dt*ff);if(started)PEOPLE.update(dt);
  update(dt);
  for(const f of DYN)f(elapsed,dt);
  updateChunks(P.x,P.z,1);updateRegion(dt,P.x,P.z);
  sun.position.set(P.x+_sd.x*300,P.y+Math.max(_sd.y,0.12)*300,P.z+_sd.z*300);sun.target.position.set(P.x,P.y,P.z);
  for(const Lb of LABELS){const dd=camera.position.distanceTo(Lb.sp.position);const near=Lb.maxD>=500?smooth(35,90,dd):1;const vis=dd<Lb.maxD&&near>0.01;Lb.sp.visible=vis;if(vis){const s=clamp(dd*0.05,1.4,220)*Lb.size;Lb.sp.scale.set(s*Lb.sp.userData.ar,s,1);Lb.sp.material.opacity=(1-smooth(Lb.maxD*0.75,Lb.maxD,dd))*near;}} // big area/station names step aside when you are right there
  updateStationBoard(dt);
  updateArea(dt);miniT-=dt;if(miniT<=0){miniT=0.12;drawMini();}
  if(toastT>0){toastT-=dt;if(toastT<=0)$('toast').style.opacity=0;}
  farCam.position.copy(camera.position);farCam.quaternion.copy(camera.quaternion);
  renderer.clear();renderer.render(farScene,farCam);renderer.clearDepth();renderer.render(scene,camera);
  requestAnimationFrame(frame);
}
addEventListener('resize',()=>{renderer.setSize(innerWidth,innerHeight);for(const c of [camera,farCam]){c.aspect=innerWidth/innerHeight;c.updateProjectionMatrix();}if(!$('mapOv').hidden)drawBigMap();});

(async()=>{
  setLoad('地図データを受信中…');const plP=loadPlaces.bind(null);await loadData();await plP();await loadCity();loadOverview();
  try{await Promise.race([document.fonts.load('800 52px "M PLUS Rounded 1c"'),new Promise(r=>setTimeout(r,2500))]);}catch(e){}
  await build();buildLabels();
  {const [sx,sz]=LMP('katase_st',35.3091,139.4829);const [tx,tz]=LMP('torii',35.3020,139.4822);let gx=sx+(tx-sx)*0.12,gz=sz+(tz-sz)*0.12;let best=null;
    for(const r of ROADS){if(r.c<5||(r.fl&3))continue;if(Math.abs(r.pts[0]-gx)>600||Math.abs(r.pts[1]-gz)>600)continue;const q=r.path.near(gx,gz);if(q.d<160&&(!best||q.d<best.d))best={d:q.d,p:r.path.at(q.s)};}
    if(best){gx=best.p.x;gz=best.p.z;}P.x=gx;P.z=gz;cam.yaw=Math.atan2(sx-tx,sz-tz);P.face=cam.yaw+Math.PI;}
  setLoad('街を建てています…');await tick();
  while(updateChunks(P.x,P.z,4)>0){await tick();}
  warp(P.x,P.z);applyTime(1);$('bTime').textContent=TIMES[timeIdx].label;
  $('loading').hidden=true;started=true;startRegion();lastArea='';canvas.focus();
  toast('ようこそ藤沢市へ<small>電車は時刻表どおりに走っています（現在 '+fmt(CLOCK)+'）</small>',3.2);
  requestAnimationFrame(t=>{last=t;frame(t);});
})().catch(err=>{console.error(err);setLoad('読み込みに失敗しました: '+err.message);});
