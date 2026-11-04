/* ================= landmarks: positions from OSM names; only a few hand-made models ================= */
const NIGHT={};
function torii(x,z,ang,c,s=1,yb){const y=yb??gy(x,z);const g=new THREE.Group();g.position.set(x,y,z);g.rotation.y=-ang;scene.add(g);
  const add=(geo,w,h,d,px,py,pz)=>{const m=new THREE.Mesh(geo,M(c));m.scale.set(w*s,h*s,d*s);m.position.set(px*s,py*s,pz*s);m.castShadow=true;g.add(m);};
  add(CYL,0.5,5,0.5,-1.8,0,0);add(CYL,0.5,5,0.5,1.8,0,0);add(BOX,5.6,0.5,0.6,0,4.6,0);add(BOX,4.4,0.35,0.4,0,3.8,0);add(BOX,6.4,0.35,0.8,0,5.1,0);
  const c0=Math.cos(ang),s0=Math.sin(ang);for(const sd of [-1,1])addOBB(x+c0*1.8*s*sd,z+s0*1.8*s*sd,0.3*s,0.3*s,0,y,y+5*s);return g;}
function boat(x,z,kind,yb,dyn=true){const y0=yb??SEA;const rot=rand()*0.4-0.2+(kind==='fish'?rand()*3:Math.PI/2);
  if(!dyn){bmesh(BOX,M('#ffffff'),x,y0-0.4,z,2.8,1.2,kind==='fish'?11:9,rot,true);
    if(kind==='yacht')bmesh(CYL,M('#dfe3e6'),x,y0+0.8,z,0.22,13,0.22,0,true);else bmesh(BOX,M('#3d6fa8'),x,y0+0.8,z,2.2,2,3,rot,true);return null;}
  const g=new THREE.Group();g.position.set(x,y0,z);g.rotation.y=rot;scene.add(g);
  const hull=new THREE.Mesh(BOX,M('#ffffff'));hull.scale.set(2.8,1.2,kind==='fish'?11:9);hull.position.y=-0.4;hull.castShadow=true;g.add(hull);
  if(kind==='yacht'){const m=new THREE.Mesh(CYL,M('#dfe3e6'));m.scale.set(0.22,13,0.22);m.position.y=0.8;g.add(m);}
  else{const c=new THREE.Mesh(BOX,M('#3d6fa8'));c.scale.set(2.2,2,3);c.position.set(0,0.8,-1.5);g.add(c);}
  const ph=rand()*6;DYN.push(t=>{g.rotation.z=Math.sin(t*1.1+ph)*0.04;g.position.y=y0+Math.sin(t*0.9+ph)*0.12;});return g;}
