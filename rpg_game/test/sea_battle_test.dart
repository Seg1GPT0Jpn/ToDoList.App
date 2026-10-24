import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('海のバトルはとても難しい：3回まちがえると倒れ、15回ほど正解しないと勝てない', () {
    for (final level in [1, 5, 10, 30, 50]) {
      final p = PlayerStats.forLevel(level);
      final s = SeaBattle.stage(
        id: 'sea_g1_01',
        title: '文型',
        worldId: 'english',
        level: level,
        normalTimeLimitSeconds: 20,
      );
      final perMiss = s.enemy.attack - p.defense / 2;
      expect(perMiss * 3, greaterThanOrEqualTo(p.maxHp), reason: 'Lv$level');
      expect(perMiss * 2, lessThan(p.maxHp), reason: 'Lv$level');
      expect(s.enemy.maxHp / p.attack, SeaBattle.hitsToWin);
      expect(s.timeLimitSeconds, 12);
    }
  });

  test('制限時間は短く、最低8秒', () {
    expect(SeaBattle.timeLimit(45), 27);
    expect(SeaBattle.timeLimit(10), 8);
  });
}
