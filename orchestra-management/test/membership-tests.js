/*
 * 正式加入確認（Membership.gs）のテスト
 *   cd orchestra-management && TZ=Asia/Tokyo node test/membership-tests.js
 *
 * メールは送らず（偽の MailApp）、フォームも作りません（偽の FormApp）。
 * テストデータはすべて架空です（@example.com）。
 */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { createGasEnvironment } = require('./gas-mock');

const ROOT = path.join(__dirname, '..');
const OWNER = 'representative@example.com'; // 代表（送信元・送信対象外）
let passed = 0;
let failed = 0;

function section(name) { console.log('\n■ ' + name); }
function check(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) { passed++; console.log('  ✓ ' + label); }
  else { failed++; console.log('  ✗ ' + label + '\n      期待: ' + e + '\n      実際: ' + a); }
}

const HEADERS = ['No.', '回答日時', '氏名', 'ニックネーム', '年代・学年', '地域', '楽器', '希望パート', '経験年数', 'オーケストラ経験', '現在の所属', '参加理由', '参加可能性', '第1回演奏会', 'やりたいこと', 'メールアドレス', '対応状況', '最終連絡日', '次の対応', '備考', '同期メモ'];
const FORM_HEADERS = ['タイムスタンプ', 'メールアドレス', 'お名前・呼ばれたい名前', '本名について', '学年・年代', '活動地域', '楽器', '希望パート', '楽器の経験年数', 'オーケストラでの演奏経験', '現在所属している音楽団体', 'このオーケストラに参加したいと思った理由', 'どのくらい練習に参加できそうですか？', '第1回演奏会への参加について', 'このオーケストラでやってみたいこと', 'その他、伝えておきたいこと'];
const CONTACT_HEADERS = ['日付', '応募者No.', '氏名', '連絡方法', '内容', '相手からの返信', '次回対応日', '担当', '備考', '次回対応内容', '対応状況'];

function person(no, name, inst, status, email) {
  return { no, ts: new Date(2026, 9, 4, 8 + no, 0, 0), name, inst, status, email: email === undefined ? 'p' + no + '@example.com' : email };
}

// 既存応募者・保留者・辞退者・代表本人・メールなし・同じアドレスの重複行
const PEOPLE = [
  person(1, 'まぐ', 'Tp', '未対応'),
  person(2, 'ろく', 'Tuba', '参加予定'),
  person(3, 'ひぐち', 'Fl', '保留'),
  person(4, 'じゅん', 'Tuba', '辞退'),
  person(5, 'だいひょう', 'Vn', '未対応', OWNER),
  person(6, 'めーるなし', 'Ob', '未対応', ''),
  person(7, 'ちか', 'Fl', '初回連絡済み', 'P7@Example.com'),
  person(8, 'ちか（2回目）', 'Fl', '未対応', 'p7@example.com'),
  person(9, 'おおかわ', 'Va', '返信待ち')
];

function row(p) {
  return [p.no, p.ts, p.name, '', '社会人', '横浜市', p.inst, '', '', '', '', '', '', 'ぜひ参加したい', '', p.email, p.status, '', '初回連絡', '', ''];
}

function load(env) {
  const ctx = vm.createContext(Object.assign({}, env.globals));
  ['Code.gs', 'AppSync.gs', 'AppNotify.gs', 'Membership.gs', 'Tests.gs'].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), 'utf8'), ctx, { filename: f }));
  return ctx;
}

function makeEnv(user) {
  const env = createGasEnvironment({ effectiveUser: user || OWNER, activeUser: user || OWNER });
  const ss = env.spreadsheet;
  const app = ss.insertSheet('応募者一覧');
  app._setTable([HEADERS].concat(PEOPLE.map(row)));
  const form = ss.insertSheet('フォームの回答 1');
  form.formUrl = 'https://docs.google.com/forms/d/applicant/viewform';
  form._setTable([FORM_HEADERS].concat(PEOPLE.map(p => [p.ts, p.email, p.name, '', '社会人', '横浜市', p.inst, '', '', '', '', '', '', 'ぜひ参加したい', '', ''])));
  const contacts = ss.insertSheet('連絡記録');
  contacts._setTable([CONTACT_HEADERS]);
  const ctx = load(env);
  ctx.syncExistingResponses();
  env.alerts.length = 0;
  return { env, ss, app, ctx, contacts };
}

