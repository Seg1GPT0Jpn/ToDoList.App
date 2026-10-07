/*******************************************************
 * 団員アプリ（Firebase）との同期  AppSync.gs
 *
 * 応募者一覧で「対応状況＝正式参加」の人を「加入確定（団員）」として、
 * （「活動休止」の人は団員のまま閲覧のみ）
 * 団員アプリ（Firebase プロジェクト）へ必要最小限の情報だけを送ります。
 *
 * 送るもの
 *   memberAccess/{メールアドレス} … ログイン許可（状態・権限・団員ID・パート）
 *   members/{団員ID}              … 表示名・楽器・パート（団員同士で見える情報）
 *   stats/summary                 … 団員数・パート別人数
 *   adminStats/summary            … 参加希望者数など（運営のみ閲覧）
 * 送らないもの
 *   本名・年代・地域・所属・参加理由・連絡記録などの個人情報
 *
 * 安全のための仕組み
 *   ・秘密鍵や API キーを使わない（実行する人の Google アカウントの権限で書き込む）
 *   ・団員ごとに変わらない「アプリID」を応募者一覧に振る → 何度実行しても重複しない
 *   ・変わった項目だけ書き込む／本人が変えた表示名・自己紹介は上書きしない
 *   ・正式参加でなくなった人は削除せず「利用停止」にする
 *   ・スプレッドシートの不具合で大量に利用停止になりそうなときは止める
 *   ・通信エラーは時間をおいて自動で再試行
 *   ・ログにメールアドレスを出さない
 *
 * 事前設定（README の手順）
 *   1. appsscript.json に Firestore 用の権限（datastore）を追加
 *   2. 「アプリ連携設定」シートで Firebase プロジェクトID・管理者を設定
 *   3. 実行する Google アカウントが Firebase プロジェクトのオーナー（または編集者）であること
 *******************************************************/

const APP_SYNC = {
  settingsSheet: 'アプリ連携設定',
  settingsTitle: 'アプリ連携設定（団員アプリ）',
  joinedStatus: '正式参加',
  // 加入確定後に休んでいる団員（アプリは閲覧のみ。出欠・回答はできない）
  pausedStatus: '活動休止',
  defaultProjectId: 'kanagawa-connect-official',
  firestoreBase: 'https://firestore.googleapis.com/v1',
  maxWritesPerCommit: 400,
  retryDelaysMs: [1000, 2000, 4000, 8000],
  lastRunProperty: 'KCO_APP_SYNC_LAST',
  triggerHandler: 'appSyncScheduled',
  // これ以上の割合の団員が一度に利用停止になる場合は止める
  massDeactivationRatio: 0.5,
  massDeactivationMin: 3
};

const APP_SYNC_ITEMS_ = [
  { key: 'projectId', label: 'Firebase プロジェクトID', def: () => APP_SYNC.defaultProjectId, desc: '団員アプリの Firebase プロジェクトID' },
  { key: 'adminEmails', label: '管理者のメールアドレス', def: () => appSyncCurrentUserEmail_(), desc: 'カンマ区切り。アプリの管理画面をすべて使えます' },
  { key: 'staffEmails', label: '運営補助のメールアドレス', def: () => '', desc: 'カンマ区切り。練習予定・お知らせを作成できます（演奏会情報・応募者数は不可）' },
  { key: 'autoSync', label: '自動同期（15分ごと）', def: () => 'いいえ', desc: 'はい／いいえ。「はい」にして「自動同期を設定」を実行すると定期的に同期します' },
  { key: 'pushEnabled', label: 'プッシュ通知の送信', def: () => 'いいえ', desc: 'はい／いいえ。「はい」にして「通知の送信を設定」を実行すると、アプリで予約した通知を10分ごとに送ります' },
  { key: 'reminderEnabled', label: '練習の前日通知', def: () => 'はい', desc: 'はい／いいえ。公開中の練習の前日に「明日は練習です」と通知します（プッシュ通知の送信が「はい」のとき）' },
  { key: 'reminderHour', label: '前日通知の時刻（時）', def: () => 18, desc: '0〜23。この時刻以降の最初の送信で前日通知を送ります' }
];


/*******************************************************
 * メニューから呼ぶ関数
 *******************************************************/

