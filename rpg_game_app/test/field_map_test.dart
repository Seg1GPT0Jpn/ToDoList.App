import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/field/field_map.dart';

void main() {
  final map = FieldMap.english;
  final world = RpgCatalog.world(RpgCatalog.englishWorldId);

  test('英語ワールドの全ステージの敵がマップに1体ずつ置かれている', () {
    expect(map.enemySpots.keys.toSet(), {
      for (final s in world.stages) s.order,
    });
  });

  test('外周はすべて壁', () {
    for (var c = 0; c < map.width; c++) {
      expect(map.tileAt(c, 0), '#');
      expect(map.tileAt(c, map.height - 1), '#');
    }
    for (var r = 0; r < map.height; r++) {
      expect(map.tileAt(0, r), '#');
      expect(map.tileAt(map.width - 1, r), '#');
    }
  });

  /// 番号 < [upTo] の敵を倒した状態（ゲート横にどいている）で、スタートから届くマス
  Set<(int, int)> reachable(int upTo) {
    final blocked = <(int, int)>{
      for (final e in map.enemySpots.entries)
        if (e.key < upTo)
          (map.asideOf(e.value).col, map.asideOf(e.value).row)
        else
          (e.value.col, e.value.row),
    };
    final start = map.find('P');
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

  bool adjacent(Set<(int, int)> cells, ({int col, int row}) p) => [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
  ].any((d) => cells.contains((p.col + d.$1, p.row + d.$2)));

  test('ステージ n の敵は、n-1 までを倒せば話しかけられ、倒す前は奥へ行けない', () {
    for (final s in world.stages) {
      final spot = map.enemySpots[s.order]!;
      expect(adjacent(reachable(s.order), spot), isTrue, reason: s.name);
      if (s.order < world.stages.length) {
        final next = map.enemySpots[s.order + 1]!;
        expect(
          adjacent(reachable(s.order), next),
          isFalse,
          reason: '${s.name} を倒す前に次の敵へ届いてしまう',
        );
      }
    }
  });

  test('倒した敵は壁のくぼみに寄り、床をふさがない', () {
    for (final spot in map.enemySpots.values) {
      final aside = map.asideOf(spot);
      expect(aside, isNot(spot));
      expect(map.tileAt(aside.col, aside.row), '#');
    }
  });

  test('ボスを倒すとゴールにたどり着ける', () {
    expect(adjacent(reachable(99), map.find('G')), isTrue);
  });
}
