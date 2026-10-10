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

  // 対応状況（v1 と同じ7種類＋「活動休止」。v1 の7種類の順番は変えない）
  //   活動休止 … 加入確定後に一時的に休んでいる団員（団員アプリは閲覧のみ）
  statuses: [
    '未対応',
    '初回連絡済み',
    '返信待ち',
    '参加予定',
    '正式参加',
    '保留',
    '辞退',
    '活動休止'
  ],
  newApplicantStatus: '未対応',
  newApplicantNextAction: '初回連絡',
  plannedStatus: '参加予定',
  officialStatus: '正式参加',
  pausedStatus: '活動休止',

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
  { key: 'syncMemo', header: '同期メモ', added: true },

  // 団員アプリ連携（AppSync.gs）で使う列。同期を実行したときだけ末尾に追加される
  { key: 'appId', header: 'アプリID', extra: true },
  { key: 'appEmail', header: 'アプリ用メールアドレス', aliases: ['アプリ用メール'], extra: true },

  // 正式加入確認（Membership.gs）で使う列。メニューを実行したときだけ末尾に追加される
  { key: 'appUsage', header: 'アプリ利用', extra: true },
  { key: 'joinIntent', header: '正式加入の意思', extra: true },
  { key: 'joinAnsweredAt', header: '加入確認 回答日時', extra: true },
  { key: 'joinMailAt', header: '加入確認メール', extra: true },
  { key: 'firebaseState', header: 'Firebase連携状態', extra: true }
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
      ui.createMenu('📱 団員アプリ')
        .addItem('同期の内容を確認（お試し・書き込みなし）', 'menuAppSyncPreview')
        .addItem('団員アプリへ同期', 'menuAppSyncRun')
        .addItem('自動同期を設定（15分ごと）', 'menuAppSyncInstallTrigger')
        .addItem('アプリ連携設定を開く', 'menuAppSyncOpenSettings')
        .addSeparator()
        .addItem('プッシュ通知をいますぐ送信', 'menuAppNotifyRunNow')
        .addItem('通知の送信を設定（10分ごと）', 'menuAppNotifyInstallTrigger')
    )
    .addSubMenu(
      ui.createMenu('✉️ 正式加入確認')
        .addItem('正式加入確認フォームを作成', 'menuMembershipCreateForm')
        .addItem('テスト送信（自分宛て）', 'menuMembershipSendTest')
        .addItem('正式加入確認メールを送信', 'menuMembershipSendEmails')
        .addSeparator()
        .addItem('正式加入回答を同期', 'menuMembershipSyncResponses')
        .addItem('正式参加者一覧を更新', 'menuMembershipUpdateMemberList')
        .addItem('アプリ利用対象者を更新', 'menuMembershipUpdateAppUsage')
        .addItem('同期状況を確認', 'menuMembershipStatus')
        .addItem('加入確認設定を開く', 'menuMembershipOpenSettings')
    )
    .addSubMenu(
      ui.createMenu('🛠 メンテナンス')
        .addItem('楽器名の表記を統一（応募者一覧の楽器列）', 'normalizeApplicantInstruments')
        .addItem('応募者一覧を整理（ずれた行・空の行を削除）', 'cleanupApplicantsSheet')
        .addItem('セルフテスト（本番データは変更しません）', 'runSelfTests')
    )
    .addToUi();
}


/*
 * 団員アプリ連携のメニュー（AppSync.gs が追加されていない場合は案内を出す）
 */
function menuAppSyncPreview() { return callAppSync_('appSyncPreview'); }
function menuAppSyncRun() { return callAppSync_('appSyncRun'); }
function menuAppSyncInstallTrigger() { return callAppSync_('appSyncInstallTrigger'); }
function menuAppSyncOpenSettings() { return callAppSync_('appSyncOpenSettings'); }
function menuAppNotifyRunNow() { return callAppSync_('appNotifyRunNow'); }
function menuAppNotifyInstallTrigger() { return callAppSync_('appNotifyInstallTrigger'); }
function menuMembershipCreateForm() { return callAppSync_('membershipCreateForm'); }
function menuMembershipSendTest() { return callAppSync_('membershipSendTest'); }
function menuMembershipSendEmails() { return callAppSync_('membershipSendEmails'); }
function menuMembershipSyncResponses() { return callAppSync_('membershipSyncResponses'); }
function menuMembershipUpdateMemberList() { return callAppSync_('membershipUpdateMemberList'); }
function menuMembershipUpdateAppUsage() { return callAppSync_('membershipUpdateAppUsage'); }
function menuMembershipStatus() { return callAppSync_('membershipStatus'); }
function menuMembershipOpenSettings() { return callAppSync_('membershipOpenSettings'); }

function callAppSync_(name) {

  const fn = globalThis[name];

  if (typeof fn !== 'function') {
    const file = name.indexOf('appNotify') === 0 ? 'AppNotify.gs' : name.indexOf('membership') === 0 ? 'Membership.gs' : 'AppSync.gs';
    alert_('団員アプリ連携用のファイル（' + file + '）が追加されていません。\nApps Script エディタで ' + file + ' を追加してください。');
    return null;
  }

  return fn();
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
 * 対応状況のプルダウン（v1 と同じ7種類＋活動休止）
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

    // 正式加入確認フォームの回答（「正式加入について」の質問がある）は応募者として取り込まない
    if (isMembershipResponseHeaders_(headers)) {
      info.reason = '正式加入確認フォームの回答シートのため対象外（「✉️ 正式加入確認」→「正式加入回答を同期」で扱います）';
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


/*
 * 正式加入確認フォームの回答シートか（見出しに「正式加入について」がある）
 * Membership.gs が無くても、応募者の二重登録を防ぐためにここで判定する。
 */
function isMembershipResponseHeaders_(headers) {

  return headers.some(h => normalizeHeader_(h).indexOf(normalizeHeader_('正式加入について')) === 0);
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


/*******************************************************
 * 楽器名を統一
 *
 * v1 の対応表（フルート→Fl、テューバ→Tuba など）はすべて引き継ぎ、
 * 次の表記ゆれを追加で吸収します。
 *  ・チューバ／テューバ／Tuba／tuba／ﾁｭｰﾊﾞ／チュ－バ
 *  ・全角/半角、大文字/小文字、空白、長音記号、ヴ/ブ、小書き文字
 *  ・「テューバ（Tuba）」のような括弧書き
 *  ・チェックボックス形式の複数回答（「フルート, ピッコロ」→「Fl, Picc」）
 *
 * 判定できない名前は v1 と同じく元の文字のまま返します（推測で割り当てない）。
 * 「募集設定」の「追加の表記ゆれ」に書くと、コードを変えずに対応を増やせます。
 *******************************************************/

function normalizeInstrument(
  value,
  index
) {

  if (value === null || value === undefined) return '';

  const raw = String(value).trim();

  if (!raw) return '';

  const idx = index || getDefaultInstrumentIndex_();

  const whole = resolveInstrumentToken_(raw, idx);

  if (whole) return whole;

  const out = [];
  const pushUnique = v => { if (out.indexOf(v) < 0) out.push(v); };

  splitInstrumentList_(raw).forEach(token => {

    const code = resolveInstrumentToken_(token, idx);

    if (code) {
      pushUnique(code);
      return;
    }

    // 「ヴァイオリン/ヴィオラ」のような書き方
    const pieces = token.split(/[\/／・･&＆]+/).map(s => s.trim()).filter(Boolean);

    if (pieces.length > 1) {
      const codes = pieces.map(p => resolveInstrumentToken_(p, idx));
      if (codes.every(Boolean)) {
        codes.forEach(pushUnique);
        return;
      }
    }

    pushUnique(token);
  });

  return out.join(', ');
}


/*
 * 1つの楽器名をコードに変換（見つからなければ null）
 */
function resolveInstrumentToken_(token, index) {

  const key = instrumentKey_(token);

  if (key && index.aliasMap[key]) return index.aliasMap[key];

  // 括弧の中身を除いて再判定（例：「打楽器（ティンパニ含む）」→ 打楽器）
  const withoutParen = nfkc_(token).replace(/[(\[［【「『][^)\]］】」』]*[)\]］】」』]/g, ' ');
  const key2 = instrumentKey_(withoutParen);

  if (key2 && key2 !== key && index.aliasMap[key2]) return index.aliasMap[key2];

  return null;
}


/*
 * 楽器名の照合用キー
 */
function instrumentKey_(value) {

  let s = nfkc_(value).toLowerCase();

  s = s
    .replace(/ヴァ/g, 'バ')
    .replace(/ヴィ/g, 'ビ')
    .replace(/ヴェ/g, 'ベ')
    .replace(/ヴォ/g, 'ボ')
    .replace(/ヴ/g, 'ブ');

  const small = { 'ァ': 'ア', 'ィ': 'イ', 'ゥ': 'ウ', 'ェ': 'エ', 'ォ': 'オ', 'ッ': 'ツ', 'ャ': 'ヤ', 'ュ': 'ユ', 'ョ': 'ヨ', 'ヮ': 'ワ' };

  s = s.replace(/[ァィゥェォッャュョヮ]/g, c => small[c]);

  // 空白・長音・ハイフン類・中黒・ピリオド・スラッシュ・括弧記号を除去
  s = s.replace(/[\s　ー〜~\-‐‑‒–—―−・･.。\/()\[\]{}「」【】『』'"’‘“”]/g, '');

  return s;
}


/*
 * 複数回答（チェックボックス）の区切り
 */
function splitInstrumentList_(value) {

  return String(value)
    .split(/[,、，;；\n]+/)
    .map(s => s.trim())
    .filter(Boolean);
}


/*
 * 応募者一覧の楽器セルを解析
 */
function parseInstrumentCell_(cell, index) {

  const idx = index || getDefaultInstrumentIndex_();
  const raw = toStr_(cell);

  if (!raw) {
    return { isBlank: true, codes: [], unknown: [], primaryCode: null, normalized: '', changed: false };
  }

  const normalized = normalizeInstrument(raw, idx);
  const tokens = splitInstrumentList_(normalized);
  const codes = [];
  const unknown = [];

  tokens.forEach(t => {
    if (idx.codes.has(t)) {
      if (codes.indexOf(t) < 0) codes.push(t);
    } else {
      unknown.push(t);
    }
  });

  return {
    isBlank: false,
    codes,
    unknown,
    primaryCode: tokens.length && idx.codes.has(tokens[0]) ? tokens[0] : null,
    normalized,
    changed: normalized !== raw
  };
}


/*
 * 楽器の対応表を作る（カタログ＋募集設定）
 */
function buildInstrumentIndex_(settings) {

  const index = { aliasMap: {}, codes: new Set(), info: {}, order: [], collisions: [] };

  const addAlias = (alias, code, strong) => {
    const key = instrumentKey_(alias);
    if (!key) return;
    const current = index.aliasMap[key];
    if (current && current !== code) {
      index.collisions.push({ alias: String(alias), existing: current, code });
      if (!strong) return;
    }
    index.aliasMap[key] = code;
  };

  INSTRUMENT_CATALOG.forEach(item => {
    const code = item[0];
    index.codes.add(code);
    index.info[code] = { name: item[1], part: item[2], target: null, min: null, targetCellFilled: false, inSettings: false };
    addAlias(code, code);
    item[5].forEach(a => addAlias(a, code));
  });

  const parts = settings && settings.parts ? settings.parts : defaultParts_();

  parts.forEach(p => {

    if (!p.code) return;

    const base = index.info[p.code] || { name: p.code, part: p.code };

    index.codes.add(p.code);
    index.info[p.code] = {
      name: p.name || base.name,
      part: p.part || base.part || p.code,
      target: p.target,
      min: p.min,
      targetCellFilled: p.target !== null || p.min !== null,
      inSettings: true
    };

    if (index.order.indexOf(p.code) < 0) index.order.push(p.code);

    addAlias(p.code, p.code, true);
    if (p.name) addAlias(p.name, p.code, false);
    (p.aliases || []).forEach(a => addAlias(a, p.code, true));
  });

  INSTRUMENT_CATALOG.forEach(item => {
    if (index.order.indexOf(item[0]) < 0) index.order.push(item[0]);
  });

  LAST_INSTRUMENT_INDEX_ = index;

  return index;
}


let LAST_INSTRUMENT_INDEX_ = null;

function getDefaultInstrumentIndex_() {

  return LAST_INSTRUMENT_INDEX_ || buildInstrumentIndex_(null);
}


function defaultParts_() {

  return INSTRUMENT_CATALOG.map(item => ({
    code: item[0], name: item[1], part: item[2], target: item[3], min: item[4], aliases: []
  }));
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

  try {

    const result = syncWithoutDialog();

    recordAutoSync_(result, null);

    // 正式加入確認フォームの回答も照合する（Membership.gs がある場合だけ）
    if (typeof globalThis.membershipSyncFromTrigger_ === 'function') {
      try {
        globalThis.membershipSyncFromTrigger_();
      } catch (e) {
        console.error('正式加入回答の同期に失敗: ' + e.message);
      }
    }

    // 応募した人を団員アプリに「参加希望者」として登録する（AppSync.gs があり、設定が「はい」の場合）
    if (typeof globalThis.appSyncOnFormSubmit_ === 'function') {
      try {
        globalThis.appSyncOnFormSubmit_();
      } catch (e) {
        console.error('団員アプリへの同期に失敗: ' + e.message);
      }
    }

  } catch (err) {

    recordAutoSync_(null, err);

    // 失敗はトリガーの実行ログと失敗通知メールに残す（個人情報は含まない）
    throw err;
  }
}


function recordAutoSync_(result, err) {

  try {

    const info = {
      at: new Date().toISOString(),
      ok: !err && !!(result && (result.ok || result.busy)),
      added: result ? result.added : 0,
      busy: !!(result && result.busy),
      error: err ? String(err.message || err).slice(0, 300) : (result && !result.ok && !result.busy ? 'フォーム回答シートが見つからない等の理由で同期できませんでした' : '')
    };

    PropertiesService.getScriptProperties().setProperty(CONFIG.lastAutoSyncProperty, JSON.stringify(info));

  } catch (e) {
    console.error('自動同期の記録に失敗: ' + e.message);
  }
}


/*******************************************************
 * フォーム送信トリガーを設定（メニュー③）
 *
 * 何度実行しても1本だけになる（v1 と同じ動き）。
 *******************************************************/

function installSpreadsheetFormTrigger() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();

  const triggers =
    ScriptApp.getProjectTriggers();

  let removed = 0;

  triggers.forEach(trigger => {

    if (trigger.getHandlerFunction() === CONFIG.formTriggerHandler) {

      ScriptApp.deleteTrigger(trigger);
      removed++;
    }
  });

  ScriptApp
    .newTrigger(CONFIG.formTriggerHandler)
    .forSpreadsheet(ss)
    .onFormSubmit()
    .create();

  const otherFormTriggers = triggers.filter(t =>
    t.getHandlerFunction() !== CONFIG.formTriggerHandler &&
    String(t.getEventType()) === String(ScriptApp.EventType.ON_FORM_SUBMIT)
  );

  let message =
    'フォーム送信トリガーを設定しました！\n\n' +
    'これから新しいフォーム回答が送信されると、\n' +
    '自動的に「応募者一覧」に追加されます。';

  if (removed > 1) {
    message += '\n\n重複していたトリガー ' + removed + '件 を整理して1件にしました。';
  }

  if (otherFormTriggers.length) {
    message +=
      '\n\n⚠️ 別の関数（' + otherFormTriggers.map(t => t.getHandlerFunction()).join('、') + '）の' +
      'フォーム送信トリガーもあります。不要なら Apps Script の「トリガー」画面から削除してください（自動では削除していません）。';
  }

  message +=
    '\n\n※ トリガーは設定した人のGoogleアカウントごとに登録されます。' +
    '\n別の管理者も設定していた場合でも、同期はロックと重複防止で二重登録しません。';

  alert_(message);
}


/*******************************************************
 * ダッシュボード更新（メニュー④）
 *
 * 楽器別集計・活動状況・ダッシュボードをまとめて更新。
 * トリガーからも呼ばれるのでダイアログは出さない。
 *******************************************************/

function updateDashboard() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();

  ensureSettingsSheet_(ss);

  const ctx = buildContext_(ss);

  writeInstrumentSheet_(ss, ctx);

  writeStatusSheet_(ss, ctx);

  writeDashboardSheet_(ss, ctx);

  SpreadsheetApp.flush();

  toast_(ss, 'ダッシュボードを更新しました（' + ctx.stamp + '）');

  return ctx.stats;
}


/*******************************************************
 * 楽器別集計を更新（メニュー⑥）
 *******************************************************/

function updateInstrumentSummary() {

  const stats = updateDashboard();

  alert_(
    '楽器別集計を更新しました。\n\n' +
    '参加希望者数（実人数）：' + stats.total + '人\n' +
    '急募パート：' + (stats.urgentParts.join('、') || 'なし') + '\n' +
    '募集中パート：' + (stats.recruitingParts.join('、') || 'なし')
  );
}


/*******************************************************
 * 応募者管理を更新（メニュー⑦）
 *
 * ・同期メモ列など足りない列を追加
 * ・No. が空欄の行に番号を振る（既存の番号は変えない）
 * ・対応状況のプルダウンを再設定
 * ・同じメールアドレスの応募に印を付ける
 * ・連絡記録 → 氏名の補完、最終連絡日の反映
 * ・集計を更新
 *******************************************************/

function updateApplicantManagement() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    alert_('他の処理が実行中です。少し待ってから再実行してください。');
    return;
  }

  let summary;

  try {

    let sheet = ss.getSheetByName(CONFIG.applicantsSheet);

    if (!sheet) sheet = setupApplicantsSheet_(ss);

    const cols = ensureApplicantColumns_(sheet);
    let app = readApplicants_(sheet);

    applyStatusValidation_(sheet, app.map, 2, Math.max(sheet.getMaxRows() - 1, 1));

    const numbered = renumberApplicants();

    app = readApplicants_(sheet);

    const memos = refreshDuplicateMemos_(sheet, app);

    setupContactSheet_(ss);

    const contact = syncContactsToApplicants_(ss);

    const stats = updateDashboard();

    summary =
      '応募者管理を更新しました。\n\n' +
      '応募者（実人数）：' + stats.total + '人\n' +
      '追加した列：' + (cols.appended.join('、') || 'なし') + '\n' +
      'No. を新しく振った行：' + numbered + '件\n' +
      '重複候補の印を更新：' + memos + '件\n' +
      '連絡記録の氏名を補完：' + contact.namesFilled + '件\n' +
      '最終連絡日を更新：' + contact.lastContactUpdated + '件';

  } finally {
    lock.releaseLock();
  }

  alert_(summary);
}