const header = sheet => sheet._rows()[0];
const col = (sheet, name) => { const i = header(sheet).indexOf(name); return sheet._rows().slice(1).map(r => r[i]); };
const byNo = (sheet, no, name) => { const rows = sheet._rows(); const r = rows.find((x, i) => i > 0 && x[0] === no); return r ? r[rows[0].indexOf(name)] : undefined; };
function setCell(sheet, no, name, value) {
  const rows = sheet._rows();
  const r = rows.findIndex((x, i) => i > 0 && x[0] === no) + 1;
  sheet.getRange(r, rows[0].indexOf(name) + 1).setValue(value);
}
function setSetting(ss, label, value) {
  const sh = ss.getSheetByName('加入確認設定');
  const r = sh._rows().findIndex(x => x[0] === label) + 1;
  sh.getRange(r, 2).setValue(value);
}
const lastAlert = env => (env.alerts.length ? env.alerts[env.alerts.length - 1].message : '');
const answer = (ts, email, name, inst, intent, concert, other) => [ts, email, name, inst, intent, concert || '', other || ''];

/* ============================================================ */
section('A. 正式加入確認フォームの作成');
const main = makeEnv();
{
  const { env, ss, app, ctx } = main;
  const before = app._rows().length;
  ctx.membershipCreateForm();
  const f = env.forms.created[0];
  check('フォームを1つ作成', env.forms.created.length, 1);
  check('質問', f.items.map(i => i.title), ['お名前（呼ばれたい名前）', '楽器', '正式加入について', '第1回演奏会への参加について', 'その他']);
  check('正式加入についての選択肢', f.items[2].choices, ['正式加入を希望する', 'もう少し活動内容を確認してから決めたい', '今回は参加を見送る']);
  check('メールアドレスは「回答者が入力」で集める（Google アカウント不要）', f.collect, 'RESPONDER_INPUT');
  check('回答先はこのスプレッドシート', f.destination, ss.getId());
  check('回答シートの名前を「正式加入確認（回答）」に', !!ss.getSheetByName('正式加入確認（回答）'), true);
  check('フォームURLを設定シートに保存', ctx.membershipSettings_(ss).formUrl, 'https://docs.google.com/forms/d/e/form1/viewform');
  ctx.membershipCreateForm();
  check('2回目は作らない（既存のURLを表示）', [env.forms.created.length, /作成済み/.test(lastAlert(env))], [1, true]);
  check('既存の参加希望フォームの回答シートはそのまま', !!ss.getSheetByName('フォームの回答 1'), true);
  check('応募者一覧の行数は変わらない', app._rows().length, before);
}

/* ============================================================ */
section('B. 設定の初期値');
{
  const s = main.ctx.membershipSettings_(main.ss);
  check('送信元の初期値は、設定を最初に開いた代表のアカウント', s.senderEmail, OWNER);
  check('代表のアドレスは送信対象外', s.excludeEmails, [OWNER]);
  check('辞退は送信対象外', s.excludeStatuses, ['辞退']);
  check('本文にフォームURL・名前の差し込み', /\{フォームURL\}/.test(s.body) && /\{名前\}/.test(s.body), true);
  check('本文に3つの選択肢と、アプリの案内', ['正式加入を希望する', 'もう少し活動内容を確認してから決めたい', '今回は参加を見送る', '団員向けアプリ'].every(t => s.body.indexOf(t) >= 0), true);
}

/* ============================================================ */
section('C. 送信元アカウントの確認・テスト送信');
{
  const other = makeEnv('other.staff@example.com');
  other.ctx.membershipCreateForm();
  setSetting(other.ss, '送信元アカウント', OWNER);   // 設定は代表、実行しているのは別のアカウント
  other.env.alerts.length = 0;
  other.ctx.membershipSendEmails();
  check('別のアカウントで実行したら送らない', [other.env.mail.sent.length, /別のアカウント/.test(lastAlert(other.env))], [0, true]);
  const noForm = makeEnv();
  noForm.ctx.membershipSendEmails();
  check('フォームURLが無いと送らない', [noForm.env.mail.sent.length, /フォーム/.test(lastAlert(noForm.env))], [0, true]);

  const { env, ctx, contacts } = main;
  ctx.membershipSendTest();
  const m = env.mail.sent[0];
  check('テスト送信は送信元アカウント宛て', m.to, OWNER);
  check('件名・本文・差出人名', [/正式加入/.test(m.subject), m.body.indexOf('https://docs.google.com/forms/d/e/form1/viewform') >= 0, m.name], [true, true, 'かながわコネクトオーケストラ 運営']);
  check('テスト送信は履歴・連絡記録に残さない', [ctx.membershipLedgerRows_(main.ss).length, contacts._rows().length], [0, 1]);
  env.mail.sent.length = 0;
}

