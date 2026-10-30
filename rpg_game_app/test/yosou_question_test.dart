import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:rpg_game_app/study/yosou_crop_view.dart';
import 'package:rpg_game_app/study/yosou_exam_screens.dart';
import 'package:rpg_game_app/study/yosou_exam_store.dart';
import 'package:rpg_game_app/vocab/speech.dart';

import 'harness.dart';

final _password = Platform.environment['SCHOOL_PASSWORD'];

Future<void> _frames(WidgetTester t, [int n = 4]) async {
  for (var i = 0; i < n; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

const _exam = YosouExam(
  id: 'joho',
  title: 'テスト用の予想問題',
  subjectId: 'information1',
  questionPages: 1,
  answerPages: 1,
  smallQuestions: true,
);

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
    tags: const ['yosou', 'pt:3'],
    passage: _p,
  ),
  QuizQuestion(
    id: 'yosou_t_2',
    category: QuestionCategory.meaning,
    prompt: '(2) 語を書こう',
    choices: const ['vital', '（書いて答える問題）'],
    answerIndex: 0,
    accepted: const [],
    tags: const ['yosou', 'pt:2'],
    passage: _p,
  ),
  QuizQuestion(
    id: 'yosou_t_3',
    category: QuestionCategory.reading,
    prompt: '(3) 説明しよう',
    format: QuestionFormat.written,
    written: WrittenSpec(modelAnswer: '模範解答', rubric: [RubricItem('ポイント', 5)]),
    tags: const ['yosou', 'pt:5'],
    passage: _p,
  ),
];

/// 本物の問題を、正しく答える
Future<void> _answer(WidgetTester t, QuizQuestion q) async {
  final list = find
      .descendant(
        of: find.byKey(ValueKey('yosou-q-${q.id}')),
        matching: find.byType(Scrollable),
      )
      .first;
  Future<void> tap(String k) async {
    await t.scrollUntilVisible(find.byKey(ValueKey(k)), 300, scrollable: list);
    await t.pump();
    await t.tap(find.byKey(ValueKey(k)));
    await t.pump();
  }

  switch (q.format) {
    case QuestionFormat.choice when !q.isInput:
      await tap('yosou-choice-${q.answerIndex}');
    case QuestionFormat.multiSelect:
      for (final i in q.multiSelect!.correct) {
        await tap('yosou-choice-$i');
      }
    case QuestionFormat.order:
      for (final w in q.order!.items) {
        await tap('yosou-order-$w');
      }
    default:
      const k = ValueKey('yosou-answer-input');
      await t.scrollUntilVisible(find.byKey(k), 300, scrollable: list);
      await t.enterText(
        find.byKey(k),
        q.format == QuestionFormat.written ? '書いた' : q.answer,
      );
      await t.pump();
  }
}