/*
 * 同じメールアドレスの行に「⚠重複候補」の印を付ける（同期メモ列のみ変更）
 */
function refreshDuplicateMemos_(sheet, app) {

  if (app.map.syncMemo === undefined) return 0;

  const desired = new Map();

  groupByEmail_(app.records).forEach(list => {

    if (list.length < 2) return;

    const primary = list[0];
    const others = list.slice(1);

    desired.set(primary.row, DUP_PREFIX_ + noLabel_(others) + ' と同じメールアドレス（この行を集計に使用）');
    others.forEach(o => desired.set(o.row, DUP_PREFIX_ + noLabel_([primary]) + ' と同じメールアドレス（集計対象外）'));
  });

  let changed = 0;

  app.records.forEach(r => {

    const parts = r.memo ? r.memo.split(' / ').filter(s => s.indexOf(DUP_PREFIX_) !== 0) : [];
    const note = desired.get(r.row);

    if (note) parts.unshift(note);

    const next = parts.join(' / ');

    if (next !== r.memo) {
      sheet.getRange(r.row, app.map.syncMemo + 1).setValue(next);
      changed++;
    }
  });

  return changed;
}


/*
 * 連絡記録 → 応募者一覧
 * ・氏名が空欄なら No. から補完
 * ・最終連絡日は「連絡記録の最新日付」が新しい場合だけ更新（手入力より古い日付で上書きしない）
 */
function syncContactsToApplicants_(ss) {

  const result = { namesFilled: 0, lastContactUpdated: 0 };
  const appSheet = ss.getSheetByName(CONFIG.applicantsSheet);
  const contacts = readContacts_(ss);

  if (!appSheet || !contacts.records.length) return result;

  const app = readApplicants_(appSheet);
  const byNo = new Map();

  app.records.forEach(r => {
    if (r.noNum !== null && !byNo.has(r.noNum)) byNo.set(r.noNum, r);
  });

  if (contacts.map.name !== undefined) {

    contacts.records.forEach(c => {

      if (c.noNum === null || !isBlank_(c.name)) return;

      const a = byNo.get(c.noNum);

      if (a && a.name) {
        contacts.sheet.getRange(c.row, contacts.map.name + 1).setValue(sanitizeForSheet_(a.name));
        result.namesFilled++;
      }
    });
  }

  if (app.map.lastContact !== undefined) {

    const latest = new Map();

    contacts.records.forEach(c => {
      if (c.noNum === null || !isDate_(c.date)) return;
      const current = latest.get(c.noNum);
      if (!current || c.date.getTime() > current.getTime()) latest.set(c.noNum, c.date);
    });

    latest.forEach((date, no) => {

      const a = byNo.get(no);

      if (!a) return;

      const current = a.lastContact;

      if (isDate_(current) && current.getTime() >= date.getTime()) return;

      // 文字で手入力されている場合は上書きしない
      if (!isBlank_(current) && !isDate_(current)) return;

      appSheet.getRange(a.row, app.map.lastContact + 1).setValue(date);
      result.lastContactUpdated++;
    });
  }

  return result;
}


/*******************************************************
 * 応募者一覧を整理（メンテナンス）
 *
 * 確認ダイアログのあと、次を行う。
 *  ・中身のない行（No. だけ等。回答日時・メール・お名前・楽器がすべて空）を削除
 *  ・古いコードが列をずらして書き込んだ行のうち、同じ人の正しい行があるものを削除
 *    （正しい行が無い人の行は残す）
 *  ・連絡記録がまだ無ければ No. を 1 から振り直す
 *  ・意味のないメモ「⚠未取得: ニックネーム」を消す
 * 実行前に「応募者一覧（整理前バックアップ）」シートを作る。
 *******************************************************/

const CLEANUP_BACKUP_NAME_ = '応募者一覧（整理前バックアップ）';
const EMAIL_PATTERN_ = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function cleanupApplicantsSheet() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

  if (!sheet) {
    alert_('「応募者一覧」シートがありません。');
    return null;
  }

  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    alert_('他の処理が実行中です。少し待ってから再実行してください。');
    return null;
  }

  let message;
  let plan;
  let done = false;

  try {

    plan = planCleanup_(ss, sheet);

    const lines = [];

    if (plan.deleteEmpty.length) lines.push('・中身のない行（No. だけ等）：' + plan.deleteEmpty.length + '行 → 削除');
    if (plan.deleteMisaligned.length) lines.push('・列がずれて書き込まれた行（同じ人の正しい行あり）：' + plan.deleteMisaligned.length + '行 → 削除');
    if (plan.keptMisaligned.length) lines.push('・列がずれているが、正しい行が無い行：' + plan.keptMisaligned.length + '行 → 削除せず残します');
    if (plan.renumber) lines.push('・No. を 1〜' + plan.remaining + ' に振り直し（連絡記録がまだ無いため）');
    if (plan.memoRows.length) lines.push('・意味のないメモ「⚠未取得: ニックネーム」を消去：' + plan.memoRows.length + '行');

    if (!plan.deleteEmpty.length && !plan.deleteMisaligned.length && !plan.renumber && !plan.memoRows.length) {
      message = '整理が必要な行はありません。';
    }

    const ok = !message && confirm_(
      '応募者一覧を整理',
      '次の整理を行います。\n\n' + lines.join('\n') +
      '\n\n整理後の応募者：' + plan.remaining + '人' +
      '\n\n実行前に「' + CLEANUP_BACKUP_NAME_ + '」シートにバックアップを作ります。\n実行しますか？'
    );

    if (!ok) {
      message = message || '整理を中止しました（何も変更していません）。';
    } else {
      done = runCleanup_(ss, sheet, plan);
      message =
        '応募者一覧を整理しました。\n\n' +
        lines.join('\n') +
        '\n\n整理後の応募者：' + plan.remaining + '人' +
        (done.renumbered ? '（No. 1〜' + done.renumbered + '）' : '') +
        '\n\n整理前の状態は「' + done.backupName + '」シートに保存しています（不要になったら削除して構いません）。';
    }

  } finally {
    lock.releaseLock();
  }

  if (done) updateDashboard();

  alert_(message);

  return plan;
}


/*
 * 整理の実行（バックアップ → メモ掃除 → 行削除 → No. 振り直し）
 */
function runCleanup_(ss, sheet, plan) {

  const backup = backupSheet_(ss, sheet, CLEANUP_BACKUP_NAME_);
  const app = plan.app;

  // メモの掃除（行を消す前に。行番号がまだ有効なうちに）
  if (app.map.syncMemo !== undefined) {
    plan.memoRows.forEach(m => sheet.getRange(m.row, app.map.syncMemo + 1).setValue(m.memo));
  }

  // 下の行から、連続した範囲ごとにまとめて削除
  const rows = plan.deleteEmpty.concat(plan.deleteMisaligned).sort((a, b) => b - a);
  let i = 0;

  while (i < rows.length) {
    let j = i;
    while (j + 1 < rows.length && rows[j + 1] === rows[j] - 1) j++;
    sheet.deleteRows(rows[j], i === j ? 1 : rows[i] - rows[j] + 1);
    i = j + 1;
  }

  let renumbered = 0;

  if (plan.renumber) renumbered = renumberAllApplicants_(ss, sheet);

  return { renumbered, backupName: backup.getName() };
}


/*
 * 整理の計画（書き込みはしない）
 */
function planCleanup_(ss, sheet) {

  const app = readApplicants_(sheet);
  const contacts = readContacts_(ss);
  const properEmails = new Set();

  app.records.forEach(r => {
    if (EMAIL_PATTERN_.test(toStr_(r.email))) properEmails.add(r.emailKey);
  });

  const deleteMisaligned = [];
  const keptMisaligned = [];

  if (app.map.email !== undefined) {

    app.records.forEach(r => {

      if (EMAIL_PATTERN_.test(toStr_(r.email))) return;

      const values = app.values[r.row - 1] || [];
      const found = values
        .map(toStr_)
        .find((v, i) => i !== app.map.email && EMAIL_PATTERN_.test(v));

      if (!found) return;

      if (properEmails.has(emailKey_(found))) deleteMisaligned.push(r.row);
      else keptMisaligned.push(r.row);
    });
  }

  const memoRows = [];

  app.records.forEach(r => {

    if (deleteMisaligned.indexOf(r.row) >= 0 || !r.memo) return;

    const parts = r.memo.split(' / ').map(seg => {
      if (seg.indexOf(MISSING_PREFIX_) !== 0) return seg;
      const rest = seg.slice(MISSING_PREFIX_.length).split('・').filter(x => x && x !== 'ニックネーム');
      return rest.length ? MISSING_PREFIX_ + rest.join('・') : null;
    }).filter(Boolean);

    const next = parts.join(' / ');

    if (next !== r.memo) memoRows.push({ row: r.row, memo: next });
  });

  return {
    app,
    deleteEmpty: app.emptyRows.slice(),
    deleteMisaligned,
    keptMisaligned,
    memoRows,
    remaining: app.records.length - deleteMisaligned.length,
    renumber: app.map.no !== undefined && contacts.records.length === 0 && !isSequentialAfterCleanup_(app, deleteMisaligned)
  };
}


