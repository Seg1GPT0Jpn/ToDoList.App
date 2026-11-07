
/* ================= 神奈川県全域: streamed straight from the GSI tile servers (CORS-enabled) =================
   Outside the hand-made Fujisawa world the ground is built on the fly:
   - far layer : zoom-11 tiles over all of Kanagawa, relief from dem_png z11, aerial photo from z13 (≈15 m/px) — loaded once
   - near layer: zoom-14 tiles (≈2 km) around the player, relief from dem_png z14, photo from z16 (≈2 m/px),
                 and the buildings of the 電子国土基本図 vector tiles (z16) extruded by kind (普通 / 堅ろう / 高層)
   Data: 地理院タイル（国土地理院） — 標高タイル, シームレス空中写真, 地理院地図Vector. */
const KANA={lat0:35.12,lat1:35.69,lon0:138.90,lon1:139.82};
const KB={x0:(KANA.lon0-LON0)*MX,x1:(KANA.lon1-LON0)*MX,z0:-(KANA.lat1-LAT0)*MZ,z1:-(KANA.lat0-LAT0)*MZ};
const GSI='https://cyberjapandata.gsi.go.jp/xyz/';
const t2lon=(x,z)=>x/2**z*360-180,t2lat=(y,z)=>{const n=Math.PI-2*Math.PI*y/2**z;return 180/Math.PI*Math.atan(0.5*(Math.exp(n)-Math.exp(-n)));};
const lon2t=(lon,z)=>(lon+180)/360*2**z,lat2t=(lat,z)=>{const r=lat*Math.PI/180;return(1-Math.log(Math.tan(r)+1/Math.cos(r))/Math.PI)/2*2**z;};
const g2ll=(x,z)=>[LAT0-z/MZ,LON0+x/MX];
function loadImg(url){return new Promise(res=>{const im=new Image();im.crossOrigin='anonymous';im.onload=()=>res(im);im.onerror=()=>res(null);im.src=url;});}
async function demTile(z,x,y){const im=await loadImg(`${GSI}dem_png/${z}/${x}/${y}.png`);const H=new Float32Array(256*256);if(!im)return H;
  const c=document.createElement('canvas');c.width=c.height=256;const g=c.getContext('2d');g.drawImage(im,0,0);const d=g.getImageData(0,0,256,256).data;
  for(let i=0;i<65536;i++){const r=d[i*4],gg=d[i*4+1],b=d[i*4+2];if(r===128&&gg===0&&b===0){H[i]=-2;continue;}let v=r*65536+gg*256+b;if(v>=8388608)v-=16777216;H[i]=v*0.01;}return H;}
async function photoMosaic(z,x0,y0,n,px=256){const c=document.createElement('canvas');c.width=c.height=n*px;const g=c.getContext('2d');g.fillStyle='#2c5a74';g.fillRect(0,0,c.width,c.height); // open sea has no photo tiles
  await Promise.all([...Array(n*n)].map(async(_,k)=>{const i=k%n,j=Math.floor(k/n);const im=await loadImg(`${GSI}seamlessphoto/${z}/${x0+i}/${y0+j}.jpg`);if(im)g.drawImage(im,i*px,j*px,px,px);}));
  const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=8;return t;}
/* material: the photo is laid on by the tile's own (lon,lat) → uv; the hand-made world rectangle is cut out */
function regionMat(tex,far){const m=new THREE.MeshLambertMaterial({map:tex,fog:true});
  m.onBeforeCompile=sh=>{sh.uniforms.uW={value:new THREE.Vector4(WORLD.x0+60,WORLD.z0+60,WORLD.x1-60,WORLD.z1-60)};
    sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nvarying vec2 vRW;').replace('#include <begin_vertex>','#include <begin_vertex>\nvRW=(modelMatrix*vec4(transformed,1.0)).xz;');
    sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nvarying vec2 vRW;uniform vec4 uW;').replace('#include <clipping_planes_fragment>',far?'#include <clipping_planes_fragment>':'#include <clipping_planes_fragment>\nif(vRW.x>uW.x&&vRW.x<uW.z&&vRW.y>uW.y&&vRW.y<uW.w)discard;')
      .replace('#include <map_fragment>','#include <map_fragment>\ndiffuseColor.rgb*=0.88;');};
  m.customProgramCacheKey=()=>'region'+(far?'f':'n');return m;}
