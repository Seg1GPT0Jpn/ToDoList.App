import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';
import 'package:rpg_game_app/meta/study_boost_card.dart';

import 'harness.dart';

LearningRecord _record(int day) => LearningRecord.empty.recordAll([
  for (final (i, set) in ['math_input_01', 'math_figure_01'].indexed)
    for (var n = 1; n <= 3; n++)
      AnswerEvent(
        questionId: '${set}_00$n',
        setId: set,
        category: 'calculation',
        unit: i == 0 ? '式' : '図形',
        isCorrect: n != 1,
        elapsedMs: 4000,
      ),
], day: day);

void main() {
  testWidgets('ひさしぶりなら「おかえり」、1分だけ・まぜて練習・週のふりかえりが出る', (t) async {
    final s = await openScreen(
      t,
      const Scaffold(body: SingleChildScrollView(child: StudyBoostCard())),
    );
    expect(find.byKey(const ValueKey('study-boost')), findsNothing);
    await s.meta.save(record: _record(RpgServices.today() - 4));
    await s.studyLog.add(
      'math',
      spent: const Duration(minutes: 12),
      answered: 6,
      correct: 4,
    );
    await t.pump();
    expect(find.text('おかえり！ 4日ぶりだね'), findsOneWidget);
    expect(find.byKey(const ValueKey('one-minute')), findsOneWidget);
    expect(find.textContaining('12分・6問'), findsOneWidget);

    // 数学だけなので、そのまま数学のまぜて練習が始まる
    await t.tap(find.byKey(const ValueKey('mix-practice')));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BattleScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 6));
  });

  testWidgets('学習ステータスに、まちがいの種類が出る', (t) async {
    final s = await openScreen(
      t,
      const Scaffold(),
      size: const Size(420, 4000),
    );
    await s.mistakes.add(
      'math',
      MistakeKind.careless,
      day: RpgServices.today(),
    );
    await s.meta.save(record: _record(RpgServices.today()));
    unawaited(
      t
          .state<NavigatorState>(find.byType(Navigator))
          .push(
            MaterialPageRoute<void>(
              builder: (_) => const LearningStatusScreen(),
            ),
          ),
    );
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const ValueKey('mistake-card')), findsOneWidget);
    expect(find.textContaining('いちばん多いのは「うっかり」'), findsOneWidget);
  });
}
