// HTML を PDF に変換する（node render_pdf.js [ファイル名...]）
// 引数がなければ問題冊子・解答用紙・解答と解説（受験者用）・採点基準（採点者用）を変換する。認定証はページ番号をつけない。
const { chromium } = require('playwright');
const path = require('path');
const names = process.argv.length > 2 ? process.argv.slice(2) : ['01_問題冊子', '02_解答用紙', '03_解答と解説_受験者用', '05_採点基準_採点者用'];
const footer = '<div style="width:100%;text-align:center;font-size:9pt;font-family:serif">- <span class="pageNumber"></span> -</div>';
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const n of names) {
    await page.goto('file://' + path.resolve(__dirname, n + '.html'));
    await page.waitForLoadState('networkidle');
    await page.pdf({ path: path.resolve(__dirname, n + '.pdf'), format: 'A4', preferCSSPageSize: true,
      displayHeaderFooter: !n.includes('認定証'), headerTemplate: '<span></span>', footerTemplate: footer });
  }
  await browser.close();
  console.log('出力:', names.map(n => n + '.pdf').join(', '));
})();
