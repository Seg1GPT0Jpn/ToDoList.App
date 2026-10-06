/*
 * 団員アプリ同期（AppSync.gs）のテスト
 *   cd orchestra-management && TZ=Asia/Tokyo node test/appsync-tests.js
 *
 * 本物の Firebase には接続しません（gas-mock.js の「偽の Firestore」を使用）。
 * テストデータはすべて架空です（@example.com）。
 */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { createGasEnvironment } = require('./gas-mock');

const ROOT = path.join(__dirname, '..');
let passed = 0;
let failed = 0;

function section(name) { console.log('\n■ ' + name); }
function check(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) { passed++; console.log('  ✓ ' + label); }
  else { failed++; console.log('  ✗ ' + label + '\n      期待: ' + e + '\n      実際: ' + a); }
}

function load(env) {
  const ctx = vm.createContext(Object.assign({}, env.globals));
  ['Code.gs', 'AppSync.gs', 'Tests.gs'].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), 'utf8'), ctx, { filename: f }));
  return ctx;
}

// 本番と同じ見出しの応募者一覧
const HEADERS = ['No.', '回答日時', '氏名', 'ニックネーム', '年代・学年', '地域', '楽器', '希望パート', '経験年数', 'オーケストラ経験', '現在の所属', '参加理由', '参加可能性', '第1回演奏会', 'やりたいこと', 'メールアドレス', '対応状況', '最終連絡日', '次の対応', '備考', '同期メモ'];
const FORM_HEADERS = ['タイムスタンプ', 'メールアドレス', 'お名前・呼ばれたい名前', '本名について', '学年・年代', '活動地域', '楽器', '希望パート', '楽器の経験年数', 'オーケストラでの演奏経験', '現在所属している音楽団体', 'このオーケストラに参加したいと思った理由', 'どのくらい練習に参加できそうですか？', '第1回演奏会への参加について', 'このオーケストラでやってみたいこと', 'その他、伝えておきたいこと'];

function person(no, name, inst, status, email) {
  const ts = new Date(2026, 9, 4, 8 + no, 0, 0);
  return { no, ts, name, inst, status, email: email || ('p' + no + '@example.com') };
}

const PEOPLE = [
  person(1, 'まぐ', 'Tp', '正式参加'),
  person(2, 'ろく', 'Tuba', '正式参加'),
  person(3, 'ひぐち', 'Fl', '正式参加'),
  person(4, 'じゅん', 'Tuba', '未対応'),
  person(5, 'あかね', 'Cl', '未対応'),
  person(6, 'みちる', 'Fl', '初回連絡済み'),
  person(7, 'ちか', 'Fl', '未対応'),
  person(8, 'おおた', 'Fl', '辞退'),
  person(9, 'おおかわ', 'Ob', '未対応')
];

function row(p) {
  return [p.no, p.ts, p.name, '', '社会人', '横浜市', p.inst, '', '10年以上', 'ある', '', '理由', '日程によって変わる', 'ぜひ参加したい', '', p.email, p.status, '', '初回連絡', '', ''];
}

function makeEnv(people) {
  const env = createGasEnvironment({ effectiveUser: 'owner@example.com' });
  const ss = env.spreadsheet;
  const app = ss.insertSheet('応募者一覧');
  app._setTable([HEADERS].concat(people.map(row)));
  const form = ss.insertSheet('フォームの回答 1');
  form.formUrl = 'https://docs.google.com/forms/d/mock/viewform';
  form._setTable([FORM_HEADERS].concat(people.map(p => [p.ts, p.email, p.name, '', '社会人', '横浜市', p.inst, '', '', '', '', '', '', '', '', ''])));
  const ctx = load(env);
  return { env, ss, app, ctx };
}

