import 'dart:math' as math;
import 'dart:typed_data';

import 'geo2d.dart';

/// 400m×400m の 3D フィールド「はじまりの大地」の設計データ（第 2.1 版）。
///
/// 第 2 版の設計図（SVG）をもとに、座標を検算して見つかった矛盾を直したもの
/// （直した点は docs/map_v2_1.md）。座標は北西の角が (0, 0)、東が +X、南が +Z、
/// Y は標高。描画に依存しない純 Dart なので、地形の高さ・通れる場所・道のつながりを
/// 単体テストで確かめられる（test/map_v2_test.dart）。
class MapV2 {
  MapV2._();

  static const size = 400.0;

  /// 地図の端からこれより内側だけ歩ける
  static const edgeMargin = 1.5;

  // ---- 川 ----

  /// 川の中心線（第 2 版の SVG の T 命令は橋のまわりで S 字に折り返していたので、
  /// コメントの通過点を折れ線でつないだものにした）
  static const river = <P2>[
    (175, 0),
    (195, 100),
    (214, 170),
    (220, 210),
    (213, 250),
    (205, 295),
    (225, 400),
  ];

  /// 川の半分の幅（川幅 20m）
  static const riverHalfWidth = 10.0;

  /// これより川の中心に近い所は通れない（岸の少し外まで）
  static const riverBlock = 10.8;

  /// 水面の高さ
  static const waterY = 0.0;

  /// 西岸の浅瀬（歩ける。本流には入れない）
  static const shallowX = 188.0, shallowZ = 252.0;
  static const shallowRx = 16.0, shallowRz = 20.0;

  // ---- 古橋（BR-01） ----

  static const bridgeX0 = 204.0, bridgeX1 = 236.0;

  /// 欄干の内側（通れる幅 8m）
  static const bridgeZ0 = 206.0, bridgeZ1 = 214.0;

  /// 橋の上面の高さ
  static const bridgeY = 3.1;

  /// 橋をわたれるようになる条件（古橋の番人をたおす）
  static const bridgeKey = 'v_b1';

  static bool onBridge(double x, double z) =>
      x >= bridgeX0 &&
      x <= bridgeX1 &&
      z >= bridgeZ0 + 0.4 &&
      z <= bridgeZ1 - 0.4;

  // ---- 道（点ごとに X, Z, 高さ Y） ----

  static const roads = <Road>[
    // ルート 2：森の探索ルート（村の広場 → 北門 → 森 → 隠し広場 → 草原分岐）
    Road('route2', '森の小道', 4, [
      (95, 310, 2.0),
      (70, 290, 2.0),
      (95, 265, 2.0),
      (95, 185, 3.5),
      (95, 170, 4.5),
      (65, 125, 6.0),
      (125, 165, 4.0),
      (165, 240, 2.2),
    ]),
    // 隠し広場 → 北ゲート（深森への道。倒木で閉鎖中）
    Road('route2n', '深森への小道', 4, [
      (65, 125, 6.0),
      (74, 90, 6.6),
      (82, 50, 7.3),
      (90, 8, 8.0),
    ]),
    // ルート 3：川辺の探索ルート（行き止まり）
    Road('route3', '川辺の小道', 3.5, [
      (165, 240, 2.2),
      (170, 250, 1.5),
      (192, 140, 2.0),
    ]),
    Road('route3s', '川辺の小道（南）', 3.5, [(170, 250, 1.5), (188, 340, 1.8)]),
    Road('route3w', '浅瀬への道', 3.5, [(170, 250, 1.5), (184, 252, 0.2)]),
    // ルート 4：南東の探索ルート（東道・西の迂回路・洞窟からの連絡道）
    Road('route4', '石碑群への道', 4, [
      (248, 210, 2.8),
      (275, 265, 3.6),
      (290, 330, 4.0),
      (250, 392, 1.0),
    ]),
    Road('route4w', '川沿いの迂回路', 4, [
      (275, 265, 3.6),
      (260, 330, 3.2),
      (250, 392, 1.0),
    ]),
    // 洞窟前 → 石碑群（第 2 版では岩壁を通っていたので、切り通しの谷道にした）
    Road('route4c', '岩場の切り通し', 4, [
      (348, 248, 6.0),
      (325, 295, 5.0),
      (290, 330, 4.0),
    ]),
    // ルート 5：東の街道と洞窟への小道
    Road('route5', '東の街道', 6, [
      (248, 210, 2.8),
      (305, 215, 5.0),
      (348, 218, 7.0),
      (395, 220, 8.0),
    ]),
    Road('route5c', '洞窟への小道', 4, [
      (348, 218, 7.0),
      (348, 248, 6.0),
      (354, 245, 6.0),
    ]),
    // ルート 1：メイン街道（村 → 古橋）。橋の上（2 番目と 3 番目の点のあいだ）は地形を変えない
    Road('route1', 'メイン街道', 6, [
      (100, 315, 2.0),
      (138, 305, 2.0),
      (165, 240, 2.2),
      (200, 210, 2.8),
      (bridgeX0, 210, 3.0),
      (bridgeX1, 210, 3.0),
      (248, 210, 2.8),
    ], bridgeSegment: 4),
    // ルート 1 の続き：登山道（第 1 スロープ 13.5 度・踊り場・第 2 スロープ 19.7 度）
    Road('trail', '星見の登山道', 6, [
      (248, 210, 2.8),
      (255, 175, 4.0),
      (295, 145, 16.0),
      (315, 145, 16.0),
      (335, 118, 28.0),
      (335, 85, 28.0),
    ], blend: 2.5),
  ];

