/* ================= three setup ================= */
const canvas=$('c');
const renderer=new THREE.WebGLRenderer({canvas,antialias:!isTouch,powerPreference:'high-performance',logarithmicDepthBuffer:true});
renderer.setPixelRatio(Math.min(devicePixelRatio,isTouch?1.5:1.75));
renderer.setSize(innerWidth,innerHeight);renderer.autoClear=false;
canvas.addEventListener('webglcontextlost',e=>{e.preventDefault();const l=document.getElementById('loading');if(l){l.hidden=false;l.querySelector('.msg').textContent='画面の描画が止まりました（端末のメモリ不足）。ページを再読み込みしてください';}});
renderer.shadowMap.enabled=!LITE;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.05;
const scene=new THREE.Scene(),farScene=new THREE.Scene();
const camera=new THREE.PerspectiveCamera(60,innerWidth/innerHeight,0.3,9000);
const farCam=new THREE.PerspectiveCamera(55,innerWidth/innerHeight,60,400000);
scene.fog=new THREE.Fog(0xcfe4f2,700,7000);farScene.fog=new THREE.Fog(0xcfe4f2,4000,120000);
const hemi=new THREE.HemisphereLight(0xcfe8ff,0x9a958a,1.1);scene.add(hemi);
const sun=new THREE.DirectionalLight(0xfff4e0,2.6);sun.castShadow=true;
sun.shadow.mapSize.set(isTouch?1024:4096,isTouch?1024:4096);
const SC=sun.shadow.camera;SC.left=SC.bottom=isTouch?-60:-130;SC.right=SC.top=isTouch?60:130;SC.near=1;SC.far=700;sun.shadow.bias=-0.0005;sun.shadow.normalBias=0.08;
scene.add(sun);scene.add(sun.target);
const farHemi=new THREE.HemisphereLight(0xcfe8ff,0x8a9a6a,1.2);farScene.add(farHemi);const farSun=new THREE.DirectionalLight(0xfff4e0,2.0);farScene.add(farSun);

const MC={};
function M(c,o){const k=c+(o?JSON.stringify(o):'');return MC[k]||(MC[k]=new THREE.MeshLambertMaterial({color:c,...(o||{})}));}
const BOX=new THREE.BoxGeometry(1,1,1).translate(0,0.5,0);
const CYL=new THREE.CylinderGeometry(0.5,0.5,1,16).translate(0,0.5,0);
const PYR=new THREE.ConeGeometry(0.7071,1,4,1).rotateY(Math.PI/4).translate(0,0.5,0);
const SPH=new THREE.SphereGeometry(0.5,20,14);
function mergeGeos(list){let tot=0;const ps=[],ns=[];for(let g of list){g=g.index?g.toNonIndexed():g;if(!g.attributes.normal)g.computeVertexNormals();ps.push(g.attributes.position.array);ns.push(g.attributes.normal.array);tot+=g.attributes.position.array.length;}
  const P=new Float32Array(tot),N=new Float32Array(tot);let o=0;for(let i=0;i<ps.length;i++){P.set(ps[i],o);N.set(ns[i],o);o+=ps[i].length;}
  const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.BufferAttribute(P,3));g.setAttribute('normal',new THREE.BufferAttribute(N,3));return g;}
const BATCH=new Map();
function bmesh(geo,mat,x,y,z,sx,sy,sz,ang,cast){const o=new THREE.Object3D();o.position.set(x,y,z);o.scale.set(sx,sy,sz);o.rotation.y=-ang;const k=mat.uuid+(cast?'c':'n');let b=BATCH.get(k);if(!b)BATCH.set(k,b={mat,cast,items:[]});b.items.push({o,geo});return o;}
function flushBatches(){for(const b of BATCH.values()){const gs=b.items.map(({o,geo})=>{o.updateMatrix();return geo.clone().applyMatrix4(o.matrix);});const m=new THREE.Mesh(mergeGeos(gs),b.mat);m.castShadow=b.cast;m.receiveShadow=true;scene.add(m);}BATCH.clear();}

