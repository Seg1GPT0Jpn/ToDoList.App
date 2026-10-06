/*******************************************************
 * かながわコネクトオーケストラ
 * 応募者管理システム 完全版（v2 強化版）
 *
 * 構成
 * Googleフォーム
 *     ↓
 * フォームの回答（Googleフォームが自動で書き込むシート。読むだけで変更しない）
 *     ↓
 * 応募者一覧（団員管理の中心データ）
 *     ↓
 * 楽器別集計 / 活動状況 / ダッシュボード（自動生成）
 *     ↑
 * 募集設定（目標人数・必要人数・表記ゆれを運営が編集）
 *
 * 連絡記録 → 応募者一覧の「最終連絡日」を自動反映
 *
 * ── v1 からの主な変更 ──
 * ・No. は一度振ったら変わらない（並べ替えても連絡記録とずれない）
 * ・同期の重複防止を強化（同期履歴・ロック・同時実行対策）
 * ・手動で削除した応募者が次の同期で復活しない
 * ・楽器名の表記ゆれ（チューバ／テューバ／Tuba 等）を吸収
 * ・列の並びが変わっても見出し名で列を探す
 * ・目標人数は「募集設定」シートで変更（コードを触らない）
 * ・ダッシュボード、データ整合性チェック、重複チェック、システム診断を追加
 * ・メールアドレス等の個人情報を集計シート・ログに出さない
 *
 * ※ 既存のシート・データは削除しません。
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

  // 団員目標（「募集設定」シートを作るときの初期値）
  targetMembers: 80,

  // 演奏会開催判断ライン（同上）
  decisionMembers: 60,

  // 最低人数（同上）
  minimumMembers: 46,


  /* ---------- v2 で追加 ---------- */

  // 追加した管理用シート
  dashboardSheet: 'ダッシュボード',
  settingsSheet: '募集設定',
  checkSheet: 'データチェック',
  diagnosisSheet: 'システム診断',
  ledgerSheet: '_同期履歴',

  // 英語表示のスプレッドシートで作られた回答シート名にも対応
  extraResponseSheetPrefixes: ['Form Responses', 'Form responses'],

  // 回答シートを名前で固定したい場合だけ指定（通常は空でOK）
  responseSheetName: '',

  // 応募フォームの回答シートと判定するのに必要な一致項目数
  minFormFieldsMatched: 5,

  // 対応状況（v1 と同じ7種類。順番も同じ）
  statuses: [
    '未対応',
    '初回連絡済み',
    '返信待ち',
    '参加予定',
    '正式参加',
    '保留',
    '辞退'
  ],
  newApplicantStatus: '未対応',
  newApplicantNextAction: '初回連絡',
  plannedStatus: '参加予定',
  officialStatus: '正式参加',

  // 第1回演奏会（v1 と同じ選択肢）
  concertChoices: ['ぜひ参加したい', '検討中', '参加しない'],

  // 連絡記録
  contactMethods: ['メール', 'SNS', 'その他'],
  contactStates: ['要対応', '完了', '不要'],

  // 「募集設定」シートを作るときの初期値
  excludedStatuses: ['辞退'],
  urgentRatio: 0,
  surplusRatio: 1.5,
  followUpDays: 3,

  // 同時実行防止のロック待ち時間（ミリ秒）
  lockWaitMs: 30000,

  // フォーム送信トリガーの関数名（v1 と同じ）
  formTriggerHandler: 'handleSpreadsheetFormSubmit',

  // スクリプトプロパティのキー
  lastAutoSyncProperty: 'KCO_LAST_AUTO_SYNC'
};


/*******************************************************
 * 応募者一覧の列定義
 *
 * header : 応募者一覧の見出し（v1 と同じ21列＋同期メモ）
 * aliases: 運営が見出しを変えた場合の別名
 * form   : フォーム回答シートの質問名（先頭ほど優先）
 *
 * 列は「位置」ではなく「見出し名」で探すので、
 * 列の順番を入れ替えたり、列を追加しても壊れません。
 *******************************************************/

const APPLICANT_FIELDS = [
  { key: 'no', header: 'No.', aliases: ['No', 'NO.', '応募者No.', '応募者ID'] },
  { key: 'timestamp', header: '回答日時', form: ['タイムスタンプ', 'Timestamp'] },
  { key: 'email', header: 'メールアドレス', form: ['メールアドレス', 'Email Address', 'Email address', 'メール アドレス'] },
  { key: 'name', header: 'お名前・呼ばれたい名前', aliases: ['氏名', 'お名前', '名前'], form: ['お名前・呼ばれたい名前', 'お名前', '氏名', '呼ばれたい名前'] },
  { key: 'nickname', header: 'ニックネーム', aliases: ['呼び名'], form: ['ニックネーム', '呼び名'], extra: true },
  { key: 'realName', header: '本名について', form: ['本名について'], optional: true },
  { key: 'age', header: '学年・年代', aliases: ['年代・学年', '年代', '学年'], form: ['学年・年代', '年代・学年', '年代'] },
  { key: 'area', header: '活動地域', aliases: ['地域'], form: ['活動地域', '地域'] },
  { key: 'instrument', header: '楽器', form: ['楽器'] },
  { key: 'part', header: '希望パート', form: ['希望パート'] },
  { key: 'years', header: '楽器の経験年数', aliases: ['経験年数'], form: ['楽器の経験年数', '経験年数'] },
  { key: 'orchExp', header: 'オーケストラでの演奏経験', aliases: ['オーケストラ経験'], form: ['オーケストラでの演奏経験', 'オーケストラ経験'] },
  { key: 'affiliation', header: '現在所属している音楽団体', aliases: ['現在の所属', '所属'], form: ['現在所属している音楽団体', '現在の所属'] },
  { key: 'reason', header: '参加したいと思った理由', aliases: ['参加理由'], form: ['このオーケストラに参加したいと思った理由', '参加理由'] },
  { key: 'practice', header: '練習参加可能性', aliases: ['参加可能性'], form: ['どのくらい練習に参加できそうですか？', '参加可能性'] },
  { key: 'concert', header: '第1回演奏会', form: ['第1回演奏会への参加について', '第1回演奏会'] },
  { key: 'wish', header: 'やってみたいこと', aliases: ['やりたいこと'], form: ['このオーケストラでやってみたいこと', 'このオーケストラでやりたいこと', 'やってみたいこと', 'やりたいこと'] },
  { key: 'other', header: 'その他', form: ['その他、伝えておきたいこと'], optional: true },
  { key: 'status', header: '対応状況', aliases: ['ステータス'] },
  { key: 'lastContact', header: '最終連絡日' },
  { key: 'nextAction', header: '次の対応' },
  { key: 'note', header: '備考' },
  { key: 'syncMemo', header: '同期メモ', added: true }
];