const PALMS=[];
function LMP(key,lat,lon){const p=META.landmarks[key];return p?p:L(lat,lon);}
function buildLandmarks(){
  /* Enoshima Sea Candle (≈60 m tower on the ≈60 m summit) */
  {const [sx,sz]=LMP('seacandle',35.2998,139.4797);const sy=gy(sx,sz);EXCL.push([sx,sz,16]);
    cyl(11,4,'#e8e2d2',sx,sy-0.5,sz,{col:true});
    cyl(2.2,50,'#f4f4f2',sx,sy,sz,{geo:new THREE.CylinderGeometry(0.5,0.85,1,16).translate(0,0.5,0),col:true});
    const legG=new THREE.CylinderGeometry(0.22,0.35,44,6).translate(0,22,0);
    for(let i=0;i<8;i++){const a=i/8*Math.PI*2;const leg=bmesh(legG,M('#e3e6e8'),sx+Math.cos(a)*6,sy,sz+Math.sin(a)*6,1,1,1,0,true);leg.rotation.z=Math.cos(a)*0.09;leg.rotation.x=-Math.sin(a)*0.09;}
    for(let k=0;k<7;k++)cyl(6.2-k*0.35,0.4,'#d7dbde',sx,sy+5+k*5.5,sz);
    const dmat=new THREE.MeshLambertMaterial({color:'#9fd8ec',emissive:'#ffd98a',emissiveIntensity:0});WINMATS.push(dmat);cyl(8,4.5,'#9fd8ec',sx,sy+40,sz,{mat:dmat});
    cyl(9,0.8,'#ffffff',sx,sy+44.5,sz);
    const lampMat=new THREE.MeshLambertMaterial({color:'#fff6d8',emissive:'#ffe28a',emissiveIntensity:0.2});cyl(2.8,4.5,'#fff',sx,sy+45.3,sz,{mat:lampMat});
    cyl(3.3,0.6,'#ffffff',sx,sy+49.8,sz);bmesh(new THREE.ConeGeometry(0.6,9,8).translate(0,4.5,0),M('#e9ecee'),sx,sy+50.4,sz,1,1,1,0,true);
    const beam=new THREE.Group();beam.position.set(sx,sy+47.5,sz);scene.add(beam);
    const bm=new THREE.MeshBasicMaterial({color:'#fff2c0',transparent:true,opacity:0,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide,fog:false});
    for(const s of [1,-1]){const c=new THREE.Mesh(new THREE.ConeGeometry(60,2400,24,1,true).translate(0,-1200,0).rotateZ(s*Math.PI/2),bm);beam.add(c);}
    DYN.push((t,dt)=>{beam.rotation.y+=dt*0.5;});NIGHT.beam=bm;NIGHT.lamp=lampMat;
    landmark('江の島シーキャンドル','Enoshima Sea Candle',sx,sz,40,{y:sy+62,travel:true});}
  {const [x,z]=LMP('torii',35.3020,139.4822);torii(x,z,0.6,'#5d9483',1.2);landmark('江の島 青銅の鳥居','Seidō Torii',x,z,12,{noLabel:true});}
  {const [x,z]=LMP('ryuren',35.2979,139.4776);const y=gy(x,z);cyl(0.15,3.2,'#8a6a3a',x-1.4,y,z);cyl(0.15,3.2,'#8a6a3a',x+1.4,y,z);box(3.4,0.3,0.4,'#8a6a3a',x,y+3.2,z,{col:false});
    bmesh(new THREE.CylinderGeometry(0.4,0.6,1.0,14),M('#d9b44a'),x,y+2.6,z,1,1,1,0,true);landmark('龍恋の鐘','Ryuren Bell',x,z,14,{y:y+7});}
  const lm=(key,lat,lon,name,en,r,opt={})=>{const [x,z]=LMP(key,lat,lon);landmark(name,en,x,z,r,{y:(opt.dy??14)+gy(x,z),...opt});return [x,z];};
  lm('hetsu',35.3008,139.4810,'江島神社 辺津宮','Hetsunomiya',20);lm('nakatsu',35.3003,139.4800,'中津宮','Nakatsunomiya',16);lm('okutsu',35.2985,139.4768,'奥津宮','Okutsunomiya',18);
  lm('zuishin',35.3013,139.4817,'瑞心門','Zuishin-mon',14,{noLabel:true});
  lm('iwaya',35.2978,139.4745,'江の島岩屋','Iwaya Caves',40,{travel:true});lm('chigo',35.2971,139.4752,'稚児ヶ淵','Chigogafuchi',60,{travel:true,dy:8});
  {const [hx,hz]=lm('harbor',35.2995,139.4855,'江の島ヨットハーバー','Enoshima Yacht Harbor',140,{travel:true,dy:22});
    let n=0;for(let k=0;k<4000&&n<60;k++){const x=hx+rr(-260,260),z=hz+rr(-200,220);if(rawH(x,z)<-0.8&&rawH(x,z)>-5&&lcAt(x,z)===1){let ok=true;for(let a=0;a<6;a++){if(rawH(x+Math.cos(a)*8,z+Math.sin(a)*8)>0){ok=false;break;}}if(ok){boat(x,z,'yacht',SEA,false);n++;}}}}
  lm('katase_st',35.3091,139.4829,'片瀬江ノ島駅（竜宮城）','Katase-Enoshima Sta.',30,{travel:true,dy:24});
  lm('aquarium',35.3088,139.4790,'新江ノ島水族館','Enoshima Aquarium',70,{travel:true,dy:24});
  lm('ryukoji',35.3095,139.4905,'龍口寺','Ryūkō-ji',40,{travel:true,dy:24});
  lm('koshigoeport',35.3045,139.4935,'腰越漁港','Koshigoe Port',60,{dy:10});
  lm('cityhall',35.3420,139.4905,'藤沢市役所','Fujisawa City Hall',50,{dy:56});
  lm('yugyoji',35.3462,139.4936,'遊行寺（清浄光寺）','Yugyō-ji',60,{travel:true,dy:34});
  lm('shirahata',35.3515,139.4786,'白旗神社','Shirahata Shrine',30,{dy:14});
  lm('terrace',35.3393,139.4476,'テラスモール湘南','Terrace Mall Shōnan',140,{travel:true,dy:40});
  lm('tsujidopark',35.3218,139.4545,'辻堂海浜公園','Tsujidō Seaside Park',200,{travel:true,dy:20});
  lm('sst',35.3405,139.4620,'Fujisawa SST','Sustainable Smart Town',240,{travel:true,dy:20});
  lm('shonandai_bc',35.3955,139.4685,'湘南台文化センター','Shōnandai Culture Center',50,{travel:true,dy:40});
  lm('akibadai',35.3887,139.4608,'秋葉台文化体育館','Akibadai Gym',70,{travel:true,dy:24});
  lm('sfc',35.3884,139.4273,'慶應義塾大学 SFC','Keio Univ. SFC',280,{travel:true,dy:40});
  lm('nichidai',35.3790,139.4660,'日本大学 生物資源科学部','Nihon Univ.',200,{dy:30});
  lm('oba',35.3560,139.4520,'大庭城址公園','Ōba Castle Ruins Park',160,{travel:true,dy:24});
  lm('hikiji_park',35.3500,139.4590,'引地川親水公園','Hikiji River Park',100,{dy:16});
  lm('ipark',35.3470,139.5040,'湘南アイパーク','Shōnan iPark',180,{travel:true,dy:60});
  {const [x,z]=lm('ofunakannon',35.3523,139.5285,'大船観音（鎌倉市）','Ōfuna Kannon',50,{dy:36});const y=gy(x,z);EXCL.push([x,z,14]);bmesh(SPH,M('#f6f5f1'),x,y+8,z,22,22,16,0,true);bmesh(SPH,M('#f6f5f1'),x,y+20,z,13,14,13,0,true);bmesh(SPH,M('#ecebe6'),x,y+28,z-1,6,5.5,6,0,true);addOBB(x,z,10,8,0,y,y+26);}
  lm('kamakurakoko',35.3066,139.5004,'鎌倉高校前 踏切','Kamakura-kōkōmae Crossing',40,{dy:12});
  landmark('鵠沼海岸','Kugenuma Beach',-1500,coastZ(-1500)-45,300,{y:8,travel:true});
  landmark('片瀬西浜','Katase Nishihama',-600,coastZ(-600)-40,200,{y:8});
  landmark('片瀬東浜','Katase Higashihama',120,coastZ(120)-30,150,{y:8});
  landmark('辻堂海岸','Tsujidō Beach',-3400,coastZ(-3400)-45,400,{y:8});
  // lifeguard towers on the sand
  for(let x=-4400;x<=1600;x+=380){let z=coastZ(x)-12;for(let k=0;k<20&&lcAt(x,z)!==5;k++)z-=5;if(lcAt(x,z)!==5)continue;const y=gy(x,z);for(const [a,b] of [[-1,-1],[1,-1],[-1,1],[1,1]])cyl(0.08,3.4,'#f4f4f4',x+a,y,z+b);box(2.6,1.6,2.6,'#e0453a',x,y+3.4,z,{col:false});}
  // palms along the coastal road (国道134号), on its sea side
  for(const r of ROADS){if(r.name!=='国道134号'||(r.fl&3))continue;const p=r.path;for(let s=0;s<p.L;s+=26){const q=p.at(s);for(const sd of [1,-1]){const x=q.x-q.tz*sd*(r.w/2+3),z=q.z+q.tx*sd*(r.w/2+3);if(z>q.z&&x<500&&x>-4400&&(lcAt(x,z)===5||lcAt(x,z)===3)){PALMS.push([x,heightAt(x,z),z]);}}}}
}

