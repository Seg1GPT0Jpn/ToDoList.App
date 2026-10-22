import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game/src/vocab/meaning_text.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('自信ベット', () {
    int hitWith(Confidence c) {
      final b = newBattle()..confidence = c;
      return b
          .answer(b.currentQuestion.correctIndex, elapsed: slow)
          .damageToEnemy;
    }

    int takenWith(Confidence c) {
      final b = newBattle()..confidence = c;
      return b.answer(wrongIndex(b), elapsed: slow).damageToPlayer;
    }

    test('自信ありは強く当たり、外すと痛い。あやふやは控えめ', () {
      expect(hitWith(Confidence.sure), greaterThan(hitWith(Confidence.normal)));
      expect(hitWith(Confidence.unsure), lessThan(hitWith(Confidence.normal)));
      expect(takenWith(Confidence.sure),
          greaterThan(takenWith(Confidence.normal)));
      expect(
          takenWith(Confidence.unsure), lessThan(takenWith(Confidence.normal)));
    });

    test('答えるたびに「ふつう」へ戻り、結果に残る', () {
      final b = newBattle()..confidence = Confidence.sure;
      final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      expect(r.confidence, Confidence.sure);
      expect(b.confidence, Confidence.normal);
    });

    test('あやふやで正解しても、定着とはみなさず翌日にもう一度', () {
      const s = QuestionStat();
      final sure = s.record(isCorrect: true, day: 10, elapsedMs: 3000);
      final lucky = s.record(
          isCorrect: true,
          day: 10,
          elapsedMs: 3000,
          confidence: Confidence.unsure);
      expect(lucky.streak, lessThanOrEqualTo(sure.streak));
      expect(lucky.dueDay, 11);
    });

    test('自信ありでまちがえた回数を数え、保存しても消えない', () {
      var s = const QuestionStat();
      s = s.record(
          isCorrect: false,
          day: 1,
          elapsedMs: 0,
          setId: 'x',
          confidence: Confidence.sure);
      s = s.record(isCorrect: false, day: 2, elapsedMs: 0);
      expect(s.sureMiss, 1);
      expect(QuestionStat.fromList(s.toList()).sureMiss, 1);
    });
  });

  group('まちがいの種類', () {
    test('数えて、いちばん多い種類を出す', () {
      final log = MistakeLog.empty
          .add('math', MistakeKind.careless, day: 100)
          .add('math', MistakeKind.careless, day: 101)
          .add('english', MistakeKind.unknown, day: 101);
      expect(log.counts()[MistakeKind.careless], 2);
      expect(log.counts(subject: 'english')[MistakeKind.unknown], 1);
      expect(log.top(), MistakeKind.careless);
      expect(log.top(since: 102), isNull);
    });

    test('古い記録は消え、保存して読みもどせる', () {
      final log = MistakeLog.empty
          .add('math', MistakeKind.misread, day: 1)
          .add('math', MistakeKind.confused, day: 200);
      expect(log.entries, hasLength(1));
      final back = MistakeLog.fromMap(log.toMap());
      expect(back.entries.single.$3, MistakeKind.confused);
    });
  });

  group('気軽な練習', () {
    LearningRecord rec(int day) => LearningRecord.empty.recordAll([
          for (var i = 0; i < 6; i++)
            AnswerEvent(
              questionId: 'q$i',
              setId: i.isEven ? 'math_stage_01' : 'math_stage_02',
              category: 'grammar',
              unit: i.isEven ? '式' : '関数',
              isCorrect: i != 0,
              elapsedMs: 3000,
            ),
        ], day: day);

    test('3日あいたら「おかえり」の復習を出す', () {
      final r = rec(100);
      expect(StudyBoost.daysAway(r, 102), 2);
      expect(StudyBoost.welcomeBack(r, 102), isEmpty);
      final items = StudyBoost.welcomeBack(r, 103);
      expect(items, hasLength(6));
      expect(items.first.questionId, 'q0');
    });

    test('1分だけは5問', () {
      expect(StudyBoost.oneMinute(rec(100), 100), hasLength(5));
    });

    test('まぜて練習は単元を交互に出す', () {
      final r = rec(100);
      expect(StudyBoost.mixSubjects(r), ['math']);
      final items = StudyBoost.mix(r, 'math', today: 100);
      expect(items, hasLength(6));
      for (var i = 1; i < items.length; i++) {
        expect(r.stats[items[i].questionId]!.unit,
            isNot(r.stats[items[i - 1].questionId]!.unit));
      }
      expect(StudyBoost.mix(r, 'english', today: 100), isEmpty);
    });

    test('週1ふりかえり：先週とくらべる', () {
      final now = DateTime(2026, 10, 19);
      expect(WeeklyReflection.of(StudyLog.empty, now), isNull);
      final log = StudyLog.empty
          .add('math',
              now: DateTime(2026, 10, 10),
              spent: const Duration(minutes: 10),
              answered: 5)
          .add('english',
              now: DateTime(2026, 10, 18),
              spent: const Duration(minutes: 25),
              answered: 10)
          .add('math',
              now: DateTime(2026, 10, 19),
              spent: const Duration(minutes: 5),
              answered: 3);
      final w = WeeklyReflection.of(log, now)!;
      expect(w.thisWeek.minutes, 30);
      expect(w.lastWeek.minutes, 10);
      expect(w.deltaMinutes, 20);
      expect(w.daysStudied, 2);
      expect(w.bestSubject, 'english');
    });
  });

  group('4択の意味', () {
    test('かっこの中では切らず、「(」だけ・閉じていないかっこの選択肢を作らない', () {
      expect(shortMeaningOf('[名] 時間(①時刻 ②期間)'), '時間(時刻 期間)');
      expect(shortMeaningOf('[動]（〈人〉に）①頼む（[名] 依頼）'), '（〈人〉に）頼む（[名] 依頼）');
      expect(shortMeaningOf('[動] (人)を[名]の状態にする'), '(人)を[名]の状態にする');
      expect(shortMeaningOf('[動] ①(～を)延期する ②遅らせる'), '(～を)延期する');
      expect(shortMeaningOf('[動] 主張する [名] 主張'), '主張する');
    });

    test('記号だけの意味は、まちがいの選択肢に出ない', () {
      expect(usableChoiceText('（'), isFalse);
      expect(usableChoiceText('～'), isFalse);
      expect(usableChoiceText('たまに'), isTrue);
    });
  });

  test('英語以外の単語帳（古文単語など）は、暗号化しても用語カードとして開く', () {
    const cards = [
      VocabCard(id: 'k1', term: 'おどろく', meaning: '①目を覚ます ②はっと気づく'),
    ];
    final data = VocabVault.seal('古文テスト', cards, 'pw', worldId: 'japanese');
    final o = VocabVault.open(data, 'pw')!;
    expect(o.worldId, 'japanese');
    final b = VocabBook(
      id: 'k',
      title: o.title,
      kind: VocabBookKind.protectedImport,
      worldId: o.worldId,
      cards: o.cards,
    );
    expect(b.isTerms, isTrue);
    expect(b.meaningOf(b.cards.first), '①目を覚ます ②はっと気づく');
    expect(VocabVault.open(VocabVault.seal('英', cards, 'pw'), 'pw')!.worldId,
        'english');
  });

  test('単語帳の名前・パスワードは、全角で入れても開ける', () {
    expect(VocabVault.fileName('古文テスト３３０'), VocabVault.fileName('古文テスト330'));
    expect(VocabVault.fileName('ＬＥＡＰ　'), VocabVault.fileName('leap'));
    const cards = [VocabCard(id: 'k1', term: 'あはれなり', meaning: 'しみじみと趣深い')];
    final data = VocabVault.seal('t', cards, 'abc1');
    expect(VocabVault.open(data, 'ａｂｃ１'), isNotNull);
  });

  test('鍵のかかった資料は、正しいパスワードの鍵でだけ画像に戻る', () {
    final page = [
      ...'RIFF'.codeUnits,
      0,
      0,
      0,
      0,
      ...'WEBP'.codeUnits,
      1,
      2,
      3
    ];
    final key = SchoolMaterials.keyFor('ｔｅｓｔ ＰＷ');
    final sealed = SchoolMaterials.seal(page, List.filled(16, 7), key: key);
    expect(SchoolMaterials.open(sealed), isNull);
    expect(SchoolMaterials.open(sealed, key: SchoolMaterials.keyFor('testpw')),
        page);
    final wrong =
        SchoolMaterials.open(sealed, key: SchoolMaterials.keyFor('x'));
    expect(SchoolMaterials.looksLikeImage(wrong!), isFalse);
    // 同梱した国語の資料も、ちがうパスワードでは開けない
    final m = SchoolMaterials.all.firstWhere((m) => m.locked);
    final raw = File('../rpg_game_app/${m.asset(1)}').readAsBytesSync();
    final tried = SchoolMaterials.open(raw, key: SchoolMaterials.keyFor('x'));
    expect(SchoolMaterials.looksLikeImage(tried!), isFalse);
  });
}