/* ============================================================ */
section('D. 正式加入確認メールの一斉送信（1人ずつ）');
{
  const { env, ss, app, ctx, contacts } = main;
  const statusBefore = JSON.stringify(col(app, '対応状況'));
  env.alerts.length = 0;
  const r = ctx.membershipSendEmails();
  const confirmText = env.alerts.find(a => a.confirm).message;
  const to = env.mail.sent.map(x => x.to).sort();
  check('確認画面が出る', !!confirmText, true);
  check('確認画面にメールアドレスを出さない', /@/.test(confirmText.replace(OWNER, '')), false);
  check('送信先：辞退・代表・メールなしを除き、重複行は1通', to, ['p1@example.com', 'p2@example.com', 'p3@example.com', 'p7@example.com', 'p9@example.com']);
  check('保留の人には送る', to.indexOf('p3@example.com') >= 0, true);
  check('1通に宛先は1人だけ（CC・BCC なし）', env.mail.sent.every(x => typeof x.to === 'string' && x.to.indexOf(',') < 0 && !x.cc && !x.bcc), true);
  check('本文にほかの人のアドレスを含めない', env.mail.sent.every(x => (x.body.match(/[\w.+-]+@[\w.-]+/g) || []).length === 0), true);
  check('本文に本人の名前', env.mail.sent.find(x => x.to === 'p3@example.com').body.indexOf('ひぐち さん') === 0, true);
  check('対応状況は変えない', JSON.stringify(col(app, '対応状況')), statusBefore);
  check('応募者一覧に送信日時（重複行も）', [1, 2, 3, 7, 8, 9].every(no => byNo(app, no, '加入確認メール') instanceof Date) && !byNo(app, 4, '加入確認メール') && !byNo(app, 5, '加入確認メール'), true);
  check('最終連絡日を今日に', byNo(app, 1, '最終連絡日') instanceof Date, true);
  const log = contacts._rows().slice(1);
  check('連絡記録に1人1行（5行）', log.length, 5);
  check('連絡記録の内容', [log[0][3], /正式加入確認メールを送信/.test(log[0][4]), log[0][9]], ['メール', true, '正式加入確認フォームの回答待ち']);
  const ledger = ss.getSheetByName('_送信履歴');
  check('送信履歴は非表示シート・メールアドレスを保存しない', [ledger.hidden, JSON.stringify(ledger._rows()).indexOf('@') < 0], [true, true]);
  check('結果', [r.sent, r.failed], [5, 0]);

  env.mail.sent.length = 0;
  env.alerts.length = 0;
  ctx.membershipSendEmails();
  check('同じ送信回でもう一度実行しても送らない（重複送信防止）', [env.mail.sent.length, /送信する相手はいません/.test(lastAlert(env))], [0, true]);
  check('連絡記録も増えない', contacts._rows().length - 1, 5);

  // 新しく応募があった人には、同じ送信回で追加で送れる
  app.appendRow([10, new Date(2026, 9, 6), 'あたらしい', '', '', '', 'Hr', '', '', '', '', '', '', '', '', 'p10@example.com', '未対応', '', '', '', '']);
  ctx.membershipSendEmails();
  check('あとから応募した人だけに送る', env.mail.sent.map(x => x.to), ['p10@example.com']);
}

/* ============================================================ */
section('E. 送信の上限・失敗・送信回');
{
  const e = makeEnv();
  e.ctx.membershipCreateForm();
  setSetting(e.ss, '1回に送る上限（通）', 2);
  e.ctx.membershipSendEmails();
  check('1回の上限で止める（2通）', e.env.mail.sent.length, 2);
  check('「残りは次回」と案内', /まだ送っていない人が 3人/.test(lastAlert(e.env)), true);
  e.ctx.membershipSendEmails();
  e.ctx.membershipSendEmails();
  check('続きから送り、全員に1通ずつ', e.env.mail.sent.map(x => x.to).sort(), ['p1@example.com', 'p2@example.com', 'p3@example.com', 'p7@example.com', 'p9@example.com']);

  setSetting(e.ss, '1回に送る上限（通）', 50);
  setSetting(e.ss, '送信回の名前', '第1回 正式加入確認（再送）');
  e.env.mail.sent.length = 0;
  e.env.mail.failFor.add('p2@example.com');
  e.ctx.membershipSendEmails();
  check('送信回を変えると再送できる。1人失敗しても続ける', e.env.mail.sent.length, 4);
  check('失敗した人は報告し、履歴に残さない（次回また送れる）', /送信できなかった：1件（No.2）/.test(lastAlert(e.env)), true);
  e.env.mail.failFor.clear();
  e.env.mail.sent.length = 0;
  e.ctx.membershipSendEmails();
  check('失敗した人にだけ送り直す', e.env.mail.sent.map(x => x.to), ['p2@example.com']);

  const q = makeEnv();
  q.ctx.membershipCreateForm();
  q.env.mail.quota = 1;
  q.ctx.membershipSendEmails();
  check('Gmail の残り送信数を超えない', q.env.mail.sent.length, 1);
}

