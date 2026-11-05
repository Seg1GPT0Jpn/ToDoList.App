/* ================= people: walkers on the pavements and passengers waiting on platforms near you ================= */
const PEOPLE=(()=>{const N=isTouch?28:72;
  const geo=mergeGeos([new THREE.CylinderGeometry(0.11,0.12,0.82,6).translate(-0.1,0.41,0),new THREE.CylinderGeometry(0.11,0.12,0.82,6).translate(0.1,0.41,0),new THREE.CapsuleGeometry(0.2,0.5,3,8).translate(0,1.17,0),new THREE.SphereGeometry(0.13,10,8).translate(0,1.62,0)]);
  const im=new THREE.InstancedMesh(geo,M('#ffffff'),N);im.frustumCulled=false;im.castShadow=true;const dm=new THREE.Object3D(),cc=new THREE.Color();
  const cols=['#2b3e5e','#e6e2d8','#8a3b3b','#3d6b4f','#d9c7a6','#1f1f22','#6a7f9a','#c96f3a','#efe9e0','#4a4a52'];
  const P=[];for(let i=0;i<N;i++){P.push({on:false});im.setColorAt(i,cc.set(cols[i%cols.length]));}im.instanceColor.needsUpdate=true;scene.add(im);
  function spawn(p,px,pz){
    if(Math.random()<0.25){const pl=PLATBUILT.filter(q=>q.b&&Math.hypot(q.x-px,q.z-pz)<220);if(pl.length){const q=pl[Math.floor(Math.random()*pl.length)];
      for(let k=0;k<6;k++){const a=q.a0+(q.a1-q.a0)*(0.1+0.8*Math.random()),w=q.w0+(q.w1-q.w0)*(0.25+0.5*Math.random());const x=q.x+q.ux*a-q.uz*w,z=q.z+q.uz*a+q.ux*w;if(inPolyF(x,z,q.b.pts)){Object.assign(p,{on:true,stand:true,x,z,y:q.top,face:Math.random()*6.3,path:null});return;}}}}
    const ci=Math.floor((px-X0)/CH),cj=Math.floor((pz-Z0)/CH);const cand=[];for(let i=ci-1;i<=ci+1;i++)for(let j=cj-1;j<=cj+1;j++)for(const ri of ROADCH.get(j*CNX+i)||[]){const r=ROADS[ri];if(r.c>=2&&r.c<=7&&!(r.fl&3))cand.push(r);}
    if(!cand.length)return;const r=cand[Math.floor(Math.random()*cand.length)];const q=r.path.near(px+(Math.random()-0.5)*160,pz+(Math.random()-0.5)*160);if(q.d>140)return;
    const side=Math.random()<0.5?1:-1;const off=r.c>=7?(Math.random()-0.5)*r.w*0.6:side*(r.w/2+(r.c<=4?1.1:0.6));
    Object.assign(p,{on:true,stand:false,path:r.path,s:q.s,off,dir:Math.random()<0.5?1:-1,v:1.1+Math.random()*0.5,ph:Math.random()*6,raise:r.c>=2&&r.c<=4?0.15:0});}
  let t=0;
  return{update(dt){t+=dt;const px=P0().x,pz=P0().z;
    for(let i=0;i<N;i++){const p=P[i];if(!p.on||Math.hypot((p.x??1e9)-px,(p.z??1e9)-pz)>200){p.x=undefined;spawn(p,px,pz);if(!p.on){dm.position.set(0,-999,0);dm.updateMatrix();im.setMatrixAt(i,dm.matrix);continue;}}
      if(!p.stand){p.s+=p.dir*p.v*dt;if(p.s<1||p.s>p.path.L-1){p.dir*=-1;p.s=clamp(p.s,1,p.path.L-1);}const a=p.path.at(p.s,p.off);p.x=a.x;p.z=a.z;p.y=demH(a.x,a.z)+p.raise;p.face=Math.atan2(a.tx*p.dir,a.tz*p.dir);}
      const bob=p.stand?0:Math.abs(Math.sin(t*7*p.v+(p.ph||0)))*0.05;dm.position.set(p.x,p.y+bob,p.z);dm.rotation.set(0,p.face,0);dm.updateMatrix();im.setMatrixAt(i,dm.matrix);}
    im.instanceMatrix.needsUpdate=true;}};})();
function P0(){return P;}
