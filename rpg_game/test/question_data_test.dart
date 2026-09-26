import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('英語ワールドの問題データ', () {
    for (final stage in RpgCatalog.englishStages) {
      group(stage.name, () {
        final set = loadSet(stage.questionSetId);

        test('20〜30問あり、自作（original）である', () {
          expect(set.questions.length, inInclusiveRange(20, 30));
          expect(set.origin, QuestionOrigin.original);
          expect(set.worldId, RpgCatalog.englishWorldId);
          expect(set.setId, stage.questionSetId);
        });

        test('文法テーマと単語レベルが設定されている', () {
          expect(stage.grammarTheme, isNotEmpty);
          expect(stage.vocabLevel, isNotEmpty);
        });

        test('品詞・意味・語法がすべて含まれる', () {
          final cats = set.questions.map((q) => q.category).toSet();
          expect(cats, containsAll(QuestionCategory.values));
        });

        test('全問に解説があり、語法問題には英文がある', () {
          for (final q in set.questions) {
            expect(q.explanation, isNotNull, reason: q.id);
            if (q.category == QuestionCategory.usage) {
              expect(q.sentence, contains('(   )'), reason: q.id);
            }
          }
        });

        test('JSON の往復で内容が変わらない', () {
          final again = QuestionSet.fromJson(set.toJson());
          expect(again.toJson(), set.toJson());
        });
      });
    }

    final all = [
      for (final s in RpgCatalog.englishStages)
        ...loadSet(s.questionSetId).questions,
    ];

    test('問題IDはワールド全体で重複しない', () {
      expect(all.map((q) => q.id).toSet().length, all.length);
    });

    test('同じ単語の意味を別ステージで重ねて聞いていない', () {
      final prompts = [
        for (final q in all)
          if (q.category == QuestionCategory.meaning) q.prompt,
      ];
      expect(prompts.toSet().length, prompts.length);
    });

    test('同じ英文を重ねて出題していない', () {
      final sentences = [
        for (final q in all)
          if (q.sentence != null) q.sentence,
      ];
      expect(sentences.toSet().length, sentences.length);
    });
  });

  group('著作権ガード', () {
    test('origin が original / userCreated 以外のデータは読み込めない', () {
      for (final origin in ['leap', 'step', 'imported', 'commercial']) {
        expect(
          () => QuestionSet.fromJson({
            ...loadStage01().toJson(),
            'origin': origin,
          }),
          throwsFormatException,
          reason: origin,
        );
      }
    });

    test('アセット内に市販教材の名前が混入していない', () {
      final dir = Directory('assets/questions');
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        // 英単語の leap / step と区別するため、大文字の教材名だけを見る
        final text = f.readAsStringSync();
        expect(text, isNot(matches(RegExp(r'\b(LEAP|STEP)\b'))),
            reason: f.path);
      }
    });
  });

  group('QuizQuestion の検証', () {
    test('選択肢が4つでないとエラー', () {
      expect(
        () => QuizQuestion(
          id: 'x',
          category: QuestionCategory.meaning,
          prompt: 'p',
          choices: const ['a', 'b', 'c'],
          answerIndex: 0,
        ),
        throwsArgumentError,
      );
    });

    test('選択肢の重複はエラー', () {
      expect(
        () => QuizQuestion(
          id: 'x',
          category: QuestionCategory.meaning,
          prompt: 'p',
          choices: const ['a', 'b', 'c', 'a'],
          answerIndex: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('JsonQuestionSource', () {
    test('未作成の問題セットは null', () async {
      final source = JsonQuestionSource((id) async {
        final f = File('assets/questions/english/$id.json');
        return f.existsSync() ? f.readAsStringSync() : null;
      });
      expect(await source.load('english_stage_01'), isNotNull);
      expect(await source.load('english_stage_99'), isNull);
    });
  });
}
