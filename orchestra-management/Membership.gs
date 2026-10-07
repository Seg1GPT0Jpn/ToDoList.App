/*******************************************************
 * 正式加入確認  Membership.gs
 *
 * 「正式加入確認 → 正式参加 → 団員アプリ利用」の流れを管理します。
 *
 *   1. 正式加入確認フォームを作る（このスプレッドシートに回答がたまる）
 *   2. 参加希望者へ正式加入確認メールを 1人ずつ 送る（宛先は他の人に見えない）
 *   3. フォームの回答を応募者一覧とメールアドレスで照合する
 *   4. 運営が内容を確認し、対応状況を「正式参加」に変える（自動では変えない）
 *   5. 正式参加の人が「アプリ利用」の対象になり、団員アプリへの同期で登録される
 *
 * 安全のための仕組み
 *   ・同じ送信回で同じアドレスには 1通だけ（_送信履歴にハッシュで記録。メールアドレス自体は保存しない）
 *   ・送信前に確認画面。1回の上限・Gmail の残り送信数を超えない
 *   ・送信元アカウントが設定と違う場合は送らない
 *   ・対応状況は自動で変えない。応募者一覧で書き換えるのは、この機能が追加した列と「最終連絡日」だけ
 *   ・フォームの回答で応募者を追加しない（見つからない人は「要確認」として照合シートに残す）
 *   ・ダイアログ・ログ・照合シートにメールアドレスを出さない（照合シートは一部を伏せ字）
 *******************************************************/

const MEMBERSHIP = {
  settingsSheet: '加入確認設定',
  settingsTitle: '加入確認設定（正式加入確認メール・フォーム）',
  reviewSheet: '加入回答の照合',
  reviewTitle: '加入回答の照合（正式加入確認フォームの回答 × 応募者一覧）',
  memberListSheet: '正式参加者一覧',
  memberListTitle: '正式参加者一覧（自動生成）',
  ledgerSheet: '_送信履歴',
  ledgerTitle: '_送信履歴（正式加入確認メール・回答の記録。メールアドレスはハッシュのみ）',
  responseSheetName: '正式加入確認（回答）',
  formTitle: 'かながわコネクトオーケストラ　正式加入確認フォーム',
  formIdProperty: 'KCO_MEMBERSHIP_FORM_ID',
  lastSyncProperty: 'KCO_MEMBERSHIP_LAST_SYNC',

  // 正式加入確認フォームの質問（「正式加入について」の見出しで回答シートを見分ける）
  questions: {
    name: 'お名前（呼ばれたい名前）',
    instrument: '楽器',
    intent: '正式加入について',
    concert: '第1回演奏会への参加について',
    other: 'その他'
  },
  intentChoices: ['正式加入を希望する', 'もう少し活動内容を確認してから決めたい', '今回は参加を見送る'],

  // アプリ利用の値（「停止」だけは運営が手で選ぶ。それ以外は自動で決まる）
  appUsageValues: ['対象外', '未発行', '招待準備', '招待済', '利用中', '停止'],
  // アプリを使える対応状況（活動休止はアプリで閲覧のみ）
  appStatuses: ['正式参加', '活動休止'],

  newColumns: ['アプリ利用', '正式加入の意思', '加入確認 回答日時', '加入確認メール', 'Firebase連携状態']
};

const MEMBERSHIP_DEFAULT_BODY_ = [
  '{名前} さん',
  '',
  'かながわコネクトオーケストラ 運営です。',
  'このたびは参加希望フォームにご回答いただき、ありがとうございました。',
  '',
  '現在、今後の活動に向けて、皆さんの参加希望の状況を確認しています。',
  'お手数ですが、下記の「正式加入確認フォーム」から、現在のお気持ちを教えてください。',
  '',
  '▼ 正式加入確認フォーム',
  '{フォームURL}',
  '',
  'フォームでは、次のいずれかを選んでいただけます。',
  '・正式加入を希望する',
  '・もう少し活動内容を確認してから決めたい',
  '・今回は参加を見送る',
  '',
  '正式に加入された方には、後日、団員向けアプリの利用方法をご案内します。',
  'まだ迷っている方は、遠慮なく「もう少し活動内容を確認してから決めたい」を選んでください。',
  '今回は見送りたい方も、今後の運営の参考にさせていただきますので、ご回答いただけるとうれしいです。',
  '',
  'ご不明な点があれば、このメールにご返信ください。',
  '',
  'かながわコネクトオーケストラ 運営'
].join('\n');

const MEMBERSHIP_ITEMS_ = [
  { key: 'senderEmail', label: '送信元アカウント', def: () => membershipCurrentUser_(), desc: 'このアカウントでメニューを実行したときだけ送信します（別のアカウントでの誤送信を防止）' },
  { key: 'senderName', label: '送信者名', def: () => 'かながわコネクトオーケストラ 運営', desc: '受信者に表示される差出人名' },
  { key: 'replyTo', label: '返信先', def: () => '', desc: '空欄なら送信元アカウントに返信が届きます' },
  { key: 'formUrl', label: '正式加入確認フォームのURL', def: () => '', desc: '「正式加入確認フォームを作成」で自動入力されます。メール本文の {フォームURL} に入ります' },
  { key: 'campaign', label: '送信回の名前', def: () => '第1回 正式加入確認', desc: '同じ送信回では1人1通だけ送ります。もう一度全員に送るときは名前を変えてください（例：第1回 正式加入確認（再送））' },
  { key: 'excludeEmails', label: '送信しないメールアドレス', def: () => membershipCurrentUser_(), desc: 'カンマ区切り（代表・運営のアドレスなど）。初期値は設定シートを最初に開いた人（代表）' },
  { key: 'excludeStatuses', label: '送信しない対応状況', def: () => '辞退', desc: 'カンマ区切り' },
  { key: 'maxPerRun', label: '1回に送る上限（通）', def: () => 50, desc: 'Gmail の1日の送信上限（無料アカウントは約100通）より小さくしてください。残りは次回送ります' },
  { key: 'subject', label: 'メールの件名', def: () => '【かながわコネクトオーケストラ】正式加入の意思確認のお願い', desc: '' },
  { key: 'body', label: 'メールの本文', def: () => MEMBERSHIP_DEFAULT_BODY_, desc: '{名前} と {フォームURL} が置き換わります' }
];


/*******************************************************
 * メニューから呼ぶ関数
 *******************************************************/