/* ================= colliders: oriented boxes and real building polygons ================= */
const COLL=new Map();const CELL=20;
function regColl(b,x0,x1,z0,z1){const keys=[];for(let i=Math.floor(x0/CELL);i<=Math.floor(x1/CELL);i++)for(let j=Math.floor(z0/CELL);j<=Math.floor(z1/CELL);j++){const k=i*65536+j;let a=COLL.get(k);if(!a)COLL.set(k,a=[]);a.push(b);keys.push(k);}b.keys=keys;return b;}
function addOBB(cx,cz,hw,hd,ang,y0,y1,tag=0){const c=Math.cos(ang),s=Math.sin(ang);const b={t:0,cx,cz,hw,hd,c,s,y0,y1,tag};const r=Math.hypot(hw,hd);return regColl(b,cx-r,cx+r,cz-r,cz+r);}
function addPoly(pts,y0,y1){let x0=1e9,x1=-1e9,z0=1e9,z1=-1e9;for(let i=0;i<pts.length;i+=2){x0=Math.min(x0,pts[i]);x1=Math.max(x1,pts[i]);z0=Math.min(z0,pts[i+1]);z1=Math.max(z1,pts[i+1]);}
  return regColl({t:1,pts,y0,y1,tag:1,x0,x1,z0,z1},x0,x1,z0,z1);}
function removeColl(list){for(const b of list)for(const k of b.keys){const a=COLL.get(k);if(a){const i=a.indexOf(b);if(i>=0)a.splice(i,1);}}}
const collNear=(x,z)=>COLL.get(Math.floor(x/CELL)*65536+Math.floor(z/CELL))||[];
function inPolyF(x,z,p){let c=false;const n=p.length/2;for(let i=0,j=n-1;i<n;j=i++){const ax=p[i*2],az=p[i*2+1],bx=p[j*2],bz=p[j*2+1];if(((az>z)!==(bz>z))&&(x<(bx-ax)*(z-az)/(bz-az)+ax))c=!c;}return c;}
function insideColl(b,x,z,m=0.05){if(b.t===0){const dx=x-b.cx,dz=z-b.cz;const lx=dx*b.c+dz*b.s,lz=-dx*b.s+dz*b.c;return Math.abs(lx)<b.hw+m&&Math.abs(lz)<b.hd+m;}if(x<b.x0-m||x>b.x1+m||z<b.z0-m||z>b.z1+m)return false;return inPolyF(x,z,b.pts);}
function mesh(geo,mat,x,y,z,sx=1,sy=1,sz=1,ang=0,cast=true,parent=scene){const m=new THREE.Mesh(geo,mat);m.position.set(x,y,z);m.scale.set(sx,sy,sz);m.rotation.y=-ang;m.castShadow=cast;m.receiveShadow=true;parent.add(m);return m;}
function box(w,h,d,c,x,y,z,o={}){const r=bmesh(BOX,o.mat||M(c),x,y,z,w,h,d,o.ang||0,o.cast!==false);if(o.col!==false)addOBB(x,z,w/2,d/2,o.ang||0,y,y+h);return r;}
function cyl(r,h,c,x,y,z,o={}){const m=bmesh(o.geo||CYL,o.mat||M(c),x,y,z,r*2,h,r*2,0,o.cast!==false);if(o.col)addOBB(x,z,r*0.8,r*0.8,0,y,y+h);return m;}
function roof(w,h,d,c,x,y,z,ang=0){return bmesh(PYR,M(c),x,y,z,w,h,d,ang,true);}
const gy=(x,z)=>heightAt(x,z);
function stairsDown(x,z,ang,top,g0,w){const n=Math.ceil((top-g0)/0.28);const c=Math.cos(ang),s=Math.sin(ang);for(let i=0;i<n;i++){const d=(i+0.5)*0.42+0.2;const h=top-(i+1)*0.28;if(h<g0-0.2)break;box(0.44,Math.max(0.2,h-g0+0.6),w,'#c9c3b6',x+c*d,g0-0.6,z+s*d,{ang,cast:false});}}

