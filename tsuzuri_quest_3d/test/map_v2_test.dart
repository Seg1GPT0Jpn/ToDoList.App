import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:tsuzuri_quest_3d/game/field3d.dart';
import 'package:tsuzuri_quest_3d/game/geo2d.dart';
import 'package:tsuzuri_quest_3d/game/map_v2.dart';
import 'package:tsuzuri_quest_3d/game/questions.dart';
import 'package:tsuzuri_quest_3d/game/quest3d.dart';
import 'package:tsuzuri_quest_3d/game/world_v2.dart';

const _open = {MapV2.bridgeKey};

bool _walk(double x, double z) => MapV2.walkable(x, z, open: _open);

void main() {
  final grid = HeightGrid.build();

  group('地形と道（第 2.1 版の設計図）', () {
    test('格子の高さは、もとの高さと格子点で一致する', () {
      for (final (i, j) in [
        (0, 0),
        (42, 155),
        (100, 105),
        (167, 51),
        (200, 200),
      ]) {
        expect(
          grid.at(i, j),
          closeTo(MapV2.rawHeight(i * grid.step, j * grid.step), 1e-4),
        );
      }
    });

    test('どの道も、全区間を歩けて、急な坂や段差がない', () {
      for (final r in MapV2.roads) {
        for (var i = 0; i + 1 < r.points.length; i++) {
          if (i == r.bridgeSegment) continue;
          final a = r.points[i], b = r.points[i + 1];
          final len = distance(a.$1, a.$2, b.$1, b.$2);
          double? prev;
          for (var s = 0.0; s <= len; s += 0.5) {
            final x = lerp(a.$1, b.$1, s / len), z = lerp(a.$2, b.$2, s / len);
            expect(_walk(x, z), isTrue, reason: '${r.id} ($x, $z) が通れない');
            final h = grid.heightAt(x, z);
            if (prev != null) {
              // 物理の自動段差（0.25m）と、登れる坂（35 度）の内側
              expect(
                (h - prev).abs(),
                lessThan(0.25),
                reason: '${r.id} ($x, $z) の段差',
              );
              final deg = math.atan((h - prev).abs() / 0.5) * 180 / math.pi;
              expect(deg, lessThan(30), reason: '${r.id} ($x, $z) の坂');
            }
            prev = h;
          }
        }
      }
    });

    test('道の設計上の傾きは、登れる上限（35 度）より十分ゆるい', () {
      final trail = MapV2.roads.firstWhere((r) => r.id == 'trail');
      final slopes = trail.slopes();
      expect(slopes[1], closeTo(13.5, 0.1), reason: '第 1 スロープ');
      expect(slopes[3], closeTo(19.65, 0.1), reason: '第 2 スロープ');
      for (final r in MapV2.roads) {
        for (final d in r.slopes()) {
          expect(d, lessThan(25), reason: r.id);
        }
      }
    });

    test('通れない場所：川・地図の外・森の奥・山のふもとの崖・岩壁・山頂のふち', () {
      expect(_walk(214, 170), isFalse, reason: '川');
      expect(_walk(205, 300), isFalse, reason: '川');
      expect(_walk(0.5, 200), isFalse, reason: '地図の外');
      expect(_walk(30, 60), isFalse, reason: '森の奥');
      expect(_walk(270, 100), isFalse, reason: 'ふもとの崖');
      expect(_walk(380, 270), isFalse, reason: '岩壁');
      expect(_walk(380, 122.5), isFalse, reason: '山頂のふち');
      expect(_walk(320, 0.5), isFalse, reason: '岩峰');
      // 通れる場所
      expect(_walk(186, 252), isTrue, reason: '浅瀬');
      expect(_walk(65, 125), isTrue, reason: '森の隠し広場');
      expect(_walk(360, 150), isTrue, reason: '中腹の踊り場');
      expect(_walk(350, 60), isTrue, reason: '山頂');
      expect(_walk(380, 220), isTrue, reason: '谷道');
      expect(_walk(130, 200), isTrue, reason: '草原');
    });

    test('古橋は、番人をたおすまでわたれない', () {
      expect(MapV2.walkable(220, 210), isFalse);
      expect(MapV2.walkable(220, 210, open: {MapV2.bridgeKey}), isTrue);
      expect(MapV2.walkable(220, 205), isFalse, reason: '欄干の外は川');
    });

    test('橋の両端は川岸の外にあり、川をまたいでいる', () {
      expect(
        MapV2.riverDistance(MapV2.bridgeX0, 210),
        greaterThan(MapV2.riverBlock),
      );
      expect(
        MapV2.riverDistance(MapV2.bridgeX1, 210),
        greaterThan(MapV2.riverBlock),
      );
      expect(MapV2.riverDistance(220, 210), lessThan(1));
    });

    test('広場は川に重ならない（B1 は半径 9m に縮めた）', () {
      for (final p in MapV2.plazas) {
        expect(
          MapV2.riverDistance(p.x, p.z) - p.r,
          greaterThan(MapV2.riverHalfWidth),
          reason: p.id,
        );
      }
    });

    test('登山道の坂の両側からは落ちない（石壁）', () {
      // 第 2 スロープの横（踊り場の高さ）には入れない
      expect(_walk(330, 135), isFalse);
      expect(_walk(325, 131.5), isTrue, reason: '坂の上');
    });
  });

  group('はじまりの大地の配置', () {
    const w = worldV2;

    test('出発点・人・敵・しらべる場所・出口・戻る場所は、すべて歩ける場所', () {
      final pts = <(String, double, double)>[
        ('P', w.spawnX, w.spawnZ),
        for (final n in w.npcs) (n.id, n.x, n.z + 1.5),
        for (final e in w.enemies) ...[
          (e.id, e.x, e.z),
          (e.id, e.homeX, e.homeZ),
          if (e.winX != null) ('${e.id} win', e.winX!, e.winZ!),
          if (e.loseX != null) ('${e.id} lose', e.loseX!, e.loseZ!),
        ],
        for (final ev in w.events) (ev.id, ev.x, ev.z),
        for (final g in w.gates) (g.id, g.x, g.z),
      ];
      for (final (id, x, z) in pts) {
        expect(w.contains(x, z), isTrue, reason: id);
        expect(_walk(x, z), isTrue, reason: '$id ($x, $z)');
      }
    });

    test('敵の ID は重ならず、ボスは 2 体', () {
      final ids = w.enemies.map((e) => e.id).toSet();
      expect(ids, hasLength(w.enemies.length));
      expect(w.enemies.where((e) => e.boss).map((e) => e.id), ['v_b1', 'v_b2']);
    });

    test('E1・E3・E4 の範囲はメインの道をふさがない。E5 は西の迂回路で避けられる', () {
      double routeDist(Enemy3D e, String road) => polylineDistance(
        e.homeX,
        e.homeZ,
        MapV2.roads.firstWhere((r) => r.id == road).xz,
      );
      for (final e in w.enemies.where((e) => !e.boss)) {
        final zone = e.id.substring(0, 4);
        if (zone == 'v_e1' || zone == 'v_e3') {
          expect(
            routeDist(e, 'route1') - e.zoneR,
            greaterThan(3),
            reason: e.id,
          );
        }
        if (zone == 'v_e4') {
          expect(routeDist(e, 'trail') - e.zoneR, greaterThan(3), reason: e.id);
        }
        if (zone == 'v_e5') {
          expect(
            routeDist(e, 'route4w') - e.zoneR,
            greaterThan(3),
            reason: e.id,
          );
        }
        if (zone == 'v_e1') {
          // 村の柵（X=138）の外
          expect(e.homeX - e.zoneR, greaterThan(138), reason: e.id);
        }
      }
    });

    test('ボスは道の上にいて、近づくと必ず戦う（橋と遺跡の手前）', () {
      final b1 = w.enemyById('v_b1')!, b2 = w.enemyById('v_b2')!;
      expect(distance(b1.x, b1.z, MapV2.bridgeX0, 210), lessThan(b1.triggerR));
      expect(distance(b2.x, b2.z, 335, 85), lessThan(20));
      // 負けたときに戻る場所は、ボスの範囲の外
      for (final b in [b1, b2]) {
        expect(
          distance(b.x, b.z, b.loseX!, b.loseZ!),
          greaterThan(b.triggerR + 4),
        );
      }
    });

    test('クエストの目的の場所は、すべて歩ける場所', () {
      for (final q in QuestBook.land.chain) {
        if (q.targetX == null) continue;
        expect(_walk(q.targetX!, q.targetZ!), isTrue, reason: q.id);
      }
    });

    test('敵と宝箱・石碑の問題は、既存のステージに 4 問以上ある', () {
      final ids = [
        for (final e in w.enemies) (e.worldId, e.stageId),
        for (final ev in w.events)
          if (ev.stageId != null) (ev.worldId!, ev.stageId!),
      ];
      for (final (worldId, stageId) in ids) {
        final world = RpgCatalog.world(worldId);
        final stage = world.stages.firstWhere((s) => s.id == stageId);
        final f = File('../rpg_game/assets/question_bundles/$worldId.json');
        final bundle = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        var n = 0;
        for (final id in stage.questionSetIds) {
          final raw = bundle[id];
          if (raw == null) continue;
          final set = QuestionSet.fromJson(raw as Map<String, dynamic>);
          if (set.origin.usableInRpg) {
            n += set.questions.where(Questions3D.playable).length;
          }
        }
        expect(n, greaterThanOrEqualTo(4), reason: stageId);
      }
    });
  });
}