/*******************************************************
 * 連絡記録の列定義（v1 の9列＋2列を末尾に追加）
 *******************************************************/

const CONTACT_FIELDS = [
  { key: 'date', header: '日付' },
  { key: 'no', header: '応募者No.', aliases: ['No.', '応募者ID'] },
  { key: 'name', header: '氏名' },
  { key: 'method', header: '連絡方法' },
  { key: 'content', header: '内容' },
  { key: 'reply', header: '相手からの返信' },
  { key: 'nextDate', header: '次回対応日' },
  { key: 'staff', header: '担当', aliases: ['担当者'] },
  { key: 'note', header: '備考' },
  { key: 'nextAction', header: '次回対応内容', added: true },
  { key: 'state', header: '対応状況', added: true }
];


/*******************************************************
 * 楽器カタログ
 *
 * [コード, 楽器名, パート, 目標人数, 最低人数, 表記ゆれ]
 *
 * ・先頭14行は v1 の楽器別集計と同じコード・人数です。
 * ・ピッコロ等は「勝手に統合しない」ため別コードにし、
 *   パート（Fl 等）でまとめて見られるようにしています。
 *   目標人数は空欄（＝目標未設定）なので、必要なら「募集設定」で入力してください。
 * ・表記ゆれは全角/半角・大文字/小文字・空白・長音・ヴ/ブ・小書き文字を
 *   吸収してから照合します（例：ﾁｭｰﾊﾞ／チュ－バ／TUBA も一致）。
 *******************************************************/

const INSTRUMENT_CATALOG = [
  ['Fl', 'フルート', 'Fl', 4, 2, ['フルート', 'Flute', 'Fl', 'フルート／ピッコロ', 'フルート・ピッコロ', 'Fl/Picc', 'Fl/Pic']],
  ['Ob', 'オーボエ', 'Ob', 2, 1, ['オーボエ', 'Oboe', 'Ob']],
  ['Cl', 'クラリネット', 'Cl', 5, 3, ['クラリネット', 'Clarinet', 'Cl']],
  ['Fg', 'ファゴット', 'Fg', 2, 1, ['ファゴット', 'バスーン', 'Fagott', 'Fagotto', 'Bassoon', 'Fg', 'Bsn']],
  ['Hr', 'ホルン', 'Hr', 6, 4, ['ホルン', 'フレンチホルン', 'Horn', 'French Horn', 'Hr', 'Hn']],
  ['Tp', 'トランペット', 'Tp', 4, 2, ['トランペット', 'Trumpet', 'Tp', 'Trp']],
  ['Tb', 'トロンボーン', 'Tb', 4, 3, ['トロンボーン', 'Trombone', 'Tb', 'Trb', 'Tbn']],
  ['Tuba', 'テューバ', 'Tuba', 1, 1, ['テューバ', 'チューバ', 'Tuba', 'Tu']],
  ['Perc', '打楽器', 'Perc', 4, 3, ['打楽器', 'パーカッション', 'Percussion', 'Perc']],
  ['1st Vn', '1st ヴァイオリン', 'Vn', 10, 7, ['第1ヴァイオリン', '第一ヴァイオリン', '1stヴァイオリン', 'ファーストヴァイオリン', 'ヴァイオリン1st', 'ヴァイオリン1', '1st Violin', 'First Violin', 'Violin 1', 'Violin I', '1st Vn', 'Vn1']],
  ['2nd Vn', '2nd ヴァイオリン', 'Vn', 10, 7, ['第2ヴァイオリン', '第二ヴァイオリン', '2ndヴァイオリン', 'セカンドヴァイオリン', 'ヴァイオリン2nd', 'ヴァイオリン2', '2nd Violin', 'Second Violin', 'Violin 2', 'Violin II', '2nd Vn', 'Vn2']],
  ['Va', 'ヴィオラ', 'Va', 10, 5, ['ヴィオラ', 'Viola', 'Va', 'Vla']],
  ['Vc', 'チェロ', 'Vc', 10, 5, ['チェロ', 'Cello', 'Violoncello', 'Vc', 'Vlc']],
  ['Cb', 'コントラバス', 'Cb', 4, 2, ['コントラバス', '弦バス', 'ストリングベース', 'ダブルベース', 'Contrabass', 'Double Bass', 'String Bass', 'Cb']],

  // ここから下は v1 に無かった楽器（目標人数は未設定）
  ['Picc', 'ピッコロ', 'Fl', null, null, ['ピッコロ', 'Piccolo', 'Picc', 'Pic']],
  ['E.H.', 'イングリッシュホルン', 'Ob', null, null, ['イングリッシュホルン', 'コールアングレ', 'English Horn', 'Cor Anglais', 'E.H.', 'E.Hr']],
  ['B.Cl', 'バスクラリネット', 'Cl', null, null, ['バスクラリネット', 'バスクラ', 'Bass Clarinet', 'B.Cl']],
  ['C.Fg', 'コントラファゴット', 'Fg', null, null, ['コントラファゴット', 'コントラバスーン', 'Contrabassoon', 'Contrafagotto', 'C.Fg', 'Kfg']],
  ['B.Tb', 'バストロンボーン', 'Tb', null, null, ['バストロンボーン', 'Bass Trombone', 'B.Tb']],
  ['Timp', 'ティンパニ', 'Perc', null, null, ['ティンパニ', 'ティンパニー', 'Timpani', 'Timp', 'Pk']],
  ['Vn', 'ヴァイオリン（1st/2nd未定）', 'Vn', null, null, ['ヴァイオリン', 'Violin', 'Vn', 'Vl', 'Vln']],
  ['Hp', 'ハープ', 'Hp', null, null, ['ハープ', 'Harp', 'Hp']],
  ['Pf', 'ピアノ・鍵盤', 'Pf', null, null, ['ピアノ', '鍵盤', 'キーボード', 'チェレスタ', 'Piano', 'Keyboard', 'Celesta', 'Pf']]
];

