import 'dart:math';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('英語ワールドの問題データ', () {
    final areas1to15 =
        RpgCatalog.englishStages.where((s) => s.order <= 15).toList();

    for (final stage in areas1to15) {
      group('エリア${stage.order} ${stage.name}', () {
        final set = loadSet(stage.questionSetId);

        test('24問（意味10・品詞2・文法12）で自作', () {
          expect(set.questions.length, 24);
          expect(set.origin, QuestionOrigin.original);
          expect(set.setId, stage.questionSetId);
          int count(QuestionCategory c) =>
              set.questions.where((q) => q.category == c).length;
          expect(count(QuestionCategory.meaning), 10);
          expect(count(QuestionCategory.partOfSpeech), 2);
          expect(count(QuestionCategory.usage), 12);
        });

        test('文法テーマと単語レベルが設定されている', () {
          expect(stage.grammarTheme, isNotEmpty);
          expect(stage.vocabLevel, isNotEmpty);
        });

        test('全問に解説があり、語法問題には英文がある', () {
          for (final q in set.questions) {
            expect(q.explanation, isNotNull, reason: q.id);
            if (q.category == QuestionCategory.usage) {
              expect(q.sentence, isNotNull, reason: q.id);
              if (q.prompt.contains('(   )')) {
                expect(q.sentence, contains('(   )'), reason: q.id);
              }
            }
          }
        });

        test('JSON の往復で内容が変わらない', () {
          final again = QuestionSet.fromJson(set.toJson());
          expect(again.toJson(), set.toJson());
        });
      });
    }

    test('エリア16・17はエリア1〜15の全問題から出題する', () {
      final ids = [for (final s in areas1to15) s.questionSetId];
      for (final order in [16, 17]) {
        final stage = RpgCatalog.englishStages[order - 1];
        expect(stage.questionSetIds, ids);
        expect(loadStagePool(stage).questions.length, 15 * 24);
      }
    });

    for (final order in [18, 19]) {
      test('エリア$order は長文（本文3本・各5問）', () {
        final stage = RpgCatalog.englishStages[order - 1];
        final set = loadSet(stage.questionSetId);
        expect(set.origin, QuestionOrigin.original);
        expect(set.passages.length, 3);
        expect(set.questions.length, 15);
        for (final q in set.questions) {
          expect(q.category, QuestionCategory.reading);
          expect(q.passage, isNotNull);
          expect(q.explanation, isNotEmpty);
        }
        for (final p in set.passages) {
          expect(p.paragraphs.length, greaterThanOrEqualTo(3));
        }
        final again = QuestionSet.fromJson(set.toJson());
        expect(again.toJson(), set.toJson());
      });
    }

    test('長文の設問は本文ごとに順番どおり出題される', () {
      final set = loadSet('english_stage_18');
      final deck = QuestionDeck(set.questions, random: Random(4));
      final drawn = [for (var i = 0; i < 15; i++) deck.draw().source];
      for (var i = 0; i < 15; i += 5) {
        final block = drawn.sublist(i, i + 5);
        expect(block.map((q) => q.passage!.id).toSet().length, 1);
        final ids = block.map((q) => q.id).toList();
        expect(ids, [...ids]..sort());
      }
    });

    test('エリア20は RPG・長文・定期テストの海のすべてから出題する', () {
      final last = RpgCatalog.englishStages.last;
      expect(
          last.questionSetIds,
          containsAll([
            'english_stage_01',
            'english_stage_15',
            'english_stage_18',
            'english_stage_19'
          ]));
      expect(
          last.questionSetIds, containsAll(SeaCatalog.units.map((u) => u.id)));
      final pool = loadStagePool(last);
      expect(pool.origin, QuestionOrigin.original);
      expect(pool.questions.length, greaterThan(15 * 24 + 30));
    });

    final all = [
      for (final s in areas1to15) ...loadSet(s.questionSetId).questions,
    ];

    test('問題IDはワールド全体で重複しない', () {
      expect(all.map((q) => q.id).toSet().length, all.length);
    });

    test('同じ単語の意味を別エリアで重ねて聞いていない', () {
      final prompts = [
        for (final q in all)
          if (q.category == QuestionCategory.meaning) q.prompt,
      ];
      expect(prompts.toSet().length, prompts.length);
    });

    test('同じ英文を別エリアで重ねて出題していない', () {
      final keys = [
        for (final q in all)
          if (q.sentence != null) '${q.prompt}|${q.sentence}',
      ];
      expect(keys.toSet().length, keys.length);
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
