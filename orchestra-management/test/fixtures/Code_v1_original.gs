/*******************************************************
 * かながわコネクトオーケストラ
 * 応募者管理システム 完全版
 *
 * 構成
 * Googleフォーム
 *     ↓
 * フォームの回答
 *     ↓
 * 応募者一覧
 *     ↓
 * 楽器別集計
 *     ↓
 * 活動状況
 *     ↓
 * 連絡記録
 *******************************************************/


/*******************************************************
 * 基本設定
 *******************************************************/

const CONFIG = {

  // 管理用シート
  applicantsSheet: '応募者一覧',
  instrumentsSheet: '楽器別集計',
  statusSheet: '活動状況',
  contactsSheet: '連絡記録',

  // フォーム回答シートの名前
  responseSheetPrefix: 'フォームの回答',

  // 団員目標
  targetMembers: 80,

  // 演奏会開催判断ライン
  decisionMembers: 60,

  // 最低人数
  minimumMembers: 46
};


/*******************************************************
 * スプレッドシートを開いたときのメニュー
 *******************************************************/

function onOpen() {

  SpreadsheetApp
    .getUi()
    .createMenu('🎻 オーケストラ管理')
    .addItem(
      '① 初期セットアップ',
      'setupOrchestraManagement'
    )
    .addItem(
      '② 既存回答を同期',
      'syncExistingResponses'
    )
    .addItem(
      '③ フォーム送信トリガー設定',
      'installSpreadsheetFormTrigger'
    )
    .addItem(
      '④ ダッシュボード更新',
      'updateDashboard'
    )
    .addSeparator()
    .addItem(
      '⑤ 接続状況を確認',
      'checkConnection'
    )
    .addToUi();
}


/*******************************************************
 * 初期セットアップ
 *******************************************************/

function setupOrchestraManagement() {

  const ss =
    SpreadsheetApp.getActiveSpreadsheet();

  setupApplicantsSheet_(ss);

  setupInstrumentSheet_(ss);

  setupStatusSheet_(ss);

  setupContactSheet_(ss);

  syncExistingResponses();

  updateDashboard();

  SpreadsheetApp.getUi().alert(
    'セットアップ完了！\n\n' +
    '「応募者一覧」「楽器別集計」「活動状況」「連絡記録」を作成しました。\n\n' +
    '既存のフォーム回答も同期しています。'
  );
}


/*******************************************************
 * 応募者一覧を作成
 *******************************************************/

function setupApplicantsSheet_(ss) {

  let sheet =
    ss.getSheetByName(CONFIG.applicantsSheet);

  if (!sheet) {

    sheet =
      ss.insertSheet(CONFIG.applicantsSheet);
  }


  const headers = [

    'No.',
    '回答日時',
    'メールアドレス',
    'お名前・呼ばれたい名前',
    '本名について',
    '学年・年代',
    '活動地域',
    '楽器',
    '希望パート',
    '楽器の経験年数',
    'オーケストラでの演奏経験',
    '現在所属している音楽団体',
    '参加したいと思った理由',
    '練習参加可能性',
    '第1回演奏会',
    'やってみたいこと',
    'その他',
    '対応状況',
    '最終連絡日',
    '次の対応',
    '備考'
  ];


  /*
   * A1:U1が空の場合だけ見出しを作る
   */
  const firstRow =
    sheet
      .getRange(
        1,
        1,
        1,
        headers.length
      )
      .getValues()[0];


  const isEmpty =
    firstRow.every(
      value => value === ''
    );


  if (isEmpty) {

    sheet
      .getRange(
        1,
        1,
        1,
        headers.length
      )
      .setValues([headers]);

  }


  /*
   * 見出しを固定
   */
  sheet.setFrozenRows(1);


  /*
   * フィルター
   */
  if (!sheet.getFilter()) {

    sheet
      .getRange(
        1,
        1,
        Math.max(sheet.getLastRow(), 2),
        headers.length
      )
      .createFilter();

  }


  /*
   * 対応状況
   */
  const statusRule =
    SpreadsheetApp
      .newDataValidation()
      .requireValueInList(
        [
          '未対応',
          '初回連絡済み',
          '返信待ち',
          '参加予定',
          '正式参加',
          '保留',
          '辞退'
        ],
        true
      )
      .build();


  sheet
    .getRange(
      2,
      18,
      Math.max(sheet.getMaxRows() - 1, 1),
      1
    )
    .setDataValidation(statusRule);


  /*
   * 第1回演奏会
   */
  const concertRule =
    SpreadsheetApp
      .newDataValidation()
      .requireValueInList(
        [
          'ぜひ参加したい',
          '検討中',
          '参加しない'
        ],
        true
      )
      .build();


  sheet
    .getRange(
      2,
      15,
      Math.max(sheet.getMaxRows() - 1, 1),
      1
    )
    .setDataValidation(concertRule);


  /*
   * 列幅
   */
  sheet.autoResizeColumns(
    1,
    headers.length
  );
}