// パートの表示名
const PART_LABELS_ = {
  Fl: 'フルート', Ob: 'オーボエ', Cl: 'クラリネット', Fg: 'ファゴット',
  Hr: 'ホルン', Tp: 'トランペット', Tb: 'トロンボーン', Tuba: 'テューバ',
  Perc: '打楽器', Vn: 'ヴァイオリン', Va: 'ヴィオラ', Vc: 'チェロ', Cb: 'コントラバス',
  Hp: 'ハープ', Pf: 'ピアノ・鍵盤'
};

// 応募者一覧に必ず必要な列（見つからないとエラー）
const ESSENTIAL_APPLICANT_KEYS_ = ['no', 'timestamp', 'name', 'instrument', 'status'];

const CODE_UNKNOWN_ = '（未分類）';
const CODE_BLANK_ = '（楽器未回答）';
const STATUS_BLANK_ = '（空欄）';
const DUP_PREFIX_ = '⚠重複候補: ';
const MISSING_PREFIX_ = '⚠未取得: ';

const RECRUIT_ = {
  URGENT: '急募',
  BELOW_MIN: '募集中（最低未達）',
  OPEN: '募集中',
  FILLED: '充足',
  SURPLUS: '充足／調整',
  NONE: '目標未設定'
};

const RECRUIT_COLORS_ = {
  '急募': '#f4cccc',
  '募集中（最低未達）': '#fce5cd',
  '募集中': '#fff2cc',
  '充足': '#d9ead3',
  '充足／調整': '#cfe2f3',
  '目標未設定': '#eeeeee'
};

const COLOR_HEADER_ = '#d9d9d9';
const COLOR_SECTION_ = '#c9daf8';
const COLOR_PLAIN_ = '#ffffff';

const DASHBOARD_TITLE_ = 'かながわコネクトオーケストラ 団員募集ダッシュボード';
const SETTINGS_TITLE_ = '募集設定（運営側で自由に変更できます）';
const CHECK_TITLE_ = 'データ整合性チェック結果';
const DIAGNOSIS_TITLE_ = 'システム診断結果';
const LEDGER_HEADERS_ = ['回答キー（SHA-256。個人情報は含みません）', '応募者No.', '取込日時', '取込元シート'];
const PARTS_TABLE_HEADER_ = ['楽器コード', '楽器名', 'パート', '目標人数', '最低人数', '追加の表記ゆれ（カンマ区切り）'];

// 「募集設定」シートの項目
const SETTINGS_ITEMS_ = [
  { key: 'targetMembers', label: '団員目標', type: 'number', def: () => CONFIG.targetMembers, desc: '人' },
  { key: 'decisionMembers', label: '演奏会開催判断ライン', type: 'number', def: () => CONFIG.decisionMembers, desc: '人' },
  { key: 'minimumMembers', label: '最低人数', type: 'number', def: () => CONFIG.minimumMembers, desc: '人（最低実施人数）' },
  { key: 'excludedStatuses', label: '集計から除外するステータス', type: 'list', def: () => CONFIG.excludedStatuses.join(', '), desc: 'カンマ区切り。ここに書いた対応状況の人は「有効応募者」に数えません' },
  { key: 'urgentRatio', label: '急募と判定する割合（最低人数に対して）', type: 'number', def: () => CONFIG.urgentRatio, desc: '0 = 0人のときだけ急募。0.5 = 最低人数の半分未満も急募' },
  { key: 'surplusRatio', label: '充足／調整と判定する倍率（目標人数に対して）', type: 'number', def: () => CONFIG.surplusRatio, desc: '例：1.5 = 目標人数の1.5倍以上で「充足／調整」' },
  { key: 'followUpDays', label: '未対応フォローの目安（日）', type: 'number', def: () => CONFIG.followUpDays, desc: '回答からこの日数が過ぎても「未対応」の人をダッシュボードに表示' },
  { key: 'autoUpdateOnEdit', label: '編集時に集計を自動更新', type: 'bool', def: () => 'はい', desc: 'はい／いいえ。「はい」なら対応状況などを書き換えた時に集計が自動で更新されます' }
];


