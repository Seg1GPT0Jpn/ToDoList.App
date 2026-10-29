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

  test('みんな同じ問題になる。範囲の外の単語は出さない', () {
    final book = VocabBook(
      id: 'eevi',
      title: 'EEVI',
      kind: VocabBookKind.custom,
      cards: [
        for (var i = 1; i <= 500; i++)
          VocabCard(id: '$i', number: i, term: 'w$i', meaning: 'm$i'),
      ],
    );
    final r = config.on(DateTime.utc(2026, 10, 30)).single;
    final a = r.questions(book), b = r.questions(book);
    expect(a.length, 20);
    expect(a.map((q) => q.card.number), b.map((q) => q.card.number));
    expect(a.map((q) => q.choices.join()), b.map((q) => q.choices.join()));
    expect(
        a.every((q) => q.card.number! >= 301 && q.card.number! <= 350), isTrue);
  });

  test('順位は点数、同点なら正解数。始めただけの人は入らない', () {
    final rows = ContestEntry.rank(const [
      ContestEntry(uid: 'a', name: 'A', correct: 9, score: 1200, done: true),
      ContestEntry(uid: 'b', name: 'B', correct: 10, score: 1200, done: true),
      ContestEntry(uid: 'c', name: 'C', correct: 0, score: 0, done: false),
      ContestEntry(uid: 'd', name: 'D', correct: 12, score: 1500, done: true),
    ]);
    expect(rows.map((e) => e.uid), ['d', 'b', 'a']);
  });

  test('管理者はひとりだけ', () {
    expect(ContestRules.isAdmin('kzmsegawa@gmail.com'), isTrue);
    expect(ContestRules.isAdmin(' KZMSegawa@gmail.com '), isTrue);
    expect(ContestRules.isAdmin('someone@gmail.com'), isFalse);
    expect(ContestRules.isAdmin(null), isFalse);
  });
}
