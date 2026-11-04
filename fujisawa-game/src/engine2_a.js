import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js';

const $ = id => document.getElementById(id);
const setLoad = t => { $('loading').querySelector('.msg').textContent = t; };
const tick = () => new Promise(r => setTimeout(r, 0));

/* ================= utils ================= */
function mulberry32(a){return function(){a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
let rand = mulberry32(251104);
const rr=(a,b)=>a+(b-a)*rand();
const pick=a=>a[Math.floor(rand()*a.length)];
const clamp=(v,a,b)=>v<a?a:v>b?b:v;
const lerp=(a,b,t)=>a+(b-a)*t;
const smooth=(e0,e1,x)=>{const t=clamp((x-e0)/(e1-e0),0,1);return t*t*(3-2*t)};
const hashf=(n)=>{let h=Math.imul(n|0,2654435761);h^=h>>>15;h=Math.imul(h,2246822519);h^=h>>>13;return(h>>>0)/4294967296;};
const isTouch = matchMedia('(pointer:coarse)').matches || ('ontouchstart' in window && navigator.maxTouchPoints>0);
const LITE=!!window.__LITE;
const LAT0=35.3389,LON0=139.4874,MX=90807,MZ=110940;
const L=(lat,lon)=>[(lon-LON0)*MX,-(lat-LAT0)*MZ];
const LL=a=>a.map(p=>L(p[0],p[1]));

function segNear(g,x,z){let t=((x-g.x)*g.dx+(z-g.z)*g.dz)/(g.len*g.len);t=t<0?0:t>1?1:t;const px=g.x+g.dx*t-x,pz=g.z+g.dz*t-z;return{d2:px*px+pz*pz,s:g.s+t*g.len};}
class Path{
  constructor(pts){this.pts=pts;this.segs=[];let s=0;
    for(let i=0;i<pts.length-1;i++){const a=pts[i],b=pts[i+1];const dx=b[0]-a[0],dz=b[1]-a[1],len=Math.hypot(dx,dz)||1e-6;this.segs.push({x:a[0],z:a[1],dx,dz,len,s,tx:dx/len,tz:dz/len});s+=len;}
    this.L=s;}
  seg(s){let lo=0,hi=this.segs.length-1;while(lo<hi){const m=(lo+hi+1)>>1;if(this.segs[m].s<=s)lo=m;else hi=m-1;}return this.segs[lo];}
  at(s,off=0){s=clamp(s,0,this.L);const g=this.seg(s),t=s-g.s;return{x:g.x+g.tx*t-g.tz*off,z:g.z+g.tz*t+g.tx*off,tx:g.tx,tz:g.tz};}
  near(x,z){let b=1e18,bs=0;for(const g of this.segs){const r=segNear(g,x,z);if(r.d2<b){b=r.d2;bs=r.s;}}return{d:Math.sqrt(b),s:bs};}
  py(s){if(!this.prof)return 0;const f=clamp(s/this.pstep,0,this.prof.length-1);const i=Math.floor(f);return lerp(this.prof[i],this.prof[Math.min(i+1,this.prof.length-1)],f-i);}
  laneOff(s,side){const o=this.offs;if(!o)return 0;const f=clamp(s/10,0,o.length-1.001);const i=f|0,t=f-i;let a=lerp(o[i][0],o[i+1][0],t),b=lerp(o[i][1],o[i+1][1],t);if(b-a<3.8){const m=(a+b)/2;a=m-1.9;b=m+1.9;}return side>0?b:a;} // 線路の間隔は最低 3.8 m
  flagAt(s){if(!this.flags)return 0;return this.flags[clamp(Math.round(s/10),0,this.flags.length-1)];}
}
class SegIndex{
  constructor(cell){this.cell=cell;this.m=new Map();}
  add(path,margin,data){const c=this.cell;for(const g of path.segs){const x0=Math.min(g.x,g.x+g.dx)-margin,x1=Math.max(g.x,g.x+g.dx)+margin,z0=Math.min(g.z,g.z+g.dz)-margin,z1=Math.max(g.z,g.z+g.dz)+margin;
    for(let i=Math.floor(x0/c);i<=Math.floor(x1/c);i++)for(let j=Math.floor(z0/c);j<=Math.floor(z1/c);j++){const k=i*65536+j;let a=this.m.get(k);if(!a)this.m.set(k,a=[]);a.push({g,data});}}}
  nearest(x,z){const a=this.m.get(Math.floor(x/this.cell)*65536+Math.floor(z/this.cell));if(!a)return null;const best=new Map();for(const e of a){const r=segNear(e.g,x,z);const b=best.get(e.data);if(!b||r.d2<b.d2)best.set(e.data,{d2:r.d2,s:r.s,data:e.data});}return best;}
}

/* ================= real data (OSM + GSI, baked) ================= */
let META,X0,Z0,X1,Z1,GS,N1,CH,CNX,CNZ,CIDX,DEMC,LCC8,COARSE,CNXg,CNZg,CG,COASTA,BOFFS,BLDS,LODC,LODH;let ROADS=[],PLATS=[],TRACKS=[];let WORLD;
async function loadData(){
  const res=await fetch('fujisawa-data2.wasm');if(!res.ok)throw new Error('データを読み込めませんでした ('+res.status+')');
  const total=+res.headers.get('content-length')||12e6;let got=0;const rd=res.body.getReader();
  const prog=new ReadableStream({async pull(c){const {done,value}=await rd.read();if(done){c.close();return;}got+=value.length;setLoad(`地図データを受信中… ${Math.min(99,Math.round(got/total*100))}%`);c.enqueue(value);}});
  const buf=await new Response(prog.pipeThrough(new DecompressionStream('gzip'))).arrayBuffer();
  const dv=new DataView(buf);const mlen=dv.getUint32(4,true);META=JSON.parse(new TextDecoder().decode(new Uint8Array(buf,8,mlen)));let hdr=8+mlen;while(hdr%4)hdr++;
  const S=n=>{const [o,l]=META.sections[n];return new Uint8Array(buf,hdr+o,l);};
  const cp=(u,T)=>new T(u.buffer.slice(u.byteOffset,u.byteOffset+u.byteLength));
  [X0,Z0,X1,Z1]=META.world;[GS,N1]=META.grid;[CH,CNX,CNZ]=META.chunk;[CNXg,CNZg,CG]=META.coarse;
  WORLD={x0:X0,z0:Z0,x1:X1,z1:Z1};
  CIDX=cp(S('cidx'),Int32Array);
  const nd=META.ndetail,per=N1*N1;const d=S('dem');DEMC=new Int16Array(nd*per);const half=nd*per;
  for(let c=0;c<nd;c++){const base=c*per;for(let j=0;j<N1;j++)for(let i=0;i<N1;i++){const k=base+j*N1+i;const r=(d[k]|(d[half+k]<<8))<<16>>16;let p=0;
    if(j>0&&i>0)p=DEMC[k-1]+DEMC[k-N1]-DEMC[k-N1-1];else if(j===0&&i>0)p=DEMC[k-1];else if(i===0&&j>0)p=DEMC[k-N1];DEMC[k]=p+r;}}
  LCC8=S('lc');
  {const c=S('coarse');const n=CNXg*CNZg;COARSE=new Int16Array(n);for(let j=0;j<CNZg;j++)for(let i=0;i<CNXg;i++){const k=j*CNXg+i;const r=(c[k]|(c[n+k]<<8))<<16>>16;let p=0;if(j>0&&i>0)p=COARSE[k-1]+COARSE[k-CNXg]-COARSE[k-CNXg-1];else if(j===0&&i>0)p=COARSE[k-1];else if(i===0&&j>0)p=COARSE[k-CNXg];COARSE[k]=p+r;}}
  LODC=S('lodc');LODH=S('lodh');COASTA=cp(S('coast'),Float32Array);BOFFS=cp(S('boffs'),Uint32Array);BLDS=S('blds');
  const [RX,RZ]=META.roadOrigin;
  {const rb=S('roads');const rv=new DataView(rb.buffer,rb.byteOffset,rb.byteLength);let o=0;
    for(let k=0;k<META.nroads;k++){const c=rv.getUint8(o),fl=rv.getUint8(o+1),layer=rv.getInt8(o+2),w=rv.getUint8(o+3)/5,ni=rv.getUint16(o+4,true),np=rv.getUint16(o+6,true);o+=8;
      const pts=new Float32Array(np*2);for(let i=0;i<np;i++){pts[i*2]=rv.getInt16(o,true)/2+RX;pts[i*2+1]=rv.getInt16(o+2,true)/2+RZ;o+=4;}ROADS.push({c,fl,layer,w,name:META.names[ni]||'',pts});}}
  {const pb=S('plats');const pv=new DataView(pb.buffer,pb.byteOffset,pb.byteLength);let q=0;for(let k=0;k<META.nplats;k++){const n=pv.getUint16(q,true);q+=2;const a=new Float32Array(n*2);for(let i=0;i<n;i++){a[i*2]=pv.getInt16(q,true)/2+RX;a[i*2+1]=pv.getInt16(q+2,true)/2+RZ;q+=4;}PLATS.push(a);}}
  {const tb=S('tracks');const tv=new DataView(tb.buffer,tb.byteOffset,tb.byteLength);let q=0;for(let k=0;k<META.ntracks;k++){const fl=tv.getUint8(q),n=tv.getUint16(q+1,true);q+=3;const a=new Float32Array(n*2);for(let i=0;i<n;i++){a[i*2]=tv.getInt16(q,true)/2+RX;a[i*2+1]=tv.getInt16(q+2,true)/2+RZ;q+=4;}TRACKS.push({fl,pts:a});}}
}
const SEA=0;
function chunkIndex(x,z){const ci=Math.floor((x-X0)/CH),cj=Math.floor((z-Z0)/CH);if(ci<0||cj<0||ci>=CNX||cj>=CNZ)return -1;return CIDX[cj*CNX+ci];}
function coarseH(x,z){let fx=(x-X0)/CG,fz=(z-Z0)/CG;fx=clamp(fx,0,CNXg-1.001);fz=clamp(fz,0,CNZg-1.001);const i=fx|0,j=fz|0,ax=fx-i,az=fz-j,k=j*CNXg+i;
  return ((COARSE[k]*(1-ax)+COARSE[k+1]*ax)*(1-az)+(COARSE[k+CNXg]*(1-ax)+COARSE[k+CNXg+1]*ax)*az)*0.2;}
function cornerH(b,k){const h=DEMC[b+k]*0.2;return LCC8[b+k]===1&&h>0?h-2.2:h;}
function demH(x,z){
  const ci=Math.floor((x-X0)/CH),cj=Math.floor((z-Z0)/CH);if(ci<0||cj<0||ci>=CNX||cj>=CNZ)return coarseH(x,z);const c=CIDX[cj*CNX+ci];if(c<0)return coarseH(x,z);
  const fx=clamp((x-(X0+ci*CH))/GS,0,N1-1.001),fz=clamp((z-(Z0+cj*CH))/GS,0,N1-1.001);const i=fx|0,j=fz|0,ax=fx-i,az=fz-j,b=c*N1*N1,k=j*N1+i;
  return (cornerH(b,k)*(1-ax)+cornerH(b,k+1)*ax)*(1-az)+(cornerH(b,k+N1)*(1-ax)+cornerH(b,k+N1+1)*ax)*az;}
function cellK(x,z){const ci=Math.floor((x-X0)/CH),cj=Math.floor((z-Z0)/CH);if(ci<0||cj<0||ci>=CNX||cj>=CNZ)return -1;const c=CIDX[cj*CNX+ci];if(c<0)return -1;
  const i=clamp(Math.round((x-(X0+ci*CH))/GS),0,N1-1),j=clamp(Math.round((z-(Z0+cj*CH))/GS),0,N1-1);return c*N1*N1+j*N1+i;}
function rawH(x,z){const k=cellK(x,z);return k<0?coarseH(x,z):DEMC[k]*0.2;}
function lcAt(x,z){const k=cellK(x,z);return k<0?(coarseH(x,z)<0?1:0):LCC8[k];}
function coastZ(x){const f=clamp((x-X0)/10,0,COASTA.length-1.001);const i=f|0;return lerp(COASTA[i],COASTA[i+1],f-i);}
const isDetail=(x,z)=>chunkIndex(x,z)>=0;

/* ================= lines & trains ================= */
const LINES={
  jr:{name:'JR東海道線',short:'東海道線',color:'#f68b1e',plat:300,car:{len:20,n:10,body:'#e6e9ec',stripes:[['#f68b1e',0.95,0.38],['#1d8a4a',1.33,0.16]],w:2.95,h:3.0},vmax:33},
  odn:{name:'小田急江ノ島線',short:'小田急線',color:'#1a5fb4',plat:200,car:{len:20,n:6,body:'#e6e9ec',stripes:[['#1a5fb4',1.0,0.42]],w:2.9,h:3.0},vmax:28},
  ods:{name:'小田急江ノ島線',short:'小田急線',color:'#1a5fb4',plat:200,car:{len:20,n:6,body:'#e6e9ec',stripes:[['#1a5fb4',1.0,0.42]],w:2.9,h:3.0},vmax:20},
  sot:{name:'相鉄本線',short:'相鉄線',color:'#1d3c8f',plat:200,car:{len:20,n:10,body:'#17295e',stripes:[['#e8742f',1.0,0.12],['#3d64b8',1.25,0.08]],w:2.95,h:3.0},vmax:28},
  izm:{name:'相鉄いずみ野線',short:'相鉄線',color:'#1d3c8f',plat:200,car:{len:20,n:10,body:'#17295e',stripes:[['#e8742f',1.0,0.12],['#3d64b8',1.25,0.08]],w:2.95,h:3.0},vmax:28},
  blu:{name:'横浜市営地下鉄ブルーライン',short:'ブルーライン',color:'#0072bc',plat:120,car:{len:18,n:6,body:'#dfe3e8',stripes:[['#0072bc',0.95,0.45]],w:2.76,h:3.0},vmax:22},
  eno:{name:'江ノ島電鉄線',short:'江ノ電',color:'#2f8f4e',plat:56,car:{len:12.5,n:4,two:['#2f8f4e','#f2e6c4'],w:2.5,h:2.9,roof:'#6f7780'},vmax:11,single:true},
  mono:{name:'湘南モノレール',short:'湘南モノレール',color:'#d6392f',plat:45,car:{len:15,n:3,body:'#f4f4f2',stripes:[['#d6392f',0.6,0.4]],w:2.6,h:3.1},vmax:16,mono:true,single:true},
};
const ROMANCE={len:20,n:7,body:'#c2463d',stripes:[['#e9e2d6',1.0,0.18],['#3a3a3a',0.2,0.15]],w:2.9,h:3.1,roof:'#c2463d'};
function initLines(){
  for(const k in LINES){const l=LINES[k];const D=META.lines[k];l.key=k;l.path=new Path(D.pts);l.path.flags=D.flags;l.path.offs=D.offs;l.cgap=l.mono?0.6:0.8;l.halfT=(l.car.n*l.car.len+(l.car.n-1)*l.cgap)/2;
    l.st=META.stations[k].map(s=>{const a=[s[0],s[1]];a.x=s[2];a.z=s[3];return a;});
    if(k==='eno'){for(const [n,e,x,z] of [['稲村ヶ崎','Inamuragasaki',3132.8,3831.5],['極楽寺','Gokurakuji',3747.8,3293.6],['長谷','Hase',4401.1,3062.8]]){if(l.st.some(q=>q[0]===n))continue;const q=l.path.near(x,z);if(q.d<40&&q.s<l.path.L-40){const a=[n,e];a.x=x;a.z=z;l.st.push(a);}}}
    for(const st of l.st){st.s=l.path.near(st.x,st.z).s;}
    l.stByName=new Map(l.st.map(s=>[s[0],s]));}
}

/* ================= height model with rail beds ================= */
const FIDX=new SegIndex(64);
function heightAt(x,z){
  let h=demH(x,z);
  const m=FIDX.nearest(x,z);
  if(m){for(const v of m.values()){const f=v.data;const d=Math.sqrt(v.d2);if(d>f.half+f.blend)continue;if(f.path.flagAt(v.s)!==0)continue;const w=1-smooth(f.half,f.half+f.blend,d);h=lerp(h,f.path.py(v.s)-f.sink,w);}}
  return h;
}
function waterAt(x,z){const k=cellK(x,z);if(k>=0){if(LCC8[k]===1)return DEMC[k]*0.2>0?DEMC[k]*0.2:SEA;return DEMC[k]*0.2<SEA?SEA:null;}return coarseH(x,z)<SEA?SEA:null;}
const BIDX=new SegIndex(40);
function deckAt(x,z){
  const m=BIDX.nearest(x,z);if(m){let best=null;for(const v of m.values()){const r=v.data;if(Math.sqrt(v.d2)<r.w/2+0.3){const y=r.path.py(v.s);if(best===null||y>best)best=y;}}if(best!==null)return best;}
  const f=FIDX.nearest(x,z);if(f){for(const v of f.values()){const d=v.data;if(Math.sqrt(v.d2)>d.half)continue;if(d.path.flagAt(v.s)===1)return d.path.py(v.s)+0.2;}}
  return null;
}
function groundAt(x,z){let h=heightAt(x,z);const d=deckAt(x,z);if(d!==null&&d>h)h=d;return h;}
/* rail profile: smoothed terrain; bridges stay up, tunnels go under (subways run ~10 m deep) */
function railProfile(l){
  const p=l.path,F=p.flags,n=F.length,step=10;const raw=new Float32Array(n);
  for(let i=0;i<n;i++){const q=p.at(i*step);raw[i]=Math.max(demH(q.x,q.z),0.6);}
  const sm=new Float32Array(n);for(let i=0;i<n;i++){let a=0,c=0;for(let k=-5;k<=5;k++){const j=clamp(i+k,0,n-1);if(F[j]===0||l.mono){a+=raw[j];c++;}}sm[i]=c?a/c:raw[i];}
  const big=new Float32Array(n);for(let i=0;i<n;i++){let a=0,c=0;for(let k=-15;k<=15;k++){a+=raw[clamp(i+k,0,n-1)];c++;}big[i]=a/c;}
  const out=new Float32Array(n);for(let i=0;i<n;i++)out[i]=l.mono?sm[i]+10.5:sm[i];
  for(let i=0;i<n;i++){if(F[i]===0)continue;let j=i;while(j<n&&F[j]===F[i])j++;const a=out[Math.max(0,i-1)],b=out[Math.min(n-1,j)];const runL=(j-i)*step;const st=i===0,en=j>=n;
    for(let k=i;k<j;k++){let y=lerp(st?(F[i]===2?big[k]-11:a):a,en?(F[i]===2?big[k]-11:b):b,(k-i+1)/(j-i+1));
      if(F[i]===1&&!l.mono)y=Math.max(y,sm[k]+(runL>=100?6.5:1.2));
      if(F[i]===2&&!l.mono){if(runL>=150)y=Math.min(y,big[k]-11);}
      out[k]=y;}i=j-1;}
  if(l.key==='blu'){for(let i=0;i<n;i++){const d=i*step;out[i]-=8*(1-smooth(250,600,d));}} // ブルーラインは相鉄より一層深い
  const o2=new Float32Array(n);for(let i=0;i<n;i++){let a=0,c=0;for(let k=-4;k<=4;k++){a+=out[clamp(i+k,0,n-1)];c++;}o2[i]=a/c;}
  p.prof=o2;p.pstep=step;
}