/* grid mesh of one slippy tile: vertices at exact lat/lon, heights from the DEM, uv = position in the tile */
function tileMesh(z,x,y,H,N,tex,far){const P=[],U=[],I=[];
  for(let j=0;j<=N;j++)for(let i=0;i<=N;i++){const lon=t2lon(x+i/N,z),lat=t2lat(y+j/N,z);const gx=(lon-LON0)*MX,gz=-(lat-LAT0)*MZ;
    const hi=Math.min(255,Math.round(i/N*255)),hj=Math.min(255,Math.round(j/N*255));const h=H[hj*256+hi];P.push(gx,(h<-1?-3:h)-(far?6:0.6),gz);U.push(i/N,1-j/N);}
  for(let j=0;j<N;j++)for(let i=0;i<N;i++){const a=j*(N+1)+i;I.push(a,a+N+1,a+1,a+1,a+N+1,a+N+2);}
  const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(P,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(U,2));g.setIndex(I);g.computeVertexNormals();
  const m=new THREE.Mesh(g,regionMat(tex,far));m.receiveShadow=!far;return m;}
/* ---------- minimal Mapbox Vector Tile reader (only what the building layer needs) ---------- */
function mvtBuildings(buf){const u8=new Uint8Array(buf);let p=0;const out=[];
  const varint=()=>{let r=0,s=0,b;do{b=u8[p++];r+=(b&0x7f)*2**s;s+=7;}while(b&0x80);return r;};
  const skip=w=>{if(w===0)varint();else if(w===1)p+=8;else if(w===2){const l=varint();p+=l;}else if(w===5)p+=4;};
  while(p<u8.length){const tag=varint();const f=tag>>>3,w=tag&7;if(f!==3||w!==2){skip(w);continue;}const len=varint();const end=p+len;
    let name='',extent=4096;const keys=[],vals=[],feats=[];
    while(p<end){const t2=varint();const f2=t2>>>3,w2=t2&7;
      if(f2===1&&w2===2){const l=varint();name=new TextDecoder().decode(u8.subarray(p,p+l));p+=l;}
      else if(f2===3&&w2===2){const l=varint();keys.push(new TextDecoder().decode(u8.subarray(p,p+l)));p+=l;}
      else if(f2===4&&w2===2){const l=varint();const e2=p+l;let v=null;while(p<e2){const t3=varint();const f3=t3>>>3,w3=t3&7;if(f3===1&&w3===2){const l3=varint();v=new TextDecoder().decode(u8.subarray(p,p+l3));p+=l3;}else if((f3===4||f3===5||f3===6)&&w3===0){v=varint();}else skip(w3);}vals.push(v);}
      else if(f2===5&&w2===0)extent=varint();
      else if(f2===2&&w2===2){const l=varint();feats.push([p,p+l]);p+=l;}
      else skip(w2);}
    p=end;if(name!=='building')continue;
    for(const [a,b] of feats){let q=p;p=a;let type=0,tags=[],geom=[];
      while(p<b){const t3=varint();const f3=t3>>>3,w3=t3&7;
        if(f3===2&&w3===2){const l=varint();const e=p+l;while(p<e)tags.push(varint());}
        else if(f3===3&&w3===0)type=varint();
        else if(f3===4&&w3===2){const l=varint();const e=p+l;while(p<e)geom.push(varint());}
        else skip(w3);}
      p=q;if(type!==3)continue;let code=0;for(let i=0;i<tags.length;i+=2)if(keys[tags[i]]==='ftCode')code=+vals[tags[i+1]];
      const rings=[];let cx=0,cy=0,ring=null;for(let i=0;i<geom.length;){const cmd=geom[i]&7,cnt=geom[i]>>3;i++;
        if(cmd===7){if(ring&&ring.length>2)rings.push(ring);ring=null;continue;}
        for(let k=0;k<cnt;k++){const dx=geom[i++],dy=geom[i++];cx+=(dx>>>1)^-(dx&1);cy+=(dy>>>1)^-(dy&1);if(cmd===1){ring=[[cx,cy]];}else ring.push([cx,cy]);}}
      let got=false;for(const r of rings){let s2=0;for(let i=0;i<r.length;i++){const j=(i+1)%r.length;s2+=r[i][0]*r[j][1]-r[j][0]*r[i][1];}if(s2>0){out.push({code,ring:r,extent});got=true;}}  // exterior rings (clockwise on screen)
      if(!got&&rings.length)out.push({code,ring:rings[0],extent});}
    break;}
  return out;}