/* stations: side platforms at real height (1.1 m), canopies, end steps, signs */
const PLATBUILT=[];
function buildRealPlatforms(){
  const gb=new GB();const col=new THREE.Color('#d6d0c2'),edge=new THREE.Color('#bdb6a8');
  for(const p of PLATS){const n=p.length/2;let cx=0,cz=0;for(let i=0;i<n;i++){cx+=p[i*2];cz+=p[i*2+1];}cx/=n;cz/=n;
    if(cx<WORLD.x0||cx>WORLD.x1||cz<WORLD.z0||cz>WORLD.z1)continue;
    let top=null,line=null;
    const mr=LINES.mono.path.near(cx,cz);if(mr.d<16){const y=LINES.mono.beamY(mr.s);top=y-1.6-LINES.mono.car.h-0.95-0.3+0.95+0.2;line=LINES.mono;}
    else{let best=null;for(const k in LINES){const l=LINES[k];if(l.mono)continue;const r=l.path.near(cx,cz);if(r.d<45&&(!best||r.d<best.d))best={d:r.d,s:r.s,l};}if(best){top=best.l.path.py(best.s)+1.1;line=best.l;}}
    if(top===null)continue;
    let gmin=1e9;for(let i=0;i<n;i++)gmin=Math.min(gmin,demH(p[i*2],p[i*2+1]));const y0=Math.min(gmin-0.3,top-1.2);
    for(let i=0;i<n;i++){const j=(i+1)%n;const ax=p[i*2],az=p[i*2+1],bx=p[j*2],bz=p[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)continue;const nx=dz/len,nz=-dx/len;
      gb.tri([ax,y0,az],[bx,y0,bz],[bx,top,bz],nx,0,nz,edge);gb.tri([ax,y0,az],[bx,top,bz],[ax,top,az],nx,0,nz,edge);
      // yellow safety line along the edge
      const ix=-nx*0.6,iz=-nz*0.6;const yl=_col2.set('#f2d33c');gb.tri([ax+ix*0.5,top+0.015,az+iz*0.5],[bx+ix*0.5,top+0.015,bz+iz*0.5],[bx+ix,top+0.015,bz+iz],0,1,0,yl);gb.tri([ax+ix*0.5,top+0.015,az+iz*0.5],[bx+ix,top+0.015,bz+iz],[ax+ix,top+0.015,az+iz],0,1,0,yl);}
    const contour=[];for(let i=0;i<n;i++)contour.push(new THREE.Vector2(p[i*2],p[i*2+1]));let tris=[];try{tris=THREE.ShapeUtils.triangulateShape(contour,[]);}catch(e){}
    for(const t of tris)gb.tri([p[t[0]*2],top,p[t[0]*2+1]],[p[t[1]*2],top,p[t[1]*2+1]],[p[t[2]*2],top,p[t[2]*2+1]],0,1,0,col);
    const b=addPoly(p,y0,top);b.tag=0;b.plat=true;PLATBUILT.push({x:cx,z:cz,line,top,b});
    // stairs at both ends of an elevated platform
    if(top-gmin>2.2){let bi=0,bl=0;for(let i=0;i<n;i++){const j=(i+1)%n;const l=Math.hypot(p[j*2]-p[i*2],p[j*2+1]-p[i*2+1]);if(l>bl){bl=l;bi=i;}}
      const j=(bi+1)%n;let ux=p[j*2]-p[bi*2],uz=p[j*2+1]-p[bi*2+1];const ul=Math.hypot(ux,uz);ux/=ul;uz/=ul;let a0=1e9,a1=-1e9;for(let i=0;i<n;i++){const a=(p[i*2]-cx)*ux+(p[i*2+1]-cz)*uz;a0=Math.min(a0,a);a1=Math.max(a1,a);}
      for(const [a,sg] of [[a1,1],[a0,-1]]){const ex=cx+ux*a,ez=cz+uz*a;const ang=Math.atan2(uz*sg,ux*sg);stairsDown(ex,ez,ang,top,demH(ex+ux*sg*15,ez+uz*sg*15),2.2);}}
  }
  if(!gb.empty){const m=new THREE.Mesh(gb.geo(),MAT.top);m.receiveShadow=true;m.castShadow=true;scene.add(m);}
}
function buildStations(){
  buildRealPlatforms();
  const done=[];
  for(const k in LINES){const l=LINES[k];
    for(const st of l.st){
      const s0=l.path.near(st.x,st.z).s;const s=clamp(s0,l.halfT+2,l.path.L-l.halfT-2);st.s=s;const p=l.path.at(s);
      if(p.x<WORLD.x0||p.x>WORLD.x1||p.z<WORLD.z0||p.z>WORLD.z1)continue;
      const grp=k==='odn'||k==='ods'?'od':k;const dup=done.find(d=>d.name===st[0]&&d.grp===grp&&Math.hypot(d.x-p.x,d.z-p.z)<260);
      if(dup){st.s=s;st.off=dup.off;continue;}
      EXCL.push([p.x,p.z,-1,l,s]);
      const hasReal=PLATBUILT.some(q=>q.line===l&&Math.hypot(q.x-p.x,q.z-p.z)<l.plat/2+60);
      if(hasReal){addLabel(st[0],st[1],p.x,l.mono?l.beamY(s)+7:l.path.py(s)+8,p.z,'st',l.color,900);done.push({name:st[0],x:p.x,z:p.z,grp});
        if(!LM.find(m=>m.name.startsWith(st[0]+'駅')||m.name==='湘南モノレール '+st[0]+'駅'))LM.push({name:(l.mono?'湘南モノレール ':'')+st[0]+'駅',en:st[1]+' Sta.',x:p.x,z:p.z,r:60,noLabel:true,station:true,travel:true,line:l.short,mono:l.mono});continue;}
      if(l.mono){const y=l.beamY(s);const fl=y-1.6-l.car.h-0.95-0.3+0.95+0.2;st.floor=fl;const ang=Math.atan2(p.tz,p.tx);
        for(const sd of [-1,1]){const cx=p.x-p.tz*sd*3.0,cz=p.z+p.tx*sd*3.0;box(l.plat,0.6,2.4,'#d9dde1',cx,fl-0.6,cz,{ang});}
        box(l.plat+4,0.5,11,'#c8434a',p.x,y+2.0,p.z,{ang,col:false});
        const c=Math.cos(ang),sn=Math.sin(ang);
        for(const sd of [-1,1]){const ex=p.x+c*(l.plat/2)-p.tz*sd*3.0,ez=p.z+sn*(l.plat/2)+p.tx*sd*3.0;stairsDown(ex,ez,ang,fl,demH(ex+c*10,ez+sn*10),2.2);}
        addLabel(st[0],st[1],p.x,y+7,p.z,'st',l.color,900);
        done.push({name:st[0],x:p.x,z:p.z,grp});if(!LM.find(m=>m.name==='湘南モノレール '+st[0]+'駅'))LM.push({name:'湘南モノレール '+st[0]+'駅',en:st[1],x:p.x,z:p.z,r:40,noLabel:true,station:true,mono:true});
        continue;}
      const pw=l.single?3:4.2;const offF=(ss,sd)=>l.path.laneOff(ss,sd)+sd*(l.car.w/2+0.1+pw/2);const off=Math.abs(offF(s,1));st.off=off;
      for(const sd of [-1,1]){
        for(let q=-l.plat/2;q<l.plat/2;q+=6){const a=l.path.at(s+q+3,offF(s+q+3,sd));const y=l.path.py(s+q+3);const ang=Math.atan2(a.tz,a.tx);
          box(6.05,1.1,pw,'#d8d2c4',a.x,y,a.z,{ang});const ex=a.x+a.tz*sd*(pw/2-0.5),ez=a.z-a.tx*sd*(pw/2-0.5);box(6.05,0.04,0.35,'#f2d33c',ex,y+1.1,ez,{ang,col:false,cast:false});
          if(Math.abs(q)<l.plat*0.32){box(6.05,0.25,pw+0.6,'#8fa0ae',a.x,y+4.3,a.z,{ang,col:false,cast:false});}}
        for(let q=-l.plat*0.32;q<=l.plat*0.32;q+=12){const a=l.path.at(s+q,offF(s+q,sd));cyl(0.12,3.2,'#8fa0ae',a.x,l.path.py(s+q)+1.1,a.z,{cast:false});}
        for(const e of [-1,1]){const se=s+e*l.plat/2;const a=l.path.at(se,offF(se,sd));const ang=Math.atan2(a.tz,a.tx)+(e>0?0:Math.PI);const top=l.path.py(se)+1.1;const g0=demH(a.x+Math.cos(ang)*12,a.z+Math.sin(ang)*12);
          if(top-g0>0.3)stairsDown(a.x,a.z,ang,top,Math.min(g0,top-0.3),pw*0.9);}
      }
      const a=l.path.at(s,offF(s,1)+pw/2+0.5);addLabel(st[0],st[1],a.x,l.path.py(s)+7.5,a.z,'st',l.color,900);
      done.push({name:st[0],x:p.x,z:p.z,grp,off});
      if(!LM.find(m=>m.name.startsWith(st[0]+'駅')))LM.push({name:st[0]+'駅',en:st[1]+' Sta.',x:p.x,z:p.z,r:60,noLabel:true,station:true,travel:true,line:l.short});
    }}
}

