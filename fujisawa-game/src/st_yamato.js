/* ================= 大和駅 (小田急江ノ島線・相鉄本線) =================
   From the station descriptions (Wikipedia, 小田急「駅立体図」, 相鉄「駅構内マップ」), OSM and the aerial photo:
   - 小田急: 高架駅, two island platforms / four tracks (2面4線). From east to west: 1 (下り待避), 2 (下り本線), 3 (上り本線),
     4 (上り待避); 1・2 = 藤沢・片瀬江ノ島方面, 3・4 = 相模大野・新宿方面. Fast trains overtake locals here.
   - 相鉄: 地下駅 (B1), one island platform (1面2線) under the old surface right of way (now the プロムナード).
     1番線 (south) 海老名方面 / orange wall band, 2番線 (north) 横浜方面 / light-blue wall band.
   - 1F: one concourse under the 小田急 viaduct, all inside the gates: 相鉄口 at the north end, 小田急口 at the south end
     (two steps down to the street), the 乗換改札 between them. From the 小田急 part four stairs go up (A/C towards
     藤沢, B/D with escalators towards 相模大野), from the 相鉄 part two stairs go down to B1 (west one westwards,
     east one eastwards) with escalators, and lifts on all three platforms.
   - 駅ビル「プロス」 stands against the east side of the viaduct (OSM building, left to the city layer).
   Frame F: origin on the 小田急 centre line at the station, +a towards 相模大野 (NNW), +b east.
   Frame G: origin on the 相鉄 island centre line, +a towards 海老名 (west), +b north. */
