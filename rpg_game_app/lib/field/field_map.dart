import 'dart:collection';
import 'dart:math';

/// エリアの地方
enum Region {
  grass('草原エリア'),
  coast('海岸エリア'),
  cave('洞窟エリア'),
  lava('溶岩エリア');

  const Region(this.label);
  final String label;

  static Region ofArea(int area) => area <= 5
      ? grass
      : area <= 10
      ? coast
      : area <= 15
      ? cave
      : lava;
}

typedef Cell = ({int col, int row});

/// フィールドのマップ（1文字 = 1マス）。
///
///   #  壁      .  床      T  障害物（木・岩など、地方ごとに見た目が変わる）
///   ~  水・溶岩  E  ステージの敵（道をふさいでいる）
///   P  スタート地点   S  看板   G  ゴール   I  宿（授業）
///   C  宝箱（難問1問でレアカード）   W  泉（基礎問題で次のバトルのHPアップ）
class FieldMap {
  FieldMap(
    this.rows, {
    required this.regions,
    required this.enemySpots,
    required this.areaOfRow,
    required this.safeCells,
  }) : width = rows.first.length {
    for (final r in rows) {
      if (r.length != width) {
        throw ArgumentError('マップの行の長さがそろっていません: "$r"');
      }
    }
  }

  final List<String> rows;

  /// 行ごとの地方
  final List<Region> regions;

  /// 行ごとのエリア番号（その部屋の先にいる敵の番号。ゴールの部屋は 21）
  final List<int> areaOfRow;

  /// エリア番号（ステージの order）→ 敵の位置
  final Map<int, Cell> enemySpots;

  /// エリアごとの「何かを置いても通り道をふさがない床」（亡霊や捕まった仲間を置く）
  final Map<int, List<Cell>> safeCells;

  final int width;
  int get height => rows.length;

  String tileAt(int col, int row) {
    if (row < 0 || row >= height || col < 0 || col >= width) return '#';
    return rows[row][col];
  }

  Region regionAt(int row) => regions[row.clamp(0, height - 1)];

  /// 地形として通れるか（敵の立ち位置も地面は床。敵の有無はゲーム側で判定する）
  bool isFloor(int col, int row) {
    final t = tileAt(col, row);
    return t == '.' || t == 'P' || t == 'E';
  }

  Cell find(String ch) {
    for (var r = 0; r < height; r++) {
      final c = rows[r].indexOf(ch);
      if (c >= 0) return (col: c, row: r);
    }
    throw ArgumentError('マップに "$ch" がありません');
  }

  List<Cell> findAll(String ch) => [
    for (var r = 0; r < height; r++)
      for (var c = 0; c < width; c++)
        if (rows[r][c] == ch) (col: c, row: r),
  ];

  /// 倒した敵の待機場所。ゲート横の壁のくぼみに寄るので、通り道をふさがない。
  Cell asideOf(Cell gate) {
    for (final dc in [1, -1]) {
      if (tileAt(gate.col + dc, gate.row) == '#') {
        return (col: gate.col + dc, row: gate.row);
      }
    }
    return gate;
  }

  /// 宿の位置
  List<Cell> get innSpots => findAll('I');

  /// そのマスの先にいる（次に戦う）敵の番号。上にある一番近いゲートの敵。
  int? enemyAhead(Cell cell) {
    int? best;
    int? bestRow;
    for (final e in enemySpots.entries) {
      if (e.value.row < cell.row &&
          (bestRow == null || e.value.row > bestRow)) {
        best = e.key;
        bestRow = e.value.row;
      }
    }
    return best;
  }

  /// 看板のメッセージ
  static const signMessages = [
    'ここは英語ワールド。20のエリアを越えて、最終章の玉座をめざそう。'
        '魔物に話しかけるとバトル、宿では授業、泉では回復の加護、宝箱には難問とレアカードが待っている。'
        '寄り道も探検してみよう！',
  ];

  static const _roomRows = 9;
  static const _width = 31;

  /// 20エリアの英語ワールド（毎回同じ形になる）。
  static final english = _build(20);