/* ---------- the two layers ---------- */
const REGON={value:0};const REG={far:new Map(),near:new Map(),dem:new Map(),busy:0,started:false};
function regionH(x,z){const [lat,lon]=g2ll(x,z);
  for(const zz of [14,11]){const fx=lon2t(lon,zz),fy=lat2t(lat,zz);const key=zz+'/'+Math.floor(fx)+'/'+Math.floor(fy);const H=REG.dem.get(key);if(!H)continue;
    const u=(fx-Math.floor(fx))*255,v=(fy-Math.floor(fy))*255;const i=Math.min(254,u|0),j=Math.min(254,v|0),a=u-i,b=v-j;
    const h=(H[j*256+i]*(1-a)+H[j*256+i+1]*a)*(1-b)+(H[(j+1)*256+i]*(1-a)+H[(j+1)*256+i+1]*a)*b;return h<-1?-3:h;}
  return -3;}
const inWorld=(x,z,m=0)=>x>WORLD.x0+m&&x<WORLD.x1-m&&z>WORLD.z0+m&&z<WORLD.z1-m;
async function loadFarTile(x,y){const key=x+'/'+y;if(REG.far.has(key))return;REG.far.set(key,null);
  const H=await demTile(11,x,y);REG.dem.set('11/'+key,H);const tex=await photoMosaic(13,x*4,y*4,4);const m=tileMesh(11,x,y,H,48,tex,true);m.position.y=5.5;m.renderOrder=-5;farScene.add(m);REG.far.set(key,m);}
function startRegion(){if(REG.started)return;REG.started=true;
  const x0=Math.floor(lon2t(KANA.lon0,11)),x1=Math.floor(lon2t(KANA.lon1,11)),y0=Math.floor(lat2t(KANA.lat1,11)),y1=Math.floor(lat2t(KANA.lat0,11));
  (async()=>{const jobs=[];for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)jobs.push([x,y]);const px=P.x,pz=P.z;jobs.sort((a,b)=>{const c=t=>{const lo=t2lon(t[0]+0.5,11),la=t2lat(t[1]+0.5,11);return Math.hypot((lo-LON0)*MX-px,-(la-LAT0)*MZ-pz);};return c(a)-c(b);});
    let n=0;for(const [x,y] of jobs){await loadFarTile(x,y);if(++n===6)REGON.value=1;}REGON.value=1;console.log('LOG region far tiles',REG.far.size);})();}