void main() {
  late List<int> key;
  final oldLoader = YosouExamFiles.loader;

  setUp(() => speaker = SilentSpeaker());
  tearDown(() => YosouExamFiles.loader = oldLoader);

  testWidgets('はじめると小問が1問ずつ出る。その場では採点せず、提出でまとめて採点', (t) async {
    key = SchoolMaterials.keyFor('test-pw');
    final sealed = SchoolMaterials.seal(
      utf8.encode(
        jsonEncode(
          QuestionSet(
            setId: 'yosou_joho',
            worldId: 'information1',
            origin: QuestionOrigin.original,
            version: 1,
            questions: _qs,
          ).toJson(),
        ),
      ),
      List.filled(16, 3),
      key: key,
    );
    YosouExamFiles.loader = (asset) async => sealed;
    var now = DateTime(2026, 10, 28, 9);
    final s = await openScreen(
      t,
      YosouExamScreen(exam: _exam, keyBytes: key, now: () => now),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 3,
    );
    await _frames(t);
    expect(find.textContaining('小問 3問'), findsOneWidget);
    expect(find.byKey(const ValueKey('yosou-small')), findsNothing);
    await t.tap(find.byKey(const ValueKey('yosou-start')));
    await _frames(t);
    expect(find.text('のこり 60:00'), findsOneWidget);
    expect(find.text('第1問 / 3'), findsOneWidget);
    expect(find.text('📜 大問A'), findsOneWidget);
    expect(find.text('本文の1段落目'), findsOneWidget);

    // 選んでも○×は出ない。選びなおせる
    await t.tap(find.byKey(const ValueKey('yosou-choice-0')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('yosou-choice-2')));
    await t.pump();
    expect(find.textContaining('正解'), findsNothing);
    await t.tap(find.byKey(const ValueKey('yosou-flag-yosou_t_1')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('yosou-next')));
    await _frames(t);
    expect(find.text('第2問 / 3'), findsOneWidget);
    await t.enterText(
      find.byKey(const ValueKey('yosou-answer-input')),
      'Vital',
    );
    await t.pump();

    // 同じ大問の問題と、自分の答えが見られる。タップでその問題へ
    await t.tap(find.byKey(const ValueKey('yosou-open-group')));
    await _frames(t);
    expect(find.text('この大問の問題（3問）・タップでその問題へ'), findsOneWidget);
    expect(find.text('あなたの答え：3. う'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-sibling-yosou_t_3')));
    await t.pumpAndSettle();
    expect(find.text('第3問 / 3'), findsOneWidget);

    // 計算メモ
    await t.tap(find.byKey(const ValueKey('yosou-memo')));
    await _frames(t);
    expect(find.byKey(const ValueKey('scratchpad')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('scratchpad-close')));
    await _frames(t);

    // 一覧から問題へ（答えた数・見直しの印）
    await t.tap(find.byKey(const ValueKey('yosou-list-open')));
    await _frames(t);
    expect(find.text('答えた 2/3・見直し 1'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-go-2')));
    await t.pumpAndSettle();
    expect(find.text('第2問 / 3'), findsOneWidget);
    // 前に書いた答えが残っている
    expect(find.text('Vital'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-prev')));
    await _frames(t);
    expect(find.text('第1問 / 3'), findsOneWidget);

    now = now.add(const Duration(minutes: 20));
    await _frames(t, 12);
    final saved = YosouExamStore.of(s.personalBooks).attempt('joho')!;
    expect(saved.answers, {'yosou_t_1': '3. う', 'yosou_t_2': 'Vital'});
    expect(saved.flags, {'yosou_t_1'});

    // 最後の問題の「提出する」から提出
    await t.tap(find.byKey(const ValueKey('yosou-next')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-next')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-next')));
    await _frames(t);
    expect(find.textContaining('未記入が 1 問'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-submit-ok')));
    await _frames(t);
    expect(find.text('5 / 10 点'), findsOneWidget);
    expect(find.text('(1) 正しいものは？'), findsOneWidget);
    expect(find.text('あなたの答え：3. う'), findsOneWidget);
    // 結果の画面を、自分で採点するボタンが見えるところまでスクロールする
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('yosou-self-yosou_t_3-2')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('yosou-result')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.drag(
      find.byKey(const ValueKey('yosou-result')),
      const Offset(0, -150),
    );
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-self-yosou_t_3-2')));
    await _frames(t);
    await t.drag(
      find.byKey(const ValueKey('yosou-result')),
      const Offset(0, 3000),
    );
    await _frames(t);
    expect(find.text('7 / 10 点'), findsOneWidget);
    expect(YosouExamStore.of(s.personalBooks).history('joho').single.score, 7);
    expect(t.takeException(), isNull);
  });

  testWidgets('リセット：途中の答えだけ消す／結果もふくめて消す', (t) async {
    key = SchoolMaterials.keyFor('test-pw');
    final sealed = SchoolMaterials.seal(
      utf8.encode(
        jsonEncode(
          QuestionSet(
            setId: 'yosou_joho',
            worldId: 'information1',
            origin: QuestionOrigin.original,
            version: 1,
            questions: _qs,
          ).toJson(),
        ),
      ),
      List.filled(16, 3),
      key: key,
    );
    YosouExamFiles.loader = (asset) async => sealed;
    final now = DateTime(2026, 10, 28, 9);
    final s = await openScreen(
      t,
      YosouExamScreen(exam: _exam, keyBytes: key, now: () => now),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 3,
    );
    final store = YosouExamStore.of(s.personalBooks);
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-start')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-choice-2')));
    await t.pump();
    expect(store.attempt('joho')!.answers, isNotEmpty);

    // 解いている途中：答えだけ消して、はじめる前へ
    await t.tap(find.byKey(const ValueKey('yosou-restart')));
    await _frames(t);
    expect(find.textContaining('これまでの結果は残ります'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-reset-ok')));
    await _frames(t);
    expect(store.attempt('joho'), isNull);
    expect(find.byKey(const ValueKey('yosou-start')), findsOneWidget);

    // 提出したあと：結果もふくめて消す
    await t.tap(find.byKey(const ValueKey('yosou-start')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-submit')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-submit-ok')));
    await _frames(t);
    expect(store.history('joho'), hasLength(1));
    await t.ensureVisible(find.byKey(const ValueKey('yosou-reset')));
    await t.tap(find.byKey(const ValueKey('yosou-reset')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-reset-ok')));
    await _frames(t);
    expect(store.attempt('joho'), isNull);
    expect(store.history('joho'), isEmpty);
    expect(find.byKey(const ValueKey('yosou-start')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    '本物の小問：すべての教科で、全問を1問ずつ表示して正しく答え、提出で満点（記述をのぞく）になる',
    (t) async {
      speaker = SilentSpeaker();
      final key = SchoolMaterials.keyFor(_password!);
      YosouImages.key = key;
      for (final e in YosouExams.all.where((e) => e.smallQuestions)) {
        final qs = (await t.runAsync(YosouExamFiles(e, key).questions))!;
        final sheet = YosouSheet.of(qs);
        final selfPoints = sheet.items
            .where((i) => i.type == MockItemType.self)
            .fold(0, (a, i) => a + i.points);
        final now = DateTime(2026, 10, 28, 9);
        await openScreen(
          t,
          YosouExamScreen(
            key: ValueKey(e.id),
            exam: e,
            keyBytes: key,
            now: () => now,
          ),
          prefs: {SchoolExamStore.gateKey: true},
          frames: 3,
        );
        await _frames(t, 6);
        await t.tap(find.byKey(const ValueKey('yosou-start')));
        await _frames(t, 4);
        for (var n = 0; n < qs.length; n++) {
          final q = qs[n];
          expect(find.text('第${n + 1}問 / ${qs.length}'), findsOneWidget);
          if (q.figure != null ||
              q.passage!.paragraphs.any(
                (p) => p.startsWith(YosouCrop.paragraphPrefix),
              )) {
            await _frames(t, 4);
            expect(
              find.textContaining('図を開けませんでした'),
              findsNothing,
              reason: q.id,
            );
          }
          await _answer(t, q);
          expect(t.takeException(), isNull, reason: q.id);
          await t.tap(find.byKey(const ValueKey('yosou-next')));
          await _frames(t, 2);
        }
        await t.tap(find.byKey(const ValueKey('yosou-submit-ok')));
        await _frames(t, 4);
        expect(
          find.text('${100 - selfPoints} / 100 点'),
          findsOneWidget,
          reason: e.id,
        );
        for (var i = 0; i < 60; i++) {
          await t.drag(
            find.byKey(const ValueKey('yosou-result')),
            const Offset(0, -700),
          );
          await t.pump();
        }
        expect(t.takeException(), isNull, reason: e.id);
      }
      await t.pumpWidget(const SizedBox());
    },
    skip: _password == null,
    timeout: const Timeout(Duration(minutes: 20)),
  );

  test('小問がまだない教科は null', () async {
    const e = YosouExam(
      id: 'geo',
      title: '地理総合',
      subjectId: 'geography_general',
      questionPages: 1,
      answerPages: 1,
    );
    expect(await YosouExamFiles(e, const [1]).questions(), isNull);
    expect(jsonEncode(e.questionsAsset), contains(e.id));
  });
}