function fsDocs(env, prefix) {
  const out = {};
  env.firestore.docs.forEach((fields, key) => {
    if (!key.startsWith(prefix + '/')) return;
    const plain = {};
    Object.keys(fields).forEach(k => {
      const v = fields[k];
      plain[k] = 'stringValue' in v ? v.stringValue : 'booleanValue' in v ? v.booleanValue : 'integerValue' in v ? Number(v.integerValue) : 'nullValue' in v ? null : 'timestampValue' in v ? 'TS' : v;
    });
    out[key.slice(prefix.length + 1)] = plain;
  });
  return out;
}

function header(sheet) { return sheet._rows()[0]; }
function col(sheet, name) { const h = header(sheet); const i = h.indexOf(name); return sheet._rows().slice(1).map(r => r[i]); }
function setStatus(sheet, no, status) {
  const rows = sheet._rows();
  const r = rows.findIndex((x, i) => i > 0 && x[0] === no) + 1;
  sheet.getRange(r, rows[0].indexOf('対応状況') + 1).setValue(status);
}
function lastAlert(env) { const a = env.alerts[env.alerts.length - 1]; return a ? a.message : ''; }
function allAlerts(env) { return env.alerts.map(a => a.message).join('\n'); }

/* ============================================================ */
section('A. お試し（書き込みなし）');
{
  const { env, app, ctx } = makeEnv(PEOPLE);
  const before = JSON.stringify(app._rows());
  const r = ctx.appSyncPreview();
  check('お試しでは Firestore に書き込まない', env.firestore.docs.size, 0);
  check('お試しでは応募者一覧を変更しない（アプリID列も追加しない）', JSON.stringify(app._rows()), before);
  check('加入確定 3人', r.members, 3);
  check('ログイン許可：3人＋管理者1人 を新規作成する予定', r.accessCreate, 4);
  check('メッセージにメールアドレスを含めない', /@/.test(lastAlert(env)), false);
  check('「アプリ連携設定」シートが作られ、管理者に実行者が入る', env.spreadsheet.getSheetByName('アプリ連携設定')._rows().find(x => x[0] === '管理者のメールアドレス')[1], 'owner@example.com');
}

/* ============================================================ */
section('B. 同期の実行');
const main = makeEnv(PEOPLE);
{
  const { env, app, ctx } = main;
  env.alerts.length = 0;
  ctx.appSyncRun();
  check('確認ダイアログが出る', env.alerts.some(a => a.confirm), true);
  check('応募者一覧に「アプリID」「アプリ用メールアドレス」列が末尾に追加', header(app).slice(-2), ['アプリID', 'アプリ用メールアドレス']);
  const ids = col(app, 'アプリID');
  check('正式参加の3人だけにアプリIDが振られた', ids.filter(Boolean).length, 3);
  check('アプリIDの形式', ids.filter(Boolean).every(id => /^m[0-9a-f]{15}$/.test(id)), true);
  const access = fsDocs(env, 'memberAccess');
  check('ログイン許可は 3人＋管理者', Object.keys(access).sort(), ['owner@example.com', 'p1@example.com', 'p2@example.com', 'p3@example.com']);
  check('団員の権限は member・状態は active', [access['p1@example.com'].role, access['p1@example.com'].status], ['member', 'active']);
  check('管理者（実行者）は admin・団員IDなし', [access['owner@example.com'].role, access['owner@example.com'].memberId], ['admin', null]);
  check('参加希望者（未対応）はログイン許可なし', access['p4@example.com'], undefined);
  const members = fsDocs(env, 'members');
  const m1 = members[access['p1@example.com'].memberId];
  check('団員プロフィール 3件', Object.keys(members).length, 3);
  check('表示名＝氏名（呼ばれたい名前）', m1.displayName, 'まぐ');
  check('楽器コード・パート・セクション', [m1.instrument, m1.part, m1.section, m1.instrumentLabel], ['Tp', 'Tp', 'brass', 'トランペット']);
  check('団員プロフィールに個人情報（メール・地域・年代）を含めない', Object.keys(m1).filter(k => /mail|area|age|region|地域|年代/.test(k)), []);
  const stats = fsDocs(env, 'stats').summary;
  check('団員数 3 / 目標 80', [stats.memberCount, stats.targetMembers, stats.decisionMembers, stats.minimumMembers], [3, 80, 60, 46]);
  const byPart = env.firestore.docs.get('stats/summary').byPart.arrayValue.values.map(v => {
    const f = v.mapValue.fields;
    return f.part.stringValue + ':' + f.count.integerValue + '/' + (f.target.integerValue || '-');
  });
  check('パート別人数（目標つき・オーケストラ順）', byPart.slice(0, 9), ['Fl:1/4', 'Ob:0/2', 'Cl:0/5', 'Fg:0/2', 'Hr:0/6', 'Tp:1/4', 'Tb:0/4', 'Tuba:1/1', 'Perc:0/4']);
  const adminStats = fsDocs(env, 'adminStats').summary;
  check('運営用：参加希望者 9人・団員 3人', [adminStats.applicantCount, adminStats.memberCount], [9, 3]);
  const req = env.firestore.requests[0];
  check('秘密鍵なし：実行者の OAuth トークンで認証', req.headers.Authorization, 'Bearer mock-oauth-token');
  check('書き込み先は設定のプロジェクト', env.firestore.projectId, 'kanagawa-connect-official');
  check('ログにメールアドレスを出さない', env.logs.filter(l => /@example\.com/.test(l)), []);
}