(()=>{
const NAME='大和';
const PY=70.5,PYS=55.3,FL=62.95;            // 小田急 rail level (viaduct), 相鉄 rail level (B1), 1F concourse floor
const S_OD=15541.3,S_SO=17319.0,SOFF=7.8;   // station s on each line; the 相鉄 island centre lies 7.8 m north of the line
PROF_ADJ.push({key:'odn',s0:S_OD-130,s1:S_OD+118,y:PY,blend:150},
              {key:'sot',s0:S_SO-140,s1:S_SO+440,y:PYS,blend:300});   // the 相鉄 tunnel runs on to its real portal near x=-2877
LANE_ADJ.push({key:'sot',s0:S_SO-112,s1:S_SO+112,lo:SOFF-7.2,hi:SOFF+7.2,blend:150});
{const O=[-2353.8,-14519.9],A=Math.atan2(-0.922,-0.387);
  BLD_CLEAR.push([O[0],O[1],A,128,18.6]);                         // the OSM station building is the viaduct itself
  PLAT_CLEAR.push([O[0],O[1],A,130,22]);}                         // OSM platforms (both lines) are rebuilt by hand
const ZN=-14555.5,ZS=-14502.0,ZFN=-14558.5,ZFS=-14499.6;          // building / forecourt edges (E–W lines, OSM)
const ZGN=-14552.0,ZGS=-14502.6,ZGT=-14532.5;                     // 相鉄口, 小田急口, 乗換改札 gate lines
const BW=-17.3,BE=17.9;                                           // concourse side walls (F b): the flats on the west and プロス on the east stand right against them
const XSW=-2366,XSE=-2349;                                        // tops of the two 相鉄 stairs (world x on the island axis)
/* ---------- small helpers ---------- */
function seg(gb,colls,x0,z0,x1,z1,y0,y1,th,col,faces=63){const dx=x1-x0,dz=z1-z0,L=Math.hypot(dx,dz);if(L<0.05)return;const ux=dx/L,uz=dz/L;
  gb.obox((x0+x1)/2,(z0+z1)/2,ux,uz,L/2,th/2,y0,y1,col,faces);if(colls)colls.push(addOBB((x0+x1)/2,(z0+z1)/2,L/2,th/2,Math.atan2(uz,ux),y0,y1));}
/* polygon slab with polygon holes: top (and bottom) faces, edges, one collider that knows its holes */
function polySlab(gb,outline,holes,y,th,colTop,colBot,colEdge,colls){const v2=a=>a.map(p=>new THREE.Vector2(p[0],p[1]));
  const tris=THREE.ShapeUtils.triangulateShape(v2(outline),holes.map(v2));const all=[...outline,...holes.flat()];
  for(const t of tris){const A=all[t[0]],B=all[t[1]],C=all[t[2]];if(colTop)gb.tri([A[0],y,A[1]],[B[0],y,B[1]],[C[0],y,C[1]],0,1,0,colTop);if(colBot)gb.tri([A[0],y-th,A[1]],[B[0],y-th,B[1]],[C[0],y-th,C[1]],0,-1,0,colBot);}
  if(colEdge)for(const ring of [outline,...holes])for(let i=0;i<ring.length;i++){const p=ring[i],q=ring[(i+1)%ring.length];const dx=q[0]-p[0],dz=q[1]-p[1],l=Math.hypot(dx,dz);if(l<0.01)continue;
    gb.quad([p[0],y-th,p[1]],[q[0],y-th,q[1]],[q[0],y,q[1]],[p[0],y,p[1]],dz/l,0,-dx/l,colEdge);gb.quad([p[0],y-th,p[1]],[q[0],y-th,q[1]],[q[0],y,q[1]],[p[0],y,p[1]],-dz/l,0,dx/l,colEdge);}
  if(colls){const f=[];for(const p of outline)f.push(p[0],p[1]);const b=addPoly(f,y-th,y);b.tag=0;if(holes.length)b.holes=holes;colls.push(b);return b;}}
/* one band of a platform along a line (path offsets o0→o1), with a bottom face; tactile strips on the o0 side if it is a track edge */
function platPiece(gb,colls,l,s0,s1,o0,o1,top,tactile){if(s1-s0<0.2)return;const N=Math.max(1,Math.ceil((s1-s0)/10));const A=[],B=[];const y0=top-1.45;
  for(let i=0;i<=N;i++){const s=s0+(s1-s0)*i/N;const a=l.path.at(s,o0),b=l.path.at(s,o1);A.push([a.x,a.z]);B.push([b.x,b.z]);}
  const deck=C_('#d6d0c2'),edge=C_('#bdb6a8'),bot=C_('#a9a49a');
  for(let i=0;i<N;i++){const a=A[i],b=A[i+1],c=B[i+1],d=B[i];gb.quad([a[0],top,a[1]],[b[0],top,b[1]],[c[0],top,c[1]],[d[0],top,d[1]],0,1,0,deck);gb.quad([a[0],y0,a[1]],[b[0],y0,b[1]],[c[0],y0,c[1]],[d[0],y0,d[1]],0,-1,0,bot);}
  const side=(P,Q,sg)=>{const dx=Q[0]-P[0],dz=Q[1]-P[1],l=Math.hypot(dx,dz)||1;gb.quad([P[0],y0,P[1]],[Q[0],y0,Q[1]],[Q[0],top,Q[1]],[P[0],top,P[1]],sg*dz/l,0,-sg*dx/l,edge);};
  const sg=Math.sign(o1-o0)||1;for(let i=0;i<N;i++){side(A[i],A[i+1],sg);side(B[i],B[i+1],-sg);}side(A[0],B[0],-sg);side(A[N],B[N],sg);
  if(tactile){const dir=sg;for(let i=0;i<N;i++){const sa=s0+(s1-s0)*i/N,sb=s0+(s1-s0)*(i+1)/N;for(const [q0,q1,c] of [[o0+dir*0.08,o0+dir*0.22,'#f4f4f2'],[o0+dir*0.85,o0+dir*1.15,'#f2d33c']]){const P=l.path.at(sa,q0),Q=l.path.at(sb,q0),R=l.path.at(sb,q1),S=l.path.at(sa,q1);gb.quad([P.x,top+0.012,P.z],[Q.x,top+0.012,Q.z],[R.x,top+0.012,R.z],[S.x,top+0.012,S.z],0,1,0,C_(c));}}}
  const f=[];for(const p of A)f.push(p[0],p[1]);for(const p of B.slice().reverse())f.push(p[0],p[1]);const b=addPoly(f,top-1.2,top);b.tag=0;b.plat=true;}
/* path interval [s0,s1] minus holes */
function minus(s0,s1,holes){let out=[[s0,s1]];for(const [h0,h1] of holes){const n=[];for(const [a,b] of out){if(h1<=a||h0>=b){n.push([a,b]);continue;}if(h0>a)n.push([a,h0]);if(h1<b)n.push([h1,b]);}out=n;}return out;}
/* stair flight with sloped glass balustrades and side colliders: top at (a,b) of frame Fr, descending along +a (da=1) or -a (da=-1) */
function flightR(gb,glass,colls,Fr,a,b,da,yTop,yBot,w){const ang=Fr.ang+(da>0?0:Math.PI);const p=Fr.W(a,b);const run=stairsGB(gb,colls,p[0],p[1],ang,yTop,yBot,w);
  const rc=C_('#8d969d'),gc=C_('#bfd3df');
  for(const sd of [-1,1]){const bb=b+sd*(w/2+0.06);const P0=Fr.W(a,bb),P1=Fr.W(a+da*run,bb);const nx=Fr.vx*sd,nz=Fr.vz*sd;
    glass.quad([P0[0],yTop+0.05,P0[1]],[P1[0],yBot+0.05,P1[1]],[P1[0],yBot+1.0,P1[1]],[P0[0],yTop+1.0,P0[1]],nx,0,nz,gc);
    gb.quad([P0[0],yTop+1.0,P0[1]],[P1[0],yBot+1.0,P1[1]],[P1[0],yBot+1.07,P1[1]],[P0[0],yTop+1.07,P0[1]],nx,0,nz,rc);gb.quad([P0[0],yTop+1.0,P0[1]],[P1[0],yBot+1.0,P1[1]],[P1[0],yBot+1.07,P1[1]],[P0[0],yTop+1.07,P0[1]],-nx,0,-nz,rc);
    for(let d=0;d<run-0.3;d+=1.26){const c=Fr.W(a+da*(d+0.63),bb);const h=yTop-(d+0.63)*(yTop-yBot)/run;colls.push(addOBB(c[0],c[1],0.63,0.06,Fr.ang,h-1.0,h+1.1));}}
  return run;}
/* a rail (glass panel + handrail + collider) between two world points at floor y */
function railSeg(gb,glass,colls,x0,z0,x1,z1,y){const dx=x1-x0,dz=z1-z0,L=Math.hypot(dx,dz);if(L<0.05)return;const ux=dx/L,uz=dz/L;const cx=(x0+x1)/2,cz=(z0+z1)/2;
  glass.obox(cx,cz,ux,uz,L/2,0.03,y,y+1.05,C_('#bfd3df'));gb.obox(cx,cz,ux,uz,L/2,0.05,y+1.05,y+1.12,C_('#8d969d'));colls.push(addOBB(cx,cz,L/2,0.08,Math.atan2(uz,ux),y,y+1.12));}
function rectRails(gb,glass,colls,Fr,a0,a1,b0,b1,y,open){const P=[Fr.W(a0,b0),Fr.W(a1,b0),Fr.W(a1,b1),Fr.W(a0,b1)];for(let i=0;i<4;i++){if(open===i)continue;const p=P[i],q=P[(i+1)%4];railSeg(gb,glass,colls,p[0],p[1],q[0],q[1],y);}}
/* ---------- sign atlas: operator-style boards drawn once into one texture, all signs in one mesh ---------- */
const AW=2048,AH=1024,SW=512,SH=128;let atlas=null,actx=null,slotN=0;const SLOT=new Map();
function slot(key,draw){if(SLOT.has(key))return SLOT.get(key);const i=slotN++;const x0=(i%4)*SW,y0=Math.floor(i/4)*SH;actx.save();actx.translate(x0,y0);actx.beginPath();actx.rect(0,0,SW,SH);actx.clip();draw(actx);actx.restore();
  const r=[x0/AW,1-(y0+SH)/AH,(x0+SW)/AW,1-y0/AH];SLOT.set(key,r);return r;}
const FONT='"M PLUS Rounded 1c","Hiragino Sans","Noto Sans JP",sans-serif';
function txt(x,s,px,cx,cy,col,w=800,align='center',maxW=480){x.fillStyle=col;x.font=`${w} ${px}px ${FONT}`;x.textAlign=align;x.textBaseline='middle';x.fillText(s,cx,cy,maxW);}
function rrect(x,x0,y0,w,h,r){x.beginPath();x.moveTo(x0+r,y0);x.arcTo(x0+w,y0,x0+w,y0+h,r);x.arcTo(x0+w,y0+h,x0,y0+h,r);x.arcTo(x0,y0+h,x0,y0,r);x.arcTo(x0,y0,x0+w,y0,r);x.closePath();}
const ODC='#2288cc',SOC='#0c1e56',SON='#0072c2',SOO='#f08300';
function odBadge(x,cx,cy,s){x.lineWidth=4*s;x.strokeStyle=ODC;x.fillStyle='#fff';rrect(x,cx-24*s,cy-24*s,48*s,48*s,6*s);x.fill();x.stroke();txt(x,'OE',13*s,cx,cy-11*s,ODC,800);txt(x,'05',22*s,cx,cy+8*s,ODC,800);}
function soBadge(x,cx,cy,s){x.fillStyle='#fff';rrect(x,cx-24*s,cy-24*s,48*s,48*s,7*s);x.fill();x.fillStyle=SON;rrect(x,cx-20*s,cy-20*s,40*s,40*s,5*s);x.fill();txt(x,'SO',13*s,cx,cy-9*s,'#fff',800);x.fillStyle=SOO;x.fillRect(cx-14*s,cy-0.5*s,28*s,2*s);txt(x,'14',19*s,cx,cy+10*s,'#fff',800);}
function odName(x,left,right){x.fillStyle='#fff';x.fillRect(0,0,SW,SH);txt(x,'大和',62,256,44,'#1b1f24',800);txt(x,'やまと   Yamato',19,256,84,'#4b5a66',600);odBadge(x,52,48,1.15);
  x.fillStyle=ODC;x.fillRect(0,100,SW,28);txt(x,left,17,10,114,'#fff',700,'left',240);txt(x,right,17,502,114,'#fff',700,'right',240);}
function soName(x,left,right){x.fillStyle=SOC;x.fillRect(0,0,SW,SH);x.fillStyle=SOO;x.fillRect(0,97,SW,3);txt(x,'大和',62,256,44,'#fff',800);txt(x,'やまと   Yamato',19,256,84,'#cfd8e6',600);soBadge(x,52,48,1.2);
  txt(x,left,17,10,114,'#fff',700,'left',240);txt(x,right,17,502,114,'#fff',700,'right',240);}
function infoSign(x,bg,num,main,sub,fg='#fff'){x.fillStyle=bg;x.fillRect(0,0,SW,SH);let tx=256;if(num){x.fillStyle='#fff';rrect(x,14,18,num.length>2?150:92,92,10);x.fill();txt(x,num,num.length>2?44:62,14+(num.length>2?75:46),66,bg,800);tx=num.length>2?336:292;}
  txt(x,main,sub?40:48,tx,sub?50:64,fg,800,'center',num?(num.length>2?320:400):480);if(sub)txt(x,sub,20,tx,96,fg==='#fff'?'#dfe8f2':'#33404a',600,'center',num?(num.length>2?320:400):480);}
function mkAtlas(){const cv=document.createElement('canvas');cv.width=AW;cv.height=AH;actx=cv.getContext('2d');actx.fillStyle='#888';actx.fillRect(0,0,AW,AH);
  slot('odE',x=>odName(x,'← 桜ヶ丘 OE 06','鶴間 OE 04 →'));slot('odW',x=>odName(x,'← 鶴間 OE 04','桜ヶ丘 OE 06 →'));
  slot('soN',x=>soName(x,'← 瀬谷 SO 13','相模大塚 SO 15 →'));slot('soS',x=>soName(x,'← 相模大塚 SO 15','瀬谷 SO 13 →'));
  slot('od12',x=>infoSign(x,ODC,'1・2','藤沢・片瀬江ノ島方面','for Fujisawa / Katase-Enoshima'));slot('od34',x=>infoSign(x,ODC,'3・4','相模大野・新宿方面','for Sagami-Ōno / Shinjuku / 千代田線'));
  slot('od1',x=>infoSign(x,ODC,'1','藤沢・片瀬江ノ島方面','for Fujisawa / Katase-Enoshima'));slot('od2',x=>infoSign(x,ODC,'2','藤沢・片瀬江ノ島方面','for Fujisawa / Katase-Enoshima'));
  slot('od3',x=>infoSign(x,ODC,'3','相模大野・新宿方面','for Sagami-Ōno / Shinjuku'));slot('od4',x=>infoSign(x,ODC,'4','相模大野・新宿方面','for Sagami-Ōno / Shinjuku'));
  slot('so1',x=>infoSign(x,SOC,'1','海老名方面','for Ebina'));slot('so2',x=>infoSign(x,SOC,'2','横浜・湘南台・羽沢横浜国大方面','for Yokohama / Shōnandai / Hazawa'));
  slot('gSO',x=>infoSign(x,SOC,'','相鉄線','Sotetsu Line  SO 14'));slot('gOD',x=>infoSign(x,ODC,'','小田急線','Odakyu Line  OE 05'));
  slot('xSO',x=>infoSign(x,SOC,'','相鉄線 のりかえ','Transfer to Sotetsu Line'));slot('xOD',x=>infoSign(x,ODC,'','小田急線 のりかえ','Transfer to Odakyu Line'));
  slot('eSO',x=>{x.fillStyle=SOC;x.fillRect(0,0,SW,SH);soBadge(x,62,64,1.6);txt(x,'大和駅  相鉄口',52,300,52,'#fff',800,'center',380);txt(x,'Yamato Sta.  Sotetsu Line ・ 小田急線',20,300,100,'#dfe8f2',600,'center',380);});
  slot('eOD',x=>{x.fillStyle='#fff';x.fillRect(0,0,SW,SH);odBadge(x,62,60,1.6);txt(x,'大和駅  小田急口',52,300,50,'#1b1f24',800,'center',380);x.fillStyle=ODC;x.fillRect(0,92,SW,36);txt(x,'Yamato Sta.  Odakyu Line ・ 相鉄線',20,300,110,'#fff',600,'center',380);});
  slot('pros',x=>{x.fillStyle='#f4efe4';x.fillRect(0,0,SW,SH);txt(x,'PROS',64,170,62,'#c0392b',800);txt(x,'大和駅ビル プロス',30,370,62,'#3a3f45',800,'center',250);});
  slot('hOD12',x=>infoSign(x,'#ffffff','1・2','番ホーム  藤沢・片瀬江ノ島','Platforms 1・2  for Fujisawa','#1b1f24'));slot('hOD34',x=>infoSign(x,'#ffffff','3・4','番ホーム  相模大野・新宿','Platforms 3・4  for Shinjuku','#1b1f24'));
  slot('hSO',x=>infoSign(x,SOC,'B1','相鉄線ホーム','海老名・横浜方面  Sotetsu Platform'));
  slot('exN',x=>infoSign(x,'#f2d33c','','出口  相鉄口 ↑','Exit  Sotetsu Gate (North)','#1b1f24'));slot('exS',x=>infoSign(x,'#f2d33c','','出口  小田急口 ↓','Exit  Odakyu Gate (South)','#1b1f24'));
  slot('shop',x=>infoSign(x,'#2a7ab8','','ODAKYU SHOP','','#fff'));slot('ist',x=>infoSign(x,'#d0021b','','station IST','','#fff'));slot('wc',x=>infoSign(x,'#5a6670','','トイレ','Toilets','#fff'));
  atlas=new THREE.CanvasTexture(cv);atlas.colorSpace=THREE.SRGBColorSpace;atlas.anisotropy=4;}
/* a board in the sign mesh: centre (x,y,z), right vector (rx,rz) as seen from the front, width/height, front slot, back slot (or null) */
function board(sg,x,y,z,rx,rz,w,h,front,back){const P=(sx,sy,d)=>[x+rx*sx*w/2+(-rz)*d,y+sy*h/2,z+rz*sx*w/2+rx*d];const nx=-rz,nz=rx; // front normal (toward the viewer)
  const put=(r,sgn)=>{const d=sgn*0.035;const A=sgn>0?P(-1,-1,d):P(1,-1,d),B=sgn>0?P(1,-1,d):P(-1,-1,d),C=sgn>0?P(1,1,d):P(-1,1,d),D=sgn>0?P(-1,1,d):P(1,1,d);
    sg.quad(A,B,C,D,nx*sgn,0,nz*sgn,_col.set('#fff'),[[r[0],r[1]],[r[2],r[1]],[r[2],r[3]],[r[0],r[3]]]);};
  put(SLOT.get(front),1);put(SLOT.get(back||front),-1);}
/* ---------- build ---------- */
function build(){
  const odn=LINES.odn,sot=LINES.sot;const sC=odn.stByName.get(NAME).s,sS=sot.stByName.get(NAME).s;
  if(Math.abs(sC-S_OD)>2||Math.abs(sS-S_SO)>2)console.warn('大和: station s moved',sC,sS);
  const p0=odn.path.at(sC);const ANG=Math.atan2(p0.tz,p0.tx);const F=stFrame(p0.x,p0.z,ANG);
  const toF=(x,z)=>{const dx=x-F.ox,dz=z-F.oz;return [dx*F.ux+dz*F.uz,dx*F.vx+dz*F.vz];};
  const aAtZ=(z,b)=>(z-F.oz-b*F.vz)/F.uz;const WZ=(z,b)=>F.W(aAtZ(z,b),b);
  const q0=sot.path.at(sS,SOFF);const G=stFrame(q0.x,q0.z,Math.atan2(q0.tz,q0.tx));const W0=stFrame(0,0,0);
  const TOP=odn.path.py(sC)+1.1,TOPS=sot.path.py(sS)+1.1,CEILS=TOPS+3.6,DECK0=TOP-2.8,DECK1=TOP-1.4,CCEIL=FL+4.2;
  const gb=new GB(),colls=[],inn=new GB(),glass=new GB(),sg=new GB(),lg=new GB();inn.glass=glass;mkAtlas();
  const WALL=C_('#eeebe4'),TILE=C_('#d9d4c9'),CEIL=C_('#f2f1ec'),CONC=C_('#c9c5bb'),DARK=C_('#3a3f45'),ODB=C_(ODC),SON_=C_(SOC);
  /* --- line data the generic pass got wrong here: the whole station is on the viaduct, the 相鉄 tunnel is longer --- */
  {const f=odn.path.flags;for(let i=Math.round((sC+10)/10);i<=Math.round((sC+220)/10)&&i<f.length;i++)if(f[i]===0)f[i]=1;
   const g=sot.path.flags;for(let i=Math.round((S_SO+130)/10);i<=Math.round((S_SO+512)/10)&&i<g.length;i++)g[i]=2;}
  // generic bridge piers on the centre line inside the station are replaced by the viaduct's own bents
  {let n=0;for(const bt of BATCH.values()){const keep=[];for(const it of bt.items){if(it.geo===CYL&&Math.abs(it.o.position.x-p0.x)<320&&Math.abs(it.o.position.z-p0.z)<320){const r=odn.path.near(it.o.position.x,it.o.position.z);if(r.d<2&&r.s>sC-230&&r.s<sC+240){n++;
      const k=Math.floor(it.o.position.x/CELL)*65536+Math.floor(it.o.position.z/CELL);const a=COLL.get(k)||[];const hit=a.filter(b=>b.t===0&&Math.abs(b.cx-it.o.position.x)<0.01&&Math.abs(b.cz-it.o.position.z)<0.01);if(hit.length)removeColl(hit);continue;}}keep.push(it);}bt.items=keep;}
   console.log('LOG 大和: generic piers removed',n);}
  // OSM tracks on the viaduct take the 小田急 rail level (the passing tracks were picking up the 相鉄 tunnel below)
  for(const t of TRACKS){const a=t.pts;if(!t.ys)continue;let near=false;for(let i=0;i<a.length;i+=2)if(Math.abs(a[i]-p0.x)<300&&Math.abs(a[i+1]-p0.z)<300){near=true;break;}if(!near)continue;
    for(let i=0;i<a.length;i+=2){const r=odn.path.near(a[i],a[i+1]);if(r.d<18&&Math.abs(r.s-sC)<260)t.ys[i/2]=odn.path.py(r.s);}}
  /* =============== 2F: 小田急 viaduct, two island platforms =============== */
  const RUN_O=Math.ceil((TOP-FL)/0.28)*0.42,RUN_E=(TOP-FL)/Math.tan(30*Math.PI/180);
  const aF_AC=-1.0,aT_AC=aF_AC-RUN_O,aF_BD=5.0,aT_BD=aF_BD+RUN_O,aTE=aF_BD+RUN_E;  // stair feet / tops (F a)
  const BS0=6.75,BS1=9.65,BE1=11.0,BIN=3.45,BOUT=12.9,BC=8.2,BESC=10.35;            // island bands (|b|)
  const sA=sC-110,sB=sC+99;const EL=2.25;                                           // platform ends, lifts at a=EL
  // the two 相鉄 stair wells (G frame), their tops on the island axis; rooms of the concourse (F frame)
  const aW=(XSW-G.ox)/G.ux,aE=(XSE-G.ox)/G.ux;const RUN_S=Math.ceil((FL-TOPS)/0.28)*0.42,RUN_SE=(FL-TOPS)/Math.tan(30*Math.PI/180);
  const WELL=[{a0:aW,a1:aW+4.4,b0:-2.7,b1:2.7,da:1,top:aW},{a0:aE-4.4,a1:aE,b0:-2.2,b1:2.4,da:-1,top:aE}];
  const gRect=(a0,a1,b0,b1)=>[G.W(a0,b0),G.W(a1,b0),G.W(a1,b1),G.W(a0,b1)];
  const fRect=(a0,a1,b0,b1)=>[F.W(a0,b0),F.W(a1,b0),F.W(a1,b1),F.W(a0,b1)];
  const flat=r=>{const f=[];for(const p of r)f.push(p[0],p[1]);return f;};
  const ROOMS={odToilet:[7,15.5,BW,-13.2],odShop:[-11,-7.5,-1.6,1.6],odOffice:[-21,-14.5,12.8,BE],soOffice:[31,40,BW,-13.2],soShop:[22.5,27,13.5,BE]};
  const KEEPOUT=[];for(const w of WELL)KEEPOUT.push(flat(gRect(w.a0-1,w.a1+1,w.b0-1,w.b1+1)));
  for(const k in ROOMS){const r=ROOMS[k];KEEPOUT.push(flat(fRect(r[0]-0.8,r[1]+0.8,r[2]-0.8,r[3]+0.8)));}
  for(const sd of [-1,1])KEEPOUT.push(flat(fRect(aT_AC-0.5,aT_BD+0.5,Math.min(sd*(BS0-0.5),sd*(BE1+0.5)),Math.max(sd*(BS0-0.5),sd*(BE1+0.5)))));
  KEEPOUT.push(flat(gRect((aW+aE)/2-1.8,(aW+aE)/2+1.8,-1.8,1.8)));
  for(const sd of [-1,1]){
    const bands=[[BIN,BS0,[],true],[BS0,BS1,[[sC+aT_AC,sC+aT_AC+5.0],[sC+aT_BD-5.0,sC+aT_BD]],false],[BS1,BE1,[[sC+aTE-5.0,sC+aTE]],false],[BE1,BOUT,[],false]];
    for(const [b0,b1,holes,tac] of bands)for(const [s0,s1] of minus(sA,sB,holes)){
      if(b1===BOUT)platPiece(gb,colls,odn,s0,s1,sd*BOUT,sd*b0,TOP,true);else platPiece(gb,colls,odn,s0,s1,sd*b0,sd*b1,TOP,tac);}
    const rp=[];for(const [s,o] of [[sA,sd*BIN],[sB,sd*BIN],[sB,sd*BOUT],[sA,sd*BOUT]]){const p=odn.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,TOP,odn,false,false);
    // stairs and escalator from the concourse (A/C go up towards 藤沢, B/D towards 相模大野)
    flightR(inn,glass,colls,F,aT_AC,sd*BC,1,TOP,FL,2.6);flightR(inn,glass,colls,F,aT_BD,sd*BC,-1,TOP,FL,2.6);
    escalatorVis(inn,F,aTE,sd*BESC,-1,TOP,FL,1.0);{const c=F.W(aF_BD+1.6,sd*BESC);colls.push(addOBB(c[0],c[1],1.6,0.6,ANG,FL,FL+1.2));}
    // railings round the openings on the platform
    {const y=TOP;const o=(a,b)=>F.W(a,sd*b);const R=(a0,b0,a1,b1)=>{const p=o(a0,b0),q=o(a1,b1);railSeg(gb,glass,colls,p[0],p[1],q[0],q[1],y);};
      R(aT_AC,BS0,aT_AC+5,BS0);R(aT_AC,BS1,aT_AC+5,BS1);R(aT_AC+5,BS0,aT_AC+5,BS1);
      R(aT_BD-5,BS0,aT_BD,BS0);R(aT_BD-5,BS0,aT_BD-5,BS1);R(aT_BD-5,BS1,aTE-5,BS1);R(aT_BD,BS1,aTE,BS1);R(aTE-5,BS1,aTE-5,BE1);R(aTE-5,BE1,aTE,BE1);}
    // lift between the stair feet (① on 3・4, ② on 1・2)
    {const c=F.W(EL,sd*BC);glass.obox(c[0],c[1],F.ux,F.uz,1.0,1.0,FL,TOP+2.6,C_('#a9c8d8'));for(const [u,v] of [[-1,-1],[1,-1],[1,1],[-1,1]]){const q=F.W(EL+u*1.0,sd*BC+v*1.0);gb.obox(q[0],q[1],F.ux,F.uz,0.07,0.07,FL,TOP+2.6,C_('#7d868d'));}
      gb.obox(c[0],c[1],F.ux,F.uz,1.1,1.1,TOP+2.6,TOP+2.9,C_('#7d868d'));colls.push(addOBB(c[0],c[1],1.05,1.05,ANG,FL,TOP+2.9));}
    // canopy over the island: roof in 5 m panels, darker roof lights, columns on the island axis
    {const cA=-104,cB=93,h=3.7;for(let a=cA;a<cB;a+=5){const p=odn.path.at(sC+a+2.5,sd*8.15);gb.obox(p.x,p.z,p.tx,p.tz,2.55,5.25,TOP+h,TOP+h+0.22,C_('#b9bfc4'),1|4|8|16|32);inn.obox(p.x,p.z,p.tx,p.tz,2.55,5.1,TOP+h-0.06,TOP+h,C_('#b9bcba'),2);
        if(((a-cA)/5)%2===0){const q=odn.path.at(sC+a+2.5,sd*8.15);gb.obox(q.x,q.z,q.tx,q.tz,1.4,2.2,TOP+h+0.22,TOP+h+0.26,C_('#5d6870'),1);}}
      for(let a=cA+4;a<cB;a+=15){if((a>aT_AC-1&&a<aT_AC+6)||(a>aT_BD-6&&a<aTE+1)||Math.abs(a-EL)<2)continue;const p=odn.path.at(sC+a,sd*BC);gb.obox(p.x,p.z,p.tx,p.tz,0.2,0.2,TOP,TOP+h,C_('#7a858e'));colls.push(addOBB(p.x,p.z,0.2,0.2,0,TOP,TOP+h));
        gb.obox(p.x,p.z,-p.tz,p.tx,0.12,4.9,TOP+h-0.55,TOP+h,C_('#7a858e'));}
      for(let a=cA+11;a<cB-6;a+=30){if((a>aT_AC-4&&a<aT_AC+8)||(a>aT_BD-8&&a<aTE+3)||Math.abs(a-EL)<4)continue;const q=odn.path.at(sC+a,sd*BC);gb.obox(q.x,q.z,q.tx,q.tz,0.9,0.22,TOP+0.42,TOP+0.48,C_('#2f6fb3'));gb.obox(q.x,q.z,q.tx,q.tz,0.9,0.03,TOP+0.48,TOP+0.85,C_('#2f6fb3'));gb.obox(q.x,q.z,q.tx,q.tz,0.05,0.2,TOP,TOP+0.42,C_('#8a949c'));colls.push(addOBB(q.x,q.z,0.9,0.25,ANG,TOP,TOP+0.85));}}
    // station name boards along both platform edges, 番線 signs across the island
    for(const a of [-82,-40,38,78])for(const bb of [BIN+1.9,BOUT-1.9]){const p=odn.path.at(sC+a,sd*bb);board(sg,p.x,TOP+2.75,p.z,p.tx,p.tz,2.3,0.575,'odE','odW');
      gb.obox(p.x,p.z,p.tx,p.tz,0.03,0.03,TOP+3.06,TOP+3.7,C_('#7a858e'));}
    for(const a of [-60,58]){const p=odn.path.at(sC+a,sd*BC);const r=[-p.tz,p.tx];board(sg,p.x,TOP+2.9,p.z,r[0],r[1],2.6,0.65,sd>0?'od12':'od34');gb.obox(p.x,p.z,p.tx,p.tz,0.03,0.03,TOP+3.22,TOP+3.7,C_('#7a858e'));
      for(const [bb,k] of [[BIN+1.2,sd>0?'od2':'od3'],[BOUT-1.2,sd>0?'od1':'od4']]){const q=odn.path.at(sC+a+6,sd*bb);board(sg,q.x,TOP+2.9,q.z,r[0],r[1],1.6,0.4,k);}}
  }
  // deck slab (the viaduct) with the stair openings, parapets, bents
  {const wAt=a=>a<-176||a>164?6.0:a<-130?lerp(6.0,17.4,(a+176)/46):a>118?lerp(17.4,6.0,(a-118)/46):17.4;
    const sD0=sC-200,sD1=sC+222;const L1=[],L2=[];for(let s=sD0;s<=sD1+0.01;s+=6){const w=wAt(s-sC);const a=odn.path.at(s,w),b=odn.path.at(s,-w);L1.push([a.x,a.z]);L2.push([b.x,b.z]);}
    const outline=[...L1,...L2.reverse()];const holes=[];
    const hp=(s0,s1,o0,o1)=>{const r=[];for(const [s,o] of [[s0,o0],[s1,o0],[s1,o1],[s0,o1]]){const p=odn.path.at(s,o);r.push([p.x,p.z]);}return r;};
    for(const sd of [-1,1]){holes.push(hp(sC+aT_AC-0.2,sC+aT_AC+7.4,sd*6.6,sd*9.8));holes.push(hp(sC+aT_BD-7.4,sC+aTE+0.2,sd*6.6,sd*11.1));}
    polySlab(gb,outline,holes,DECK1,DECK1-DECK0,C_('#8a8177'),null,C_('#c4bfb5'),colls);polySlab(inn,outline,holes,DECK1,DECK1-DECK0,null,C_('#9d998f'),null,null);
    for(const L of [L1,L2.slice().reverse()])for(let i=0;i<L.length-1;i++){const p=L[i],q=L[i+1];seg(gb,colls,p[0],p[1],q[0],q[1],DECK0,TOP+0.1,0.35,C_('#cfcabf'));}
    // bents: three columns where the deck is wide, one where it is narrow; none in roads or where the concourse needs the room
    const keep=[];const roadHit=(x,z)=>{for(const r of ROADS){const p=r.pts;if(Math.abs(p[0]-x)>400&&Math.abs(p[p.length-2]-x)>400)continue;for(let i=0;i+3<p.length;i+=2){const ax=p[i],az=p[i+1],bx=p[i+2],bz=p[i+3];const dx=bx-ax,dz=bz-az,l2=dx*dx+dz*dz||1;let t=((x-ax)*dx+(z-az)*dz)/l2;t=clamp(t,0,1);if(Math.hypot(ax+dx*t-x,az+dz*t-z)<r.w/2+1.2)return true;}}return false;};
    for(let a=-194;a<=216;a+=12){const w=wAt(a);const bs=w>12?[-(w-1.8),0,w-1.8]:[0];const p=odn.path.at(sC+a);
      for(const b of bs){const q=odn.path.at(sC+a,b);const inC=q.z>ZN-1&&q.z<ZS+1&&b>BW-1&&b<BE+1;
        if(!inC&&roadHit(q.x,q.z))continue;if(KEEPOUT.some(k=>inPolyF(q.x,q.z,k)))continue;if(inC&&[ZGN,ZGS,ZGT].some(z=>Math.abs(q.z-z)<1.6))continue;
        const g=inC?FL:demH(q.x,q.z)-0.3;(inC?inn:gb).obox(q.x,q.z,p.tx,p.tz,0.5,0.5,g,DECK0,C_('#c9c5bb'));colls.push(addOBB(q.x,q.z,0.5,0.5,ANG,g,DECK0));}
      gb.obox(p.x,p.z,p.tx,p.tz,0.45,w-0.5,DECK0-0.6,DECK0,C_('#bdb8ad'),2|4|8|16|32);}}
  /* =============== 1F concourse =============== */
  // floor (with the forecourts) and its holes; one terrain hole per well
  {const outline=[WZ(ZFS,BW),WZ(ZFS,BE),WZ(ZFN,BE),WZ(ZFN,BW)];const holes=WELL.map(w=>gRect(w.a0,w.a1,w.b0,w.b1));
    polySlab(inn,outline,holes,FL,0.4,TILE,C_('#c4c0b6'),C_('#bdb6a8'),colls);
    for(const w of WELL){const c=G.W((w.a0+w.a1)/2,(w.b0+w.b1)/2);terrainHole(c[0],c[1],G.ang,(w.a1-w.a0)/2+0.1,(w.b1-w.b0)/2+0.1);}
    // guide band along the axis of the paid area, darker forecourt paving
    {const c=F.W(10,0);inn.obox(c[0],c[1],F.ux,F.uz,24,0.35,FL,FL+0.01,C_('#f2d33c'),1);}
    for(const [z0,z1] of [[ZFN,ZGN],[ZGS,ZFS]]){const r=[WZ(z1,BW),WZ(z1,BE),WZ(z0,BE),WZ(z0,BW)];const v2=r.map(p=>new THREE.Vector2(p[0],p[1]));for(const t of THREE.ShapeUtils.triangulateShape(v2,[])){const A=r[t[0]],B=r[t[1]],C=r[t[2]];inn.tri([A[0],FL+0.008,A[1]],[B[0],FL+0.008,B[1]],[C[0],FL+0.008,C[1]],0,1,0,C_('#c8c1b2'));}}
    // two steps down from the 小田急口 forecourt to the street, a kerb at the 相鉄口 side
    {const gS=Math.min(demH(...WZ(ZFS+1.5,-10)),demH(...WZ(ZFS+1.5,10)));const n=clamp(Math.round((FL-gS)/0.2),0,3);
      for(let i=0;i<n;i++){const h=FL-(i+1)*(FL-gS)/(n+1);const z0=ZFS+i*0.42,z1=z0+0.42;const r=[WZ(z1,BW),WZ(z1,BE),WZ(z0,BE),WZ(z0,BW)];const c=[(r[0][0]+r[2][0])/2,(r[0][1]+r[2][1])/2];
        const len=Math.hypot(r[1][0]-r[0][0],r[1][1]-r[0][1]);inn.obox(c[0],c[1],1,0,len/2,0.21,gS-0.4,h,C_('#c9c3b6'));colls.push(addOBB(c[0],c[1],len/2,0.21,0,gS-0.4,h));}}}
  // side walls (with outside faces), fascias over the open ends, suspended ceiling with the stair openings
  {for(const b of [BW,BE]){const p=WZ(ZS,b),q=WZ(ZN,b);seg(inn,colls,p[0],p[1],q[0],q[1],FL,DECK0,0.3,WALL);if(b>0)continue;
      const s=b<0?-1:1;const p2=WZ(ZS,b+s*0.2),q2=WZ(ZN,b+s*0.2);seg(gb,null,p2[0],p2[1],q2[0],q2[1],FL-0.3,DECK0,0.12,C_('#d9d3c6'));
      for(let a=0;a<1;a+=0.125){const x0=lerp(p2[0],q2[0],a+0.02),z0=lerp(p2[1],q2[1],a+0.02),x1=lerp(p2[0],q2[0],a+0.105),z1=lerp(p2[1],q2[1],a+0.105);seg(gb,null,x0+s*F.vx*0.08,z0+s*F.vz*0.08,x1+s*F.vx*0.08,z1+s*F.vz*0.08,FL+2.6,FL+4.6,0.05,C_('#7f97a6'));}}
    for(const z of [ZN,ZS]){const p=WZ(z,BW),q=WZ(z,BE);seg(gb,null,p[0],p[1],q[0],q[1],FL+3.6,DECK1,0.4,C_('#d9d3c6'));seg(gb,null,p[0],p[1],q[0],q[1],FL+3.45,FL+3.6,0.5,ODB);}
    const ceil=[WZ(ZS,BW),WZ(ZS,BE),WZ(ZN,BE),WZ(ZN,BW)];const ch=[];for(const sd of [-1,1]){ch.push(fRect(aT_AC,aT_AC+10,sd>0?6.6:-9.8,sd>0?9.8:-6.6));ch.push(fRect(aT_BD-10,aTE+0.3,sd>0?6.6:-11.1,sd>0?11.1:-6.6));}
    polySlab(inn,ceil,ch,CCEIL+0.1,0.1,null,CEIL,null,null);
    for(const h of ch)for(let i=0;i<4;i++){const p=h[i],q=h[(i+1)%4];seg(inn,null,p[0],p[1],q[0],q[1],CCEIL,DECK0,0.12,WALL);}
    // light strips (skip the openings)
    for(let a=-24;a<46;a+=4.5)for(let b=-15.5;b<16;b+=5.2){const c=F.W(a,b);if(!inPolyF(c[0],c[1],flat(ceil)))continue;if(ch.some(h=>inPolyF(c[0],c[1],flat(h))))continue;lg.obox(c[0],c[1],F.ux,F.uz,1.4,0.16,CCEIL-0.04,CCEIL+0.05,C_('#ffffff'),2);}}
  // gate lines (E–W, as the station's own ends): partitions with the gate groups, machines on the free side
  const xAt=(z,b)=>WZ(z,b)[0];
  const gateLine=(z,gates,skip,face)=>{const xw=xAt(z,BW),xe=xAt(z,BE);const cut=[...gates.map(g=>[g[0]-g[1]/2-0.3,g[0]+g[1]/2+0.3]),...skip].sort((p,q)=>p[0]-q[0]);let x=xw;
    for(const [c0,c1] of cut){if(c0>x)partition(inn,colls,W0,x,z,c0,z,FL);x=Math.max(x,c1);}if(x<xe)partition(inn,colls,W0,x,z,xe,z,FL);
    for(const [cx,len] of gates){gatesGB(inn,colls,cx,z,1,0,len,FL);}};
  const wedgeX=(z,sd)=>{const x0=xAt(z,sd*(BS0-0.1)),x1=xAt(z,sd*(BS1+0.1));return [Math.min(x0,x1),Math.max(x0,x1)];};
  {const xg=xAt(ZGT,0);gateLine(ZGT,[[xg,9]],[wedgeX(ZGT,-1),wedgeX(ZGT,1)]);
    board(sg,xg,FL+3.15,ZGT,-1,0,4.2,1.05,'xOD','xSO');inn.obox(xg,ZGT,1,0,5.2,0.12,FL+2.55,FL+2.75,C_('#2f3940'));}
  {const xg=xAt(ZGN,-2.5);gateLine(ZGN,[[xg,11]],[]);board(sg,xg,FL+3.1,ZGN,-1,0,4.4,1.1,'gSO','exN');inn.obox(xg,ZGN,1,0,6.0,0.1,FL+2.45,FL+2.62,SON_);
    machinesGB(inn,colls,xAt(ZGN-1.0,8),ZGN-1.0,1,0,5,FL);machinesGB(inn,colls,xAt(ZGN-1.0,-12.5),ZGN-1.0,1,0,3,FL);}
  {const xg=xAt(ZGS,-3.0);gateLine(ZGS,[[xg,11]],[]);board(sg,xg,FL+3.1,ZGS,1,0,4.4,1.1,'gOD','exS');inn.obox(xg,ZGS,1,0,6.0,0.1,FL+2.45,FL+2.62,ODB);
    machinesGB(inn,colls,xAt(ZGS+0.9,-14),ZGS+0.9,1,0,4,FL);machinesGB(inn,colls,xAt(ZGS+0.9,9.5),ZGS+0.9,1,0,3,FL);}
  // rooms: toilets, offices, kiosks
  {const room=(r,col,band,key)=>{const [a0,a1,b0,b1]=r;const c=F.W((a0+a1)/2,(b0+b1)/2);inn.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2,(b1-b0)/2,FL,FL+3.0,C_('#f3efe6'));inn.obox(c[0],c[1],F.ux,F.uz,(a1-a0)/2+0.05,(b1-b0)/2+0.05,FL+3.0,FL+3.4,C_(band));colls.push(addOBB(c[0],c[1],(a1-a0)/2,(b1-b0)/2,ANG,FL,FL+3.4));
      if(key){const bb=b0>-1&&b1<1?b1:(b0<0?b1:b0);const s=F.W((a0+a1)/2,bb+(b0<0?0.06:-0.06));board(sg,s[0],FL+3.2,s[1],b0<0?F.ux:-F.ux,b0<0?F.uz:-F.uz,Math.min(a1-a0-0.6,3.2),0.6,key);}};
    room(ROOMS.odToilet,'#5a6670',null,'wc');room(ROOMS.odShop,'#2a7ab8',null,'shop');room(ROOMS.odOffice,ODC,null,null);room(ROOMS.soOffice,SOC,null,null);room(ROOMS.soShop,'#d0021b',null,'ist');}
  // signs over the stair feet
  for(const sd of [-1,1]){const k=sd>0?'hOD12':'hOD34';const p=F.W(aF_AC+1.2,sd*BC),q=F.W(aF_BD-1.2,sd*BC);board(sg,p[0],FL+3.3,p[1],-F.vx,-F.vz,3.0,0.75,k);board(sg,q[0],FL+3.3,q[1],F.vx,F.vz,3.0,0.75,k);
    inn.obox(p[0],p[1],F.ux,F.uz,0.03,0.03,FL+3.7,CCEIL,C_('#7a858e'));inn.obox(q[0],q[1],F.ux,F.uz,0.03,0.03,FL+3.7,CCEIL,C_('#7a858e'));}
  // exterior signs on the fascias, the station-building sign on プロス
  {const n=WZ(ZN-0.25,-1);board(sg,n[0],FL+4.7,n[1],-1,0,6.4,1.6,'eSO','eSO');const n2=WZ(ZN-0.25,12);board(sg,n2[0],FL+4.7,n2[1],-1,0,4.4,1.1,'gOD','gOD');
    const s=WZ(ZS+0.25,-2);board(sg,s[0],FL+4.7,s[1],1,0,6.4,1.6,'eOD','eOD');const s2=WZ(ZS+0.25,-14);board(sg,s2[0],FL+4.7,s2[1],1,0,4.4,1.1,'gSO','gSO');
    board(sg,-2334,FL+9.5,-14555.4,-1,0,7.2,1.8,'pros','pros');}
  /* =============== B1: 相鉄 island platform =============== */
  {const s0=sS-108,s1=sS+108;const hb=9.8;const a0=-114,a1=114;
    roomShell(inn,G,a0,a1,-hb,hb,PYS-0.3,CEILS,C_('#e4e6ea'),C_('#6f6a63'),null);{const f=addPoly(flat(gRect(a0,a1,-hb,hb)),PYS-1.0,PYS-0.3);f.tag=0;}
    const holes=[...WELL.map(w=>[Math.min(w.top,w.top+w.da*7.8),Math.max(w.top,w.top+w.da*7.8),w.b0,w.b1]),[(aW+aE)/2-1.1,(aW+aE)/2+1.1,-1.1,1.1]];
    slabWithHoles(inn,colls,G,a0,a1,-hb,hb,CEILS+0.3,0.3,holes,CEIL,CEIL);
    // wall colour bands (1番線 orange on the south wall, 2番線 light blue on the north wall), name boards on the walls
    for(const [b,c] of [[-hb+0.02,'#f08300'],[hb-0.02,'#58b7e8']]){const p=G.W(0,b);inn.obox(p[0],p[1],G.ux,G.uz,a1,0.03,PYS+1.6,PYS+2.3,C_(c));}
    for(let a=-90;a<=90;a+=30){for(const b of [-hb+0.05,hb-0.05]){const p=G.W(a,b);const r=b<0?[G.ux,G.uz]:[-G.ux,-G.uz];board(sg,p[0],PYS+3.1,p[1],r[0],r[1],2.8,0.7,b<0?'soN':'soS',b<0?'soN':'soS');}}
    for(const sd of [-1,1])platPiece(inn,colls,sot,s0,s1,SOFF+sd*(7.2-1.575),SOFF,TOPS,true);
    const rp=[];for(const [s,o] of [[s0,SOFF-5.625],[s1,SOFF-5.625],[s1,SOFF+5.625],[s0,SOFF+5.625]]){const p=sot.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,TOPS,sot,true,false);
    // columns, benches, hanging name boards and 番線 signs
    const busy=a=>WELL.some(w=>a>Math.min(w.top,w.top+w.da*RUN_SE)-1.5&&a<Math.max(w.top,w.top+w.da*RUN_SE)+1.5)||Math.abs(a-(aW+aE)/2)<2.2;
    for(let a=-100;a<=100;a+=10)for(const b of [-3.4,3.4]){const p=G.W(a,b);inn.obox(p[0],p[1],G.ux,G.uz,0.35,0.35,TOPS,CEILS,C_('#dfe3e8'));colls.push(addOBB(p[0],p[1],0.35,0.35,G.ang,TOPS,CEILS));}
    for(let a=-95;a<=95;a+=20){if(busy(a))continue;const p=G.W(a,0);inn.obox(p[0],p[1],G.ux,G.uz,1.0,0.25,TOPS+0.42,TOPS+0.48,C_('#2c4a8a'));inn.obox(p[0],p[1],G.ux,G.uz,0.06,0.2,TOPS,TOPS+0.42,C_('#8a949c'));colls.push(addOBB(p[0],p[1],1.0,0.28,G.ang,TOPS,TOPS+0.5));}
    for(const a of [-70,-35,40,75]){if(busy(a))continue;const p=G.W(a,0);board(sg,p[0],TOPS+2.75,p[1],G.ux,G.uz,2.4,0.6,'soN','soS');}
    for(const a of [-55,58]){const p=G.W(a,0);for(const [b,k] of [[-2.2,'so1'],[2.2,'so2']]){const q=G.W(a,b);board(sg,q[0],TOPS+2.95,q[1],G.vx,G.vz,2.0,0.5,k);}}
    // stairs + escalators up to the concourse, the shafts around them, railings at the top
    flightR(inn,glass,colls,G,aW,0,1,FL,TOPS,2.6);escalatorVis(inn,G,aW,-2.0,1,FL,TOPS,1.0);escalatorVis(inn,G,aW,2.0,1,FL,TOPS,1.0);
    flightR(inn,glass,colls,G,aE,-0.4,-1,FL,TOPS,2.6);escalatorVis(inn,G,aE,1.75,-1,FL,TOPS,1.0);
    for(const w of WELL){const e0=Math.min(w.top,w.top+w.da*7.8),e1=Math.max(w.top,w.top+w.da*7.8);roomShell(inn,G,e0,e1,w.b0,w.b1,CEILS,FL-0.4,WALL,null,null);
      rectRails(inn,glass,colls,G,w.a0,w.a1,w.b0,w.b1,FL,w.da>0?3:1);   // open at the stair top
      const q=G.W(w.top-w.da*1.4,(w.b0+w.b1)/2);board(sg,q[0],FL+3.25,q[1],G.vx*w.da,G.vz*w.da,3.0,0.75,'hSO');}
    // lift from B1 to the concourse
    {const am=(aW+aE)/2;const c=G.W(am,0);glass.obox(c[0],c[1],G.ux,G.uz,1.0,1.0,TOPS,FL+2.6,C_('#a9c8d8'));gb.obox(c[0],c[1],G.ux,G.uz,1.1,1.1,FL+2.6,FL+2.9,C_('#7d868d'));
      for(const [u,v] of [[-1,-1],[1,-1],[1,1],[-1,1]]){const q=G.W(am+u,v);inn.obox(q[0],q[1],G.ux,G.uz,0.07,0.07,TOPS,FL+2.6,C_('#7d868d'));}colls.push(addOBB(c[0],c[1],1.05,1.05,G.ang,TOPS,FL+2.9));}
    // tunnels on beyond the hall
    for(const sd of [-1,1]){const c=G.W(sd*(a1+60),0);inn.obox(c[0],c[1],G.ux,G.uz,60,hb,PYS-0.3,CEILS,DARK,2|4|8);}
    for(let a=a0+4;a<a1;a+=6)for(const b of [-5.8,0,5.8]){const c=G.W(a,b);if(holes.some(h=>a>h[0]-1.6&&a<h[1]+1.6&&b>h[2]-0.3&&b<h[3]+0.3))continue;lg.obox(c[0],c[1],G.ux,G.uz,1.4,0.15,CEILS-0.05,CEILS+0.02,C_('#ffffff'),2);}
    // zones: the wells first (they win where volumes overlap), then the hall, then the concourse strips
    for(const w of WELL){const lo=Math.min(w.top-w.da*1.0,w.top+w.da*(RUN_S+1.5)),hi=Math.max(w.top-w.da*1.0,w.top+w.da*(RUN_S+1.5));const up0=Math.min(w.top-w.da*1.0,w.top+w.da*5.5),up1=Math.max(w.top-w.da*1.0,w.top+w.da*5.5);
      regZone(G,up0,up1,w.b0-0.6,w.b1+0.6,FL-4.5,FL+2.5,NAME,sot,FL,null,true);regZone(G,lo,hi,w.b0-0.6,w.b1+0.6,PYS-1.3,FL-3.0,NAME,sot,FL,null,true);}
    regZone(G,a0,a1,-hb,hb,PYS-1.3,CEILS+0.6,NAME,sot,FL,null,true);}
  {const N=6;for(let i=0;i<N;i++){const b0=lerp(BW,BE,i/N),b1=lerp(BW,BE,(i+1)/N);const aS=Math.max(aAtZ(ZFS-0.25,b0),aAtZ(ZFS-0.25,b1)),aN=Math.min(aAtZ(ZFN+0.25,b0),aAtZ(ZFN+0.25,b1));
      regZone(F,aS,aN,b0,b1,FL-1.0,FL+5.5,NAME,odn,FL,null,true);}}
  /* --- meshes: outdoor, indoor (self-lit), glass, lights, signs --- */
  if(!gb.empty){const m=new THREE.Mesh(gb.geo(),MAT.top);m.castShadow=true;m.receiveShadow=true;scene.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),UGMAT);m.receiveShadow=true;scene.add(m);}
  if(!glass.empty){const m=new THREE.Mesh(glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
  if(!lg.empty)scene.add(new THREE.Mesh(lg.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));
  if(!sg.empty)scene.add(new THREE.Mesh(sg.geo(),new THREE.MeshBasicMaterial({map:atlas})));
  console.log('LOG 大和: built, top',TOP.toFixed(2),'B1 top',TOPS.toFixed(2),'wells a',aW.toFixed(1),aE.toFixed(1));
}
ST_CUSTOM[NAME]={lines:new Set(['odn','sot']),build};
})();