/** 書き込まずに、同期すると何が変わるかだけ表示する */
function appSyncPreview() {

  const result = appSyncCore_({ dryRun: true });

  alert_(appSyncDescribe_(result, true));

  return result;
}


/** 確認のうえ同期する */
function appSyncRun() {

  const preview = appSyncCore_({ dryRun: true });

  if (preview.error) {
    alert_(appSyncDescribe_(preview, true));
    return preview;
  }

  if (!preview.writes) {
    // Firebase 側は最新。応募者一覧の「Firebase連携状態」「アプリ利用」だけ最新にする
    appSyncCore_({ dryRun: false, allowMassDeactivation: false });
    alert_('団員アプリはすでに最新です（変更なし）。\n\n' + appSyncDescribe_(preview, true));
    return preview;
  }

  const ok = confirm_('団員アプリへ同期', appSyncDescribe_(preview, true) + '\n\nこの内容で団員アプリへ反映しますか？');

  if (!ok) {
    alert_('同期を中止しました（何も変更していません）。');
    return preview;
  }

  const result = appSyncCore_({ dryRun: false, allowMassDeactivation: preview.massDeactivation });

  alert_(appSyncDescribe_(result, false));

  return result;
}


/** 15分ごとの自動同期を設定する（設定シートで「はい」のときだけ実際に同期） */
function appSyncInstallTrigger() {

  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === APP_SYNC.triggerHandler)
    .forEach(t => ScriptApp.deleteTrigger(t));

  ScriptApp.newTrigger(APP_SYNC.triggerHandler).timeBased().everyMinutes(15).create();

  const settings = appSyncSettings_(SpreadsheetApp.getActiveSpreadsheet());

  alert_(
    '自動同期（15分ごと）を設定しました。\n\n' +
    (settings.autoSync
      ? '「アプリ連携設定」で自動同期が「はい」になっているため、15分ごとに同期します。'
      : '※「アプリ連携設定」の「自動同期」が「いいえ」のため、まだ同期は行われません。「はい」にすると開始します。') +
    '\n\n大量の利用停止が必要な変更など、確認が必要な場合は自動では反映せず、次回の手動同期で確認できます。'
  );
}


/** 時間ベースのトリガーから呼ばれる */
function appSyncScheduled() {

  const settings = appSyncSettings_(SpreadsheetApp.getActiveSpreadsheet());

  if (!settings.autoSync) return null;

  // 自動実行では、大量の利用停止は行わない（人が確認する）
  const result = appSyncCore_({ dryRun: false, allowMassDeactivation: false });

  if (result.error && !result.busy) {
    // 失敗はトリガーの失敗通知メールに残す（個人情報は含まない）
    throw new Error('団員アプリ同期に失敗しました: ' + result.error);
  }

  return result;
}


/** 「アプリ連携設定」シートを開く（無ければ作る） */
function appSyncOpenSettings() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = appSyncEnsureSettingsSheet_(ss);

  ss.setActiveSheet(sheet);
}


/*******************************************************
 * 同期の本体
 *******************************************************/