/*******************************************************
 * スプレッドシートを開いたときのメニュー
 *
 * ①〜⑤ は v1 と同じ。⑥以降を追加。
 *******************************************************/

function onOpen() {

  const ui = SpreadsheetApp.getUi();

  ui
    .createMenu('🎻 オーケストラ管理')
    .addItem('① 初期セットアップ', 'setupOrchestraManagement')
    .addItem('② 既存回答を同期', 'syncExistingResponses')
    .addItem('③ フォーム送信トリガー設定', 'installSpreadsheetFormTrigger')
    .addItem('④ ダッシュボード更新', 'updateDashboard')
    .addSeparator()
    .addItem('⑤ 接続状況を確認', 'checkConnection')
    .addSeparator()
    .addItem('⑥ 楽器別集計を更新', 'updateInstrumentSummary')
    .addItem('⑦ 応募者管理を更新', 'updateApplicantManagement')
    .addItem('⑧ データ整合性チェック', 'runIntegrityCheck')
    .addItem('⑨ 重複チェック', 'runDuplicateCheck')
    .addItem('⑩ システム診断', 'runSystemDiagnosis')
    .addSeparator()
    .addSubMenu(
      ui.createMenu('🛠 メンテナンス')
        .addItem('楽器名の表記を統一（応募者一覧の楽器列）', 'normalizeApplicantInstruments')
        .addItem('セルフテスト（本番データは変更しません）', 'runSelfTests')
    )
    .addToUi();
}


/*******************************************************
 * 編集時の自動更新（シンプルトリガー）
 *
 * ・応募者一覧の「対応状況」「楽器」などを変えたら集計を更新
 * ・連絡記録に記入したら氏名の補完と最終連絡日を更新
 * ・「募集設定」で「編集時に集計を自動更新」を「いいえ」にすると止まります
 *
 * ※ スクリプトによる書き込みでは発火しないので無限ループしません。
 *******************************************************/

function onEdit(e) {

  try {

    if (!e || !e.range) return;

    const sheet = e.range.getSheet();
    const name = sheet.getName();
    const ss = e.source || SpreadsheetApp.getActiveSpreadsheet();

    const settingsSheet = findOwnedSheet_(ss, CONFIG.settingsSheet, SETTINGS_TITLE_);
    const isSettings = settingsSheet && settingsSheet.getName() === name;

    if (name !== CONFIG.applicantsSheet && name !== CONFIG.contactsSheet && !isSettings) return;
    if (!isSettings && e.range.getLastRow() < 2) return;

    const settings = loadSettings_(ss);
    if (!settings.autoUpdateOnEdit) return;

    if (name === CONFIG.applicantsSheet) {
      // 集計に関係する列だけで反応する（備考などの編集では何もしない）
      const headers = sheet.getRange(1, 1, 1, Math.max(sheet.getLastColumn(), 1)).getValues()[0].map(toStr_);
      const res = resolveColumns_(headers, applicantFieldDefs_(), false);
      const watched = ['no', 'timestamp', 'email', 'instrument', 'status', 'concert'];
      const first = e.range.getColumn() - 1;
      const last = e.range.getLastColumn() - 1;
      const hit = watched.some(k => res.map[k] !== undefined && res.map[k] >= first && res.map[k] <= last);
      if (!hit) return;
    }

    if (name === CONFIG.contactsSheet) {
      syncContactsToApplicants_(ss);
    }

    updateDashboard();

  } catch (err) {
    console.error('onEdit で集計を更新できませんでした: ' + err.message);
  }
}


/*******************************************************
 * 初期セットアップ
 *
 * 何度実行しても安全（既存データは消さない）。
 *******************************************************/

function setupOrchestraManagement() {

  const ss =
    SpreadsheetApp.getActiveSpreadsheet();

  setupApplicantsSheet_(ss);

  ensureSettingsSheet_(ss);

  setupInstrumentSheet_(ss);

  setupStatusSheet_(ss);

  setupContactSheet_(ss);

  const result = syncCore_({ interactive: true });

  if (!result.ok) {
    updateDashboard();
  }

  let message =
    'セットアップ完了！\n\n' +
    '「応募者一覧」「楽器別集計」「活動状況」「連絡記録」を作成・確認しました。\n' +
    '「募集設定」「ダッシュボード」も用意しています。\n\n';

  message += describeSyncResult_(result);

  message +=
    '\n\n目標人数・必要人数は「募集設定」シートで変更できます。' +
    '\n既存のデータは削除していません。';

  alert_(message);
}


/*******************************************************
 * 応募者一覧を作成
 *
 * ・見出しが空なら作る（v1 と同じ）
 * ・見出しがあれば触らず、足りない「同期メモ」列だけ末尾に追加
 *******************************************************/