/*
 * 整理後の No. がすでに 1, 2, 3 … の順になっているか（なっていれば振り直さない）
 */
function isSequentialAfterCleanup_(app, deleteRows) {

  const nos = app.records
    .filter(r => deleteRows.indexOf(r.row) < 0)
    .sort((a, b) => a.row - b.row)
    .map(r => r.noNum);

  return nos.every((n, i) => n === i + 1);
}


/*
 * No. を上から 1, 2, 3 … に振り直す（連絡記録が無いときだけ呼ぶ）
 * _同期履歴 の No. も合わせて書き換える。
 */
function renumberAllApplicants_(ss, sheet) {

  const app = readApplicants_(sheet);

  if (app.map.no === undefined || !app.records.length) return 0;

  const oldToNew = new Map();
  const column = [];
  let next = 1;

  for (let i = 1; i < app.values.length; i++) {
    const row = app.values[i];
    if (hasApplicantData_(row, app.map)) {
      const oldNo = toNumberOrNull_(row[app.map.no]);
      if (oldNo !== null) oldToNew.set(oldNo, next);
      column.push([next++]);
    } else {
      column.push([row[app.map.no]]);
    }
  }

  sheet.getRange(2, app.map.no + 1, column.length, 1).setValues(column);

  const ledger = ss.getSheetByName(CONFIG.ledgerSheet);

  if (ledger && ledger.getLastRow() >= 2) {
    const range = ledger.getRange(2, 2, ledger.getLastRow() - 1, 1);
    const values = range.getValues().map(r => {
      const n = toNumberOrNull_(r[0]);
      return [n !== null && oldToNew.has(n) ? oldToNew.get(n) : r[0]];
    });
    range.setValues(values);
  }

  return next - 1;
}


/*
 * シートを丸ごとコピーしてバックアップを作る（同名があれば日時を付ける）
 */
function backupSheet_(ss, sheet, name) {

  const copy = sheet.copyTo(ss);
  const finalName = ss.getSheetByName(name)
    ? name + ' ' + formatDate_(ss, new Date(), 'yyyyMMdd-HHmmss')
    : name;

  copy.setName(finalName);

  return copy;
}


/*******************************************************
 * 楽器名の表記を統一（メンテナンス）
 *
 * v1 時代に正規化されずに残った「チューバ」などを「Tuba」に揃える。
 * ・判定できる楽器名だけ変更（不明な名前はそのまま）
 * ・元の回答はフォーム回答シートに残っている
 *******************************************************/

function normalizeApplicantInstruments() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

  if (!sheet) {
    alert_('「応募者一覧」シートがありません。');
    return;
  }

  const app = readApplicants_(sheet);

  if (app.map.instrument === undefined) {
    alert_('「応募者一覧」に「楽器」列が見つかりません。');
    return;
  }

  const index = buildInstrumentIndex_(loadSettings_(ss));
  const changes = [];

  app.records.forEach(r => {
    const p = parseInstrumentCell_(r.instrument, index);
    if (!p.isBlank && p.changed && p.unknown.length === 0) {
      changes.push({ record: r, from: toStr_(r.instrument), to: p.normalized });
    }
  });

  if (!changes.length) {
    alert_('楽器名の表記はすでに統一されています（変更なし）。');
    return;
  }

  const preview = changes.slice(0, 15)
    .map(c => 'No.' + toStr_(c.record.no) + '：' + c.from + ' → ' + c.to)
    .join('\n');

  const ok = confirm_(
    '楽器名の表記を統一',
    changes.length + '件の楽器名を統一します。\n\n' + preview +
    (changes.length > 15 ? '\n…ほか' + (changes.length - 15) + '件' : '') +
    '\n\n（元の回答はフォーム回答シートに残っています）\n実行しますか？'
  );

  if (!ok) return;

  changes.forEach(c => {
    sheet.getRange(c.record.row, app.map.instrument + 1).setValue(sanitizeForSheet_(c.to));
  });

  updateDashboard();

  alert_(changes.length + '件の楽器名を統一しました。');
}


/*******************************************************
 * 集計（読み取り → 計算）
 *******************************************************/

function buildContext_(ss) {

  const settings = loadSettings_(ss);
  const index = buildInstrumentIndex_(settings);
  const appSheet = ss.getSheetByName(CONFIG.applicantsSheet);
  const app = appSheet ? readApplicants_(appSheet) : emptyApplicants_();
  const contacts = readContacts_(ss);
  const now = new Date();

  return {
    settings,
    index,
    app,
    contacts,
    now,
    stamp: formatDate_(ss, now, 'yyyy/MM/dd HH:mm'),
    stats: computeStats_(app.records, settings, index, now),
    contactStats: computeContactStats_(contacts.records, now)
  };
}


/*
 * 集計の本体（シートを触らない純粋な計算。テスト可能）
 *
 * 重複の扱い：
 *  同じメールアドレスの行が複数ある場合は「No. が一番小さい行」を1人として数え、
 *  ほかの行は「重複候補（集計対象外）」とする。
 */
function computeStats_(records, settings, index, now) {

  const s = settings || defaultSettings_();
  const idx = index || getDefaultInstrumentIndex_();
  const excluded = new Set(s.excludedStatuses || []);
  const today = now || new Date();

  const primaries = [];
  const duplicates = [];

  groupByEmail_(records).forEach(list => {
    primaries.push(list[0]);
    for (let i = 1; i < list.length; i++) duplicates.push({ record: list[i], primary: list[0] });
  });

  primaries.sort((a, b) => a.row - b.row);

  const st = {
    total: 0,
    active: 0,
    excluded: 0,
    planned: 0,
    official: 0,
    statusCounts: {},
    concertCounts: {},
    unknownTokens: {},
    blankInstrument: 0,
    followUps: [],
    duplicates,
    codeRows: [],
    partRows: [],
    urgentParts: [],
    recruitingParts: [],
    filledParts: [],
    situation: '',
    // 正式加入確認・アプリ利用（Membership.gs の列が無ければすべて 0／未回答）
    membership: { intents: {}, appTarget: 0, appUsage: {}, mailed: 0 }
  };

  const codeStats = {};
  const bump = (code, field) => {
    if (!codeStats[code]) codeStats[code] = { all: 0, active: 0, planned: 0, official: 0, secondary: 0 };
    codeStats[code][field]++;
  };
  const inc = (obj, key) => { obj[key] = (obj[key] || 0) + 1; };
  const followMs = (Number(s.followUpDays) || 0) * 86400000;

  primaries.forEach(r => {

    st.total++;

    inc(st.membership.intents, r.joinIntent || '未回答');
    if ((r.status === CONFIG.officialStatus || r.status === CONFIG.pausedStatus) && r.appUsage !== '停止') st.membership.appTarget++;
    if (r.appUsage) inc(st.membership.appUsage, r.appUsage);
    if (!isBlank_(r.joinMailAt)) st.membership.mailed++;

    const status = r.status;
    const isExcluded = excluded.has(status);

    if (isExcluded) st.excluded++; else st.active++;
    if (status === CONFIG.plannedStatus) st.planned++;
    if (status === CONFIG.officialStatus) st.official++;

    inc(st.statusCounts, status || STATUS_BLANK_);
    inc(st.concertCounts, toStr_(r.concert) || '（未回答）');

    const p = parseInstrumentCell_(r.instrument, idx);
    const code = p.isBlank ? CODE_BLANK_ : (p.primaryCode || CODE_UNKNOWN_);

    if (p.isBlank) st.blankInstrument++;
    p.unknown.forEach(t => inc(st.unknownTokens, t));

    bump(code, 'all');
    if (!isExcluded) bump(code, 'active');
    if (status === CONFIG.plannedStatus) bump(code, 'planned');
    if (status === CONFIG.officialStatus) bump(code, 'official');

    if (!isExcluded) {
      p.codes.forEach(c => { if (c !== p.primaryCode) bump(c, 'secondary'); });
    }

    if (status === CONFIG.newApplicantStatus && isDate_(r.timestamp) && followMs > 0 &&
        today.getTime() - r.timestamp.getTime() >= followMs) {
      st.followUps.push(r.no);
    }
  });

  // 楽器（コード）ごとの行
  const order = idx.order.slice();

  Object.keys(codeStats).forEach(c => {
    if (order.indexOf(c) < 0 && c !== CODE_UNKNOWN_ && c !== CODE_BLANK_) order.push(c);
  });

  order.push(CODE_UNKNOWN_, CODE_BLANK_);

  const zero = { all: 0, active: 0, planned: 0, official: 0, secondary: 0 };

  st.codeRows = order.map(code => {

    const special = code === CODE_UNKNOWN_ || code === CODE_BLANK_;
    const info = idx.info[code] || {
      name: code === CODE_UNKNOWN_ ? '楽器名を判定できない回答' : code === CODE_BLANK_ ? '楽器が未回答' : code,
      part: code,
      target: null,
      min: null,
      targetCellFilled: false
    };
    const c = codeStats[code] || zero;

    return {
      code,
      name: info.name,
      part: special ? code : (info.part || code),
      target: info.target,
      min: info.min,
      all: c.all,
      active: c.active,
      planned: c.planned,
      official: c.official,
      secondary: c.secondary,
      // v1 と同じ「不足数 = 最低人数 − 正式参加（0未満は0）」
      shortage: info.min === null || info.min === undefined ? '' : Math.max(info.min - c.official, 0),
      rate: fillRate_(c.active, info.target, info.min),
      status: special ? (c.all ? '要確認' : '') : judgeRecruitStatus_(c.active, info.target, info.min, s),
      visible: special ? c.all > 0 : (info.targetCellFilled || c.all > 0 || c.secondary > 0)
    };
  });

  // パートごとの行（例：Vn = 1st Vn + 2nd Vn + 未定、Fl = Fl + Picc）
  const partOrder = [];
  const parts = {};

  st.codeRows.forEach(row => {

    if (!parts[row.part]) {
      parts[row.part] = { part: row.part, members: [], all: 0, active: 0, planned: 0, official: 0, secondary: 0, target: null, min: null, visible: false, special: row.code === CODE_UNKNOWN_ || row.code === CODE_BLANK_ };
      partOrder.push(row.part);
    }

    const p = parts[row.part];

    p.members.push(row);
    p.all += row.all;
    p.active += row.active;
    p.planned += row.planned;
    p.official += row.official;
    p.secondary += row.secondary;
    if (row.target !== null && row.target !== undefined) p.target = (p.target || 0) + row.target;
    if (row.min !== null && row.min !== undefined) p.min = (p.min || 0) + row.min;
    if (row.visible) p.visible = true;
  });

  st.partRows = partOrder.map(name => {

    const p = parts[name];
    const label = p.special ? name : (PART_LABELS_[name] ? name + '（' + PART_LABELS_[name] + '）' : name);
    const breakdown = p.members.length > 1
      ? p.members.filter(m => m.all > 0).map(m => m.code + ' ' + m.active).join('・')
      : '';

    return {
      part: name,
      label,
      breakdown,
      all: p.all,
      active: p.active,
      planned: p.planned,
      official: p.official,
      secondary: p.secondary,
      target: p.target,
      min: p.min,
      shortageToTarget: p.target > 0 ? Math.max(p.target - p.active, 0) : '',
      shortageToMin: p.min > 0 ? Math.max(p.min - p.active, 0) : '',
      rate: fillRate_(p.active, p.target, p.min),
      status: p.special ? (p.all ? '要確認' : '') : judgeRecruitStatus_(p.active, p.target, p.min, s),
      visible: p.visible,
      special: p.special
    };
  });

  st.partRows.forEach(p => {
    if (!p.visible || p.special) return;
    if (p.status === RECRUIT_.URGENT) st.urgentParts.push(p.label);
    else if (p.status === RECRUIT_.OPEN || p.status === RECRUIT_.BELOW_MIN) st.recruitingParts.push(p.label);
    else if (p.status === RECRUIT_.FILLED || p.status === RECRUIT_.SURPLUS) st.filledParts.push(p.label);
  });

  st.situation = judgeSituation_(st.official, s);

  return st;
}


/*
 * 募集状況の判定（人数はコードに固定せず、設定値で判断）
 *
 *  目標・最低とも未設定 → 目標未設定
 *  0人                 → 急募
 *  最低×急募割合 未満   → 急募（初期値 0 なので通常は0人のときだけ）
 *  最低人数 未満        → 募集中（最低未達）
 *  目標人数 未満        → 募集中
 *  目標×調整倍率 以上   → 充足／調整
 *  それ以外             → 充足
 */
function judgeRecruitStatus_(count, target, min, settings) {

  const s = settings || {};
  const t = Number(target) > 0 ? Number(target) : 0;
  const m = Number(min) > 0 ? Number(min) : 0;
  const n = Number(count) || 0;

  if (!t && !m) return RECRUIT_.NONE;

  const urgentRatio = typeof s.urgentRatio === 'number' ? s.urgentRatio : CONFIG.urgentRatio;
  const surplusRatio = typeof s.surplusRatio === 'number' ? s.surplusRatio : CONFIG.surplusRatio;

  if (n <= 0) return RECRUIT_.URGENT;
  if (m && n < m * urgentRatio) return RECRUIT_.URGENT;
  if (m && n < m) return RECRUIT_.BELOW_MIN;
  if (t && n < t) return RECRUIT_.OPEN;

  const base = t || m;

  if (surplusRatio > 1 && n >= base * surplusRatio) return RECRUIT_.SURPLUS;

  return RECRUIT_.FILLED;
}


