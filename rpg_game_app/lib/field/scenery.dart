import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui' show Offset, Rect;

import 'package:rpg_game/rpg_game.dart';

import 'field_map.dart';
import 'paper_art.dart';
import 'terrain_art.dart';

/// 障害物の描き方
enum _Obs {
  tree,
  blossom,
  pine,
  snowPine,
  palm,
  cactus,
  rock,
  crystal,
  spike,
  cloud,

  /// 建物の中・町の小物（柱・本棚・家・木箱）。1つずつ描く
  indoor,
}

/// 地形ごとの色
class _Palette {
  const _Palette({
    required this.ground,
    required this.patch,
    required this.path,
    required this.pathEdge,
    required this.leaf,
    required this.leafDark,
    required this.leafLight,
    required this.obs,
    required this.detail,
  });

  /// 地面と、地面のむら（水彩のしみ）
  final int ground;
  final int patch;

  /// 道とそのふち
  final int path;
  final int pathEdge;

  /// 茂み・木の葉（ふつう・かげ・光）
  final int leaf;
  final int leafDark;
  final int leafLight;
  final _Obs obs;

  /// 地面の小さな描きこみの色（草・小石・砂紋など）
  final int detail;
}

_Palette _paletteOf(Terrain t) => switch (t) {
  Terrain.meadow || Terrain.hill => const _Palette(
    ground: 0xFFEAF1D2,
    patch: 0xFFC9DFA0,
    path: 0xFFE8D5AC,
    pathEdge: 0xFFC9AE7E,
    leaf: 0xFF7DB45E,
    leafDark: 0xFF3F6E35,
    leafLight: 0xFFB5DB8C,
    obs: _Obs.tree,
    detail: 0xFF7FA95A,
  ),
  Terrain.flower => const _Palette(
    ground: 0xFFF2EFD8,
    patch: 0xFFF6CFD8,
    path: 0xFFEEDCB8,
    pathEdge: 0xFFD2B88C,
    leaf: 0xFFF3A9BE,
    leafDark: 0xFFB0566F,
    leafLight: 0xFFFFDDE6,
    obs: _Obs.blossom,
    detail: 0xFFE57A9A,
  ),
  Terrain.forest => const _Palette(
    ground: 0xFFDDE8C8,
    patch: 0xFFA9C98A,
    path: 0xFFD9C29A,
    pathEdge: 0xFFB0946A,
    leaf: 0xFF4F8A4A,
    leafDark: 0xFF234A2A,
    leafLight: 0xFF86BC6E,
    obs: _Obs.pine,
    detail: 0xFF5C8A4C,
  ),
  Terrain.river => const _Palette(
    ground: 0xFFE2F0DA,
    patch: 0xFFBFDDB0,
    path: 0xFFE6D6B0,
    pathEdge: 0xFFC2A97C,
    leaf: 0xFF6FAE62,
    leafDark: 0xFF35663A,
    leafLight: 0xFFA9D68E,
    obs: _Obs.tree,
    detail: 0xFF6E9E5A,
  ),
  Terrain.beach || Terrain.harbor => const _Palette(
    ground: 0xFFF5E6BF,
    patch: 0xFFEBD29A,
    path: 0xFFE9D3A2,
    pathEdge: 0xFFC9A96E,
    leaf: 0xFF6DAA5C,
    leafDark: 0xFF3B6B37,
    leafLight: 0xFFA6D48A,
    obs: _Obs.palm,
    detail: 0xFFC9A86A,
  ),
  Terrain.desert => const _Palette(
    ground: 0xFFF2DDA8,
    patch: 0xFFE4C07A,
    path: 0xFFE9D1A0,
    pathEdge: 0xFFC49A5E,
    leaf: 0xFF7FA25A,
    leafDark: 0xFF4C6B34,
    leafLight: 0xFFB2CC84,
    obs: _Obs.cactus,
    detail: 0xFFC9A060,
  ),
  Terrain.snow => const _Palette(
    ground: 0xFFF4F8FB,
    patch: 0xFFD9E6EF,
    path: 0xFFE5E9EE,
    pathEdge: 0xFFB8C6D2,
    leaf: 0xFF6E9C8A,
    leafDark: 0xFF35584E,
    leafLight: 0xFFFFFFFF,
    obs: _Obs.snowPine,
    detail: 0xFFA9BCC9,
  ),
  Terrain.cave => const _Palette(
    ground: 0xFFD3CCC2,
    patch: 0xFFB7AEA2,
    path: 0xFFC9BEAE,
    pathEdge: 0xFF9C9080,
    leaf: 0xFF8E867C,
    leafDark: 0xFF4F4840,
    leafLight: 0xFFBDB4A8,
    obs: _Obs.rock,
    detail: 0xFF8F8578,
  ),
  Terrain.crystal => const _Palette(
    ground: 0xFFCFD8E2,
    patch: 0xFFAFC0D8,
    path: 0xFFC6CCD8,
    pathEdge: 0xFF8E98B2,
    leaf: 0xFFB39DDB,
    leafDark: 0xFF5E4A8C,
    leafLight: 0xFFE6DCFA,
    obs: _Obs.crystal,
    detail: 0xFF8C9BC0,
  ),
  Terrain.lava => const _Palette(
    ground: 0xFF4A3530,
    patch: 0xFF6B3A2C,
    path: 0xFF5E4A42,
    pathEdge: 0xFF2E201C,
    leaf: 0xFF2B1D1D,
    leafDark: 0xFF140C0C,
    leafLight: 0xFF5A3A32,
    obs: _Obs.spike,
    detail: 0xFFE4572E,
  ),
  Terrain.sky => const _Palette(
    ground: 0xFFEEF5FF,
    patch: 0xFFD6E6FA,
    path: 0xFFFFFFFF,
    pathEdge: 0xFFB9CDE8,
    leaf: 0xFFFFFFFF,
    leafDark: 0xFF9DB4D6,
    leafLight: 0xFFFFFFFF,
    obs: _Obs.cloud,
    detail: 0xFFB9CDE8,
  ),
  _ => const _Palette(
    ground: 0xFFE9E2D2,
    patch: 0xFFD8CCB4,
    path: 0xFFB8484A,
    pathEdge: 0xFFE2B44C,
    leaf: 0xFF9E9AAE,
    leafDark: 0xFF5C566E,
    leafLight: 0xFFC8C4D6,
    obs: _Obs.indoor,
    detail: 0xFFB0A48A,
  ),
};