/* ================= LOD: one box per 40 m cell with real building coverage & mean height ================= */
function maskPatch(mat){mat.onBeforeCompile=sh=>{sh.uniforms.uMask={value:maskTex};sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nuniform sampler2D uMask;').replace('#include <project_vertex>',`#include <project_vertex>
  {vec4 ic=modelMatrix*instanceMatrix*vec4(0.0,0.0,0.0,1.0);vec2 mu=(ic.xz-vec2(${GX0.toFixed(1)},${GZ0.toFixed(1)}))/vec2(${(CNX*CH).toFixed(1)},${(CNZ*CH).toFixed(1)});
  if(texture2D(uMask,mu).r>0.5)gl_Position=vec4(2.0,2.0,2.0,1.0);}`);};mat.customProgramCacheKey=()=>'lodmask';return mat;}
function buildLOD(){
  const [LNX,LNZ,LG0]=META.lod;const LG=LG0*2;const items=[];
  for(let j=0;j<LNZ-1;j+=2)for(let i=0;i<LNX-1;i+=2){let a=0,ah=0;for(const [di,dj] of [[0,0],[1,0],[0,1],[1,1]]){const k=(j+dj)*LNX+i+di;const c=(LODC[k]/255)**2;a+=c;ah+=c*LODH[k];}
    if(a/4<0.06)continue;items.push([i,j,Math.sqrt(a/4),ah/a]);}
  const m=new THREE.InstancedMesh(BOX,maskPatch(new THREE.MeshLambertMaterial({color:0xffffff})),items.length);const dm=new THREE.Object3D(),cc=new THREE.Color();let n=0;
  const cols=['#d9d6cc','#cfcbc0','#c7cbcf','#d6cfc4','#bdb7ae'];
  for(const [i,j,cv,hh] of items){const x=GX0+(i+1)*LG0,z=GZ0+(j+1)*LG0;const s=LG*cv*0.95;const h=Math.max(4,hh);
    dm.position.set(x,demH(x,z)-0.5,z);dm.scale.set(s,h,s);dm.updateMatrix();m.setMatrixAt(n,dm.matrix);m.setColorAt(n,cc.set(cols[(i*7+j*13)%cols.length]));n++;}
  m.count=n;m.frustumCulled=false;scene.add(m);
}