/* ================= labels ================= */
const LABELS=[];
function makeLabel(text,sub,kind,color){
  const cv=document.createElement('canvas');const ctx=cv.getContext('2d');const F=`"M PLUS Rounded 1c","Hiragino Maru Gothic ProN",sans-serif`;
  ctx.font=`800 52px ${F}`;const tw=ctx.measureText(text).width;ctx.font=`500 22px ${F}`;const sw=sub?ctx.measureText(sub).width:0;
  const W=Math.ceil(Math.max(tw,sw)+64),H=sub?118:84;cv.width=W;cv.height=H+(kind==='lm'?22:0);
  const r=kind==='st'?10:H/2;
  ctx.fillStyle=kind==='st'?'#ffffff':'#10283a';ctx.strokeStyle=kind==='st'?'#10283a':'#ffffff';ctx.lineWidth=5;
  ctx.beginPath();ctx.roundRect(4,4,W-8,H-8,r);ctx.fill();ctx.stroke();
  if(kind==='st'){ctx.fillStyle=color;ctx.fillRect(10,H-24,W-20,10);}
  if(kind==='lm'){ctx.fillStyle='#10283a';ctx.beginPath();ctx.moveTo(W/2-14,H-6);ctx.lineTo(W/2+14,H-6);ctx.lineTo(W/2,H+18);ctx.fill();}
  ctx.textAlign='center';ctx.textBaseline='middle';
  ctx.fillStyle=kind==='st'?'#10283a':'#ffffff';ctx.font=`800 52px ${F}`;ctx.fillText(text,W/2,sub?(kind==='st'?42:44):H/2+2);
  if(sub){ctx.font=`500 22px ${F}`;ctx.fillStyle=kind==='st'?'#4b6475':'#ffd79a';ctx.fillText(sub,W/2,kind==='st'?78:86);}
  const tex=new THREE.CanvasTexture(cv);tex.colorSpace=THREE.SRGBColorSpace;tex.anisotropy=4;
  const sp=new THREE.Sprite(new THREE.SpriteMaterial({map:tex,depthWrite:false,fog:false,transparent:true}));
  sp.userData.ar=cv.width/cv.height;sp.center.set(0.5,kind==='lm'?0:0.5);sp.renderOrder=5;return sp;
}
function addLabel(text,sub,x,y,z,kind='lm',color='#ff9a3c',maxD=1500,size=1){if(LABELS.some(l=>l.text===text&&Math.hypot(l.sp.position.x-x,l.sp.position.z-z)<120))return null;const sp=makeLabel(text,sub,kind,color);sp.position.set(x,y,z);scene.add(sp);LABELS.push({sp,maxD,size,text});return sp;}
const LM=[];
function landmark(name,en,x,z,r,opt={}){LM.push({name,en,x,z,r,...opt});}