function setupApplicantsSheet_(ss) {

  let sheet =
    ss.getSheetByName(CONFIG.applicantsSheet);

  if (!sheet) {

    sheet =
      ss.insertSheet(CONFIG.applicantsSheet);
  }

  ensureApplicantColumns_(sheet);

  /*
   * 見出しを固定
   */
  sheet.setFrozenRows(1);

  const lastCol = Math.max(sheet.getLastColumn(), 1);

  /*
   * フィルター（既にあれば触らない）
   */
  if (!sheet.getFilter()) {

    sheet
      .getRange(1, 1, Math.max(sheet.getLastRow(), 2), lastCol)
      .createFilter();

  } else {

    expandFilterToData_(sheet);
  }

  const headers = sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(toStr_);
  const map = resolveColumns_(headers, applicantFieldDefs_(), false).map;
  const rows = Math.max(sheet.getMaxRows() - 1, 1);

  /*
   * 対応状況
   */
  applyStatusValidation_(sheet, map, 2, rows);

  /*
   * 第1回演奏会（v1 と同じ選択肢。不一致は警告表示のみで入力は拒否しない）
   */
  if (map.concert !== undefined) {

    const concertRule =
      SpreadsheetApp
        .newDataValidation()
        .requireValueInList(CONFIG.concertChoices, true)
        .build();

    sheet
      .getRange(2, map.concert + 1, rows, 1)
      .setDataValidation(concertRule);
  }

  /*
   * 列幅
   */
  sheet.autoResizeColumns(1, lastCol);

  return sheet;
}


/*
 * 応募者一覧の見出しを確認し、無ければ作る・足りなければ末尾に追加
 */
function ensureApplicantColumns_(sheet) {

  const headers = APPLICANT_FIELDS.filter(f => !f.extra).map(f => f.header);
  const lastCol = sheet.getLastColumn();

  if (lastCol === 0) {
    ensureCols_(sheet, headers.length);
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    return { created: true, appended: [] };
  }

  const current = sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(toStr_);

  if (current.every(v => v === '')) {
    ensureCols_(sheet, headers.length);
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    return { created: true, appended: [] };
  }

  const res = resolveColumns_(current, applicantFieldDefs_(), false);
  const appended = [];

  // 自動で追加するのはシステム用の列（同期メモ）だけ。
  // 既存の列が見つからない場合は勝手に作らず、システム診断で知らせる。
  APPLICANT_FIELDS.forEach(f => {
    if (f.added && res.map[f.key] === undefined) appended.push(f.header);
  });

  if (appended.length) {
    ensureCols_(sheet, lastCol + appended.length);
    sheet.getRange(1, lastCol + 1, 1, appended.length).setValues([appended]);
    expandFilterToData_(sheet);
  }

  return { created: false, appended };
}


/*
 * フィルタの範囲をデータ全体に広げる（絞り込み条件はそのまま）
 *
 * v1 のフィルタは A〜U列・作成時の行数だけが対象。
 * 範囲外の列（同期メモ）があると、フィルタで並べ替えたときにその列だけ動かず行とずれるため。
 */
function expandFilterToData_(sheet) {

  try {

    const filter = sheet.getFilter();

    if (!filter) return false;

    const range = filter.getRange();
    const lastRow = Math.max(sheet.getLastRow(), range.getLastRow());
    const lastCol = Math.max(sheet.getLastColumn(), range.getLastColumn());

    if (range.getLastRow() >= lastRow && range.getLastColumn() >= lastCol) return false;

    const criteria = [];

    for (let c = range.getColumn(); c <= range.getLastColumn(); c++) {
      const cr = filter.getColumnFilterCriteria(c);
      if (cr) criteria.push([c, cr]);
    }

    filter.remove();

    const next = sheet
      .getRange(range.getRow(), range.getColumn(), lastRow - range.getRow() + 1, lastCol - range.getColumn() + 1)
      .createFilter();

    criteria.forEach(x => next.setColumnFilterCriteria(x[0], x[1]));

    return true;

  } catch (e) {
    console.warn('フィルタの範囲を広げられませんでした: ' + e.message);
    return false;
  }
}


/*
 * 対応状況のプルダウン（v1 と同じ7種類）
 */
function applyStatusValidation_(sheet, map, startRow, numRows) {

  if (map.status === undefined || numRows <= 0) return;

  const statusRule =
    SpreadsheetApp
      .newDataValidation()
      .requireValueInList(CONFIG.statuses, true)
      .build();

  sheet
    .getRange(startRow, map.status + 1, numRows, 1)
    .setDataValidation(statusRule);
}


/*******************************************************
 * 楽器別集計
 *
 * v1 は毎回 sheet.clear() して数式を入れ直していたため、
 * 運営が変えた目標人数が消えていた。
 * v2 では目標人数は「募集設定」に保存し、このシートは自動生成する。
 * A〜G列の意味（楽器／目標人数／最低人数／応募者数／参加予定／正式参加／不足数）は v1 と同じ。
 *******************************************************/

function setupInstrumentSheet_(ss) {

  ensureSettingsSheet_(ss);

  writeInstrumentSheet_(ss, buildContext_(ss));
}


/*******************************************************
 * 活動状況
 *
 * A1:B9 の項目は v1 と同じ並び（B9 の判定ずれは修正）。
 *******************************************************/

function setupStatusSheet_(ss) {

  ensureSettingsSheet_(ss);

  writeStatusSheet_(ss, buildContext_(ss));
}


/*******************************************************
 * 連絡記録
 *
 * v1 の9列はそのまま。「次回対応内容」「対応状況」を末尾に追加。
 *******************************************************/

