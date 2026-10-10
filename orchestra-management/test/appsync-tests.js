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
  ['Code.gs', 'AppSync.gs', 'AppNotify.gs', 'Membership.gs', 'Tests.gs'].forEach(f => vm.runInContext(fs.readFileSync(path.join(ROOT, f), 'utf8'), ctx, { filename: f }));
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

// 既存のテスト（A〜Q）は「参加希望者もアプリを使える＝いいえ」で、正式参加だけを登録する従来の動きを確認する
function makeEnv(people, opts = {}) {
  const env = createGasEnvironment({ effectiveUser: 'owner@example.com' });
  const ss = env.spreadsheet;
  const app = ss.insertSheet('応募者一覧');
  app._setTable([HEADERS].concat(people.map(row)));
  const form = ss.insertSheet('フォームの回答 1');
  form.formUrl = 'https://docs.google.com/forms/d/mock/viewform';
  form._setTable([FORM_HEADERS].concat(people.map(p => [p.ts, p.email, p.name, '', '社会人', '横浜市', p.inst, '', '', '', '', '', '', '', '', ''])));
  const ctx = load(env);
  if (!opts.raw) {
    ctx.appSyncEnsureSettingsSheet_(ss);
    setAppSetting(ss, '参加希望者もアプリを使える', opts.applicants ? 'はい' : 'いいえ');
    setAppSetting(ss, '応募時に自動でアプリに登録', opts.syncOnSubmit ? 'はい' : 'いいえ');
  }
  return { env, ss, app, ctx };
}