/// フィールドの地面・水・道・壁・木を、マス目が目立たないようにまとめて描く。
///
/// ノートに色鉛筆と水彩で描いたような見た目：地面は水彩のむらでつなぎ、
/// 木や岩はかたまりの外側だけをペンでなぞり、すべてに影を落とす。
/// 航路（海・空）のマップには使わない。
abstract final class Scenery {
  /// このマップを新しい描き方で描けるか（航路はこれまでの描き方）
  static bool supports(FieldMap map) {
    for (var r = 0; r < map.height; r++) {
      for (var c = 0; c < map.width; c++) {
        if (map.terrainAt(c, r).isVoyage) return false;
      }
    }
    return true;
  }

  /// 0〜1 のくり返さない値（マスの位置から決まる）
  static double _h(int a, int b, [int salt = 0]) {
    var x = a * 374761393 + b * 668265263 + salt * 1274126177;
    x = (x ^ (x >> 13)) * 1274126177;
    x = x ^ (x >> 16);
    return (x & 0xFFFFFF) / 0xFFFFFF;
  }

  static ui.Paint _p(int argb, [double alpha = 1]) =>
      ui.Paint()..color = ui.Color(argb).withValues(alpha: alpha);

  static ui.Paint _stroke(int argb, double w, [double alpha = 1]) => ui.Paint()
    ..color = ui.Color(argb).withValues(alpha: alpha)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  static bool _outdoor(Terrain t) => _paletteOf(t).obs != _Obs.indoor;

