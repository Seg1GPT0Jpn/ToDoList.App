import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';

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

void main() {
  testWidgets('必殺技：ゲージがたまったら構えて、正解すると必殺技が決まる', (t) async {
    final boss = RpgCatalog.world(RpgCatalog.englishWorldId).stages.last;
    await openScreen(
      t,
      BattleScreen(
        world: RpgCatalog.world(RpgCatalog.englishWorldId),
        stage: boss,
        questions: _qs,
        progress: RpgProgress.initial,
      ),
      size: const Size(420, 900),
      frames: 40,
    );
    expect(find.textContaining('必殺 0%'), findsOneWidget);
    for (var i = 0; i < 8 && find.text('必殺技！').evaluate().isEmpty; i++) {
      await t.tap(find.text('せいかい').first, warnIfMissed: false);
      await _frames(t, 14);
    }
    expect(find.text('必殺技！'), findsOneWidget);
    await t.tap(find.text('必殺技！'));
    await _frames(t, 2);
    expect(find.text('構え中'), findsOneWidget);
    await t.tap(find.text('せいかい').first, warnIfMissed: false);
    await _frames(t, 3);
    expect(find.text('必殺技！'), findsOneWidget, reason: '必殺技の文字が出る');
    await _frames(t, 20);
    expect(find.textContaining('必殺 0%'), findsOneWidget);
    expect(t.takeException(), isNull);
    await _frames(t, 100);
  });
}