/*******************************************************
 * 楽器別集計
 *******************************************************/

function setupInstrumentSheet_(ss) {

  let sheet =
    ss.getSheetByName(CONFIG.instrumentsSheet);

  if (!sheet) {

    sheet =
      ss.insertSheet(CONFIG.instrumentsSheet);

  }


  sheet.clear();


  const headers = [
    '楽器',
    '目標人数',
    '最低人数',
    '応募者数',
    '参加予定',
    '正式参加',
    '不足数'
  ];


  sheet
    .getRange(
      1,
      1,
      1,
      headers.length
    )
    .setValues([headers]);


  const instruments = [

    ['Fl', 4, 2],
    ['Ob', 2, 1],
    ['Cl', 5, 3],
    ['Fg', 2, 1],
    ['Hr', 6, 4],
    ['Tp', 4, 2],
    ['Tb', 4, 3],
    ['Tuba', 1, 1],
    ['Perc', 4, 3],

    ['1st Vn', 10, 7],
    ['2nd Vn', 10, 7],
    ['Va', 10, 5],
    ['Vc', 10, 5],
    ['Cb', 4, 2]
  ];


  sheet
    .getRange(
      2,
      1,
      instruments.length,
      3
    )
    .setValues(instruments);


  /*
   * 数式
   */

  for (
    let row = 2;
    row < instruments.length + 2;
    row++
  ) {

    /*
     * 応募者数
     */
    sheet
      .getRange(row, 4)
      .setFormula(
        `=COUNTIF('${CONFIG.applicantsSheet}'!H:H,A${row})`
      );


    /*
     * 参加予定
     */
    sheet
      .getRange(row, 5)
      .setFormula(
        `=COUNTIFS('${CONFIG.applicantsSheet}'!H:H,A${row},'${CONFIG.applicantsSheet}'!R:R,"参加予定")`
      );


    /*
     * 正式参加
     */
    sheet
      .getRange(row, 6)
      .setFormula(
        `=COUNTIFS('${CONFIG.applicantsSheet}'!H:H,A${row},'${CONFIG.applicantsSheet}'!R:R,"正式参加")`
      );


    /*
     * 不足数
     */
    sheet
      .getRange(row, 7)
      .setFormula(
        `=MAX(C${row}-F${row},0)`
      );

  }


  sheet.setFrozenRows(1);

  sheet.autoResizeColumns(
    1,
    headers.length
  );
}


/*******************************************************
 * 活動状況
 *******************************************************/

function setupStatusSheet_(ss) {

  let sheet =
    ss.getSheetByName(CONFIG.statusSheet);

  if (!sheet) {

    sheet =
      ss.insertSheet(CONFIG.statusSheet);

  }


  sheet.clear();


  sheet
    .getRange('A1:B1')
    .setValues([
      ['項目', '現在値']
    ]);


  const rows = [

    ['応募者数', ''],
    ['参加予定', ''],
    ['正式参加', ''],
    ['団員目標', CONFIG.targetMembers],
    ['演奏会開催判断ライン', CONFIG.decisionMembers],
    ['最低人数', CONFIG.minimumMembers],
    ['目標達成率', ''],
    ['現在の状況', '']
  ];


  sheet
    .getRange(
      2,
      1,
      rows.length,
      2
    )
    .setValues(rows);


  /*
   * 応募者数
   */
  sheet
    .getRange('B2')
    .setFormula(
      `=COUNTA('${CONFIG.applicantsSheet}'!C2:C)`
    );


  /*
   * 参加予定
   */
  sheet
    .getRange('B3')
    .setFormula(
      `=COUNTIF('${CONFIG.applicantsSheet}'!R:R,"参加予定")`
    );


  /*
   * 正式参加
   */
  sheet
    .getRange('B4')
    .setFormula(
      `=COUNTIF('${CONFIG.applicantsSheet}'!R:R,"正式参加")`
    );


  /*
   * 達成率
   */
  sheet
    .getRange('B8')
    .setFormula(
      '=IF(B5=0,0,B4/B5)'
    );


  sheet
    .getRange('B8')
    .setNumberFormat('0.0%');


  /*
   * 状況
   */
  sheet
    .getRange('B9')
    .setFormula(
      '=IF(B4>=B5,"演奏会開催判断ライン到達",IF(B4>=B6,"最低人数到達","団員募集継続"))'
    );


  sheet.setFrozenRows(1);

  sheet.autoResizeColumns(1, 2);
}


