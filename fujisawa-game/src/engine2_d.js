
/* ================= road traffic (simple shuttles) ================= */
const CARS=[];
class Mover{
  constructor(path,o){Object.assign(this,{off:0,n:1,carLen:5,gap:0.6,vmax:16,acc:0.9,dec:1.0,dwellT:20},o);this.path=path;
    this.half=(this.n*this.carLen+(this.n-1)*this.gap)/2;const lo=this.half+2,hi=path.L-this.half-2;this.lo=lo;this.hi=Math.max(lo+1,hi);
    this.stops=[lo,this.hi];this.s=lo;this.dir=1;this.v=0;this.dwell=0;this.cars=[];}
  step(dt){if(this.dwell>0){this.dwell-=dt;return;}const tgt=this.dir>0?this.hi:this.lo;const dist=Math.abs(tgt-this.s);const vt=Math.min(this.vmax,Math.sqrt(2*this.dec*dist)+0.3);
    this.v=this.v<vt?Math.min(vt,this.v+this.acc*dt):Math.max(vt,this.v-this.dec*2*dt);const ds=this.v*dt;if(ds>=dist){this.s=tgt;this.v=0;this.dwell=this.dwellT;this.dir*=-1;}else this.s+=ds*this.dir;}
  update(dt){let t=dt;while(t>1e-6){const h=Math.min(t,0.25);this.step(h);t-=h;}this.place();}
  place(){const off=this.off*this.dir;for(let i=0;i<this.cars.length;i++){const sc=this.s;const f=this.path.at(sc+this.carLen/2-1,-off),b=this.path.at(sc-this.carLen/2+1,-off);const x=(f.x+b.x)/2,z=(f.z+b.z)/2;
      const car=this.cars[i];car.position.set(x,this.yFn(x,z,sc),z);car.rotation.y=Math.atan2(-(f.z-b.z),f.x-b.x);}}
}
function buildCars(){
  const cols=['#e0453a','#f4f4f2','#2c3e50','#3d6fa8','#f2c230','#9aa3ab','#4f9a45','#ffffff','#1b1f24','#e8902f','#c9ced3'];
  const cand=ROADS.filter(r=>r.c<=3&&!(r.fl&3)&&r.path.L>250).sort((a,b)=>b.path.L-a.path.L).slice(0,90);
  for(const r of cand){const cnt=Math.max(1,Math.round(r.path.L/350));
    for(let i=0;i<cnt;i++){const bus=rand()<0.15;const m=new Mover(r.path,{off:Math.min(r.w/4,2.2),n:1,carLen:bus?11:4.5,vmax:bus?10:rr(11,15),acc:2,dec:3,dwellT:0.5});
      m.dir=rand()<0.5?1:-1;m.s=rr(m.lo,m.hi);m.yFn=(x,z)=>demH(x,z)+0.2;
      const g=new THREE.Group();const c=bus?'#f2efe6':pick(cols);
      const add=(mat,sx,sy,sz,x,y)=>{const b=new THREE.Mesh(BOX,mat);b.scale.set(sx,sy,sz);b.position.set(x,y,0);b.castShadow=true;g.add(b);};
      if(bus){add(M(c),11,2.8,2.5,0,0.4);add(M('#d9622b'),11.05,0.5,2.55,0,1.1);add(winTrainMat,10.4,0.9,2.55,0,1.9);}
      else{add(M(c),4.5,0.75,1.75,0,0.3);add(M(rand()<0.5?c:'#2a3a48'),2.4,0.65,1.6,-0.3,1.05);add(winTrainMat,2.5,0.4,1.62,-0.3,1.15);}
      scene.add(g);m.cars.push(g);m.place();CARS.push(m);}}
}

/* ================= timetable: services, stop patterns, left-hand running ================= */
let CLOCK=0; // seconds since midnight (game time)
{const d=new Date();CLOCK=d.getHours()*3600+d.getMinutes()*60+d.getSeconds();if(CLOCK<5*3600)CLOCK=6*3600;}
const fmt=t=>{t=((t%86400)+86400)%86400;const h=Math.floor(t/3600),m=Math.floor(t%3600/60);return `${h}:${String(m).padStart(2,'0')}`;};
const SPEC={
  jr:LINES.jr.car,od10:{...LINES.odn.car,n:10},od6:{...LINES.odn.car,n:6},rc:{...ROMANCE,n:7},so10:{...LINES.sot.car,n:10},so8:{...LINES.sot.car,n:8},blu:LINES.blu.car,eno:LINES.eno.car,mono:{...LINES.mono.car,mono:true}};
const TYPECOL={'各停':'#cfd6de','普通':'#cfd6de','急行':'#ff6b5e','快速急行':'#ffa14a','快速':'#6fb3ff','特急':'#ff8a3c','ロマンスカー':'#ff6f9c'};
const UPDIR={jr:1,odn:1,ods:-1,sot:-1,izm:1}; // which travel direction along the path is 上り
const RUNS=[];
const ACC=0.75,DEC=0.9;
function runTime(D,v){const da=v*v/(2*ACC),dd=v*v/(2*DEC);if(D>=da+dd)return v/ACC+v/DEC+(D-da-dd)/v;const vp=Math.sqrt(2*D*ACC*DEC/(ACC+DEC));return vp/ACC+vp/DEC;}
function distAt(tau,D,T,v){const da=v*v/(2*ACC),dd=v*v/(2*DEC);let vp=v,t1,t3;if(D>=da+dd){t1=v/ACC;t3=v/DEC;}else{vp=Math.sqrt(2*D*ACC*DEC/(ACC+DEC));t1=vp/ACC;t3=vp/DEC;}
  if(tau<=0)return 0;if(tau>=T)return D;if(tau<t1)return 0.5*ACC*tau*tau;if(tau<T-t3)return 0.5*ACC*t1*t1+vp*(tau-t1);const r=T-tau;return D-0.5*DEC*r*r;}
