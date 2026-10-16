import 'package:rpg_game/rpg_game.dart';

import 'package:tsuzuri_quest_3d/game/field3d.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const r = Field3DRegion.meadow;

  test('試作の草原の敵は、既存のワールドのステージにつながっている', () {
    for (final e in r.enemies) {
      final w = RpgCatalog.world(e.worldId);
      expect(w.stages.map((s) => s.id), contains(e.stageId), reason: e.id);
    }
    expect(r.enemies.map((e) => e.id).toSet(), hasLength(r.enemies.length));
  });

  test('置き物・人・敵・出発点は地図の内側', () {
    final all = [
      for (final p in r.props) (p.x, p.z),
      for (final n in r.npcs) (n.x, n.z),
      for (final e in r.enemies) (e.x, e.z),
      (r.spawnX, r.spawnZ),
    ];
    for (final (x, z) in all) {
      expect(x.abs(), lessThan(r.halfSize - 1));
      expect(z.abs(), lessThan(r.halfSize - 1));
    }
  });

  test('近くの人に話しかけられ、遠いと話せない', () {
    final n = r.npcs.first;
    expect(r.npcInRange(n.x + 1, n.z)?.id, n.id);
    expect(r.npcInRange(n.x + 5, n.z), isNull);
  });

  test('敵に触れるとわかる。倒した敵には触れない', () {
    final e = r.enemies.first;
    expect(r.touchedEnemy(e.x + 0.5, e.z, const {})?.id, e.id);
    expect(r.touchedEnemy(e.x + 0.5, e.z, {e.id}), isNull);
    expect(r.touchedEnemy(e.x + 3, e.z, const {}), isNull);
  });

  test('負けたら敵から離れた地図の内側に戻る', () {
    final e = r.enemies.first;
    final (x, z) = r.retreatFrom(e, e.x + 0.5, e.z);
    expect(r.touchedEnemy(x, z, const {}), isNull);
    expect(x.abs(), lessThan(r.halfSize));
    // 真上に重なっていても落ちない
    final (x2, z2) = r.retreatFrom(e, e.x, e.z);
    expect(r.touchedEnemy(x2, z2, const {}), isNull);
  });

  group('保存', () {
    test('位置・向き・倒した敵・話した人を保存して戻せる', () {
      final s = Field3DState.start(r).copyWith(
        x: 3.5,
        y: 0.2,
        z: -4,
        heading: 1.2,
        cameraYaw: -0.5,
        defeated: {r.enemies.first.id},
        talked: {'proto_guide'},
      );
      final again = Field3DState.decode(s.encode(), r);
      expect(again.x, 3.5);
      expect(again.y, 0.2);
      expect(again.z, -4);
      expect(again.heading, 1.2);
      expect(again.cameraYaw, -0.5);
      expect(again.defeated, {r.enemies.first.id});
      expect(again.talked, {'proto_guide'});
    });

    test('空・壊れた・別の地域・地図の外・知らない敵は、はじめから（または除く）', () {
      for (final raw in [null, '', '{', '[]', '{"region":"other"}']) {
        final s = Field3DState.decode(raw, r);
        expect((s.x, s.z), (r.spawnX, r.spawnZ), reason: '$raw');
        expect(s.defeated, isEmpty);
      }
      final outside = Field3DState.decode(
        '{"region":"meadow_proto","x":999,"z":0}',
        r,
      );
      expect((outside.x, outside.z), (r.spawnX, r.spawnZ));
      final unknown = Field3DState.decode(
        '{"region":"meadow_proto","x":1,"z":1,"defeated":["nobody", 3]}',
        r,
      );
      expect(unknown.defeated, isEmpty);
      expect(unknown.x, 1);
    });
  });
}
