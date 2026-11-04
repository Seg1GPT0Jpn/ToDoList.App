
/* ================= facades: one canvas atlas, 8 styles × (ground floor, upper floors) =================
   Walls carry uv = (bays along the wall + style*1000, storeys up the wall). The shader picks the atlas tile
   (ground floor row for the first storey, the repeating upper tile above) and lights windows per cell at night. */
const FAC={HOUSE_A:0,HOUSE_B:1,MANSION:2,MANSION_B:3,OFFICE_GLASS:4,OFFICE:5,SHOP:6,WAREHOUSE:7};
const FAC_BAY=[3.6,3.6,3.4,3.4,3.2,3.2,4.0,6.0];
function facadeAtlas(){
  const T=256,S=T*4;const a=document.createElement('canvas'),e=document.createElement('canvas');a.width=a.height=e.width=e.height=S;
  const x=a.getContext('2d'),y=e.getContext('2d');y.fillStyle='#000';y.fillRect(0,0,S,S);
  const R=mulberry32(77);
  const tile=(style,ground,fn)=>{const cx=(style%4)*T,cy=(3-(Math.floor(style/4)*2+(ground?0:1)))*T;x.save();y.save();x.translate(cx,cy);y.translate(cx,cy);x.beginPath();x.rect(0,0,T,T);x.clip();y.beginPath();y.rect(0,0,T,T);y.clip();fn(x,y);x.restore();y.restore();};
  const noise=(c,a0,n=900)=>{for(let i=0;i<n;i++){c.fillStyle=`rgba(${R()<0.5?0:255},${R()<0.5?0:255},${R()<0.5?0:255},${a0*R()})`;c.fillRect(R()*T,R()*T,1+R()*2,1+R()*2);}};
  const glass=(c,px,py,w,h,tone='#3b5266')=>{const g=c.createLinearGradient(px,py,px+w,py+h);g.addColorStop(0,tone);g.addColorStop(0.55,'#6f8aa0');g.addColorStop(1,tone);c.fillStyle=g;c.fillRect(px,py,w,h);c.fillStyle='rgba(255,255,255,.18)';c.beginPath();c.moveTo(px,py+h*0.7);c.lineTo(px+w*0.35,py);c.lineTo(px+w*0.5,py);c.lineTo(px,py+h);c.fill();};
  const lit=(c,px,py,w,h)=>{c.fillStyle='#fff';c.fillRect(px,py,w,h);};
  const wallBase=(c,col)=>{c.fillStyle=col;c.fillRect(0,0,T,T);noise(c,0.05);};
  // 0: house, light siding, sash window with frame; ground: door + small window
  tile(0,false,(c,l)=>{wallBase(c,'#f3efe6');c.strokeStyle='rgba(0,0,0,.06)';c.lineWidth=2;for(let k=8;k<T;k+=14){c.beginPath();c.moveTo(0,k);c.lineTo(T,k);c.stroke();}
    c.fillStyle='#d8d4cc';c.fillRect(52,58,152,112);glass(c,60,66,136,96,'#44586a');c.fillStyle='#e9e6df';c.fillRect(126,66,5,96);c.fillStyle='#9aa0a6';c.fillRect(48,170,160,8);lit(l,60,66,136,96);});
  tile(0,true,(c,l)=>{wallBase(c,'#ece7dc');c.fillStyle='#7b5a3e';c.fillRect(40,70,70,186);c.fillStyle='#c9a36a';c.fillRect(98,160,6,10);c.fillStyle='#d8d4cc';c.fillRect(140,90,84,80);glass(c,146,96,72,68);c.fillStyle='#b8b2a6';c.fillRect(0,236,T,20);lit(l,146,96,72,68);});
  // 1: house, warm tile-look siding with two small windows
  tile(1,false,(c,l)=>{wallBase(c,'#e6dccb');for(let k=0;k<T;k+=22)for(let j=0;j<T;j+=44){c.fillStyle=`rgba(120,90,60,${0.05+R()*0.05})`;c.fillRect(j+(k/22%2)*22,k,42,20);}
    for(const px of [30,150]){c.fillStyle='#cfc8bb';c.fillRect(px-4,70,84,100);glass(c,px,76,76,88,'#3e5262');lit(l,px,76,76,88);c.fillStyle='#8f8f8f';c.fillRect(px-6,170,88,6);}});
  tile(1,true,(c,l)=>{wallBase(c,'#ddd2bf');c.fillStyle='#5c4a3a';c.fillRect(150,64,72,192);c.fillStyle='#cfc8bb';c.fillRect(26,96,86,74);glass(c,30,100,78,66);lit(l,30,100,78,66);c.fillStyle='#a9a293';c.fillRect(0,240,T,16);});
  // 2: mansion balcony: slab edge, frosted railing, sliding glass door, partition
  tile(2,false,(c,l)=>{wallBase(c,'#ebe7df');glass(c,18,26,220,206,'#2f4252');c.fillStyle='rgba(240,230,210,.55)';c.fillRect(24,32,60,196);lit(l,18,26,220,206);
    c.fillStyle='#d9d6cf';c.fillRect(0,0,T,20);c.fillStyle='rgba(255,255,255,.82)';c.fillRect(0,140,T,96);c.fillStyle='rgba(120,130,140,.35)';for(let k=0;k<T;k+=64)c.fillRect(k,140,3,96);c.fillStyle='#c2c0bb';c.fillRect(0,136,T,6);c.fillStyle='#cfccc5';c.fillRect(0,236,T,20);
    c.fillStyle='#d4d1ca';c.fillRect(250,20,6,236);y.fillStyle='#000';y.fillRect(0,140,T,96);});
  tile(2,true,(c,l)=>{wallBase(c,'#d9d5cc');c.fillStyle='#b9b5ac';for(let k=0;k<T;k+=32)c.fillRect(0,k,T,2);glass(c,30,60,190,196,'#2c3b47');c.fillStyle='#8c8f92';c.fillRect(122,60,6,196);lit(l,30,60,190,196);c.fillStyle='#e9e6df';c.fillRect(20,40,210,20);});
  // 3: mansion, brown tiles, metal-bar railing
  tile(3,false,(c,l)=>{wallBase(c,'#b89a7e');for(let k=0;k<T;k+=10){c.fillStyle='rgba(60,40,20,.08)';c.fillRect(0,k,T,1);}glass(c,30,30,196,200,'#334656');lit(l,30,30,196,200);
    c.fillStyle='#e3dfd7';c.fillRect(0,0,T,18);c.fillStyle='#5d5a55';c.fillRect(0,150,T,6);for(let k=4;k<T;k+=12)c.fillRect(k,150,3,86);c.fillRect(0,232,T,4);c.fillStyle='#e3dfd7';c.fillRect(0,236,T,20);});
  tile(3,true,(c,l)=>{wallBase(c,'#a88b70');c.fillStyle='#7a6553';c.fillRect(0,0,T,10);glass(c,40,70,176,186,'#2c3b47');lit(l,40,70,176,186);c.fillStyle='#5e5a55';c.fillRect(126,70,4,186);});
  // 4: office glass ribbon: spandrel band + glass with mullions
  tile(4,false,(c,l)=>{wallBase(c,'#c9cfd4');glass(c,0,60,T,170,'#2e4a63');for(let k=0;k<T;k+=64){c.fillStyle='#9aa4ac';c.fillRect(k,60,5,170);}lit(l,0,60,T,170);for(let k=0;k<T;k+=64)l.fillStyle='#000',l.fillRect(k,60,5,170);
    c.fillStyle='#b9c0c6';c.fillRect(0,0,T,60);c.fillRect(0,230,T,26);c.fillStyle='rgba(0,0,0,.08)';c.fillRect(0,56,T,4);});
  tile(4,true,(c,l)=>{wallBase(c,'#aab3ba');glass(c,0,30,T,226,'#2a3e50');for(let k=0;k<T;k+=86){c.fillStyle='#7d8890';c.fillRect(k,30,6,226);}c.fillStyle='#d5dade';c.fillRect(0,0,T,30);lit(l,0,30,T,226);});
  // 5: office / public building, punched windows in concrete
  tile(5,false,(c,l)=>{wallBase(c,'#dedbd3');c.fillStyle='rgba(0,0,0,.05)';c.fillRect(0,0,T,4);c.fillStyle='#c7c4bc';c.fillRect(34,54,188,138);glass(c,40,60,176,126,'#3a5468');c.fillStyle='#d8d6d0';c.fillRect(126,60,4,126);lit(l,40,60,176,126);c.fillStyle='#bcb8b0';c.fillRect(30,192,196,6);});
  tile(5,true,(c,l)=>{wallBase(c,'#cfccc3');glass(c,20,50,216,206,'#2f4558');c.fillStyle='#8c949a';for(const k of [20,128,236])c.fillRect(k-3,50,6,206);lit(l,20,50,216,206);c.fillStyle='#e9e6df';c.fillRect(0,30,T,20);});
  // 6: commercial: signboards upstairs, shopfront + awning downstairs
  tile(6,false,(c,l)=>{wallBase(c,'#e4ded2');glass(c,28,40,200,120,'#3c5062');lit(l,28,40,200,120);const sc=['#d6392f','#1d6fb8','#f2b632','#2f8f4e','#7a3e9d'];c.fillStyle=sc[Math.floor(R()*sc.length)];c.fillRect(20,176,216,56);
    c.fillStyle='#fff';for(let k=0;k<5;k++)c.fillRect(40+k*38,192,24,24);lit(l,20,176,216,56);});
  tile(6,true,(c,l)=>{wallBase(c,'#d2ccc0');glass(c,10,96,236,160,'#2b3a46');c.fillStyle='rgba(255,240,200,.25)';c.fillRect(10,96,236,160);lit(l,10,96,236,160);
    const g=c.createLinearGradient(0,40,0,96);g.addColorStop(0,'#c8432f');g.addColorStop(1,'#9c2f22');c.fillStyle=g;c.fillRect(0,40,T,56);c.fillStyle='rgba(255,255,255,.5)';for(let k=0;k<T;k+=32)c.fillRect(k,40,14,56);c.fillStyle='#fff';c.font='bold 30px sans-serif';});
  // 7: warehouse / factory: corrugated panels, high strip windows, shutter
  tile(7,false,(c,l)=>{wallBase(c,'#cdd1d2');for(let k=0;k<T;k+=8){c.fillStyle='rgba(0,0,0,.07)';c.fillRect(k,0,3,T);}c.fillStyle='#e8eaea';c.fillRect(0,0,T,10);glass(c,20,40,216,40,'#506878');lit(l,20,40,216,40);});
  tile(7,true,(c,l)=>{wallBase(c,'#c3c7c8');for(let k=0;k<T;k+=8){c.fillStyle='rgba(0,0,0,.07)';c.fillRect(k,0,3,T);}c.fillStyle='#9ca3a8';c.fillRect(40,50,176,206);for(let k=50;k<T;k+=10){c.fillStyle='rgba(0,0,0,.12)';c.fillRect(40,k,176,2);}});
  const m=new THREE.CanvasTexture(a),em=new THREE.CanvasTexture(e);m.colorSpace=em.colorSpace=THREE.SRGBColorSpace;m.anisotropy=em.anisotropy=8;m.generateMipmaps=em.generateMipmaps=true;
  return {m,em};
}
let FACMAT=null;
function facadeMat(){if(FACMAT)return FACMAT;const t=facadeAtlas();
  const m=new THREE.MeshLambertMaterial({color:0xffffff,map:t.m,emissiveMap:t.em,emissive:0xffd9a0,emissiveIntensity:0,vertexColors:true});
  m.onBeforeCompile=sh=>{
    sh.fragmentShader=sh.fragmentShader.replace('#include <map_fragment>',`
      float fSty=floor(vMapUv.x/1000.0);vec2 fq=vec2(vMapUv.x-fSty*1000.0,vMapUv.y);float fFl=floor(fq.y+0.0001);vec2 ff=fract(fq);
      vec2 fCell=vec2(mod(fSty,4.0),floor(fSty/4.0)*2.0+(fFl<0.5?0.0:1.0));vec2 fAuv=(fCell+ff*0.996+0.002)/4.0;
      vec2 fdx=dFdx(fq)/4.0,fdy=dFdy(fq)/4.0;
      diffuseColor*=textureGrad(map,fAuv,fdx,fdy);`)
    .replace('#include <emissivemap_fragment>',`{vec2 cid=floor(fq+0.0001)+vec2(fSty*13.0,0.0)+floor(vColor.rg*97.0);float hh=fract(sin(dot(cid,vec2(12.9898,78.233)))*43758.5453);
      totalEmissiveRadiance*=textureGrad(emissiveMap,fAuv,fdx,fdy).rgb*step(0.42,hh)*(0.7+0.6*fract(hh*7.0));}`);};
  m.customProgramCacheKey=()=>'facade';WINMATS.push(m);FACMAT=m;return m;}
