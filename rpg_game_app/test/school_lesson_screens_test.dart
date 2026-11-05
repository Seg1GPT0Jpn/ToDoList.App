import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:rpg_game_app/study/school_lesson_screens.dart';
import 'package:rpg_game_app/study/school_lesson_store.dart';
import 'package:rpg_game_app/vocab/speech.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 問題データ・教材の読み込み（本物の非同期）を待つ
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await _frames(t, 2);
  }
}

const _immunity = 'science.biology.body.immunity';

class _FakeSpeaker implements Speaker {
  final said = <String>[];
  var stopped = 0;
  @override
  Future<void> speak(
    String text, {
    required String lang,
    required double rate,
  }) async {
    said.add(text);
  }

  @override
  Future<void> stop() async => stopped++;
}

/// 教材ファイル（rpg_game/assets/lessons/）をそのまま読む
String? _lessonFile(String subjectId) {
  final f = File('../rpg_game/assets/lessons/$subjectId.json');
  return f.existsSync() ? f.readAsStringSync() : null;
}

void main() {
  setUp(() {
    SchoolLessonStore.loader = (id) async => _lessonFile(id);
    SchoolLessonStore.clearCache();
  });
  final plan = ShonanRangeTable.plan('後期中間試験', id: 'p1', now: DateTime(2026));
  final subject = ShonanSubjects.byId('biology_basic')!;

  Future<void> openCourse(WidgetTester t, {bool keep = false}) async {
    await openScreen(
      t,
      SchoolCourseScreen(
        plan: plan,
        subject: subject,
        sp: plan.subject(subject.id),
      ),
      prefs: {SchoolExamStore.gateKey: true},
      keepPrefs: keep,
      frames: 5,
    );
    await _settle(t);
  }

  Future<SchoolLesson> lesson(WidgetTester t) async =>
      SchoolLessons.parse(jsonDecode(_lessonFile('biology_basic')!) as List)
          .firstWhere((l) => l.unitId == _immunity);

  Future<void> scrollTo(WidgetTester t, Finder f) async {
    await t.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _frames(t, 2);
  }

  testWidgets('範囲の網羅状況：教材の整備と学習の進み具合を分けて出す', (t) async {
    await openCourse(t);
    expect(find.byKey(const ValueKey('coverage-summary')), findsOneWidget);
    // 生物基礎の後期中間は4単元。授業はすべて整備済み、まだ誰も学習していない
    expect(
      t.widget<Text>(find.byKey(const ValueKey('coverage-lesson'))).data,
      '4/4',
    );
    expect(
      t.widget<Text>(find.byKey(const ValueKey('coverage-mastered'))).data,
      '0/4',
    );
    expect(find.textContaining('完全攻略'), findsNothing);
    // 間違いがまだないので「間違い直し」は押せない
    final mistakes = t.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('course-mode-mistakes')),
    );
    expect(mistakes.onPressed, isNull);
    await scrollTo(t, find.byKey(const ValueKey('course-unit-$_immunity')));
    expect(
      t
          .widget<Text>(find.byKey(const ValueKey('course-state-$_immunity')))
          .data,
      '未着手',
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('授業を最後まで進め、確認テストに合格すると「理解度確認済み」になる', (t) async {
    final l = await lesson(t);
    await openCourse(t);
    await scrollTo(t, find.byKey(const ValueKey('course-lesson-$_immunity')));
    await t.tap(find.byKey(const ValueKey('course-lesson-$_immunity')));
    await _frames(t);
    expect(find.text('この授業の目標'), findsOneWidget);
    // 先生のあいさつ
    expect(find.text(l.opening.first), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('lesson-next')));
    await _frames(t, 3);
    // 説明は黒板（板書）と先生の話。話は1つずつ進められ、全文も出せる
    final first = l.steps.first;
    expect(find.byKey(const ValueKey('lesson-board')), findsOneWidget);
    expect(find.text(first.talk[0]), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('lesson-talk-next')));
    await _frames(t, 3);
    expect(find.text(first.talk[1]), findsOneWidget);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('lesson-talk-count'))).data,
      '2/${first.talk.length}',
    );
    await t.tap(find.byKey(const ValueKey('lesson-talk-all')));
    await _frames(t, 3);
    expect(find.text(first.talk.last), findsOneWidget);
    for (var i = 0; i < l.steps.length; i++) {
      final check = l.steps[i].check;
      if (check != null) {
        // 途中の問題は、答えないと次へ進めない
        final next = t.widget<FilledButton>(
          find.byKey(const ValueKey('lesson-next')),
        );
        expect(next.onPressed, isNull);
        // 1回まちがえるとヒントが出る
        final wrong = check.answerIndex == 0 ? 1 : 0;
        await t.tap(find.byKey(ValueKey('lesson-choice-$i-$wrong')));
        await _frames(t, 2);
        expect(find.byKey(const ValueKey('lesson-hint')), findsOneWidget);
        await t.ensureVisible(
          find.byKey(ValueKey('lesson-choice-$i-${check.answerIndex}')),
        );
        await t.tap(
          find.byKey(ValueKey('lesson-choice-$i-${check.answerIndex}')),
        );
        await _frames(t, 2);
        expect(find.byKey(const ValueKey('lesson-feedback')), findsOneWidget);
      }
      await t.tap(find.byKey(const ValueKey('lesson-next')));
      await _frames(t, 3);
    }
    await t.tap(find.byKey(const ValueKey('lesson-understanding-3')));
    await _frames(t, 2);
    await t.ensureVisible(find.byKey(const ValueKey('lesson-to-quiz')));
    await t.tap(find.byKey(const ValueKey('lesson-to-quiz')));
    await _settle(t);
    for (final q in l.quiz) {
      await t.tap(find.byKey(ValueKey('quiz-choice-${q.answerIndex}')));
      await _frames(t, 2);
      await t.ensureVisible(find.byKey(const ValueKey('quiz-next')));
      await t.tap(find.byKey(const ValueKey('quiz-next')));
      await _settle(t);
    }
    expect(
      t.widget<Text>(find.byKey(const ValueKey('quiz-score'))).data,
      '${l.quiz.length}問中${l.quiz.length}問正解',
    );
    expect(find.byKey(const ValueKey('quiz-practice')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('quiz-close')));
    await _settle(t);
    await scrollTo(t, find.byKey(const ValueKey('course-state-$_immunity')));
    expect(
      t
          .widget<Text>(find.byKey(const ValueKey('course-state-$_immunity')))
          .data,
      '理解度確認済み',
    );
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('coverage-learned')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      t.widget<Text>(find.byKey(const ValueKey('coverage-learned'))).data,
      '1/4',
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('自動再生で先生の話が進み、話し終えると次の説明へ。読み上げもできる', (t) async {
    final fake = _FakeSpeaker();
    final saved = speaker;
    speaker = fake;
    addTearDown(() => speaker = saved);
    final l = await lesson(t);
    await openCourse(t);
    await scrollTo(t, find.byKey(const ValueKey('course-lesson-$_immunity')));
    await t.tap(find.byKey(const ValueKey('course-lesson-$_immunity')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('lesson-next')));
    await _frames(t, 3);
    final talk = l.steps.first.talk;
    await t.tap(find.byKey(const ValueKey('lesson-talk-voice')));
    await _frames(t, 2);
    expect(fake.said, [talk.first]);
    await t.tap(find.byKey(const ValueKey('lesson-talk-auto')));
    // 話をすべて終えるまで待つと、次のページ（2つめの説明）へ進む
    for (var i = 0; i < talk.length + 2; i++) {
      await t.pump(const Duration(seconds: 30));
    }
    expect(fake.said, containsAllInOrder(talk));
    expect(find.byKey(const ValueKey('lesson-page-1')), findsNothing);
    // 読み上げを止める
    await t.tap(find.byKey(const ValueKey('lesson-talk-auto')));
    await t.tap(find.byKey(const ValueKey('lesson-talk-voice')));
    await _frames(t, 2);
    expect(fake.stopped, greaterThan(0));
    expect(t.takeException(), isNull);
  });

  testWidgets('授業の途中でやめても続きから再開でき、確認テスト不合格は「要復習」', (t) async {
    final l = await lesson(t);
    await openCourse(t);
    await scrollTo(t, find.byKey(const ValueKey('course-lesson-$_immunity')));
    await t.tap(find.byKey(const ValueKey('course-lesson-$_immunity')));
    await _frames(t);
    // 目標→説明→説明 まで進んでやめる
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(const ValueKey('lesson-next')));
      await _frames(t, 3);
    }
    await t.pageBack();
    await _settle(t);
    await scrollTo(t, find.byKey(const ValueKey('course-lesson-$_immunity')));
    expect(find.text('続きから'), findsOneWidget);
    expect(
      t
          .widget<Text>(find.byKey(const ValueKey('course-state-$_immunity')))
          .data,
      '学習中',
    );
    await t.tap(find.byKey(const ValueKey('course-lesson-$_immunity')));
    await _frames(t);
    expect(find.byKey(const ValueKey('lesson-page-3')), findsOneWidget);
    await t.pageBack();
    await _settle(t);
    // 確認テストで全部まちがえる
    await scrollTo(t, find.byKey(const ValueKey('course-quiz-$_immunity')));
    await t.tap(find.byKey(const ValueKey('course-quiz-$_immunity')));
    await _frames(t);
    for (final q in l.quiz) {
      await t.tap(
        find.byKey(ValueKey('quiz-choice-${q.answerIndex == 0 ? 1 : 0}')),
      );
      await _frames(t, 2);
      await t.ensureVisible(find.byKey(const ValueKey('quiz-next')));
      await t.tap(find.byKey(const ValueKey('quiz-next')));
      await _settle(t);
    }
    expect(find.byKey(const ValueKey('quiz-relesson')), findsOneWidget);
    expect(find.textContaining('別の角度から'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('quiz-close')));
    await _settle(t);
    await scrollTo(t, find.byKey(const ValueKey('course-state-$_immunity')));
    expect(
      t
          .widget<Text>(find.byKey(const ValueKey('course-state-$_immunity')))
          .data,
      '要復習',
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('重要事項の確認で、範囲の授業の要点を一覧で見られる', (t) async {
    await openCourse(t);
    await t.tap(find.byKey(const ValueKey('course-mode-points')));
    await _frames(t);
    expect(find.byType(LessonKeyPointsScreen), findsOneWidget);
    expect(find.textContaining('神経系と内分泌系'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('範囲の問題セットがない科目は、登録のしかたを案内する', (t) async {
    final geo = ShonanSubjects.byId('geography_general')!;
    await openScreen(
      t,
      SchoolCourseScreen(plan: plan, subject: geo, sp: plan.subject(geo.id)),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 5,
    );
    await _settle(t);
    expect(find.textContaining('まだ登録されていません'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