/*******************************************************
 * 連絡記録
 *******************************************************/

function setupContactSheet_(ss) {

  let sheet =
    ss.getSheetByName(CONFIG.contactsSheet);

  if (!sheet) {

    sheet =
      ss.insertSheet(CONFIG.contactsSheet);

  }


  const headers = [

    '日付',
    '応募者No.',
    '氏名',
    '連絡方法',
    '内容',
    '相手からの返信',
    '次回対応日',
    '担当',
    '備考'
  ];


  if (sheet.getLastRow() === 0) {

    sheet
      .getRange(
        1,
        1,
        1,
        headers.length
      )
      .setValues([headers]);

  }


  const contactRule =
    SpreadsheetApp
      .newDataValidation()
      .requireValueInList(
        [
          'メール',
          'SNS',
          'その他'
        ],
        true
      )
      .build();


  sheet
    .getRange(
      2,
      4,
      Math.max(sheet.getMaxRows() - 1, 1),
      1
    )
    .setDataValidation(contactRule);


  sheet.setFrozenRows(1);

  sheet.autoResizeColumns(
    1,
    headers.length
  );
}


/*******************************************************
 * 既存フォーム回答を同期
 *
 * 重要：
 * Googleフォームそのものには接続しない。
 *
 * 「フォームの回答」シートを読む。
 *******************************************************/

