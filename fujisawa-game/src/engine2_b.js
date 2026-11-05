
/* ================= world build ================= */
const DYN=[];
let maskTex=null,maskData=null;
const NEAR_R=LITE?450:isTouch?650:900,FAR_KEEP=NEAR_R+380;
const EXCL=[];
const ZONES=[];   // underground station volumes (terrain ignored inside)
const INDOOR=[];  // rooms where the camera is kept inside
async function build(){
  initMats();initLines();
  setLoad('線路の高さを測っています…');await tick();
  for(const k in LINES){const l=LINES[k];railProfile(l);if(!l.mono)FIDX.add(l.path,(l.single?4:7)+14,{path:l.path,half:l.single?4:7,blend:8,sink:0.35});}
  prepareRoads();
  setLoad('空と遠景をつくっています…');await tick();
  buildSky();buildFarScenery();
  setLoad('地形をつくっています…');await tick();
  buildFarTerrain();buildWater();
  await tick();setLoad('線路を敷いています…');
  buildRails();
  await tick();setLoad('名所と駅を建てています…');
  buildLandmarks();buildStations();flushBatches();
  await tick();setLoad('遠くの街並みを並べています…');
  buildLOD();
  await tick();setLoad('時刻表を組んでいます…');
  buildTimetable();buildCars();buildLife();
  await tick();setLoad('地図を描いています…');
  bakeMap();
}
const ROADCH=new Map();
const RCOL={1:'#54585e',2:'#5a5e65',3:'#61656b',4:'#686b71',5:'#76797d',6:'#808386',7:'#b9b3a6',8:'#c4bba8'};
const chKey=(x,z)=>Math.floor((z-Z0)/CH)*CNX+Math.floor((x-X0)/CH);
const JUNC=new Map();const jkey=(x,z)=>Math.round(x/1.5)+','+Math.round(z/1.5);
function prepareRoads(){
  for(let ri=0;ri<ROADS.length;ri++){const r=ROADS[ri];if(r.c>6||(r.fl&3))continue;const p=r.pts,n=p.length/2;for(const e of [0,n-1]){const k=jkey(p[e*2],p[e*2+1]);let a=JUNC.get(k);if(!a)JUNC.set(k,a=[]);a.push(ri);}}
  for(let ri=0;ri<ROADS.length;ri++){const r=ROADS[ri];const p=r.pts;const n=p.length/2;
    const arr=[];for(let i=0;i<n;i++)arr.push([p[i*2],p[i*2+1]]);r.path=new Path(arr);
    if(r.fl&1){const a=demH(arr[0][0],arr[0][1]),b=demH(arr[n-1][0],arr[n-1][1]);r.path.prof=new Float32Array([a+0.25,b+0.25]);r.path.pstep=Math.max(r.path.L,0.01);BIDX.add(r.path,r.w,r);}
    const seen=new Set();for(let i=0;i<n;i++){const k=chKey(p[i*2],p[i*2+1]);if(!seen.has(k)){seen.add(k);let a=ROADCH.get(k);if(!a)ROADCH.set(k,a=[]);a.push(ri);}
      if(i<n-1){const k2=chKey((p[i*2]+p[i*2+2])/2,(p[i*2+1]+p[i*2+3])/2);if(!seen.has(k2)){seen.add(k2);let a=ROADCH.get(k2);if(!a)ROADCH.set(k2,a=[]);a.push(ri);}}}}
}
let skyMat,stars,sunGlow;
function buildSky(){
  skyMat=new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,fog:false,
    uniforms:{top:{value:new THREE.Color('#4f9fe6')},hor:{value:new THREE.Color('#d4ebf7')},bot:{value:new THREE.Color('#9cc7e0')},sunDir:{value:new THREE.Vector3(0,1,0)},sunCol:{value:new THREE.Color('#fff1c9')},glow:{value:1}},
    vertexShader:`varying vec3 vD;void main(){vD=normalize(position);gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}`,
    fragmentShader:`uniform vec3 top,hor,bot,sunCol,sunDir;uniform float glow;varying vec3 vD;
      void main(){float h=vD.y;vec3 c=h>0.0?mix(hor,top,pow(clamp(h*1.6,0.0,1.0),0.7)):mix(hor,bot,clamp(-h*6.0,0.0,1.0));
      float s=max(dot(normalize(vD),normalize(sunDir)),0.0);c+=sunCol*(pow(s,900.0)*2.5+pow(s,40.0)*0.25*glow+pow(s,6.0)*0.12*glow);
      gl_FragColor=vec4(c,1.0);
      #include <tonemapping_fragment>
      #include <colorspace_fragment>
      }`});
  const sky=new THREE.Mesh(new THREE.SphereGeometry(300000,32,16),skyMat);sky.renderOrder=-10;farScene.add(sky);DYN.push(()=>sky.position.copy(camera.position));
  const g=new THREE.BufferGeometry();const p=[];for(let i=0;i<1400;i++){const u=rand()*Math.PI*2,v=rand()*0.9+0.05;const r=280000;p.push(Math.cos(u)*Math.cos(Math.asin(v))*r,v*r,Math.sin(u)*Math.cos(Math.asin(v))*r);}
  g.setAttribute('position',new THREE.Float32BufferAttribute(p,3));
  stars=new THREE.Points(g,new THREE.PointsMaterial({color:0xffffff,size:2,sizeAttenuation:false,fog:false,transparent:true,opacity:0,depthWrite:false}));farScene.add(stars);
  DYN.push(()=>stars.position.copy(camera.position));
  sunGlow=new THREE.Mesh(new THREE.SphereGeometry(2600,16,10),new THREE.MeshBasicMaterial({color:'#fff3c0',fog:false}));farScene.add(sunGlow);
}
const FARMATS=[];
function farMat(){const m=new THREE.MeshLambertMaterial({color:'#ffffff',vertexColors:true,fog:false});FARMATS.push(m);return m;}
function buildFarScenery(){
  const fp=L(35.3606,138.7274);
  const prof=[];const R=17000,Hh=3776;for(let i=0;i<=48;i++){const t=i/48;const r=R*(1-t);const y=Hh*Math.pow(t,1.6)*0.985;prof.push(new THREE.Vector2(Math.max(r,420),y));}prof.push(new THREE.Vector2(0,Hh-40));
  const fg=new THREE.LatheGeometry(prof,72);const fc=[];const pp=fg.attributes.position;
  for(let i=0;i<pp.count;i++){const x=pp.getX(i),y=pp.getY(i),z=pp.getZ(i);const a=Math.atan2(z,x);const lim=Hh*(0.62+0.06*Math.sin(a*9)+0.04*Math.sin(a*23));const c=y>lim?new THREE.Color('#f7fbff'):new THREE.Color('#6f7fa8');fc.push(c.r,c.g,c.b);}
  fg.setAttribute('color',new THREE.Float32BufferAttribute(fc,3));fg.computeVertexNormals();
  const fuji=new THREE.Mesh(fg,farMat());fuji.position.set(fp[0],-20,fp[1]);farScene.add(fuji);
  const R2=[[35.233,139.021,1438,9000],[35.20,139.05,1200,8000],[35.30,139.06,1100,7000],[35.475,139.14,1673,12000],[35.441,139.231,1252,8000],[35.50,139.05,1500,12000],[34.86,138.95,1405,16000],[35.05,139.05,900,12000],[34.73,139.39,758,6500],[35.25,139.62,240,6000],[35.20,139.65,200,6000],[35.10,139.85,350,9000],[35.47,138.90,1700,14000]];
  for(const h of R2){const p=L(h[0],h[1]);const g=new THREE.SphereGeometry(1,32,10,0,Math.PI*2,0,Math.PI/2);const c=[];const d=Math.hypot(p[0],p[1]);for(let i=0;i<g.attributes.position.count;i++){const cc=new THREE.Color(d>30000?'#8696b8':'#87a08a');c.push(cc.r,cc.g,cc.b);}g.setAttribute('color',new THREE.Float32BufferAttribute(c,3));
    const m=new THREE.Mesh(g,farMat());m.scale.set(h[3],h[2],h[3]*0.75);m.position.set(p[0],-15,p[1]);farScene.add(m);}
  const shp=(pts)=>{const sh=new THREE.Shape();pts.forEach((p,i)=>i?sh.lineTo(p[0],-p[1]):sh.moveTo(p[0],-p[1]));return sh;};
  const cW=coastZ(WORLD.x0),cE=coastZ(WORLD.x1);
  const land=[[-120000,-120000],[-60000,cW+55000],[-30000,cW+7600],[-20000,cW+600],[WORLD.x0,cW]];
  for(let x=WORLD.x0;x<=WORLD.x1;x+=200)land.push([x,coastZ(x)]);
  land.push([WORLD.x1,cE],[WORLD.x1+3000,cE+9000],[WORLD.x1+6000,24000],[WORLD.x1+9000,6000],[WORLD.x1+12000,-2000],[120000,-2000],[120000,-120000]);
  const og=new THREE.ShapeGeometry(shp(land),1);og.rotateX(-Math.PI/2);
  const outer=new THREE.Mesh(og,new THREE.MeshLambertMaterial({color:'#93b07a',side:THREE.DoubleSide}));outer.position.y=-2;farScene.add(outer);
  const fsea=new THREE.Mesh(new THREE.PlaneGeometry(800000,800000).rotateX(-Math.PI/2),new THREE.MeshLambertMaterial({color:'#3a9ad3'}));fsea.position.y=-6;farScene.add(fsea);FARMATS.sea=fsea.material;
  const cg=[];for(let k=0;k<6;k++){const g=new THREE.IcosahedronGeometry(1,1);g.scale(rr(1,1.6),rr(0.5,0.8),rr(1,1.4));g.translate(rr(-1.6,1.6),rr(-0.2,0.3),rr(-1,1));cg.push(g);}
  const cm=new THREE.MeshLambertMaterial({color:'#ffffff',emissive:'#ffffff',emissiveIntensity:0.3,flatShading:true});
  const N=60;const clouds=new THREE.InstancedMesh(mergeGeos(cg),cm,N);const dm=new THREE.Object3D();const cl=[];
  for(let i=0;i<N;i++)cl.push({x:rr(X0-3000,X1+3000),z:rr(Z0-3000,Z1+3000),y:rr(1400,2300),s:rr(220,480),sp:rr(3,7)});
  clouds.frustumCulled=false;farScene.add(clouds);
  DYN.push((t,dt)=>{for(let i=0;i<N;i++){const c=cl[i];c.x+=c.sp*dt;if(c.x>X1+3000)c.x=X0-3000;dm.position.set(c.x,c.y,c.z);dm.scale.set(c.s,c.s*0.6,c.s);dm.updateMatrix();clouds.setMatrixAt(i,dm.matrix);}clouds.instanceMatrix.needsUpdate=true;});
  FARMATS.cloud=cm;
}
const LCCH={0:'#c2c4ae',1:'#3f86b3',2:'#4e8a44',3:'#8cc56a',4:'#aebf64',5:'#ead7a2',6:'#c3c2ba',7:'#cfba92',8:'#aeaca5',10:'#93b066',11:'#a9b597',13:'#79bb55'};
const LCCOL=[];for(let i=0;i<16;i++)LCCOL.push(new THREE.Color(LCCH[i]||LCCH[0]));
const DEEP=new THREE.Color('#2b6f93'),SAND=new THREE.Color('#e2d0a0'),ROCK=new THREE.Color('#9b8f7c'),BANK=new THREE.Color('#3d7598'),RURAL=new THREE.Color('#a3b986');
const _tc=new THREE.Color(),_c3=new THREE.Color();
function groundColorAt(k,x,z,h,slope){
  if(h<SEA+0.05){_tc.copy(SAND).lerp(DEEP,clamp((SEA+0.05-h)/7,0,1));return _tc;}
  if(k<0){_tc.copy(RURAL);if(slope>0.3)_tc.lerp(LCCOL[2],0.5);_tc.offsetHSL(0,0,(Math.sin(x*0.011+z*0.007))*0.04);return _tc;}
  const c=LCC8[k];_tc.copy(LCCOL[c]);
  if(c===1)_tc.copy(BANK);else if(c===0&&slope>0.35)_tc.lerp(LCCOL[2],0.45);
  if(slope>1.1&&c!==1)_tc.lerp(ROCK,0.5);
  if(c===4){const v=hashf((Math.floor(x/22)*73856093)^(Math.floor(z/30)*19349663));_tc.offsetHSL(v*0.04-0.02,0,v*0.08-0.04);}
  _tc.offsetHSL(0,0,(Math.sin(x*0.037+z*0.011)*Math.cos(z*0.029-x*0.007))*0.03);return _tc;
}
let farTerrain,terrainInfo;
function buildFarTerrain(){
  const W=WORLD.x1-WORLD.x0,D=WORLD.z1-WORLD.z0,step=isTouch?90:60,nx=Math.round(W/step),nz=Math.round(D/step);
  const geo=new THREE.PlaneGeometry(W,D,nx,nz);geo.rotateX(-Math.PI/2);geo.translate(WORLD.x0+W/2,0,WORLD.z0+D/2);
  const pos=geo.attributes.position,n=pos.count,col=new Float32Array(n*3);const mapCols=new Uint8ClampedArray(n*4);
  const H=new Float32Array(n);for(let i=0;i<n;i++){H[i]=demH(pos.getX(i),pos.getZ(i));pos.setY(i,H[i]-0.8);}
  for(let i=0;i<n;i++){const x=pos.getX(i),z=pos.getZ(i),h=H[i];const ix=i%(nx+1),iz=Math.floor(i/(nx+1));
    const hr=H[i+(ix<nx?1:0)],hd=H[i+(iz<nz?nx+1:0)];const slope=Math.max(Math.abs(hr-h),Math.abs(hd-h))/step;
    const k=cellK(x,z);const c=groundColorAt(k,x,z,h,slope);
    const li=clamp(Math.floor((x-X0)/40),0,META.lod[0]-1),lj=clamp(Math.floor((z-Z0)/40),0,META.lod[1]-1);const cov=LODC[lj*META.lod[0]+li]/255;
    if(cov>0)c.lerp(_c3.set('#a9a8a2'),Math.min(0.6,cov*0.8));
    if(k>=0&&LCC8[k]===1)c.copy(LCCOL[1]);
    col[i*3]=c.r;col[i*3+1]=c.g;col[i*3+2]=c.b;
    const sr=c.clone().convertLinearToSRGB();mapCols[i*4]=sr.r*255;mapCols[i*4+1]=sr.g*255;mapCols[i*4+2]=sr.b*255;mapCols[i*4+3]=255;
    if(h<SEA){const dd=clamp((SEA-h)/6,0,1);mapCols[i*4]=lerp(120,40,dd);mapCols[i*4+1]=lerp(190,120,dd);mapCols[i*4+2]=lerp(225,190,dd);}}
  geo.setAttribute('color',new THREE.BufferAttribute(col,3));geo.computeVertexNormals();
  maskData=new Uint8Array(CNX*CNZ);maskTex=new THREE.DataTexture(maskData,CNX,CNZ,THREE.RedFormat,THREE.UnsignedByteType);maskTex.magFilter=maskTex.minFilter=THREE.NearestFilter;maskTex.needsUpdate=true;
  const mat=new THREE.MeshLambertMaterial({vertexColors:true});
  mat.onBeforeCompile=sh=>{sh.uniforms.uMask={value:maskTex};
    sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nvarying vec2 vWP;').replace('#include <begin_vertex>','#include <begin_vertex>\nvWP=(modelMatrix*vec4(transformed,1.0)).xz;');
    sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nvarying vec2 vWP;uniform sampler2D uMask;').replace('#include <clipping_planes_fragment>',`#include <clipping_planes_fragment>
      vec2 mu=(vWP-vec2(${X0.toFixed(1)},${Z0.toFixed(1)}))/vec2(${(CNX*CH).toFixed(1)},${(CNZ*CH).toFixed(1)});
      if(texture2D(uMask,mu).r>0.5)discard;`);};
  farTerrain=new THREE.Mesh(geo,mat);scene.add(farTerrain);
  terrainInfo={nx,nz,step,mapCols};
}
function ribbonGeo(path,width,yFn,step=5,off=0,s0=0,s1=null){
  s1=s1??path.L;const n=Math.max(2,Math.ceil((s1-s0)/step)+1);const P=[],I=[];
  for(let i=0;i<n;i++){const s=s0+i/(n-1)*(s1-s0);const o=typeof off==='function'?off(s):off;const p=path.at(s,o);const nx=-p.tz,nz=p.tx;
    for(const sd of [-1,1]){const x=p.x+nx*width/2*sd,z=p.z+nz*width/2*sd;P.push(x,yFn(x,z,s),z);}
    if(i<n-1){const a=i*2;I.push(a,a+2,a+1,a+1,a+2,a+3);}}
  const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(P,3));g.setIndex(I);g.computeVertexNormals();return g;}
let seaMat,foam;
function buildWater(){
  seaMat=new THREE.MeshStandardMaterial({color:'#3a9ad3',roughness:0.25,metalness:0.1,transparent:true,opacity:0.86});
  const sea=new THREE.Mesh(new THREE.PlaneGeometry(26000,26000).rotateX(-Math.PI/2),seaMat);sea.position.y=SEA;sea.receiveShadow=true;scene.add(sea);
  DYN.push(()=>{sea.position.x=Math.round(camera.position.x/100)*100;sea.position.z=Math.round(camera.position.z/100)*100;});
  const fp=[];for(let x=WORLD.x0;x<=WORLD.x1;x+=10){const z=coastZ(x);if(z<WORLD.z1-50)fp.push([x,z+3]);}
  if(fp.length>2){foam=new THREE.Mesh(ribbonGeo(new Path(fp),5,()=>SEA+0.06,10),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:0.55,depthWrite:false}));scene.add(foam);
    DYN.push((t)=>{foam.position.z=Math.sin(t*0.6)*3-1;foam.material.opacity=0.3+0.3*(0.5+0.5*Math.sin(t*0.6+1.2));});}
}
function polyMat(c){return new THREE.MeshLambertMaterial({color:c,polygonOffset:true,polygonOffsetFactor:-2,polygonOffsetUnits:-6});}
/* rails: OSM tracks are drawn in detailed chunks; between station areas the line's own two tracks are drawn here */
function buildRails(){
  const gb=new GB();const bal=new THREE.Color('#8a8177'),sl=new THREE.Color('#5f5650'),rc=new THREE.Color('#cfd2d6');const poles=[];
  for(const k in LINES){const l=LINES[k];
    if(l.mono){buildMonoBeam(l);continue;}
    const P=l.path,n=Math.ceil(P.L/5);
    for(const side of (l.single?[0]:[-1,1])){
      for(let i=0;i<n;i++){const s0=i*5,s1=Math.min(P.L,s0+5);const sm=(s0+s1)/2;const pm=P.at(sm);if(isDetail(pm.x,pm.z)||P.flagAt(sm)===2)continue;
        const o0=side?P.laneOff(s0,side):0,o1=side?P.laneOff(s1,side):0;const a=P.at(s0,o0),b=P.at(s1,o1);const ya=P.py(s0),yb=P.py(s1);const nx=-a.tz,nz=a.tx;
        const quad=(w0,w1,dy,c)=>{gb.tri([a.x+nx*w0,ya+dy,a.z+nz*w0],[b.x+nx*w0,yb+dy,b.z+nz*w0],[b.x+nx*w1,yb+dy,b.z+nz*w1],0,1,0,c);gb.tri([a.x+nx*w0,ya+dy,a.z+nz*w0],[b.x+nx*w1,yb+dy,b.z+nz*w1],[a.x+nx*w1,ya+dy,a.z+nz*w1],0,1,0,c);};
        quad(-1.7,1.7,-0.02,bal);quad(-1.25,1.25,0.04,sl);quad(-0.62,-0.5,0.18,rc);quad(0.5,0.62,0.18,rc);}}
    const F=P.flags;for(let i=0;i<F.length;i++){if(F[i]!==1)continue;let j=i;while(j<F.length&&F[j]===1)j++;const s0=Math.max(0,i*10-5),s1=Math.min(P.L,j*10+5);
      let w=4;for(let q=i;q<j;q++){const o=P.offs[q];w=Math.max(w,Math.max(Math.abs(o[0]),Math.abs(o[1]))*2+4.2);}
      scene.add(Object.assign(new THREE.Mesh(ribbonGeo(P,w+1.2,(x,z,s)=>P.py(s)-1.0,4,0,s0,s1),M('#b3aea4',{side:THREE.DoubleSide})),{castShadow:true}));
      for(const sd of [-1,1])scene.add(new THREE.Mesh(ribbonGeo(P,0.3,(x,z,s)=>P.py(s)+0.9,4,sd*(w/2+0.4),s0,s1),M('#d9d6cf',{side:THREE.DoubleSide})));
      for(let s=s0+6;s<s1-3;s+=16){const p=P.at(s);const y=P.py(s),g=demH(p.x,p.z);if(y-g>1.5)cyl(0.8,y-g,'#c9c5bb',p.x,g-0.5,p.z,{col:true});}
      i=j-1;}
    for(let s=20;s<P.L;s+=50){if(P.flagAt(s)===2)continue;const p=P.at(s,Math.max(Math.abs(P.laneOff(s,1)),Math.abs(P.laneOff(s,-1)))+2.6);poles.push([p.x,P.py(s),p.z,Math.atan2(p.tz,p.tx)]);}
  }
  if(!gb.empty){const m=new THREE.Mesh(gb.geo(),MAT.road);m.receiveShadow=true;scene.add(m);}
  prepareTracks();
  const pg=mergeGeos([new THREE.CylinderGeometry(0.15,0.18,7,6).translate(0,3.5,0),new THREE.BoxGeometry(0.15,0.15,5).translate(0,6.6,-2.3)]);const pm=new THREE.InstancedMesh(pg,M('#7d858c'),poles.length);
  const dm=new THREE.Object3D();poles.forEach((p,i)=>{dm.position.set(p[0],p[1],p[2]);dm.rotation.y=-p[3];dm.updateMatrix();pm.setMatrixAt(i,dm.matrix);});pm.frustumCulled=false;pm.castShadow=true;scene.add(pm);
}
function buildMonoBeam(l){
  l.beamY=s=>l.path.py(s);
  const nn=Math.ceil(l.path.L/4);const P=[],I=[];
  for(let i=0;i<=nn;i++){const s=i/nn*l.path.L;const p=l.path.at(s);const y=l.beamY(s);const nx=-p.tz,nz=p.tx;
    for(const [a,b] of [[-1,0.4],[1,0.4],[1,-1.6],[-1,-1.6]])P.push(p.x+nx*a*0.9,y+b,p.z+nz*a*0.9);
    if(i<nn){const o=i*4;for(let f=0;f<4;f++){const a=o+f,b=o+(f+1)%4,c=a+4,d=b+4;I.push(a,c,b,b,c,d);}}}
  const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(P,3));g.setIndex(I);g.computeVertexNormals();
  const m=new THREE.Mesh(g,M('#9ea6ad',{side:THREE.DoubleSide}));m.castShadow=true;scene.add(m);
  for(let s=15;s<l.path.L;s+=30){if(l.path.flagAt(s)===2)continue;const p=l.path.at(s);const y=l.beamY(s);const px=p.x-p.tz*4.2,pz=p.z+p.tx*4.2;const g0=demH(px,pz);if(y-g0<3)continue;
    cyl(0.75,y-g0+0.6,'#c9ced3',px,g0-0.5,pz,{col:true});
    box(1.2,1.2,5.2,'#c9ced3',p.x-p.tz*2.2,y+0.2,p.z+p.tx*2.2,{ang:Math.atan2(p.tz,p.tx),col:false});}
}
const TRACKCH=new Map();
function lineYAt(x,z,r=12){const m=FIDX.nearest(x,z);if(!m)return null;let best=null;for(const v of m.values()){const d=Math.sqrt(v.d2);if(d<r&&(!best||d<best.d))best={d,y:v.data.path.py(v.s),fl:v.data.path.flagAt(v.s)};}return best;}
function prepareTracks(){
  for(let ti=0;ti<TRACKS.length;ti++){const t=TRACKS[ti];const p=t.pts,n=p.length/2;const ys=new Float32Array(n);
    let L0=0;const cum=[0];for(let i=1;i<n;i++){L0+=Math.hypot(p[i*2]-p[i*2-2],p[i*2+1]-p[i*2-1]);cum.push(L0);}
    const a=demH(p[0],p[1]),b=demH(p[n*2-2],p[n*2-1]);
    for(let i=0;i<n;i++){const x=p[i*2],z=p[i*2+1];const ly=lineYAt(x,z);if(ly)ys[i]=ly.y;else if(t.fl&1)ys[i]=Math.max(lerp(a,b,cum[i]/(L0||1)),demH(x,z)+(L0>150?8:1.5));else ys[i]=Math.max(demH(x,z),0.3)+0.1;}
    t.ys=ys;const seen=new Set();for(let i=0;i<n;i++){const k=chKey(p[i*2],p[i*2+1]);if(!seen.has(k)){seen.add(k);let arr=TRACKCH.get(k);if(!arr)TRACKCH.set(k,arr=[]);arr.push(ti);}
      if(i<n-1){const k2=chKey((p[i*2]+p[i*2+2])/2,(p[i*2+1]+p[i*2+3])/2);if(!seen.has(k2)){seen.add(k2);let arr=TRACKCH.get(k2);if(!arr)TRACKCH.set(k2,arr=[]);arr.push(ti);}}}}
}
function buildTracksInto(gb,ci,cj){const cx0=X0+ci*CH,cz0=Z0+cj*CH;const bal=new THREE.Color('#8a8177'),sl=new THREE.Color('#5f5650'),rc=new THREE.Color('#cfd2d6');
  for(const ti of TRACKCH.get(cj*CNX+ci)||[]){const t=TRACKS[ti];const p=t.pts,n=p.length/2;
    for(let i=0;i<n-1;i++){const ax=p[i*2],az=p[i*2+1],bx=p[i*2+2],bz=p[i*2+3];const mx=(ax+bx)/2,mz=(az+bz)/2;if(mx<cx0||mx>=cx0+CH||mz<cz0||mz>=cz0+CH)continue;
      const ly=lineYAt(mx,mz,6);if(ly&&ly.fl===2)continue;
      const dx=bx-ax,dz=bz-az,l=Math.hypot(dx,dz);if(l<0.01)continue;const nx=-dz/l,nz=dx/l;const ya=t.ys[i],yb=t.ys[i+1];
      const quad=(o0,o1,dy,c)=>{const A=[ax+nx*o0,ya+dy,az+nz*o0],B=[bx+nx*o0,yb+dy,bz+nz*o0],C=[bx+nx*o1,yb+dy,bz+nz*o1],D=[ax+nx*o1,ya+dy,az+nz*o1];gb.tri(A,B,C,0,1,0,c);gb.tri(A,C,D,0,1,0,c);};
      quad(-1.7,1.7,-0.02,bal);quad(-1.25,1.25,0.04,sl);quad(-0.62,-0.5,0.18,rc);quad(0.5,0.62,0.18,rc);}}}
