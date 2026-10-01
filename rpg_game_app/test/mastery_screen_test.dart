import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('バトル：冒険Lvの下に、その科目の習熟Lvが出る', (t) async {
    final world = RpgCatalog.world('math');
    final stage = world.stages.first;
    final progress = Mastery.migrate(
      const RpgProgress(level: 30),
    ).copyWith(masteryExp: {'math.m1': Mastery.expForLevel(4)});
    await openScreen(
      t,
      BattleScreen(
        world: world,
        stage: stage,
        questions: [
          for (var i = 0; i < 6; i++)
            QuizQuestion(
              id: 'm$i',
              unit: 'math.m1.numexpr.poly.expand',
              category: QuestionCategory.calculation,
              prompt: '問$i',
              choices: ['$i', '${i + 1}', '${i + 2}', '${i + 3}'],
              answerIndex: 0,
            ),
        ],
        progress: progress,
      ),
      frames: 30,
    );
    expect(find.text('Lv30'), findsOneWidget);
    expect(find.text('数学Ⅰ 習熟Lv4'), findsOneWidget);
  });

  testWidgets('学習ステータス：科目の習熟Lvが並ぶ', (t) async {
    final progress = Mastery.migrate(RpgProgress.initial).copyWith(
      masteryExp: {
        'math.m1': Mastery.expForLevel(6),
        'science.chemistry': Mastery.expForLevel(2),
      },
    );
    await openScreen(
      t,
      const LearningStatusScreen(),
      prefs: {'rpg_progress_v1': jsonEncode(progress.toMap())},
    );
    expect(find.byKey(const ValueKey('mastery-card')), findsOneWidget);
    expect(find.text('数学Ⅰ Lv6'), findsOneWidget);
    expect(find.text('化学 Lv2'), findsOneWidget);
  });
}