/* ============================================================ */
section('C. 何度実行しても同じ（重複しない）');
{
  const { env, app, ctx } = main;
  const idsBefore = col(app, 'アプリID');
  const commitsBefore = env.firestore.commits;
  env.alerts.length = 0;
  ctx.appSyncRun();
  check('2回目は「変更なし」', /すでに最新/.test(lastAlert(env)), true);
  check('2回目は書き込みなし', env.firestore.commits, commitsBefore);
  check('アプリIDは変わらない', col(app, 'アプリID'), idsBefore);
  check('団員プロフィールは3件のまま', Object.keys(fsDocs(env, 'members')).length, 3);
}

/* ============================================================ */
section('D. 本人がアプリで変えた表示名・自己紹介は上書きしない');
{
  const { env, app, ctx } = main;
  const id = fsDocs(env, 'memberAccess')['p1@example.com'].memberId;
  const doc = env.firestore.docs.get('members/' + id);
  doc.displayName = { stringValue: 'まぐさん' };
  doc.bio = { stringValue: 'よろしくお願いします' };
  // スプレッドシート側で楽器を変更
  const rows = app._rows();
  const r = rows.findIndex((x, i) => i > 0 && x[0] === 1) + 1;
  app.getRange(r, rows[0].indexOf('楽器') + 1).setValue('Hr');
  ctx.appSyncRun();
  const m = fsDocs(env, 'members')[id];
  check('楽器の変更は反映', [m.instrument, m.part, m.section], ['Hr', 'Hr', 'brass']);
  check('表示名・自己紹介はアプリでの変更のまま', [m.displayName, m.bio], ['まぐさん', 'よろしくお願いします']);
}

/* ============================================================ */
section('E. 退団（正式参加 → 辞退）と復帰');
{
  const { env, app, ctx } = main;
  const id2 = fsDocs(env, 'memberAccess')['p2@example.com'].memberId;
  setStatus(app, 2, '辞退');
  env.alerts.length = 0;
  ctx.appSyncRun();
  check('ログイン許可は削除せず「利用停止」', fsDocs(env, 'memberAccess')['p2@example.com'].status, 'inactive');
  check('団員プロフィールも「利用停止」（削除しない）', fsDocs(env, 'members')[id2].status, 'inactive');
  check('団員数 2', fsDocs(env, 'stats').summary.memberCount, 2);
  setStatus(app, 2, '正式参加');
  ctx.appSyncRun();
  check('正式参加に戻すと同じ団員IDで復帰', [fsDocs(env, 'memberAccess')['p2@example.com'].status, fsDocs(env, 'memberAccess')['p2@example.com'].memberId], ['active', id2]);
  check('新しいアプリIDは振られない', col(app, 'アプリID').filter(Boolean).length, 3);
}