  /// 地面・道・水・壁・障害物を描く（看板・宿などの小物は呼び出し側）
  static void paint(ui.Canvas c, FieldMap map, String worldId, double ts) {
    final w = map.width, h = map.height;
    final bounds = Rect.fromLTWH(0, 0, w * ts, h * ts);
    Terrain t(int col, int row) => map.terrainAt(col, row);
    String tile(int col, int row) => map.tileAt(col, row);

    // ---- 地面：エリアの色を水彩のようにぼかしてつなぎ、むらをつける ----
    c.drawRect(bounds, _p(_paletteOf(t(0, 0)).ground));
    c.saveLayer(
      bounds,
      ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: ts * 0.45,
          sigmaY: ts * 0.45,
          tileMode: ui.TileMode.clamp,
        ),
    );
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        final pal = _paletteOf(t(col, r));
        final paper = NotebookWorld.paperOf(t(col, r), worldId);
        c.drawRect(
          Rect.fromLTWH(col * ts - 1, r * ts - 1, ts + 2, ts + 2),
          _p(PaperArt.tintFloor(ui.Color(pal.ground), paper).toARGB32()),
        );
      }
    }
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        final v = _h(col, r, 1);
        if (v > 0.22) continue;
        final pal = _paletteOf(t(col, r));
        final cx = (col + _h(col, r, 2)) * ts, cy = (r + _h(col, r, 3)) * ts;
        final rw = ts * (0.8 + _h(col, r, 4) * 1.6);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: rw,
            height: rw * (0.5 + _h(col, r, 5) * 0.4),
          ),
          _p(pal.patch, 0.35 + v),
        );
      }
    }
    c.restore();

    // ---- ノートの線（うすく。ノートに描いた世界であることは残す） ----
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        final terr = t(col, r);
        final paper = NotebookWorld.paperOf(terr, worldId);
        PaperArt.lines(
          c,
          Rect.fromLTWH(col * ts, r * ts, ts, ts),
          paper,
          TerrainArt.grid(terr).withValues(alpha: 0.35),
          col,
          r,
        );
      }
    }

    // ---- 建物の中の床：石だたみ・板張り ----
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        if (_outdoor(t(col, r)) || tile(col, r) == '#') continue;
        _indoorFloor(c, t(col, r), col, r, ts);
      }
    }

    // ---- 地面の描きこみ（草・小石・花・砂紋・ひび）。マスの中の位置はばらばら ----
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        if (!map.isFloor(col, r) || tile(col, r) == 'R') continue;
        _groundDetail(c, t(col, r), col, r, ts);
      }
    }

    // ---- けもの道：スタートから敵・ゴールをつなぐ道と、宿・宝箱などへの小道 ----
    _trails(c, map, ts);

    // ---- 道（R）：マスをつないだ1本の帯にする（外は土の道、建物の中はじゅうたん） ----
    _ribbon(
      c,
      map,
      ts,
      // 外の道は、けもの道（_trails）で描く。建物の中のじゅうたんだけ帯にする
      (col, r) =>
          (tile(col, r) == 'R' || tile(col, r) == 'B') && !_outdoor(t(col, r)),
      edge: (col, r) => _paletteOf(t(col, r)).pathEdge,
      fill: (col, r) => _paletteOf(t(col, r)).path,
      grow: 0.08,
      radius: 0.42,
    );
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        if (tile(col, r) != 'R' || !_outdoor(t(col, r))) continue;
        // 土の道の小石・わだち
        for (var i = 0; i < 3; i++) {
          if (_h(col, r, 30 + i) > 0.5) continue;
          c.drawCircle(
            Offset(
              (col + 0.2 + _h(col, r, 40 + i) * 0.6) * ts,
              (r + 0.2 + _h(col, r, 50 + i) * 0.6) * ts,
            ),
            0.8 + _h(col, r, 60 + i) * 1.2,
            _p(_paletteOf(t(col, r)).pathEdge, 0.7),
          );
        }
      }
    }

    // ---- 水（~）：岸の泡 → 水 → 深いところ → 波 ----
    bool water(int col, int r) => tile(col, r) == '~' || tile(col, r) == 'B';
    final waterCells = <Cell>[
      for (var r = 0; r < h; r++)
        for (var col = 0; col < w; col++)
          if (tile(col, r) == '~') (col: col, row: r),
    ];
    if (waterCells.isNotEmpty) {
      int shore(int col, int r) =>
          t(col, r) == Terrain.lava ? 0xFF2B1D1D : 0xFFFFFFFF;
      int deep(int col, int r) => switch (t(col, r)) {
        Terrain.lava => 0xFFE4572E,
        Terrain.sky => 0xFFBFD7F2,
        Terrain.crystal => 0xFF7FA6D8,
        _ => 0xFF7EB7DA,
      };
      _ribbon(
        c,
        map,
        ts,
        water,
        edge: (col, r) => shore(col, r),
        fill: (col, r) => deep(col, r),
        grow: 0.18,
        radius: 0.5,
        edgeWidth: ts * 0.14,
      );
      // 深いところは、ぼかしてかさねる（マス目が出ないように）
      c.saveLayer(
        null,
        ui.Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: ts * 0.3,
            sigmaY: ts * 0.3,
          ),
      );
      for (final cell in waterCells) {
        final col = cell.col, r = cell.row;
        // まわりがすべて水なら、深い色をかさねる
        final inner = [
          (0, -1),
          (1, 0),
          (0, 1),
          (-1, 0),
        ].every((d) => water(col + d.$1, r + d.$2));
        if (inner) {
          c.drawRRect(
            ui.RRect.fromRectAndRadius(
              Rect.fromLTWH(col * ts, r * ts, ts, ts).inflate(2),
              ui.Radius.circular(ts * 0.4),
            ),
            _p(t(col, r) == Terrain.lava ? 0xFFB83A1E : 0xFF4F94C4, 0.45),
          );
        }
      }
      c.restore();
      for (final cell in waterCells) {
        final col = cell.col, r = cell.row;
        // 波（色鉛筆の短い線）
        if (_h(col, r, 70) < 0.55) {
          final y = (r + 0.3 + _h(col, r, 71) * 0.4) * ts;
          final x = (col + 0.15 + _h(col, r, 72) * 0.3) * ts;
          final wave = ui.Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + ts * 0.15, y - 3, x + ts * 0.3, y)
            ..quadraticBezierTo(x + ts * 0.45, y + 3, x + ts * 0.6, y);
          c.drawPath(
            wave,
            _stroke(
              t(col, r) == Terrain.lava ? 0xFFFFC069 : 0xFFFFFFFF,
              1.3,
              0.75,
            ),
          );
        }
      }
    }

    // ---- 影（壁・障害物の右下に落ちる） ----
    final shade = ui.Paint()
      ..color = const ui.Color(0x2E1E1A30)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        final k = tile(col, r);
        if (k != 'T' && k != '#' && k != 'H') continue;
        if (!_outdoor(t(col, r)) && k == '#') continue;
        c.drawOval(
          Rect.fromCenter(
            center: Offset((col + 0.6) * ts, (r + 0.88) * ts),
            width: ts * 0.95,
            height: ts * 0.42,
          ),
          shade,
        );
      }
    }

    // ---- 建物の中の壁：上の面と、手前の面（下が床のとき）で奥行きを出す ----
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        if (tile(col, r) != '#' || _outdoor(t(col, r))) continue;
        _indoorWall(c, map, col, r, ts);
      }
    }

    // ---- 外の壁（#）と障害物（T・H）：かたまりの外側だけをなぞった茂み・岩場 ----
    bool mass(int col, int r) {
      final k = tile(col, r);
      return (k == '#' || k == 'T' || k == 'H') && _outdoor(t(col, r));
    }

    _canopies(c, map, ts, mass);

    // ---- 建物の中・町の障害物は1つずつ（影は上で落とした） ----
    final rnd = Random(7);
    for (var r = 0; r < h; r++) {
      for (var col = 0; col < w; col++) {
        final k = tile(col, r);
        if ((k == 'T' || k == 'H') && !_outdoor(t(col, r))) {
          TerrainArt.obstacle(
            c,
            Rect.fromLTWH(col * ts, r * ts, ts, ts),
            rnd,
            t(col, r),
          );
        }
      }
    }

    // ---- 光：上のほうを少し明るく、四すみを少しくらく ----
    c.drawRect(
      bounds,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(bounds.width, bounds.height),
          [const ui.Color(0x14FFF6D0), const ui.Color(0x00FFFFFF)],
        ),
    );
  }

  /// 歩いて通れるマス（敵の立ち位置・橋もふくむ）
  static bool _walk(FieldMap map, int col, int r) =>
      map.isFloor(col, r) || const {'B', 'R'}.contains(map.tileAt(col, r));

  /// [from] から [to] までのいちばん近い道（マスの列）
  static List<Cell>? _route(FieldMap map, Cell from, Set<Cell> to) {
    final prev = <Cell, Cell>{};
    final seen = {from};
    final queue = <Cell>[from];
    for (var i = 0; i < queue.length; i++) {
      final c = queue[i];
      if (to.contains(c) && c != from) {
        final out = [c];
        for (var p = prev[c]; p != null; p = prev[p]) {
          out.add(p);
        }
        return out.reversed.toList();
      }
      for (final (dc, dr) in const [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
        final n = (col: c.col + dc, row: c.row + dr);
        if (seen.contains(n)) continue;
        if (!_walk(map, n.col, n.row) && !to.contains(n)) continue;
        seen.add(n);
        prev[n] = c;
        queue.add(n);
      }
    }
    return null;
  }

  static void _trails(ui.Canvas c, FieldMap map, double ts) {
    // 大きな道：スタート → 敵（エリアの順）→ ゴール
    final keys = <Cell>[
      ...map.findAll('P'),
      for (final e
          in (map.enemySpots.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))))
        e.value,
      ...map.findAll('G'),
    ];
    final main = <List<Cell>>[];
    final onMain = <Cell>{};
    for (var i = 0; i + 1 < keys.length; i++) {
      final r = _route(map, keys[i], {keys[i + 1]});
      if (r == null) continue;
      main.add(r);
      onMain.addAll(r);
    }
    // 小道：宿・宝箱・泉・看板・住人・ワープ石・出入口から、大きな道へ
    final side = <List<Cell>>[];
    if (onMain.isNotEmpty) {
      for (final ch in const ['I', 'C', 'W', 'S', 'N', 'X', 'O']) {
        for (final f in map.findAll(ch)) {
          final r = _route(map, f, onMain);
          if (r != null && r.length > 2) side.add(r.sublist(1));
        }
      }
    }
    // 地形が変わるところで切って、地形ごとの色で描く
    final pieces = <(Terrain, List<Cell>, double)>[];
    void split(List<List<Cell>> routes, double width) {
      for (final route in routes) {
        var cur = <Cell>[];
        Terrain? at;
        for (final p in route) {
          final t = map.terrainAt(p.col, p.row);
          if (at != null && t != at) {
            if (cur.length > 1) pieces.add((at, cur, width));
            cur = [cur.last];
          }
          at = t;
          cur.add(p);
        }
        if (at != null && cur.length > 1) pieces.add((at, cur, width));
      }
    }

    split(side, ts * 0.32);
    split(main, ts * 0.52);
    for (final pass in [0, 1]) {
      for (final (t, route, width) in pieces) {
        if (!_outdoor(t)) continue;
        final pal = _paletteOf(t);
        c.drawPath(
          _smooth(route, ts, map),
          pass == 0
              ? _stroke(pal.pathEdge, width + 3, 0.8)
              : _stroke(pal.path, width, 0.95),
        );
      }
    }
  }

  /// マスの中心を、角をまるめてつないだ線（建物の中のマスは飛ばす）
  static ui.Path _smooth(List<Cell> route, double ts, FieldMap map) {
    final path = ui.Path();
    Offset at(Cell p) {
      // 少しだけゆらして、手で描いた道にする
      final j = (_h(p.col, p.row, 99) - 0.5) * ts * 0.18;
      return Offset((p.col + 0.5) * ts + j, (p.row + 0.5) * ts - j);
    }

    var drawing = false;
    for (var i = 0; i < route.length; i++) {
      final p = route[i];
      if (!_outdoor(map.terrainAt(p.col, p.row))) {
        drawing = false;
        continue;
      }
      final o = at(p);
      if (!drawing) {
        path.moveTo(o.dx, o.dy);
        drawing = true;
        continue;
      }
      final prev = at(route[i - 1]);
      final mid = Offset((prev.dx + o.dx) / 2, (prev.dy + o.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      if (i == route.length - 1) path.lineTo(o.dx, o.dy);
    }
    return path;
  }

  /// マスをつないだ帯（道・水）。ふちの色で一回り大きく塗り、その上を中の色で塗る
  static void _ribbon(
    ui.Canvas c,
    FieldMap map,
    double ts,
    bool Function(int col, int row) on, {
    required int Function(int col, int row) edge,
    required int Function(int col, int row) fill,
    required double grow,
    required double radius,
    double? edgeWidth,
  }) {
    final ew = edgeWidth ?? ts * 0.1;
    for (final pass in [0, 1]) {
      for (var r = 0; r < map.height; r++) {
        for (var col = 0; col < map.width; col++) {
          if (!on(col, r)) continue;
          final paint = pass == 0 ? _p(edge(col, r)) : _p(fill(col, r));
          final g = pass == 0 ? ts * grow + ew : ts * grow;
          final cell = Rect.fromLTWH(col * ts, r * ts, ts, ts).inflate(g);
          c.drawRRect(
            ui.RRect.fromRectAndRadius(cell, ui.Radius.circular(ts * radius)),
            paint,
          );
          // となりのマスとつなぐ（角が丸いままだと、くびれて見えるため）
          if (on(col + 1, r)) {
            c.drawRect(
              Rect.fromLTRB(
                (col + 0.5) * ts,
                cell.top,
                (col + 1.5) * ts,
                cell.bottom,
              ),
              paint,
            );
          }
          if (on(col, r + 1)) {
            c.drawRect(
              Rect.fromLTRB(
                cell.left,
                (r + 0.5) * ts,
                cell.right,
                (r + 1.5) * ts,
              ),
              paint,
            );
          }
        }
      }
    }
  }

  /// 地面の小さな描きこみ
  static void _groundDetail(ui.Canvas c, Terrain t, int col, int r, double ts) {
    final pal = _paletteOf(t);
    final v = _h(col, r, 9);
    if (v > 0.55) return;
    final x = (col + 0.15 + _h(col, r, 10) * 0.7) * ts;
    final y = (r + 0.25 + _h(col, r, 11) * 0.6) * ts;
    switch (pal.obs) {
      case _Obs.tree || _Obs.pine || _Obs.blossom:
        // 草のひと束
        final p = _stroke(pal.detail, 1.1, 0.8);
        c.drawLine(Offset(x, y), Offset(x - 2.5, y - 5), p);
        c.drawLine(Offset(x + 1, y), Offset(x + 1, y - 6.5), p);
        c.drawLine(Offset(x + 2, y), Offset(x + 4.5, y - 4.5), p);
        if (pal.obs == _Obs.blossom || v < 0.12) {
          // 小さな花
          final color = [
            0xFFF48FB1,
            0xFFFFF176,
            0xFFFFFFFF,
            0xFFB39DDB,
          ][(v * 97).floor() % 4];
          for (var i = 0; i < 5; i++) {
            final a = i * pi * 2 / 5;
            c.drawCircle(
              Offset(x + 6 + cos(a) * 2, y - 6 + sin(a) * 2),
              1.4,
              _p(color),
            );
          }
          c.drawCircle(Offset(x + 6, y - 6), 1, _p(0xFFF9A825));
        }
      case _Obs.palm || _Obs.cactus:
        // 砂紋
        final p = _stroke(pal.detail, 1, 0.55);
        final path = ui.Path()
          ..moveTo(x - 6, y)
          ..quadraticBezierTo(x, y - 3, x + 6, y);
        c.drawPath(path, p);
        c.drawPath(path.shift(const Offset(2, 4)), p);
      case _Obs.snowPine:
        c.drawCircle(Offset(x, y), 1.2, _p(pal.detail, 0.6));
        c.drawCircle(Offset(x + 5, y + 2), 0.9, _p(pal.detail, 0.5));
      case _Obs.rock || _Obs.crystal:
        // 小石
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 5, height: 3.4),
          _p(pal.detail, 0.8),
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(x + 6, y + 3), width: 3, height: 2),
          _p(pal.detail, 0.6),
        );
      case _Obs.spike:
        // 溶岩のひび
        final p = _stroke(pal.detail, 1.1, 0.6);
        c.drawLine(Offset(x, y), Offset(x + 5, y + 4), p);
        c.drawLine(Offset(x + 5, y + 4), Offset(x + 3, y + 9), p);
      case _Obs.cloud:
        c.drawCircle(Offset(x, y), 1.5, _p(0xFFFFFFFF, 0.9));
      case _Obs.indoor:
        if (v < 0.2) {
          // 床の小さなしみ・すり傷
          c.drawLine(
            Offset(x, y),
            Offset(x + 6, y + 1),
            _stroke(pal.detail, 0.8, 0.5),
          );
        }
    }
  }

  /// 建物の中の床。書庫・町・工房は板張り、それ以外は石だたみ
  static void _indoorFloor(ui.Canvas c, Terrain t, int col, int r, double ts) {
    final x = col * ts, y = r * ts;
    final line = _stroke(0xFF5D4A3A, 0.7, 0.16);
    final wood =
        t == Terrain.library || t == Terrain.town || t == Terrain.workshop;
    if (wood) {
      // 板：横に3枚。継ぎ目は列ごとにずらす
      for (var k = 0; k < 3; k++) {
        final yy = y + ts * k / 3;
        c.drawLine(Offset(x, yy), Offset(x + ts, yy), line);
        final j = x + ts * _h(col, r * 3 + k, 12);
        c.drawLine(Offset(j, yy), Offset(j, yy + ts / 3), line);
      }
      return;
    }
    // 石だたみ：マスを大小の石に分ける（角を少しまるめる）
    final split = _h(col, r, 13);
    final stones = split < 0.4
        ? [Rect.fromLTWH(x, y, ts, ts)]
        : split < 0.7
        ? [
            Rect.fromLTWH(x, y, ts / 2, ts),
            Rect.fromLTWH(x + ts / 2, y, ts / 2, ts),
          ]
        : [
            Rect.fromLTWH(x, y, ts / 2, ts / 2),
            Rect.fromLTWH(x + ts / 2, y, ts / 2, ts / 2),
            Rect.fromLTWH(x, y + ts / 2, ts, ts / 2),
          ];
    for (final st in stones) {
      c.drawRRect(
        ui.RRect.fromRectAndRadius(
          st.deflate(1.2),
          const ui.Radius.circular(4),
        ),
        line,
      );
    }
    if (_h(col, r, 14) < 0.15) {
      // ひび
      c.drawLine(
        Offset(x + ts * 0.3, y + ts * 0.4),
        Offset(x + ts * 0.5, y + ts * 0.55),
        line,
      );
    }
  }

  /// 建物の中の壁（石の上の面と、手前の面）
  static void _indoorWall(
    ui.Canvas c,
    FieldMap map,
    int col,
    int r,
    double ts,
  ) {
    final t = map.terrainAt(col, r);
    final pal = _paletteOf(t);
    final rect = Rect.fromLTWH(col * ts, r * ts, ts, ts);
    final front = map.tileAt(col, r + 1) != '#';
    final top = front
        ? Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + ts * 0.55)
        : rect;
    c.drawRect(rect, _p(pal.leafDark));
    c.drawRect(top, _p(pal.leaf));
    // 上の面の石の目
    final joint = _stroke(pal.leafDark, 0.8, 0.45);
    c.drawLine(
      Offset(rect.left, top.top + top.height / 2),
      Offset(rect.right, top.top + top.height / 2),
      joint,
    );
    if (front) {
      // 手前の面のれんが
      final fr = Rect.fromLTRB(rect.left, top.bottom, rect.right, rect.bottom);
      c.drawRect(fr, _p(pal.leafDark));
      final brick = _stroke(0xFF000000, 0.8, 0.25);
      c.drawLine(
        Offset(fr.left, fr.center.dy),
        Offset(fr.right, fr.center.dy),
        brick,
      );
      final off = col.isEven ? 0.0 : ts / 2;
      for (var x = fr.left + off; x < fr.right; x += ts / 2) {
        c.drawLine(Offset(x, fr.top), Offset(x, fr.center.dy), brick);
      }
      // 上の面のふちの光
      c.drawLine(
        Offset(rect.left, top.bottom),
        Offset(rect.right, top.bottom),
        _stroke(pal.leafLight, 1.2, 0.8),
      );
      // 床に落ちる影
      c.drawRect(
        Rect.fromLTWH(rect.left, rect.bottom, ts, ts * 0.22),
        _p(0xFF1E1A30, 0.12),
      );
    }
  }

  /// 外の茂み・岩場。かたまりの外側だけをペンでなぞる
  static void _canopies(
    ui.Canvas c,
    FieldMap map,
    double ts,
    bool Function(int col, int row) mass,
  ) {
    final cells = <Cell>[
      for (var r = 0; r < map.height; r++)
        for (var col = 0; col < map.width; col++)
          if (mass(col, r)) (col: col, row: r),
    ];
    if (cells.isEmpty) return;

    // 1マスに2〜3個の丸（木なら葉のかたまり、岩場なら岩）を置く
    final blobs = <(Cell, Offset, double)>[];
    for (final cell in cells) {
      final col = cell.col, r = cell.row;
      // かたまりの内側は大きな丸1つ（細かい丸ばかりだと、泡のように見える）
      final inner =
          mass(col - 1, r) &&
          mass(col + 1, r) &&
          mass(col, r - 1) &&
          mass(col, r + 1);
      if (inner) {
        if (_h(col, r, 19) < 0.55) {
          blobs.add((
            cell,
            Offset(
              (col + 0.5 + (_h(col, r, 21) - 0.5) * 0.4) * ts,
              (r + 0.5 + (_h(col, r, 24) - 0.5) * 0.4) * ts,
            ),
            ts * (0.75 + _h(col, r, 27) * 0.25),
          ));
        }
        continue;
      }
      final n = 1 + (_h(col, r, 20) * 2).floor();
      for (var i = 0; i < n; i++) {
        final cx = (col + 0.5 + (_h(col, r, 21 + i) - 0.5) * 0.5) * ts;
        final cy = (r + 0.42 + (_h(col, r, 24 + i) - 0.5) * 0.45) * ts;
        final rad = ts * (0.45 + _h(col, r, 27 + i) * 0.25);
        blobs.add((cell, Offset(cx, cy), rad));
      }
    }
    // 内側の大きな丸をあとにすると、外側の木の上にかぶさるので先に描く
    blobs.sort((a, b) => b.$3.compareTo(a.$3));

    _Obs obsAt(Cell cell) => _paletteOf(map.terrainAt(cell.col, cell.row)).obs;

    // 木の幹（下が茂みでない木だけ）
    for (final cell in cells) {
      final o = obsAt(cell);
      if (o != _Obs.tree && o != _Obs.blossom) continue;
      if (mass(cell.col, cell.row + 1)) continue;
      final x = (cell.col + 0.5) * ts, y = (cell.row + 0.7) * ts;
      c.drawRRect(
        ui.RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 5, height: ts * 0.45),
          const ui.Radius.circular(2),
        ),
        _p(0xFF7A5236),
      );
    }

    // 1回目：ふちの色で一回り大きく（これが外側の線になる）
    for (final (cell, o, rad) in blobs) {
      final pal = _paletteOf(map.terrainAt(cell.col, cell.row));
      _blob(c, obsAt(cell), o, rad + 1.8, _p(pal.leafDark));
    }
    // 2回目：中の色（内側の線は塗りつぶされて消える）
    for (final (cell, o, rad) in blobs) {
      final pal = _paletteOf(map.terrainAt(cell.col, cell.row));
      _blob(c, obsAt(cell), o, rad, _p(pal.leaf));
    }
    // 3回目：左上の光と、右下のかげ
    for (final (cell, o, rad) in blobs) {
      final pal = _paletteOf(map.terrainAt(cell.col, cell.row));
      final kind = obsAt(cell);
      c.save();
      c.clipPath(_blobPath(kind, o, rad));
      c.drawCircle(
        o.translate(rad * 0.45, rad * 0.55),
        rad * 0.85,
        _p(pal.leafDark, 0.28),
      );
      c.drawCircle(
        o.translate(-rad * 0.35, -rad * 0.4),
        rad * 0.45,
        _p(pal.leafLight, kind == _Obs.snowPine ? 0.95 : 0.55),
      );
      c.restore();
    }
    // 4回目：かたまりの上の飾り（花・実・雪・結晶の光）
    for (final (cell, o, rad) in blobs) {
      final kind = obsAt(cell);
      final v = _h(o.dx.round(), o.dy.round(), 80);
      switch (kind) {
        case _Obs.blossom when v < 0.6:
          c.drawCircle(o.translate(rad * 0.2, -rad * 0.1), 1.8, _p(0xFFFFFFFF));
          c.drawCircle(
            o.translate(-rad * 0.3, rad * 0.25),
            1.5,
            _p(0xFFFFF59D),
          );
        case _Obs.tree when v < 0.18:
          c.drawCircle(o.translate(rad * 0.25, rad * 0.1), 2, _p(0xFFE53935));
        case _Obs.crystal when v < 0.5:
          c.drawLine(
            o.translate(-rad * 0.2, -rad * 0.5),
            o.translate(rad * 0.1, rad * 0.2),
            _stroke(0xFFFFFFFF, 1.2, 0.8),
          );
        case _Obs.spike when v < 0.5:
          c.drawCircle(o, rad * 0.25, _p(0xFFE4572E, 0.55));
        default:
      }
    }
    // サボテン・ヤシは、かたまりの手前に1本ずつ立てる
    final rnd = Random(11);
    for (final cell in cells) {
      final kind = obsAt(cell);
      if (kind != _Obs.palm && kind != _Obs.cactus) continue;
      if (map.tileAt(cell.col, cell.row) != 'T') continue;
      if (_h(cell.col, cell.row, 90) > 0.45) continue;
      TerrainArt.obstacle(
        c,
        Rect.fromLTWH(cell.col * ts, cell.row * ts, ts, ts),
        rnd,
        map.terrainAt(cell.col, cell.row),
      );
    }
  }

  static void _blob(ui.Canvas c, _Obs kind, Offset o, double rad, ui.Paint p) =>
      c.drawPath(_blobPath(kind, o, rad), p);

  /// かたまりの1つぶんの形（木は丸、針葉樹は三角、岩は角ばった形）
  static ui.Path _blobPath(_Obs kind, Offset o, double rad) {
    switch (kind) {
      case _Obs.pine || _Obs.snowPine:
        return ui.Path()
          ..moveTo(o.dx, o.dy - rad * 1.25)
          ..lineTo(o.dx + rad * 0.95, o.dy + rad * 0.75)
          ..lineTo(o.dx - rad * 0.95, o.dy + rad * 0.75)
          ..close();
      case _Obs.rock || _Obs.spike:
        final path = ui.Path();
        for (var i = 0; i < 7; i++) {
          final a = i * pi * 2 / 7 + 0.3;
          final k = 0.78 + _h(o.dx.round(), o.dy.round(), i) * 0.3;
          final p = Offset(
            o.dx + cos(a) * rad * k,
            o.dy + sin(a) * rad * k * (kind == _Obs.spike ? 1.25 : 0.85),
          );
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case _Obs.crystal:
        return ui.Path()
          ..moveTo(o.dx, o.dy - rad * 1.3)
          ..lineTo(o.dx + rad * 0.6, o.dy - rad * 0.2)
          ..lineTo(o.dx + rad * 0.4, o.dy + rad * 0.8)
          ..lineTo(o.dx - rad * 0.4, o.dy + rad * 0.8)
          ..lineTo(o.dx - rad * 0.6, o.dy - rad * 0.2)
          ..close();
      default:
        return ui.Path()..addOval(Rect.fromCircle(center: o, radius: rad));
    }
  }
}
