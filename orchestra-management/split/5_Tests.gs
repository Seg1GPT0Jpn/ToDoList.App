/*******************************************************
 * セルフテスト（ユニットテスト相当）
 *
 * メニュー「🛠 メンテナンス ＞ セルフテスト」から実行できます。
 * シートの読み書きは一切しません（本番データに影響なし）。
 * テストデータはすべて架空のものです。
 *******************************************************/

function runAllTests_() {

  const results = { passed: 0, failed: 0, failures: [] };

  const check = (name, actual, expected) => {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a === e) {
      results.passed++;
    } else {
      results.failed++;
      results.failures.push('✗ ' + name + '：期待 ' + e + ' ／ 実際 ' + a);
    }
  };

  const index = buildInstrumentIndex_(null);

  testInstrumentNormalization_(check, index);
  testInstrumentCatalog_(check, index);
  testRecruitStatus_(check);
  testSituation_(check);
  testColumnResolution_(check);
  testKeys_(check);
  testSanitize_(check);
  testStats_(check, index);
  testLargeScale_(check, index);
  testContactStats_(check);
  testSettingsParsing_(check);

  return results;
}


/*
 * 楽器名の正規化
 */
function testInstrumentNormalization_(check, index) {

  const n = v => normalizeInstrument(v, index);

  // テューバ／チューバ（今回の不具合）
  check('テューバ', n('テューバ'), 'Tuba');
  check('チューバ', n('チューバ'), 'Tuba');
  check('Tuba', n('Tuba'), 'Tuba');
  check('tuba', n('tuba'), 'Tuba');
  check('TUBA', n('TUBA'), 'Tuba');
  check('半角ｶﾅ ﾁｭｰﾊﾞ', n('ﾁｭｰﾊﾞ'), 'Tuba');
  check('前後の空白', n('  テューバ　'), 'Tuba');
  check('ハイフンの長音', n('チュ-バ'), 'Tuba');
  check('括弧書き', n('テューバ（Tuba）'), 'Tuba');
  check('大きいユ', n('テユーバ'), 'Tuba');

  // v1 の対応表はそのまま
  check('v1 フルート', n('フルート'), 'Fl');
  check('v1 バスーン', n('バスーン'), 'Fg');
  check('v1 第１ヴァイオリン', n('第１ヴァイオリン'), '1st Vn');
  check('v1 第2ヴァイオリン', n('第2ヴァイオリン'), '2nd Vn');
  check('v1 打楽器', n('打楽器'), 'Perc');
  check('v1 パーカッション', n('パーカッション'), 'Perc');
  check('v1 コントラバス', n('コントラバス'), 'Cb');

  // ヴ／ブ
  check('バイオリン', n('バイオリン'), 'Vn');
  check('ビオラ', n('ビオラ'), 'Va');
  check('Violin I', n('Violin I'), '1st Vn');
  check('ヴァイオリン(2nd)', n('ヴァイオリン(2nd)'), '2nd Vn');

  // 勝手に統合しない
  check('ピッコロは別コード', n('ピッコロ'), 'Picc');
  check('Piccolo', n('Piccolo'), 'Picc');
  check('バスクラリネットは別コード', n('バスクラリネット'), 'B.Cl');
  check('イングリッシュホルンは別コード', n('イングリッシュホルン'), 'E.H.');
  check('ヴァイオリン（1st/2nd未定）は Vn', n('ヴァイオリン'), 'Vn');
  check('ホルンとイングリッシュホルンを混同しない', n('ホルン'), 'Hr');

  // フォームの選択肢「フルート／ピッコロ」はフルートパートとして扱う
  check('フルート／ピッコロ', n('フルート／ピッコロ'), 'Fl');

  // チェックボックス（複数回答）
  check('複数回答', n('フルート, ピッコロ'), 'Fl, Picc');
  check('複数回答（読点）', n('ヴァイオリン、ヴィオラ'), 'Vn, Va');
  check('スラッシュ区切りの自由記述', n('ヴァイオリン/ヴィオラ'), 'Vn, Va');

  // 判定できないものは推測せずそのまま
  check('未知の楽器はそのまま', n('サックス'), 'サックス');
  check('一部だけ未知', n('クラリネット, サックス'), 'Cl, サックス');
  check('空欄', n(''), '');
  check('null', n(null), '');
  check('undefined', n(undefined), '');

  // 何度通しても同じ結果（冪等）
  ['Fl', '1st Vn', 'E.H.', 'Fl, Picc', 'Tuba'].forEach(code => check('冪等 ' + code, n(code), code));
}


