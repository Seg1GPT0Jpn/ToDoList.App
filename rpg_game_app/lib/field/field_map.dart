/// フィールドのマップ定義（1文字 = 1マス）。
///
///   #  壁（クラフト紙の束）     T  木（インクのしみ）
///   ~  インクの池               .  床（方眼紙）
///   1〜6  ステージの敵（道をふさいでいる）
///   P  スタート地点   S  看板   G  ゴール（トロフィー）   I  宿（授業が受けられる）
class FieldMap {
  FieldMap(this.rows) : width = rows.first.length {
    for (final r in rows) {
      if (r.length != width) {
        throw ArgumentError('マップの行の長さがそろっていません: "$r"');
      }
    }
  }

  final List<String> rows;
  final int width;
  int get height => rows.length;

  String tileAt(int col, int row) {
    if (row < 0 || row >= height || col < 0 || col >= width) return '#';
    return rows[row][col];
  }

  /// 地形として通れるか。敵の立ち位置（1〜9）も地面は床で、
  /// 敵がいるかどうかはゲーム側で別に判定する。
  bool isFloor(int col, int row) {
    final t = tileAt(col, row);
    return t == '.' || t == 'P' || int.tryParse(t) != null;
  }

  ({int col, int row}) find(String ch) {
    for (var r = 0; r < height; r++) {
      final c = rows[r].indexOf(ch);
      if (c >= 0) return (col: c, row: r);
    }
    throw ArgumentError('マップに "$ch" がありません');
  }

  /// 敵の番号（ステージの order）→ 位置
  Map<int, ({int col, int row})> get enemySpots => {
    for (var n = 1; n <= 9; n++)
      if (rows.any((r) => r.contains('$n'))) n: find('$n'),
  };

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
  int? enemyAhead(({int col, int row}) inn) {
    int? best;
    int? bestRow;
    for (final e in enemySpots.entries) {
      if (e.value.row < inn.row && (bestRow == null || e.value.row > bestRow)) {
        best = e.key;
        bestRow = e.value.row;
      }
    }
    return best;
  }

  /// 看板のメッセージ（上から順に）
  static const signMessages = ['ここは英語ワールド。道をふさぐ魔物に話しかけると、4択クイズのバトルが始まるよ。'];

  static final english = FieldMap(const [
    '###############',
    '#T....~~~....T#',
    '#....T.G.T....#',
    '#T...........T#',
    '#######6#######',
    '#TT.........TT#',
    '#T..~~...~~..T#',
    '#............I#',
    '#..T.......T..#',
    '#.............#',
    '#####5#########',
    '#............I#',
    '#.TT.....~~~..#',
    '#.T......~~~..#',
    '#.............#',
    '#.......T...TT#',
    '#########4#####',
    '#I............#',
    '#..~~~~...T...#',
    '#..~~~~.......#',
    '#.......TT....#',
    '#T............#',
    '###3###########',
    '#............I#',
    '#.T.T.T.T.T.T.#',
    '#.............#',
    '#TT.......~~..#',
    '#.............#',
    '##########2####',
    '#............I#',
    '#.~~.....T....#',
    '#.~~..........#',
    '#......T......#',
    '#T...........T#',
    '######1########',
    '#............I#',
    '#..T..S....T..#',
    '#......P......#',
    '#T...........T#',
    '###############',
  ]);
}