/** 正式加入確認フォームを新しく作り、回答をこのスプレッドシートにつなぐ（既存のフォームは変更しない） */
function membershipCreateForm() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const settings = membershipSettings_(ss);
  const props = PropertiesService.getScriptProperties();
  const existingId = props.getProperty(MEMBERSHIP.formIdProperty);

  if (existingId) {
    let existing = null;
    try {
      existing = FormApp.openById(existingId);
    } catch (e) {
      existing = null;
    }
    if (existing) {
      alert_('正式加入確認フォームはすでに作成済みです。\n\n' + existing.getPublishedUrl() + '\n\n（同じフォームを二重に作らないため、新しくは作りません）');
      return existing.getPublishedUrl();
    }
  }

  if (!confirm_('正式加入確認フォームを作成', '新しい Google フォーム「' + MEMBERSHIP.formTitle + '」を作り、回答をこのスプレッドシートの新しいシートに保存します。\n既存の参加希望フォームは変更しません。\n\n作成しますか？')) {
    alert_('作成を中止しました。');
    return null;
  }

  const q = MEMBERSHIP.questions;
  const form = FormApp.create(MEMBERSHIP.formTitle);

  form.setDescription(
    'かながわコネクトオーケストラの正式加入について、現在のお気持ちを教えてください。\n' +
    '参加希望フォームで回答したメールアドレスで回答してください（運営が回答を照合するために使います）。'
  );

  // メールアドレスは「回答者が入力」で集める（Google アカウントが無い人も回答できるように）
  if (typeof form.setEmailCollectionType === 'function' && FormApp.EmailCollectionType) {
    form.setEmailCollectionType(FormApp.EmailCollectionType.RESPONDER_INPUT);
  } else {
    form.setCollectEmail(true);
  }

  form.addTextItem().setTitle(q.name).setRequired(true);
  form.addTextItem().setTitle(q.instrument).setHelpText('参加希望フォームで回答した楽器を書いてください').setRequired(true);
  form.addMultipleChoiceItem().setTitle(q.intent).setChoiceValues(MEMBERSHIP.intentChoices).setRequired(true);
  form.addMultipleChoiceItem().setTitle(q.concert).setChoiceValues(CONFIG.concertChoices).setRequired(false);
  form.addParagraphTextItem().setTitle(q.other).setHelpText('質問や、運営に伝えておきたいことがあればご記入ください').setRequired(false);
  form.setConfirmationMessage('ご回答ありがとうございました。内容を確認のうえ、運営からご連絡します。');
  props.setProperty(MEMBERSHIP.formIdProperty, form.getId());

  let linked = true;

  try {
    form.setDestination(FormApp.DestinationType.SPREADSHEET, ss.getId());
  } catch (e) {
    linked = false;
    console.error('回答先の設定に失敗: ' + e.message);
  }

  const url = form.getPublishedUrl();

  membershipSetSetting_(ss, 'formUrl', url);

  // 回答シートの名前を分かりやすくする（見つからなくても、見出しで判定するので動作に影響なし）
  SpreadsheetApp.flush();
  const sheet = ss.getSheets().find(sh => {
    const u = formUrlOf_(sh);
    return u && u.indexOf(form.getId()) >= 0;
  });
  if (sheet && !ss.getSheetByName(MEMBERSHIP.responseSheetName)) sheet.setName(MEMBERSHIP.responseSheetName);

  alert_(
    '正式加入確認フォームを作成しました。\n\n' + url + '\n\n' +
    (linked ? '' : '⚠️ 回答の保存先をこのスプレッドシートに自動で設定できませんでした。\nフォームの編集画面 →「回答」→「スプレッドシートにリンク」→「既存のスプレッドシートを選択」で、このスプレッドシートを選んでください。\n\n') +
    'このURLは「加入確認設定」シートに保存し、メール本文に自動で入ります。\n' +
    '次に「テスト送信（自分宛て）」で、届くメールを確認してください。'
  );

  return url;
}


/** 送信元アカウント自身にテストメールを1通送る（送信履歴・連絡記録には残さない） */
function membershipSendTest() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const settings = membershipSettings_(ss);
  const me = membershipCurrentUser_();
  const problem = membershipCheckSendSettings_(settings, me);

  if (problem) {
    alert_('⚠️ ' + problem);
    return null;
  }

  MailApp.sendEmail(membershipMessage_(settings, me, '（テスト）'));

  alert_('テストメールを送信元アカウント（' + me + '）に送りました。\n受信箱で、件名・本文・フォームのリンクを確認してください。');

  return me;
}


/** 正式加入確認メールを送る（確認画面あり・1人ずつ個別送信） */
function membershipSendEmails() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const settings = membershipSettings_(ss);
  const me = membershipCurrentUser_();
  const problem = membershipCheckSendSettings_(settings, me);

  if (problem) {
    alert_('⚠️ ' + problem);
    return null;
  }

  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    alert_('他の処理が実行中です。少し待ってから再実行してください。');
    return null;
  }

  try {

    const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

    if (!sheet) {
      alert_('「応募者一覧」シートがありません。');
      return null;
    }

    membershipEnsureColumns_(sheet);

    const app = readApplicants_(sheet);
    const sent = membershipLedgerKeys_(ss);
    const plan = membershipPlanSend_(app.records, settings, sent);
    let quota = 0;

    try {
      quota = MailApp.getRemainingDailyQuota();
    } catch (e) {
      quota = 0;
    }

    const count = Math.min(plan.targets.length, settings.maxPerRun, quota);
    const summary = membershipDescribePlan_(plan, settings);

    if (!plan.targets.length) {
      alert_('送信する相手はいません。\n\n' + summary);
      return { sent: 0, plan };
    }

    if (count <= 0) {
      alert_('⚠️ 今日の Gmail の送信上限に達しているため送信できません。明日以降に再実行してください。\n\n' + summary);
      return { sent: 0, plan };
    }

    const ok = confirm_('正式加入確認メールを送信',
      summary + '\n\n' +
      '送信元：' + me + '\n' +
      '今回送るのは ' + count + '通' + (count < plan.targets.length ? '（残り ' + (plan.targets.length - count) + '人は次回）' : '') + 'です。\n' +
      '1人ずつ個別に送るため、ほかの人のアドレスは見えません。\n\n送信しますか？');

    if (!ok) {
      alert_('送信を中止しました（何も送っていません）。');
      return { sent: 0, plan };
    }

    const result = membershipDeliver_(ss, sheet, plan.targets.slice(0, count), settings, me);

    updateDashboardQuietly_(ss);

    alert_(
      '【正式加入確認メール】\n' +
      '送信：' + result.sent.length + '通' +
      (result.failed.length ? '\n送信できなかった：' + result.failed.length + '件（' + noLabel_(result.failed.map(t => t.record)) + '）' : '') +
      (plan.targets.length > count ? '\n\nまだ送っていない人が ' + (plan.targets.length - count) + '人います。もう一度実行すると続きを送ります。' : '') +
      '\n\n送信した記録は「連絡記録」に追加しました。'
    );

    return { sent: result.sent.length, failed: result.failed.length, plan };

  } finally {
    lock.releaseLock();
  }
}


