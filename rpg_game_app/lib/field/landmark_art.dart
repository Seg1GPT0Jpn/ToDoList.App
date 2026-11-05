import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui' show Offset, Rect;

import 'field_map.dart';

/// 大きな目印の絵（ノートに色鉛筆で描いたような見た目。マスより少し上にはみ出す）
abstract final class LandmarkArt {
  static ui.Paint _p(int argb, [double a = 1]) =>
      ui.Paint()..color = ui.Color(argb).withValues(alpha: a);

  static final _ink = ui.Paint()
    ..color = const ui.Color(0xFF3E3A4A)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;

  static void _fillInk(ui.Canvas c, ui.Path path, int argb) {
    c.drawPath(path, _p(argb));
    c.drawPath(path, _ink);
  }

  static void _shadow(ui.Canvas c, Rect r, [double scale = 1]) => c.drawOval(
    Rect.fromCenter(
      center: Offset(r.center.dx + 4, r.bottom - 3),
      width: r.width * 0.95 * scale,
      height: r.height * 0.28,
    ),
    ui.Paint()
      ..color = const ui.Color(0x38201A30)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
  );

  static ui.Path _circle(Offset o, double r) =>
      ui.Path()..addOval(Rect.fromCircle(center: o, radius: r));

  /// [r] は目印がしめるマスの範囲
  static void paint(ui.Canvas c, Rect r, LandmarkKind kind) {
    final cx = r.center.dx, w = r.width, h = r.height;
    switch (kind) {
      case LandmarkKind.bigTree ||
          LandmarkKind.blossomTree ||
          LandmarkKind.ancientTree:
        _shadow(c, r);
        final (leaf, dark, light) = switch (kind) {
          LandmarkKind.blossomTree => (0xFFF3A9BE, 0xFFB0566F, 0xFFFFDDE6),
          LandmarkKind.ancientTree => (0xFF3F7A45, 0xFF1F3F26, 0xFF7DB070),
          _ => (0xFF6FAE58, 0xFF35663A, 0xFFB5DB8C),
        };
        // 幹と根
        final trunk = ui.Path()
          ..moveTo(cx - w * 0.12, r.bottom - 4)
          ..quadraticBezierTo(
            cx - w * 0.08,
            r.top + h * 0.5,
            cx - w * 0.05,
            r.top + h * 0.35,
          )
          ..lineTo(cx + w * 0.05, r.top + h * 0.35)
          ..quadraticBezierTo(
            cx + w * 0.08,
            r.top + h * 0.5,
            cx + w * 0.12,
            r.bottom - 4,
          )
          ..close();
        _fillInk(c, trunk, 0xFF8A5A3C);
        c.drawLine(
          Offset(cx - w * 0.02, r.bottom - 8),
          Offset(cx, r.top + h * 0.5),
          _p(0xFF5D3A26, 0.6)..strokeWidth = 1.2,
        );
        // 葉のかたまり（外側だけをなぞる）
        final blobs = [
          (Offset(cx, r.top - h * 0.05), w * 0.36),
          (Offset(cx - w * 0.28, r.top + h * 0.12), w * 0.27),
          (Offset(cx + w * 0.28, r.top + h * 0.12), w * 0.27),
          (Offset(cx - w * 0.14, r.top + h * 0.3), w * 0.25),
          (Offset(cx + w * 0.16, r.top + h * 0.3), w * 0.25),
        ];
        for (final (o, rad) in blobs) {
          c.drawCircle(o, rad + 1.8, _p(dark));
        }
        for (final (o, rad) in blobs) {
          c.drawCircle(o, rad, _p(leaf));
        }
        for (final (o, rad) in blobs) {
          c.drawCircle(
            o.translate(-rad * 0.3, -rad * 0.35),
            rad * 0.45,
            _p(light, 0.6),
          );
        }
        if (kind == LandmarkKind.blossomTree) {
          for (var i = 0; i < 14; i++) {
            final a = i * 2.4;
            c.drawCircle(
              Offset(
                cx + cos(a) * w * 0.3 * (i % 3 + 1) / 3,
                r.top + h * 0.1 + sin(a) * h * 0.2,
              ),
              2,
              _p(0xFFFFFFFF),
            );
          }
        } else if (kind == LandmarkKind.bigTree) {
          for (var i = 0; i < 6; i++) {
            final a = i * 1.9;
            c.drawCircle(
              Offset(
                cx + cos(a) * w * 0.28,
                r.top + h * 0.1 + sin(a) * h * 0.18,
              ),
              2.6,
              _p(0xFFE53935),
            );
          }
        } else {
          // 古い大樹：幹のしめ縄
          c.drawLine(
            Offset(cx - w * 0.1, r.top + h * 0.62),
            Offset(cx + w * 0.1, r.top + h * 0.62),
            _p(0xFFEFE3C2)..strokeWidth = 3,
          );
        }

      case LandmarkKind.windmill:
        _shadow(c, r, 0.7);
        final body = ui.Path()
          ..moveTo(cx - w * 0.22, r.bottom - 3)
          ..lineTo(cx - w * 0.14, r.top + h * 0.2)
          ..lineTo(cx + w * 0.14, r.top + h * 0.2)
          ..lineTo(cx + w * 0.22, r.bottom - 3)
          ..close();
        _fillInk(c, body, 0xFFF3E3C3);
        final roof = ui.Path()
          ..moveTo(cx - w * 0.19, r.top + h * 0.22)
          ..lineTo(cx, r.top - h * 0.02)
          ..lineTo(cx + w * 0.19, r.top + h * 0.22)
          ..close();
        _fillInk(c, roof, 0xFFB5523B);
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.bottom - h * 0.14),
            width: w * 0.12,
            height: h * 0.22,
          ),
          _p(0xFF7A4A30),
        );
        final hub = Offset(cx, r.top + h * 0.2);
        for (var i = 0; i < 4; i++) {
          final a = i * pi / 2 + 0.4;
          final tip = hub + Offset(cos(a), sin(a)) * w * 0.48;
          final side = Offset(-sin(a), cos(a)) * w * 0.08;
          final blade = ui.Path()
            ..moveTo(hub.dx, hub.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(tip.dx + side.dx, tip.dy + side.dy)
            ..lineTo(hub.dx + side.dx * 0.4, hub.dy + side.dy * 0.4)
            ..close();
          _fillInk(c, blade, 0xFFFFFFFF);
        }
        c.drawCircle(hub, 3, _p(0xFF5D4037));

      case LandmarkKind.lighthouse:
        _shadow(c, r, 0.6);
        final tower = ui.Path()
          ..moveTo(cx - w * 0.2, r.bottom - 3)
          ..lineTo(cx - w * 0.12, r.top + h * 0.05)
          ..lineTo(cx + w * 0.12, r.top + h * 0.05)
          ..lineTo(cx + w * 0.2, r.bottom - 3)
          ..close();
        _fillInk(c, tower, 0xFFFFFFFF);
        c.save();
        c.clipPath(tower);
        for (var k = 0; k < 3; k++) {
          final y = r.top + h * (0.2 + k * 0.28);
          c.drawRect(Rect.fromLTWH(r.left, y, w, h * 0.13), _p(0xFFD64545));
        }
        c.restore();
        c.drawPath(tower, _ink);
        c.drawCircle(
          Offset(cx, r.top - h * 0.02),
          w * 0.3,
          _p(0xFFFFE08A, 0.35),
        );
        final lamp = Rect.fromCenter(
          center: Offset(cx, r.top - h * 0.02),
          width: w * 0.2,
          height: h * 0.16,
        );
        c.drawRect(lamp, _p(0xFFFFE08A));
        c.drawRect(lamp, _ink);
        final cap = ui.Path()
          ..moveTo(cx - w * 0.14, lamp.top)
          ..lineTo(cx, lamp.top - h * 0.12)
          ..lineTo(cx + w * 0.14, lamp.top)
          ..close();
        _fillInk(c, cap, 0xFF3F5A7A);

      case LandmarkKind.pyramid:
        _shadow(c, r);
        final py = ui.Path()
          ..moveTo(r.left + 2, r.bottom - 3)
          ..lineTo(cx, r.top - h * 0.15)
          ..lineTo(r.right - 2, r.bottom - 3)
          ..close();
        _fillInk(c, py, 0xFFE8C77E);
        final side = ui.Path()
          ..moveTo(cx, r.top - h * 0.15)
          ..lineTo(r.right - 2, r.bottom - 3)
          ..lineTo(cx + w * 0.1, r.bottom - 3)
          ..close();
        c.drawPath(side, _p(0xFFB8914A, 0.6));
        for (var k = 1; k <= 4; k++) {
          final y = r.bottom - 3 - (h * 1.15) * k / 5;
          final half = (w / 2 - 2) * (1 - k / 5);
          c.drawLine(
            Offset(cx - half, y),
            Offset(cx + half, y),
            _p(0xFF9C7A3C, 0.5)..strokeWidth = 0.9,
          );
        }
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.bottom - h * 0.15),
            width: w * 0.08,
            height: h * 0.2,
          ),
          _p(0xFF5D4037),
        );

      case LandmarkKind.snowman:
        _shadow(c, r, 0.7);
        _fillInk(
          c,
          _circle(Offset(cx, r.bottom - h * 0.3), w * 0.3),
          0xFFFFFFFF,
        );
        _fillInk(
          c,
          _circle(Offset(cx, r.top + h * 0.22), w * 0.21),
          0xFFFFFFFF,
        );
        // 帽子
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.top - h * 0.02),
            width: w * 0.26,
            height: h * 0.16,
          ),
          _p(0xFF3E3A4A),
        );
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.06),
            width: w * 0.36,
            height: 3,
          ),
          _p(0xFF3E3A4A),
        );
        // 目と鉛筆の鼻
        c.drawCircle(Offset(cx - w * 0.07, r.top + h * 0.2), 2, _p(0xFF3E3A4A));
        c.drawCircle(Offset(cx + w * 0.07, r.top + h * 0.2), 2, _p(0xFF3E3A4A));
        final nose = ui.Path()
          ..moveTo(cx, r.top + h * 0.25)
          ..lineTo(cx + w * 0.18, r.top + h * 0.28)
          ..lineTo(cx, r.top + h * 0.3)
          ..close();
        c.drawPath(nose, _p(0xFFF2A93B));
        // マフラー
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.4),
            width: w * 0.4,
            height: 5,
          ),
          _p(0xFFD64545),
        );

      case LandmarkKind.crystals:
        _shadow(c, r);
        for (final (dx, hh, col) in const [
          (-0.25, 0.75, 0xFF9AD1D4),
          (0.22, 0.65, 0xFFB39DDB),
          (0.0, 1.05, 0xFFC5E8F2),
        ]) {
          final x = cx + w * dx;
          final top = r.bottom - h * hh * 1.1;
          final cr = ui.Path()
            ..moveTo(x, top)
            ..lineTo(x + w * 0.13, top + h * 0.18)
            ..lineTo(x + w * 0.1, r.bottom - 4)
            ..lineTo(x - w * 0.1, r.bottom - 4)
            ..lineTo(x - w * 0.13, top + h * 0.18)
            ..close();
          _fillInk(c, cr, col);
          c.drawLine(
            Offset(x - w * 0.03, top + h * 0.12),
            Offset(x - w * 0.05, r.bottom - h * 0.25),
            _p(0xFFFFFFFF, 0.8)..strokeWidth = 1.6,
          );
        }

      case LandmarkKind.vent:
        _shadow(c, r);
        final cone = ui.Path()
          ..moveTo(r.left + 3, r.bottom - 3)
          ..lineTo(cx - w * 0.18, r.top + h * 0.15)
          ..lineTo(cx + w * 0.18, r.top + h * 0.15)
          ..lineTo(r.right - 3, r.bottom - 3)
          ..close();
        _fillInk(c, cone, 0xFF3A2724);
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.16),
            width: w * 0.4,
            height: h * 0.14,
          ),
          _p(0xFFE4572E),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.16),
            width: w * 0.25,
            height: h * 0.08,
          ),
          _p(0xFFFFC069),
        );
        for (var i = 0; i < 3; i++) {
          final x = cx - w * 0.15 + i * w * 0.12;
          final lava = ui.Path()
            ..moveTo(x, r.top + h * 0.2)
            ..quadraticBezierTo(
              x + 4,
              r.top + h * 0.5,
              x - 2,
              r.top + h * (0.55 + i * 0.1),
            );
          c.drawPath(
            lava,
            _p(0xFFE4572E)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }
        c.drawCircle(
          Offset(cx, r.top - h * 0.05),
          w * 0.12,
          _p(0xFF8A8A8A, 0.35),
        );
        c.drawCircle(
          Offset(cx + w * 0.1, r.top - h * 0.2),
          w * 0.09,
          _p(0xFF8A8A8A, 0.25),
        );

      case LandmarkKind.statue:
        _shadow(c, r, 0.8);
        final base = Rect.fromLTRB(
          cx - w * 0.32,
          r.bottom - h * 0.32,
          cx + w * 0.32,
          r.bottom - 3,
        );
        c.drawRect(base, _p(0xFFCFC8B8));
        c.drawRect(base, _ink);
        c.drawRect(
          Rect.fromLTRB(base.left, base.top, base.right, base.top + 4),
          _p(0xFFE9E3D4),
        );
        // 剣をかかげた人
        const stone = 0xFFB9B4A8;
        _fillInk(c, _circle(Offset(cx, r.top + h * 0.12), w * 0.09), stone);
        final body = ui.Path()
          ..moveTo(cx - w * 0.14, base.top)
          ..lineTo(cx - w * 0.1, r.top + h * 0.22)
          ..lineTo(cx + w * 0.1, r.top + h * 0.22)
          ..lineTo(cx + w * 0.14, base.top)
          ..close();
        _fillInk(c, body, stone);
        c.drawLine(
          Offset(cx + w * 0.1, r.top + h * 0.28),
          Offset(cx + w * 0.22, r.top - h * 0.12),
          _p(0xFF8A8478)..strokeWidth = 3,
        );
        c.drawLine(
          Offset(cx + w * 0.1, r.top + h * 0.28),
          Offset(cx + w * 0.22, r.top - h * 0.12),
          _ink..strokeWidth = 1,
        );
        _ink.strokeWidth = 1.5;

      case LandmarkKind.fountain:
        _shadow(c, r);
        final pool = Rect.fromLTRB(
          r.left + 3,
          r.top + h * 0.35,
          r.right - 3,
          r.bottom - 4,
        );
        c.drawOval(pool, _p(0xFFCFC8B8));
        c.drawOval(pool, _ink);
        c.drawOval(pool.deflate(5), _p(0xFF7EB7DA));
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.38),
            width: w * 0.1,
            height: h * 0.3,
          ),
          _p(0xFFCFC8B8),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.22),
            width: w * 0.36,
            height: h * 0.1,
          ),
          _p(0xFFCFC8B8),
        );
        // 水しぶき
        for (final s in [-1.0, 1.0]) {
          final arc = ui.Path()
            ..moveTo(cx, r.top + h * 0.12)
            ..quadraticBezierTo(
              cx + s * w * 0.25,
              r.top - h * 0.1,
              cx + s * w * 0.3,
              r.top + h * 0.5,
            );
          c.drawPath(
            arc,
            _p(0xFFFFFFFF, 0.9)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }

      case LandmarkKind.clock:
        _shadow(c, r, 0.7);
        final tower = Rect.fromLTRB(
          cx - w * 0.24,
          r.top - h * 0.05,
          cx + w * 0.24,
          r.bottom - 3,
        );
        c.drawRect(tower, _p(0xFF8E7CA8));
        c.drawRect(tower, _ink);
        final face = Offset(cx, r.top + h * 0.22);
        _fillInk(c, _circle(face, w * 0.19), 0xFFFFF8E7);
        c.drawLine(face, face.translate(0, -w * 0.13), _ink);
        c.drawLine(face, face.translate(w * 0.1, w * 0.03), _ink);
        final cap = ui.Path()
          ..moveTo(tower.left - 3, tower.top)
          ..lineTo(cx, tower.top - h * 0.22)
          ..lineTo(tower.right + 3, tower.top)
          ..close();
        _fillInk(c, cap, 0xFF4A3F66);
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.bottom - h * 0.15),
            width: w * 0.14,
            height: h * 0.22,
          ),
          _p(0xFF4A3F66),
        );

      case LandmarkKind.gears:
        _shadow(c, r);
        for (final (o, rad, col) in [
          (Offset(cx - w * 0.15, r.top + h * 0.55), w * 0.24, 0xFFB08D57),
          (Offset(cx + w * 0.2, r.top + h * 0.3), w * 0.18, 0xFF9E9E9E),
        ]) {
          final g = ui.Path();
          for (var i = 0; i < 16; i++) {
            final a = i * pi / 8;
            final rr = i.isEven ? rad : rad * 0.8;
            final p = o + Offset(cos(a), sin(a)) * rr;
            i == 0 ? g.moveTo(p.dx, p.dy) : g.lineTo(p.dx, p.dy);
          }
          g.close();
          _fillInk(c, g, col);
          _fillInk(c, _circle(o, rad * 0.3), 0xFF5A5A5A);
        }

      case LandmarkKind.globe:
        _shadow(c, r, 0.7);
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.bottom - h * 0.12),
            width: w * 0.4,
            height: 5,
          ),
          _p(0xFF8A5A3C),
        );
        c.drawLine(
          Offset(cx, r.bottom - h * 0.14),
          Offset(cx, r.top + h * 0.6),
          _ink..strokeWidth = 3,
        );
        _ink.strokeWidth = 1.5;
        final o = Offset(cx, r.top + h * 0.32);
        _fillInk(c, _circle(o, w * 0.3), 0xFF7EB7DA);
        c.save();
        c.clipPath(_circle(o, w * 0.3));
        c.drawOval(
          Rect.fromCenter(
            center: o.translate(-w * 0.1, -h * 0.05),
            width: w * 0.25,
            height: h * 0.3,
          ),
          _p(0xFF8CC06B),
        );
        c.drawOval(
          Rect.fromCenter(
            center: o.translate(w * 0.15, h * 0.08),
            width: w * 0.2,
            height: h * 0.2,
          ),
          _p(0xFF8CC06B),
        );
        c.restore();
        c.drawArc(
          Rect.fromCircle(center: o, radius: w * 0.36),
          -2.4,
          3.6,
          false,
          _ink,
        );

      case LandmarkKind.house:
        _shadow(c, r);
        // 壁の色・屋根の色は場所で変える
        final v = (r.left * 7 + r.top * 13).round() % 4;
        final wallColor = const [
          0xFFF6E7C8,
          0xFFEFD9D0,
          0xFFE3E9F2,
          0xFFF1EBD5,
        ][v];
        final roofColor = const [
          0xFFC0563E,
          0xFF5B7DB8,
          0xFF6E9C5A,
          0xFF9A6BB0,
        ][v];
        final body = Rect.fromLTRB(
          r.left + w * 0.08,
          r.top + h * 0.3,
          r.right - w * 0.08,
          r.bottom - 3,
        );
        c.drawRect(body, _p(wallColor));
        c.drawRect(body, _ink);
        final roof = ui.Path()
          ..moveTo(r.left + 1, body.top + 3)
          ..lineTo(r.left + w * 0.2, r.top - h * 0.1)
          ..lineTo(r.right - w * 0.2, r.top - h * 0.1)
          ..lineTo(r.right - 1, body.top + 3)
          ..close();
        _fillInk(c, roof, roofColor);
        for (var k = 1; k <= 3; k++) {
          final y =
              r.top - h * 0.1 + (body.top + 3 - (r.top - h * 0.1)) * k / 4;
          c.drawLine(
            Offset(r.left + w * 0.1, y),
            Offset(r.right - w * 0.1, y),
            _p(0xFF000000, 0.15)..strokeWidth = 0.8,
          );
        }
        // 窓（あかり）と扉
        for (final dx in [-0.3, 0.3]) {
          final win = Rect.fromCenter(
            center: Offset(cx + w * dx, body.top + body.height * 0.45),
            width: w * 0.12,
            height: h * 0.2,
          );
          c.drawRect(win, _p(0xFFFFD36B));
          c.drawRect(win, _ink..strokeWidth = 1);
          c.drawLine(win.centerLeft, win.centerRight, _ink);
        }
        _ink.strokeWidth = 1.5;
        c.drawRRect(
          ui.RRect.fromRectAndCorners(
            Rect.fromCenter(
              center: Offset(cx, r.bottom - h * 0.17),
              width: w * 0.12,
              height: h * 0.3,
            ),
            topLeft: const ui.Radius.circular(4),
            topRight: const ui.Radius.circular(4),
          ),
          _p(0xFF7A4A30),
        );
        // 植木ばち
        c.drawCircle(Offset(body.left + 5, r.bottom - 6), 4, _p(0xFF6FAE58));
        c.drawRect(
          Rect.fromLTWH(body.left + 2, r.bottom - 6, 6, 4),
          _p(0xFFB5763B),
        );

      case LandmarkKind.cloudCastle:
        for (final (dx, dy, rad) in const [
          (-0.3, 0.75, 0.22),
          (0.0, 0.8, 0.26),
          (0.3, 0.75, 0.22),
        ]) {
          _fillInk(
            c,
            _circle(Offset(cx + w * dx, r.top + h * dy), w * rad),
            0xFFFFFFFF,
          );
        }
        final keep = Rect.fromLTRB(
          cx - w * 0.22,
          r.top + h * 0.15,
          cx + w * 0.22,
          r.top + h * 0.62,
        );
        c.drawRect(keep, _p(0xFFE8E4F5));
        c.drawRect(keep, _ink);
        for (final dx in [-0.22, 0.22]) {
          final t = Rect.fromLTRB(
            cx + w * dx - w * 0.08,
            r.top,
            cx + w * dx + w * 0.08,
            r.top + h * 0.62,
          );
          c.drawRect(t, _p(0xFFD6D0EE));
          c.drawRect(t, _ink);
          final roof = ui.Path()
            ..moveTo(t.left - 2, t.top)
            ..lineTo(t.center.dx, t.top - h * 0.2)
            ..lineTo(t.right + 2, t.top)
            ..close();
          _fillInk(c, roof, 0xFF6A8FD6);
        }
        c.drawRect(
          Rect.fromCenter(
            center: Offset(cx, r.top + h * 0.5),
            width: w * 0.12,
            height: h * 0.2,
          ),
          _p(0xFF6A8FD6),
        );
    }
  }
}
