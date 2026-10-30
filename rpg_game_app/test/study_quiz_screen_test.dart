import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/study/study_quiz_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('バトルなしで1問ずつ解き、まちがえた問題はもう一度出て、答えは学習記録に残る', (t) async {
    final services = await openScreen(
      t,
      const SizedBox(),
      size: const Size(420, 1400),
    );
    late List<QuizQuestion> questions;
    await t.runAsync(() async {
      // 学習記録に残るのは、読みこんだ問題セットの問題（どのセットのものかが分かる）
      final setId = (await RpgServices.questionSetsOf('english')).keys.first;
      final set = (await services.questions.load(setId))!;
      final picked = <QuizQuestion>[];
      for (final q in set.questions.where((q) => q.isChoice && !q.isInput)) {
        if (picked.every(
          (p) =>
              p.answer != q.answer &&
              (p.sentence ?? p.prompt) != (q.sentence ?? q.prompt),
        )) {
          picked.add(q);
        }
        if (picked.length == 3) break;
      }
      questions = picked;
    });
    expect(questions, hasLength(3));
    var finished = (-1, -1);
    t
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => StudyQuizScreen(
              title: '単元の練習',
              subject: 'english',
              questions: questions,
              random: Random(1),
              onFinished: (c, a) => finished = (c, a),
            ),
          ),
        );
    await _frames(t);
    expect(find.byKey(const ValueKey('study-quiz')), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    /// いま出ている問題
    QuizQuestion current() => questions.firstWhere(
      (q) => find.text(q.sentence ?? q.prompt).evaluate().isNotEmpty,
    );

    /// 正解（または、まちがい）の選択肢をえらぶ
    Future<void> answer({required bool right}) async {
      final q = current();
      for (var i = 0; i < 6; i++) {
        final key = find.byKey(ValueKey('study-choice-$i'));
        if (key.evaluate().isEmpty) break;
        final text = t
            .widget<Text>(find.descendant(of: key, matching: find.byType(Text)))
            .data;
        if ((text == q.answer) == right) {
          await t.tap(key);
          await _frames(t, 2);
          return;
        }
      }
      fail('選択肢が見つかりません');
    }

    // 1問目はまちがえる：正解が出て、もう一度出る分だけ問題が増える
    await answer(right: false);
    expect(find.text('不正解…'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('study-next')));
    await _frames(t);
    expect(find.text('2 / 4'), findsOneWidget);
    // 残り（もう一度の1問をふくむ）はすべて正解
    for (var i = 0; i < 3; i++) {
      await answer(right: true);
      expect(find.text('正解！'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('study-next')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await _frames(t);
    }
    expect(find.byKey(const ValueKey('study-summary')), findsOneWidget);
    expect(finished, (3, 4));
    expect(find.text('75%'), findsOneWidget);
    // 学習記録に残っている（復習の日が決まる）
    for (final q in questions) {
      expect(services.meta.record[q.id], isNotNull, reason: q.id);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('1回に解く問題の数は、設定の「問題の量」（かんたん5・ふつう10・むずかしい20）', (t) async {
    expect(AppSettings.fromMap({'quizAmount': 'hard'}).quizCount, 20);
    expect(AppSettings.fromMap({'quizAmount': 'xxx'}).quizCount, 10);
    expect(
      AppSettings.fromMap(const AppSettings(quizAmount: 'easy').toMap())
          .quizCount,
      5,
    );
    final services = await openScreen(
      t,
      const SizedBox(),
      settings: const AppSettings(quizAmount: 'easy'),
    );
    late List<QuizQuestion> questions;
    await t.runAsync(() async {
      final setId = (await RpgServices.questionSetsOf('english')).keys.first;
      final set = (await services.questions.load(setId))!;
      questions = set.questions.where((q) => q.isChoice).take(8).toList();
    });
    t
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => StudyQuizScreen(
              title: '練習',
              subject: 'english',
              questions: questions,
            ),
          ),
        );
    await _frames(t);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