/*
 * 楽器カタログ自体の整合性
 */
function testInstrumentCatalog_(check, index) {

  const ownCollisions = index.collisions.filter(c => c.existing !== c.code);

  check('カタログ内で表記ゆれが重複していない', ownCollisions.map(c => c.alias + ':' + c.existing + '/' + c.code), []);

  const v1Codes = ['Fl', 'Ob', 'Cl', 'Fg', 'Hr', 'Tp', 'Tb', 'Tuba', 'Perc', '1st Vn', '2nd Vn', 'Va', 'Vc', 'Cb'];
  const v1Targets = [[4, 2], [2, 1], [5, 3], [2, 1], [6, 4], [4, 2], [4, 3], [1, 1], [4, 3], [10, 7], [10, 7], [10, 5], [10, 5], [4, 2]];

  check('v1 の14楽器が同じ順番', INSTRUMENT_CATALOG.slice(0, 14).map(i => i[0]), v1Codes);
  check('v1 の目標・最低人数が同じ', INSTRUMENT_CATALOG.slice(0, 14).map(i => [i[3], i[4]]), v1Targets);
}


/*
 * 募集状況の判定
 */
function testRecruitStatus_(check) {

  const s = { urgentRatio: 0, surplusRatio: 1.5 };

  check('0人 → 急募', judgeRecruitStatus_(0, 4, 2, s), '急募');
  check('最低未満 → 募集中（最低未達）', judgeRecruitStatus_(1, 4, 2, s), '募集中（最低未達）');
  check('目標未満 → 募集中', judgeRecruitStatus_(3, 4, 2, s), '募集中');
  check('目標ちょうど → 充足', judgeRecruitStatus_(4, 4, 2, s), '充足');
  check('目標の1.5倍 → 充足／調整', judgeRecruitStatus_(6, 4, 2, s), '充足／調整');
  check('目標未設定', judgeRecruitStatus_(3, null, null, s), '目標未設定');
  check('最低人数だけ設定', judgeRecruitStatus_(2, null, 2, s), '充足');
  check('急募割合 0.5', judgeRecruitStatus_(3, 10, 7, { urgentRatio: 0.5, surplusRatio: 1.5 }), '急募');
  check('テューバ 2人（目標1） → 充足／調整', judgeRecruitStatus_(2, 1, 1, s), '充足／調整');
}


function testSituation_(check) {

  const s = { targetMembers: 80, decisionMembers: 60, minimumMembers: 46 };

  check('45人 → 団員募集継続', judgeSituation_(45, s), '団員募集継続');
  check('46人 → 最低人数到達', judgeSituation_(46, s), '最低人数到達');
  check('60人 → 演奏会開催判断ライン到達（v1 は誤って「最低人数到達」）', judgeSituation_(60, s), '演奏会開催判断ライン到達');
  check('80人 → 団員目標達成', judgeSituation_(80, s), '団員目標達成');
}


/*
 * 見出し名での列検出
 */