/** 正式加入確認フォームの回答を応募者一覧と照合する */
function membershipSyncResponses() {

  const result = membershipSyncCore_(SpreadsheetApp.getActiveSpreadsheet(), true);

  alert_(membershipDescribeSync_(result));

  return result;
}


/** フォーム送信トリガー（handleSpreadsheetFormSubmit）から呼ばれる。画面は出さない */
function membershipSyncFromTrigger_() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();

  if (!membershipFindResponseSheet_(ss)) return null;

  return membershipSyncCore_(ss, false);
}


/** 正式参加者一覧（と、正式加入を希望しているがまだ確定していない人）を作り直す */
function membershipUpdateMemberList() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

  if (!sheet) {
    alert_('「応募者一覧」シートがありません。');
    return null;
  }

  const result = membershipWriteMemberList_(ss, readApplicants_(sheet));

  alert_('「' + MEMBERSHIP.memberListSheet + '」を更新しました。\n\n正式参加（活動休止を含む）：' + result.members + '人\n正式加入を希望・未確定：' + result.pending + '人');

  return result;
}


/** アプリ利用の列を、対応状況・アプリID・Firebase連携状態から更新する */
function membershipUpdateAppUsage() {

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

  try {
    membershipEnsureColumns_(sheet);
    const result = membershipRefreshAppUsage_(sheet, null);
    updateDashboardQuietly_(ss);
    alert_('「アプリ利用」を更新しました。\n\n' + Object.keys(result.counts).map(k => k + '：' + result.counts[k] + '人').join('\n') +
      '\n\n変更した行：' + result.changed + '行' +
      '\n\n※「停止」は運営が手で選ぶ値です（選んだ人は団員アプリに登録されません）。' +
      '\n※ 団員アプリへの反映は「📱 団員アプリ」→「団員アプリへ同期」で行います。');
    return result;
  } finally {
    lock.releaseLock();
  }
}


/** 同期状況をまとめて表示する（メールアドレスは出さない） */
function membershipStatus() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const settings = membershipSettings_(ss);
  const props = PropertiesService.getScriptProperties();
  const lines = ['【正式加入確認・団員アプリの状況】', ''];
  const responseSheet = membershipFindResponseSheet_(ss);
  const ledger = membershipLedgerRows_(ss);
  const sentThisCampaign = ledger.filter(r => r.type === '送信' && r.campaign === settings.campaign).length;

  lines.push('フォーム：' + (settings.formUrl ? '作成済み' : '未作成（「正式加入確認フォームを作成」を実行してください）'));
  lines.push('回答シート：' + (responseSheet ? responseSheet.getName() + '（' + Math.max(responseSheet.getLastRow() - 1, 0) + '件）' : 'まだありません'));
  lines.push('送信回「' + settings.campaign + '」：' + sentThisCampaign + '通 送信済み（すべての送信回で ' + ledger.filter(r => r.type === '送信').length + '通）');

  try {
    lines.push('今日あと送れるメール：' + MailApp.getRemainingDailyQuota() + '通（実行中のアカウント）');
  } catch (e) {
    lines.push('今日あと送れるメール：確認できません');
  }

  const last = membershipParseJson_(props.getProperty(MEMBERSHIP.lastSyncProperty));
  lines.push('回答の最終同期：' + (last ? last.at.replace('T', ' ').slice(0, 16) + '（回答 ' + last.responses + '件・要確認 ' + last.review + '件）' : 'まだ実行していません'));

  const appLast = membershipParseJson_(props.getProperty('KCO_APP_SYNC_LAST'));
  lines.push('団員アプリへの最終同期：' + (appLast ? appLast.at.replace('T', ' ').slice(0, 16) + (appLast.ok ? '（成功・団員 ' + appLast.members + '人）' : '（失敗：' + appLast.error + '）') : 'まだ実行していません'));

  const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

  if (sheet) {
    const app = readApplicants_(sheet);
    const counts = {};
    const states = {};
    const intents = {};
    membershipPrimaries_(app.records).forEach(r => {
      counts[r.appUsage || '（未設定）'] = (counts[r.appUsage || '（未設定）'] || 0) + 1;
      if (r.firebaseState) states[r.firebaseState] = (states[r.firebaseState] || 0) + 1;
      intents[r.joinIntent || '未回答'] = (intents[r.joinIntent || '未回答'] || 0) + 1;
    });
    lines.push('', '正式加入の意思：' + membershipJoinCounts_(intents));
    lines.push('アプリ利用：' + membershipJoinCounts_(counts));
    lines.push('Firebase連携状態：' + (membershipJoinCounts_(states) || 'まだありません'));
  }

  alert_(lines.join('\n'));

  return lines;
}


function membershipOpenSettings() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();

  ss.setActiveSheet(membershipEnsureSettingsSheet_(ss));
}


/*******************************************************
 * メール送信
 *******************************************************/

/**
 * 送信する相手を決める（純粋な計算。テスト可能）
 *  ・メールアドレスごとに1人（重複行は No. の小さい行）
 *  ・メールアドレスが無い／正しくない、除外アドレス、除外する対応状況、この送信回で送信済み → 送らない
 */
function membershipPlanSend_(records, settings, sentKeys) {

  const plan = { targets: [], noEmail: [], excludedEmail: [], excludedStatus: [], alreadySent: [], duplicateRows: 0 };
  const excludeEmails = new Set(settings.excludeEmails);
  const excludeStatuses = new Set(settings.excludeStatuses);

  groupByEmail_(records).forEach(list => {

    const r = list[0];

    plan.duplicateRows += list.length - 1;

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(r.emailKey)) {
      plan.noEmail.push(r);
      return;
    }
    if (excludeEmails.has(r.emailKey)) {
      plan.excludedEmail.push(r);
      return;
    }
    if (excludeStatuses.has(r.status)) {
      plan.excludedStatus.push(r);
      return;
    }
    if (sentKeys.has(membershipSendKey_(settings.campaign, r.emailKey))) {
      plan.alreadySent.push(r);
      return;
    }

    plan.targets.push({ record: r, rows: list.map(x => x.row), email: r.emailKey });
  });

  plan.targets.sort((a, b) => compareByNo_(a.record, b.record));

  return plan;
}


