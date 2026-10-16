import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri_quest_3d/battle/battle3d_screen.dart';
import 'package:tsuzuri_quest_3d/game/questions.dart';
import 'package:tsuzuri_quest_3d/game/save3d.dart';
import 'package:tsuzuri_quest_3d/title_screen.dart';

List<QuizQuestion> _questions() => [
  for (var i = 0; i < 6; i++)
    QuizQuestion(
      id: 'q$i',
      category: QuestionCategory.values.first,
      prompt: '問題$i',
      choices: ['正解$i', 'ちがう$i-a', 'ちがう$i-b', 'ちがう$i-c'],
      answerIndex: 0,
    ),
];

Future<(Save3D, Battle3DResult?)> _play(
  WidgetTester t, {
  required bool answerAll,
}) async {
  SharedPreferences.setMockInitialValues({'rpg_progress_v1': '2D版のデータ'});
  final save = await Save3D.open();
  final world = RpgCatalog.world('english');
  final stage = world.stages.first;
  Battle3DResult? result;
  await t.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (c) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              result = await Navigator.of(c).push(
                MaterialPageRoute<Battle3DResult>(
                  builder: (_) => Battle3DScreen(
                    save: save,
                    world: world,
                    stage: stage,
                    questions: _questions(),
                    enemyLabel: '英語スライム',
                    color: Colors.blue,
                  ),
                ),
              );
            },
            child: const Text('start'),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('start'));
  await t.pumpAndSettle();
  if (answerAll) {
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const ValueKey('battle3d-result')).evaluate().isNotEmpty) {
        break;
      }
      final correct = find.textContaining('正解');
      final choice = find.descendant(
        of: find.byType(FilledButton),
        matching: correct,
      );
      if (choice.evaluate().isEmpty) {
        await t.pump(const Duration(milliseconds: 200));
        continue;
      }
      await t.tap(choice.first);
      await t.pump(const Duration(milliseconds: 1200));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pumpAndSettle();
    expect(find.text('勝利！'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('battle3d-back')));
  } else {
    await t.tap(find.byKey(const ValueKey('battle3d-flee')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('battle3d-flee-ok')));
  }
  await t.pumpAndSettle();
  return (save, result);
}

void main() {
  testWidgets('正解し続けると勝ち、3D版の経験値が増え、2D版のデータは変わらない', (t) async {
    final (save, result) = await _play(t, answerAll: true);
    expect(result?.won, isTrue);
    expect(result?.clear?.expResult.expGained, greaterThan(0));
    final p = save.loadProgress();
    expect(p.totalExp, greaterThan(0));
    expect(p.clearedStageIds, contains('english_01'));
    expect(save.prefs.getString('rpg_progress_v1'), '2D版のデータ');
  });

  testWidgets('にげると負け扱いで、経験値は増えない', (t) async {
    final (save, result) = await _play(t, answerAll: false);
    expect(result?.won, isFalse);
    expect(result?.clear, isNull);
    expect(save.loadProgress().totalExp, 0);
  });

  testWidgets('タイトルで3D版のデータを消しても、2D版のデータは残る', (t) async {
    SharedPreferences.setMockInitialValues({
      'rpg_progress_v1': '2D版のデータ',
      Save3D.progressKey: '{"level":3}',
      Save3D.fieldKey: '{}',
    });
    await t.pumpWidget(const MaterialApp(home: TitleScreen()));
    await t.pumpAndSettle();
    expect(find.text('つづきから'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('title-reset')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('title-reset-ok')));
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('rpg_progress_v1'), '2D版のデータ');
    expect(prefs.containsKey(Save3D.progressKey), isFalse);
    expect(prefs.containsKey(Save3D.fieldKey), isFalse);
    expect(find.text('冒険をはじめる'), findsOneWidget);
  });

  test('3D版のバトルで出せない問題（図・本文・聞き取り・4択以外）は除く', () {
    final base = _questions().first;
    expect(Questions3D.playable(base), isTrue);
    QuizQuestion copy(Map<String, dynamic> extra) =>
        QuizQuestion.fromJson({...base.toJson(), ...extra});
    expect(
      Questions3D.playable(
        copy({
          'figure': {'type': 'graph'},
        }),
      ),
      isFalse,
    );
    expect(Questions3D.playable(copy({'listen': true})), isFalse);
  });
}