/*
 * 楽団全体の状況（v1 の判定式の参照ずれを修正）
 *  v1: B4>=B5（団員目標80）で「演奏会開催判断ライン到達」、B4>=B6（60）で「最低人数到達」になっていた
 */
function judgeSituation_(official, settings) {

  const s = settings || defaultSettings_();

  if (s.targetMembers > 0 && official >= s.targetMembers) return '団員目標達成';
  if (s.decisionMembers > 0 && official >= s.decisionMembers) return '演奏会開催判断ライン到達';
  if (s.minimumMembers > 0 && official >= s.minimumMembers) return '最低人数到達';

  return '団員募集継続';
}


function fillRate_(count, target, min) {

  const base = Number(target) > 0 ? Number(target) : (Number(min) > 0 ? Number(min) : 0);

  return base ? count / base : null;
}


/*
 * 連絡記録の集計（次回対応日が近いもの）
 */
function computeContactStats_(records, now) {

  const today = startOfDay_(now || new Date());
  const endToday = today.getTime() + 86400000 - 1;
  const week = today.getTime() + 8 * 86400000 - 1;
  const result = { overdue: [], upcoming: [], open: 0 };

  records.forEach(c => {

    const state = toStr_(c.state);

    if (state === '完了' || state === '不要') return;
    if (!isDate_(c.nextDate)) return;

    result.open++;

    const t = c.nextDate.getTime();
    const label = c.noNum !== null ? c.noNum : ('行' + c.row);

    if (t <= endToday) result.overdue.push(label);
    else if (t <= week) result.upcoming.push(label);
  });

  return result;
}


/*******************************************************
 * シートへの書き出し
 *******************************************************/

function writeInstrumentSheet_(ss, ctx) {

  let sheet = ss.getSheetByName(CONFIG.instrumentsSheet);

  if (!sheet) sheet = insertSheetQuietly_(ss, CONFIG.instrumentsSheet);

  const headers = ['楽器', '目標人数', '最低人数', '応募者数', '参加予定', '正式参加', '不足数', '有効応募者', '兼任可（第2希望以降）', '充足率', '募集状況', 'パート', '楽器名'];
  const W = headers.length;
  const st = ctx.stats;
  const rows = [headers];
  const bgs = [headers.map(() => COLOR_HEADER_)];
  const sum = { target: 0, min: 0, all: 0, planned: 0, official: 0, shortage: 0, active: 0, secondary: 0 };

  st.codeRows.filter(r => r.visible).forEach(r => {

    rows.push([
      r.code,
      blankIfNull_(r.target),
      blankIfNull_(r.min),
      r.all,
      r.planned,
      r.official,
      r.shortage,
      r.active,
      r.secondary,
      r.rate === null ? '' : r.rate,
      r.status,
      r.part,
      r.name
    ]);

    const bg = new Array(W).fill(COLOR_PLAIN_);
    bg[10] = RECRUIT_COLORS_[r.status] || (r.status ? '#f4cccc' : COLOR_PLAIN_);
    bgs.push(bg);

    sum.target += Number(r.target) || 0;
    sum.min += Number(r.min) || 0;
    sum.all += r.all;
    sum.planned += r.planned;
    sum.official += r.official;
    sum.shortage += Number(r.shortage) || 0;
    sum.active += r.active;
    sum.secondary += r.secondary;
  });

  rows.push(['合計', sum.target, sum.min, sum.all, sum.planned, sum.official, sum.shortage, sum.active, sum.secondary, sum.target ? sum.active / sum.target : '', '', '', '']);
  bgs.push(new Array(W).fill(COLOR_HEADER_));

  const notes = [
    [],
    ['最終更新', ctx.stamp],
    ['※ このシートは自動生成です。目標人数・最低人数は「募集設定」シートで変更してください。'],
    ['※ 応募者数＝重複候補を除いた実人数（第1希望の楽器で数える）／不足数＝最低人数−正式参加（v1 と同じ計算）'],
    ['※ 有効応募者＝「募集設定」の除外ステータス（初期値：辞退）以外。募集状況は有効応募者で判定します。'],
    ['※ 目標人数が空欄の楽器（ピッコロ等）は、応募者がいる場合だけ表示します。パートとしての合計はダッシュボードで確認できます。']
  ];

  notes.forEach(n => {
    const line = n.slice();
    while (line.length < W) line.push('');
    rows.push(line);
    bgs.push(new Array(W).fill(COLOR_PLAIN_));
  });

  ensureCols_(sheet, W);
  ensureRows_(sheet, rows.length);

  sheet.getRange(1, 1, sheet.getMaxRows(), W).clear();
  sheet.getRange(1, 1, rows.length, W).setValues(rows);
  sheet.getRange(1, 1, rows.length, W).setBackgrounds(bgs);
  sheet.getRange(1, 1, 1, W).setFontWeight('bold');
  sheet.getRange(rows.length - notes.length, 1, 1, W).setFontWeight('bold');

  const dataRows = rows.length - notes.length - 1;

  if (dataRows > 0) {
    sheet.getRange(2, 10, dataRows, 1).setNumberFormat('0%');
  }

  sheet.setFrozenRows(1);
}


function writeStatusSheet_(ss, ctx) {

  let sheet = ss.getSheetByName(CONFIG.statusSheet);

  if (!sheet) sheet = insertSheetQuietly_(ss, CONFIG.statusSheet);

  const s = ctx.settings;
  const st = ctx.stats;

  // 1〜9行目は v1 と同じ項目・同じ並び
  const rows = [
    ['項目', '現在値', 'メモ'],
    ['応募者数', st.total, '重複候補を除いた実人数（辞退を含む）'],
    ['参加予定', st.planned, ''],
    ['正式参加', st.official, ''],
    ['団員目標', s.targetMembers, '「募集設定」シートで変更'],
    ['演奏会開催判断ライン', s.decisionMembers, '「募集設定」シートで変更'],
    ['最低人数', s.minimumMembers, '「募集設定」シートで変更'],
    ['目標達成率', s.targetMembers > 0 ? st.official / s.targetMembers : 0, '正式参加 ÷ 団員目標'],
    ['現在の状況', st.situation, '正式参加の人数で判定'],
    ['', '', ''],
    ['対応状況別', '人数', '']
  ];

  statusListForDisplay_(st.statusCounts).forEach(label => {
    rows.push([label, st.statusCounts[label] || 0, CONFIG.statuses.indexOf(label) < 0 ? '一覧にない対応状況（⑧ データ整合性チェック）' : '']);
  });

  rows.push(['', '', '']);
  rows.push(['有効応募者（除外ステータス以外）', st.active, '除外：' + (s.excludedStatuses.join('・') || 'なし')]);
  rows.push(['重複候補（集計対象外）', st.duplicates.length, '⑨ 重複チェックで確認']);
  rows.push(['', '', '']);
  rows.push(['最終更新', ctx.stamp, '※ このシートは自動生成です（A〜C列）']);

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, 3);

  sheet.getRange(1, 1, sheet.getMaxRows(), 3).clear();
  sheet.getRange(1, 1, rows.length, 3).setValues(rows);
  sheet.getRange('B8').setNumberFormat('0.0%');
  sheet.getRange(1, 1, 1, 3).setFontWeight('bold').setBackground(COLOR_HEADER_);
  sheet.getRange(11, 1, 1, 3).setFontWeight('bold').setBackground(COLOR_HEADER_);
  sheet.setFrozenRows(1);
}


function writeDashboardSheet_(ss, ctx) {

  const sheet = getOrCreateOwnedSheet_(ss, CONFIG.dashboardSheet, DASHBOARD_TITLE_);
  const s = ctx.settings;
  const st = ctx.stats;
  const cs = ctx.contactStats;
  const W = 10;
  const rows = [];
  const bgs = [];
  const boldRows = [];

  const push = (cells, bg, bold) => {
    const line = (cells || []).slice(0, W);
    while (line.length < W) line.push('');
    rows.push(line);
    let colors;
    if (Array.isArray(bg)) {
      colors = bg.slice(0, W);
      while (colors.length < W) colors.push(COLOR_PLAIN_);
    } else {
      colors = new Array(W).fill(bg || COLOR_PLAIN_);
    }
    bgs.push(colors);
    if (bold) boldRows.push(rows.length);
  };

  const remain = (target, current) => (target > 0 ? (current >= target ? '到達' : 'あと ' + (target - current) + ' 人') : '');
  const situationColor = st.situation === '団員募集継続' ? '#fff2cc' : '#d9ead3';
  const colorAt = (col, color) => { const b = new Array(W).fill(COLOR_PLAIN_); b[col] = color; return b; };

  push([DASHBOARD_TITLE_], COLOR_PLAIN_, true);
  push(['最終更新', ctx.stamp, '※ 自動生成シートです。直接編集せず「応募者一覧」「募集設定」「連絡記録」を編集してください']);
  push([]);

  push(['【全体】'], COLOR_SECTION_, true);
  push(['項目', '人数', 'メモ'], COLOR_HEADER_, true);
  push(['参加希望者数（実人数）', st.total, '重複候補を除く。辞退を含む']);
  push(['有効応募者数', st.active, '除外：' + (s.excludedStatuses.join('・') || 'なし')]);
  push(['参加見込み（参加予定＋正式参加）', st.planned + st.official, '']);
  push(['正式参加', st.official, '']);
  push(['団員目標', s.targetMembers, '正式参加 ' + remain(s.targetMembers, st.official)]);
  push(['演奏会開催判断ライン', s.decisionMembers, '正式参加 ' + remain(s.decisionMembers, st.official)]);
  push(['最低人数（最低実施人数）', s.minimumMembers, '正式参加 ' + remain(s.minimumMembers, st.official)]);
  push(['達成率（正式参加 ÷ 団員目標）', percentText_(st.official, s.targetMembers), bar_(st.official, s.targetMembers)]);
  push(['達成率（参加見込み ÷ 団員目標）', percentText_(st.planned + st.official, s.targetMembers), bar_(st.planned + st.official, s.targetMembers)]);
  push(['達成率（有効応募者 ÷ 団員目標）', percentText_(st.active, s.targetMembers), bar_(st.active, s.targetMembers)]);
  push(['現在の状況', st.situation, '正式参加の人数で判定'], colorAt(1, situationColor), true);
  push([]);

  push(['【募集状況まとめ】', '', '', '判定は有効応募者数（パート単位）で行います'], COLOR_SECTION_, true);
  push(['🔴 急募パート', st.urgentParts.join('、') || 'なし'], colorAt(1, st.urgentParts.length ? RECRUIT_COLORS_['急募'] : COLOR_PLAIN_), true);
  push(['🟡 募集中パート', st.recruitingParts.join('、') || 'なし'], colorAt(1, st.recruitingParts.length ? RECRUIT_COLORS_['募集中'] : COLOR_PLAIN_));
  push(['🟢 充足パート', st.filledParts.join('、') || 'なし'], colorAt(1, st.filledParts.length ? RECRUIT_COLORS_['充足'] : COLOR_PLAIN_));
  push([]);

  push(['【パート別】'], COLOR_SECTION_, true);
  push(['パート', '内訳（有効応募者）', '有効応募者', '参加予定', '正式参加', '目標人数', '最低人数', '目標まで不足', '充足率', '募集状況'], COLOR_HEADER_, true);

  const total = { active: 0, planned: 0, official: 0, target: 0, min: 0, shortage: 0 };

  st.partRows.filter(p => p.visible).forEach(p => {

    push(
      [p.label, p.breakdown, p.active, p.planned, p.official, blankIfNull_(p.target), blankIfNull_(p.min), p.shortageToTarget, p.rate === null ? '' : percentText_(p.active, p.target > 0 ? p.target : p.min) + ' ' + bar_(p.active, p.target > 0 ? p.target : p.min), p.status],
      colorAt(9, RECRUIT_COLORS_[p.status] || (p.status ? '#f4cccc' : COLOR_PLAIN_))
    );

    total.active += p.active;
    total.planned += p.planned;
    total.official += p.official;
    total.target += Number(p.target) || 0;
    total.min += Number(p.min) || 0;
    total.shortage += Number(p.shortageToTarget) || 0;
  });

  push(['合計', '', total.active, total.planned, total.official, total.target, total.min, total.shortage, percentText_(total.active, total.target), ''], COLOR_HEADER_, true);
  push([]);

  const ms = st.membership;

  push(['【正式加入・団員アプリ】', '', '', '「✉️ 正式加入確認」メニューで更新されます'], COLOR_SECTION_, true);
  push(['項目', '人数', 'メモ'], COLOR_HEADER_, true);
  push(['参加希望者数（実人数）', st.total, '']);
  push(['正式参加', st.official, '']);
  push(['保留', st.statusCounts['保留'] || 0, '']);
  push(['辞退', st.statusCounts['辞退'] || 0, '']);
  push(['アプリ利用対象者', ms.appTarget, '対応状況が「正式参加」（活動休止を含む）で、アプリ利用が「停止」でない人']);
  push(['正式加入確認メール 送信済み', ms.mailed, '']);
  push(['加入の意思：希望', ms.intents['希望'] || 0, ms.intents['希望'] ? '「正式参加者一覧」の確認待ちリストで確認してください' : '']);
  push(['加入の意思：検討中', ms.intents['検討中'] || 0, '']);
  push(['加入の意思：見送り', ms.intents['見送り'] || 0, '']);
  push(['加入の意思：未回答', ms.intents['未回答'] || 0, '']);
  Object.keys(ms.appUsage).sort().forEach(k => push(['アプリ利用：' + k, ms.appUsage[k], '']));
  push([]);

  push(['【楽器別 正式参加者数】'], COLOR_SECTION_, true);
  push(['パート', '正式参加', '目標人数', '内訳'], COLOR_HEADER_, true);
  st.partRows.filter(p => p.visible).forEach(p => {
    const detail = st.codeRows
      .filter(c => c.part === p.part && c.official > 0 && c.code !== p.part)
      .map(c => c.name + ' ' + c.official).join('、');
    push([p.label, p.official, blankIfNull_(p.target), detail]);
  });
  push([]);


  push(['【活動状況】'], COLOR_SECTION_, true);
  push(['対応状況', '人数', 'メモ'], COLOR_HEADER_, true);

  statusListForDisplay_(st.statusCounts).forEach(label => {
    push([label, st.statusCounts[label] || 0, CONFIG.statuses.indexOf(label) < 0 ? '一覧にない対応状況です' : '']);
  });

  push(['未対応のまま ' + s.followUpDays + ' 日以上', st.followUps.length, formatNoList_(st.followUps)], colorAt(1, st.followUps.length ? '#fce5cd' : COLOR_PLAIN_));
  push(['連絡記録：次回対応が期限切れ・本日', cs.overdue.length, formatNoList_(cs.overdue)], colorAt(1, cs.overdue.length ? '#f4cccc' : COLOR_PLAIN_));
  push(['連絡記録：次回対応（7日以内）', cs.upcoming.length, formatNoList_(cs.upcoming)]);
  push([]);

  push(['【第1回演奏会への参加希望】'], COLOR_SECTION_, true);
  push(['回答', '人数'], COLOR_HEADER_, true);

  Object.keys(st.concertCounts)
    .sort((a, b) => st.concertCounts[b] - st.concertCounts[a])
    .forEach(k => push([k, st.concertCounts[k]]));

  push([]);

  const unknownList = Object.keys(st.unknownTokens);

  push(['【データの注意】'], COLOR_SECTION_, true);
  push(['重複候補（集計から除外）', st.duplicates.length, st.duplicates.length ? '⑨ 重複チェックで確認してください' : ''], colorAt(1, st.duplicates.length ? '#fce5cd' : COLOR_PLAIN_));
  push(['楽器名を判定できない回答', unknownList.reduce((n, k) => n + st.unknownTokens[k], 0), unknownList.length ? unknownList.join('、') + '（「募集設定」の「追加の表記ゆれ」に登録すると集計されます）' : ''], colorAt(1, unknownList.length ? '#fce5cd' : COLOR_PLAIN_));
  push(['楽器が未回答', st.blankInstrument, '']);

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, W);

  sheet.getRange(1, 1, sheet.getMaxRows(), W).clear();
  sheet.getRange(1, 1, rows.length, W).setValues(rows);
  sheet.getRange(1, 1, rows.length, W).setBackgrounds(bgs);

  boldRows.forEach(r => sheet.getRange(r, 1, 1, W).setFontWeight('bold'));

  sheet.setColumnWidth(1, 240);
  sheet.setColumnWidth(2, 170);
  sheet.setColumnWidth(3, 110);
}


