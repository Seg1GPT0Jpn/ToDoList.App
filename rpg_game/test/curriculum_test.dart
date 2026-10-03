import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// 問題ファイルの教科（ワールド）→ 学習体系の教科
String curriculumSubjectOf(String world) => switch (world) {
      'sea' => 'english',
      _ => world,
    };

Iterable<File> questionFiles() => Directory('assets/questions')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'));

void main() {
  group('学習体系（教科→科目→分野→単元→小単元）', () {
    test('5教科・各階層が親より1段深い', () {
      expect(
        Curriculum.subjects.map((s) => s.id),
        ['english', 'math', 'japanese', 'science', 'social'],
      );
      for (final n in Curriculum.all) {
        for (final c in n.children) {
          expect(c.level.index, n.level.index + 1, reason: c.id);
          expect(c.parentId, n.id);
        }
        if (n.level == CurriculumLevel.unit) {
          expect(n.children, isNotEmpty, reason: '${n.id} に小単元がない');
        }
        expect(n.name.trim(), isNotEmpty);
      }
    });

    test('科目は学年の道（小1〜中3）', () {
      List<String> courses(String s) =>
          [for (final c in Curriculum.node(s).children) c.name];
      expect(courses('english'),
          ['小3・4', '小5', '小6', '中1', '中2', '中3', '中学の単語と熟語']);
      expect(courses('math'),
          ['小1', '小2', '小3', '小4', '小5', '小6', '中1', '中2', '中3']);
      expect(courses('japanese'),
          ['小1', '小2', '小3', '小4', '小5', '小6', '中1', '中2', '中3']);
      expect(courses('science'), ['小3', '小4', '小5', '小6', '中1', '中2', '中3']);
      expect(courses('social'), ['小3', '小4', '小5', '小6', '地理', '歴史', '公民']);
    });

    test('どの学年の道にも分野と単元がある', () {
      int count(String id, CurriculumLevel level) =>
          Curriculum.descendants(id).where((n) => n.level == level).length;
      for (final s in Curriculum.subjects) {
        for (final c in s.children) {
          expect(count(c.id, CurriculumLevel.field), greaterThanOrEqualTo(1),
              reason: c.id);
          expect(count(c.id, CurriculumLevel.unit), greaterThanOrEqualTo(4),
              reason: c.id);
        }
      }
    });

    test('前提はすべて存在し、出典は教科から受け継ぐ', () {
      for (final n in Curriculum.all) {
        for (final p in n.prerequisites) {
          expect(Curriculum.contains(p), isTrue, reason: '${n.id} → $p');
        }
        final (source, url) = Curriculum.sourceOf(n.id);
        expect(source, contains('学習指導要領'));
        expect(url, startsWith('https://'));
      }
      expect(Curriculum.prerequisitesOf('math.j1.s1.a03.main'),
          contains('math.j1.s1.a02'));
    });

    test('道すじ・学年・パンくず', () {
      const id = 'math.j3.s2.a07.main';
      expect(Curriculum.pathOf(id).map((n) => n.level), CurriculumLevel.values);
      expect(Curriculum.breadcrumb(id), '中3 ＞ 関数と図形 ＞ 円周角 ＞ 円周角');
      expect(Curriculum.gradeOf(id), '中3');
      expect(Curriculum.ancestorAt(id, CurriculumLevel.course)?.name, '中3');
      expect(Curriculum.tryNode('nope'), isNull);
    });
  });

  group('問題と学習体系の対応', () {
    test('すべての問題が、自分の教科の単元か小単元に属している', () {
      var total = 0;
      final used = <String>{};
      for (final f in questionFiles()) {
        final set = JsonQuestionSource.parse(f.readAsStringSync());
        final subject = curriculumSubjectOf(set.worldId);
        for (final q in set.questions) {
          total++;
          final unit = q.unit;
          expect(unit, isNotNull, reason: '${q.id} に unit がない');
          final node = Curriculum.tryNode(unit!);
          expect(node, isNotNull, reason: '${q.id}: $unit は学習体系にない');
          expect(node!.subjectId, subject, reason: q.id);
          expect(
            node.level,
            anyOf(CurriculumLevel.unit, CurriculumLevel.subUnit),
            reason: q.id,
          );
          used.add(unit);
        }
      }
      expect(total, greaterThan(4000));
      // 振り分けが一部の単元に偏っていない
      expect(used.length, greaterThan(300));
    });

    test('エリアの問題は、そのエリアの単元に固定されている', () {
      for (final w in RpgCatalog.worlds) {
        for (final s in w.stages) {
          final own = loadSet(s.questionSetIds.last);
          for (final q in own.questions) {
            expect(q.unitLocked, isTrue, reason: q.id);
            expect(q.unit, startsWith('${w.id}.${s.branch}.'), reason: q.id);
          }
        }
      }
    });
  });

  group('問題の新しい属性', () {
    test('JSON で読み書きできる（省略したときは書き出さない）', () {
      final q = QuizQuestion.fromJson({
        'id': 'x1',
        'unit': 'math.j3.s2.a07.main',
        'unitLocked': true,
        'category': 'thinking',
        'prompt': 'p',
        'choices': ['a', 'b', 'c', 'd'],
        'answerIndex': 0,
        'thinkingLevel': 8,
        'axes': {'thinking': 5, 'novelty': 4, 'time': 3},
        'sourceKind': 'officialStyle',
        'targetGrade': '3',
        'phase': 'todai',
        'estimatedSeconds': 900,
        'related': ['x0'],
        'combines': ['math.j3.s2.a08'],
        'steps': 5,
        'guidance': 1,
      });
      expect(q.thinkingLevel, ThinkingLevel.todai);
      expect(q.axes!.novelty, 4);
      expect(q.sourceKind, QuestionSourceKind.officialStyle);
      expect(q.phase, LearningPhase.todai);
      final back = QuizQuestion.fromJson(q.toJson());
      expect(back.toJson(), q.toJson());

      final plain = QuizQuestion.fromJson({
        'id': 'x2',
        'category': 'knowledge',
        'prompt': 'p',
        'choices': ['a', 'b', 'c', 'd'],
        'answerIndex': 0,
      });
      final json = plain.toJson();
      for (final k in [
        'unit',
        'thinkingLevel',
        'axes',
        'sourceKind',
        'phase'
      ]) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test('推定は控えめ：書かれていなければ思考レベル6以上にならない', () {
      for (final f in questionFiles()) {
        final set = JsonQuestionSource.parse(f.readAsStringSync());
        for (final q in set.questions) {
          final p = QuestionProfiler.of(q,
              fallbackDifficulty: Difficulty.challenge,
              sea: set.worldId == 'sea');
          if (q.thinkingLevel == null) {
            expect(p.thinking.number, lessThanOrEqualTo(6), reason: q.id);
            expect(p.estimated, isTrue);
          }
          for (final v in p.axes.toMap().values) {
            expect(v, inInclusiveRange(0, 5));
          }
          expect(p.estimatedSeconds, greaterThan(0));
        }
      }
    });

    test('書かれた値はそのまま使う', () {
      final q = QuizQuestion.fromJson({
        'id': 'x3',
        'unit': 'english.j3.s2.a08.main',
        'category': 'usage',
        'prompt': 'p',
        'choices': ['a', 'b', 'c', 'd'],
        'answerIndex': 0,
        'thinkingLevel': 7,
        'axes': {'reading': 4},
        'phase': 'topUniv',
      });
      final p = QuestionProfiler.of(q);
      expect(p.thinking, ThinkingLevel.problemSolving);
      expect(p.axes.reading, 4);
      expect(p.phase, LearningPhase.topUniv);
      expect(p.estimated, isFalse);
      expect(p.grade, '中3');
      expect(p.node?.name, '仮定法');
    });

    test('難易度と種類で推定が変わる', () {
      final calc = loadSet('math_j1_02').questions.first;
      final basic =
          QuestionProfiler.of(calc, fallbackDifficulty: Difficulty.basic);
      final adv =
          QuestionProfiler.of(calc, fallbackDifficulty: Difficulty.advanced);
      expect(adv.thinking.number, greaterThan(basic.thinking.number));
      expect(adv.axes.calculation, greaterThan(0));
      expect(basic.phase, LearningPhase.basics);
      expect(
          QuestionProfiler.of(calc, sea: true).phase, LearningPhase.teikiTest);
    });
  });

  group('学習記録の単元（マイグレーション）', () {
    test('古い形式の記録も読め、単元と初回の結果を保存できる', () {
      final old =
          QuestionStat.fromList(['math_j1_01', 3, 2, 1, 0, 10, 900, 2, 12, 0]);
      expect(old.unit, '');
      expect(old.firstTryCorrect, isNull);
      final fresh = const QuestionStat().record(
          isCorrect: false, day: 5, elapsedMs: 100, setId: 's', unit: 'u.x');
      expect(fresh.firstTryCorrect, isFalse);
      final again = fresh.record(isCorrect: true, day: 6, elapsedMs: 100);
      expect(again.firstTryCorrect, isFalse, reason: '初回の結果は変わらない');
      expect(again.unit, 'u.x');
      final back = QuestionStat.fromList(again.toList());
      expect(back.unit, 'u.x');
      expect(back.first, 2);
      expect(back.category, '');
    });

    test('単元が空の記録を補える', () {
      final record = LearningRecord.empty.recordAll([
        const AnswerEvent(
            questionId: 'q1', setId: 's', isCorrect: true, elapsedMs: 1),
        const AnswerEvent(
            questionId: 'q2',
            setId: 's',
            isCorrect: true,
            elapsedMs: 1,
            unit: 'keep'),
      ], day: 1);
      expect(record.missingUnits, ['q1']);
      final migrated = record.withUnits({'q1': 'a.b', 'q2': 'other'});
      expect(migrated['q1']!.unit, 'a.b');
      expect(migrated['q2']!.unit, 'keep');
      expect(migrated.missingUnits, isEmpty);
      expect(identical(migrated.withUnits({'q1': 'z'}), migrated), isTrue);
    });
  });

  group('学習体系ごとの進みぐあい', () {
    test('節の問題数と、問題セットの対応', () {
      expect(
          CurriculumProgress.questionCount('math'),
          [
            for (final c in Curriculum.node('math').children)
              CurriculumProgress.questionCount(c.id),
          ].reduce((a, b) => a + b));
      expect(CurriculumProgress.setsFor('math.j3.s2.a07'),
          contains('math_j3_07'));
    });

    test('答えた記録を、小単元から教科まで積み上げる', () {
      final record = LearningRecord.empty.recordAll([
        for (var i = 0; i < 6; i++)
          AnswerEvent(
              questionId: 'q$i',
              setId: 'math_j3_07',
              isCorrect: i.isEven,
              elapsedMs: 1,
              unit: 'math.j3.s2.a07.main'),
      ], day: 1);
      final p = CurriculumProgress.of(record);
      expect(p['math.j3.s2.a07.main'].answered, 6);
      expect(p['math.j3.s2'].answered, 6);
      expect(p['math'].accuracy, 50);
      expect(p['math'].firstTryAccuracy, 50);
      expect(p['science'].answered, 0);
      expect(p.weakest().single.node.id, 'math.j3.s2.a07');
    });
  });

  test('マイグレーション：古い記録の単元を問題ファイルと単語リストから補う', () async {
    final source = JsonQuestionSource((id) async {
      final f = File('assets/questions/${id.split('_').first}/$id.json');
      return f.existsSync() ? f.readAsStringSync() : null;
    });
    final first = loadSet('math_j3_07').questions.first;
    final old = LearningRecord.fromMap({
      'stats': {
        first.id: ['math_j3_07', 1, 1, 1, 0, 3, 100, 1, 4, 0],
        'words_j1_enToJa_3': [
          'words_j1_enToJa',
          1,
          0,
          0,
          1,
          3,
          100,
          1,
          4,
          0
        ],
        'leap_x': ['leap_book', 1, 1, 1, 0, 3, 100, 1, 4, 0],
      },
      'days': [3],
    });
    final migrated = await UnitMigration.run(old, source);
    expect(migrated[first.id]!.unit, first.unit);
    expect(migrated['words_j1_enToJa_3']!.unit,
        'english.vocab.words.j1.meaning');
    expect(migrated['leap_x']!.unit, '', reason: '読めないセットは飛ばす');
    expect(migrated.studyDays, {3});
  });
}
