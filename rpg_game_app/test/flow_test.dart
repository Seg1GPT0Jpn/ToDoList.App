import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/battle/result_screen.dart';
import 'package:rpg_game_app/meta/equipment_screen.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';
import 'package:rpg_game_app/meta/story_screen.dart';
import 'package:rpg_game_app/study/common_test_screens.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

final _qs = [
  for (var i = 0; i < 10; i++)
    QuizQuestion(
      id: 'english_q$i',
      category: i.isEven ? QuestionCategory.usage : QuestionCategory.meaning,
      prompt: '問題$i',
      choices: const ['せいかい', 'はずれA', 'はずれB', 'はずれC'],
      answerIndex: 0,
      explanation: '解説です。二文目。',
    ),
];

/// バトルで [correct] の選択肢を押しつづけ、結果画面まで進める
Future<void> _play(WidgetTester t, StageDef stage, {required bool win}) async {
  await openScreen(
    t,
    BattleScreen(
      world: RpgCatalog.world(stage.worldId),
      stage: stage,
      questions: _qs,
      progress: RpgProgress.initial,
    ),
    frames: 30,
  );
  for (var turn = 0; turn < 80; turn++) {
    if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
    final choice = find.text(win ? 'せいかい' : 'はずれA');
    if (choice.evaluate().isNotEmpty) {
      await t.tap(choice.first, warnIfMissed: false);
    }
    // 不正解のあとは「つぎへ」
    final next = find.text('つぎへ');
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    if (next.evaluate().isNotEmpty) {
      await t.tap(next.first, warnIfMissed: false);
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    expect(t.takeException(), isNull);
  }
  for (var i = 0; i < 40; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(ResultScreen), findsOneWidget);
  expect(t.takeException(), isNull);
}

void main() {
  final english = RpgCatalog.world(RpgCatalog.englishWorldId).stages;

  testWidgets('バトルに勝って結果画面まで進む', (t) async {
    await _play(t, english.first, win: true);
  });

  testWidgets('バトルに負けて結果画面まで進む', (t) async {
    await _play(t, english.first, win: false);
  });

  testWidgets('ボス（試練）にも勝てる', (t) async {
    await _play(t, english[15], win: true);
  });

  testWidgets('共通テスト遺跡：ボスが重なる連戦に勝てる（乱入・交代の演出つき）', (t) async {
    final stage = CommonTest.stage(
      RuinsFloor.standard,
      CommonTest.stagesFor(RuinsFloor.standard, [
        RpgCatalog.world(RpgCatalog.englishWorldId),
      ], seed: 1),
      level: 1,
    );
    expect(stage.reinforcements.length, 2);
    await _play(t, stage, win: true);
  });

  testWidgets('強敵にも勝てる', (t) async {
    await _play(t, Elites.of(english[2]), win: true);
  });

  const narrow = Size(360, 780);
  for (final e in <String, Widget>{
    'ホーム': const WorldMapScreen(),
    '物語': const StoryScreen(),
    '装備': const EquipmentScreen(),
    '学習ステータス': const LearningStatusScreen(),
    '模試': const MockExamScreen(),
    '遺跡': const CommonTestRuinsScreen(),
  }.entries) {
    testWidgets('せまい画面でもはみ出さない：${e.key}', (t) async {
      await openScreen(t, e.value, size: narrow);
    });
  }
}