/* ============================================================ */
section('F. 正式加入回答の同期（照合）');
{
  const { env, ss, app, ctx, contacts } = main;
  const sheet = ss.getSheetByName('正式加入確認（回答）');
  const h = sheet._rows()[0];
  sheet._setTable([h,
    answer(new Date(2026, 9, 8, 10), 'p1@example.com', 'まぐ', 'トランペット', '正式加入を希望する', 'ぜひ参加したい'),          // 既存応募者・希望
    answer(new Date(2026, 9, 8, 11), 'P3@EXAMPLE.COM ', 'ひぐち', 'フルート', 'もう少し活動内容を確認してから決めたい', '検討中'), // 保留者・大文字
    answer(new Date(2026, 9, 8, 12), 'p4@example.com', 'じゅん', 'チューバ', '今回は参加を見送る', '参加しない'),              // 辞退者
    answer(new Date(2026, 9, 8, 13), 'stranger@example.com', 'しらないひと', 'ホルン', '正式加入を希望する'),                // メール不一致
    answer(new Date(2026, 9, 8, 14), 'p9@example.com', 'おおかわ', 'ヴィオラ', 'もう少し活動内容を確認してから決めたい'),      // 重複回答（1回目）
    answer(new Date(2026, 9, 9, 9), 'p9@example.com', 'おおかわ', 'チェロ', '正式加入を希望する', '', "'=HYPERLINK(\"x\")"),     // 重複回答（2回目・楽器違い）
    answer(new Date(2026, 9, 8, 15), 'p7@example.com', 'ちか', 'フルート', '正式加入を希望する')                             // 重複行のある応募者
  ]);
  const before = app._rows().length;
  const statusBefore = JSON.stringify(col(app, '対応状況'));
  env.alerts.length = 0;
  const r = ctx.membershipSyncResponses();

  check('応募者一覧に行を追加しない（新規回答者を勝手に登録しない）', app._rows().length, before);
  check('対応状況は自動で変えない', JSON.stringify(col(app, '対応状況')), statusBefore);
  check('既存応募者：正式加入の意思「希望」', byNo(app, 1, '正式加入の意思'), '希望');
  check('保留者：大文字・空白のアドレスでも照合し「検討中」', byNo(app, 3, '正式加入の意思'), '検討中');
  check('辞退者：「見送り」', byNo(app, 4, '正式加入の意思'), '見送り');
  check('重複回答：最新の回答（希望）を使う', byNo(app, 9, '正式加入の意思'), '希望');
  check('重複行のある応募者は No. の小さい行に記録', [byNo(app, 7, '正式加入の意思'), byNo(app, 8, '正式加入の意思') || ''], ['希望', '']);
  check('回答日時を記録', byNo(app, 9, '加入確認 回答日時') instanceof Date, true);
  check('件数', [r.responses, r.people, r.matched, r.unmatched], [7, 6, 5, 1]);

  const review = ss.getSheetByName('加入回答の照合')._rows();
  const rowOf = name => review.find(x => x[2] === name);
  check('照合シート：メール不一致の人は「要確認」・No.なし', [rowOf('しらないひと')[1], /同じメールアドレスがありません/.test(rowOf('しらないひと')[10])], ['', true]);
  check('照合シート：重複回答・回答の変化・楽器違いを表示', ['回答が 2件', '回答の内容が変わっています', '楽器が応募時と違います'].every(t => rowOf('おおかわ')[10].indexOf(t) >= 0), true);
  check('照合シート：希望者には「正式参加に変更」を案内', /「正式参加」に変更/.test(rowOf('まぐ')[11]), true);
  check('照合シート：辞退者の見送りは対応不要', /辞退済み/.test(rowOf('じゅん')[11]), true);
  check('照合シート：保留者（検討中）には活動内容の案内', /活動内容の案内/.test(rowOf('ひぐち')[11]), true);
  check('照合シート：要確認の人が先頭', review[3][2], 'しらないひと');
  check('照合シートにメールアドレスをそのまま出さない', JSON.stringify(review).indexOf('stranger@example.com') < 0 && JSON.stringify(review).indexOf('st***@example.com') >= 0, true);
  check('数式のような回答は文字列として保存（実行されない）', rowOf('おおかわ')[12], '=HYPERLINK("x")');

  const log = contacts._rows().slice(1).filter(x => /フォームに回答/.test(x[4]));
  check('連絡記録：一致した人の回答を記録（不一致の人は記録しない）', log.length, 6);
  check('連絡記録：要対応', log.every(x => x[10] === '要対応'), true);
  ctx.membershipSyncResponses();
  check('もう一度同期しても連絡記録・行は増えない', [contacts._rows().slice(1).filter(x => /フォームに回答/.test(x[4])).length, app._rows().length], [6, before]);
  check('結果メッセージにメールアドレスを出さない', /@/.test(lastAlert(env)), false);

  const list = ss.getSheetByName('正式参加者一覧')._rows();
  const pendingStart = list.findIndex(x => /正式加入を希望・まだ確定していない人/.test(x[0]));
  check('正式参加者一覧：希望・未確定の人（No.1・7・9）', list.slice(pendingStart + 2).map(x => x[0]).filter(Boolean), [1, 7, 9]);
  check('正式参加者一覧にメールアドレスを出さない', JSON.stringify(list).indexOf('@') < 0, true);
}