/*******************************************************
 * 接続状況確認（メニュー⑤）
 *******************************************************/

function checkConnection() {

  const ss =
    SpreadsheetApp
      .getActiveSpreadsheet();

  const responseSheets = findResponseSheets_(ss);

  let message =
    'かながわコネクトオーケストラ\n' +
    '応募者管理システム 接続状況\n\n';

  message +=
    '現在のスプレッドシート：\n' +
    ss.getName() +
    '\n\n';

  if (responseSheets.length) {

    message += '✅ フォーム回答シート：\n';

    responseSheets.forEach(sheet => {
      message += sheet.getName() + (formUrlOf_(sheet) ? '（フォーム連携中）' : '（フォーム連携なし）') + '\n';
    });

    message += '\n';

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

  const triggerInfo = describeTriggers_();

  if (triggerInfo.error) {

    message += '⚠️ トリガーを確認できません：' + triggerInfo.error + '\n';

  } else if (triggerInfo.formSubmitCount === 1) {

    message += '✅ 自動同期トリガー：設定済み\n';

  } else if (triggerInfo.formSubmitCount > 1) {

    message += '⚠️ 自動同期トリガー：' + triggerInfo.formSubmitCount + '件（重複）→ ③ を実行すると1件に整理されます\n';

  } else {

    message +=
      '⚠️ 自動同期トリガー：未設定（あなたのアカウントでは）\n';
  }

  if (responseSheets.length) {

    const rows = responseSheets[0].getLastRow();

    message +=
      '\nフォーム回答件数：' +
      Math.max(rows - 1, 0) +
      '件';
  }

  if (applicants) {

    const app = readApplicants_(applicants);
    const stats = computeStats_(app.records, loadSettings_(ss), null, new Date());

    message += '\n応募者一覧：' + stats.total + '人（重複候補 ' + stats.duplicates.length + '件）';

    if (responseSheets.length) {
      const plan = planSync_(responseSheets, app, readLedger_(ss, false).hashes);
      message += '\n未同期のフォーム回答：' + plan.newItems.length + '件' + (plan.newItems.length ? ' → ② 既存回答を同期 を実行してください' : '');
    }
  }

  message += '\n最終自動同期：' + describeLastAutoSync_(ss);

  alert_(message);
}


function describeTriggers_() {

  try {

    const triggers = ScriptApp.getProjectTriggers();
    const list = triggers.map(t => ({
      handler: t.getHandlerFunction(),
      type: String(t.getEventType())
    }));

    return {
      list,
      formSubmitCount: list.filter(t => t.handler === CONFIG.formTriggerHandler).length
    };

  } catch (e) {
    return { list: [], formSubmitCount: 0, error: e.message };
  }
}


function describeLastAutoSync_(ss) {

  try {

    const raw = PropertiesService.getScriptProperties().getProperty(CONFIG.lastAutoSyncProperty);

    if (!raw) return '記録なし';

    const info = JSON.parse(raw);
    const when = formatDate_(ss, new Date(info.at), 'yyyy/MM/dd HH:mm');

    if (info.error) return when + ' ❌ ' + info.error;
    if (info.busy) return when + ' ⚠️ 他の同期と重なったため次回に持ち越し';

    return when + ' ✅ 追加 ' + info.added + '件';

  } catch (e) {
    return '確認できません';
  }
}


/*******************************************************
 * データ整合性チェック（メニュー⑧）
 *******************************************************/

function runIntegrityCheck() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const issues = collectIntegrityIssues_(ss);

  writeCheckSheet_(ss, issues, 'データ整合性チェック');

  alert_(summarizeIssues_(issues, 'データ整合性チェック'));

  return issues;
}


/*******************************************************
 * 重複チェック（メニュー⑨）
 *******************************************************/

function runDuplicateCheck() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.applicantsSheet);
  const issues = sheet ? collectDuplicateIssues_(readApplicants_(sheet)) : [];

  writeCheckSheet_(ss, issues, '重複チェック');

  alert_(
    summarizeIssues_(issues, '重複チェック') +
    (issues.length
      ? '\n\n対応の目安：\n・同じ人の再回答なら、古い行（集計に使用中の行）に内容を反映し、新しい行は削除してOK（削除しても同期で復活しません）\n・別人なら備考にその旨を記入'
      : '')
  );

  return issues;
}


/*
 * 整合性チェックの本体
 */
function collectIntegrityIssues_(ss) {

  const issues = [];
  const add = (level, type, sheetName, row, no, detail) => {
    issues.push({ level, type, sheet: sheetName, row: row || '', no: no === undefined || no === null ? '' : no, detail });
  };

  const settings = loadSettings_(ss);
  const index = buildInstrumentIndex_(settings);

  settings.warnings.forEach(w => add('警告', '募集設定', CONFIG.settingsSheet, '', '', w));

  const appSheet = ss.getSheetByName(CONFIG.applicantsSheet);

  if (!appSheet) {
    add('エラー', 'シートがない', CONFIG.applicantsSheet, '', '', '「応募者一覧」シートがありません（① 初期セットアップ）');
    return sortIssues_(issues);
  }

  const app = readApplicants_(appSheet);
  const A = CONFIG.applicantsSheet;

  // 見出し
  app.missing.forEach(k => {
    const field = APPLICANT_FIELDS.find(f => f.key === k) || {};
    if (field.extra || field.optional) return;
    const essential = ESSENTIAL_APPLICANT_KEYS_.indexOf(k) >= 0;
    if (k === 'syncMemo') add('確認', '列がない', A, 1, '', '「同期メモ」列がありません（⑦ 応募者管理を更新 で追加されます）');
    else add(essential ? 'エラー' : '警告', '列がない', A, 1, '', '「' + fieldLabel_(k) + '」列が見つかりません（見出し名が変更された可能性）');
  });

  if (app.emptyRows.length) {
    const rows = app.emptyRows;
    add('確認', '中身のない行', A, rows[0] + '〜' + rows[rows.length - 1], '',
      'No. や対応状況・チェックボックスなどだけが入った行が ' + rows.length + '行 あります（回答日時・メール・お名前・楽器が空）。集計には含めていません。不要なら行ごと削除して構いません');
  }

  // 1行ずつ
  const noCount = new Map();

  app.records.forEach(r => {

    if (r.noNum === null) {
      add('警告', 'No.未設定', A, r.row, '', 'No. が空欄または数字ではありません（⑦ 応募者管理を更新 で空欄に番号を振れます）');
    } else {
      noCount.set(r.noNum, (noCount.get(r.noNum) || []).concat([r.row]));
    }

    if (isBlank_(r.timestamp)) {
      add('警告', '必須項目が空欄', A, r.row, r.no, '回答日時が空欄です');
    } else if (!isDate_(r.timestamp)) {
      if (parseDateLoose_(r.timestamp)) add('確認', '日付の形式', A, r.row, r.no, '回答日時が文字として入っています（日付としては解釈できます）');
      else add('エラー', '不正な日付', A, r.row, r.no, '回答日時を日付として解釈できません');
    }

    if (!r.name) add('警告', '必須項目が空欄', A, r.row, r.no, 'お名前が空欄です');

    // 列ずれ：メールアドレス列にメールが無く、別の列にメールアドレスが入っている
    if (app.map.email !== undefined) {
      const rowValues = app.values[r.row - 1] || [];
      const emailHere = /@/.test(toStr_(r.email));
      const elsewhere = rowValues.some((v, i) => i !== app.map.email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(toStr_(v)));
      if (!emailHere && elsewhere) {
        add('エラー', '列ずれの可能性', A, r.row, r.no, '「メールアドレス」以外の列にメールアドレスが入っています。古いコードが見出しと違う並びで書き込んだ行の可能性があります（この行の楽器・対応状況は正しく集計されません）');
      }
    }
    if (isBlank_(r.email)) add('確認', '必須項目が空欄', A, r.row, r.no, 'メールアドレスが空欄です（重複判定ができません）');

    const p = parseInstrumentCell_(r.instrument, index);

    if (p.isBlank) {
      add('警告', '必須項目が空欄', A, r.row, r.no, '楽器が空欄です（集計では「楽器未回答」）');
    } else if (p.unknown.length) {
      add('警告', '未知の楽器名', A, r.row, r.no, '「' + p.unknown.join('、') + '」を判定できません（「募集設定」の「追加の表記ゆれ」に登録すると集計されます）');
    } else if (p.changed) {
      add('確認', '楽器名の表記ゆれ', A, r.row, r.no, '「' + toStr_(r.instrument) + '」→「' + p.normalized + '」として集計しています（メンテナンス＞楽器名の表記を統一 で揃えられます）');
    }

    if (!r.status) {
      add('警告', '対応状況が空欄', A, r.row, r.no, '対応状況が空欄です');
    } else if (CONFIG.statuses.indexOf(r.status) < 0) {
      add('警告', '未知のステータス', A, r.row, r.no, '対応状況「' + r.status + '」は一覧（' + CONFIG.statuses.join('／') + '）にありません');
    }

    if (!isBlank_(r.lastContact) && !isDate_(r.lastContact)) {
      if (parseDateLoose_(r.lastContact)) add('確認', '日付の形式', A, r.row, r.no, '最終連絡日が文字として入っています');
      else add('エラー', '不正な日付', A, r.row, r.no, '最終連絡日を日付として解釈できません');
    }
  });

  noCount.forEach((rows, no) => {
    if (rows.length > 1) add('エラー', 'No.重複', A, rows.join('・'), no, 'No.' + no + ' が ' + rows.length + '行あります（連絡記録の紐づけがずれます）');
  });

  collectDuplicateIssues_(app).forEach(i => issues.push(i));

  // 連絡記録
  const contacts = readContacts_(ss);
  const C = CONFIG.contactsSheet;
  const byNo = new Map();

  app.records.forEach(r => { if (r.noNum !== null && !byNo.has(r.noNum)) byNo.set(r.noNum, r); });

  const contacted = new Set();

  contacts.records.forEach(c => {

    if (c.noNum === null) {
      add('警告', '連絡記録', C, c.row, '', '応募者No. が空欄または数字ではありません');
    } else {
      const a = byNo.get(c.noNum);
      if (!a) {
        add('エラー', '連絡記録', C, c.row, c.noNum, '応募者一覧に No.' + c.noNum + ' がいません');
      } else {
        contacted.add(c.noNum);
        if (!isBlank_(c.name) && a.name && nameKey_(c.name) !== nameKey_(a.name)) {
          add('警告', '連絡記録', C, c.row, c.noNum, '氏名が応募者一覧（No.' + c.noNum + '）と一致しません（v1 の No. 振り直しでずれた可能性）');
        }
      }
    }

    if (isBlank_(c.date)) add('警告', '連絡記録', C, c.row, c.no, '日付が空欄です');
    else if (!isDate_(c.date)) add('エラー', '不正な日付', C, c.row, c.no, '日付を日付として解釈できません');

    if (!isBlank_(c.nextDate) && !isDate_(c.nextDate)) add('エラー', '不正な日付', C, c.row, c.no, '次回対応日を日付として解釈できません');
    if (!isBlank_(c.method) && CONFIG.contactMethods.indexOf(toStr_(c.method)) < 0) add('確認', '連絡記録', C, c.row, c.no, '連絡方法「' + toStr_(c.method) + '」は選択肢にありません');
    if (!isBlank_(c.state) && CONFIG.contactStates.indexOf(toStr_(c.state)) < 0) add('確認', '連絡記録', C, c.row, c.no, '対応状況「' + toStr_(c.state) + '」は選択肢にありません');
  });

  app.records.forEach(r => {
    if (r.noNum !== null && contacted.has(r.noNum) && r.status === CONFIG.newApplicantStatus) {
      add('確認', '対応状況', A, r.row, r.no, '連絡記録があるのに対応状況が「' + CONFIG.newApplicantStatus + '」です');
    }
  });

  // フォーム回答との同期
  const responseSheets = findResponseSheets_(ss);

  if (!responseSheets.length) {

    add('エラー', '同期', '（フォーム回答）', '', '', '「フォームの回答」で始まるシートが見つかりません');

  } else {

    const plan = planSync_(responseSheets, app, readLedger_(ss, false).hashes);

    plan.sheets.forEach(s => {
      if (!s.used) {
        add('確認', '同期', s.name, '', '', '同期の対象外：' + s.reason);
        return;
      }
      s.missing.forEach(k => {
        add(k === 'email' || k === 'name' || k === 'instrument' ? '警告' : '確認', '同期', s.name, 1, '', 'フォームの質問「' + fieldLabel_(k) + '」が見つかりません（質問名が変更された可能性）');
      });
    });

    if (plan.newItems.length) {
      add('エラー', '同期不一致', '（フォーム回答）', '', '', '応募者一覧に未反映のフォーム回答が ' + plan.newItems.length + '件 あります（② 既存回答を同期）');
    }

    if (plan.skippedNoTimestamp) {
      add('確認', '同期', '（フォーム回答）', '', '', 'タイムスタンプが空の行が ' + plan.skippedNoTimestamp + '件 あります（同期対象外）');
    }

    if (plan.ledgerOnly) {
      add('確認', '同期', '（フォーム回答）', '', '', '応募者一覧から削除済みの回答が ' + plan.ledgerOnly + '件 あります（再追加はしません）');
    }

    if (plan.sheets.some(s => s.used)) {
      app.records.forEach(r => {
        if (!plan.matchedRows.has(r.row)) {
          add('確認', '同期不一致', A, r.row, r.no, 'フォーム回答に対応する回答が見つかりません（手入力・回答の削除・回答日時の変更の可能性）');
        }
      });
    }
  }

  // 集計との不一致
  const fresh = computeStats_(app.records, settings, index, new Date());
  const codeSum = fresh.codeRows.reduce((n, r) => n + r.all, 0);

  if (codeSum !== fresh.total) {
    add('エラー', '集計不一致', CONFIG.instrumentsSheet, '', '', '楽器別の合計（' + codeSum + '）と応募者数（' + fresh.total + '）が一致しません');
  }

  const written = readWrittenTotal_(ss);

  if (written !== null && written !== fresh.total) {
    add('警告', '集計不一致', CONFIG.instrumentsSheet, '', '', '楽器別集計の合計（' + written + '人）が応募者一覧（' + fresh.total + '人）と一致しません（④ ダッシュボード更新 で最新になります）');
  }

  return sortIssues_(issues);
}


