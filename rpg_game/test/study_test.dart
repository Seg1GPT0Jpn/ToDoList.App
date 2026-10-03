import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

QuestionSet loadSea(String id) => JsonQuestionSource.parse(
    File('assets/questions/sea/$id.json').readAsStringSync());

WordList loadWords(String id) => WordList.fromJson(
    jsonDecode(File('assets/words/$id.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  group('定期テストの海：文法単元', () {
    test('中1〜中3の単元がそろっている', () {
      expect(SeaCatalog.unitsOf(1).length, 8);
      expect(SeaCatalog.unitsOf(2).length, 8);
      expect(SeaCatalog.unitsOf(3).length, 7);
    });

    for (final unit in SeaCatalog.units) {
      test('${unit.id} ${unit.title}: 自作の問題が6問以上あり、解説つき', () {
        final set = loadSea(unit.id);
        expect(set.setId, unit.id);
        expect(set.origin, QuestionOrigin.original);
        expect(set.questions.length, greaterThanOrEqualTo(6));
        for (final q in set.questions) {
          expect(q.explanation, isNotEmpty, reason: q.id);
          if (q.category == QuestionCategory.usage &&
              q.prompt.contains('(   )')) {
            expect(q.sentence, contains('(   )'), reason: q.id);
          }
        }
        expect(unit.topics, isNotEmpty);
      });
    }

    test('同じ英文を別の単元で重ねて出題していない', () {
      final all = [
        for (final u in SeaCatalog.units) ...loadSea(u.id).questions,
      ];
      final keys = all
          .map((q) => '${q.prompt}|${q.sentence}|${q.choices[q.answerIndex]}')
          .toList();
      expect(keys.toSet().length, keys.length);
    });
  });

  group('定期テストの海：単語帳', () {
    for (final book in SeaCatalog.wordBooks) {
      test('${book.title}: 自作・4択が作れる', () {
        final list = loadWords(book.id);
        expect(list.listId, book.id);
        expect(list.origin, QuestionOrigin.original);
        expect(list.words.length, greaterThanOrEqualTo(40));
        for (final dir in WordQuizDirection.values) {
          final set =
              WordQuizBuilder(random: Random(1)).build(list, direction: dir);
          expect(set.questions.length, list.words.length);
          for (final q in set.questions) {
            expect(q.choices.toSet().length, 4);
          }
        }
      });
    }
  });

  group('貼り付けた単語リストの読み取り', () {
    const pasted = '1\tsample\t[名] ①見本 ②試供品\n'
        '2\tpractice\t[他] ①～を練習する [名] ②練習\n'
        '\n'
        '3\tquiet\t[形] 静かな\n'
        'これは読めない行\n'
        '4 bright [形] ①明るい ②賢い\n'
        '5\tcarry\t[他] ～を運ぶ\n';

    test('番号・英語・意味を読み取り、読めない行は飛ばす', () {
      final skipped = <int>[];
      final list = WordList.parsePasted(
          listId: 'my', title: 'テスト', text: pasted, skipped: skipped);
      expect(list.words.map((w) => w.term),
          ['sample', 'practice', 'quiet', 'bright', 'carry']);
      expect(list.words.first.number, 1);
      expect(skipped, [5]);
      expect(list.origin, QuestionOrigin.personalImport);
    });

    test('4択用の短い意味は最初の品詞・最初の語義だけ', () {
      final list =
          WordList.parsePasted(listId: 'my', title: 'テスト', text: pasted);
      expect(list.words[0].shortMeaning, '見本');
      expect(list.words[0].partOfSpeech, '名');
      expect(list.words[1].shortMeaning, '～を練習する');
      expect(list.words[2].shortMeaning, '静かな');
      expect(list.words[3].shortMeaning, '明るい');
    });

    test('取り込んだ単語帳の問題は RPG では使えない', () {
      final list =
          WordList.parsePasted(listId: 'my', title: 'テスト', text: pasted);
      final set = WordQuizBuilder(random: Random(2))
          .build(list, direction: WordQuizDirection.enToJa);
      expect(set.origin, QuestionOrigin.personalImport);
      expect(set.origin.usableInRpg, isFalse);
      expect(QuestionOrigin.original.usableInRpg, isTrue);
    });
  });

  group('同梱データの出どころ', () {
    test('アプリ同梱の問題・単語帳はすべて自作（personalImport を含まない）', () {
      for (final f in Directory('assets')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        if (f.path.contains('question_bundles')) {
          // 教科ごとのまとめファイル：中の問題セットを1つずつ確かめる
          expect(json, isNotEmpty, reason: f.path);
          for (final e in json.entries) {
            expect(
              (e.value as Map)['origin'],
              'original',
              reason: '${f.path} の ${e.key}',
            );
          }
          continue;
        }
        expect(json['origin'], 'original', reason: f.path);
      }
    });
  });

  group('PracticeSession', () {
    final qs = loadSea('sea_g1_01').questions;

    test('指定数だけ出題し、正答率と間違いを集計する', () {
      final s = PracticeSession(qs, count: 5, random: Random(3));
      expect(s.total, 5);
      var i = 0;
      while (!s.isFinished) {
        final q = s.current;
        s.answer(i.isEven ? q.correctIndex : (q.correctIndex + 1) % 4);
        i++;
      }
      expect(s.correctCount, 3);
      expect(s.percent, 60);
      expect(s.missed.length, 2);
      expect(() => s.answer(0), throwsStateError);
    });
  });

  group('宿の授業', () {
    test('書いた授業は実在するステージのもので、要点が1つ以上ある', () {
      expect(JuniorLessons.all, isNotEmpty);
      for (final lesson in JuniorLessons.all) {
        expect(RpgCatalog.stage(lesson.stageId).id, lesson.stageId);
        expect(lesson.points, isNotEmpty, reason: lesson.stageId);
        expect(InnLessons.forStage(lesson.stageId), same(lesson));
      }
    });

    test('授業を書いていないステージは、要点なし（アプリが問題から作る）', () {
      final written = {for (final l in JuniorLessons.all) l.stageId};
      for (final w in RpgCatalog.worlds) {
        for (final s in w.stages.where((s) => !written.contains(s.id))) {
          final lesson = InnLessons.forStage(s.id);
          expect(lesson.points, isEmpty);
          expect(lesson.title, s.grammarTheme);
        }
      }
    });

    test('練習の経験値は正解1問につき2', () {
      final r = Progression.applyTraining(RpgProgress.initial, 5);
      expect(r.expGained, 10);
    });

    test('定期テストの海は最高正答率だけ残す', () {
      var p = Progression.recordSea(RpgProgress.initial, 'sea_g1_01', 60);
      p = Progression.recordSea(p, 'sea_g1_01', 40);
      expect(p.seaBest['sea_g1_01'], 60);
      p = Progression.recordSea(p, 'sea_g1_01', 90);
      expect(RpgProgress.fromMap(p.toMap()).seaBest['sea_g1_01'], 90);
    });
  });
}
