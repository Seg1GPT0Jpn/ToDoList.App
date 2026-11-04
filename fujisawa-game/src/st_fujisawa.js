
/* ================= 藤沢駅 (JR東日本・小田急・江ノ電) =================
   From the station descriptions and the aerial photo:
   - JR: two island platforms (1・2 on the freight line to the north, 3・4 on the passenger line), a bridge-level
     station building (橋上駅舎) over the tracks with the north–south free passage, decks to the north (サンパール広場)
     and to the south over the bus terminal towards ODAKYU 湘南 GATE.
   - 小田急: terminal south of JR, 2 island platforms / 3 tracks; concourse at ground beyond the buffer stops,
     the new 2F gate into the JR concourse, and the transfer overpass at the west end of the platforms.
   - 江ノ電: one track with an alighting and a boarding platform on the 2nd floor of ODAKYU 湘南 GATE.
   Frame F: origin on the JR line under the concourse, +a east along the tracks, +b south. */
(()=>{
const NAME='藤沢';
LINE_EXT.odn=50;LINE_EXT.ods=50;LINE_EXT.eno=30;              // tracks run on to the buffer stops
ST_S['odn|藤沢']=0;ST_S['ods|藤沢']=0;ST_S['eno|藤沢']=28.5;     // trains pull up to the buffers
NO_LOOP.add('eno|藤沢');
ST_TRACKS['odn|藤沢']=[8.7,0,-5.5];ST_TRACKS['ods|藤沢']=[8.7,0,-5.5]; // 1・2・3 tracks measured on the OSM rails at the platform middle; followed from there                                       // one track between the two platforms
BLD_CLEAR.push([-7,21,0,4,4],[-100,27,0,4,4]);              // the PLATEAU station blocks are rebuilt by hand
BLD_SPLIT.push({x:25,z:150,lo:17.6,hi:26.6},{x:-27,z:223,lo:17.6,hi:23.6});
const FL=20.2,ROOF=25.8;
function canopyAlong(gb,colls,l,s0,s1,off,w,top,h=4.2){for(let s=s0;s<s1;s+=5){const a=l.path.at(s,off);const ang=Math.atan2(a.tz,a.tx);gb.obox(a.x,a.z,a.tx,a.tz,2.55,w/2,top+h,top+h+0.25,C_('#c3c8cc'));(gb.inn||gb).obox(a.x,a.z,a.tx,a.tz,2.55,w/2-0.4,top+h-0.25,top+h,C_('#c5cacd'),2);}
  for(let s=s0+4;s<s1;s+=15){const a=l.path.at(s,off);gb.obox(a.x,a.z,a.tx,a.tz,0.2,0.2,top,top+h,C_('#7a858e'));colls.push(addOBB(a.x,a.z,0.2,0.2,0,top,top+h));
    gb.obox(a.x,a.z,-a.tz,a.tx,0.12,w/2-0.3,top+h-0.6,top+h-0.25,C_('#7a858e'));}}
function lightStrips(F,a0,a1,b0,b1,y,step=6){const lg=new GB();for(let a=a0+3;a<a1;a+=step)for(let b=b0+3;b<b1;b+=8){const c=F.W(a,b);lg.obox(c[0],c[1],F.ux,F.uz,1.4,0.16,y-0.06,y-0.01,C_('#ffffff'),2);}scene.add(new THREE.Mesh(lg.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));}
/* a roofed, glazed box at bridge level (concourse, overpass, decks) */
function hallBox(gb,colls,F,a0,a1,b0,b1,fl,roof,open=[]){const c=F.W((a0+a1)/2,(b0+b1)/2);const hu=(a1-a0)/2,hv=(b1-b0)/2;
  gb.obox(c[0],c[1],F.ux,F.uz,hu,hv,roof,roof+0.5,C_('#b9bfc4'));(gb.inn||gb).obox(c[0],c[1],F.ux,F.uz,hu,hv,roof-0.02,roof,C_('#f3f2ee'),2);
  gb.obox(c[0],c[1],F.ux,F.uz,hu,hv,fl-0.6,fl-0.4,C_('#9aa1a7'),2);
  gb.glass&&[[a0,a1,b0,b0],[a0,a1,b1,b1],[a0,a0,b0,b1],[a1,a1,b0,b1]].forEach(([p0,p1,q0,q1],i)=>{if(open.includes(i))return;const cc=F.W((p0+p1)/2,(q0+q1)/2);gb.glass.obox(cc[0],cc[1],F.ux,F.uz,Math.max(0.05,(p1-p0)/2),Math.max(0.05,(q1-q0)/2),fl+1.1,roof,C_('#a9c8d8'));gb.obox(cc[0],cc[1],F.ux,F.uz,Math.max(0.06,(p1-p0)/2),Math.max(0.06,(q1-q0)/2),fl,fl+1.1,C_('#d9dcd8'));});
  for(const [p,q] of [[a0,b0],[a1,b0],[a0,b1],[a1,b1]]){const cc=F.W(p,q);gb.obox(cc[0],cc[1],F.ux,F.uz,0.3,0.3,fl,roof,C_('#8e979e'));}
  INDOOR.push({cx:c[0],cz:c[1],c:F.ux,s:F.uz,hl:hu,hw:hv,y0:fl-0.5,y1:roof});}
function build(){
  const jr=LINES.jr,odn=LINES.odn,eno=LINES.eno;const sK=jr.path.near(20,3).s;const p0=jr.path.at(sK);const ANG=Math.atan2(p0.tz,p0.tx);const F=stFrame(p0.x,p0.z,ANG);const W0=stFrame(0,0,0);
  const gb=new GB(),colls=[],inn=new GB();gb.glass=new GB();inn.glass=gb.glass;gb.inn=inn;
  const TILE=C_('#d7d2c7'),WALL=C_('#eeebe4'),JRG=C_('#2e8b3d');const jrTop=jr.path.py(sK)+1.1;
  /* ---------- 橋上駅舎 concourse ---------- */
  const CA0=-14,CA1=14,CB0=-26,CB1=63;
  const isl=[{b:-9.6,e:-7.3,name:'1・2'},{b:5.4,e:8.4,name:'3・4'}];const run=Math.ceil((FL-jrTop)/0.28)*0.42;
  const holes=isl.map(i=>[-1.5-run-0.5,-1.2,Math.min(i.b,i.e)-1.6,Math.max(i.b,i.e)+1.2]);
  const odRun=Math.ceil((FL-13.9)/0.28)*0.42;holes.push([-3-odRun-0.5,-2.7,43.4,46.6]);
  slabWithHoles(inn,colls,F,CA0,CA1,CB0,CB1,FL,0.5,holes,TILE,C_('#a6abaf'));
  hallBox(gb,colls,F,CA0,CA1,CB0,CB1,FL,ROOF,[0,1]);rectWalls(colls,F,CA0,CA1,CB0,CB1,FL,ROOF,[[0,-1e9,1e9],[1,-1e9,1e9]]);lightStrips(F,CA0,CA1,CB0,CB1,ROOF);
  {const c=F.W(8,(CB0+CB1)/2);inn.obox(c[0],c[1],F.ux,F.uz,6,(CB1-CB0)/2,FL,FL+0.012,C_('#e6e1d6'),1);}
  // JR paid area, gates facing the free passage, ticket machines, みどりの窓口
  partition(inn,colls,F,1.5,-20,1.5,-4.5,FL);partition(inn,colls,F,1.5,12.5,1.5,24,FL);partition(inn,colls,F,CA0,-20,1.5,-20,FL);partition(inn,colls,F,CA0,24,1.5,24,FL);
  {const g=F.W(1.5,4);gatesGB(inn,colls,g[0],g[1],-F.uz*0+F.vx,F.vz,16,FL);const m=F.W(9,-14);machinesGB(inn,colls,m[0],m[1],F.vx,F.vz,6,FL);
    const mw=F.W(11.5,-22);inn.obox(mw[0],mw[1],F.ux,F.uz,2.4,3,FL,FL+2.8,C_('#2e8b3d'));colls.push(addOBB(mw[0],mw[1],2.4,3,ANG,FL,FL+2.8));
    const sb=F.W(1.7,4);signBoard(sb[0],FL+3.3,sb[1],ANG+Math.PI/2,5,0.9,'JR線','東海道線  JR Tōkaidō Line','#2e8b3d',true);
    const so=F.W(11.6,-22);signBoard(so[0]-F.vx*3.05,FL+3.2,so[1]-F.vz*3.05,ANG,3.6,0.6,'みどりの窓口','Ticket Office','#2e8b3d',true);}
  for(const i of isl){stairDir(inn,colls,F,-1.5,i.b,-1,0,FL,jrTop,2.8);escalatorVis(inn,stFrame(...F.W(-1.5,i.e),ANG+Math.PI),0,0,1,FL,jrTop,1.0);
    const s=F.W(-6,i.b+1.6);signBoard(s[0],FL+2.6,s[1],ANG,2.6,0.5,i.name+'番線','東海道線','#2e8b3d',true);
    // shaft sides between concourse and platform
    const c=F.W(-1.5-run/2,(i.b+i.e)/2);inn.obox(c[0],c[1],F.ux,F.uz,run/2+0.3,Math.abs(i.e-i.b)/2+1.4,jrTop+2.3,FL-0.5,WALL,4|8);}
  // 小田急 2F gate (opened 2026) and its stairs to the ground concourse
  partition(inn,colls,F,1.5,38,1.5,39.5,FL);partition(inn,colls,F,1.5,50.5,1.5,52,FL);partition(inn,colls,F,CA0,38,1.5,38,FL);partition(inn,colls,F,CA0,52,1.5,52,FL);
  {const g=F.W(1.5,45);gatesGB(inn,colls,g[0],g[1],F.vx,F.vz,11,FL);const sb=F.W(1.7,45);signBoard(sb[0],FL+3.3,sb[1],ANG+Math.PI/2,5,0.9,'小田急線','江ノ島線  Odakyu Line','#1a5fb4',true);
    stairDir(inn,colls,F,-3,45,-1,0,FL,13.9,2.8);}
  // free-passage signs
  for(const [b,t] of [[-20,'北口  North Exit ↑'],[30,'南口・江ノ電 ↓'],[58,'南口  South Exit ↓']]){const c=F.W(8,b);signBoard(c[0],FL+3.3,c[1],ANG,4.2,0.65,t,'','#f2d33c',true);}
  for(const [a,b,w,col,t] of [[10,-6,5,'#d6392f','NewDays'],[10,18,4,'#8a5a3c','ベーカリー']]){const c=F.W(a+2,b);inn.obox(c[0],c[1],F.ux,F.uz,2,w/2,FL,FL+2.7,C_('#f2eee6'));inn.obox(c[0],c[1],F.ux,F.uz,2.1,w/2+0.1,FL+2.7,FL+3.1,C_(col));colls.push(addOBB(c[0],c[1],2,w/2,ANG,FL,FL+2.7));}
  /* ---------- 小田急 ground concourse beyond the buffer stops ---------- */
  {const fl=13.9,a0=-14,a1=8,b0=18,b1=48;const c=F.W((a0+a1)/2,(b0+b1)/2);inn.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2,(b1-b0)/2,demH(c[0],c[1])-0.3,fl,TILE,1|4|8|16|32);colls.push(addOBB(c[0],c[1],(a1-a0)/2,(b1-b0)/2,ANG,fl-1.4,fl));
    const g=F.W(-6,33);gatesGB(inn,colls,g[0],g[1],F.vx,F.vz,22,fl);partition(inn,colls,F,-6,b0,-6,22,fl);partition(inn,colls,F,-6,44,-6,b1,fl);
    const sb=F.W(-5.8,33);signBoard(sb[0],fl+3.0,sb[1],ANG+Math.PI/2,4.4,0.8,'小田急線 のりば','1・2・3・4番ホーム','#1a5fb4',true);
    const st=F.W(8,33);stairDir(inn,colls,F,8,33,1,0,fl,demH(st[0],st[1])+0.05,8);
    for(const [b,n] of [[24,'1'],[30.5,'2'],[36.5,'3'],[42,'4']]){const q=F.W(-13.6,b);signBoard(q[0],fl+2.6,q[1],ANG+Math.PI/2,1.0,0.6,n,'','#1a5fb4',true);}}
  // Odakyu buffer stops
  for(const o of [12.1,0,-8]){const p=odn.path.at(0.5,o);gb.obox(p.x,p.z,p.tx,p.tz,0.4,1.4,12.9,14.0,C_('#c8432f'));colls.push(addOBB(p.x,p.z,0.4,1.4,0,12.9,14));}
  /* ---------- platform roofs, name boards, the 80系 kiosk ---------- */
  {const sA=jr.path.near(-175,10).s,sB=jr.path.near(-4,6).s;canopyAlong(gb,colls,jr,sA,sB,-8.9,6.0,jrTop);canopyAlong(gb,colls,jr,sA,sB+60,6.85,9.4,jrTop);
    for(const s of [sA+20,sA+80,sB-30])for(const o of [-8.9,6.85]){const q=jr.path.at(s,o);signBoard(q.x,jrTop+2.7,q.z,Math.atan2(q.tz,q.tx),2.0,0.5,'藤沢','ふじさわ  Fujisawa  JT 08','#2e8b3d');}
    platformDressing(gb,colls,jr,sA,sB,6.85,jrTop,{every:30,pillars:false});
    // 湘南電車キオスク: NewDays dressed as a 国鉄80系 car, Tsujidō end of the 3・4 platform
    const q=jr.path.at(sA+8,6.85);const ang=Math.atan2(q.tz,q.tx);const kg=new THREE.Group();kg.position.set(q.x,jrTop,q.z);kg.rotation.y=-ang;scene.add(kg);
    const add=(c,w,h,d,x,y,z)=>{const m=new THREE.Mesh(BOX,M(c));m.scale.set(w,h,d);m.position.set(x,y,z);m.castShadow=true;kg.add(m);};
    add('#2f6b3f',8,1.2,2.6,0,0,0);add('#f08a24',8,1.1,2.62,0,1.2,0);add('#2f6b3f',8,0.5,2.64,0,2.3,0);add('#2f6b3f',8.2,0.25,2.4,0,2.8,0);add('#2a3a48',6.4,0.55,2.66,0.4,1.45,0);
    add('#f08a24',0.4,2.2,2.62,-4.1,0.5,0);add('#2a3a48',0.2,0.6,1.8,-4.31,1.6,0);colls.push(addOBB(q.x,q.z,4.2,1.35,ang,jrTop,jrTop+3));
    const op=odn.path;for(const [o,w] of [[6.05,9],[-4,5.2]])canopyAlong(gb,colls,odn,2,190,o,w+0.8,13.9,4.0);
    for(const s of [20,90,160])for(const o of [6.05,-4]){const q2=op.at(s,o);signBoard(q2.x,13.9+2.6,q2.z,Math.atan2(q2.tz,q2.tx),1.9,0.48,'藤沢','ふじさわ  Fujisawa  OE 13','#1a5fb4');}}
  /* ---------- 小田急・JR transfer overpass at the west end ---------- */
  {const ax0=-104,ax1=-96,bz0=-2,bz1=49;const c=W0.W((ax0+ax1)/2,(bz0+bz1)/2);
    const fingers=[{z:1.3,top:jrTop},{z:17.0,top:jrTop},{z:34.7,top:13.9},{z:44.7,top:13.9}];
    const hz=fingers.map(f=>[ax0-0.3-Math.ceil((FL-f.top)/0.28)*0.42,ax0+0.2,f.z-1.6,f.z+1.6]);
    slabWithHoles(inn,colls,W0,ax0,ax1,bz0,bz1,FL,0.5,[],TILE,C_('#a6abaf'));hallBox(gb,colls,W0,ax0,ax1,bz0,bz1,FL,FL+4.2);
    rectWalls(colls,W0,ax0,ax1,bz0,bz1,FL,FL+4.2,fingers.map(f=>[2,f.z-1.5,f.z+1.5]));
    for(const f of fingers){const r=stairDir(inn,colls,W0,ax0,f.z,-1,0,FL,f.top,2.8);const cc=W0.W(ax0-r/2,f.z);gb.obox(cc[0],cc[1],1,0,r/2,1.7,FL+2.6,FL+2.9,C_('#b9bfc4'));
      for(const sd of [-1,1]){const w=W0.W(ax0-r/2,f.z+sd*1.65);gb.glass.obox(w[0],w[1],1,0,r/2,0.04,f.top+1,FL+2.6,C_('#a9c8d8'));}}
    const g=W0.W(-100,26);gatesGB(inn,colls,g[0],g[1],1,0,8,FL);signBoard(-100,FL+3.3,26.2,0,6,0.8,'小田急線・JR線 のりかえ口','Odakyu ⇄ JR Transfer','#1a5fb4',true);lightStrips(W0,ax0,ax1,bz0,bz1,FL+4.2,5);}
  /* ---------- north deck (サンパール広場) ---------- */
  {const a0=-26,a1=46,b0=-60,b1=CB0;slabWithHoles(gb,colls,F,a0,a1,b0,b1,FL,0.6,[],C_('#d8cfbf'),C_('#9aa1a7'));
    for(let a=a0+4;a<a1;a+=12)for(let b=b0+4;b<b1;b+=11){const c=F.W(a,b);const g=demH(c[0],c[1]);gb.obox(c[0],c[1],F.ux,F.uz,0.45,0.45,g,FL-0.6,C_('#c9c5bb'));colls.push(addOBB(c[0],c[1],0.45,0.45,ANG,g,FL-0.6));}
    rectWalls(colls,F,a0,a1,b0,b1,FL,FL+1.15,[[1,CA0,CA1],[0,-19,-11],[0,31,39]]);
    for(const [p0,p1,q0,q1] of [[a0,a1,b0,b0],[a0,a0,b0,b1],[a1,a1,b0,b1],[a0,CA0,b1,b1],[CA1,a1,b1,b1]]){const c=F.W((p0+p1)/2,(q0+q1)/2);gb.obox(c[0],c[1],F.ux,F.uz,Math.max(0.06,(p1-p0)/2),Math.max(0.06,(q1-q0)/2),FL,FL+1.1,C_('#c0c6cb'));}
    for(const a of [-15,35]){const t=F.W(a,b0);stairDir(gb,colls,F,a,b0,0,-1,FL,demH(t[0],t[1]-12)+0.05,7);}
    const c=F.W(10,-44);signBoard(c[0],FL+3.6,c[1],ANG,5,0.95,'藤沢駅 北口','サンパール広場','#2e8b3d');
    for(const [a,b] of [[-6,-40],[26,-50],[40,-34]]){const t=F.W(a,b);gb.obox(t[0],t[1],F.ux,F.uz,1.2,1.2,FL,FL+0.6,C_('#a89b86'));const tr=new THREE.Mesh(CROWN,M('#4f9a45'));tr.position.set(t[0],FL+3.2,t[1]);tr.scale.set(2.4,2.2,2.4);scene.add(tr);const tk=new THREE.Mesh(TRUNK,MAT.trunk);tk.position.set(t[0],FL+0.6,t[1]);tk.scale.set(1.4,2,1.4);scene.add(tk);}}
  /* ---------- south deck over the bus terminal to ODAKYU 湘南 GATE ---------- */
  {const a0=12,a1=28,b0=CB1,b1=119;slabWithHoles(gb,colls,F,a0,a1,b0,b1,FL,0.6,[],C_('#d8cfbf'),C_('#9aa1a7'));
    for(let b=b0+6;b<b1;b+=12)for(const a of [a0+1.5,a1-1.5]){const c=F.W(a,b);const g=demH(c[0],c[1]);gb.obox(c[0],c[1],F.ux,F.uz,0.4,0.4,g,FL-0.6,C_('#c9c5bb'));colls.push(addOBB(c[0],c[1],0.4,0.4,ANG,g,FL-0.6));}
    rectWalls(colls,F,a0,a1,b0,b1,FL,FL+1.15,[[0,-1e9,1e9],[1,-1e9,1e9],[3,84,92]]);
    for(const a of [a0,a1]){const c=F.W(a,(b0+b1)/2);gb.obox(c[0],c[1],F.ux,F.uz,0.08,(b1-b0)/2,FL,FL+1.1,C_('#c0c6cb'));}
    // roof over the deck
    for(let b=b0;b<b1;b+=5){const c=F.W((a0+a1)/2,b+2.5);gb.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2-1,2.5,FL+3.6,FL+3.8,C_('#d2d6d9'));}
    const t=F.W(a1,88);stairDir(gb,colls,F,a1,88,1,0,FL,demH(t[0]+12,t[1])+0.05,3.2);
    const s=F.W(20,72);signBoard(s[0],FL+3.0,s[1],ANG,4.6,0.7,'江ノ電のりば ↓','ODAKYU 湘南 GATE 2F','#2f8f4e',true);}
  /* ---------- 江ノ電 藤沢駅 on the 2nd floor of ODAKYU 湘南 GATE ---------- */
  {const a0=-40,a1=10,b0=120,b1=171;slabWithHoles(inn,colls,F,a0,a1,b0,b1,FL,0.5,[],TILE,null);const c=F.W((a0+a1)/2,(b0+b1)/2);
    inn.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2,(b1-b0)/2,26.4,26.5,C_('#f2f1ec'),2);INDOOR.push({cx:c[0],cz:c[1],c:F.ux,s:F.uz,hl:(a1-a0)/2,hw:(b1-b0)/2,y0:FL-0.5,y1:26.4});lightStrips(F,a0,a1,b0,b1,26.4);
    // corridor from the deck into the building
    slabWithHoles(inn,colls,F,10,28,112,124,FL,0.5,[],TILE,null);
    // shops along the north side
    for(const [a,col,tx] of [[-30,'#2f8f4e','江ノ電グッズ'],[-16,'#8a5a3c','喫茶'],[0,'#e8902f','パン']]){const q=F.W(a,123);inn.obox(q[0],q[1],F.ux,F.uz,5,2.5,FL,FL+3,C_('#f4efe6'));inn.obox(q[0],q[1],F.ux,F.uz,5.1,2.6,FL+3,FL+3.5,C_(col));colls.push(addOBB(q[0],q[1],5,2.5,ANG,FL,FL+3));const s=F.W(a,125.7);signBoard(s[0],FL+3.25,s[1],ANG,3.6,0.45,tx,'',col,true,false);}
    // gates at the head of the two platforms, then steps down to platform level
    const ep=eno.path.at(0,0);const et=[eno.path.at(0,0).tx,eno.path.at(0,0).tz];const g=[ep.x-et[0]*3.5,ep.z-et[1]*3.5];
    gatesGB(inn,colls,g[0],g[1],-et[1],et[0],14,FL);signBoard(g[0],FL+3.1,g[1],Math.atan2(et[1],et[0])+Math.PI/2,4.4,0.85,'江ノ電','江ノ島・鎌倉方面  Enoden','#2f8f4e',true);
    {const st=[ep.x-et[0]*1.0,ep.z-et[1]*1.0];const ang=Math.atan2(et[1],et[0]);stairsGB(inn,colls,st[0],st[1],ang,FL,19.1,13);}
    for(const s of [10,30])for(const o of [-3.4,3.4]){const q=eno.path.at(s,o);signBoard(q.x,19.1+2.5,q.z,Math.atan2(q.tz,q.tx),1.7,0.45,'藤沢','ふじさわ  Fujisawa  EN 01','#2f8f4e');}
    {const q=eno.path.at(8,-3.4);signBoard(q.x,19.1+2.9,q.z,Math.atan2(q.tz,q.tx)+Math.PI/2,1.6,0.42,'のりば','Boarding','#2f8f4e',true);const q2=eno.path.at(8,3.4);signBoard(q2.x,19.1+2.9,q2.z,Math.atan2(q2.tz,q2.tx)+Math.PI/2,1.6,0.42,'おりば','Alighting','#7a858e',true);}
    {const p=eno.path.at(0.3,0);gb.obox(p.x,p.z,p.tx,p.tz,0.35,1.3,18.2,19.2,C_('#c8432f'));}}
  for(const [g,mat] of [[gb,MAT.top]])if(!g.empty){const m=new THREE.Mesh(g.geo(),mat);m.castShadow=true;m.receiveShadow=true;scene.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),UGMAT);m.receiveShadow=true;scene.add(m);}
  if(!gb.glass.empty){const m=new THREE.Mesh(gb.glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
  addLabel('藤沢駅','JR・小田急・江ノ電',...(()=>{const c=F.W(0,18);return [c[0],ROOF+6,c[1]];})(),'st','#2e8b3d',600,0.8);
}
ST_CUSTOM[NAME]={lines:new Set(['jr','odn','ods','eno']),build};
LANE_ADJ.push({key:'jr',s0:7140,s1:7460,lo:0.1,hi:13.6,blend:140,follow:true}); // follow the real 3・4番線 rails out to where they rejoin
})();