/*
 * 重複の検出（エラー：二重取込／警告：同じメール／確認：同名）
 */
function collectDuplicateIssues_(app) {

  const issues = [];
  const A = CONFIG.applicantsSheet;
  const strict = new Map();

  app.records.forEach(r => {
    if (isBlank_(r.timestamp)) return;
    const key = normalizeKeyValue(r.timestamp) + '|' + normalizeKeyValue(r.email);
    strict.set(key, (strict.get(key) || []).concat([r]));
  });

  strict.forEach(list => {
    if (list.length > 1) {
      issues.push({ level: 'エラー', type: '二重取込', sheet: A, row: list.map(r => r.row).join('・'), no: noLabel_(list), detail: '同じ回答（回答日時＋メールアドレス）が ' + list.length + '行あります。1行を残して削除してください' });
    }
  });

  groupByEmail_(app.records).forEach(list => {
    if (list.length < 2 || !list[0].emailKey) return;
    issues.push({ level: '警告', type: '重複応募の可能性', sheet: A, row: list.map(r => r.row).join('・'), no: noLabel_(list), detail: '同じメールアドレスの応募が ' + list.length + '件あります（集計は ' + noLabel_([list[0]]) + ' を使用）' });
  });

  const byName = new Map();

  app.records.forEach(r => {
    const k = nameKey_(r.name);
    if (k) byName.set(k, (byName.get(k) || []).concat([r]));
  });

  byName.forEach(list => {
    if (list.length < 2) return;
    const emails = new Set(list.map(r => r.emailKey));
    if (emails.size < 2) return; // 同じメールなら上で報告済み
    issues.push({ level: '確認', type: '同名の応募者', sheet: A, row: list.map(r => r.row).join('・'), no: noLabel_(list), detail: '同じお名前で別のメールアドレスの応募があります（別人なら問題ありません）' });
  });

  return sortIssues_(issues);
}


function sortIssues_(issues) {

  const rank = { 'エラー': 0, '警告': 1, '確認': 2 };

  return issues.sort((a, b) => rank[a.level] - rank[b.level]);
}


function summarizeIssues_(issues, title) {

  const count = level => issues.filter(i => i.level === level).length;
  const errors = count('エラー');
  const warnings = count('警告');
  const infos = count('確認');

  if (errors + warnings === 0) {
    return title + '：問題ありません' + (infos ? '\n（参考情報 ' + infos + '件は「' + CONFIG.checkSheet + '」シートに記載）' : '');
  }

  const head = issues
    .filter(i => i.level !== '確認')
    .slice(0, 10)
    .map(i => '・[' + i.level + '] ' + i.type + (i.no !== '' ? '（' + (String(i.no).indexOf('No.') === 0 ? i.no : 'No.' + i.no) + '）' : '') + '：' + i.detail);

  return title + '：エラー ' + errors + '件／警告 ' + warnings + '件／確認 ' + infos + '件\n\n' +
    head.join('\n') +
    (errors + warnings > 10 ? '\n…' : '') +
    '\n\n詳細は「' + CONFIG.checkSheet + '」シートを確認してください。';
}


function writeCheckSheet_(ss, issues, title) {

  const sheet = getOrCreateOwnedSheet_(ss, CONFIG.checkSheet, CHECK_TITLE_);
  const W = 6;
  const rows = [
    [CHECK_TITLE_, '', '', '', '', ''],
    ['実行内容', title, '実行日時', formatDate_(ss, new Date(), 'yyyy/MM/dd HH:mm'), '', ''],
    [summarizeIssues_(issues, title).split('\n')[0], '', '', '', '', ''],
    ['', '', '', '', '', ''],
    ['重要度', '種類', 'シート', '行', '応募者No.', '内容']
  ];
  const bgs = [];

  issues.forEach(i => rows.push([i.level, i.type, i.sheet, String(i.row), String(i.no), i.detail]));

  rows.forEach((r, n) => {
    const color = n === 4 ? COLOR_HEADER_ : n < 4 ? COLOR_PLAIN_ : (r[0] === 'エラー' ? '#f4cccc' : r[0] === '警告' ? '#fff2cc' : COLOR_PLAIN_);
    bgs.push(new Array(W).fill(color));
  });

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, W);

  sheet.getRange(1, 1, sheet.getMaxRows(), W).clear();
  sheet.getRange(1, 1, rows.length, W).setValues(rows);
  sheet.getRange(1, 1, rows.length, W).setBackgrounds(bgs);
  sheet.getRange(1, 1, 1, W).setFontWeight('bold');
  sheet.getRange(3, 1, 1, W).setFontWeight('bold');
  sheet.getRange(5, 1, 1, W).setFontWeight('bold');
  sheet.setFrozenRows(5);
}


function readWrittenTotal_(ss) {

  const sheet = ss.getSheetByName(CONFIG.instrumentsSheet);

  if (!sheet || sheet.getLastRow() < 2) return null;

  const values = sheet.getRange(1, 1, sheet.getLastRow(), Math.min(Math.max(sheet.getLastColumn(), 4), 13)).getValues();
  const header = values[0].map(toStr_);
  const col = header.indexOf('応募者数');

  if (col < 0) return null;

  const total = values.find(r => toStr_(r[0]) === '合計');

  return total ? toNumberOrNull_(total[col]) : null;
}


/*******************************************************
 * システム診断（メニュー⑩）
 *
 * 設定・トリガー・列の対応・楽器名の判定結果などを一覧にする。
 * 個人情報（名前・メールアドレス）は出力しない。
 *******************************************************/

function runSystemDiagnosis() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const rows = [];
  let problems = 0;

  const add = (item, value, judge) => {
    rows.push([item, value === undefined ? '' : String(value), judge || '']);
    if (judge === '❌' || judge === '⚠️') problems++;
  };
  const section = title => rows.push(['【' + title + '】', '', '']);

  section('基本情報');
  add('スプレッドシート', ss.getName(), '');
  add('タイムゾーン', tz_(ss), '');
  add('診断日時', formatDate_(ss, new Date(), 'yyyy/MM/dd HH:mm'), '');

  section('応募者一覧');
  const appSheet = ss.getSheetByName(CONFIG.applicantsSheet);
  let app = emptyApplicants_();

  if (!appSheet) {
    add('シート', 'ありません（① 初期セットアップ）', '❌');
  } else {
    app = readApplicants_(appSheet);
    add('行数（応募件数）', app.records.length, '');
    if (app.emptyRows.length) add('中身のない行（集計対象外）', app.emptyRows.length + '行（' + app.emptyRows[0] + '〜' + app.emptyRows[app.emptyRows.length - 1] + '行目）', '⚠️');
    APPLICANT_FIELDS.forEach(f => {
      const c = app.map[f.key];
      if (c === undefined && f.extra) return;
      const essential = ESSENTIAL_APPLICANT_KEYS_.indexOf(f.key) >= 0;
      add('列：' + f.header, c === undefined ? '見つかりません' + (f.optional ? '（この列が無くても動作します）' : '') : columnLetter_(c + 1) + '列「' + app.headers[c] + '」', c === undefined ? (essential ? '❌' : f.optional ? '' : '⚠️') : '✅');
    });
    const extra = app.headers.filter((h, i) => h && Object.keys(app.map).every(k => app.map[k] !== i));
    if (extra.length) add('運営が追加した列（同期では触りません）', extra.join('、'), '');
  }

  section('フォーム回答シート');
  const responseSheets = findResponseSheets_(ss);

  if (!responseSheets.length) {
    add('回答シート', '「' + CONFIG.responseSheetPrefix + '」で始まるシートがありません', '❌');
  } else {
    const ledger = readLedger_(ss, false);
    const plan = planSync_(responseSheets, app, ledger.hashes);
    plan.sheets.forEach(s => {
      add('シート「' + s.name + '」', (s.linked ? 'フォーム連携中' : 'フォーム連携なし') + '／回答 ' + s.rows + '行', s.used ? '✅' : '⚠️');
      if (!s.used) {
        add('　対象外の理由', s.reason, '⚠️');
        return;
      }
      formFieldDefs_().forEach(f => {
        const c = s.map[f.key];
        add('　質問：' + fieldLabel_(f.key), c === undefined ? '見つかりません' : '「' + s.headers[c] + '」', c === undefined ? (f.key === 'timestamp' ? '❌' : '⚠️') : '✅');
      });
      const used = Object.keys(s.map).map(k => s.map[k]);
      const extra = s.headers.filter((h, i) => h && used.indexOf(i) < 0);
      if (extra.length) add('　未使用の質問（新しく追加された質問など）', extra.join('、'), '');
    });
    add('未同期の回答', plan.newItems.length + '件', plan.newItems.length ? '⚠️' : '✅');
    add('同期履歴（取込済みの記録）', ledger.hashes.size + '件', '');
    if (plan.ledgerOnly) add('削除済みのため再追加しない回答', plan.ledgerOnly + '件', '');
  }

  section('トリガー（あなたのアカウント分）');
  const t = describeTriggers_();

  if (t.error) {
    add('トリガー一覧', '取得できません：' + t.error, '⚠️');
  } else {
    add('自動同期（' + CONFIG.formTriggerHandler + '）', t.formSubmitCount + '件', t.formSubmitCount === 1 ? '✅' : t.formSubmitCount === 0 ? '⚠️' : '⚠️');
    if (t.formSubmitCount === 0) add('　対処', '③ フォーム送信トリガー設定 を実行（他の管理者が設定済みなら不要）', '');
    if (t.formSubmitCount > 1) add('　対処', '③ を実行すると1件に整理されます（ロックがあるので二重登録はされません）', '');
    t.list.forEach(x => add('　登録済み', x.handler + '（' + x.type + '）', ''));
    add('　補足', '他の管理者のアカウントで設定されたトリガーはここには表示されません', '');
  }

  add('最終自動同期', describeLastAutoSync_(ss), '');

  section('募集設定');
  const settings = loadSettings_(ss);
  const index = buildInstrumentIndex_(settings);
  add('募集設定シート', settings.fromSheet ? 'あり' : 'なし（初期値で動作中。④ で作成されます）', settings.fromSheet ? '✅' : '⚠️');
  add('団員目標／判断ライン／最低人数', settings.targetMembers + '／' + settings.decisionMembers + '／' + settings.minimumMembers, '');
  add('除外ステータス', settings.excludedStatuses.join('、') || 'なし', '');
  add('編集時の自動更新', settings.autoUpdateOnEdit ? 'はい' : 'いいえ', '');
  settings.warnings.forEach(w => add('設定の警告', w, '⚠️'));
  index.collisions
    .filter(c => !INSTRUMENT_CATALOG.some(item => item[0] === c.code && item[5].indexOf(c.alias) >= 0))
    .forEach(c => add('表記ゆれの重複', '「' + c.alias + '」が ' + c.existing + ' と ' + c.code + ' の両方に登録されています（' + c.code + ' を優先）', '⚠️'));

  section('楽器名の判定（フォーム回答の値）');
  const seen = {};

  responseSheets.forEach(sheet => {
    const lastRow = sheet.getLastRow();
    const lastCol = sheet.getLastColumn();
    if (lastRow < 2 || lastCol < 1) return;
    const values = sheet.getRange(1, 1, lastRow, lastCol).getValues();
    const res = resolveColumns_(values[0].map(toStr_), formFieldDefs_(), true);
    if (res.map.instrument === undefined) return;
    for (let i = 1; i < values.length; i++) {
      const v = toStr_(values[i][res.map.instrument]);
      seen[v] = (seen[v] || 0) + 1;
    }
  });

  Object.keys(seen).sort().forEach(v => {
    const p = parseInstrumentCell_(v, index);
    add('「' + (v || '（空欄）') + '」（' + seen[v] + '件）', p.isBlank ? '未回答' : p.normalized + (p.unknown.length ? '（判定できない：' + p.unknown.join('、') + '）' : ''), p.isBlank || p.unknown.length ? '⚠️' : '✅');
  });

  const sheet = getOrCreateOwnedSheet_(ss, CONFIG.diagnosisSheet, DIAGNOSIS_TITLE_);
  const all = [[DIAGNOSIS_TITLE_, '', ''], ['項目', '内容', '判定']].concat(rows);

  ensureRows_(sheet, all.length);
  ensureCols_(sheet, 3);
  sheet.getRange(1, 1, sheet.getMaxRows(), 3).clear();
  sheet.getRange(1, 1, all.length, 3).setValues(all);
  sheet.getRange(1, 1, 2, 3).setFontWeight('bold');
  sheet.getRange(2, 1, 1, 3).setBackground(COLOR_HEADER_);
  sheet.setColumnWidth(1, 320);
  sheet.setColumnWidth(2, 420);
  sheet.setFrozenRows(2);

  alert_(
    'システム診断が完了しました。\n\n' +
    (problems ? '⚠️ 確認が必要な項目：' + problems + '件' : '✅ 問題は見つかりませんでした') +
    '\n\n詳細は「' + sheet.getName() + '」シートを確認してください。'
  );

  return { problems, rows };
}


