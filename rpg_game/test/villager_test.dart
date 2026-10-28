import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final stages = RpgCatalog.world(RpgCatalog.englishWorldId).stages;

  String say(RpgProgress p, {int day = 0, int who = 0, int hour = 12}) =>
      VillagerChat.line(
        progress: p,
        stages: stages,
        terrain: Terrain.meadow,
        hour: hour,
        day: day,
        who: who,
      );

  test('住人のおしゃべりは、日と人で変わり、冒険の進み具合のうわさもする', () {
    final lines = {
      for (var d = 0; d < 20; d++)
        for (var w = 0; w < 3; w++) say(RpgProgress.initial, day: d, who: w),
    };
    expect(lines.length, greaterThan(4));
    expect(lines.any((l) => l.contains(stages.first.enemy.name)), isTrue);
    // 同じ日・同じ人なら同じ話
    expect(say(RpgProgress.initial, day: 3), say(RpgProgress.initial, day: 3));

    final all = RpgProgress.initial.copyWith(
      clearedStageIds: {for (final s in stages) s.id},
    );
    final later = {
      for (var d = 0; d < 20; d++) say(all, day: d),
    };
    expect(later.any((l) => l.contains('影')), isTrue);
  });
}
