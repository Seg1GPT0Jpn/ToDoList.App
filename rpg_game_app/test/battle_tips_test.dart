import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/battle/battle_tips.dart';

import 'harness.dart';

final _qs = [
  for (var i = 0; i < 10; i++)
    QuizQuestion(
      id: 'english_q$i',
      category: QuestionCategory.usage,
      prompt: '問題$i',
      choices: const ['せいかい', 'はずれA', 'はずれB', 'はずれC'],
      answerIndex: 0,
      explanation: '解説',
    ),
];

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final _english = RpgCatalog.world(RpgCatalog.englishWorldId);

Future<void> _battle(WidgetTester t, RpgProgress p, List<String> seen) =>
    openScreen(
      t,
      BattleScreen(
        world: _english,
        stage: _english.stages.first,
        questions: _qs,
        progress: p,
      ),
      prefs: {BattleTipStore.key: seen},
      size: const Size(420, 900),
      frames: 40,
    );

void main() {
  testWidgets('はじめてのバトル：基本の心得を読むまで1問目は始まらず、カードは出ない', (t) async {
    await _battle(t, RpgProgress.initial, const []);
    expect(find.byKey(const ValueKey('battle-tip-answer')), findsOneWidget);
    // 読んでいるあいだ、時間はへらない（1問目の時計が動かない）
    final limit = '${_english.stages.first.timeLimitSeconds}';
    await _frames(t, 30);
    expect(find.text(limit), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('battle-tip-ok')));
    await _frames(t, 10);
    expect(find.byKey(const ValueKey('battle-tip-answer')), findsNothing);
    expect(find.text('せいかい'), findsOneWidget);
    expect(find.byKey(const ValueKey('confidence-button')), findsNothing);
    expect(find.textContaining('必殺'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('1つクリアしたあと：カードの心得。カード・ベットが出る', (t) async {
    await _battle(
      t,
      RpgProgress.initial.copyWith(clearedStageIds: {_english.stages.first.id}),
      const ['answer'],
    );
    expect(find.byKey(const ValueKey('battle-tip-cards')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('battle-tip-ok')));
    await _frames(t, 10);
    expect(find.byKey(const ValueKey('confidence-button')), findsOneWidget);
    expect(find.textContaining('必殺'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