/* legs: [lineKey, fromStation|'<'|'>', toStation|'<'|'>', [stopping stations]] ('<' path start, '>' path end) */
function addRun(type,dest,spec,legs,t0,vmax,opt={}){
  const tl=[];let t=t0;let first=true;
  for(let li=0;li<legs.length;li++){const [lk,fromN,toN,stops]=legs[li];const l=LINES[lk];if(!l)return;const half=(spec.n*spec.len+(spec.n-1)*(l.mono?0.6:0.8))/2;
    const sOf=n=>n==='<'?half+2:n==='>'?l.path.L-half-2:(l.stByName.get(n)?clamp(l.stByName.get(n).s,half+2,l.path.L-half-2):null);
    const sA=sOf(fromN),sB=sOf(toN);if(sA===null||sB===null)return;const d=Math.sign(sB-sA)||1;
    const endName=(n,s0)=>{if(n!=='<'&&n!=='>')return n;for(const q of stops){const st=l.stByName.get(q);if(st&&Math.abs(clamp(st.s,half+2,l.path.L-half-2)-s0)<40)return q;}return null;};
    const nA=endName(fromN,sA),nB=endName(toN,sB);
    let pos=[{s:sA,name:nA}];
    for(const n of stops){if(n===fromN||n===toN||n===nA||n===nB)continue;const s=sOf(n);if(s===null)continue;if((s-sA)*d>0&&(sB-s)*d>0)pos.push({s,name:n});}
    pos.push({s:sB,name:nB});pos.sort((a,b)=>(a.s-b.s)*d);
    if(first){if(pos[0].name){const T0=VIRTUAL_END.has(lk+'|'+pos[0].name)||l.single?30:75;tl.push({k:'dwell',l,d,s:pos[0].s,t0:t-T0,T:T0,name:pos[0].name,origin:true});}first=false;}
    for(let i=0;i<pos.length-1;i++){const D=Math.abs(pos[i+1].s-pos[i].s);let v=Math.min(vmax,l.vmax);
      if(lk==='eno'&&((pos[i].name==='江ノ島'&&pos[i+1].name==='腰越')||(pos[i].name==='腰越'&&pos[i+1].name==='江ノ島')))v=4.5;
      const T=runTime(D,v);tl.push({k:'move',l,d,sA:pos[i].s,sB:pos[i+1].s,D,T,v,t0:t});t+=T;
      const last=i===pos.length-2;const nm=pos[i+1].name;
      if(nm){const dw=last?(li<legs.length-1?(opt.revDwell||240):90):(opt.dwell||(lk==='jr'?40:30));tl.push({k:'dwell',l,d,s:pos[i+1].s,t0:t,T:dw,name:nm,last:last&&li===legs.length-1});t+=dw;}}
  }
  if(!tl.length)return;
  const allStops=new Set();for(const e of tl)if(e.k==='dwell')allStops.add(e.name);
  RUNS.push({type,dest,spec,tl,tStart:tl[0].t0,tEnd:tl[tl.length-1].t0+tl[tl.length-1].T,stops:allStops,cars:[],id:RUNS.length});
}
function everyHour(mins,f){for(let h=5;h<=24;h++)for(const m of mins){const t=h*3600+m*60;if(t>24*3600+40*60)continue;f(t,h);}}
const OD_ALL=['藤沢','藤沢本町','善行','六会日大前','湘南台','長後','高座渋谷','桜ヶ丘','大和','鶴間','南林間','中央林間','東林間','相模大野'];
const ODS_ALL=['片瀬江ノ島','鵠沼海岸','本鵠沼','藤沢'];
const SO_ALL=['横浜','平沼橋','西横浜','天王町','星川','和田町','上星川','西谷','鶴ヶ峰','二俣川','希望ヶ丘','三ツ境','瀬谷','大和','相模大塚','さがみ野','かしわ台','海老名'];
const IZ_ALL=['二俣川','南万騎が原','緑園都市','弥生台','いずみ野','いずみ中央','ゆめが丘','湘南台'];
const BL_ALL=['湘南台','下飯田','立場','中田','踊場','戸塚','舞岡','下永谷','上永谷','港南中央','上大岡','弘明寺','蒔田','吉野町','阪東橋','伊勢佐木長者町','関内','桜木町','高島町','横浜'];
function buildTimetable(){
  /* 小田急江ノ島線 (daytime pattern) */
  const KQ=['藤沢','湘南台','大和','中央林間','相模大野'];          // 快速急行
  const EX=['藤沢','湘南台','長後','大和','中央林間','南林間','相模大野'];// 急行
  const RC=['片瀬江ノ島','藤沢','大和','相模大野'];                  // ロマンスカー
  everyHour([2,12,22,32,42,52],t=>addRun('各停','相模大野',SPEC.od6,[['odn','藤沢','相模大野',OD_ALL]],t,24));
  everyHour([6,16,26,36,46,56],t=>addRun('各停','藤沢',SPEC.od6,[['odn','相模大野','藤沢',OD_ALL]],t,24));
  everyHour([7,47],t=>addRun('快速急行','新宿',SPEC.od10,[['odn','藤沢','相模大野',KQ]],t,30));
  everyHour([15],t=>addRun('快速急行','新宿',SPEC.od10,[['ods','片瀬江ノ島','藤沢',ODS_ALL],['odn','藤沢','相模大野',KQ]],t,30));
  everyHour([11,51],t=>addRun('快速急行','藤沢',SPEC.od10,[['odn','相模大野','藤沢',KQ]],t,30));
  everyHour([31],t=>addRun('快速急行','片瀬江ノ島',SPEC.od10,[['odn','相模大野','藤沢',KQ],['ods','藤沢','片瀬江ノ島',ODS_ALL]],t,30));
  everyHour([17,37],t=>addRun('急行','新宿',SPEC.od10,[['odn','藤沢','相模大野',EX]],t,30));
  everyHour([21,41],t=>addRun('急行','藤沢',SPEC.od10,[['odn','相模大野','藤沢',EX]],t,30));
  everyHour([35],(t,h)=>{if(h%2===0&&h>=8&&h<=20)addRun('ロマンスカー','新宿',SPEC.rc,[['ods','片瀬江ノ島','藤沢',RC],['odn','藤沢','相模大野',RC]],t,30,{revDwell:180});});
  everyHour([5],(t,h)=>{if(h%2===1&&h>=9&&h<=21)addRun('ロマンスカー','片瀬江ノ島',SPEC.rc,[['odn','相模大野','藤沢',RC],['ods','藤沢','片瀬江ノ島',RC]],t,30,{revDwell:180});});
  everyHour([0,15,30,45],t=>addRun('各停','片瀬江ノ島',SPEC.od6,[['ods','藤沢','片瀬江ノ島',ODS_ALL]],t,20));
  everyHour([8,23,38,53],t=>addRun('各停','藤沢',SPEC.od6,[['ods','片瀬江ノ島','藤沢',ODS_ALL]],t,20));
  /* JR東海道線 */
  const JRS=['茅ヶ崎','辻堂','藤沢','大船','戸塚','横浜'];
  everyHour([3,13,23,33,43,53],(t,h)=>addRun('普通',h%2?'東京':'上野',SPEC.jr,[['jr','<','>',JRS]],t,33,{dwell:40}));
  everyHour([1,11,21,31,41,51],(t,h)=>addRun('普通',(h+Math.floor(t/600))%3===0?'熱海':'小田原',SPEC.jr,[['jr','>','<',JRS]],t,33,{dwell:40}));
  /* 相鉄本線・いずみ野線 */
  const SO_RAP=['横浜','星川','西谷','鶴ヶ峰','二俣川','希望ヶ丘','三ツ境','瀬谷','大和','相模大塚','さがみ野','かしわ台','海老名'];
  const SO_LTD=['横浜','西谷','二俣川','大和','海老名'];
  everyHour([0,20,40],t=>addRun('各停','海老名',SPEC.so8,[['sot','横浜','海老名',SO_ALL]],t,28));
  everyHour([10,50],t=>addRun('快速','海老名',SPEC.so10,[['sot','横浜','海老名',SO_RAP]],t,28));
  everyHour([30],t=>addRun('特急','海老名',SPEC.so10,[['sot','横浜','海老名',SO_LTD]],t,30));
  everyHour([5,25,45],t=>addRun('各停','湘南台',SPEC.so8,[['sot','横浜','二俣川',SO_ALL],['izm','二俣川','湘南台',IZ_ALL]],t,28,{revDwell:30}));
  everyHour([15,55],t=>addRun('快速','湘南台',SPEC.so10,[['sot','横浜','二俣川',SO_RAP],['izm','二俣川','湘南台',IZ_ALL]],t,28,{revDwell:30}));
  everyHour([35],t=>addRun('特急','湘南台',SPEC.so10,[['sot','横浜','二俣川',SO_LTD],['izm','二俣川','湘南台',['二俣川','いずみ野','湘南台']]],t,30,{revDwell:30}));
  everyHour([3,23,43],t=>addRun('各停','横浜',SPEC.so8,[['sot','海老名','横浜',SO_ALL]],t,28));
  everyHour([13,53],t=>addRun('快速','横浜',SPEC.so10,[['sot','海老名','横浜',SO_RAP]],t,28));
  everyHour([33],t=>addRun('特急','横浜',SPEC.so10,[['sot','海老名','横浜',SO_LTD]],t,30));
  everyHour([8,28,48],t=>addRun('各停','横浜',SPEC.so8,[['izm','湘南台','二俣川',IZ_ALL],['sot','二俣川','横浜',SO_ALL]],t,28,{revDwell:30}));
  everyHour([18,58],t=>addRun('快速','横浜',SPEC.so10,[['izm','湘南台','二俣川',IZ_ALL],['sot','二俣川','横浜',SO_RAP]],t,28,{revDwell:30}));
  everyHour([38],t=>addRun('特急','横浜',SPEC.so10,[['izm','湘南台','二俣川',['湘南台','いずみ野','二俣川']],['sot','二俣川','横浜',SO_LTD]],t,30,{revDwell:30}));
  /* ブルーライン */
  everyHour([0,7.5,15,22.5,30,37.5,45,52.5],t=>addRun('各停','あざみ野',SPEC.blu,[['blu','湘南台','>',BL_ALL]],t,22));
  everyHour([3,10.5,18,25.5,33,40.5,48,55.5],t=>addRun('各停','湘南台',SPEC.blu,[['blu','>','湘南台',BL_ALL]],t,22));
  /* 江ノ電・湘南モノレール */
  const EN=LINES.eno.st.map(s=>s[0]);const MO=LINES.mono.st.map(s=>s[0]);
  everyHour([0,12,24,36,48],t=>addRun('各停','鎌倉',SPEC.eno,[['eno','藤沢','>',EN]],t,11,{dwell:25}));
  everyHour([5,17,29,41,53],t=>addRun('各停','藤沢',SPEC.eno,[['eno','>','藤沢',EN]],t,11,{dwell:25}));
  everyHour([0,7.5,15,22.5,30,37.5,45,52.5],t=>addRun('各停','大船',SPEC.mono,[['mono','湘南江の島','大船',MO]],t,16,{dwell:25}));
  everyHour([3,10.5,18,25.5,33,40.5,48,55.5],t=>addRun('各停','湘南江の島',SPEC.mono,[['mono','大船','湘南江の島',MO]],t,16,{dwell:25}));
  RUNS.sort((a,b)=>a.tStart-b.tStart);
  scheduleSingleTrack();
  resolveOvertakes();
  buildTrainMeshes();
}
/* state of a run at clock t */
function runState(r,t){
  const tl=r.tl;let lo=0,hi=tl.length-1;while(lo<hi){const m=(lo+hi+1)>>1;if(tl[m].t0<=t)lo=m;else hi=m-1;}const e=tl[lo];
  if(e.k==='dwell')return{l:e.l,d:e.d,s:e.s,v:0,dwell:true,name:e.name,left:e.t0+e.T-t,last:!!e.last,e,idx:lo};
  const tau=t-e.t0;const D=e.D;const x=distAt(Math.min(tau,e.T),D,e.T,e.v);const v=tau<e.T?Math.max(0,(distAt(Math.min(tau+0.5,e.T),D,e.T,e.v)-x)/0.5):0;
  return{l:e.l,d:e.d,s:e.sA+e.d*x,v,dwell:false,e,idx:lo};
}
function nextStopOf(r,idx){for(let i=idx+1;i<r.tl.length;i++)if(r.tl[i].k==='dwell')return r.tl[i];return null;}
/* instanced train cars */
const CARPOOL=new Map();
function poolFor(spec){const key=JSON.stringify(spec);let p=CARPOOL.get(key);if(p)return p;
  const w=spec.w,h=spec.h,len=spec.len;const body=[],win=[];
  const add=(c,sx,sy,sz,y,x=0,isWin=false)=>{const g=new THREE.BoxGeometry(sx,sy,sz).translate(x,y+sy/2,0).toNonIndexed();if(isWin){win.push(g);return;}const cc=new THREE.Color(c);const n=g.attributes.position.count;const a=new Float32Array(n*3);for(let i=0;i<n;i++){a[i*3]=cc.r;a[i*3+1]=cc.g;a[i*3+2]=cc.b;}g.setAttribute('color',new THREE.BufferAttribute(a,3));body.push(g);};
  add('#2c2f33',len*0.86,0.75,w*0.8,0.2);
  for(const k of [-1,1])add('#24272b',2.4,0.55,w*0.86,0.25,k*len*0.34); // bogies
  for(let k=-2;k<=2;k++)add('#3a3e44',1.6,0.5,w*0.7,0.55,k*len*0.15); // under-floor equipment
  if(spec.two){add(spec.two[0],len,h*0.45,w,0.95);add(spec.two[1],len,h*0.55,w,0.95+h*0.45);}else add(spec.body,len,h,w,0.95);
  add(null,len*0.9,h*0.3,w+0.04,0.95+h*0.42,0,true);
  // window pillars over the glass band
  for(let k=-4;k<=4;k++)add(spec.two?spec.two[1]:spec.body,0.28,h*0.3,w+0.06,0.95+h*0.42,k*len*0.1);
  const nd=spec.len>=19?4:spec.len>=15?3:2;for(let k=0;k<nd;k++){const x=(k-(nd-1)/2)*len/nd;add('#9aa3aa',1.3,h*0.72,w+0.07,0.95+h*0.04,x);add('#2a3a48',0.5,h*0.28,w+0.08,0.95+h*0.42,x-0.32);add('#2a3a48',0.5,h*0.28,w+0.08,0.95+h*0.42,x+0.32);}
  for(const st of spec.stripes||[])add(st[0],len+0.04,st[2],w+0.06,0.95+st[1]);
  add(spec.roof||'#a7adb3',len*0.97,0.25,w*0.88,0.95+h);
  if(!spec.mono){for(const k of [-1,1])add('#c9ced3',2.6,0.32,w*0.6,0.95+h+0.25,k*len*0.22); // roof air conditioners
    add('#5a6168',1.4,0.08,1.6,0.95+h+0.5,len*0.36);add('#5a6168',0.08,0.5,1.0,0.95+h+0.25,len*0.36);}
  if(spec.mono)add('#8a949c',1.2,1.9,0.8,h+0.95);
  const mg=(list,colr)=>{let tot=0;for(const g of list)tot+=g.attributes.position.count;const P=new Float32Array(tot*3),N=new Float32Array(tot*3),C=colr?new Float32Array(tot*3):null;let o=0;for(const g of list){P.set(g.attributes.position.array,o);N.set(g.attributes.normal.array,o);if(C)C.set(g.attributes.color.array,o);o+=g.attributes.position.array.length;}const r=new THREE.BufferGeometry();r.setAttribute('position',new THREE.BufferAttribute(P,3));r.setAttribute('normal',new THREE.BufferAttribute(N,3));if(C)r.setAttribute('color',new THREE.BufferAttribute(C,3));return r;};
  const cap=500;const mb=new THREE.InstancedMesh(mg(body,true),CARMAT,cap),mw=new THREE.InstancedMesh(mg(win,false),winTrainMat,cap);
  for(const m of [mb,mw]){m.count=0;m.frustumCulled=false;m.castShadow=m===mb;scene.add(m);}
  p={mb,mw,n:0};CARPOOL.set(key,p);return p;}
