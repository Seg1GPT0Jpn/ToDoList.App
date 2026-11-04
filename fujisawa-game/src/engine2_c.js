
/* ================= stations ================= */
class GB{ // geometry builder with position, normal, color, uv
  constructor(){this.p=[];this.n=[];this.c=[];this.u=[];}
  tri(a,b,c,nx,ny,nz,col,ua,ub,uc){const ex=b[0]-a[0],ey=b[1]-a[1],ez=b[2]-a[2],fx=c[0]-a[0],fy=c[1]-a[1],fz=c[2]-a[2];
    const cx=ey*fz-ez*fy,cy=ez*fx-ex*fz,cz=ex*fy-ey*fx;if(cx*nx+cy*ny+cz*nz<0){const t=b;b=c;c=t;const tu=ub;ub=uc;uc=tu;}
    this.p.push(...a,...b,...c);for(let i=0;i<3;i++){this.n.push(nx,ny,nz);this.c.push(col.r,col.g,col.b);}if(ua)this.u.push(...ua,...ub,...uc);else this.u.push(0,0,0,0,0,0);}
  quad(a,b,c,d,nx,ny,nz,col,uv){this.tri(a,b,c,nx,ny,nz,col,uv&&uv[0],uv&&uv[1],uv&&uv[2]);this.tri(a,c,d,nx,ny,nz,col,uv&&uv[0],uv&&uv[2],uv&&uv[3]);}
  /* oriented box in a local frame: centre (cx,cz), axis angle via (ux,uz), extents along u/v, y0..y1 */
  obox(cx,cz,ux,uz,hu,hv,y0,y1,col,faces=63){const vx=-uz,vz=ux;const P=(a,b,y)=>[cx+ux*a+vx*b,y,cz+uz*a+vz*b];
    const A=P(-hu,-hv,y0),B=P(hu,-hv,y0),C=P(hu,hv,y0),D=P(-hu,hv,y0),E=P(-hu,-hv,y1),F=P(hu,-hv,y1),G2=P(hu,hv,y1),H=P(-hu,hv,y1);
    if(faces&1)this.quad(E,F,G2,H,0,1,0,col);if(faces&2)this.quad(A,B,C,D,0,-1,0,col);
    if(faces&4)this.quad(A,B,F,E,-vx,0,-vz,col);if(faces&8)this.quad(D,C,G2,H,vx,0,vz,col);
    if(faces&16)this.quad(A,D,H,E,-ux,0,-uz,col);if(faces&32)this.quad(B,C,G2,F,ux,0,uz,col);}
  geo(){const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(this.p,3));g.setAttribute('normal',new THREE.Float32BufferAttribute(this.n,3));g.setAttribute('color',new THREE.Float32BufferAttribute(this.c,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(this.u,2));g.computeBoundingSphere();return g;}
  get empty(){return this.p.length===0;}
}
const _col=new THREE.Color(),_col2=new THREE.Color();
const C_=s=>new THREE.Color(s);
const COL={floor:C_('#cfc9bd'),tile:C_('#d8d3c8'),wallIn:C_('#efebe2'),gate:C_('#5d6670'),gateTop:C_('#2f8fd0'),machine:C_('#2d5f9a'),yellow:C_('#f2d33c'),ceiling:C_('#f4f2ec'),dark:C_('#3a3f45'),wood:C_('#c9a77c'),desk:C_('#c49a6c'),board:C_('#2f5a43'),locker:C_('#9aa3ab'),court:C_('#d8b07a'),line:C_('#ffffff'),tunnel:C_('#8e8f8c'),stair:C_('#c9c3b6')};
/* stairs: steps as boxes + OBB colliders, in a local frame */
function stairsGB(gb,colls,x,z,ang,yTop,yBot,w,col=COL.stair){const n=Math.max(1,Math.ceil((yTop-yBot)/0.28));const c=Math.cos(ang),s=Math.sin(ang);
  for(let i=0;i<n;i++){const d=(i+0.5)*0.42;const h=yTop-i*0.28;const cx=x+c*d,cz=z+s*d;gb.obox(cx,cz,c,s,0.22,w/2,yBot-0.2,h,col);colls&&colls.push(addOBB(cx,cz,0.22,w/2,ang,yBot-0.2,h));}
  return n*0.42;}
const PLATBUILT=[];
function lineAtPlat(cx,cz){
  let best=null;for(const k in LINES){const l=LINES[k];const r=l.path.near(cx,cz);const lim=l.mono?16:45;if(r.d<lim&&(!best||r.d<best.d))best={d:r.d,s:r.s,l};}return best;}
function platTop(l,s){if(l.mono){return l.beamY(s)-1.6-l.car.h-0.95-0.3+0.95+0.2;}return l.path.py(s)+1.1;}
function buildRealPlatforms(){
  const gb=new GB();const col=new THREE.Color('#d6d0c2'),edge=new THREE.Color('#bdb6a8');
  for(const p of PLATS){const n=p.length/2;let cx=0,cz=0;for(let i=0;i<n;i++){cx+=p[i*2];cz+=p[i*2+1];}cx/=n;cz/=n;if(inClear(cx,cz,PLAT_CLEAR))continue;
    const b0=lineAtPlat(cx,cz);if(!b0)continue;const line=b0.l;if(line.mono){let bs=null;for(const st of line.st){if(Math.abs(st.s-b0.s)<90&&(!bs||Math.abs(st.s-b0.s)<Math.abs(bs-b0.s)))bs=st.s;}if(bs!==null)b0.s=clamp(bs,line.halfT+2,line.path.L-line.halfT-2);}const top=platTop(line,b0.s);
    let gmin=1e9;for(let i=0;i<n;i++)gmin=Math.min(gmin,demH(p[i*2],p[i*2+1]));const under=top<gmin-3;const y0=under?top-1.2:Math.min(gmin-0.3,top-1.2);
    for(let i=0;i<n;i++){const j=(i+1)%n;const ax=p[i*2],az=p[i*2+1],bx=p[j*2],bz=p[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)continue;const nx=dz/len,nz=-dx/len;
      gb.quad([ax,y0,az],[bx,y0,bz],[bx,top,bz],[ax,top,az],nx,0,nz,edge);
      const ix=-nx*0.6,iz=-nz*0.6;gb.quad([ax+ix*0.5,top+0.015,az+iz*0.5],[bx+ix*0.5,top+0.015,bz+iz*0.5],[bx+ix,top+0.015,bz+iz],[ax+ix,top+0.015,az+iz],0,1,0,COL.yellow);}
    const contour=[];for(let i=0;i<n;i++)contour.push(new THREE.Vector2(p[i*2],p[i*2+1]));let tris=[];try{tris=THREE.ShapeUtils.triangulateShape(contour,[]);}catch(e){}
    for(const t of tris)gb.tri([p[t[0]*2],top,p[t[0]*2+1]],[p[t[1]*2],top,p[t[1]*2+1]],[p[t[2]*2],top,p[t[2]*2+1]],0,1,0,col);
    const b=addPoly(p,y0,top);b.tag=0;b.plat=true;
    // platform axis
    let bi=0,bl=0;for(let i=0;i<n;i++){const j=(i+1)%n;const l=Math.hypot(p[j*2]-p[i*2],p[j*2+1]-p[i*2+1]);if(l>bl){bl=l;bi=i;}}
    const j=(bi+1)%n;let ux=p[j*2]-p[bi*2],uz=p[j*2+1]-p[bi*2+1];const ul=Math.hypot(ux,uz)||1;ux/=ul;uz/=ul;let a0=1e9,a1=-1e9,w0=1e9,w1=-1e9;for(let i=0;i<n;i++){const a=(p[i*2]-cx)*ux+(p[i*2+1]-cz)*uz,w=-(p[i*2]-cx)*uz+(p[i*2+1]-cz)*ux;a0=Math.min(a0,a);a1=Math.max(a1,a);w0=Math.min(w0,w);w1=Math.max(w1,w);}
    PLATBUILT.push({x:cx,z:cz,line,top,b,ux,uz,a0,a1,w0,w1,under,gmin,stairs:0});
  }
  if(!gb.empty){const m=new THREE.Mesh(gb.geo(),MAT.top);m.receiveShadow=true;m.castShadow=true;scene.add(m);}
}
/* ticket gates & machines */
function gatesGB(gb,colls,cx,cz,ux,uz,len,y){const n=Math.max(3,Math.floor(len/1.5));const vx=-uz,vz=ux;
  for(let i=0;i<=n;i++){const a=-len/2+i*len/n;const x=cx+ux*a,z=cz+uz*a;gb.obox(x,z,ux,uz,0.15,0.75,y,y+1.0,COL.gate);gb.obox(x,z,ux,uz,0.16,0.2,y+1.0,y+1.05,COL.gateTop);colls&&colls.push(addOBB(x,z,0.15,0.75,Math.atan2(uz,ux),y,y+1.0));}}
