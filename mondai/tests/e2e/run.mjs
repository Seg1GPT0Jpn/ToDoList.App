// E2E テスト（Playwright）。使い方：cd mondai && node tests/e2e/run.mjs
// リポジトリのルートを簡易サーバーで配信し、実際のブラウザで主要な操作を通しで確かめる
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const require = createRequire(import.meta.url);
const { chromium, devices } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '../../..');
const PORT = 8766;
const BASE = `http://localhost:${PORT}/mondai/`;

const results = [];
let failed = 0;
let lastPage = null;
async function test(name, fn) {
  try { await fn(); results.push(['OK', name]); }
  catch (e) {
    failed++;
    results.push(['NG', name, String(e && e.message || e).split('\n')[0]]);
    if (lastPage) {
      try {
        await lastPage.screenshot({ path: path.join(here, `_fail_${failed}.png`) });
        // 開いたままのダイアログを閉じて、次のテストに影響させない
        await lastPage.evaluate(() => document.querySelectorAll('.modal-back').forEach(m => m.remove()));
      } catch (_) { /* 撮れなくても続ける */ }
    }
  }
}
const assert = (c, msg) => { if (!c) throw new Error(msg); };

for (const f of fs.readdirSync(here)) if (/^_fail_\d+\.png$/.test(f)) fs.unlinkSync(path.join(here, f));
const server = spawn('python3', ['-m', 'http.server', String(PORT)], { cwd: repoRoot, stdio: 'ignore' });
await new Promise(r => setTimeout(r, 800));

const proxy = process.env.HTTPS_PROXY ? { server: process.env.HTTPS_PROXY, bypass: 'localhost,127.0.0.1' } : undefined;
const browser = await chromium.launch({ proxy });
const errors = [];
const newPage = async (opts = {}) => {
  const ctx = await browser.newContext({ viewport: { width: 1360, height: 900 }, ignoreHTTPSErrors: true, acceptDownloads: true, ...opts });
  const p = await ctx.newPage();
  lastPage = p;
  p.on('pageerror', e => errors.push(e.message));
  p.on('console', m => { if (m.type() === 'error' && !/favicon|Failed to load resource/.test(m.text())) errors.push(m.text()); });
  return p;
};
const go = async (p, hash) => { await p.evaluate(h => { location.hash = h; }, hash); await p.waitForTimeout(500); };
const state = (p) => p.evaluate(() => {
  const s = /** @type {any} */ (window).__mondai.state;
  return { questions: s.questions.length, materials: s.materials.map(m => ({ id: m.id, title: m.title, kind: m.kind, status: m.status, blocks: m.blocks.map(b => ({ type: b.type, ref: b.ref, pts: b.pts, perm: b.perm, rev: b.rev })), exam: m.exam, page: m.page })) };
});