  /// 両側に石壁がある坂（登山道の第 1・第 2 スロープ）。道の外へ落ちない
  static List<((double, double, double), (double, double, double))>
  get guardedRamps {
    final t = roads.firstWhere((r) => r.id == 'trail').points;
    return [(t[1], t[2]), (t[3], t[4])];
  }

  /// 坂の石壁の、道の中心からの距離
  static const rampWallOffset = 3.6;

  /// 平らな広場（中心・高さ・半径）
  static const plazas = <Plaza>[
    Plaza('S1', '村の中央広場', 100, 315, 2.0, 22),
    Plaza('S2', '川辺の休憩地', 170, 250, 1.5, 8),
    // 第 2 版の半径 12m は、直した川の岸と 2.3m 重なるので 9m に
    Plaza('B1', '古橋の西詰広場', 200, 210, 2.8, 9),
    Plaza('B2', '山頂の闘技場', 335, 102, 28.0, 16),
    Plaza('T1', '森の隠し広場', 65, 125, 6.0, 20),
    Plaza('T3', '古代の石碑群', 290, 330, 4.0, 16),
    Plaza('T4F', '洞窟前の小広場', 348, 248, 6.0, 5),
  ];

  // ---- 地域（多角形） ----

  static const village = <P2>[(48, 265), (138, 265), (138, 355), (48, 355)];

  /// 村の門（柵のすき間）
  static const villageEastGate = (138.0, 305.0);
  static const villageNorthGate = (95.0, 265.0);

  /// ささやきの森（木が密集して通れない。道と隠し広場だけ通れる）
  static final forest = <P2>[
    (0, 0),
    (155, 0),
    ...quadratic((155, 0), (150, 95), (135, 155)),
    ...quadratic((135, 155), (115, 195), (60, 190)),
    (0, 185),
  ];

  /// 星見の山のふもと（急な崖。登山道だけ通れる）
  static final mountainBase = <P2>[
    (245, 0),
    (400, 0),
    (400, 185),
    (295, 185),
    (250, 175),
    ...quadratic((250, 175), (240, 120), (245, 0)),
  ];

  /// 中腹の踊り場（Y=16、歩ける）
  static final mountainMid = <P2>[
    (265, 0),
    (400, 0),
    (400, 165),
    (340, 165),
    (285, 155),
    (285, 130),
    ...quadratic((285, 130), (265, 90), (265, 0)),
  ];

  /// 山頂の平地（Y=28、遺跡と闘技場）
  static final summit = <P2>[
    (290, 15),
    (385, 15),
    ...quadratic((385, 15), (390, 75), (380, 122)),
    (295, 122),
    ...quadratic((295, 122), (285, 75), (290, 15)),
  ];

  /// 遺跡の背後の岩峰（第 2 版の Z=0〜40 は山頂と重なるので Z=0〜15 に）
  static const peak = <P2>[(285, 0), (392, 0), (392, 15), (285, 15)];

  /// 東の岩場の高い岩壁（通れない）
  static const rockWall = <P2>[
    (310, 185),
    (400, 185),
    (400, 285),
    (320, 280),
    (305, 245),
  ];