const CARMAT=new THREE.MeshLambertMaterial({vertexColors:true});
function buildTrainMeshes(){for(const r of RUNS)r.pool=poolFor(r.spec);}
const ACTIVE=[];const _dm=new THREE.Object3D();
function carPose(r,st,i){const sp=r.spec;const l=st.l;const gap=l.mono?0.6:0.8;const n=sp.n;const sc=st.s+st.d*((n-1)/2-i)*(sp.len+gap);
  const sf=sc+st.d*(sp.len/2-1),sb=sc-st.d*(sp.len/2-1);const side=-st.d;
  let pe=null;const tl=r.tl,ix=st.idx;for(const k of [ix,ix+1,ix-1]){const e=tl[k];if(e&&e.k==='dwell'&&e.pass!==undefined&&e.l===l){pe=e;break;}}
  const lo=(ss)=>{const m=l.single?loopOff(l,ss,side):l.path.laneOff(ss,side);if(!pe)return m;const hp=Math.min(l.plat/2,110);const w=1-smooth(hp+4,hp+130,Math.abs(ss-pe.s));return lerp(m,pe.passProf?pe.passProf(ss):pe.pass,w);};
  const f=l.path.at(sf,lo(sf)),b=l.path.at(sb,lo(sb));
  const x=(f.x+b.x)/2,z=(f.z+b.z)/2;const y=l.mono?l.beamY(sc)-1.6-sp.h-0.95-0.3:l.path.py(sc)+0.2;return{x,y,z,ry:Math.atan2(-(f.z-b.z),f.x-b.x),sc,lane:lo(sc)};}
