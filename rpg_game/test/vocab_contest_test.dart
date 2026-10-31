import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final config = ContestConfig.initial;

  String days(List<ContestRound> rs) =>
      rs.map((r) => '${ContestRules.dayKey(r.date)} ${r.range}').join(', ');

  test('EEVI は 10/30（金）の 301〜350 から毎週金曜。11/13 はとばして範囲も進めない', () {
    final eevi = config.plans['eevi']!;
    expect(
      days(eevi.rounds(DateTime.utc(2026, 10, 29), 4)),
      '2026-10-30 301〜350, 2026-11-06 351〜400, '
      '2026-11-20 401〜450, 2026-11-27 451〜500',
    );
    expect(eevi.weekday, DateTime.friday);
  });

  test('LEAP は 11/1（日）の 1801〜1900 から毎週日曜。11/22 はとばす', () {
    final leap = config.plans['leap']!;
    expect(
      days(leap.rounds(DateTime.utc(2026, 10, 29), 5)),
      '2026-11-01 1801〜1900, 2026-11-08 1901〜2000, 2026-11-15 2001〜2100, '
      '2026-11-29 2101〜2200, 2026-12-06 2201〜2300',
    );
    expect(leap.weekday, DateTime.sunday);
  });

  test('その日の回・前の回・これからの回', () {
    expect(config.on(DateTime.utc(2026, 10, 30)).single.id, 'eevi-2026-10-30');
    expect(config.on(DateTime.utc(2026, 11, 13)), isEmpty);
    expect(config.on(DateTime.utc(2026, 11, 22)), isEmpty);
    expect(config.on(DateTime.utc(2026, 11, 2)), isEmpty);
    expect(config.plans['leap']!.before(DateTime.utc(2026, 11, 10))!.id,
        'leap-2026-11-08');
    expect(config.plans['leap']!.before(DateTime.utc(2026, 11, 1)), isNull);
    expect(
      config.upcoming(DateTime.utc(2026, 10, 29), 3).map((r) => r.id),
      ['eevi-2026-10-30', 'leap-2026-11-01', 'eevi-2026-11-06'],
    );
  });

  test('EEVI の受付は木曜 18:00〜金曜 19:15、LEAP は土曜 18:00〜月曜 8:00（日本時間）', () {
    // 日本時間は UTC+9
    DateTime jst(int m, int d, int h, [int mi = 0]) =>
        DateTime.utc(2026, m, d, h, mi).subtract(const Duration(hours: 9));
    final eevi = config.plans['eevi']!, leap = config.plans['leap']!;
    final first = eevi.on(DateTime.utc(2026, 10, 30))!;
    expect(first.window, '10/29（木）18:00〜10/30（金）19:15');
    expect(eevi.openAt(jst(10, 29, 17, 59)), isNull);
    expect(eevi.nextAt(jst(10, 29, 17, 59))!.id, 'eevi-2026-10-30');
    expect(eevi.openAt(jst(10, 29, 18))!.id, 'eevi-2026-10-30');
    expect(eevi.openAt(jst(10, 30, 19, 14))!.id, 'eevi-2026-10-30');
    expect(eevi.openAt(jst(10, 30, 19, 15)), isNull);
    expect(eevi.lastClosed(jst(10, 30, 19, 15))!.id, 'eevi-2026-10-30');
    expect(eevi.lastClosed(jst(10, 30, 19, 14)), isNull);
    expect(
      leap.on(DateTime.utc(2026, 11, 1))!.window,
      '10/31（土）18:00〜11/2（月）8:00',
    );
    expect(leap.openAt(jst(11, 2, 7, 59))!.id, 'leap-2026-11-01');
    expect(leap.openAt(jst(11, 2, 8)), isNull);
    expect(
        config.openAt(jst(10, 31, 20)).map((r) => r.id), ['leap-2026-11-01']);
    // お休みの週（11/13）は、木曜の夜になっても受付しない
    expect(eevi.openAt(jst(11, 12, 20)), isNull);
    expect(eevi.nextAt(jst(11, 12, 20))!.id, 'eevi-2026-11-20');
  });

  test('受付時間の書き方', () {
    expect(ContestRules.offset(-360), '前日 18:00');
    expect(ContestRules.offset(19 * 60 + 15), '当日 19:15');
    expect(ContestRules.offset(32 * 60), '翌日 8:00');
    expect(ContestRules.parseOffset('前日 18:00'), -360);
    expect(ContestRules.parseOffset('翌日 8:00'), 32 * 60);
    expect(ContestRules.parseOffset('-1 18:00'), -360);
    expect(ContestRules.parseOffset('当日 25:00'), isNull);
    expect(ContestRules.parseOffset('あした'), isNull);
  });

  test('範囲の書きかえ・追加の日・お休みの日を足す', () {
    final eevi = config.plans['eevi']!.copyWith(
      ranges: {'2026-11-06': const ContestRange(1, 100)},
      extras: {'2026-11-14': const ContestRange(401, 420)},
      skips: {'2026-11-13', '2026-11-27'},
    );
    expect(
      days(eevi.rounds(DateTime.utc(2026, 11, 1), 4)),
      '2026-11-06 1〜100, 2026-11-14 401〜420, 2026-11-20 401〜450, '
      '2026-12-04 451〜500',
    );
  });

  test('保存して読みもどしても同じ。読めないときははじめの設定', () {
    final m = config.toMap();
    final back = ContestConfig.fromMap(m);
    expect(back.toMap(), m);
    expect(ContestConfig.fromMap(null).toMap(), m);
    expect(
        ContestConfig.fromMap({
          'leap': {'first': 'x'}
        }).toMap(),
        m);
  });

  test('日本時間で日付を数える', () {
    // 日本時間 10/30 0:30 は、UTC では 10/29 15:30
    expect(
      ContestRules.dayKey(
          ContestRules.jstToday(DateTime.utc(2026, 10, 29, 15, 30))),
      '2026-10-30',
    );
    expect(
      ContestRules.dayKey(
          ContestRules.jstToday(DateTime.utc(2026, 10, 29, 14, 59))),
      '2026-10-29',
    );
  });

  // 英字だけの単語（例文の中から見つけられるように）
  String w(int i) =>
      'z${String.fromCharCode(97 + i ~/ 26 % 26)}${String.fromCharCode(97 + i % 26)}q';

  VocabBook book({bool examples = true}) => VocabBook(
        id: 'eevi',
        title: 'EEVI',
        kind: VocabBookKind.custom,
        cards: [
          for (var i = 1; i <= 500; i++)
            VocabCard(
              id: '$i',
              number: i,
              term: w(i),
              meaning: '意味$i',
              example: examples ? 'I like ${w(i)} very much.' : '',
              exampleJa: examples ? 'わたしは意味$iがとても好き。' : '',
            ),
        ],
      );

  test('EEVI は範囲の50語を4種類で1回ずつ。みんな同じ問題で、範囲の外の単語は出さない', () {
    final r = config.on(DateTime.utc(2026, 10, 30))!.single;
    final a = r.parts(book()), b = r.parts(book());
    expect(a.map((p) => p.length), [50, 50, 50, 50]);
    expect(a.map((p) => p.first.part), ContestPart.values);
    for (var i = 0; i < 4; i++) {
      expect(a[i].map((q) => '${q.prompt}${q.sub}${q.choices.join()}'),
          b[i].map((q) => '${q.prompt}${q.sub}${q.choices.join()}'));
    }
    final all = [for (final p in a) ...p];
    expect(
      all.every((q) => q.card.number! >= 301 && q.card.number! <= 350),
      isTrue,
    );
    // どの単語も、各種類で1回ずつ出る
    final counts = <int, int>{};
    for (final q in a[2]) {
      counts[q.card.number!] = (counts[q.card.number!] ?? 0) + 1;
    }
    expect(counts.values.toSet(), {1});
    expect(counts, hasLength(50));
    // 正解の選択肢
    final flash = a[0];
    for (final q in flash) {
      expect(q.choices, hasLength(2));
      expect(q.answer == 0, q.sub == q.card.shortMeaning);
    }
    expect(flash.where((q) => q.answer == 0).length, inInclusiveRange(12, 38));
    for (final q in a[1]) {
      expect(q.choices[q.answer], q.card.term);
      expect(q.prompt, q.card.shortMeaning);
    }
    for (final q in a[2]) {
      expect(q.choices[q.answer], q.card.shortMeaning);
      expect(q.choices.toSet(), hasLength(4));
    }
    for (final q in a[3]) {
      expect(q.prompt, contains('＿＿＿＿'));
      expect(q.choices[q.answer], q.card.term);
      expect(q.sub, isNotEmpty);
    }
  });

  test('例文がない単語帳では、例文の問題を出さない', () {
    final r = config.on(DateTime.utc(2026, 10, 30))!.single;
    expect(
        r.parts(book(examples: false)).map((p) => p.length), [50, 50, 50, 0]);
  });

  test('点数：正解は100点＋速さで最大50点。得点は満点に対する割合', () {
    const limit = Duration(seconds: 8);
    expect(ContestScoring.points(false, Duration.zero, limit), 0);
    expect(ContestScoring.points(true, Duration.zero, limit), 150);
    expect(ContestScoring.points(true, const Duration(seconds: 4), limit), 125);
    expect(ContestScoring.points(true, const Duration(seconds: 9), limit), 100);
    expect(ContestScoring.score(400 * 150, 400), 10000);
    expect(ContestScoring.score(30000, 400), 5000);
    expect(ContestScoring.percent(8735), '87.35%');
    expect(ContestScoring.percent(10000), '100.00%');
    expect(ContestScoring.percent(5), '0.05%');
  });

  test('順位は得点、同点なら正解数。1種類も解き終わっていない人は入らない', () {
    const all = {0: 1, 1: 1, 2: 1, 3: 1};
    final rows = ContestEntry.rank(const [
      ContestEntry(uid: 'a', name: 'A', correct: 9, score: 1200, scores: all),
      ContestEntry(uid: 'b', name: 'B', correct: 10, score: 1200, scores: all),
      ContestEntry(uid: 'c', name: 'C', correct: 0, score: 0),
      ContestEntry(
        uid: 'd',
        name: 'D',
        correct: 12,
        score: 1500,
        scores: {0: 1, 3: 1},
      ),
    ]);
    expect(rows.map((e) => e.uid), ['d', 'b', 'a']);
  });

  test('分野ごとに、好きな順で1回ずつ。始めて30分たつと記録なし', () {
    final t0 = DateTime.utc(2026, 10, 29, 10);
    var e = const ContestEntry(uid: 'x', name: 'X', correct: 0, score: 0);
    expect(e.started(2), isFalse);
    e = e.withStart(2, t0);
    expect(e.started(2), isTrue);
    expect(e.abandoned(2, t0.add(const Duration(minutes: 29))), isFalse);
    expect(e.abandoned(2, t0.add(const Duration(minutes: 30))), isTrue);
    e = e.next(
      part: 2,
      partScore: 9000,
      partCorrect: 48,
      partPoints: 6750,
      totalQuestions: 200,
    );
    expect(e.section, 1);
    expect(e.partScore(2), 9000);
    expect(e.partScore(0), isNull);
    expect(e.score, ContestScoring.score(6750, 200));
    expect(e.done, isFalse);
    final back = ContestEntry.fromMap('x', e.toMap())!;
    expect(back.partScore(2), 9000);
    expect(back.starts[2], t0);
  });

  test('入賞：2〜4人なら1位、5〜9人なら上位2人、10人以上なら上位3人', () {
    expect([1, 2, 4, 5, 9, 10, 50].map(ContestPrizes.winners),
        [0, 1, 1, 2, 2, 3, 3]);
    expect(ContestPrizes.place(0, 1), isNull);
    expect(ContestPrizes.place(0, 3), 1);
    expect(ContestPrizes.place(1, 3), isNull);
    expect(ContestPrizes.place(1, 5), 2);
    expect(ContestPrizes.place(2, 9), isNull);
    expect(ContestPrizes.place(2, 10), 3);
    // 同じ得点の人が上にいなければ、同じ順位になる
    expect(ContestPrizes.place(0, 12), 1);
    expect(ContestPrizes.exp(1), greaterThan(ContestPrizes.exp(2)));
  });

  test('報酬は1回だけ。入賞の回数で実績が解除される', () {
    var p = RpgProgress.initial;
    expect(ContestPrizes.claimed(p, 'eevi-2026-10-30'), isNull);
    p = ContestPrizes.claim(p, 'eevi-2026-10-30', 1);
    p = ContestPrizes.claim(p, 'leap-2026-11-01', 3);
    expect(ContestPrizes.claimed(p, 'eevi-2026-10-30'), 1);
    expect(ContestPrizes.claimed(p, 'leap-2026-11-01'), 3);
    expect(ContestPrizes.count(p), 2);
    expect(ContestPrizes.count(p, bookId: 'eevi', place: 1), 1);
    expect(ContestPrizes.count(p, bookId: 'leap', place: 1), 0);
    final ids = Achievements.newlyAchieved(AchievementContext(
      progress: p,
      record: LearningRecord.empty,
      journal: PlayerJournal.empty,
      today: 0,
    )).map((a) => a.id);
    expect(ids, containsAll(['contest_podium_1', 'contest_eevi_1']));
    expect(ids, isNot(contains('contest_leap_1')));
    expect(ids, isNot(contains('contest_podium_10')));
  });

  test('管理者はひとりだけ', () {
    expect(ContestRules.isAdmin('kzmsegawa@gmail.com'), isTrue);
    expect(ContestRules.isAdmin(' KZMSegawa@gmail.com '), isTrue);
    expect(ContestRules.isAdmin('someone@gmail.com'), isFalse);
    expect(ContestRules.isAdmin(null), isFalse);
  });
}