function syncExistingResponses() {

  const ss =
    SpreadsheetApp.getActiveSpreadsheet();


  /*
   * フォーム回答シートを探す
   */

  const responseSheet =
    findResponseSheet_(ss);


  if (!responseSheet) {

    SpreadsheetApp
      .getUi()
      .alert(
        '「フォームの回答」で始まるシートが見つかりません。\n\n' +
        'Googleフォームの回答先スプレッドシートを確認してください。'
      );

    return;
  }


  /*
   * 応募者一覧を取得
   */

  let applicants =
    ss.getSheetByName(
      CONFIG.applicantsSheet
    );


  if (!applicants) {

    setupApplicantsSheet_(ss);

    applicants =
      ss.getSheetByName(
        CONFIG.applicantsSheet
      );
  }


  /*
   * フォーム回答を取得
   */

  const data =
    responseSheet
      .getDataRange()
      .getValues();


  if (data.length <= 1) {

    SpreadsheetApp
      .getUi()
      .alert(
        'フォーム回答はまだありません。'
      );

    return;
  }


  const headers =
    data[0].map(
      value => String(value).trim()
    );


  /*
   * ヘッダー位置を取得
   */

  const index = {};

  headers.forEach(
    (header, i) => {
      index[header] = i;
    }
  );


  /*
   * 必須ヘッダー確認
   */

  const requiredHeaders = [

    'タイムスタンプ',
    'メールアドレス',
    'お名前・呼ばれたい名前',
    '本名について',
    '学年・年代',
    '活動地域',
    '楽器',
    '希望パート',
    '楽器の経験年数',
    'オーケストラでの演奏経験',
    '現在所属している音楽団体',
    'このオーケストラに参加したいと思った理由',
    'どのくらい練習に参加できそうですか？',
    '第1回演奏会への参加について',
    'このオーケストラでやってみたいこと',
    'その他、伝えておきたいこと'
  ];


  const missing =
    requiredHeaders.filter(
      header =>
        index[header] === undefined
    );


  if (missing.length > 0) {

    SpreadsheetApp
      .getUi()
      .alert(
        'フォームの質問名が一致していません。\n\n' +
        '見つからない項目：\n' +
        missing.join('\n')
      );

    return;
  }


  /*
   * 既存の応募者を取得
   */

  const applicantData =
    applicants
      .getDataRange()
      .getValues();


  /*
   * 重複判定用
   *
   * 「回答日時＋メールアドレス」
   */

  const existingKeys =
    new Set();


  for (
    let i = 1;
    i < applicantData.length;
    i++
  ) {

    const timestamp =
      normalizeKeyValue(
        applicantData[i][1]
      );

    const email =
      normalizeKeyValue(
        applicantData[i][2]
      );


    if (
      timestamp ||
      email
    ) {

      existingKeys.add(
        timestamp +
        '|' +
        email
      );
    }
  }


  /*
   * 新規追加数
   */

  let added = 0;


  /*
   * フォーム回答を処理
   */

  for (
    let r = 1;
    r < data.length;
    r++
  ) {

    const row =
      data[r];


    const timestamp =
      row[index['タイムスタンプ']];


    const email =
      row[index['メールアドレス']];


    const key =
      normalizeKeyValue(timestamp) +
      '|' +
      normalizeKeyValue(email);


    /*
     * すでにある回答はスキップ
     */

    if (
      existingKeys.has(key)
    ) {

      continue;
    }


    /*
     * 新規応募者
     */

    const newRow = [

      '',

      timestamp,

      email,

      getCell(
        row,
        index,
        'お名前・呼ばれたい名前'
      ),

      getCell(
        row,
        index,
        '本名について'
      ),

      getCell(
        row,
        index,
        '学年・年代'
      ),

      getCell(
        row,
        index,
        '活動地域'
      ),

      normalizeInstrument(
        getCell(
          row,
          index,
          '楽器'
        )
      ),

      getCell(
        row,
        index,
        '希望パート'
      ),

      getCell(
        row,
        index,
        '楽器の経験年数'
      ),

      getCell(
        row,
        index,
        'オーケストラでの演奏経験'
      ),

      getCell(
        row,
        index,
        '現在所属している音楽団体'
      ),

      getCell(
        row,
        index,
        'このオーケストラに参加したいと思った理由'
      ),

      getCell(
        row,
        index,
        'どのくらい練習に参加できそうですか？'
      ),

      getCell(
        row,
        index,
        '第1回演奏会への参加について'
      ),

      getCell(
        row,
        index,
        'このオーケストラでやってみたいこと'
      ),

      getCell(
        row,
        index,
        'その他、伝えておきたいこと'
      ),

      '未対応',

      '',

      '初回連絡',

      ''
    ];


    applicants.appendRow(
      newRow
    );


    existingKeys.add(key);

    added++;
  }


  /*
   * No.を振り直す
   */

  renumberApplicants();


  /*
   * 集計更新
   */

  updateDashboard();


  SpreadsheetApp
    .getUi()
    .alert(

      '同期完了！\n\n' +

      'フォーム回答総数：' +
      (data.length - 1) +
      '件\n' +

      '今回追加：' +
      added +
      '件\n\n' +

      '「応募者一覧」を確認してください。'
    );
}


/*******************************************************
 * フォーム回答シートを探す
 *******************************************************/

function findResponseSheet_(ss) {

  const sheets =
    ss.getSheets();


  for (
    const sheet of sheets
  ) {

    if (
      sheet
        .getName()
        .startsWith(
          CONFIG.responseSheetPrefix
        )
    ) {

      return sheet;
    }
  }


  return null;
}


/*******************************************************
 * セル取得
 *******************************************************/

function getCell(
  row,
  index,
  header
) {

  if (
    index[header] === undefined
  ) {

    return '';
  }


  const value =
    row[index[header]];


  if (
    value === null ||
    value === undefined
  ) {

    return '';
  }


  return value;
}


/*******************************************************
 * キー用文字列
 *******************************************************/

function normalizeKeyValue(value) {

  if (
    value === null ||
    value === undefined
  ) {

    return '';
  }


  if (
    value instanceof Date
  ) {

    return String(
      value.getTime()
    );
  }


  return String(value)
    .trim();
}


