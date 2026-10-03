import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/meta/curriculum_map_screen.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('学びの地図：教科を切りかえ、単元の中身と進みぐあいを見る', (t) async {
    final record = LearningRecord.empty.recordAll([
      for (var i = 0; i < 6; i++)
        AnswerEvent(
          questionId: 'q$i',
          setId: 'math_j3_07',
          isCorrect: i < 3,
          elapsedMs: 1000,
          unit: 'math.j3.s2.a07.main',
        ),
    ], day: 1);
    await openScreen(
      t,
      const CurriculumMapScreen(initialSubject: 'math'),
      prefs: {'rpg_learning_v1': jsonEncode(record.toMap())},
      // 9つの学年の道が1画面に入る大きさ
      size: const Size(420, 2400),
    );
    expect(find.text('小1'), findsOneWidget);
    expect(find.text('中3'), findsOneWidget);

    await t.tap(find.text('中3'));
    await t.pumpAndSettle();
    expect(find.text('円周角'), findsOneWidget);
    expect(find.text('正答50%'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('unit-math.j3.s2.a07')));
    await t.pumpAndSettle();
    expect(find.text('正答率 50%'), findsOneWidget);
    expect(find.text('この単元で練習バトル'), findsOneWidget);
    Navigator.of(t.element(find.text('正答率 50%'))).pop();
    await t.pumpAndSettle();

    // 理科に切りかえる：小3〜中3の7つの道が並ぶ
    await t.tap(find.byKey(const ValueKey('subject-science')));
    await t.pumpAndSettle();
    for (final c in ['小3', '小4', '小5', '小6', '中1', '中2', '中3']) {
      expect(find.text(c), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('学習ステータスから学びの地図をひらける', (t) async {
    await openScreen(t, const LearningStatusScreen());
    await t.tap(find.byKey(const ValueKey('open-curriculum-map')));
    await t.pumpAndSettle();
    expect(find.byType(CurriculumMapScreen), findsOneWidget);
    expect(find.text('英語'), findsWidgets);
  });
}