  static FieldMap _build(int areas) {
    final rnd = Random(2026);
    // ゲートの列（左右に大きくずらして、寄り道したくなる形にする）
    final gateCols = [
      for (var n = 1; n <= areas; n++) 3 + rnd.nextInt(_width - 6),
    ];
    final rows = <String>[];
    final regions = <Region>[];
    final areaOfRow = <int>[];
    final enemyRows = <int, int>{};
    final safe = <int, List<Cell>>{};
    String wall() => '#' * _width;

    void add(String line, Region region, int area) {
      rows.add(line);
      regions.add(region);
      areaOfRow.add(area);
    }

    // 上から：外壁 → ゴールの部屋 → [ゲートn → 部屋n] (n = 20 → 1) → 外壁
    add(wall(), Region.lava, areas + 1);
    final goal = List.filled(_width, '.')
      ..[0] = '#'
      ..[_width - 1] = '#';
    add(goal.join(), Region.lava, areas + 1);
    add((List.of(goal)..[_width ~/ 2] = 'G').join(), Region.lava, areas + 1);
    add(goal.join(), Region.lava, areas + 1);
    for (var n = areas; n >= 1; n--) {
      final region = Region.ofArea(n);
      final gate = gateCols[n - 1];
      enemyRows[n] = rows.length;
      add((wall().split('')..[gate] = 'E').join(), region, n);
      final top = rows.length;
      final room = _Room.generate(
        area: n,
        entryCol: n > 1 ? gateCols[n - 2] : _width ~/ 2,
        exitCol: gate,
        isStart: n == 1,
      );
      for (final line in room.lines) {
        add(line, region, n);
      }
      safe[n] = [for (final c in room.safe) (col: c.col, row: c.row + top)];
    }
    add(wall(), Region.grass, 1);

    return FieldMap(
      rows,
      regions: regions,
      areaOfRow: areaOfRow,
      enemySpots: {
        for (final e in enemyRows.entries)
          e.key: (col: gateCols[e.key - 1], row: e.value),
      },
      safeCells: safe,
    );
  }
}

/// 1エリアの部屋（9行 × 31列）を作る。
///
/// 1. ランダムに埋めた障害物を「まわりに多ければ残す」ルールで何度かならし、自然な木立・岩場にする
/// 2. 入口（下のゲート）から出口（上のゲート）まで、くねくねした道を掘る
/// 3. 入口から行けない場所は障害物で埋める（閉じこめられる場所をなくす）
/// 4. 入口の近くに宿、入口から一番遠い行き止まりに宝箱、途中に泉を置く
class _Room {
  _Room(this.lines, this.safe);

  final List<String> lines;

  /// 部屋の中の座標（row は部屋の中での行）
  final List<Cell> safe;

  static const h = FieldMap._roomRows;
  static const w = FieldMap._width;