function setupContactSheet_(ss) {

  let sheet =
    ss.getSheetByName(CONFIG.contactsSheet);

  if (!sheet) {

    sheet =
      ss.insertSheet(CONFIG.contactsSheet);
  }

  const headers = CONTACT_FIELDS.map(f => f.header);
  const lastCol = sheet.getLastColumn();

  if (sheet.getLastRow() === 0 || lastCol === 0) {

    ensureCols_(sheet, headers.length);
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);

  } else {

    const current = sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(toStr_);
    const res = resolveColumns_(current, contactFieldDefs_(), false);
    const appended = CONTACT_FIELDS
      .filter(f => f.added && res.map[f.key] === undefined)
      .map(f => f.header);

    if (appended.length) {
      ensureCols_(sheet, lastCol + appended.length);
      sheet.getRange(1, lastCol + 1, 1, appended.length).setValues([appended]);
    }
  }

  const finalCols = Math.max(sheet.getLastColumn(), 1);
  const current = sheet.getRange(1, 1, 1, finalCols).getValues()[0].map(toStr_);
  const map = resolveColumns_(current, contactFieldDefs_(), false).map;
  const rows = Math.max(sheet.getMaxRows() - 1, 1);

  if (map.method !== undefined) {

    const contactRule =
      SpreadsheetApp
        .newDataValidation()
        .requireValueInList(CONFIG.contactMethods, true)
        .build();

    sheet.getRange(2, map.method + 1, rows, 1).setDataValidation(contactRule);
  }

  if (map.state !== undefined) {

    const stateRule =
      SpreadsheetApp
        .newDataValidation()
        .requireValueInList(CONFIG.contactStates, true)
        .build();

    sheet.getRange(2, map.state + 1, rows, 1).setDataValidation(stateRule);
  }

  sheet.setFrozenRows(1);

  sheet.autoResizeColumns(1, finalCols);
}


/*******************************************************
 * 既存フォーム回答を同期（メニュー②）
 *
 * 重要：
 * Googleフォームそのものには接続しない。
 * 「フォームの回答」シートを読むだけで、回答シートは変更しない。
 *******************************************************/

function syncExistingResponses() {

  const result = syncCore_({ interactive: true });

  if (result.busy || result.cancelled || result.error) {
    alert_(result.message);
    return;
  }

  if (result.noResponseSheet) {
    alert_(
      '「フォームの回答」で始まるシートが見つかりません。\n\n' +
      'Googleフォームの回答先スプレッドシートを確認してください。' +
      (result.message ? '\n\n' + result.message : '')
    );
    return;
  }

  if (result.totalResponses === 0) {
    alert_('フォーム回答はまだありません。');
    return;
  }

  alert_(
    '同期完了！\n\n' +
    describeSyncResult_(result) +
    '\n\n「応募者一覧」を確認してください。'
  );
}


/*******************************************************
 * ダイアログなし同期（トリガー・他の関数から呼ぶ）
 *******************************************************/

function syncWithoutDialog() {

  return syncCore_({ interactive: false });
}


/*******************************************************
 * 同期の本体
 *
 * 安全のための仕組み：
 * 1. LockService で同時実行を防ぐ（トリガーが2本あっても二重登録しない）
 * 2. 「回答日時＋メールアドレス」（v1 と同じキー）で既存行と照合
 * 3. 取り込んだ回答は _同期履歴 シートにハッシュで記録
 *    → 応募者一覧から手動で消した行が復活しない
 * 4. 既存の行は一切上書きしない（新しい回答は新しい行として追加）
 * 5. 列は見出し名で探す（列の並び替え・追加に強い）
 *******************************************************/

function syncCore_(options) {

  const interactive = !!(options && options.interactive);
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  const result = {
    ok: false,
    added: 0,
    addedNos: [],
    totalResponses: 0,
    backfilled: 0,
    skippedNoTimestamp: 0,
    duplicateCandidates: 0,
    ledgerOnly: 0,
    sheets: [],
    missingFields: [],
    message: ''
  };

  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    result.busy = true;
    result.message = '他の同期処理が実行中のため、今回は同期しませんでした。\n少し待ってから再実行してください（回答は次の同期で取り込まれます）。';
    return result;
  }

  try {

    const responseSheets = findResponseSheets_(ss);

    if (!responseSheets.length) {
      result.noResponseSheet = true;
      return result;
    }

    let applicants = ss.getSheetByName(CONFIG.applicantsSheet);

    if (!applicants) {
      setupApplicantsSheet_(ss);
      applicants = ss.getSheetByName(CONFIG.applicantsSheet);
    } else {
      ensureApplicantColumns_(applicants);
    }

    const app = readApplicants_(applicants);

    if (app.map.timestamp === undefined) {
      result.error = true;
      result.message = '「応募者一覧」に「回答日時」列が見つからないため同期できません。\n見出し名を確認してください（⑩ システム診断 で確認できます）。';
      return result;
    }

    const settings = loadSettings_(ss);
    const index = buildInstrumentIndex_(settings);
    const ledger = readLedger_(ss, true);
    const plan = planSync_(responseSheets, app, ledger.hashes);

    result.sheets = plan.sheets;
    result.totalResponses = plan.totalResponses;
    result.skippedNoTimestamp = plan.skippedNoTimestamp;
    result.ledgerOnly = plan.ledgerOnly;

    const usable = plan.sheets.filter(s => s.used);

    if (!usable.length) {
      result.noResponseSheet = true;
      result.message = plan.sheets.map(s => '・' + s.name + '：' + s.reason).join('\n');
      return result;
    }

    // 質問名が変わって見つからない項目
    const missing = [];
    usable.forEach(s => s.missing.forEach(k => {
      const label = fieldLabel_(k);
      if (missing.indexOf(label) < 0) missing.push(label);
    }));
    result.missingFields = missing;

    if (interactive && missing.length && plan.newItems.length) {
      const ok = confirm_(
        'フォームの質問が見つかりません',
        '次の項目がフォーム回答シートに見つかりません（質問名が変更された可能性があります）。\n\n' +
        missing.join('\n') +
        '\n\n続行すると、この項目は空欄のまま追加され、「同期メモ」に記録されます。\n続行しますか？'
      );
      if (!ok) {
        result.cancelled = true;
        result.message = '同期を中止しました。応募者一覧は変更していません。';
        return result;
      }
    }

    // 新しい行を作る
    let nextNo = maxApplicantNo_(app) + 1;
    const now = new Date();
    const firstNoByEmail = new Map();

    app.records
      .slice()
      .sort(compareByNo_)
      .forEach(r => {
        if (r.emailKey && !firstNoByEmail.has(r.emailKey)) firstNoByEmail.set(r.emailKey, r.no);
      });

    const newRows = [];
    const ledgerRows = [];

    plan.newItems.forEach(item => {

      const no = nextNo++;
      const memo = [];

      if (item.emailKey) {
        if (firstNoByEmail.has(item.emailKey)) {
          memo.push(DUP_PREFIX_ + 'No.' + firstNoByEmail.get(item.emailKey) + ' と同じメールアドレス（集計対象外）');
          result.duplicateCandidates++;
        } else {
          firstNoByEmail.set(item.emailKey, no);
        }
      }

      if (item.missingLabels.length) {
        memo.push(MISSING_PREFIX_ + item.missingLabels.join('・'));
      }

      newRows.push(buildApplicantRow_(app, item, no, index, memo.join(' / ')));
      ledgerRows.push([item.hash, no, now, item.sheetName]);
      result.addedNos.push(no);
    });

    plan.backfill.forEach(b => {
      ledgerRows.push([b.hash, b.no, now, b.sheetName + '（既存行と照合）']);
    });

    if (newRows.length) {
      const start = applicants.getLastRow() + 1;
      ensureRows_(applicants, start + newRows.length - 1);
      applicants
        .getRange(start, 1, newRows.length, app.headers.length)
        .setValues(newRows);
      applyStatusValidation_(applicants, app.map, start, newRows.length);
      expandFilterToData_(applicants);
    }

    appendLedger_(ledger.sheet, ledgerRows);

    result.added = newRows.length;
    result.backfilled = plan.backfill.length;

    // No. が空欄の行（手入力など）にだけ番号を振る（既存の No. は変えない）
    renumberApplicants();

    // 重複候補のメモを更新（既存側の行にも印を付ける）
    if (result.duplicateCandidates) {
      refreshDuplicateMemos_(applicants, readApplicants_(applicants));
    }

    updateDashboard();

    result.ok = true;
    return result;

  } finally {
    lock.releaseLock();
  }
}


