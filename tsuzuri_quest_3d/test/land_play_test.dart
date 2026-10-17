import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri_quest_3d/field/land_map.dart';
import 'package:tsuzuri_quest_3d/game/enemy_ai.dart';
import 'package:tsuzuri_quest_3d/game/field3d.dart';
import 'package:tsuzuri_quest_3d/game/geo2d.dart';
import 'package:tsuzuri_quest_3d/game/map_v2.dart';
import 'package:tsuzuri_quest_3d/game/quest3d.dart';
import 'package:tsuzuri_quest_3d/game/save3d.dart';
import 'package:tsuzuri_quest_3d/game/world_v2.dart';

QuestContext _ctx(Field3DState s, {int mastered = 0}) =>
    QuestContext.of(s, worldV2, mastered: mastered);

void main() {
  group('敵の動き', () {
    EnemyBrain brain({bool Function(double, double)? walkable}) => EnemyBrain(
      homeX: 0,
      homeZ: 0,
      radius: 10,
      x: 0,
      z: 0,
      seed: 3,
      walkable: walkable ?? (_, _) => true,
    );

    test('主人公がいないときは、自分の範囲の中を歩き回る', () {
      final b = brain();
      var moved = false;
      for (var i = 0; i < 2000; i++) {
        b.update(1 / 30, px: 100, pz: 100);
        if (b.x != 0 || b.z != 0) moved = true;
        expect(distance(b.x, b.z, 0, 0), lessThanOrEqualTo(10.01));
      }
      expect(moved, isTrue);
    });

    test('近くに来ると追いかけ、範囲から遠く離れると戻る。追う速さは歩きより遅い', () {
      final b = brain();
      b.update(1 / 30, px: 5, pz: 0);
      expect(b.chasing, isTrue);
      expect(EnemyBrain.chaseSpeed, lessThan(4.0));
      // 主人公が範囲の外へ逃げた
      for (var i = 0; i < 60; i++) {
        b.update(1 / 30, px: 40, pz: 0);
      }
      expect(b.chasing, isFalse);
    });

    test('通れない場所には入らない', () {
      final b = brain(walkable: (x, _) => x < 2);
      for (var i = 0; i < 600; i++) {
        b.update(1 / 30, px: 6, pz: 0);
        expect(b.x, lessThan(2));
      }
    });

    test('にげた直後は追いかけない。バトル中（止める）は動かない', () {
      final b = brain()..calm(3);
      b.update(1 / 30, px: 3, pz: 0);
      expect(b.chasing, isFalse);
      final c = brain();
      c.update(1, px: 3, pz: 0, frozen: true);
      expect((c.x, c.z), (0.0, 0.0));
    });

    test('はじまりの大地の敵は、範囲の中でも通れる所だけを歩く', () {
      for (final e in worldV2.enemies.where((e) => e.wanders)) {
        final b = EnemyBrain(
          homeX: e.homeX,
          homeZ: e.homeZ,
          radius: e.zoneR,
          x: e.x,
          z: e.z,
          seed: e.id.hashCode,
          walkable: (x, z) => MapV2.walkable(x, z),
        );
        for (var i = 0; i < 900; i++) {
          b.update(1 / 30, px: -100, pz: -100);
          expect(MapV2.walkable(b.x, b.z), isTrue, reason: e.id);
        }
      }
    });
  });

  group('はじまりの大地のクエスト', () {
    final book = QuestBook.land;

    test('村長と話すと始まり、目的を達成したらその場で次へ進む', () {
      var s = Field3DState.start(worldV2);
      expect(book.current(s.questsDone)!.id, 'v_hello');
      // 話しかけるまでは、その場の達成にならない
      expect(book.autoComplete(s.questsDone, _ctx(s)), isEmpty);
      s = s.copyWith(talked: {book.giverId});
      final talk = book.talk(s.questsDone, _ctx(s));
      expect(talk.completed!.id, 'v_hello');
      s = s.copyWith(questsDone: {'v_hello'});
      // スライムをたおす → その場で達成
      s = s.copyWith(defeated: {'v_e1a'});
      final done = book.autoComplete(s.questsDone, _ctx(s));
      expect(done.map((q) => q.id), ['v_first']);
    });

    test('ボス・石碑・祭壇で順に進み、称号がもらえる', () {
      var s = Field3DState.start(worldV2)
          .copyWith(talked: {book.giverId}, questsDone: {'v_hello', 'v_first'});
      expect(book.current(s.questsDone)!.id, 'v_bridge');
      s = s.copyWith(defeated: {'v_b1'}, flags: {'T3'});
      // 橋と石碑を同時に達成していたら、まとめて報告
      expect(book.autoComplete(s.questsDone, _ctx(s)).map((q) => q.id), [
        'v_bridge',
        'v_stele',
      ]);
      s = s.copyWith(
        questsDone: {...s.questsDone, 'v_bridge', 'v_stele'},
        defeated: {'v_b1', 'v_b2'},
        flags: {'T3', 'T2'},
      );
      final more = book.autoComplete(s.questsDone, _ctx(s));
      expect(more.map((q) => q.id), ['v_summit', 'v_temple']);
      s = s.copyWith(questsDone: {...s.questsDone, ...more.map((q) => q.id)});
      expect(book.honors(s.questsDone), ['橋をわたる者', '星見の勇者', 'はじまりの大地の踏破者']);
      expect(book.current(s.questsDone)!.id, 'v_review');
    });

    test('ボスを数えずに「たおした数」を出す', () {
      final s = Field3DState.start(worldV2)
          .copyWith(defeated: {'v_b1', 'v_e1a'});
      final c = _ctx(s);
      expect(c.defeated, 1);
      expect(c.totalEnemies, worldV2.enemies.where((e) => !e.boss).length);
    });

    test('地域ごとにクエストが分かれている', () {
      expect(QuestBook.forRegion('land_v2'), same(QuestBook.land));
      expect(QuestBook.forRegion('meadow_proto'), same(QuestBook.proto));
      expect(QuestBook.proto.autoReport, isFalse);
    });
  });

  group('保存（地域ごと・古い形式の引き継ぎ）', () {
    test('試作の草原の古い保存（tq3d_field_v1）を、そのまま読める', () async {
      const old =
          '{"v":1,"region":"meadow_proto","x":1,"y":0,"z":2,'
          '"defeated":["proto_slime_math"],"talked":["proto_guide"],"quests":["q_hello"]}';
      SharedPreferences.setMockInitialValues({Save3D.fieldKey: old});
      final save = await Save3D.open();
      final proto = save.loadField(Field3DRegion.meadow);
      expect(proto.questsDone, {'q_hello'});
      expect(save.currentRegion, 'meadow_proto');
      expect(save.hasRegion('meadow_proto'), isTrue);
      expect(save.hasRegion(worldV2.id), isFalse);
      // 新しい地域は最初から
      final land = save.loadField(worldV2);
      expect((land.x, land.z), (worldV2.spawnX, worldV2.spawnZ));
      // 新しい地域を保存しても、試作の草原の記録は消えない
      await save.saveField(land.copyWith(x: 100, flags: {'T3'}, rest: 'S2'));
      expect(save.loadField(worldV2).flags, {'T3'});
      expect(save.loadField(worldV2).rest, 'S2');
      expect(save.loadField(Field3DRegion.meadow).questsDone, {'q_hello'});
      expect(save.currentRegion, worldV2.id);
      expect(save.prefs.getString(Save3D.fieldKey), old, reason: '古い保存は消さない');
    });

    test('山の上（高さ 28m）の位置も保存できる', () {
      final s = Field3DState.start(worldV2).copyWith(x: 335, y: 28, z: 110);
      final back = Field3DState.decode(s.encode(), worldV2);
      expect((back.x, back.y, back.z), (335.0, 28.0, 110.0));
      // 地図の外は出発点に戻す
      final out = Field3DState.decode(
        Field3DState.start(worldV2).copyWith(x: -5).encode(),
        worldV2,
      );
      expect((out.x, out.z), (worldV2.spawnX, worldV2.spawnZ));
    });
  });

  test('方角の名前', () {
    expect(compassName(0, -10), '北');
    expect(compassName(10, 0), '東');
    expect(compassName(0, 10), '南');
    expect(compassName(-10, 0), '西');
    expect(compassName(10, -10), '北東');
  });
}
