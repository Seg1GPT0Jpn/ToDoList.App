import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// 正答率 [acc] の人が、[stages] を順に遊ぶ（負けたらもう一度）。
/// エリアごとの挑戦回数・冒険Lv・戦闘Lv を返す
List<(String, int, int, int, int)> playthrough(
  WorldDef world,
  List<StageDef> stages,
  double acc, {
  int seed = 1,
  BattleDifficulty d = BattleDifficulty.normal,
}) {
  final rnd = Random(seed);
  var p = RpgProgress.initial;
  final out = <(String, int, int, int, int)>[];
  for (final stage in stages) {
    final qs = loadStagePool(stage).questions;
    var tries = 0;
    while (tries < 30) {
      tries++;
      final b = BattleEngine(
        player: BattlePower.forStage(p, stage),
        enemy: d.enemy(stage.enemy),
        reinforcements: [for (final e in stage.reinforcements) d.enemy(e)],
        questions: qs,
        timeLimit: Duration(seconds: d.seconds(stage.timeLimitSeconds)),
        random: Random(rnd.nextInt(1 << 30)),
      );
      while (!b.isOver) {
        final q = b.currentQuestion;
        final ok = rnd.nextDouble() < acc;
        final secs =
            d.seconds(stage.timeLimitSeconds) * (0.2 + 0.5 * rnd.nextDouble());
        b.answer(
          ok ? q.correctIndex : (q.correctIndex + 1) % q.choices.length,
          elapsed: Duration(milliseconds: (secs * 1000).round()),
        );
      }
      final r = Progression.applyBattle(
        progress: p,
        world: world,
        stage: stage,
        summary: b.summary(),
      );
      p = r.expResult.progress;
      if (b.phase == BattlePhase.won) break;
    }
    final eff = BattlePower.effectiveLevel(
      playerLevel: p.level,
      masteryLevel: Mastery.levelForStage(p, stage),
    );
    out.add((stage.name, tries, p.level, eff, stage.recommendedLevel));
  }
  return out;
}

double _avgTries(WorldDef w, double acc, BattleDifficulty d, {int people = 3}) {
  var sum = 0;
  for (var s = 1; s <= people; s++) {
    sum += playthrough(w, w.stages, acc, seed: s, d: d)
        .fold(0, (a, r) => a + r.$2);
  }
  return sum / (people * w.stages.length);
}

void main() {
  final w = RpgCatalog.world(RpgCatalog.englishWorldId);

  test('ふつう：正答率5割でも少しずつ進め、7割ならほとんど負けない', () {
    expect(_avgTries(w, 0.5, BattleDifficulty.normal), lessThan(2.5));
    expect(_avgTries(w, 0.7, BattleDifficulty.normal), lessThan(1.2));
  });

  test('むずかしい：9割解ける人は勝てて、7割だと手ごわい', () {
    expect(_avgTries(w, 0.9, BattleDifficulty.hard), lessThan(1.3));
    expect(_avgTries(w, 0.7, BattleDifficulty.hard), greaterThan(1.6));
    expect(
      _avgTries(w, 0.8, BattleDifficulty.hard),
      greaterThan(_avgTries(w, 0.8, BattleDifficulty.normal)),
    );
  });

  test('むずかしいは、敵の HP・攻撃が上がり、答える時間が短くなる', () {
    final e = w.stages.first.enemy;
    expect(BattleDifficulty.hard.enemy(e).maxHp, greaterThan(e.maxHp));
    expect(BattleDifficulty.hard.enemy(e).attack, greaterThan(e.attack));
    expect(BattleDifficulty.normal.enemy(e), same(e));
    expect(BattleDifficulty.hard.seconds(20), 15);
    expect(BattleDifficulty.byName('hard'), BattleDifficulty.hard);
    expect(BattleDifficulty.byName('???'), BattleDifficulty.normal);
  });

  test('むずかしいで勝つと、経験値が1.3倍になり、エリアに印がつく。実績も解除', () {
    final stage = w.stages.first;
    BattleSummary win() {
      final b = BattleEngine(
        player: PlayerStats.forLevel(30),
        enemy: stage.enemy,
        questions: loadStagePool(stage).questions,
        timeLimit: const Duration(seconds: 20),
        random: Random(3),
      );
      while (!b.isOver) {
        b.answer(b.currentQuestion.correctIndex,
            elapsed: const Duration(seconds: 10));
      }
      return b.summary();
    }

    final s = win();
    final normal = Progression.applyBattle(
        progress: RpgProgress.initial, world: w, stage: stage, summary: s);
    final hard = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: w,
        stage: stage,
        summary: s,
        difficulty: BattleDifficulty.hard);
    expect(
        hard.expResult.expGained, (normal.expResult.expGained * 1.3).round());
    expect(BattleDifficulty.hardCleared(normal.progress, stage), isFalse);
    expect(BattleDifficulty.hardCleared(hard.progress, stage), isTrue);
    final c = AchievementContext(
      progress: hard.progress,
      record: LearningRecord.empty,
      journal: PlayerJournal.empty,
      today: 1,
    );
    expect(Achievements.byId('hard_1')!.achieved(c), isTrue);
    expect(Achievements.byId('hard_english')!.achieved(c), isFalse);
  });

  test('バランスの表（確かめる用。dart test -t sim --run-skipped）', () {
    for (final d in BattleDifficulty.values) {
      for (final acc in [0.5, 0.7, 0.8, 0.9]) {
        final runs = [
          for (var s = 1; s <= 5; s++)
            playthrough(w, w.stages, acc, seed: s, d: d)
        ];
        print('--- ${d.label} 正答率 $acc（5人の平均の挑戦回数）');
        print([
          for (var i = 0; i < w.stages.length; i++)
            (runs.map((r) => r[i].$2).reduce((a, b) => a + b) / runs.length)
                .toStringAsFixed(1),
        ].join(' '));
      }
    }
  }, tags: ['sim'], skip: '時間がかかるので、ふだんは動かさない');
}