function setAppSetting(ss, label, value) {
  const sheet = ss.getSheetByName('アプリ連携設定');
  const r = sheet._rows().findIndex(x => x[0] === label) + 1;
  sheet.getRange(r, 2).setValue(value);
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
  check('応募者一覧の末尾に「アプリID」「アプリ用メールアドレス」（＋正式加入確認の列）を追加', header(app).slice(21), ['アプリID', 'アプリ用メールアドレス', 'アプリ利用', '正式加入の意思', '加入確認 回答日時', '加入確認メール', 'Firebase連携状態']);
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
  check('メニューに「📱 団員アプリ」', sub.submenu.items.map(i => i.fn), ['menuAppSyncPreview', 'menuAppSyncRun', 'menuAppSyncInstallTrigger', 'menuAppSyncOpenSettings', null, 'menuAppNotifyRunNow', 'menuAppNotifyInstallTrigger']);
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

/* ============================================================ */
section('N. 活動休止');
{
  const { env, app, ctx } = makeEnv(PEOPLE);
  ctx.appSyncRun();
  const idOf = no => col(app, 'アプリID')[no - 1];
  setStatus(app, 2, '活動休止');
  env.alerts.length = 0;
  const r = ctx.appSyncRun();
  const access = fsDocs(env, 'memberAccess');
  check('活動休止 → ログイン許可は paused（削除・利用停止しない）', access['p2@example.com'].status, 'paused');
  check('活動休止 → 団員プロフィールも paused', fsDocs(env, 'members')[idOf(2)].status, 'paused');
  check('団員数には含め、休止中の人数も送る', [fsDocs(env, 'stats').summary.memberCount, fsDocs(env, 'stats').summary.pausedCount], [3, 1]);
  check('利用停止の扱いにはならない', r.accessDeactivate, 0);
  check('結果に休止中の人数', /うち活動休止 1人/.test(allAlerts(env)), true);
  setStatus(app, 2, '正式参加');
  ctx.appSyncRun();
  check('休止から復帰 → active', fsDocs(env, 'memberAccess')['p2@example.com'].status, 'active');
  check('「活動休止」は対応状況の選択肢にある', vm.runInContext('CONFIG.statuses', ctx).slice(-2), ['辞退', '活動休止']);
  check('v1 の7種類の並びは変えない', vm.runInContext('CONFIG.statuses', ctx).slice(0, 7), ['未対応', '初回連絡済み', '返信待ち', '参加予定', '正式参加', '保留', '辞退']);
}

/* ============================================================ */
section('O. パートをログイン許可に含める（楽譜の閲覧範囲）');
{
  const { env, ctx } = makeEnv(PEOPLE);
  ctx.appSyncRun();
  const access = fsDocs(env, 'memberAccess');
  check('団員のパート', [access['p1@example.com'].part, access['p2@example.com'].part, access['p3@example.com'].part], ['Tp', 'Tuba', 'Fl']);
  check('団員でない管理者はパートなし', access['owner@example.com'].part, '');
  // 既存の（パートが無い）ログイン許可にもパートを追加する
  env.firestore.docs.forEach((f, k) => { if (k.startsWith('memberAccess/')) delete f.part; });
  const r = ctx.appSyncCore_({ dryRun: false });
  check('パートが無い既存の団員の許可を更新（団員3人）', [r.accessUpdate, fsDocs(env, 'memberAccess')['p1@example.com'].part], [3, 'Tp']);
}

/* ============================================================ */
section('P. 設定シートに新しい項目を追記（既存の値は変えない）');
{
  const { env, ss, ctx } = makeEnv(PEOPLE, { raw: true });
  const sheet = ss.insertSheet('アプリ連携設定');
  sheet._setTable([
    ['アプリ連携設定（団員アプリ）', '', ''], ['項目', '値', '説明'],
    ['Firebase プロジェクトID', 'kanagawa-connect-official', ''],
    ['管理者のメールアドレス', 'boss@example.com', ''],
    ['運営補助のメールアドレス', '', ''],
    ['自動同期（15分ごと）', 'はい', '']
  ]);
  const s = ctx.appSyncSettings_(ss);
  const labels = sheet._rows().map(r => r[0]);
  check('既存の値はそのまま', [s.adminEmails.join(), s.autoSync], ['boss@example.com', true]);
  check('通知の項目を末尾に追加', ['プッシュ通知の送信', '練習の前日通知', '前日通知の時刻（時）'].every(l => labels.indexOf(l) >= 0), true);
  check('初期値：通知の送信は「いいえ」、前日通知は18時', [s.pushEnabled, s.reminderEnabled, s.reminderHour], [false, true, 18]);
  ctx.appSyncSettings_(ss);
  check('2回目は追記しない', sheet._rows().filter(r => r[0] === 'プッシュ通知の送信').length, 1);
}

/* ============================================================ */
section('Q. プッシュ通知の送信');
function notifyEnv() {
  const e = makeEnv(PEOPLE);
  e.ctx.appSyncRun();
  const sheet = e.ss.getSheetByName('アプリ連携設定');
  const rows = sheet._rows();
  sheet.getRange(rows.findIndex(r => r[0] === 'プッシュ通知の送信') + 1, 2).setValue('はい');
  const access = fsDocs(e.env, 'memberAccess');
  const put = (path, obj) => e.env.firestore.docs.set(path, e.ctx.appSyncEncodeFields_(obj));
  // 端末：Tp・Tuba・Fl の団員、管理者、退団した人（p8 は辞退＝許可なし）、偽装（ID と token が不一致）
  put('pushTokens/tok-tp', { uid: 'u1', accessKey: 'p1@example.com', token: 'tok-tp', platform: 'iOS' });
  put('pushTokens/tok-tuba', { uid: 'u2', accessKey: 'p2@example.com', token: 'tok-tuba', platform: 'Android' });
  put('pushTokens/tok-fl', { uid: 'u3', accessKey: 'p3@example.com', token: 'tok-fl', platform: 'Android' });
  put('pushTokens/tok-admin', { uid: 'u0', accessKey: 'owner@example.com', token: 'tok-admin', platform: 'Mac' });
  put('pushTokens/tok-left', { uid: 'u8', accessKey: 'p8@example.com', token: 'tok-left', platform: 'iOS' });
  put('pushTokens/tok-fake', { uid: 'u9', accessKey: 'p1@example.com', token: 'other', platform: 'iOS' });
  e.put = put;
  e.access = access;
  return e;
}
{
  const { env, ctx, put } = notifyEnv();
  const now = new Date(2026, 9, 7, 10, 0, 0);
  put('notifications/n-all', { title: '全員へ', body: '本文', url: '/news#a1', audience: { type: 'all', values: [] }, status: 'pending', source: 'manual', createdAt: new Date(2026, 9, 7, 9) });
  put('notifications/n-brass', { title: '金管へ', body: '', url: '/scores', audience: { type: 'section', values: ['brass'] }, status: 'pending', source: 'score', createdAt: new Date(2026, 9, 7, 9, 1) });
  put('notifications/n-fl', { title: 'Flへ', body: '', url: 'https://evil.example.com', audience: { type: 'part', values: ['Fl'] }, status: 'pending', source: 'manual', createdAt: new Date(2026, 9, 7, 9, 2) });
  put('notifications/n-done', { title: '送信済み', body: '', url: '/', audience: { type: 'all', values: [] }, status: 'sent', source: 'manual' });
  env.fcm.invalidTokens.add('tok-fl');
  env.fcm.busyOnce.add('tok-tp');
  env.logs.length = 0;
  const r = ctx.appNotifyCore_({ now });
  const sentTo = title => env.fcm.sent.filter(x => x.data.title === title).map(x => x.token).sort();
  check('全員宛て：在籍中の団員と運営の端末（退団者・偽装登録には送らない）', sentTo('全員へ'), ['tok-admin', 'tok-tp', 'tok-tuba']);
  check('セクション宛て：金管（Tp・Tuba）だけ', sentTo('金管へ'), ['tok-tp', 'tok-tuba']);
  check('混雑（503）は1回だけ再試行して届ける', env.sleeps.indexOf(2000) >= 0 && sentTo('全員へ').indexOf('tok-tp') >= 0, true);
  check('届かなくなった端末（Fl）は登録を削除', env.firestore.docs.has('pushTokens/tok-fl'), false);
  check('送信済みの通知は送り直さない', sentTo('送信済み'), []);
  const n = fsDocs(env, 'notifications');
  check('結果を記録（送信済み・送れた台数・対象の台数）', [n['n-all'].status, n['n-all'].sentCount, n['n-all'].targetCount], ['sent', 3, 4]);
  check('アプリ外へのリンクは「/」に置き換える', env.fcm.sent.every(x => x.data.url.charAt(0) === '/') && n['n-fl'].status, 'sent');
  check('通知の中身は data だけ（表示はアプリが行う）', Object.keys(env.fcm.sent[0].data).sort(), ['body', 'tag', 'title', 'url']);
  check('秘密鍵を使わずログイン中アカウントの権限で送る', env.fcm.sent[0].headers.Authorization, 'Bearer mock-oauth-token');
  check('件数', [r.notifications, r.sent, r.removedTokens], [3, 5, 1]);
  check('ログにメールアドレス・通知トークンを出さない', env.logs.some(l => /@|tok-/.test(l)), false);
  check('結果メッセージにメールアドレス・トークンを含めない', /@|tok-/.test(ctx.appNotifyDescribe_(r)), false);
  const before = env.fcm.sent.length;
  ctx.appNotifyCore_({ now });
  check('もう一度実行しても二重に送らない', env.fcm.sent.length, before);
}
{
  const { env, ctx, put } = notifyEnv();
  const today = new Date(2026, 9, 7, 17, 59, 0);
  const evening = new Date(2026, 9, 7, 18, 5, 0);
  const base = { content: '', notes: '', target: '', scoreNote: '', attendanceDeadline: null };
  put('rehearsals/r-tomorrow', Object.assign({ title: '合奏練習', date: '2026-10-08', startTime: '13:00', endTime: '16:00', venue: '', published: true }, base));
  put('rehearsals/r-draft', Object.assign({ title: '下書き', date: '2026-10-08', startTime: '', endTime: '', venue: '', published: false }, base));
  put('rehearsals/r-later', Object.assign({ title: '来週', date: '2026-10-14', startTime: '', endTime: '', venue: '', published: true }, base));
  put('rehearsals/r-tbd', Object.assign({ title: '未定', date: '', startTime: '', endTime: '', venue: '', published: true }, base));
  let r = ctx.appNotifyCore_({ now: today });
  check('前日通知は設定した時刻（18時）より前には送らない', [r.reminders, env.fcm.sent.length], [0, 0]);
  r = ctx.appNotifyCore_({ now: evening });
  const msgs = env.fcm.sent.map(x => x.data);
  check('明日の公開中の練習だけ前日通知', [r.reminders, msgs.length ? msgs[0].title : ''], [1, '明日は練習です']);
  check('時間を本文に入れ、未定の会場は書かない', msgs[0].body, '合奏練習　13:00〜16:00');
  check('タップすると練習の詳細へ', msgs[0].url, '/schedule/r-tomorrow');
  r = ctx.appNotifyCore_({ now: new Date(2026, 9, 7, 21, 0, 0) });
  check('同じ練習の前日通知は1回だけ（端末4台に1通ずつ）', [r.reminders, env.fcm.sent.filter(x => x.data.title === '明日は練習です').length], [0, 4]);
  check('前日通知も送信履歴に残る', fsDocs(env, 'notifications')['reminder-r-tomorrow-2026-10-08'].status, 'sent');
}
{
  const { env, ctx, put } = notifyEnv();
  put('notifications/n1', { title: 'x', body: '', url: '/', audience: { type: 'all', values: [] }, status: 'pending', source: 'manual' });
  put('notifications/n-stuck', { title: '止まった', body: '', url: '/', audience: { type: 'all', values: [] }, status: 'sending', startedAt: new Date(2026, 9, 7, 8, 0), source: 'manual' });
  env.fcm.denied = true;
  const r = ctx.appNotifyCore_({ now: new Date(2026, 9, 7, 10, 0) });
  const n = fsDocs(env, 'notifications');
  check('権限エラーは「失敗」として記録し、案内を出す', [n.n1.status, /firebase\.messaging/.test(r.error)], ['failed', true]);
  check('「送信中」で止まった通知は再送せず失敗にする', [n['n-stuck'].status, env.fcm.sent.length], ['failed', 0]);
}
{
  const { env, ctx } = notifyEnv();
  env.firestore.requests.length = 0;
  env.firestore.docs.forEach((f, k) => { if (k.startsWith('notifications/')) env.firestore.docs.delete(k); });
  const r = ctx.appNotifyCore_({ now: new Date(2026, 9, 7, 10, 0) });
  check('送るものが無いときは端末・団員の一覧を読まない（読み取りを節約）', env.firestore.requests.filter(q => /pushTokens|memberAccess/.test(q.url)).length, 0);
  check('送るものが無いときの結果', [r.notifications, r.error], [0, null]);
}
{
  const { env, ctx } = notifyEnv();
  env.alerts.length = 0;
  ctx.appNotifyInstallTrigger();
  ctx.appNotifyInstallTrigger();
  check('通知のトリガーは1本だけ（10分ごと）', env.triggers.filter(t => t.getHandlerFunction() === 'appNotifyScheduled').length, 1);
  const sheet = env.spreadsheet.getSheetByName('アプリ連携設定');
  sheet.getRange(sheet._rows().findIndex(r => r[0] === 'プッシュ通知の送信') + 1, 2).setValue('いいえ');
  check('「いいえ」のときは送信しない', ctx.appNotifyScheduled(), null);
}

/* ============================================================ */
section('R. 参加希望者（応募しただけの人）もアプリを使える');
{
  const { env, app, ctx } = makeEnv(PEOPLE, { applicants: true });
  ctx.appSyncRun();
  const access = fsDocs(env, 'memberAccess');
  const stageOf = e => access[e] && access[e].stage;
  check('正式参加は stage=member', [stageOf('p1@example.com'), stageOf('p2@example.com'), stageOf('p3@example.com')], ['member', 'member', 'member']);
  check('未対応・初回連絡済みの人は stage=applicant でログインできる', [stageOf('p4@example.com'), stageOf('p6@example.com'), stageOf('p9@example.com'), access['p4@example.com'].status], ['applicant', 'applicant', 'applicant', 'active']);
  check('辞退の人は登録しない', access['p8@example.com'], undefined);
  check('管理者は stage=member', stageOf('owner@example.com'), 'member');
  const members = fsDocs(env, 'members');
  const applicants = fsDocs(env, 'applicants');
  check('団員一覧（members）に参加希望者は入らない', Object.keys(members).length, 3);
  check('参加希望者は applicants に（本人と運営だけが読める）', Object.keys(applicants).length, 5);
  const one = applicants[access['p4@example.com'].memberId];
  check('参加希望者のプロフィール：表示名・楽器のみ（個人情報なし）', Object.keys(one).filter(k => /mail|area|age|region|reason/i.test(k)), []);
  check('参加希望者のプロフィールの中身', [one.displayName, one.instrument, one.status], ['じゅん', 'Tuba', 'active']);
  check('団員数には参加希望者を含めない・参加希望者数を別に記録', [fsDocs(env, 'stats').summary.memberCount, fsDocs(env, 'stats').summary.applicantCount], [3, 5]);
  check('参加希望者にもアプリIDを振る（出欠の記録用）', col(app, 'アプリID').filter(Boolean).length, 8);

  // 正式参加に変わったら団員に（同じアプリIDのまま）
  const idBefore = access['p4@example.com'].memberId;
  setStatus(app, 4, '正式参加');
  ctx.appSyncRun();
  const after = fsDocs(env, 'memberAccess')['p4@example.com'];
  check('正式参加にすると stage=member、アプリIDは同じ（出欠の記録が引き継がれる）', [after.stage, after.memberId], ['member', idBefore]);
  check('団員プロフィールを作り、参加希望者のプロフィールは停止', [fsDocs(env, 'members')[idBefore].status, fsDocs(env, 'applicants')[idBefore].status], ['active', 'inactive']);

  // 辞退にしたら使えなくなる
  setStatus(app, 9, '辞退');
  ctx.appSyncRun();
  check('辞退にするとログイン許可を停止', fsDocs(env, 'memberAccess')['p9@example.com'].status, 'inactive');
  check('アプリ利用：参加希望者は「参加希望者」、辞退は「対象外」', [col(app, 'アプリ利用')[5], col(app, 'アプリ利用')[8]], ['参加希望者', '対象外']);
}
{
  // 既存の許可（stage なし）は団員として扱い、同期で stage を書き足す
  const { env, ctx } = makeEnv(PEOPLE);
  ctx.appSyncRun();
  env.firestore.docs.forEach((f, k) => { if (k.startsWith('memberAccess/')) delete f.stage; });
  ctx.appSyncRun();
  check('stage が無い既存の許可に stage=member を書き足す', fsDocs(env, 'memberAccess')['p1@example.com'].stage, 'member');
}
{
  const { env, app, ctx } = makeEnv(PEOPLE, { applicants: true, syncOnSubmit: true });
  ctx.appSyncRun();
  // 新しい応募がフォームから届く
  const form = env.spreadsheet.getSheetByName('フォームの回答 1');
  form.appendRow([new Date(2026, 9, 10, 9), 'new@example.com', 'あたらしい', '', '中学生', '横浜市', 'Fl', '', '', '', '', '', '', '', '', '']);
  ctx.handleSpreadsheetFormSubmit({});
  const a = fsDocs(env, 'memberAccess')['new@example.com'];
  check('応募が届いた時点で参加希望者としてログインできる', [a && a.stage, a && a.status], ['applicant', 'active']);
  check('応募者一覧にも取り込まれている', col(app, 'メールアドレス').indexOf('new@example.com') >= 0, true);
  check('トリガーは増やさない', env.triggers.length, 0);
}
{
  const { env, ctx } = makeEnv(PEOPLE, { applicants: true, syncOnSubmit: false });
  const form = env.spreadsheet.getSheetByName('フォームの回答 1');
  form.appendRow([new Date(2026, 9, 10, 9), 'new@example.com', 'あたらしい', '', '', '', 'Fl', '', '', '', '', '', '', '', '', '']);
  ctx.handleSpreadsheetFormSubmit({});
  check('「応募時に自動でアプリに登録」が「いいえ」なら同期しない', env.firestore.docs.size, 0);
}
{
  const { env, ss, ctx } = makeEnv(PEOPLE, { applicants: true });
  ctx.membershipEnsureSettingsSheet_(ss);
  ctx.membershipSetSetting_(ss, 'formUrl', 'https://docs.google.com/forms/d/e/join/viewform');
  ctx.appSyncRun();
  check('正式加入確認フォームの URL をアプリに送る（参加希望者のホームに表示）', fsDocs(env, 'appConfig').public.joinFormUrl, 'https://docs.google.com/forms/d/e/join/viewform');
  env.firestore.docs.get('appConfig/public').vapidKey = { stringValue: 'KEY' };
  ctx.appSyncRun();
  check('通知の公開鍵は消さない', fsDocs(env, 'appConfig').public.vapidKey, 'KEY');
}

{
  // 通知：参加希望者は「参加希望者にも送る」通知と前日通知だけ受け取る
  const { env, ctx } = makeEnv(PEOPLE, { applicants: true });
  ctx.appSyncRun();
  const sheet = env.spreadsheet.getSheetByName('アプリ連携設定');
  sheet.getRange(sheet._rows().findIndex(r => r[0] === 'プッシュ通知の送信') + 1, 2).setValue('はい');
  const put = (path, obj) => env.firestore.docs.set(path, ctx.appSyncEncodeFields_(obj));
  put('pushTokens/tok-member', { uid: 'u1', accessKey: 'p1@example.com', token: 'tok-member', platform: 'iOS' });
  put('pushTokens/tok-applicant', { uid: 'u4', accessKey: 'p4@example.com', token: 'tok-applicant', platform: 'iOS' });
  put('notifications/n-members', { title: '団員へ', body: '', url: '/', audience: { type: 'all', values: [] }, status: 'pending', source: 'manual' });
  put('notifications/n-both', { title: 'みなさんへ', body: '', url: '/', audience: { type: 'all', values: [] }, includeApplicants: true, status: 'pending', source: 'announcement' });
  ctx.appNotifyCore_({ now: new Date(2026, 9, 7, 10, 0) });
  const to = title => env.fcm.sent.filter(x => x.data.title === title).map(x => x.token).sort();
  check('通常の通知は団員だけ', to('団員へ'), ['tok-member']);
  check('「参加希望者にも送る」通知は参加希望者にも', to('みなさんへ'), ['tok-applicant', 'tok-member']);
  const base = { content: '', notes: '', target: '', scoreNote: '', attendanceDeadline: null };
  put('rehearsals/r1', Object.assign({ title: '合奏', date: '2026-10-08', startTime: '', endTime: '', venue: '', published: true }, base));
  ctx.appNotifyCore_({ now: new Date(2026, 9, 7, 19, 0) });
  check('練習の前日通知は参加希望者にも', to('明日は練習です'), ['tok-applicant', 'tok-member']);
}

console.log('\n============================');
console.log('団員アプリ同期テスト：成功 ' + passed + '件 ／ 失敗 ' + failed + '件');
process.exit(failed ? 1 : 0);