function updateTrains(){
  for(const p of CARPOOL.values())p.n=0;ACTIVE.length=0;
  const t=CLOCK<4*3600?CLOCK+86400:CLOCK;
  for(const r of RUNS){if(r.tStart>t)break;if(r.tEnd<t)continue;const st=runState(r,t);r.st=st;ACTIVE.push(r);
    const far=Math.abs(st.l.path.at(st.s).x-camera.position.x)+Math.abs(st.l.path.at(st.s).z-camera.position.z)>4500;r.poses=[];
    for(let i=0;i<r.spec.n;i++){const ps=carPose(r,st,i);r.poses.push(ps);if(far)continue;const p=r.pool;if(p.n>=500)continue;
      _dm.position.set(ps.x,ps.y,ps.z);_dm.rotation.set(0,ps.ry,0);_dm.updateMatrix();p.mb.setMatrixAt(p.n,_dm.matrix);p.mw.setMatrixAt(p.n,_dm.matrix);p.n++;}}
  for(const p of CARPOOL.values()){p.mb.count=p.mw.count=p.n;p.mb.instanceMatrix.needsUpdate=p.mw.instanceMatrix.needsUpdate=true;}
}

/* ===== train separation: followers wait, slower trains step aside onto real passing tracks ===== */
const PASSC=new Map();
function passOff(l,s,side){const key=l.key+'|'+Math.round(s)+'|'+side;if(PASSC.has(key))return PASSC.get(key);
  const p=l.path.at(s);const vx=-p.tz,vz=p.tx;const lane=l.path.laneOff(s,side);const half=Math.min(l.plat/2,90);const offs=[];
  for(const t of TRACKS){const a=t.pts;let near=false;for(let i=0;i<a.length;i+=2){if(Math.abs(a[i]-p.x)<half+40&&Math.abs(a[i+1]-p.z)<half+40){near=true;break;}}if(!near)continue;
    for(let i=0;i+3<a.length;i+=2){const ax=a[i],az=a[i+1],bx=a[i+2],bz=a[i+3];const dx=bx-ax,dz=bz-az,L0=Math.hypot(dx,dz);if(L0<0.5)continue;if(Math.abs((dx*p.tx+dz*p.tz)/L0)<0.97)continue;
      for(let k=0;k<=L0;k+=4){const x=ax+dx*k/L0,z=az+dz*k/L0;const al=(x-p.x)*p.tx+(z-p.z)*p.tz;if(Math.abs(al)>half*0.6)continue;const o=(x-p.x)*vx+(z-p.z)*vz;if((o-lane)*side>2.8&&(o-lane)*side<16.5)offs.push(o);}}}
  let r=null;if(offs.length>=6){offs.sort((a,b)=>(a-b)*side);r=offs[Math.floor(offs.length*0.3)];}
  PASSC.set(key,r);return r;}
