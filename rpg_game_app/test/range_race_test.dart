import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/study/range_race.dart';

import 'harness.dart';

void main() {
  test('全体は科目ごとの割合の平均（問題の多い科目だけが効かない）', () {
    const p = RangeProgress({
      'a': (done: 50, total: 100),
      'b': (done: 1000, total: 1000),
      'c': (done: 0, total: 10),
    });
    expect(p.overall, 500);
    expect(p.done, 1050);
    expect(p.finished, 1);
    expect(RangeRaceEntry.percent(p.overall), '50.0%');
  });

  test('ランキングは進んでいる順（同じなら正解ずみの問題が多い順）', () {
    final r = RangeRaceEntry.rank(const [
      RangeRaceEntry(uid: 'a', name: 'A', pct: 300, done: 10, finished: 0),
      RangeRaceEntry(uid: 'b', name: 'B', pct: 700, done: 5, finished: 1),
      RangeRaceEntry(uid: 'c', name: 'C', pct: 300, done: 90, finished: 0),
    ]);
    expect(r.map((e) => e.uid), ['b', 'c', 'a']);
    final m = RangeRaceEntry.fromMap('x', r.first.toMap())!;
    expect([m.name, m.pct, m.done, m.finished], ['B', 700, 5, 1]);
  });

  testWidgets('開くと自分の進みぐあいが送られ、みんなと順位で比べられる', (t) async {
    final b = MemoryRangeRaceBackend(userId: 'me');
    final board = RangeRaceBackend.boardId('後期中間試験');
    b.boards[board] = {
      'a': const RangeRaceEntry(
        uid: 'a',
        name: 'えー',
        pct: 420,
        done: 900,
        finished: 1,
        subjects: {'public_economy': 1000},
      ),
    };
    await openScreen(
      t,
      RangeRaceScreen(sheet: '後期中間試験', backend: b),
      size: const Size(420, 1400),
    );
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // 自分の分が送られている（まだ何も解いていないので 0%）
    final mine = b.boards[board]!['me']!;
    expect(mine.pct, 0);
    expect(mine.subjects.keys, contains('public_economy'));
    expect(find.byKey(const ValueKey('race-mine')), findsOneWidget);
    expect(find.textContaining('（2位 / 2人）'), findsOneWidget);
    expect(find.textContaining('えー'), findsOneWidget);
    expect(find.textContaining('42.0%'), findsOneWidget);
    expect(find.textContaining('（あなた）'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('ログインしていなければ、自分の進みぐあいだけ見えて参加のしかたを出す', (t) async {
    await openScreen(
      t,
      RangeRaceScreen(
        sheet: '後期中間試験',
        backend: MemoryRangeRaceBackend(userId: null),
      ),
      size: const Size(420, 1400),
    );
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('race-mine')), findsOneWidget);
    expect(find.text(RangeRaceText.needLogin), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
