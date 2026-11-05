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
          setId: 'math_m1_10',
          isCorrect: i < 3,
          elapsedMs: 1000,
          unit: 'math.m1.quad.maxmin.param',
        ),
    ], day: 1);
    await openScreen(
      t,
      const CurriculumMapScreen(initialSubject: 'math'),
      prefs: {'rpg_learning_v1': jsonEncode(record.toMap())},
    );
    expect(find.text('数学Ⅰ'), findsOneWidget);
    expect(find.text('数学Ⅲ'), findsOneWidget);

    await t.tap(find.text('数学Ⅰ'));
    await t.pumpAndSettle();
    expect(find.text('2次関数の最大・最小'), findsOneWidget);
    expect(find.text('正答50%'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('unit-math.m1.quad.maxmin')));
    await t.pumpAndSettle();
    expect(find.text('文字を含む場合分け'), findsOneWidget);
    expect(find.text('正答率 50%'), findsOneWidget);
    expect(find.textContaining('数学Ⅰ 内容(3) 2次関数'), findsOneWidget);
    expect(find.text('この単元で練習バトル'), findsOneWidget);
    Navigator.of(t.element(find.text('文字を含む場合分け'))).pop();
    await t.pumpAndSettle();

    // 理科に切りかえる：4科目が並ぶ
    await t.tap(find.byKey(const ValueKey('subject-science')));
    await t.pumpAndSettle();
    for (final c in ['物理', '化学', '生物', '地学']) {
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