/* ============================================================ */
section('F. 大量の利用停止を防ぐ');
{
  const { env, app, ctx } = main;
  [1, 2, 3].forEach(no => setStatus(app, no, '未対応'));
  const sheet = env.spreadsheet.getSheetByName('アプリ連携設定');
  const r = sheet._rows().findIndex(x => x[0] === '自動同期（15分ごと）') + 1;
  sheet.getRange(r, 2).setValue('はい');
  let err = null;
  try { ctx.appSyncScheduled(); } catch (e) { err = e.message; }
  check('自動同期では反映しない（エラーで止まる）', /一度に 3人 が利用停止/.test(err || ''), true);
  check('団員は在籍のまま', fsDocs(env, 'memberAccess')['p1@example.com'].status, 'active');
  env.alerts.length = 0;
  ctx.appSyncRun();
  check('手動同期では警告つきで確認できる', env.alerts.some(a => a.confirm && /一度に多くの人が利用停止/.test(a.message)), true);
  check('確認して「はい」なら反映', fsDocs(env, 'memberAccess')['p1@example.com'].status, 'inactive');
  [1, 2, 3].forEach(no => setStatus(app, no, '正式参加'));
  ctx.appSyncRun();
  check('戻せば全員復帰', ['p1', 'p2', 'p3'].map(p => fsDocs(env, 'memberAccess')[p + '@example.com'].status), ['active', 'active', 'active']);
  sheet.getRange(r, 2).setValue('いいえ');
}

/* ============================================================ */
section('G. アプリ用メールアドレス（学校のメールが届かない場合など）');
{
  const { env, app, ctx } = main;
  const rows = app._rows();
  const r = rows.findIndex((x, i) => i > 0 && x[0] === 3) + 1;
  app.getRange(r, rows[0].indexOf('アプリ用メールアドレス') + 1).setValue('Private3@Example.com');
  const id3 = fsDocs(env, 'memberAccess')['p3@example.com'].memberId;
  ctx.appSyncRun();
  const access = fsDocs(env, 'memberAccess');
  check('新しいアドレス（小文字化）でログイン可能・同じ団員ID', [access['private3@example.com'].status, access['private3@example.com'].memberId], ['active', id3]);
  check('元のアドレスは利用停止', access['p3@example.com'].status, 'inactive');
}

/* ============================================================ */
section('H. 運営補助（staff）の設定');
{
  const { env, ctx } = main;
  const sheet = env.spreadsheet.getSheetByName('アプリ連携設定');
  const r = sheet._rows().findIndex(x => x[0] === '運営補助のメールアドレス') + 1;
  sheet.getRange(r, 2).setValue('p2@example.com, helper@example.com');
  ctx.appSyncRun();
  const access = fsDocs(env, 'memberAccess');
  check('団員を運営補助にできる', [access['p2@example.com'].role, access['p2@example.com'].status], ['staff', 'active']);
  check('団員でない運営補助も登録できる', [access['helper@example.com'].role, access['helper@example.com'].memberId], ['staff', null]);
  sheet.getRange(r, 2).setValue('');
  ctx.appSyncRun();
  check('設定から外すと権限が戻る／利用停止', [fsDocs(env, 'memberAccess')['p2@example.com'].role, fsDocs(env, 'memberAccess')['helper@example.com'].status], ['member', 'inactive']);
}

/* ============================================================ */
section('I. 問題のある行');
{
  const people = PEOPLE.map(p => Object.assign({}, p));
  people[3].status = '正式参加';
  people[3].email = 'p1@example.com';      // 同じメール
  people[4].status = '正式参加';
  people[4].email = '';                    // メールなし
  people[5].status = '正式参加';
  people[5].inst = 'サックス';             // 判定できない楽器
  const { env, ctx } = makeEnv(people);
  const r = ctx.appSyncPreview();
  check('同じメールは1人分だけ', r.members, 4);
  check('問題の行を報告（No.で表示）', r.problems.length, 3);
  check('報告にメールアドレスを含めない', r.problems.some(p => /@/.test(p)), false);
}

