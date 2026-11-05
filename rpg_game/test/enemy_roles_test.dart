import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

EnemyDef enemy(EnemyAbility a, {int hp = 300, int attack = 10}) =>
    EnemyDef(id: 'e', name: 'テキ', maxHp: hp, attack: attack, ability: a);

BattleEngine battle(EnemyDef e) => BattleEngine(
      player: PlayerStats.forLevel(10),
      enemy: e,
      questions: loadStage01().questions,
      timeLimit: const Duration(seconds: 20),
      random: Random(4),
      damage: fixedDamage(),
    );

int firstHit(EnemyAbility a, {Duration elapsed = slow}) {
  final b = battle(enemy(a));
  return b
      .answer(b.currentQuestion.correctIndex, elapsed: elapsed)
      .damageToEnemy;
}

void main() {
  test('図鑑：67種族、見た目が重ならず、v4の種族はすべて役割をもつ', () {
    final looks = [for (final s in EnemySpeciesCatalog.all) s.look];
    expect(looks.length, greaterThanOrEqualTo(60));
    expect(looks.toSet().length, looks.length);
    for (final l in [
      'notebook',
      'pencilcase',
      'glue',
      'tape',
      'clip',
      'pushpin',
      'sharpener',
      'brush',
      'correction',
      'inkpot',
      'calculator',
      'ray',
      'turtle',
      'whale',
      'seahorse',
      'starfish',
      'eel',
      'ammonite',
      'urchin',
      'angel',
      'owl',
      'phoenix',
      'pegasus',
      'balloon',
      'kite',
      'griffin',
      'rainbow',
      'mimic',
    ]) {
      expect(EnemyAbility.forLook(l), isNot(EnemyAbility.none), reason: l);
      expect(EnemySpeciesCatalog.of(l).look, l);
    }
  });

  test('RPG のエリアで、同じ見た目が使われすぎない（1種類11エリアまで）', () {
    final count = <String, int>{};
    for (final w in RpgCatalog.worlds) {
      for (final s in w.stages.where((s) => !s.isBoss)) {
        count[s.enemy.look] = (count[s.enemy.look] ?? 0) + 1;
      }
    }
    for (final e in count.entries) {
      expect(e.value, lessThanOrEqualTo(11), reason: e.key);
    }
    expect(count.length, greaterThanOrEqualTo(30));
  });

  test('高HP型：受けるダメージ0.75倍・攻撃0.8倍', () {
    expect(firstHit(EnemyAbility.tank),
        (firstHit(EnemyAbility.normal) * 0.75).round());
    final b = battle(enemy(EnemyAbility.tank));
    final w = b.answer(wrongIndex(b), elapsed: slow).damageToPlayer;
    final n = battle(enemy(EnemyAbility.normal));
    expect(w, lessThan(n.answer(wrongIndex(n), elapsed: slow).damageToPlayer));
  });

  test('回避型：制限時間の半分をこえた正解はかわされる', () {
    final b = battle(enemy(EnemyAbility.evasive));
    final r = b.answer(b.currentQuestion.correctIndex,
        elapsed: const Duration(seconds: 15));
    expect(r.evaded, isTrue);
    expect(r.damageToEnemy, 0);
    expect(r.correct, isTrue, reason: '学習としては正解のまま');
    final r2 = b.answer(b.currentQuestion.correctIndex,
        elapsed: const Duration(seconds: 8));
    expect(r2.evaded, isFalse);
  });

  test('コンボ妨害型：3連続正解でチェインが切れる', () {
    final b = battle(enemy(EnemyAbility.comboBreaker, hp: 5000));
    TurnResult? last;
    for (var i = 0; i < 3; i++) {
      last = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    }
    expect(last!.comboBroken, isTrue);
    expect(b.combo, 0);
  });

  test('連続出現型：HP を分けた3体の群れ', () {
    final b = battle(enemy(EnemyAbility.swarm, hp: 90));
    expect(b.lineup.length, 3);
    expect(b.lineup.map((e) => e.maxHp), [30, 30, 30]);
    expect(b.lineup.first.effectiveAbility, EnemyAbility.none);
  });

  test('ミミック型：最初の問題をまちがえると2倍の不意打ち', () {
    final m = battle(enemy(EnemyAbility.mimic));
    final r = m.answer(wrongIndex(m), elapsed: slow);
    expect(r.ambush, isTrue);
    final n = battle(enemy(EnemyAbility.normal));
    final base = n.answer(wrongIndex(n), elapsed: slow).damageToPlayer;
    expect(r.damageToPlayer, closeTo(base * 2, 1));
    expect(m.answer(wrongIndex(m), elapsed: slow).ambush, isFalse);
  });

  test('レア型：6問のうちに倒さないと逃げる（負けには数えない）', () {
    final b = battle(enemy(EnemyAbility.rare, hp: 100000));
    for (var i = 0; i < BattleEngine.rareTurns && !b.isOver; i++) {
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    }
    expect(b.phase, BattlePhase.escaped);
    final s = b.summary();
    expect(s.escaped, isTrue);
    expect(s.won, isFalse);
    final stage = RpgCatalog.world('english').stages.first;
    final r = Progression.applyBattle(
      progress: RpgProgress.initial,
      world: RpgCatalog.world('english'),
      stage: stage,
      summary: s,
    );
    expect(r.progress.lostStages, isEmpty);
  });
}