/*******************************************************
 * セルフテスト（メンテナンス）
 *
 * Tests.gs の関数を実行する。シートは一切変更しない。
 *******************************************************/

function runSelfTests() {

  if (typeof runAllTests_ !== 'function') {
    alert_('テスト用ファイル（Tests.gs）が追加されていません。\nApps Script エディタで Tests.gs を追加してから実行してください。');
    return null;
  }

  const r = runAllTests_();

  alert_(
    'セルフテスト結果\n\n' +
    '成功：' + r.passed + '件\n' +
    '失敗：' + r.failed + '件' +
    (r.failed ? '\n\n' + r.failures.slice(0, 15).join('\n') : '\n\nすべて成功しました。') +
    '\n\n※ 本番データ（シート）は一切変更していません。'
  );

  return r;
}


/*******************************************************
 * 募集設定シート
 *******************************************************/

function ensureSettingsSheet_(ss) {

  const existing = findOwnedSheet_(ss, CONFIG.settingsSheet, SETTINGS_TITLE_);

  if (existing && existing.getLastRow() > 0) return existing;

  // v1 の楽器別集計・活動状況に運営が入れた人数があれば引き継ぐ
  const legacy = readLegacyTargets_(ss);
  const sheet = existing || getOrCreateOwnedSheet_(ss, CONFIG.settingsSheet, SETTINGS_TITLE_);
  const W = PARTS_TABLE_HEADER_.length;
  const rows = [];

  const push = cells => {
    const line = cells.slice(0, W);
    while (line.length < W) line.push('');
    rows.push(line);
  };

  push([SETTINGS_TITLE_]);
  push(['項目', '値', '説明']);

  SETTINGS_ITEMS_.forEach(item => {
    const value = legacy.overall[item.key] !== undefined ? legacy.overall[item.key] : item.def();
    push([item.label, value, item.desc]);
  });

  push([]);
  push(['■ 楽器ごとの募集人数（目標人数・最低人数は空欄可。空欄の楽器は「目標未設定」として扱います）']);
  push(PARTS_TABLE_HEADER_);

  INSTRUMENT_CATALOG.forEach(item => {
    const old = legacy.parts[item[0]] || {};
    const target = old.target !== undefined ? old.target : item[3];
    const min = old.min !== undefined ? old.min : item[4];
    push([item[0], item[1], item[2], blankIfNull_(target), blankIfNull_(min), '']);
  });

  push([]);
  push(['※ 楽器コードを追加すると新しい楽器として集計されます。「パート」が同じ楽器はダッシュボードでまとめて表示されます。']);
  push(['※ フォームの楽器名が判定できない場合は「追加の表記ゆれ」に書いてください（例：Tuba の行に「チューバー」）。']);
  push(['※ 変更後は ④ ダッシュボード更新（または応募者一覧の編集）で集計に反映されます。']);

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, W);
  sheet.getRange(1, 1, rows.length, W).setValues(rows);
  sheet.getRange(1, 1, 2, W).setFontWeight('bold');
  sheet.getRange(2, 1, 1, W).setBackground(COLOR_HEADER_);

  const tableHeaderRow = rows.findIndex(r => r[0] === PARTS_TABLE_HEADER_[0]) + 1;

  sheet.getRange(tableHeaderRow, 1, 1, W).setFontWeight('bold').setBackground(COLOR_HEADER_);
  sheet.setColumnWidth(1, 300);
  sheet.setColumnWidth(3, 120);

  return sheet;
}


function readLegacyTargets_(ss) {

  const result = { overall: {}, parts: {} };

  try {

    const inst = ss.getSheetByName(CONFIG.instrumentsSheet);

    if (inst && inst.getLastRow() >= 2) {
      const values = inst.getRange(1, 1, inst.getLastRow(), Math.max(Math.min(inst.getLastColumn(), 13), 3)).getValues();
      const h = values[0].map(toStr_);
      const cCode = h.indexOf('楽器');
      const cTarget = h.indexOf('目標人数');
      const cMin = h.indexOf('最低人数');
      if (cCode >= 0 && cTarget >= 0 && cMin >= 0) {
        for (let i = 1; i < values.length; i++) {
          const code = toStr_(values[i][cCode]);
          if (!code || code === '合計' || code === '最終更新' || code.charAt(0) === '※') continue;
          const target = toNumberOrNull_(values[i][cTarget]);
          const min = toNumberOrNull_(values[i][cMin]);
          if (target !== null || min !== null) result.parts[code] = { target, min };
        }
      }
    }

    const status = ss.getSheetByName(CONFIG.statusSheet);

    if (status && status.getLastRow() >= 2) {
      const values = status.getRange(1, 1, status.getLastRow(), 2).getValues();
      const labelToKey = { '団員目標': 'targetMembers', '演奏会開催判断ライン': 'decisionMembers', '最低人数': 'minimumMembers' };
      values.forEach(r => {
        const key = labelToKey[toStr_(r[0])];
        const n = toNumberOrNull_(r[1]);
        if (key && n !== null && n > 0) result.overall[key] = n;
      });
    }

  } catch (e) {
    console.warn('旧シートから設定を読み取れませんでした: ' + e.message);
  }

  return result;
}


function defaultSettings_() {

  const s = { fromSheet: false, warnings: [], parts: defaultParts_() };

  SETTINGS_ITEMS_.forEach(item => {
    s[item.key] = parseSettingValue_(item, item.def());
  });

  return s;
}


function loadSettings_(ss) {

  const s = defaultSettings_();
  const sheet = findOwnedSheet_(ss, CONFIG.settingsSheet, SETTINGS_TITLE_);

  if (!sheet || sheet.getLastRow() === 0) return s;

  s.fromSheet = true;

  const values = sheet.getRange(1, 1, sheet.getLastRow(), Math.max(sheet.getLastColumn(), PARTS_TABLE_HEADER_.length)).getValues();

  values.forEach(row => {
    const item = SETTINGS_ITEMS_.find(x => x.label === toStr_(row[0]));
    if (!item) return;
    const parsed = parseSettingValue_(item, row[1]);
    if (parsed === null) {
      s.warnings.push('「' + item.label + '」の値「' + toStr_(row[1]) + '」を読み取れないため初期値（' + item.def() + '）を使います');
      s[item.key] = parseSettingValue_(item, item.def());
    } else {
      s[item.key] = parsed;
    }
  });

  const headerRow = values.findIndex(r => toStr_(r[0]) === PARTS_TABLE_HEADER_[0]);

  if (headerRow >= 0) {

    const h = values[headerRow].map(toStr_);
    const col = name => h.indexOf(name);
    const cCode = 0;
    const cName = col('楽器名');
    const cPart = col('パート');
    const cTarget = col('目標人数');
    const cMin = col('最低人数');
    const cAlias = h.findIndex(x => x.indexOf('追加の表記ゆれ') === 0);
    const parts = [];

    for (let i = headerRow + 1; i < values.length; i++) {

      const row = values[i];
      const code = toStr_(row[cCode]);

      if (!code || code.charAt(0) === '※' || code.charAt(0) === '■') continue;

      const target = cTarget >= 0 ? toNumberOrNull_(row[cTarget]) : null;
      const min = cMin >= 0 ? toNumberOrNull_(row[cMin]) : null;

      if (cTarget >= 0 && !isBlank_(row[cTarget]) && target === null) s.warnings.push('楽器「' + code + '」の目標人数「' + toStr_(row[cTarget]) + '」が数字ではありません');
      if (cMin >= 0 && !isBlank_(row[cMin]) && min === null) s.warnings.push('楽器「' + code + '」の最低人数「' + toStr_(row[cMin]) + '」が数字ではありません');

      parts.push({
        code,
        name: cName >= 0 ? toStr_(row[cName]) : '',
        part: cPart >= 0 ? toStr_(row[cPart]) : '',
        target,
        min,
        aliases: cAlias >= 0 ? splitInstrumentList_(toStr_(row[cAlias])) : []
      });
    }

    s.parts = parts;

  } else {
    s.warnings.push('「楽器コード」の表が見つからないため、楽器ごとの人数は初期値を使います');
  }

  if (!(s.targetMembers > 0)) s.warnings.push('団員目標が0以下です');

  return s;
}


function parseSettingValue_(item, value) {

  if (item.type === 'number') {
    const n = toNumberOrNull_(value);
    return n === null ? null : n;
  }

  if (item.type === 'list') {
    return toStr_(value).split(/[,、，\n]+/).map(s => s.trim()).filter(Boolean);
  }

  if (item.type === 'bool') {
    if (value === true || value === false) return value;
    const v = nfkc_(toStr_(value)).toLowerCase();
    if (['はい', 'yes', 'true', '1', 'on', 'する', '有効'].indexOf(v) >= 0) return true;
    if (['いいえ', 'no', 'false', '0', 'off', 'しない', '無効', ''].indexOf(v) >= 0) return false;
    return null;
  }

  return value;
}


/*******************************************************
 * シートの読み取り
 *******************************************************/

function readApplicants_(sheet) {

  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();

  if (lastRow === 0 || lastCol === 0) {
    const empty = emptyApplicants_();
    empty.sheet = sheet;
    return empty;
  }

  const values = sheet.getRange(1, 1, lastRow, lastCol).getValues();
  const headers = values[0].map(toStr_);
  const res = resolveColumns_(headers, applicantFieldDefs_(), false);
  const records = [];
  const emptyRows = [];

  for (let i = 1; i < values.length; i++) {

    const row = values[i];

    if (row.every(v => isBlank_(v))) continue;

    // No.・対応状況・チェックボックス・数式だけが入った行は応募者として数えない
    if (!hasApplicantData_(row, res.map)) {
      emptyRows.push(i + 1);
      continue;
    }

    const get = key => (res.map[key] === undefined ? '' : row[res.map[key]]);
    const no = get('no');

    records.push({
      row: i + 1,
      no: no,
      noNum: toNumberOrNull_(no),
      timestamp: get('timestamp'),
      email: get('email'),
      emailKey: emailKey_(get('email')),
      name: toStr_(get('name')),
      instrument: get('instrument'),
      status: toStr_(get('status')),
      concert: get('concert'),
      lastContact: get('lastContact'),
      memo: toStr_(get('syncMemo')),
      nickname: toStr_(get('nickname')),
      appId: toStr_(get('appId')),
      appEmail: toStr_(get('appEmail')),
      appUsage: toStr_(get('appUsage')),
      joinIntent: toStr_(get('joinIntent')),
      joinAnsweredAt: get('joinAnsweredAt'),
      joinMailAt: get('joinMailAt'),
      firebaseState: toStr_(get('firebaseState'))
    });
  }

  return { sheet, headers, map: res.map, missing: res.missing, values, records, emptyRows };
}


