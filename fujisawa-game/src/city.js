
/* ================= 藤沢市全域: PLATEAU buildings everywhere, aerial photo blocks, real street furniture =================
   fujisawa-city.wasm: 'FCT1', meta {chunks:[[key,offset,bytes,n]], blocks:[[bi,bj,file]], pois:[[type,x,z,name,brand,kind]]}, building blob.
   A chunk that has PLATEAU buildings drops the OSM buildings standing on them (2 m occupancy grid), so the rest of OSM stays. */
const CITY_IDX=new Map(),CITY_BLK=new Map(),CITY_POI=new Map();let CITY_BUF=null,CITY_DV=null,CITY_OFF=0;
async function loadCity(){
  try{const res=await fetch('fujisawa-city.wasm');if(!res.ok)throw new Error(res.status);
    const buf=await new Response(res.body.pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();const dv=new DataView(buf);
    const ml=dv.getUint32(4,true);const meta=JSON.parse(new TextDecoder().decode(new Uint8Array(buf,8,ml)));let o=8+ml;while(o%4)o++;
    CITY_BUF=buf;CITY_DV=dv;CITY_OFF=o;for(const [k,off,len,n] of meta.chunks)CITY_IDX.set(k,[off,len,n]);
    for(const [bi,bj,file] of meta.blocks)CITY_BLK.set(bj*1000+bi,{name:file,file,x0:X0+bi*4*CH,z0:Z0+bj*4*CH,size:4*CH,tex:null,ready:false});
    for(const p of meta.pois){const k=chKey(p[1],p[2]);let a=CITY_POI.get(k);if(!a)CITY_POI.set(k,a=[]);a.push(p);}
    console.log('LOG city chunks',CITY_IDX.size,'blocks',CITY_BLK.size,'pois',meta.pois.length);
  }catch(e){console.warn('city data not loaded',e);}
}
function cityBlock(ci,cj){return CITY_BLK.get(Math.floor(cj/4)*1000+Math.floor(ci/4))||null;}
function blockTex(b){if(!b.tex){b.tex=new THREE.TextureLoader().load(b.file,t=>{if(isTouch&&t.image&&t.image.width>1024){const c=document.createElement('canvas');c.width=c.height=1024;c.getContext('2d').drawImage(t.image,0,0,1024,1024);t.image=c;t.needsUpdate=true;}
    b.ready=true;for(const m of PHOTOMATS.values())m.userData.sync&&m.userData.sync();});b.tex.colorSpace=THREE.SRGBColorSpace;b.tex.anisotropy=8;b.tex.wrapS=b.tex.wrapT=THREE.ClampToEdgeWrapping;}return b.tex;}
/* decode one chunk's buildings (same record layout as the place file, coordinates relative to the chunk centre) */
function cityChunkBuildings(ci,cj){const e=CITY_IDX.get(cj*CNX+ci);if(!e)return [];const dv=CITY_DV,buf=CITY_BUF;let o=CITY_OFF+e[0];const end=o+e[1];
  const P={cx:X0+(ci+0.5)*CH,cz:Z0+(cj+0.5)*CH,city:true};const out=[];
  while(o<end){const nf=dv.getUint16(o,true),st=dv.getUint8(o+2),use=dv.getUint16(o+3,true),h=dv.getUint16(o+5,true)/10,z0=dv.getInt16(o+7,true)/10;o+=9;
    const foot=new Float32Array(nf*2);let cx=0,cz=0;for(let i=0;i<nf;i++){foot[i*2]=dv.getInt16(o,true)/10+P.cx;foot[i*2+1]=dv.getInt16(o+2,true)/10+P.cz;o+=4;cx+=foot[i*2];cz+=foot[i*2+1];}
    const rd=()=>{const n=dv.getUint32(o,true);o+=4;const a=new Int16Array(buf.slice(o,o+n*18));o+=n*18;return a;};const roof=rd(),wall=rd();
    out.push({foot,st,use,h,z0,roof,wall,cx:cx/nf,cz:cz/nf,P});}
  return out;}
/* 2 m occupancy of PLATEAU footprints in a chunk */
let CUR_OCC=null;
function buildOcc(ci,cj,list){if(!list.length)return null;const N=CH/2,g=new Uint8Array(N*N),x0=X0+ci*CH,z0=Z0+cj*CH;
  for(const b of list){const f=b.foot;let a0=1e9,a1=-1e9,b0=1e9,b1=-1e9;for(let i=0;i<f.length;i+=2){a0=Math.min(a0,f[i]);a1=Math.max(a1,f[i]);b0=Math.min(b0,f[i+1]);b1=Math.max(b1,f[i+1]);}
    for(let j=Math.max(0,Math.floor((b0-z0)/2));j<=Math.min(N-1,Math.floor((b1-z0)/2));j++)for(let i=Math.max(0,Math.floor((a0-x0)/2));i<=Math.min(N-1,Math.floor((a1-x0)/2));i++){if(inPolyF(x0+i*2+1,z0+j*2+1,f))g[j*N+i]=1;}}
  return{g,x0,z0,N};}
function occAt(o,x,z){const i=Math.floor((x-o.x0)/2),j=Math.floor((z-o.z0)/2);if(i<0||j<0||i>=o.N||j>=o.N)return false;
  for(let dj=-1;dj<=1;dj++)for(let di=-1;di<=1;di++){const a=i+di,b=j+dj;if(a>=0&&b>=0&&a<o.N&&b<o.N&&o.g[b*o.N+a])return true;}return false;}
/* ---------- signs: brand colours of the chains you actually see in Fujisawa ---------- */
const BRANDS=[[/7-?ELEVEN|セブン/i,'#ffffff','#1b7a3f','7-ELEVEN','#f58220'],[/LAWSON|ローソン/i,'#0068b7','#ffffff','LAWSON'],[/Family ?Mart|ファミリーマート/i,'#ffffff','#00a23c','FamilyMart','#0d63ae'],
  [/マクドナルド|McDonald/i,'#d52b1e','#ffc72c','M マクドナルド'],[/スターバックス|STARBUCKS/i,'#006241','#ffffff','STARBUCKS'],[/TULLY/i,'#1d2a44','#ffffff',"TULLY'S COFFEE"],[/ドトール|DOUTOR/i,'#ffe100','#1d2a44','DOUTOR'],
  [/吉野家/,'#f39800','#4a2a00','吉野家'],[/松屋/,'#ffd900','#0a3c8c','松屋'],[/すき家/,'#d7000f','#ffffff','すき家'],[/ガスト/,'#e60012','#ffffff','ガスト'],[/ケンタッキー|KFC/i,'#c8102e','#ffffff','KFC'],
  [/横浜銀行/,'#004098','#ffffff','横浜銀行'],[/三井住友/,'#004b37','#a5c63b','三井住友銀行'],[/みずほ/,'#001f87','#ffffff','みずほ銀行'],[/三菱UFJ/,'#e60012','#ffffff','三菱UFJ銀行'],[/スルガ/,'#00479d','#ffffff','スルガ銀行'],
  [/ビックカメラ/,'#e60012','#ffffff','ビックカメラ'],[/ABC/,'#d7000f','#ffffff','ABC-MART'],[/マツモトキヨシ/,'#ffe600','#1a3c8f','マツモトキヨシ'],[/ツルハ/,'#e4007f','#ffffff','ツルハドラッグ'],[/HARD/,'#ffd700','#d7000f','HARD OFF'],
  [/郵便局/,'#e60012','#ffffff','〒 郵便局'],[/ENEOS/,'#ff6600','#ffffff','ENEOS'],[/au/,'#eb5505','#ffffff','au'],[/docomo/i,'#cc0033','#ffffff','docomo'],[/ソフトバンク|SoftBank/i,'#bbbbbb','#111111','SoftBank']];
const KIND_STYLE={convenience:['#ffffff','#2b2b2b'],restaurant:['#7a2e1f','#ffe8c8'],cafe:['#5a3b2a','#fff3dd'],fast_food:['#d7000f','#ffffff'],bank:['#0b3c7a','#ffffff'],pharmacy:['#1f8a5a','#ffffff'],clothes:['#222222','#ffffff'],books:['#2a4a7a','#ffffff'],supermarket:['#e86a12','#ffffff'],hairdresser:['#3a3a3a','#ffd6e0']};
function signStyle(name,brand,kind){const s=(brand||'')+' '+(name||'');for(const b of BRANDS)if(b[0].test(s))return{bg:b[1],fg:b[2],text:b[3],band:b[4]};const k=KIND_STYLE[kind]||['#1d2a3a','#ffffff'];return{bg:k[0],fg:k[1],text:name||brand};}
/* one sign atlas per chunk: 4 × 16 slots of 256 × 64 px */
function signAtlas(){const cv=document.createElement('canvas');cv.width=1024;cv.height=1024;return{cv,x:cv.getContext('2d'),n:0};}
function atlasSlot(A,st){if(A.n>=64)return null;const i=A.n++;const sx=(i%4)*256,sy=Math.floor(i/4)*64;const x=A.x;x.fillStyle=st.bg;x.fillRect(sx,sy,256,64);
  if(st.band){x.fillStyle=st.band;x.fillRect(sx,sy+50,256,8);x.fillStyle='#e60012';x.fillRect(sx,sy+58,256,6);}
  x.fillStyle=st.fg;x.textAlign='center';x.textBaseline='middle';let fs=36;x.font=`800 ${fs}px "M PLUS Rounded 1c",sans-serif`;while(x.measureText(st.text).width>236&&fs>14){fs-=2;x.font=`800 ${fs}px "M PLUS Rounded 1c",sans-serif`;}
  x.fillText(st.text,sx+128,sy+(st.band?26:32));return[(sx+2)/1024,1-(sy+62)/1024,(sx+254)/1024,1-(sy+2)/1024];}
/* ---------- street furniture of one chunk ---------- */
function buildCityFurniture(grp,ci,cj,cityB,L2){
  const list=CITY_POI.get(cj*CNX+ci);if(!list)return;const fur=new GB(),zb=new GB(),lit=new GB();const A=signAtlas();const sg=new GB();
  const nearRoad=(x,z,lim=25)=>{let best=null;for(const ri of ROADCH.get(chKey(x,z))||[]){const r=ROADS[ri];if(r.fl&3||r.c>7)continue;const q=r.path.near(x,z);if(q.d<lim&&(!best||q.d<best.d))best={d:q.d,r,p:r.path.at(q.s),s:q.s};}return best;};
  const g=(x,z)=>demH(x,z);
  for(const [t,x,z,name,brand,kind] of list){
    if(t==='tree'){L2.round.push({x,y:heightAt(x,z),z,s:rr(0.9,1.25),k:'r'});continue;}
    if(t==='cross'){const n=nearRoad(x,z,8);if(!n||n.r.c>6)continue;const hw=n.r.w/2,tx=n.p.tx,tz=n.p.tz,nx=-tz,nz=tx;const zc=_col.set('#f1eee6');
      for(let k=-hw+0.3;k<hw-0.3;k+=0.9){const a0=k,a1=Math.min(k+0.45,hw-0.3);const P4=[[a0,-1.6],[a1,-1.6],[a1,1.6],[a0,1.6]].map(([u,v])=>{const X=n.p.x+nx*u+tx*v,Z=n.p.z+nz*u+tz*v;return[X,g(X,Z)+0.25,Z];});zb.quad(P4[0],P4[1],P4[2],P4[3],0,1,0,zc);}continue;}
    if(t==='sig'){const n=nearRoad(x,z,15);if(!n)continue;const tx=n.p.tx,tz=n.p.tz,nx=-tz,nz=tx;const hw=n.r.w/2+1.1;
      for(const sd of [1,-1]){const px=x+nx*hw*sd+tx*sd*4,pz=z+nz*hw*sd+tz*sd*4;const y=g(px,pz);fur.obox(px,pz,1,0,0.12,0.12,y,y+5.6,_col.set('#8e979e'));
        const ax=px-nx*sd*2.6,az=pz-nz*sd*2.6;fur.obox(ax,az,nx,nz,2.6,0.06,y+5.5,y+5.62,_col.set('#8e979e'));
        const hx=px-nx*sd*4.6,hz=pz-nz*sd*4.6;fur.obox(hx,hz,nx,nz,0.62,0.18,y+5.2,y+5.65,_col.set('#3a3e44'));
        for(const [k,c] of [[-0.4,'#2bd16a'],[0,'#3d3a30'],[0.4,'#3d2626']]){const lx=hx+nx*k,lz=hz+nz*k;lit.obox(lx+tx*sd*0.19,lz+tz*sd*0.19,nx,nz,0.14,0.02,y+5.3,y+5.56,_col.set(c));}
        fur.obox(px+tx*sd*0.2,pz+tz*sd*0.2,tx,tz,0.15,0.2,y+2.4,y+3.1,_col.set('#3a3e44'));lit.obox(px+tx*sd*0.36,pz+tz*sd*0.36,tx,tz,0.01,0.12,y+2.5,y+2.75,_col.set('#2bd16a'));}continue;}
    if(t==='bus'){const n=nearRoad(x,z,20);let px=x,pz=z,tx=1,tz=0;if(n){const nx=-n.p.tz,nz=n.p.tx;const side=((x-n.p.x)*nx+(z-n.p.z)*nz)>=0?1:-1;px=n.p.x+nx*side*(n.r.w/2+0.9);pz=n.p.z+nz*side*(n.r.w/2+0.9);tx=n.p.tx;tz=n.p.tz;}
      const y=g(px,pz);fur.obox(px,pz,1,0,0.05,0.05,y,y+2.6,_col.set('#c9ced3'));fur.obox(px,pz,tx,tz,0.3,0.04,y+2.3,y+2.9,_col.set('#1f4fa0'));fur.obox(px,pz,1,0,0.25,0.25,y,y+0.15,_col.set('#7d858c'));
      const uv=atlasSlot(A,{bg:'#ffffff',fg:'#1f2a44',text:(name||'バス停')});if(uv)addSign(sg,px+tz*0.05,y+1.95,pz-tx*0.05,tx,tz,1.1,0.28,uv,true);continue;}
    if(t==='vend'){const y=g(x,z);const c=['#d52b1e','#1d5fb0','#f4f4f2','#2a8a4a'][Math.floor(hashf(x*13+z)*4)];fur.obox(x,z,1,0,0.5,0.38,y,y+1.83,_col.set(c));lit.obox(x+0.01,z-0.39,1,0,0.42,0.01,y+0.95,y+1.6,_col.set('#e9f1f7'));continue;}
    if(t==='post'){const y=g(x,z);fur.obox(x,z,1,0,0.22,0.2,y,y+1.15,_col.set('#d52b1e'));fur.obox(x,z,1,0,0.24,0.22,y+1.15,y+1.3,_col.set('#b8241a'));continue;}
    if(t==='tel'){const y=g(x,z);fur.obox(x,z,1,0,0.45,0.45,y,y+2.2,_col.set('#bfe0d0'));fur.obox(x,z,1,0,0.5,0.5,y+2.2,y+2.35,_col.set('#3a8a5a'));continue;}
    if(t==='bike'){const y=g(x,z);for(let k=-2;k<=2;k++)fur.obox(x+k*0.7,z,1,0,0.03,0.5,y,y+0.8,_col.set('#8e979e'));continue;}
    if(t==='shop'){const st=signStyle(name,brand,kind);if(!st.text)continue;
      // the facade nearest to the shop point
      let best=null;for(const b of cityB){if(Math.abs(b.cx-x)>40||Math.abs(b.cz-z)>40)continue;const f=b.foot,n=f.length/2;
        for(let i=0;i<n;i++){const j=(i+1)%n;const ax=f[i*2],az=f[i*2+1],dx=f[j*2]-ax,dz=f[j*2+1]-az,l2=dx*dx+dz*dz;if(l2<4)continue;const u=clamp(((x-ax)*dx+(z-az)*dz)/l2,0.15,0.85);const qx=ax+dx*u,qz=az+dz*u;const d=Math.hypot(qx-x,qz-z);
          if(d<18&&(!best||d<best.d)){const L=Math.sqrt(l2);let nx=dz/L,nz=-dx/L;if((qx-b.cx)*nx+(qz-b.cz)*nz<0){nx=-nx;nz=-nz;}best={d,qx,qz,nx,nz,len:L,b};}}}
      const uv=atlasSlot(A,st);if(!uv)continue;
      if(best){const y=demH(best.qx,best.qz)+3.3;const w=Math.min(4.2,best.len*0.8);addSign(sg,best.qx+best.nx*0.12,y,best.qz+best.nz*0.12,best.nz,-best.nx,w,w/4,uv,false);
        if(st.band){fur.obox(best.qx+best.nx*0.25,best.qz+best.nz*0.25,-best.nz,best.nx,Math.min(6,best.len*0.45),0.22,y-0.95,y-0.62,_col.set(st.band));}}
      else{const y=g(x,z);fur.obox(x,z,1,0,0.06,0.06,y,y+3,_col.set('#8e979e'));addSign(sg,x,y+3.4,z,1,0,2.2,0.55,uv,true);}}
  }
  if(!fur.empty){const m=new THREE.Mesh(fur.geo(),MAT.top);m.castShadow=true;m.receiveShadow=true;grp.add(m);}
  if(!zb.empty){grp.add(new THREE.Mesh(zb.geo(),MAT.road));}
  if(!lit.empty){grp.add(new THREE.Mesh(lit.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));}
  if(!sg.empty){const tex=new THREE.CanvasTexture(A.cv);tex.colorSpace=THREE.SRGBColorSpace;tex.anisotropy=4;const m=new THREE.Mesh(sg.geo(),new THREE.MeshLambertMaterial({map:tex,side:THREE.DoubleSide,emissive:0xffffff,emissiveMap:tex,emissiveIntensity:0.25}));m.userData.ownTex=tex;grp.add(m);}
}
/* a flat sign quad facing (−uz, ux) with atlas uv [u0,v0,u1,v1] */
function addSign(gb,cx,cy,cz,ux,uz,w,h,uv,both){const nx=-uz,nz=ux;const A=[cx-ux*w/2,cy-h/2,cz-uz*w/2],B=[cx+ux*w/2,cy-h/2,cz+uz*w/2],C=[cx+ux*w/2,cy+h/2,cz+uz*w/2],D=[cx-ux*w/2,cy+h/2,cz-uz*w/2];
  gb.tri(A,B,C,nx,0,nz,_col.set('#ffffff'),[uv[0],uv[1]],[uv[2],uv[1]],[uv[2],uv[3]]);gb.tri(A,C,D,nx,0,nz,_col.set('#ffffff'),[uv[0],uv[1]],[uv[2],uv[3]],[uv[0],uv[3]]);}

/* whole-city overview photo (6 m/px) for the far terrain and the colours of the distant building blocks */
const OVERVIEW={u:{value:null},r:{value:new THREE.Vector4(-10440,-10740,0,0)},W:14080,H:16640};const LODINST={m:null,items:null};
function loadOverview(){new THREE.TextureLoader().load('city/overview.jpg',t=>{t.colorSpace=THREE.SRGBColorSpace;OVERVIEW.u.value=t;OVERVIEW.r.value.set(-10440,-10740,OVERVIEW.W,OVERVIEW.H);
  try{const c=document.createElement('canvas');c.width=t.image.width;c.height=t.image.height;const x=c.getContext('2d');x.drawImage(t.image,0,0);const d=x.getImageData(0,0,c.width,c.height).data;
    if(LODINST.m){const [LNX,LNZ,LG0]=META.lod;const cc=new THREE.Color(),c2=new THREE.Color();let n=0;for(const [i,j] of LODINST.items){const X=X0+(i+1)*LG0,Z=Z0+(j+1)*LG0;const u=Math.floor((X+10440)/OVERVIEW.W*c.width),v=Math.floor((Z+10740)/OVERVIEW.H*c.height);
      if(u>=0&&v>=0&&u<c.width&&v<c.height){const k=(v*c.width+u)*4;if(d[k]+d[k+1]+d[k+2]>20){LODINST.m.getColorAt(n,cc);c2.setRGB(d[k]/255,d[k+1]/255,d[k+2]/255,THREE.SRGBColorSpace);cc.lerp(c2,0.55);LODINST.m.setColorAt(n,cc);}}n++;}LODINST.m.instanceColor.needsUpdate=true;}}catch(e){}});}