function appSyncCore_(options) {

  const dryRun = !!options.dryRun;
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const result = {
    dryRun,
    error: null,
    busy: false,
    projectId: '',
    members: 0,
    paused: 0,
    accessCreate: 0,
    accessUpdate: 0,
    accessDeactivate: 0,
    memberCreate: 0,
    memberUpdate: 0,
    memberDeactivate: 0,
    statsChanged: false,
    newIds: 0,
    writes: 0,
    problems: [],
    massDeactivation: false
  };

  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    result.busy = true;
    result.error = '他の処理が実行中です。少し待ってから再実行してください。';
    return result;
  }

  try {

    const settings = appSyncSettings_(ss);

    result.projectId = settings.projectId;

    if (!/^[a-z0-9-]{4,40}$/.test(settings.projectId)) {
      result.error = '「アプリ連携設定」の Firebase プロジェクトID が正しくありません。';
      return result;
    }

    const sheet = ss.getSheetByName(CONFIG.applicantsSheet);

    if (!sheet) {
      result.error = '「応募者一覧」シートがありません。';
      return result;
    }

    if (!dryRun) appSyncEnsureColumns_(sheet);

    let app = readApplicants_(sheet);

    if (app.map.status === undefined || app.map.email === undefined) {
      result.error = '応募者一覧に「対応状況」または「メールアドレス」列が見つかりません。';
      return result;
    }

    // 1. 加入確定者を決める（アプリIDが無い人には新しく振る）
    const desired = appSyncDesiredMembers_(app, settings, result);

    // アプリIDは Firestore に書く前にスプレッドシートへ保存する
    // （先に Firestore へ書いて失敗すると、次回に別IDで二重登録されるため）
    if (!dryRun && desired.newIdRows.length) {
      const appIdCol = readApplicants_(sheet).map.appId;
      desired.newIdRows.forEach(x => sheet.getRange(x.row, appIdCol + 1).setValue(x.id));
      app = readApplicants_(sheet);
    }

    result.newIds = desired.newIdRows.length;
    result.members = desired.members.length;
    result.paused = desired.members.filter(m => m.status === 'paused').length;

    // 2. いまの Firestore の状態を読む
    const client = appSyncClient_(settings.projectId);
    const existingAccess = client.list('memberAccess');
    const existingMembers = client.list('members');
    const existingStats = client.get('stats/summary');
    const existingAdminStats = client.get('adminStats/summary');

    // 3. 書き込み内容を計算
    const plan = appSyncPlan_(desired, settings, existingAccess, existingMembers, {
      stats: existingStats,
      adminStats: existingAdminStats,
      applicants: app.records
    });

    Object.assign(result, plan.counts);
    result.writes = plan.writes.length;

    // 大量の利用停止は止める（スプレッドシートの列が変わった・誤操作などの防止）
    const activeBefore = existingAccess.filter(d => d.fields.status === 'active' && d.fields.source === 'sheet').length;
    const deactivating = plan.counts.accessDeactivate;

    if (deactivating >= APP_SYNC.massDeactivationMin && activeBefore > 0 && deactivating / activeBefore >= APP_SYNC.massDeactivationRatio) {
      result.massDeactivation = true;
      if (!dryRun && !options.allowMassDeactivation) {
        result.error = '一度に ' + deactivating + '人 が利用停止になる変更のため、自動では反映しませんでした。「団員アプリへ同期」で内容を確認してください。';
        return result;
      }
    }

    if (dryRun) return result;

    // 4. 書き込み（まとめて送信。失敗したら自動で再試行）
    for (let i = 0; i < plan.writes.length; i += APP_SYNC.maxWritesPerCommit) {
      client.commit(plan.writes.slice(i, i + APP_SYNC.maxWritesPerCommit));
    }

    // 5. 応募者一覧の「Firebase連携状態」「アプリ利用」に結果を書き戻す（Membership.gs がある場合）
    if (typeof globalThis.membershipAfterAppSync_ === 'function') {
      try {
        globalThis.membershipAfterAppSync_(ss, new Set(desired.members.map(m => m.row)));
      } catch (e) {
        result.problems.push('「アプリ利用」列の更新に失敗しました（同期自体は完了）');
        console.error('アプリ利用の更新に失敗: ' + e.message);
      }
    }

    if (plan.writes.length) appSyncRecordRun_(result);

    return result;

  } catch (err) {

    result.error = appSyncErrorMessage_(err);
    if (!dryRun) appSyncRecordRun_(result);
    return result;

  } finally {
    lock.releaseLock();
  }
}


/**
 * 応募者一覧から「加入確定（正式参加）」の団員を作る
 */
