/*******************************************************
 * 団員アプリのプッシュ通知  AppNotify.gs
 *
 * 団員アプリの運営画面で「送信を予約」した通知（notifications）と、
 * 練習の前日通知を、通知をオンにした団員の端末へ送ります。
 *
 *   ・送信には Firebase Cloud Messaging（FCM）の HTTP v1 API を使う
 *   ・秘密鍵やサーバーキーは使わない（実行する Google アカウントの権限で送る）
 *   ・送り先は「在籍中・活動休止中」の団員の端末だけ（退団した人の端末には送らない）
 *   ・同じ通知を二重に送らない（送信前に「送信中」にする／前日通知は練習ごとに1回）
 *   ・届かなくなった端末の登録は自動で削除する
 *   ・ログにメールアドレス・通知トークンを出さない
 *
 * 事前設定（README の手順）
 *   1. appsscript.json に firebase.messaging の権限を追加
 *   2. 「アプリ連携設定」の「プッシュ通知の送信」を「はい」
 *   3. メニュー「通知の送信を設定（10分ごと）」を1回実行
 *******************************************************/

const APP_NOTIFY = {
  triggerHandler: 'appNotifyScheduled',
  intervalMinutes: 10,
  fcmBase: 'https://fcm.googleapis.com/v1/projects/',
  batchSize: 50,
  // 「送信中」のまま止まった通知（実行時間切れなど）は、この時間が過ぎたら失敗扱いにする（再送はしない）
  staleSendingMs: 30 * 60 * 1000,
  maxPerRun: 20,
  lastRunProperty: 'KCO_APP_NOTIFY_LAST'
};


/*******************************************************
 * メニューから呼ぶ関数
 *******************************************************/

/** 10分ごとの送信を設定する（「アプリ連携設定」で「はい」のときだけ実際に送る） */
function appNotifyInstallTrigger() {

  ScriptApp.getProjectTriggers()
    .filter(t => t.getHandlerFunction() === APP_NOTIFY.triggerHandler)
    .forEach(t => ScriptApp.deleteTrigger(t));

  ScriptApp.newTrigger(APP_NOTIFY.triggerHandler).timeBased().everyMinutes(APP_NOTIFY.intervalMinutes).create();

  const settings = appSyncSettings_(SpreadsheetApp.getActiveSpreadsheet());

  alert_(
    '通知の送信（' + APP_NOTIFY.intervalMinutes + '分ごと）を設定しました。\n\n' +
    (settings.pushEnabled
      ? '団員アプリで予約した通知を' + APP_NOTIFY.intervalMinutes + '分ごとに送ります。' +
        (settings.reminderEnabled ? '\n練習の前日 ' + settings.reminderHour + '時以降に「明日は練習です」も送ります。' : '')
      : '※「アプリ連携設定」の「プッシュ通知の送信」が「いいえ」のため、まだ送信は行われません。「はい」にすると開始します。')
  );
}


/** いますぐ送信する（予約済みの通知と、必要なら前日通知） */
function appNotifyRunNow() {

  const result = appNotifyCore_({});

  alert_(appNotifyDescribe_(result));

  return result;
}


/** 時間ベースのトリガーから呼ばれる */
function appNotifyScheduled() {

  const settings = appSyncSettings_(SpreadsheetApp.getActiveSpreadsheet());

  if (!settings.pushEnabled) return null;

  const result = appNotifyCore_({});

  if (result.error && !result.busy) {
    throw new Error('団員アプリの通知送信に失敗しました: ' + result.error);
  }

  return result;
}


/*******************************************************
 * 送信の本体
 *******************************************************/

