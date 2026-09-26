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

/// フィールドのマップ（1文字 = 1マス）。
///
///   #  壁      .  床      T  障害物（木・岩など、地方ごとに見た目が変わる）
///   ~  水・溶岩  E  ステージの敵（道をふさいでいる）
///   P  スタート地点   S  看板   G  ゴール   I  宿（授業が受けられる）
class FieldMap {
  FieldMap(this.rows, {required this.regions, required this.enemySpots})
    : width = rows.first.length {
    for (final r in rows) {
      if (r.length != width) {
        throw ArgumentError('マップの行の長さがそろっていません: "$r"');
      }
    }
  }

  final List<String> rows;

  /// 行ごとの地方
  final List<Region> regions;

  /// エリア番号（ステージの order）→ 敵の位置
  final Map<int, ({int col, int row})> enemySpots;
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

  ({int col, int row}) find(String ch) {
    for (var r = 0; r < height; r++) {
      final c = rows[r].indexOf(ch);
      if (c >= 0) return (col: c, row: r);
    }
    throw ArgumentError('マップに "$ch" がありません');
  }

  /// 倒した敵の待機場所。ゲート横の壁のくぼみに寄るので、通り道をふさがない。
  ({int col, int row}) asideOf(({int col, int row}) gate) {
    for (final dc in [1, -1]) {
      if (tileAt(gate.col + dc, gate.row) == '#') {
        return (col: gate.col + dc, row: gate.row);
      }
    }
    return gate;
  }

  /// 宿の位置
  List<({int col, int row})> get innSpots => [
    for (var r = 0; r < height; r++)
      for (var c = 0; c < width; c++)
        if (rows[r][c] == 'I') (col: c, row: r),
  ];

  /// 宿の先にいる（次に戦う）敵の番号。宿より上にある一番近いゲートの敵。
  int? enemyAhead(({int col, int row}) cell) {
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
        '道をふさぐ魔物に話しかけるとバトル、宿に話しかけると授業が受けられるよ。',
  ];

  static const _roomRows = 5;
  static const _width = 15;

  /// ゲートの列（エリアごとに左右へずらして、まっすぐ進めないようにする）
  static const _gateCols = [
    7,
    3,
    10,
    5,
    11,
    2,
    8,
    12,
    4,
    9,
    6,
    11,
    3,
    8,
    12,
    5,
    9,
    2,
    10,
    7,
  ];

  /// 20エリアの英語ワールドを作る（毎回同じ形になる）。
  static final english = _build(20);

  static FieldMap _build(int areas) {
    final rows = <String>[];
    final regions = <Region>[];
    final enemyRows = <int, int>{};
    String wall() => '#' * _width;

    // 上から順に積む：外壁 → ゴールの部屋 → エリア20のゲート → エリア20の部屋 → … → エリア1の部屋 → 外壁
    rows.add(wall());
    regions.add(Region.lava);
    for (final line in [
      '#.............#',
      '#......G......#',
      '#.............#',
    ]) {
      rows.add(line);
      regions.add(Region.lava);
    }
    for (var n = areas; n >= 1; n--) {
      final region = Region.ofArea(n);
      final gate = _gateCols[n - 1];
      final gateRow = wall().split('')..[gate] = 'E';
      enemyRows[n] = rows.length;
      rows.add(gateRow.join());
      regions.add(region);
      final room = _room(n, region);
      rows.addAll(room);
      for (var i = 0; i < room.length; i++) {
        regions.add(region);
      }
    }
    rows.add(wall());
    regions.add(Region.grass);

    return FieldMap(
      rows,
      regions: regions,
      enemySpots: {
        for (final e in enemyRows.entries)
          e.key: (col: _gateCols[e.key - 1], row: e.value),
      },
    );
  }

  /// エリア n の部屋（ゲート n の手前）。
  /// 1・3・5行目は通り道として空けておき、障害物は2・4行目にだけ置く。
  static List<String> _room(int n, Region region) {
    final rnd = Random(n * 31 + 7);
    final grid = List.generate(
      _roomRows,
      (_) => ['#', ...List.filled(_width - 2, '.'), '#'],
    );
    final gateAbove = _gateCols[n - 1];
    final gateBelow = n > 1 ? _gateCols[n - 2] : -1;
    for (final r in [1, 3]) {
      var c = 1 + rnd.nextInt(2);
      while (c < _width - 1) {
        final free = c != gateAbove && c != gateBelow;
        if (free && rnd.nextDouble() < 0.45) {
          grid[r][c] = 'T';
          c += 2; // 横に並べない（縦の通り道を残す）
        } else {
          c += 1;
        }
      }
    }
    // 水（溶岩）の小さな池
    final pr = [1, 3][rnd.nextInt(2)];
    final pc = 2 + rnd.nextInt(_width - 6);
    for (final c in [pc, pc + 1]) {
      if (c != gateAbove && c != gateBelow) grid[pr][c] = '~';
    }
    // 宿は真ん中の行の端（ゲートと反対側）
    grid[2][gateAbove <= 7 ? _width - 2 : 1] = 'I';
    if (n == 1) {
      grid[3] = ['#', ...List.filled(_width - 2, '.'), '#'];
      grid[3][7] = 'P';
      grid[1][5] = 'S';
      if (grid[1][4] == '~') grid[1][4] = '.';
    }
    return [for (final r in grid) r.join()];
  }
}
