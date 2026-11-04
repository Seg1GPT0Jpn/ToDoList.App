
/* ================= hand-built stations: shared toolkit =================
   A station file registers ST_CUSTOM[name] = {lines:Set(lineKeys), build()} and may ask for
   - LINE_EXT[key]=metres      : extend a line before its first point (tunnel tails beyond a terminal)
   - PROF_ADJ.push({key,s0,s1,y,blend}) : force the rail level (platform depth) over a stretch
   - LANE_ADJ.push({key,s0,s1,lo,hi,blend}) : force the two track offsets (island platforms)
   - ST_S[key+'|'+name]=s      : where trains of that line stop
   - BLD_CLEAR.push([cx,cz,ang,hu,hv]) : no city building may stand here
   - HOLES (via terrainHole)   : the ground is cut open (stair wells to the street)
   The builders use the same GB / collider / zone machinery as the generic stations. */
const NO_LOOP=new Set(),BLD_SPLIT=[];const ST_CUSTOM={},LINE_EXT={},PROF_ADJ=[],LANE_ADJ=[],ST_S={},BLD_CLEAR=[],PLAT_CLEAR=[],HOLES=[];
const HOLE_U={value:Array.from({length:80},()=>new THREE.Vector4())},HOLE_N={value:0};
function terrainHole(cx,cz,ang,hu,hv){const i=HOLES.length;if(i>=40)return;HOLES.push([cx,cz,ang,hu,hv]);HOLE_U.value[i*2].set(cx,cz,Math.cos(ang),Math.sin(ang));HOLE_U.value[i*2+1].set(hu,hv,0,0);HOLE_N.value=HOLES.length;}
function inHole(x,z,m=0){for(const h of HOLES){const dx=x-h[0],dz=z-h[1],c=Math.cos(h[2]),s=Math.sin(h[2]);if(Math.abs(dx*c+dz*s)<h[3]+m&&Math.abs(-dx*s+dz*c)<h[4]+m)return true;}return false;}
/* patch a terrain material so fragments inside a hole are dropped */
function holePatch(sh){sh.uniforms.uHoles=HOLE_U;sh.uniforms.uHoleN=HOLE_N;
  if(!sh.vertexShader.includes('varying vec3 vPW'))sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nvarying vec3 vPW;').replace('#include <begin_vertex>','#include <begin_vertex>\nvPW=(modelMatrix*vec4(transformed,1.0)).xyz;');
  if(!sh.fragmentShader.includes('varying vec3 vPW'))sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nvarying vec3 vPW;');
  sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform vec4 uHoles[80];uniform int uHoleN;').replace('#include <clipping_planes_fragment>',`#include <clipping_planes_fragment>
    for(int i=0;i<40;i++){if(i>=uHoleN)break;vec4 a=uHoles[i*2];vec4 b=uHoles[i*2+1];vec2 d=vPW.xz-a.xy;if(abs(d.x*a.z+d.y*a.w)<b.x&&abs(-d.x*a.w+d.y*a.z)<b.y)discard;}`);}
TERRAINMAT.onBeforeCompile=holePatch;TERRAINMAT.customProgramCacheKey=()=>'terrainHoles';
function inClear(x,z,L=BLD_CLEAR){for(const b of L){const dx=x-b[0],dz=z-b[1],c=Math.cos(b[2]),s=Math.sin(b[2]);if(Math.abs(dx*c+dz*s)<b[3]&&Math.abs(-dx*s+dz*c)<b[4])return true;}return false;}
/* apply line tweaks: called from initLines / railProfile */
function extendLineData(k,D){const e=LINE_EXT[k];if(!e)return D;const p=D.pts;const a=p[0],b=p[1];const dx=a[0]-b[0],dz=a[1]-b[1],l=Math.hypot(dx,dz)||1;const n=Math.round(e/10);const ext=n*10;
  const pts=[[a[0]+dx/l*ext,a[1]+dz/l*ext],...p];const flags=D.flags?[...Array(n).fill(D.flags[0]),...D.flags]:D.flags;const offs=D.offs?[...Array(n).fill(D.offs[0]),...D.offs]:D.offs;
  for(const q of ST_SHIFT)if(q.key===k)q.by=ext;return {...D,pts,flags,offs};}
const ST_SHIFT=[];
function applyLaneAdj(l){for(const a of LANE_ADJ){if(a.key!==l.key)continue;const o=l.path.offs;if(!o)continue;
  for(let i=0;i<o.length;i++){const s=i*10;let w=0;if(s>=a.s0&&s<=a.s1)w=1;else if(s<a.s0)w=1-smooth(0,a.blend,a.s0-s);else w=1-smooth(0,a.blend,s-a.s1);if(w<=0)continue;o[i]=[lerp(o[i][0],a.lo,w),lerp(o[i][1],a.hi,w)];}}}
function applyProfAdj(l,out,step){for(const a of PROF_ADJ){if(a.key!==l.key)continue;for(let i=0;i<out.length;i++){const s=i*step;let w=0;if(s>=a.s0&&s<=a.s1)w=1;else if(s<a.s0)w=1-smooth(0,a.blend,a.s0-s);else w=1-smooth(0,a.blend,s-a.s1);if(w>0)out[i]=lerp(out[i],a.y,w);}}}
/* ---------- builder helpers ---------- */
/* frame: origin (ox,oz), unit axis (ux,uz); local (a,b) → world */
function stFrame(ox,oz,ang){const ux=Math.cos(ang),uz=Math.sin(ang),vx=-uz,vz=ux;return{ox,oz,ang,ux,uz,vx,vz,W:(a,b)=>[ox+ux*a+vx*b,oz+uz*a+vz*b]};}
/* hollow room (inner faces), with optional face mask; registers a zone + indoor box so terrain is ignored and the camera stays inside */
function roomShell(gb,F,a0,a1,b0,b1,y0,y1,colWall,colFloor,colCeil,opt={}){const c=F.W((a0+a1)/2,(b0+b1)/2);const hu=(a1-a0)/2,hv=(b1-b0)/2;
  if(opt.walls!==false)gb.obox(c[0],c[1],F.ux,F.uz,hu,hv,y0,y1,colWall,(opt.wallMask??(4|8|16|32)));
  if(colFloor)gb.obox(c[0],c[1],F.ux,F.uz,hu,hv,y0-0.3,y0,colFloor,1);if(colCeil)gb.obox(c[0],c[1],F.ux,F.uz,hu,hv,y1,y1+0.3,colCeil,2);return{c,hu,hv};}
function regZone(F,a0,a1,b0,b1,y0,y1,name,line,floorC,conc,indoor=true){const c=F.W((a0+a1)/2,(b0+b1)/2);const z={cx:c[0],cz:c[1],c:Math.cos(F.ang),s:Math.sin(F.ang),hl:(a1-a0)/2,hw:(b1-b0)/2,y0,y1,name,line,floorC,conc:conc||{cx:c[0],cz:c[1]}};ZONES.push(z);
  if(indoor)INDOOR.push({cx:c[0],cz:c[1],c:z.c,s:z.s,hl:z.hl,hw:z.hw,y0:y0,y1:y1,zone:true});return z;}
/* walls as colliders along the outline of a local rectangle (with gaps [[side,from,to],...]; sides 0:b0 1:b1 2:a0 3:a1) */
function rectWalls(colls,F,a0,a1,b0,b1,y0,y1,gaps=[]){const seg=(side,p0,p1)=>{const g=gaps.filter(q=>q[0]===side).sort((x,y)=>x[1]-y[1]);let a=p0;const out=[];for(const q of g){if(q[1]>a)out.push([a,q[1]]);a=Math.max(a,q[2]);}if(a<p1)out.push([a,p1]);return out;};
  for(const [s0,s1] of seg(0,a0,a1)){const c=F.W((s0+s1)/2,b0-0.15);colls.push(addOBB(c[0],c[1],(s1-s0)/2,0.15,F.ang,y0,y1));}
  for(const [s0,s1] of seg(1,a0,a1)){const c=F.W((s0+s1)/2,b1+0.15);colls.push(addOBB(c[0],c[1],(s1-s0)/2,0.15,F.ang,y0,y1));}
  for(const [s0,s1] of seg(2,b0,b1)){const c=F.W(a0-0.15,(s0+s1)/2);colls.push(addOBB(c[0],c[1],0.15,(s1-s0)/2,F.ang,y0,y1));}
  for(const [s0,s1] of seg(3,b0,b1)){const c=F.W(a1+0.15,(s0+s1)/2);colls.push(addOBB(c[0],c[1],0.15,(s1-s0)/2,F.ang,y0,y1));}}
/* floor slab with rectangular openings (local coords), as geometry + collider strips */
function slabWithHoles(gb,colls,F,a0,a1,b0,b1,y,th,holes,colTop,colBot){const vc=[b0,b1];for(const h of holes){vc.push(clamp(h[2],b0,b1),clamp(h[3],b0,b1));}vc.sort((p,q)=>p-q);
  for(let i=0;i<vc.length-1;i++){const v0=vc[i],v1=vc[i+1];if(v1-v0<0.05)continue;const vm=(v0+v1)/2;const hs=holes.filter(h=>vm>h[2]&&vm<h[3]).sort((p,q)=>p[0]-q[0]);let a=a0;
    const put=(p0,p1)=>{if(p1-p0<0.05)return;const c=F.W((p0+p1)/2,(v0+v1)/2);gb.obox(c[0],c[1],F.ux,F.uz,(p1-p0)/2,(v1-v0)/2,y-th,y,colTop,1);if(colBot)gb.obox(c[0],c[1],F.ux,F.uz,(p1-p0)/2,(v1-v0)/2,y-th,y,colBot,2);colls.push(addOBB(c[0],c[1],(p1-p0)/2,(v1-v0)/2,F.ang,y-th,y));};
    for(const h of hs){put(a,h[0]);a=Math.max(a,h[1]);}put(a,a1);}}
/* straight stair flight in a frame: from local (a,b) going +a (dir=1) or -a (dir=-1), top at yTop down to yBot; railings */
function flight(gb,colls,F,a,b,dir,yTop,yBot,w,col=COL.stair){const ang=F.ang+(dir>0?0:Math.PI);const p=F.W(a,b);const run=stairsGB(gb,colls,p[0],p[1],ang,yTop,yBot,w,col);
  for(const sd of [-1,1]){const q=F.W(a+dir*run/2,b+sd*(w/2+0.06));const len=Math.hypot(run,yTop-yBot);gb.obox(q[0],q[1],F.ux,F.uz,run/2,0.04,(yTop+yBot)/2+0.4,(yTop+yBot)/2+1.0,C_('#9aa3aa'),63);}
  return run;}
/* escalator look-alike beside a flight (visual only) */
function escalatorVis(gb,F,a,b,dir,yTop,yBot,w=1.2){const n=Math.ceil((yTop-yBot)/0.2);const run=(yTop-yBot)/Math.tan(30*Math.PI/180);
  for(let i=0;i<n;i++){const t=(i+0.5)/n;const q=F.W(a+dir*run*t,b);gb.obox(q[0],q[1],F.ux,F.uz,run/n/2+0.02,w/2,yBot+(yTop-yBot)*(1-t)-0.25,yBot+(yTop-yBot)*(1-t)-0.05,C_('#5a6168'),1|4|8);}
  for(const sd of [-1,1]){const q=F.W(a+dir*run/2,b+sd*(w/2+0.12));gb.obox(q[0],q[1],F.ux,F.uz,run/2,0.1,(yTop+yBot)/2,(yTop+yBot)/2+1.0,C_('#c9ced3'),63);}
  return run;}
/* hanging station sign (white board, line-colour band, name); returns sprite */
const SIGNC=new Map();
function signTex(text,sub,color,dark){const key=text+'|'+sub+'|'+color+dark;let t=SIGNC.get(key);if(t)return t;const cv=document.createElement('canvas');cv.width=512;cv.height=128;const x=cv.getContext('2d');
  x.fillStyle=dark?'#27323b':'#ffffff';x.fillRect(0,0,512,128);x.fillStyle=color;x.fillRect(0,104,512,24);x.fillStyle=dark?'#ffffff':'#1b1f24';x.textAlign='center';x.textBaseline='middle';
  x.font='800 56px "M PLUS Rounded 1c",sans-serif';x.fillText(text,256,sub?42:56);if(sub){x.font='500 22px "M PLUS Rounded 1c",sans-serif';x.fillStyle=dark?'#cfd8de':'#4b5a66';x.fillText(sub,256,86);}
  t=new THREE.CanvasTexture(cv);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=4;SIGNC.set(key,t);return t;}
function signBoard(x,y,z,ang,w,h,text,sub,color,dark=false,twoSided=true){const m=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:signTex(text,sub,color,dark),side:twoSided?THREE.DoubleSide:THREE.FrontSide}));
  m.position.set(x,y,z);m.rotation.y=-ang;scene.add(m);return m;}
/* register a platform polygon for boarding/alighting + collider */
function regPlatform(pts,top,line,under,coll=true){let b=null;if(coll){b=addPoly(pts,top-1.2,top);b.tag=0;b.plat=true;}let cx=0,cz=0;const n=pts.length/2;for(let i=0;i<n;i++){cx+=pts[i*2];cz+=pts[i*2+1];}cx/=n;cz/=n;
  const ux=pts[2]-pts[0],uz=pts[3]-pts[1],ul=Math.hypot(ux,uz);PLATBUILT.push({x:cx,z:cz,line,top,b:b||undefined,ux:ux/ul,uz:uz/ul,a0:-ul/2,a1:ul/2,w0:-Math.hypot(pts[6]-pts[0],pts[7]-pts[1])/2,w1:Math.hypot(pts[6]-pts[0],pts[7]-pts[1])/2,under:!!under,custom:true});return b;}
/* platform slab along a line with an outline in local frame (a along line); returns polygon */
function platformAlong(gb,colls,l,s0,s1,offIn,offOut,top,opt={}){const P=[];const N=Math.max(2,Math.ceil((s1-s0)/10));const L1=[],L2=[];
  for(let i=0;i<=N;i++){const s=s0+(s1-s0)*i/N;const a=l.path.at(s,offIn),b=l.path.at(s,offOut);L1.push([a.x,a.z]);L2.push([b.x,b.z]);}
  const poly=[...L1,...L2.reverse()];const flat=[];for(const p of poly)flat.push(p[0],p[1]);
  const y0=opt.y0??top-1.25;const edge=C_('#bdb6a8'),deck=C_(opt.deck||'#d6d0c2');
  for(let i=0;i<poly.length;i++){const p=poly[i],q=poly[(i+1)%poly.length];const dx=q[0]-p[0],dz=q[1]-p[1],len=Math.hypot(dx,dz);if(len<0.05)continue;gb.quad([p[0],y0,p[1]],[q[0],y0,q[1]],[q[0],top,q[1]],[p[0],top,p[1]],dz/len,0,-dx/len,edge);}
  const holes=opt.holes||[];const tris=tri2(flat);for(const t of tris){const A=[flat[t[0]*2],top,flat[t[0]*2+1]],B=[flat[t[1]*2],top,flat[t[1]*2+1]],C=[flat[t[2]*2],top,flat[t[2]*2+1]];gb.tri(A,B,C,0,1,0,deck);}
  // tactile strip and white edge line along the track side
  for(let i=0;i<N;i++){const sa=s0+(s1-s0)*i/N,sb=s0+(s1-s0)*(i+1)/N;const dir=Math.sign(offOut-offIn);for(const [o0,o1,c] of [[offIn+dir*0.08,offIn+dir*0.22,'#f4f4f2'],[offIn+dir*0.85,offIn+dir*1.15,'#f2d33c']]){const A=l.path.at(sa,o0),B=l.path.at(sb,o0),C2=l.path.at(sb,o1),D2=l.path.at(sa,o1);gb.quad([A.x,top+0.012,A.z],[B.x,top+0.012,B.z],[C2.x,top+0.012,C2.z],[D2.x,top+0.012,D2.z],0,1,0,C_(c));}}
  return flat;}
/* simple bench / vending / pillar dressing on a platform */
function platformDressing(gb,colls,l,s0,s1,offMid,top,opt={}){const every=opt.every||24;
  for(let s=s0+10;s<s1-8;s+=every){const p=l.path.at(s,offMid);const ang=Math.atan2(p.tz,p.tx);
    if(opt.pillars!==false){gb.obox(p.x,p.z,p.tx,p.tz,0.22,0.22,top,top+(opt.ph||3.6),C_(opt.pc||'#cfd4d8'));colls.push(addOBB(p.x,p.z,0.22,0.22,ang,top,top+3.6));}
    const q=l.path.at(s+5,offMid);gb.obox(q.x,q.z,q.tx,q.tz,0.9,0.22,top+0.42,top+0.48,C_('#2f6fb3'));gb.obox(q.x,q.z,q.tx,q.tz,0.9,0.03,top+0.48,top+0.85,C_('#2f6fb3'));gb.obox(q.x,q.z,q.tx,q.tz,0.05,0.05,top,top+0.42,C_('#8a949c'));}}

/* stair flight along any local axis direction (da,db) ∈ {(±1,0),(0,±1)} */
function stairDir(gb,colls,F,a,b,da,db,yTop,yBot,w,rail=true){const ang=F.ang+Math.atan2(db,da);const p=F.W(a,b);const run=stairsGB(gb,colls,p[0],p[1],ang,yTop,yBot,w);
  if(rail){const c=Math.cos(ang),s=Math.sin(ang);for(const sd of [-1,1]){const x=p[0]+c*run/2-s*sd*(w/2+0.05),z=p[1]+s*run/2+c*sd*(w/2+0.05);const yb=Math.min(yTop,yBot);
    gb.obox(x,z,c,s,run/2,0.03,(yTop+yBot)/2+0.85,(yTop+yBot)/2+0.95,C_('#a9b1b8'));}}return run;}
function flatPolyRect(F,a0,a1,b0,b1){const p=[F.W(a0,b0),F.W(a1,b0),F.W(a1,b1),F.W(a0,b1)];return [p[0][0],p[0][1],p[1][0],p[1][1],p[2][0],p[2][1],p[3][0],p[3][1]];}
/* glass partition with a collider */
function partition(gb,colls,F,a0,b0,a1,b1,y0,h=2.3,col='#bfd3df'){if(gb.glass)gb=gb.glass;const c=F.W((a0+a1)/2,(b0+b1)/2);const la=Math.abs(a1-a0)/2,lb=Math.abs(b1-b0)/2;gb.obox(c[0],c[1],F.ux,F.uz,Math.max(la,0.05),Math.max(lb,0.05),y0,y0+h,C_(col));colls.push(addOBB(c[0],c[1],Math.max(la,0.06),Math.max(lb,0.06),F.ang,y0,y0+h));}

/* interiors are lit by their own lamps: lambert + a self-lit share so ceilings are not tinted by the sky light */
const UGMAT=new THREE.MeshLambertMaterial({vertexColors:true,side:THREE.DoubleSide});
UGMAT.onBeforeCompile=sh=>{sh.fragmentShader=sh.fragmentShader.replace('#include <emissivemap_fragment>','#include <emissivemap_fragment>\n totalEmissiveRadiance+=diffuseColor.rgb*0.62;');};UGMAT.customProgramCacheKey=()=>'ugmat';
const GLASSMAT=new THREE.MeshLambertMaterial({vertexColors:true,transparent:true,opacity:0.32,side:THREE.DoubleSide,depthWrite:false});
