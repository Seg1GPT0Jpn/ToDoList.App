import 'dart:math' as math;

/// 地図の上の点（X, Z）。単位はメートル
typedef P2 = (double, double);

/// 平面の幾何の小さな道具（描画なし・純 Dart）

double lerp(double a, double b, double t) => a + (b - a) * t;

double smoothstep(double e0, double e1, double x) {
  if (e0 == e1) return x < e0 ? 0 : 1;
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// 線分 a-b への距離と、いちばん近い点の位置（0〜1）
(double, double) segmentDistance(double x, double z, P2 a, P2 b) {
  final (ax, az) = a;
  final (bx, bz) = b;
  final dx = bx - ax, dz = bz - az;
  final len2 = dx * dx + dz * dz;
  var t = len2 == 0 ? 0.0 : ((x - ax) * dx + (z - az) * dz) / len2;
  t = t.clamp(0.0, 1.0);
  final px = ax + dx * t, pz = az + dz * t;
  return (math.sqrt((x - px) * (x - px) + (z - pz) * (z - pz)), t);
}

/// 折れ線への距離
double polylineDistance(double x, double z, List<P2> pts) {
  var best = double.infinity;
  for (var i = 0; i + 1 < pts.length; i++) {
    final (d, _) = segmentDistance(x, z, pts[i], pts[i + 1]);
    if (d < best) best = d;
  }
  return best;
}

/// 多角形の内側か（偶奇判定）
bool insidePolygon(double x, double z, List<P2> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final (xi, zi) = poly[i];
    final (xj, zj) = poly[j];
    if ((zi > z) != (zj > z) && x < (xj - xi) * (z - zi) / (zj - zi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

/// 多角形の辺までの距離
double polygonEdgeDistance(double x, double z, List<P2> poly) {
  var best = double.infinity;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final (d, _) = segmentDistance(x, z, poly[j], poly[i]);
    if (d < best) best = d;
  }
  return best;
}

/// 内側なら正、外側なら負の、辺までの距離
double signedPolygonDistance(double x, double z, List<P2> poly) {
  final d = polygonEdgeDistance(x, z, poly);
  return insidePolygon(x, z, poly) ? d : -d;
}

/// 2次ベジェ曲線（SVG の Q）を折れ線に（始点はふくめない）
List<P2> quadratic(P2 a, P2 c, P2 b, {int steps = 10}) => [
  for (var i = 1; i <= steps; i++)
    () {
      final t = i / steps, u = 1 - t;
      return (
        u * u * a.$1 + 2 * u * t * c.$1 + t * t * b.$1,
        u * u * a.$2 + 2 * u * t * c.$2 + t * t * b.$2,
      );
    }(),
];

double distance(double ax, double az, double bx, double bz) =>
    math.sqrt((ax - bx) * (ax - bx) + (az - bz) * (az - bz));
