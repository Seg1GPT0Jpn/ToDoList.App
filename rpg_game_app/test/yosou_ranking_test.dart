import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/yosou_ranking.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final _exam = YosouExams.all.first;
final _first = DateTime.utc(2026, 10, 30, 9);

/// 結果の画面のかわり：点数を変えられる
class _Host extends StatefulWidget {
  const _Host({required this.backend, required this.started});
  final YosouRankBackend backend;
  final DateTime started;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int score = 70;
  int unscored = 2;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      children: [
        YosouRankCard(
          exam: _exam,
          attempt: MockAttempt(examId: _exam.id, startedAt: widget.started),
          score: score,
          total: 100,
          unscored: unscored,
          spent: const Duration(minutes: 55),
          firstStart: _first,
          backend: widget.backend,
        ),
        TextButton(
          key: const ValueKey('selfscore'),
          onPressed: () => setState(() {
            score = 76;
            unscored = 0;
          }),
          child: const Text('自分で採点'),
        ),
      ],
    ),
  );
}

void main() {
  final board = YosouRankBackend.boardId(_exam.id);

  testWidgets('1回目の結果をランキングに登録し、自分で採点した点も入る', (t) async {
    final boards = {
      board: {
        'a': const YosouRankEntry(
          uid: 'a',
          name: 'えー',
          score: 90,
          total: 100,
          spent: 3000,
          start: 1,
        ),
      },
    };
    final me = MemoryYosouRankBackend(userId: 'me', boards: boards);
    await openScreen(
      t,
      _Host(backend: me, started: _first),
      frames: 5,
      size: const Size(420, 1000),
    );
    await t.enterText(find.byKey(const ValueKey('yosou-rank-name')), 'あり');
    expect(find.text('70点でランキングに登録'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-rank-enter')));
    await _frames(t);
    expect(boards[board]!['me']!.name, 'あり');
    expect(find.textContaining('あなたは 2位 / 2人（70/100 点）'), findsOneWidget);
    // 自分で採点すると、ランキングの点も変わる
    await t.tap(find.byKey(const ValueKey('selfscore')));
    await _frames(t);
    expect(boards[board]!['me']!.score, 76);
    expect(boards[board]!['me']!.unscored, 0);
    expect(find.textContaining('（76/100 点）'), findsOneWidget);
    // ランキングの画面
    await t.tap(find.byKey(const ValueKey('yosou-rank-open')));
    await _frames(t);
    expect(find.textContaining('1位　えー　90/100 点'), findsOneWidget);
    expect(find.textContaining('2位　あり（あなた）　76/100 点'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('解き直した回は登録できない', (t) async {
    await openScreen(
      t,
      _Host(
        backend: MemoryYosouRankBackend(),
        started: _first.add(const Duration(days: 1)),
      ),
      frames: 5,
    );
    expect(find.byKey(const ValueKey('yosou-rank-retry')), findsOneWidget);
    expect(find.byKey(const ValueKey('yosou-rank-enter')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('ログインしていないときは、その説明を出す', (t) async {
    await openScreen(
      t,
      _Host(backend: MemoryYosouRankBackend(userId: null), started: _first),
      frames: 5,
    );
    expect(find.text(YosouRankText.needLogin), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
