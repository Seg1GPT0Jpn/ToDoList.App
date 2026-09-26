import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/field/field_map.dart';

bool adjacent(Set<(int, int)> cells, Cell p) => [
  (0, 1),
  (0, -1),
  (1, 0),
  (-1, 0),
].any((d) => cells.contains((p.col + d.$1, p.row + d.$2)));

/// 1本道のマップ（英語ワールド、理科の各系統）に共通するチェック
void checkRoute(String name, FieldMap map, List<StageDef> stages, Cell start) {
  group(name, () {
    test('すべてのステージの敵がマップに1体ずつ置かれている', () {
      expect(map.enemySpots.keys.toSet(), {for (final s in stages) s.order});
    });

    test('外周は壁（出入口をのぞく）', () {
      bool edge(int c, int r) {
        final t = map.tileAt(c, r);
        return t == '#' || t == 'O';
      }

      for (var c = 0; c < map.width; c++) {
        expect(edge(c, 0) && edge(c, map.height - 1), isTrue);
      }
      for (var r = 0; r < map.height; r++) {
        expect(edge(0, r) && edge(map.width - 1, r), isTrue);
      }
    });

    /// 亡霊を置く位置（ゲーム本体と同じく、各部屋の safeCells の真ん中）
    final ghosts = <(int, int)>{
      for (final cells in map.safeCells.values)
        if (cells.isNotEmpty)
          (cells[cells.length ~/ 2].col, cells[cells.length ~/ 2].row),
    };

    /// 並び順が [upTo] より前の敵を倒した状態（ゲート横にどいている）で、スタートから届くマス
    Set<(int, int)> reachable(int upTo, {bool withGhosts = false}) {
      final blocked = <(int, int)>{
        if (withGhosts) ...ghosts,
        for (final e in map.enemySpots.entries)
          if (e.key < upTo)
            (map.asideOf(e.value).col, map.asideOf(e.value).row)
          else
            (e.value.col, e.value.row),
      };
      final seen = <(int, int)>{(start.col, start.row)};
      final queue = Queue.of([(start.col, start.row)]);
      while (queue.isNotEmpty) {
        final (c, r) = queue.removeFirst();
        for (final (dc, dr) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final n = (c + dc, r + dr);
          // ゲーム本体と同じく、地形は isFloor、敵の有無は blocked で判定する
          final passable = !blocked.contains(n) && map.isFloor(n.$1, n.$2);
          if (passable && seen.add(n)) queue.add(n);
        }
      }
      return seen;
    }

    test('敵は1つ前までを倒せば話しかけられ、倒す前は奥へ行けない', () {
      for (final (i, s) in stages.indexed) {
        final spot = map.enemySpots[s.order]!;
        expect(adjacent(reachable(s.order), spot), isTrue, reason: s.name);
        if (i + 1 < stages.length) {
          final next = map.enemySpots[stages[i + 1].order]!;
          expect(
            adjacent(reachable(s.order), next),
            isFalse,
            reason: '${s.name} を倒す前に次の敵へ届いてしまう',
          );
        }
      }
    });

    test('倒した敵は壁のくぼみに寄り、反対側の壁に檻を置ける', () {
      for (final spot in map.enemySpots.values) {
        final aside = map.asideOf(spot);
        expect(aside, isNot(spot));
        expect(map.tileAt(aside.col, aside.row), '#');
        final cage = map.cageOf(spot);
        expect(map.tileAt(cage.col, cage.row), '#');
      }
    });

    test('どのエリアにも宿があり、その先の敵を倒す前に立ち寄れる', () {
      final inns = map.innSpots;
      expect(inns.length, stages.length);
      expect(
        {for (final inn in inns) map.enemyAhead(inn)},
        {for (final s in stages) s.order},
      );
      for (final inn in inns) {
        final n = map.enemyAhead(inn)!;
        expect(adjacent(reachable(n), inn), isTrue, reason: 'ステージ$n 手前の宿');
      }
    });

    test('宝箱は全エリアに1つずつ、泉は2エリアに1つ、どれも立ち寄れる', () {
      final chests = map.findAll('C');
      expect(
        {for (final c in chests) map.enemyAhead(c)},
        {for (final s in stages) s.order},
      );
      expect(chests.length, stages.length);
      expect(map.findAll('W').length, stages.length ~/ 2);
      final all = reachable(1 << 20, withGhosts: true);
      for (final c in [...chests, ...map.findAll('W')]) {
        expect(adjacent(all, c), isTrue, reason: '$c');
      }
    });

    test('全部屋に亡霊がいても、敵・宿・ゴールへの道はふさがれない', () {
      for (final s in stages) {
        final r = reachable(s.order, withGhosts: true);
        expect(adjacent(r, map.enemySpots[s.order]!), isTrue, reason: s.name);
      }
      final all = reachable(1 << 20, withGhosts: true);
      for (final inn in map.innSpots) {
        expect(adjacent(all, inn), isTrue);
      }
      expect(adjacent(all, map.find('G')), isTrue);
      for (final g in ghosts) {
        expect(adjacent(all, (col: g.$1, row: g.$2)), isTrue);
      }
    });

    test('ほどよく障害物がある', () {
      final floors = [
        for (final r in map.rows) ...r.split('').where((c) => c == '.'),
      ].length;
      expect(floors / (map.width * map.height), inInclusiveRange(0.3, 0.75));
    });
  });
}

