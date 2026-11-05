import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

const _unit = 'science.biology.body.immunity';

LessonCheck _check(String q) => LessonCheck(
      prompt: q,
      choices: const ['正しい', 'ちがう1', 'ちがう2'],
      answerIndex: 0,
      explanation: '解説',
    );

SchoolLesson _lesson({String unit = _unit, int quiz = 5}) => SchoolLesson(
      id: 'les_$unit',
      subjectId: 'biology_basic',
      unitId: unit,
      title: '免疫',
      goals: const ['免疫のしくみを説明できる'],
      steps: [
        const LessonStep.block(LessonBlockKind.intro, '導入', '本文'),
        const LessonStep.block(LessonBlockKind.explain, '説明', '本文'),
        LessonStep.check(_check('途中の問題')),
        const LessonStep.block(LessonBlockKind.summary, 'まとめ', '本文'),
      ],
      quiz: [for (var i = 0; i < quiz; i++) _check('確認$i')],
    );

QuizQuestion _q(String id, String unit) => QuizQuestion(
      id: id,
      category: QuestionCategory.meaning,
      prompt: id,
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      explanation: '解説',
      unit: unit,
    );

/// 問題 ID → [正解なら true] の順に答えた記録を作る
Map<String, QuestionStat> _stats(Map<String, List<bool>> answers, int day) => {
      for (final e in answers.entries)
        e.key: e.value.fold(
          const QuestionStat(),
          (s, ok) => s.record(isCorrect: ok, day: day, elapsedMs: 1000),
        ),
    };

