/*
 * ブラウザでの動作確認（エミュレータ使用・本番データには触れません）
 *
 *   npx firebase emulators:exec --only firestore,auth --project demo-kco "node tests/e2e/run-e2e.mjs"
 *
 * 必要なもの：playwright-core（NODE_PATH で指定可）と Chromium。
 * テストデータはすべて架空（@example.com）です。
 */
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync } from 'node:fs';
import { createServer } from 'vite';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp } from 'firebase/firestore';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright-core');

const PROJECT = 'demo-kco';
const SHOTS = process.env.SHOTS_DIR || 'e2e-screenshots';
const AUTH = 'http://127.0.0.1:9099';
mkdirSync(SHOTS, { recursive: true });

let passed = 0;
let failed = 0;
function check(label, ok, detail = '') {
  if (ok) {
    passed++;
    console.log('  ✓ ' + label);
  } else {
    failed++;
    console.log('  ✗ ' + label + (detail ? '  … ' + detail : ''));
  }
}

// ---------- テストデータ ----------
const env = await initializeTestEnvironment({
  projectId: PROJECT,
  firestore: { host: '127.0.0.1', port: 8085, rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') }
});
await env.clearFirestore();
await fetch(`${AUTH}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });

const future = new Date(Date.now() + 10 * 86400000);
const futureStr = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Tokyo' }).format(future);

await env.withSecurityRulesDisabled(async ctx => {
  const db = ctx.firestore();
  const now = Timestamp.now();
  await setDoc(doc(db, 'memberAccess', 'member.a@example.com'), { email: 'member.a@example.com', status: 'active', role: 'member', memberId: 'm-a', source: 'sheet' });
  await setDoc(doc(db, 'memberAccess', 'admin@example.com'), { email: 'admin@example.com', status: 'active', role: 'admin', memberId: null, source: 'sheet' });
  await setDoc(doc(db, 'memberAccess', 'left@example.com'), { email: 'left@example.com', status: 'inactive', role: 'member', memberId: 'm-l', source: 'sheet' });
  const member = (id, name, inst, label, part, section) => setDoc(doc(db, 'members', id), { displayName: name, instrument: inst, instrumentLabel: label, part, section, status: 'active', bio: '', roleLabel: '' });
  await member('m-a', 'えーちゃん', 'Va', 'ヴィオラ', 'Va', 'strings');
  await member('m-b', 'びー', 'Vc', 'チェロ', 'Vc', 'strings');
  await member('m-c', 'しー', 'Fl', 'フルート', 'Fl', 'woodwind');
  await member('m-d', 'でぃー', 'Tuba', 'テューバ', 'Tuba', 'brass');
  await setDoc(doc(db, 'stats', 'summary'), {
    memberCount: 4, targetMembers: 80, decisionMembers: 60, minimumMembers: 46, updatedAt: now,
    byPart: [
      { part: 'Fl', label: 'フルート', count: 1, target: 4, min: 2 },
      { part: 'Tuba', label: 'テューバ', count: 1, target: 1, min: 1 },
      { part: 'Va', label: 'ヴィオラ', count: 1, target: 10, min: 5 },
      { part: 'Vc', label: 'チェロ', count: 1, target: 10, min: 5 }
    ]
  });
  await setDoc(doc(db, 'adminStats', 'summary'), { applicantCount: 9, activeApplicantCount: 9, memberCount: 4, statusCounts: { '未対応': 5, '正式参加': 4 }, updatedAt: now });
  await setDoc(doc(db, 'rehearsals', 'r1'), { title: '第1回 合奏練習', date: futureStr, startTime: '13:00', endTime: '16:00', venue: '', content: '初回の顔合わせと合奏', notes: '', target: '全員', scoreNote: '', attendanceDeadline: null, published: true, createdAt: now, updatedAt: now });
  await setDoc(doc(db, 'rehearsals', 'r2'), { title: 'パート練習', date: '', startTime: '', endTime: '', venue: '', content: '', notes: '', target: '', scoreNote: '', attendanceDeadline: null, published: true, createdAt: now, updatedAt: now });
  await setDoc(doc(db, 'announcements', 'n1'), { title: '団員専用ページを公開しました', body: 'ホームから練習予定と出欠を確認できます。', important: true, category: 'general', audience: { type: 'all', values: [] }, published: true, publishedAt: now, createdAt: now, updatedAt: now });
  await setDoc(doc(db, 'announcements', 'n2'), { title: '弦楽器の皆さんへ', body: '分奏の予定を調整中です。', important: false, category: 'practice', audience: { type: 'section', values: ['strings'] }, published: true, publishedAt: now, createdAt: now, updatedAt: now });
  await setDoc(doc(db, 'announcements', 'n3'), { title: '管楽器の皆さんへ', body: '管楽器向けの連絡です。', important: false, category: 'practice', audience: { type: 'section', values: ['woodwind', 'brass'] }, published: true, publishedAt: now, createdAt: now, updatedAt: now });
});

// ---------- 開発サーバー（エミュレータ接続モード） ----------
const server = await createServer({ root: new URL('../..', import.meta.url).pathname, mode: 'emulator', server: { port: 5199, strictPort: true, host: '127.0.0.1' }, logLevel: 'error' });
await server.listen();
const BASE = 'http://127.0.0.1:5199';

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined });

async function newPhone() {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, locale: 'ja-JP', timezoneId: 'Asia/Tokyo' });
  return { ctx, page: await ctx.newPage() };
}

// エミュレータの REST API で、ルールを通さずに保存内容を確認する
async function readAsOwner(path) {
  const res = await fetch(`http://127.0.0.1:8085/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, { headers: { Authorization: 'Bearer owner' } });
  if (!res.ok) return undefined;
  const json = await res.json();
  const conv = v => {
    if ('stringValue' in v) return v.stringValue;
    if ('booleanValue' in v) return v.booleanValue;
    if ('integerValue' in v) return Number(v.integerValue);
    if ('nullValue' in v) return null;
    if ('timestampValue' in v) return v.timestampValue;
    if ('arrayValue' in v) return (v.arrayValue.values || []).map(conv);
    if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, conv(x)]));
    return v;
  };
  return Object.fromEntries(Object.entries(json.fields || {}).map(([k, v]) => [k, conv(v)]));
}

