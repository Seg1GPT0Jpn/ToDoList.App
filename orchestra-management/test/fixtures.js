/*
 * テスト用の架空データ（実在の人物・メールアドレスではありません）。
 * メールアドレスはすべて example.com（RFC 2606 の予約ドメイン）を使用。
 */
'use strict';

const FORM_HEADERS = [
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

function ts(day, hour, minute) {
  return new Date(2026, 8, day, hour, minute || 0, 0);
}

// 1行分のフォーム回答を作る
function response(t, email, name, instrument, extra) {
  const e = extra || {};
  return [
    t, email, name,
    e.realName === undefined ? '呼び名でOK' : e.realName,
    e.age === undefined ? '20代' : e.age,
    e.area === undefined ? '横浜市' : e.area,
    instrument,
    e.part === undefined ? '' : e.part,
    e.years === undefined ? '5年' : e.years,
    e.orch === undefined ? 'あり' : e.orch,
    e.affiliation === undefined ? '' : e.affiliation,
    e.reason === undefined ? '地元で演奏したい' : e.reason,
    e.practice === undefined ? '月2回程度' : e.practice,
    e.concert === undefined ? 'ぜひ参加したい' : e.concert,
    e.wish === undefined ? '' : e.wish,
    e.other === undefined ? '' : e.other
  ];
}

// 現在（8人程度）を想定した既存回答
function initialResponses() {
  return [
    response(ts(1, 10), 'tester01@example.com', 'テスト一郎', 'フルート'),
    response(ts(1, 12), 'tester02@example.com', 'テスト二郎', 'ヴァイオリン', { part: '1st希望' }),
    response(ts(2, 9), 'tester03@example.com', 'テスト三子', 'テューバ'),
    response(ts(2, 21), 'tester04@example.com', 'テスト四郎', 'チューバ'),
    response(ts(3, 8), 'tester05@example.com', 'テスト五子', 'チェロ', { affiliation: '' }),
    response(ts(4, 19), 'tester06@example.com', 'テスト六郎', 'クラリネット', { concert: '検討中' }),
    response(ts(5, 7), 'tester07@example.com', 'テスト七子', 'ピッコロ'),
    response(ts(6, 22), 'tester08@example.com', 'テスト八郎', 'ホルン')
  ];
}

module.exports = { FORM_HEADERS, ts, response, initialResponses };