/* ============================================================ */
section('J. 通信エラー・権限エラー');
{
  const { env, ctx } = makeEnv(PEOPLE);
  env.firestore.failNext = 2;
  env.alerts.length = 0;
  ctx.appSyncRun();
  check('一時的なエラー（503）は自動で再試行して成功', Object.keys(fsDocs(env, 'memberAccess')).length, 4);
  check('再試行の間隔は 1秒→2秒', env.sleeps.slice(0, 2), [1000, 2000]);

  const e2 = makeEnv(PEOPLE);
  e2.env.firestore.denied = true;
  e2.env.alerts.length = 0;
  let thrown = null;
  try { e2.ctx.appSyncRun(); } catch (e) { thrown = e.message; }
  check('権限エラーでも手動同期は落ちずに理由を表示', [thrown, /書き込む権限がありません/.test(lastAlert(e2.env))], [null, true]);
  check('権限エラーでは応募者一覧にアプリIDを振らない（お試しの段階で止まる）', header(e2.app).includes('アプリID'), false);
}

/* ============================================================ */
section('K. 自動同期トリガー');
{
  const { env, ctx } = makeEnv(PEOPLE);
  ctx.appSyncInstallTrigger();
  ctx.appSyncInstallTrigger();
  check('何度設定しても1本', env.triggers.filter(t => t.handler === 'appSyncScheduled').length, 1);
  check('自動同期が「いいえ」なら何もしない', [ctx.appSyncScheduled(), env.firestore.docs.size], [null, 0]);
}

/* ============================================================ */
section('L. 既存機能への影響なし');
{
  const { env, ctx } = main;
  env.alerts.length = 0;
  ctx.runIntegrityCheck();
  const rows = env.spreadsheet.getSheetByName('データチェック')._rows();
  check('アプリID・アプリ用メール列があっても整合性チェックのエラーなし', rows.filter(r => r[0] === 'エラー').map(r => r[1] + ':' + r[5]), []);
  ctx.runSystemDiagnosis();
  const diag = env.spreadsheet.getSheetByName('システム診断')._rows();
  check('アプリ関連の列は「運営が追加した列」扱いにしない', diag.some(r => /運営が追加した列/.test(r[0]) && /アプリ/.test(r[1])), false);
  const unit = ctx.runAllTests_();
  check('Tests.gs のセルフテストは全件成功', unit.failed, 0);
  env.alerts.length = 0;
  ctx.onOpen();
  const menu = env.menus[env.menus.length - 1];
  const sub = menu.items.find(i => i.submenu && i.submenu.name === '📱 団員アプリ');
  check('メニューに「📱 団員アプリ」', sub.submenu.items.map(i => i.fn), ['menuAppSyncPreview', 'menuAppSyncRun', 'menuAppSyncInstallTrigger', 'menuAppSyncOpenSettings']);
  check('メニューから呼べる', !!ctx.menuAppSyncPreview(), true);
}

/* ============================================================ */
section('M. 120人規模');
{
  const many = Array.from({ length: 120 }, (_, i) => person(i + 1, '団員' + i, ['Fl', 'Ob', 'Cl', 'Hr', 'Tp', 'Va', 'Vc', 'Cb'][i % 8], '正式参加'));
  const { env, ctx } = makeEnv(many);
  env.firestore.requests.length = 0;
  const started = Date.now();
  ctx.appSyncRun();
  check('120人を同期', fsDocs(env, 'stats').summary.memberCount, 120);
  check('書き込み 243件 → 400件ずつまとめて送信（1回）', env.firestore.commits, 1);
  check('通信回数が人数に比例しない（' + env.firestore.requests.length + '回）', env.firestore.requests.length < 20, true);
  console.log('    （ローカル実行時間 ' + (Date.now() - started) + 'ms）');
}

console.log('\n============================');
console.log('団員アプリ同期テスト：成功 ' + passed + '件 ／ 失敗 ' + failed + '件');
process.exit(failed ? 1 : 0);