function appSyncDesiredMembers_(app, settings, result) {

  const index = buildInstrumentIndex_(loadSettings_(SpreadsheetApp.getActiveSpreadsheet()));
  const members = [];
  const newIdRows = [];
  const usedEmails = new Map();
  const usedIds = new Map();

  // 既存のアプリIDの重複チェック
  app.records.forEach(r => {
    const id = toStr_(r.appId);
    if (!id) return;
    usedIds.set(id, (usedIds.get(id) || []).concat([r]));
  });

  usedIds.forEach((list, id) => {
    if (list.length > 1) result.problems.push('アプリID「' + id + '」が ' + noLabel_(list) + ' に重複しています（同期対象外）');
  });

  app.records
    .slice()
    .sort(compareByNo_)
    .forEach(r => {

      if (r.status !== APP_SYNC.joinedStatus && r.status !== APP_SYNC.pausedStatus) return;

      // 運営が「アプリ利用」を「停止」にした人は登録しない（正式参加のままでも）
      if (r.appUsage === '停止') {
        result.stopped = (result.stopped || 0) + 1;
        return;
      }

      const email = emailKey_(toStr_(r.appEmail) || toStr_(r.email));

      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        result.problems.push(noLabel_([r]) + '：メールアドレスが無いか正しくないため、アプリに登録できません');
        return;
      }

      if (usedEmails.has(email)) {
        result.problems.push(noLabel_([r]) + '：' + noLabel_([usedEmails.get(email)]) + ' と同じメールアドレスのため、アプリには1人分だけ登録します');
        return;
      }

      let id = toStr_(r.appId);

      if (id && (usedIds.get(id) || []).length > 1) return;

      if (!id) {
        id = appSyncNewId_();
        newIdRows.push({ row: r.row, id });
      }

      usedEmails.set(email, r);

      const parsed = parseInstrumentCell_(r.instrument, index);
      const code = parsed.primaryCode || '';
      const info = code ? index.info[code] : null;
      const part = info ? (info.part || code) : '';

      if (!code) result.problems.push(noLabel_([r]) + '：楽器を判定できないため「未設定」で登録します');

      members.push({
        id,
        email,
        row: r.row,
        no: r.no,
        displayName: appSyncDisplayName_(r),
        instrument: code,
        instrumentLabel: info ? info.name : toStr_(r.instrument),
        part,
        section: APP_SYNC_SECTIONS_[part] || 'other',
        status: r.status === APP_SYNC.pausedStatus ? 'paused' : 'active'
      });
    });

  return { members, newIdRows };
}


// パート → セクション（アプリの表示用。src/lib/parts.ts と同じ）
const APP_SYNC_SECTIONS_ = {
  Fl: 'woodwind', Ob: 'woodwind', Cl: 'woodwind', Fg: 'woodwind',
  Hr: 'brass', Tp: 'brass', Tb: 'brass', Tuba: 'brass',
  Perc: 'percussion',
  Vn: 'strings', Va: 'strings', Vc: 'strings', Cb: 'strings',
  Hp: 'other', Pf: 'other'
};


/**
 * 表示名：ニックネーム → お名前・呼ばれたい名前（フォームの質問自体が「呼ばれたい名前」）
 * 本人はアプリのマイページで変更できる（以後、同期では上書きしない）
 */
function appSyncDisplayName_(r) {

  const name = toStr_(r.nickname) || toStr_(r.name);

  return (name || ('団員' + toStr_(r.no))).slice(0, 30);
}


/**
 * Firestore への書き込み内容を計算する（純粋な計算。テスト可能）
 *
 * existingAccess / existingMembers: [{ id, fields }]
 */