const appears = (locator, timeout = 8000) => locator.waitFor({ timeout }).then(() => true).catch(() => false);

async function emailLinkLogin(page, email) {
  await page.goto(BASE + '/');
  await page.getByLabel('メールアドレス').fill(email);
  await page.getByRole('button', { name: 'ログイン用リンクを送る' }).click();
  await page.getByText('メールを確認してください').waitFor();
  const res = await fetch(`${AUTH}/emulator/v1/projects/${PROJECT}/oobCodes`);
  const codes = (await res.json()).oobCodes.filter(c => c.email === email);
  const link = new URL(codes[codes.length - 1].oobLink);
  const finish = new URL(link.searchParams.get('continueUrl'));
  for (const k of ['apiKey', 'oobCode', 'mode', 'lang']) if (link.searchParams.get(k)) finish.searchParams.set(k, link.searchParams.get(k));
  await page.goto(finish.toString());
}

const pageErrors = [];

try {
  console.log('■ 未ログイン');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await page.goto(BASE + '/members');
    await page.getByRole('button', { name: 'ログイン用リンクを送る' }).waitFor();
    check('団員ページを開いてもログイン画面になる', true);
    await page.screenshot({ path: `${SHOTS}/01-login.png` });
    await ctx.close();
  }

  console.log('■ 一般団員（メールリンクでログイン）');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'member.a@example.com');
    await page.getByText('現在の団員数').waitFor();
    const count = await page.locator('.member-count').getAttribute('aria-label');
    check('ホームに団員数「4 / 80人」', count === '現在の団員数 4人、目標 80人', count);
    check('重要なお知らせが表示', await page.getByText('団員専用ページを公開しました').isVisible());
    check('次回練習の会場は「未定」', (await page.locator('#next-title').locator('..').innerText()).includes('未定'));
    check('自分のパート向け（弦楽器）のお知らせは表示', await page.getByText('弦楽器の皆さんへ').isVisible());
    check('他パート向け（管楽器）のお知らせはホームに出ない', !(await page.getByText('管楽器の皆さんへ').isVisible()));
    check('運営ボタンは表示されない', !(await page.getByRole('link', { name: '運営' }).isVisible()));
    await page.screenshot({ path: `${SHOTS}/02-home-member.png`, fullPage: true });

    await page.getByRole('link', { name: '詳細・出欠' }).click();
    await page.getByRole('button', { name: '出席' }).click();
    await page.getByText('「出席」で登録しました。').waitFor();
    const saved = await readAsOwner('rehearsals/r1/attendance/m-a');
    check('出欠「出席」が保存された', saved?.status === 'present', JSON.stringify(saved));
    await page.screenshot({ path: `${SHOTS}/03-attendance.png`, fullPage: true });

    await page.getByRole('link', { name: '予定', exact: true }).click();
    check('日程未定の練習も一覧に出る', await appears(page.getByText('日程未定').first()));

    await page.getByRole('link', { name: '団員' }).click();
    await page.getByText('びー').waitFor();
    const body = await page.locator('main').innerText();
    check('団員一覧に名前と楽器', body.includes('しー') && body.includes('フルート'));
    check('団員一覧にメールアドレスが出ない', !/@example\.com/.test(body));
    await page.screenshot({ path: `${SHOTS}/04-members.png`, fullPage: true });

    await page.getByRole('link', { name: 'マイページ' }).click();
    await page.getByLabel('呼ばれたい名前').fill('えーさん');
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByText('保存しました。').waitFor();
    const me = await readAsOwner('members/m-a');
    check('表示名を変更できた', me?.displayName === 'えーさん');

    await page.goto(BASE + '/admin');
    check('管理画面を開いても「運営メンバー専用」', await appears(page.getByText('この画面は運営メンバー専用です。')));

    await page.getByRole('link', { name: 'マイページ' }).click();
    await page.getByRole('button', { name: 'ログアウト' }).click();
    await page.getByRole('button', { name: 'ログイン用リンクを送る' }).waitFor();
    check('ログアウトできる', true);
    await ctx.close();
  }

  console.log('■ 加入確定前ユーザー（応募しただけ）');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'applicant@example.com');
    await page.getByText('加入確定後にご利用いただけます').waitFor();
    check('「加入確定後にご利用いただけます」画面', true);
    check('団員数などは表示されない', !(await page.getByText('現在の団員数').isVisible()));
    await page.screenshot({ path: `${SHOTS}/05-not-member.png` });
    await ctx.close();
  }

  console.log('■ 退団ユーザー');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'left@example.com');
    await page.getByText('現在ご利用いただけません').waitFor();
    check('「現在ご利用いただけません」画面', true);
    await ctx.close();
  }

  console.log('■ 管理者');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'admin@example.com');
    await page.getByRole('link', { name: '運営' }).click();
    await page.getByText('参加希望者（応募）').waitFor();
    const tiles = await page.locator('.stat-tiles').innerText();
    check('参加希望者数と加入確定者数を分けて表示', tiles.includes('9') && tiles.includes('4'));
    await page.screenshot({ path: `${SHOTS}/06-admin-dashboard.png`, fullPage: true });

    await page.getByRole('link', { name: '練習・出欠' }).click();
    await page.getByRole('link', { name: '＋ 練習を追加' }).click();
    await page.getByLabel('タイトル').fill('セクション練習（弦）');
    await page.getByLabel('団員に公開する（オフの間は運営だけが見られる下書き）').check();
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByText('出欠状況').waitFor();
    check('練習予定を作成できた（日時・会場は未定のまま）', true);

    await page.getByRole('link', { name: '← 練習予定一覧' }).click();
    await page.getByText('第1回 合奏練習').click();
    await page.getByText('出欠状況').waitFor();
    const tilesR1 = await page.locator('.stat-tiles').innerText();
    check('出欠集計：出席1・未回答3', /出席\s*1/.test(tilesR1) && /未回答\s*3/.test(tilesR1), tilesR1.replace(/\s+/g, ' '));
    await page.screenshot({ path: `${SHOTS}/07-admin-attendance.png`, fullPage: true });

    await page.getByRole('link', { name: 'お知らせ' }).first().click();
    await page.getByRole('button', { name: '＋ お知らせを作成' }).click();
    await page.getByLabel('タイトル').fill('会場変更のお知らせ');
    await page.getByLabel('本文').fill('テスト本文');
    await page.getByLabel('重要なお知らせ（ホームの一番上に目立つ形で表示）').check();
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByText('会場変更のお知らせ').waitFor();
    check('お知らせを作成できた', true);

    await page.getByRole('link', { name: '演奏会' }).click();
    await page.getByRole('button', { name: '第1回演奏会の情報を作成' }).click();
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByRole('button', { name: '編集' }).waitFor();
    const concert = await readAsOwner('concerts/first');
    check('第1回演奏会：日時・会場は空欄（架空の情報を入れない）', concert?.date === '' && concert?.venue === '');
    check('第1回演奏会：メインはドヴォルザーク交響曲第7番', concert?.program?.[0]?.work?.includes('交響曲第7番'));
    await ctx.close();
  }

  console.log('■ 管理者が作った内容が団員に反映される');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'member.a@example.com');
    await page.getByText('会場変更のお知らせ').waitFor();
    check('重要なお知らせがホームに出る', true);
    await page.getByRole('link', { name: '演奏会の詳細' }).click();
    const text = await page.locator('main').innerText();
    check('演奏会ページ：会場「未定」・曲目表示', text.includes('未定') && text.includes('交響曲第7番'));
    await page.screenshot({ path: `${SHOTS}/08-concert.png`, fullPage: true });
    await ctx.close();
  }

  check('画面上の JavaScript エラーなし', pageErrors.length === 0, pageErrors.join(' / '));
} catch (e) {
  failed++;
  console.log('  ✗ 例外: ' + e.message);
} finally {
  await browser.close();
  await server.close();
  await env.cleanup();
}

console.log(`\nブラウザ確認：成功 ${passed}件 ／ 失敗 ${failed}件`);
process.exit(failed ? 1 : 0);