/** 1人ずつ送信し、送った直後に送信履歴へ記録する（途中で止まっても二重に送らない） */
function membershipDeliver_(ss, sheet, targets, settings, me) {

  const ledger = membershipEnsureLedger_(ss);
  const sent = [];
  const failed = [];
  const now = new Date();

  for (const t of targets) {
    try {
      MailApp.sendEmail(membershipMessage_(settings, t.email, membershipDisplayName_(t.record)));
    } catch (e) {
      failed.push(t);
      // 送信上限に達したら残りは送らない
      if (/limit|上限|quota|Service invoked too many times/i.test(String(e && e.message))) break;
      continue;
    }
    membershipAppendLedger_(ledger, [now, '送信', settings.campaign, membershipSendKey_(settings.campaign, t.email), toStr_(t.record.no)]);
    sent.push(t);
  }

  if (!sent.length) return { sent, failed };

  // 応募者一覧：「加入確認メール」に送信日時、「最終連絡日」に今日（ほかの列は変えない）
  const app = readApplicants_(sheet);
  const mailCol = app.map.joinMailAt;
  const lastCol = app.map.lastContact;
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  sent.forEach(t => t.rows.forEach(row => {
    if (mailCol !== undefined) sheet.getRange(row, mailCol + 1).setValue(now);
    if (lastCol !== undefined) sheet.getRange(row, lastCol + 1).setValue(today);
  }));

  // 連絡記録に1人1行追加
  membershipAppendContacts_(ss, sent.map(t => ({
    date: today,
    no: t.record.no,
    name: membershipDisplayName_(t.record),
    method: 'メール',
    content: '正式加入確認メールを送信（' + settings.campaign + '）',
    staff: settings.senderName,
    nextAction: '正式加入確認フォームの回答待ち',
    state: '完了'
  })));

  return { sent, failed };
}


function membershipMessage_(settings, to, name) {

  const fill = text => String(text)
    .split('{名前}').join(name || '参加希望者')
    .split('{フォームURL}').join(settings.formUrl);

  const message = {
    to,
    subject: fill(settings.subject),
    body: fill(settings.body),
    name: settings.senderName
  };

  if (settings.replyTo) message.replyTo = settings.replyTo;

  return message;
}


/** 送信してよいか（設定の不備・アカウント違いを止める）。問題が無ければ null */
function membershipCheckSendSettings_(settings, me) {

  if (!settings.senderEmail) return '「加入確認設定」の送信元アカウントが空欄です。';
  if (me !== settings.senderEmail) {
    return '送信元アカウントは「' + settings.senderEmail + '」に設定されていますが、いまメニューを実行しているのは別のアカウントです。\n' +
      '誤送信を防ぐため送信しません。送信元アカウントでスプレッドシートを開き直して実行してください。';
  }
  if (!/^https:\/\/\S+$/.test(settings.formUrl)) return '正式加入確認フォームのURLが設定されていません。先に「正式加入確認フォームを作成」を実行してください。';
  if (settings.body.indexOf('{フォームURL}') < 0 && settings.body.indexOf(settings.formUrl) < 0) return 'メールの本文にフォームのURL（{フォームURL}）が入っていません。';
  if (!settings.subject) return 'メールの件名が空欄です。';
  if (settings.replyTo && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(settings.replyTo)) return '返信先のメールアドレスが正しくありません。';

  return null;
}


function membershipDescribePlan_(plan, settings) {

  const lines = [
    '送信回：' + settings.campaign,
    '送信する人：' + plan.targets.length + '人' + (plan.targets.length ? '（' + formatNoList_(plan.targets.map(t => t.record.no)) + '）' : ''),
    '送らない人：',
    '　この送信回で送信済み ' + plan.alreadySent.length + '人',
    '　対応状況が「' + settings.excludeStatuses.join('・') + '」 ' + plan.excludedStatus.length + '人',
    '　除外アドレス（代表など） ' + plan.excludedEmail.length + '人',
    '　メールアドレスなし・不正 ' + plan.noEmail.length + '人' + (plan.noEmail.length ? '（' + noLabel_(plan.noEmail) + '）' : '')
  ];

  if (plan.duplicateRows) lines.push('　同じアドレスの重複行 ' + plan.duplicateRows + '行（1通だけ送ります）');

  return lines.join('\n');
}


/*******************************************************
 * 回答の照合
 *******************************************************/

function membershipSyncCore_(ss, interactive) {

  const result = { error: null, busy: false, responses: 0, people: 0, matched: 0, updated: 0, review: 0, unmatched: 0, contacts: 0, intents: {} };
  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    result.busy = true;
    result.error = '他の処理が実行中です。少し待ってから再実行してください。';
    return result;
  }

  try {

    const responseSheet = membershipFindResponseSheet_(ss);

    if (!responseSheet) {
      result.error = '正式加入確認フォームの回答シートが見つかりません。「正式加入確認フォームを作成」を実行したか確認してください。';
      return result;
    }

    const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

    if (!sheet) {
      result.error = '「応募者一覧」シートがありません。';
      return result;
    }

    membershipEnsureColumns_(sheet);

    const app = readApplicants_(sheet);
    const responses = membershipReadResponses_(responseSheet);

    if (responses.error) {
      result.error = responses.error;
      return result;
    }

    const index = buildInstrumentIndex_(loadSettings_(ss));
    const review = membershipBuildReview_(responses.items, app.records, index);

    result.responses = responses.items.length;
    result.people = review.length;

    // 応募者一覧：この機能の列（正式加入の意思・回答日時）だけ更新
    review.forEach(x => {
      if (x.intent) result.intents[x.intent] = (result.intents[x.intent] || 0) + 1;
      if (!x.applicant) {
        result.unmatched++;
        return;
      }
      result.matched++;
      let changed = false;
      if (x.intent && x.applicant.joinIntent !== x.intent && app.map.joinIntent !== undefined) {
        sheet.getRange(x.applicant.row, app.map.joinIntent + 1).setValue(x.intent);
        changed = true;
      }
      if (app.map.joinAnsweredAt !== undefined && !sameTime_(x.applicant.joinAnsweredAt, x.latest.timestamp)) {
        sheet.getRange(x.applicant.row, app.map.joinAnsweredAt + 1).setValue(x.latest.timestamp);
        changed = true;
      }
      if (changed) result.updated++;
    });

    result.review = review.filter(x => x.flags.length).length;

    // 連絡記録：新しい回答を1回だけ記録（応募者一覧で見つかった人のみ）
    const ledger = membershipEnsureLedger_(ss);
    const seen = membershipLedgerKeys_(ss);
    const contacts = [];

    review.forEach(x => {
      if (!x.applicant) return;
      x.items.forEach(item => {
        const key = hashKey_('answer|' + item.emailKey + '|' + membershipTimeKey_(item.timestamp));
        if (seen.has(key)) return;
        seen.add(key);
        membershipAppendLedger_(ledger, [new Date(), '回答', '', key, toStr_(x.applicant.no)]);
        contacts.push({
          date: isDate_(item.timestamp) ? item.timestamp : new Date(),
          no: x.applicant.no,
          name: membershipDisplayName_(x.applicant),
          method: 'その他',
          content: '正式加入確認フォームに回答：' + (item.intent || '（未回答）'),
          reply: item.intentText,
          nextAction: x.action,
          state: '要対応'
        });
      });
    });

    if (contacts.length) membershipAppendContacts_(ss, contacts);
    result.contacts = contacts.length;

    membershipWriteReview_(ss, review);

    membershipRefreshAppUsage_(sheet, null);
    membershipWriteMemberList_(ss, readApplicants_(sheet));

    try {
      PropertiesService.getScriptProperties().setProperty(MEMBERSHIP.lastSyncProperty, JSON.stringify({
        at: new Date().toISOString(), responses: result.responses, review: result.review, matched: result.matched, unmatched: result.unmatched
      }));
    } catch (e) {
      console.error('回答同期の記録に失敗: ' + e.message);
    }

    updateDashboardQuietly_(ss);

    return result;

  } catch (err) {

    result.error = '回答の同期に失敗しました：' + String(err && err.message || err).slice(0, 200);
    if (!interactive) throw err;
    return result;

  } finally {
    lock.releaseLock();
  }
}