const LANEID=new Map();
function sampleRun(r){const t0=Math.ceil(r.tStart/10)*10;const n=Math.max(1,Math.floor((r.tEnd-t0)/10)+1);r.sT0=t0;r.sN=n;r.sL=new Int16Array(n);r.sS=new Float32Array(n);r.sI=new Int16Array(n);
  for(let i=0;i<n;i++){const st=runState(r,t0+i*10);let id=LANEID.get(st.l.key+st.d);if(id===undefined){id=LANEID.size;LANEID.set(st.l.key+st.d,id);}r.sL[i]=(st.l.single||(st.dwell&&st.e.pass!==undefined))?-1:id;r.sS[i]=st.s;r.sI[i]=st.idx;}r.half=(r.spec.n*r.spec.len)/2;}
function shiftRun(r,from,delta){for(let i=from;i<r.tl.length;i++)r.tl[i].t0+=delta;r.tEnd+=delta;if(from===0)r.tStart+=delta;}
function stationTracks(l,s){const fx=ST_TRACKS[l.key+'|'+(l.st.find(q=>Math.abs(q.s-s)<120)||[''])[0]];if(fx)return fx.slice();const p=l.path.at(s);const vx=-p.tz,vz=p.tx;const half=Math.min(l.plat/2,90);const offs=[];
  for(const t of TRACKS){const a=t.pts;let near=false;for(let i=0;i<a.length;i+=2){if(Math.abs(a[i]-p.x)<half+40&&Math.abs(a[i+1]-p.z)<half+40){near=true;break;}}if(!near)continue;
    for(let i=0;i+3<a.length;i+=2){const ax=a[i],az=a[i+1],bx=a[i+2],bz=a[i+3];const dx=bx-ax,dz=bz-az,L0=Math.hypot(dx,dz);if(L0<0.5)continue;if(Math.abs((dx*p.tx+dz*p.tz)/L0)<0.97)continue;
      for(let k=0;k<=L0;k+=4){const x=ax+dx*k/L0,z=az+dz*k/L0;const al=(x-p.x)*p.tx+(z-p.z)*p.tz;if(Math.abs(al)>half*0.5)continue;const o=(x-p.x)*vx+(z-p.z)*vz;if(Math.abs(o)<16)offs.push(o);}}}
  offs.sort((a,b)=>a-b);const cl=[];let cur=[];for(const o of offs){if(cur.length&&o-cur[cur.length-1]>2.5){cl.push(cur);cur=[];}cur.push(o);}if(cur.length)cl.push(cur);
  return cl.filter(c=>c.length>=4).map(c=>c[Math.floor(c.length/2)]);}
/* stations where the game's line simply ends but real trains run on (no terminal track juggling there) */
const VIRTUAL_END=new Set(['odn|相模大野','jr|茅ヶ崎','jr|横浜','blu|横浜','eno|七里ヶ浜','sot|海老名']);
const STGRP=k=>k==='odn'||k==='ods'?'od':k;
function isReversal(r,i){const e=r.tl[i];const n=r.tl[i+1];if(!n||n.k!=='move')return false;if(n.l===e.l)return n.d!==e.d;
  const a=e.l.path.at(e.s),b=n.l.path.at(n.sA);return (a.tx*e.d)*(b.tx*n.d)+(a.tz*e.d)*(b.tz*n.d)<0;}
