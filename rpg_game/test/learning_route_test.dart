import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

/// [unit] の問題を [n] 問、それぞれ [correct]/[attempts] で答えた記録
Map<String, QuestionStat> answered(
  String unit,
  int n, {
  required int correct,
  int attempts = 2,
  int profile = 0,
}) =>
    {
      for (var i = 0; i < n; i++)
        '$unit#$i': QuestionStat(
          setId: 'math_x',
          unit: unit,
          attempts: attempts,
          correct: correct,
          first: correct > 0 ? 1 : 2,
          profile: profile,
        ),
    };

QuizQuestion choice(String id, String unit,
        {int? tl, List<String> combines = const []}) =>
    QuizQuestion(
      id: id,
      category: QuestionCategory.calculation,
      prompt: 'Q$id',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      unit: unit,
      thinkingLevel: tl == null ? null : ThinkingLevel.of(tl),
      combines: combines,
    );

void main() {
  group('QuestionStat の新しい項目', () {
    test('問題の性質・間をあけた回答が保存され、古い形も読める', () {
      var s = const QuestionStat();
      s = s.record(
          isCorrect: true, day: 10, elapsedMs: 1000, setId: 'a', profile: 37);
      s = s.record(isCorrect: false, day: 11, elapsedMs: 1000);
      s = s.record(isCorrect: true, day: 15, elapsedMs: 1000);
      expect(s.profile, 37);
      expect(s.gapTried, 1, reason: '11日 → 15日だけが3日以上あいている');
      expect(s.gapCorrect, 1);
      final back = QuestionStat.fromList(s.toList());
      expect(back.profile, 37);
      expect(back.gapTried, 1);
      expect(back.gapCorrect, 1);
      expect(back.first, 1);
      // 古い形（10項目）
      final old = QuestionStat.fromList(['a', 1, 1, 1, 0, 5, 100, 1, 6, 0]);
      expect(old.profile, 0);
      expect(old.gapTried, 0);
      expect(
          const QuestionStat(setId: 'a', attempts: 1).toList(), hasLength(10));
    });

    test('AnswerProfile は1つの数にまとめて戻せる', () {
      for (final p in LearningPhase.values) {
        for (var t = 1; t <= 8; t++) {
          for (final novel in [true, false]) {
            final a = AnswerProfile(thinking: t, novel: novel, phase: p);
            final b = AnswerProfile.decode(a.code)!;
            expect((b.thinking, b.novel, b.phase), (t, novel, p));
          }
        }
      }
      expect(AnswerProfile.decode(0), isNull);
    });

    test('AnswerProfile.of は問題の思考レベルと段階を使う', () {
      final q = QuizQuestion(
        id: 'x',
        category: QuestionCategory.thinking,
        prompt: 'p',
        choices: const ['a', 'b', 'c', 'd'],
        thinkingLevel: ThinkingLevel.of(7),
        axes: const DifficultyAxes(novelty: 4),
        phase: LearningPhase.topUniv,
      );
      final a = AnswerProfile.of(q);
      expect(a.thinking, 7);
      expect(a.novel, isTrue);
      expect(a.applied, isTrue);
      expect(a.phase, LearningPhase.topUniv);
    });
  });

  group('成長の見える化', () {
    test('初見正答率・応用・初見・定着を数える', () {
      final applied = AnswerProfile(
              thinking: 5, novel: true, phase: LearningPhase.standardUniv)
          .code;
      final basic =
          AnswerProfile(thinking: 1, novel: false, phase: LearningPhase.basics)
              .code;
      final record = LearningRecord(stats: {
        'a': QuestionStat(
            setId: 'math_1',
            attempts: 4,
            correct: 3,
            first: 1,
            profile: applied,
            gapTried: 2,
            gapCorrect: 1),
        'b': QuestionStat(
            setId: 'math_1', attempts: 2, correct: 0, first: 2, profile: basic),
        'c': const QuestionStat(
            setId: 'english_1', attempts: 1, correct: 1, first: 1),
      });
      final g = GrowthReport.of(record, subject: 'math');
      expect(g.firstTry.tried, 2);
      expect(g.firstTry.percent, 50);
      expect(g.applied.tried, 4);
      expect(g.applied.percent, 75);
      expect(g.novel.percent, 75);
      expect(g.retention.tried, 2);
      expect(g.retention.percent, 50);
      expect(GrowthReport.of(record).firstTry.tried, 3);
    });

    test('段階のはしご：下から続けて到達した段の次がいまの段', () {
      int code(LearningPhase p) =>
          AnswerProfile(thinking: 2, novel: false, phase: p).code;
      final stats = <String, QuestionStat>{
        for (var i = 0; i < 10; i++)
          'b$i': QuestionStat(
              setId: 'math_1',
              attempts: 1,
              correct: 1,
              profile: code(LearningPhase.basics)),
        for (var i = 0; i < 10; i++)
          't$i': QuestionStat(
              setId: 'math_1',
              attempts: 2,
              correct: 1,
              profile: code(LearningPhase.teikiTest)),
      };
      final ladder = PhaseLadder.of(LearningRecord(stats: stats));
      expect(ladder.steps, hasLength(7));
      expect(ladder.steps[0].cleared, isTrue);
      expect(ladder.steps[1].cleared, isFalse, reason: '正答率50%');
      expect(ladder.clearedCount, 1);
      expect(ladder.current.phase, LearningPhase.teikiTest);
      expect(PhaseLadder.of(LearningRecord.empty).current.phase,
          LearningPhase.basics);
    });
  });

  group('学習ルート', () {
    test('前提の ID はすべて学習体系にある', () {
      for (final n in Curriculum.all) {
        for (final p in n.prerequisites) {
          expect(Curriculum.contains(p), isTrue, reason: '${n.id} → $p');
        }
      }
    });

    test('どの単元からさかのぼっても止まり、目標が最後にくる', () {
      final progress = CurriculumProgress.of(LearningRecord.empty);
      for (final n in Curriculum.all) {
        final r = LearningRoute.trace(n.id, progress);
        expect(r.steps.last.node.id, n.id);
        expect(
            r.steps.map((s) => s.node.id).toSet(), hasLength(r.steps.length));
      }
    });

    test('微分の応用が苦手で、2次関数のグラフも弱点なら、そこが根本の原因', () {
      final record = LearningRecord(stats: {
        ...answered('math.j1.s1.a05.main', 6, correct: 0),
        ...answered('math.j1.s1.a03.main', 6, correct: 2),
        ...answered('math.j1.s1.a02.main', 6, correct: 0),
        ...answered('math.j1.s1.a01.main', 6, correct: 2),
      });
      final progress = CurriculumProgress.of(record);
      final route = LearningRoute.trace('math.j1.s1.a05', progress);
      final ids = route.steps.map((s) => s.node.id).toList();
      expect(ids.last, 'math.j1.s1.a05');
      expect(ids,
          containsAll(['math.j1.s1.a03', 'math.j1.s1.a02', 'math.j1.s1.a01']));
      // 前提ほど前にくる
      expect(ids.indexOf('math.j1.s1.a01'),
          lessThan(ids.indexOf('math.j1.s1.a02')));
      expect(ids.indexOf('math.j1.s1.a02'),
          lessThan(ids.indexOf('math.j1.s1.a03')));
      expect(route.rootCause!.node.id, 'math.j1.s1.a02');
      expect(route.nextStep.node.id, 'math.j1.s1.a02');
      expect(route.target.status, RouteStatus.weak);
    });

    test('前提がすべてできていれば、目標そのものを学ぶ', () {
      final record = LearningRecord(stats: {
        ...answered('math.j1.s1.a05.main', 6, correct: 0),
        ...answered('math.j1.s1.a03.main', 6, correct: 2),
        ...answered('math.j1.s1.a02.main', 6, correct: 2),
        ...answered('math.j1.s1.a01.main', 6, correct: 2),
      });
      final route =
          LearningRoute.trace('math.j1.s1.a05', CurriculumProgress.of(record));
      expect(route.rootCause, isNull);
      expect(route.nextStep.node.id, 'math.j1.s1.a05');
      final weak = LearningRoute.forWeakUnits(CurriculumProgress.of(record),
          under: 'math');
      expect(weak.map((r) => r.target.node.id), contains('math.j1.s1.a05'));
    });
  });

  group('複合弱点', () {
    test('土台の弱点と、組み合わせの弱点を区別する', () {
      final record = LearningRecord(stats: {
        ...answered('math.j1.s1.a03.main', 6, correct: 2),
        ...answered('math.j1.s1.a02.main', 6, correct: 0),
      });
      final progress = CurriculumProgress.of(record);
      final qs = [
        choice('q1', 'math.j1.s1.a05.main', combines: ['math.j1.s1.a02']),
        choice('q2', 'math.j1.s1.a05.main', combines: ['math.j1.s1.a03']),
        choice('q3', 'math.j1.s1.a05.main', combines: ['math.j1.s1.a03']),
      ];
      final found =
          CompositeWeakness.find(qs, {'q1': 0, 'q2': 0.2, 'q3': 1}, progress);
      expect(found, hasLength(2));
      final graph = found.firstWhere((c) => c.combined == 'math.j1.s1.a02');
      expect(graph.foundationWeak, isTrue);
      expect(graph.advice, contains('先にこちら'));
      final diff = found.firstWhere((c) => c.combined == 'math.j1.s1.a03');
      expect(diff.tried, 2);
      expect(diff.missed, 1);
      expect(diff.foundationWeak, isFalse);
      expect(diff.advice, contains('組み合わせる'));
    });
  });

  group('総合演習', () {
    final sets = {
      'math_a': [
        for (var i = 0; i < 10; i++)
          choice('a$i', 'math.j1.s1.a02.main', tl: 1),
        for (var i = 0; i < 10; i++)
          choice('b$i', 'math.j1.s2.a07.main', tl: 3),
        for (var i = 0; i < 4; i++)
          choice('c$i', 'math.j2.s1.a03.main',
              tl: 6, combines: ['math.j1.s1.a03']),
      ],
    };

    test('3部構成で、配点と制限時間がつく', () {
      final paper = ExamPaper.build(subject: 'math', sets: sets, seed: 1);
      expect(paper.itemsOf(ExamSection.basic), hasLength(6));
      expect(paper.itemsOf(ExamSection.standard), hasLength(6));
      expect(paper.itemsOf(ExamSection.advanced), hasLength(2));
      expect(paper.totalPoints, 6 * 3 + 6 * 5 + 2 * 12);
      expect(paper.timeLimitSeconds, greaterThanOrEqualTo(300));
      expect(paper.timeLimitSeconds % 60, 0);
      // 同じ seed なら同じ問題
      expect(
        ExamPaper.build(subject: 'math', sets: sets, seed: 1)
            .items
            .map((i) => i.question.id),
        paper.items.map((i) => i.question.id),
      );
    });

    test('部分点をふくめて採点し、分野・思考の種類ごとに分析する', () {
      final paper = ExamPaper.build(subject: 'math', sets: sets, seed: 3);
      final grades = <int, Grade>{};
      for (var i = 0; i < paper.items.length; i++) {
        final s = paper.items[i].section;
        grades[i] = switch (s) {
          ExamSection.basic => Grade.right,
          ExamSection.standard => const Grade(credit: 0.5, correct: false),
          ExamSection.advanced => Grade.wrong,
        };
      }
      grades.remove(paper.items.length - 1); // 最後の1問は時間切れ
      final r = ExamResult(paper: paper, grades: grades, elapsedSeconds: 100);
      expect(r.earned, 6 * 3 + 6 * 5 * 0.5);
      expect(r.score, ((18 + 15) * 100 / 72).round());
      expect(r.unanswered, 1);
      expect(r.bySection.map((t) => t.percent), [100, 50, 0]);
      expect(r.byThinking.map((t) => t.label),
          containsAll(['知識確認', '標準適用', '難関大学']));
      expect(r.byField.length, 3);
      expect(r.weakestField!.label, contains('一次関数'));
      final comp = r.composites(CurriculumProgress.of(LearningRecord.empty));
      expect(comp.single.combined, 'math.j1.s1.a03');
      expect(comp.single.missed, 2);
    });

    test('候補の問題セットは、その教科のエリアの問題セットから選ぶ', () {
      final ids = ExamPaper.candidateSets('math', seed: 5);
      expect(ids, hasLength(12));
      expect(ids.every((id) => id.startsWith('math_')), isTrue);
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('ExamGrader', () {
      final q = choice('z', 'math.j1.s1.a02.main');
      expect(ExamGrader.choice(q, 0).correct, isTrue);
      expect(ExamGrader.choice(q, 1).credit, 0);
    });
  });
}
