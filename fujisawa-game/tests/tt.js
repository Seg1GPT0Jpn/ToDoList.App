const { chromium } = require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const pg=await b.newPage({viewport:{width:+(process.env.VW||800),height:+(process.env.VH||500)}});await pg.addInitScript(w=>{window.__LITE=1;if(w)window.__WDEBUG=1},!!process.env.WD);
pg.on('pageerror',e=>console.log('ERR',e.message,e.stack&&e.stack.slice(0,400)));pg.on('console',m=>{if(m.type()==='error'||m.text().startsWith('LOG'))console.log('CE',m.text().slice(0,400))});
await pg.route('**/three.module.js',r=>r.fulfill({body:fs.readFileSync(require('path').join(require('path').dirname(require.resolve('three')),'three.module.js')),contentType:'application/javascript'}));
await pg.route('https://fonts.googleapis.com/**',r=>r.fulfill({body:'',contentType:'text/css'}));
await pg.route(/^http:\/\/local\/(?!x\.html).*/,r=>{const p=decodeURIComponent(new URL(r.request().url()).pathname);const fn=__dirname+'/..'+p;if(!fs.existsSync(fn))return r.fulfill({status:404,body:''});r.fulfill({body:fs.readFileSync(fn),contentType:p.endsWith('.jpg')?'image/jpeg':'application/octet-stream'});});
const cp=require('child_process');const GC=require('path').join(require('os').tmpdir(),'gsi_cache');try{fs.mkdirSync(GC,{recursive:true});}catch(e){}
await pg.route(/cyberjapandata\.gsi\.go\.jp/,r=>{const u=r.request().url();const fn=require('path').join(GC,u.replace(/[^a-z0-9]/gi,'_'));
  if(!fs.existsSync(fn)){const res=cp.spawnSync('curl',['-sS','-m','30','-o',fn,'-w','%{http_code}',u],{encoding:'utf8'});if(res.stdout.trim()!=='200'){try{fs.unlinkSync(fn);}catch(e){}return r.fulfill({status:404,body:'',headers:{'access-control-allow-origin':'*'}});}}
  r.fulfill({body:fs.readFileSync(fn),headers:{'access-control-allow-origin':'*','content-type':u.endsWith('.jpg')?'image/jpeg':u.endsWith('.png')?'image/png':'application/octet-stream'}});});
const html='<!doctype html><html><head><meta charset="utf-8"></head><body>'+fs.readFileSync(process.env.H||__dirname+'/test.html','utf8')+'</body></html>';
await pg.route('http://local/x.html',r=>r.fulfill({body:html,contentType:'text/html'}));
const t0=Date.now();
await pg.goto('http://local/x.html');
try{await pg.waitForFunction(()=>window.__dbg,{timeout:900000});}catch(e){console.log('TIMEOUT',await pg.evaluate(()=>document.querySelector('#loading .msg').textContent));await b.close();return;}
console.log('loaded in',(Date.now()-t0)/1000,'s');
const scr=fs.readFileSync(process.argv[2],'utf8');
const r=await pg.evaluate(scr);console.log(typeof r==='string'?r:JSON.stringify(r,null,0));
if(process.argv[3]){await pg.screenshot({path:process.argv[3],timeout:180000});}
await b.close();})();
