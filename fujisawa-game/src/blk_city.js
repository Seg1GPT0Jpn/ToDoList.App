/* ================= city boundary & areas ================= */
const CITY=LL([[35.3170,139.4350],[35.3400,139.4380],[35.3500,139.4280],[35.3600,139.4150],[35.3720,139.3930],[35.3850,139.3850],[35.4000,139.3880],[35.4080,139.4050],[35.4100,139.4300],[35.4200,139.4500],[35.4310,139.4680],[35.4200,139.4790],[35.4000,139.4880],[35.3800,139.4945],[35.3600,139.4960],[35.3560,139.5050],[35.3540,139.5200],[35.3450,139.5230],[35.3350,139.5150],[35.3250,139.5050],[35.3150,139.4960],[35.3080,139.4900],[35.3050,139.4895],[35.2950,139.4900],[35.2950,139.4700],[35.3080,139.4650],[35.3150,139.4500]]);
function inPoly(x,z,P){let c=false;for(let i=0,j=P.length-1;i<P.length;j=i++){const a=P[i],b=P[j];if(((a[1]>z)!==(b[1]>z))&&(x<(b[0]-a[0])*(z-a[1])/(b[1]-a[1])+a[0]))c=!c;}return c;}
const AREAS=[['藤沢','Fujisawa',35.3430,139.4890],['鵠沼','Kugenuma',35.3220,139.4780],['片瀬','Katase',35.3120,139.4870],['辻堂','Tsujidō',35.3300,139.4500],['村岡','Muraoka',35.3430,139.5050],['明治','Meiji',35.3390,139.4620],['善行','Zengyō',35.3620,139.4790],['湘南大庭','Shōnan-Ōba',35.3570,139.4480],['湘南台','Shōnandai',35.3950,139.4690],['六会','Mutsuai',35.3780,139.4680],['長後','Chōgo',35.4120,139.4660],['遠藤','Endō',35.3880,139.4300],['御所見','Goshomi',35.3850,139.4000]].map(a=>{const p=L(a[2],a[3]);return{name:a[0],en:a[1],x:p[0],z:p[1]};});
function nearestArea(x,z){let b=1e18,a=AREAS[0];for(const r of AREAS){const d=(x-r.x)**2+(z-r.z)**2;if(d<b){b=d;a=r;}}return a;}
function areaAt(x,z){
  const h=rawH(x,z);
  if(z>coastZ(x)+20){if(h>0.1&&z<coastZ(x)+1400)return{city:'藤沢市',name:'江の島',en:'Enoshima'};return{city:'',name:'相模湾',en:'Sagami Bay'};}
  if(!inPoly(x,z,CITY)){
    if(x>0&&z>-1800)return{city:'鎌倉市',name:x<1600&&z>2800?'腰越':'鎌倉市',en:'Kamakura'};
    if(x>0)return{city:'横浜市',name:'横浜市',en:'Yokohama'};
    if(z<-9000)return{city:'大和市',name:'大和市',en:'Yamato'};
    if(z>-1500)return{city:'茅ヶ崎市',name:'茅ヶ崎市',en:'Chigasaki'};
    if(z>-5500)return{city:'寒川町',name:'寒川町',en:'Samukawa'};
    return{city:'綾瀬市',name:'綾瀬市',en:'Ayase'};
  }
  const a=nearestArea(x,z);return{city:'藤沢市',name:a.name,en:a.en};
}

