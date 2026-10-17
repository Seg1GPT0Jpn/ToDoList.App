import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/geo2d.dart';
import '../game/map_v2.dart';
import '../game/world_v2.dart';

/// 方角の名前（北が -Z、東が +X）
String compassName(double dx, double dz) {
  const names = ['北', '北東', '東', '南東', '南', '南西', '西', '北西'];
  final a = math.atan2(dx, -dz); // 北 0、東 +π/2
  final i = ((a / (math.pi / 4)).round() % 8 + 8) % 8;
  return names[i];
}

/// はじまりの大地の地図（MapV2 の設計データから描く）。
/// [zoom] が 1 より大きいと、主人公のまわりだけを拡大する（小さな地図）
class LandMapPainter extends CustomPainter {
  LandMapPainter({
    required this.player,
    required this.heading,
    required this.open,
    this.target,
    this.enemies = const [],
    this.zoom = 1,
    this.labels = false,
  });

  final P2 player;
  final double heading;
  final P2? target;
  final Set<String> open;

  /// (ボスか, 位置)
  final List<(bool, P2)> enemies;
  final double zoom;
  final bool labels;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / MapV2.size * zoom;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (zoom > 1) {
      canvas.translate(
        size.width / 2 - player.$1 * s,
        size.height / 2 - player.$2 * s,
      );
    }
    canvas.scale(s);
    final fill = Paint()..style = PaintingStyle.fill;
    void poly(List<P2> pts, Color c) {
      final path = Path()..moveTo(pts.first.$1, pts.first.$2);
      for (final p in pts.skip(1)) {
        path.lineTo(p.$1, p.$2);
      }
      path.close();
      canvas.drawPath(path, fill..color = c);
    }

    void line(List<P2> pts, double width, Color c) {
      final path = Path()..moveTo(pts.first.$1, pts.first.$2);
      for (final p in pts.skip(1)) {
        path.lineTo(p.$1, p.$2);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = c,
      );
    }

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, MapV2.size, MapV2.size),
      fill..color = const Color(0xFF6FA85A),
    );
    poly(MapV2.plateau, const Color(0xFF64994F));
    poly(MapV2.forest, const Color(0xFF2E5A28));
    poly(MapV2.mountainBase, const Color(0xFF7A6A58));
    poly(MapV2.mountainMid, const Color(0xFF92816C));
    poly(MapV2.summit, const Color(0xFFAA9A84));
    poly(MapV2.peak, const Color(0xFF5E5148));
    poly(MapV2.rockWall, const Color(0xFF5E554F));
    poly(MapV2.valley, const Color(0xFF8C827A));
    poly(MapV2.village, const Color(0xFF86B86B));
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(MapV2.shallowX, MapV2.shallowZ),
        width: MapV2.shallowRx * 2,
        height: MapV2.shallowRz * 2,
      ),
      fill..color = const Color(0xFF8FCBE8),
    );
    line(MapV2.river, MapV2.riverHalfWidth * 2, const Color(0xFF2F6BD8));
    for (final r in MapV2.roads) {
      line(r.xz, math.max(r.width, 3), const Color(0xFFD8C690));
    }
    // 古橋（わたれないうちは赤い線）
    canvas.drawRect(
      const Rect.fromLTRB(
        MapV2.bridgeX0,
        MapV2.bridgeZ0 - 1,
        MapV2.bridgeX1,
        MapV2.bridgeZ1 + 1,
      ),
      fill
        ..color = open.contains(MapV2.bridgeKey)
            ? const Color(0xFF8B5A2B)
            : const Color(0xFFB03030),
    );
    canvas.drawRect(
      const Rect.fromLTRB(
        MapV2.templeX0,
        MapV2.templeZ0,
        MapV2.templeX1,
        MapV2.templeZ1,
      ),
      fill..color = const Color(0xFFDCD7D0),
    );
    // 記号は画面の大きさ（ピクセル）で決める
    final px = 1 / s;
    for (final ev in worldV2.events) {
      if (ev.id == 'S1' || ev.id == 'S2') {
        canvas.drawCircle(
          Offset(ev.x, ev.z),
          4 * px,
          fill..color = const Color(0xFF3498DB),
        );
      }
    }
    for (final (boss, (x, z)) in enemies) {
      canvas.drawCircle(
        Offset(x, z),
        (boss ? 6 : 3.5) * px,
        fill..color = boss ? const Color(0xFFC0392B) : const Color(0xFFE67E22),
      );
    }
    final t = target;
    if (t != null) _star(canvas, Offset(t.$1, t.$2), 9 * px);
    // 自分（向きの三角）
    final fx = math.sin(heading), fz = math.cos(heading);
    final r = 9 * px;
    final tip = Offset(player.$1 + fx * r, player.$2 + fz * r);
    final l = Offset(
      player.$1 - fx * r * 0.6 + fz * r * 0.6,
      player.$2 - fz * r * 0.6 - fx * r * 0.6,
    );
    final rr = Offset(
      player.$1 - fx * r * 0.6 - fz * r * 0.6,
      player.$2 - fz * r * 0.6 + fx * r * 0.6,
    );
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(l.dx, l.dy)
      ..lineTo(rr.dx, rr.dy)
      ..close();
    canvas.drawPath(arrow, fill..color = Colors.white);
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * px
        ..color = Colors.black,
    );
    if (labels) {
      for (final (text, x, z) in const [
        ('始まりの村', 93.0, 362.0),
        ('ささやきの森', 60.0, 60.0),
        ('風渡る草原', 140.0, 230.0),
        ('星見の山', 330.0, 140.0),
        ('山上の遺跡', 335.0, 45.0),
        ('東の岩場', 360.0, 200.0),
        ('南東の台地', 330.0, 350.0),
        ('古橋', 220.0, 198.0),
        ('石碑群', 290.0, 312.0),
      ]) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              // CustomPaint の文字にはテーマの字体が効かないので、日本語の字体を指定する
              fontFamily: 'NotoSansJP',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x, z);
        canvas.scale(1 / s);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _star(Canvas canvas, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE04A));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.15
        ..color = Colors.black87,
    );
  }

  @override
  bool shouldRepaint(LandMapPainter old) => true;
}
