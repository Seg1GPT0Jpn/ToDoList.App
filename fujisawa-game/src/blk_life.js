function buildLife(){
  for(let i=0;i<60;i++){const x=rr(-4200,900);if(x>-420&&x<-60)continue;const z=coastZ(x)+rr(40,200);if(rawH(x,z)>-0.5)continue;const g=new THREE.Group();scene.add(g);
    const bd=new THREE.Mesh(BOX,M(pick(['#ffffff','#f2c230','#e0453a','#4fb3e6'])));bd.scale.set(0.55,0.1,2.1);g.add(bd);
    const p=new THREE.Mesh(new THREE.CapsuleGeometry(0.2,0.6,3,6),M('#1b1f24'));p.position.y=rand()<0.4?0.75:0.25;if(p.position.y<0.5)p.rotation.x=Math.PI/2;g.add(p);
    const ph=rand()*9;g.rotation.y=rand()*0.5-0.25;DYN.push(t=>{g.position.set(x+Math.sin(t*0.05+ph)*6,SEA+0.05+Math.sin(t*1.4+ph)*0.22,z+Math.sin(t*0.2+ph)*4);g.rotation.z=Math.sin(t*1.1+ph)*0.08;});}
  for(let i=0;i<12;i++){const sx=rr(-1500,1200),sz=rr(4500,5600);const b=boat(0,0,'yacht');const sail=new THREE.Mesh(new THREE.ConeGeometry(3.6,12,3).translate(0,7,0),M(pick(['#ffffff','#ffffff','#f6d5d5','#d5e6f6'])));sail.scale.z=0.12;b.add(sail);
    const ph=rand()*6,rad=rr(150,500),sp=rr(0.004,0.01);DYN.push(t=>{const a=t*sp+ph;b.position.x=sx+Math.cos(a)*rad;b.position.z=sz+Math.sin(a)*rad*0.5;b.rotation.y=-a;});}
  const wg=new THREE.BufferGeometry();wg.setAttribute('position',new THREE.Float32BufferAttribute([0,0,-0.25,0,0,0.4,-0.8,0,-0.05, 0,0,-0.25,0.8,0,-0.05,0,0,0.4, 0,0,-0.25,-0.18,0,-0.6,0.18,0,-0.6],3));wg.computeVertexNormals();
  const km=M('#5b4636',{side:THREE.DoubleSide});const [ex,ez]=LMP('seacandle',35.2998,139.4797);
  for(let i=0;i<16;i++){const cx=ex+rr(-400,800),cz=rr(3300,4400),rad=rr(30,90),hgt=rr(25,90),sp=rr(0.12,0.25)*(rand()<0.5?1:-1),ph=rand()*6;
    const b=new THREE.Mesh(wg,km);scene.add(b);
    DYN.push(t=>{const a=t*sp+ph;b.position.set(cx+Math.cos(a)*rad,hgt+Math.sin(t*0.5+ph)*4,cz+Math.sin(a)*rad);b.rotation.set(0,-a+(sp>0?0:Math.PI),(sp>0?-0.3:0.3));});}
}
function buildLabels(){for(const m of LM){if(m.noLabel)continue;addLabel(m.name,m.en,m.x,m.y??(heightAt(m.x,m.z)+12),m.z,'lm','#ff9a3c',m.r>150?3000:1600);}}
