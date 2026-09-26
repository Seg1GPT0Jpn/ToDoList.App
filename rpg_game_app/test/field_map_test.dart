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

  /// 亡霊を置く位置（ゲーム本体と同じく、各部屋の safeCells の真ん中）
  final ghosts = <(int, int)>{
    for (final cells in map.safeCells.values)
      if (cells.isNotEmpty)
        (cells[cells.length ~/ 2].col, cells[cells.length ~/ 2].row),
  };

  /// 番号 < [upTo] の敵を倒した状態（ゲート横にどいている）で、スタートから届くマス。
  /// [withGhosts] なら全部屋に亡霊が立っている状態。
  Set<(int, int)> reachable(int upTo, {bool withGhosts = false}) {
    final blocked = <(int, int)>{
      if (withGhosts) ...ghosts,
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

  test('どのエリアにも宿があり、その先の敵を倒す前に立ち寄れる', () {
    final inns = map.innSpots;
    expect(inns.length, world.stages.length);
    final ahead = {for (final inn in inns) map.enemyAhead(inn)};
    expect(ahead, {for (final s in world.stages) s.order});
    for (final inn in inns) {
      final n = map.enemyAhead(inn)!;
      expect(adjacent(reachable(n), inn), isTrue, reason: 'ステージ$n 手前の宿');
    }
  });

  test('ボスを倒すとゴールにたどり着ける', () {
    expect(adjacent(reachable(99), map.find('G')), isTrue);
  });

  test('宝箱は全エリアに1つずつ、泉は2エリアに1つあり、どれも立ち寄れる', () {
    final chests = map.findAll('C');
    expect(chests.length, world.stages.length);
    expect(
      {for (final c in chests) map.enemyAhead(c)},
      {for (final s in world.stages) s.order},
    );
    expect(map.findAll('W').length, world.stages.length ~/ 2);
    final all = reachable(99, withGhosts: true);
    for (final c in [...chests, ...map.findAll('W')]) {
      expect(adjacent(all, c), isTrue, reason: '$c');
    }
  });

  test('全部屋に亡霊がいても、敵・宿・ゴールへの道はふさがれない', () {
    for (final s in world.stages) {
      final r = reachable(s.order, withGhosts: true);
      expect(adjacent(r, map.enemySpots[s.order]!), isTrue, reason: s.name);
    }
    final all = reachable(99, withGhosts: true);
    for (final inn in map.innSpots) {
      expect(adjacent(all, inn), isTrue);
    }
    expect(adjacent(all, map.find('G')), isTrue);
    for (final g in ghosts) {
      expect(adjacent(all, (col: g.$1, row: g.$2)), isTrue);
    }
  });

  test('捕まった仲間の檻はゲートの反対側の壁に置ける', () {
    for (final gate in map.enemySpots.values) {
      final aside = map.asideOf(gate);
      final cage = (col: gate.col * 2 - aside.col, row: gate.row);
      expect(map.tileAt(cage.col, cage.row), '#');
    }
  });

  test('部屋は毎回同じ形で、ほどよく障害物がある', () {
    final floors = [
      for (final r in map.rows) ...r.split('').where((c) => c == '.'),
    ].length;
    final total = map.width * map.height;
    expect(floors / total, inInclusiveRange(0.3, 0.75));
  });
}
