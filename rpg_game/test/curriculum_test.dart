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
    test('7教科・各階層が親より1段深い', () {
      expect(
        Curriculum.subjects.map((s) => s.id),
        [
          'english',
          'science',
          'social',
          'japanese',
          'math',
          'information',
          'music'
        ],
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

    test('科目は指示書のとおり（英語1・数学6・理科4・国語3・社会5・情報1）', () {
      List<String> courses(String s) =>
          [for (final c in Curriculum.node(s).children) c.name];
      expect(courses('english'), ['英語']);
      expect(courses('math'), ['数学Ⅰ', '数学A', '数学Ⅱ', '数学B', '数学C', '数学Ⅲ']);
      expect(courses('science'), ['物理', '化学', '生物', '地学']);
      expect(courses('japanese'), ['現代文', '古文', '漢文']);
      expect(courses('social'), ['地理', '日本史', '世界史', '政治・経済', '倫理']);
      expect(courses('information'), ['情報']);
    });

    test('理科・社会は細かく分かれている', () {
      int count(String id, CurriculumLevel level) =>
          Curriculum.descendants(id).where((n) => n.level == level).length;
      for (final c in Curriculum.node('science').children) {
        expect(count(c.id, CurriculumLevel.unit), greaterThanOrEqualTo(10),
            reason: c.name);
        expect(count(c.id, CurriculumLevel.subUnit), greaterThanOrEqualTo(40),
            reason: c.name);
      }
      for (final c in Curriculum.node('social').children) {
        expect(count(c.id, CurriculumLevel.subUnit), greaterThanOrEqualTo(25),
            reason: c.name);
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
      expect(Curriculum.prerequisitesOf('math.m2.calculus.diff.derivative'),
          contains('math.m1.quad.graph'));
    });

    test('道すじ・学年・パンくず', () {
      const id = 'math.m1.quad.maxmin.param';
      expect(Curriculum.pathOf(id).map((n) => n.level), CurriculumLevel.values);
      expect(Curriculum.breadcrumb(id), '数学Ⅰ ＞ 2次関数 ＞ 2次関数の最大・最小 ＞ 文字を含む場合分け');
      expect(Curriculum.gradeOf(id), '1');
      expect(Curriculum.ancestorAt(id, CurriculumLevel.course)?.name, '数学Ⅰ');
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
      expect(total, greaterThan(9000));
      // 振り分けが一部の単元に偏っていない
      expect(used.length, greaterThan(600));
    });

    test('数学の単元は「基本・標準・応用」のエリアの範囲から外れない', () {
      final set = loadSet('math_m2_16');
      for (final q in set.questions) {
        expect(q.unit, startsWith('math.m2.calculus.'), reason: q.id);
      }
    });
  });

  group('問題の新しい属性', () {
    test('JSON で読み書きできる（省略したときは書き出さない）', () {
      final q = QuizQuestion.fromJson({
        'id': 'x1',
        'unit': 'math.m1.quad.maxmin.param',
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
        'combines': ['math.m1.trig.solve'],
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
        'unit': 'english.eng.grammar.subjunctive.past',
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
      expect(p.grade, '2');
      expect(p.node?.name, '仮定法過去');
    });

    test('難易度と種類で推定が変わる', () {
      final calc = loadSet('math_m1_03').questions.first;
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
          QuestionStat.fromList(['math_m1_01', 3, 2, 1, 0, 10, 900, 2, 12, 0]);
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
          CurriculumProgress.questionCount('math.m1') +
              CurriculumProgress.questionCount('math.ma') +
              CurriculumProgress.questionCount('math.m2') +
              CurriculumProgress.questionCount('math.mb') +
              CurriculumProgress.questionCount('math.mc') +
              CurriculumProgress.questionCount('math.m3'));
      expect(CurriculumProgress.setsFor('math.m1.quad.maxmin'),
          contains('math_m1_10'));
    });

    test('答えた記録を、小単元から教科まで積み上げる', () {
      final record = LearningRecord.empty.recordAll([
        for (var i = 0; i < 6; i++)
          AnswerEvent(
              questionId: 'q$i',
              setId: 'math_m1_10',
              isCorrect: i.isEven,
              elapsedMs: 1,
              unit: 'math.m1.quad.maxmin.param'),
      ], day: 1);
      final p = CurriculumProgress.of(record);
      expect(p['math.m1.quad.maxmin.param'].answered, 6);
      expect(p['math.m1.quad'].answered, 6);
      expect(p['math'].accuracy, 50);
      expect(p['math'].firstTryAccuracy, 50);
      expect(p['science'].answered, 0);
      expect(p.weakest().single.node.id, 'math.m1.quad.maxmin');
    });
  });

  test('マイグレーション：古い記録の単元を問題ファイルと単語リストから補う', () async {
    final source = JsonQuestionSource((id) async {
      final f = File('assets/questions/${id.split('_').first}/$id.json');
      return f.existsSync() ? f.readAsStringSync() : null;
    });
    final first = loadSet('math_m1_10').questions.first;
    final old = LearningRecord.fromMap({
      'stats': {
        first.id: ['math_m1_10', 1, 1, 1, 0, 3, 100, 1, 4, 0],
        'words_basic_enToJa_3': [
          'words_basic_enToJa',
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
    expect(migrated['words_basic_enToJa_3']!.unit,
        'english.eng.vocab.basic.meaning');
    expect(migrated['leap_x']!.unit, '', reason: '読めないセットは飛ばす');
    expect(migrated.studyDays, {3});
  });
}
