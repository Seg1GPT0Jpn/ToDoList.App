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
    situation: ''
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


