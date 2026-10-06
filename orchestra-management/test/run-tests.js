/*
 * 統合テスト（ローカル実行）
 *   cd orchestra-management && TZ=Asia/Tokyo node test/run-tests.js
 *
 * 1. v1（変更前のコード）で実際に運用した状態を作る
 * 2. そこに v2（Code.gs）を適用し、既存データが壊れないことを確認
 * 3. 同期・重複防止・集計・連絡記録・トリガー・整合性チェックなどを確認
 */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { createGasEnvironment } = require('./gas-mock');
const { FORM_HEADERS, ts, response, initialResponses } = require('./fixtures');

const ROOT = path.join(__dirname, '..');
let passed = 0;
let failed = 0;
let current = '';

function section(name) {
  current = name;
  console.log('\n■ ' + name);
}

function check(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) {
    passed++;
    console.log('  ✓ ' + label);
  } else {
    failed++;
    console.log('  ✗ ' + label + '\n      期待: ' + e + '\n      実際: ' + a);
  }
}

function load(env, files) {
  const ctx = vm.createContext(Object.assign({}, env.globals));
  files.forEach(f => vm.runInContext(fs.readFileSync(f, 'utf8'), ctx, { filename: path.basename(f) }));
  return ctx;
}

function loadV1(env) {
  return load(env, [path.join(__dirname, 'fixtures', 'Code_v1_original.gs')]);
}

function loadV2(env) {
  return load(env, [path.join(ROOT, 'Code.gs'), path.join(ROOT, 'Tests.gs')]);
}

function table(sheet) {
  const rows = sheet._rows();
  const headers = rows[0] || [];
  return {
    headers,
    rows: rows.slice(1),
    col: name => rows.slice(1).map(r => r[headers.indexOf(name)]),
    find: (name, value) => rows.slice(1).find(r => r[headers.indexOf(name)] === value),
    get: (row, name) => row[headers.indexOf(name)]
  };
}

function cell(sheet, label, col) {
  const row = sheet._rows().find(r => r[0] === label);
  return row ? row[col === undefined ? 1 : col] : undefined;
}

function lastAlert(env) {
  const a = env.alerts[env.alerts.length - 1];
  return a ? a.message : '';
}

function addResponse(form, values) {
  const row = form.getLastRow() + 1;
  form.getRange(row, 1, 1, values.length).setValues([values]);
  return form.getRange(row, 1, 1, values.length);
}

function allText(env) {
  const parts = [];
  env.spreadsheet.getSheets().forEach(s => {
    if (s.getName() === '応募者一覧' || s.getName().indexOf('フォームの回答') === 0 || s.getName() === '連絡記録') return;
    s._rows().forEach(r => r.forEach(v => parts.push(String(v))));
  });
  return parts.join('\n');
}

/* ============================================================
 * シナリオ A：v1 で運用中のスプレッドシートに v2 を適用
 * ============================================================ */

const env = createGasEnvironment();
const ss = env.spreadsheet;
const form = ss.insertSheet('フォームの回答 1');
form.formUrl = 'https://docs.google.com/forms/d/mock/viewform';
form._setTable([FORM_HEADERS].concat(initialResponses()));

const v1 = loadV1(env);
v1.setupOrchestraManagement();
v1.installSpreadsheetFormTrigger();

// 運営が v1 上で行った手作業を再現
const app = ss.getSheetByName('応募者一覧');
const contacts = ss.getSheetByName('連絡記録');
const instSheet = ss.getSheetByName('楽器別集計');
let t = table(app);
const rowOf = name => t.rows.findIndex(r => r[3] === name) + 2;
app.getRange(rowOf('テスト一郎'), 18).setValue('正式参加');
app.getRange(rowOf('テスト三子'), 18).setValue('参加予定');
app.getRange(rowOf('テスト五子'), 21).setValue('チェロの経験豊富');
app.getRange(rowOf('テスト八郎'), 18).setValue('辞退');
contacts.getRange(2, 1, 1, 9).setValues([[ts(10, 10), 3, 'テスト三子', 'メール', '初回のご案内', 'あり', ts(12, 0), '担当A', '']]);
contacts.getRange(3, 1, 1, 9).setValues([[ts(11, 10), 1, 'テスト一郎', 'SNS', '練習日程', '', '', '担当B', '']]);
instSheet.getRange(2, 2).setValue(6); // Fl の目標を 4 → 6 に変更

app.getFilter().setColumnFilterCriteria(18, { hidden: ['辞退'] }); // 運営がフィルタで絞り込み中
const v1FilterCols = app.getFilter().getRange().getNumColumns();
const v1Snapshot = app._rows().map(r => r.slice(0, 21));
const formSnapshot = JSON.stringify(form._rows());

section('A. v1 → v2 移行（既存データを壊さない）');

const v2 = loadV2(env);
env.alerts.length = 0;
v2.onOpen();
check('メニュー①〜⑤が v1 と同じ順番で残っている',
  env.menus[0].items.filter(i => i.label).slice(0, 5).map(i => i.fn),
  ['setupOrchestraManagement', 'syncExistingResponses', 'installSpreadsheetFormTrigger', 'updateDashboard', 'checkConnection']);
check('メニュー⑥〜⑩が追加されている',
  env.menus[0].items.filter(i => i.label).slice(5).map(i => i.fn),
  ['updateInstrumentSummary', 'updateApplicantManagement', 'runIntegrityCheck', 'runDuplicateCheck', 'runSystemDiagnosis']);

v2.setupOrchestraManagement();

t = table(app);
check('既存8人の A〜U列（v1 の21列）は1文字も変わらない', app._rows().slice(0, v1Snapshot.length).map(r => r.slice(0, 21)), v1Snapshot);
check('「同期メモ」列が末尾（V列）に追加された', t.headers[21], '同期メモ');
check('重複して追加されていない（8人のまま）', t.rows.length, 8);
check('v1 のフィルタは A〜U 列・2行だけだった', [v1FilterCols, 21], [21, 21]);
check('フィルタが同期メモ列と全データ行まで広がった', [app.getFilter().getRange().getNumColumns(), app.getFilter().getRange().getLastRow()], [22, 9]);
check('フィルタの絞り込み条件は保たれている', app.getFilter().getColumnFilterCriteria(18), { hidden: ['辞退'] });
check('フォーム回答シートは変更していない', JSON.stringify(form._rows()), formSnapshot);
check('No. は v1 の番号のまま', t.col('No.'), [1, 2, 3, 4, 5, 6, 7, 8]);
check('_同期履歴 が作られ非表示', [!!ss.getSheetByName('_同期履歴'), ss.getSheetByName('_同期履歴').hidden], [true, true]);
check('既存8件が同期履歴に照合済みとして記録', ss.getSheetByName('_同期履歴').getLastRow() - 1, 8);

