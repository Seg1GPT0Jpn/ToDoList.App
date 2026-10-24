part of 'terrain_art.dart';

/// 航路（大海原・深海・雲海・宇宙）のマスの絵。
/// 床は「進める海・空」、障害物は島・サンゴ・雲・小惑星、
/// 水は「うずしお・海溝・雷雲の切れ目・ブラックホール」、橋は「航路」になる。
class _Voyage {
  const _Voyage._();

  static ui.Paint get _ink => TerrainArt._ink;
  static ui.Paint _fill(int argb) => TerrainArt._fill(argb);

  static int floor(Terrain t) => switch (t) {
    Terrain.ocean => 0xFF8CCBEA,
    Terrain.abyss => 0xFF1D3557,
    Terrain.cloudSea => 0xFFD6EAFF,
    _ => 0xFF1A1633,
  };

  static ui.Color grid(Terrain t) => ui.Color(switch (t) {
    Terrain.ocean => 0xFF79BADB,
    Terrain.abyss => 0xFF284469,
    Terrain.cloudSea => 0xFFC2DAF2,
    _ => 0xFF28234A,
  });

  static void floorDetail(ui.Canvas c, Rect r, Terrain t, int col, int row) {
    final k = (col * 7 + row * 13) % 11;
    switch (t) {
      case Terrain.ocean:
        // 小さな波
        if (k == 1 || k == 6) {
          final y = r.top + (k == 1 ? 10 : 22);
          final x = r.left + (k == 1 ? 6 : 14);
          final p = ui.Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + 3, y - 3, x + 6, y)
            ..quadraticBezierTo(x + 9, y - 3, x + 12, y);
          c.drawPath(
            p,
            ui.Paint()
              ..color = const ui.Color(0xCCFFFFFF)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1.1,
          );
        }
      case Terrain.abyss:
        // マリンスノーと泡
        if (k % 3 == 0) {
          c.drawCircle(
            Offset(r.left + 5 + k * 2, r.top + 7 + k),
            0.9,
            _fill(0x88E0F7FA),
          );
        }
        if (k == 7) {
          c.drawCircle(
            Offset(r.left + 22, r.top + 12),
            2.2,
            ui.Paint()
              ..color = const ui.Color(0x9980DEEA)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 0.8,
          );
        }
      case Terrain.cloudSea:
        // 小さな雲のかけら
        if (k == 3) {
          c.drawOval(
            Rect.fromLTWH(r.left + 6, r.top + 18, 14, 6),
            _fill(0xCCFFFFFF),
          );
        }
        if (k == 9) {
          c.drawCircle(Offset(r.left + 24, r.top + 8), 1.2, _fill(0xFFFFF59D));
        }
      default:
        // 星
        if (k % 4 == 0) {
          c.drawCircle(
            Offset(r.left + 4 + k * 2.3, r.top + 5 + k * 1.7),
            k == 8 ? 1.3 : 0.8,
            _fill(k == 4 ? 0xFFFFF59D : 0xFFFFFFFF),
          );
        }
        if (k == 7) {
          final p = ui.Paint()
            ..color = const ui.Color(0xCCFFFFFF)
            ..strokeWidth = 0.8;
          final o = Offset(r.left + 20, r.top + 20);
          c.drawLine(o - const Offset(3, 0), o + const Offset(3, 0), p);
          c.drawLine(o - const Offset(0, 3), o + const Offset(0, 3), p);
        }
    }
  }

  /// 外壁・ゲートの壁（岩礁・深海の岩・雷雲・小惑星帯）
  static void wall(ui.Canvas c, Rect r, Random rnd, Terrain t) {
    final (int base, int spot, int edge) = switch (t) {
      Terrain.ocean => (0xFF5D7A86, 0xFF8FA9B3, 0xFF3E5560),
      Terrain.abyss => (0xFF0D1A2B, 0xFF1F6F78, 0xFF050C16),
      Terrain.cloudSea => (0xFF7E8C9F, 0xFFA7B4C4, 0xFF5B6778),
      _ => (0xFF3A3450, 0xFF5A527A, 0xFF221E33),
    };
    c.drawRect(r, _fill(base));
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
        Offset(
          r.left + 5 + rnd.nextDouble() * 22,
          r.top + 5 + rnd.nextDouble() * 22,
        ),
        1.5 + rnd.nextDouble() * 3,
        _fill(spot),
      );
    }
    if (t == Terrain.ocean) {
      // 岩にくだける白波
      c.drawLine(
        Offset(r.left, r.top + 2),
        Offset(r.right, r.top + 2),
        ui.Paint()
          ..color = const ui.Color(0xDDFFFFFF)
          ..strokeWidth = 2,
      );
    }
    c.drawRect(
      r.deflate(0.5),
      ui.Paint()
        ..color = ui.Color(edge)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// 障害物（島・サンゴと海藻・大きな雲・小惑星）
  static void obstacle(ui.Canvas c, Rect r, Random rnd, Terrain t) {
    final cx = r.center.dx, cy = r.center.dy;
    switch (t) {
      case Terrain.ocean:
        // 小島とヤシの木
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 7), width: 28, height: 12),
          _fill(0xFFF3DFA2),
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 7), width: 28, height: 12),
          _ink..strokeWidth = 1,
        );
        TerrainArt._palm(
          c,
          Rect.fromLTWH(r.left, r.top - 3, r.width, r.height),
        );
      case Terrain.abyss:
        if (rnd.nextBool()) {
          // サンゴ
          final coral = ui.Paint()
            ..color = const ui.Color(0xFFFF8A80)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = ui.StrokeCap.round;
          c.drawLine(Offset(cx, r.bottom - 4), Offset(cx, cy - 4), coral);
          c.drawLine(Offset(cx, cy + 2), Offset(cx - 7, cy - 6), coral);
          c.drawLine(Offset(cx, cy), Offset(cx + 7, cy - 9), coral);
          c.drawLine(Offset(cx - 7, cy - 6), Offset(cx - 9, cy - 11), coral);
        } else {
          // 海藻
          final kelp = ui.Paint()
            ..color = const ui.Color(0xFF4DB6AC)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = ui.StrokeCap.round;
          for (final dx in [-6.0, 0.0, 6.0]) {
            final p = ui.Path()..moveTo(cx + dx, r.bottom - 3);
            p.quadraticBezierTo(cx + dx - 5, cy + 3, cx + dx, cy - 3);
            p.quadraticBezierTo(cx + dx + 5, cy - 8, cx + dx, r.top + 3);
            c.drawPath(p, kelp);
          }
        }
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, r.bottom - 3),
            width: 24,
            height: 6,
          ),
          _fill(0xFF0D1A2B),
        );
      case Terrain.cloudSea:
        ui.Path oval(Offset o, double r) =>
            ui.Path()..addOval(Rect.fromCircle(center: o, radius: r));
        var p = ui.Path.combine(
          ui.PathOperation.union,
          oval(Offset(cx - 8, cy + 3), 8),
          oval(Offset(cx + 7, cy + 2), 9),
        );
        p = ui.Path.combine(
          ui.PathOperation.union,
          p,
          oval(Offset(cx - 1, cy - 6), 9),
        );
        c.drawPath(p, _fill(0xFFFFFFFF));
        c.drawPath(p, _ink..strokeWidth = 1);
      default:
        // 小惑星
        final rock = ui.Path()
          ..moveTo(cx - 11, cy + 2)
          ..lineTo(cx - 6, cy - 9)
          ..lineTo(cx + 5, cy - 11)
          ..lineTo(cx + 12, cy - 1)
          ..lineTo(cx + 8, cy + 10)
          ..lineTo(cx - 5, cy + 11)
          ..close();
        c.drawPath(rock, _fill(0xFF8D8A9E));
        c.drawPath(
          rock,
          ui.Paint()
            ..color = const ui.Color(0xFFEDE7F6)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        c.drawCircle(Offset(cx - 2, cy - 2), 3, _fill(0xFF6E6A80));
        c.drawCircle(Offset(cx + 5, cy + 5), 2, _fill(0xFF6E6A80));
    }
  }

  /// 通れない水（うずしお・海溝・雷雲の切れ目・ブラックホール）
  static void water(ui.Canvas c, Rect r, Terrain t) {
    final cx = r.center.dx, cy = r.center.dy;
    switch (t) {
      case Terrain.ocean:
        c.drawRect(r, _fill(0xFF3D8DBD));
        final p = ui.Path()..moveTo(cx, cy);
        for (var a = 0.0; a < pi * 5; a += 0.4) {
          final rad = a * 1.0;
          p.lineTo(cx + cos(a) * rad, cy + sin(a) * rad);
        }
        c.drawPath(
          p,
          ui.Paint()
            ..color = const ui.Color(0xCCFFFFFF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      case Terrain.abyss:
        c.drawRect(r, _fill(0xFF050A14));
        c.drawCircle(Offset(cx - 5, cy + 4), 1.2, _fill(0x6680DEEA));
        c.drawCircle(Offset(cx + 6, cy - 5), 0.9, _fill(0x6680DEEA));
      case Terrain.cloudSea:
        c.drawRect(r, _fill(0xFF55606E));
        final bolt = ui.Path()
          ..moveTo(cx + 2, r.top + 4)
          ..lineTo(cx - 4, cy + 1)
          ..lineTo(cx + 1, cy + 1)
          ..lineTo(cx - 3, r.bottom - 4)
          ..lineTo(cx + 6, cy - 3)
          ..lineTo(cx + 1, cy - 3)
          ..close();
        c.drawPath(bolt, _fill(0xFFFFEB3B));
      default:
        c.drawRect(r, _fill(0xFF0B0816));
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 26, height: 10),
          ui.Paint()
            ..color = const ui.Color(0xFFB388FF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        c.drawCircle(Offset(cx, cy), 5, _fill(0xFF000000));
    }
  }

  /// 通れる航路（海の道・海流・虹の道・星の道）
  static void bridge(ui.Canvas c, Rect r, Terrain t) {
    switch (t) {
      case Terrain.ocean:
        c.drawRect(r, _fill(0xFFB3E5FC));
        _dashes(c, r, 0xFFFFFFFF);
      case Terrain.abyss:
        c.drawRect(r, _fill(0xFF26607A));
        _dashes(c, r, 0xFF80DEEA);
      case Terrain.cloudSea:
        final h = r.height / 3;
        for (final (i, color) in [0xFFFFCDD2, 0xFFFFF9C4, 0xFFBBDEFB].indexed) {
          c.drawRect(
            Rect.fromLTWH(r.left, r.top + h * i, r.width, h),
            _fill(color),
          );
        }
      default:
        c.drawRect(r, _fill(0xFF2D2760));
        for (var x = r.left + 4; x < r.right; x += 8) {
          c.drawCircle(Offset(x, r.center.dy), 1.4, _fill(0xFFFFF59D));
        }
    }
  }

  static void _dashes(ui.Canvas c, Rect r, int color) {
    final p = ui.Paint()
      ..color = ui.Color(color)
      ..strokeWidth = 1.4;
    for (var x = r.left + 2; x < r.right; x += 8) {
      c.drawLine(
        Offset(x, r.center.dy),
        Offset(min(x + 4, r.right), r.center.dy),
        p,
      );
    }
  }

  /// ボスの間の道（光る航路）
  static void carpet(ui.Canvas c, Rect r, Terrain t) {
    bridge(c, r, t);
    c.drawRect(
      r.deflate(3),
      ui.Paint()
        ..color = const ui.Color(0xAAF2B84B)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// 目印の飾り（ブイ・いかり・気球・輪のある星）
  static void decoration(ui.Canvas c, Rect r, Terrain t) {
    final cx = r.center.dx, cy = r.center.dy;
    switch (t) {
      case Terrain.ocean:
        // ブイ
        final body = Rect.fromCenter(
          center: Offset(cx, cy + 3),
          width: 14,
          height: 16,
        );
        c.drawOval(body, _fill(0xFFE53935));
        c.drawRect(
          Rect.fromLTWH(body.left, cy + 1, body.width, 4),
          _fill(0xFFFFFFFF),
        );
        c.drawOval(body, _ink..strokeWidth = 1);
        c.drawLine(Offset(cx, body.top), Offset(cx, cy - 12), _ink);
        c.drawCircle(Offset(cx, cy - 12), 2, _fill(0xFFFFEB3B));
      case Terrain.abyss:
        // しずんだ、いかり
        final p = ui.Paint()
          ..color = const ui.Color(0xFF90A4AE)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = ui.StrokeCap.round;
        c.drawCircle(Offset(cx, cy - 9), 3, p);
        c.drawLine(Offset(cx, cy - 6), Offset(cx, cy + 9), p);
        c.drawLine(Offset(cx - 6, cy - 3), Offset(cx + 6, cy - 3), p);
        c.drawArc(
          Rect.fromCenter(center: Offset(cx, cy + 3), width: 18, height: 12),
          0,
          pi,
          false,
          p,
        );
      case Terrain.cloudSea:
        // 小さな気球
        c.drawCircle(Offset(cx, cy - 4), 8, _fill(0xFFFFB74D));
        c.drawLine(Offset(cx - 5, cy + 2), Offset(cx - 3, cy + 8), _ink);
        c.drawLine(Offset(cx + 5, cy + 2), Offset(cx + 3, cy + 8), _ink);
        c.drawRect(Rect.fromLTWH(cx - 4, cy + 8, 8, 5), _fill(0xFF8D6E63));
        c.drawCircle(Offset(cx, cy - 4), 8, _ink..strokeWidth = 1);
      default:
        // 輪のある星
        c.drawCircle(Offset(cx, cy), 7, _fill(0xFFFFB74D));
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 7),
          ui.Paint()
            ..color = const ui.Color(0xFFFFE0B2)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
    }
  }

  /// 宿・看板・住人などの足場（小島・海底の岩・雲の台・小さな月）
  static void islet(ui.Canvas c, Rect r, Terrain t) {
    final base = Rect.fromCenter(
      center: Offset(r.center.dx, r.bottom - 7),
      width: r.width + 2,
      height: 14,
    );
    final color = switch (t) {
      Terrain.ocean => 0xFFF3DFA2,
      Terrain.abyss => 0xFF546E7A,
      Terrain.cloudSea => 0xFFFFFFFF,
      _ => 0xFFB0A8C8,
    };
    c.drawOval(base, _fill(color));
    c.drawOval(base, _ink..strokeWidth = 1);
  }
}