/* choose a facade style for a building */
function facadeStyle(use,h,area,r,kind){
  if(use===411||use===413||(use===0&&h<9&&area<260)){return r<0.6?FAC.HOUSE_A:FAC.HOUSE_B;}
  if(use===412||use===414){return r<0.65?FAC.MANSION:FAC.MANSION_B;}
  if(use===402||use===404||use===403){return h>25&&r<0.5?FAC.OFFICE_GLASS:FAC.SHOP;}
  if(use===431||use===441||use===453||kind===3)return FAC.WAREHOUSE;
  if(use===401){return h>20||r<0.4?FAC.OFFICE_GLASS:FAC.OFFICE;}
  if(use===421||use===422||kind===4||kind===10)return FAC.OFFICE;
  if(h>=10.5)return r<0.45?FAC.MANSION:r<0.7?FAC.OFFICE:r<0.85?FAC.OFFICE_GLASS:FAC.SHOP;
  return r<0.5?FAC.HOUSE_A:FAC.HOUSE_B;}
/* extrude a footprint with facade uvs */
function facadeWalls(gb,f,y0,y1,col,style,storeyH){const n=f.length/2;let per=0;const bay=FAC_BAY[style];const off=style*1000;
  for(let i=0;i<n;i++){const j=(i+1)%n;const ax=f[i*2],az=f[i*2+1],bx=f[j*2],bz=f[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)continue;
    const nx=dz/len,nz=-dx/len;const nb=Math.max(1,Math.round(len/bay));const u0=off+0.0,u1=off+nb;const v1=(y1-y0)/storeyH;per+=len;
    gb.tri([ax,y0,az],[bx,y0,bz],[bx,y1,bz],nx,0,nz,col,[u0,0],[u1,0],[u1,v1]);gb.tri([ax,y0,az],[bx,y1,bz],[ax,y1,az],nx,0,nz,col,[u0,0],[u1,v1],[u0,v1]);}}