const BLD_H={3101:[5.5,8],3102:[9,22],3103:[30,60],3111:[3,4.5],3112:[4,7]};
async function loadNearTile(x,y,withB){const key=x+'/'+y;const ex=REG.near.get(key);if(ex&&(ex.b||!withB))return;if(ex&&ex.loading)return;
  const rec=ex||{loading:true,grp:null,b:false};REG.near.set(key,rec);rec.loading=true;
  if(!rec.grp){const H=await demTile(14,x,y);REG.dem.set('14/'+key,H);const tex=await photoMosaic(16,x*4,y*4,4);rec.tex=tex;rec.grp=new THREE.Group();rec.grp.add(tileMesh(14,x,y,H,isTouch?40:64,tex,false));scene.add(rec.grp);}
  if(withB&&!rec.b){rec.b=true;const fac=new GB(),roof=new GB(),cols=[];
    await Promise.all([...Array(16)].map(async(_,k)=>{const bx=x*4+k%4,by=y*4+Math.floor(k/4);let buf=null;try{const r=await fetch(`${GSI}experimental_bvmap/16/${bx}/${by}.pbf`);if(r.ok)buf=await r.arrayBuffer();}catch(e){}
      if(!buf)return;for(const b of mvtBuildings(buf)){const f=new Float32Array(b.ring.length*2);let cx=0,cz=0;
        for(let i=0;i<b.ring.length;i++){const lon=t2lon(bx+b.ring[i][0]/b.extent,16),lat=t2lat(by+b.ring[i][1]/b.extent,16);f[i*2]=(lon-LON0)*MX;f[i*2+1]=-(lat-LAT0)*MZ;cx+=f[i*2];cz+=f[i*2+1];}
        cx/=b.ring.length;cz/=b.ring.length;if(inWorld(cx,cz,40))continue;const hr=BLD_H[b.code]||[5,8];const r0=hashf(Math.round(cx*3+cz*7));const area=Math.abs(polyArea(f));
        let Hh=hr[0]+(hr[1]-hr[0])*r0;if(b.code===3102&&area>1500)Hh*=1.4;let gmin=1e9;for(let i=0;i<f.length;i+=2)gmin=Math.min(gmin,regionH(f[i],f[i+1]));if(gmin<-1)continue;
        const sty=b.code===3101?(r0<0.6?FAC.HOUSE_A:FAC.HOUSE_B):b.code===3103?FAC.OFFICE_GLASS:b.code===3102?(r0<0.5?FAC.MANSION:r0<0.8?FAC.OFFICE:FAC.SHOP):FAC.WAREHOUSE;
        const y0=gmin-0.3,y1=gmin+Hh;const wc=_col.set(b.code===3101?WALLH[Math.floor(r0*WALLH.length)]:WALLO[Math.floor(r0*WALLO.length)]).lerp(_col2.set('#ffffff'),0.45).clone();
        if(b.code===3101&&area<300){const rh=Math.min(2.4,Hh*0.3);facadeWalls(fac,f,y0,y1-rh,wc,sty,2.8);roofOn(f,cx,cz,y1-rh,0,r0,roof);}
        else{facadeWalls(fac,f,y0,y1,wc,sty,Hh/Math.max(1,Math.round(Hh/3.2)));const tris=tri2(f);for(const t of tris)roof.tri([f[t[0]*2],y1,f[t[0]*2+1]],[f[t[1]*2],y1,f[t[1]*2+1]],[f[t[2]*2],y1,f[t[2]*2+1]],0,1,0,_col.set('#ffffff'));}
        cols.push(addPoly(f,y0,y1));}}));
    if(!fac.empty){const m=new THREE.Mesh(fac.geo(),facadeMat());m.castShadow=true;m.receiveShadow=true;rec.grp.add(m);}
    if(!roof.empty){const m=new THREE.Mesh(roof.geo(),regionRoofMat(rec.tex,x,y));m.castShadow=true;rec.grp.add(m);}
    rec.cols=cols;}
  rec.loading=false;}