function assignTerminalTracks(){
  const ev=new Map();
  for(const r of RUNS)for(let i=0;i<r.tl.length;i++){const e=r.tl[i];if(e.k!=='dwell'||e.l.single)continue;
    const term=e.origin||e.last||(i<r.tl.length-1&&r.tl[i+1].k==='move'&&r.tl[i+1].l!==e.l&&isReversal(r,i));if(!term)continue;
    if(VIRTUAL_END.has(e.l.key+'|'+e.name))continue;
    const key=STGRP(e.l.key)+'|'+e.name;if(!ev.has(key))ev.set(key,[]);ev.get(key).push({r,e,t0:e.t0,t1:e.t0+e.T});}
  let n=0;
  for(const [key,list] of ev){const e0=list[0].e;const tr=stationTracks(e0.l,e0.s);if(tr.length<2)continue;list.sort((a,b)=>a.t0-b.t0);const busy=tr.map(()=>-1e9);
    const ref=e0.l.path.at(e0.s);
    for(const it of list){let best=-1;for(let k=0;k<tr.length;k++){if(busy[k]<it.t0-20&&(best<0||busy[k]<busy[best]))best=k;}if(best<0){best=0;for(let k=1;k<tr.length;k++)if(busy[k]<busy[best])best=k;}
      const p=it.e.l.path.at(it.e.s);const flip=p.tx*ref.tx+p.tz*ref.tz<0?-1:1;
      // offset of the chosen track measured in this run's own line frame
      const wx=ref.x-ref.tz*tr[best],wz=ref.z+ref.tx*tr[best];it.e.pass=(wx-p.x)*(-p.tz)+(wz-p.z)*p.tx;it.e.passProf=passProfile(it.e.l,it.e.s,it.e.pass);busy[best]=it.t1;n++;}}
  console.log('LOG terminal tracks',n);
}
/* single-track lines: trains keep to the line centre, but step onto the passing loop at stations */
/* a terminal/passing track followed along the real OSM rails (tracks converge and bend towards the throat) */
const PPC=new Map();
function passProfile(l,sC,o0,half=160){const key=l.key+'|'+Math.round(sC)+'|'+o0.toFixed(1)+'|'+half;if(PPC.has(key))return PPC.get(key);if(ST_TRACKS[l.key+'|'+(l.st.find(q=>Math.abs(q.s-sC)<120)||[''])[0]+'|fixed']){PPC.set(key,null);return null;}
  const step=5,N=Math.round(half*2/step),s0=sC-N/2*step;const out=new Float32Array(N+1);const near=[];const c=l.path.at(sC);
  for(const t of TRACKS){const a=t.pts;for(let i=0;i<a.length;i+=2)if(Math.abs(a[i]-c.x)<200&&Math.abs(a[i+1]-c.z)<200){near.push(t);break;}}
  const at=(s,prev)=>{const p=l.path.at(s);let best=null;for(const t of near){const a=t.pts;for(let i=0;i+3<a.length;i+=2){const ax=a[i],az=a[i+1],dx=a[i+2]-ax,dz=a[i+3]-az,L0=dx*dx+dz*dz;if(L0<0.1)continue;
      const u=((p.x-ax)*dx+(p.z-az)*dz)/L0;if(u<-0.05||u>1.05)continue;if(Math.abs((dx*p.tx+dz*p.tz)/Math.sqrt(L0))<0.9)continue;
      const k=clamp(u,0,1);const o=(ax+dx*k-p.x)*(-p.tz)+(az+dz*k-p.z)*p.tx;const along=(ax+dx*k-p.x)*p.tx+(az+dz*k-p.z)*p.tz;if(Math.abs(along)>3)continue;if(Math.abs(o-prev)<1.6&&(!best||Math.abs(o-prev)<Math.abs(best-prev)))best=o;}}return best;};
  const mid=N/2;out[mid]=o0;for(let i=mid+1;i<=N;i++){const v=at(s0+i*step,out[i-1]);out[i]=v===null?out[i-1]:v;}for(let i=mid-1;i>=0;i--){const v=at(s0+i*step,out[i+1]);out[i]=v===null?out[i+1]:v;}
  const f=s=>{const x=clamp((s-s0)/step,0,N-0.001),i=x|0;return lerp(out[i],out[i+1],x-i);};PPC.set(key,f);return f;}
const LOOPC=new Map();
function loopOff(l,s,side){let a=LOOPC.get(l);if(!a){a=new Float32Array(Math.ceil(l.path.L/5)+2);for(const st of l.st){if(NO_LOOP.has(l.key+'|'+st[0]))continue;const r=l.plat/2+20;for(let i=Math.max(0,Math.floor((st.s-r-60)/5));i<a.length&&i*5<st.s+r+60;i++){const d=Math.abs(i*5-st.s);a[i]=Math.max(a[i],1-smooth(r,r+55,d));}}LOOPC.set(l,a);}
  const f=clamp(s/5,0,a.length-1.001),i=f|0;return lerp(a[i],a[i+1],f-i)*side*1.7;}
/* single-track lines (江ノ電・モノレール): every section between two stations is a block.
   Trains are taken in departure order; a train only leaves a station when the next section is clear of
   oncoming trains (and of a same-direction train still in it or standing at the far station). Meets happen in the loops. */