const settings = ss.getSheetByName('募集設定');
check('募集設定が作られた', !!settings, true);
check('運営が変えた Fl の目標人数(6)を引き継いだ', cell(settings, 'Fl', 3), 6);
check('団員目標 80 を引き継いだ', cell(settings, '団員目標'), 80);
check('演奏会開催判断ライン 60', cell(settings, '演奏会開催判断ライン'), 60);
check('最低人数 46', cell(settings, '最低人数'), 46);

section('B. 楽器別集計（テューバ／チューバ問題）');

const inst = ss.getSheetByName('楽器別集計');
check('楽器別集計の A〜G 列見出しは v1 と同じ', inst._rows()[0].slice(0, 7), ['楽器', '目標人数', '最低人数', '応募者数', '参加予定', '正式参加', '不足数']);
check('Tuba = 2人（v1 で取り込まれた「チューバ」も数える）', cell(inst, 'Tuba', 3), 2);
check('Tuba 参加予定 1', cell(inst, 'Tuba', 4), 1);
check('Fl 正式参加 1', cell(inst, 'Fl', 5), 1);
check('Fl 不足数 = 最低2 − 正式参加1 = 1（v1 と同じ計算）', cell(inst, 'Fl', 6), 1);
check('Fl 目標人数は運営が変えた 6', cell(inst, 'Fl', 1), 6);
check('v1 で数えられなかった「ヴァイオリン」を Vn（未定）として数える', cell(inst, 'Vn', 3), 1);
check('v1 で数えられなかった「ピッコロ」を Picc として数える', cell(inst, 'Picc', 3), 1);
check('Picc のパートは Fl', cell(inst, 'Picc', 11), 'Fl');
check('合計 = 8人', cell(inst, '合計', 3), 8);
check('Ob は 0人で急募', cell(inst, 'Ob', 10), '急募');
check('Hr は辞退のみ → 有効0人で急募', [cell(inst, 'Hr', 3), cell(inst, 'Hr', 7), cell(inst, 'Hr', 10)], [1, 0, '急募']);

section('C. 活動状況（v1 の判定ずれ修正）');

const status = ss.getSheetByName('活動状況');
check('A1:A9 の項目は v1 と同じ並び', status._rows().slice(0, 9).map(r => r[0]), ['項目', '応募者数', '参加予定', '正式参加', '団員目標', '演奏会開催判断ライン', '最低人数', '目標達成率', '現在の状況']);
check('応募者数 8', cell(status, '応募者数'), 8);
check('正式参加 1', cell(status, '正式参加'), 1);
check('目標達成率 = 1/80', cell(status, '目標達成率'), 1 / 80);
check('現在の状況', cell(status, '現在の状況'), '団員募集継続');
check('対応状況別：辞退 1', cell(status, '辞退'), 1);

section('D. ダッシュボード');

const dash = ss.getSheetByName('ダッシュボード');
check('ダッシュボードが作られた', !!dash, true);
check('参加希望者数（実人数）8', cell(dash, '参加希望者数（実人数）'), 8);
check('有効応募者数 7（辞退を除く）', cell(dash, '有効応募者数'), 7);
check('参加見込み 2', cell(dash, '参加見込み（参加予定＋正式参加）'), 2);
check('急募パートに Ob が含まれる', String(cell(dash, '🔴 急募パート')).indexOf('Ob（オーボエ）') >= 0, true);
check('パート別：Fl は Fl＋Picc の2人', cell(dash, 'Fl（フルート）', 2), 2);
check('パート別：Fl の内訳', cell(dash, 'Fl（フルート）', 1), 'Fl 1・Picc 1');
check('パート別：Vn の目標は 1st+2nd = 20', cell(dash, 'Vn（ヴァイオリン）', 5), 20);
check('ダッシュボード等にメールアドレスが出ていない', /@example\.com/.test(allText(env)), false);
check('ダッシュボード等に応募者の名前が出ていない', /テスト[一二三四五六七八九十]/.test(allText(env)), false);

section('E. 再同期・二重登録の防止');

env.alerts.length = 0;
v2.syncExistingResponses();
check('もう一度同期しても追加 0件', /今回追加：0件/.test(lastAlert(env)), true);
v2.syncWithoutDialog();
v2.syncWithoutDialog();
check('何度同期しても8人のまま', table(app).rows.length, 8);
v2.setupOrchestraManagement();
check('初期セットアップを再実行しても8人のまま', table(app).rows.length, 8);
check('再セットアップでも Fl 目標 6 は消えない', cell(ss.getSheetByName('楽器別集計'), 'Fl', 1), 6);
check('再セットアップでも連絡記録は残る', contacts.getLastRow(), 3);

section('F. 新規応募（フォーム送信トリガー）');

const r9 = addResponse(form, response(ts(12, 9), 'tester09@example.com', 'テスト九郎', 'ﾁｭｰﾊﾞ', { concert: '検討中' }));
env.setUiAvailable(false); // トリガー実行時は画面が無い
v2.handleSpreadsheetFormSubmit({ range: r9 });
env.setUiAvailable(true);
t = table(app);
const nine = t.find('お名前・呼ばれたい名前', 'テスト九郎');
check('新規応募が追加された', !!nine, true);
check('新規応募の No. は 9', t.get(nine, 'No.'), 9);
check('半角ｶﾅ「ﾁｭｰﾊﾞ」→ Tuba', t.get(nine, '楽器'), 'Tuba');
check('対応状況 = 未対応（v1 と同じ）', t.get(nine, '対応状況'), '未対応');
check('次の対応 = 初回連絡（v1 と同じ）', t.get(nine, '次の対応'), '初回連絡');
check('第1回演奏会の回答が入る', t.get(nine, '第1回演奏会'), '検討中');
check('Tuba が 3人に増えた', cell(ss.getSheetByName('楽器別集計'), 'Tuba', 3), 3);
check('自動同期の結果が記録された', JSON.parse(env.props.get('KCO_LAST_AUTO_SYNC')).added, 1);

section('G. 同じ人の再回答（上書きしない）');