function testColumnResolution_(check) {

  const fields = formFieldDefs_();

  // 列の順番が変わった・新しい質問が追加された
  const headers = ['タイムスタンプ', '新しい質問', '楽器', 'メールアドレス', 'お名前・呼ばれたい名前', '楽器の経験年数'];
  const r = resolveColumns_(headers, fields, true);

  check('並び替え：楽器', r.map.instrument, 2);
  check('並び替え：メール', r.map.email, 3);
  check('並び替え：経験年数と楽器を混同しない', r.map.years, 5);
  check('新しい質問は使わない', Object.keys(r.map).some(k => r.map[k] === 1), false);

  // 質問名の後ろに補足が付いた
  const r2 = resolveColumns_(['タイムスタンプ', 'どのくらい練習に参加できそうですか？（目安）', '楽器の経験年数（だいたい）', '楽器'], fields, true);

  check('前方一致：練習参加', r2.map.practice, 1);
  check('前方一致：経験年数（「楽器」と取り違えない）', r2.map.years, 2);
  check('前方一致：楽器', r2.map.instrument, 3);

  // 全角数字・末尾の？の違い
  const r3 = resolveColumns_(['タイムスタンプ', '第１回演奏会への参加について', 'どのくらい練習に参加できそうですか'], fields, true);

  check('全角数字', r3.map.concert, 1);
  check('末尾の？なし', r3.map.practice, 2);

  // 応募者一覧の列が入れ替わった
  const appHeaders = ['No.', '回答日時', 'メールアドレス', '備考', '楽器', '対応状況'];
  const r4 = resolveColumns_(appHeaders, applicantFieldDefs_(), false);

  check('応募者一覧：備考', r4.map.note, 3);
  check('応募者一覧：対応状況', r4.map.status, 5);
}


/*
 * 重複判定キー
 */
function testKeys_(check) {

  const d = new Date(2026, 8, 1, 10, 0, 0);

  check('v1 と同じキー（Date）', normalizeKeyValue(d), String(d.getTime()));
  check('v1 と同じキー（文字）', normalizeKeyValue(' abc '), 'abc');
  check('v1 と同じキー（空）', normalizeKeyValue(null), '');
  check('ゆるいキー：日付と文字列が一致', looseKey_(d, 'A@Example.com'), looseKey_('2026/09/01 10:00:00', 'a@example.com'));
  check('ハッシュは64桁', hashKey_('x').length, 64);
  check('ハッシュにメールアドレスが含まれない', hashKey_('1|tester@example.com').indexOf('example'), -1);
}


function testSanitize_(check) {

  check('数式は文字列に', sanitizeForSheet_('=IMPORTXML("x","y")'), "'=IMPORTXML(\"x\",\"y\")");
  check('@で始まる', sanitizeForSheet_('@abc'), "'@abc");
  check('普通の文字列はそのまま', sanitizeForSheet_('よろしくお願いします'), 'よろしくお願いします');
  check('マイナスの数はそのまま', sanitizeForSheet_('-5'), '-5');
  check('数値はそのまま', sanitizeForSheet_(10), 10);
}


/*
 * 集計（架空データ）
 */
function testStats_(check, index) {

  const settings = defaultSettings_();
  const d = new Date(2026, 8, 1);
  const rec = (row, no, email, instrument, status) => ({
    row, no, noNum: no, timestamp: d, email, emailKey: emailKey_(email), name: 'テスト' + row,
    instrument, status, concert: 'ぜひ参加したい', lastContact: '', memo: ''
  });

  const records = [
    rec(2, 1, 'a@example.com', 'Tuba', '正式参加'),
    rec(3, 2, 'b@example.com', 'チューバ', '参加予定'),     // v1 時代の未正規化データ
    rec(4, 3, 'c@example.com', 'ヴァイオリン', '未対応'),
    rec(5, 4, 'd@example.com', '1st Vn', '辞退'),
    rec(6, 5, 'A@example.com', 'Fl', '未対応'),             // No.1 と同じメール（大文字違い）
    rec(7, 6, '', '', '未対応'),                           // 楽器空欄・メール空欄
    rec(8, 7, 'e@example.com', 'サックス', '未対応'),       // 未知の楽器
    rec(9, 8, 'f@example.com', 'Fl, Picc', '正式参加')     // 複数回答
  ];

  const st = computeStats_(records, settings, index, new Date(2026, 8, 10));
  const code = c => st.codeRows.find(r => r.code === c);
  const part = p => st.partRows.find(r => r.part === p);

  check('実人数（重複1件を除く）', st.total, 7);
  check('重複候補', st.duplicates.length, 1);
  check('重複は No. の小さい行を採用', st.duplicates[0].primary.no, 1);
  check('有効応募者（辞退除く）', st.active, 6);
  check('正式参加', st.official, 2);
  check('参加予定', st.planned, 1);
  check('Tuba はチューバ・テューバ両方を数える', code('Tuba').all, 2);
  check('Tuba 正式参加', code('Tuba').official, 1);
  check('Vn（未定）を数える', code('Vn').all, 1);
  check('辞退は応募者数に含み有効応募者に含まない', [code('1st Vn').all, code('1st Vn').active], [1, 0]);
  check('ヴァイオリンパート合計', part('Vn').active, 1);
  check('複数回答は第1希望で数える', code('Fl').all, 1);
  check('第2希望は兼任可に数える', code('Picc').secondary, 1);
  check('未知の楽器は未分類', code(CODE_UNKNOWN_).all, 1);
  check('楽器空欄は未回答', code(CODE_BLANK_).all, 1);
  check('楽器別の合計 = 実人数', st.codeRows.reduce((n, r) => n + r.all, 0), st.total);
  check('未知の楽器名を記録', Object.keys(st.unknownTokens), ['サックス']);
  check('未対応フォロー（3日以上）', st.followUps.length, 3);
  check('Ob は 0人で急募', st.urgentParts.indexOf('Ob（オーボエ）') >= 0, true);
  check('空データでも落ちない', computeStats_([], settings, index, new Date()).total, 0);
}