function membershipFindResponseSheet_(ss) {

  const byName = ss.getSheetByName(MEMBERSHIP.responseSheetName);

  if (byName) return byName;

  return ss.getSheets().find(sh => {
    if (sh.getLastRow() < 1 || sh.getLastColumn() < 1) return false;
    const headers = sh.getRange(1, 1, 1, sh.getLastColumn()).getValues()[0].map(toStr_);
    return isMembershipResponseHeaders_(headers);
  }) || null;
}


function membershipResponseFieldDefs_() {

  const q = MEMBERSHIP.questions;

  return [
    { key: 'timestamp', candidates: ['タイムスタンプ', 'Timestamp'] },
    { key: 'email', candidates: ['メールアドレス', 'Email Address', 'Email address', 'メール アドレス'] },
    { key: 'name', candidates: [q.name, 'お名前・呼ばれたい名前', 'お名前', '名前', '氏名'] },
    { key: 'instrument', candidates: [q.instrument] },
    { key: 'intent', candidates: [q.intent] },
    { key: 'concert', candidates: [q.concert, '第1回演奏会'] },
    { key: 'other', candidates: [q.other] }
  ];
}


function membershipReadResponses_(sheet) {

  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();

  if (lastRow < 1 || lastCol < 1) return { items: [] };

  const values = sheet.getRange(1, 1, lastRow, lastCol).getValues();
  const headers = values[0].map(toStr_);
  const res = resolveColumns_(headers, membershipResponseFieldDefs_(), true);

  if (res.map.intent === undefined) return { error: '回答シートに「正式加入について」の列がありません。' };
  if (res.map.email === undefined) return { error: '回答シートに「メールアドレス」の列がありません。フォームでメールアドレスを集める設定にしてください。' };

  const items = [];

  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    if (row.every(v => isBlank_(v))) continue;
    const get = key => (res.map[key] === undefined ? '' : row[res.map[key]]);
    const intentText = toStr_(get('intent'));
    items.push({
      row: i + 1,
      timestamp: get('timestamp'),
      emailKey: emailKey_(get('email')),
      name: toStr_(get('name')),
      instrument: toStr_(get('instrument')),
      intentText,
      intent: membershipIntentOf_(intentText),
      concert: toStr_(get('concert')),
      other: toStr_(get('other'))
    });
  }

  return { items };
}


/** 「正式加入について」の回答 → 希望／検討中／見送り（判定できない場合は空欄） */
function membershipIntentOf_(text) {

  const t = nfkc_(toStr_(text));

  if (!t) return '';
  if (/見送|辞退|参加しない/.test(t)) return '見送り';
  if (/確認してから|検討|迷/.test(t)) return '検討中';
  if (/希望/.test(t)) return '希望';

  return '';
}


/**
 * 回答（同じメールアドレスはまとめて最新を使う）と応募者一覧を照合し、要確認の理由とおすすめの対応を付ける。
 * 純粋な計算（テスト可能）。応募者一覧への追加・対応状況の変更はしない。
 */
function membershipBuildReview_(items, records, index) {

  // 応募者：メールアドレス（とアプリ用メールアドレス）→ No. の一番小さい行
  const byEmail = new Map();

  groupByEmail_(records).forEach(list => {
    const primary = list[0];
    if (primary.emailKey && !byEmail.has(primary.emailKey)) byEmail.set(primary.emailKey, primary);
  });
  records.slice().sort(compareByNo_).forEach(r => {
    const k = emailKey_(r.appEmail);
    if (k && !byEmail.has(k)) byEmail.set(k, r);
  });

  const groups = new Map();

  items.forEach(item => {
    const id = item.emailKey ? 'mail:' + item.emailKey : 'row:' + item.row;
    if (!groups.has(id)) groups.set(id, []);
    groups.get(id).push(item);
  });

  const out = [];

  groups.forEach(list => {

    list.sort((a, b) => membershipTimeValue_(a.timestamp) - membershipTimeValue_(b.timestamp) || a.row - b.row);

    const latest = list[list.length - 1];
    const applicant = latest.emailKey ? (byEmail.get(latest.emailKey) || null) : null;
    const flags = [];
    const intent = latest.intent;

    if (!latest.emailKey) flags.push('メールアドレスがありません');
    else if (!applicant) flags.push('応募者一覧に同じメールアドレスがありません（新しい回答者・別のアドレスの可能性）');

    if (list.length > 1) {
      flags.push('回答が ' + list.length + '件あります（最新の回答を使用）');
      if (new Set(list.map(x => x.intent)).size > 1) flags.push('回答の内容が変わっています（' + list.map(x => x.intent || '?').join('→') + '）');
    }

    if (!intent) flags.push('「正式加入について」の回答を判定できません');

    if (applicant) {
      if (applicant.status === '辞退' && intent === '希望') flags.push('現在の対応状況は「辞退」です');
      const a = parseInstrumentCell_(applicant.instrument, index);
      const b = parseInstrumentCell_(latest.instrument, index);
      if (a.codes.length && b.codes.length && !b.codes.some(c => a.codes.indexOf(c) >= 0)) flags.push('楽器が応募時と違います');
      const n1 = nameKey_(latest.name);
      const n2 = nameKey_(membershipDisplayName_(applicant));
      const n3 = nameKey_(applicant.name);
      if (n1 && n2 && n1 !== n2 && n1 !== n3 && n2.indexOf(n1) < 0 && n1.indexOf(n2) < 0) flags.push('名前が応募時と違います');
    }

    out.push({
      latest,
      items: list,
      applicant,
      intent,
      flags,
      action: membershipActionFor_(applicant, intent)
    });
  });

  // 応募者一覧にいない人 → ほかの要確認 → 問題なし の順。同じ区分の中は応募者No.順
  const rank = x => (!x.applicant ? 0 : x.flags.length ? 1 : 2);
  out.sort((x, y) => rank(x) - rank(y) || compareByNo_(x.applicant || { row: 1e9 }, y.applicant || { row: 1e9 }));

  return out;
}


