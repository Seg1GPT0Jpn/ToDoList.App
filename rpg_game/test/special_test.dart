import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('必殺技：正解でゲージがたまり、構えて正解すると2.5倍。まちがえると空振り', () {
    final b = newBattle(
      enemy: const EnemyDef(id: 'x', name: 'x', maxHp: 9999, attack: 1),
    );
    expect(b.specialReady, isFalse);
    expect(() => b.armSpecial(), throwsStateError);
    final normal = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    expect(b.special, BattleEngine.specialGain);
    b.answer(b.currentQuestion.correctIndex, elapsed: fast);
    expect(b.special, BattleEngine.specialGain + BattleEngine.specialQuickGain);
    while (!b.specialReady) {
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    }
    expect(b.special, 100);
    b.armSpecial();
    expect(b.specialArmed, isTrue);
    expect(b.specialReady, isFalse);
    final combo = b.combo + 1;
    final hit = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    expect(hit.special, isTrue);
    expect(b.special, 0);
    // コンボの倍率を除くと、ふつうの2.5倍
    final base = normal.damageToEnemy;
    expect(hit.damageToEnemy / DamageCalculator.chainRate(combo),
        closeTo(base * BattleEngine.specialRate, 2));

    while (!b.specialReady) {
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    }
    b.armSpecial();
    final miss = b.answer(wrongIndex(b), elapsed: slow);
    expect(miss.specialMissed, isTrue);
    expect(b.special, 0);
    expect(b.specialArmed, isFalse);
  });
}
