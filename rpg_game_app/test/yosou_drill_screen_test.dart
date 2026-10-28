import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:rpg_game_app/study/yosou_drill_screens.dart';
import 'package:rpg_game_app/study/yosou_exam_store.dart';
import 'package:rpg_game_app/vocab/speech.dart';

import 'harness.dart';

final _password = Platform.environment['SCHOOL_PASSWORD'];

Future<void> _frames(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

const _p = Passage(
  id: 'yosou_t_a',
  title: '大問A',
  paragraphs: ['本文の1段落目', '本文の2段落目'],
);

final _qs = [
  QuizQuestion(
    id: 'yosou_t_1',
    category: QuestionCategory.reading,
    prompt: '(1) 正しいものは？',
    choices: const ['1. あ', '2. い', '3. う', '4. え', '5. お'],
    answerIndex: 2,
    tags: const ['yosou'],
    passage: _p,
    explanation: '本文2段落目より。',
  ),
  QuizQuestion(
    id: 'yosou_t_2',
    category: QuestionCategory.meaning,
    prompt: '(2) 語を書こう',
    choices: const ['vital', '（書いて答える問題）'],
    answerIndex: 0,
    accepted: const [],
    tags: const ['yosou'],
    passage: _p,
  ),
  QuizQuestion(
    id: 'yosou_t_3',
    category: QuestionCategory.reading,
    prompt: '(3) 説明しよう',
    format: QuestionFormat.written,
    written: WrittenSpec(modelAnswer: '模範解答', rubric: [RubricItem('ポイント', 2)]),
    tags: const ['yosou'],
    passage: _p,
  ),
];

void main() {
  setUp(() => speaker = SilentSpeaker());

  testWidgets('順番に解く：本文・同じ大問・メモを見ながら、選択・記入・記述を解く', (t) async {
    await openScreen(
      t,
      YosouDrillScreen(title: 'テスト', questions: _qs),
      frames: 3,
    );
    expect(find.text('📜 大問A'), findsOneWidget);
    expect(find.text('本文の1段落目'), findsOneWidget);
    // 5択（原本どおりの数）
    await t.tap(find.byKey(const ValueKey('yosou-choice-2')));
    await _frames(t);
    expect(find.text('○ 正解'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-drill-next')));
    await _frames(t);

    // 同じ大問の問題が見られる（前の問題の答えも）
    await t.tap(find.byKey(const ValueKey('yosou-open-group')));
    await _frames(t);
    expect(find.text('この大問の問題（3問）'), findsOneWidget);
    expect(find.textContaining('正解：3. う'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();

    // 計算メモ
    await t.tap(find.byKey(const ValueKey('yosou-drill-memo')));
    await _frames(t);
    expect(find.byKey(const ValueKey('scratchpad')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('scratchpad-close')));
    await _frames(t);

    await t.enterText(find.byKey(const ValueKey('yosou-drill-input')), 'Vital');
    await t.tap(find.byKey(const ValueKey('yosou-drill-submit')));
    await _frames(t);
    expect(find.text('○ 正解'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-drill-next')));
    await _frames(t);

    expect(find.text('(3) 説明しよう'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('本物のECの小問：順番にすべて表示でき、バトルでも出題できる', (t) async {
    final key = SchoolMaterials.keyFor(_password!);
    final exam = YosouExams.byId('ec')!;
    final files = YosouExamFiles(exam, key);
    final qs = (await t.runAsync(files.questions))!;
    expect(qs.length, 68);
    await openScreen(
      t,
      YosouDrillMenu(exam: exam, questions: qs),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 3,
    );
    expect(find.byKey(const ValueKey('yosou-drill-all')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-drill-all')));
    await _frames(t);
    for (var i = 0; i < qs.length; i++) {
      final q = qs[i];
      final list = find
          .descendant(
            of: find.byKey(ValueKey('yosou-drill-${q.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> show(String key) async {
        await t.scrollUntilVisible(
          find.byKey(ValueKey(key)),
          300,
          scrollable: list,
        );
        await t.pumpAndSettle();
      }

      if (q.isChoice && q.isInput) {
        await show('yosou-drill-input');
        await t.enterText(find.byKey(const ValueKey('yosou-drill-input')), 'x');
        await t.tap(find.byKey(const ValueKey('yosou-drill-submit')));
      } else if (q.isChoice) {
        await show('yosou-choice-0');
        await t.tap(find.byKey(const ValueKey('yosou-choice-0')));
      } else {
        break;
      }
      await t.pumpAndSettle();
      await show('yosou-drill-next');
      await t.tap(find.byKey(const ValueKey('yosou-drill-next')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: q.id);
    }
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('yosou-battle-all')));
    await _frames(t, 20);
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('open-scratchpad')), findsOneWidget);
    expect(t.takeException(), isNull);
    // バトルのタイマーを止める
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  }, skip: _password == null);

  test('ほかの教科は、小問がまだなら null', () async {
    final e = YosouExams.all.firstWhere((e) => !e.smallQuestions);
    expect(await YosouExamFiles(e, const [1]).questions(), isNull);
    expect(jsonEncode(e.questionsAsset), contains(e.id));
  });
}
