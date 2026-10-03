import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('6つの国すべてに、国民・守護者・忘却の理由・学ぶ理由・5話の物語がある', () {
    expect(Lore.nations.map((n) => n.worldId).toSet(),
        {for (final w in Story.worlds) w.worldId});
    for (final n in Lore.nations) {
      for (final t in [
        n.land,
        n.people,
        n.guardian,
        n.forgotten,
        n.whyLearn,
        n.midBossNote,
        n.bossNote
      ]) {
        expect(t, isNotEmpty, reason: n.worldId);
      }
      expect(n.chapters, hasLength(5));
    }
  });

  test('アーカイブは進むと読める', () {
    expect(Lore.archive(RpgProgress.initial).where((e) => e.unlocked), isEmpty);
    final math = RpgCatalog.world('math').stages;
    final half = RpgProgress(clearedStageIds: {
      for (final s in math.take((math.length / 2).ceil())) s.id,
    });
    final open = Lore.archive(half).where((e) => e.unlocked).toList();
    expect(open.map((e) => e.id), ['math_0', 'math_1', 'math_2']);
  });

  test('住人の役割：小部屋があれば頼みごと、それ以外は5つの役割を順に', () {
    expect(NpcRole.forArea(3, hasNook: true), NpcRole.quest);
    expect({for (var a = 0; a < 5; a++) NpcRole.forArea(a, hasNook: false)},
        hasLength(5));
    final stage = RpgCatalog.world('math').stages[1];
    final tutor = Npcs.talk(stage, Terrain.meadow, area: 1);
    expect(tutor.role, NpcRole.tutor);
    expect(tutor.lines.any((l) => l.startsWith('【先生】')), isTrue);
    final review = Npcs.talk(stage, Terrain.meadow, area: 2, dueReviews: 4);
    expect(review.lines.any((l) => l.contains('4問')), isTrue);
    final scout = Npcs.talk(stage, Terrain.meadow,
        area: 3, progress: RpgProgress.initial);
    expect(scout.lines.any((l) => l.startsWith('【見張り】')), isTrue);
    final lore = Npcs.talk(stage, Terrain.meadow, area: 0);
    expect(lore.lines.any((l) => l.contains('筋道')), isTrue);
  });

  test('次のボス', () {
    final stages = RpgCatalog.world('math').stages;
    final boss = Lore.nextBoss(RpgProgress.initial, stages.first);
    expect(boss, isNotNull);
    expect(boss!.isBoss, isTrue);
    expect(boss.branch, stages.first.branch);
  });
}