/*******************************************************
 * No.を振る
 *******************************************************/

function renumberApplicants() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();


  const sheet =
    ss.getSheetByName(
      CONFIG.applicantsSheet
    );


  if (!sheet) return;


  const lastRow =
    sheet.getLastRow();


  if (lastRow < 2) return;


  const numbers = [];


  for (
    let row = 2;
    row <= lastRow;
    row++
  ) {

    numbers.push([
      row - 1
    ]);
  }


  sheet
    .getRange(
      2,
      1,
      numbers.length,
      1
    )
    .setValues(numbers);
}


/*******************************************************
 * 楽器名を統一
 *******************************************************/

function normalizeInstrument(
  value
) {

  const v =
    String(value)
      .trim();


  const map = {

    'フルート': 'Fl',

    'オーボエ': 'Ob',

    'クラリネット': 'Cl',

    'ファゴット': 'Fg',

    'バスーン': 'Fg',

    'ホルン': 'Hr',

    'トランペット': 'Tp',

    'トロンボーン': 'Tb',

    'テューバ': 'Tuba',

    '打楽器': 'Perc',

    'パーカッション': 'Perc',

    '第1ヴァイオリン': '1st Vn',

    '第１ヴァイオリン': '1st Vn',

    '第2ヴァイオリン': '2nd Vn',

    '第２ヴァイオリン': '2nd Vn',

    'ヴィオラ': 'Va',

    'チェロ': 'Vc',

    'コントラバス': 'Cb'
  };


  return map[v] || v;
}


/*******************************************************
 * スプレッドシートのフォーム送信トリガー
 *
 * 新しい回答が来たときに自動実行
 *******************************************************/

function handleSpreadsheetFormSubmit(e) {

  /*
   * フォーム回答シートへの追加を待ってから同期
   */
  Utilities.sleep(1000);


  syncWithoutDialog();
}


/*******************************************************
 * ダイアログなし同期
 *******************************************************/

function syncWithoutDialog() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();


  const responseSheet =
    findResponseSheet_(ss);


  if (!responseSheet) return;


  let applicants =
    ss.getSheetByName(
      CONFIG.applicantsSheet
    );


  if (!applicants) {

    setupApplicantsSheet_(ss);

    applicants =
      ss.getSheetByName(
        CONFIG.applicantsSheet
      );
  }


  const data =
    responseSheet
      .getDataRange()
      .getValues();


  if (
    data.length <= 1
  ) {

    return;
  }


  const headers =
    data[0].map(
      value =>
        String(value).trim()
    );


  const index = {};


  headers.forEach(
    (header, i) => {

      index[header] = i;

    }
  );


  /*
   * 必須項目がない場合は終了
   */

  if (
    index['タイムスタンプ'] === undefined ||
    index['メールアドレス'] === undefined
  ) {

    return;
  }


  /*
   * 既存データ
   */

  const applicantData =
    applicants
      .getDataRange()
      .getValues();


  const existingKeys =
    new Set();


  for (
    let i = 1;
    i < applicantData.length;
    i++
  ) {

    const timestamp =
      normalizeKeyValue(
        applicantData[i][1]
      );


    const email =
      normalizeKeyValue(
        applicantData[i][2]
      );


    existingKeys.add(
      timestamp +
      '|' +
      email
    );
  }


  /*
   * 新規回答だけ追加
   */

  for (
    let r = 1;
    r < data.length;
    r++
  ) {

    const row =
      data[r];


    const timestamp =
      row[index['タイムスタンプ']];


    const email =
      row[index['メールアドレス']];


    const key =
      normalizeKeyValue(timestamp) +
      '|' +
      normalizeKeyValue(email);


    if (
      existingKeys.has(key)
    ) {

      continue;
    }


    const newRow = [

      '',

      timestamp,

      email,

      getCell(
        row,
        index,
        'お名前・呼ばれたい名前'
      ),

      getCell(
        row,
        index,
        '本名について'
      ),

      getCell(
        row,
        index,
        '学年・年代'
      ),

      getCell(
        row,
        index,
        '活動地域'
      ),

      normalizeInstrument(
        getCell(
          row,
          index,
          '楽器'
        )
      ),

      getCell(
        row,
        index,
        '希望パート'
      ),

      getCell(
        row,
        index,
        '楽器の経験年数'
      ),

      getCell(
        row,
        index,
        'オーケストラでの演奏経験'
      ),

      getCell(
        row,
        index,
        '現在所属している音楽団体'
      ),

      getCell(
        row,
        index,
        'このオーケストラに参加したいと思った理由'
      ),

      getCell(
        row,
        index,
        'どのくらい練習に参加できそうですか？'
      ),

      getCell(
        row,
        index,
        '第1回演奏会への参加について'
      ),

      getCell(
        row,
        index,
        'このオーケストラでやってみたいこと'
      ),

      getCell(
        row,
        index,
        'その他、伝えておきたいこと'
      ),

      '未対応',

      '',

      '初回連絡',

      ''
    ];


    applicants.appendRow(
      newRow
    );


    existingKeys.add(key);
  }


  renumberApplicants();

  updateDashboard();
}