/* roof photo: same tile texture, projected from (lon,lat) of each fragment */
function regionRoofMat(tex,x,y){const lon0=t2lon(x,14),lon1=t2lon(x+1,14),lat0=t2lat(y,14),lat1=t2lat(y+1,14);
  const m=new THREE.MeshLambertMaterial({map:tex});m.onBeforeCompile=sh=>{sh.uniforms.uR={value:new THREE.Vector4((lon0-LON0)*MX,-(lat0-LAT0)*MZ,(lon1-LON0)*MX,-(lat1-LAT0)*MZ)};
    sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nvarying vec2 vRW2;').replace('#include <begin_vertex>','#include <begin_vertex>\nvRW2=(modelMatrix*vec4(transformed,1.0)).xz;');
    sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nvarying vec2 vRW2;uniform vec4 uR;').replace('#include <map_fragment>','vec2 ruv=vec2((vRW2.x-uR.x)/(uR.z-uR.x),1.0-(vRW2.y-uR.y)/(uR.w-uR.y));diffuseColor*=texture2D(map,ruv);diffuseColor.rgb*=0.9;');};
  m.customProgramCacheKey=()=>'regionroof';return m;}
let regT=0;
function updateRegion(dt,px,pz){if(!REG.started)return;regT-=dt;if(regT>0)return;regT=0.6;
  const [lat,lon]=g2ll(px,pz);const fx=lon2t(lon,14),fy=lat2t(lat,14);const cx=Math.floor(fx),cy=Math.floor(fy);const R=1;const want=new Set();
  for(let j=-R;j<=R;j++)for(let i=-R;i<=R;i++){const x=cx+i,y=cy+j;const lo0=t2lon(x,14),lo1=t2lon(x+1,14),la0=t2lat(y+1,14),la1=t2lat(y,14);
    const gx0=(lo0-LON0)*MX,gx1=(lo1-LON0)*MX,gz0=-(la1-LAT0)*MZ,gz1=-(la0-LAT0)*MZ;if(gx0>WORLD.x0+60&&gx1<WORLD.x1-60&&gz0>WORLD.z0+60&&gz1<WORLD.z1-60)continue;
    if(lo1<KANA.lon0||lo0>KANA.lon1||la1<KANA.lat0||la0>KANA.lat1)continue;
    const d=Math.hypot(clamp(px,gx0,gx1)-px,clamp(pz,gz0,gz1)-pz);want.add(x+'/'+y);loadNearTile(x,y,d<(isTouch?700:1300));}
  for(const [k,rec] of REG.near){if(want.has(k)||rec.loading)continue;if(rec.grp){scene.remove(rec.grp);rec.grp.traverse(o=>{if(o.isMesh){o.geometry.dispose();}});}if(rec.tex)rec.tex.dispose();if(rec.cols)removeColl(rec.cols);REG.near.delete(k);REG.dem.delete('14/'+k);}}
/* place names outside the hand-made world */
const KANA_TOWNS=[['横浜市','Yokohama',35.4437,139.6380],['川崎市','Kawasaki',35.5308,139.7030],['相模原市','Sagamihara',35.5713,139.3732],['横須賀市','Yokosuka',35.2813,139.6722],['平塚市','Hiratsuka',35.3354,139.3496],['鎌倉市','Kamakura',35.3192,139.5467],
  ['藤沢市','Fujisawa',35.3389,139.4874],['小田原市','Odawara',35.2645,139.1522],['茅ヶ崎市','Chigasaki',35.3341,139.4040],['逗子市','Zushi',35.2955,139.5806],['三浦市','Miura',35.1440,139.6206],['秦野市','Hadano',35.3747,139.2203],['厚木市','Atsugi',35.4430,139.3619],
  ['大和市','Yamato',35.4876,139.4580],['伊勢原市','Isehara',35.4027,139.3147],['海老名市','Ebina',35.4466,139.3909],['座間市','Zama',35.4884,139.4078],['南足柄市','Minamiashigara',35.3209,139.0995],['綾瀬市','Ayase',35.4370,139.4269],
  ['葉山町','Hayama',35.2723,139.5862],['寒川町','Samukawa',35.3727,139.3846],['大磯町','Ōiso',35.3066,139.3110],['二宮町','Ninomiya',35.2992,139.2556],['箱根町','Hakone',35.2325,139.1069],['真鶴町','Manazuru',35.1586,139.1381],['湯河原町','Yugawara',35.1478,139.1084],
  ['愛川町','Aikawa',35.5289,139.3236],['清川村','Kiyokawa',35.4825,139.2753],['山北町','Yamakita',35.3602,139.0839],['開成町','Kaisei',35.3348,139.1236],['松田町','Matsuda',35.3434,139.1394],['大井町','Ōi',35.3263,139.1567],['中井町','Nakai',35.3311,139.2189]];
function kanaArea(x,z){const [lat,lon]=g2ll(x,z);let best=null;for(const t of KANA_TOWNS){const d=Math.hypot((t[2]-lat)*111,(t[3]-lon)*90.8);if(!best||d<best.d)best={d,t};}return best&&best.d<12?{city:'神奈川県',name:best.t[0],en:best.t[1]}:{city:'',name:'神奈川県',en:'Kanagawa'};}