function appSyncPlan_(desired, settings, existingAccess, existingMembers, extra) {

  const now = new Date();
  const writes = [];
  const counts = { accessCreate: 0, accessUpdate: 0, accessDeactivate: 0, memberCreate: 0, memberUpdate: 0, memberDeactivate: 0, statsChanged: false };
  const accessById = new Map(existingAccess.map(d => [d.id, d.fields]));
  const membersById = new Map(existingMembers.map(d => [d.id, d.fields]));
  const roleOf = email => (settings.adminEmails.indexOf(email) >= 0 ? 'admin' : settings.staffEmails.indexOf(email) >= 0 ? 'staff' : 'member');

  // ---- memberAccess（ログイン許可）----
  const desiredAccess = new Map();

  desired.members.forEach(m => desiredAccess.set(m.email, { status: m.status || 'active', role: roleOf(m.email), memberId: m.id, part: m.part || '' }));

  settings.adminEmails.concat(settings.staffEmails).forEach(email => {
    if (!desiredAccess.has(email)) desiredAccess.set(email, { status: 'active', role: roleOf(email), memberId: null, part: '' });
  });

  desiredAccess.forEach((want, email) => {
    const cur = accessById.get(email);
    const data = { email, status: want.status, role: want.role, memberId: want.memberId, part: want.part, source: 'sheet', updatedAt: now };
    if (!cur) {
      writes.push(appSyncWrite_('memberAccess/' + email, data, null));
      counts.accessCreate++;
      return;
    }
    if (cur.status !== want.status || cur.role !== want.role || (cur.memberId || null) !== want.memberId ||
        (cur.part || '') !== want.part || cur.source !== 'sheet') {
      writes.push(appSyncWrite_('memberAccess/' + email, data, ['email', 'status', 'role', 'memberId', 'part', 'source', 'updatedAt']));
      counts.accessUpdate++;
    }
  });

  // 同期で作った許可のうち、もう対象でない人は利用停止（削除はしない）
  existingAccess.forEach(d => {
    if (desiredAccess.has(d.id)) return;
    if (d.fields.source !== 'sheet' || d.fields.status === 'inactive') return;
    writes.push(appSyncWrite_('memberAccess/' + d.id, { status: 'inactive', updatedAt: now }, ['status', 'updatedAt']));
    counts.accessDeactivate++;
  });

  // ---- members（団員プロフィール）----
  const activeIds = new Set(desired.members.map(m => m.id));

  desired.members.forEach(m => {
    const cur = membersById.get(m.id);
    const managed = { instrument: m.instrument, instrumentLabel: m.instrumentLabel, part: m.part, section: m.section, status: m.status || 'active' };
    if (!cur) {
      writes.push(appSyncWrite_('members/' + m.id, Object.assign({ displayName: m.displayName, bio: '', roleLabel: '', joinedAt: now, updatedAt: now }, managed), null));
      counts.memberCreate++;
      return;
    }
    const changed = Object.keys(managed).filter(k => (cur[k] === undefined ? '' : cur[k]) !== managed[k]);
    if (changed.length) {
      // 表示名・自己紹介・役職表示は本人／管理者がアプリで変えるので触らない
      writes.push(appSyncWrite_('members/' + m.id, Object.assign({ updatedAt: now }, managed), Object.keys(managed).concat(['updatedAt'])));
      counts.memberUpdate++;
    }
  });

  existingMembers.forEach(d => {
    if (activeIds.has(d.id) || d.fields.status === 'inactive') return;
    writes.push(appSyncWrite_('members/' + d.id, { status: 'inactive', updatedAt: now }, ['status', 'updatedAt']));
    counts.memberDeactivate++;
  });

  // ---- stats（団員数・パート別人数）----
  const s = loadSettings_(SpreadsheetApp.getActiveSpreadsheet());
  const index = buildInstrumentIndex_(s);
  const byPart = appSyncPartStats_(desired.members, index);
  const stats = {
    memberCount: desired.members.length,
    pausedCount: desired.members.filter(m => m.status === 'paused').length,
    targetMembers: s.targetMembers,
    decisionMembers: s.decisionMembers,
    minimumMembers: s.minimumMembers,
    byPart
  };

  if (!extra.stats || JSON.stringify(appSyncComparable_(extra.stats.fields)) !== JSON.stringify(appSyncComparable_(stats))) {
    writes.push(appSyncWrite_('stats/summary', Object.assign({ updatedAt: now }, stats), null));
    counts.statsChanged = true;
  }

  // ---- adminStats（運営のみ：参加希望者数・対応状況別）----
  const st = computeStats_(extra.applicants, s, index, now);
  const adminStats = {
    applicantCount: st.total,
    activeApplicantCount: st.active,
    memberCount: desired.members.length,
    statusCounts: st.statusCounts
  };

  if (!extra.adminStats || JSON.stringify(appSyncComparable_(extra.adminStats.fields)) !== JSON.stringify(appSyncComparable_(adminStats))) {
    writes.push(appSyncWrite_('adminStats/summary', Object.assign({ updatedAt: now }, adminStats), null));
    counts.statsChanged = true;
  }

  return { writes, counts };
}


/**
 * パート別の加入確定人数（目標・最低人数は「募集設定」から）
 */
function appSyncPartStats_(members, index) {

  const counts = {};
  const targets = {};

  members.forEach(m => {
    const part = m.part || '';
    if (part) counts[part] = (counts[part] || 0) + 1;
  });

  index.order.forEach(code => {
    const info = index.info[code];
    if (!info || !info.inSettings) return;
    const part = info.part || code;
    if (!targets[part]) targets[part] = { target: null, min: null };
    if (info.target !== null && info.target !== undefined) targets[part].target = (targets[part].target || 0) + info.target;
    if (info.min !== null && info.min !== undefined) targets[part].min = (targets[part].min || 0) + info.min;
  });

  const order = [];

  index.order.forEach(code => {
    const part = (index.info[code] && index.info[code].part) || code;
    if (order.indexOf(part) < 0) order.push(part);
  });

  Object.keys(counts).forEach(p => { if (order.indexOf(p) < 0) order.push(p); });

  return order
    .filter(p => counts[p] || (targets[p] && (targets[p].target || targets[p].min)))
    .map(p => ({
      part: p,
      label: PART_LABELS_[p] || p,
      count: counts[p] || 0,
      target: targets[p] ? targets[p].target : null,
      min: targets[p] ? targets[p].min : null
    }));
}


