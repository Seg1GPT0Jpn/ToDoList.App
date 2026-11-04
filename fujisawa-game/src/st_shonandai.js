
/* ================= 湘南台駅 (小田急・相鉄・ブルーライン) =================
   Ground: 小田急 2 side platforms (2面2線) under one long glass roof, as in the aerial photo.
   B1: one east–west concourse under the whole station (free passage on the north side, the three paid areas
       side by side: 相鉄 west, 小田急 under its tracks, ブルーライン east), eight street exits at the OSM entrance points.
   B2: ブルーライン island platform. B3: 相鉄いずみ野線 island platform (OSM puts it one level below the subway).
   Frame F: origin on the 小田急 centre line at the station, +a ≈ east along the 相鉄/地下鉄 axis, +b ≈ south. */
(()=>{
const NAME='湘南台';const O=[-1895.2,-6385.1],ANG=Math.atan2(-0.261,0.965);
LINE_EXT.izm=170;                       // tunnel tail west of the 相鉄 terminal
ST_S['izm|湘南台']=166.7;ST_S['blu|湘南台']=58;
PROF_ADJ.push({key:'izm',s0:0,s1:290,y:11.9,blend:420},{key:'blu',s0:0,s1:175,y:18.3,blend:320});
ST_TRACKS['izm|湘南台']=[-5.8,5.8];ST_TRACKS['blu|湘南台']=[-5.4,5.4];ST_TRACKS['izm|湘南台|fixed']=1;ST_TRACKS['blu|湘南台|fixed']=1;
LANE_ADJ.push({key:'izm',s0:0,s1:285,lo:-5.8,hi:5.8,blend:140},{key:'blu',s0:0,s1:172,lo:-5.4,hi:5.4,blend:120});
{const F=stFrame(O[0],O[1],ANG);BLD_CLEAR.push([O[0],O[1],ANG,11.5,104]);const c=F.W(-6,7);PLAT_CLEAR.push([c[0],c[1],ANG,135,16],[O[0],O[1],ANG,12,110]);
  for(const [x,z,r] of [[-1623.2,-6585.0,19],[-1609.2,-6547.5,13]])BLD_CLEAR.push([x,z,0,r,r]);}
const ENTS=[ // top of the stairs at street level (OSM railway=subway_entrance), direction the stairs go down, exit name
  {a:-53.2,b:-13.9,da:-1,db:0,name:'西口',n:'W1'},{a:-42.2,b:46.1,da:0,db:-1,name:'西口',n:'W2'},{a:-159.3,b:4.3,da:1,db:0,name:'西口',n:'W3'},{a:-158.3,b:19.6,da:1,db:0,name:'西口',n:'W4'},
  {a:35.2,b:-33.2,da:0,db:1,name:'東口',n:'E1'},{a:155.7,b:0.8,da:-1,db:0,name:'東口',n:'E2'},{a:45.0,b:64.6,da:0,db:-1,name:'東口',n:'E3'},{a:85.5,b:57.4,da:0,db:-1,name:'東口',n:'E4'}];
const H_A0=-145,H_A1=140,H_B0=-10,H_B1=22; // B1 hall
function build(){
  const F=stFrame(O[0],O[1],ANG);const odn=LINES.odn,izm=LINES.izm,blu=LINES.blu;
  // east of the station the two tunnels run side by side for ~800 m: keep at least 8.2 m between the double tracks
  {const o=blu.path.offs;for(let i=0;i<o.length;i++){const ss=i*10;if(ss<170||ss>1000)continue;const p=blu.path.at(ss);const q=izm.path.near(p.x,p.z);const zp=izm.path.at(q.s);
    const sg=(zp.x-p.x)*(-p.tz)+(zp.z-p.z)*p.tx;const need=Math.max(0,8.2+Math.min(0,sg))*smooth(170,230,ss);if(sg<0&&need>0)o[i]=[o[i][0]+need,o[i][1]+need];}}
  const g0=demH(O[0],O[1]);const B1=g0-6.6,B1c=B1+3.9;const B2t=blu.path.py(58)+1.1,B3t=izm.path.py(166.7)+1.1;
  const gb=new GB(),colls=[],inn=new GB(),out=new GB();inn.glass=new GB();
  const TILE=C_('#d9d4c9'),TILE2=C_('#c9c3b6'),WALL=C_('#eeebe4'),CEIL=C_('#f2f1ec'),DARK=C_('#3a3f45'),PAID=C_('#e3e8ec'),ODA=C_('#1a5fb4'),SOT=C_('#1d3c8f'),BLU=C_('#0072bc');
  /* ---------- ground: 小田急 platforms + glass roof ---------- */
  const sC=odn.stByName.get(NAME).s;const sA=sC-100,sB=sC+100;const top=odn.path.py(sC)+1.1;
  const stairTop=sC-2+0.0,stairRun=Math.ceil((top-B1)/0.28)*0.42;const h0=sC-2-stairRun-0.4,h1=sC-1.6; // opening in s
  const pf=[];
  for(const sd of [-1,1]){const inner=sd*3.8,outer=sd*9.4;
    const pieces=[[sA,h0,inner,outer],[h1,sB,inner,outer],[h0,h1,inner,inner+sd*1.05]];
    for(const [s0,s1,o0,o1] of pieces){const poly=platformAlong(gb,colls,odn,s0,s1,o0,o1,top);const b=addPoly(poly,top-1.2,top);b.tag=0;b.plat=true;}
    const rp=[];for(const [s,o] of [[sA,inner],[sB,inner],[sB,outer],[sA,outer]]){const p=odn.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,top,odn,false,false);
    // stair down to B1 (descending towards smaller s = south) + escalator, in the opening
    const p=odn.path.at(stairTop,sd*6.4);const ang=Math.atan2(-p.tz,-p.tx);const run=stairsGB(inn,colls,p.x,p.z,ang,top,B1,2.6);
    {const q=odn.path.at(stairTop,sd*8.55);const Fe=stFrame(q.x,q.z,ang);escalatorVis(inn,Fe,0,0,1,top,B1,1.0);}
    // shaft walls (inner faces) from B1 up to the platform deck, railing on the deck around the opening
    const sm=(h0+h1)/2,pm=odn.path.at(sm,sd*7.2);const Fs=stFrame(pm.x,pm.z,Math.atan2(pm.tz,pm.tx));const hl=(h1-h0)/2;
    roomShell(inn,Fs,-hl,hl,-2.2,2.2,B1,top-0.02,WALL,null,null,{wallMask:4|8|16|32});
    regZone(Fs,-hl,hl,-2.2,2.2,B1-0.5,top+4,NAME,odn,B1,null,false);terrainHole(pm.x,pm.z,Fs.ang,hl,2.2);
    for(const [a0,a1,b0,b1] of [[-hl,hl,-sd*2.2-0.05*sd,-sd*2.2],[-hl,-hl+0.06,-2.2,2.2]]){const c=Fs.W((a0+a1)/2,(b0+b1)/2);inn.obox(c[0],c[1],Fs.ux,Fs.uz,Math.abs(a1-a0)/2+0.03,Math.abs(b1-b0)/2+0.03,top,top+1.1,C_('#b8c0c6'));colls.push(addOBB(c[0],c[1],Math.abs(a1-a0)/2+0.03,Math.abs(b1-b0)/2+0.03,Fs.ang,top,top+1.1));}
    // outer fence, benches, signs
    for(let s=sA;s<sB;s+=10){const a=odn.path.at(s+5,outer-sd*0.1);gb.obox(a.x,a.z,a.tx,a.tz,5,0.05,top,top+1.2,C_('#8e979e'));colls.push(addOBB(a.x,a.z,5,0.06,Math.atan2(a.tz,a.tx),top,top+1.2));}
    platformDressing(gb,colls,odn,sA,sB,sd*7.6,top,{every:30,ph:4.4,pc:'#d8dde1'});
    for(const s of [sA+30,sA+90,sC+40,sB-25]){const q=odn.path.at(s,sd*7.0);signBoard(q.x,top+2.6,q.z,Math.atan2(q.tz,q.tx),1.9,0.48,'湘南台','しょうなんだい  Shōnandai  OE 09','#1a5fb4');}
  }
  // one long glass roof over both platforms and tracks, steel frame
  {const roofY=top+5.2;const glassM=new THREE.MeshLambertMaterial({color:'#9fc3d6',transparent:true,opacity:0.45,side:THREE.DoubleSide,depthWrite:false});const rg=new GB();
    for(let s=sA-4;s<sB+4;s+=4){const a=odn.path.at(s,-10.6),b=odn.path.at(s,10.6),c=odn.path.at(s+4,10.6),d=odn.path.at(s+4,-10.6);const bow=0.9;
      const mid=(p,q,y)=>[(p.x+q.x)/2,y,(p.z+q.z)/2];rg.quad([a.x,roofY,a.z],[d.x,roofY,d.z],mid(d,c,roofY+bow),mid(a,b,roofY+bow),0,1,0,C_('#ffffff'));rg.quad(mid(a,b,roofY+bow),mid(d,c,roofY+bow),[c.x,roofY,c.z],[b.x,roofY,b.z],0,1,0,C_('#ffffff'));}
    const gm=new THREE.Mesh(rg.geo(),glassM);gm.renderOrder=2;scene.add(gm);
    for(let s=sA-4;s<=sB+4;s+=8){const a=odn.path.at(s,0);gb.obox(a.x,a.z,-a.tz,a.tx,10.8,0.12,roofY-0.1,roofY+0.95,C_('#6f7a84'));}
    for(const o of [-10.6,0,10.6]){for(let s=sA-4;s<sB+4;s+=10){const a=odn.path.at(s+5,o);gb.obox(a.x,a.z,a.tx,a.tz,5,0.12,roofY-0.15+(o===0?0.9:0),roofY+(o===0?1.0:0.1),C_('#6f7a84'));}}
    for(const sd of [-1,1])for(let s=sA+6;s<sB;s+=16){if(Math.abs(s-(h0+h1)/2)<10)continue;const a=odn.path.at(s,sd*8.9);gb.obox(a.x,a.z,a.tx,a.tz,0.22,0.22,top,roofY,C_('#7c8790'));colls.push(addOBB(a.x,a.z,0.22,0.22,0,top,roofY));}}
  /* ---------- B1 concourse ---------- */
  roomShell(inn,F,H_A0,H_A1,H_B0,H_B1,B1,B1c,WALL,null,CEIL);
  const holes=[];const SOT_A=-40,BLU_A=108;const sotRun=Math.ceil((B1-B3t)/0.28)*0.42,bluRun=Math.ceil((B1-B2t)/0.28)*0.42;
  holes.push([SOT_A-sotRun-0.6,SOT_A+0.2,7.1-1.7,7.1+3.6],[BLU_A-0.2,BLU_A+bluRun+0.6,12.6-1.6,12.6+3.4]);
  slabWithHoles(inn,colls,F,H_A0,H_A1,H_B0,H_B1,B1,0.4,holes,TILE,null);
  // floor pattern: darker guide band along the free passage
  {const c=F.W((H_A0+H_A1)/2,-6);inn.obox(c[0],c[1],F.ux,F.uz,(H_A1-H_A0)/2,0.4,B1,B1+0.01,C_('#f2d33c'),1);}
  const EG=ENTS.map(e=>{const tw=F.W(e.a,e.b);e.gy=demH(tw[0],tw[1])+0.05;e.run=Math.ceil((e.gy-B1)/0.28)*0.42;e.ba=e.a+e.da*e.run;e.bb=e.b+e.db*e.run;
    if(e.bb<H_B0){e.cor='b';e.side=0;}else if(e.bb>H_B1){e.cor='b';e.side=1;}else if(e.ba<H_A0){e.cor='a';e.side=2;}else{e.cor='a';e.side=3;}
    return e.cor==='b'?[e.side,e.ba-2,e.ba+2]:[e.side,e.bb-2,e.bb+2];});
  rectWalls(colls,F,H_A0,H_A1,H_B0,H_B1,B1,B1c,EG);
  // pillars in the free areas
  for(let a=H_A0+10;a<H_A1-5;a+=12)for(const b of [-6,18]){const c=F.W(a,b);if(holes.some(h=>a>h[0]-1&&a<h[1]+1&&b>h[2]-1&&b<h[3]+1))continue;inn.obox(c[0],c[1],F.ux,F.uz,0.45,0.45,B1,B1c,C_('#e1ddd4'));colls.push(addOBB(c[0],c[1],0.45,0.45,F.ang,B1,B1c));}
  // ceiling lights
  {const lg=new GB();for(let a=H_A0+4;a<H_A1;a+=6)for(const b of [-6,6,18]){const c=F.W(a,b);lg.obox(c[0],c[1],F.ux,F.uz,1.5,0.18,B1c-0.06,B1c-0.01,C_('#ffffff'),2);}scene.add(new THREE.Mesh(lg.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));}
  // paid areas: [a0,a1, gate a0, gate a1, colour, label, sub]
  const PAIDS=[[-110,-20,-72,-52,'#1d3c8f','相鉄線','いずみ野線  Sotetsu Line'],[-14,14,-9,9,'#1a5fb4','小田急線','江ノ島線  Odakyu Line'],[95,135,100,120,'#0072bc','ブルーライン','横浜市営地下鉄  Blue Line']];
  for(const [a0,a1,g0a,g1a,col,lbl,sub] of PAIDS){
    const c=F.W((a0+a1)/2,6);inn.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2,8,B1,B1+0.012,C_('#e7e2d8'),1);
    partition(inn,colls,F,a0,-2,g0a-0.4,-2,B1);partition(inn,colls,F,g1a+0.4,-2,a1,-2,B1);partition(inn,colls,F,a0,14,a1,14,B1);partition(inn,colls,F,a0,-2,a0,14,B1);partition(inn,colls,F,a1,-2,a1,14,B1);
    const gc=F.W((g0a+g1a)/2,-2);gatesGB(inn,colls,gc[0],gc[1],F.ux,F.uz,g1a-g0a,B1);
    const mc=F.W(g0a-4,-8.6);machinesGB(inn,colls,mc[0],mc[1],F.ux,F.uz,4,B1);
    const sb=F.W((g0a+g1a)/2,-2.2);signBoard(sb[0],B1+3.2,sb[1],ANG,4.2,1.0,lbl,sub,col,true);
    // coloured band over the gates
    const bc=F.W((g0a+g1a)/2,-2.05);inn.obox(bc[0],bc[1],F.ux,F.uz,(g1a-g0a)/2+0.6,0.08,B1+2.65,B1+2.95,C_(col));}
  // exit signs over the free passage
  for(const [a,t] of [[-120,'← 西口  West'],[-30,'← 西口　東口 →'],[30,'← 西口　東口 →'],[125,'東口  East →']]){const c=F.W(a,-6);signBoard(c[0],B1+3.25,c[1],ANG,3.4,0.6,t,'','#f2d33c',true);}
  // a few kiosks / shops along the south wall
  for(const [a,w,c1,t] of [[-128,8,'#c8432f','ベーカリー'],[-2,6,'#2f8f4e','コンビニ'],[30,9,'#e8902f','カフェ'],[70,7,'#7a3e9d','花屋']]){const c=F.W(a,H_B1-2.2);inn.obox(c[0],c[1],F.ux,F.uz,w/2,2.0,B1,B1+2.8,C_('#f4efe6'));inn.obox(c[0],c[1],F.ux,F.uz,w/2+0.1,2.1,B1+2.8,B1+3.3,C_(c1));colls.push(addOBB(c[0],c[1],w/2,2.0,ANG,B1,B1+2.8));const s2=F.W(a,H_B1-4.25);signBoard(s2[0],B1+3.05,s2[1],ANG,Math.min(w-1,4),0.42,t,'',c1,true,false);}
  /* ---------- 相鉄 stairs B1 → B3, ブルーライン stairs B1 → B2 ---------- */
  stairDir(inn,colls,F,SOT_A,7.1,-1,0,B1,B3t,2.8);escalatorVis(inn,stFrame(...F.W(SOT_A,9.6),ANG+Math.PI),0,0,1,B1,B3t,1.0);
  {const s0=SOT_A-sotRun-0.6,s1=SOT_A+0.2;roomShell(inn,F,s0,s1,7.1-1.7,7.1+3.6,B3t+4.3,B1-0.4,WALL,null,null);}
  stairDir(inn,colls,F,BLU_A,12.6,1,0,B1,B2t,2.6);escalatorVis(inn,stFrame(...F.W(BLU_A,15.0),ANG),0,0,1,B1,B2t,1.0);
  /* ---------- B2 ブルーライン ---------- */
  {const s0=4,s1=112;const pt=B2t;const fl=blu.path.py(58)-0.3;
    roomShell(inn,F,52,178,4,24,fl,B2t+4.3,C_('#dfe6ec'),null,CEIL);
    const f2=flatPolyRect(F,52,178,4,24);const fb=addPoly(f2,fl-0.4,fl);fb.tag=0;inn.obox(...F.W(115,14),F.ux,F.uz,63,10,fl-0.3,fl,C_('#6f6a63'),1);
    for(const sd of [-1,1]){const poly=platformAlong(inn,colls,blu,s0,s1,sd*3.85,0,pt);const b=addPoly(poly,pt-1.2,pt);b.tag=0;b.plat=true;}
    const rp=[];for(const [s,o] of [[s0,-3.85],[s1,-3.85],[s1,3.85],[s0,3.85]]){const p=blu.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,pt,blu,true,false);
    platformDressing(inn,colls,blu,s0,s1,0,pt,{every:18,ph:4.2,pc:'#e6ebef'});
    for(const s of [20,60,95]){const q=blu.path.at(s,0);signBoard(q.x,pt+2.7,q.z,Math.atan2(q.tz,q.tx),2.2,0.55,'湘南台','しょうなんだい  Shōnandai  B 01','#0072bc');}
    rectWalls(colls,F,52,178,4,24,fl,B2t+4.3);
    for(const sd of [-1,1]){const c=F.W(sd>0?178+60:52-30,14);inn.obox(c[0],c[1],F.ux,F.uz,sd>0?60:30,10,fl-0.3,B2t+4.3,DARK,2|4|8);}}
  /* ---------- B3 相鉄 ---------- */
  {const s0=166.7-113,s1=166.7+113;const pt=B3t;const fl=izm.path.py(166.7)-0.3;
    roomShell(inn,F,-133,121,-1,15.2,fl,B3t+4.3,C_('#e4e6ea'),null,CEIL);inn.obox(...F.W(-6,7.1),F.ux,F.uz,127,8.1,fl-0.3,fl,C_('#6f6a63'),1);
    for(const sd of [-1,1]){const poly=platformAlong(inn,colls,izm,s0,s1,sd*4.25,0,pt);const b=addPoly(poly,pt-1.2,pt);b.tag=0;b.plat=true;}
    const rp=[];for(const [s,o] of [[s0,-4.25],[s1,-4.25],[s1,4.25],[s0,4.25]]){const p=izm.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,pt,izm,true,false);
    platformDressing(inn,colls,izm,s0,s1,0,pt,{every:20,ph:4.2,pc:'#e2e5ea'});
    for(const s of [s0+25,166.7+30,s1-25]){const q=izm.path.at(s,0);signBoard(q.x,pt+2.7,q.z,Math.atan2(q.tz,q.tx),2.2,0.55,'湘南台','しょうなんだい  Shōnandai  SO 37','#1d3c8f');}
    rectWalls(colls,F,-133,121,-1,15.2,fl,B3t+4.3);
    const c=F.W(121+80,7.1);inn.obox(c[0],c[1],F.ux,F.uz,80,8.1,fl-0.3,B3t+4.3,DARK,2|4|8);const c2=F.W(-133-25,7.1);inn.obox(c2[0],c2[1],F.ux,F.uz,25,8.1,fl-0.3,B3t+4.3,DARK,2|4|8);}
  /* ---------- the one zone that holds all three levels ---------- */
  const Z=regZone(F,-150,182,-12,26,B3t-1.1-0.7,B1c+0.4,NAME,izm,B1,null);Z.floorC=B1;
  /* ---------- street exits ---------- */
  for(const e of ENTS){const tw=F.W(e.a,e.b);const gy0=e.gy,run=e.run,ba=e.ba,bb=e.bb;
    stairDir(inn,colls,F,e.a,e.b,e.da,e.db,gy0,B1,2.8);
    const sa0=Math.min(e.a,ba)-(e.da?0:1.6),sa1=Math.max(e.a,ba)+(e.da?0:1.6),sb0=Math.min(e.b,bb)-(e.db?0:1.6),sb1=Math.max(e.b,bb)+(e.db?0:1.6);
    roomShell(inn,F,sa0,sa1,sb0,sb1,B1,gy0-0.05,WALL,null,null);terrainHole(...F.W((sa0+sa1)/2,(sb0+sb1)/2),ANG,(sa1-sa0)/2+0.15,(sb1-sb0)/2+0.15);
    regZone(F,sa0-0.2,sa1+0.2,sb0-0.2,sb1+0.2,B1-0.5,gy0+5,NAME,izm,B1,null);
    {const fb=addPoly(flatPolyRect(F,sa0,sa1,sb0,sb1),B1-0.4,B1);fb.tag=0;const c=F.W((sa0+sa1)/2,(sb0+sb1)/2);inn.obox(c[0],c[1],F.ux,F.uz,(sa1-sa0)/2,(sb1-sb0)/2,B1-0.05,B1,TILE,1);}
    // corridor from the foot of the stairs to the hall
    let c0a,c1a,c0b,c1b,wsGap;
    if(e.cor==='b'){c0a=ba-2;c1a=ba+2;if(e.side===0){c0b=sb1;c1b=H_B0;wsGap=[1,ba-2,ba+2];}else{c0b=H_B1;c1b=sb0;wsGap=[0,ba-2,ba+2];}}
    else{c0b=bb-2;c1b=bb+2;if(e.side===2){c0a=sa1;c1a=H_A0;wsGap=[3,bb-2,bb+2];}else{c0a=H_A1;c1a=sa0;wsGap=[2,bb-2,bb+2];}}
    if(c1a-c0a>0.2&&c1b-c0b>0.2){roomShell(inn,F,c0a,c1a,c0b,c1b,B1,B1c,WALL,TILE,CEIL);regZone(F,c0a,c1a,c0b,c1b,B1-0.5,B1c+0.4,NAME,izm,B1,null);
      const fb=addPoly(flatPolyRect(F,c0a,c1a,c0b,c1b),B1-0.4,B1);fb.tag=0;
      rectWalls(colls,F,c0a,c1a,c0b,c1b,B1,B1c,e.cor==='b'?[[0,-1e9,1e9],[1,-1e9,1e9]]:[[2,-1e9,1e9],[3,-1e9,1e9]]);}
    // well walls: the street end is open, and the side the corridor leaves from
    const topSide=e.da<0?3:e.da>0?2:e.db>0?0:1;
    rectWalls(colls,F,sa0,sa1,sb0,sb1,B1,gy0+1.1,[[topSide,-1e9,1e9],wsGap]);
    // street-level entrance: parapet walls, roof, sign
    const ang=ANG+Math.atan2(e.db,e.da);const c=Math.cos(ang),s=Math.sin(ang);const L=Math.min(run,6.5);
    for(const sd of [-1,1]){const x=tw[0]+c*L/2-s*sd*1.65,z=tw[1]+s*L/2+c*sd*1.65;out.obox(x,z,c,s,L/2+0.2,0.15,gy0-0.4,gy0+1.1,C_('#c9ced3'));}
    {const x=tw[0]+c*L*0.55,z=tw[1]+s*L*0.55;out.obox(x,z,c,s,L*0.55+0.4,1.95,gy0+2.75,gy0+2.95,C_('#dfe3e6'));out.obox(x,z,c,s,L*0.55+0.4,1.98,gy0+2.6,gy0+2.75,C_('#1a5fb4'));
      for(const sd of [-1,1])for(const f2 of [0.05,1.05]){const xx=tw[0]+c*L*f2-s*sd*1.7,zz=tw[1]+s*L*f2+c*sd*1.7;out.obox(xx,zz,c,s,0.06,0.06,gy0,gy0+2.75,C_('#8e979e'));}
      signBoard(tw[0]-c*0.5,gy0+3.55,tw[1]-s*0.5,ang+Math.PI/2,3.0,0.75,'湘南台駅 '+e.name,'小田急線・相鉄線・ブルーライン','#1a5fb4');}
  }
  for(let i=LM.length-1;i>=0;i--)if(LM[i].name==='湘南台文化センター')LM.splice(i,1);
  /* ---------- 湘南台文化センター: the two spheres (planetarium & theatre), positions from the aerial photo ---------- */
  {const sm=new THREE.MeshStandardMaterial({color:'#e9edf0',metalness:0.55,roughness:0.32});
    for(const [x,z,r,k] of [[-1623.2,-6585.0,17.5,0.62],[-1609.2,-6547.5,11.0,0.55]]){const y=demH(x,z);const m=new THREE.Mesh(new THREE.SphereGeometry(r,48,32,0,Math.PI*2,0,Math.PI*(0.5+k*0.5)),sm);m.position.set(x,y+r*k,z);m.castShadow=m.receiveShadow=true;scene.add(m);
      addOBB(x,z,r*0.75,r*0.75,0,y,y+r*(1+k));const rim=new THREE.Mesh(new THREE.CylinderGeometry(r*0.82,r*0.86,1.2,40),M('#b9bec2'));rim.position.set(x,y+0.6,z);scene.add(rim);}
    landmark('湘南台文化センター','Shōnandai Cultural Center',-1617,-6568,45,{travel:true,y:demH(-1617,-6568)+40});}
  for(const [g,mat] of [[gb,MAT.top],[out,MAT.top]])if(!g.empty){const m=new THREE.Mesh(g.geo(),mat);m.castShadow=true;m.receiveShadow=true;scene.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),UGMAT);m.receiveShadow=true;scene.add(m);}
  if(!inn.glass.empty){const m=new THREE.Mesh(inn.glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
  addLabel('湘南台','小田急・相鉄・ブルーライン',O[0],B1+2.9,O[1]-8,'st','#1a5fb4',140,0.5);
}
ST_CUSTOM[NAME]={lines:new Set(['odn','izm','blu']),build};
})();