const before3 = JSON.stringify(table(app).find('No.', 3));
addResponse(form, response(ts(13, 9), 'TESTER03@example.com', 'テスト三子', 'テューバ', { reason: '書き直しました' }));
v2.syncWithoutDialog();
t = table(app);
check('既存の No.3 の行は変わらない（上書きしない）', JSON.stringify(t.find('No.', 3)).replace(/"⚠重複候補[^"]*"/, '""'), before3);
const ten = t.find('No.', 10);
check('再回答は新しい行（No.10）として追加', t.get(ten, 'お名前・呼ばれたい名前'), 'テスト三子');
check('再回答の行に重複候補の印', String(t.get(ten, '同期メモ')).indexOf('⚠重複候補: No.3') === 0, true);
check('元の行にも印', String(t.get(t.find('No.', 3), '同期メモ')).indexOf('No.10') >= 0, true);
check('実人数は 9人（重複は数えない）', cell(ss.getSheetByName('ダッシュボード'), '参加希望者数（実人数）'), 9);
check('Tuba も 3人のまま', cell(ss.getSheetByName('楽器別集計'), 'Tuba', 3), 3);

section('H. 手作業との共存（並べ替え・削除・列の追加）');

// 並べ替え（楽器順）
const header = app._rows()[0];
const sorted = app._rows().slice(1).sort((a, b) => String(a[7]).localeCompare(String(b[7])));
app._setTable([header].concat(sorted));
addResponse(form, response(ts(14, 9), 'tester11@example.com', 'テスト十一', 'オーボエ'));
v2.syncWithoutDialog();
t = table(app);
check('並べ替え後も No.3 はテスト三子のまま（連絡記録とずれない）', t.get(t.find('No.', 3), 'お名前・呼ばれたい名前'), 'テスト三子');
check('新規は No.11', t.get(t.find('お名前・呼ばれたい名前', 'テスト十一'), 'No.'), 11);

// 削除しても復活しない
const delRow = t.rows.findIndex(r => r[0] === 10) + 2;
app._deleteRow(delRow);
v2.syncWithoutDialog();
t = table(app);
check('手動で削除した No.10 は同期で復活しない', t.find('No.', 10), undefined);
check('人数は 10行', t.rows.length, 10);

// 運営が応募者一覧の途中に列を追加
app._insertColumnBefore(4);
app.getRange(1, 4).setValue('運営メモ');
addResponse(form, response(ts(15, 9), 'tester12@example.com', 'テスト十二', 'ヴィオラ'));
v2.syncWithoutDialog();
t = table(app);
const twelve = t.find('お名前・呼ばれたい名前', 'テスト十二');
check('列を挿入しても正しい列に書き込む（名前）', !!twelve, true);
check('列を挿入しても正しい列に書き込む（楽器）', t.get(twelve, '楽器'), 'Va');
check('運営メモ列は空のまま', t.get(twelve, '運営メモ'), '');

section('I. フォームの変更（質問の追加・並び替え・名前変更）');

// 新しい質問が途中に追加された
form._insertColumnBefore(5);
form.getRange(1, 5).setValue('楽譜は読めますか？');
const vals = response(ts(16, 9), 'tester13@example.com', 'テスト十三', 'トロンボーン');
vals.splice(4, 0, 'はい');
addResponse(form, vals);
v2.syncWithoutDialog();
t = table(app);
const thirteen = t.find('お名前・呼ばれたい名前', 'テスト十三');
check('質問が追加されても楽器が正しい', t.get(thirteen, '楽器'), 'Tb');
check('質問が追加されても年代が正しい', t.get(thirteen, '学年・年代'), '20代');

// 質問名が変わった（楽器 → 演奏する楽器）
form.getRange(1, 8).setValue('演奏する楽器（メイン）');
const vals2 = response(ts(17, 9), 'tester14@example.com', 'テスト十四', 'ホルン');
vals2.splice(4, 0, 'はい');
addResponse(form, vals2);
env.alerts.length = 0;
v2.syncExistingResponses();
check('質問名が変わると確認ダイアログが出る', env.alerts.some(a => a.confirm && /楽器/.test(a.message)), true);
t = table(app);
const fourteen = t.find('お名前・呼ばれたい名前', 'テスト十四');
check('「はい」で続行 → 追加される', !!fourteen, true);
check('楽器は空欄・同期メモに未取得を記録', [t.get(fourteen, '楽器'), String(t.get(fourteen, '同期メモ'))], ['', '⚠未取得: 楽器']);
form.getRange(1, 8).setValue('楽器');

// 「いいえ」で中止
form.getRange(1, 8).setValue('演奏する楽器（メイン）');
const vals3 = response(ts(18, 9), 'tester15@example.com', 'テスト十五', 'ホルン');
vals3.splice(4, 0, 'はい');
addResponse(form, vals3);
env.setConfirmAnswer('NO');
const rowsBefore = table(app).rows.length;
v2.syncExistingResponses();
env.setConfirmAnswer('YES');
check('「いいえ」なら何も追加しない', table(app).rows.length, rowsBefore);
form.getRange(1, 8).setValue('楽器');
v2.syncWithoutDialog();
check('質問名を戻せば次の同期で追加される', !!table(app).find('お名前・呼ばれたい名前', 'テスト十五'), true);

section('J. 空欄・未知の値・数式インジェクション');

const blank = new Array(FORM_HEADERS.length + 1).fill('');
blank[0] = ts(19, 9);
addResponse(form, blank);
const weird = response(ts(19, 10), 'tester16@example.com', 'テスト十六', 'サックス', { reason: "'=IMPORTXML(\"https://example.com\",\"//a\")", age: '', affiliation: '', part: '' });
weird.splice(4, 0, '');
addResponse(form, weird);
let error = null;
try { v2.syncWithoutDialog(); } catch (e) { error = e.message; }
check('タイムスタンプ以外すべて空欄でもエラーにならない', error, null);
t = table(app);
const sixteen = t.find('お名前・呼ばれたい名前', 'テスト十六');
check('未知の楽器はそのまま保存（推測しない）', t.get(sixteen, '楽器'), 'サックス');
check('「=」で始まる回答は数式にならない', app.formulas.size, 0);
check('「=」で始まる回答も文字として保存', t.get(sixteen, '参加したいと思った理由'), '=IMPORTXML("https://example.com","//a")');
check('未分類として集計', cell(ss.getSheetByName('楽器別集計'), '（未分類）', 3), 1);
check('楽器未回答として集計（空欄2件：質問名変更時の1件＋全空欄1件）', cell(ss.getSheetByName('楽器別集計'), '（楽器未回答）', 3), 2);

section('K. 連絡記録 → 最終連絡日・氏名の補完');

contacts.getRange(4, 1, 1, 2).setValues([[ts(20, 15), 9]]); // 氏名は空欄で記入
v2.updateApplicantManagement();
t = table(app);
check('連絡記録の追加列（次回対応内容・対応状況）', table(contacts).headers.slice(9), ['次回対応内容', '対応状況']);
check('v1 の連絡記録はそのまま', table(contacts).rows[0].slice(0, 9).map(v => (v instanceof Date ? 'date' : v)), ['date', 3, 'テスト三子', 'メール', '初回のご案内', 'あり', 'date', '担当A', '']);
check('氏名が空欄なら No. から補完', contacts.get(4, 3), 'テスト九郎');
check('No.9 の最終連絡日が入る', +t.get(t.find('No.', 9), '最終連絡日'), +ts(20, 15));
check('No.3 の最終連絡日が入る', +t.get(t.find('No.', 3), '最終連絡日'), +ts(10, 10));

// 手入力の方が新しい場合は上書きしない
const row1 = t.rows.findIndex(r => r[0] === 1) + 2;
const lcCol = t.headers.indexOf('最終連絡日') + 1;
app.getRange(row1, lcCol).setValue(ts(25, 10));
v2.updateApplicantManagement();
check('手入力の新しい日付は古い連絡記録で上書きしない', +app.get(row1, lcCol), +ts(25, 10));

section('L. ステータス変更 → 編集時に自動更新');

t = table(app);
const stCol = t.headers.indexOf('対応状況') + 1;
const row11 = t.rows.findIndex(r => r[0] === 11) + 2;
app.getRange(row11, stCol).setValue('正式参加');
v2.onEdit({ range: app.getRange(row11, stCol), source: ss });
check('対応状況を変えると楽器別集計に反映（Ob 正式参加 1）', cell(ss.getSheetByName('楽器別集計'), 'Ob', 5), 1);
check('活動状況にも反映（正式参加 2）', cell(ss.getSheetByName('活動状況'), '正式参加'), 2);
const noteCol = t.headers.indexOf('備考') + 1;
env.resetStats();
v2.onEdit({ range: app.getRange(row11, noteCol), source: ss });
check('備考の編集では集計しない（無駄な処理をしない）', env.stats.writes, 0);

section('M. 募集設定の変更');

const settingsSheet = ss.getSheetByName('募集設定');
const obRow = settingsSheet._rows().findIndex(r => r[0] === 'Ob') + 1;
settingsSheet.getRange(obRow, 4).setValue(1);
settingsSheet.getRange(obRow, 5).setValue(1);
const aliasRow = settingsSheet._rows().findIndex(r => r[0] === 'Tuba') + 1;
settingsSheet.getRange(aliasRow, 6).setValue('チューバー');
v2.onEdit({ range: settingsSheet.getRange(obRow, 4), source: ss });
check('目標人数の変更が反映（Ob 目標1・有効1 → 充足）', cell(ss.getSheetByName('楽器別集計'), 'Ob', 10), '充足');
check('追加の表記ゆれが使える', v2.normalizeInstrument('チューバー', v2.buildInstrumentIndex_(v2.loadSettings_(ss))), 'Tuba');
const targetRow = settingsSheet._rows().findIndex(r => r[0] === '団員目標') + 1;
settingsSheet.getRange(targetRow, 2).setValue('たくさん');
v2.updateDashboard();
check('不正な設定値は初期値で動く', cell(ss.getSheetByName('活動状況'), '団員目標'), 80);
settingsSheet.getRange(targetRow, 2).setValue(80);

section('N. トリガー');

env.alerts.length = 0;
v2.installSpreadsheetFormTrigger();
v2.installSpreadsheetFormTrigger();
check('何度設定してもトリガーは1本', env.triggers.filter(x => x.handler === 'handleSpreadsheetFormSubmit').length, 1);
env.addForeignTrigger('handleSpreadsheetFormSubmit');
env.alerts.length = 0;
v2.checkConnection();
check('重複トリガーを接続状況で警告', /2件（重複）/.test(lastAlert(env)), true);
v2.installSpreadsheetFormTrigger();
check('③ で1本に整理', env.triggers.filter(x => x.handler === 'handleSpreadsheetFormSubmit').length, 1);
check('整理したことを表示', /2件 を整理/.test(lastAlert(env)), true);
env.triggers.length = 0;
env.alerts.length = 0;
v2.checkConnection();
check('トリガーが無くてもエラーにならず「未設定」と表示', /未設定/.test(lastAlert(env)), true);

section('O. 同時実行（ロック）');

env.setLockAvailable(false);
env.alerts.length = 0;
addResponse(form, response(ts(21, 9), 'tester17@example.com', 'テスト十七', 'フルート'));
v2.syncExistingResponses();
check('他の同期が実行中なら何もせず知らせる', /他の同期処理が実行中/.test(lastAlert(env)), true);
env.setUiAvailable(false);
let lockErr = null;
try { v2.handleSpreadsheetFormSubmit({}); } catch (e) { lockErr = e.message; }
env.setUiAvailable(true);
check('トリガー実行中に重なってもエラーにしない', lockErr, null);
check('重なった回はスキップと記録', JSON.parse(env.props.get('KCO_LAST_AUTO_SYNC')).busy, true);
env.setLockAvailable(true);
v2.syncWithoutDialog();
check('次の同期で取り込まれる', !!table(app).find('お名前・呼ばれたい名前', 'テスト十七'), true);

section('P. データ整合性チェック・重複チェック・システム診断');

env.alerts.length = 0;
v2.runIntegrityCheck();
const checkSheet = ss.getSheetByName('データチェック');
const issues = checkSheet._rows().slice(5);
const has = (type, re) => issues.some(r => r[1] === type && re.test(r[5]));
check('未知の楽器名を検出', has('未知の楽器名', /サックス/), true);
check('楽器の空欄を検出', has('必須項目が空欄', /楽器が空欄/), true);
check('お名前の空欄を検出', has('必須項目が空欄', /お名前が空欄/), true);
check('v1 の未正規化「チューバ」を表記ゆれとして検出', has('楽器名の表記ゆれ', /チューバ/), true);
check('ヴァイオリン（v1 データ）を表記ゆれとして検出', has('楽器名の表記ゆれ', /ヴァイオリン/), true);
check('連絡記録があるのに未対応を検出', issues.some(r => r[1] === '対応状況'), true);
check('チェック結果にメールアドレスを出さない', issues.some(r => /@/.test(r.join(' '))), false);

// 不正データを入れて検出できるか（H で重複行は削除済みなので、改めて同じメールの再回答を追加）
const dupVals = response(ts(21, 8), 'tester05@example.com', 'テスト五子', 'チェロ');
dupVals.splice(4, 0, '');
addResponse(form, dupVals);
v2.syncWithoutDialog();
t = table(app);
const row2 = t.rows.findIndex(r => r[0] === 2) + 2;
app.getRange(row2, t.headers.indexOf('対応状況') + 1).setValue('検討中？');
app.getRange(row2, t.headers.indexOf('最終連絡日') + 1).setValue('あした');
contacts.getRange(5, 1, 1, 2).setValues([[ts(21, 9), 999]]);
const dupNoRow = t.rows.findIndex(r => r[0] === 4) + 2;
app.getRange(dupNoRow, 1).setValue(5);
v2.runIntegrityCheck();
const issues2 = ss.getSheetByName('データチェック')._rows().slice(5);
const has2 = (type, re) => issues2.some(r => r[1] === type && re.test(r[5]));
check('未知のステータスを検出', has2('未知のステータス', /検討中？/), true);
check('不正な日付を検出', has2('不正な日付', /最終連絡日/), true);
check('存在しない応募者No.の連絡記録を検出', has2('連絡記録', /999/), true);
check('No. の重複を検出', has2('No.重複', /No\.5/), true);
check('同じメールアドレスの重複応募を検出', issues2.some(r => r[1] === '重複応募の可能性'), true);
check('アラートにエラー件数を表示', /データ整合性チェック：エラー \d+件/.test(lastAlert(env)), true);
app.getRange(dupNoRow, 1).setValue(4);
app.getRange(row2, t.headers.indexOf('対応状況') + 1).setValue('未対応');
app.getRange(row2, t.headers.indexOf('最終連絡日') + 1).setValue('');
contacts.getRange(5, 1, 1, 2).setValues([['', '']]);

// 未同期を検出
addResponse(form, response(ts(22, 9), 'tester18@example.com', 'テスト十八', 'チェロ'));
v2.runIntegrityCheck();
check('未同期のフォーム回答を検出', ss.getSheetByName('データチェック')._rows().some(r => r[1] === '同期不一致' && /未反映のフォーム回答が 1件/.test(r[5])), true);
v2.syncWithoutDialog();

// 集計が古い状態を検出
app.getRange(app.getLastRow() + 1, 1, 1, 3).setValues([[99, ts(23, 9), 'manual@example.com']]);
v2.runIntegrityCheck();
check('集計と応募者一覧の人数不一致を検出', ss.getSheetByName('データチェック')._rows().some(r => r[1] === '集計不一致'), true);
check('手入力の行（フォームに無い）を検出', ss.getSheetByName('データチェック')._rows().some(r => r[1] === '同期不一致' && r[4] === '99'), true);

env.alerts.length = 0;
v2.runDuplicateCheck();
check('重複チェック：No.3 と No.? の同じメールを検出', /重複応募の可能性/.test(lastAlert(env)), true);

env.alerts.length = 0;
v2.runSystemDiagnosis();
const diag = ss.getSheetByName('システム診断');
check('システム診断シートが作られた', !!diag, true);
check('診断：楽器「チューバ」の判定結果', diag._rows().some(r => /「チューバ」/.test(r[0]) && r[1] === 'Tuba'), true);
check('診断：未使用の質問（追加された質問）を表示', diag._rows().some(r => /未使用の質問/.test(r[0]) && /楽譜は読めますか/.test(r[1])), true);
check('診断：応募者一覧の運営メモ列を表示', diag._rows().some(r => /運営が追加した列/.test(r[0]) && /運営メモ/.test(r[1])), true);
check('診断にメールアドレスを出さない', diag._rows().some(r => /@/.test(r.join(' '))), false);

section('Q. 楽器名の表記を統一（メンテナンス）');

env.alerts.length = 0;
v2.normalizeApplicantInstruments();
t = table(app);
check('v1 時代の「チューバ」→ Tuba', t.get(t.find('No.', 4), '楽器'), 'Tuba');
check('「ヴァイオリン」→ Vn', t.get(t.find('No.', 2), '楽器'), 'Vn');
check('判定できない「サックス」は変更しない', t.get(t.find('お名前・呼ばれたい名前', 'テスト十六'), '楽器'), 'サックス');

section('R. セルフテスト（Tests.gs）');

const unit = v2.runAllTests_();
unit.failures.forEach(f => console.log('    ' + f));
check('Tests.gs のユニットテストがすべて成功（' + unit.passed + '件）', unit.failed, 0);

/* ============================================================
 * シナリオ S：まっさらな状態から・問題のないデータ
 * ============================================================ */

section('S. 新規導入（シートが何も無い状態）＋ 問題なしの表示');

const env2 = createGasEnvironment();
const ss2 = env2.spreadsheet;
const form2 = ss2.insertSheet('フォームの回答 1');
form2.formUrl = 'https://docs.google.com/forms/d/mock2/viewform';
form2._setTable([FORM_HEADERS].concat([
  response(ts(1, 9), 'clean1@example.com', 'クリーン一', 'フルート'),
  response(ts(1, 10), 'clean2@example.com', 'クリーン二', 'チェロ')
]));
const userSheet = ss2.insertSheet('ダッシュボード');
userSheet.getRange(1, 1).setValue('運営が自分で作ったメモ');
const c2 = loadV2(env2);
c2.setupOrchestraManagement();
check('新規導入で2人を同期', table(ss2.getSheetByName('応募者一覧')).rows.length, 2);
check('既存の同名シート「ダッシュボード」は上書きしない', ss2.getSheetByName('ダッシュボード').get(1, 1), '運営が自分で作ったメモ');
check('代わりに「ダッシュボード（自動）」を作る', !!ss2.getSheetByName('ダッシュボード（自動）'), true);
env2.alerts.length = 0;
c2.runIntegrityCheck();
check('問題が無ければ「データ整合性チェック：問題ありません」', lastAlert(env2).split('\n')[0], 'データ整合性チェック：問題ありません');

section('T. フォームの回答シートが2つ（再リンク）');

const old = ss2.getSheetByName('フォームの回答 1');
old.formUrl = null;
old.setName('フォームの回答 1');
const relinked = ss2.insertSheet('フォームの回答 2');
relinked.formUrl = 'https://docs.google.com/forms/d/mock2/viewform';
relinked._setTable([FORM_HEADERS, response(ts(2, 9), 'clean3@example.com', 'クリーン三', 'ホルン')]);
const other = ss2.insertSheet('フォームの回答 3');
other._setTable([['タイムスタンプ', '出欠', 'コメント'], [ts(3, 9), '出席', '']]);
c2.syncWithoutDialog();
const app2 = table(ss2.getSheetByName('応募者一覧'));
check('連携中の新しい回答シートから取り込む', !!app2.find('お名前・呼ばれたい名前', 'クリーン三'), true);
check('古い回答シートの回答は二重に取り込まない', app2.rows.length, 3);
check('別のフォーム（出欠）の回答は取り込まない', app2.rows.some(r => r.indexOf('出席') >= 0), false);
check('findResponseSheet_ は連携中のシートを返す', c2.findResponseSheet_(ss2).getName(), 'フォームの回答 2');

section('U. フォーム回答シートが無い・応募者一覧が無い');

const env3 = createGasEnvironment();
const c3 = loadV2(env3);
let e3 = null;
try { c3.syncExistingResponses(); c3.updateDashboard(); c3.checkConnection(); c3.runIntegrityCheck(); c3.runSystemDiagnosis(); } catch (e) { e3 = e.message; }
check('回答シートが無くてもエラーにならない', e3, null);
check('回答シートが無いことを表示', env3.alerts.some(a => /「フォームの回答」で始まるシートが見つかりません/.test(a.message)), true);
env3.setUiAvailable(false);
let e4 = null;
try { c3.handleSpreadsheetFormSubmit({}); } catch (e) { e4 = e.message; }
check('トリガーから呼ばれてもエラーにならない', e4, null);

/* ============================================================
 * シナリオ V：80人以上（150人）
 * ============================================================ */

section('V. 150人規模の性能');

const env4 = createGasEnvironment();
const ss4 = env4.spreadsheet;
const form4 = ss4.insertSheet('フォームの回答 1');
form4.formUrl = 'https://docs.google.com/forms/d/mock4/viewform';
const insts = ['フルート', 'オーボエ', 'クラリネット', 'ファゴット', 'ホルン', 'トランペット', 'トロンボーン', 'テューバ', 'チューバ', 'パーカッション', '第1ヴァイオリン', '第2ヴァイオリン', 'ヴァイオリン', 'ヴィオラ', 'チェロ', 'コントラバス'];
const many = [];
for (let i = 0; i < 150; i++) {
  const d = new Date(2026, 8, 1, 0, i, 0);
  many.push(response(d, 'm' + i + '@example.com', '団員' + i, insts[i % insts.length]));
}
form4._setTable([FORM_HEADERS].concat(many));
const c4 = loadV2(env4);
env4.resetStats();
let started = Date.now();
c4.setupOrchestraManagement();
let elapsed = Date.now() - started;
const apiWrites = env4.stats.writes;
check('150人を一括同期', table(ss4.getSheetByName('応募者一覧')).rows.length, 150);
check('書き込み回数が人数に比例しない（' + apiWrites + '回）', apiWrites < 40, true);
check('楽器別集計の合計 150', cell(ss4.getSheetByName('楽器別集計'), '合計', 3), 150);
check('Tuba = テューバ＋チューバ', cell(ss4.getSheetByName('楽器別集計'), 'Tuba', 3), many.filter(r => r[6] === 'テューバ' || r[6] === 'チューバ').length);
env4.resetStats();
started = Date.now();
addResponse(form4, response(new Date(2026, 9, 1), 'm150@example.com', '団員150', 'ホルン'));
c4.handleSpreadsheetFormSubmit({});
const incWrites = env4.stats.writes;
check('151人目の追加も書き込み回数は一定（' + incWrites + '回）', incWrites < 40, true);
console.log('    （ローカル実行時間：初回 ' + elapsed + 'ms／追加 ' + (Date.now() - started) + 'ms）');

/* ============================================================
 * シナリオ W：中身のない行（No.・チェックボックス・数式だけ）が大量にある
 * ============================================================ */

section('W. 中身のない行を応募者として数えない（1009人バグ）');

const env5 = createGasEnvironment();
const ss5 = env5.spreadsheet;
const form5 = ss5.insertSheet('フォームの回答 1');
form5.formUrl = 'https://docs.google.com/forms/d/mock5/viewform';
const real = initialResponses().concat([response(ts(7, 9), 'tester09@example.com', 'テスト九郎', 'オーボエ')]);
form5._setTable([FORM_HEADERS].concat(real));
const app5 = ss5.insertSheet('応募者一覧');
const v1Headers = ['No.', '回答日時', 'メールアドレス', 'お名前・呼ばれたい名前', '本名について', '学年・年代', '活動地域', '楽器', '希望パート', '楽器の経験年数', 'オーケストラでの演奏経験', '現在所属している音楽団体', '参加したいと思った理由', '練習参加可能性', '第1回演奏会', 'やってみたいこと', 'その他', '対応状況', '最終連絡日', '次の対応', '備考', '連絡済み'];
const junk = [v1Headers];
// v1 の No. 振り直しで 2〜1000行目に番号だけ入り、運営が追加したチェックボックス列（FALSE）も1000行目まである状態
for (let r = 2; r <= 1000; r++) {
  const line = new Array(v1Headers.length).fill('');
  line[0] = r - 1;
  line[21] = false;
  junk.push(line);
}
app5._setTable(junk);
const c5 = loadV2(env5);
c5.setupOrchestraManagement();
const dash5 = ss5.getSheetByName('ダッシュボード');
check('参加希望者数は実際の9人（1000行目までの空行を数えない）', cell(dash5, '参加希望者数（実人数）'), 9);
check('楽器別集計の合計も9人', cell(ss5.getSheetByName('楽器別集計'), '合計', 3), 9);
check('活動状況の応募者数も9人', cell(ss5.getSheetByName('活動状況'), '応募者数'), 9);
const t5 = table(app5);
const realRows = t5.rows.filter(r => r[3]);
check('実際の9人は取り込まれている', realRows.length, 9);
check('新しい No. は空行の番号と重ならない', realRows.every(r => r[0] > 999), true);
env5.alerts.length = 0;
c5.runIntegrityCheck();
check('整合性チェックで「中身のない行」を知らせる', ss5.getSheetByName('データチェック')._rows().some(r => r[1] === '中身のない行' && /999/.test(r[5])), true);
check('空行はエラー扱いしない（No.未設定・空欄の警告を大量に出さない）', ss5.getSheetByName('データチェック')._rows().filter(r => r[0] === '警告' || r[0] === 'エラー').length < 20, true);

/* ============================================================
 * シナリオ X：本番の応募者一覧（見出しが「氏名」「ニックネーム」「地域」など）
 *   ⑩ システム診断の結果から再現した列構成
 * ============================================================ */

section('X. 本番の見出し名（氏名・ニックネーム・地域 など）');

const PROD_HEADERS = ['No.', '回答日時', '氏名', 'ニックネーム', '年代・学年', '地域', '楽器', '希望パート', '経験年数', 'オーケストラ経験', '現在の所属', '参加理由', '参加可能性', '第1回演奏会', 'やりたいこと', 'メールアドレス', '対応状況', '最終連絡日', '次の対応', '備考'];
const PROD_FORM = ['タイムスタンプ', 'メールアドレス', '氏名', 'ニックネーム', '年代・学年', '地域', '楽器', '希望パート', '経験年数', 'オーケストラ経験', '現在の所属', '参加理由', '参加可能性', '第1回演奏会', 'やりたいこと'];
const env6 = createGasEnvironment();
const ss6 = env6.spreadsheet;
const prodRow = (no, d, email, name, nick, inst, status) =>
  [no, d, name, nick, '20代', '横浜', inst, '', '5年', 'あり', '', '楽しそう', '月2回', 'ぜひ参加したい', '', email, status, '', '初回連絡', ''];
const prodData = [PROD_HEADERS];
for (let r = 2; r <= 1000; r++) {           // 2〜1000行目：No. だけの行
  const line = new Array(PROD_HEADERS.length).fill('');
  line[0] = r - 1;
  prodData.push(line);
}
const prodPeople = [
  [ts(1, 10), 'p01@example.com', '本番一', 'いち', 'フルート', '正式参加'],
  [ts(1, 11), 'p02@example.com', '本番二', 'に', 'テューバ', '参加予定'],
  [ts(2, 9), 'p03@example.com', '本番三', 'さん', 'チューバ', '未対応'],
  [ts(2, 10), 'p04@example.com', '本番四', 'よん', 'ヴァイオリン', '未対応'],
  [ts(3, 9), 'p05@example.com', '本番五', 'ご', 'チェロ', '未対応'],
  [ts(3, 10), 'p06@example.com', '本番六', 'ろく', 'クラリネット', '初回連絡済み'],
  [ts(4, 9), 'p07@example.com', '本番七', 'なな', 'ホルン', '未対応'],
  [ts(4, 10), 'p08@example.com', '本番八', 'はち', 'ヴィオラ', '辞退'],
  [ts(5, 9), 'p09@example.com', '本番九', 'きゅう', 'コントラバス', '未対応'],
  [ts(5, 10), 'p10@example.com', '本番十', 'じゅう', 'オーボエ', '未対応']
];
prodPeople.forEach((p, i) => prodData.push(prodRow(1000 + i, p[0], p[1], p[2], p[3], p[4], p[5])));
const app6 = ss6.insertSheet('応募者一覧');
app6._setTable(prodData);
const form6 = ss6.insertSheet('フォームの回答 1');
form6.formUrl = 'https://docs.google.com/forms/d/mock6/viewform';
form6._setTable([PROD_FORM].concat(prodPeople.map(p => [p[0], p[1], p[2], p[3], '20代', '横浜', p[4], '', '5年', 'あり', '', '楽しそう', '月2回', 'ぜひ参加したい', ''])));
const before6 = JSON.stringify(app6._rows().map(r => r.slice(0, 20)));
const c6 = loadV2(env6);
c6.setupOrchestraManagement();
check('既存の20列は変わらない', JSON.stringify(app6._rows().slice(0, 1011).map(r => r.slice(0, 20))), before6);
check('同期で二重登録しない（10人のまま）', table(app6).rows.filter(r => r[2]).length, 10);
const dash6 = ss6.getSheetByName('ダッシュボード');
const inst6 = ss6.getSheetByName('楽器別集計');
check('参加希望者数 10人', cell(dash6, '参加希望者数（実人数）'), 10);
check('有効応募者 9人（辞退1）', cell(dash6, '有効応募者数'), 9);
check('Tuba 2人（テューバ＋チューバ）', cell(inst6, 'Tuba', 3), 2);
check('Fl 正式参加 1', cell(inst6, 'Fl', 5), 1);
check('Va は辞退のみ → 応募1・有効0', [cell(inst6, 'Va', 3), cell(inst6, 'Va', 7)], [1, 0]);
check('楽器別集計の合計 10', cell(inst6, '合計', 3), 10);
check('未分類なし', cell(inst6, '（未分類）', 3), undefined);

// 新しい回答が本番の列構成に正しく入る
addResponse(form6, [ts(6, 9), 'p11@example.com', '本番十一', 'じゅういち', '30代', '川崎', 'ﾁｭｰﾊﾞ', '', '10年', 'なし', '市民吹奏楽団', '近いから', '毎週', '検討中', 'ソロ']);
c6.syncWithoutDialog();
const t6 = table(app6);
const p11 = t6.find('氏名', '本番十一');
check('新しい回答が追加される', !!p11, true);
check('氏名列に名前', t6.get(p11, '氏名'), '本番十一');
check('ニックネーム列', t6.get(p11, 'ニックネーム'), 'じゅういち');
check('年代・学年列', t6.get(p11, '年代・学年'), '30代');
check('地域列', t6.get(p11, '地域'), '川崎');
check('楽器列（正規化）', t6.get(p11, '楽器'), 'Tuba');
check('経験年数列', t6.get(p11, '経験年数'), '10年');
check('オーケストラ経験列', t6.get(p11, 'オーケストラ経験'), 'なし');
check('現在の所属列', t6.get(p11, '現在の所属'), '市民吹奏楽団');
check('参加理由列', t6.get(p11, '参加理由'), '近いから');
check('参加可能性列', t6.get(p11, '参加可能性'), '毎週');
check('第1回演奏会列', t6.get(p11, '第1回演奏会'), '検討中');
check('やりたいこと列', t6.get(p11, 'やりたいこと'), 'ソロ');
check('メールアドレス列', t6.get(p11, 'メールアドレス'), 'p11@example.com');
check('対応状況 = 未対応', t6.get(p11, '対応状況'), '未対応');
check('新しい No. は既存の最大値の次（1010）', t6.get(p11, 'No.'), 1010);
check('Tuba 3人に', cell(ss6.getSheetByName('楽器別集計'), 'Tuba', 3), 3);
check('同期メモに「未取得」が付かない', String(t6.get(p11, '同期メモ')).indexOf('未取得'), -1);

env6.alerts.length = 0;
c6.runSystemDiagnosis();
const diag6 = ss6.getSheetByName('システム診断')._rows();
check('診断：氏名を「お名前」として認識', diag6.some(r => r[0] === '列：お名前・呼ばれたい名前' && /氏名/.test(r[1]) && r[2] === '✅'), true);
check('診断：本番に無い列（本名について・その他）は ❌ にしない', diag6.filter(r => /^列：/.test(r[0]) && r[2] === '❌').map(r => r[0]), []);
check('診断：運営が追加した列は無し', diag6.some(r => /運営が追加した列/.test(r[0])), false);

section('Y. 古いコードが列をずらして書いた行を検出');

// シナリオ X の本番シートに、v1（21列の並び）で書き込まれた行を足す
const misaligned = new Array(PROD_HEADERS.length).fill('');
misaligned[0] = 2000; misaligned[1] = ts(6, 12); misaligned[2] = 'shifted@example.com'; misaligned[3] = 'ずれ太郎';
misaligned[6] = '藤沢市'; misaligned[7] = 'Tp'; misaligned[16] = '伝えておきたいこと';
app6.insertRowsAfter(app6.getMaxRows(), 5);
app6.getRange(app6.getLastRow() + 1, 1, 1, PROD_HEADERS.length).setValues([misaligned]);
c6.runIntegrityCheck();
check('列ずれの行をエラーとして検出', ss6.getSheetByName('データチェック')._rows().some(r => r[1] === '列ずれの可能性' && r[4] === '2000'), true);
check('正しい行は列ずれ扱いしない', ss6.getSheetByName('データチェック')._rows().filter(r => r[1] === '列ずれの可能性').length, 1);
check('フォームに無いニックネームは「未取得」にしない', table(app6).rows.filter(r => /ニックネーム/.test(String(r[20]))).length, 0);

/* ============================================================
 * シナリオ Z：本番の状態をそのまま再現して「応募者一覧を整理」
 *   2〜1000行目：No. だけ
 *   1001〜1010行目：以前のコード（v1）が列をずらして書いた10行（オーボエの方が2回）
 *   1011〜1019行目：v2 が正しく取り込んだ9人
 * ============================================================ */

section('Z. 本番の状態を再現 → 応募者一覧を整理');

const REAL_FORM = ['タイムスタンプ', 'メールアドレス', '  個人情報の取り扱いについて  ', 'お名前・呼ばれたい名前 ', ' 本名について  ', '学年・年代', ' 活動地域  ', '楽器', '希望パート', '楽器の経験年数', 'オーケストラでの演奏経験', '現在所属している音楽団体', '  このオーケストラに参加したいと思った理由  ', '  どのくらい練習に参加できそうですか？  ', '  第1回演奏会への参加について  ', '  このオーケストラでやってみたいこと  ', ' その他、伝えておきたいこと  '];
const realLike = [
  ['トランペット', ''], ['テューバ', 'チューバ'], ['フルート', 'フルート・ピッコロ'], ['テューバ', 'テューバ'], ['クラリネット', 'クラリネット'],
  ['フルート', 'フルート'], ['フルート', '2ndもしくはpicc'], ['フルート', ''], ['オーボエ', 'オーボエ']
].map((x, i) => [new Date(2026, 9, 4 + Math.floor(i / 3), 8 + i, 0, 0), 'r' + i + '@example.com', '確認しました', '応募者' + i, '本名を登録してもよい', '社会人', '横浜市', x[0], x[1], '10年以上', 'ある', '', '理由', '日程によって変わる', 'ぜひ参加したい', '', i === 2 ? 'お手伝いできます' : '']);

const env7 = createGasEnvironment();
const ss7 = env7.spreadsheet;
const form7 = ss7.insertSheet('フォームの回答 1');
form7.formUrl = 'https://docs.google.com/forms/d/mock7/viewform';
form7._setTable([REAL_FORM].concat(realLike));
const app7 = ss7.insertSheet('応募者一覧');
const base7 = [PROD_HEADERS];
for (let r = 2; r <= 1000; r++) { const l = new Array(PROD_HEADERS.length).fill(''); l[0] = r - 1; base7.push(l); }
app7._setTable(base7);

// 以前のコード（v1）で同期 → 列がずれて追加される。オーボエの方は2回（トリガーの重複などを再現）
const v1z = loadV1(env7);
env7.setUiAvailable(false);
v1z.syncWithoutDialog();
const oboe = app7._rows()[app7.getLastRow() - 1].slice();
app7.appendRow(oboe);
env7.setUiAvailable(true);

// 新しいコードで同期 → 正しい9行が追加される
const v2z = loadV2(env7);
v2z.setupOrchestraManagement();
check('再現：1019行（No.だけ999＋ずれ10＋正しい9）', app7.getLastRow(), 1019);
check('再現：ずれた行の「楽器」列には地域が入っている', app7.get(1001, 7), '横浜市');
check('再現：ダッシュボードは19人（ずれ10が未分類）', cell(ss7.getSheetByName('ダッシュボード'), '参加希望者数（実人数）'), 19);

env7.alerts.length = 0;
v2z.runIntegrityCheck();
check('整合性チェックが列ずれ10行を検出', ss7.getSheetByName('データチェック')._rows().filter(r => r[1] === '列ずれの可能性').length, 10);

// 整理を実行（「はい」）
env7.alerts.length = 0;
v2z.cleanupApplicantsSheet();
const confirmMsg = env7.alerts.find(a => a.confirm);
check('確認ダイアログに内容を表示', !!confirmMsg && /中身のない行（No\. だけ等）：999行/.test(confirmMsg.message) && /列がずれて書き込まれた行（同じ人の正しい行あり）：10行/.test(confirmMsg.message), true);
const t7 = table(app7);
check('整理後は9人だけ', t7.rows.length, 9);
check('9人が2〜10行目にある', app7.getLastRow(), 10);
check('No. は 1〜9', t7.col('No.'), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
check('残ったのは正しい行（メールアドレス列にメール）', t7.col('メールアドレス').every(v => /@example\.com$/.test(v)), true);
check('氏名列に名前', t7.col('氏名').every(v => /^応募者\d$/.test(v)), true);
check('楽器列は楽器コード', t7.col('楽器'), ['Tp', 'Tuba', 'Fl', 'Tuba', 'Cl', 'Fl', 'Fl', 'Fl', 'Ob']);
check('「⚠未取得: ニックネーム」のメモは消えた', t7.col('同期メモ').filter(v => /ニックネーム/.test(String(v))).length, 0);
check('バックアップシートが作られた（整理前の1019行）', ss7.getSheetByName('応募者一覧（整理前バックアップ）').getLastRow(), 1019);
const dash7 = ss7.getSheetByName('ダッシュボード');
const inst7 = ss7.getSheetByName('楽器別集計');
check('ダッシュボード：参加希望者 9人', cell(dash7, '参加希望者数（実人数）'), 9);
check('楽器別：Fl 4・Tuba 2・Tp 1・Cl 1・Ob 1', ['Fl', 'Tuba', 'Tp', 'Cl', 'Ob'].map(c => cell(inst7, c, 3)), [4, 2, 1, 1, 1]);
check('楽器別：未分類なし', cell(inst7, '（未分類）', 3), undefined);
check('活動状況：未対応 9（変な状況名なし）', [cell(ss7.getSheetByName('活動状況'), '未対応'), ss7.getSheetByName('活動状況')._rows().some(r => /お手伝い/.test(r[0]))], [9, false]);
check('同期履歴の No. も 1〜9 に更新', ss7.getSheetByName('_同期履歴')._rows().slice(1).map(r => r[1]), [1, 2, 3, 4, 5, 6, 7, 8, 9]);

v2z.syncWithoutDialog();
check('整理後に同期しても誰も再追加されない', table(app7).rows.length, 9);
addResponse(form7, [new Date(2026, 9, 7, 9, 0, 0), 'r9@example.com', '確認しました', '応募者9', '本名を登録してもよい', '社会人', '川崎市', 'ホルン', '', '3~5年', 'ない', '', '理由', '月2回程度なら参加できそう', 'ぜひ参加したい', '', '']);
v2z.syncWithoutDialog();
const t7b = table(app7);
check('次の新しい応募は No.10・11行目', [t7b.get(t7b.find('氏名', '応募者9'), 'No.'), app7.getLastRow()], [10, 11]);
check('新しい応募の楽器は Hr', t7b.get(t7b.find('氏名', '応募者9'), '楽器'), 'Hr');
env7.alerts.length = 0;
v2z.runIntegrityCheck();
check('整理後のデータ整合性チェックはエラー・警告なし', ss7.getSheetByName('データチェック')._rows().filter(r => r[0] === 'エラー' || r[0] === '警告').map(r => r[1] + ':' + r[5]), []);

env7.alerts.length = 0;
v2z.cleanupApplicantsSheet();
check('2回目の整理は「整理が必要な行はありません」', lastAlert(env7), '整理が必要な行はありません。');

// 「いいえ」なら何も変えない
const env8 = createGasEnvironment();
const ss8 = env8.spreadsheet;
const app8 = ss8.insertSheet('応募者一覧');
app8._setTable(base7.slice(0, 5).concat([prodRow(4, ts(1, 9), 'x@example.com', '人', 'ニック', 'フルート', '未対応')]));
const c8 = loadV2(env8);
env8.setConfirmAnswer('NO');
c8.cleanupApplicantsSheet();
check('「いいえ」なら何も削除しない', app8.getLastRow(), 6);
check('「いいえ」ならバックアップも作らない', !!ss8.getSheetByName('応募者一覧（整理前バックアップ）'), false);

console.log('\n============================');
console.log('統合テスト：成功 ' + passed + '件 ／ 失敗 ' + failed + '件');
process.exit(failed ? 1 : 0);