function membershipActionFor_(applicant, intent) {

  if (!applicant) return '同じ人が別のメールアドレスで応募していないか確認してください（応募者一覧へは自動で追加しません）';

  const status = applicant.status;

  if (intent === '希望') {
    if (MEMBERSHIP.appStatuses.indexOf(status) >= 0) return '正式参加済みです（対応不要）';
    return '楽器・演奏会・連絡事項を確認し、問題なければ対応状況を「正式参加」に変更してください';
  }
  if (intent === '検討中') return '活動内容の案内を送り、必要なら対応状況を「保留」などに変更してください';
  if (intent === '見送り') return status === '辞退' ? '辞退済みです（対応不要）' : '本人の意思を確認し、対応状況を「辞退」に変更するか判断してください';

  return '回答内容を確認してください';
}


function membershipWriteReview_(ss, review) {

  const sheet = getOrCreateOwnedSheet_(ss, MEMBERSHIP.reviewSheet, MEMBERSHIP.reviewTitle);
  const header = ['最新の回答日時', '応募者No.', 'お名前（回答）', 'メール（一部）', '現在の対応状況', '正式加入の意思', '第1回演奏会（回答）', '楽器（回答）', '楽器（応募時）', '回答回数', '要確認', 'おすすめの対応', 'その他（回答）'];
  const rows = [[MEMBERSHIP.reviewTitle].concat(new Array(header.length - 1).fill('')),
    ['※ 自動生成シートです。対応状況の変更は「応募者一覧」で行ってください。メールアドレスは一部を伏せています。'].concat(new Array(header.length - 1).fill('')),
    header];

  review.forEach(x => {
    const a = x.applicant;
    rows.push([
      x.latest.timestamp,
      a ? a.no : '',
      sanitizeForSheet_(x.latest.name),
      membershipMaskEmail_(x.latest.emailKey),
      a ? a.status : '（応募者一覧にいない）',
      x.intent || '（判定できない）',
      sanitizeForSheet_(x.latest.concert),
      sanitizeForSheet_(x.latest.instrument),
      a ? sanitizeForSheet_(toStr_(a.instrument)) : '',
      x.items.length,
      x.flags.join('／'),
      x.action,
      sanitizeForSheet_(x.latest.other)
    ]);
  });

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, header.length);
  sheet.getRange(1, 1, sheet.getMaxRows(), header.length).clear();
  sheet.getRange(1, 1, rows.length, header.length).setValues(rows);
  sheet.getRange(1, 1, 1, header.length).setFontWeight('bold');
  sheet.getRange(3, 1, 1, header.length).setFontWeight('bold').setBackground(COLOR_HEADER_);

  review.forEach((x, i) => {
    if (x.flags.length) sheet.getRange(4 + i, 11, 1, 1).setBackground('#fce5cd');
  });

  sheet.setFrozenRows(3);

  return sheet;
}


/*******************************************************
 * アプリ利用・Firebase連携状態
 *******************************************************/

/**
 * アプリ利用の値を決める（純粋な計算）
 *  停止（運営が選んだもの）はそのまま
 *  正式参加・活動休止でない／重複行 → 対象外
 *  アプリIDなし → 未発行、同期前 → 招待準備、同期済み → 招待済（利用中はそのまま）
 */
function membershipAppUsageFor_(r, isPrimary) {

  if (r.appUsage === '停止') return '停止';
  if (!isPrimary || MEMBERSHIP.appStatuses.indexOf(r.status) < 0) return '対象外';
  if (!r.appId) return '未発行';
  if (r.firebaseState === '同期済み') return r.appUsage === '利用中' ? '利用中' : '招待済';

  return '招待準備';
}


/**
 * アプリ利用・Firebase連携状態の列を書き直す。
 * syncedRows（団員アプリへの同期が成功したときだけ渡す）：同期で登録された行番号の Set
 */
function membershipRefreshAppUsage_(sheet, syncedRows) {

  const app = readApplicants_(sheet);
  const usageCol = app.map.appUsage;
  const stateCol = app.map.firebaseState;
  const result = { changed: 0, counts: {} };

  if (usageCol === undefined) return result;

  const primaryRows = new Set(membershipPrimaries_(app.records).map(r => r.row));
  const lastRow = sheet.getLastRow();

  if (lastRow < 2) return result;

  const usage = sheet.getRange(2, usageCol + 1, lastRow - 1, 1).getValues();
  const state = stateCol === undefined ? null : sheet.getRange(2, stateCol + 1, lastRow - 1, 1).getValues();
  let stateChanged = false;

  app.records.forEach(r => {

    const i = r.row - 2;

    if (state && syncedRows) {
      let next = r.firebaseState;
      if (syncedRows.has(r.row)) next = '同期済み';
      else if (r.firebaseState === '同期済み') next = '停止済み';
      if (next !== r.firebaseState) {
        state[i][0] = next;
        r.firebaseState = next;
        stateChanged = true;
      }
    }

    const value = membershipAppUsageFor_(r, primaryRows.has(r.row));

    result.counts[value] = (result.counts[value] || 0) + 1;

    if (toStr_(usage[i][0]) !== value) {
      usage[i][0] = value;
      result.changed++;
    }
  });

  if (result.changed) sheet.getRange(2, usageCol + 1, lastRow - 1, 1).setValues(usage);
  if (stateChanged) sheet.getRange(2, stateCol + 1, lastRow - 1, 1).setValues(state);

  // プルダウン（運営が「停止」を選べるように）
  const rule = SpreadsheetApp.newDataValidation().requireValueInList(MEMBERSHIP.appUsageValues, true).setAllowInvalid(false).build();
  sheet.getRange(2, usageCol + 1, lastRow - 1, 1).setDataValidation(rule);

  return result;
}


/**
 * 団員アプリへの同期（AppSync.gs）が成功した後に呼ばれる。
 * 同期対象になった行を「同期済み」、外れた行を「停止済み」にし、アプリ利用を更新する。
 * （AppSync のロックの中で呼ばれるため、ここではロックを取らない）
 */
