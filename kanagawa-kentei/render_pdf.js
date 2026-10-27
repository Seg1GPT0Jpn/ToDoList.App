// HTML を PDF に変換する（node render_pdf.js）
const { chromium } = require('playwright');
const path = require('path');
const names = ['01_問題冊子', '02_解答用紙', '03_解答と解説'];
const footer = '<div style="width:100%;text-align:center;font-size:9pt;font-family:serif">- <span class="pageNumber"></span> -</div>';
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const n of names) {
    await page.goto('file://' + path.resolve(__dirname, n + '.html'));
    await page.waitForLoadState('networkidle');
    await page.pdf({ path: path.resolve(__dirname, n + '.pdf'), format: 'A4', preferCSSPageSize: true,
      displayHeaderFooter: true, headerTemplate: '<span></span>', footerTemplate: footer });
  }
  await browser.close();
  console.log('出力:', names.map(n => n + '.pdf').join(', '));
})();
