/* ================= 横浜駅 (JR東日本・相鉄・横浜市営地下鉄ブルーライン) =================
   Sources: ja.wikipedia「横浜駅」駅構造, OSM (tracks, platforms ref 3;4–9;10, corridors level -1/-2, entrances),
   PLATEAU LOD2 (新相鉄ビル, JR横浜タワー), GSI aerial photo.
   - JR: ground station, 4 island platforms / 8 tracks numbered 3–10 from the 京急 side (east):
     3・4 京浜東北・根岸, 5・6 東海道 下り, 7・8 東海道 上り, 9・10 横須賀・湘南新宿. The game's 東海道線 runs on 6 (down)
     and 7 (up); 5 and 8 are the passing tracks. Free passages on B1 cross under the tracks: きた通路, 中央通路, みなみ通路.
     Gates: 中央北改札 / 中央南改札 on 中央通路, 北改札 on きた通路, 南改札 on みなみ通路; stairs from each paid concourse
     up to every island.
   - 相鉄: terminal on the 2nd floor of 新相鉄ビル (相鉄ジョイナス), 4 platforms / 3 tracks (頭端式4面3線): side platform,
     island (1・2番 降車), island (2番 乗車・3番), side platform. Gates at the 2F head end and on the 1F under the middle
     of the platforms (みなみ西口 side); the 2F gate area is linked to the JR みなみ通路 by stairs down to B1.
   - ブルーライン: island platform on B3, gates on B2, linked to みなみ通路 (B1) and to street exit 5.
   Frames: J = JR (origin on the 東海道 line at the stop, +a NE along the tracks, +b ESE), S = 相鉄 (origin at the
   buffer end of the line, +a SSW along the tracks, +b WNW), U = ブルーライン (origin at the stop, +a NNW). */
