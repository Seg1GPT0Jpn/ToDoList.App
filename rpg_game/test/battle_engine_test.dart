import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('DamageCalculator', () {
    final calc = fixedDamage();
    const limit = Duration(seconds: 20);

    test('通常の正解は攻撃力そのまま', () {
      expect(
          calc.playerAttack(
              attack: 10, combo: 1, elapsed: slow, timeLimit: limit),
          10);
    });

    test('連続正解で10%ずつ上がり、上限は+50%', () {
      expect(
          calc.playerAttack(
              attack: 10, combo: 3, elapsed: slow, timeLimit: limit),
          12);
      expect(
          calc.playerAttack(
              attack: 10, combo: 99, elapsed: slow, timeLimit: limit),
          15);
    });

    test('制限時間の1/3以内の回答で+20%', () {
      expect(
          calc.playerAttack(
              attack: 10, combo: 1, elapsed: fast, timeLimit: limit),
          12);
    });

    test('敵の攻撃は 攻撃力 - 防御/2、最低1', () {
      expect(calc.enemyAttack(attack: 8, defense: 2), 7);
      expect(calc.enemyAttack(attack: 1, defense: 50), 1);
    });

    test('ブレは ±10% に収まる', () {
      final c = DamageCalculator(random: Random(7));
      for (var i = 0; i < 500; i++) {
        final d = c.playerAttack(
            attack: 100, combo: 1, elapsed: slow, timeLimit: limit);
        expect(d, inInclusiveRange(90, 110));
      }
    });
  });

  group('QuestionDeck', () {
    final questions = loadStage01().questions;

    test('1周するまで同じ問題は出ない', () {
      final deck = QuestionDeck(questions, random: Random(3));
      final ids = {
        for (var i = 0; i < questions.length; i++) deck.draw().source.id
      };
      expect(ids.length, questions.length);
    });

    test('周の切れ目で同じ問題が連続しない', () {
      final deck = QuestionDeck(questions, random: Random(5));
      String? prev;
      for (var i = 0; i < questions.length * 20; i++) {
        final id = deck.draw().source.id;
        expect(id, isNot(prev));
        prev = id;
      }
    });

    test('選択肢をシャッフルしても正解の位置が正しい', () {
      final deck = QuestionDeck(questions, random: Random(9));
      for (var i = 0; i < 100; i++) {
        final p = deck.draw();
        expect(p.choices[p.correctIndex], p.source.answer);
        expect(p.choices.toSet(), p.source.choices.toSet());
      }
    });

    test('問題がないとエラー', () {
      expect(() => QuestionDeck(const []), throwsArgumentError);
    });
  });

  group('BattleEngine', () {
    test('正解で敵にダメージ、プレイヤーは無傷', () {
      final b = newBattle();
      final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      expect(r.correct, isTrue);
      expect(r.damageToEnemy, 10);
      expect(b.enemyHp, 30);
      expect(b.playerHp, 50);
      expect(b.combo, 1);
    });

    test('不正解で敵の反撃を受け、コンボが途切れる', () {
      final b = newBattle();
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      final r = b.answer(wrongIndex(b), elapsed: slow);
      expect(r.correct, isFalse);
      expect(r.damageToPlayer, 7);
      expect(b.playerHp, 43);
      expect(b.combo, 0);
    });

    test('時間切れは不正解扱い', () {
      final b = newBattle();
      final r = b.timeout();
      expect(r.timedOut, isTrue);
      expect(r.correct, isFalse);
      expect(b.playerHp, 43);
    });

    test('制限時間を過ぎた回答は正解でも時間切れ扱い', () {
      final b = newBattle();
      final r = b.answer(b.currentQuestion.correctIndex,
          elapsed: const Duration(seconds: 21));
      expect(r.timedOut, isTrue);
      expect(b.enemyHp, 40);
    });

    test('全問正解（ゆっくり）で4ターンで勝利: 10+11+12+13', () {
      final b = newBattle();
      while (!b.isOver) {
        b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      }
      expect(b.phase, BattlePhase.won);
      final s = b.summary();
      expect(s.answeredCount, 4);
      expect(s.isPerfect, isTrue);
      expect(s.maxCombo, 4);
      expect(s.remainingHp, 50);
    });

    test('全問不正解で敗北し、間違えた問題が復習リストに入る', () {
      final b = newBattle();
      while (!b.isOver) {
        b.answer(wrongIndex(b), elapsed: slow);
      }
      expect(b.phase, BattlePhase.lost);
      final s = b.summary();
      expect(s.won, isFalse);
      expect(b.playerHp, 0);
      expect(s.answeredCount, 8); // 50 / 7 → 8ターン
      expect(s.missedQuestions.length, 8);
    });

    test('終了後に回答するとエラー', () {
      final b = newBattle();
      while (!b.isOver) {
        b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      }
      expect(() => b.answer(0, elapsed: slow), throwsStateError);
      expect(b.timeout, throwsStateError);
    });

    test('範囲外の選択肢はエラー', () {
      final b = newBattle();
      expect(() => b.answer(4, elapsed: slow), throwsRangeError);
    });

    test('推奨レベル・正答率7割なら各ステージにおおむね勝てる', () {
      for (final stage in RpgCatalog.englishStages) {
        var wins = 0;
        for (var seed = 0; seed < 50; seed++) {
          final rnd = Random(seed);
          final b = BattleEngine(
            player: PlayerStats.forLevel(stage.recommendedLevel),
            enemy: stage.enemy,
            questions: loadSet(stage.questionSetId).questions,
            timeLimit: Duration(seconds: stage.timeLimitSeconds),
            random: rnd,
          );
          while (!b.isOver) {
            if (rnd.nextDouble() < 0.7) {
              b.answer(b.currentQuestion.correctIndex, elapsed: slow);
            } else {
              b.answer(wrongIndex(b), elapsed: slow);
            }
          }
          if (b.phase == BattlePhase.won) wins++;
        }
        expect(wins, greaterThanOrEqualTo(35),
            reason: '${stage.name}: 50戦中 $wins 勝');
      }
    });
  });
}
