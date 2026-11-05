import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('紙の種類：国と地形で変わり、いろいろな紙が使われる', () {
    expect(NotebookWorld.paperOf(Terrain.library, 'japanese'),
        PaperStyle.manuscript);
    expect(NotebookWorld.paperOf(Terrain.meadow, 'music'), PaperStyle.staff);
    expect(NotebookWorld.paperOf(Terrain.cave, 'math'), PaperStyle.chalkboard);
    expect(NotebookWorld.paperOf(Terrain.ocean, 'english'), PaperStyle.grid);
    final used = {
      for (final w in RpgCatalog.worlds)
        for (final t in Terrain.values) NotebookWorld.paperOf(t, w.id),
    };
    expect(used, containsAll(PaperStyle.values));
    for (final w in RpgCatalog.worlds) {
      expect(NotebookWorld.scribblesOf(w.id), isNotEmpty);
    }
  });

  test('宝箱の種類：エリアで決まり、ボスの間はふつうの封印', () {
    expect(ChestVariant.forMainChest(4), ChestVariant.chain);
    expect(ChestVariant.forMainChest(6), ChestVariant.mimic);
    expect(ChestVariant.forMainChest(5), ChestVariant.seal);
    expect(ChestVariant.forMainChest(6, boss: true), ChestVariant.seal);
  });

  test('連続正解の宝箱：全問2枚・1問ミスで1枚・それ以外は空っぽ（1回きり）', () {
    expect(Progression.chainChestCards(3, 3), 2);
    expect(Progression.chainChestCards(2, 3), 1);
    expect(Progression.chainChestCards(1, 3), 0);
    final (p, cards) =
        Progression.openChestWith(RpgProgress.initial, 'c1', 2, Random(1));
    expect(cards, hasLength(2));
    expect(p.openedChests, {'c1'});
    expect(p.deck.length, RpgProgress.initial.deck.length + 2);
    final (empty, none) =
        Progression.openChestWith(RpgProgress.initial, 'c2', 0, Random(1));
    expect(none, isEmpty);
    expect(empty.openedChests, {'c2'});
  });

  test('ミミック：そのエリアの敵より少し強いミミック型', () {
    final base = RpgCatalog.world('math').stages[3];
    final m = Progression.mimicStage(base, 'math_chest_4');
    expect(m.enemy.look, 'mimic');
    expect(m.enemy.effectiveAbility, EnemyAbility.mimic);
    expect(m.enemy.maxHp, greaterThan(base.enemy.maxHp));
    expect(m.questionSetIds, base.questionSetIds);
    expect(Mastery.courseOfStage(m), Mastery.courseOfStage(base));
  });

  test('発見率', () {
    expect(const FieldDiscovery(found: 3, total: 4).percent, 75);
    expect(const FieldDiscovery(found: 0, total: 0).percent, 100);
    expect(const FieldDiscovery(found: 2, total: 2).complete, isTrue);
  });
}
