import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('追加問題のセットがすべて読み込めて、図の形式も正しい', () {
    final ids = <String>{};
    for (final s in ExtraSets.all) {
      final f = File('assets/questions/${s.subject}/${s.id}.json');
      final set = JsonQuestionSource.parse(f.readAsStringSync());
      expect(set.setId, s.id);
      expect(set.questions, isNotEmpty, reason: s.id);
      for (final q in set.questions) {
        expect(ids.add(q.id), isTrue, reason: q.id);
        expect(q.explanation, isNotEmpty, reason: q.id);
        if (q.figure != null) {
          expect(FigureSpec.problems(q.figure!), isEmpty, reason: q.id);
        }
        if (q.listen) expect(q.sentence, isNotNull, reason: q.id);
        // 入力問題は、正解の選択肢そのものを入力すれば正解になる
        if (q.isInput) expect(q.matchesInput(q.answer), isTrue, reason: q.id);
      }
    }
  });

  test('番外編・音楽の虹：4つの道・30エリア以上、各エリア15問以上', () {
    final w = RpgCatalog.world('music');
    expect(w.isFree, isTrue);
    expect(w.routes, hasLength(4));
    expect(w.stages.length, greaterThanOrEqualTo(30));
    for (final s in w.stages) {
      final f = File('assets/questions/music/${s.questionSetIds.last}.json');
      final set = JsonQuestionSource.parse(f.readAsStringSync());
      expect(set.questions.length, greaterThanOrEqualTo(15), reason: s.id);
    }
  });

  test('番外編・資格の塔：宅建の道は4分野・16エリア、各エリア15問。正解の位置がかたよらない', () {
    final w = RpgCatalog.world('shikaku');
    expect(w.isFree, isTrue);
    final takken = w.stages.where((s) => s.branch == 'takken').toList();
    expect(takken, hasLength(16));
    expect({for (final s in takken) s.region},
        {'権利関係', '宅建業法', '法令上の制限', '税・その他'});
    final pos = List.filled(4, 0);
    final prompts = <String>{};
    for (final s in takken) {
      final f = File('assets/questions/shikaku/${s.questionSetIds.last}.json');
      final set = JsonQuestionSource.parse(f.readAsStringSync());
      expect(set.questions.length, 15, reason: s.id);
      for (final q in set.questions) {
        expect(q.unit, startsWith('shikaku.takken.'), reason: q.id);
        expect(Curriculum.contains(q.unit!), isTrue, reason: q.id);
        expect(q.choices.toSet(), hasLength(4), reason: q.id);
        expect(prompts.add(q.prompt), isTrue, reason: '同じ問題文: ${q.id}');
        pos[q.answerIndex]++;
      }
    }
    for (final n in pos) {
      expect(n, inInclusiveRange(55, 65));
    }
  });

  test('入力の答えは全角・半角・大文字小文字・空白の違いを無視する', () {
    final q = QuizQuestion(
      id: 'x',
      category: QuestionCategory.calculation,
      prompt: 'p',
      choices: const ['-12', '1', '2', '3'],
      answerIndex: 0,
      accepted: const ['マイナス12'],
    );
    expect(q.matchesInput('−１２'), isTrue);
    expect(q.matchesInput(' -12 '), isTrue);
    expect(q.matchesInput('マイナス12'), isTrue);
    expect(q.matchesInput('12'), isFalse);
    expect(q.matchesInput(''), isFalse);
    expect(QuizQuestion.normalizeAnswer('Photosynthesis.'), 'photosynthesis');
  });

  test('図の形式チェック', () {
    expect(
      FigureSpec.problems({
        'chart': 'bar',
        'labels': ['a', 'b'],
        'values': [1, 2],
      }),
      isEmpty,
    );
    expect(
      FigureSpec.problems({
        'chart': 'line',
        'labels': ['a', 'b'],
        'series': [
          {
            'name': 's',
            'values': [1]
          },
        ],
      }),
      isNotEmpty,
    );
    expect(
      FigureSpec.problems({
        'w': 10,
        'h': 10,
        'items': [
          {
            'line': [0, 0, 1]
          },
        ],
      }),
      isNotEmpty,
    );
  });

  test('学習レポートの文章が作れる', () {
    final r = const LearningRecord().recordAll([
      const AnswerEvent(
        questionId: 'q1',
        setId: 'math_m1_01',
        isCorrect: true,
        elapsedMs: 3000,
      ),
    ], day: 100);
    final text = StudyReport.text(r, 100, name: 'かず');
    expect(text, contains('学習レポート（かず）'));
    expect(text, contains('数学：1問'));
  });
}