function appSyncComparable_(obj) {

  const copy = {};

  Object.keys(obj || {}).sort().forEach(k => {
    if (k !== 'updatedAt') copy[k] = obj[k];
  });

  return copy;
}


function appSyncWrite_(path, data, mask) {

  return { path, data, mask };
}


/*******************************************************
 * Firestore REST クライアント（秘密鍵不要）
 *
 * ScriptApp.getOAuthToken() = 実行している Google アカウントの権限で書き込む。
 * そのため Security Rules ではなく IAM（プロジェクトのオーナー・編集者）で許可される。
 *******************************************************/

function appSyncClient_(projectId) {

  const root = 'projects/' + projectId + '/databases/(default)/documents';
  const base = APP_SYNC.firestoreBase + '/' + root;

  const request = (method, url, body) => {

    let lastError = null;

    for (let attempt = 0; attempt <= APP_SYNC.retryDelaysMs.length; attempt++) {

      let res = null;

      try {
        res = UrlFetchApp.fetch(url, {
          method,
          contentType: 'application/json',
          payload: body ? JSON.stringify(body) : undefined,
          headers: { Authorization: 'Bearer ' + ScriptApp.getOAuthToken(), 'X-Goog-User-Project': projectId },
          muteHttpExceptions: true
        });
      } catch (e) {
        lastError = e;
      }

      if (res) {
        const code = res.getResponseCode();
        if (code >= 200 && code < 300) return JSON.parse(res.getContentText() || '{}');
        if (code === 409 || (code === 400 && /FAILED_PRECONDITION/.test(res.getContentText()))) {
          throw new Error('HTTP ' + code + ' ALREADY_EXISTS');
        }
        if (code === 404 && method === 'get') return null;
        if ([429, 500, 502, 503, 504].indexOf(code) < 0) {
          throw new Error('HTTP ' + code + ' ' + appSyncApiError_(res.getContentText()));
        }
        lastError = new Error('HTTP ' + code);
      }

      if (attempt < APP_SYNC.retryDelaysMs.length) Utilities.sleep(APP_SYNC.retryDelaysMs[attempt]);
    }

    throw lastError || new Error('通信に失敗しました');
  };

  return {

    get(path) {
      const doc = request('get', base + '/' + path);
      return doc ? { id: path.split('/').pop(), fields: appSyncDecodeFields_(doc.fields || {}) } : null;
    },

    list(collection) {
      const out = [];
      let token = '';
      do {
        const res = request('get', base + '/' + collection + '?pageSize=300' + (token ? '&pageToken=' + encodeURIComponent(token) : ''));
        ((res && res.documents) || []).forEach(d => out.push({ id: d.name.split('/').pop(), fields: appSyncDecodeFields_(d.fields || {}) }));
        token = res && res.nextPageToken ? res.nextPageToken : '';
      } while (token);
      return out;
    },

    /** 1つの項目が値と等しいドキュメントだけを読む（読み取り回数を抑える） */
    query(collection, field, value) {
      const res = request('post', base + ':runQuery', {
        structuredQuery: {
          from: [{ collectionId: collection }],
          where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: appSyncEncodeValue_(value) } },
          limit: 500
        }
      });
      return (Array.isArray(res) ? res : [])
        .filter(r => r && r.document)
        .map(r => ({ id: r.document.name.split('/').pop(), fields: appSyncDecodeFields_(r.document.fields || {}) }));
    },

    commit(writes) {
      return request('post', base + ':commit', {
        writes: writes.map(w => {
          if (w.remove) return { delete: root + '/' + w.path };
          const out = { update: { name: root + '/' + w.path, fields: appSyncEncodeFields_(w.data) } };
          if (w.mask) out.updateMask = { fieldPaths: w.mask };
          if (w.mustNotExist) out.currentDocument = { exists: false };
          return out;
        })
      });
    }
  };
}


