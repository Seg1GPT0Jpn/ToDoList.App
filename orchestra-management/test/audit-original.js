/*
 * 【監査用】変更前のコード（v1）をそのまま動かし、問題点を再現する。
 * 実行: TZ=Asia/Tokyo node test/audit-original.js
 */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { createGasEnvironment } = require('./gas-mock');
const { FORM_HEADERS, ts, response, initialResponses } = require('./fixtures');

function loadV1(env) {
  const ctx = vm.createContext(Object.assign({}, env.globals));
  const code = fs.readFileSync(path.join(__dirname, 'fixtures', 'Code_v1_original.gs'), 'utf8');
  vm.runInContext(code, ctx, { filename: 'Code_v1_original.gs' });
  return ctx;
}

function col(sheet, header) {
  const rows = sheet._rows();
  const i = rows[0].indexOf(header);
  return rows.slice(1).map(r => r[i]);
}

const findings = [];
function finding(title, detail) {
  findings.push(title);
  console.log('■ ' + title + '\n   ' + detail + '\n');
}

const env = createGasEnvironment();
const ss = env.spreadsheet;
const form = ss.insertSheet('フォームの回答 1');
form.formUrl = 'https://docs.google.com/forms/d/mock/viewform';
form._setTable([FORM_HEADERS].concat(initialResponses()));

const v1 = loadV1(env);
v1.setupOrchestraManagement();
const app = ss.getSheetByName('応募者一覧');

// 1. 楽器名の正規化
const inst = col(app, '楽器');
finding('楽器名：「チューバ」は Tuba に正規化されない',
  '応募者一覧の楽器列 = ' + JSON.stringify(inst) + '\n   ' +
  '楽器別集計は COUNTIF(H:H,"Tuba") なので「チューバ」「ヴァイオリン」「ピッコロ」の人は0人扱い（どの行にも数えられない）');

// 2. 活動状況 B9 の参照ずれ
const status = ss.getSheetByName('活動状況');
finding('活動状況：「現在の状況」の判定式が1行ずれている',
  'B9 = ' + status.formulas.get('9:2') + '\n   ' +
  'B5=団員目標(80), B6=演奏会開催判断ライン(60) なので、正式参加60人で「最低人数到達」、80人で「演奏会開催判断ライン到達」と表示される');

// 3. 応募者数は C列（メール）COUNTA
finding('活動状況：応募者数はメールアドレス列の件数',
  'B2 = ' + status.formulas.get('2:2') + '（メール空欄の応募者は数えられない）');

// 4. 再セットアップで楽器別の目標人数が初期化される
const instSheet = ss.getSheetByName('楽器別集計');
instSheet.getRange(2, 2).setValue(6); // 運営が Fl 目標を 6 に変更
v1.setupOrchestraManagement();
finding('楽器別集計：① 初期セットアップを再実行すると運営が変えた目標人数が消える',
  'Fl の目標人数を 6 に変更 → 再セットアップ後 = ' + instSheet.get(2, 2) + '（sheet.clear() で全消去される）');

// 5. 並べ替え後に No. が振り直され、連絡記録とずれる
const contacts = ss.getSheetByName('連絡記録');
contacts.getRange(2, 1, 1, 3).setValues([[ts(10, 10), 3, 'テスト三子']]);
const before = app._rows().slice(1).map(r => r[0] + ':' + r[3]);
// 運営がフィルタで「楽器」順に並べ替えた状況を再現
const header = app._rows()[0];
const body = app._rows().slice(1).sort((a, b) => String(a[7]).localeCompare(String(b[7])));
app._setTable([header].concat(body));
form.getRange(10, 1, 1, FORM_HEADERS.length).setValues([response(ts(7, 10), 'tester09@example.com', 'テスト九郎', 'オーボエ')]);
v1.syncWithoutDialog();
const after = app._rows().slice(1).map(r => r[0] + ':' + r[3]);
const no3 = app._rows().slice(1).find(r => r[0] === 3);
finding('No. が行番号で毎回振り直される → 連絡記録の「応募者No.」と別人になる',
  '並べ替え前 ' + JSON.stringify(before) + '\n   並べ替え＋同期後 ' + JSON.stringify(after) + '\n   ' +
  '連絡記録は「No.3 テスト三子」だが、同期後の No.3 は「' + no3[3] + '」');

// 6. 手動で削除した行が同期で復活する
const countBefore = app.getLastRow() - 1;
app._deleteRow(2);
v1.syncWithoutDialog();
finding('応募者一覧から手動で削除した行が、次の同期で復活する',
  '削除前 ' + countBefore + '人 → 1行削除 → 同期後 ' + (app.getLastRow() - 1) + '人');

// 7. 同時実行（ロックなし）
finding('LockService が無く、同期の同時実行を防げない',
  'コード上 LockService の利用なし。フォームが続けて送信された／別の管理者もトリガーを設定した場合、' +
  '2つの同期が同じ「未追加の回答」を読んで二重に appendRow し得る（installSpreadsheetFormTrigger は自分のトリガーしか見えない）');

// 8. フォームの質問名変更
const form2 = ss.getSheetByName('フォームの回答 1');
form2.getRange(1, 7).setValue('演奏する楽器');
env.alerts.length = 0;
v1.syncExistingResponses();
finding('フォームの質問名が1つ変わると、手動同期は全件停止／自動同期は黙って楽器を空欄で取り込む',
  '手動同期のメッセージ: ' + JSON.stringify(env.alerts.map(a => a.message)));
form2.getRange(1, 7).setValue('楽器');

// 9. トリガー文脈で getUi
env.setUiAvailable(false);
let err = null;
try { v1.syncExistingResponses(); } catch (e) { err = e.message; }
env.setUiAvailable(true);
finding('（参考）ダイアログ付き関数はトリガーから呼ぶとエラー', String(err));

// 10. 数式インジェクション
form.getRange(12, 1, 1, FORM_HEADERS.length).setValues([response(ts(9, 10), 'tester11@example.com', 'テスト十一', 'チェロ', { reason: "'=IMPORTXML(\"https://example.com\",\"//a\")" })]);
v1.syncWithoutDialog();
const formulaCells = [];
app.formulas.forEach((f, k) => formulaCells.push(k + ' ' + f));
finding('フォームの自由記述が「=」で始まると、応募者一覧に数式として書き込まれる',
  formulaCells.join(' / ') || '（なし）');

console.log('再現できた問題: ' + findings.length + '件');