/*
 * フォーム回答を照合して「新規」「既存」「取込済み」に分ける（書き込みはしない）
 * 同期とデータ整合性チェックの両方で使う。
 */
function planSync_(responseSheets, app, ledgerHashes) {

  const strict = new Map();
  const loose = new Map();

  app.records.forEach(r => {
    strict.set(normalizeKeyValue(r.timestamp) + '|' + normalizeKeyValue(r.email), r);
    loose.set(looseKey_(r.timestamp, r.email), r);
  });

  const plan = {
    sheets: [],
    newItems: [],
    backfill: [],
    totalResponses: 0,
    skippedNoTimestamp: 0,
    ledgerOnly: 0,
    matchedRows: new Set()
  };

  const seen = new Set();

  responseSheets.forEach(sheet => {

    const name = sheet.getName();
    const lastRow = sheet.getLastRow();
    const lastCol = sheet.getLastColumn();
    const info = { name, linked: !!formUrlOf_(sheet), rows: Math.max(lastRow - 1, 0), map: {}, missing: [], headers: [], used: false, reason: '' };

    plan.sheets.push(info);

    if (lastRow < 1 || lastCol < 1) {
      info.reason = '空のシートです';
      return;
    }

    const values = sheet.getRange(1, 1, lastRow, lastCol).getValues();
    const headers = values[0].map(toStr_);
    const res = resolveColumns_(headers, formFieldDefs_(), true);

    info.map = res.map;
    // 応募者一覧に列が無い項目（本番に無い「本名について」等）は、取れなくても問題にしない
    info.missing = res.missing.filter(k => {
      const field = APPLICANT_FIELDS.find(f => f.key === k) || {};
      return !field.extra && (app.map[k] !== undefined || !app.headers.length);
    });
    info.headers = headers;

    if (res.map.timestamp === undefined) {
      info.reason = '「タイムスタンプ」列がありません';
      return;
    }

    const matchedCount = Object.keys(res.map).length;

    if ((res.map.name === undefined && res.map.instrument === undefined) || matchedCount < CONFIG.minFormFieldsMatched) {
      info.reason = '応募フォームの回答シートと判定できません（質問名の一致が少ないため対象外にしました）';
      return;
    }

    info.used = true;

    const missingLabels = info.missing.map(fieldLabel_);

    for (let i = 1; i < values.length; i++) {

      const row = values[i];
      const timestamp = row[res.map.timestamp];

      if (isBlank_(timestamp)) {
        if (row.some(v => !isBlank_(v))) plan.skippedNoTimestamp++;
        continue;
      }

      plan.totalResponses++;

      const email = res.map.email === undefined ? '' : row[res.map.email];
      const key = normalizeKeyValue(timestamp) + '|' + normalizeKeyValue(email);
      const hash = hashKey_(key);
      const match = strict.get(key) || loose.get(looseKey_(timestamp, email));

      if (match) plan.matchedRows.add(match.row);

      if (seen.has(hash)) continue;
      seen.add(hash);

      if (ledgerHashes.has(hash)) {
        if (!match) plan.ledgerOnly++;
        continue;
      }

      if (match) {
        plan.backfill.push({ hash, no: match.no, sheetName: name });
        continue;
      }

      plan.newItems.push({
        hash,
        values: row,
        map: res.map,
        sheetName: name,
        responseRow: i + 1,
        timestamp,
        email,
        emailKey: emailKey_(email),
        missingLabels
      });
    }
  });

  return plan;
}


