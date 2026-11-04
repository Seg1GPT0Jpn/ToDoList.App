/* ================= 戸塚駅 (JR東日本・横浜市営地下鉄ブルーライン) =================
   From Wikipedia (駅構造), the Yokohama subway floor map (構内図) and OSM:
   - JR: ground station, 2 island platforms / 4 tracks, directional pairing (方向別) so the
     東海道線 and 横須賀線 share each island: 1 横須賀線上り | 2 東海道線上り ‖ 3 東海道線下り | 4 横須賀線下り.
     The 東海道貨物線 runs past the west side. Two gates: the 橋上改札 (bridge-level station building with the
     east–west free passage and the pedestrian decks to トツカーナ (west) and the 東口 bus terminal / ラピス (east)),
     and the 地下改札 on the B1 free passage under the tracks.
   - ブルーライン (B06): B1 地下自由通路 (east–west, under the JR tracks, JR 地下改札 on its south side, exits 1–6 and
     the west connection), B2 gate concourse, B3 island platform under the 東口 bus terminal / ラピス戸塚2.
   Frames: FJ on the JR line at the station (+a north along the tracks, +b east = lane offset);
           FB on the subway at the stop (+a east, +b south). */
(()=>{
const NAME='戸塚';
const SJ=17500,SB=7466;
ST_S['jr|戸塚']=SJ;ST_S['blu|戸塚']=SB;
LANE_ADJ.push({key:'jr',s0:17330,s1:17665,lo:-1.35,hi:3.1,blend:150},{key:'blu',s0:7396,s1:7536,lo:-5.8,hi:5.8,blend:150});
PROF_ADJ.push({key:'blu',s0:7392,s1:7540,y:-5.5,blend:400});
BLD_CLEAR.push([4245.5,-6852.2,0,3,3],[4276.2,-6884.6,0,2,2],[4198.9,-6904.5,0,2,2]);   // PLATEAU: the old station-building block over the tracks, a stair hood (rebuilt by hand)
PLAT_CLEAR.push([4253,-6860,0,16,16]);                               // OSM JR platforms (rebuilt along the real tracks)
// OSM tracks that are not game lines (横須賀線 1・4番線), world coordinates
const T1=[[4328.3,-6538.9],[4315.8,-6586.8],[4301.6,-6637.9],[4287.3,-6683.8],[4269.9,-6742.0],[4248.6,-6814.5],[4242.1,-6838.6],[4234.2,-6868.3],[4220.0,-6937.2],[4206.4,-7017.0]];
const T4=[[4325.7,-6598.6],[4305.0,-6708.2],[4291.6,-6772.4],[4283.7,-6808.9],[4273.5,-6846.9],[4257.3,-6906.8],[4233.6,-6983.2],[4223.9,-7022.0],[4219.3,-7048.1]];
/* ---------- small kit ---------- */
const FONT='"Hiragino Sans","Noto Sans JP","M PLUS Rounded 1c",sans-serif';
const TEXC=new Map(),MATC=new Map();
function canvasTex(key,w,h,draw){let t=TEXC.get(key);if(t)return t;const cv=document.createElement('canvas');cv.width=w;cv.height=h;draw(cv.getContext('2d'),w,h);t=new THREE.CanvasTexture(cv);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=4;TEXC.set(key,t);return t;}
function texMat(t){let m=MATC.get(t);if(!m){m=new THREE.MeshBasicMaterial({map:t});MATC.set(t,m);}return m;}
const B=(gb,F,a0,a1,b0,b1,y0,y1,col,faces=63)=>{const c=F.W((a0+a1)/2,(b0+b1)/2);gb.obox(c[0],c[1],F.ux,F.uz,Math.abs(a1-a0)/2,Math.abs(b1-b0)/2,y0,y1,col,faces);};
const K=(colls,F,a0,a1,b0,b1,y0,y1)=>{const c=F.W((a0+a1)/2,(b0+b1)/2);const o=addOBB(c[0],c[1],Math.max(0.05,Math.abs(a1-a0)/2),Math.max(0.05,Math.abs(b1-b0)/2),F.ang,y0,y1);colls.push(o);return o;};
const BK=(gb,colls,F,a0,a1,b0,b1,y0,y1,col,faces)=>{B(gb,F,a0,a1,b0,b1,y0,y1,col,faces);K(colls,F,a0,a1,b0,b1,y0,y1);};
function badge(x,cx,cy,s,code,num,col){x.fillStyle='#ffffff';x.strokeStyle=col;x.lineWidth=s*0.11;const r=s*0.16;x.beginPath();x.roundRect?x.roundRect(cx-s/2,cy-s/2,s,s,r):x.rect(cx-s/2,cy-s/2,s,s);x.fill();x.stroke();
  x.fillStyle='#1b1f24';x.textAlign='center';x.textBaseline='middle';x.font=`800 ${s*0.3}px ${FONT}`;x.fillText(code,cx,cy-s*0.2);x.font=`800 ${s*0.42}px ${FONT}`;x.fillText(num,cx,cy+s*0.16);}
/* operator-style station name board: st={name,kana,roma,code,num,col,band}, L/R = neighbour shown on the left / right {name,num} */
const nameDraw=(st,L,R)=>(x,w,h)=>{
  x.fillStyle='#ffffff';x.fillRect(0,0,w,h);x.fillStyle=st.band;x.fillRect(0,h-62,w,62);if(st.top){x.fillStyle=st.top;x.fillRect(0,0,w,10);}
  badge(x,92,92,118,st.code,st.num,st.col);
  x.fillStyle='#1b1f24';x.textAlign='center';x.textBaseline='middle';x.font=`800 104px ${FONT}`;x.fillText(st.name,w/2+30,78);
  x.font=`600 30px ${FONT}`;x.fillStyle='#3d4852';x.fillText(st.kana+'　'+st.roma,w/2+30,154);
  x.font=`700 30px ${FONT}`;x.fillStyle='#ffffff';x.textBaseline='middle';
  if(L){x.textAlign='left';x.fillText('◀ '+L.name+'  '+(L.num||''),24,h-31);}if(R){x.textAlign='right';x.fillText((R.num||'')+'  '+R.name+' ▶',w-24,h-31);}};
const textDraw=(t1,t2,bg,fg,acc)=>(x,w,h)=>{x.fillStyle=bg;x.fillRect(0,0,w,h);if(acc){x.fillStyle=acc;x.fillRect(0,0,14,h);}x.fillStyle=fg;x.textAlign='center';x.textBaseline='middle';
  x.font=`800 ${t2?50:58}px ${FONT}`;x.fillText(t1,w/2+6,t2?44:64,w-30);if(t2){x.font=`500 24px ${FONT}`;x.globalAlpha=0.85;x.fillText(t2,w/2+6,96,w-30);x.globalAlpha=1;}};
/* every sign of the station is drawn into one 2048² canvas (4×16 cells of 512×128) and merged into one mesh */
const ATL={cv:null,ctx:null,used:new Set(),cells:new Map(),gb:null};
function atlasCell(key,wc,hc,draw){let r=ATL.cells.get(key);if(r)return r;if(!ATL.cv){ATL.cv=document.createElement('canvas');ATL.cv.width=2048;ATL.cv.height=2048;ATL.ctx=ATL.cv.getContext('2d');ATL.gb=new GB();}
  for(let row=0;row<=16-hc;row++)for(let col=0;col<=4-wc;col++){let ok=true;for(let i=0;i<wc&&ok;i++)for(let j=0;j<hc&&ok;j++)if(ATL.used.has((row+j)*4+col+i))ok=false;if(!ok)continue;
    for(let i=0;i<wc;i++)for(let j=0;j<hc;j++)ATL.used.add((row+j)*4+col+i);const x=ATL.ctx,W=wc*512,H=hc*128;x.save();x.translate(col*512,row*128);x.beginPath();x.rect(0,0,W,H);x.clip();draw(x,W,H);x.restore();
    r=[(col*512+2)/2048,1-(row*128+H-2)/2048,(col*512+W-2)/2048,1-(row*128+2)/2048];ATL.cells.set(key,r);return r;}
  return null;}
function atlasQuad(x,y,z,nx,nz,w,h,uv){const rx=nz,rz=-nx,hw=w/2,hh=h/2;const BL=[x-rx*hw,y-hh,z-rz*hw],BR=[x+rx*hw,y-hh,z+rz*hw],TR=[x+rx*hw,y+hh,z+rz*hw],TL=[x-rx*hw,y+hh,z-rz*hw];const wc=C_('#ffffff');
  ATL.gb.tri(BL,BR,TR,nx,0,nz,wc,[uv[0],uv[1]],[uv[2],uv[1]],[uv[2],uv[3]]);ATL.gb.tri(BL,TR,TL,nx,0,nz,wc,[uv[0],uv[1]],[uv[2],uv[3]],[uv[0],uv[3]]);}
function flushAtlas(){if(!ATL.gb||ATL.gb.empty)return;const t=new THREE.CanvasTexture(ATL.cv);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=4;scene.add(new THREE.Mesh(ATL.gb.geo(),new THREE.MeshBasicMaterial({map:t})));}
/* one face of a sign: an atlas cell while there is room, else its own small texture */
function signFace(key,wc,hc,draw,x,y,z,nx,nz,w,h){const uv=atlasCell(key,wc,hc,draw);if(uv){atlasQuad(x,y,z,nx,nz,w,h,uv);return;}
  const t=canvasTex(key,wc*512,hc*128,draw);const m=new THREE.Mesh(new THREE.PlaneGeometry(w,h),texMat(t));m.position.set(x,y,z);m.rotation.y=Math.atan2(nx,nz);scene.add(m);}
/* a board seen from both sides with the right text on each: centre (x,y,z), long axis t=(tx,tz); nbT = neighbour in +t */
function nameBoard(fr,x,y,z,tx,tz,w,h,sideSpec){const l=Math.hypot(tx,tz);tx/=l;tz/=l;
  for(const sd of [1,-1]){const sp=sideSpec(sd);if(!sp)continue;const nx=-tz*sd,nz=tx*sd;const rx=nz,rz=-nx;const rightIsT=rx*tx+rz*tz>0;
    const L=rightIsT?sp.nbB:sp.nbT,R=rightIsT?sp.nbT:sp.nbB;const st=sp.st;
    signFace('nb|'+st.name+st.code+st.num+(L&&L.name)+(R&&R.name),2,2,nameDraw(st,L,R),x+nx*0.035,y,z+nz*0.035,nx,nz,w,h);}
  fr.obox(x,z,tx,tz,w/2+0.06,0.03,y-h/2-0.06,y+h/2+0.06,C_('#59626b'));}
/* flat sign readable from both sides (normal n) */
function sign(x,y,z,nx,nz,w,h,t1,t2,bg='#27323b',fg='#ffffff',acc=null,both=true){const l=Math.hypot(nx,nz);nx/=l;nz/=l;
  for(const sd of both?[1,-1]:[1])signFace('tx|'+t1+t2+bg+fg+acc,1,1,textDraw(t1,t2,bg,fg,acc),x+nx*sd*0.03,y,z+nz*sd*0.03,nx*sd,nz*sd,w,h);}
/* offset of a world polyline from line l at s (along the normal); null if it does not cross */
function offOf(l,poly,s){const p=l.path.at(s);const nx=-p.tz,nz=p.tx;let best=null;
  for(let i=0;i<poly.length-1;i++){const A=poly[i],Bq=poly[i+1];const dx=Bq[0]-A[0],dz=Bq[1]-A[1];const det=-nx*dz+dx*nz;if(Math.abs(det)<1e-9)continue;
    const ex=A[0]-p.x,ez=A[1]-p.z;const t=(-ex*dz+dx*ez)/det,u=(nx*ez-nz*ex)/det;if(u<-0.01||u>1.01)continue;if(best===null||Math.abs(t)<Math.abs(best))best=t;}return best;}
/* platform deck between two offset functions, in strips; holes [s0,s1,b0,b1]; both long edges get the white line + tactile strip */
function deckAlong(gb,colls,l,s0,s1,fA,fB,holes=[],opt={}){const step=opt.step||5;const deck=C_(opt.deck||'#d6d0c2'),edge=C_('#bdb6a8'),yel=C_('#f2d33c'),wht=C_('#f4f4f2');
  const P=(s,o,y)=>{const q=l.path.at(s,o);return [q.x,y,q.z];};
  const cuts=[];for(let s=s0;s<s1-0.01;s+=step)cuts.push(s);for(const h of holes)for(const v of [h[0],h[1]])if(v>s0+0.01&&v<s1-0.01)cuts.push(v);cuts.push(s1);cuts.sort((x,y)=>x-y);
  for(let ci=0;ci<cuts.length-1;ci++){const sa=cuts[ci],sb=cuts[ci+1];if(sb-sa<0.01)continue;const sm=(sa+sb)/2;let lo=fA(sm),hi=fB(sm);if(lo>hi){const t=lo;lo=hi;hi=t;}if(hi-lo<0.6)continue;
    const top=(opt.top!==undefined?opt.top:l.path.py(sm)+1.1);const y0=top-1.25;
    let ivs=[[lo,hi]];for(const h of holes){if(sb<=h[0]+0.001||sa>=h[1]-0.001)continue;const nv=[];for(const [p,q] of ivs){if(h[3]<=p||h[2]>=q){nv.push([p,q]);continue;}if(h[2]>p)nv.push([p,h[2]]);if(h[3]<q)nv.push([h[3],q]);}ivs=nv;}
    for(const [p,q] of ivs){if(q-p<0.05)continue;const A=P(sa,p,top),Bp=P(sb,p,top),Cp=P(sb,q,top),D=P(sa,q,top);gb.quad(A,Bp,Cp,D,0,1,0,deck);
      for(const [E,G,o] of [[A,Bp,p],[Cp,D,q]]){const dx=G[0]-E[0],dz=G[2]-E[2],ln=Math.hypot(dx,dz)||1;const n=o===p?-1:1;const pp=l.path.at(sm,o),nx=-pp.tz*n,nz=pp.tx*n;gb.quad([E[0],y0,E[2]],[G[0],y0,G[2]],[G[0],top,G[2]],[E[0],top,E[2]],nx,0,nz,edge);}
      if(sa<=s0+0.01)gb.quad([A[0],y0,A[2]],[D[0],y0,D[2]],D,A,-l.path.at(sm).tx,0,-l.path.at(sm).tz,edge);
      if(sb>=s1-0.01)gb.quad([Bp[0],y0,Bp[2]],[Cp[0],y0,Cp[2]],Cp,Bp,l.path.at(sm).tx,0,l.path.at(sm).tz,edge);
      const b=addPoly([A[0],A[2],Bp[0],Bp[2],Cp[0],Cp[2],D[0],D[2]],top-1.2,top);b.tag=0;b.plat=true;colls.push(b);}
    // edge markings only along the full-width long edges (track sides)
    for(const [o,dir] of [[lo,1],[hi,-1]]){for(const [o0,o1,c] of [[o+dir*0.08,o+dir*0.22,wht],[o+dir*0.85,o+dir*1.15,yel]]){const A=P(sa,o0,top+0.012),Bp=P(sb,o0,top+0.012),Cp=P(sb,o1,top+0.012),D=P(sa,o1,top+0.012);gb.quad(A,Bp,Cp,D,0,1,0,c);}}}}
/* platform roof between two offset functions: slab + underside + centre columns */
function canopyAlong(gb,inn,colls,l,s0,s1,fA,fB,h=4.2,skip=[],skipCol=[]){for(let s=s0;s<s1-0.01;s+=5){const sb=Math.min(s1,s+5),sm=(s+sb)/2;if(skip.some(k=>sm>k[0]&&sm<k[1]))continue;const a=fA(sm),b=fB(sm);const c=l.path.at(sm,(a+b)/2);const top=l.path.py(sm)+1.1;const hv=Math.abs(b-a)/2+0.45;
    gb.obox(c.x,c.z,c.tx,c.tz,(sb-s)/2+0.02,hv,top+h,top+h+0.22,C_('#c4c9cd'),1|4|8|16|32);inn.obox(c.x,c.z,c.tx,c.tz,(sb-s)/2+0.02,hv-0.05,top+h-0.12,top+h,C_('#d9dcdc'),2);}
  for(let s=s0+6;s<s1-3;s+=15){if(skip.concat(skipCol).some(k=>s>k[0]-3&&s<k[1]+3))continue;const a=fA(s),b=fB(s);const c=l.path.at(s,(a+b)/2);const top=l.path.py(s)+1.1;
    gb.obox(c.x,c.z,c.tx,c.tz,0.18,0.18,top,top+h,C_('#7f8a93'));colls.push(addOBB(c.x,c.z,0.18,0.18,Math.atan2(c.tz,c.tx),top,top+h));
    gb.obox(c.x,c.z,c.tx,c.tz,0.1,Math.abs(b-a)/2+0.3,top+h-0.55,top+h-0.12,C_('#7f8a93'));}}
/* rails + ballast along a world polyline at a given height (scenery tracks) */
function railsAlong(gb,poly,yAt){const bal=C_('#8a8177'),sl=C_('#5f5650'),rc=C_('#cfd2d6');
  for(let i=0;i<poly.length-1;i++){const [ax,az]=poly[i],[bx,bz]=poly[i+1];const dx=bx-ax,dz=bz-az,L0=Math.hypot(dx,dz);const n=Math.max(1,Math.ceil(L0/8));const nx=-dz/L0,nz=dx/L0;
    for(let k=0;k<n;k++){const x0=ax+dx*k/n,z0=az+dz*k/n,x1=ax+dx*(k+1)/n,z1=az+dz*(k+1)/n;const y0=yAt(x0,z0),y1=yAt(x1,z1);
      const q=(o0,o1,dy,c)=>gb.quad([x0+nx*o0,y0+dy,z0+nz*o0],[x1+nx*o0,y1+dy,z1+nz*o0],[x1+nx*o1,y1+dy,z1+nz*o1],[x0+nx*o1,y0+dy,z0+nz*o1],0,1,0,c);
      q(-1.7,1.7,0.0,bal);q(-1.25,1.25,0.06,sl);q(-0.62,-0.5,0.2,rc);q(0.5,0.62,0.2,rc);}}}
const LG={gb:null};
function lights(F,a0,a1,b0,b1,y,da=6,db=6){const lg=LG.gb||(LG.gb=new GB());for(let a=a0+da/2;a<a1;a+=da)for(let b=b0+db/2;b<b1;b+=db){const c=F.W(a,b);lg.obox(c[0],c[1],F.ux,F.uz,1.4,0.16,y-0.06,y-0.01,C_('#ffffff'),2);}}
function flushLights(){if(LG.gb&&!LG.gb.empty)scene.add(new THREE.Mesh(LG.gb.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));}
/* inner wall faces of a rectangle with openings (same gap convention as rectWalls: sides 0:b0 1:b1 2:a0 3:a1) */
function wallsV(g,F,a0,a1,b0,b1,y0,y1,col,gaps=[]){const seg=(side,p0,p1)=>{const gg=gaps.filter(q=>q[0]===side).sort((x,y)=>x[1]-y[1]);let a=p0;const o=[];for(const q of gg){if(q[1]>a)o.push([a,q[1]]);a=Math.max(a,q[2]);}if(a<p1)o.push([a,p1]);return o;};
  for(const [s0,s1] of seg(0,a0,a1))B(g,F,s0,s1,b0,b0+0.02,y0,y1,col,8);for(const [s0,s1] of seg(1,a0,a1))B(g,F,s0,s1,b1-0.02,b1,y0,y1,col,4);
  for(const [s0,s1] of seg(2,b0,b1))B(g,F,a0,a0+0.02,s0,s1,y0,y1,col,32);for(const [s0,s1] of seg(3,b0,b1))B(g,F,a1-0.02,a1,s0,s1,y0,y1,col,16);}
/* deck slab between world points p→q (width w) at height y: slab, underside, parapets (sides given), pillars */
function deck(gb,colls,p,q,w,y,par=[1,1],pillars=true,caps=[0,0]){const dx=q[0]-p[0],dz=q[1]-p[1],L0=Math.hypot(dx,dz);const ux=dx/L0,uz=dz/L0;const F=stFrame(p[0],p[1],Math.atan2(uz,ux));
  BK(gb,colls,F,0,L0,-w/2,w/2,y-0.6,y,C_('#cfc6b6'));
  for(const [sd,on] of [[-1,par[0]],[1,par[1]]]){if(!on)continue;const gp=Array.isArray(on)?on.slice().sort((a,b)=>a[0]-b[0]):[];let u=0;const segs=[];for(const g of gp){if(g[0]>u)segs.push([u,g[0]]);u=Math.max(u,g[1]);}if(u<L0)segs.push([u,L0]);
    const b0=sd*(w/2-0.12);for(const [u0,u1] of segs){if(u1-u0<0.1)continue;B(gb,F,u0,u1,b0-0.12,b0+0.12,y,y+1.15,C_('#c0c6cb'));K(colls,F,u0,u1,b0-0.12,b0+0.12,y,y+1.15);}}
  for(const [u,on] of [[0,caps[0]],[L0,caps[1]]]){if(!on)continue;B(gb,F,u-0.12,u+0.12,-w/2,w/2,y,y+1.15,C_('#c0c6cb'));K(colls,F,u-0.12,u+0.12,-w/2,w/2,y,y+1.15);}
  if(pillars)for(let a=4;a<L0-2;a+=11){const c=F.W(a,0);const g=demH(c[0],c[1]);B(gb,F,a-0.45,a+0.45,-0.45,0.45,g-0.5,y-0.6,C_('#c9c5bb'));K(colls,F,a-0.45,a+0.45,-0.45,0.45,g-0.5,y-0.6);}
  return F;}
/* stair from a deck edge point down to the street, along world direction d, with side walls */
function deckStair(gb,colls,x,z,dx,dz,yTop,w=3){const l=Math.hypot(dx,dz);dx/=l;dz/=l;let g=heightAt(x+dx*12,z+dz*12);for(let k=0;k<3;k++){const run=Math.ceil((yTop-g)/0.28)*0.42;g=heightAt(x+dx*run,z+dz*run);}
  const F=stFrame(x,z,Math.atan2(dz,dx));const run=stairDir(gb,colls,F,0,0,1,0,yTop,g+0.05,w,true);
  for(const sd of [-1,1]){K(colls,F,0,run,sd*(w/2+0.1)-0.08,sd*(w/2+0.1)+0.08,g,yTop+1.1);B(gb,F,0,run,sd*(w/2+0.1)-0.08,sd*(w/2+0.1)+0.08,yTop-0.6,yTop+1.05,C_('#c0c6cb'));}
  return run;}
/* street entrance of an underground exit: parapets, roof, sign (stairs go down along (dx,dz) from (x,z)) */
function exitHood(out,x,z,dx,dz,gy,run,label,sub){const l=Math.hypot(dx,dz);dx/=l;dz/=l;const L=Math.min(run,7);const c=dx,s=dz;
  for(const sd of [-1,1]){const xx=x+c*L/2-s*sd*1.7,zz=z+s*L/2+c*sd*1.7;out.obox(xx,zz,c,s,L/2+0.2,0.15,gy-0.4,gy+1.1,C_('#c9ced3'));}
  {const xx=x+c*L*0.55,zz=z+s*L*0.55;out.obox(xx,zz,c,s,L*0.55+0.4,2.0,gy+2.75,gy+2.95,C_('#dfe3e6'));out.obox(xx,zz,c,s,L*0.55+0.4,2.03,gy+2.6,gy+2.75,C_('#0072bc'));
    for(const sd of [-1,1])for(const f2 of [0.05,1.05]){out.obox(x+c*L*f2-s*sd*1.75,z+s*L*f2+c*sd*1.75,c,s,0.06,0.06,gy,gy+2.75,C_('#8e979e'));}}
  sign(x-c*0.45,gy+3.5,z-s*0.45,c,s,3.0,0.75,label,sub,'#ffffff','#1b1f24','#0072bc');}

function build(){
  const jr=LINES.jr,blu=LINES.blu;if(!jr||!blu)return;
  const gb=new GB(),colls=[],inn=new GB(),out=new GB(),fr=new GB();const glass=new GB();inn.glass=glass;
  const TILE=C_('#d9d4c9'),WALL=C_('#eeebe4'),CEIL=C_('#f2f1ec'),PAIDC=C_('#e5e1d6'),JRG=C_('#2e8b3d'),BLUC=C_('#0072bc'),DARK=C_('#3a3f45');
  const p0=jr.path.at(SJ);const FJ=stFrame(p0.x,p0.z,Math.atan2(p0.tz,p0.tx));
  const q0=blu.path.at(SB);const FB=stFrame(q0.x,q0.z,Math.atan2(q0.tz,q0.tx));
  const lo=s=>jr.path.laneOff(s,-1),hi=s=>jr.path.laneOff(s,1);
  const o1=s=>{const v=offOf(jr,T1,s);return v===null?lo(s)-12:v;},o4=s=>{const v=offOf(jr,T4,s);return v===null?hi(s)+15:v;};
  const sS=jr.path.near(4292,-6680).s,sN=jr.path.near(4222,-6988).s;
  const jrTop=s=>jr.path.py(s)+1.1;
  // island outlines (offsets from the jr centre line): 1・2 between 横須賀上り and 東海道上り, 3・4 between 東海道下り and 横須賀下り
  const I12=[s=>o1(s)+1.575,s=>lo(s)-1.575],I34=[s=>hi(s)+1.575,s=>o4(s)-1.575];
  const c12=s=>(I12[0](s)+I12[1](s))/2,c34=s=>(I34[0](s)+I34[1](s))/2;
  /* ---------- levels ---------- */
  const FL=20.8,ROOF=25.4;                    // 橋上 concourse and decks
  const B1Y=7.2,B1C=10.7;                     // 地下自由通路
  const B2Y=1.6,B2C=5.4;                      // ブルーライン改札階
  const B3T=blu.path.py(SB)+1.1;              // ブルーライン platform
  const DBG=window.__WDEBUG?((window.__ST_DBG=window.__ST_DBG||{})[NAME]=[]):null;const dbgR=(F,a0,a1,b0,b1,c)=>DBG&&DBG.push({c,p:[F.W(a0,b0),F.W(a1,b0),F.W(a1,b1),F.W(a0,b1),F.W(a0,b0)]});
  /* =================== JR platforms =================== */
  const B1S0=SJ+35.3;                          // head of the B1 stairs on the islands (they go down northwards)
  const runB1=Math.ceil((jrTop(B1S0)-B1Y)/0.28)*0.42;
  // shaft through each island: stair (centre cb-1.6) + escalator (cb+0.6); rectangle in FJ (a,b)
  const SH=[{cf:c12,sw:2.8,isl:'1・2'},{cf:c34,sw:3.0,isl:'3・4'}].map(q=>{const cb=q.cf(B1S0+6);return {...q,cb,a0:B1S0-SJ-0.2,a1:B1S0-SJ+runB1+0.3,b0:cb-1.6-q.sw/2-0.25,b1:cb+1.35,top:jrTop(B1S0)};});
  const holes12=[[SH[0].a0+SJ,SH[0].a1+SJ,SH[0].b0,SH[0].b1]],holes34=[[SH[1].a0+SJ,SH[1].a1+SJ,SH[1].b0,SH[1].b1]];
  deckAlong(gb,colls,jr,sS,sN,I12[0],I12[1],holes12);deckAlong(gb,colls,jr,sS,sN,I34[0],I34[1],holes34);
  for(const I of [I12,I34]){const rp=[];for(const [s,f] of [[sS,I[0]],[sN,I[0]],[sN,I[1]],[sS,I[1]]]){const p=jr.path.at(s,f(s));rp.push(p.x,p.z);}regPlatform(rp,jrTop(SJ),jr,false,false);}
  const CA0=-28,CA1=38,CB0=-36,CB1=22.5;         // concourse rectangle in FJ
  canopyAlong(gb,inn,colls,jr,sS+2,sN-2,I12[0],I12[1],4.2,[[SJ+CA0+1,SJ+CA1-1]],[[SH[0].a0+SJ,SH[0].a1+SJ]]);canopyAlong(gb,inn,colls,jr,sS+2,sN-2,I34[0],I34[1],4.2,[[SJ+CA0+1,SJ+CA1-1]],[[SH[1].a0+SJ,SH[1].a1+SJ]]);
  // 横須賀線下り (4番線) drawn here: the shared track renderer dips it to the subway level where it passes over the tunnel
  railsAlong(gb,[[4283.7,-6808.9],[4273.5,-6846.9],[4257.3,-6906.8],[4233.6,-6983.2]],(x,z)=>jr.path.py(jr.path.near(x,z).s)+0.02);
  // name boards: 東海道線 side shows JT 06, 横須賀線 side shows JO 10
  const ST_JT={name:'戸塚',kana:'とつか',roma:'Totsuka',code:'JT',num:'06',col:'#f68b1e',band:'#2e8b3d'},ST_JO={name:'戸塚',kana:'とつか',roma:'Totsuka',code:'JO',num:'10',col:'#0067c0',band:'#2e8b3d'};
  const NB={JTn:{name:'横浜',num:'JT 05'},JTs:{name:'大船',num:'JT 07'},JOn:{name:'東戸塚',num:'JO 11'},JOs:{name:'大船',num:'JO 09'}};
  for(const s of [sS+30,sS+85,SJ-55,SJ+60,SJ+110,sN-30]){
    {const c=jr.path.at(s,c12(s));nameBoard(fr,c.x,jrTop(s)+2.75,c.z,c.tx,c.tz,2.3,0.58,sd=>sd>0?{st:ST_JT,nbT:NB.JTn,nbB:NB.JTs}:{st:ST_JO,nbT:NB.JOn,nbB:NB.JOs});}
    {const c=jr.path.at(s,c34(s));nameBoard(fr,c.x,jrTop(s)+2.75,c.z,c.tx,c.tz,2.3,0.58,sd=>sd<0?{st:ST_JT,nbT:NB.JTn,nbB:NB.JTs}:{st:ST_JO,nbT:NB.JOn,nbB:NB.JOs});}}
  // track-number boards and platform furniture
  for(const [cf,wfn,lab] of [[c12,s=>I12[1](s)-I12[0](s),[['1','横須賀線 上り 横浜・東京方面'],['2','東海道線 上り 横浜・東京方面']]],[c34,s=>I34[1](s)-I34[0](s),[['3','東海道線 下り 大船・小田原方面'],['4','横須賀線 下り 大船・鎌倉方面']]]]){
    for(const s of [SJ-30,SJ+48]){const c=jr.path.at(s,cf(s));const nx=-c.tz,nz=c.tx;const hw=wfn(s)/2-1.6;
      for(const [k,sd] of [[0,-1],[1,1]]){const x=c.x+nx*sd*hw*0.5,z=c.z+nz*sd*hw*0.5;sign(x,jrTop(s)+3.05,z,c.tx,c.tz,2.0,0.5,lab[k][0]+'番線',lab[k][1],'#27323b','#ffffff',lab[k][1].includes('横須賀')?'#0067c0':'#f68b1e',true);}}
    for(let s=sS+20;s<sN-15;s+=34){if(s>SJ+CA0-4&&s<SJ+CA1+4)continue;if(s>B1S0-3&&s<B1S0+runB1+3)continue;const c=jr.path.at(s,cf(s));const ang=Math.atan2(c.tz,c.tx);
      gb.obox(c.x,c.z,c.tx,c.tz,0.9,0.22,jrTop(s)+0.42,jrTop(s)+0.48,C_('#2f6fb3'));gb.obox(c.x,c.z,c.tx,c.tz,0.9,0.03,jrTop(s)+0.48,jrTop(s)+0.85,C_('#2f6fb3'));colls.push(addOBB(c.x,c.z,0.9,0.25,ang,jrTop(s),jrTop(s)+0.85));}}
  /* =================== 2F: 橋上駅舎 (concourse, JR gate, free passage) =================== */
  const PA0=16,PA1=32;                         // free passage band (a) across the concourse
  // stair (sb = centre offset from the island centre) + one or two escalators (eb) per island
  const st2=[{c:c12(SJ),sw:2.8,sb:-1.2,eb:[2.0],isl:'1・2'},{c:c34(SJ),sw:3.2,sb:-1.8,eb:[1.0,2.3],isl:'3・4'}];
  const run2=Math.ceil((FL-jrTop(SJ))/0.28)*0.42,esc2=(FL-jrTop(SJ))/Math.tan(Math.PI/6);
  for(const q of st2){q.b0=q.c+q.sb-q.sw/2-0.2;q.b1=q.c+q.eb[q.eb.length-1]+0.7;}
  const h2=st2.map(q=>[4-esc2-0.3,4.05,q.b0,q.b1]);
  slabWithHoles(inn,colls,FJ,CA0,CA1,CB0,CB1,FL,0.5,h2,TILE,C_('#a6abaf'));
  {B(gb,FJ,CA0,CA1,CB0,CB1,ROOF,ROOF+0.6,C_('#b9bfc4'));K(colls,FJ,CA0,CA1,CB0,CB1,ROOF,ROOF+0.6);B(inn,FJ,CA0,CA1,CB0,CB1,ROOF-0.02,ROOF,CEIL,2);B(gb,FJ,CA0,CA1,CB0,CB1,FL-0.62,FL-0.5,C_('#9aa1a7'),2);
    for(const [a0,a1,b0,b1,gap] of [[CA0,CA1,CB0,CB0,1],[CA0,CA1,CB1,CB1,1],[CA0,CA0,CB0,CB1,0],[CA1,CA1,CB0,CB1,0]]){
      const segs=gap?[[a0,PA0],[PA1,a1]]:[[b0,b1]];for(const [u0,u1] of segs){const A0=gap?u0:a0,A1=gap?u1:a1,Bb0=gap?b0:u0,Bb1=gap?b1:u1;
        B(glass,FJ,A0-0.05,A1+0.05,Bb0-0.05,Bb1+0.05,FL+1.1,ROOF,C_('#a9c8d8'));B(gb,FJ,A0-0.06,A1+0.06,Bb0-0.06,Bb1+0.06,FL,FL+1.1,C_('#d9dcd8'));K(colls,FJ,A0-0.1,A1+0.1,Bb0-0.1,Bb1+0.1,FL,ROOF);}}
    for(const [a,b] of [[CA0,CB0],[CA1,CB0],[CA0,CB1],[CA1,CB1],[PA0,CB0],[PA1,CB0],[PA0,CB1],[PA1,CB1]])B(gb,FJ,a-0.35,a+0.35,b-0.35,b+0.35,FL-0.5,ROOF,C_('#8e979e'));
    // columns down to the ground between the tracks / outside them
    for(const a of [CA0+6,10,30])for(const b of [CB0+2,c12(SJ),c34(SJ),CB1-0.7]){const c=FJ.W(a,b);const g=demH(c[0],c[1]);B(gb,FJ,a-0.5,a+0.5,b-0.5,b+0.5,Math.min(g,jrTop(SJ))-0.3,FL-0.5,C_('#c9c5bb'));K(colls,FJ,a-0.5,a+0.5,b-0.5,b+0.5,Math.min(g,jrTop(SJ))-0.3,FL-0.5);}
    // facade band with the station name
    for(const [b,n] of [[CB0-0.08,-1],[CB1+0.08,1]]){const c=FJ.W((CA0+PA0)/2,b);sign(c[0],ROOF-1.0,c[1],FJ.vx*n,FJ.vz*n,9,1.6,'戸塚駅',n<0?'TOTSUKA STATION  西口':'TOTSUKA STATION  東口','#ffffff','#2e8b3d','#2e8b3d',false);}
    INDOOR.push({cx:FJ.W((CA0+CA1)/2,(CB0+CB1)/2)[0],cz:FJ.W((CA0+CA1)/2,(CB0+CB1)/2)[1],c:FJ.ux,s:FJ.uz,hl:(CA1-CA0)/2,hw:(CB1-CB0)/2,y0:FL-0.5,y1:ROOF});
    lights(FJ,CA0,CA1,CB0,CB1,ROOF,6,7);
    B(inn,FJ,PA0,PA1,CB0,CB1,FL,FL+0.012,C_('#cfc7b8'),1);}
  // paid area: gates on the passage side, partitions
  {const g0=-7,g1=9;partition(inn,colls,FJ,PA0,CB0+6,PA0,g0-0.4,FL);partition(inn,colls,FJ,PA0,g1+0.4,PA0,CB1-2,FL);partition(inn,colls,FJ,CA0,CB0+6,PA0,CB0+6,FL);partition(inn,colls,FJ,CA0,CB1-2,PA0,CB1-2,FL);
    const g=FJ.W(PA0,(g0+g1)/2);gatesGB(inn,colls,g[0],g[1],FJ.vx,FJ.vz,g1-g0,FL);B(inn,FJ,CA0,PA0,CB0+6,CB1-2,FL,FL+0.012,PAIDC,1);
    const sb=FJ.W(PA0+0.15,(g0+g1)/2);sign(sb[0],FL+3.2,sb[1],FJ.ux,FJ.uz,5.6,1.0,'JR線 のりば','東海道線・横須賀線・湘南新宿ライン','#27323b','#ffffff','#2e8b3d');
    B(inn,FJ,PA0-0.1,PA0+0.1,g0-0.6,g1+0.6,FL+2.6,FL+2.9,JRG);
    const m=FJ.W(PA0+2.2,CB1-5.5);machinesGB(inn,colls,m[0],m[1],FJ.vx,FJ.vz,5,FL);
    // みどりの窓口 and shops along the north side of the passage
    for(const [b0,b1,col,t] of [[CB0+1,CB0+9,'#2e8b3d','みどりの窓口'],[CB0+11,CB0+18,'#d6392f','NewDays'],[CB0+20,CB0+26,'#c8432f','崎陽軒'],[CB0+28,CB0+34,'#5a3a24','BECK\'S COFFEE'],[CB0+36,CB0+43,'#3f6f4f','いろり庵きらく']]){
      BK(inn,colls,FJ,PA1+0.6,CA1-0.3,b0,b1,FL,FL+2.8,C_('#f4efe6'));B(inn,FJ,PA1+0.5,CA1-0.2,b0-0.1,b1+0.1,FL+2.8,FL+3.3,C_(col));const s=FJ.W(PA1+0.45,(b0+b1)/2);sign(s[0],FL+3.05,s[1],-FJ.ux,-FJ.uz,Math.min(b1-b0-1,4),0.44,t,'',col,'#ffffff',null,false);}
    for(const [b,t] of [[CB0+3,'← 西口  West Exit・トツカーナ'],[CB1-3,'東口  East Exit・バスターミナル →']]){const c=FJ.W((PA0+PA1)/2,b);sign(c[0],FL+3.4,c[1],FJ.ux,FJ.uz,4.6,0.62,t,'','#f2d33c','#1b1f24');}}
  // stairs + escalators concourse ↔ islands
  for(const q of st2){stairDir(inn,colls,FJ,4,q.c+q.sb,-1,0,FL,jrTop(SJ),q.sw);
    for(const e of q.eb)escalatorVis(inn,stFrame(...FJ.W(4,q.c+e),FJ.ang+Math.PI),0,0,1,FL,jrTop(SJ),1.0);
    const a0=4-esc2-0.3,b0=q.b0,b1=q.b1;
    for(const [p0,p1,r0,r1] of [[a0,4,b0-0.06,b0],[a0,4,b1,b1+0.06],[a0-0.06,a0,b0,b1]]){B(inn,FJ,p0,p1,r0,r1,FL,FL+1.1,C_('#b8c0c6'));K(colls,FJ,p0,p1,r0,r1,FL,FL+1.1);}
    // enclosure around the stair well on the platform (glass sides, roof is the concourse floor)
    for(const b of [b0-0.1,b1+0.1]){B(glass,FJ,a0,4,b-0.04,b+0.04,jrTop(SJ)+1.0,FL-0.5,C_('#a9c8d8'));B(gb,FJ,a0,4,b-0.05,b+0.05,jrTop(SJ),jrTop(SJ)+1.0,C_('#c9ced3'));K(colls,FJ,a0,4,b-0.08,b+0.08,jrTop(SJ),FL-0.5);}
    B(gb,FJ,4-0.1,4.1,b0-0.1,b1+0.1,jrTop(SJ),FL-0.5,C_('#c9ced3'));K(colls,FJ,4-0.1,4.2,b0-0.1,b1+0.1,jrTop(SJ),FL-0.5);
    const s=FJ.W(-1,q.c);sign(s[0],FL+2.7,s[1],FJ.ux,FJ.uz,2.8,0.55,q.isl+'番線',q.isl==='1・2'?'上り 横浜・東京・新宿方面':'下り 大船・小田原・鎌倉方面','#27323b','#ffffff','#2e8b3d');}
  /* =================== decks =================== */
  {// west: to トツカーナ (OSM 265049537/266254486), stairs down to the 西口 street
    deck(gb,colls,FJ.W(24,CB0),FJ.W(24,CB0-24),12,FL,[[[9,15]],[[4.4,7.6]]],true,[0,1]);
    deck(gb,colls,FJ.W(18.3,CB0-12),FJ.W(6,CB0-12),6,FL,[1,1],true,[0,0]);
    {const t=FJ.W(6,CB0-12);deckStair(gb,colls,t[0],t[1],-FJ.ux,-FJ.uz,FL,3.2);}
    {const t=FJ.W(29.7,CB0-6);deckStair(gb,colls,t[0],t[1],FJ.ux,FJ.uz,FL,3.0);}
    const s=FJ.W(24,CB0-23.7);sign(s[0],FL+3.0,s[1],FJ.vx,FJ.vz,4.4,0.7,'トツカーナ','TOTSUKANA  西口','#ffffff','#1b1f24','#e8902f');
    for(let a=19;a<30;a+=5){const c=FJ.W(a,CB0-12);B(gb,FJ,a,a+4.6,CB0-24,CB0,FL+3.6,FL+3.8,C_('#d2d6d9'));}}
  {// east: ペデストリアンデッキ over the 東口 bus terminal (OSM 218698525 / 218698527)
    const e0=FJ.W(24,CB1),e1=[4348,-6884.5];const x0=[4292.0,-6874.6];const u1=Math.hypot(x0[0]-e0[0],x0[1]-e0[1]);
    const FE=deck(gb,colls,e0,e1,7,FL,[[[u1-3.5,u1+3.5]],[[u1-3.5,u1+3.5],[2.4,6.0]]],true,[0,0]);
    const n0=[4306.3,-6821.2],n1=[4290.8,-6890];const u2=Math.hypot(x0[0]-n0[0],x0[1]-n0[1]);deck(gb,colls,n0,n1,6,FL,[[[u2-3.6,u2+3.6]],[[u2-3.6,u2+3.6]]],true,[0,1]);
    {const L=Math.hypot(e1[0]-e0[0],e1[1]-e0[1]);deckStair(gb,colls,e1[0],e1[1],(e1[0]-e0[0])/L,(e1[1]-e0[1])/L,FL,3.0);}
    {const L=Math.hypot(n0[0]-n1[0],n0[1]-n1[1]);deckStair(gb,colls,n0[0],n0[1],(n0[0]-n1[0])/L,(n0[1]-n1[1])/L,FL,3.2);}
    {const t=FE.W(4.2,3.5);deckStair(gb,colls,t[0],t[1],FE.vx,FE.vz,FL,2.8);}
    for(let u=3;u<u1+30;u+=5)B(gb,FE,u,u+4.6,-3.5,3.5,FL+3.6,FL+3.8,C_('#d2d6d9'));
    sign(4320,FL+3.3,-6880.6,0.18,1,4.6,0.7,'← JR戸塚駅 東口','バスターミナル・ラピス','#ffffff','#1b1f24','#2e8b3d');}
  /* =================== B1: 地下自由通路 + JR 地下改札 =================== */
  const H_A0=-132,H_A1=64,H_B0=-7,H_B1=7;      // passage in FB
  const ALC=[-94,-57.5];                       // alcove in front of the JR gate (south side)
  const b1b2=[-42,-31.6];                      // B1→B2 stair opening (a), in the passage
  const escB12=(B1Y-B2Y)/Math.tan(Math.PI/6);
  const holeB1=[b1b2[0]-0.3,b1b2[0]+escB12+0.3,-6.6,-0.4];
  slabWithHoles(inn,colls,FB,H_A0,H_A1,H_B0,H_B1,B1C+0.3,0.3,[],CEIL,CEIL);
  slabWithHoles(inn,colls,FB,H_A0,H_A1,H_B0,H_B1,B1Y,0.4,[holeB1],TILE,null);
  B(inn,FB,H_A0,H_A1,-0.5,0.5,B1Y,B1Y+0.01,C_('#f2d33c'),1);
  // alcove floor / ceiling (its south side opens into the JR paid area)
  slabWithHoles(inn,colls,FB,ALC[0],ALC[1],H_B1,H_B1+7,B1Y,0.4,[],TILE,null);slabWithHoles(inn,colls,FB,ALC[0],ALC[1],H_B1,H_B1+7,B1C+0.3,0.3,[],CEIL,CEIL);
  B(inn,FB,ALC[0],ALC[0]+0.02,H_B1,H_B1+7,B1Y,B1C,WALL,32);K(colls,FB,ALC[0]-0.3,ALC[0],H_B1,H_B1+7,B1Y,B1C);
  dbgR(FB,H_A0,H_A1,H_B0,H_B1,[255,255,0]);dbgR(FB,ALC[0],ALC[1],H_B1,H_B1+7,[255,255,0]);
  // JR paid area under the islands (FJ)
  const JA0=26,JA1=50,JB0=-16,JB1=20;
  {const hz=SH.map(h=>[h.a0,h.a1,h.b0,h.b1]);
    wallsV(inn,FJ,JA0,JA1,JB0,JB1,B1Y,B1C,WALL,[[3,-1e9,1e9]]);
    slabWithHoles(inn,colls,FJ,JA0,JA1,JB0,JB1,B1Y,0.4,[],TILE,null);slabWithHoles(inn,[],FJ,JA0,JA1,JB0,JB1,B1C+0.3,0.3,hz,CEIL,CEIL);
    B(inn,FJ,JA0,JA1,JB0,JB1,B1Y,B1Y+0.012,PAIDC,1);
    rectWalls(colls,FJ,JA0,JA1,JB0,JB1,B1Y,B1C,[[3,-1e9,1e9]]);
    regZone(FJ,JA0,JA1,JB0,JB1,B1Y-1,B1C+0.4,NAME,blu,B1Y,null);dbgR(FJ,JA0,JA1,JB0,JB1,[0,255,0]);
    // gate line facing the passage
    const g0=-4,g1=12;partition(inn,colls,FJ,JA1,JB0,JA1,g0-0.4,B1Y);partition(inn,colls,FJ,JA1,g1+0.4,JA1,JB1,B1Y);
    const g=FJ.W(JA1,(g0+g1)/2);gatesGB(inn,colls,g[0],g[1],FJ.vx,FJ.vz,g1-g0,B1Y);B(inn,FJ,JA1-0.1,JA1+0.1,g0-0.6,g1+0.6,B1Y+2.55,B1Y+2.85,JRG);
    const sb=FJ.W(JA1+0.15,(g0+g1)/2);sign(sb[0],B1Y+3.0,sb[1],FJ.ux,FJ.uz,4.4,0.8,'JR線 地下改札','東海道線・横須賀線  JR Lines','#27323b','#ffffff','#2e8b3d');
    {const m=FJ.W(JA1+1.2,JB0+4);machinesGB(inn,colls,m[0],m[1],FJ.vx,FJ.vz,4,B1Y);}
    // stairs from the islands down to B1 (north-going), escalator beside; shafts through the embankment
    for(const h of SH){const top=h.top;
      stairDir(inn,colls,FJ,h.a0+0.2,h.cb-1.6,1,0,top,B1Y,h.sw);escalatorVis(inn,stFrame(...FJ.W(h.a0+0.2,h.cb+0.6),FJ.ang),0,0,1,top,B1Y,1.0);
      wallsV(inn,FJ,h.a0,h.a1,h.b0,h.b1,B1C,top-0.02,WALL);terrainHole(...FJ.W((h.a0+h.a1)/2,(h.b0+h.b1)/2),FJ.ang,(h.a1-h.a0)/2,(h.b1-h.b0)/2);
      regZone(FJ,h.a0,h.a1,h.b0,h.b1,B1Y-0.5,top+4,NAME,blu,B1Y,null,false);
      // railing round the opening on the platform (open at the stair head, a0)
      for(const [p0,p1,q0,q1] of [[h.a0,h.a1,h.b0-0.06,h.b0],[h.a0,h.a1,h.b1,h.b1+0.06],[h.a1,h.a1+0.06,h.b0,h.b1]]){B(gb,FJ,p0,p1,q0,q1,top,top+1.1,C_('#b8c0c6'));K(colls,FJ,p0,p1,q0,q1,top,top+1.1);}
      const s=FJ.W(h.a0+2,h.b1+0.1);sign(s[0],top+2.4,s[1],FJ.ux,FJ.uz,2.6,0.5,'地下改札・ブルーライン','B1  Underground Gate','#27323b','#ffffff','#0072bc');}}
  // B1 shops, mural, signs
  for(const [a0,a1,side,col,t] of [[-24,-16,1,'#00a040','ファミリーマート'],[4,14,1,'#1e5aa8','有隣堂'],[-54,-50,-1,'#c8432f','崎陽軒'],[22,30,-1,'#2a7fbf','QB HOUSE']]){
    const b0=side>0?H_B1-2.4:H_B0,b1=side>0?H_B1:H_B0+2.4;BK(inn,colls,FB,a0,a1,b0,b1,B1Y,B1Y+2.7,C_('#f4efe6'));B(inn,FB,a0-0.1,a1+0.1,b0-0.05,b1+0.05,B1Y+2.7,B1Y+3.1,C_(col));
    const s=FB.W((a0+a1)/2,side>0?b0-0.05:b1+0.05);sign(s[0],B1Y+2.9,s[1],FB.vx*-side,FB.vz*-side,Math.min(a1-a0-1,4.5),0.4,t,'',col,'#ffffff',null,false);}
  {const t=canvasTex('mural_totsuka',1024,384,(x,w,h)=>{const g=x.createLinearGradient(0,0,0,h);g.addColorStop(0,'#c8dce8');g.addColorStop(0.55,'#f1e8d2');g.addColorStop(1,'#d9c79e');x.fillStyle=g;x.fillRect(0,0,w,h);
      x.fillStyle='#e9eef0';x.beginPath();x.moveTo(560,190);x.lineTo(700,70);x.lineTo(840,190);x.fill();x.fillStyle='#5f7c8a';x.beginPath();x.moveTo(640,122);x.lineTo(700,70);x.lineTo(760,122);x.fill();
      x.fillStyle='#4f6f45';for(let i=0;i<9;i++){x.beginPath();x.arc(80+i*55,250-((i*37)%40),38,0,Math.PI*2);x.fill();}x.strokeStyle='#7a5a3a';x.lineWidth=10;x.beginPath();x.moveTo(300,300);x.quadraticCurveTo(520,230,760,300);x.stroke();
      x.fillStyle='#2b3a55';x.font=`700 34px ${FONT}`;x.textAlign='right';x.fillText('東海道五拾三次之内 戸塚 元町別道',w-30,h-26);x.fillStyle='#8a2a1e';x.fillRect(w-64,24,40,120);});
    const c=FB.W(-6,H_B0+0.03);const m=new THREE.Mesh(new THREE.PlaneGeometry(12,4.5*0.94*0.75),texMat(t));m.position.set(c[0],B1Y+1.95,c[1]);m.rotation.y=Math.atan2(FB.vx,FB.vz);scene.add(m);}
  {const s=FB.W(H_A0+0.03,0);sign(s[0],B1Y+2.3,s[1],FB.ux,FB.uz,3.2,0.55,'トツカーナ連絡口','TOTSUKANA  B1','#ffffff','#1b1f24','#e8902f',false);B(glass,FB,H_A0,H_A0+0.05,-3,3,B1Y,B1Y+2.4,C_('#9fb7c6'));}
  for(const [a,t] of [[-110,'西口 ↓  トツカーナ ←'],[-75,'JR線 地下改札 ↓  出口6 →'],[-36,'↓ ブルーライン  Blue Line'],[10,'← 西口・JR線　出口1・2・3 →'],[52,'出口1・東口 →']]){const c=FB.W(a,0);sign(c[0],B1Y+3.05,c[1],FB.ux,FB.uz,4.6,0.6,t,'','#f2d33c','#1b1f24');}
  /* =================== B2: ブルーライン改札階 =================== */
  const C2A0=-48,C2A1=58,C2B0=-9,C2B1=9,GA=-20;
  const runB23=Math.ceil((B2Y-B3T)/0.28)*0.42,escB23=(B2Y-B3T)/Math.tan(Math.PI/6);
  const st3=[-8,34];const holes2=st3.map(a=>[a-0.3,a+escB23+0.3,-3.3,2.1]);
  roomShell(inn,FB,C2A0,C2A1,C2B0,C2B1,B2Y,B2C,C_('#e8ecef'),null,null);slabWithHoles(inn,colls,FB,C2A0,C2A1,C2B0,C2B1,B2Y,0.4,holes2,TILE,null);
  slabWithHoles(inn,[],FB,C2A0,C2A1,C2B0,C2B1,B2C+0.3,0.3,[holeB1],CEIL,CEIL);
  rectWalls(colls,FB,C2A0,C2A1,C2B0,C2B1,B2Y,B2C);B(inn,FB,GA,C2A1,C2B0,C2B1,B2Y,B2Y+0.012,PAIDC,1);
  {const g0=-7,g1=7;partition(inn,colls,FB,GA,C2B0,GA,g0-0.3,B2Y);partition(inn,colls,FB,GA,g1+0.3,GA,C2B1,B2Y);const g=FB.W(GA,0);gatesGB(inn,colls,g[0],g[1],FB.vx,FB.vz,g1-g0,B2Y);
    B(inn,FB,GA-0.1,GA+0.1,g0-0.6,g1+0.6,B2Y+2.45,B2Y+2.75,BLUC);const s=FB.W(GA-0.15,0);sign(s[0],B2Y+3.05,s[1],-FB.ux,-FB.uz,4.6,0.85,'ブルーライン','横浜市営地下鉄  Blue Line  B06','#27323b','#ffffff','#0072bc');
    const m=FB.W(GA-6,C2B0+0.8);machinesGB(inn,colls,m[0],m[1],FB.ux,FB.uz,5,B2Y);const o=FB.W(GA-3,C2B1-1.4);BK(inn,colls,FB,GA-6,GA-1,C2B1-2.4,C2B1,B2Y,B2Y+2.5,C_('#dfe6ec'));sign(o[0],B2Y+2.85,o[1]-1.25*FB.vz,FB.vx,FB.vz,3.2,0.4,'定期券発売所','','#0072bc','#ffffff',null,false);
    BK(inn,colls,FB,C2A1-8,C2A1,C2B1-3,C2B1,B2Y,B2C,C_('#dfe6ec'));const tt=FB.W(C2A1-4,C2B1-3.05);sign(tt[0],B2Y+2.6,tt[1],FB.vx,FB.vz,2.4,0.45,'トイレ','Toilets','#0072bc','#ffffff',null,false);}
  lights(FB,C2A0,C2A1,C2B0,C2B1,B2C,6,6);lights(FB,H_A0,H_A1,H_B0,H_B1,B1C,6,7);lights(FJ,JA0,JA1,JB0,JB1,B1C,6,7);
  // B1 → B2 stairs + escalators (free side)
  stairDir(inn,colls,FB,b1b2[0],-5.0,1,0,B1Y,B2Y,3.0);escalatorVis(inn,stFrame(...FB.W(b1b2[0],-2.6),FB.ang),0,0,1,B1Y,B2Y,1.0);escalatorVis(inn,stFrame(...FB.W(b1b2[0],-1.3),FB.ang),0,0,1,B1Y,B2Y,1.0);
  {const a0=holeB1[0],a1=holeB1[1];roomShell(inn,FB,a0,a1,holeB1[2],holeB1[3],B2C,B1Y-0.4,WALL,null,null);
    for(const [p0,p1,q0,q1] of [[a0,a1,holeB1[2]-0.06,holeB1[2]],[a0,a1,holeB1[3],holeB1[3]+0.06],[a1,a1+0.06,holeB1[2],holeB1[3]]]){B(inn,FB,p0,p1,q0,q1,B1Y,B1Y+1.1,C_('#b8c0c6'));K(colls,FB,p0,p1,q0,q1,B1Y,B1Y+1.1);}}
  // B2 → B3 stairs + escalators (paid side)
  for(const a of st3){stairDir(inn,colls,FB,a,-1.5,1,0,B2Y,B3T,2.8);escalatorVis(inn,stFrame(...FB.W(a,1.3),FB.ang),0,0,1,B2Y,B3T,1.0);
    const a1=a+escB23+0.3;for(const [p0,p1,q0,q1] of [[a-0.3,a1,-3.36,-3.3],[a-0.3,a1,2.1,2.16],[a1,a1+0.06,-3.3,2.1]]){B(inn,FB,p0,p1,q0,q1,B2Y,B2Y+1.1,C_('#b8c0c6'));K(colls,FB,p0,p1,q0,q1,B2Y,B2Y+1.1);}
    roomShell(inn,FB,a-0.3,a1,-3.3,2.1,B3T+4.3,B2Y-0.4,WALL,null,null);}
  /* =================== B3: ブルーライン island platform =================== */
  {const s0=SB-60,s1=SB+60;const fl=blu.path.py(SB)-0.3;const pe=blu.path.laneOff(SB,1)-1.48;
    roomShell(inn,FB,-66,66,-10,10,fl,B3T+4.3,C_('#dfe6ec'),null,null);slabWithHoles(inn,[],FB,-66,66,-10,10,B3T+4.6,0.3,holes2,CEIL,CEIL);inn.obox(...FB.W(0,0),FB.ux,FB.uz,66,10,fl-0.3,fl,C_('#6f6a63'),1);{const f=addPoly(flatPolyRect(FB,-66,66,-10,10),fl-0.4,fl);f.tag=0;}
    deckAlong(inn,colls,blu,s0,s1,()=>-pe,()=>pe,[],{top:B3T,deck:'#d9d5cc'});
    const rp=[];for(const [s,o] of [[s0,-pe],[s1,-pe],[s1,pe],[s0,pe]]){const p=blu.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,B3T,blu,true,false);
    // platform doors (ホームドア) along both edges, with gaps at the car doors
    for(const sd of [-1,1])for(let s=s0+1;s<s1-1;s+=3){const p=blu.path.at(s+1.5,sd*(pe-0.25));const ang=Math.atan2(p.tz,p.tx);if(((s-s0)%6)<2.9){inn.obox(p.x,p.z,p.tx,p.tz,1.0,0.12,B3T,B3T+1.3,C_('#cfd6dc'));inn.obox(p.x,p.z,p.tx,p.tz,1.0,0.13,B3T+1.0,B3T+1.12,BLUC);colls.push(addOBB(p.x,p.z,1.0,0.12,ang,B3T,B3T+1.3));}}
    for(let s=s0+8;s<s1-4;s+=12){const p=blu.path.at(s,2.8);if(st3.some(a=>s>SB+a-1&&s<SB+a+escB23+1))continue;inn.obox(p.x,p.z,p.tx,p.tz,0.25,0.25,B3T,B3T+4.3,C_('#e6ebef'));colls.push(addOBB(p.x,p.z,0.25,0.25,Math.atan2(p.tz,p.tx),B3T,B3T+4.3));
      const q=blu.path.at(s,-2.8);inn.obox(q.x,q.z,q.tx,q.tz,0.25,0.25,B3T,B3T+4.3,C_('#e6ebef'));colls.push(addOBB(q.x,q.z,0.25,0.25,Math.atan2(q.tz,q.tx),B3T,B3T+4.3));}
    const ST_B={name:'戸塚',kana:'とつか',roma:'Totsuka',code:'B',num:'06',col:'#0072bc',band:'#0072bc'};
    for(const s of [s0+12,SB+22,s1-14]){const q=blu.path.at(s,0);nameBoard(fr,q.x,B3T+2.75,q.z,q.tx,q.tz,2.3,0.58,()=>({st:ST_B,nbT:{name:'舞岡',num:'B07'},nbB:{name:'踊場',num:'B05'}}));}
    for(const [sd,t1,t2] of [[1,'1番線','湘南台方面  for Shonandai'],[-1,'2番線','あざみ野方面  for Azamino']]){const q=blu.path.at(SB-30,sd*1.5);sign(q.x,B3T+3.1,q.z,q.tx,q.tz,2.4,0.5,t1,t2,'#27323b','#ffffff','#0072bc',true);}
    rectWalls(colls,FB,-66,66,-10,10,fl,B3T+4.3);
    for(const sd of [-1,1]){const c=FB.W(sd*(66+60),0);inn.obox(c[0],c[1],FB.ux,FB.uz,60,10,fl-0.3,B3T+4.3,DARK,2|4|8);}
    lights(FB,-66,66,-6,6,B3T+4.3,6,6);}
  /* =================== street exits from B1 =================== */
  const runEx=g=>Math.ceil((g-B1Y)/0.28)*0.42;
  const EXITS=[{a:-125,side:1,name:'西口',sub:'トツカーナ・西口バスターミナル'},{a:-46,side:1,name:'出口6',sub:'東口  JR線'},{a:-12,side:1,name:'出口5',sub:'東口バスターミナル'},{a:18,side:1,name:'出口3',sub:'ラピス戸塚'},{a:61.5,side:0,name:'出口1',sub:'柏尾川・ラピス'}];
  const gaps=[];
  for(const e of EXITS){// side 0: north (b0), 1: south (b1), 2: west end (a0)
    let ax,bx,da,db;if(e.side===2){bx=0;da=-1;db=0;}else{ax=e.a;da=0;db=e.side===0?-1:1;}
    // ground height at the far end (iterate run)
    let g=13.5,run=0;for(let k=0;k<4;k++){run=runEx(g);const tp=e.side===2?FB.W(H_A0-run,0):FB.W(e.a,(e.side===0?H_B0:H_B1)+db*run);g=heightAt(tp[0],tp[1]);}
    run=runEx(g+0.05);const ta=e.side===2?H_A0-run:e.a,tb=e.side===2?0:(e.side===0?H_B0:H_B1)+db*run;
    stairDir(inn,colls,FB,ta,tb,-da,-db,g+0.05,B1Y,2.9);
    const sa0=Math.min(ta,ta-da*run)-(da?0:1.65),sa1=Math.max(ta,ta-da*run)+(da?0:1.65),sb0=Math.min(tb,tb-db*run)-(db?0:1.65),sb1=Math.max(tb,tb-db*run)+(db?0:1.65);
    const topSide=da<0?2:da>0?3:db<0?0:1;const hallSide=e.side===2?3:e.side===0?1:0;
    wallsV(inn,FB,sa0,sa1,sb0,sb1,B1Y,g-0.05,WALL,[[hallSide,-1e9,1e9]]);wallsV(inn,FB,sa0,sa1,sb0,sb1,B1C,g-0.05,WALL,[0,1,2,3].filter(k=>k!==hallSide).map(k=>[k,-1e9,1e9]));terrainHole(...FB.W((sa0+sa1)/2,(sb0+sb1)/2),FB.ang,(sa1-sa0)/2+0.15,(sb1-sb0)/2+0.15);
    regZone(FB,sa0-0.2,sa1+0.2,sb0-0.2,sb1+0.2,B1Y-0.5,g+5,NAME,blu,B1Y,null);dbgR(FB,sa0,sa1,sb0,sb1,[255,0,255]);
    {const fb=addPoly(flatPolyRect(FB,sa0,sa1,sb0,sb1),B1Y-0.4,B1Y);fb.tag=0;B(inn,FB,sa0,sa1,sb0,sb1,B1Y-0.05,B1Y,TILE,1);}
    rectWalls(colls,FB,sa0,sa1,sb0,sb1,B1Y,g+1.1,[[topSide,-1e9,1e9],[hallSide,-1e9,1e9]]);
    gaps.push(e.side===2?[2,-1.65,1.65]:[e.side,e.a-1.65,e.a+1.65]);
    const tw=FB.W(ta,tb);const dw=[FB.ux*-da+FB.vx*-db,FB.uz*-da+FB.vz*-db];exitHood(out,tw[0],tw[1],dw[0],dw[1],g+0.05,run,'戸塚駅 '+e.name,e.sub);
  }
  rectWalls(colls,FB,H_A0,H_A1,H_B0,H_B1,B1Y,B1C,gaps.concat([[1,ALC[0],ALC[1]]]));wallsV(inn,FB,H_A0,H_A1,H_B0,H_B1,B1Y,B1C,WALL,gaps.concat([[1,ALC[0],ALC[1]]]));
  /* =================== zones =================== */
  {const Z=regZone(FB,-150,82,-14,34,B3T-1.1-0.9,B1C+0.4,NAME,blu,B1Y,null);Z.floorC=B1Y;dbgR(FB,-150,82,-14,34,[0,255,255]);}
  dbgR(FJ,CA0,CA1,CB0,CB1,[255,128,0]);
  for(const [g,mat] of [[gb,MAT.top],[out,MAT.top],[fr,MAT.top]])if(!g.empty){const m=new THREE.Mesh(g.geo(),mat);m.castShadow=g!==fr;m.receiveShadow=true;scene.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),UGMAT);scene.add(m);}
  flushAtlas();flushLights();
  if(!glass.empty){const m=new THREE.Mesh(glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
  {const c=FJ.W(4,-8);addLabel('戸塚駅','JR東海道線・横須賀線・ブルーライン',c[0],ROOF+7,c[1],'st','#2e8b3d',700,0.8);}
}
ST_CUSTOM[NAME]={lines:new Set(['jr','blu']),build};
})();