  /// 岩場の中の谷道（歩ける）
  static const valley = <P2>[
    (305, 205),
    (400, 208),
    (400, 232),
    (365, 232),
    (362, 255),
    (340, 255),
    (330, 225),
    (305, 220),
  ];

  /// 南東の台地（Y=4）。第 2 版は西の辺が川の中心線と同じで、川と G2 を含んでいたので内側へ
  static const plateau = <P2>[
    (238, 276),
    (265, 268),
    (320, 280),
    (400, 285),
    (400, 400),
    (300, 400),
    (275, 360),
  ];

  // ---- 遺跡（T2） ----

  static const templeX0 = 315.0, templeX1 = 355.0;
  static const templeZ0 = 55.0, templeZ1 = 85.0;

  /// 遺跡の南の入口（幅 8m）
  static const templeGateX0 = 331.0, templeGateX1 = 339.0;

  // ---- 計算 ----

  /// 川の中心線までの距離
  static double riverDistance(double x, double z) =>
      polylineDistance(x, z, river);

  /// 道・広場の上か（[pad] だけ広く見る）
  static bool onRoadOrPlaza(double x, double z, {double pad = 0.2}) {
    for (final r in roads) {
      if (r.distance(x, z, includeBridge: false) <= r.width / 2 + pad) {
        return true;
      }
    }
    for (final p in plazas) {
      if (distance(x, z, p.x, p.z) <= p.r + pad) return true;
    }
    return false;
  }

  /// その場所を歩けるか。[open] は通れるようになった条件（たおしたボスなど）
  static bool walkable(double x, double z, {Set<String> open = const {}}) {
    const lo = edgeMargin, hi = size - edgeMargin;
    if (x < lo || x > hi || z < lo || z > hi) return false;
    if (onBridge(x, z)) return open.contains(bridgeKey);
    if (riverDistance(x, z) < riverBlock) return false;
    if (onRoadOrPlaza(x, z)) return true;
    for (final (a, b) in guardedRamps) {
      final (d, _) = segmentDistance(x, z, (a.$1, a.$2), (b.$1, b.$2));
      if (d < rampWallOffset + 3) return false;
    }
    if (insidePolygon(x, z, forest)) return false;
    if (insidePolygon(x, z, peak)) return false;
    if (insidePolygon(x, z, mountainBase)) {
      // ふもとの崖は通れない。踊り場と山頂は歩けるが、山頂のふちの崖は通れない
      if (!insidePolygon(x, z, mountainMid)) return false;
      return polygonEdgeDistance(x, z, summit) >= 2.5;
    }
    if (insidePolygon(x, z, rockWall) && !insidePolygon(x, z, valley)) {
      return false;
    }
    return true;
  }

  /// 森の高さ（南の村から北のゲートへ、ゆるやかに上る）
  static double _forestY(double z) {
    const pts = [
      (0.0, 8.0),
      (8.0, 8.0),
      (125.0, 6.0),
      (170.0, 4.5),
      (185.0, 3.5),
      (265.0, 2.0),
    ];
    if (z <= pts.first.$1) return pts.first.$2;
    for (var i = 0; i + 1 < pts.length; i++) {
      final (z0, y0) = pts[i];
      final (z1, y1) = pts[i + 1];
      if (z <= z1) return lerp(y0, y1, (z - z0) / (z1 - z0));
    }
    return pts.last.$2;
  }

  /// 草原のゆるい起伏（傾き 3 度未満）。川の東は東へ少しずつ高くなる
  static double _base(double x, double z) {
    var h =
        2.2 +
        0.5 * math.sin(x * 0.045 + 0.7) * math.cos(z * 0.05) +
        0.3 * math.sin((x + z) * 0.021);
    h += 2.2 * smoothstep(235, 305, x);
    return h;
  }