function membershipAfterAppSync_(ss, syncedRows) {

  const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

  if (!sheet) return null;

  membershipEnsureColumns_(sheet);

  return membershipRefreshAppUsage_(sheet, syncedRows);
}


function membershipWriteMemberList_(ss, app) {

  const sheet = getOrCreateOwnedSheet_(ss, MEMBERSHIP.memberListSheet, MEMBERSHIP.memberListTitle);
  const W = 9;
  const index = buildInstrumentIndex_(loadSettings_(ss));
  const primaries = membershipPrimaries_(app.records).sort(compareByNo_);
  const partOf = r => {
    const p = parseInstrumentCell_(r.instrument, index);
    const info = p.primaryCode ? index.info[p.primaryCode] : null;
    return info ? (PART_LABELS_[info.part] || info.part) : '（未分類）';
  };
  const pad = cells => { const line = cells.slice(0, W); while (line.length < W) line.push(''); return line; };

  const members = primaries.filter(r => MEMBERSHIP.appStatuses.indexOf(r.status) >= 0);
  const pending = primaries.filter(r => r.joinIntent === '希望' && MEMBERSHIP.appStatuses.indexOf(r.status) < 0);

  const rows = [
    pad([MEMBERSHIP.memberListTitle]),
    pad(['※ 自動生成シートです（メールアドレスは載せていません）。対応状況の変更は「応募者一覧」で行ってください。']),
    pad([]),
    pad(['【正式参加（活動休止を含む）】 ' + members.length + '人']),
    pad(['No.', '名前', '楽器', 'パート', '対応状況', '第1回演奏会', '正式加入の意思', 'アプリ利用', 'Firebase連携状態'])
  ];
  const headerRows = [5];

  members.forEach(r => rows.push(pad([r.no, sanitizeForSheet_(membershipDisplayName_(r)), sanitizeForSheet_(toStr_(r.instrument)), partOf(r), r.status, toStr_(r.concert), r.joinIntent, r.appUsage, r.firebaseState])));

  rows.push(pad([]));
  rows.push(pad(['【正式加入を希望・まだ確定していない人】 ' + pending.length + '人（「加入回答の照合」の確認事項を見て、応募者一覧の対応状況を「正式参加」に変更してください）']));
  rows.push(pad(['No.', '名前', '楽器', 'パート', '現在の対応状況', '第1回演奏会', '回答日時', 'アプリ利用', '']));
  headerRows.push(rows.length);

  pending.forEach(r => rows.push(pad([r.no, sanitizeForSheet_(membershipDisplayName_(r)), sanitizeForSheet_(toStr_(r.instrument)), partOf(r), r.status, toStr_(r.concert), r.joinAnsweredAt, r.appUsage, ''])));

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, W);
  sheet.getRange(1, 1, sheet.getMaxRows(), W).clear();
  sheet.getRange(1, 1, rows.length, W).setValues(rows);
  sheet.getRange(1, 1, 1, W).setFontWeight('bold');
  headerRows.forEach(r => sheet.getRange(r, 1, 1, W).setFontWeight('bold').setBackground(COLOR_HEADER_));

  return { members: members.length, pending: pending.length };
}


/*******************************************************
 * 列・設定・履歴
 *******************************************************/

/** 応募者一覧の末尾に、この機能の列が無ければ追加する（既存の列は動かさない） */
function membershipEnsureColumns_(sheet) {

  const lastCol = sheet.getLastColumn();
  const headers = sheet.getRange(1, 1, 1, Math.max(lastCol, 1)).getValues()[0].map(toStr_);
  const res = resolveColumns_(headers, applicantFieldDefs_(), false);
  const keys = ['appUsage', 'joinIntent', 'joinAnsweredAt', 'joinMailAt', 'firebaseState'];
  const add = keys.filter(k => res.map[k] === undefined).map(k => APPLICANT_FIELDS.find(f => f.key === k).header);

  if (add.length) {
    ensureCols_(sheet, lastCol + add.length);
    sheet.getRange(1, lastCol + 1, 1, add.length).setValues([add]);
    expandFilterToData_(sheet);
  }

  return add;
}


function membershipEnsureSettingsSheet_(ss) {

  const existing = findOwnedSheet_(ss, MEMBERSHIP.settingsSheet, MEMBERSHIP.settingsTitle);

  if (existing && existing.getLastRow() > 0) {
    const labels = existing.getRange(1, 1, existing.getLastRow(), 1).getValues().map(r => toStr_(r[0]));
    const missing = MEMBERSHIP_ITEMS_.filter(item => labels.indexOf(item.label) < 0);
    if (missing.length) {
      const last = existing.getLastRow();
      ensureRows_(existing, last + missing.length);
      existing.getRange(last + 1, 1, missing.length, 3).setValues(missing.map(item => [item.label, item.def(), item.desc]));
    }
    return existing;
  }

  const sheet = existing || getOrCreateOwnedSheet_(ss, MEMBERSHIP.settingsSheet, MEMBERSHIP.settingsTitle);
  const rows = [[MEMBERSHIP.settingsTitle, '', ''], ['項目', '値', '説明']];

  MEMBERSHIP_ITEMS_.forEach(item => rows.push([item.label, item.def(), item.desc]));
  rows.push(['', '', '']);
  rows.push(['※ このシートには運営のメールアドレスが入ります。公開しないでください。', '', '']);

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, 3);
  sheet.getRange(1, 1, rows.length, 3).setValues(rows);
  sheet.getRange(1, 1, 2, 3).setFontWeight('bold');
  sheet.getRange(2, 1, 1, 3).setBackground(COLOR_HEADER_);
  sheet.getRange(3, 2, rows.length - 2, 1).setWrap(true);
  sheet.setColumnWidth(1, 220);
  sheet.setColumnWidth(2, 420);

  return sheet;
}


function membershipSettings_(ss) {

  const sheet = membershipEnsureSettingsSheet_(ss);
  const values = sheet.getRange(1, 1, Math.max(sheet.getLastRow(), 1), 3).getValues();
  const raw = {};

  MEMBERSHIP_ITEMS_.forEach(item => {
    const row = values.find(r => toStr_(r[0]) === item.label);
    raw[item.key] = row ? row[1] : item.def();
  });

  const list = v => toStr_(v).split(/[,、，\n]+/).map(x => x.trim()).filter(Boolean);
  const max = Number(raw.maxPerRun);

  return {
    senderEmail: emailKey_(raw.senderEmail),
    senderName: toStr_(raw.senderName) || 'かながわコネクトオーケストラ 運営',
    replyTo: emailKey_(raw.replyTo),
    formUrl: toStr_(raw.formUrl),
    campaign: toStr_(raw.campaign) || '第1回 正式加入確認',
    excludeEmails: list(raw.excludeEmails).map(emailKey_),
    excludeStatuses: list(raw.excludeStatuses),
    maxPerRun: Number.isInteger(max) && max > 0 ? Math.min(max, 1500) : 50,
    subject: toStr_(raw.subject),
    body: String(raw.body === null || raw.body === undefined ? '' : raw.body)
  };
}