void main() {
  final english = RpgCatalog.world(RpgCatalog.englishWorldId);
  checkRoute(
    '英語ワールド',
    FieldMap.english,
    english.stages,
    FieldMap.english.start,
  );

  for (final world in RpgCatalog.worlds.where((w) => w.routes.isNotEmpty)) {
    for (final r in world.routes) {
      final map = FieldMap.byId('${world.id}_${r.id}');
      checkRoute(
        '${world.name}・${r.name}',
        map,
        world.stages.where((s) => s.branch == r.id).toList(),
        world.routes.length > 1 ? map.spawnFrom('${world.id}_hub') : map.start,
      );
    }
    if (world.routes.length > 1) {
      test('${world.name}のハブ：すべてのルートの出入口に歩いて行ける', () {
        final hub = FieldMap.byId('${world.id}_hub');
        expect(
          {for (final p in hub.portals.values) p.target},
          {for (final r in world.routes) '${world.id}_${r.id}'},
        );
        final start = hub.start;
        final seen = <(int, int)>{(start.col, start.row)};
        final queue = Queue.of([(start.col, start.row)]);
        while (queue.isNotEmpty) {
          final (c, rr) = queue.removeFirst();
          for (final (dc, dr) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
            final n = (c + dc, rr + dr);
            if (hub.isFloor(n.$1, n.$2) && seen.add(n)) queue.add(n);
          }
        }
        for (final p in hub.portals.keys) {
          expect(adjacent(seen, p), isTrue, reason: '$p');
        }
      });
    }
  }

  group('理の国のスタート地点', () {
    final hub = FieldMap.byId('science_hub');

    test('上＝物理・左＝化学・右＝地学・下＝生物 の出入口がある', () {
      final byTarget = {
        for (final e in hub.portals.entries) e.value.target: e.key,
      };
      expect(byTarget['science_physics']!.row, 0);
      expect(byTarget['science_chemistry']!.col, 0);
      expect(byTarget['science_earth']!.col, hub.width - 1);
      expect(byTarget['science_biology']!.row, hub.height - 1);
    });

    test('スタート地点から4つの出入口すべてに歩いて行ける', () {
      final start = hub.start;
      final seen = <(int, int)>{(start.col, start.row)};
      final queue = Queue.of([(start.col, start.row)]);
      while (queue.isNotEmpty) {
        final (c, r) = queue.removeFirst();
        for (final (dc, dr) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final n = (c + dc, r + dr);
          if (hub.isFloor(n.$1, n.$2) && seen.add(n)) queue.add(n);
        }
      }
      for (final p in hub.portals.keys) {
        expect(adjacent(seen, p), isTrue, reason: '$p');
      }
    });

    test('各系統のマップは、ハブから来た向きの端に帰り口がある', () {
      final expected = {
        'physics': 'bottom',
        'chemistry': 'right',
        'earth': 'left',
        'biology': 'top',
      };
      for (final b in ScienceCatalog.branches) {
        final map = FieldMap.byId('science_${b.id}');
        final back = map.portals.entries
            .singleWhere((e) => e.value.target == 'science_hub')
            .key;
        final side = back.row == 0
            ? 'top'
            : back.row == map.height - 1
            ? 'bottom'
            : back.col == 0
            ? 'left'
            : 'right';
        expect(side, expected[b.id], reason: b.id);
        // ハブの出入口から来ると、そのとなりに立つ
        expect(hub.spawnFrom('science_${b.id}'), isNot(hub.start));
      }
    });
  });
}
