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