/*
 * 応募者としての中身がある行か（回答日時・メールアドレス・お名前・楽器のどれかが入っている）
 *
 * v1 は「最終行まで全部に No. を振る」動きだったため、1000行目付近まで No. だけの行が
 * できていることがある。チェックボックス（FALSE）や数式だけの列も同様。
 */
function hasApplicantData_(row, map) {

  return ['timestamp', 'email', 'name', 'instrument'].some(key => {
    const c = map[key];
    if (c === undefined) return false;
    const v = row[c];
    return typeof v === 'boolean' ? false : !isBlank_(v);
  });
}


function emptyApplicants_() {

  return { sheet: null, headers: [], map: {}, missing: [], values: [], records: [], emptyRows: [] };
}


function readContacts_(ss) {

  const sheet = ss.getSheetByName(CONFIG.contactsSheet);

  if (!sheet || sheet.getLastRow() < 1 || sheet.getLastColumn() < 1) {
    return { sheet, headers: [], map: {}, missing: [], records: [] };
  }

  const values = sheet.getRange(1, 1, sheet.getLastRow(), sheet.getLastColumn()).getValues();
  const headers = values[0].map(toStr_);
  const res = resolveColumns_(headers, contactFieldDefs_(), false);
  const records = [];

  for (let i = 1; i < values.length; i++) {

    const row = values[i];

    if (row.every(v => isBlank_(v))) continue;

    const get = key => (res.map[key] === undefined ? '' : row[res.map[key]]);
    const no = get('no');

    records.push({
      row: i + 1,
      date: get('date'),
      no,
      noNum: toNumberOrNull_(no),
      name: get('name'),
      method: get('method'),
      nextDate: get('nextDate'),
      nextAction: get('nextAction'),
      state: get('state')
    });
  }

  return { sheet, headers, map: res.map, missing: res.missing, records };
}


function readLedger_(ss, createIfMissing) {

  let sheet = ss.getSheetByName(CONFIG.ledgerSheet);

  if (!sheet && createIfMissing) {
    sheet = insertSheetQuietly_(ss, CONFIG.ledgerSheet);
    sheet.getRange(1, 1, 1, LEDGER_HEADERS_.length).setValues([LEDGER_HEADERS_]);
    sheet.setFrozenRows(1);
    try {
      sheet.hideSheet();
    } catch (e) {
      // 非表示にできなくても動作には影響しない
    }
  }

  const hashes = new Set();

  if (sheet && sheet.getLastRow() >= 2) {
    sheet.getRange(2, 1, sheet.getLastRow() - 1, 1).getValues().forEach(r => {
      const h = toStr_(r[0]);
      if (h) hashes.add(h);
    });
  }

  return { sheet, hashes };
}


function appendLedger_(sheet, rows) {

  if (!sheet || !rows.length) return;

  const start = sheet.getLastRow() + 1;

  ensureRows_(sheet, start + rows.length - 1);
  ensureCols_(sheet, LEDGER_HEADERS_.length);
  sheet.getRange(start, 1, rows.length, LEDGER_HEADERS_.length).setValues(rows);
}


/*******************************************************
 * 見出し名で列を探す
 *
 * 1. 完全一致
 * 2. 全角/半角・空白・末尾の「？」を無視して一致
 * 3. （フォーム回答のみ）前方一致：質問名の後ろに補足が付いた場合など
 *    例：「どのくらい練習に参加できそうですか？（目安）」
 *******************************************************/

function resolveColumns_(headers, fields, allowPrefix) {

  const norm = headers.map(normalizeHeader_);
  const map = {};
  const used = {};

  fields.forEach(f => {
    for (const c of f.candidates) {
      const i = headers.findIndex((h, idx) => !used[idx] && h === c);
      if (i >= 0) {
        map[f.key] = i;
        used[i] = true;
        break;
      }
    }
  });

  fields.forEach(f => {
    if (map[f.key] !== undefined) return;
    for (const c of f.candidates) {
      const nc = normalizeHeader_(c);
      const i = norm.findIndex((h, idx) => !used[idx] && h && h === nc);
      if (i >= 0) {
        map[f.key] = i;
        used[i] = true;
        break;
      }
    }
  });

  if (allowPrefix) {

    const options = [];

    fields.forEach(f => {
      if (map[f.key] !== undefined) return;
      f.candidates.forEach(c => {
        const nc = normalizeHeader_(c);
        if (nc.length < 2) return;
        norm.forEach((h, idx) => {
          if (!used[idx] && h && h.indexOf(nc) === 0) options.push({ key: f.key, idx, score: nc.length });
        });
      });
    });

    options
      .sort((a, b) => (b.score - a.score) || (a.idx - b.idx))
      .forEach(o => {
        if (map[o.key] !== undefined || used[o.idx]) return;
        map[o.key] = o.idx;
        used[o.idx] = true;
      });
  }

  return {
    map,
    missing: fields.filter(f => map[f.key] === undefined).map(f => f.key)
  };
}


function applicantFieldDefs_() {

  return APPLICANT_FIELDS.map(f => ({ key: f.key, candidates: [f.header].concat(f.aliases || []) }));
}


function formFieldDefs_() {

  return APPLICANT_FIELDS.filter(f => f.form).map(f => ({ key: f.key, candidates: f.form }));
}


function contactFieldDefs_() {

  return CONTACT_FIELDS.map(f => ({ key: f.key, candidates: [f.header].concat(f.aliases || []) }));
}


function fieldLabel_(key) {

  const f = APPLICANT_FIELDS.find(x => x.key === key);

  return f ? f.header : key;
}


function normalizeHeader_(value) {

  return nfkc_(toStr_(value))
    .replace(/\s+/g, '')
    .replace(/[?？*＊:：]+$/, '')
    .toLowerCase();
}


/*******************************************************
 * 共通の小さな関数
 *******************************************************/

function toStr_(value) {

  if (value === null || value === undefined) return '';

  return String(value).trim();
}


function nfkc_(value) {

  const s = value === null || value === undefined ? '' : String(value);

  return typeof s.normalize === 'function' ? s.normalize('NFKC') : s;
}


function isDate_(value) {

  return Object.prototype.toString.call(value) === '[object Date]' && !isNaN(value.getTime());
}


function isBlank_(value) {

  if (isDate_(value)) return false;

  return toStr_(value) === '';
}


function toNumberOrNull_(value) {

  if (value === null || value === undefined || value === '' || isDate_(value)) return null;
  if (typeof value === 'number') return isFinite(value) ? value : null;
  if (typeof value === 'boolean') return null;

  const s = nfkc_(String(value)).replace(/[,\s人名]/g, '');

  if (!s) return null;

  const n = Number(s);

  return isFinite(n) ? n : null;
}


function parseDateLoose_(value) {

  if (isDate_(value)) return value;

  const s = nfkc_(toStr_(value))
    .replace(/年|月/g, '/')
    .replace(/日/g, ' ')
    .replace(/\([^)]*\)/g, ' ')
    .replace(/-/g, '/')
    .trim();

  if (!s || !/\d/.test(s)) return null;

  const d = new Date(s);

  return isNaN(d.getTime()) ? null : d;
}


function startOfDay_(date) {

  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}


function emailKey_(value) {

  return nfkc_(toStr_(value)).toLowerCase();
}


function nameKey_(value) {

  return nfkc_(toStr_(value)).replace(/\s+/g, '').toLowerCase();
}


/*
 * 回答日時の表記が変わっても照合できるキー（秒単位）
 */
function looseKey_(timestamp, email) {

  const d = parseDateLoose_(timestamp);
  const t = d ? String(Math.floor(d.getTime() / 1000)) : toStr_(timestamp);

  return emailKey_(email) + '|' + t;
}


/*
 * 同期履歴に保存するハッシュ（メールアドレスそのものは保存しない）
 */
function hashKey_(key) {

  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, key, Utilities.Charset.UTF_8);

  return bytes.map(b => ((b + 256) % 256).toString(16).padStart(2, '0')).join('');
}


/*
 * 「=」などで始まる回答が数式として実行されないようにする
 * （例：=IMPORTXML(...) でシートの内容が外部に送られるのを防ぐ）
 */
function sanitizeForSheet_(value) {

  if (typeof value !== 'string') return value;
  if (!/^[=+\-@]/.test(value)) return value;
  if (/^[-+]?\d+(\.\d+)?$/.test(value.trim())) return value;

  return "'" + value;
}


/*
 * 同じメールアドレスごとにまとめる（No. の小さい順。メール空欄は1行ずつ）
 */
function groupByEmail_(records) {

  const groups = new Map();

  records.forEach(r => {
    const id = r.emailKey ? 'mail:' + r.emailKey : 'row:' + r.row;
    if (!groups.has(id)) groups.set(id, []);
    groups.get(id).push(r);
  });

  groups.forEach(list => list.sort(compareByNo_));

  return groups;
}


function compareByNo_(a, b) {

  const na = a.noNum === null || a.noNum === undefined ? Infinity : a.noNum;
  const nb = b.noNum === null || b.noNum === undefined ? Infinity : b.noNum;

  if (na !== nb) return na < nb ? -1 : 1;

  return a.row - b.row;
}


function noLabel_(records) {

  return records.map(r => (isBlank_(r.no) ? '行' + r.row : 'No.' + toStr_(r.no))).join('・');
}


function formatNoList_(list) {

  if (!list.length) return '';

  const labels = list.map(n => (String(n).indexOf('行') === 0 ? String(n) : 'No.' + n));

  return labels.slice(0, 20).join('、') + (labels.length > 20 ? ' …ほか' + (labels.length - 20) + '件' : '');
}


function statusListForDisplay_(counts) {

  const list = CONFIG.statuses.slice();

  Object.keys(counts).forEach(k => {
    if (list.indexOf(k) < 0) list.push(k);
  });

  return list;
}


function blankIfNull_(value) {

  return value === null || value === undefined ? '' : value;
}


function percentText_(count, base) {

  if (!(Number(base) > 0)) return '—';

  return Math.round((count / base) * 1000) / 10 + '%';
}


function bar_(count, base) {

  if (!(Number(base) > 0)) return '';

  const filled = Math.max(0, Math.min(10, Math.round((count / base) * 10)));

  return '■'.repeat(filled) + '□'.repeat(10 - filled);
}


function columnLetter_(n) {

  let s = '';

  while (n > 0) {
    const m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = Math.floor((n - 1) / 26);
  }

  return s;
}


function tz_(ss) {

  try {
    return ss.getSpreadsheetTimeZone() || Session.getScriptTimeZone();
  } catch (e) {
    return Session.getScriptTimeZone();
  }
}


function formatDate_(ss, date, pattern) {

  return Utilities.formatDate(date, tz_(ss), pattern);
}


function ensureRows_(sheet, lastRowNeeded) {

  const max = sheet.getMaxRows();

  if (lastRowNeeded > max) sheet.insertRowsAfter(max, lastRowNeeded - max);
}


function ensureCols_(sheet, lastColNeeded) {

  const max = sheet.getMaxColumns();

  if (lastColNeeded > max) sheet.insertColumnsAfter(max, lastColNeeded - max);
}


/*
 * システムが作るシートを開く／作る。
 * 同じ名前の「運営が作った別のシート」があれば上書きせず、名前に（自動）を付けて別に作る。
 */
function findOwnedSheet_(ss, name, marker) {

  const sheet = ss.getSheetByName(name);

  if (sheet && (isEmptySheet_(sheet) || toStr_(sheet.getRange(1, 1).getValue()) === marker)) return sheet;

  return ss.getSheetByName(name + '（自動）');
}


function getOrCreateOwnedSheet_(ss, name, marker) {

  const found = findOwnedSheet_(ss, name, marker);

  if (found) return found;

  return insertSheetQuietly_(ss, ss.getSheetByName(name) ? name + '（自動）' : name);
}


function isEmptySheet_(sheet) {

  return sheet.getLastRow() === 0 && sheet.getLastColumn() === 0;
}


/*
 * シートを追加しても、見ている画面（アクティブシート）は変えない
 */
function insertSheetQuietly_(ss, name) {

  let active = null;

  try {
    active = ss.getActiveSheet();
  } catch (e) {
    active = null;
  }

  const sheet = ss.insertSheet(name);

  try {
    if (active) ss.setActiveSheet(active);
  } catch (e) {
    // トリガー実行時など、画面が無い場合は何もしない
  }

  return sheet;
}


/*
 * ダイアログ（トリガー実行時は画面が無いのでログに残すだけ）
 */
function ui_() {

  try {
    return SpreadsheetApp.getUi();
  } catch (e) {
    return null;
  }
}


function alert_(message) {

  const ui = ui_();

  if (ui) ui.alert(message);
  else console.log(message);
}


function confirm_(title, message) {

  const ui = ui_();

  if (!ui) return false;

  return ui.alert(title, message, ui.ButtonSet.YES_NO) === ui.Button.YES;
}


function toast_(ss, message) {

  try {
    ss.toast(message, 'オーケストラ管理', 5);
  } catch (e) {
    // トースト表示できない環境では何もしない
  }
}