function appSyncEncodeValue_(v) {

  if (v === null || v === undefined) return { nullValue: null };
  if (isDate_(v)) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(appSyncEncodeValue_) } };
  if (typeof v === 'object') return { mapValue: { fields: appSyncEncodeFields_(v) } };

  return { stringValue: String(v) };
}


function appSyncEncodeFields_(obj) {

  const out = {};

  Object.keys(obj).forEach(k => { out[k] = appSyncEncodeValue_(obj[k]); });

  return out;
}


function appSyncDecodeValue_(v) {

  if (!v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('nullValue' in v) return null;
  if ('timestampValue' in v) return v.timestampValue;
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(appSyncDecodeValue_);
  if ('mapValue' in v) return appSyncDecodeFields_(v.mapValue.fields || {});

  return null;
}


function appSyncDecodeFields_(fields) {

  const out = {};

  Object.keys(fields).forEach(k => { out[k] = appSyncDecodeValue_(fields[k]); });

  return out;
}


function appSyncApiError_(text) {

  try {
    const json = JSON.parse(text);
    return (json.error && (json.error.status + ' ' + json.error.message)) || '';
  } catch (e) {
    return '';
  }
}


function appSyncErrorMessage_(err) {

  const msg = String((err && err.message) || err);

  if (/HTTP 403/.test(msg)) {
    return 'Firebase に書き込む権限がありません。実行している Google アカウントが Firebase プロジェクトのオーナー（または編集者）か、appsscript.json に datastore の権限があるか確認してください。（' + msg.slice(0, 160) + '）';
  }

  if (/HTTP 404/.test(msg)) {
    return 'Firebase プロジェクトまたは Firestore が見つかりません。プロジェクトIDと、Firestore データベースが作成済みか確認してください。（' + msg.slice(0, 160) + '）';
  }

  return '同期に失敗しました：' + msg.slice(0, 200);
}


/*******************************************************
 * 設定・補助
 *******************************************************/

function appSyncEnsureSettingsSheet_(ss) {

  const existing = findOwnedSheet_(ss, APP_SYNC.settingsSheet, APP_SYNC.settingsTitle);

  if (existing && existing.getLastRow() > 0) {
    appSyncAddMissingItems_(existing);
    return existing;
  }

  const sheet = existing || getOrCreateOwnedSheet_(ss, APP_SYNC.settingsSheet, APP_SYNC.settingsTitle);
  const rows = [[APP_SYNC.settingsTitle, '', ''], ['項目', '値', '説明']];

  APP_SYNC_ITEMS_.forEach(item => rows.push([item.label, item.def(), item.desc]));

  rows.push(['', '', '']);
  rows.push(['※ このシートには団員アプリの管理者のメールアドレスが入ります。公開しないでください。', '', '']);
  rows.push(['※ 加入確定 ＝ 応募者一覧の対応状況が「' + APP_SYNC.joinedStatus + '」の人です。「' + APP_SYNC.pausedStatus + '」の人は閲覧のみ可能です。', '', '']);

  ensureRows_(sheet, rows.length);
  ensureCols_(sheet, 3);
  sheet.getRange(1, 1, rows.length, 3).setValues(rows);
  sheet.getRange(1, 1, 2, 3).setFontWeight('bold');
  sheet.getRange(2, 1, 1, 3).setBackground(COLOR_HEADER_);
  sheet.setColumnWidth(1, 240);
  sheet.setColumnWidth(2, 320);

  return sheet;
}


/** 後から増えた設定項目を、既存の設定シートの末尾に追加する（入力済みの値は変えない） */
function appSyncAddMissingItems_(sheet) {

  const lastRow = sheet.getLastRow();
  const labels = sheet.getRange(1, 1, Math.max(lastRow, 1), 1).getValues().map(r => toStr_(r[0]));
  const missing = APP_SYNC_ITEMS_.filter(item => labels.indexOf(item.label) < 0);

  if (!missing.length) return 0;

  const rows = missing.map(item => [item.label, item.def(), item.desc]);

  ensureRows_(sheet, lastRow + rows.length);
  ensureCols_(sheet, 3);
  sheet.getRange(lastRow + 1, 1, rows.length, 3).setValues(rows);

  return rows.length;
}


function appSyncSettings_(ss) {

  const sheet = appSyncEnsureSettingsSheet_(ss);
  const values = sheet.getRange(1, 1, Math.max(sheet.getLastRow(), 1), 3).getValues();
  const raw = {};

  APP_SYNC_ITEMS_.forEach(item => {
    const row = values.find(r => toStr_(r[0]) === item.label);
    raw[item.key] = row ? row[1] : item.def();
  });

  const emails = v => toStr_(v).split(/[,、，\s]+/).map(emailKey_).filter(e => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e));

  return {
    projectId: toStr_(raw.projectId) || APP_SYNC.defaultProjectId,
    adminEmails: emails(raw.adminEmails),
    staffEmails: emails(raw.staffEmails),
    autoSync: parseSettingValue_({ type: 'bool' }, raw.autoSync) === true,
    pushEnabled: parseSettingValue_({ type: 'bool' }, raw.pushEnabled) === true,
    reminderEnabled: parseSettingValue_({ type: 'bool' }, raw.reminderEnabled) !== false,
    reminderHour: appSyncHour_(raw.reminderHour)
  };
}