/*
 * 80人以上（120人）でも正しく・速く集計できる
 */
function testLargeScale_(check, index) {

  const names = ['フルート', 'オーボエ', 'クラリネット', 'ファゴット', 'ホルン', 'トランペット', 'トロンボーン', 'チューバ', 'パーカッション', '第1ヴァイオリン', '第2ヴァイオリン', 'ヴィオラ', 'チェロ', 'コントラバス'];
  const statuses = CONFIG.statuses;
  const records = [];

  for (let i = 0; i < 120; i++) {
    records.push({
      row: i + 2, no: i + 1, noNum: i + 1, timestamp: new Date(2026, 8, 1 + (i % 28)),
      email: 'member' + i + '@example.com', emailKey: 'member' + i + '@example.com', name: 'テスト' + i,
      instrument: names[i % names.length], status: statuses[i % statuses.length], concert: '', lastContact: '', memo: ''
    });
  }

  const started = Date.now();
  const st = computeStats_(records, defaultSettings_(), index, new Date(2026, 9, 1));
  const elapsed = Date.now() - started;

  check('120人：実人数', st.total, 120);
  check('120人：楽器別の合計が一致', st.codeRows.reduce((n, r) => n + r.all, 0), 120);
  check('120人：未分類なし', st.codeRows.find(r => r.code === CODE_UNKNOWN_).all, 0);
  check('120人：正式参加', st.official, records.filter(r => r.status === '正式参加').length);
  check('120人：1秒以内に集計', elapsed < 1000, true);
}


function testContactStats_(check) {

  const now = new Date(2026, 8, 10, 12, 0, 0);
  const c = (row, no, nextDate, state) => ({ row, no, noNum: no, nextDate, state });

  const r = computeContactStats_([
    c(2, 1, new Date(2026, 8, 9), ''),        // 期限切れ
    c(3, 2, new Date(2026, 8, 10), '要対応'),  // 今日
    c(4, 3, new Date(2026, 8, 15), ''),       // 7日以内
    c(5, 4, new Date(2026, 8, 30), ''),       // 先
    c(6, 5, new Date(2026, 8, 1), '完了'),     // 完了済み
    c(7, 6, '', '')                            // 日付なし
  ], now);

  check('期限切れ・本日', r.overdue, [1, 2]);
  check('7日以内', r.upcoming, [3]);
}


function testSettingsParsing_(check) {

  const item = key => SETTINGS_ITEMS_.find(i => i.key === key);

  check('数値：全角', parseSettingValue_(item('targetMembers'), '８０'), 80);
  check('数値：「人」付き', parseSettingValue_(item('targetMembers'), '80人'), 80);
  check('数値：不正', parseSettingValue_(item('targetMembers'), 'たくさん'), null);
  check('リスト', parseSettingValue_(item('excludedStatuses'), '辞退、保留'), ['辞退', '保留']);
  check('真偽：はい', parseSettingValue_(item('autoUpdateOnEdit'), 'はい'), true);
  check('真偽：チェックボックス', parseSettingValue_(item('autoUpdateOnEdit'), false), false);
}