void main() {
  final questions = [
    for (var i = 0; i < 10; i++) _q('q$i', '$_unit.adaptive'),
  ];

  group('授業の教材', () {
    test('JSON から読み、足りない授業は整備済みにしない', () {
      final l = SchoolLesson.fromJson({
        'id': 'les_x',
        'subjectId': 'biology_basic',
        'unitId': _unit,
        'title': '免疫',
        'goals': ['目標'],
        'steps': [
          {'t': 'intro', 'h': '導入', 'b': '本文'},
          {'t': 'explain', 'h': '説明', 'b': '本文'},
          {
            't': 'check',
            'q': '問',
            'c': ['A', 'B'],
            'a': 1,
            'e': '解説',
            'hint': 'ヒント',
          },
          {'t': 'summary', 'h': 'まとめ', 'b': '本文'},
        ],
        'quiz': [
          for (var i = 0; i < 3; i++)
            {
              'q': '確認$i',
              'c': ['A', 'B'],
              'a': 0,
              'e': '解説',
            },
        ],
      });
      expect(l.isComplete, isTrue, reason: l.problems().join('、'));
      expect(l.inlineChecks.single.hint, 'ヒント');
      expect(l.passScore, 3);
      expect(_lesson(quiz: 5).passScore, 4);
      // 確認テストが少ない・解説が空・存在しない単元は「整備済み」にしない
      expect(_lesson(quiz: 2).isComplete, isFalse);
      expect(_lesson(unit: 'no.such.unit').problems(), isNotEmpty);
      const bad = LessonCheck(
        prompt: '問',
        choices: ['A', 'A'],
        answerIndex: 3,
        explanation: '',
      );
      expect(bad.problems().length, 3);
    });
  });

  group('単元の状態', () {
    final lesson = _lesson();
    UnitPractice practice(Map<String, List<bool>> a, [int day = 10]) =>
        UnitPractice.of(questions, _stats(a, day));

    test('授業を開いただけでは習得にならず、確認テストと演習で状態が進む', () {
      LessonState s(LessonRecord? r, UnitPractice p) =>
          LessonMastery.evaluate(lesson: lesson, record: r, practice: p);
      final none = practice({});
      const r0 = LessonRecord(lessonId: 'x');
      expect(s(null, none), LessonState.notStarted);
      expect(s(r0.advance(1, 4, day: 9), none), LessonState.studying);
      final viewed = r0.advance(4, 4, day: 9);
      expect(viewed.viewed, isTrue);
      expect(s(viewed, none), LessonState.viewed);
      // 確認テスト不合格（5問中3問）→ 要復習
      final failed = viewed.withQuiz(3, lesson.passScore, day: 9);
      expect(s(failed, none), LessonState.needsReview);
      // 合格（4問）→ 理解度確認済み
      final passed = failed.withQuiz(4, lesson.passScore, day: 9);
      expect(passed.quizPassedDay, 9);
      expect(s(passed, none), LessonState.checked);
      // 演習を少し → 演習中
      expect(
          s(
              passed,
              practice({
                'q0': [true]
              })),
          LessonState.practicing);
      // 8問すべて正解でも、合格した日と同じ日だけなら習得にしない（時間をあけた確認が必要）
      final all8 = {
        for (var i = 0; i < 8; i++) 'q$i': [true]
      };
      expect(s(passed, practice(all8, 9)), LessonState.practicing);
      expect(s(passed, practice(all8, 10)), LessonState.mastered);
      // 正解率が低いと要復習
      final weak = {
        for (var i = 0; i < 5; i++) 'q$i': [i < 2],
      };
      expect(s(passed, practice(weak)), LessonState.needsReview);
      // 習得したあとに少しまちがえると「再確認が必要」
      final once = passed.copyWith(masteredDay: 10);
      final slipped = {
        for (var i = 0; i < 8; i++) 'q$i': [true, i >= 2],
      };
      expect(s(once, practice(slipped, 11)), LessonState.recheck);
    });

    test('授業のない単元は、演習だけで状態を決める', () {
      LessonState s(UnitPractice p) =>
          LessonMastery.evaluate(lesson: null, record: null, practice: p);
      expect(s(practice({})), LessonState.notStarted);
      expect(
          s(practice({
            'q0': [true]
          })),
          LessonState.practicing);
      expect(
        s(practice({
          for (var i = 0; i < 8; i++) 'q$i': [true]
        })),
        LessonState.mastered,
      );
    });

    test('記録の保存と読み込み（壊れた値でも落ちない）', () {
      const r = LessonRecord(
        lessonId: 'les',
        step: 3,
        viewed: true,
        quizAttempts: 2,
        quizBest: 4,
        quizLast: 3,
        quizPassedDay: 100,
        masteredDay: 101,
        understanding: 2,
        updatedDay: 102,
      );
      final back = LessonRecord.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
      expect(LessonRecord.fromJson({'id': 'x'}).quizLast, -1);
    });
  });

  group('範囲の網羅と学習計画', () {
    final other = [for (var i = 0; i < 3; i++) _q('z$i', 'no.such.unit')];
    final veg = [
      for (var i = 0; i < 6; i++)
        _q('v$i', 'science.biology.ecology.vegetation.biome'),
    ];

    test('教材の整備と、学習者の習得を別々に数える', () {
      final c = SubjectCoverage.build(
        questions: [...questions, ...veg, ...other],
        lessons: {_unit: _lesson()},
        records: const {},
        stats: const {},
      );
      expect(c.total, 3);
      expect(c.mapped, 2); // 「その他」は対応づいていない
      expect(c.withLesson, 1);
      expect(c.withPractice, 2); // その他は3問しかない
      expect(c.learned, 0);
      expect(c.mastered, 0);
      expect(c.missing.map((u) => u.name), containsAll(['その他']));
      expect(c.complete, isFalse);
    });

    test('すべて習得しても、教材が足りない単元があれば「完全攻略」にしない', () {
      final all = {
        for (final q in [...questions, ...veg]) q.id: [true],
      };
      final c = SubjectCoverage.build(
        questions: [...questions, ...veg],
        lessons: {_unit: _lesson()},
        records: {
          'les_$_unit': const LessonRecord(
            lessonId: 'les',
            viewed: true,
            quizLast: 5,
            quizPassedDay: 9,
          ),
        },
        stats: _stats(all, 10),
      );
      expect(c.mastered, 2);
      expect(c.complete, isFalse); // 植生には授業がない
      expect(c.missing.single.unitId, 'science.biology.ecology.vegetation');
    });

    test('要復習 → 授業の途中 → 未学習 の順に勧め、習得した単元は出さない', () {
      final c = SubjectCoverage.build(
        questions: [...questions, ...veg],
        lessons: {_unit: _lesson()},
        records: {
          'les_$_unit': const LessonRecord(
            lessonId: 'les',
            viewed: true,
            quizLast: 1,
          ),
        },
        stats: const {},
      );
      final plan = LessonPlanner.plan(c, daysLeft: 10);
      expect(plan.first.unit.state, LessonState.needsReview);
      expect(plan.last.unit.state, LessonState.notStarted);
      expect(LessonPlanner.perDay(c, 1), 2);
      expect(LessonPlanner.perDay(c, 10), 1);
      expect(
        LessonPlanner.daysUntil(
            DateTime(2026, 11, 3), DateTime(2026, 10, 30, 23)),
        4,
      );
    });

    test('演習モードは同じ学習記録から問題を選ぶ', () {
      final stats = _stats({
        'q0': [false],
        'q1': [true],
        'v0': [false],
      }, 10);
      final c = SubjectCoverage.build(
        questions: [...questions, ...veg],
        lessons: const {},
        records: const {},
        stats: stats,
      );
      expect(LessonPracticeMode.mistakes.pick(c), {'q0', 'v0'});
      expect(LessonPracticeMode.all.pick(c, random: Random(1)).length, 16);
      final fc = LessonPracticeMode.finalCheck.pick(c, random: Random(1));
      expect(fc, containsAll(['q0', 'v0']));
      expect(fc.length, lessThanOrEqualTo(20));
      expect(LessonPracticeMode.weak.pick(c), isEmpty);
    });
  });
}
