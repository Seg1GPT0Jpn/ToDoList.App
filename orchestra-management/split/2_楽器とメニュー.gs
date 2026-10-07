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


