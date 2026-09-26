import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('英語ステージ1の問題データ', () {
    final set = loadStage01();

    test('10〜15問あり、自作（original）である', () {
      expect(set.questions.length, inInclusiveRange(10, 15));
      expect(set.origin, QuestionOrigin.original);
      expect(set.worldId, RpgCatalog.englishWorldId);
    });

    test('品詞・意味・語法がすべて含まれる', () {
      final cats = set.questions.map((q) => q.category).toSet();
      expect(cats, containsAll(QuestionCategory.values));
    });

    test('全問に解説がある', () {
      for (final q in set.questions) {
        expect(q.explanation, isNotNull, reason: q.id);
      }
    });

    test('JSON の往復で内容が変わらない', () {
      final again = QuestionSet.fromJson(set.toJson());
      expect(again.toJson(), set.toJson());
    });

    test('ステージ1の setId がカタログと一致する', () {
      expect(set.setId, RpgCatalog.englishStages.first.questionSetId);
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
      expect(await source.load('english_stage_02'), isNull);
    });
  });
}
