import 'dart:collection';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

/// エリアの地方（床・壁・障害物の見た目）
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

/// ほかのマップへの出入口
typedef Portal = ({String target, String label});

/// フィールドのマップ（1文字 = 1マス）。
///
///   #  壁      .  床      T  障害物（木・岩など、地方ごとに見た目が変わる）
///   ~  水・溶岩  E  ステージの敵（道をふさいでいる）
///   P  スタート地点   S  看板   G  ゴール   I  宿（授業）
///   C  宝箱（難問1問でレアカード）   W  泉（基礎問題で次のバトルのHPアップ）
///   O  出入口（ほかのマップへ移動する）
///
/// 英語ワールドは1枚、理の国はスタート地点（ハブ）と4系統の計5枚。
/// 系統のマップは、上へ進む形で作ってから、進む向き（左・右・下）に回転させる。
class FieldMap {
  FieldMap(
    this.rows, {
    required this.id,
    required List<List<Region>> regionGrid,
    required List<List<int>> areaGrid,
    required this.enemySpots,
    required this.safeCells,
    this.areaLabels = const {},
    this.portals = const {},
    this.signText = '',
    this.goalText = 'トロフィーがある。',
  }) : width = rows.first.length,
       _region = regionGrid,
       _area = areaGrid {
    for (final r in rows) {
      if (r.length != width) {
        throw ArgumentError('マップの行の長さがそろっていません: "$r"');
      }
    }
  }

  final String id;
  final List<String> rows;
  final List<List<Region>> _region;
  final List<List<int>> _area;

  /// エリア番号（ステージの order）→ 敵の位置
  final Map<int, Cell> enemySpots;

  /// エリアごとの「何かを置いても通り道をふさがない床」（亡霊などを置く）
  final Map<int, List<Cell>> safeCells;

  /// エリア番号 → 画面上部に出す名前（なければ地方の名前）
  final Map<int, String> areaLabels;

  /// 出入口のマス → 行き先
  final Map<Cell, Portal> portals;

  /// 看板のメッセージ
  final String signText;

  /// ゴールのトロフィーの説明
  final String goalText;

  final int width;
  int get height => rows.length;

  String tileAt(int col, int row) {
    if (row < 0 || row >= height || col < 0 || col >= width) return '#';
    return rows[row][col];
  }

  Region regionAt(int col, int row) =>
      _region[row.clamp(0, height - 1)][col.clamp(0, width - 1)];

  /// そのマスが属する部屋の番号（その部屋の先にいる敵の番号）
  int areaAt(int col, int row) =>
      _area[row.clamp(0, height - 1)][col.clamp(0, width - 1)];

  /// 画面上部に出すエリアの名前
  String labelAt(int col, int row) =>
      areaLabels[areaAt(col, row)] ?? regionAt(col, row).label;

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

  /// スタート地点
  Cell get start => find('P');

  /// [from] のマップから来たときに立つマス（出入口のとなりの床）。なければスタート地点。
  Cell spawnFrom(String? from) {
    for (final e in portals.entries) {
      if (e.value.target != from) continue;
      for (final (dc, dr) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final c = (col: e.key.col + dc, row: e.key.row + dr);
        if (isFloor(c.col, c.row) && tileAt(c.col, c.row) != 'E') return c;
      }
    }
    return start;
  }

