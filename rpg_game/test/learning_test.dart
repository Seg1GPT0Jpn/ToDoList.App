import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

QuizQuestion q(String id) => QuizQuestion(
      id: id,
      category: QuestionCategory.knowledge,
      prompt: 'p$id',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
    );

void main() {
  group('問題ごとの記録（間隔反復）', () {
    test('正解するたびに箱が上がり、次の復習日が伸びる。まちがえると箱1に戻る', () {
      var s = const QuestionStat();
      s = s.record(isCorrect: true, day: 100, elapsedMs: 3000, setId: 'x');
      expect(s.box, 1);
      expect(s.dueDay, 101);
      s = s.record(isCorrect: true, day: 101, elapsedMs: 3000);
      expect(s.box, 2);
      expect(s.dueDay, 103);
      s = s.record(isCorrect: true, day: 103, elapsedMs: 3000);
      expect(s.mastered, isTrue);
      s = s.record(isCorrect: false, day: 107, elapsedMs: 9000);
      expect(s.box, 1);
      expect(s.missStreak, 1);
      expect(s.streak, 0);
      expect(s.dueDay, 108);
      expect(s.attempts, 4);
      expect(s.averageMs, 4500);
      expect(s.setId, 'x');
    });

    test('2回以上まちがえた問題を3回連続で正解すると「苦手克服」', () {
      var s = const QuestionStat();
      s = s.record(isCorrect: false, day: 1, elapsedMs: 0);
      s = s.record(isCorrect: false, day: 1, elapsedMs: 0);
      s = s.record(isCorrect: true, day: 2, elapsedMs: 0);
      s = s.record(isCorrect: true, day: 3, elapsedMs: 0);
      expect(s.overcome, isFalse);
      s = s.record(isCorrect: true, day: 5, elapsedMs: 0);
      expect(s.overcome, isTrue);
    });

    test('保存用の形に変換しても元にもどる', () {
      final s = const QuestionStat().record(
        isCorrect: true,
        day: 9,
        elapsedMs: 1234,
        setId: 'math_m1_01',
      );
      final back = QuestionStat.fromList(s.toList());
      expect(back.toList(), s.toList());
    });
  });

  group('学習記録', () {
    test('教科ごとの習得数・教科レベル・連続学習日数', () {
      var r = LearningRecord.empty;
      for (var d = 10; d <= 12; d++) {
        r = r.recordAll([
          for (var i = 0; i < 4; i++)
            AnswerEvent(
              questionId: 'm$i',
              setId: 'math_m1_01',
              isCorrect: true,
              elapsedMs: 1000,
            ),
          const AnswerEvent(
            questionId: 'e1',
            setId: 'sea_g1_01',
            isCorrect: true,
            elapsedMs: 1000,
          ),
        ], day: d);
      }
      expect(r.masteredCount('math'), 4);
      expect(r.masteredCount('english'), 1);
      expect(r.subjectLevel('math'), LearningRecord.levelFor(4));
      expect(r.streakDays(12), 3);
      expect(r.streakDays(13), 3);
      expect(r.streakDays(14), 0);
      final back = LearningRecord.fromMap(r.toMap());
      expect(back.masteredCount(), r.masteredCount());
      expect(back.studyDays, r.studyDays);
    });

    test('教科レベルは習得数とともに上がる', () {
      expect(LearningRecord.levelFor(0), 1);
      expect(LearningRecord.levelFor(2), 2);
      expect(LearningRecord.levelFor(8), 3);
      for (var lv = 2; lv < 10; lv++) {
        expect(
          LearningRecord.levelFor(LearningRecord.masteredForLevel(lv)),
          lv,
        );
      }
    });
  });

  group('復習の計画', () {
    test('まちがえた問題・期限が来た問題が優先され、習得済みで期限前の問題は選ばれない', () {
      final r = LearningRecord(
        stats: {
          'wrong': const QuestionStat().record(
            isCorrect: false,
            day: 50,
            elapsedMs: 5000,
            setId: 's1',
          ),
          'mastered': const QuestionStat(
            setId: 's1',
            attempts: 5,
            correct: 5,
            streak: 5,
            box: 5,
            lastDay: 49,
            dueDay: 70,
          ),
          'due': const QuestionStat(
            setId: 's2',
            attempts: 2,
            correct: 2,
            streak: 2,
            box: 2,
            lastDay: 40,
            dueDay: 45,
          ),
        },
      );
      final plan = ReviewPlanner.plan(r, today: 51);
      expect(plan.map((e) => e.questionId), ['wrong', 'due']);
      expect(plan.first.reason, 'まちがえた');
      expect(plan.last.reason, '復習の日');
    });
  });

  group('適応出題', () {
    test('苦手な問題ほど山札の早い位置に来やすい', () {
      final weak = q('weak');
      final others = [for (var i = 0; i < 9; i++) q('n$i')];
      final r = LearningRecord(
        stats: {
          'weak': const QuestionStat(
            attempts: 4,
            correct: 0,
            missStreak: 3,
            box: 1,
            lastDay: 1,
            dueDay: 2,
          ),
        },
      );
      final weight = AdaptiveWeights.forRecord(r, 10);
      var firstThree = 0;
      for (var seed = 0; seed < 300; seed++) {
        final deck = QuestionDeck(
          [weak, ...others],
          random: Random(seed),
          weight: weight,
        );
        final drawn = [for (var i = 0; i < 3; i++) deck.draw().source.id];
        if (drawn.contains('weak')) firstThree++;
      }
      // 重みなしなら約30%。苦手なら大きく上がる
      expect(firstThree / 300, greaterThan(0.6));
    });

    test('重みをつけても、すべての問題が1周で1回ずつ出る', () {
      final qs = [for (var i = 0; i < 12; i++) q('x$i')];
      final deck = QuestionDeck(
        qs,
        random: Random(3),
        weight: (q) => q.id == 'x0' ? 4 : 1,
      );
      final ids = {for (var i = 0; i < 12; i++) deck.draw().source.id};
      expect(ids.length, 12);
    });
  });

  group('問題データの拡張', () {
    test('difficulty・hint・tags・commonMistakes を読み書きできる（なくても読める）', () {
      final json = {
        'id': 'a',
        'category': 'calculation',
        'prompt': 'p',
        'choices': ['1', '2', '3', '4'],
        'answerIndex': 0,
        'difficulty': 'advanced',
        'hint': 'h',
        'tags': ['2次関数'],
        'commonMistakes': ['軸を見落とす'],
      };
      final qq = QuizQuestion.fromJson(json);
      expect(qq.difficulty, Difficulty.advanced);
      expect(qq.hint, 'h');
      expect(qq.tags, ['2次関数']);
      expect(QuizQuestion.fromJson(qq.toJson()).commonMistakes, ['軸を見落とす']);
      final plain = QuizQuestion.fromJson({...json}
        ..remove('difficulty')
        ..remove('hint')
        ..remove('tags')
        ..remove('commonMistakes'));
      expect(plain.difficulty, isNull);
      expect(plain.tags, isEmpty);
    });

    test('数学のエリアは名前から難易度が分かる', () {
      final stages = RpgCatalog.world('math').stages;
      expect(stages.first.difficulty, Difficulty.basic);
      expect(stages[1].difficulty, Difficulty.standard);
      expect(stages[2].difficulty, Difficulty.advanced);
    });
  });

  group('復習の塔', () {
    test('正解数で階が上がり、5階ごとに番人が出る', () {
      expect(ReviewTower.floorOf(0), 1);
      expect(ReviewTower.floorOf(25), 3);
      final s = ReviewTower.stage(
        level: 5,
        floor: 5,
        questionCount: 10,
        worldId: 'english',
      );
      expect(s.isBoss, isTrue);
      final p = PlayerStats.forLevel(5);
      // 8問正解で倒せる
      expect(s.enemy.maxHp, p.attack * 8);
      // 5回まちがえると倒れる
      expect(
          (s.enemy.attack - p.defense / 2) * 5, greaterThanOrEqualTo(p.maxHp));
      expect(
          EnemySpeciesCatalog.all.map((e) => e.look), contains(s.enemy.look));
    });
  });
}
