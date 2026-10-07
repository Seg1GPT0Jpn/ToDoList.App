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
  await setDoc(doc(db, 'memberAccess', 'member.a@example.com'), { email: 'member.a@example.com', status: 'active', role: 'member', memberId: 'm-a', part: 'Va', source: 'sheet' });
  await setDoc(doc(db, 'memberAccess', 'member.b@example.com'), { email: 'member.b@example.com', status: 'active', role: 'member', memberId: 'm-b', part: 'Vc', source: 'sheet' });
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

    await page.getByRole('link', { name: 'みんなで' }).click();
    await page.getByRole('link', { name: /団員一覧/ }).click();
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


  console.log('■ 管理者：アンケート・楽譜・募集キャンペーン・通知');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'admin@example.com');
    await page.getByRole('link', { name: '運営' }).click();

    // アンケート
    await page.getByRole('link', { name: 'アンケート' }).click();
    await page.getByRole('link', { name: '＋ アンケートを作成' }).click();
    await page.getByLabel('タイトル').fill('練習日の希望');
    await page.getByLabel('質問文').fill('参加しやすい曜日');
    await page.getByLabel('選択肢 1', { exact: true }).fill('土曜');
    await page.getByLabel('選択肢 2', { exact: true }).fill('日曜');
    await page.getByLabel('団員に公開する').check();
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByText('集計').first().waitFor();
    check('アンケートを作成・公開できた', true);
    await page.screenshot({ path: `${SHOTS}/09-admin-survey.png`, fullPage: true });

    // 楽譜（リンクで登録：ヴィオラだけ）
    await page.getByRole('link', { name: '楽譜' }).click();
    await page.getByRole('button', { name: '＋ 楽譜を登録' }).click();
    await page.getByLabel('曲名・タイトル').fill('ヴィオラ譜 第1楽章');
    await page.getByLabel('全員（スコア・全体の資料など）').uncheck();
    await page.getByLabel('ヴィオラ').check();
    await page.getByLabel('リンク（Google ドライブなど）').check();
    await page.getByLabel('リンク', { exact: true }).fill('https://example.com/viola.pdf');
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByText('ヴィオラ譜 第1楽章').waitFor();
    check('楽譜を登録できた（ヴィオラ向け）', true);

    // 募集キャンペーン
    await page.getByRole('link', { name: '募集' }).click();
    await page.getByLabel('募集中にする（オフにすると募集ページは「現在募集していません」と表示）').check();
    await page.getByLabel('応募フォームの URL（任意）').fill('https://forms.gle/example');
    await page.getByLabel('ハッシュタグ（任意・空白区切り）').fill('#オーケストラ #団員募集');
    await page.getByRole('button', { name: '人数から自動で選ぶ' }).click();
    await page.getByRole('button', { name: '保存する' }).click();
    await page.getByText('保存しました。募集ページとカードに反映されています。').waitFor();
    const camp = await readAsOwner('publicCampaign/current');
    check('募集パートを人数から自動で選ぶ（Fl・Va・Vc が目標未満、Tuba は充足）',
      JSON.stringify(camp?.parts?.map(p => p.part).sort()) === JSON.stringify(['Fl', 'Va', 'Vc']), JSON.stringify(camp?.parts));
    check('募集ページの内容に個人情報を含めない', !JSON.stringify(camp).includes('@'));
    await page.screenshot({ path: `${SHOTS}/10-admin-campaign.png`, fullPage: true });

    // 通知の予約
    await page.getByRole('link', { name: '通知' }).click();
    await page.getByLabel('タイトル（60文字まで）').fill('明日の練習について');
    page.once('dialog', d => d.accept());
    await page.getByRole('button', { name: '送信を予約する' }).click();
    await page.getByText('送信を予約しました。数分以内に届きます。').waitFor();
    await page.getByText('送信待ち').first().waitFor();
    check('通知を予約できた（送信待ち）', true);
    check('管理者には通知の設定（公開鍵）欄が出る', await page.getByLabel('ウェブプッシュ証明書（鍵ペア）').isVisible());
    await ctx.close();
  }

  console.log('■ 団員：アンケート回答・提案・楽譜・募集のシェア');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'member.a@example.com');
    await page.getByText('現在の団員数').waitFor();
    check('ホームに「団員募集をシェアする」', await appears(page.getByRole('link', { name: '📣 団員募集をシェアする' })));

    await page.getByRole('link', { name: 'みんなで' }).click();
    await page.getByRole('link', { name: /練習日の希望/ }).click();
    await page.getByLabel('日曜').check();
    await page.getByRole('button', { name: '回答する' }).click();
    await page.getByText('回答を送信しました。ありがとうございます！').waitFor();
    const ans = await readAsOwner('surveys/' + page.url().split('/').pop() + '/responses/m-a');
    check('アンケートの回答が保存された（日曜＝2番目）', ans?.answers?.q1 === 1, JSON.stringify(ans));

    await page.goto(BASE + '/proposals');
    await page.getByRole('button', { name: '＋ 提案する' }).click();
    await page.getByLabel('タイトル（80文字まで）').fill('本番前に合宿をしたい');
    await page.getByRole('button', { name: '送信する' }).click();
    await page.getByText('本番前に合宿をしたい').waitFor();
    check('提案を投稿できた（表示名つき）', await appears(page.getByText('えーさん さん（あなた）')));
    check('自分の提案には賛成できない', await page.getByRole('button', { name: /賛成/ }).isDisabled());
    await page.screenshot({ path: `${SHOTS}/11-proposals.png`, fullPage: true });

    await page.goto(BASE + '/scores');
    check('自分のパート（ヴィオラ）の楽譜が見える', await appears(page.getByText('ヴィオラ譜 第1楽章')));

    await page.goto(BASE + '/campaign');
    const img = page.locator('.card-preview img');
    await img.waitFor({ timeout: 15000 });
    const size = await img.evaluate(el => [el.naturalWidth, el.naturalHeight]);
    check('募集カード（投稿用 1080×1350）を作成', size[0] === 1080 && size[1] === 1350, size.join('x'));
    check('LINE で送るボタン', (await page.getByRole('link', { name: 'LINE で送る（文章とリンク）' }).getAttribute('href')).startsWith('https://line.me/R/share?text='));
    const png = await img.evaluate(async el => {
      const b = await fetch(el.src).then(r => r.blob());
      return [b.type, b.size];
    });
    check('画像は PNG', png[0] === 'image/png' && png[1] > 10000, png.join(' '));
    await page.screenshot({ path: `${SHOTS}/12-campaign-share.png`, fullPage: true });
    // 画像そのものも保存して見た目を確認できるようにする
    const dataUrl = await img.evaluate(async el => {
      const b = await fetch(el.src).then(r => r.blob());
      return await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(fr.result); fr.readAsDataURL(b); });
    });
    const { writeFileSync } = await import('node:fs');
    writeFileSync(`${SHOTS}/13-card-post.png`, Buffer.from(String(dataUrl).split(',')[1], 'base64'));
    await page.getByRole('button', { name: 'ストーリーズ用（9:16）' }).click();
    await page.waitForFunction(() => document.querySelector('.card-preview img')?.naturalHeight === 1920, null, { timeout: 15000 });
    const story = await img.evaluate(async el => {
      const b = await fetch(el.src).then(r => r.blob());
      return await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(fr.result); fr.readAsDataURL(b); });
    });
    writeFileSync(`${SHOTS}/14-card-story.png`, Buffer.from(String(story).split(',')[1], 'base64'));
    check('ストーリーズ用（1080×1920）に切り替え', true);

    await page.getByRole('link', { name: 'マイページ' }).click();
    check('通知：公開鍵が未設定なら「準備中」と表示', await appears(page.getByText('通知機能は準備中です。')));
    await ctx.close();
  }

  console.log('■ 別のパートの団員（チェロ）');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'member.b@example.com');
    await page.getByText('現在の団員数').waitFor();
    await page.goto(BASE + '/scores');
    await page.getByText('配布中の楽譜はまだありません。').waitFor();
    check('他パート（ヴィオラ）の楽譜は見えない', !(await page.getByText('ヴィオラ譜 第1楽章').isVisible()));
    await page.goto(BASE + '/proposals');
    await page.getByText('本番前に合宿をしたい').waitFor();
    await page.getByRole('button', { name: /賛成 0/ }).click();
    await page.getByRole('button', { name: /賛成 1/ }).waitFor();
    check('他の団員の提案に賛成できる（1）', true);
    await page.getByRole('button', { name: /賛成 1/ }).click();
    await page.getByRole('button', { name: /賛成 0/ }).waitFor();
    check('賛成を取り消せる（0）', true);
    await ctx.close();
  }

  console.log('■ 一般公開の募集ページ（ログインなし）');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await page.goto(BASE + '/join');
    await page.getByRole('link', { name: '応募フォームを開く' }).waitFor();
    const text = await page.locator('body').innerText();
    check('募集ページはログインなしで見られる', text.includes('募集中のパート') || text.includes('急募のパート'));
    check('応募フォームへのボタン', (await page.getByRole('link', { name: '応募フォームを開く' }).getAttribute('href')) === 'https://forms.gle/example');
    check('募集ページに団員の名前・メールは出ない', !/えーさん|びー|@example\.com/.test(text));
    await page.screenshot({ path: `${SHOTS}/15-join.png`, fullPage: true });
    await ctx.close();
  }

  console.log('■ 管理者：アンケート集計');
  {
    const { ctx, page } = await newPhone();
    page.on('pageerror', e => pageErrors.push(e.message));
    await emailLinkLogin(page, 'admin@example.com');
    await page.getByRole('link', { name: '運営' }).click();
    await page.getByRole('link', { name: 'アンケート' }).click();
    await page.getByRole('link', { name: /練習日の希望/ }).click();
    await page.getByText('回答 1 人').waitFor();
    check('回答数 1人', true);
    await page.getByRole('button', { name: '集計結果を団員に公開' }).click();
    await page.getByText('いまの集計結果を団員に公開しました（自由記述は公開されません）。').waitFor();
    check('集計結果を団員に公開できた', true);
    await page.goto(BASE + '/proposals');
    await page.getByText('本番前に合宿をしたい').waitFor();
    await page.getByText('運営として対応する').click();
    await page.getByLabel('対応状況').selectOption('considering');
    await page.getByLabel('返信（提案を見られる人に表示されます）').fill('前向きに検討します');
    await page.getByRole('button', { name: '保存', exact: true }).click();
    await page.getByText('前向きに検討します').first().waitFor();
    check('運営が提案に返信できた', true);
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
