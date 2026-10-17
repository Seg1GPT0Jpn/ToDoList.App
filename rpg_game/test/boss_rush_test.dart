import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const _a = EnemyDef(id: 'a', name: 'ボスA', maxHp: 40, attack: 7);
const _b = EnemyDef(id: 'b', name: 'ボスB', maxHp: 40, attack: 7);
const _c = EnemyDef(id: 'c', name: 'ボスC', maxHp: 40, attack: 7);

BattleEngine _rush({int level = 5, int seed = 1}) => BattleEngine(
      player: PlayerStats.forLevel(level),
      enemy: _a,
      reinforcements: const [_b, _c],
      questions: loadStage01().questions,
      timeLimit: const Duration(seconds: 20),
      random: Random(seed),
      damage: fixedDamage(),
    );

/// [accuracy] の確率で正解するプレイヤーが、ボスの連戦に勝つ割合
double _winRate(StageDef stage, int level, double accuracy) {
  final questions = [
    for (final s in stage.questionSetIds.take(3)) ...loadSet(s).questions,
  ];
  var wins = 0;
  const n = 300;
  for (var i = 0; i < n; i++) {
    final rnd = Random(i);
    final b = BattleEngine(
      player: PlayerStats.forLevel(level),
      enemy: stage.enemy,
      reinforcements: stage.reinforcements,
      questions: questions,
      timeLimit: Duration(seconds: stage.timeLimitSeconds),
      random: Random(i + 1000),
    );
    while (!b.isOver) {
      final q = b.currentQuestion;
      final ok = rnd.nextDouble() < accuracy;
      b.answer(ok ? q.correctIndex : (q.correctIndex + 1) % q.choices.length,
          elapsed: Duration(seconds: stage.timeLimitSeconds ~/ 2));
    }
    if (b.phase == BattlePhase.won) wins++;
  }
  return wins / n;
}

void main() {
  group('ボスの連戦（共通テスト遺跡）', () {
    test('前のボスが半分まで減ると、次のボスが乱入して2体が重なる', () {
      final b = _rush();
      expect(b.lineup.length, 3);
      expect(b.backEnemy, isNull);
      TurnResult r;
      do {
        r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      } while (r.joined == null);
      expect(r.joined, _b);
      expect(b.enemy, _a, reason: '前にいるのは最初のボスのまま');
      expect(b.backEnemy, _b);
      expect(b.enemyHp, lessThanOrEqualTo(_a.maxHp ~/ 2));
    });

    test('2体いるときにまちがえると、後ろのボスからも攻撃を受ける', () {
      final single = newBattle(level: 5);
      final alone = single.answer(wrongIndex(single), elapsed: slow);
      final b = _rush();
      while (b.backEnemy == null) {
        b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      }
      final r = b.answer(wrongIndex(b), elapsed: slow);
      expect(r.backDamage, greaterThan(0));
      expect(r.damageToPlayer, alone.damageToPlayer + r.backDamage);
    });

    test('前のボスを倒すと後ろのボスが前に出て、HP は引き継ぐ。全員倒すと勝ち', () {
      final b = _rush(level: 10);
      final defeated = <EnemyDef>[];
      final joined = <EnemyDef>[];
      var lastHp = b.playerHp;
      while (!b.isOver) {
        final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
        if (r.defeated != null) defeated.add(r.defeated!);
        if (r.joined != null) joined.add(r.joined!);
        expect(b.playerHp, lessThanOrEqualTo(lastHp));
        lastHp = b.playerHp;
      }
      expect(b.phase, BattlePhase.won);
      expect(defeated, [_a, _b], reason: '最後のボスは defeated ではなく勝利になる');
      expect(joined, [_b, _c]);
      expect(b.defeatedCount, 3);
    });

    test('遺跡の階はボスの連戦になり、上の階ほどボスが多い', () {
      final worlds = RpgCatalog.worlds;
      var prev = 0;
      for (final f in RuinsFloor.values) {
        final st = CommonTest.stage(f, CommonTest.stagesFor(f, worlds, seed: 1),
            level: 10);
        final count = 1 + st.reinforcements.length;
        expect(count, CommonTest.bossCount(f));
        expect(count, greaterThanOrEqualTo(prev));
        prev = count;
        expect(st.isBoss, isTrue);
        expect(BossRules.of(st), BossRule.none, reason: '連戦そのものが特別ルール');
        final names = {
          st.enemy.name,
          for (final e in st.reinforcements) e.name
        };
        expect(names.length, count, reason: '同じ名前のボスは出さない');
      }
    });

    test('バランス：よく解ける人は勝てて、まぐれでは勝てない', () {
      final worlds = RpgCatalog.worlds;
      StageDef floor(RuinsFloor f, int level) =>
          CommonTest.stage(f, CommonTest.stagesFor(f, worlds, seed: 4),
              level: level);
      // 第1階層：レベル5・正答率85%なら、ほぼ勝てる
      expect(_winRate(floor(RuinsFloor.basic, 5), 5, 0.85), greaterThan(0.8));
      // 最上階：レベル25・正答率90%なら、たいてい勝てる
      expect(_winRate(floor(RuinsFloor.real, 25), 25, 0.9), greaterThan(0.6));
      // でも正答率60%では、最上階はほとんど勝てない
      expect(_winRate(floor(RuinsFloor.real, 25), 25, 0.6), lessThan(0.15));
    });
  });
}