  /// 地形の高さ（格子にする前の、もとの形）
  static double rawHeight(double x, double z) {
    var h = _base(x, z);
    double zone(List<P2> poly, double target, double from, double to) {
      final w = smoothstep(from, to, signedPolygonDistance(x, z, poly));
      if (w > 0) h = lerp(h, target, w);
      return w;
    }

    zone(village, 2.0, -8, 0);
    final fw = smoothstep(-10, 2, signedPolygonDistance(x, z, forest));
    if (fw > 0) h = lerp(h, _forestY(z), fw);
    zone(plateau, 4.0, -8, 4);
    final ws = signedPolygonDistance(x, z, rockWall);
    if (ws > -1) {
      h = lerp(h, 14 + 3 * smoothstep(3, 30, ws), smoothstep(-1, 3, ws));
    }
    zone(valley, 7.0, -1, 2);
    final bs = signedPolygonDistance(x, z, mountainBase);
    if (bs > -6) {
      h = lerp(h, 4 + 8 * smoothstep(0, 22, bs), smoothstep(-6, 0, bs));
    }
    zone(mountainMid, 16.0, -1, 3);
    zone(summit, 28.0, -1, 3);
    final ps = signedPolygonDistance(x, z, peak);
    if (ps > -1) {
      h = lerp(h, 32 + 6 * smoothstep(0, 8, ps), smoothstep(-1, 4, ps));
    }

    // 川：中心から 10m が水の下（川底 -2m）、その外 6m が岸
    final d = riverDistance(x, z);
    if (d < 10) {
      h = -2 + 1.7 * smoothstep(4, 10, d);
    } else if (d < 16) {
      h = lerp(0.3, h, smoothstep(10, 16, d));
    }
    // 浅瀬（水深 0.2m）
    final e =
        math.pow((x - shallowX) / shallowRx, 2) +
        math.pow((z - shallowZ) / shallowRz, 2);
    if (e < 1) h = lerp(-0.2, h, smoothstep(0.55, 1.0, e.toDouble()));

    // 広場のあとに道（道の高さを優先して、つなぎ目に段差を作らない）
    for (final p in plazas) {
      final w = 1 - smoothstep(p.r, p.r + 3, distance(x, z, p.x, p.z));
      if (w > 0) h = lerp(h, p.y, w);
    }
    for (final r in roads) {
      h = r.flatten(x, z, h);
    }
    return h;
  }

  /// 地面の種類（色分け用）
  static Surface surface(double x, double z, double h, double slopeDeg) {
    for (final r in roads) {
      if (r.distance(x, z, includeBridge: false) <= r.width / 2) {
        return Surface.road;
      }
    }
    final d = riverDistance(x, z);
    if (d < riverHalfWidth + 0.5) return Surface.riverBed;
    final e =
        math.pow((x - shallowX) / shallowRx, 2) +
        math.pow((z - shallowZ) / shallowRz, 2);
    if (e < 1 || d < riverHalfWidth + 3) return Surface.sand;
    for (final p in plazas) {
      if (distance(x, z, p.x, p.z) <= p.r) {
        return p.y >= 16 ? Surface.stone : Surface.plaza;
      }
    }
    if (slopeDeg > 33) return Surface.rock;
    if (insidePolygon(x, z, village)) return Surface.village;
    if (insidePolygon(x, z, forest)) return Surface.forest;
    if (insidePolygon(x, z, peak) || insidePolygon(x, z, summit)) {
      return Surface.stone;
    }
    if (insidePolygon(x, z, mountainBase)) {
      return insidePolygon(x, z, mountainMid) ? Surface.terrace : Surface.rock;
    }
    if (insidePolygon(x, z, rockWall)) {
      return insidePolygon(x, z, valley) ? Surface.gravel : Surface.rock;
    }
    if (insidePolygon(x, z, plateau)) return Surface.plateau;
    return Surface.grass;
  }
}

/// 地面の種類
enum Surface {
  grass(0.40, 0.64, 0.30),
  plateau(0.42, 0.60, 0.32),
  forest(0.20, 0.38, 0.17),
  village(0.52, 0.70, 0.40),
  road(0.76, 0.68, 0.50),
  plaza(0.80, 0.72, 0.52),
  sand(0.82, 0.76, 0.58),
  riverBed(0.30, 0.34, 0.30),
  rock(0.47, 0.42, 0.36),
  terrace(0.56, 0.50, 0.41),
  stone(0.66, 0.62, 0.55),
  gravel(0.55, 0.51, 0.48);

  const Surface(this.r, this.g, this.b);
  final double r, g, b;
}

/// 道（折れ線）。点ごとに高さを持ち、道の上の地形をその高さにならす
class Road {
  const Road(
    this.id,
    this.name,
    this.width,
    this.points, {
    this.bridgeSegment = -1,
    this.blend = 3,
  });