function machinesGB(gb,colls,cx,cz,ux,uz,n,y){for(let i=0;i<n;i++){const a=(i-(n-1)/2)*1.1;const x=cx+ux*a,z=cz+uz*a;gb.obox(x,z,ux,uz,0.5,0.35,y,y+1.8,COL.machine);colls&&colls.push(addOBB(x,z,0.5,0.35,Math.atan2(uz,ux),y,y+1.8));}}
const STATIONS=[];
function buildStations(){
  buildRealPlatforms();
  const done=[];const sgb=new GB();
  for(const k in LINES){const l=LINES[k];
    for(const st of l.st){
      const s=clamp(st.s,l.halfT+2,l.path.L-l.halfT-2);st.s=s;const p=l.path.at(s);
      const grp=k==='odn'||k==='ods'?'od':k==='sot'||k==='izm'?'so':k;
      const dup=done.find(d=>d.name===st[0]&&d.grp===grp&&Math.hypot(d.x-p.x,d.z-p.z)<300);
      const realHere=PLATBUILT.filter(q=>q.line===l&&!q.gen&&Math.hypot(q.x-p.x,q.z-p.z)<l.plat/2+60);const under=!l.mono&&(realHere.length?realHere.every(q=>q.under):(l.path.flagAt(s)===2||[-60,0,60].every(o=>{const q=l.path.at(s+o);return l.path.py(s+o)<demH(q.x,q.z)-4.5;})));
      const hasReal=PLATBUILT.some(q=>q.line===l&&Math.hypot(q.x-p.x,q.z-p.z)<l.plat/2+60);
      if(!dup){
        const lbY=l.mono?l.beamY(s)+7:(under?demH(p.x,p.z)+9:l.path.py(s)+8);
        addLabel(st[0],st[1],p.x,lbY,p.z,'st',l.color,900);done.push({name:st[0],x:p.x,z:p.z,grp});
        const nm=(l.mono?'湘南モノレール ':'')+st[0]+'駅';if(!LM.find(m=>m.name===nm&&Math.hypot(m.x-p.x,m.z-p.z)<400))LM.push({name:nm,en:st[1]+' Sta.',x:p.x,z:p.z,r:60,noLabel:true,station:true,travel:true,line:l.short,mono:l.mono,under});
      }
      STATIONS.push({l,st,s,under,p});
      if(ST_CUSTOM[st[0]]&&ST_CUSTOM[st[0]].lines.has(k))continue;
      if(under){buildUnderground(l,st,s,hasReal);continue;}
      if(hasReal||dup)continue;
      generatedPlatforms(l,st,s);
    }}
  for(const n in ST_CUSTOM){try{ST_CUSTOM[n].build();}catch(e){console.error('station',n,e);}}
  // simple gate lines at the street end of ground-level platforms that are not under a concourse
  if(!sgb.empty){const m=new THREE.Mesh(sgb.geo(),MAT.top);scene.add(m);}
}
function generatedPlatforms(l,st,s){
  if(l.mono){const y=l.beamY(s);const fl=platTop(l,s);const p=l.path.at(s);const ang=Math.atan2(p.tz,p.tx);
    for(const sd of [-1,1]){const cx=p.x-p.tz*sd*3.0,cz=p.z+p.tx*sd*3.0;box(l.plat,0.6,2.4,'#d9dde1',cx,fl-0.6,cz,{ang});}
    box(l.plat+4,0.5,11,'#c8434a',p.x,y+2.0,p.z,{ang,col:false});const c=Math.cos(ang),sn=Math.sin(ang);
    for(const sd of [-1,1]){const ex=p.x+c*(l.plat/2)-p.tz*sd*3.0,ez=p.z+sn*(l.plat/2)+p.tx*sd*3.0;stairsDown(ex,ez,ang,fl,demH(ex+c*10,ez+sn*10),2.2);}return;}
  const pw=l.single?3:4.2;const offF=(ss,sd)=>l.path.laneOff(ss,sd)+sd*(l.car.w/2+0.1+pw/2);
  for(const sd of [-1,1]){
    for(let q=-l.plat/2;q<l.plat/2;q+=6){const a=l.path.at(s+q+3,offF(s+q+3,sd));const y=l.path.py(s+q+3);const ang=Math.atan2(a.tz,a.tx);
      const b=box(6.05,1.1,pw,'#d8d2c4',a.x,y,a.z,{ang});const ex=a.x+a.tz*sd*(pw/2-0.5),ez=a.z-a.tx*sd*(pw/2-0.5);box(6.05,0.04,0.35,'#f2d33c',ex,y+1.1,ez,{ang,col:false,cast:false});
      if(Math.abs(q)<l.plat*0.32){box(6.05,0.25,pw+0.6,'#8fa0ae',a.x,y+4.3,a.z,{ang,col:false,cast:false});}}
    for(let q=-l.plat*0.32;q<=l.plat*0.32;q+=12){const a=l.path.at(s+q,offF(s+q,sd));cyl(0.12,3.2,'#8fa0ae',a.x,l.path.py(s+q)+1.1,a.z,{cast:false});}
    for(const e of [-1,1]){const se=s+e*l.plat/2;const a=l.path.at(se,offF(se,sd));const ang=Math.atan2(a.tz,a.tx)+(e>0?0:Math.PI);const top=l.path.py(se)+1.1;const g0=demH(a.x+Math.cos(ang)*12,a.z+Math.sin(ang)*12);
      if(top-g0>0.3)stairsDown(a.x,a.z,ang,top,Math.min(g0,top-0.3),pw*0.9);}
  }
  // generated platforms are registered as platforms so the alighting search finds them
  for(const sd of [-1,1]){const a=l.path.at(s,offF(s,sd));PLATBUILT.push({x:a.x,z:a.z,line:l,top:l.path.py(s)+1.1,gen:true,ux:a.tx,uz:a.tz,a0:-l.plat/2,a1:l.plat/2,w0:-pw/2,w1:pw/2});}
}
/* underground station: platform hall + concourse, gates, stairs and street entrances */
const ENTRANCES=[];
function buildUnderground(l,st,s,hasReal){
  const p=l.path.at(s);const ux=p.tx,uz=p.tz,vx=-uz,vz=ux;const ang=Math.atan2(uz,ux);
  const py=l.path.py(s),top=py+1.1;const ground=demH(p.x,p.z);
  const lo=l.path.laneOff(s,-1),hi=l.path.laneOff(s,1);const half=l.plat/2+12;
  const reals=PLATBUILT.filter(q=>q.line===l&&Math.hypot(q.x-p.x,q.z-p.z)<l.plat/2+60);
  let wl=Math.min(lo,hi)-l.car.w/2-0.6,wr=Math.max(lo,hi)+l.car.w/2+0.6;
  for(const q of reals){if(q.b){const pp=q.b.pts;for(let i=0;i<pp.length;i+=2){const qs=(pp[i]-p.x)*vx+(pp[i+1]-p.z)*vz;wl=Math.min(wl,qs-1);wr=Math.max(wr,qs+1);}}else{const qs=(q.x-p.x)*vx+(q.z-p.z)*vz;wl=Math.min(wl,qs-3);wr=Math.max(wr,qs+3);}}
  const island=!reals.length&&Math.abs(hi-lo)>5;
  if(!reals.length){ // generate platforms
    if(island){const w=Math.abs(hi-lo)-l.car.w-0.3;const cx=p.x+vx*(lo+hi)/2,cz=p.z+vz*(lo+hi)/2;const P2=[];for(const [a,b] of [[-l.plat/2,-w/2],[l.plat/2,-w/2],[l.plat/2,w/2],[-l.plat/2,w/2]])P2.push(cx+ux*a+vx*b,cz+uz*a+vz*b);PLATS_EXTRA(P2,l,s,top);}
    else for(const sd of [-1,1]){const o=(sd>0?Math.max(lo,hi):Math.min(lo,hi))+sd*(l.car.w/2+0.1+2);const cx=p.x+vx*o,cz=p.z+vz*o;const P2=[];for(const [a,b] of [[-l.plat/2,-2],[l.plat/2,-2],[l.plat/2,2],[-l.plat/2,2]])P2.push(cx+ux*a+vx*b,cz+uz*a+vz*b);PLATS_EXTRA(P2,l,s,top);wl=Math.min(wl,o-2.6);wr=Math.max(wr,o+2.6);}
  }
  const ccx=p.x+vx*(wl+wr)/2,ccz=p.z+vz*(wl+wr)/2,hw=(wr-wl)/2;
  const y0=py-0.5,yPlatCeil=top+4.2,yc=yPlatCeil+0.4,yCeil=yc+3.6;
  const gb=new GB();const colls=[];
  // platform hall shell (inner faces) and tunnel continuing both ways
  gb.obox(ccx,ccz,ux,uz,half,hw,y0,yPlatCeil,COL.tunnel,2|4|8|16|32);
  for(const sd of [-1,1]){const tcx=ccx+ux*sd*(half+60),tcz=ccz+uz*sd*(half+60);gb.obox(tcx,tcz,ux,uz,60,hw,y0,yPlatCeil,COL.dark,2|4|8);}
  // concourse floor with stair openings
  const stairsAt=[];
  const plats=PLATBUILT.filter(q=>q.line===l&&Math.hypot(q.x-p.x,q.z-p.z)<l.plat/2+60);
  for(const q of plats){const qa=(q.x-ccx)*ux+(q.z-ccz)*uz,qv=(q.x-ccx)*vx+(q.z-ccz)*vz;stairsAt.push({a:qa-8,v:qv,w:Math.min(2.6,(q.w1-q.w0)-0.8),top:q.top});}
  const conc=new GB();
  // floor pieces: split around stair openings (openings are 3.6 m long)
  const holes=stairsAt.map(h=>({a0:h.a+8-4.2,a1:h.a+8+0.4,v0:h.v-h.w/2-0.2,v1:h.v+h.w/2+0.2}));
  const fl=[[-half,half]];
  const slab=(a0,a1,v0,v1)=>{if(a1-a0<0.2||v1-v0<0.2)return;const cx=ccx+ux*(a0+a1)/2+vx*(v0+v1)/2,cz=ccz+uz*(a0+a1)/2+vz*(v0+v1)/2;conc.obox(cx,cz,ux,uz,(a1-a0)/2,(v1-v0)/2,yc-0.4,yc,COL.tile,1|2);colls.push(addOBB(cx,cz,(a1-a0)/2,(v1-v0)/2,ang,yc-0.4,yc));};
  // simple strip decomposition across v
  const vcuts=[-hw];for(const h of holes){vcuts.push(h.v0,h.v1);}vcuts.push(hw);vcuts.sort((a,b)=>a-b);
  for(let i=0;i<vcuts.length-1;i++){const v0=vcuts[i],v1=vcuts[i+1];if(v1-v0<0.05)continue;const vm=(v0+v1)/2;const hs=holes.filter(h=>vm>h.v0&&vm<h.v1).sort((a,b)=>a.a0-b.a0);let a=-half;for(const h of hs){slab(a,h.a0,v0,v1);a=h.a1;}slab(a,half,v0,v1);}
  conc.obox(ccx,ccz,ux,uz,half,hw,yc,yCeil,COL.ceiling,1|4|8|16|32);
  // stairs platform -> concourse
  for(const h of stairsAt){const x=ccx+ux*h.a+vx*h.v,z=ccz+uz*h.a+vz*h.v;stairsGB(conc,colls,x,z,ang,yc,h.top,h.w);}
  // gates across the concourse, machines, walls
  const ga=-half+14;gatesGB(conc,colls,ccx+ux*ga,ccz+uz*ga,vx,vz,hw*2-1,yc);machinesGB(conc,colls,ccx+ux*(-half+3)+vx*(hw-0.6),ccz+uz*(-half+3)+vz*(hw-0.6),ux,uz,4,yc);
  for(const sd of [-1,1]){colls.push(addOBB(ccx+vx*sd*(hw+0.2),ccz+vz*sd*(hw+0.2),half,0.2,ang,y0,yCeil));}
  for(const sd of [-1,1]){colls.push(addOBB(ccx+ux*sd*(half+0.2),ccz+uz*sd*(half+0.2),0.2,hw,ang,yc,yCeil));}
  const m1=new THREE.Mesh(gb.geo(),new THREE.MeshLambertMaterial({vertexColors:true,side:THREE.DoubleSide}));scene.add(m1);
  const m2=new THREE.Mesh(conc.geo(),new THREE.MeshLambertMaterial({vertexColors:true,side:THREE.DoubleSide}));scene.add(m2);
  // lights strip
  const lg=new GB();for(let a=-half+4;a<half;a+=8){lg.obox(ccx+ux*a,ccz+uz*a,ux,uz,1.6,0.15,yCeil-0.08,yCeil-0.02,C_('#ffffff'),2);lg.obox(ccx+ux*a,ccz+uz*a,ux,uz,1.6,0.15,yPlatCeil-0.08,yPlatCeil-0.02,C_('#ffffff'),2);}
  scene.add(new THREE.Mesh(lg.geo(),new THREE.MeshBasicMaterial({vertexColors:true})));
  const zone={cx:ccx,cz:ccz,c:Math.cos(ang),s:Math.sin(ang),hl:half+120,hw:hw+0.3,y0:y0-1,y1:yCeil+0.5,name:st[0],line:l,floorC:yc,conc:{cx:ccx+ux*(-half+5),cz:ccz+uz*(-half+5)}};
  ZONES.push(zone);INDOOR.push({cx:ccx,cz:ccz,c:zone.c,s:zone.s,hl:half,hw,y0:y0,y1:yCeil,zone:true});
  addLabel(st[0],st[1],ccx,yc+2.6,ccz,'st',l.color,120,0.5);
  // street entrances (OSM subway entrances near the station, else one above the concourse end)
  let ents=(META.entrances||[]).filter(e=>Math.hypot(e[0]-p.x,e[1]-p.z)<320);
  if(!ents.length)ents=[[ccx+ux*(-half+5)+vx*(hw+6),ccz+uz*(-half+5)+vz*(hw+6),'']];
  for(const e of ents.slice(0,6)){const g=demH(e[0],e[1]);const ea=Math.atan2(uz,ux);
    box(3.4,3,4.6,'#d8dde2',e[0],g,e[1],{ang:ea,col:false});box(3.8,0.3,5,l.color,e[0],g+3,e[1],{ang:ea,col:false});
    for(const sd of [-1,1])box(0.25,3,4.6,'#b9c0c8',e[0]+Math.cos(ea+Math.PI/2)*sd*1.6,g,e[1]+Math.sin(ea+Math.PI/2)*sd*1.6,{ang:ea});
    ENTRANCES.push({x:e[0],z:e[1],y:g,zone,name:st[0],line:l});addLabel(l.short==='ブルーライン'?'Ⓑ '+st[0]:st[0],'入口',e[0],g+5,e[1],'st',l.color,250,0.6);}
}
function PLATS_EXTRA(p,l,s,top){const n=p.length/2;const gb=new GB();const col=new THREE.Color('#d6d0c2');const y0=top-1.2;
  for(let i=0;i<n;i++){const j=(i+1)%n;const ax=p[i*2],az=p[i*2+1],bx=p[j*2],bz=p[j*2+1];const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);const nx=dz/len,nz=-dx/len;gb.quad([ax,y0,az],[bx,y0,bz],[bx,top,bz],[ax,top,az],nx,0,nz,col);}
  gb.quad([p[0],top,p[1]],[p[2],top,p[3]],[p[4],top,p[5]],[p[6],top,p[7]],0,1,0,col);scene.add(new THREE.Mesh(gb.geo(),new THREE.MeshLambertMaterial({vertexColors:true,side:THREE.DoubleSide})));
  const b=addPoly(p,y0,top);b.tag=0;b.plat=true;let cx=0,cz=0;for(let i=0;i<n;i++){cx+=p[i*2];cz+=p[i*2+1];}cx/=n;cz/=n;
  const ux=(p[2]-p[0]),uz=(p[3]-p[1]);const ul=Math.hypot(ux,uz);PLATBUILT.push({x:cx,z:cz,line:l,top,b,ux:ux/ul,uz:uz/ul,a0:-ul/2,a1:ul/2,w0:-Math.hypot(p[6]-p[0],p[7]-p[1])/2,w1:Math.hypot(p[6]-p[0],p[7]-p[1])/2,under:true});}
