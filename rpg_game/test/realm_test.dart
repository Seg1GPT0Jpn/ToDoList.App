import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

ExamWorldPlan _plan(StudyRealm realm, int areas) {
  final stages = RpgCatalog.world(RpgCatalog.englishWorldId).stages;
  return ExamWorldPlan(
    id: 'p_${realm.name}_$areas',
    title: '2学期中間',
    worldId: 'english',
    stageIds: [for (final s in stages.take(areas)) s.id],
    createdAt: DateTime(2026, 9, 1),
    realm: realm,
  );
}

void main() {
  group('航路（定期テストの海・模擬試験の空）', () {
    test('終盤（全体の4分の1ほど）は深海・宇宙になり、前半も必ず残る', () {
      expect(StudyRealm.deepFrom(1), 0);
      expect(StudyRealm.deepFrom(2), 1);
      expect(StudyRealm.deepFrom(8), 6);
      expect(StudyRealm.deepFrom(61), 45);
      for (final total in [2, 3, 5, 12, 61]) {
        final kinds = [
          for (var i = 0; i < total; i++) StudyRealm.sea.terrainAt(i, total),
        ];
        expect(kinds.first, Terrain.ocean);
        expect(kinds.last, Terrain.abyss);
        // 一度潜ったら、もう海面にはもどらない
        expect(kinds.skipWhile((t) => t == Terrain.ocean),
            everyElement(Terrain.abyss));
      }
      expect(StudyRealm.sky.terrainAt(0, 5), Terrain.cloudSea);
      expect(StudyRealm.sky.terrainAt(4, 5), Terrain.space);
    });

    test('海の試験ワールドの敵は海の魔物。終盤は深海の魔物、最後は海竜', () {
      final plan = _plan(StudyRealm.sea, 11);
      final stages = ExamWorlds.build(plan, level: 10);
      final total = stages.length;
      final deepFrom = StudyRealm.deepFrom(total);
      final surface = {
        for (final m in VoyageMonsters.surface(StudyRealm.sea)) m.look
      };
      final deep = {
        for (final m in VoyageMonsters.deep(StudyRealm.sea)) m.look
      };
      for (var i = 0; i < total - 1; i++) {
        expect(i < deepFrom ? surface : deep, contains(stages[i].enemy.look),
            reason: 'エリア${i + 1}');
      }
      expect(stages.last.enemy.look, 'leviathan');
      expect(stages.last.isBoss, isTrue);
      expect(stages.first.region, '大海原');
      expect(stages.last.region, '深海');
    });

    test('空の試験ワールドは空の魔物で、海より難しい（時間が短く、攻撃が強い）', () {
      final sea = ExamWorlds.build(_plan(StudyRealm.sea, 6), level: 10);
      final sky = ExamWorlds.build(_plan(StudyRealm.sky, 6), level: 10);
      expect(sky.last.enemy.look, 'astral');
      expect(sky.first.region, '雲海');
      expect(sky.last.region, '宇宙');
      for (var i = 0; i < sea.length; i++) {
        expect(sky[i].timeLimitSeconds,
            lessThanOrEqualTo(sea[i].timeLimitSeconds));
        expect(sky[i].enemy.attack, greaterThan(sea[i].enemy.attack));
        expect(sky[i].enemy.maxHp, greaterThanOrEqualTo(sea[i].enemy.maxHp));
      }
    });

    test('空のバトルは2回まちがえると倒れ、16回ほど正解しないと勝てない', () {
      for (final level in [1, 10, 30, 50]) {
        final p = PlayerStats.forLevel(level);
        final s = SeaBattle.stage(
          id: 'english_stage_01',
          title: '文型',
          worldId: 'english',
          level: level,
          normalTimeLimitSeconds: 20,
          realm: StudyRealm.sky,
        );
        final perMiss = s.enemy.attack - p.defense / 2;
        expect(perMiss * 2, greaterThanOrEqualTo(p.maxHp), reason: 'Lv$level');
        expect(perMiss, lessThan(p.maxHp), reason: 'Lv$level');
        expect(s.enemy.maxHp / p.attack, StudyRealm.sky.hitsToWin);
        expect(s.timeLimitSeconds, 10);
        expect(s.region, '模擬試験の空');
        expect(VoyageMonsters.looks, contains(s.enemy.look));
      }
    });

    test('海・空の魔物はすべて図鑑にのっている', () {
      final known = {for (final s in EnemySpeciesCatalog.all) s.look};
      expect(known, containsAll(VoyageMonsters.looks));
      expect(VoyageMonsters.looks.length, 15);
    });

    test('保存しても海か空かは元にもどる（古いデータは海）', () {
      final plan = _plan(StudyRealm.sky, 3);
      expect(ExamWorldPlan.fromMap(plan.toMap()).realm, StudyRealm.sky);
      final old = plan.toMap()..remove('realm');
      expect(ExamWorldPlan.fromMap(old).realm, StudyRealm.sea);
      expect(plan.copyWith(gauge: 3).realm, StudyRealm.sky);
    });

    test('航路の地形にも住人がいる', () {
      for (final t in [
        Terrain.ocean,
        Terrain.abyss,
        Terrain.cloudSea,
        Terrain.space,
      ]) {
        expect(Npcs.of(t).name, isNotEmpty);
      }
    });
  });
}
