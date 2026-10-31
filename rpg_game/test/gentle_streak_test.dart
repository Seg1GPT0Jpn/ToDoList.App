import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  const today = 20000;
  Set<int> days(Iterable<int> back) => {for (final b in back) today - b};

  test('勉強した日が続くと伸びる。今日まだでも昨日まで続いていれば数える', () {
    const s = GentleStreak();
    expect(s.length(days([0, 1, 2]), today), 3);
    expect(s.length(days([1, 2]), today), 2);
    expect(s.length(days([2, 3]), today), 0);
    expect(s.length({}, today), 0);
  });

  test('お休み券の日はつなぐだけで、数えない', () {
    final s = GentleStreak(restDays: {today - 1});
    expect(s.length(days([0, 2, 3]), today), 3);
  });

  test('休んだ日が券の枚数以内なら、券を使ってつなぐ', () {
    const s = GentleStreak(tickets: 2);
    final study = days([3, 4, 5]);
    final (next, news) = s.settle(study, today);
    expect(news.used, 2);
    expect(next.tickets, 0);
    expect(next.restDays, {today - 2, today - 1});
    expect(next.length(study, today), 3);
    // もう一度呼んでも二重には使わない
    final (again, news2) = next.settle(study, today);
    expect(news2.isEmpty, isTrue);
    expect(again.tickets, 0);
  });

  test('昨日だけ休んだら昨日の分を使う。昨日勉強していれば使わない', () {
    const s = GentleStreak(tickets: 1);
    final (next, news) = s.settle(days([2, 3]), today);
    expect(news.used, 1);
    expect(next.restDays, {today - 1});
    // 昨日勉強していれば使わない
    final (n2, news2) = s.settle(days([1, 2]), today);
    expect(news2.used, 0);
    expect(n2.tickets, 1);
  });

  test('休みが券より長いときは使わない（切れても責めない）', () {
    const s = GentleStreak(tickets: 1);
    final (next, news) = s.settle(days([3, 4]), today);
    expect(news.used, 0);
    expect(next.tickets, 1);
    expect(next.length(days([3, 4]), today), 0);
  });

  test('7日続くごとに1枚。同じ節目では2回もらわない。2枚まで', () {
    const s = GentleStreak();
    final week = days([for (var i = 0; i < 7; i++) i]);
    final (a, n1) = s.settle(week, today);
    expect(n1.earned, 1);
    expect(a.tickets, 1);
    final (b, n2) = a.settle(week, today);
    expect(n2.earned, 0);
    expect(b.tickets, 1);
    // 翌日、8日目でももらわない
    final (c, n3) = b.settle({...week, today + 1}, today + 1);
    expect(n3.earned, 0);
    expect(c.tickets, 1);
    final month = days([for (var i = 0; i < 28; i++) i]);
    final (d, _) = const GentleStreak().settle(month, today);
    expect(d.tickets, GentleStreak.maxTickets);
  });

  test('保存して戻せる。壊れたデータは空に', () {
    final s = GentleStreak(
      tickets: 2,
      restDays: {today - 1},
      awardedAt: {today - 7},
    );
    final back = GentleStreak.fromMap(s.toMap());
    expect(back.tickets, 2);
    expect(back.restDays, {today - 1});
    expect(back.awardedAt, {today - 7});
    expect(GentleStreak.fromMap('x').tickets, 0);
    expect(GentleStreak.fromMap({'t': 99}).tickets, GentleStreak.maxTickets);
  });
}