try {
  // ---------- 旧版データの移行 ----------
  const p = await newPage();
  // アプリが起動する前に、旧版の保存データを置いておく（最初の1回だけ）
  await p.addInitScript(() => {
    if (sessionStorage.getItem('e2e-seeded')) return;
    sessionStorage.setItem('e2e-seeded', '1');
    localStorage.setItem('mondai.cart', JSON.stringify([{ ref: 'BI-HS-MATH1-U03-B01' }, { q: { id: 'w:x:1:meaning', type: 'short', stem: 'apple', ans: 'りんご', compact: true } }]));
    localStorage.setItem('mondai.saved', JSON.stringify([{ name: '旧プリント', at: Date.now(), cart: [{ ref: 'BI-HS-MATH1-U03-B02' }], settings: { title: '旧プリント', cols: '2' } }]));
  });
  await p.goto(BASE, { waitUntil: 'networkidle' });
  await p.waitForTimeout(1500);

  await test('起動：内蔵問題 3,840 問が zip なしで読み込まれる', async () => {
    const s = await state(p);
    assert(s.questions === 3840, `問題数 ${s.questions}`);
  });
  await test('移行：旧版のカートと保存プリントが教材になる（元データは残る）', async () => {
    const s = await state(p);
    assert(s.materials.some(m => m.title === '旧プリント' && m.page.cols === '2'), '旧プリントがない');
    assert(s.materials.some(m => m.blocks.length === 2), '作業中プリントがない');
    assert(await p.evaluate(() => !!localStorage.getItem('mondai.saved')), '元データが消えた');
  });
  await test('ホーム：はじめての案内とサンプル作成', async () => {
    await go(p, '#/home');
    assert(await p.isVisible('#tutorial'), '案内がない');
    await p.click('#sample');
    await p.waitForTimeout(1200);
    assert((await p.evaluate(() => location.hash)).startsWith('#/editor/'), '教材が開かない');
    assert((await p.textContent('#m-count')).includes('問題 9 問'), await p.textContent('#m-count'));
  });

  // ---------- 問題バンク ----------
  await test('問題バンク：教科・単元（複数）・検索式で絞り込める', async () => {
    await go(p, '#/bank');
    await p.selectOption('[data-facet="subj"]', '数学');
    await p.waitForTimeout(300);
    await p.click('#f-unit .uc:has-text("二次関数")');
    await p.click('#f-unit .uc:has-text("数と式")');
    await p.waitForTimeout(300);
    const n1 = parseInt((await p.textContent('#result-count')).replace(/,/g, ''));
    assert(n1 > 40, `件数 ${n1}`);
    await p.fill('#f-q', 'level:応用 -証明');
    await p.waitForTimeout(700);
    const n2 = parseInt((await p.textContent('#result-count')).replace(/,/g, ''));
    assert(n2 > 0 && n2 < n1, `検索後 ${n2}`);
    await p.fill('#f-q', '最大 OR 最小');
    await p.waitForTimeout(700);
    assert(parseInt(await p.textContent('#result-count')) > 0, 'OR 検索が0件');
  });
  await test('問題バンク：問題を登録できる（検証つき）', async () => {
    await p.click('#f-reset');
    await p.click('#new-q');
    await p.waitForSelector('.modal');
    await p.fill('[name=stem]', 'テスト用：$2+3$ の値を求めなさい。');
    await p.selectOption('[name=type]', 'short');
    await p.waitForTimeout(200);
    await p.fill('[name=ans]', '5');
    await p.click('summary:has-text("分類・属性")');
    await p.fill('[name=checkExpr]', '2+3');
    await p.fill('[name=subj]', '数学');
    await p.fill('[name=unit]', 'E2E単元');
    await p.click('#run-check');
    assert((await p.textContent('#check-out')).length > 0, '検算結果がない');
    await p.click('#qe-save');
    await p.waitForTimeout(600);
    await p.fill('#f-q', 'テスト用');
    await p.waitForTimeout(700);
    assert((await p.textContent('#result-count')).startsWith('1'), await p.textContent('#result-count'));
  });
  await test('問題バンク：編集すると版が上がり、履歴から戻せる', async () => {
    await p.click('.qrow [data-act=edit]');
    await p.fill('[name=stem]', 'テスト用：$2+4$ の値を求めなさい。');
    await p.fill('[name=ans]', '6');
    await p.click('#qe-save');
    await p.waitForTimeout(600);
    await p.click('.qrow [data-act=history]');
    await p.waitForSelector('[data-restore]');
    assert((await p.textContent('.modal')).includes('版 1'), '旧版がない');
    await p.click('[data-restore]');
    await p.waitForTimeout(600);
    assert((await p.textContent('.qrow .qstem')).includes('2'), '戻らない');
  });
  await test('問題バンク：複製・類似検出・教材への追加・削除', async () => {
    await p.click('.qrow [data-act=dup]');
    await p.waitForSelector('#qe-save');
    await p.click('#qe-save');
    await p.waitForTimeout(600);
    assert((await p.textContent('#result-count')).startsWith('2'), '複製されない');
    await p.click('.qrow [data-act=similar]');
    await p.waitForSelector('.modal');
    assert(/完全一致|数値だけ違う|似ている/.test(await p.textContent('.modal')), '類似が出ない');
    await p.click('.modal [data-close]');
    await p.click('.qrow [data-act=toggle]');
    await p.waitForTimeout(400);
    p.once('dialog', d => d.accept());
    await p.click('.qrow:nth-child(2) [data-act=delete]');
    await p.waitForTimeout(600);
    assert((await p.textContent('#result-count')).startsWith('1'), '削除されない');
  });
  await test('問題バンク：内蔵問題の削除は非表示で、設定から戻せる', async () => {
    await p.fill('#f-q', '');
    await p.waitForTimeout(500);
    const before = (await state(p)).questions;
    p.once('dialog', d => d.accept());
    await p.click('.qrow [data-act=delete]');
    await p.waitForTimeout(600);
    assert((await state(p)).questions === before - 1, '減らない');
    await go(p, '#/settings');
    await p.click('#restore-hidden');
    await p.waitForTimeout(600);
    assert((await state(p)).questions === before, '戻らない');
  });
  await test('問題バンク：CSV・JSON で書き出し、取り込み直せる', async () => {
    await go(p, '#/bank');
    await p.fill('#f-q', 'テスト用');
    await p.waitForTimeout(700);
    await p.click('#export-q');
    const [dl] = await Promise.all([p.waitForEvent('download'), p.click('#ex-csv')]);
    const file = await dl.path();
    const csv = fs.readFileSync(file, 'utf8');
    assert(csv.includes('問題文') && csv.includes('テスト用'), 'CSV の中身');
    const csvPath = path.join(here, '_e2e.csv');
    fs.writeFileSync(csvPath, csv.replace(/U-[0-9A-Z]+/g, ''));
    const chooser = p.waitForEvent('filechooser');
    await p.click('#import-q');
    await (await chooser).setFiles(csvPath);
    await p.waitForSelector('#im-go');
    await p.click('#im-go');
    await p.waitForTimeout(800);
    fs.unlinkSync(csvPath);
    assert((await p.textContent('#result-count')).startsWith('2'), '取り込めない：' + await p.textContent('#result-count'));
  });
  await test('問題バンク：一括編集（タグ追加）', async () => {
    await p.check('#sel-page');
    await p.click('[data-bulk=edit]');
    await p.fill('[name=addTags]', 'E2Eタグ');
    await p.click('#be-save');
    await p.waitForTimeout(700);
    await p.fill('#f-q', 'tag:E2Eタグ');
    await p.waitForTimeout(700);
    assert((await p.textContent('#result-count')).startsWith('2'), 'タグ検索');
  });

  // ---------- 教材制作 ----------
  let matId = '';
  await test('教材：新規作成・ブロック追加・並べかえ・元に戻す・自動保存', async () => {
    await go(p, '#/editor/new');
    await p.click('[data-kind=test]');
    await p.waitForTimeout(800);
    matId = (await p.evaluate(() => location.hash)).split('/')[2];
    await p.fill('#m-title', 'E2E 定期テスト');
    await p.click('[data-add=heading]');
    await p.fill('.blk:last-child input[data-f=text]', '第1部');
    await p.click('[data-add=text]');
    await p.fill('.blk:last-child textarea', '説明文 $x^2$');
    await p.click('.blk:last-child [data-up]');
    await p.waitForTimeout(300);
    let blocks = await p.$$eval('.blk', e => e.map(x => x.querySelector('b').textContent));
    assert(blocks[0] === '文章', '並べかえ ' + blocks.join(','));
    await p.click('#undo');
    await p.waitForTimeout(300);
    blocks = await p.$$eval('.blk', e => e.map(x => x.querySelector('b').textContent));
    assert(blocks[0] === '見出し', '元に戻す ' + blocks.join(','));
    await p.click('#redo');
    await p.waitForTimeout(1500);
    assert((await p.textContent('#savestate')).includes('保存済み'), await p.textContent('#savestate'));
  });
  await test('教材：保存した教材を開き直して再編集できる', async () => {
    await p.reload({ waitUntil: 'networkidle' });
    await p.waitForTimeout(1500);
    assert((await p.inputValue('#m-title')) === 'E2E 定期テスト', 'タイトルが残っていない');
    assert((await p.$$('.blk')).length === 2, 'ブロック数');
  });
  await test('教材：問題を追加し、用紙（B4 横・2段・ヘッダー・ページ番号）を設定できる', async () => {
    await go(p, '#/bank');
    await p.fill('#f-q', 'subj:数学 unit:二次関数 level:基礎');
    await p.waitForTimeout(700);
    await p.click('#add-page');
    await p.waitForTimeout(600);
    await go(p, '#/editor/' + matId);
    await p.click('[data-tab=page]');
    await p.selectOption('[data-pg=size]', 'B4');
    await p.selectOption('[data-pg=orientation]', 'landscape');
    await p.selectOption('[data-pg=cols]', '2');
    await p.fill('[data-pg=header]', 'E2E高校');
    await p.waitForTimeout(500);
    const css = await p.textContent('#page-css');
    assert(css.includes('B4 landscape') && css.includes('E2E高校') && css.includes('counter(page)'), css);
    assert(await p.isVisible('#preview .pbody.cols2'), '2段');
  });
  await test('出力：問題用紙・解答用紙・解答解説が見本に出る', async () => {
    await p.selectOption('[data-pr=answer]', 'sheet');
    await p.selectOption('[data-pr=key]', 'expl');
    await p.waitForTimeout(600);
    const txt = await p.textContent('#preview');
    assert(txt.includes('解答用紙') && txt.includes('解答・解説'), '部品が足りない');
    assert((await p.$$('#preview .asheet tr')).length >= 10, '解答欄の行');
    assert((await p.$$('#preview .katex')).length > 0, '数式が表示されない');
  });
  await test('配点：問題ごとの配点と満点の一致チェック', async () => {
    await p.selectOption('[data-pr=points]', 'equal');
    await p.fill('#full-marks', '50');
    await p.dispatchEvent('#full-marks', 'change');
    await p.waitForTimeout(500);
    assert((await p.textContent('#m-count')).includes('合計 50 点'), await p.textContent('#m-count'));
  });
  await test('印刷・PDF のファイル名が【試験名】【種類】になる', async () => {
    await p.evaluate(() => { /** @type {any} */ (window).__titles = []; window.print = () => { /** @type {any} */ (window).__titles.push(document.title); }; });
    await p.selectOption('[data-pr=key]', 'expl');
    for (const part of ['all', 'questions', 'sheet', 'key']) { await p.click(`[data-print=${part}]`); await p.waitForTimeout(400); }
    await p.selectOption('[data-pr=key]', 'ans');
    await p.waitForTimeout(300);
    await p.click('[data-print=all]');
    await p.waitForTimeout(400);
    const t = await p.evaluate(() => /** @type {any} */ (window).__titles);
    const want = ['【E2E 定期テスト】【問題+解答・解説】', '【E2E 定期テスト】【問題】', '【E2E 定期テスト】【解答用紙】', '【E2E 定期テスト】【解答・解説】', '【E2E 定期テスト】【問題+解答】'];
    assert(JSON.stringify(t) === JSON.stringify(want), JSON.stringify(t));
    await p.selectOption('[data-pr=key]', 'expl');
  });
  await test('単語・用語テストが作れる（データがないときは案内）', async () => {
    await p.click('[data-tab=blocks]');
    await p.click('[data-add=words]');
    await p.waitForTimeout(300);
    const t = await p.textContent('#toast');
    assert(t.includes('単語帳') || await p.isVisible('#w-go'), '反応なし');
    if (await p.isVisible('.modal')) await p.click('.modal [data-close]');
  });

  // ---------- テスト制作 ----------
  await test('テスト制作：条件どおりに選び、配点合計＝満点、A・B 版を作る', async () => {
    await go(p, '#/exam');
    await p.selectOption('#x-subj', '数学');
    await p.waitForTimeout(300);
    await p.selectOption('#x-course', '数学Ⅰ');
    await p.waitForTimeout(300);
    await p.fill('#x-total', '100'); await p.dispatchEvent('#x-total', 'change');
    await p.fill('#x-count', '12'); await p.dispatchEvent('#x-count', 'change');
    await p.selectOption('#x-versions', '2');
    await p.fill('#x-title', 'E2E 実力テスト'); await p.dispatchEvent('#x-title', 'change');
    await p.click('#x-build');
    await p.waitForTimeout(800);
    assert((await p.textContent('#x-result')).includes('一致しています'), await p.textContent('#x-result .notice'));
    await p.click('#x-save');
    await p.waitForTimeout(1200);
    const s = await state(p);
    const vs = s.materials.filter(m => m.title.startsWith('E2E 実力テスト'));
    assert(vs.length === 2, '版の数 ' + vs.length);
    for (const v of vs) {
      const pts = v.blocks.filter(b => b.type === 'question').reduce((a, b) => a + b.pts, 0);
      assert(pts === 100, `${v.title} の合計 ${pts}`);
    }
    const orderA = vs[0].blocks.filter(b => b.type === 'question').map(b => b.ref).join();
    const orderB = vs[1].blocks.filter(b => b.type === 'question').map(b => b.ref).join();
    assert(orderA !== orderB || vs.some(v => v.blocks.some(b => b.perm)), 'A・B が同じ');
  });

  // ---------- 入試形式 ----------
  for (const [fmt, label, sheetSel] of [['kyotsu', '共通テスト', '.msheet .bub'], ['kanagawa', '神奈川県入試', '.msheet .bub'], ['niji', '二次試験', '.pd-q .lines']]) {
    await test(`入試形式：${label}の形で作れる（表紙・番号・解答用紙）`, async () => {
      await go(p, '#/exam');
      await p.selectOption('#x-format', fmt);
      await p.waitForTimeout(300);
      await p.selectOption('#x-subj', '数学');
      await p.waitForTimeout(300);
      await p.selectOption('#x-course', '数学Ⅰ');
      await p.waitForTimeout(300);
      await p.selectOption('#x-versions', '1');
      await p.click('#x-build');
      await p.waitForTimeout(800);
      assert((await p.textContent('#x-result')).includes('一致しています'), '配点');
      await p.click('#x-save');
      await p.waitForTimeout(1500);
      const txt = await p.textContent('#preview');
      assert(await p.isVisible('#preview .paper.cover'), '表紙がない');
      assert(txt.includes(fmt === 'kanagawa' ? '問1' : '第1問'), '大問の番号');
      assert((await p.$$(`#preview ${sheetSel}`)).length > 0, '解答用紙の形');
      if (fmt === 'kyotsu') assert((await p.$$('#preview .markbox')).length > 0, '解答番号の枠');
    });
  }

  // ---------- 図形 ----------
  await test('図形：教材に図を描いて入れ、問題にも図を付けられる', async () => {
    await go(p, '#/editor/' + matId);
    await p.waitForTimeout(600);
    const n0 = (await p.$$('#preview svg')).length;
    await p.click('[data-tab=blocks]');
    await p.click('[data-add=figure]');
    await p.waitForSelector('[data-preset=graph]');
    await p.click('[data-preset=graph]');
    await p.click('[data-preset=triangle]');
    await p.click('[data-act=save]');
    await p.waitForTimeout(800);
    assert((await p.$$('.blk-fig svg')).length === 1, '図形ブロック');
    assert((await p.$$('#preview svg')).length > n0, '見本に図が出ない');
    assert((await p.innerHTML('#preview')).includes('<polyline') || (await p.innerHTML('#preview')).includes('<path'), 'グラフの線');
    // 問題にも図を付ける
    await go(p, '#/bank?new=1');
    await p.waitForSelector('#fig-draw');
    await p.fill('[name=stem]', '図の三角形について答えなさい。');
    await p.click('#fig-draw');
    await p.waitForSelector('[data-preset=triangle]');
    await p.click('[data-preset=triangle]');
    await p.click('[data-act=save]');
    await p.waitForTimeout(500);
    assert((await p.$$('#qe-prev svg')).length > 0, '問題の見本に図が出ない');
    assert((await p.textContent('#fig-draw')).includes('編集'), '図を編集できない');
    await p.click('.modal [data-close]');
  });

  // ---------- 数値替え ----------
  await test('数値替え：検算の式から自動で数値を変えた問題を作れる', async () => {
    await go(p, '#/editor/new');
    await p.click('[data-kind=quiz]');
    await p.waitForTimeout(800);
    await go(p, '#/bank');
    await p.fill('#f-q', 'テスト用');
    await p.waitForTimeout(700);
    await p.click('.qrow [data-act=toggle]');
    await p.waitForTimeout(400);
    await go(p, '#/editor');
    await p.waitForSelector('[data-vary]');
    const before = await p.textContent('.blk.q .qtext');
    await p.click('[data-vary]');
    await p.waitForSelector('#vy-use');
    await p.click('#vy-use');
    await p.waitForTimeout(500);
    const after = await p.textContent('.blk.q .qtext');
    assert(before !== after, '問題文が変わらない');
    assert((await p.textContent('.blk.q')).includes('数値替え'), '数値替えの印');
  });
  await test('数値替え：テンプレートを編集画面で試せる', async () => {
    await go(p, '#/bank?new=1');
    await p.waitForSelector('[name=stem]');
    await p.selectOption('[name=type]', 'short');
    await p.fill('[name=stem]', '1個 {{a}} 円の品物を 3 個買うといくらか。');
    await p.fill('[name=ans]', '300円');
    await p.click('summary:has-text("数値替えのテンプレート")');
    await p.fill('[name=varyJson]', JSON.stringify({ vars: { a: { min: 50, max: 200, step: 10 } }, stem: '1個 {{a}} 円の品物を 3 個買うといくらか。', ans: '{{=3*a}}円', check: '3*a', expl: '{{a}}×3={{=3*a}}', original: { a: 100 } }));
    await p.click('#try-vary');
    await p.waitForTimeout(300);
    assert(/円/.test(await p.textContent('#vary-out')) && !(await p.textContent('#vary-out')).includes('作れません'), await p.textContent('#vary-out'));
    await p.click('.modal [data-close]');
  });

  // ---------- 解答・解説 ----------
  await test('解答・解説：一覧と要再確認の通知', async () => {
    await go(p, '#/answers/' + matId);
    assert((await p.$$('[data-act=edit]')).length > 0, '問題がない');
    // バンク側で問題を編集 → この教材に「要再確認」
    const ref = (await state(p)).materials.find(m => m.id === matId).blocks.find(b => b.type === 'question').ref;
    await go(p, '#/bank?id=' + encodeURIComponent(ref));
    await p.waitForSelector('#qe-save');
    await p.click('summary:has-text("解説・採点基準")');
    await p.fill('[name=expl]', 'E2E で書きかえた解説');
    await p.click('#qe-save');
    await p.waitForTimeout(600);
    await go(p, '#/answers/' + matId);
    assert((await p.textContent('#a-body')).includes('要再確認'), '通知がない');
    await p.click('[data-act=update]');
    await p.waitForTimeout(500);
    assert(!(await p.textContent('#a-body')).includes('バンクの問題が更新されました'), '更新できない');
  });

  // ---------- ライブラリ ----------
  await test('ライブラリ：検索・複製・アーカイブ', async () => {
    await go(p, '#/library');
    await p.fill('#l-q', 'E2E 定期');
    await p.waitForTimeout(300);
    await p.click('tr[data-id] [data-act=dup]');
    await p.waitForTimeout(500);
    assert((await p.$$('tr[data-id]')).length === 2, '複製');
    await p.click('tr[data-id]:nth-of-type(2) [data-act=archive]');
    await p.waitForTimeout(500);
    assert((await p.$$('tr[data-id]')).length === 1, 'アーカイブ');
  });

  // ---------- 分析 ----------
  await test('分析：記録がないときは架空の数字を出さず、記録すると正答率が出る', async () => {
    await go(p, '#/analytics/' + matId);
    assert((await p.textContent('#an-sum')).includes('まだ学習結果の記録がありません'), '空の表示');
    await p.click('#an-entry');
    await p.fill('[data-name]', '生徒A');
    const cells = await p.$$('#an-grid [data-b]');
    await cells[0].fill('○'); await cells[1].fill('×');
    await p.click('#an-addrow');
    await p.fill('#an-grid tr:last-child [data-name]', '生徒B');
    const cells2 = await p.$$('#an-grid tr:last-child [data-b]');
    await cells2[0].fill('○'); await cells2[1].fill('○');
    await p.click('#an-save');
    await p.waitForTimeout(800);
    const t = await p.textContent('#an-out');
    assert(t.includes('100%') && t.includes('50%'), '正答率が出ない');
  });

  // ---------- AI（未接続） ----------
  await test('AI 未接続でも AI スタジオで既存問題の検索・追加ができる', async () => {
    await go(p, '#/studio');
    assert((await p.textContent('.notice')).includes('AI は使えません'), '未接続の案内');
    assert(await p.isDisabled('#s-gen'), '生成ボタンが押せてしまう');
    await p.fill('[data-c=subj]', '数学'); await p.dispatchEvent('[data-c=subj]', 'change');
    await p.fill('[data-c=units]', '三角関数'); await p.dispatchEvent('[data-c=units]', 'change');
    await p.fill('[data-c=count]', '5'); await p.dispatchEvent('[data-c=count]', 'change');
    await p.click('#s-search');
    await p.waitForTimeout(500);
    assert((await p.$$('#s-items .qrow')).length === 5, '既存問題が選べない');
    assert((await p.textContent('#s-items')).includes('既存（問題バンク）'), 'ラベル');
  });
  await test('チーム：未接続のときは設定手順を表示', async () => {
    await go(p, '#/team');
    assert((await p.textContent('#view')).includes('クラウドに接続していません'), '案内');
  });

  // ---------- 設定・バックアップ ----------
  await test('バックアップを保存し、復元できる', async () => {
    await go(p, '#/settings');
    const [dl] = await Promise.all([p.waitForEvent('download'), p.click('#backup')]);
    const data = JSON.parse(fs.readFileSync(await dl.path(), 'utf8'));
    assert(data.format === 'mondai-backup' && data.stores.materials.length >= 4, 'バックアップの中身');
    // 別のブラウザ（空のデータ）に復元
    const p2 = await newPage();
    await p2.goto(BASE + '#/settings', { waitUntil: 'networkidle' });
    await p2.waitForTimeout(1200);
    const bk = path.join(here, '_e2e_backup.json');
    fs.writeFileSync(bk, JSON.stringify(data));
    const chooser = p2.waitForEvent('filechooser');
    await p2.click('#restore');
    await (await chooser).setFiles(bk);
    await p2.waitForSelector('#do-restore');
    await p2.click('#do-restore');
    await p2.waitForTimeout(2500);
    fs.unlinkSync(bk);
    const s2 = await state(p2);
    assert(s2.materials.length === data.stores.materials.length, `復元後 ${s2.materials.length}`);
    await p2.context().close();
  });
  await test('不正なバックアップファイルは拒否される', async () => {
    const bad = path.join(here, '_e2e_bad.json');
    fs.writeFileSync(bad, JSON.stringify({ hello: 1 }));
    const chooser = p.waitForEvent('filechooser');
    await p.click('#restore');
    await (await chooser).setFiles(bad);
    await p.waitForTimeout(500);
    fs.unlinkSync(bad);
    assert((await p.textContent('#toast')).includes('バックアップではありません'), await p.textContent('#toast'));
  });
  await test('ダークモードに切り替えられる', async () => {
    await p.selectOption('#theme', 'dark');
    assert((await p.evaluate(() => document.documentElement.dataset.theme)) === 'dark', 'テーマ');
    const bg = await p.evaluate(() => getComputedStyle(document.body).backgroundColor);
    assert(bg !== 'rgb(244, 246, 249)', bg);
    await p.selectOption('#theme', 'auto');
  });
  await test('印刷用 PDF を出力できる（全ページ）', async () => {
    await go(p, '#/editor/' + matId);
    await p.waitForTimeout(800);
    const pdf = await p.pdf({ format: 'A4' });
    assert(pdf.length > 20000, 'PDF が小さい ' + pdf.length);
    fs.writeFileSync(path.join(here, '_last_print.pdf'), pdf);
  });
  await p.context().close();

  // ---------- スマートフォン ----------
  await test('スマートフォン：メニューの開閉と各画面の表示', async () => {
    const m = await newPage({ ...devices['iPhone 13'] });
    await m.goto(BASE, { waitUntil: 'networkidle' });
    await m.waitForTimeout(1200);
    assert(await m.isVisible('#nav-toggle'), 'メニューボタン');
    await m.click('#nav-toggle');
    await m.waitForTimeout(300);
    await m.click('#nav a[data-page=bank]');
    await m.waitForTimeout(800);
    assert((await m.textContent('h1')).includes('問題バンク'), '画面');
    const overflow = await m.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    assert(overflow <= 2, '横にはみ出す ' + overflow);
    for (const h of ['#/editor/new', '#/exam', '#/library', '#/analytics', '#/settings', '#/studio']) {
      await go(m, h);
      const ov = await m.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
      assert(ov <= 2, `${h} が横にはみ出す ${ov}`);
    }
    await m.context().close();
  });

  await test('画面のエラーが出ていない', async () => {
    assert(!errors.length, errors.slice(0, 5).join(' / '));
  });
} finally {
  await browser.close();
  server.kill();
}

for (const r of results) console.log(r[0] === 'OK' ? '✓' : '✗', r[1], r[2] ? '— ' + r[2] : '');
console.log(`\n${results.length - failed} / ${results.length} 件成功`);
process.exit(failed ? 1 : 0);