/* ============================================================ */
section('G. 正式加入確認フォームの回答を応募者として取り込まない');
{
  const { ss, app, ctx } = main;
  const before = app._rows().length;
  const unlinked = ss.insertSheet('フォームの回答 3');
  unlinked._setTable([['タイムスタンプ', 'メールアドレス', 'お名前', '楽器', '正式加入について', '第1回演奏会への参加について', 'その他'],
    [new Date(2026, 9, 9), 'new@example.com', 'あたらしいひと', 'フルート', '正式加入を希望する', 'ぜひ参加したい', '']]);
  ctx.syncExistingResponses();
  ctx.syncWithoutDialog();
  check('既存の同期（②・フォーム送信時）を実行しても応募者は増えない', app._rows().length, before);
  ctx.runSystemDiagnosis();
  const diag = JSON.stringify(ss.getSheetByName('システム診断')._rows());
  check('システム診断で「正式加入確認フォームの回答シートのため対象外」と表示', diag.indexOf('正式加入確認フォームの回答シートのため対象外') >= 0, true);
}

/* ============================================================ */
section('H. 正式参加の確定 → アプリ利用 → 団員アプリへの同期');
{
  const { env, ss, app, ctx } = main;
  ctx.membershipUpdateAppUsage();
  check('正式参加でない人は「対象外」', byNo(app, 1, 'アプリ利用'), '対象外');

  // 管理者が確認して正式参加に変更
  setCell(app, 1, '対応状況', '正式参加');
  setCell(app, 9, '対応状況', '正式参加');
  ctx.membershipUpdateAppUsage();
  check('正式参加にしただけでは「未発行」（アプリIDなし）', [byNo(app, 1, 'アプリ利用'), byNo(app, 9, 'アプリ利用')], ['未発行', '未発行']);
  check('アプリ利用の列はプルダウン（停止を選べる）', app.validationRanges.filter(v => v.col === header(app).indexOf('アプリ利用') + 1).pop().rule.values, ['対象外', '未発行', '招待準備', '招待済', '利用中', '停止']);

  ctx.appSyncRun();
  const access = Object.keys(Object.fromEntries([...env.firestore.docs.keys()].filter(k => k.startsWith('memberAccess/')).map(k => [k.slice(13), 1]))).sort();
  check('団員アプリに登録されるのは正式参加の2人＋管理者', access, ['p1@example.com', 'p9@example.com', OWNER].sort());
  check('同期後：Firebase連携状態「同期済み」・アプリ利用「招待済」', [byNo(app, 1, 'Firebase連携状態'), byNo(app, 1, 'アプリ利用')], ['同期済み', '招待済']);
  const member = [...env.firestore.docs.entries()].find(([k]) => k.startsWith('members/'))[1];
  check('団員アプリに送るのは表示名・楽器・パートなど（加入意思・年代・地域は送らない）', Object.keys(member).filter(k => /intent|answer|mail|age|area|region|grade|school/i.test(k)), []);

  // 停止
  setCell(app, 9, 'アプリ利用', '停止');
  env.alerts.length = 0;
  ctx.appSyncRun();
  const a9 = env.firestore.docs.get('memberAccess/p9@example.com');
  check('「停止」の人は正式参加のままでもアプリを利用停止に', a9.status.stringValue, 'inactive');
  check('停止：Firebase連携状態「停止済み」・アプリ利用は「停止」のまま', [byNo(app, 9, 'Firebase連携状態'), byNo(app, 9, 'アプリ利用'), byNo(app, 9, '対応状況')], ['停止済み', '停止', '正式参加']);
  check('同期結果に「停止」の人数', env.alerts.some(x => /停止」のため登録しない人：1人/.test(x.message)), true);

  ctx.updateDashboard();
  const dash = ss.getSheetByName('ダッシュボード')._rows();
  const get = label => { const i = dash.findIndex(x => x[0] === '【正式加入・団員アプリ】'); return dash.slice(i).find(x => x[0] === label)[1]; };
  check('ダッシュボード：参加希望者・正式参加・保留・辞退', [get('参加希望者数（実人数）'), get('正式参加'), get('保留'), get('辞退')], [9, 2, 1, 1]);
  check('ダッシュボード：アプリ利用対象者（停止を除く）', get('アプリ利用対象者'), 1);
  check('ダッシュボード：加入の意思', [get('加入の意思：希望'), get('加入の意思：検討中'), get('加入の意思：見送り')], [3, 1, 1]);
  const i = dash.findIndex(x => x[0] === '【楽器別 正式参加者数】');
  const parts = dash.slice(i + 2).filter(x => x[0] && x[1] > 0).map(x => x[0] + ':' + x[1]);
  check('ダッシュボード：楽器別の正式参加者数', parts.slice(0, 2), ['Tp（トランペット）:1', 'Va（ヴィオラ）:1']);
}