(()=>{
const NAME='横浜';
/* ---------- line tweaks ---------- */
LINE_EXT.sot=10;ST_S['sot|横浜']=0;                                     // the 相鉄 trains pull up to the buffer stops
/* NB: lanes and rail levels are stored per path point and read at index s/10, while the points are ~10.13 m apart, so
   at the far end of a line (JR and ブルーライン end here) they are clamped to the last samples: one constant value each. */
PROF_ADJ.push({key:'sot',s0:0,s1:215,y:8.6,blend:260},                    // 相鉄: 2F platforms inside 新相鉄ビル
  {key:'blu',s0:22060,s1:22700,y:-13.6,blend:250});                       // ブルーライン: B3 platform
LANE_ADJ.push({key:'jr',s0:29000,s1:29700,lo:-2.3,hi:2.3,blend:150},      // 東海道線 on tracks 7 (up) and 6 (down)
  {key:'blu',s0:21900,s1:22700,lo:-5.2,hi:5.2,blend:200});                // ブルーライン island platform
const JLANE=2.3;
// OSM platforms that are rebuilt here (JR 3;4 – 9;10, 相鉄, a stray みなとみらい線 outline at ground level)
for(const [x,z] of [[12077.3,-13923.7],[12212.8,-14073.4],[12186.3,-14013.9],[12230.0,-14044.6],[12267.8,-14067.4],[12233.3,-14127.8]])PLAT_CLEAR.push([x,z,0,3,3]);
BLD_CLEAR.push([12070.1,-13934.0,0,3,3],[12334.1,-14020.4,0,3,3]);  // + the small 東口 entrance block (its stairs are rebuilt)                                 // 新相鉄ビル: rebuilt with the station inside
/* ---------- frames ---------- */
const nrm=(x,z)=>{const l=Math.hypot(x,z);return[x/l,z/l];};
const JT=nrm(0.606,-0.795),ST=nrm(-0.471,0.882);
const J=stFrame(12179.1,-13989.2,Math.atan2(JT[1],JT[0])),S=stFrame(12125.0,-13998.1,Math.atan2(ST[1],ST[0]));
const loc=(F,x,z)=>{const dx=x-F.ox,dz=z-F.oz;return[dx*F.ux+dz*F.uz,dx*F.vx+dz*F.vz];};
/* JR track centre lines in frame J (OSM): a, T10, T9, T8, T7, T6, T5, T4, T3 */
const TT=[[-120,-17.35,-13.35,-9.17,-2.33,1.72,8.9,20,34],[-110,-18.56,-14.27,-10.09,-2.32,1.68,9.72,20,34],[-100,-19.77,-15.19,-10.97,-2.31,1.69,10.47,20,34],[-90,-20.98,-16.1,-11.82,-2.31,1.76,11.17,20,34],
  [-80,-22.26,-16.81,-12.67,-2.3,1.83,11.88,20,34],[-70,-23.59,-17.36,-13.05,-2.29,1.9,12.4,20,34],[-60,-24.89,-17.91,-13.4,-2.29,1.97,12.38,20,34],[-50,-26.07,-18.35,-13.74,-2.28,2.04,12.35,20,34],
  [-40,-27.26,-18.3,-14.03,-2.27,2.11,12.33,20,34],[-30,-28.44,-18.25,-13.9,-2.27,2.18,12.31,20,34],[-20,-29.62,-18.2,-13.78,-2.26,2.25,12.29,20,34],[-10,-30.76,-18.15,-13.65,-2.25,2.32,12.26,20.1,34.5],
  [0,-31.55,-18.1,-13.53,-2.25,2.39,12.24,20.1,34.1],[10,-32.34,-18.05,-13.41,-2.24,2.46,12.22,20.09,33.69],[20,-33.13,-18,-13.28,-2.23,2.53,12.19,18.5,32.37],[30,-33.92,-17.95,-13.16,-2.22,2.6,12.17,18.3,31.62],
  [40,-34.71,-17.9,-13.03,-2.22,2.67,12.15,18.11,30.86],[50,-34.84,-17.85,-12.91,-2.21,2.74,12.12,17.93,30.52],[60,-34.77,-17.77,-12.82,-2.27,2.76,12.1,17.81,30.27],[70,-34.71,-17.6,-12.85,-2.47,2.65,12.08,17.88,30.03],
  [80,-35.07,-17.42,-12.88,-2.68,2.54,12.05,17.94,29.78],[90,-35.44,-17.24,-12.91,-2.89,2.43,12.03,18.01,29.53],[100,-35.8,-17.06,-12.94,-3.1,2.33,12.01,18.07,29.29],[110,-36.17,-16.89,-12.97,-3.2,2.22,11.98,18.14,29.04],
  [120,-36.08,-16.98,-13,-3.25,2.11,11.96,18.02,28.89],[130,-35.89,-17.17,-13.03,-3.3,2.06,11.94,17.83,28.78],[140,-35.7,-17.37,-13.06,-3.34,2.01,11.92,17.64,28.67],[150,-35.51,-17.56,-13.09,-3.39,1.96,11.89,17.44,28.56],
  [160,-35.32,-17.75,-13.12,-3.44,1.92,11.87,17.25,28.46],[170,-35.14,-17.95,-13.15,-3.49,1.87,11.85,17.06,28.35],[180,-34.89,-18.14,-13.17,-3.54,1.83,11.82,16.86,28.24],[190,-33.9,-17.78,-12.79,-3.59,1.62,11.44,16.38,27.28],
  [200,-32.9,-17.28,-12.29,-3.64,1.37,10.95,15.8,26.08],[210,-31.91,-16.78,-11.79,-3.69,1.12,10.46,15.22,24.88],[220,-30.91,-16.28,-11.29,-3.74,0.87,9.97,14.65,23.68],[230,-29.91,-15.78,-10.79,-3.79,0.62,9.48,14.07,22.48],
  [240,-28.92,-15.28,-10.29,-3.84,0.37,8.99,13.13,21.27],[250,-27.92,-14.43,-9.57,-3.89,0.35,8.04,12.17,19.85],[260,-26.93,-13.54,-8.84,-3.94,0.33,7.07,11.22,18.39],[270,-25.93,-12.65,-8.1,-4,0.31,6.1,10.26,16.94],
  [280,-24.94,-11.9,-7.37,-4.05,0.29,5.14,9.3,15.54],[290,-23.94,-11.18,-6.64,-4.1,0.27,4.17,8.35,14.14],[300,-22.95,-10.7,-5.9,-4.16,0.25,3.2,7.39,12.74]];
const TK={10:1,9:2,8:3,7:4,6:5,5:6,4:7,3:8};
const T=(n,a)=>{const k=TK[n];const f=clamp((a+120)/10,0,TT.length-1.001);const i=f|0;return lerp(TT[i][k],TT[i+1][k],f-i);};
const EDGE=1.575;                                                         // track centre → platform edge (half car + 0.1 m)
/* 相鉄: OSM track offsets from the line at the terminal; the JR 9番線 track nearby must not be used as a terminal track */
const SOT_TR=[0.05,6.89,13.59];
/* ---------- levels ---------- */
const B1=-3.0,B1C=0.9,B2=-7.6,B2C=-4.2;
/* ---------- builder state ---------- */
let gb,inn,colls,lights,fac,roofG,glass;const PLAN=[];
const TILE=C_('#d9d4c9'),TILE2=C_('#cfc9bc'),WALL=C_('#eeebe4'),CEIL=C_('#f2f1ec'),EDGEC=C_('#bdb6a8'),DECK=C_('#d3cdbf'),GRAV=C_('#7d756c');
const JRC='#f68b1e',JRG='#2e8b3d',YSK='#0067c0',KTC='#00b2e5',SOTC='#1d3c8f',BLUC='#0072bc';
const plan=(F,a0,a1,b0,b1,k)=>{const p=[F.W(a0,b0),F.W(a1,b0),F.W(a1,b1),F.W(a0,b1)];PLAN.push({k,p:p.flat()});};
/* visual-only slab with rectangular holes (local coords [a0,a1,b0,b1]) */
function vslab(g,F,a0,a1,b0,b1,y,holes,col,faces){const vc=[b0,b1];for(const h of holes)vc.push(clamp(h[2],b0,b1),clamp(h[3],b0,b1));vc.sort((p,q)=>p-q);
  for(let i=0;i<vc.length-1;i++){const v0=vc[i],v1=vc[i+1];if(v1-v0<0.05)continue;const vm=(v0+v1)/2;const hs=holes.filter(h=>vm>h[2]&&vm<h[3]).sort((p,q)=>p[0]-q[0]);let a=a0;
    const put=(p0,p1)=>{if(p1-p0<0.05)return;const c=F.W((p0+p1)/2,(v0+v1)/2);g.obox(c[0],c[1],F.ux,F.uz,(p1-p0)/2,(v1-v0)/2,y-0.02,y,col,faces);};
    for(const h of hs){put(a,h[0]);a=Math.max(a,h[1]);}put(a,a1);}}
/* walls of a local rectangle with gaps [side,from,to] (sides 0:b0 1:b1 2:a0 3:a1), visual (both faces) + colliders */
function walls(g,F,a0,a1,b0,b1,y0,y1,gaps,col,coll=true){
  const seg=(side,p0,p1)=>{const gg=gaps.filter(q=>q[0]===side).sort((x,y)=>x[1]-y[1]);let a=p0;const out=[];for(const q of gg){if(q[1]>a)out.push([a,q[1]]);a=Math.max(a,q[2]);}if(a<p1)out.push([a,p1]);return out;};
  for(const [s0,s1] of seg(0,a0,a1)){const c=F.W((s0+s1)/2,b0-0.1);g.obox(c[0],c[1],F.ux,F.uz,(s1-s0)/2,0.1,y0,y1,col,4|8|16|32);}
  for(const [s0,s1] of seg(1,a0,a1)){const c=F.W((s0+s1)/2,b1+0.1);g.obox(c[0],c[1],F.ux,F.uz,(s1-s0)/2,0.1,y0,y1,col,4|8|16|32);}
  for(const [s0,s1] of seg(2,b0,b1)){const c=F.W(a0-0.1,(s0+s1)/2);g.obox(c[0],c[1],F.ux,F.uz,0.1,(s1-s0)/2,y0,y1,col,4|8|16|32);}
  for(const [s0,s1] of seg(3,b0,b1)){const c=F.W(a1+0.1,(s0+s1)/2);g.obox(c[0],c[1],F.ux,F.uz,0.1,(s1-s0)/2,y0,y1,col,4|8|16|32);}
  if(coll)rectWalls(colls,F,a0,a1,b0,b1,y0,y1,gaps);}
function lightGrid(F,a0,a1,b0,b1,y,da=6,db=7){for(let a=a0+da/2;a<a1;a+=da)for(let b=b0+db/2;b<b1;b+=db){const c=F.W(a,b);lights.obox(c[0],c[1],F.ux,F.uz,1.4,0.16,y-0.06,y-0.01,C_('#ffffff'),2);}}
/* an interior hall: floor (holes), ceiling (holes), walls (gaps), lights, zone */
function hall(F,a0,a1,b0,b1,y0,y1,o={}){
  const fh=o.fh||[];slabWithHoles(inn,colls,F,a0,a1,b0,b1,y0,0.4,fh,o.fc||TILE,null);
  vslab(inn,F,a0,a1,b0,b1,y1,o.ch||[],o.cc||CEIL,2);
  if(o.top)vslab(gb,F,a0,a1,b0,b1,o.top,o.ch||[],GRAV,1);
  walls(inn,F,a0,a1,b0,b1,y0,y1,o.gaps||[],o.wc||WALL);
  if(o.lights!==false)lightGrid(F,a0,a1,b0,b1,y1,o.ld||6,o.lb||7);
  regZone(F,a0,a1,b0,b1,y0-0.6,y1+0.3,NAME,o.line||LINES.jr,y0,null,o.indoor!==false);plan(F,a0,a1,b0,b1,o.k||'hall');}
/* stair shaft between a lower ceiling and an upper deck (inner faces), opening rect in local coords */
function shaft(F,a0,a1,b0,b1,y0,y1,col=WALL,mask=4|8|16|32){const c=F.W((a0+a1)/2,(b0+b1)/2);inn.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2,(b1-b0)/2,y0,y1,col,mask);}
/* railing around a stair opening on a deck: open towards the stair's top end */
function rail(F,a0,a1,b0,b1,y,openSide){const r=C_('#b8c0c6');const sides=[[a0,a1,b0,b0],[a0,a1,b1,b1],[a0,a0,b0,b1],[a1,a1,b0,b1]];
  sides.forEach(([p0,p1,q0,q1],i)=>{if(i===openSide)return;const c=F.W((p0+p1)/2,(q0+q1)/2);const hu=Math.max(0.04,(p1-p0)/2),hv=Math.max(0.04,(q1-q0)/2);inn.obox(c[0],c[1],F.ux,F.uz,hu,hv,y,y+1.1,r);colls.push(addOBB(c[0],c[1],hu,hv,F.ang,y,y+1.1));});}
/* platform deck in a frame: a0..a1 between fL(a)<fR(a); rectangular openings; tactile lines on track edges */
function deck(F,a0,a1,fL,fR,top,holes,opt={}){const y0=top-1.25;const cuts=new Set([a0,a1]);for(let a=Math.ceil(a0/5)*5;a<a1;a+=5)cuts.add(a);for(const h of holes){if(h[0]>a0&&h[0]<a1)cuts.add(h[0]);if(h[1]>a0&&h[1]<a1)cuts.add(h[1]);}
  const A=[...cuts].sort((p,q)=>p-q);const g=opt.g||gb;const P=(a,b,y)=>{const w=F.W(a,b);return[w[0],y,w[1]];};
  const side=(p,q,bp,bq,dir)=>{const A1=P(p,bp,y0),B1=P(q,bq,y0),C1=P(q,bq,top),D1=P(p,bp,top);const nx=F.vx*dir,nz=F.vz*dir;g.quad(A1,B1,C1,D1,nx,0,nz,EDGEC);};
  const endF=(a,b0,b1,dir)=>{g.quad(P(a,b0,y0),P(a,b1,y0),P(a,b1,top),P(a,b0,top),F.ux*dir,0,F.uz*dir,EDGEC);};
  for(let i=0;i<A.length-1;i++){const p=A[i],q=A[i+1];const m=(p+q)/2;const h=holes.find(h=>m>h[0]&&m<h[1]);
    const pieces=h?[[fL,()=>h[2],1,0],[()=>h[3],fR,0,1]]:[[fL,fR,1,1]];
    for(const [L,R,eL,eR] of pieces){const lp=L(p),lq=L(q),rp=R(p),rq=R(q);if(rp-lp<0.05&&rq-lq<0.05)continue;
      g.quad(P(p,lp,top),P(q,lq,top),P(q,rq,top),P(p,rp,top),0,1,0,opt.col||DECK);
      side(p,q,lp,lq,-1);side(p,q,rp,rq,1);
      const pts=[...F.W(p,lp),...F.W(q,lq),...F.W(q,rq),...F.W(p,rp)];const b=addPoly(pts,top-1.2,top);b.tag=0;b.plat=true;
      }
    // tactile + white edge lines along track edges
    const lines=[];if(opt.trackL!==false)lines.push([fL,1]);if(opt.trackR!==false)lines.push([fR,-1]);
    for(const [E,dir] of lines)for(const [o0,o1,c] of [[0.08,0.22,'#f4f4f2'],[0.85,1.15,'#f2d33c']]){const e0=E(p),e1=E(q);g.quad(P(p,e0+dir*o0,top+0.012),P(q,e1+dir*o0,top+0.012),P(q,e1+dir*o1,top+0.012),P(p,e0+dir*o1,top+0.012),0,1,0,C_(c));}}
  endF(a0,fL(a0),fR(a0),-1);endF(a1,fL(a1),fR(a1),1);
  const pl=[];for(const a of A)pl.push(F.W(a,fL(a)));for(const a of A.slice().reverse())pl.push(F.W(a,fR(a)));PLAN.push({k:'plat',p:pl.flat()});}
/* platform roof along a deck */
function canopy(F,a0,a1,fL,fR,top,h=4.4,col='#c3c8cc'){for(let a=a0;a<a1;a+=5){const q=Math.min(a1,a+5);const m=(a+q)/2;const l=fL(m)+0.35,r=fR(m)-0.35;const c=F.W(m,(l+r)/2);
    gb.obox(c[0],c[1],F.ux,F.uz,(q-a)/2+0.02,(r-l)/2,top+h,top+h+0.25,C_(col));}
  for(let a=a0+6;a<a1-3;a+=16){const m=(fL(a)+fR(a))/2;const c=F.W(a,m);gb.obox(c[0],c[1],F.ux,F.uz,0.2,0.2,top,top+h,C_('#7a858e'));colls.push(addOBB(c[0],c[1],0.2,0.2,F.ang,top,top+h));
    gb.obox(c[0],c[1],F.ux,F.uz,0.12,(fR(a)-fL(a))/2-0.5,top+h-0.55,top+h,C_('#7a858e'));}}
/* street entrance: stairs from street level at local (a,b) going (da,db) down to yBot; returns the foot */
function exitAt(F,aF,bF,da,db,yBot,w,title,sub,col,line,o={}){let run=6;for(let i=0;i<4;i++){const t=F.W(aF-da*run,bF-db*run);run=Math.ceil((Math.max(o.minG??-9,demH(t[0],t[1]))+0.05-yBot)/0.28)*0.42;}
  return exitWell(F,aF-da*run,bF-db*run,da,db,yBot,w,title,sub,col,line,o);}
function exitWell(F,a,b,da,db,yBot,w,title,sub,col,line,o={}){const tw=F.W(a,b);const gy=Math.max(o.minG??-9,demH(tw[0],tw[1]))+0.05;const run=Math.ceil((gy-yBot)/0.28)*0.42;
  stairDir(inn,colls,F,a,b,da,db,gy,yBot,w);const ba=a+da*run,bb=b+db*run;
  const sa0=Math.min(a,ba)-(da?0:w/2+0.25),sa1=Math.max(a,ba)+(da?0:w/2+0.25),sb0=Math.min(b,bb)-(db?0:w/2+0.25),sb1=Math.max(b,bb)+(db?0:w/2+0.25);
  const topSide=da<0?3:da>0?2:db>0?0:1,botSide=da<0?2:da>0?3:db>0?1:0;shaft(F,sa0,sa1,sb0,sb1,yBot,gy-0.05,WALL,(4|8|16|32)&~[4,8,16,32][botSide]);terrainHole(...F.W((sa0+sa1)/2,(sb0+sb1)/2),F.ang,(sa1-sa0)/2+0.15,(sb1-sb0)/2+0.15);
  regZone(F,sa0-0.2,sa1+0.2,sb0-0.2,sb1+0.2,yBot-0.5,gy+5,NAME,line,yBot,null);plan(F,sa0,sa1,sb0,sb1,'exit');
  {const fb=addPoly(flatPolyRect(F,sa0,sa1,sb0,sb1),yBot-0.4,yBot);fb.tag=0;}
  rectWalls(colls,F,sa0,sa1,sb0,sb1,yBot,gy+1.1,[[topSide,-1e9,1e9],[botSide,-1e9,1e9]]);
  const ang=F.ang+Math.atan2(db,da);const c=Math.cos(ang),s=Math.sin(ang);const Ln=Math.min(run,7);const hw=w/2+0.25;
  for(const sd of [-1,1]){const x=tw[0]+c*Ln/2-s*sd*hw,z=tw[1]+s*Ln/2+c*sd*hw;gb.obox(x,z,c,s,Ln/2+0.2,0.15,gy-0.4,gy+1.1,C_('#c9ced3'));}
  {const x=tw[0]+c*Ln*0.55,z=tw[1]+s*Ln*0.55;gb.obox(x,z,c,s,Ln*0.55+0.4,hw+0.3,gy+2.75,gy+2.95,C_('#dfe3e6'));gb.obox(x,z,c,s,Ln*0.55+0.4,hw+0.33,gy+2.6,gy+2.75,C_(col));
    for(const sd of [-1,1])for(const f2 of [0.05,1.05]){const xx=tw[0]+c*Ln*f2-s*sd*(hw+0.05),zz=tw[1]+s*Ln*f2+c*sd*(hw+0.05);gb.obox(xx,zz,c,s,0.06,0.06,gy,gy+2.75,C_('#8e979e'));}
    signBoard(tw[0]-c*0.5,gy+3.6,tw[1]-s*0.5,ang+Math.PI/2,Math.min(w+1.2,6),0.8,title,sub,col);}
  return{ba,bb,sa0,sa1,sb0,sb1};}
function gateLine(F,a,b0,b1,g0,g1,y,lbl,sub,col,facing){ // gates across a line a=const between b0..b1, gate section g0..g1
  partition(inn,colls,F,a,b0,a,g0-0.3,y);partition(inn,colls,F,a,g1+0.3,a,b1,y);const gc=F.W(a,(g0+g1)/2);gatesGB(inn,colls,gc[0],gc[1],F.vx,F.vz,g1-g0,y);
  const sb=F.W(a+facing*0.15,(g0+g1)/2);signBoard(sb[0],y+3.0,sb[1],F.ang+Math.PI/2,Math.min(6,g1-g0+1),0.9,lbl,sub,col,true);
  const bc=F.W(a,(g0+g1)/2);inn.obox(bc[0],bc[1],F.ux,F.uz,0.08,(g1-g0)/2+0.6,y+2.5,y+2.75,C_(col));
  const mc=F.W(a+facing*3,g0-3);machinesGB(inn,colls,mc[0],mc[1],F.vx,F.vz,4,y);}
function nameBoards(F,a0,a1,step,bf,top,text,sub,col){for(let a=a0;a<=a1;a+=step){const c=F.W(a,bf(a));signBoard(c[0],top+2.7,c[1],F.ang,2.2,0.55,text,sub,col);}}
/* rails (ballast, sleepers, rails) along a list of world points [x,y,z] */
function railsAlong(g,P){const bal=C_('#8a8177'),sl=C_('#5f5650'),rc=C_('#cfd2d6');
  for(let i=0;i<P.length-1;i++){const a=P[i],b=P[i+1];const dx=b[0]-a[0],dz=b[2]-a[2],l=Math.hypot(dx,dz);if(l<0.01)continue;const nx=-dz/l,nz=dx/l;
    const q=(o0,o1,dy,c)=>{g.quad([a[0]+nx*o0,a[1]+dy,a[2]+nz*o0],[b[0]+nx*o0,b[1]+dy,b[2]+nz*o0],[b[0]+nx*o1,b[1]+dy,b[2]+nz*o1],[a[0]+nx*o1,a[1]+dy,a[2]+nz*o1],0,1,0,c);};
    q(-1.7,1.7,-0.02,bal);q(-1.25,1.25,0.04,sl);q(-0.62,-0.5,0.18,rc);q(0.5,0.62,0.18,rc);}}
/* half-plane clip of a local polygon [[a,b],...] keeping k*coord >= v */
function clipP(P,ax,k,v){const out=[];for(let i=0;i<P.length;i++){const p=P[i],q=P[(i+1)%P.length];const fp=k*p[ax]-v,fq=k*q[ax]-v;if(fp>=0)out.push(p);if((fp>=0)!==(fq>=0)){const t=fp/(fp-fq);out.push([p[0]+(q[0]-p[0])*t,p[1]+(q[1]-p[1])*t]);}}return out;}
function build(){
  const jr=LINES.jr,sot=LINES.sot,blu=LINES.blu;
  gb=new GB();inn=new GB();colls=[];lights=new GB();fac=new GB();roofG=new GB();inn.glass=new GB();gb.glass=inn.glass;
  const sJ=jr.stByName.get(NAME).s,sS=sot.stByName.get(NAME).s,sB=blu.stByName.get(NAME).s;
  const jTop=jr.path.py(sJ)+1.1,sTop=sot.path.py(sS)+1.1,bTop=blu.path.py(sB)+1.1;
  /* the 相鉄 terminal uses its three own tracks only */
  {const st0=stationTracks;stationTracks=function(l,s){const r=st0(l,s);if(l===sot&&Math.abs(s-sS)<60)return r.filter(o=>o>-8);return r;};}
  /* =============== JR: where the 東海道線 trains really run =============== */
  // the game's line bends ~3 m west of the OSM tracks towards its end, and the lanes are constant here:
  // tracks 6/7 are redrawn along the trains' path and the two islands follow them
  const LS={6:[],7:[]};for(let s=sJ-240;s<=jr.path.L;s+=2)for(const n of [6,7]){const q=jr.path.at(s,n===6?JLANE:-JLANE);LS[n].push(loc(J,q.x,q.z));}
  const aEnd=LS[7][LS[7].length-1][0];
  const LB=(n,a)=>{const A=LS[n];if(a>=aEnd){const e=A[A.length-1];const t=clamp((a-aEnd)/(130-aEnd),0,1);const w=t*t*(3-2*t);return lerp(e[1],T(n,a),w);}
    let lo=0,hi=A.length-1;while(hi-lo>1){const m=(lo+hi)>>1;if(A[m][0]<a)lo=m;else hi=m;}const p=A[lo],q=A[hi];return lerp(p[1],q[1],clamp((a-p[0])/((q[0]-p[0])||1),0,1));};
  const TB=(n,a)=>(n===6||n===7)&&a>-150&&a<131?LB(n,a):T(n,a);
  {const rg=new GB();
    // remove the OSM pieces of tracks 6/7 along the platforms
    const cutTr=[];for(let ti=0;ti<TRACKS.length;ti++){const t=TRACKS[ti];const p=t.pts;let near=false;for(let i=0;i<p.length;i+=2)if(Math.abs(p[i]-J.ox)<500&&Math.abs(p[i+1]-J.oz)<500){near=true;break;}if(!near)continue;
      const S2=[];for(let i=0;i<p.length/2-1;i++){const ax=p[i*2],az=p[i*2+1],bx=p[i*2+2],bz=p[i*2+3];const L0=Math.hypot(bx-ax,bz-az);const n=Math.max(1,Math.ceil(L0/2));
        for(let k=(i?1:0);k<=n;k++){const f=k/n;const x=lerp(ax,bx,f),z=lerp(az,bz,f);const y=lerp(t.ys[i],t.ys[i+1],f);const l=loc(J,x,z);
          const cut=l[0]>-150&&l[0]<131&&(Math.abs(l[1]-T(6,l[0]))<0.9||Math.abs(l[1]-T(7,l[0]))<0.9);S2.push({x,z,y,cut});}}
      if(!S2.some(q=>q.cut))continue;const runs=[];let cur=[];for(const q of S2){if(q.cut){if(cur.length>1)runs.push(cur);cur=[];}else cur.push(q);}if(cur.length>1)runs.push(cur);
      const mk=r=>{const pts=new Float32Array(r.length*2),ys=new Float32Array(r.length);r.forEach((q,i)=>{pts[i*2]=q.x;pts[i*2+1]=q.z;ys[i]=q.y;});return{fl:t.fl,pts,ys};};
      if(runs.length){Object.assign(t,mk(runs[0]));cutTr.push(ti);for(const r of runs.slice(1)){TRACKS.push(mk(r));cutTr.push(TRACKS.length-1);}}else{t.pts=new Float32Array(0);t.ys=new Float32Array(0);}}
    for(const ti of cutTr){const p=TRACKS[ti].pts;for(let i=0;i<p.length/2;i++){const k=chKey(p[i*2],p[i*2+1]);let arr=TRACKCH.get(k);if(!arr)TRACKCH.set(k,arr=[]);if(!arr.includes(ti))arr.push(ti);}}
    for(const n of [6,7]){const P=[];for(let a=-150;a<=131;a+=2){const w=J.W(a,TB(n,a));P.push([w[0],jr.path.py(sJ),w[1]]);}railsAlong(rg,P);}
    if(!rg.empty){const m=new THREE.Mesh(rg.geo(),MAT.road);m.receiveShadow=true;scene.add(m);}}
  /* =============== JR: platforms =============== */
  const isl=[ // name, left track, right track, a0, a1, colour, numbering
    {n:'9・10',L:10,R:9,a0:-60,a1:295,col:YSK,num:'JO 13',sub:'横須賀線・湘南新宿ライン'},
    {n:'7・8',L:8,R:7,a0:-106,a1:240,col:JRC,num:'JT 05',sub:'東海道線 上り'},
    {n:'5・6',L:6,R:5,a0:-105,a1:240,col:JRC,num:'JT 05',sub:'東海道線 下り'},
    {n:'3・4',L:4,R:3,a0:10,a1:241,col:KTC,num:'JK 12',sub:'京浜東北・根岸線'}];
  const run=Math.ceil((jTop-B1)/0.28)*0.42;
  // stair tops (a) and the direction they descend; one stair per island from each paid concourse
  const STAIRS=[{a:104.5,d:1,g:'cs'},{a:146.3,d:-1,g:'cn'},{a:-19.8,d:-1,g:'ms'},{a:195.8,d:1,g:'kn'}];
  for(const I of isl){const fL=a=>TB(I.L,a)+EDGE,fR=a=>TB(I.R,a)-EDGE;const holes=[];
    for(const st of STAIRS){if(st.a<I.a0+3||st.a>I.a1-3)continue;const am=st.a+st.d*run/2;const bc=(fL(am)+fR(am))/2;const h0=Math.min(st.a,st.a+st.d*run)-0.3,h1=Math.max(st.a,st.a+st.d*run)+0.3;
      holes.push([h0,h1,bc-1.7,bc+1.7]);st[I.n]=bc;
      stairDir(inn,colls,J,st.a,bc,st.d,0,jTop,B1,2.8);shaft(J,h0,h1,bc-1.7,bc+1.7,B1C,jTop-0.05);rail(J,h0,h1,bc-1.7,bc+1.7,jTop,st.d>0?2:3);
      regZone(J,h0,h1,bc-1.7,bc+1.7,B1-0.6,jTop+3,NAME,jr,B1,null,false);}
    I.holes=holes;deck(J,I.a0,I.a1,fL,fR,jTop,holes.sort((p,q)=>p[0]-q[0]));
    canopy(J,Math.max(I.a0,-90),Math.min(I.a1,225),fL,fR,jTop,I.n==='9・10'||I.n==='3・4'?5.2:4.4,I.n==='9・10'||I.n==='3・4'?'#e8eaeb':'#c3c8cc');
    nameBoards(J,Math.max(I.a0,-80)+10,Math.min(I.a1,220)-10,60,a=>(fL(a)+fR(a))/2,jTop,'横浜','よこはま  Yokohama  '+I.num,I.col);
    for(const a of [-40,60,170]){if(a<I.a0||a>I.a1)continue;const m=(fL(a)+fR(a))/2;const c=J.W(a+3,m);signBoard(c[0],jTop+2.9,c[1],J.ang+Math.PI/2,1.9,0.5,I.n+'番線',I.sub,I.col,true);}
    platformBench(J,I,fL,fR,jTop);}
  // the game's 東海道線 boards at 5・6 and 7・8
  regPlatform(flatPolyRect(J,-60,100,-11.2,-7.0),jTop,jr,false,false);regPlatform(flatPolyRect(J,-60,100,3.8,10.4),jTop,jr,false,false);
  /* =============== JR: B1 passages and paid concourses =============== */
  const holeFor=g=>isl.flatMap(I=>I.holes.filter(h=>STAIRS.find(s=>s.g===g&&Math.abs(Math.min(s.a,s.a+s.d*run)-0.3-h[0])<0.01)));
  const shH=g=>holeFor(g);
  // 中央通路
  hall(J,118,132,-90,100,B1,B1C,{gaps:[[2,-38,31],[2,33,40],[3,-38,31],[3,-88.2,-81.8],[1,121,129]],fc:TILE2,k:'中央通路'});
  {const c=J.W(125,10);inn.obox(c[0],c[1],J.ux,J.uz,1.2,90,B1,B1+0.012,C_('#f2d33c'),1);}
  hall(J,100,118,-38,31,B1,B1C,{ch:shH('cs'),gaps:[[3,-38,31]],top:1.72,k:'中央南'});
  hall(J,132,152,-38,31,B1,B1C,{ch:shH('cn'),gaps:[[2,-38,31]],top:1.72,k:'中央北'});
  gateLine(J,118,-38,31,-8,8,B1,'中央南改札','JR線  JR Lines',JRG,1);gateLine(J,132,-38,31,-8,8,B1,'中央北改札','JR線  JR Lines',JRG,-1);
  {const mw=J.W(127,-60);inn.obox(mw[0],mw[1],J.ux,J.uz,3.8,4,B1,B1+2.8,C_(JRG));colls.push(addOBB(mw[0],mw[1],3.8,4,J.ang,B1,B1+2.8));
    signBoard(mw[0]-J.vx*4.05,B1+3.3,mw[1]-J.vz*4.05,J.ang,3.6,0.6,'みどりの窓口','Ticket Office',JRG,true);}
  for(const [b,t] of [[-70,'中央西口  West Exit ↑'],[90,'中央東口  East Exit ↑'],[-25,'← 西口　東口 →'],[45,'みなみ通路 ↘  South Passage']]){const c=J.W(125,b);signBoard(c[0],B1+3.3,c[1],J.ang,4.4,0.62,t,'','#f2d33c',true);}
  // shops along 中央通路 (崎陽軒 etc.)
  for(const [b,col,t] of [[-50,'#c8432f','崎陽軒'],[55,'#2f8f4e','NewDays'],[70,'#8a5a3c','カフェ']]){const c=J.W(131,b);inn.obox(c[0],c[1],J.ux,J.uz,1,3,B1,B1+2.6,C_('#f4efe6'));inn.obox(c[0],c[1],J.ux,J.uz,1.05,3.05,B1+2.6,B1+3.1,C_(col));colls.push(addOBB(c[0],c[1],1,3,J.ang,B1,B1+2.6));const s2=J.W(129.9,b);signBoard(s2[0],B1+2.85,s2[1],J.ang+Math.PI/2,3.6,0.4,t,'',col,true,false);}
  // 中央西口 comes up in the gap the PLATEAU block at the west plaza leaves for it
  exitAt(J,132,-85,-1,0,B1,6,'横浜駅 中央西口','JR線・相鉄線・地下鉄',JRG,jr);
  exitAt(J,125,100,0,-1,B1,6,'横浜駅 中央東口','JR線・京急線',JRG,jr);
  // みなみ通路 (+ the みなみ東口通路 up to 中央通路, the 相鉄 link corridor, the stairs to the 相鉄 1F and the ブルーライン B2)
  hall(J,-60,-46,-95,40,B1,B1C,{gaps:[[3,-32,16],[3,-43,-35],[3,33,40],[2,-69,-62]],fc:TILE2,fh:[[-54.8,-51.2,-95,-86]],k:'みなみ通路'});
  hall(J,-46,-19,-32,16,B1,B1C,{ch:shH('ms'),gaps:[[2,-32,16]],top:1.72,k:'南改札内'});
  gateLine(J,-46,-32,16,-14,0,B1,'南改札','JR線  JR Lines',JRG,-1);
  hall(J,-46,118,33,40,B1,B1C,{gaps:[[2,33,40],[3,33,40]],lb:7,k:'みなみ東口通路'});
  for(const [a,b,t] of [[-53,-30,'← 相鉄線・地下鉄  Sōtetsu / Subway'],[-53,25,'中央通路 →  Central Passage']]){const c=J.W(a,b);signBoard(c[0],B1+3.3,c[1],J.ang+Math.PI/2,4.6,0.62,t,'','#f2d33c',true);}
  // きた通路 and its paid concourse
  hall(J,288,300,-60,40,B1,B1C,{gaps:[[2,-34,26],[0,290,298]],fc:TILE2,k:'きた通路'});
  hall(J,195,288,-34,26,B1,B1C,{ch:shH('kn'),gaps:[[3,-34,26],[2,-34,26]],top:1.72,k:'北改札内'});
  gateLine(J,288,-34,26,-10,4,B1,'北改札','JR線  JR Lines',JRG,1);
  exitAt(J,294,-60,0,1,B1,5,'横浜駅 きた西口','JR線',JRG,jr);
  // ground above the paid concourses where the stair wells cut the terrain
  for(const [g,a0,a1] of [['cs',103.8,115.0],['cn',135.7,146.9],['ms',-30.5,-19.2],['kn',195.2,206.4]]){const hs=holeFor(g);const b0=Math.min(...hs.map(h=>h[2]))-0.4,b1=Math.max(...hs.map(h=>h[3]))+0.4;terrainHole(...J.W((a0+a1)/2,(b0+b1)/2),J.ang,(a1-a0)/2,(b1-b0)/2);plan(J,a0,a1,b0,b1,'hole');}
  /* =============== 相鉄: 2F platforms inside 新相鉄ビル =============== */
  const sp=a=>{const p=sot.path.at(a+10);return loc(S,p.x,p.z)[1];};             // line centre (S b) at S a
  const tr=k=>a=>sp(a)+SOT_TR[k];
  // east wall of the building (footprint, S frame): b=-11.2 up to a≈101, then towards -3.9 at a≈186
  const eastW=a=>a<101?-11.0:lerp(-11.0,-3.7,clamp((a-101)/85,0,1)),westW=a=>a<106?21.0:lerp(21,21.5,clamp((a-106)/80,0,1));
  const SA0=-11,SA1=200;
  const y1F=demH(...S.W(50,30))+0.05;const run1=Math.ceil((sTop-y1F)/0.28)*0.42;
  const sotPl=[ // fL, fR, label
    {fL:a=>eastW(a)+0.2,fR:a=>tr(0)(a)-EDGE,tl:false,n:'1番線 のりば',c:-1},
    {fL:a=>tr(0)(a)+EDGE,fR:a=>tr(1)(a)-EDGE,n:'1・2番線 おりば'},
    {fL:a=>tr(1)(a)+EDGE,fR:a=>tr(2)(a)-EDGE,n:'2番線のりば・3番線'},
    {fL:a=>tr(2)(a)+EDGE,fR:a=>westW(a)-0.2,tr:false,n:'3番線 おりば'}];
  const sHoles=[];
  for(const P of sotPl){const bc=(P.fL(58)+P.fR(58))/2;const w=Math.min(2.6,P.fR(58)-P.fL(58)-1.6);P.w=w;P.bc=bc;const h=[51.7,52+run1+0.3,bc-w/2-0.25,bc+w/2+0.25];P.h=h;sHoles.push(h);
    deck(S,SA0,P===sotPl[0]?Math.min(SA1,190):SA1,P.fL,P.fR,sTop,[h],{trackL:P.tl!==false,trackR:P.tr!==false});
    stairDir(inn,colls,S,52,bc,1,0,sTop,y1F,w);shaft(S,h[0],h[1],h[2],h[3],y1F+5.6,sTop-0.05);rail(S,h[0],h[1],h[2],h[3],sTop,2);
    for(const a of [20,90,160]){const c=S.W(a,bc);signBoard(c[0],sTop+2.7,c[1],S.ang,2.2,0.55,'横浜','よこはま  Yokohama  SO 01',SOTC);}
    {const c=S.W(30,bc);signBoard(c[0],sTop+2.95,c[1],S.ang+Math.PI/2,Math.min(2.8,P.fR(30)-P.fL(30)),0.5,P.n,'相鉄本線  海老名・湘南台方面',SOTC,true);}
    for(let a=12;a<SA1-10;a+=24){const c=S.W(a,bc);gb.obox(c[0],c[1],S.ux,S.uz,0.22,0.22,sTop,sTop+6.6,C_('#d5d9dc'));colls.push(addOBB(c[0],c[1],0.22,0.22,S.ang,sTop,sTop+6.6));}}
  for(let k=0;k<3;k++)regPlatform(flatPolyRect(S,-5,195,tr(k)(90)-EDGE-2.2,tr(k)(90)-EDGE-0.3),sTop,sot,false,false),regPlatform(flatPolyRect(S,-5,195,tr(k)(90)+EDGE+0.3,tr(k)(90)+EDGE+2.0),sTop,sot,false,false);
  // buffer stops and platform doors at the track ends
  for(let k=0;k<3;k++){const b=tr(k)(-10);const c=S.W(-12.2,b);gb.obox(c[0],c[1],S.ux,S.uz,0.4,1.4,sTop-1.0,sTop+0.1,C_('#c8432f'));colls.push(addOBB(c[0],c[1],0.4,1.4,S.ang,sTop-1.0,sTop+0.1));}
  // 2F head concourse: free side a<-19, gates, paid side up to the platform ends
  {const a0=-30,a1=-11;const b0=eastW(-20)+0.2,b1=21;const holeS=[-26.6,-18.6,-8.4,-4.6];
    slabWithHoles(inn,colls,S,a0,a1,b0,b1,sTop,1.25,[holeS],TILE,C_('#a6abaf'));plan(S,a0,a1,b0,b1,'相鉄2F改札');
    gateLine(S,-19,b0,b1,2,14,sTop,'相鉄線 2F改札','Sōtetsu Line  SO 01',SOTC,-1);
    rail(S,holeS[0],holeS[1],holeS[2],holeS[3],sTop,2);
    for(const [b,t] of [[0,'← JR線 みなみ改札・地下鉄'],[17,'相鉄ジョイナス・髙島屋 →']]){const c=S.W(-25,b);signBoard(c[0],sTop+3.2,c[1],S.ang,4.6,0.6,t,'','#f2d33c',true);}
    for(const [b,col,t] of [[17,'#e8902f','パン'],[8,'#2f8f4e','コンビニ']]){const c=S.W(-28,b);inn.obox(c[0],c[1],S.ux,S.uz,1.8,3,sTop,sTop+2.7,C_('#f4efe6'));inn.obox(c[0],c[1],S.ux,S.uz,1.85,3.05,sTop+2.7,sTop+3.2,C_(col));colls.push(addOBB(c[0],c[1],1.8,3,S.ang,sTop,sTop+2.7));}}
  // the 2F hall: walls follow the building, ceiling, lights; the line leaves through the south end
  {const H=sTop+7.6;const segs=[];for(let a=-30;a<SA1+6;a+=6)segs.push(a);
    for(let i=0;i<segs.length-1;i++){const p=segs[i],q=segs[i+1];for(const [f,dir] of [[eastW,-1],[westW,1]]){const A1=S.W(p,f(p)),B1_=S.W(q,f(q));const dx=B1_[0]-A1[0],dz=B1_[1]-A1[1],l=Math.hypot(dx,dz);const cx=(A1[0]+B1_[0])/2,cz=(A1[1]+B1_[1])/2;
      inn.obox(cx,cz,dx/l,dz/l,l/2+0.05,0.12,sTop-1.3,H,WALL,4|8|16|32);colls.push(addOBB(cx,cz,l/2+0.05,0.15,Math.atan2(dz,dx),sTop-1.3,H));}}
    {const c=S.W(-30.1,5);inn.obox(c[0],c[1],S.ux,S.uz,0.12,16.5,sTop-1.3,H,WALL);colls.push(addOBB(c[0],c[1],0.12,16.5,S.ang,sTop-1.3,H));}
    lightGrid(S,-30,SA1,-8,19,H,6,6);
    INDOOR.push({cx:S.W(85,5)[0],cz:S.W(85,5)[1],c:S.ux,s:S.uz,hl:116,hw:16.5,y0:sTop-1.4,y1:H});}
  /* 1F: gate concourse under the middle of the platforms, みなみ西口 */
  {const a0=30,a1=92,b0=-10.5,b1=24;const C1=y1F+5.6;
    const fh=[[30,35.8,21.0,24.0]];
    hall(S,a0,a1,b0,b1,y1F,C1,{fh,ch:sHoles,gaps:[[1,44,56],[2,21,24]],line:sot,k:'相鉄1F'});
    hall(S,44,56,24,28.4,y1F,C1-1.5,{gaps:[[0,44,56],[1,45,55]],line:sot,k:'みなみ西口'});
    terrainHole(...S.W(61,8.5),S.ang,32.5,21);
    gateLine({...S,W:(a,b)=>S.W(b,a),ux:S.vx,uz:S.vz,vx:S.ux,vz:S.uz,ang:S.ang+Math.PI/2},19,a0+0.2,a1-0.2,46,58,y1F,'相鉄線 1F改札','Sōtetsu Line  SO 01',SOTC,1);
    {const c=S.W(50,28.6);gb.obox(c[0],c[1],S.ux,S.uz,6.2,0.12,y1F,y1F+3.2,C_('#33414c'));gb.obox(c[0],c[1],S.ux,S.uz,6.4,0.2,y1F+3.2,y1F+3.6,C_(SOTC));
      signBoard(c[0]+S.vx*0.35,y1F+4.3,c[1]+S.vz*0.35,S.ang,6,0.9,'横浜駅 みなみ西口','相鉄線・JR線・地下鉄  相鉄口',SOTC,false);}
    // stairs between the 1F free area and みなみ通路 (B1)
    stairDir(inn,colls,S,35.5,22.5,-1,0,y1F,B1,2.8);regZone(S,27.4,36,20.8,24.2,B1-0.6,y1F+3,NAME,sot,B1,null);
    {const c=S.W(70,-4);signBoard(c[0],y1F+3.4,c[1],S.ang,4.4,0.6,'相鉄線 のりば  2F ↑','1・2・3番線',SOTC,true);}}
  /* B1 link from みなみ通路 north under the station to the stairs up to the 2F gate */
  {hall(S,-8,25,-9,-4,B1+0.004,B1C,{gaps:[[3,-9,-4],[0,21,25],[1,21,25],[2,-8.2,-4.8]],line:sot,k:'相鉄連絡通路'});
    stairDir(inn,colls,S,-26.4,-6.5,1,0,sTop,B1,2.8);escalatorVis(inn,stFrame(...S.W(-26.4,-5.35),S.ang),0,0,1,sTop,B1,0.9);
    shaft(S,-26.6,-7.6,-8.4,-4.6,B1,sTop-1.3);regZone(S,-26.8,-7.4,-8.6,-4.4,B1-0.6,sTop+3,NAME,sot,B1,null);terrainHole(...S.W(-17,-6.5),S.ang,9.8,2.3);plan(S,-26.6,-7.6,-8.4,-4.6,'stair');
    const c=S.W(5,-6.5);signBoard(c[0],B1+3.2,c[1],S.ang+Math.PI/2,4.2,0.6,'相鉄線 2F改札 ↑','JR線 みなみ改札 ↓',SOTC,true);}
  /* =============== 新相鉄ビル (相鉄ジョイナス・髙島屋): the PLATEAU footprint, station strip opened up =============== */
  {let Bd=null;for(const Pl of PLACES)for(const b of Pl.b)if(Math.abs(b.cx-12070.1)<4&&Math.abs(b.cz+13934.0)<4)Bd=b;
    if(Bd){const f=Bd.foot;const Lp=[];for(let i=0;i<f.length;i+=2)Lp.push(loc(S,f[i],f[i+1]));
      let base=1e9;for(let i=0;i<f.length;i+=2)base=Math.min(base,demH(f[i],f[i+1]));base-=0.15;
      const north=clipP(Lp,0,-1,30),westmid=clipP(clipP(clipP(Lp,1,1,21.5),0,1,-30),0,-1,-30);
      const strip1=clipP(clipP(clipP(Lp,1,-1,-21.5),0,1,-30),0,-1,-30),strip2=clipP(Lp,0,1,30);
      const toW=P=>{const o=[];for(const p of P){const w=S.W(p[0],p[1]);o.push(w[0],w[1]);}return o;};
      const tall=Bd.roof&&Bd.roof.length?34.8:30;const wallC=_col.set('#e4ded2').clone();
      const pls=placesNearRect(12000,-14130,12210,-13820);const rmat=pls.length?photoMat(pls,'roof'):MAT.top;
      const block=(P,y1,cutWall)=>{if(P.length<3)return;const w=toW(P);const n=w.length/2;
        for(let i=0;i<n;i++){const j=(i+1)%n;const p=P[i],q=P[j];const cut=cutWall(p,q);if(cut==='skip')continue;const yA=cut==='upper'?base+20:base;
          const dx=w[j*2]-w[i*2],dz=w[j*2+1]-w[i*2+1],len=Math.hypot(dx,dz);if(len<0.05)continue;facadeWalls(fac,[w[i*2],w[i*2+1],w[j*2],w[j*2+1]],yA,y1,wallC,FAC.SHOP,4.2);}
        for(const t of tri2(w))roofG.tri([w[t[0]*2],y1,w[t[0]*2+1]],[w[t[1]*2],y1,w[t[1]*2+1]],[w[t[2]*2],y1,w[t[2]*2+1]],0,1,0,_col.set('#ffffff'));};
      const on=(p,q,ax,v)=>Math.abs(p[ax]-v)<0.05&&Math.abs(q[ax]-v)<0.05;
      // the tall part: 髙島屋 / ジョイナス north of the platforms and west of the head concourse
      block(north,base+tall,(p,q)=>on(p,q,0,-30)?'upper':'full');block(westmid,base+tall,(p,q)=>(on(p,q,1,21.5)||on(p,q,0,30))?'upper':on(p,q,0,-30)?'skip':'full');
      for(const P of [north,westmid])if(P.length>=3){const c=addPoly(toW(P),base-0.3,base+tall);}
      // the station strip: 20 m, the platform level open at the south end where the line leaves
      const stripWall=(p,q)=>{if(on(p,q,0,-30)||on(p,q,0,30)||on(p,q,1,21.5))return'skip';return'full';};
      for(const P of [strip1,strip2]){if(P.length<3)continue;const w=toW(P);const n=w.length/2;const y1=base+20;
        for(let i=0;i<n;i++){const j=(i+1)%n;const p=P[i],q=P[j];if(stripWall(p,q)==='skip')continue;const seg=[w[i*2],w[i*2+1],w[j*2],w[j*2+1]];
          const south=p[0]>186&&q[0]>186;
          if(south){facadeWalls(fac,seg,base,sTop-1.4,wallC,FAC.SHOP,4.2);facadeWalls(fac,seg,sTop+7.8,y1,wallC,FAC.SHOP,4.2);}
          else facadeWalls(fac,seg,base,y1,wallC,FAC.SHOP,4.2);
          const dx=seg[2]-seg[0],dz=seg[3]-seg[1],len=Math.hypot(dx,dz);if(len<0.05)continue;
          if(!south){const np=Math.max(1,Math.ceil(len/2));for(let k=0;k<np;k++){const t0=k/np,t1=(k+1)/np;const mx=lerp(p[0],q[0],(t0+t1)/2),mb=lerp(p[1],q[1],(t0+t1)/2);if(mx>44.5&&mx<55.5&&mb>20)continue;
            colls.push(addOBB(lerp(seg[0],seg[2],(t0+t1)/2),lerp(seg[1],seg[3],(t0+t1)/2),len/np/2+0.05,0.2,Math.atan2(dz,dx),base,y1));}}}
        for(const t of tri2(w))roofG.tri([w[t[0]*2],y1,w[t[0]*2+1]],[w[t[1]*2],y1,w[t[1]*2+1]],[w[t[2]*2],y1,w[t[2]*2+1]],0,1,0,_col.set('#ffffff'));
        {const H=sTop+7.6;for(const t of tri2(w))inn.tri([w[t[0]*2],H,w[t[0]*2+1]],[w[t[1]*2],H,w[t[1]*2+1]],[w[t[2]*2],H,w[t[2]*2+1]],0,-1,0,CEIL);}}
      const rm=new THREE.Mesh(roofG.geo(),rmat);rm.castShadow=rm.receiveShadow=true;scene.add(rm);}}
  /* =============== ブルーライン: B3 platform, B2 concourse =============== */
  {const pc=blu.path.at(sB);const U=stFrame(pc.x,pc.z,Math.atan2(pc.tz,pc.tx));const ua=s=>s-sB;
    const s0=22398,s1=blu.path.L-0.5;const pt=bTop;const fl=blu.path.py(sB)-0.35;
    let bmin=1e9,bmax=-1e9;for(let s=s0-20;s<=s1;s+=4){const p=blu.path.at(s);const l=loc(U,p.x,p.z)[1];bmin=Math.min(bmin,l);bmax=Math.max(bmax,l);}
    const ha0=ua(s0)-14,ha1=ua(s1)+40,hb0=bmin-9.5,hb1=bmax+9.5;
    // the platform hall (the line runs on past the game's end of the line, so the tunnel continues)
    slabWithHoles(inn,colls,U,ha0,ha1,hb0,hb1,fl,0.4,[],C_('#6f6a63'),null);vslab(inn,U,ha0,ha1,hb0,hb1,B2-0.55,[],CEIL,2);walls(inn,U,ha0,ha1,hb0,hb1,fl,B2-0.55,[[2,bmin-7,bmax+7],[3,bmin-7,bmax+7]],C_('#dfe6ec'));
    for(const sd of [-1,1]){const c=U.W(sd>0?ha1+40:ha0-40,(hb0+hb1)/2);inn.obox(c[0],c[1],U.ux,U.uz,40,(bmax-bmin)/2+7,fl,pt+3.2,C_('#3a3f45'),2|4|8|(sd>0?32:16));}
    for(const sd of [-1,1]){const poly=platformAlong(inn,colls,blu,s0,s1,sd*(5.2-1.48),0,pt);const b=addPoly(poly,pt-1.2,pt);b.tag=0;b.plat=true;}
    {const rp=[];for(const [s,o] of [[s0,-3.72],[s1,-3.72],[s1,3.72],[s0,3.72]]){const p=blu.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,pt,blu,true,false);}
    {const rg=new GB();for(const sd of [-1,1]){const P=[];for(let s=s0-30;s<=blu.path.L;s+=3){const q=blu.path.at(s,sd*5.2);P.push([q.x,blu.path.py(s),q.z]);}railsAlong(rg,P);}scene.add(new THREE.Mesh(rg.geo(),UGMAT));}
    platformDressing(inn,colls,blu,s0,s1,0,pt,{every:20,ph:B2-0.55-pt,pc:'#e6ebef'});
    for(const s of [s0+15,sB,s1-18]){const q=blu.path.at(s,0);signBoard(q.x,pt+2.7,q.z,Math.atan2(q.tz,q.tx),2.2,0.55,'横浜','よこはま  Yokohama  B 20',BLUC);}
    {const q=blu.path.at(sB-30,0);signBoard(q.x,pt+3.0,q.z,Math.atan2(q.tz,q.tx)+Math.PI/2,2.6,0.5,'1番線 湘南台方面','2番線 あざみ野方面',BLUC,true);}
    lightGrid(U,ha0,ha1,hb0+3,hb1-3,B2-0.55,8,6);
    regZone(U,ha0,ha1,hb0,hb1,fl-1.2,B2C+0.3,NAME,blu,B2,null);plan(U,ha0,ha1,hb0,hb1,'blu B3');
    // B2 concourse: paid half to the south (stairs to the platform), free half to the north
    const runB=Math.ceil((B2-pt)/0.28)*0.42;const bh=[];
    for(const sa of [sB-8,sB-34]){const q=blu.path.at(sa,0);const l=loc(U,q.x,q.z);const top=[l[0],l[1]];const ang=Math.atan2(q.tz,q.tx)+Math.PI;
      stairsGB(inn,colls,...U.W(top[0],top[1]),ang,B2,pt,2.6);const h=[top[0]-runB-0.3,top[0]+0.3,top[1]-1.6,top[1]+1.6];bh.push(h);
      rail(U,h[0],h[1],h[2],h[3],B2,3);escalatorVis(inn,stFrame(...U.W(top[0],top[1]+2.3),ang),0,0,1,B2,pt,0.9);}
    // where the stairs from みなみ通路 come down
    const mf=J.W(-53,-86-Math.ceil((B1-B2)/0.28)*0.42);const ml=loc(U,mf[0],mf[1]);
    const ca0=-48,ca1=Math.max(62,ml[0]+6),cb0=-10,cb1=Math.max(20,ml[1]+4);
    const e5=loc(U,12066.9,-13979.3);const ch2=[[e5[0]-0.5,e5[0]+15,e5[1]-2.0,e5[1]+2.0]];
    {let x0=1e9,x1=-1e9,y0=1e9,y1=-1e9;for(const [a,b] of [[-54.8,-95],[-51.2,-95],[-54.8,-86],[-51.2,-86]]){const w=J.W(a,b);const l=loc(U,w[0],w[1]);x0=Math.min(x0,l[0]);x1=Math.max(x1,l[0]);y0=Math.min(y0,l[1]);y1=Math.max(y1,l[1]);}ch2.push([x0,x1,y0,y1]);}
    hall(U,ca0,ca1,cb0,cb1,B2,B2C,{fh:bh,ch:ch2,line:blu,k:'blu B2'});
    gateLine(U,0,cb0,cb1,-1,11,B2,'ブルーライン 改札','横浜市営地下鉄  Blue Line  B20',BLUC,1);
    stairDir(inn,colls,J,-53,-86,0,-1,B1,B2,2.8);shaft(J,-54.8,-51.2,-95,-86,B2C,B1-0.05);
    {const c=U.W(30,5);signBoard(c[0],B2+3.0,c[1],U.ang,4.6,0.6,'JR線・相鉄線  みなみ通路 ↑','出口 5  みなみ西口 ↑','#f2d33c',true);}
    // street exit 5 (OSM 2291214042), stairs down towards the free concourse
    {const e=e5;exitWell(U,e[0],e[1],1,0,B2,3.2,'市営地下鉄 横浜駅 5','ブルーライン  Blue Line',BLUC,blu);}}
  /* =============== meshes =============== */
  for(const g of [gb])if(!g.empty){const m=new THREE.Mesh(g.geo(),MAT.top);m.castShadow=true;m.receiveShadow=true;scene.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),UGMAT);m.receiveShadow=true;scene.add(m);}
  if(!inn.glass.empty){const m=new THREE.Mesh(inn.glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
  if(!lights.empty)scene.add(new THREE.Mesh(lights.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));
  if(!fac.empty){const m=new THREE.Mesh(fac.geo(),facadeMat());m.castShadow=true;m.receiveShadow=true;scene.add(m);}
  addLabel('横浜駅','JR・相鉄・ブルーライン',...(()=>{const c=J.W(125,-10);return[c[0],jTop+16,c[1]];})(),'st',JRC,900,0.9);
  if(window.__WDEBUG)window.__YKPLAN=PLAN;
}
/* benches and a 崎陽軒 kiosk on the JR islands */
function platformBench(F,I,fL,fR,top){for(let a=Math.max(I.a0,-90)+14;a<Math.min(I.a1,225)-10;a+=32){if(I.holes.some(h=>a>h[0]-6&&a<h[1]+6))continue;const m=(fL(a)+fR(a))/2;const c=F.W(a,m);
    gb.obox(c[0],c[1],F.ux,F.uz,0.9,0.22,top+0.42,top+0.48,C_('#2f6fb3'));gb.obox(c[0],c[1],F.ux,F.uz,0.9,0.03,top+0.48,top+0.85,C_('#2f6fb3'));gb.obox(c[0],c[1],F.ux,F.uz,0.05,0.05,top,top+0.42,C_('#8a949c'));}
  if(I.n==='5・6'){const a=40,m=(fL(a)+fR(a))/2;const c=F.W(a,m);gb.obox(c[0],c[1],F.ux,F.uz,2.2,1.1,top,top+2.5,C_('#f4efe6'));gb.obox(c[0],c[1],F.ux,F.uz,2.25,1.15,top+2.5,top+2.9,C_('#c8432f'));colls.push(addOBB(c[0],c[1],2.2,1.1,F.ang,top,top+2.5));
    signBoard(c[0]-F.vx*1.2,top+2.7,c[1]-F.vz*1.2,F.ang,2.0,0.35,'崎陽軒 シウマイ','','#c8432f',true);}}
ST_CUSTOM[NAME]={lines:new Set(['jr','sot','blu']),build};
})();
