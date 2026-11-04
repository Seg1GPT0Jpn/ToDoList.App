/* ================= 藤沢本町駅 (小田急江ノ島線) =================
   相対式ホーム2面2線, ground level. The only station building and ticket gate stand on the 1番線 (east, 片瀬江ノ島・藤沢方面)
   side at the south end of the platform, next to 藤沢本町1号踏切; 2番線 is reached over a footbridge (跨線橋). */
(()=>{
const NAME='藤沢本町';
function build(){
  const l=LINES.odn;const sC=l.stByName.get(NAME).s;const top=l.path.py(sC)+1.1;const gb=new GB(),colls=[];gb.glass=new GB();
  const s0=sC-64,s1=sC+60;const pw=4.2;
  for(const sd of [-1,1]){const inner=sd*3.5,outer=sd*(3.5+pw);
    const poly=platformAlong(gb,colls,l,s0,s1,inner,outer,top);const b=addPoly(poly,top-1.2,top);b.tag=0;b.plat=true;
    const rp=[];for(const [s,o] of [[s0,inner],[s1,inner],[s1,outer],[s0,outer]]){const p=l.path.at(s,o);rp.push(p.x,p.z);}regPlatform(rp,top,l,false,false);
    // roof over the southern half, fence on the outer edge, benches, name boards
    for(let s=s0;s<sC+12;s+=5){const a=l.path.at(s+2.5,sd*(3.5+pw/2));gb.obox(a.x,a.z,a.tx,a.tz,2.55,pw/2+0.3,top+3.5,top+3.7,C_('#c7ccd0'));}
    for(let s=s0+4;s<sC+12;s+=12){const a=l.path.at(s,sd*(3.5+pw*0.62));gb.obox(a.x,a.z,a.tx,a.tz,0.15,0.15,top,top+3.5,C_('#7a858e'));colls.push(addOBB(a.x,a.z,0.16,0.16,0,top,top+3.5));}
    for(let s=s0;s<s1;s+=10){const a=l.path.at(s+5,outer-sd*0.08);gb.obox(a.x,a.z,a.tx,a.tz,5,0.05,top,top+1.2,C_('#8e979e'));colls.push(addOBB(a.x,a.z,5,0.06,Math.atan2(a.tz,a.tx),top,top+1.2));}
    platformDressing(gb,colls,l,s0+8,s1-6,sd*(3.5+pw*0.62),top,{every:26,pillars:false});
    for(const s of [s0+30,sC+5,s1-15]){const q=l.path.at(s,sd*(3.5+pw*0.6));signBoard(q.x,top+2.4,q.z,Math.atan2(q.tz,q.tx),1.8,0.46,'藤沢本町','ふじさわほんまち  Fujisawa-honmachi  OE 12','#1a5fb4');}
    const q=l.path.at(s0+14,sd*(3.5+pw*0.6));signBoard(q.x,top+2.9,q.z,Math.atan2(q.tz,q.tx)+Math.PI/2,1.4,0.5,sd>0?'1番線':'2番線',sd>0?'藤沢・片瀬江ノ島方面':'湘南台・大和・新宿方面','#1a5fb4',true);}
  // station building on the east side at the south end, gate opening onto the 1番線 platform
  {const p=l.path.at(s0+6,3.5+pw+5);const F=stFrame(p.x,p.z,Math.atan2(p.tz,p.tx));const g=demH(p.x,p.z);
    const fac=new GB();const f=[];for(const [a,b] of [[-9,-5],[9,-5],[9,5],[-9,5]]){const w=F.W(a,b);f.push(w[0],w[1]);}
    facadeWalls(fac,f,g-0.2,g+4.2,_col.set('#efe9de'),FAC.OFFICE,4.4);scene.add(Object.assign(new THREE.Mesh(fac.geo(),facadeMat()),{castShadow:true,receiveShadow:true}));
    gb.obox(p.x,p.z,F.ux,F.uz,9.6,5.6,g+4.2,g+4.6,C_('#5e6a74'));gb.obox(p.x,p.z,F.ux,F.uz,9.8,5.8,g+4.6,g+4.9,C_('#1a5fb4'));
    colls.push(addOBB(F.W(0,1)[0],F.W(0,1)[1],9,3.8,F.ang,g-0.2,g+4.2));
    const gc=F.W(0,-4.6);gatesGB(gb,colls,gc[0],gc[1],F.ux,F.uz,7,top);const ent=F.W(0,-5.8);
    const sb=F.W(-10.2,0);signBoard(sb[0],g+3.4,sb[1],F.ang+Math.PI/2,4.6,1.0,'藤沢本町駅','Fujisawa-honmachi Sta.','#1a5fb4');
    const mc=F.W(6.5,-4.4);machinesGB(gb,colls,mc[0],mc[1],F.ux,F.uz,3,top);
    // small forecourt slab between platform and building (platform level), step down to the street at the south
    const fc=F.W(0,-4.4);gb.obox(fc[0],fc[1],F.ux,F.uz,9,1.2,g-0.3,top,C_('#d6d0c2'),1|4|8|16|32);colls.push(addOBB(fc[0],fc[1],9,1.2,F.ang,g-0.3,top));
    const st=F.W(-9,-4.4);stairDir(gb,colls,F,-9,-4.4,-1,0,top,g+0.05,2.2);}
  // footbridge over the tracks at the south end
  {const sb=s0+10;const fl=top+6.4;const a=l.path.at(sb,0);const F=stFrame(a.x,a.z,Math.atan2(a.tz,a.tx));
    gb.obox(a.x,a.z,F.ux,F.uz,1.6,8,fl-0.4,fl,C_('#c9ced3'));colls.push(addOBB(a.x,a.z,1.6,8,F.ang,fl-0.4,fl));gb.obox(a.x,a.z,F.ux,F.uz,1.8,8.2,fl+2.6,fl+2.9,C_('#5e6a74'));
    for(const sd of [-1,1]){const w=F.W(0,sd*1.62);gb.glass.obox(w[0],w[1],F.ux,F.uz,0.04,8,fl,fl+2.6,C_('#a9c8d8'));colls.push(addOBB(F.W(sd*1.62,0)[0],F.W(sd*1.62,0)[1],0.06,8,F.ang,fl,fl+2.6));
      // stairs down onto each platform, running north along it
      const b=sd*7.6;const sw=F.W(1.6,b);const r=stairsGB(gb,colls,sw[0],sw[1],F.ang,fl,top,1.9);
      const mid=F.W(1.6+r/2,b);gb.obox(mid[0],mid[1],F.ux,F.uz,r/2,1.05,fl+2.3,fl+2.6,C_('#5e6a74'));
      for(const e of [-1,1]){const w2=F.W(1.6+r/2,b+e*1.0);gb.glass.obox(w2[0],w2[1],F.ux,F.uz,r/2,0.04,top+1,fl+2.3,C_('#a9c8d8'));}}
    INDOOR.push({cx:a.x,cz:a.z,c:F.ux,s:F.uz,hl:1.6,hw:8,y0:fl-0.5,y1:fl+2.6});}
  if(!gb.empty){const m=new THREE.Mesh(gb.geo(),MAT.top);m.castShadow=true;m.receiveShadow=true;scene.add(m);}
  if(!gb.glass.empty){const m=new THREE.Mesh(gb.glass.geo(),GLASSMAT);m.renderOrder=3;scene.add(m);}
}
ST_CUSTOM[NAME]={lines:new Set(['odn']),build};
})();