function appSyncHour_(v) {

  const n = Number(v);

  return Number.isInteger(n) && n >= 0 && n <= 23 ? n : 18;
}


/** 応募者一覧に「アプリID」「アプリ用メールアドレス」列が無ければ末尾に追加 */
function appSyncEnsureColumns_(sheet) {

  const lastCol = sheet.getLastColumn();
  const headers = sheet.getRange(1, 1, 1, Math.max(lastCol, 1)).getValues()[0].map(toStr_);
  const res = resolveColumns_(headers, applicantFieldDefs_(), false);
  const add = [];

  if (res.map.appId === undefined) add.push('アプリID');
  if (res.map.appEmail === undefined) add.push('アプリ用メールアドレス');

  if (add.length) {
    ensureCols_(sheet, lastCol + add.length);
    sheet.getRange(1, lastCol + 1, 1, add.length).setValues([add]);
    expandFilterToData_(sheet);
  }

  return add;
}


function appSyncNewId_() {

  return 'm' + Utilities.getUuid().replace(/-/g, '').slice(0, 15);
}


function appSyncCurrentUserEmail_() {

  try {
    return Session.getEffectiveUser().getEmail() || '';
  } catch (e) {
    return '';
  }
}


function appSyncRecordRun_(result) {

  try {
    PropertiesService.getScriptProperties().setProperty(APP_SYNC.lastRunProperty, JSON.stringify({
      at: new Date().toISOString(),
      ok: !result.error,
      members: result.members,
      writes: result.writes,
      error: result.error ? String(result.error).slice(0, 300) : ''
    }));
  } catch (e) {
    console.error('同期結果を記録できませんでした: ' + e.message);
  }
}


/** 結果の説明（メールアドレスは含めない） */
function appSyncDescribe_(r, isPreview) {

  if (r.error) return '⚠️ ' + r.error;

  const lines = [
    (isPreview ? '【確認（まだ反映していません）】' : '【団員アプリへ反映しました】'),
    'Firebase プロジェクト：' + r.projectId,
    '加入確定（正式参加＋活動休止）：' + r.members + '人' + (r.paused ? '（うち活動休止 ' + r.paused + '人）' : ''),
    '',
    'ログイン許可：新規 ' + r.accessCreate + '人／変更 ' + r.accessUpdate + '人／利用停止 ' + r.accessDeactivate + '人',
    '団員プロフィール：新規 ' + r.memberCreate + '人／変更 ' + r.memberUpdate + '人／利用停止 ' + r.memberDeactivate + '人',
    '団員数・パート別人数：' + (r.statsChanged ? '更新' : '変更なし')
  ];

  if (r.newIds) lines.push('新しく振るアプリID：' + r.newIds + '件（応募者一覧の「アプリID」列）');
  if (r.stopped) lines.push('アプリ利用が「停止」のため登録しない人：' + r.stopped + '人');
  if (r.massDeactivation) lines.push('', '⚠️ 一度に多くの人が利用停止になります。応募者一覧の「対応状況」が正しいか確認してください。');
  if (r.problems.length) lines.push('', '確認が必要な行：', ...r.problems.slice(0, 15).map(p => '・' + p));

  return lines.join('\n');
}