/*******************************************************
 * フォーム送信トリガーを設定
 *******************************************************/

function installSpreadsheetFormTrigger() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();


  /*
   * 同じ関数の既存トリガーを削除
   */

  const triggers =
    ScriptApp.getProjectTriggers();


  triggers.forEach(
    trigger => {

      if (
        trigger.getHandlerFunction() ===
        'handleSpreadsheetFormSubmit'
      ) {

        ScriptApp.deleteTrigger(
          trigger
        );
      }

    }
  );


  /*
   * スプレッドシート側の
   * フォーム送信トリガー
   */

  ScriptApp
    .newTrigger(
      'handleSpreadsheetFormSubmit'
    )
    .forSpreadsheet(ss)
    .onFormSubmit()
    .create();


  SpreadsheetApp
    .getUi()
    .alert(
      'フォーム送信トリガーを設定しました！\n\n' +
      'これから新しいフォーム回答が送信されると、\n' +
      '自動的に「応募者一覧」に追加されます。'
    );
}


/*******************************************************
 * ダッシュボード更新
 *******************************************************/

function updateDashboard() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();


  /*
   * 活動状況シート
   */

  let status =
    ss.getSheetByName(
      CONFIG.statusSheet
    );


  if (!status) {

    setupStatusSheet_(ss);

    status =
      ss.getSheetByName(
        CONFIG.statusSheet
      );
  }


  /*
   * 楽器別集計が存在しなければ作る
   */

  let instruments =
    ss.getSheetByName(
      CONFIG.instrumentsSheet
    );


  if (!instruments) {

    setupInstrumentSheet_(ss);

  }


  /*
   * 数式再計算
   */

  SpreadsheetApp.flush();
}


/*******************************************************
 * 接続状況確認
 *******************************************************/

function checkConnection() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();


  const responseSheet =
    findResponseSheet_(ss);


  let message =
    'かながわコネクトオーケストラ\n' +
    '応募者管理システム 接続状況\n\n';


  message +=
    '現在のスプレッドシート：\n' +
    ss.getName() +
    '\n\n';


  if (responseSheet) {

    message +=
      '✅ フォーム回答シート：\n' +
      responseSheet.getName() +
      '\n\n';

  } else {

    message +=
      '❌ フォーム回答シートが見つかりません\n\n';
  }


  const applicants =
    ss.getSheetByName(
      CONFIG.applicantsSheet
    );


  if (applicants) {

    message +=
      '✅ 応募者一覧：存在します\n';

  } else {

    message +=
      '❌ 応募者一覧：ありません\n';
  }


  const triggers =
    ScriptApp.getProjectTriggers();


  const formTrigger =
    triggers.some(
      trigger =>
        trigger.getHandlerFunction() ===
        'handleSpreadsheetFormSubmit'
    );


  if (formTrigger) {

    message +=
      '✅ 自動同期トリガー：設定済み\n';

  } else {

    message +=
      '⚠️ 自動同期トリガー：未設定\n';
  }


  if (responseSheet) {

    const rows =
      responseSheet.getLastRow();


    message +=
      '\nフォーム回答件数：' +
      Math.max(rows - 1, 0) +
      '件';

  }


  SpreadsheetApp
    .getUi()
    .alert(message);
}