function zoneAt(x,z,y){for(const Z of ZONES){const dx=x-Z.cx,dz=z-Z.cz;const lx=dx*Z.c+dz*Z.s,lz=-dx*Z.s+dz*Z.c;if(Math.abs(lx)<Z.hl&&Math.abs(lz)<Z.hw&&y>Z.y0-0.5&&y<Z.y1)return Z;}return null;}

/* ================= LOD ================= */
function maskPatch(mat){mat.onBeforeCompile=sh=>{sh.uniforms.uMask={value:maskTex};sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nuniform sampler2D uMask;').replace('#include <project_vertex>',`#include <project_vertex>
  {vec4 ic=modelMatrix*instanceMatrix*vec4(0.0,0.0,0.0,1.0);vec2 mu=(ic.xz-vec2(${X0.toFixed(1)},${Z0.toFixed(1)}))/vec2(${(CNX*CH).toFixed(1)},${(CNZ*CH).toFixed(1)});
  if(texture2D(uMask,mu).r>0.5)gl_Position=vec4(2.0,2.0,2.0,1.0);}`);};mat.customProgramCacheKey=()=>'lodmask';return mat;}
function buildLOD(){
  const [LNX,LNZ,LG0]=META.lod;const LG=LG0*2;const items=[];
  for(let j=0;j<LNZ-1;j+=2)for(let i=0;i<LNX-1;i+=2){let a=0,ah=0;for(const [di,dj] of [[0,0],[1,0],[0,1],[1,1]]){const k=(j+dj)*LNX+i+di;const c=(LODC[k]/255)**2;a+=c;ah+=c*LODH[k];}
    if(a/4<0.06)continue;items.push([i,j,Math.sqrt(a/4),ah/a]);}
  const m=new THREE.InstancedMesh(BOX,maskPatch(new THREE.MeshLambertMaterial({color:0xffffff})),Math.max(1,items.length));const dm=new THREE.Object3D(),cc=new THREE.Color();let n=0;
  const cols=['#d9d6cc','#cfcbc0','#c7cbcf','#d6cfc4','#bdb7ae'];
  for(const [i,j,cv,hh] of items){const x=X0+(i+1)*LG0,z=Z0+(j+1)*LG0;const s=LG*cv*0.95;const h=Math.max(4,hh);
    dm.position.set(x,demH(x,z)-0.5,z);dm.scale.set(s,h,s);dm.updateMatrix();m.setMatrixAt(n,dm.matrix);m.setColorAt(n,cc.set(cols[(i*7+j*13)%cols.length]));n++;}
  m.count=n;m.frustumCulled=false;scene.add(m);
}

/* ================= detailed chunks ================= */
const CHUNKS=new Map();
const chunkKey=(i,j)=>i*1000+j;
const WALLH=['#f4ede0','#efe6d2','#f8f5ee','#e8dcc5','#dfe6e8','#f1e1cf','#e6ebda','#f5f0e7','#d9cbb5','#efd9ca','#dde2ee','#ebe6df'];
const WALLO=['#e6e3db','#d6dce1','#efe9de','#cfd5d5','#e2d6c5','#c2cad1','#eee5da','#dcd7cc','#b9c3cb'];
const ROOFG=['#545c68','#6f4a3a','#3f5776','#848a94','#8f5641','#4b6658','#664a37','#434c58','#2f3d52','#69707a'];
const ROOFF=['#9aa1a8','#a7a49e','#8f969c','#b2b0aa','#959089'];
const TRUNK=new THREE.CylinderGeometry(0.14,0.2,1,5).translate(0,0.5,0);
const CROWN=new THREE.IcosahedronGeometry(1,0);
const PINEC=mergeGeos([new THREE.IcosahedronGeometry(1,0).scale(1.6,0.45,1.6),new THREE.IcosahedronGeometry(1,0).scale(1.1,0.4,1.1).translate(0.7,0.7,0.3),new THREE.IcosahedronGeometry(1,0).scale(0.9,0.35,0.9).translate(-0.6,1.1,-0.2)]);
const PALMC=(()=>{const l=[];for(let k=0;k<9;k++){const g=new THREE.BoxGeometry(3.8,0.08,0.8).translate(1.9,0,0);g.rotateZ(-0.5);g.rotateY(k/9*Math.PI*2);l.push(g);}return mergeGeos(l);})();
const DESKG=mergeGeos([new THREE.BoxGeometry(0.62,0.04,0.45).translate(0,0.72,0),new THREE.BoxGeometry(0.05,0.7,0.05).translate(-0.27,0.35,-0.19),new THREE.BoxGeometry(0.05,0.7,0.05).translate(0.27,0.35,-0.19),new THREE.BoxGeometry(0.05,0.7,0.05).translate(-0.27,0.35,0.19),new THREE.BoxGeometry(0.05,0.7,0.05).translate(0.27,0.35,0.19),new THREE.BoxGeometry(0.4,0.04,0.38).translate(0,0.44,0.5),new THREE.BoxGeometry(0.4,0.42,0.04).translate(0,0.65,0.7)]);
const SHARED=new Set([TRUNK,CROWN,PINEC,PALMC,DESKG]);
function nearLineY(x,z,r){const b=lineYAt(x,z,r);return b?b.y:null;}
const TERRAINMAT=new THREE.MeshLambertMaterial({vertexColors:true});
const INMAT=new THREE.MeshLambertMaterial({vertexColors:true,side:THREE.DoubleSide});
function buildChunk(ci,cj){
  const cx0=X0+ci*CH,cz0=Z0+cj*CH;const grp=new THREE.Group();const colls=[];const indoor=[];const ci2=CIDX[cj*CNX+ci];
  rand=mulberry32(ci*7919+cj*104729+11);
  const step=isTouch?10:5,n=Math.round(CH/step);
  const geo=new THREE.PlaneGeometry(CH,CH,n,n);geo.rotateX(-Math.PI/2);geo.translate(cx0+CH/2,0,cz0+CH/2);
  const pos=geo.attributes.position,cnt=pos.count,col=new Float32Array(cnt*3),H=new Float32Array(cnt);
  for(let i=0;i<cnt;i++){H[i]=heightAt(pos.getX(i),pos.getZ(i));pos.setY(i,H[i]);}
  for(let i=0;i<cnt;i++){const x=pos.getX(i),z=pos.getZ(i),h=H[i];const ix=i%(n+1),iz=Math.floor(i/(n+1));
    const hr=H[i+(ix<n?1:-1)],hd=H[i+(iz<n?n+1:-(n+1))];const slope=Math.max(Math.abs(hr-h),Math.abs(hd-h))/step;
    const k=ci2*N1*N1+Math.round((z-cz0)/GS)*N1+Math.round((x-cx0)/GS);const c=groundColorAt(k,x,z,h,slope);col[i*3]=c.r;col[i*3+1]=c.g;col[i*3+2]=c.b;}
  geo.setAttribute('color',new THREE.BufferAttribute(col,3));geo.computeVertexNormals();
  const pls=placesNearRect(cx0,cz0,cx0+CH,cz0+CH);const tm=new THREE.Mesh(geo,pls.length?photoMat(pls,'ground'):TERRAINMAT);tm.receiveShadow=true;grp.add(tm);
  {const wb=new GB();const base=ci2*N1*N1;
    for(let j=0;j<N1-1;j++)for(let i=0;i<N1-1;i++){const k=base+j*N1+i;if(!(LCC8[k]===1&&DEMC[k]>0))continue;const y=DEMC[k]*0.2;const x=cx0+i*GS-GS/2,z=cz0+j*GS-GS/2;wb.quad([x,y,z],[x+GS,y,z],[x+GS,y,z+GS],[x,y,z+GS],0,1,0,_col.set('#ffffff'));}
    if(!wb.empty){const wm=new THREE.Mesh(wb.geo(),MAT.water);wm.receiveShadow=true;grp.add(wm);}}
  {const rb=new GB();const rl=ROADCH.get(cj*CNX+ci)||[];
    for(const ri of rl){const r=ROADS[ri];if(r.fl&2)continue;const P=r.path;const cc=_col2.set(RCOL[r.c]);const yoff=0.22-r.c*0.015;const hw=r.w/2;const segs=P.segs;
      for(let si=0;si<segs.length;si++){const g=segs[si];const mx=g.x+g.dx/2,mz=g.z+g.dz/2;if(mx<cx0||mx>=cx0+CH||mz<cz0||mz>=cz0+CH)continue;if(HOLES.length&&inHole(mx,mz,1))continue;
        const nseg=Math.max(1,Math.ceil(g.len/5));const prev=segs[si-1],next=segs[si+1];
        const nrm=(a,b)=>{if(!a)return[-b.tz,b.tx];if(!b)return[-a.tz,a.tx];let nx=-(a.tz+b.tz),nz=a.tx+b.tx;const l=Math.hypot(nx,nz)||1;nx/=l;nz/=l;const dot=nx*(-b.tz)+nz*b.tx;const k=1/Math.max(0.5,dot);return[nx*k,nz*k];};
        const n0=nrm(prev,g),n1=nrm(g,next);let lastL=null,lastR=null;
        for(let t=0;t<=nseg;t++){const f=t/nseg;const s=g.s+g.len*f;const x=g.x+g.dx*f,z=g.z+g.dz*f;const nx=lerp(n0[0],n1[0],f),nz=lerp(n0[1],n1[1],f);
          const lx=x+nx*hw,lz=z+nz*hw,rx=x-nx*hw,rz=z-nz*hw;let yl,yr;
          if(r.fl&1){yl=yr=r.path.py(s);}else{yl=demH(lx,lz)+yoff;yr=demH(rx,rz)+yoff;const yc=demH(x,z)+yoff;yl=Math.max(yl,yc-0.4);yr=Math.max(yr,yc-0.4);}
          const Lp=[lx,yl,lz],Rp=[rx,yr,rz];if(lastL){rb.tri(lastL,lastR,Rp,0,1,0,cc);rb.tri(lastL,Rp,Lp,0,1,0,cc);}lastL=Lp;lastR=Rp;}
        if(r.c<=3&&!(r.fl&1)){const wc=_col.set('#eeeadc');for(let s=g.s;s<g.s+g.len-3;s+=8){const p0=P.at(s),p1=P.at(Math.min(s+4,g.s+g.len));const nx=-g.tz*0.12,nz=g.tx*0.12;const y0=demH(p0.x,p0.z)+yoff+0.02,y1=demH(p1.x,p1.z)+yoff+0.02;
            rb.tri([p0.x+nx,y0,p0.z+nz],[p1.x+nx,y1,p1.z+nz],[p1.x-nx,y1,p1.z-nz],0,1,0,wc);rb.tri([p0.x+nx,y0,p0.z+nz],[p1.x-nx,y1,p1.z-nz],[p0.x-nx,y0,p0.z-nz],0,1,0,wc);}}
        if(r.fl&1&&r.c<=7){const rc=_col.set('#d8d4ca');for(const sd of [1,-1]){const ax=g.x+n0[0]*hw*sd,az=g.z+n0[1]*hw*sd,bx=g.x+g.dx+n1[0]*hw*sd,bz=g.z+g.dz+n1[1]*hw*sd;const ya=r.path.py(g.s),yb=r.path.py(g.s+g.len);
            rb.quad([ax,ya-0.9,az],[bx,yb-0.9,bz],[bx,yb+1.0,bz],[ax,ya+1.0,az],-g.tz*sd,0,g.tx*sd,rc);rb.quad([ax,ya-0.9,az],[ax,ya+1.0,az],[bx,yb+1.0,bz],[bx,yb-0.9,bz],g.tz*sd,0,-g.tx*sd,rc);}}}}
    buildTracksInto(rb,ci,cj);
    if(!rb.empty){const m=new THREE.Mesh(rb.geo(),MAT.road);m.receiveShadow=true;grp.add(m);}}
  const wH=new GB(),wO=new GB(),tops=new GB(),gh=new GB(),inn=new GB(),proof=new GB(),fac=new GB();const desks=[];
  {const v=new DataView(BLDS.buffer,BLDS.byteOffset,BLDS.byteLength);let o=BOFFS[ci2];const end=BOFFS[ci2+1];let bi=0;
    while(o<end){const nn=v.getUint8(o),fl=v.getUint8(o+1),h=v.getUint16(o+2,true)/10,minh=v.getUint8(o+4);let x=v.getInt16(o+5,true),z=v.getInt16(o+7,true);const sk=v.getInt16(o+9,true),kind=v.getUint8(o+11);o+=12;
      const pts=new Float32Array(nn*2);pts[0]=cx0+x/4;pts[1]=cz0+z/4;for(let i=1;i<nn;i++){x+=v.getInt8(o);z+=v.getInt8(o+1);o+=2;pts[i*2]=cx0+x/4;pts[i*2+1]=cz0+z/4;}
      bi++;addBuilding(pts,h,minh,fl&3,kind,hashf(ci2*100003+bi),sk,{wH,wO,tops,gh,inn,desks,colls,indoor,fac});}
    for(const b of PLB.get(cj*CNX+ci)||[])addPlateau(b,{wH,wO,tops,gh,inn,desks,colls,indoor,proof,fac});}
  if(!wH.empty){const m=new THREE.Mesh(wH.geo(),MAT.wallH);m.castShadow=true;m.receiveShadow=true;grp.add(m);}
  if(!wO.empty){const m=new THREE.Mesh(wO.geo(),MAT.wallO);m.castShadow=true;m.receiveShadow=true;grp.add(m);}
  if(!tops.empty){const m=new THREE.Mesh(tops.geo(),MAT.top);m.castShadow=true;m.receiveShadow=true;grp.add(m);}
  if(!fac.empty){const m=new THREE.Mesh(fac.geo(),facadeMat());m.castShadow=true;m.receiveShadow=true;grp.add(m);}
  if(!proof.empty){const m=new THREE.Mesh(proof.geo(),pls.length?photoMat(pls,'roof'):MAT.top);m.castShadow=true;m.receiveShadow=true;grp.add(m);}
  if(!gh.empty){const m=new THREE.Mesh(gh.geo(),MAT.green);grp.add(m);}
  if(!inn.empty){const m=new THREE.Mesh(inn.geo(),INMAT);m.receiveShadow=true;grp.add(m);}
  if(desks.length){const dm=new THREE.Object3D();const im=new THREE.InstancedMesh(DESKG,M('#c49a6c'),desks.length);desks.forEach((d,i)=>{dm.position.set(d[0],d[1],d[2]);dm.rotation.set(0,-d[3],0);dm.updateMatrix();im.setMatrixAt(i,dm.matrix);});im.computeBoundingSphere();grp.add(im);}
  const L2={round:[],autumn:[],pine:[],palm:[]};
  for(let z=cz0+3;z<cz0+CH;z+=8)for(let x=cx0+3;x<cx0+CH;x+=8){const px=x+rr(-3,3),pz=z+rr(-3,3);const c=lcAt(px,pz);let p=0;
    if(c===2)p=0.8;else if(c===3)p=0.12;else if(c===10)p=0.3;else if(c===11)p=0.06;else if(c===0)p=0.035;else if(c===7)p=0.04;
    if(pls.length&&photoAt(px,pz)>0.5)p*=0.5;if(HOLES.length&&inHole(px,pz,2))continue;if(rand()>=p)continue;const h=heightAt(px,pz);if(h<0.4)continue;
    let blocked=false;for(const b of collNear(px,pz)){if(insideColl(b,px,pz,1.2)){blocked=true;break;}}if(blocked)continue;
    const fn=FIDX.nearest(px,pz);if(fn){let nr=false;for(const v of fn.values())if(Math.sqrt(v.d2)<v.data.half+2)nr=true;if(nr)continue;}
    const coastD=coastZ(px)-pz;const kind=(c===2&&coastD<900&&coastD>0)?'pine':(rand()<0.1?'autumn':'round');L2[kind].push({x:px,y:h,z:pz,s:rr(0.8,1.3)*(c===0?0.8:1)});}
  for(const p of PALMS){if(p[0]>=cx0&&p[0]<cx0+CH&&p[2]>=cz0&&p[2]<cz0+CH)L2.palm.push({x:p[0],y:p[1],z:p[2],s:1});}
  buildTreesInto(grp,L2);
  for(const z of indoor)INDOOR.push(z);
  scene.add(grp);
  return{grp,colls,ci,cj,indoor};
}
const KIND_WALL={5:'#c8432f',3:'#c8d0d6',4:'#ece4d2',8:'#eef4f2',11:'#e7e2d6'};
function rectOf(pts){const n=pts.length/2;let bi=0,bl=0;for(let i=0;i<n;i++){const j=(i+1)%n;const l=Math.hypot(pts[j*2]-pts[i*2],pts[j*2+1]-pts[i*2+1]);if(l>bl){bl=l;bi=i;}}
  const j=(bi+1)%n;let ux=pts[j*2]-pts[bi*2],uz=pts[j*2+1]-pts[bi*2+1];const ul=Math.hypot(ux,uz)||1;ux/=ul;uz/=ul;let cx=0,cz=0;for(let i=0;i<n;i++){cx+=pts[i*2];cz+=pts[i*2+1];}cx/=n;cz/=n;
  let a0=1e9,a1=-1e9,b0=1e9,b1=-1e9;for(let i=0;i<n;i++){const a=(pts[i*2]-cx)*ux+(pts[i*2+1]-cz)*uz,b=-(pts[i*2]-cx)*uz+(pts[i*2+1]-cz)*ux;a0=Math.min(a0,a);a1=Math.max(a1,a);b0=Math.min(b0,b);b1=Math.max(b1,b);}
  const mx=(a0+a1)/2,mb=(b0+b1)/2;return{cx:cx+ux*mx-uz*mb,cz:cz+uz*mx+ux*mb,ux,uz,hu:(a1-a0)/2,hv:(b1-b0)/2};}
function addBuilding(pts,h,minh,roofT,kind,r,sk,G){
  const n=pts.length/2;let cx=0,cz=0;for(let i=0;i<n;i++){cx+=pts[i*2];cz+=pts[i*2+1];}cx/=n;cz/=n;
  for(const e of EXCL){if(e[2]>0&&Math.hypot(cx-e[0],cz-e[1])<e[2])return;}if(BLD_CLEAR.length&&inClear(cx,cz))return;
  let gmin=1e9,gmax=-1e9;for(let i=0;i<n;i++){const g=demH(pts[i*2],pts[i*2+1]);gmin=Math.min(gmin,g);gmax=Math.max(gmax,g);}
  if(gmin<-0.5)return;
  let y0=gmin-0.3,y1=gmin+h;
  let ly=null;for(let i=0;i<n&&ly===null;i++)ly=nearLineY(pts[i*2],pts[i*2+1],5);if(ly===null)ly=nearLineY(cx,cz,5);
  const lyB=lineYAt(cx,cz,40);if(ly!==null&&lyB&&lyB.fl===2)ly=null; // tracks underground: building stays on the street
  if(minh>0)y0=gmin+minh;
  if(ly!==null){if(kind===7||roofT===2){y0=ly+4.6;y1=y0+0.5;}else{const area=Math.abs(polyArea(pts));if(area>120){buildConcourse(pts,ly,gmin,h,r,G);return;}y0=Math.max(y0,ly+6.8);y1=Math.max(y1,y0+5);}}
  if(roofT===2||kind===7){y0=Math.max(y0,y1-0.6);}
  if(sk>=0&&(kind===4||kind===11)){const R=rectOf(pts);if(R.hv>=4&&R.hu>=8&&R.hu*R.hv*4<6000){if(kind===11||(R.hu<26&&R.hv>11&&h<16&&R.hu/R.hv<2.2&&r<0.35)){buildGym(R,gmin,h,G);return;}buildSchool(R,gmin,h,G,sk);return;}}
  const office=h>=10.5||kind===2||kind===3||kind===4||kind===10;
  if(kind!==8){const area=Math.abs(polyArea(pts));const sty=facadeStyle(0,y1-y0,area,r,kind);const sh0=office?3.4:2.9;const nst=Math.max(1,Math.round((y1-y0)/sh0));
    const pal=office?WALLO:WALLH;const wc=_col.set(KIND_WALL[kind]||pal[Math.floor(r*pal.length)]).lerp(_col2.set('#ffffff'),0.45).clone();facadeWalls(G.fac,pts,y0,y1,wc,sty,(y1-y0)/nst);}
  else{const wall=_col.set('#eef4f2');const U=CELLH.w*CELLH.cols,V=CELLH.h*CELLH.rows;let per=0;
  for(let i=0;i<n;i++){const j=(i+1)%n;const ax=pts[i*2],az=pts[i*2+1],bx=pts[j*2],bz=pts[j*2+1];const dx=bx-ax,dz=bz-az;const len=Math.hypot(dx,dz);if(len<0.05)continue;
    const nx=dz/len,nz=-dx/len;const u0=per/U,u1=(per+len)/U;const v1=(y1-y0)/V;per+=len;
    G.gh.tri([ax,y0,az],[bx,y0,bz],[bx,y1,bz],nx,0,nz,wall,[u0,0],[u1,0],[u1,v1]);G.gh.tri([ax,y0,az],[bx,y1,bz],[ax,y1,az],nx,0,nz,wall,[u0,0],[u1,v1],[u0,v1]);}}
  if(roofT===1){roofOn(pts,cx,cz,y1,kind,r,G.tops);}
  else{const tris=tri2(pts);const tc=_col2.set(kind===8?'#eef4f2':ROOFF[Math.floor(r*991)%ROOFF.length]);
    for(const t of tris){const a=t[0],b=t[1],c=t[2];(kind===8?G.gh:G.tops).tri([pts[a*2],y1,pts[a*2+1]],[pts[b*2],y1,pts[b*2+1]],[pts[c*2],y1,pts[c*2+1]],0,1,0,tc);}
    if(roofT===2||kind===7){for(const t of tris){const a=t[0],b=t[1],c=t[2];G.tops.tri([pts[a*2],y0,pts[a*2+1]],[pts[b*2],y0,pts[b*2+1]],[pts[c*2],y0,pts[c*2+1]],0,-1,0,tc);}}}
  G.colls.push(addPoly(pts,y0,y1+(roofT===1?0.6:0)));
}
function polyArea(p){let a=0;const n=p.length/2;for(let i=0;i<n;i++){const j=(i+1)%n;a+=p[i*2]*p[j*2+1]-p[j*2]*p[i*2+1];}return a/2;}
function tri2(pts,holes=[]){const contour=[];const n=pts.length/2;for(let i=0;i<n;i++)contour.push(new THREE.Vector2(pts[i*2],pts[i*2+1]));const hs=holes.map(h=>h.map(q=>new THREE.Vector2(q[0],q[1])));
  try{const t=THREE.ShapeUtils.triangulateShape(contour,hs);if(!hs.length)return t;const all=[...contour,...hs.flat()];return t.map(tr=>tr.map(i=>i)).map(tr=>({all,tr}));}catch(e){return[];}}
function roofOn(pts,cx,cz,y1,kind,r,tops){const n=pts.length/2;
  let bi=0,bl=0;for(let i=0;i<n;i++){const j=(i+1)%n;const l=Math.hypot(pts[j*2]-pts[i*2],pts[j*2+1]-pts[i*2+1]);if(l>bl){bl=l;bi=i;}}
  const j=(bi+1)%n;let ux=pts[j*2]-pts[bi*2],uz=pts[j*2+1]-pts[bi*2+1];const ul=Math.hypot(ux,uz);ux/=ul;uz/=ul;const vx=-uz,vz=ux;
  let a0=1e9,a1=-1e9,b0=1e9,b1=-1e9;for(let i=0;i<n;i++){const px=pts[i*2]-cx,pz=pts[i*2+1]-cz;const a=px*ux+pz*uz,b=px*vx+pz*vz;a0=Math.min(a0,a);a1=Math.max(a1,a);b0=Math.min(b0,b);b1=Math.max(b1,b);}
  const la=a1-a0,lb=b1-b0;const ov=0.35;a0-=ov;a1+=ov;b0-=ov;b1+=ov;const ac=(a0+a1)/2,bc=(b0+b1)/2;const rh=Math.min(Math.min(la,lb)*0.38,3.6);
  const W=(a,b,y)=>[cx+ux*a+vx*b,y,cz+uz*a+vz*b];const rc=_col2.set(kind===5?'#3c4a44':ROOFG[Math.floor(r*997)%ROOFG.length]);const hip=r>0.55;
  if(la>=lb){const ra0=hip?a0+Math.min(lb/2,la/3):a0,ra1=hip?a1-Math.min(lb/2,la/3):a1;const A=W(a0,b0,y1),B=W(a1,b0,y1),C=W(a1,b1,y1),D=W(a0,b1,y1),E=W(ra0,bc,y1+rh),F=W(ra1,bc,y1+rh);
    tops.tri(A,B,F,0,1,0,rc);tops.tri(A,F,E,0,1,0,rc);tops.tri(D,E,F,0,1,0,rc);tops.tri(D,F,C,0,1,0,rc);tops.tri(A,E,D,0,1,0,rc);tops.tri(B,C,F,0,1,0,rc);}
  else{const rb0=hip?b0+Math.min(la/2,lb/3):b0,rb1=hip?b1-Math.min(la/2,lb/3):b1;const A=W(a0,b0,y1),B=W(a1,b0,y1),C=W(a1,b1,y1),D=W(a0,b1,y1),E=W(ac,rb0,y1+rh),F=W(ac,rb1,y1+rh);
    tops.tri(A,D,F,0,1,0,rc);tops.tri(A,F,E,0,1,0,rc);tops.tri(B,E,F,0,1,0,rc);tops.tri(B,F,C,0,1,0,rc);tops.tri(A,E,B,0,1,0,rc);tops.tri(D,C,F,0,1,0,rc);}}
/* wall segment with a window texture outside and plain inside, gaps given as [from,to] along the edge */
function wallSeg(G,ax,az,bx,bz,y0,y1,gaps,office,colOut,colIn,colls,thick=0.25){
  const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)return;const tx=dx/len,tz=dz/len,nx=tz,nz=-tx;const cw=office?CELLO:CELLH;const U=cw.w*cw.cols,V=cw.h*cw.rows;
  const pieces=[];let a=0;for(const g of (gaps||[]).slice().sort((p,q)=>p[0]-q[0])){if(g[0]>a)pieces.push([a,Math.min(g[0],len),0]);pieces.push([Math.max(0,g[0]),Math.min(len,g[1]),g[2]||2.4]);a=g[1];}if(a<len)pieces.push([a,len,0]);
  for(const [s0,s1,gh] of pieces){if(s1-s0<0.02)continue;const P0=[ax+tx*s0,az+tz*s0],P1=[ax+tx*s1,az+tz*s1];const yb=gh>0?y0+gh:y0;if(yb>=y1)continue;
    const wb=office?G.wO:G.wH;wb.tri([P0[0],yb,P0[1]],[P1[0],yb,P1[1]],[P1[0],y1,P1[1]],nx,0,nz,colOut,[s0/U,yb/V],[s1/U,yb/V],[s1/U,y1/V]);wb.tri([P0[0],yb,P0[1]],[P1[0],y1,P1[1]],[P0[0],y1,P0[1]],nx,0,nz,colOut,[s0/U,yb/V],[s1/U,y1/V],[s0/U,y1/V]);
    const ix=-nx*thick,iz=-nz*thick;G.inn.quad([P0[0]+ix,yb,P0[1]+iz],[P1[0]+ix,yb,P1[1]+iz],[P1[0]+ix,y1,P1[1]+iz],[P0[0]+ix,y1,P0[1]+iz],-nx,0,-nz,colIn);
    if(colls){const mx=(P0[0]+P1[0])/2+ix/2,mz=(P0[1]+P1[1])/2+iz/2;colls.push(addOBB(mx,mz,(s1-s0)/2,thick/2+0.05,Math.atan2(tz,tx),yb,y1));}}
}
/* over-track concourse (橋上駅舎): hollow hall with gates, stairs down to each platform and to the street */
function buildConcourse(pts,ly,gmin,h,r,G){
  const n=pts.length/2;let cx=0,cz=0;for(let i=0;i<n;i++){cx+=pts[i*2];cz+=pts[i*2+1];}cx/=n;cz/=n;
  const fy=ly+6.8,ft=fy+0.4,yTop=ft+Math.max(4.0,Math.min(h-6.8,8));
  const lb=lineYAt(cx,cz,60);let line=null,ls=0,bd=1e9;for(const k in LINES){const l=LINES[k];if(l.mono)continue;const q=l.path.near(cx,cz);if(q.d<bd){bd=q.d;line=l;ls=q.s;}}
  const lp=line.path.at(ls);const tx=lp.tx,tz=lp.tz;
  // platforms under this concourse → stair openings
  const holes=[];const stairs=[];
  for(const q of PLATBUILT){if(q.under)continue;if(Math.abs(q.top-(ly+1.1))>3)continue;
    const pa=(cx-q.x)*q.ux+(cz-q.z)*q.uz;if(pa<q.a0-2||pa>q.a1+2)continue;const pw=(-(cx-q.x)*q.uz+(cz-q.z)*q.ux);
    // is the platform centre line inside the concourse footprint near this point?
    const px=q.x+q.ux*pa+(-q.uz)*((q.w0+q.w1)/2),pz=q.z+q.uz*pa+q.ux*((q.w0+q.w1)/2);if(!inPolyF(px,pz,pts))continue;
    const w=Math.min(2.6,(q.w1-q.w0)-1.2);if(w<1.2)continue;const runL=Math.ceil((ft-q.top)/0.28)*0.42;
    // stair climbs along the platform towards the concourse point (px,pz)
    const sx=px-q.ux*runL,sz=pz-q.uz*runL;stairs.push({x:sx,z:sz,ang:Math.atan2(q.uz,q.ux),bot:q.top,w,q});
    const hx0=px-q.ux*3.6,hz0=pz-q.uz*3.6;const vx=-q.uz,vz=q.ux;
    holes.push([[hx0+vx*(w/2+0.2),hz0+vz*(w/2+0.2)],[px+q.ux*0.3+vx*(w/2+0.2),pz+q.uz*0.3+vz*(w/2+0.2)],[px+q.ux*0.3-vx*(w/2+0.2),pz+q.uz*0.3-vz*(w/2+0.2)],[hx0-vx*(w/2+0.2),hz0-vz*(w/2+0.2)]]);}
  // floor with holes
  {const contour=[];for(let i=0;i<n;i++)contour.push(new THREE.Vector2(pts[i*2],pts[i*2+1]));const hs=holes.map(h=>h.map(q=>new THREE.Vector2(q[0],q[1])));let tris=[];try{tris=THREE.ShapeUtils.triangulateShape(contour,hs);}catch(e){}
    const all=[...contour,...hs.flat()];for(const t of tris){const A=all[t[0]],B=all[t[1]],C=all[t[2]];G.inn.tri([A.x,ft,A.y],[B.x,ft,B.y],[C.x,ft,C.y],0,1,0,COL.tile);G.tops.tri([A.x,fy,A.y],[B.x,fy,B.y],[C.x,fy,C.y],0,-1,0,COL.floor);}
    const b=addPoly(pts,fy,ft);b.holes=holes;G.colls.push(b);}
  // walls with doors on edges facing away from the tracks
  const edges=[];for(let i=0;i<n;i++){const j=(i+1)%n;const ax=pts[i*2],az=pts[i*2+1],bx=pts[j*2],bz=pts[j*2+1];const mx=(ax+bx)/2,mz=(az+bz)/2;const d=Math.abs((mx-lp.x)*(-tz)+(mz-lp.z)*tx);edges.push({i,j,ax,az,bx,bz,len:Math.hypot(bx-ax,bz-az),d,side:Math.sign((mx-lp.x)*(-tz)+(mz-lp.z)*tx)});}
  const doorE=new Set();for(const sd of [-1,1]){const c=edges.filter(e=>e.side===sd&&e.len>4).sort((a,b)=>b.d-a.d)[0];if(c)doorE.add(c.i);}
  const wcol=_col.set(WALLO[Math.floor(r*WALLO.length)]).clone();
  for(const e of edges){const gaps=doorE.has(e.i)?[[e.len/2-1.6,e.len/2+1.6,2.6]]:[];wallSeg(G,e.ax,e.az,e.bx,e.bz,ft,yTop,gaps,true,wcol,COL.wallIn,G.colls);
    if(doorE.has(e.i)){const mx=(e.ax+e.bx)/2,mz=(e.az+e.bz)/2;const nx=(e.bz-e.az)/e.len,nz=-(e.bx-e.ax)/e.len;const g0=demH(mx+nx*8,mz+nz*8);
      const run=stairsGB(G.inn,G.colls,mx+nx*0.3,mz+nz*0.3,Math.atan2(nz,nx),ft,Math.min(g0,ft-0.3),3.0);G.tops.obox(mx+nx*(run/2+0.3),mz+nz*(run/2+0.3),nx,nz,run/2+0.3,1.8,ft+2.9,ft+3.1,COL.floor);}}
  // roof
  {const tris=tri2(pts);const tc=_col2.set(ROOFF[Math.floor(r*991)%ROOFF.length]);for(const t of tris){const a=t[0],b=t[1],c=t[2];G.tops.tri([pts[a*2],yTop,pts[a*2+1]],[pts[b*2],yTop,pts[b*2+1]],[pts[c*2],yTop,pts[c*2+1]],0,1,0,tc);G.inn.tri([pts[a*2],yTop-0.02,pts[a*2+1]],[pts[b*2],yTop-0.02,pts[b*2+1]],[pts[c*2],yTop-0.02,pts[c*2+1]],0,-1,0,COL.ceiling);}}
  // stairs to the platforms
  for(const s of stairs){stairsGB(G.inn,G.colls,s.x,s.z,s.ang,s.bot+0.01+(Math.ceil((ft-s.bot)/0.28))*0.28,s.bot,s.w);s.q.stairs++;}
  // ticket gates parallel to the tracks between the free passage and the platform stairs
  const R=rectOf(pts);const along=Math.abs(R.ux*tx+R.uz*tz)>0.7;
  const gl=(along?R.hu:R.hv)*2-2;let off=0;let mx=0;for(const s of stairs){const d=(s.x-lp.x)*(-tz)+(s.z-lp.z)*tx;mx=Math.max(mx,Math.abs(d));}
  const sideFar=Math.sign(((R.cx-lp.x)*(-tz)+(R.cz-lp.z)*tx))||1;const gd=(mx+4)*sideFar;
  const gx=lp.x+(-tz)*gd,gz=lp.z+tx*gd;if(inPolyF(gx,gz,pts))gatesGB(G.inn,G.colls,gx,gz,tx,tz,Math.min(gl,24),ft);
  const mxp=gx+(-tz)*sideFar*3,mzp=gz+tx*sideFar*3;if(inPolyF(mxp,mzp,pts))machinesGB(G.inn,G.colls,mxp,mzp,tx,tz,4,ft);
  G.indoor.push({cx:R.cx,cz:R.cz,c:R.ux,s:R.uz,hl:R.hu,hw:R.hv,y0:ft,y1:yTop});
}
/* school building: floors of classrooms along a corridor, stairs at alternating ends, entrance on the corridor side */
function buildSchool(R,gmin,h,G,sk){
  const nF=clamp(Math.round(h/3.7),1,5);const FH=3.7;const y0=gmin-0.1;const {cx,cz,ux,uz}=R;const hu=R.hu,hv=R.hv;const vx=-uz,vz=ux;const ang=Math.atan2(uz,ux);
  const W=(a,b)=>[cx+ux*a+vx*b,cz+uz*a+vz*b];const cor=Math.min(2.8,hv*0.35);const vb=-hv,vc=-hv+cor; // corridor strip v∈[vb,vc]
  const st=5.6; // stair length
  const outC=_col.set('#ece4d2').clone();
  // exterior walls (entrance in the middle of the corridor-side wall on the ground floor)
  const corners=[W(-hu,-hv),W(hu,-hv),W(hu,hv),W(-hu,hv)];
  for(let f=0;f<nF;f++){const ya=y0+f*FH,yb=ya+FH;
    for(let e=0;e<4;e++){const A=corners[e],B=corners[(e+1)%4];const len=Math.hypot(B[0]-A[0],B[1]-A[1]);const gaps=(f===0&&e===0)?[[len/2-1.8,len/2+1.8,2.6]]:[];wallSeg(G,A[0],A[1],B[0],B[1],ya,yb,gaps,false,outC,COL.wallIn,G.colls);}}
  // floors & ceilings with stair openings
  for(let f=0;f<=nF;f++){const y=y0+f*FH;const top=f===nF;
    // stair from floor f-1 arrives at floor f: opening at the end (alternating)
    const endA=(f%2===1)?1:-1;const hole=(f>0&&!top)?[endA>0?hu-st-0.3:-hu,endA>0?hu:-hu+st+0.3]:null;
    const pieces=[];if(hole){pieces.push([-hu,hu,vc,hv]);if(hole[0]>-hu)pieces.push([-hu,hole[0],vb,vc]);if(hole[1]<hu)pieces.push([hole[1],hu,vb,vc]);}else pieces.push([-hu,hu,vb,hv]);
    for(const [a0,a1,b0,b1] of pieces){const m=W((a0+a1)/2,(b0+b1)/2);const hu2=(a1-a0)/2,hv2=(b1-b0)/2;
      if(f===0){G.inn.obox(m[0],m[1],ux,uz,hu2,hv2,y,y+0.12,(b0>=vc-0.01?COL.wood:COL.tile),1);G.colls.push(addOBB(m[0],m[1],hu2,hv2,ang,y-0.5,y+0.12));}
      else{G.inn.obox(m[0],m[1],ux,uz,hu2,hv2,y-0.3,y+0.12,(b0>=vc-0.01?COL.wood:COL.tile),top?2:3);if(top)G.tops.obox(m[0],m[1],ux,uz,hu2,hv2,y-0.3,y+0.3,_col2.set('#a9a69f'),1);if(!top)G.colls.push(addOBB(m[0],m[1],hu2,hv2,ang,y-0.3,y+0.12));}}
    if(top){G.colls.push(addOBB(cx,cz,hu,hv,ang,y-0.3,y+0.3));}}
  // stairs in the corridor ends
  for(let f=0;f<nF-1;f++){const endA=((f+1)%2===1)?1:-1;const ya=y0+f*FH+0.12,yb=y0+(f+1)*FH+0.12;const sw=cor-0.4;
    const startA=endA>0?hu-st-0.2:-hu+st+0.2;const p0=W(startA,(vb+vc)/2);stairsGB(G.inn,G.colls,p0[0],p0[1],endA>0?ang:ang+Math.PI,yb,ya,sw);}
  // classrooms
  const cl0=-hu+st+0.6,cl1=hu-st-0.6;const nC=Math.max(1,Math.floor((cl1-cl0)/8));const cw=(cl1-cl0)/nC;
  for(let f=0;f<nF;f++){const ya=y0+f*FH+0.12,yb=y0+(f+1)*FH-0.3;
    // corridor wall with two doors per classroom
    const A=W(cl0,vc),B=W(cl1,vc);const gaps=[];for(let c=0;c<nC;c++){gaps.push([c*cw+0.8,c*cw+1.9,2.1],[c*cw+cw-1.9,c*cw+cw-0.8,2.1]);}
    wallSegIn(G,A[0],A[1],B[0],B[1],ya,yb,gaps,G.colls);
    for(let c=0;c<=nC;c++){const a=cl0+c*cw;const P1=W(a,vc),P2=W(a,hv);wallSegIn(G,P1[0],P1[1],P2[0],P2[1],ya,yb,[],G.colls);}
    // stair-hall partitions
    for(const a of [cl0,cl1]){const P1=W(a,vb+0.01),P2=W(a,vc);}
    for(let c=0;c<nC;c++){const a0=cl0+c*cw,a1=a0+cw;const depth=hv-vc;
      // blackboard on the front partition (a0 side)
      const bb=W(a0+0.08,(vc+hv)/2);G.inn.obox(bb[0],bb[1],ux,uz,0.04,Math.min(2.2,depth/2-0.6),ya+0.9,ya+2.1,COL.board);
      const td=W(a0+1.3,(vc+hv)/2);G.inn.obox(td[0],td[1],ux,uz,0.35,0.7,ya,ya+0.75,COL.desk);
      const rows=Math.max(1,Math.floor((cw-2.6)/1.05)),colsN=Math.max(1,Math.floor((depth-1.0)/1.0));
      for(let i=0;i<rows;i++)for(let j=0;j<colsN;j++){const p=W(a0+2.4+i*1.05,vc+0.8+j*1.0);G.desks.push([p[0],ya,p[1],ang+Math.PI/2]);}
      const lk=W(a1-0.3,(vc+hv)/2);G.inn.obox(lk[0],lk[1],ux,uz,0.25,Math.min(2.5,depth/2-0.4),ya,ya+1.0,COL.locker);}
  }
  G.indoor.push({cx,cz,c:ux,s:uz,hl:hu,hw:hv,y0:y0,y1:y0+nF*FH,floors:FH,school:true});
}
function wallSegIn(G,ax,az,bx,bz,y0,y1,gaps,colls){const dx=bx-ax,dz=bz-az,len=Math.hypot(dx,dz);if(len<0.05)return;const tx=dx/len,tz=dz/len,nx=tz,nz=-tx;
  const pieces=[];let a=0;for(const g of gaps.slice().sort((p,q)=>p[0]-q[0])){if(g[0]>a)pieces.push([a,g[0],0]);pieces.push([g[0],g[1],g[2]]);a=g[1];}if(a<len)pieces.push([a,len,0]);
  for(const [s0,s1,gh] of pieces){const yb=gh>0?y0+gh:y0;if(yb>=y1||s1-s0<0.02)continue;const cxp=ax+tx*(s0+s1)/2,czp=az+tz*(s0+s1)/2;G.inn.obox(cxp,czp,tx,tz,(s1-s0)/2,0.06,yb,y1,COL.wallIn,4|8|16|32);
    if(gh===0&&colls)colls.push(addOBB(cxp,czp,(s1-s0)/2,0.08,Math.atan2(tz,tx),yb,y1));}}
function buildGym(R,gmin,h,G){
  const {cx,cz,ux,uz,hu,hv}=R;const y0=gmin-0.1,y1=y0+Math.max(8,Math.min(h,14));const vx=-uz,vz=ux;const ang=Math.atan2(uz,ux);const W=(a,b)=>[cx+ux*a+vx*b,cz+uz*a+vz*b];
  const corners=[W(-hu,-hv),W(hu,-hv),W(hu,hv),W(-hu,hv)];const outC=_col.set('#e7e2d6').clone();
  for(let e=0;e<4;e++){const A=corners[e],B=corners[(e+1)%4];const len=Math.hypot(B[0]-A[0],B[1]-A[1]);const gaps=(e===0||e===2)?[[len/2-1.8,len/2+1.8,2.8]]:[];wallSeg(G,A[0],A[1],B[0],B[1],y0,y1,gaps,true,outC,COL.wallIn,G.colls);}
  G.inn.obox(cx,cz,ux,uz,hu,hv,y0,y0+0.15,COL.court,1);G.colls.push(addOBB(cx,cz,hu,hv,ang,y0-0.5,y0+0.15));
  // court lines & hoops
  const lw=0.06;for(const [a,b,l,w] of [[0,0,hu*0.85,lw],[0,0,lw,hv*0.8]]){G.inn.obox(cx,cz,ux,uz,l,w,y0+0.16,y0+0.17,COL.line,1);}
  for(const sd of [-1,1]){const e1=W(sd*(hu*0.85),0);G.inn.obox(e1[0],e1[1],ux,uz,lw,hv*0.8,y0+0.16,y0+0.17,COL.line,1);const hp=W(sd*(hu-0.6),0);G.inn.obox(hp[0],hp[1],ux,uz,0.05,0.9,y0+2.9,y0+3.95,C_('#ffffff'));const rim=W(sd*(hu-1.1),0);G.inn.obox(rim[0],rim[1],ux,uz,0.25,0.25,y0+3.05,y0+3.1,C_('#e0453a'));}
  const rf=new THREE.Color('#8f9aa5');G.tops.obox(cx,cz,ux,uz,hu+0.3,hv+0.3,y1,y1+0.4,rf,1);G.inn.obox(cx,cz,ux,uz,hu,hv,y1-0.02,y1,COL.ceiling,2);G.colls.push(addOBB(cx,cz,hu,hv,ang,y1,y1+0.4));
  G.indoor.push({cx,cz,c:ux,s:uz,hl:hu,hw:hv,y0,y1});
}
function buildTreesInto(grp,L2){
  const dm=new THREE.Object3D(),cc=new THREE.Color();
  const rounds=[...L2.round.map(t=>({...t,k:'r'})),...L2.autumn.map(t=>({...t,k:'a'}))];const pines=L2.pine,palms=L2.palm;
  const tot=rounds.length+pines.length+palms.length;if(!tot)return;
  const trunks=new THREE.InstancedMesh(TRUNK,MAT.trunk,tot);let ti=0;
  const greens=['#4f9a45','#5aa84c','#468c3f','#62b052','#3f8a4a'],aut=['#f2c230','#e8902f','#d9622b','#f0b13a'];
  if(rounds.length){const rm=new THREE.InstancedMesh(CROWN,MAT.crown,rounds.length);
    rounds.forEach((t,i)=>{const s=t.s;dm.rotation.set(0,rand()*3,0);dm.position.set(t.x,t.y-0.3,t.z);dm.scale.set(s*2,4*s,s*2);dm.updateMatrix();trunks.setMatrixAt(ti++,dm.matrix);
      dm.position.set(t.x,t.y+4*s+2.4*s,t.z);dm.scale.set(3.6*s,3.4*s*rr(0.9,1.2),3.6*s);dm.updateMatrix();rm.setMatrixAt(i,dm.matrix);rm.setColorAt(i,cc.set(pick(t.k==='a'?aut:greens)));});
    rm.castShadow=true;rm.receiveShadow=true;rm.computeBoundingSphere();grp.add(rm);}
  if(pines.length){const pm=new THREE.InstancedMesh(PINEC,MAT.crown,pines.length);
    pines.forEach((t,i)=>{const s=t.s;dm.rotation.set(rr(-0.12,0.12),rand()*3,rr(-0.12,0.12));dm.position.set(t.x,t.y-0.3,t.z);dm.scale.set(s*2.2,10*s,s*2.2);dm.updateMatrix();trunks.setMatrixAt(ti++,dm.matrix);
      dm.rotation.set(0,rand()*3,0);dm.position.set(t.x,t.y+10*s,t.z);dm.scale.set(3*s,2.6*s,3*s);dm.updateMatrix();pm.setMatrixAt(i,dm.matrix);pm.setColorAt(i,cc.set(pick(['#2f6b3f','#356f43','#2a5f3a'])));});
    pm.castShadow=true;pm.computeBoundingSphere();grp.add(pm);}
  if(palms.length){const pa=new THREE.InstancedMesh(PALMC,M('#3f9a4f'),palms.length);
    palms.forEach((t,i)=>{dm.rotation.set(0,rand()*3,0);dm.position.set(t.x,t.y,t.z);dm.scale.set(2.4,11,2.4);dm.updateMatrix();trunks.setMatrixAt(ti++,dm.matrix);dm.position.set(t.x,t.y+11,t.z);dm.scale.set(1,1,1);dm.updateMatrix();pa.setMatrixAt(i,dm.matrix);});
    pa.castShadow=true;pa.computeBoundingSphere();grp.add(pa);}
  trunks.castShadow=true;trunks.computeBoundingSphere();grp.add(trunks);
}
function disposeChunk(ch){removeColl(ch.colls);for(const z of ch.indoor){const i=INDOOR.indexOf(z);if(i>=0)INDOOR.splice(i,1);}scene.remove(ch.grp);ch.grp.traverse(o=>{if(o.isMesh&&!SHARED.has(o.geometry))o.geometry.dispose();if(o.isInstancedMesh)o.dispose();});}
function updateChunks(px,pz,budget=1){
  const ci0=Math.floor((px-X0)/CH),cj0=Math.floor((pz-Z0)/CH);const R=Math.ceil(NEAR_R/CH)+1;const want=[];
  for(let i=ci0-R;i<=ci0+R;i++)for(let j=cj0-R;j<=cj0+R;j++){if(i<0||j<0||i>=CNX||j>=CNZ)continue;if(CIDX[j*CNX+i]<0)continue;const cx=X0+(i+0.5)*CH,cz=Z0+(j+0.5)*CH;const d=Math.hypot(cx-px,cz-pz);if(d<NEAR_R&&!CHUNKS.has(chunkKey(i,j)))want.push([d,i,j]);}
  want.sort((a,b)=>a[0]-b[0]);let changed=false;
  for(let k=0;k<Math.min(budget,want.length);k++){const [,i,j]=want[k];CHUNKS.set(chunkKey(i,j),buildChunk(i,j));maskData[j*CNX+i]=255;changed=true;}
  for(const [key,ch] of CHUNKS){const cx=X0+(ch.ci+0.5)*CH,cz=Z0+(ch.cj+0.5)*CH;if(Math.hypot(cx-px,cz-pz)>FAR_KEEP){disposeChunk(ch);CHUNKS.delete(key);maskData[ch.cj*CNX+ch.ci]=0;changed=true;}}
  if(changed)maskTex.needsUpdate=true;return want.length;
}