/* ================= textures / materials ================= */
function windowTex(cols,rows,lit,glass='#2f4a63'){
  const S=256,a=document.createElement('canvas'),b=document.createElement('canvas');a.width=b.width=S;a.height=b.height=S;
  const x=a.getContext('2d'),y=b.getContext('2d');x.fillStyle='#ffffff';x.fillRect(0,0,S,S);y.fillStyle='#000';y.fillRect(0,0,S,S);
  const cw=S/cols,ch=S/rows;
  for(let i=0;i<cols;i++)for(let j=0;j<rows;j++){const px=i*cw+cw*.16,py=j*ch+ch*.24,w=cw*.68,h=ch*.5;
    x.fillStyle=glass;x.fillRect(px,py,w,h);x.fillStyle='rgba(255,255,255,.22)';x.fillRect(px,py,w*.35,h);x.fillStyle='rgba(0,0,0,.12)';x.fillRect(i*cw,j*ch+ch*.9,cw,ch*.1);
    if(rand()<lit){y.fillStyle=pick(['#ffd889','#ffe7b0','#fff2d6','#ffc76a']);y.fillRect(px,py,w,h);}}
  const m=new THREE.CanvasTexture(a),e=new THREE.CanvasTexture(b);m.colorSpace=e.colorSpace=THREE.SRGBColorSpace;
  m.wrapS=m.wrapT=e.wrapS=e.wrapT=THREE.RepeatWrapping;m.anisotropy=e.anisotropy=4;return{m,e};
}
const WINMATS=[];
/* walls carry their own metre-based UVs (u = distance along the outline, v = height) */
function wallMat(lit,cols,rows){const t=windowTex(cols,rows,lit);const m=new THREE.MeshLambertMaterial({color:0xffffff,map:t.m,emissiveMap:t.e,emissive:0xffffff,emissiveIntensity:0,vertexColors:true});WINMATS.push(m);return m;}
/* boxes for hand-built landmarks: UVs from world-scaled position */
function boxWallMat(cellW,cellH,lit,cols=8,rows=8){const t=windowTex(cols,rows,lit);
  const m=new THREE.MeshLambertMaterial({color:0xffffff,map:t.m,emissiveMap:t.e,emissive:0xffffff,emissiveIntensity:0});
  m.onBeforeCompile=sh=>{sh.vertexShader=sh.vertexShader.replace('#include <uv_vertex>',`#include <uv_vertex>
    {vec3 sc=vec3(length(modelMatrix[0].xyz),length(modelMatrix[1].xyz),length(modelMatrix[2].xyz));
    vec2 wu=abs(normal.x)>0.5?vec2(position.z*sc.z,position.y*sc.y):vec2(position.x*sc.x,position.y*sc.y);
    wu/=vec2(${(cellW*cols).toFixed(2)},${(cellH*rows).toFixed(2)});vMapUv=wu;
    #ifdef USE_EMISSIVEMAP
    vEmissiveMapUv=wu;
    #endif
    }`);};m.customProgramCacheKey=()=>'bw'+cellW;WINMATS.push(m);return m;}
const MAT={};
const CELLH={w:2.7,h:2.9,cols:6,rows:6},CELLO={w:3.4,h:3.2,cols:8,rows:8};
function initMats(){
  MAT.top=new THREE.MeshLambertMaterial({color:0xffffff,vertexColors:true});
  MAT.wallH=wallMat(0.5,CELLH.cols,CELLH.rows);MAT.wallO=wallMat(0.5,CELLO.cols,CELLO.rows);
  MAT.green=new THREE.MeshLambertMaterial({color:0xeef4f2,transparent:true,opacity:0.8,side:THREE.DoubleSide});
  MAT.crown=new THREE.MeshLambertMaterial({color:0xffffff,flatShading:true});MAT.crownV=new THREE.MeshLambertMaterial({color:0xffffff,vertexColors:true});MAT.trunk=M('#6b4f36');
  MAT.road=new THREE.MeshLambertMaterial({vertexColors:true,polygonOffset:true,polygonOffsetFactor:-2,polygonOffsetUnits:-4});MAT.road.onBeforeCompile=sh=>detailPatch(sh,0.045,0.33,0.85);MAT.road.customProgramCacheKey=()=>'roadDet';
  MAT.water=new THREE.MeshStandardMaterial({color:'#4b97c4',roughness:0.25,metalness:0.05,transparent:true,opacity:0.88,polygonOffset:true,polygonOffsetFactor:-1,polygonOffsetUnits:-2});
  MAT.mid=boxWallMat(3.4,3.0,0.55);
}
const winTrainMat=new THREE.MeshLambertMaterial({color:'#2a3a48',emissive:'#ffe2a0',emissiveIntensity:0});