  static _Room generate({
    required int area,
    required int entryCol,
    required int exitCol,
    required bool isStart,
  }) {
    final rnd = Random(area * 97 + 13);
    // true = 障害物
    var g = List.generate(
      h,
      (r) => List.generate(w, (c) {
        if (c == 0 || c == w - 1) return true;
        return rnd.nextDouble() < 0.5;
      }),
    );
    for (var i = 0; i < 2; i++) {
      final next = List.generate(
        h,
        (r) => List.generate(w, (c) {
          if (c == 0 || c == w - 1) return true;
          var n = 0;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final rr = r + dr, cc = c + dc;
              if (rr < 0 || rr >= h || cc < 0 || cc >= w || g[rr][cc]) n++;
            }
          }
          return n >= 5;
        }),
      );
      g = next;
    }
    // 入口から出口まで道を掘る（横に寄り道しながら）
    var r = h - 1, c = entryCol;
    void open(int rr, int cc) {
      if (rr >= 0 && rr < h && cc > 0 && cc < w - 1) g[rr][cc] = false;
    }

    open(r, c);
    while (r > 0 || c != exitCol) {
      final roll = rnd.nextDouble();
      if (r > 0 && (roll < 0.35 || c == exitCol && roll < 0.8)) {
        r--;
      } else if (c != exitCol && roll < 0.85) {
        c += c < exitCol ? 1 : -1;
      } else {
        final side = rnd.nextBool() ? 1 : -1;
        if (c + side > 1 && c + side < w - 2) c += side;
      }
      open(r, c);
      if (rnd.nextDouble() < 0.4) open(r, c + 1); // ところどころ道幅を広げる
    }
    open(0, exitCol);

    // 入口から行けない床は埋める
    Set<(int, int)> reach(List<List<bool>> grid) {
      final seen = <(int, int)>{};
      final q = Queue<(int, int)>();
      if (!grid[h - 1][entryCol]) {
        q.add((h - 1, entryCol));
        seen.add((h - 1, entryCol));
      }
      while (q.isNotEmpty) {
        final (rr, cc) = q.removeFirst();
        for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nr = rr + dr, nc = cc + dc;
          if (nr < 0 || nr >= h || nc < 0 || nc >= w) continue;
          if (grid[nr][nc] || !seen.add((nr, nc))) continue;
          q.add((nr, nc));
        }
      }
      return seen;
    }

    final reachable = reach(g);
    for (var rr = 0; rr < h; rr++) {
      for (var cc = 0; cc < w; cc++) {
        if (!reachable.contains((rr, cc))) g[rr][cc] = true;
      }
    }

    // 文字にする。障害物の一部はかたまりで水（溶岩）の池にする
    var pond = List.generate(
      h,
      (_) => List.generate(w, (_) => rnd.nextDouble() < 0.42),
    );
    for (var i = 0; i < 2; i++) {
      pond = List.generate(
        h,
        (r) => List.generate(w, (c) {
          var n = 0;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              final rr = r + dr, cc = c + dc;
              if (rr >= 0 && rr < h && cc >= 0 && cc < w && pond[rr][cc]) n++;
            }
          }
          return n >= 5;
        }),
      );
    }
    final tiles = List.generate(
      h,
      (rr) => List.generate(w, (cc) {
        if (cc == 0 || cc == w - 1) return '#';
        if (!g[rr][cc]) return '.';
        return pond[rr][cc] ? '~' : 'T';
      }),
    );

    // 置いても道をふさがないマスか（出口まで・すべての床まで行けるままか）
    bool canBlock(int rr, int cc) {
      if (g[rr][cc]) return false;
      if ((rr == h - 1 && cc == entryCol) || (rr == 0 && cc == exitCol)) {
        return false;
      }
      final copy = [
        for (final row in g) [...row],
      ];
      copy[rr][cc] = true;
      final after = reach(copy);
      return after.length == reachable.length - 1;
    }

    void place(String ch, int rr, int cc) {
      tiles[rr][cc] = ch;
      g[rr][cc] = true;
      reachable.remove((rr, cc));
    }

    // 入口からの距離
    Map<(int, int), int> distances() {
      final d = <(int, int), int>{(h - 1, entryCol): 0};
      final q = Queue<(int, int)>()..add((h - 1, entryCol));
      while (q.isNotEmpty) {
        final (rr, cc) = q.removeFirst();
        for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nr = rr + dr, nc = cc + dc;
          if (nr < 0 || nr >= h || nc < 0 || nc >= w || g[nr][nc]) continue;
          if (d.containsKey((nr, nc))) continue;
          d[(nr, nc)] = d[(rr, cc)]! + 1;
          q.add((nr, nc));
        }
      }
      return d;
    }

    // スタート地点と看板
    if (isStart) {
      place('P', h - 2, entryCol);
      g[h - 2][entryCol] = false; // P は歩ける
      reachable.add((h - 2, entryCol));
      if (canBlock(h - 3, entryCol - 2)) place('S', h - 3, entryCol - 2);
    }
    // 宿：入口に近い床
    var d = distances();
    final innCand =
        d.entries
            .where((e) => e.value >= 2 && e.value <= 8)
            .map((e) => e.key)
            .toList()
          ..sort((a, b) => d[a]!.compareTo(d[b]!));
    for (final (rr, cc) in innCand) {
      if (canBlock(rr, cc)) {
        place('I', rr, cc);
        break;
      }
    }
    // 宝箱：入口から一番遠い床（行き止まりの奥）
    d = distances();
    final far = d.keys.toList()..sort((a, b) => d[b]!.compareTo(d[a]!));
    for (final (rr, cc) in far) {
      if (rr == 0 && cc == exitCol) continue;
      if (canBlock(rr, cc)) {
        place('C', rr, cc);
        break;
      }
    }
    // 泉：2エリアに1つ、真ん中くらいの距離に
    if (area.isEven) {
      d = distances();
      final maxD = d.values.reduce(max);
      final mid = d.keys.where((k) => (d[k]! - maxD ~/ 2).abs() <= 3).toList()
        ..shuffle(rnd);
      for (final (rr, cc) in mid) {
        if (canBlock(rr, cc)) {
          place('W', rr, cc);
          break;
        }
      }
    }

    // 亡霊などを置いても道をふさがないマス（入口から近すぎない床）
    d = distances();
    final safe = <Cell>[
      for (final e in d.entries)
        if (e.value >= 3 && canBlock(e.key.$1, e.key.$2))
          (col: e.key.$2, row: e.key.$1),
    ]..sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);

    return _Room([for (final row in tiles) row.join()], safe);
  }
}