  /// 倒した敵の待機場所。ゲート横の壁のくぼみに寄るので、通り道をふさがない。
  Cell asideOf(Cell gate) {
    for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      if (tileAt(gate.col + dc, gate.row + dr) == '#') {
        return (col: gate.col + dc, row: gate.row + dr);
      }
    }
    return gate;
  }

  /// ゲートをはさんで [asideOf] の反対側の壁（捕まった仲間の檻を置く）
  Cell cageOf(Cell gate) {
    final a = asideOf(gate);
    return (col: gate.col * 2 - a.col, row: gate.row * 2 - a.row);
  }

  /// 宿の位置
  List<Cell> get innSpots => findAll('I');

  /// そのマスの先にいる（次に戦う）敵の番号。ゴールの部屋やハブでは null。
  int? enemyAhead(Cell cell) {
    final a = areaAt(cell.col, cell.row);
    return enemySpots.containsKey(a) ? a : null;
  }

  static const _roomRows = 9;
  static const _width = 31;

  /// 20エリアの英語ワールド（毎回同じ形になる）。
  static final english = _build(
    id: 'english',
    areas: 20,
    seed: 2026,
    roomSeed: 13,
    regionOf: Region.ofArea,
    signText:
        'ここは英語ワールド。20のエリアを越えて、最終章の玉座をめざそう。'
        '魔物に話しかけるとバトル、宿では授業、泉では回復の加護、宝箱には難問とレアカードが待っている。'
        '寄り道も探検してみよう！',
    goalText: '英語ワールドのトロフィー',
  );

  static final Map<String, FieldMap> _cache = {};

  /// マップの ID から取り出す。
  /// `english`、`<worldId>_hub`（ハブ）、`<worldId>_<ルートID>`（ルートのマップ）
  static FieldMap byId(String id) => _cache.putIfAbsent(id, () {
    if (id == 'english') return english;
    final sep = id.indexOf('_');
    final world = RpgCatalog.world(id.substring(0, sep));
    final rest = id.substring(sep + 1);
    if (rest == 'hub') return _hub(world);
    return _route(world, world.route(rest)!);
  });

  /// そのワールドに入ったときの最初のマップ
  static String firstMapOf(String worldId) {
    if (worldId == RpgCatalog.englishWorldId) return 'english';
    final w = RpgCatalog.world(worldId);
    return w.routes.length > 1 ? '${w.id}_hub' : '${w.id}_${w.routes.first.id}';
  }

  static const _palettes = [
    Region.grass,
    Region.coast,
    Region.cave,
    Region.lava,
  ];

  /// スタート地点のハブ。ルートの向きごとに、辺に出入口を並べる（1辺に2つまで）。
  static FieldMap _hub(WorldDef world) {
    final lines = [
      '###########',
      '#.........#',
      '#.T.....T.#',
      '#....S....#',
      '#.........#',
      '#.~.....~.#',
      '#....P....#',
      '#.........#',
      '#.~.....~.#',
      '#.........#',
      '#.T.....T.#',
      '#.........#',
      '###########',
    ].map((l) => l.split('')).toList();
    final h = lines.length, w = lines.first.length;
    final portals = <Cell, Portal>{};
    for (final dir in const ['up', 'left', 'right', 'down']) {
      final rs = world.routes.where((r) => r.direction == dir).toList();
      if (rs.length > 2) throw ArgumentError('1辺の出入口は2つまで: $dir');
      final slots = rs.length == 1 ? const [0.5] : const [0.3, 0.7];
      for (final (i, r) in rs.indexed) {
        final Cell cell = switch (dir) {
          'up' => (col: (w * slots[i]).floor(), row: 0),
          'down' => (col: (w * slots[i]).floor(), row: h - 1),
          'left' => (col: 0, row: (h * slots[i]).floor()),
          _ => (col: w - 1, row: (h * slots[i]).floor()),
        };
        lines[cell.row][cell.col] = 'O';
        portals[cell] = (target: '${world.id}_${r.id}', label: r.name);
      }
    }
    return FieldMap(
      [for (final l in lines) l.join()],
      id: '${world.id}_hub',
      regionGrid: List.generate(h, (_) => List.filled(w, Region.grass)),
      areaGrid: List.generate(h, (_) => List.filled(w, 0)),
      enemySpots: const {},
      safeCells: const {},
      areaLabels: {0: world.hubName},
      portals: portals,
      signText: world.hubSign,
    );
  }

  /// ルートの1本道。上へ進む形で作ってから、ルートの向きに回転させる。
  static FieldMap _route(WorldDef world, RouteInfo route) {
    final stages = world.stages.where((s) => s.branch == route.id).toList();
    final offset = stages.first.order - 1;
    final routeIndex = world.routes.indexOf(route);
    // 分野（section）が変わるごとに地方の見た目を変える
    final sections = <String>[];
    for (final s in stages) {
      if (!sections.contains(s.region)) sections.add(s.region);
    }
    Region regionOf(int k) {
      final s = stages[(k - 1).clamp(0, stages.length - 1)];
      return _palettes[(routeIndex + sections.indexOf(s.region)) % 4];
    }

    final bosses = [
      for (final s in stages)
        if (s.isBoss) 'エリア${s.areaNo}',
    ];
    final hasHub = world.routes.length > 1;
    final up = _build(
      id: '${world.id}_${route.id}',
      areas: stages.length,
      seed: 3000 + offset,
      roomSeed: 5000 + offset * 31,
      regionOf: regionOf,
      orderOffset: offset,
      areaLabel: (k) => k > stages.length
          ? '${route.name}の玉座の先'
          : '${stages[k - 1].region}・エリア$k',
      backPortal: hasHub
          ? (target: '${world.id}_hub', label: world.hubName)
          : null,
      signText:
          'ここから${route.name}の道。${sections.join('、')}を順に進む。'
          'ボスは${bosses.join('と')}。宿で授業を受けてから挑もう。',
      goalText: '${route.name}マスターのトロフィー',
    );
    return up._turned(route.direction);
  }

  /// 上へ進む形のマップを、[dir]（up / down / left / right）へ進む形に向きを変える
  FieldMap _turned(String dir) {
    if (dir == 'up') return this;
    final h = height, w = width;
    // 新しい座標 → もとの座標
    final (int nw, int nh, Cell Function(int c, int r) src) = switch (dir) {
      'down' => (w, h, (c, r) => (col: w - 1 - c, row: h - 1 - r)),
      'left' => (h, w, (c, r) => (col: r, row: c)),
      'right' => (h, w, (c, r) => (col: r, row: h - 1 - c)),
      _ => throw ArgumentError(dir),
    };
    final back = <Cell, Cell>{};
    for (var r = 0; r < nh; r++) {
      for (var c = 0; c < nw; c++) {
        back[src(c, r)] = (col: c, row: r);
      }
    }
    Cell to(Cell old) => back[old]!;
    return FieldMap(
      [
        for (var r = 0; r < nh; r++)
          [for (var c = 0; c < nw; c++) tileAt(src(c, r).col, src(c, r).row)]
              .join(),
      ],
      id: id,
      regionGrid: [
        for (var r = 0; r < nh; r++)
          [for (var c = 0; c < nw; c++) regionAt(src(c, r).col, src(c, r).row)],
      ],
      areaGrid: [
        for (var r = 0; r < nh; r++)
          [for (var c = 0; c < nw; c++) areaAt(src(c, r).col, src(c, r).row)],
      ],
      enemySpots: {for (final e in enemySpots.entries) e.key: to(e.value)},
      safeCells: {
        for (final e in safeCells.entries)
          e.key: [for (final c in e.value) to(c)],
      },
      areaLabels: areaLabels,
      portals: {for (final e in portals.entries) to(e.key): e.value},
      signText: signText,
      goalText: goalText,
    );
  }

  /// 上へ進む1本道のマップを作る。
  ///
  /// 上から：外壁 → ゴールの部屋 → [ゲートn → 部屋n]（n = areas → 1）→ 外壁。
  /// 敵の番号は orderOffset ＋ n（理の国では系統ごとに 16 ずつずらす）。
  static FieldMap _build({
    required String id,
    required int areas,
    required int seed,
    required int roomSeed,
    required Region Function(int area) regionOf,
    int orderOffset = 0,
    String Function(int area)? areaLabel,
    Portal? backPortal,
    String signText = '',
    String goalText = 'トロフィーがある。',
  }) {
    final rnd = Random(seed);
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

    final goalArea = orderOffset + areas + 1;
    add(wall(), regionOf(areas), goalArea);
    final goal = List.filled(_width, '.')
      ..[0] = '#'
      ..[_width - 1] = '#';
    add(goal.join(), regionOf(areas), goalArea);
    add((List.of(goal)..[_width ~/ 2] = 'G').join(), regionOf(areas), goalArea);
    add(goal.join(), regionOf(areas), goalArea);
    for (var n = areas; n >= 1; n--) {
      final region = regionOf(n);
      final gate = gateCols[n - 1];
      enemyRows[orderOffset + n] = rows.length;
      add((wall().split('')..[gate] = 'E').join(), region, orderOffset + n);
      final top = rows.length;
      final room = _Room.generate(
        area: n,
        seed: roomSeed + n * 97,
        entryCol: n > 1 ? gateCols[n - 2] : _width ~/ 2,
        exitCol: gate,
        isStart: n == 1,
        withSign: signText.isNotEmpty,
      );
      for (final line in room.lines) {
        add(line, region, orderOffset + n);
      }
      safe[orderOffset + n] = [
        for (final c in room.safe) (col: c.col, row: c.row + top),
      ];
    }
    final bottom = wall().split('');
    final portals = <Cell, Portal>{};
    if (backPortal != null) {
      bottom[_width ~/ 2] = 'O';
      portals[(col: _width ~/ 2, row: rows.length)] = backPortal;
    }
    add(bottom.join(), regionOf(1), orderOffset + 1);

    return FieldMap(
      rows,
      id: id,
      regionGrid: [for (final r in regions) List.filled(_width, r)],
      areaGrid: [for (final a in areaOfRow) List.filled(_width, a)],
      enemySpots: {
        for (final e in enemyRows.entries)
          e.key: (col: gateCols[e.key - orderOffset - 1], row: e.value),
      },
      safeCells: safe,
      areaLabels: {
        if (areaLabel != null)
          for (var n = 1; n <= areas + 1; n++) orderOffset + n: areaLabel(n),
      },
      portals: portals,
      signText: signText,
      goalText: goalText,
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
    required int seed,
    required int entryCol,
    required int exitCol,
    required bool isStart,
    bool withSign = true,
  }) {
    final rnd = Random(seed);
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
      if (withSign && canBlock(h - 3, entryCol - 2)) {
        place('S', h - 3, entryCol - 2);
      }
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