function membershipSetSetting_(ss, key, value) {

  const sheet = membershipEnsureSettingsSheet_(ss);
  const item = MEMBERSHIP_ITEMS_.find(i => i.key === key);
  const labels = sheet.getRange(1, 1, sheet.getLastRow(), 1).getValues().map(r => toStr_(r[0]));
  const i = labels.indexOf(item.label);

  if (i >= 0) sheet.getRange(i + 1, 2).setValue(value);
}


function membershipEnsureLedger_(ss) {

  const existing = findOwnedSheet_(ss, MEMBERSHIP.ledgerSheet, MEMBERSHIP.ledgerTitle);

  if (existing && existing.getLastRow() > 0) return existing;

  const sheet = existing || getOrCreateOwnedSheet_(ss, MEMBERSHIP.ledgerSheet, MEMBERSHIP.ledgerTitle);

  sheet.getRange(1, 1, 2, 5).setValues([
    [MEMBERSHIP.ledgerTitle, '', '', '', ''],
    ['日時', '種類', '送信回', 'キー（ハッシュ）', '応募者No.']
  ]);

  try {
    sheet.hideSheet();
  } catch (e) {
    // 非表示にできなくても動作には影響しない
  }

  return sheet;
}


function membershipAppendLedger_(sheet, row) {

  const next = sheet.getLastRow() + 1;

  ensureRows_(sheet, next);
  sheet.getRange(next, 1, 1, row.length).setValues([row]);
}


function membershipLedgerRows_(ss) {

  const sheet = findOwnedSheet_(ss, MEMBERSHIP.ledgerSheet, MEMBERSHIP.ledgerTitle);

  if (!sheet || sheet.getLastRow() < 3) return [];

  return sheet.getRange(3, 1, sheet.getLastRow() - 2, 5).getValues()
    .filter(r => toStr_(r[3]))
    .map(r => ({ at: r[0], type: toStr_(r[1]), campaign: toStr_(r[2]), key: toStr_(r[3]), no: r[4] }));
}


function membershipLedgerKeys_(ss) {

  return new Set(membershipLedgerRows_(ss).map(r => r.key));
}


function membershipSendKey_(campaign, emailKey) {

  return hashKey_('send|' + toStr_(campaign) + '|' + emailKey);
}


/** 連絡記録に行を追加する（見出し名で列を探す。無い列は飛ばす） */
function membershipAppendContacts_(ss, entries) {

  const sheet = ss.getSheetByName(CONFIG.contactsSheet);

  if (!sheet || !entries.length) return 0;

  const lastCol = Math.max(sheet.getLastColumn(), 1);
  const headers = sheet.getRange(1, 1, 1, lastCol).getValues()[0].map(toStr_);
  const map = resolveColumns_(headers, contactFieldDefs_(), false).map;
  const rows = entries.map(e => {
    const line = new Array(lastCol).fill('');
    Object.keys(e).forEach(k => {
      if (map[k] !== undefined && e[k] !== undefined) line[map[k]] = sanitizeForSheet_(e[k]);
    });
    return line;
  });

  // 最後のデータ行の次に追加（書式だけの空行の後ろには足さない）
  const values = sheet.getRange(1, 1, Math.max(sheet.getLastRow(), 1), lastCol).getValues();
  let last = values.length;
  while (last > 1 && values[last - 1].every(v => isBlank_(v))) last--;

  ensureRows_(sheet, last + rows.length);
  sheet.getRange(last + 1, 1, rows.length, lastCol).setValues(rows);

  return rows.length;
}


/*******************************************************
 * 補助
 *******************************************************/

function membershipPrimaries_(records) {

  const out = [];

  groupByEmail_(records).forEach(list => out.push(list[0]));

  return out;
}


function membershipDisplayName_(r) {

  return toStr_(r.nickname) || toStr_(r.name) || ('No.' + toStr_(r.no));
}


function membershipCurrentUser_() {

  let email = '';

  try {
    email = Session.getActiveUser().getEmail();
  } catch (e) {
    email = '';
  }

  if (!email) {
    try {
      email = Session.getEffectiveUser().getEmail();
    } catch (e) {
      email = '';
    }
  }

  return emailKey_(email);
}


function membershipMaskEmail_(emailKey) {

  const m = /^([^@]*)@(.+)$/.exec(emailKey || '');

  if (!m) return '';

  return m[1].slice(0, 2) + '***@' + m[2];
}


function membershipTimeValue_(v) {

  const d = parseDateLoose_(v);

  return d ? d.getTime() : 0;
}


function membershipTimeKey_(v) {

  const d = parseDateLoose_(v);

  return d ? String(Math.floor(d.getTime() / 1000)) : toStr_(v);
}


function sameTime_(a, b) {

  if (isBlank_(a) && isBlank_(b)) return true;

  return membershipTimeKey_(a) === membershipTimeKey_(b);
}


function membershipParseJson_(text) {

  try {
    return text ? JSON.parse(text) : null;
  } catch (e) {
    return null;
  }
}


function membershipJoinCounts_(counts) {

  return Object.keys(counts).map(k => k + ' ' + counts[k]).join('／');
}


function membershipDescribeSync_(r) {

  if (r.error) return '⚠️ ' + r.error;

  const intents = Object.keys(r.intents).map(k => k + ' ' + r.intents[k] + '人').join('・') || 'なし';

  return [
    '【正式加入回答の同期】',
    '回答：' + r.responses + '件（' + r.people + '人分）',
    '加入の意思：' + intents,
    '応募者一覧と一致：' + r.matched + '人（更新 ' + r.updated + '人）',
    '応募者一覧にいない回答者：' + r.unmatched + '人（応募者一覧には追加していません）',
    '要確認：' + r.review + '人 →「' + MEMBERSHIP.reviewSheet + '」シートで確認してください',
    '連絡記録に追加：' + r.contacts + '件',
    '',
    '※ 対応状況は自動では変えません。確認のうえ「応募者一覧」で「正式参加」などに変更してください。'
  ].join('\n');
}


function updateDashboardQuietly_(ss) {

  try {
    ensureSettingsSheet_(ss);
    const ctx = buildContext_(ss);
    writeInstrumentSheet_(ss, ctx);
    writeStatusSheet_(ss, ctx);
    writeDashboardSheet_(ss, ctx);
  } catch (e) {
    console.error('ダッシュボードの更新に失敗: ' + e.message);
  }
}