function scheduleSingleTrack(){
  for(const k in LINES){const l=LINES[k];if(!l.single)continue;
    const runs=RUNS.filter(r=>r.tl.every(e=>e.l===l)).sort((a,b)=>a.tStart-b.tStart);const occ=[];let held=0,maxRun=0;for(const r of runs)r.plan0=r.tStart;
    const sec=(a,b)=>{const i=l.st.findIndex(q=>Math.abs(clamp(q.s,0,l.path.L)-a)<l.plat);const j=l.st.findIndex(q=>Math.abs(clamp(q.s,0,l.path.L)-b)<l.plat);return [Math.min(a,b),Math.max(a,b)];};
    for(const r of runs){let lastOcc=null;
      for(let i=0;i<r.tl.length;i++){const e=r.tl[i];if(e.k!=='move')continue;const [a,b]=sec(e.sA,e.sB);
        const nx=r.tl[i+1];const tEnd=()=>e.t0+e.T+(nx&&nx.k==='dwell'?nx.T:0);
        let maxH=0;
        for(let guard=0;guard<200;guard++){let wait=0;const t0=e.t0,t1=e.t0+e.T,te=tEnd();
          for(const o of occ){if(o.b<=a+1||o.a>=b-1)continue;
            if(o.d===e.d){if(t0<o.tEndDw+8&&te>o.t0-8)wait=Math.max(wait,o.tEndDw+8-t0);}
            else if(t0<o.t1+6&&t1>o.t0-6)wait=Math.max(wait,o.t1+6-t0);}
          if(wait<=0)break;wait=Math.ceil(wait);const pd=r.tl[i-1];
          if(pd&&pd.k==='dwell'){pd.T+=wait;shiftRun(r,i,wait);if(lastOcc)lastOcc.tEndDw+=wait;}else shiftRun(r,0,wait);held+=wait;}
        lastOcc={a,b,d:e.d,t0:e.t0,t1:e.t0+e.T,tEndDw:tEnd()};occ.push(lastOcc);}
      maxRun=Math.max(maxRun,r.tStart-r.plan0);}
    console.log('LOG single-track',k,runs.length,'held s',Math.round(held),'max start shift',maxRun);}
}
const UNRES=[];function resolveOvertakes(){
  assignTerminalTracks();
  for(const r of RUNS){r.lines=new Set(r.tl.map(e=>e.l));sampleRun(r);}
  const dirOf=id=>{for(const [k,v] of LANEID)if(v===id)return k.endsWith('-1')?-1:1;return 1;};
  const DIR=[];for(const [k,v] of LANEID)DIR[v]=k.endsWith('-1')?-1:1;
  let waits=0,passes=0,left=0;
  for(let pass=0;pass<60;pass++){let changed=0;const dirty=new Set();
    RUNS.sort((a,b)=>a.tStart-b.tStart);
    for(let ai=0;ai<RUNS.length;ai++){const A=RUNS[ai];if(dirty.has(A))continue;
      for(let bi=ai+1;bi<RUNS.length;bi++){const B=RUNS[bi];if(B.tStart>A.tEnd)break;if(dirty.has(B))continue;
        let share=false;for(const l of B.lines)if(A.lines.has(l)){share=true;break;}if(!share)continue;
        const t0=Math.max(A.sT0,B.sT0),t1=Math.min(A.sT0+(A.sN-1)*10,B.sT0+(B.sN-1)*10);if(t1<t0)continue;
        let prevRel=null,viol=null;
        for(let t=t0;t<=t1;t+=10){const ia=(t-A.sT0)/10,ib=(t-B.sT0)/10;const la=A.sL[ia],lb=B.sL[ib];if(la<0||lb<0||la!==lb){prevRel=null;continue;}
          const d=DIR[la];const rel=(B.sS[ib]-A.sS[ia])*d;const gap=Math.abs(rel)-(A.half+B.half);
          if(gap<12){const relSign=prevRel!==null?Math.sign(prevRel):Math.sign(rel);viol={t,d,lane:la,ia,ib,follower:relSign>0?A:B,leader:relSign>0?B:A};break;}prevRel=rel;}
        if(!viol)continue;
        const X=viol.follower,Y=viol.leader;
        // try: faster follower passes the slower leader at a station with a passing track
        let done=false;
        if(X.stops.size<Y.stops.size){
          const iy=(viol.t-Y.sT0)/10;const curIdx=Y.sI[Math.max(0,iy)];
          for(let k=curIdx;k>=0&&!done;k--){const e=Y.tl[k];if(e.k!=='dwell')continue;if(viol.t-(e.t0+e.T)>900)break;if(e.pass!==undefined||e.origin)continue;
            const side=-e.d;const po=passOff(e.l,e.s,side);if(po===null)continue;
            // time when X's tail has cleared the station
            let tp=null;for(let t=Math.max(e.t0,X.sT0);t<X.sT0+X.sN*10;t+=10){const ix=(t-X.sT0)/10;const st=runState(X,t);if(st.l===e.l&&st.d===e.d&&(st.s-e.s)*e.d>X.half+Y.half+20){tp=t;break;}}
            if(tp===null)continue;const need=tp+15-(e.t0+e.T);e.pass=po;if(need>0){e.T+=need;shiftRun(Y,k+1,need);}passes++;done=true;dirty.add(Y);}
        }
        if(!done){// follower waits longer at its last stop before the conflict
          const ix=(viol.t-X.sT0)/10;let k=X.sI[Math.max(0,ix)];while(k>0&&!(X.tl[k].k==='dwell'&&X.tl[k].t0+X.tl[k].T<=viol.t-5))k--;
          if(k<0)k=0;const e=X.tl[k];if((e.wait||0)>900){left++;UNRES.push([...LANEID].find(q=>q[1]===viol.lane)[0]+' '+X.type+'/'+Y.type);continue;}const dl=40;
          if(e.k==='dwell'){e.T+=dl;e.wait=(e.wait||0)+dl;shiftRun(X,k+1,dl);}else shiftRun(X,0,dl);waits++;dirty.add(X);}
        changed++;break;}
    }
    for(const r of dirty)sampleRun(r);
    if(!changed)break;}
  RUNS.sort((a,b)=>a.tStart-b.tStart);
  console.log('LOG separation: passes',passes,'waits',waits,'unresolved',left);if(window.__WDEBUG){const c={};for(const u of UNRES)c[u]=(c[u]||0)+1;console.log('LOG unres',JSON.stringify(c));}
  resolveWorldConflicts();
}
/* ===== world-space check: no two trains may share the same piece of track at the same moment =====
   catches what the per-lane check cannot: single-track meets, the 藤沢 switchback (two line keys, one station),
   terminal throats and junctions. The train that entered later is held at its previous stop. */
const WSTEP=4;
function wSample(r){const t0=Math.ceil(r.tStart/WSTEP)*WSTEP;const n=Math.max(1,Math.floor((r.tEnd-t0)/WSTEP)+1);r.wT0=t0;r.wN=n;r.wX=new Float32Array(n);r.wZ=new Float32Array(n);
  for(let i=0;i<n;i++){const st=runState(r,t0+i*WSTEP);const p=st.l.path.at(st.s);r.wX[i]=p.x;r.wZ[i]=p.z;}r.wHalf=(r.spec.n*r.spec.len+(r.spec.n-1)*0.8)/2;}
