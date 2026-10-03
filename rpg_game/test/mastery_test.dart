import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// RPG のエリア（強敵・世界の中心をふくむ）
Iterable<StageDef> rpgStages() sync* {
  for (final w in RpgCatalog.worlds) {
    for (final s in w.stages) {
      yield s;
      yield Elites.of(s);
    }
  }
  yield Story.centerStage();
}

QuizQuestion q(String id, {String? unit, int? thinking}) => QuizQuestion(
      id: id,
      category: QuestionCategory.knowledge,
      prompt: 'p',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      unit: unit,
      thinkingLevel: thinking == null ? null : ThinkingLevel.of(thinking),
    );

void main() {
  group('科目の習熟', () {
    test('すべてのエリアが学習体系の科目に属する（世界の中心だけは属さない）', () {
      for (final w in RpgCatalog.worlds) {
        for (final s in w.stages) {
          final c = Mastery.courseOfStage(s);
          expect(c, isNotNull, reason: s.id);
          expect(Curriculum.node(c!).level, CurriculumLevel.course);
          expect(Curriculum.node(c).subjectId, w.id);
        }
      }
      expect(Mastery.courseOfStage(Story.centerStage()), isNull);
      expect(
        Mastery.courseOfStage(RpgCatalog.world('math').stages.first),
        'math.e1',
      );
    });

    test('習熟Lvは冒険Lvと同じ曲線', () {
      for (final l in [1, 2, 5, 17, 50]) {
        expect(Mastery.levelFor(Mastery.expForLevel(l)), l);
        if (l > 1) expect(Mastery.levelFor(Mastery.expForLevel(l) - 1), l - 1);
      }
      expect(Mastery.levelFor(1 << 30), PlayerStats.maxLevel);
    });

    test('古いセーブデータ：クリアしたエリアの経験値が、その科目の習熟になる（1回だけ）', () {
      final math = RpgCatalog.world('math').stages.take(3).toList();
      final old = RpgProgress.fromMap({
        'level': 12,
        'clearedStageIds': [for (final s in math) s.id],
      });
      expect(old.masteryVersion, 0);
      final m = Mastery.migrate(old);
      expect(m.masteryVersion, Mastery.version);
      expect(m.masteryExp['math.e1'],
          math.fold<int>(0, (a, s) => a + s.expReward));
      expect(m.masteryExp.containsKey('science.j1'), isFalse);
      expect(identical(Mastery.migrate(m), m), isTrue);
      final back = RpgProgress.fromMap(m.toMap());
      expect(back.masteryExp, m.masteryExp);
      expect(back.masteryVersion, Mastery.version);
    });
  });

  group('戦いの強さ（ワンパン対策）', () {
    test('どのエリアも、推奨レベルでは4問以上の正解が必要', () {
      for (final s in rpgStages()) {
        expect(BattlePower.baseHits(s), greaterThanOrEqualTo(3.9),
            reason: '${s.id}（HP${s.enemy.maxHp}・推奨Lv${s.recommendedLevel}）');
      }
    });

    test('冒険Lv50・習熟Lv50でも、すばやい正解1回では倒せない（最低3問）', () {
      final strong = RpgProgress(
        level: 50,
        masteryVersion: Mastery.version,
        masteryExp: {
          for (final w in RpgCatalog.worlds)
            for (final s in w.stages)
              if (Mastery.courseOfStage(s) != null)
                Mastery.courseOfStage(s)!: Mastery.expForLevel(50),
        },
      );
      for (final s in rpgStages()) {
        final p = BattlePower.forStage(strong, s);
        // ブレなし・クリティカル（1.5倍）でも1撃にならない
        expect(
            p.attack * DamageCalculator.criticalRate, lessThan(s.enemy.maxHp),
            reason: s.id);
        expect((s.enemy.maxHp / p.attack).ceil(), greaterThanOrEqualTo(3),
            reason: s.id);
      }
    });

    test('ほかの科目で冒険Lvを上げても、新しい科目の敵の攻撃は習熟の分しか伸びない', () {
      final stage = RpgCatalog.world('science').stages[8]; // 物理の中盤
      final veteran = Mastery.migrate(const RpgProgress(level: 40));
      final specialist = veteran.copyWith(masteryExp: {
        Mastery.courseOfStage(stage)!: Mastery.expForLevel(40),
      });
      final a = BattlePower.forStage(veteran, stage).attack;
      final b = BattlePower.forStage(specialist, stage).attack;
      expect(b, greaterThan(a));
      // 冒険Lv だけでは推奨レベル付近の強さ
      final eff = BattlePower.effectiveLevel(playerLevel: 40, masteryLevel: 1);
      expect(eff, 17); // 0.6×1 ＋ 0.4×40
      // 体の強さ（HP・守り）は冒険Lvで決まる
      expect(BattlePower.forStage(veteran, stage).maxHp,
          PlayerStats.forLevel(40).maxHp);
    });

    test('習熟が低いと攻撃は下がるが、0 にはならない（最低0.55倍）', () {
      final stage = RpgCatalog.world('math').stages.last;
      final p =
          BattlePower.forStage(Mastery.migrate(RpgProgress.initial), stage);
      final base = PlayerStats.forLevel(stage.recommendedLevel).attack;
      expect(p.attack, (base * BattlePower.minAdvantage).round());
    });

    test('装備の攻撃は、冒険Lvの攻撃に対する割合になる', () {
      const bonus = BattleBonus(attack: 14, attackRate: 1.1, defense: 3);
      final adjusted =
          BattlePower.bonusForStage(bonus, const RpgProgress(level: 25));
      expect(adjusted.attack, 0);
      expect(adjusted.defense, 3);
      expect(adjusted.attackRate,
          closeTo(1.1 * (1 + 14 / PlayerStats.forLevel(25).attack), 1e-9));
    });
  });

  group('学びのボーナス', () {
    test('思考レベルが高いほど、苦手な単元ほどダメージが大きい', () {
      expect(LearningBonus.thinkingRate(q('a', thinking: 1)), 1.0);
      expect(
          LearningBonus.thinkingRate(q('a', thinking: 4)), closeTo(1.1, 1e-9));
      expect(
          LearningBonus.thinkingRate(q('a', thinking: 8)), closeTo(1.5, 1e-9));
      final weak = {'math.j3.s2.a07'};
      expect(
          LearningBonus.isWeak(q('a', unit: 'math.j3.s2.a07.main'), weak),
          isTrue);
      expect(LearningBonus.isWeak(q('a', unit: 'math.j3.s2.a07x'), weak),
          isFalse);
    });

    test('バトルで、苦手な単元の正解に「苦手に挑戦」がつき、ダメージが増える', () {
      List<QuizQuestion> qs(String unit) =>
          [for (var i = 0; i < 6; i++) q('w$i', unit: unit, thinking: 1)];
      int firstHit(Set<String> weak) {
        final b = BattleEngine(
          player: PlayerStats.forLevel(5),
          enemy: testEnemy,
          questions: qs('math.j3.s2.a07.main'),
          timeLimit: const Duration(seconds: 20),
          random: Random(1),
          damage: fixedDamage(),
          weakUnits: weak,
        );
        final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
        expect(r.challenge, weak.isNotEmpty);
        return r.damageToEnemy;
      }

      expect(firstHit({'math.j3.s2'}),
          (firstHit({}) * LearningBonus.weakRate).round());
    });

    test('難しい問題・苦手への正解は経験値もふえ、科目の習熟にも入る', () {
      final stage = RpgCatalog.world('math').stages.first;
      final questions = [
        for (var i = 0; i < 12; i++)
          q('t$i', unit: 'math.j1.s1.a01.main', thinking: 6),
      ];
      final b = BattleEngine(
        player: PlayerStats.forLevel(30),
        enemy: stage.enemy,
        questions: questions,
        timeLimit: const Duration(seconds: 20),
        random: Random(3),
        damage: fixedDamage(),
      );
      while (!b.isOver) {
        b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      }
      final summary = b.summary();
      final bonus =
          LearningBonus.bonusExp(summary, weakUnits: {'math.j1.s1.a01'});
      expect(bonus, summary.correctIds.length * (3 * 3 + 3));
      final r = Progression.applyBattle(
        progress: Mastery.migrate(RpgProgress.initial),
        world: RpgCatalog.world('math'),
        stage: stage,
        summary: summary,
        weakUnits: {'math.j1.s1.a01'},
      );
      expect(r.learningBonusExp, bonus);
      // 習熟はステージの科目（小1の道）に入る
      expect(r.progress.masteryExp['math.e1'], r.expResult.expGained);
      expect(r.masteryCourse, 'math.e1');
      expect(r.masteryAfter, greaterThan(r.masteryBefore));
    });

    test('練習のバトルの経験値は、正解した問題の科目に分けて入る', () {
      final questions = [
        q('p1', unit: 'math.j1.s1.a01.main'),
        q('p2', unit: 'science.j1.s2.a06.main'),
        q('p3', unit: 'science.j1.s2.a06.main'),
        q('p4', unit: 'science.j1.s2.a06.main'),
      ];
      final b = BattleEngine(
        player: PlayerStats.forLevel(1),
        enemy: const EnemyDef(id: 'x', name: 'x', maxHp: 40, attack: 1),
        questions: questions,
        timeLimit: const Duration(seconds: 20),
        random: Random(5),
        damage: fixedDamage(),
      );
      for (var i = 0; i < 4 && !b.isOver; i++) {
        b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      }
      final summary = b.summary();
      final r = Progression.applyPractice(
          Mastery.migrate(RpgProgress.initial), summary);
      final m = r.progress.masteryExp;
      expect((m['math.j1'] ?? 0) + (m['science.j1'] ?? 0),
          closeTo(r.expGained, 1));
      expect(m['science.j1'] ?? 0, greaterThan(m['math.j1'] ?? 0));
    });
  });
}