/*
 * フォーム回答1件から応募者一覧の1行を作る（応募者一覧の実際の列順に合わせる）
 */
function buildApplicantRow_(app, item, no, index, memo) {

  const width = app.headers.length;
  const out = new Array(width).fill('');

  const put = (key, value) => {
    const c = app.map[key];
    if (c !== undefined && c < width) out[c] = value;
  };

  put('no', no);

  APPLICANT_FIELDS.forEach(f => {

    if (!f.form) return;

    const c = item.map[f.key];
    let value = c === undefined ? '' : item.values[c];

    if (value === null || value === undefined) value = '';

    if (f.key === 'instrument') value = normalizeInstrument(value, index);

    put(f.key, sanitizeForSheet_(value));
  });

  put('status', CONFIG.newApplicantStatus);
  put('nextAction', CONFIG.newApplicantNextAction);
  put('syncMemo', memo);

  return out;
}


/*
 * 同期結果の説明文（個人情報は含めない）
 */
function describeSyncResult_(r) {

  if (r.busy || r.cancelled || r.error) return r.message;

  if (r.noResponseSheet) {
    return '⚠️ フォーム回答シートが見つからないため、同期はしていません。' + (r.message ? '\n' + r.message : '');
  }

  let text =
    'フォーム回答総数：' + r.totalResponses + '件\n' +
    '今回追加：' + r.added + '件';

  if (r.addedNos.length) {
    text += '（' + formatNoList_(r.addedNos) + '）';
  }

  if (r.duplicateCandidates) {
    text += '\n⚠️ 既に応募のあるメールアドレスからの回答：' + r.duplicateCandidates + '件（「同期メモ」に印を付けました。⑨ 重複チェックで確認できます）';
  }

  if (r.missingFields.length) {
    text += '\n⚠️ フォームに見つからない質問：' + r.missingFields.join('・');
  }

  if (r.skippedNoTimestamp) {
    text += '\n※ タイムスタンプが空の行を ' + r.skippedNoTimestamp + '件 スキップしました';
  }

  if (r.ledgerOnly) {
    text += '\n※ 応募者一覧から削除済みの回答 ' + r.ledgerOnly + '件 は再追加していません';
  }

  return text;
}


/*******************************************************
 * フォーム回答シートを探す
 *
 * v1：名前が「フォームの回答」で始まる最初のシート
 * v2：フォームと連携中のシートを優先して返す
 *     （フォームを再リンクして「フォームの回答 2」ができた場合に古い方を読まない）
 *******************************************************/

function findResponseSheet_(ss) {

  const sheets = findResponseSheets_(ss);

  return sheets.length ? sheets[0] : null;
}


/*
 * 回答シートの候補をすべて返す（連携中のシートが先頭）
 */
function findResponseSheets_(ss) {

  if (CONFIG.responseSheetName) {
    const fixed = ss.getSheetByName(CONFIG.responseSheetName);
    return fixed ? [fixed] : [];
  }

  const prefixes = [CONFIG.responseSheetPrefix].concat(CONFIG.extraResponseSheetPrefixes || []);

  return ss.getSheets()
    .filter(sheet => prefixes.some(p => sheet.getName().indexOf(p) === 0))
    .map((sheet, i) => ({ sheet, i, linked: formUrlOf_(sheet) ? 1 : 0 }))
    .sort((a, b) => (b.linked - a.linked) || (a.i - b.i))
    .map(x => x.sheet);
}


function formUrlOf_(sheet) {

  try {
    return sheet.getFormUrl() || '';
  } catch (e) {
    return '';
  }
}


/*******************************************************
 * セル取得（v1 の関数。互換のため残しています）
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
 * キー用文字列（v1 と同じ。重複判定キーの互換性のため変更しない）
 *******************************************************/

function normalizeKeyValue(value) {

  if (
    value === null ||
    value === undefined
  ) {

    return '';
  }


  if (
    isDate_(value)
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
 *
 * v1：行番号で毎回振り直し → 並べ替えると連絡記録の「応募者No.」とずれた
 * v2：空欄の行にだけ「最大No.＋1」を振る。既存の No. は変えない。
 *     （v1 で振られた番号はそのまま引き継がれます）
 *******************************************************/

function renumberApplicants() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();

  const sheet =
    ss.getSheetByName(
      CONFIG.applicantsSheet
    );

  if (!sheet) return 0;

  const app = readApplicants_(sheet);

  if (app.map.no === undefined || !app.records.length) return 0;

  let next = maxApplicantNo_(app) + 1;
  const column = [];
  let assigned = 0;

  for (let i = 1; i < app.values.length; i++) {

    const row = app.values[i];
    const current = row[app.map.no];
    if (isBlank_(current) && hasApplicantData_(row, app.map)) {
      column.push([next++]);
      assigned++;
    } else {
      column.push([current]);
    }
  }

  if (assigned) {
    sheet.getRange(2, app.map.no + 1, column.length, 1).setValues(column);
  }

  return assigned;
}


function maxApplicantNo_(app) {

  let max = 0;

  if (app.map.no === undefined) return max;

  for (let i = 1; i < app.values.length; i++) {
    const n = toNumberOrNull_(app.values[i][app.map.no]);
    if (n !== null && n > max) max = n;
  }

  return max;
}


