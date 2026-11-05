import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final english = RpgCatalog.world(RpgCatalog.englishWorldId);

  test('練習バトルの敵は、レベルが高くてもおよそ10問分の体力がある', () {
    final base = english.stages.first;
    for (final level in [1, 20, 46]) {
      final s = PracticeBattle.stage(base, level);
      expect(
        s.enemy.maxHp,
        PlayerStats.forLevel(level).attack * PracticeBattle.hits,
      );
      expect(s.id, base.id);
    }
  });

  test('レベルで装備が手に入り、選んでいなければ一番よいものをつける', () {
    final low = RpgProgress.initial;
    expect(Gear.equipped(low).map((g) => g.id), contains('wood_pen'));
    final high = RpgProgress.initial.copyWith(level: 46);
    final ids = Gear.equipped(high).map((g) => g.id).toList();
    expect(ids, contains('star_pen'));
    expect(ids, contains('hard_cover'));
    expect(Gear.owned(high), containsAll(['silver_pen', 'gold_pen']));
  });
}
