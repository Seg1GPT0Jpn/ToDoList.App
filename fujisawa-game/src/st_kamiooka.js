/* ================= 上大岡駅 (横浜市営地下鉄ブルーライン・京急本線) =================
   From Wikipedia (駅構造), the Yokohama subway floor map (構内図) and OSM:
   - ブルーライン (B11): underground, B1 concourse / B2 island platform (島式1面2線). Two gates on B1:
     the north 京急方面改札口 and the south バスターミナル改札口, each with stairs + escalator to the platform.
     A long free passage runs along the east side of the station under 鎌倉街道 from 出口1 (north) to 出口6・7 (south),
     with links to カミオ (A: north-west, B: the covered PASSAGE KAMIOOKA) and to ゆめおおおか / 京急 (出口2).
   - 京急本線 (KK44, scenery, not a game line): elevated, 2 island platforms / 4 tracks (1・2 east, 3・4 west,
     main lines 2・3 in the middle, passing loops 1・4 outside), inside the ゆめおおおか building (PLATEAU, split
     into a solid base, a glazed station band and the floors above); the north end runs out on a viaduct.
   Frame FK on the subway at the stop: +a north along the line, +b east. */
(()=>{
const NAME='上大岡';
const SK=13874;
ST_S['blu|上大岡']=SK;
LANE_ADJ.push({key:'blu',s0:13806,s1:13942,lo:-4.0,hi:6.0,blend:130});
PROF_ADJ.push({key:'blu',s0:13800,s1:13948,y:-3.1,blend:320});
const RK=17.4,RKH=24.6;                                   // 京急 rail deck level / ceiling of the platform floor
BLD_SPLIT.push({x:9897.5,z:-7717.2,lo:RK,hi:RKH});          // ゆめおおおか: solid base, station band, store above
// OSM 京急 tracks (1 = up loop east … 4 = down loop west) and platforms
const KT=[
  [[9923.6,-7630.5],[9927.4,-7668.4],[9927.9,-7673.8],[9933.2,-7743.7],[9932.2,-7790.7],[9932.0,-7800.7],[9929.4,-7859.3],[9925.9,-7900.0],[9921.3,-7949.8],[9916.7,-7986.0]],
  [[9924.9,-7566.3],[9923.6,-7630.5],[9921.8,-7712.9],[9920.2,-7790.6],[9916.7,-7986.0]],
  [[9921.8,-7566.6],[9920.8,-7593.6],[9920.4,-7613.5],[9919.1,-7670.0],[9917.0,-7790.6],[9914.5,-7937.3],[9913.4,-7990.4]],
  [[9920.4,-7613.5],[9911.5,-7689.4],[9907.9,-7731.1],[9906.9,-7775.5],[9906.3,-7790.5],[9905.7,-7879.3],[9906.6,-7904.4],[9910.6,-7950.5],[9913.4,-7990.4]]];
const KP=[[9923.7,-7681.9,9927.2,-7681.9,9929.9,-7721.6,9931.3,-7745.6,9931.0,-7771.6,9930.1,-7808.1,9921.4,-7935.5,9918.7,-7935.4,9919.4,-7907.2,9920.2,-7874.0,9921.1,-7849.2,9921.4,-7822.2,9921.9,-7788.4,9922.6,-7756.9,9923.2,-7712.8],
  [9914.0,-7681.6,9917.8,-7681.5,9913.4,-7935.3,9910.4,-7935.5,9908.7,-7914.7,9907.6,-7901.6,9907.1,-7879.7,9907.1,-7862.6,9907.4,-7838.0,9907.7,-7813.5,9908.2,-7789.6,9908.5,-7772.7,9908.9,-7751.1,9909.7,-7730.8,9913.2,-7688.0]];
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
function canopyAlong(gb,inn,colls,l,s0,s1,fA,fB,h=4.2,skip=[]){for(let s=s0;s<s1-0.01;s+=5){const sb=Math.min(s1,s+5),sm=(s+sb)/2;if(skip.some(k=>sm>k[0]&&sm<k[1]))continue;const a=fA(sm),b=fB(sm);const c=l.path.at(sm,(a+b)/2);const top=l.path.py(sm)+1.1;const hv=Math.abs(b-a)/2+0.45;
    gb.obox(c.x,c.z,c.tx,c.tz,(sb-s)/2+0.02,hv,top+h,top+h+0.22,C_('#c4c9cd'),1|4|8|16|32);inn.obox(c.x,c.z,c.tx,c.tz,(sb-s)/2+0.02,hv-0.05,top+h-0.12,top+h,C_('#d9dcdc'),2);}
  for(let s=s0+6;s<s1-3;s+=15){if(skip.some(k=>s>k[0]-3&&s<k[1]+3))continue;const a=fA(s),b=fB(s);const c=l.path.at(s,(a+b)/2);const top=l.path.py(s)+1.1;
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

/* polyline clipped to a z range (the 京急 tracks run north–south) */
function clipZ(poly,z0,z1){const o=[];for(let i=0;i<poly.length-1;i++){const A=poly[i],Bq=poly[i+1];let t0=0,t1=1;const dz=Bq[1]-A[1];
  if(Math.abs(dz)<1e-9){if(A[1]<z0||A[1]>z1)continue;}else{let ta=(z0-A[1])/dz,tb=(z1-A[1])/dz;if(ta>tb){const t=ta;ta=tb;tb=t;}t0=Math.max(0,ta);t1=Math.min(1,tb);if(t0>=t1)continue;}
  const P=t=>[A[0]+(Bq[0]-A[0])*t,A[1]+dz*t];const p0=P(t0);if(!o.length||Math.hypot(o[o.length-1][0]-p0[0],o[o.length-1][1]-p0[1])>0.01)o.push(p0);o.push(P(t1));}return o;}
const xAtZ=(poly,z)=>{for(let i=0;i<poly.length-1;i++){const [ax,az]=poly[i],[bx,bz]=poly[i+1];if((z-az)*(z-bz)<=0&&az!==bz)return ax+(bx-ax)*(z-az)/(bz-az);}return poly[0][0];};

function build(){
  const blu=LINES.blu;if(!blu)return;
  const gb=new GB(),colls=[],inn=new GB(),out=new GB(),fr=new GB();const glass=new GB();inn.glass=glass;
  const TILE=C_('#d9d4c9'),WALL=C_('#eeebe4'),CEIL=C_('#f2f1ec'),PAIDC=C_('#e5e1d6'),BLUC=C_('#0072bc'),DARK=C_('#3a3f45'),KQR=C_('#e5171f');
  const q0=blu.path.at(SK);const F=stFrame(q0.x,q0.z,Math.atan2(q0.tz,q0.tx));
  const DBG=window.__WDEBUG?((window.__ST_DBG=window.__ST_DBG||{})[NAME]=[]):null;const dbgR=(Fr,a0,a1,b0,b1,c)=>DBG&&DBG.push({c,p:[Fr.W(a0,b0),Fr.W(a1,b0),Fr.W(a1,b1),Fr.W(a0,b1),Fr.W(a0,b0)]});
  /* ---------- levels ---------- */
  const B2T=blu.path.py(SK)+1.1;          // platform
  const B1Y=4.2,B1C=7.6;                  // concourse
  const lo=blu.path.laneOff(SK,-1),hi=blu.path.laneOff(SK,1);const pc=(lo+hi)/2,pe=(hi-lo)/2-1.48;
  /* =================== B1 =================== */
  const PA=[-142,42],PB=[5,14];            // free passage along the east side
  const NC=[38,54,-16,14];                 // north concourse (free)
  const NP=[12,38,-10,5],SP=[-95,-48,-10,5];// paid areas
  const stN=16,stS=-58;                    // tops of the B1→B2 stairs (both go down northwards)
  const runP=Math.ceil((B1Y-B2T)/0.28)*0.42,escP=(B1Y-B2T)/Math.tan(Math.PI/6);
  const sb=pc-1.0,eb=pc+1.75;              // stair / escalator centre lines on the island
  const holeP=a=>[a-0.3,a+escP+0.3,sb-1.5,eb+0.75];
  // floors & ceilings
  slabWithHoles(inn,colls,F,PA[0],PA[1],PB[0],PB[1],B1Y,0.4,[],TILE,null);slabWithHoles(inn,colls,F,PA[0],PA[1],PB[0],PB[1],B1C+0.3,0.3,[],CEIL,CEIL);
  slabWithHoles(inn,colls,F,NC[0],NC[1],NC[2],NC[3],B1Y,0.4,[],TILE,null);slabWithHoles(inn,colls,F,NC[0],NC[1],NC[2],NC[3],B1C+0.3,0.3,[],CEIL,CEIL);
  for(const [R,st] of [[NP,stN],[SP,stS]]){slabWithHoles(inn,colls,F,R[0],R[1],R[2],R[3],B1Y,0.4,[holeP(st)],TILE,null);slabWithHoles(inn,colls,F,R[0],R[1],R[2],R[3],B1C+0.3,0.3,[],CEIL,CEIL);
    B(inn,F,R[0],R[1],R[2],R[3],B1Y,B1Y+0.012,PAIDC,1);}
  B(inn,F,PA[0],PA[1],9.0,10.0,B1Y,B1Y+0.012,C_('#f2d33c'),1);
  dbgR(F,PA[0],PA[1],PB[0],PB[1],[255,255,0]);dbgR(F,NC[0],NC[1],NC[2],NC[3],[255,255,0]);dbgR(F,NP[0],NP[1],NP[2],NP[3],[0,255,0]);dbgR(F,SP[0],SP[1],SP[2],SP[3],[0,255,0]);
  /* ---------- exits ---------- */
  const runEx=g=>Math.ceil((g-B1Y)/0.28)*0.42;
  // perpendicular: from a hall side straight out; parallel: beside the passage (east side), rising along ±a from a landing
  const EXITS=[
    {k:'perp',R:NC,side:3,u:-8,name:'出口1',sub:'上大岡駅前・カミオ'},
    {k:'par',a:30,da:1,name:'出口2',sub:'京急線・ゆめおおおか'},
    {k:'par',a:-14,da:-1,name:'出口4',sub:'京急線・バスターミナル'},
    {k:'perp',R:[PA[0],PA[1],PB[0],PB[1]],side:2,u:9.0,name:'出口6',sub:'港南区役所方面'},
    {k:'perp',R:[-142,-100,-10,PB[0]],side:0,u:-136,name:'出口7',sub:'上大岡西'},
    {k:'perp',R:[-40,-30,-17,PB[0]],side:0,u:-36,name:'カミオ連絡口B',sub:'PASSAGE KAMIOOKA'}];
  const gapsPA=[],gapsNC=[],extraRooms=[];
  for(const e of EXITS){let g=9.4,run=0;
    if(e.k==='perp'){const R=e.R;// side: 0 b0 (west), 1 b1 (east), 2 a0 (south), 3 a1 (north)
      const dA=e.side===2?-1:e.side===3?1:0,dB=e.side===0?-1:e.side===1?1:0;const ea=dA?(dA>0?R[1]:R[0]):e.u,eb2=dB?(dB>0?R[3]:R[2]):e.u;
      for(let k=0;k<4;k++){run=runEx(g);const tp=F.W(ea+dA*run,eb2+dB*run);g=heightAt(tp[0],tp[1]);}run=runEx(g+0.05);
      const ta=ea+dA*run,tb=eb2+dB*run;stairDir(inn,colls,F,ta,tb,-dA,-dB,g+0.05,B1Y,2.9);
      const sa0=Math.min(ta,ea)-(dA?0:1.65),sa1=Math.max(ta,ea)+(dA?0:1.65),sb0=Math.min(tb,eb2)-(dB?0:1.65),sb1=Math.max(tb,eb2)+(dB?0:1.65);
      const topSide=dA<0?2:dA>0?3:dB<0?0:1,hallSide=dA<0?3:dA>0?2:dB<0?1:0;
      e.well=[sa0,sa1,sb0,sb1,topSide,hallSide,g,ta,tb,-dA,-dB,run];
      const gp=dA?[e.side,eb2-1.65,eb2+1.65]:[e.side,ea-1.65,ea+1.65];
      if(R===NC)gapsNC.push(gp);else if(R[0]===PA[0]&&R[1]===PA[1])gapsPA.push(gp);else{extraRooms.push({R,gp});gapsPA.push([0,R[0],R[1]]);}}
    else{// parallel well east of the passage, landing 2.6 m long at the foot
      const bC=PB[1]+0.15+1.55;for(let k=0;k<4;k++){run=runEx(g);const tp=F.W(e.a+e.da*run,bC);g=heightAt(tp[0],tp[1]);}run=runEx(g+0.05);
      const ta=e.a+e.da*run;stairDir(inn,colls,F,ta,bC,-e.da,0,g+0.05,B1Y,2.9);
      const la0=e.da>0?e.a-2.6:e.a,la1=e.da>0?e.a:e.a+2.6;const sa0=Math.min(la0,ta),sa1=Math.max(la1,ta),sb0=PB[1],sb1=bC+1.55+0.05;
      const topSide=e.da>0?3:2;e.well=[sa0,sa1,sb0,sb1,topSide,null,g,ta,bC,-e.da,0,run,[0,la0,la1]];gapsPA.push([1,la0,la1]);}
    const [sa0,sa1,sb0,sb1,topSide,hallSide,gg,ta,tb,dda,ddb,rr,land]=e.well;
    const wg=[[topSide,-1e9,1e9]];if(hallSide!==null)wg.push([hallSide,-1e9,1e9]);if(land)wg.push(land);
    wallsV(inn,F,sa0,sa1,sb0,sb1,B1Y,gg-0.05,WALL,wg);if(hallSide!==null)wallsV(inn,F,sa0,sa1,sb0,sb1,B1C,gg-0.05,WALL,[0,1,2,3].filter(k=>k!==hallSide).map(k=>[k,-1e9,1e9]));
    rectWalls(colls,F,sa0,sa1,sb0,sb1,B1Y,gg+1.1,wg);
    terrainHole(...F.W((sa0+sa1)/2,(sb0+sb1)/2),F.ang,(sa1-sa0)/2+0.15,(sb1-sb0)/2+0.15);
    regZone(F,sa0-0.2,sa1+0.2,sb0-0.2,sb1+0.2,B1Y-0.5,gg+5,NAME,blu,B1Y,null);dbgR(F,sa0,sa1,sb0,sb1,[255,0,255]);
    {const fb=addPoly(flatPolyRect(F,sa0,sa1,sb0,sb1),B1Y-0.4,B1Y);fb.tag=0;B(inn,F,sa0,sa1,sb0,sb1,B1Y-0.05,B1Y,TILE,1);}
    if(land)slabWithHoles(inn,colls,F,land[1],land[2],sb0,sb1,B1C+0.3,0.3,[],CEIL,CEIL);
    const tw=F.W(ta,tb);const dw=[F.ux*dda+F.vx*ddb,F.uz*dda+F.vz*ddb];exitHood(out,tw[0],tw[1],dw[0],dw[1],gg+0.05,rr,'上大岡駅 '+e.name,e.sub);}
  // small corridors that lead to exits off the west side (出口7, カミオ連絡口B)
  for(const x of extraRooms){const R=x.R;slabWithHoles(inn,colls,F,R[0],R[1],R[2],R[3],B1Y,0.4,[],TILE,null);slabWithHoles(inn,colls,F,R[0],R[1],R[2],R[3],B1C+0.3,0.3,[],CEIL,CEIL);
    const gg=[[1,-1e9,1e9],x.gp];wallsV(inn,F,R[0],R[1],R[2],R[3],B1Y,B1C,WALL,gg);rectWalls(colls,F,R[0],R[1],R[2],R[3],B1Y,B1C,gg);regZone(F,R[0],R[1],R[2],R[3],B1Y-1,B1C+0.4,NAME,blu,B1Y,null);dbgR(F,R[0],R[1],R[2],R[3],[0,200,255]);lights(F,R[0],R[1],R[2],R[3],B1C,6,6);}
  // passage + north concourse walls (NC opens to the passage; paid areas open to the passage through their gates)
  const gapNP=[0,NP[0],NP[1]],gapSP=[0,SP[0],SP[1]];
  wallsV(inn,F,PA[0],PA[1],PB[0],PB[1],B1Y,B1C,WALL,gapsPA.concat([gapNP,gapSP,[0,NC[0],NC[1]+1],[3,-1e9,1e9]]));rectWalls(colls,F,PA[0],PA[1],PB[0],PB[1],B1Y,B1C,gapsPA.concat([gapNP,gapSP,[0,NC[0],NC[1]+1],[3,-1e9,1e9]]));
  wallsV(inn,F,NC[0],NC[1],NC[2],NC[3],B1Y,B1C,WALL,gapsNC.concat([[2,NP[2],PB[1]]]));rectWalls(colls,F,NC[0],NC[1],NC[2],NC[3],B1Y,B1C,gapsNC.concat([[2,NP[2],PB[1]]]));
  // paid areas: walls on three sides, gate lines on the open side
  {// north 京急方面改札口: gates on its north side (a=38) facing the north concourse
    const R=NP;wallsV(inn,F,R[0],R[1],R[2],R[3],B1Y,B1C,WALL,[[3,-1e9,1e9],[1,-1e9,1e9]]);rectWalls(colls,F,R[0],R[1],R[2],R[3],B1Y,B1C,[[3,-1e9,1e9],[1,-1e9,1e9]]);
    partition(inn,colls,F,R[0],R[3],R[1],R[3],B1Y);// glass to the passage
    const g0=-7,g1=3;partition(inn,colls,F,R[1],R[2],R[1],g0-0.3,B1Y);partition(inn,colls,F,R[1],g1+0.3,R[1],R[3],B1Y);const g=F.W(R[1],(g0+g1)/2);gatesGB(inn,colls,g[0],g[1],F.vx,F.vz,g1-g0,B1Y);
    B(inn,F,R[1]-0.1,R[1]+0.1,g0-0.6,g1+0.6,B1Y+2.45,B1Y+2.75,BLUC);const s=F.W(R[1]+0.15,(g0+g1)/2);sign(s[0],B1Y+3.0,s[1],F.ux,F.uz,4.6,0.8,'京急方面改札口','ブルーライン  Blue Line  B11','#27323b','#ffffff','#0072bc');
    const m=F.W(NC[0]+4,NC[2]+0.7);machinesGB(inn,colls,m[0],m[1],F.ux,F.uz,5,B1Y);
    BK(inn,colls,F,R[0],R[0]+7,R[2],R[2]+3,B1Y,B1C,C_('#dfe6ec'));const t=F.W(R[0]+3.5,R[2]+3.05);sign(t[0],B1Y+2.6,t[1],F.vx,F.vz,2.4,0.45,'トイレ','Toilets','#0072bc','#ffffff',null,false);}
  {// south バスターミナル改札口: gates on its east side (b=5) facing the passage
    const R=SP;wallsV(inn,F,R[0],R[1],R[2],R[3],B1Y,B1C,WALL,[[1,-1e9,1e9]]);rectWalls(colls,F,R[0],R[1],R[2],R[3],B1Y,B1C,[[1,-1e9,1e9]]);
    const g0=-84,g1=-72;partition(inn,colls,F,R[0],R[3],g0-0.3,R[3],B1Y);partition(inn,colls,F,g1+0.3,R[3],R[1],R[3],B1Y);const g=F.W((g0+g1)/2,R[3]);gatesGB(inn,colls,g[0],g[1],F.ux,F.uz,g1-g0,B1Y);
    B(inn,F,g0-0.6,g1+0.6,R[3]-0.1,R[3]+0.1,B1Y+2.45,B1Y+2.75,BLUC);const s=F.W((g0+g1)/2,R[3]+0.15);sign(s[0],B1Y+3.0,s[1],F.vx,F.vz,4.6,0.8,'バスターミナル改札口','ブルーライン  Blue Line  B11','#27323b','#ffffff','#0072bc');
    const m=F.W(g0-6,PB[1]-0.7);machinesGB(inn,colls,m[0],m[1],F.ux,F.uz,5,B1Y);
    BK(inn,colls,F,R[0],R[0]+8,R[2],R[2]+3,B1Y,B1C,C_('#dfe6ec'));const t=F.W(R[0]+4,R[2]+3.05);sign(t[0],B1Y+2.6,t[1],F.vx,F.vz,2.4,0.45,'トイレ','Toilets','#0072bc','#ffffff',null,false);
    // the silver sea-turtle monument near the bus-terminal gate
    {const c=F.W(-66,PB[1]-2.2);out.obox(c[0],c[1],F.ux,F.uz,1.0,0.7,B1Y,B1Y+0.5,C_('#8e979e'));const m2=new THREE.Mesh(new THREE.SphereGeometry(0.8,16,10),new THREE.MeshStandardMaterial({color:'#d9dde2',metalness:0.8,roughness:0.25}));m2.scale.set(1.3,0.45,1.0);m2.position.set(c[0],B1Y+0.85,c[1]);scene.add(m2);}}
  // shops / signs in the passage
  for(const [a0,a1,col,t] of [[44,50,'#00a040','ファミリーマート']]){BK(inn,colls,F,a0,a1,NC[2],NC[2]+2.6,B1Y,B1Y+2.7,C_('#f4efe6'));B(inn,F,a0-0.1,a1+0.1,NC[2]-0.05,NC[2]+2.65,B1Y+2.7,B1Y+3.1,C_(col));const s=F.W((a0+a1)/2,NC[2]+2.66);sign(s[0],B1Y+2.9,s[1],F.vx,F.vz,4.4,0.4,t,'',col,'#ffffff',null,false);}
  {const s=F.W(NC[1]-0.03,-12);sign(s[0],B1Y+2.2,s[1],-F.ux,-F.uz,3.0,0.5,'カミオ連絡口A','Camio  (10:00–21:00)','#ffffff','#1b1f24','#e8902f',false);B(glass,F,NC[1]-0.05,NC[1],-14.5,-9.5,B1Y,B1Y+2.4,C_('#9fb7c6'));}
  for(const [a,t] of [[30,'出口1・2・3  京急線 →'],[-20,'← 出口6・7　出口1・2 →'],[-70,'↓ バスターミナル改札口'],[-118,'出口6・7 →']]){const c=F.W(a,9.5);sign(c[0],B1Y+3.05,c[1],F.ux,F.uz,4.4,0.6,t,'','#f2d33c','#1b1f24');}
  lights(F,PA[0],PA[1],PB[0],PB[1],B1C,6,9);lights(F,NC[0],NC[1],NC[2],NC[3],B1C,6,6);lights(F,NP[0],NP[1],NP[2],NP[3],B1C,6,6);lights(F,SP[0],SP[1],SP[2],SP[3],B1C,6,6);
  /* ---------- B1 → B2 stairs + escalators ---------- */
  for(const st of [stN,stS]){stairDir(inn,colls,F,st,sb,1,0,B1Y,B2T,2.6);escalatorVis(inn,stFrame(...F.W(st,eb),F.ang),0,0,1,B1Y,B2T,1.0);
    const h=holeP(st);for(const [p0,p1,q0,q1] of [[h[0],h[1],h[2]-0.06,h[2]],[h[0],h[1],h[3],h[3]+0.06],[h[1],h[1]+0.06,h[2],h[3]]]){B(inn,F,p0,p1,q0,q1,B1Y,B1Y+1.1,C_('#b8c0c6'));K(colls,F,p0,p1,q0,q1,B1Y,B1Y+1.1);}
    wallsV(inn,F,h[0],h[1],h[2],h[3],B2T+4.3,B1Y-0.4,WALL);}
  /* =================== B2 island platform =================== */
  {const s0=SK-60,s1=SK+60;const fl=blu.path.py(SK)-0.3;const HB0=pc-9,HB1=pc+9;
    roomShell(inn,F,-66,66,HB0,HB1,fl,B2T+4.3,C_('#dfe6ec'),null,null);slabWithHoles(inn,[],F,-66,66,HB0,HB1,B2T+4.6,0.3,[holeP(stN),holeP(stS)],CEIL,CEIL);
    inn.obox(...F.W(0,pc),F.ux,F.uz,66,9,fl-0.3,fl,C_('#6f6a63'),1);{const f=addPoly(flatPolyRect(F,-66,66,HB0,HB1),fl-0.4,fl);f.tag=0;}
    deckAlong(inn,colls,blu,s0,s1,()=>pc-pe,()=>pc+pe,[],{top:B2T,deck:'#d9d5cc'});
    const rp=[];for(const [s,o] of [[s0,pc-pe],[s1,pc-pe],[s1,pc+pe],[s0,pc+pe]]){const p=blu.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,B2T,blu,true,false);
    for(const sd of [-1,1])for(let s=s0+1;s<s1-1;s+=3){if(((s-s0)%6)>=2.9)continue;const p=blu.path.at(s+1.5,pc+sd*(pe-0.25));const ang=Math.atan2(p.tz,p.tx);inn.obox(p.x,p.z,p.tx,p.tz,1.0,0.12,B2T,B2T+1.3,C_('#cfd6dc'));inn.obox(p.x,p.z,p.tx,p.tz,1.0,0.13,B2T+1.0,B2T+1.12,BLUC);colls.push(addOBB(p.x,p.z,1.0,0.12,ang,B2T,B2T+1.3));}
    for(let s=s0+6;s<s1-4;s+=12){if([stN,stS].some(a=>s>SK+a-1.5&&s<SK+a+escP+1.5))continue;for(const o of [pc-2.0,pc+2.0]){const p=blu.path.at(s,o);inn.obox(p.x,p.z,p.tx,p.tz,0.25,0.25,B2T,B2T+4.3,C_('#e6ebef'));colls.push(addOBB(p.x,p.z,0.25,0.25,Math.atan2(p.tz,p.tx),B2T,B2T+4.3));}}
    const ST_B={name:'上大岡',kana:'かみおおおか',roma:'Kami-ōoka',code:'B',num:'11',col:'#0072bc',band:'#0072bc'};
    for(const s of [s0+9,SK+4,s1-12]){const q=blu.path.at(s,pc);nameBoard(fr,q.x,B2T+2.75,q.z,q.tx,q.tz,2.3,0.58,()=>({st:ST_B,nbT:{name:'弘明寺',num:'B12'},nbB:{name:'港南中央',num:'B10'}}));}
    for(const [sd,t1,t2] of [[1,'1番線','湘南台方面  for Shonandai'],[-1,'2番線','あざみ野方面  for Azamino']]){const q=blu.path.at(SK-24,pc+sd*1.4);sign(q.x,B2T+3.1,q.z,q.tx,q.tz,2.4,0.5,t1,t2,'#27323b','#ffffff','#0072bc',true);}
    rectWalls(colls,F,-66,66,HB0,HB1,fl,B2T+4.3);
    for(const sd of [-1,1]){const c=F.W(sd*(66+60),pc);inn.obox(c[0],c[1],F.ux,F.uz,60,9,fl-0.3,B2T+4.3,DARK,2|4|8);}
    lights(F,-66,66,pc-6,pc+6,B2T+4.3,6,6);}
  /* =================== zones =================== */
  {const Z=regZone(F,-146,58,-18,16,B2T-1.1-0.9,B1C+0.4,NAME,blu,B1Y,null);Z.floorC=B1Y;}
  /* =================== 京急 上大岡駅 (scenery) =================== */
  {const kg=new GB(),ki=new GB();const Z0=-7995,ZB=-7853.5,ZS=-7690;   // north end of the viaduct, north face of ゆめおおおか, south end of the station
    const ys=z=>z>ZS?lerp(RK,15.2,clamp((z-ZS)/(-7612-ZS),0,1)):RK;
    for(const t of KT)railsAlong(kg,clipZ(t,Z0,-7612),(x,z)=>ys(z)+0.04);
    // platforms (OSM polygons) with edge strips, canopies on the open part north of the building
    for(const P of KP){const n=P.length/2;const top=RK+1.1;const tris=tri2(P);for(const t of tris)kg.tri([P[t[0]*2],top,P[t[0]*2+1]],[P[t[1]*2],top,P[t[1]*2+1]],[P[t[2]*2],top,P[t[2]*2+1]],0,1,0,C_('#d6d0c2'));
      for(let i=0;i<n;i++){const j=(i+1)%n;const ax=P[i*2],az=P[i*2+1],bx=P[j*2],bz=P[j*2+1];const dx=bx-ax,dz=bz-az,l=Math.hypot(dx,dz);if(l<0.05)continue;const nx=dz/l,nz=-dx/l;
        kg.quad([ax,RK,az],[bx,RK,bz],[bx,top,bz],[ax,top,az],nx,0,nz,C_('#bdb6a8'));const ix=-nx*0.6,iz=-nz*0.6;kg.quad([ax+ix*0.5,top+0.012,az+iz*0.5],[bx+ix*0.5,top+0.012,bz+iz*0.5],[bx+ix,top+0.012,bz+iz],[ax+ix,top+0.012,az+iz],0,1,0,C_('#f2d33c'));}
      const b=addPoly(P,RK,top);b.tag=0;}
    const pcx=(i,z)=>{const P=KP[i];let xs=[];const n=P.length/2;for(let k=0;k<n;k++){const j=(k+1)%n;const az=P[k*2+1],bz=P[j*2+1];if((z-az)*(z-bz)<=0&&az!==bz)xs.push(P[k*2]+(P[j*2]-P[k*2])*(z-az)/(bz-az));}if(xs.length<2)return null;return [Math.min(...xs),Math.max(...xs)];};
    for(let i=0;i<2;i++){for(let z=ZB;z>-7932;z-=5){const r=pcx(i,z-2.5);if(!r)continue;const cx=(r[0]+r[1])/2,hw=(r[1]-r[0])/2+0.5;kg.obox(cx,z-2.5,0,1,2.55,hw,RK+5.3,RK+5.55,C_('#c4c9cd'),1|4|8|16|32);ki.obox(cx,z-2.5,0,1,2.55,hw-0.05,RK+5.15,RK+5.3,C_('#d9dcdc'),2);}
      for(let z=-7700;z>-7930;z-=16){const r=pcx(i,z);if(!r)continue;const cx=(r[0]+r[1])/2;kg.obox(cx,z,0,1,0.22,0.22,RK+1.1,z<ZB?RK+5.3:RKH,C_('#7f8a93'));addOBB(cx,z,0.22,0.22,0,RK+1.1,RKH);}
      // name boards (京急 style: white, KK number, red band) and track numbers
      const ST_K={name:'上大岡',kana:'かみおおおか',roma:'Kami-ōoka',code:'KK',num:'44',col:'#e5171f',band:'#1d50a2',top:'#e5171f'};
      for(const z of [-7720,-7790,-7850,-7905]){const r=pcx(i,z);if(!r)continue;nameBoard(fr,(r[0]+r[1])/2,RK+1.1+2.8,z,0,-1,2.3,0.58,()=>({st:ST_K,nbT:{name:'弘明寺',num:'KK43'},nbB:{name:'屏風浦',num:'KK45'}}));}
      const r=pcx(i,-7760);if(r){const cx=(r[0]+r[1])/2;const L=i===0?[['1','上り 横浜・品川方面'],['2','上り 横浜・品川方面']]:[['3','下り 横須賀中央・三崎口方面'],['4','下り 横須賀中央・三崎口方面']];
        sign(cx+(i===0?1.6:-1.6),RK+1.1+3.2,-7760,0,-1,2.2,0.5,L[i===0?0:1][0]+'番線',L[i===0?0:1][1],'#27323b','#ffffff','#e5171f',true);sign(cx+(i===0?-1.6:1.6),RK+1.1+3.2,-7760,0,-1,2.2,0.5,L[i===0?1:0][0]+'番線',L[i===0?1:0][1],'#27323b','#ffffff','#1d50a2',true);}}
    // station hall walls inside ゆめおおおか (between the station and the store floor) and ceiling lights
    const wx=[KT[3],KT[0]];const wallAt=(t,z,sd)=>xAtZ(t,z)+sd*4.6;
    for(const [t,sd] of [[KT[3],-1],[KT[0],1]]){for(let z=-7712;z>ZB+0.5;z-=6){const z1=Math.max(ZB,z-6);const xa=wallAt(t,z,sd),xb=wallAt(t,z1,sd);const dx=xb-xa,dz=z1-z,l=Math.hypot(dx,dz);
      ki.quad([xa,RK,z],[xb,RK,z1],[xb,RKH,z1],[xa,RKH,z],-dz/l*sd,0,dx/l*sd,C_('#e9e6df'));addOBB((xa+xb)/2,(z+z1)/2,l/2,0.15,Math.atan2(dz,dx),RK,RKH);}}
    // own floor and ceiling for the hall (the building's footprint is too ragged to rely on its slabs)
    for(let z=-7690;z>ZB+0.01;z-=6){const z1=Math.max(ZB,z-6);const xa0=wallAt(KT[3],z,-1),xb0=wallAt(KT[3],z1,-1),xa1=wallAt(KT[0],z,1),xb1=wallAt(KT[0],z1,1);
      ki.quad([xa0,RKH-0.02,z],[xa1,RKH-0.02,z],[xb1,RKH-0.02,z1],[xb0,RKH-0.02,z1],0,-1,0,C_('#e8e6e0'));kg.quad([xa0,RK+0.01,z],[xa1,RK+0.01,z],[xb1,RK+0.01,z1],[xb0,RK+0.01,z1],0,1,0,C_('#9a948a'));}
    {const lg=new GB();for(let z=-7712;z>ZB;z-=5)for(const x of [xAtZ(KT[3],z)+1.5,(xAtZ(KT[2],z)+xAtZ(KT[1],z))/2,xAtZ(KT[0],z)-1.5])lg.obox(x,z,0,1,1.2,0.12,RKH-0.06,RKH-0.01,C_('#ffffff'),2);scene.add(new THREE.Mesh(lg.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));}
    INDOOR.push({cx:9920,cz:-7782,c:1,s:0,hl:19,hw:70,y0:RK,y1:RKH});
    // viaduct north of the building: deck, parapets, and the space below closed in (shops under the tracks)
    {const zA=ZB,zB2=Z0;let vi=0;for(let z=zA;z>zB2;z-=6){vi++;const z1=Math.max(zB2,z-6);const zm=(z+z1)/2;const x0=xAtZ(KT[3],zm)-4.2,x1=xAtZ(KT[0],zm)+4.2;const c=[(x0+x1)/2,zm];const g=Math.min(demH(x0,zm),demH(x1,zm));
      kg.obox(c[0],c[1],1,0,(x1-x0)/2,(z-z1)/2+0.02,g-0.5,RK,C_('#cfc8bb'),1|4|8|16|32);addOBB(c[0],c[1],(x1-x0)/2,(z-z1)/2,0,g-0.5,RK);
      for(const x of [x0+0.15,x1-0.15]){kg.obox(x,zm,1,0,0.15,(z-z1)/2+0.02,RK,RK+1.3,C_('#c0c6cb'));addOBB(x,zm,0.15,(z-z1)/2,0,RK,RK+1.3);}
      if(vi%2===0)for(const x of [x0-0.02,x1+0.02])kg.obox(x,zm,1,0,0.03,2.0,g+0.4,g+2.9,C_('#3d4a55'),16|32);}}
    // south approach (tracks climb down to the ground south of the station)
    {for(let z=ZS+2;z<-7612;z+=6){const z1=Math.min(-7612,z+6);const zm=(z+z1)/2;const x0=xAtZ(KT[3],zm)-2.6,x1=Math.max(xAtZ(KT[1],zm),xAtZ(KT[0],zm))+2.6;const g=Math.min(demH(x0,zm),demH(x1,zm));const y=ys(zm);if(y-g<0.5)continue;
      kg.obox((x0+x1)/2,zm,1,0,(x1-x0)/2,(z1-z)/2+0.02,g-0.5,y-0.02,C_('#cfc8bb'),4|8|16|32|1);}}
    // 京急 signs at the street-level gates on the west face of ゆめおおおか
    for(const [x,z] of [[9879.7,-7800.5],[9877.3,-7762]])sign(x-0.25,9.4+4.2,z,-1,0,5.2,1.1,'京急線 上大岡駅','KEIKYU  Kami-ōoka  KK44  1F改札','#ffffff','#1b1f24','#e5171f',false);
    for(const [g,mat] of [[kg,MAT.top]])if(!g.empty){const m=new THREE.Mesh(g.geo(),mat);m.castShadow=true;m.receiveShadow=true;scene.add(m);}
    if(!ki.empty){const m=new THREE.Mesh(ki.geo(),UGMAT);scene.add(m);}
    addLabel('京急 上大岡駅','京浜急行本線 KK44',9920,RKH+40,-7790,'st','#e5171f',600,0.7);}
  for(const [g,mat] of [[gb,MAT.top],[out,MAT.top],[fr,MAT.top]])if(!g.empty){const m=new THREE.Mesh(g.geo(),mat);m.castShadow=g!==fr;m.receiveShadow=true;scene.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),UGMAT);scene.add(m);}
  flushAtlas();flushLights();
  if(!glass.empty){const m=new THREE.Mesh(glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
  {const c=F.W(0,9);addLabel('上大岡','ブルーライン B11・京急線',c[0],B1Y+2.9,c[1],'st','#0072bc',140,0.5);}
}
ST_CUSTOM[NAME]={lines:new Set(['blu']),build};
})();
