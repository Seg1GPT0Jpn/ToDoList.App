
/* ================= detailed places: PLATEAU buildings + GSI aerial photo =================
   fujisawa-places.wasm (gzip): 'FPL1', meta JSON, then per place a run of building records.
   Inside each place circle the OSM buildings are replaced by PLATEAU ones (real footprints and measured
   heights, LOD2 roofs/walls where the city published them), and the ground and roofs carry the aerial photo. */
const PLACES=[];const PLB=new Map();let PLACES_ON=false;
async function loadPlaces(){
  try{
    const res=await fetch('fujisawa-places.wasm');if(!res.ok)throw new Error(res.status);
    const buf=await new Response(res.body.pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();const dv=new DataView(buf);
    const ml=dv.getUint32(4,true);const meta=JSON.parse(new TextDecoder().decode(new Uint8Array(buf,8,ml)));let o=8+ml;while(o%4)o++;
    for(const P of meta.places){const end=o+P.bytes;P.b=[];
      while(o<end){const nf=dv.getUint16(o,true),st=dv.getUint8(o+2),use=dv.getUint16(o+3,true),h=dv.getUint16(o+5,true)/10,z0=dv.getInt16(o+7,true)/10;o+=9;
        const foot=new Float32Array(nf*2);let cx=0,cz=0;for(let i=0;i<nf;i++){foot[i*2]=dv.getInt16(o,true)/10+P.cx;foot[i*2+1]=dv.getInt16(o+2,true)/10+P.cz;o+=4;cx+=foot[i*2];cz+=foot[i*2+1];}
        const rd=()=>{const n=dv.getUint32(o,true);o+=4;const a=new Int16Array(buf.slice(o,o+n*18));o+=n*18;return a;};
        const roof=rd(),wall=rd();const b={foot,st,use,h,z0,roof,wall,cx:cx/nf,cz:cz/nf,P};P.b.push(b);
        const k=chKey(b.cx,b.cz);let a=PLB.get(k);if(!a)PLB.set(k,a=[]);a.push(b);}
      o=end;P.tex=null;PLACES.push(P);
      if(P.nb>0)EXCL.push([P.cx,P.cz,P.r]);}
    PLACES_ON=true;console.log('LOG places',PLACES.length,PLACES.reduce((a,p)=>a+p.nb,0));
  }catch(e){console.warn('places not loaded',e);}
}
const placeW=(x,z,P,pad=25)=>1-smooth(P.r-pad,P.r+45,Math.hypot(x-P.cx,z-P.cz));
function photoAt(x,z){let w=0;for(const P of PLACES){const d=Math.hypot(x-P.cx,z-P.cz);if(d<P.r+50)w=Math.max(w,placeW(x,z,P));}return w;}
function placesNearRect(x0,z0,x1,z1){return PLACES.filter(P=>{const dx=Math.max(x0-P.cx,0,P.cx-x1),dz=Math.max(z0-P.cz,0,P.cz-z1);return Math.hypot(dx,dz)<P.r+50;}).slice(0,2);}
function placeTex(P){if(!P.tex){P.tex=new THREE.TextureLoader().load(P.photo.file,t=>{P.texReady=1;for(const m of PHOTOMATS.values())m.userData.sync&&m.userData.sync();});P.tex.colorSpace=THREE.SRGBColorSpace;P.tex.anisotropy=8;P.tex.wrapS=P.tex.wrapT=THREE.ClampToEdgeWrapping;}return P.tex;}
/* Lambert material whose diffuse colour is replaced by the aerial photo inside the place circles (world-xz projection) */
const PHOTOMATS=new Map();
function photoMat(list,kind){const key=kind+list.map(p=>p.key).join('+');let m=PHOTOMATS.get(key);if(m)return m;
  m=new THREE.MeshLambertMaterial({vertexColors:true,...(kind==='road'?{polygonOffset:true,polygonOffsetFactor:-2,polygonOffsetUnits:-4}:{})});
  const U={};for(let i=0;i<2;i++){const P=list[i];U['ph'+i]={value:P?placeTex(P):null};U['pr'+i]={value:new THREE.Vector4(P?P.photo.x0:0,P?P.photo.z0:0,P?P.photo.size:1,0)};U['pc'+i]={value:new THREE.Vector3(P?P.cx:0,P?P.cz:0,P?P.r:0)};}
  m.userData.sync=()=>{for(let i=0;i<2;i++){const P=list[i];U['pr'+i].value.w=P&&P.texReady?1:0;}};m.userData.sync();
  const full=kind==='roof'?1:0;
  m.onBeforeCompile=sh=>{Object.assign(sh.uniforms,U);
    sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nvarying vec3 vPW;').replace('#include <begin_vertex>','#include <begin_vertex>\nvPW=(modelMatrix*vec4(transformed,1.0)).xyz;');
    sh.fragmentShader=sh.fragmentShader.replace('#include <common>',`#include <common>
      varying vec3 vPW;uniform sampler2D ph0,ph1;uniform vec4 pr0,pr1;uniform vec3 pc0,pc1;
      vec4 photoS(sampler2D t,vec4 r,vec3 c){if(r.w<0.5)return vec4(0.0);vec2 uv=(vPW.xz-r.xy)/r.z;if(uv.x<0.0||uv.y<0.0||uv.x>1.0||uv.y>1.0)return vec4(0.0);
        float w=${full?'1.0-smoothstep(c.z+20.0,c.z+50.0,distance(vPW.xz,c.xy))':'1.0-smoothstep(c.z-25.0,c.z+45.0,distance(vPW.xz,c.xy))'};return vec4(texture2D(t,vec2(uv.x,1.0-uv.y)).rgb,w);}`)
      .replace('#include <color_fragment>',`#include <color_fragment>
      {vec4 a=photoS(ph0,pr0,pc0);vec4 b=photoS(ph1,pr1,pc1);vec4 p=a.w>=b.w?a:b;diffuseColor.rgb=mix(diffuseColor.rgb,p.rgb*${kind==='roof'?'0.92':'0.86'},p.w);}`);};
  if(kind==='ground'){const ob=m.onBeforeCompile;m.onBeforeCompile=sh=>{ob(sh);holePatch(sh);};}
  m.customProgramCacheKey=()=>'photo'+kind;PHOTOMATS.set(key,m);return m;}
/* wall colours by PLATEAU usage code */
const USE_WALL={401:['#d9dde0','#c9d0d6','#e6e2da','#b9c3cb'],402:['#ece6da','#d8d2c6','#f0ebe2','#c7c2b8'],403:['#e9e2d4','#d7d0c2'],404:['#e3ddd2','#d1d4d6','#ede8df'],
  411:['#f4ede0','#efe6d2','#f8f5ee','#e8dcc5','#ece4d8','#dfe2e0','#e9e0d0','#d9cbb5'],412:['#efe9de','#e6e1d6','#dcd7cc','#f2ede4','#d7d4cc'],413:['#ece4d8','#e3dccf'],414:['#e8e2d6','#dedad0'],
  421:['#e6e3db','#d9d6cd'],422:['#ece4d2','#efe9dc','#e2dccb'],431:['#d0d3d4','#c4c8cb'],441:['#d6d8d4','#c9ccc8'],461:['#e6e2da']};
const OFFICE_USE=new Set([401,402,403,404,421,422,431,441,453]);
function addPlateau(b,G){
  const f=b.foot,n=f.length/2;if(n<3)return;if(BLD_CLEAR.length&&inClear(b.cx,b.cz))return;
  for(const q of PLATBUILT){if(q.b&&q.b.pts&&Math.abs(q.x-b.cx)<160&&Math.abs(q.z-b.cz)<160&&inPolyF(b.cx,b.cz,q.b.pts))return;} // kiosks and stair housings on a platform are drawn by the station
  let gmin=1e9;for(let i=0;i<n;i++)gmin=Math.min(gmin,demH(f[i*2],f[i*2+1]));if(gmin<-0.5)return;
  let H=b.h>0.5?b.h:(b.st?b.st*3:6);const base=gmin-0.15;const r=hashf(Math.round(b.cx*7+b.cz*13));
  const office=OFFICE_USE.has(b.use)||H>=12;const pal=USE_WALL[b.use]||(office?WALLO:WALLH);const wall=_col.set(pal[Math.floor(r*pal.length)]).clone();
  const area=Math.abs(polyArea(f));const sty=facadeStyle(b.use,H,area,r,0);const nst=b.st>0?b.st:Math.max(1,Math.round(H/(office?3.4:2.9)));const storeyH=clamp(H/nst,2.5,6);const bay=FAC_BAY[sty];
  const wallT=wall.clone().lerp(_col2.set('#ffffff'),0.45);
  // a building with a station floor inside (江ノ電藤沢 in ODAKYU 湘南 GATE): solid below and above, a glazed band for the station level
  const sp=BLD_SPLIT.find(q=>Math.hypot(q.x-b.cx,q.z-b.cz)<5);
  if(sp){const y1=base+H;facadeWalls(G.fac,f,base,sp.lo,wallT,sty,clamp((sp.lo-base)/Math.max(1,Math.round((sp.lo-base)/4)),2.8,5));facadeWalls(G.fac,f,sp.hi,y1,wallT,sty,storeyH);
    if(G.glass){for(let i=0;i<n;i++){const j=(i+1)%n;const ax=f[i*2],az=f[i*2+1],bx=f[j*2],bz=f[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)continue;G.glass.quad([ax,sp.lo,az],[bx,sp.lo,bz],[bx,sp.hi,bz],[ax,sp.hi,az],dz/len,0,-dx/len,_col.set('#9fc0d2'));}}
    if(b.roof.length){const R=b.roof;const P3=(a,i)=>[a[i]/10+b.P.cx,a[i+1]/10+base,a[i+2]/10+b.P.cz];for(let i=0;i<R.length;i+=9){const A=P3(R,i),B=P3(R,i+3),C=P3(R,i+6);G.proof.tri(A,B,C,0,1,0,_col.set('#ffffff'));}}
    else{const tris=tri2(f);for(const t of tris)G.proof.tri([f[t[0]*2],y1,f[t[0]*2+1]],[f[t[1]*2],y1,f[t[1]*2+1]],[f[t[2]*2],y1,f[t[2]*2+1]],0,1,0,_col.set('#ffffff'));}
    {const tris=tri2(f);const cc=_col2.set('#e9e6df');for(const t of tris){for(const y of [sp.lo,sp.hi])(y===sp.hi?G.inn:G.tops).tri([f[t[0]*2],y,f[t[0]*2+1]],[f[t[1]*2],y,f[t[1]*2+1]],[f[t[2]*2],y,f[t[2]*2+1]],0,y===sp.lo?1:-1,0,cc);}}
    G.colls.push(addPoly(f,base-0.3,sp.lo));G.colls.push(addPoly(f,sp.hi,y1));return;}
  // structures standing over a railway at track level (platform roofs, station buildings straddling the line) become canopies
  let ly=null;for(let i=0;i<n&&ly===null;i++){const q=lineYAt(f[i*2],f[i*2+1],5);if(q&&q.fl!==2)ly=q.y;}
  if(ly===null){const q=lineYAt(b.cx,b.cz,5);if(q&&q.fl!==2)ly=q.y;}
  if(ly!==null&&base+H>ly+3.5){const top=Math.max(base+H,ly+5.2);const y0=Math.max(top-0.6,ly+4.6);const tris=tri2(f);const tc=_col2.set('#b5b8bb');
    for(const t of tris){const A=[f[t[0]*2],top,f[t[0]*2+1]],B=[f[t[1]*2],top,f[t[1]*2+1]],C=[f[t[2]*2],top,f[t[2]*2+1]];G.proof.tri(A,B,C,0,1,0,_col.set('#ffffff'));G.tops.tri([A[0],y0,A[2]],[B[0],y0,B[2]],[C[0],y0,C[2]],0,-1,0,tc);}
    for(let i=0;i<n;i++){const j=(i+1)%n;const ax=f[i*2],az=f[i*2+1],bx=f[j*2],bz=f[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)continue;G.tops.quad([ax,y0,az],[bx,y0,bz],[bx,top,bz],[ax,top,az],dz/len,0,-dx/len,tc);}
    G.colls.push(addPoly(f,y0,top));return;}
  if(b.roof.length){
    const R=b.roof,W=b.wall;const P3=(a,i)=>[a[i]/10+b.P.cx,a[i+1]/10+base,a[i+2]/10+b.P.cz];
    for(let i=0;i<R.length;i+=9){const A=P3(R,i),B=P3(R,i+3),C=P3(R,i+6);let nx=(B[1]-A[1])*(C[2]-A[2])-(B[2]-A[2])*(C[1]-A[1]),ny=(B[2]-A[2])*(C[0]-A[0])-(B[0]-A[0])*(C[2]-A[2]),nz=(B[0]-A[0])*(C[1]-A[1])-(B[1]-A[1])*(C[0]-A[0]);
      const l=Math.hypot(nx,ny,nz)||1;nx/=l;ny/=l;nz/=l;if(ny<0){nx=-nx;ny=-ny;nz=-nz;}G.proof.tri(A,B,C,nx,ny,nz,_col.set('#ffffff'));}
    for(let i=0;i<W.length;i+=9){const A=P3(W,i),B=P3(W,i+3),C=P3(W,i+6);let nx=(B[1]-A[1])*(C[2]-A[2])-(B[2]-A[2])*(C[1]-A[1]),nz=(B[0]-A[0])*(C[1]-A[1])-(B[1]-A[1])*(C[0]-A[0]);
      const l=Math.hypot(nx,nz);if(l<1e-6)continue;nx/=l;nz/=l;const mx=(A[0]+B[0]+C[0])/3-b.cx,mz=(A[2]+B[2]+C[2])/3-b.cz;if(nx*mx+nz*mz<0){nx=-nx;nz=-nz;}
      const tx=nz,tz=-nx;const uv=p=>[sty*1000+(((p[0]*tx+p[2]*tz)/bay)%500+500)%500,(p[1]-base)/storeyH];G.fac.tri(A,B,C,nx,0,nz,wallT,uv(A),uv(B),uv(C));}
    if(!W.length)facadeWalls(G.fac,f,base,base+H,wallT,sty,storeyH);
  }else{
    const house=(sty===FAC.HOUSE_A||sty===FAC.HOUSE_B)&&area<320&&H<13;
    if(house){const rh=Math.min(2.4,H*0.3);const y1=base+H-rh;facadeWalls(G.fac,f,base,y1,wallT,sty,clamp((H-rh)/Math.max(1,Math.round((H-rh)/2.8)),2.5,3.4));roofOn(f,b.cx,b.cz,y1,0,r,G.proof);G.colls.push(addPoly(f,base-0.3,base+H));return;}
    const y1=base+H;facadeWalls(G.fac,f,base,y1,wallT,sty,storeyH);
    const tris=tri2(f);for(const t of tris)G.proof.tri([f[t[0]*2],y1,f[t[0]*2+1]],[f[t[1]*2],y1,f[t[1]*2+1]],[f[t[2]*2],y1,f[t[2]*2+1]],0,1,0,_col.set('#ffffff'));
    // parapet on taller flat roofs
    if(H>=7){for(let i=0;i<n;i++){const j=(i+1)%n;const ax=f[i*2],az=f[i*2+1],bx=f[j*2],bz=f[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.3)continue;const nx=dz/len,nz=-dx/len;
      G.tops.quad([ax,y1,az],[bx,y1,bz],[bx,y1+0.9,bz],[ax,y1+0.9,az],nx,0,nz,wall);G.tops.quad([ax-nx*0.2,y1+0.9,az-nz*0.2],[bx-nx*0.2,y1+0.9,bz-nz*0.2],[bx-nx*0.2,y1,bz-nz*0.2],[ax-nx*0.2,y1,az-nz*0.2],-nx,0,-nz,wall);
      G.tops.quad([ax,y1+0.9,az],[bx,y1+0.9,bz],[bx-nx*0.2,y1+0.9,bz-nz*0.2],[ax-nx*0.2,y1+0.9,az-nz*0.2],0,1,0,_col2.set('#c9c6bf'));}}
  }
  G.colls.push(addPoly(f,base-0.3,base+H));
}
function extrudeWalls(f,y0,y1,wb,wall,U,V){const n=f.length/2;let per=0;
  for(let i=0;i<n;i++){const j=(i+1)%n;const ax=f[i*2],az=f[i*2+1],bx=f[j*2],bz=f[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)continue;
    const nx=dz/len,nz=-dx/len;const u0=per/U,u1=(per+len)/U;const v1=(y1-y0)/V;per+=len;
    wb.tri([ax,y0,az],[bx,y0,bz],[bx,y1,bz],nx,0,nz,wall,[u0,0],[u1,0],[u1,v1]);wb.tri([ax,y0,az],[bx,y1,bz],[ax,y1,az],nx,0,nz,wall,[u0,0],[u1,v1],[u0,v1]);}}