/* ============================================================ */
section('I. フォーム送信時に自動で照合');
{
  const e = makeEnv();
  e.ctx.membershipCreateForm();
  const sheet = e.ss.getSheetByName('正式加入確認（回答）');
  sheet.appendRow(answer(new Date(2026, 9, 10), 'p2@example.com', 'ろく', 'テューバ', '正式加入を希望する'));
  e.ctx.handleSpreadsheetFormSubmit({});
  check('フォーム送信トリガーで照合され、意思が記録される', byNo(e.app, 2, '正式加入の意思'), '希望');
  check('トリガーを増やさない', e.env.triggers.length, 0);
}

/* ============================================================ */
section('J. 既存機能への影響なし・個人情報');
{
  const { env, ss, ctx } = main;
  ctx.runIntegrityCheck();
  const rows = ss.getSheetByName('データチェック')._rows();
  check('整合性チェックでエラーなし', rows.filter(r => r[0] === 'エラー').map(r => r[1]), []);
  check('Tests.gs のセルフテストは全件成功', ctx.runAllTests_().failed, 0);
  ctx.onOpen();
  const menu = env.menus[env.menus.length - 1];
  check('既存メニュー（①〜⑩）はそのまま', menu.items.filter(i => i.fn).map(i => i.label).slice(0, 10).map(n => n.slice(0, 1)), ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩']);
  const sub = menu.items.find(i => i.submenu && i.submenu.name === '✉️ 正式加入確認');
  check('「✉️ 正式加入確認」メニュー', sub.submenu.items.filter(i => i.fn).map(i => i.label), ['正式加入確認フォームを作成', 'テスト送信（自分宛て）', '正式加入確認メールを送信', '正式加入回答を同期', '正式参加者一覧を更新', 'アプリ利用対象者を更新', '同期状況を確認', '加入確認設定を開く']);
  ctx.membershipStatus();
  check('同期状況の表示にメールアドレスを出さない（送信元の表示を除く）', /@/.test(lastAlert(env)), false);
  check('ログにメールアドレスを出さない', env.logs.some(l => /@example\.com/.test(l)), false);
}

console.log('\n============================');
console.log('正式加入確認テスト：成功 ' + passed + '件 ／ 失敗 ' + failed + '件');
process.exit(failed ? 1 : 0);