  final String id;
  final String name;
  final double width;
  final List<(double, double, double)> points;

  /// 橋の上の区間（この区間は地形を変えない）。なければ -1
  final int bridgeSegment;

  /// 道のわきを、まわりの地形へなじませる幅
  final double blend;

  List<P2> get xz => [for (final (x, z, _) in points) (x, z)];

  /// 道の中心線までの距離
  double distance(double x, double z, {bool includeBridge = true}) {
    var best = double.infinity;
    for (var i = 0; i + 1 < points.length; i++) {
      if (!includeBridge && i == bridgeSegment) continue;
      final (d, _) = segmentDistance(
        x,
        z,
        (points[i].$1, points[i].$2),
        (points[i + 1].$1, points[i + 1].$2),
      );
      if (d < best) best = d;
    }
    return best;
  }

  /// 道の高さ（いちばん近い区間の、位置に応じた高さ）と距離
  (double, double) heightNear(double x, double z) {
    var best = double.infinity, y = 0.0;
    for (var i = 0; i + 1 < points.length; i++) {
      if (i == bridgeSegment) continue;
      final a = points[i], b = points[i + 1];
      final (d, t) = segmentDistance(x, z, (a.$1, a.$2), (b.$1, b.$2));
      if (d < best) {
        best = d;
        y = lerp(a.$3, b.$3, t);
      }
    }
    return (y, best);
  }

  double flatten(double x, double z, double h) {
    final (y, d) = heightNear(x, z);
    final w = 1 - smoothstep(width / 2, width / 2 + blend, d);
    return w > 0 ? lerp(h, y, w) : h;
  }

  /// 区間ごとの傾き（度）
  List<double> slopes() => [
    for (var i = 0; i + 1 < points.length; i++)
      if (i != bridgeSegment)
        () {
          final a = points[i], b = points[i + 1];
          final run = distance2(a.$1, a.$2, b.$1, b.$2);
          return math.atan2((b.$3 - a.$3).abs(), run) * 180 / math.pi;
        }(),
  ];

  static double distance2(double ax, double az, double bx, double bz) =>
      math.sqrt((ax - bx) * (ax - bx) + (az - bz) * (az - bz));
}

/// 平らな広場
class Plaza {
  const Plaza(this.id, this.name, this.x, this.z, this.y, this.r);
  final String id;
  final String name;
  final double x, z, y, r;
}

/// 高さの格子（2m 間隔）。描画のメッシュと、物理の高さマップの両方に使う
class HeightGrid {
  HeightGrid._(this.n, this.step, this.heights);

  /// 1 辺の点の数（201 なら 0〜400m を 2m 間隔）
  final int n;
  final double step;

  /// heights[z * n + x]（行が Z）
  final Float32List heights;

  factory HeightGrid.build({
    double Function(double x, double z) height = MapV2.rawHeight,
    double step = 2,
  }) {
    final n = (MapV2.size / step).round() + 1;
    final h = Float32List(n * n);
    for (var j = 0; j < n; j++) {
      for (var i = 0; i < n; i++) {
        h[j * n + i] = height(i * step, j * step);
      }
    }
    return HeightGrid._(n, step, h);
  }

  double at(int i, int j) => heights[j.clamp(0, n - 1) * n + i.clamp(0, n - 1)];

  /// 格子の三角形（v10-v01 の対角線）で補間した高さ。メッシュと同じ形
  double heightAt(double x, double z) {
    final fx = (x / step).clamp(0.0, n - 1.0001);
    final fz = (z / step).clamp(0.0, n - 1.0001);
    final i = fx.floor(), j = fz.floor();
    final u = fx - i, v = fz - j;
    final h00 = at(i, j), h10 = at(i + 1, j), h01 = at(i, j + 1);
    final h11 = at(i + 1, j + 1);
    if (u + v <= 1) return h00 + (h10 - h00) * u + (h01 - h00) * v;
    return h11 + (h01 - h11) * (1 - u) + (h10 - h11) * (1 - v);
  }

  /// その点の傾き（度）
  double slopeAt(int i, int j) {
    final dx = (at(i + 1, j) - at(i - 1, j)) / (2 * step);
    final dz = (at(i, j + 1) - at(i, j - 1)) / (2 * step);
    return math.atan(math.sqrt(dx * dx + dz * dz)) * 180 / math.pi;
  }
}