function appNotifyCore_(options) {

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const settings = appSyncSettings_(ss);
  const result = { error: null, busy: false, reminders: 0, notifications: 0, sent: 0, failed: 0, removedTokens: 0, stale: 0 };
  const lock = LockService.getScriptLock();

  if (!lock.tryLock(CONFIG.lockWaitMs)) {
    result.busy = true;
    result.error = '他の処理が実行中です。少し待ってから再実行してください。';
    return result;
  }

  try {

    if (!/^[a-z0-9-]{4,40}$/.test(settings.projectId)) {
      result.error = '「アプリ連携設定」の Firebase プロジェクトID が正しくありません。';
      return result;
    }

    const client = appSyncClient_(settings.projectId);
    const now = options.now || new Date();

    // 1. 練習の前日通知を予約する
    if (settings.reminderEnabled && appNotifyHourJst_(now) >= settings.reminderHour) {
      result.reminders = appNotifyQueueReminders_(client, now);
    }

    // 2. 「送信中」のまま止まっている通知を失敗にする（二重送信を避けるため再送しない）
    client.query('notifications', 'status', 'sending').forEach(n => {
      const started = Date.parse(n.fields.startedAt || '') || 0;
      if (now.getTime() - started < APP_NOTIFY.staleSendingMs) return;
      client.commit([appSyncWrite_('notifications/' + n.id,
        { status: 'failed', error: '送信が途中で止まりました（再送はしていません）', finishedAt: now },
        ['status', 'error', 'finishedAt'])]);
      result.stale++;
    });

    // 3. 予約された通知を送る
    const pending = client.query('notifications', 'status', 'pending')
      .sort((a, b) => String(a.fields.createdAt || '').localeCompare(String(b.fields.createdAt || '')))
      .slice(0, APP_NOTIFY.maxPerRun);

    if (!pending.length) {
      appNotifyRecordRun_(result);
      return result;
    }

    const recipients = appNotifyRecipients_(client);

    pending.forEach(n => {

      // 先に「送信中」にしてから送る（途中で止まっても二重には送らない）
      client.commit([appSyncWrite_('notifications/' + n.id, { status: 'sending', startedAt: now }, ['status', 'startedAt'])]);

      const targets = appNotifyTargets_(recipients, n.fields.audience);
      const outcome = appNotifySend_(settings.projectId, targets.map(t => t.token), {
        title: String(n.fields.title || 'お知らせ').slice(0, 60),
        body: String(n.fields.body || '').slice(0, 200),
        url: /^\/[A-Za-z0-9/_#?=&-]*$/.test(n.fields.url || '') ? n.fields.url : '/',
        tag: n.id
      });

      // 届かなくなった端末の登録を削除
      if (outcome.invalid.length) {
        const removes = outcome.invalid.map(token => ({ path: 'pushTokens/' + token, remove: true }));
        for (let i = 0; i < removes.length; i += APP_SYNC.maxWritesPerCommit) {
          client.commit(removes.slice(i, i + APP_SYNC.maxWritesPerCommit));
        }
        outcome.invalid.forEach(token => recipients.forEach(r => { if (r.token === token) r.removed = true; }));
        result.removedTokens += outcome.invalid.length;
      }

      client.commit([appSyncWrite_('notifications/' + n.id, {
        status: outcome.fatal ? 'failed' : 'sent',
        sentCount: outcome.sent,
        failedCount: outcome.failed,
        targetCount: targets.length,
        error: outcome.fatal ? appNotifyErrorMessage_(outcome.fatal) : '',
        sentAt: new Date()
      }, ['status', 'sentCount', 'failedCount', 'targetCount', 'error', 'sentAt'])]);

      result.notifications++;
      result.sent += outcome.sent;
      result.failed += outcome.failed;

      if (outcome.fatal) result.error = appNotifyErrorMessage_(outcome.fatal);
    });

    appNotifyRecordRun_(result);

    return result;

  } catch (err) {

    result.error = appSyncErrorMessage_(err);
    appNotifyRecordRun_(result);
    return result;

  } finally {
    lock.releaseLock();
  }
}


/**
 * 明日の練習（公開中・日付が決まっているもの）の前日通知を予約する。
 * 通知のIDを「reminder-練習ID-日付」に固定し、同じ練習には1回だけ送る。
 */
function appNotifyQueueReminders_(client, now) {

  const tomorrow = appNotifyDateJst_(new Date(now.getTime() + 24 * 60 * 60 * 1000));
  let queued = 0;

  client.query('rehearsals', 'date', tomorrow)
    .filter(r => r.fields.published === true)
    .forEach(r => {

      const id = 'reminder-' + r.id + '-' + tomorrow;

      if (client.get('notifications/' + id)) return;

      const f = r.fields;
      const time = f.startTime ? (f.startTime + (f.endTime ? '〜' + f.endTime : '〜')) : '';
      const body = [String(f.title || '練習'), time, f.venue ? String(f.venue) : ''].filter(Boolean).join('　').slice(0, 200);

      try {
        client.commit([{
          path: 'notifications/' + id,
          data: {
            title: '明日は練習です',
            body,
            url: '/schedule/' + r.id,
            audience: { type: 'all', values: [] },
            status: 'pending',
            source: 'reminder',
            createdAt: now,
            createdBy: 'apps-script'
          },
          mask: null,
          mustNotExist: true
        }]);
        queued++;
      } catch (e) {
        // 同時に予約された（すでにある）場合は何もしない
        if (!/ALREADY_EXISTS/.test(String(e && e.message))) throw e;
      }
    });

  return queued;
}


/**
 * 通知を受け取れる端末の一覧（在籍中・活動休止中の団員と運営の端末だけ）
 * 戻り値：[{ token, part, section }]（メールアドレスは持ち回らない）
 */
function appNotifyRecipients_(client) {

  const access = new Map(client.list('memberAccess').map(d => [d.id, d.fields]));
  const out = [];

  client.list('pushTokens').forEach(d => {
    const a = access.get(String(d.fields.accessKey || ''));
    if (!a || (a.status !== 'active' && a.status !== 'paused')) return;
    if (String(d.fields.token || '') !== d.id) return;
    const part = String(a.part || '');
    out.push({ token: d.id, part, section: APP_SYNC_SECTIONS_[part] || '' });
  });

  return out;
}


/** 対象（全員／セクション／パート）で絞り込む。運営などパートの無い人は「全員」宛てだけ受け取る */
function appNotifyTargets_(recipients, audience) {

  const type = audience && audience.type;
  const values = (audience && Array.isArray(audience.values)) ? audience.values : [];
  const seen = new Set();

  return recipients.filter(r => {
    if (r.removed || seen.has(r.token)) return false;
    let ok = true;
    if (type === 'section' && values.length) ok = values.indexOf(r.section) >= 0;
    if (type === 'part' && values.length) ok = values.indexOf(r.part) >= 0;
    if (ok) seen.add(r.token);
    return ok;
  });
}


/**
 * FCM HTTP v1 で送る（まとめて並列に送信。混雑時は1回だけ再試行）
 * 戻り値：{ sent, failed, invalid: [届かなくなったトークン], fatal: 権限エラーなど }
 */
function appNotifySend_(projectId, tokens, message) {

  const outcome = { sent: 0, failed: 0, invalid: [], fatal: null };

  if (!tokens.length) return outcome;

  const url = APP_NOTIFY.fcmBase + projectId + '/messages:send';
  const headers = { Authorization: 'Bearer ' + ScriptApp.getOAuthToken(), 'X-Goog-User-Project': projectId };
  const build = token => ({
    url,
    method: 'post',
    contentType: 'application/json',
    headers,
    muteHttpExceptions: true,
    payload: JSON.stringify({
      message: {
        token,
        // 表示は団員アプリのサービスワーカーが行う（data だけを送る）
        data: { title: message.title, body: message.body, url: message.url, tag: message.tag },
        webpush: { headers: { Urgency: 'high', TTL: '86400' } }
      }
    })
  });

  let queue = tokens.slice();

  for (let round = 0; round < 2 && queue.length && !outcome.fatal; round++) {

    const retry = [];

    for (let i = 0; i < queue.length && !outcome.fatal; i += APP_NOTIFY.batchSize) {

      const chunk = queue.slice(i, i + APP_NOTIFY.batchSize);
      const responses = UrlFetchApp.fetchAll(chunk.map(build));

      responses.forEach((res, j) => {
        const code = res.getResponseCode();
        const text = res.getContentText() || '';
        if (code >= 200 && code < 300) {
          outcome.sent++;
        } else if (code === 404 || (code === 400 && /UNREGISTERED|registration token|INVALID_ARGUMENT/.test(text))) {
          outcome.invalid.push(chunk[j]);
        } else if (code === 401 || code === 403) {
          outcome.fatal = 'HTTP ' + code + ' ' + appSyncApiError_(text);
        } else if ((code === 429 || code >= 500) && round === 0) {
          retry.push(chunk[j]);
        } else {
          outcome.failed++;
        }
      });
    }

    queue = retry;
    if (queue.length) Utilities.sleep(2000);
  }

  if (outcome.fatal) {
    // 権限エラーのときは残りを送っていないので、送れなかった数に含める
    outcome.failed = tokens.length - outcome.sent - outcome.invalid.length;
  }

  return outcome;
}


/*******************************************************
 * 補助
 *******************************************************/

function appNotifyDateJst_(date) {

  return Utilities.formatDate(date, 'Asia/Tokyo', 'yyyy-MM-dd');
}


function appNotifyHourJst_(date) {

  return Number(Utilities.formatDate(date, 'Asia/Tokyo', 'HH'));
}


function appNotifyErrorMessage_(msg) {

  if (/HTTP 40[13]/.test(msg)) {
    return '通知を送る権限がありません。appsscript.json に firebase.messaging の権限があり、実行している Google アカウントが Firebase プロジェクトのオーナーか確認してください。';
  }

  return String(msg).slice(0, 200);
}


function appNotifyRecordRun_(result) {

  try {
    PropertiesService.getScriptProperties().setProperty(APP_NOTIFY.lastRunProperty, JSON.stringify({
      at: new Date().toISOString(),
      ok: !result.error,
      notifications: result.notifications,
      sent: result.sent,
      error: result.error ? String(result.error).slice(0, 300) : ''
    }));
  } catch (e) {
    console.error('通知の送信結果を記録できませんでした: ' + e.message);
  }
}


/** 結果の説明（メールアドレス・通知トークンは含めない） */
function appNotifyDescribe_(r) {

  if (r.error && !r.notifications) return '⚠️ ' + r.error;

  const lines = [
    '【プッシュ通知】',
    '前日通知の予約：' + r.reminders + '件',
    '送信した通知：' + r.notifications + '件（端末 ' + r.sent + '台に送信' + (r.failed ? '／失敗 ' + r.failed + '台' : '') + '）'
  ];

  if (r.removedTokens) lines.push('届かなくなった端末の登録を削除：' + r.removedTokens + '件');
  if (r.stale) lines.push('途中で止まっていた通知：' + r.stale + '件（失敗として記録）');
  if (r.error) lines.push('', '⚠️ ' + r.error);
  if (!r.notifications && !r.reminders) lines.push('', '送信待ちの通知はありませんでした。');

  return lines.join('\n');
}
