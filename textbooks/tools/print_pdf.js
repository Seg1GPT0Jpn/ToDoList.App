// HTML を A4 の PDF に印刷する。build_pdf.py から呼ばれる。
// 使い方: node print_pdf.js <jobs.json>
//   jobs.json = [{"html": "...", "pdf": "...", "title": "...", "style": "math" | "plain"}]
const fs = require('fs');
let chromium;
try {
  ({ chromium } = require('playwright'));
} catch (e) {
  // tools/node_modules に無ければ、グローバルにインストールされた playwright を使う
  const globalRoot = require('child_process').execSync('npm root -g').toString().trim();
  ({ chromium } = require(globalRoot + '/playwright'));
}

const small = 'font-size:9px;color:#444;font-family:sans-serif;';

(async () => {
  const jobs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const job of jobs) {
    await page.goto('file://' + job.html, { waitUntil: 'load', timeout: 0 });
    await page.evaluate(() => document.fonts.ready);
    if (job.style === 'book') {
      // 本（build_book.py）：余白を小さくし、ページ番号はあとで入れる
      await page.pdf({
        path: job.pdf, format: 'A4', printBackground: true, timeout: 0,
        margin: { top: '12mm', bottom: '14mm', left: '13mm', right: '13mm' },
      });
      console.log('PDF:', job.pdf);
      continue;
    }
    if (job.style === 'test') {
      // 定期テスト（build_tests.py）：用紙は CSS の @page（算数 A3・国語 A4横・社会 B5 など）。柱は教科ごとに実物に合わせる
      const k = job.kind || '';
      const num = '<span class="pageNumber"></span>';
      const foot = k === 'rika'
        ? `${job.title}　${num} / <span class="totalPages"></span>`
        : (k === 'sansu' ? '' : num);
      const head = k === 'shakai'
        ? `<div style="width:100%;text-align:right;padding-right:10mm;${small}"><span style="border:1px solid #000;padding:0 3px">${job.title.replace(/^.*?　/, '')}</span></div>`
        : '<span></span>';
      await page.pdf({
        path: job.pdf, printBackground: true, timeout: 0, preferCSSPageSize: true,
        margin: k === 'sansu' ? { top: '14mm', bottom: '12mm', left: '16mm', right: '16mm' }
          : k === 'shakai' ? { top: '12mm', bottom: '11mm', left: '10mm', right: '10mm' }
          : { top: '12mm', bottom: '13mm', left: '14mm', right: '14mm' },
        displayHeaderFooter: true,
        headerTemplate: head,
        footerTemplate: `<div style="width:100%;text-align:center;${small}">${foot}</div>`,
      });
      console.log('PDF:', job.pdf);
      continue;
    }
    const math = job.style === 'math';
    await page.pdf({
      path: job.pdf,
      format: 'A4',
      printBackground: true,
      margin: math
        ? { top: '16mm', bottom: '14mm', left: '16mm', right: '8mm' }
        : { top: '14mm', bottom: '16mm', left: '14mm', right: '14mm' },
      displayHeaderFooter: true,
      // 算数・数学：教科書のように右上に「柱」とページ番号。ほかの教科：下にページ番号。
      headerTemplate: math
        ? `<div style="width:100%;text-align:right;padding-right:19mm;${small}">${job.title}　<span class="pageNumber"></span></div>`
        : '<span></span>',
      footerTemplate: math
        ? '<span></span>'
        : `<div style="width:100%;text-align:center;${small}">${job.title}　<span class="pageNumber"></span> / <span class="totalPages"></span></div>`,
    });
    console.log('PDF:', job.pdf);
  }
  await browser.close();
})();