function trainBoxes(r,t){const st=runState(r,t);const out=[];const tl=r.tl;
  const fake={...r,st};for(let i=0;i<r.spec.n;i++){out.push(carPose(fake,st,i));}return {st,cars:out};}
function carsClash(A,B,lenA,lenB){for(const a of A){const c=Math.cos(a.ry),s=Math.sin(a.ry);for(const b of B){if(Math.abs(a.y-b.y)>3)continue;const dx=b.x-a.x,dz=b.z-a.z;
  const al=dx*c-dz*s,lat=dx*s+dz*c;if(Math.abs(al)<(lenA+lenB)/2-0.5&&Math.abs(lat)<2.6)return true;}}return false;}
function lastStopBefore(r,t){let k=-1;for(let i=0;i<r.tl.length;i++){const e=r.tl[i];if(e.t0>t)break;if(e.k==='dwell'&&e.t0+e.T<=t-2)k=i;}return k;}
const TGRP={odn:'od',ods:'od',sot:'so',izm:'so',jr:'jr',blu:'blu',eno:'eno',mono:'mono'};
function touch(A,B){if(!A.grp)A.grp=new Set([...A.lines].map(l=>TGRP[l.key]));if(!B.grp)B.grp=new Set([...B.lines].map(l=>TGRP[l.key]));for(const g of A.grp)if(B.grp.has(g))return true;return false;}
/* greedy dispatcher: runs are fixed one at a time in departure order. Each new run is checked against the ones
   already fixed, leg by leg, with the real car positions. If it would touch another train it is held at the stop
   before that leg (10 s at a time). Earlier runs never move, so this always settles. */
function resolveWorldConflicts(){
  const T0=performance.now();const BK=60;const buckets=new Map();let holds=0,stuck=0,retrack=0;
  const addIdx=r=>{wSample(r);for(let b=Math.floor(r.tStart/BK);b<=Math.floor(r.tEnd/BK);b++){let a=buckets.get(b);if(!a)buckets.set(b,a=[]);a.push(r);}};
  const clashAt=(Y,t)=>{const a=buckets.get(Math.floor(t/BK));if(!a)return false;const sy=runState(Y,t);const py=sy.l.path.at(sy.s);let yb=null;
    for(const X of a){if(X.tStart>t||X.tEnd<t||!touch(X,Y))continue;const i=Math.round((t-X.wT0)/WSTEP);if(i<0||i>=X.wN)continue;const lim=X.wHalf+Y.wHalf+8;const dx=X.wX[i]-py.x,dz=X.wZ[i]-py.z;if(dx*dx+dz*dz>lim*lim)continue;
      if(!yb)yb=trainBoxes(Y,t).cars;const xb=trainBoxes(X,t).cars;if(carsClash(yb,xb,Y.spec.len,X.spec.len))return true;}return false;};
  const firstClash=(Y,ta,tb)=>{for(let t=Math.ceil(ta/WSTEP)*WSTEP;t<=tb;t+=WSTEP)if(clashAt(Y,t))return t;return null;};
  const order=RUNS.slice().sort((a,b)=>a.tStart-b.tStart);
  for(const Y of order){Y.wHalf=(Y.spec.n*Y.spec.len+(Y.spec.n-1)*0.8)/2;
    for(let i=0;i<Y.tl.length;i++){const e=Y.tl[i];if(e.k!=='move')continue;const pd=i>0&&Y.tl[i-1].k==='dwell'?Y.tl[i-1]:null;const nd=Y.tl[i+1]&&Y.tl[i+1].k==='dwell'?Y.tl[i+1]:null;
      for(let g=0;g<100;g++){const ta=pd?pd.t0:e.t0,tb=e.t0+e.T+(nd?nd.T:0);const tc=firstClash(Y,ta,tb);if(tc===null)break;
        if(nd&&nd.pass===undefined&&tc>=nd.t0-2&&!nd.tried&&!nd.l.single&&!nd.last){const po=passOff(nd.l,nd.s,-nd.d);if(po!==null){nd.tried=1;nd.pass=po;if(firstClash(Y,nd.t0-30,nd.t0+nd.T)===null){retrack++;continue;}delete nd.pass;}}
        if(nd&&nd.pass!==undefined&&tc>=nd.t0-2&&!nd.tried){nd.tried=1;const tr=stationTracks(nd.l,nd.s);const keep=nd.pass;let ok=false;
          for(const o of tr){if(Math.abs(o-keep)<1)continue;nd.pass=o;if(firstClash(Y,nd.t0-30,nd.t0+nd.T)===null){ok=true;break;}}if(ok){retrack++;continue;}nd.pass=keep;}
        if(tc<e.t0-1){ // hit while standing at the station
          if(pd.origin){shiftRun(Y,0,10);holds++;continue;}
          if(pd.pass===undefined&&!pd.tried&&!pd.l.single){const po=passOff(pd.l,pd.s,-pd.d);if(po!==null){pd.tried=1;pd.pass=po;if(firstClash(Y,pd.t0-30,e.t0+2)===null){retrack++;continue;}delete pd.pass;}}
          if(pd.pass!==undefined&&!pd.tried){pd.tried=1;const tr=stationTracks(pd.l,pd.s);const keep=pd.pass;let ok=false;for(const o of tr){if(Math.abs(o-keep)<1)continue;pd.pass=o;if(firstClash(Y,pd.t0-30,e.t0+e.T)===null){ok=true;break;}}if(ok){retrack++;continue;}pd.pass=keep;}
          stuck++;break;}
        if(pd){pd.T+=10;shiftRun(Y,i,10);}else shiftRun(Y,0,10);holds++;}}
    addIdx(Y);}
  RUNS.sort((a,b)=>a.tStart-b.tStart);
  console.log('LOG dispatcher: holds',holds,'retracked',retrack,'stuck',stuck,'ms',Math.round(performance.now()-T0));
}
