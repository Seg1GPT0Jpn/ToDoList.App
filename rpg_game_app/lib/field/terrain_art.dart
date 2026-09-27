import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui' show Offset, Rect;

import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';

/// 地形ごとのマスの絵（方眼ノートに色鉛筆で描いたような見た目）。
class TerrainArt {
  const TerrainArt._();

  static final _ink = ui.Paint()
    ..color = TsuzuriColors.ink
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = ui.StrokeCap.round;

  static ui.Paint _fill(int argb) => ui.Paint()..color = ui.Color(argb);

  /// 床の色
  static ui.Color floor(Terrain t) => ui.Color(switch (t) {
    Terrain.meadow => 0xFFF4F7E6,
    Terrain.flower => 0xFFFBF1F2,
    Terrain.forest => 0xFFE8F0DC,
    Terrain.hill => 0xFFF2ECD6,
    Terrain.river => 0xFFEAF3EE,
    Terrain.beach => 0xFFF6E8C4,
    Terrain.harbor => 0xFFE9DCC4,
    Terrain.cave => 0xFFD6D0C8,
    Terrain.crystal => 0xFFD3DCE3,
    Terrain.ruins => 0xFFE3DCCD,
    Terrain.shrine => 0xFFF1E4CC,
    Terrain.town => 0xFFEDE6DA,
    Terrain.workshop => 0xFFDCD6CE,
    Terrain.library => 0xFFEDE0C8,
    Terrain.tower => 0xFFE0DCE6,
    Terrain.sky => 0xFFF0F6FF,
    Terrain.snow => 0xFFF7FAFC,
    Terrain.desert => 0xFFF3DFB0,
    Terrain.lava => 0xFF4A3530,
    Terrain.castle => 0xFFDCD7E0,
  });

  /// 方眼の線の色
  static ui.Color grid(Terrain t) => switch (t) {
    Terrain.lava => const ui.Color(0xFF5E4640),
    Terrain.cave || Terrain.workshop => const ui.Color(0xFFBDB5AB),
    Terrain.crystal ||
    Terrain.tower ||
    Terrain.castle => const ui.Color(0xFFB9BCD0),
    Terrain.beach ||
    Terrain.desert ||
    Terrain.harbor => const ui.Color(0xFFE6D3A6),
    Terrain.library ||
    Terrain.shrine ||
    Terrain.ruins => const ui.Color(0xFFD8C8A8),
    _ => const ui.Color(0xFFCFDDEA),
  };

  /// 床の模様（石だたみ・板の間・砂紋など）
  static void floorDetail(ui.Canvas c, Rect r, Terrain t, int col, int row) {
    final k = (col * 7 + row * 13) % 11;
    switch (t) {
      case Terrain.lava:
        if (k % 5 == 0) {
          c.drawLine(
            Offset(r.left + 8, r.top + 6),
            Offset(r.left + 17, r.top + 20),
            ui.Paint()
              ..color = const ui.Color(0x66FF7A3D)
              ..strokeWidth = 1,
          );
        }
      case Terrain.flower || Terrain.meadow:
        if (k == 3) {
          final p = _fill(t == Terrain.flower ? 0xFFF48FB1 : 0xFFFFE082);
          for (var i = 0; i < 4; i++) {
            final a = i * pi / 2;
            c.drawCircle(
              Offset(r.left + 10 + cos(a) * 2.5, r.top + 20 + sin(a) * 2.5),
              2,
              p,
            );
          }
        } else if (k == 7) {
          final grass = ui.Paint()
            ..color = const ui.Color(0xFF8CC06B)
            ..strokeWidth = 1.2;
          c.drawLine(
            Offset(r.left + 20, r.top + 24),
            Offset(r.left + 18, r.top + 18),
            grass,
          );
          c.drawLine(
            Offset(r.left + 21, r.top + 24),
            Offset(r.left + 23, r.top + 17),
            grass,
          );
        }
      case Terrain.ruins || Terrain.castle || Terrain.town:
        // 石だたみ
        final line = ui.Paint()
          ..color = const ui.Color(0x33000000)
          ..strokeWidth = 0.8;
        final off = row.isEven ? 0.0 : r.width / 2;
        c.drawLine(
          Offset(r.left + off, r.top),
          Offset(r.left + off, r.top + r.height / 2),
          line,
        );
        c.drawLine(
          Offset(r.left, r.top + r.height / 2),
          Offset(r.right, r.top + r.height / 2),
          line,
        );
      case Terrain.library || Terrain.shrine:
        // 板の間
        final line = ui.Paint()
          ..color = const ui.Color(0x228D6E63)
          ..strokeWidth = 1;
        for (final y in [r.top + 8, r.top + 16, r.top + 24]) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y), line);
        }
      case Terrain.desert || Terrain.beach:
        if (k % 3 == 0) {
          final p = ui.Path()
            ..moveTo(r.left + 4, r.top + 18)
            ..quadraticBezierTo(
              r.left + 16,
              r.top + 12,
              r.left + 28,
              r.top + 18,
            );
          c.drawPath(
            p,
            ui.Paint()
              ..color = const ui.Color(0x55C8A165)
              ..style = ui.PaintingStyle.stroke,
          );
        }
      case Terrain.snow:
        if (k % 4 == 0) {
          c.drawCircle(
            Offset(r.left + 8 + k.toDouble(), r.top + 10),
            1.2,
            _fill(0xFFB3D4E6),
          );
        }
      case Terrain.crystal:
        if (k == 5) {
          c.drawCircle(Offset(r.left + 22, r.top + 9), 1.5, _fill(0xAA9AD1D4));
        }
      case Terrain.sky:
        if (k == 2) {
          c.drawCircle(Offset(r.left + 20, r.top + 10), 1.4, _fill(0xFFFFE082));
        }
      default:
        break;
    }
  }

  /// 壁の色（外壁・ゲートの壁）
  static void wall(ui.Canvas c, Rect r, Random rnd, Terrain t) {
    final (int base, int hatch, int edge) = switch (t) {
      Terrain.lava => (0xFF2B1D1D, 0x55E4572E, 0xFF1A1111),
      Terrain.cave || Terrain.crystal => (0xFF7A746E, 0x55474038, 0xFF4E4842),
      Terrain.castle || Terrain.tower => (0xFF9E9AAE, 0x556A6480, 0xFF5C566E),
      Terrain.ruins || Terrain.shrine => (0xFFC9B79A, 0x558D6E63, 0xFF8D6E63),
      Terrain.library => (0xFF8D6E63, 0x55503A30, 0xFF5D4037),
      Terrain.workshop => (0xFF8A8A8A, 0x55505050, 0xFF5A5A5A),
      Terrain.town => (0xFFC6A98A, 0x558D6E63, 0xFF8D6E63),
      Terrain.snow => (0xFFCFE0EA, 0x5590A4AE, 0xFF90A4AE),
      Terrain.sky => (0xFFD6E6F5, 0x5590A4C8, 0xFF90A4C8),
      Terrain.beach ||
      Terrain.desert ||
      Terrain.harbor => (0xFFD9B98A, 0x558D6E63, 0xFF8D6E63),
      Terrain.forest => (0xFF7FA66A, 0x55466B3A, 0xFF4F7A40),
      _ => (0xFFD9C7A5, 0x558D6E63, 0xFF8D6E63),
    };
    c.drawRect(r, _fill(base));
    final hp = ui.Paint()
      ..color = ui.Color(hatch)
      ..strokeWidth = 1;
    if (t.layout == Layout.grid) {
      // れんが積み
      for (var y = r.top; y < r.bottom; y += 8) {
        c.drawLine(Offset(r.left, y), Offset(r.right, y), hp);
        final off = ((y - r.top) ~/ 8).isEven ? 0.0 : 8.0;
        for (var x = r.left + off; x < r.right; x += 16) {
          c.drawLine(Offset(x, y), Offset(x, min(y + 8, r.bottom)), hp);
        }
      }
    } else {
      for (var i = -1; i < 4; i++) {
        final x = r.left + i * 9 + rnd.nextDouble() * 3;
        c.drawLine(Offset(x, r.bottom), Offset(x + 12, r.top), hp);
      }
    }
    c.drawRect(
      r.deflate(0.5),
      ui.Paint()
        ..color = ui.Color(edge)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  static void _shadow(ui.Canvas c, Rect r, [double w = 20]) => c.drawOval(
    Rect.fromCenter(
      center: Offset(r.center.dx, r.bottom - 3),
      width: w,
      height: 6,
    ),
    _fill(0x33000000),
  );

  /// 障害物（木・岩・柱・本棚など）
  static void obstacle(ui.Canvas c, Rect r, Random rnd, Terrain t) {
    final cx = r.center.dx, cy = r.center.dy;
    switch (t) {
      case Terrain.meadow || Terrain.hill || Terrain.river:
        _shadow(c, r);
        _roundTree(c, r, rnd, 0xFF8CC06B);
      case Terrain.flower:
        _shadow(c, r);
        _roundTree(c, r, rnd, 0xFFF8BBD0, blossoms: true);
      case Terrain.forest:
        _shadow(c, r);
        _pine(c, r, 0xFF4F8A4A);
      case Terrain.snow:
        _shadow(c, r);
        _pine(c, r, 0xFF6E9C8A, snow: true);
      case Terrain.beach || Terrain.harbor:
        _shadow(c, r);
        _palm(c, r);
      case Terrain.desert:
        _shadow(c, r, 14);
        _cactus(c, r);
      case Terrain.cave || Terrain.crystal:
        _rock(
          c,
          r,
          crystal: true,
          color: t == Terrain.crystal ? 0xFFB39DDB : 0xFF9AD1D4,
        );
      case Terrain.lava:
        final spike = ui.Path()
          ..moveTo(cx - 10, r.bottom - 4)
          ..lineTo(cx - 3, cy - 12)
          ..lineTo(cx + 1, cy - 2)
          ..lineTo(cx + 5, cy - 9)
          ..lineTo(cx + 10, r.bottom - 4)
          ..close();
        c.drawPath(spike, _fill(0xFF1E1414));
        c.drawPath(
          spike,
          ui.Paint()
            ..color = const ui.Color(0xFFE4572E)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      case Terrain.ruins || Terrain.castle || Terrain.shrine:
        _shadow(c, r, 18);
        _pillar(c, r, switch (t) {
          Terrain.shrine => 0xFFC0504D,
          Terrain.castle => 0xFFB0AABF,
          _ => 0xFFD8CCB4,
        }, broken: t == Terrain.ruins && rnd.nextDouble() < 0.35);
      case Terrain.library:
        _shelf(c, r, rnd);
      case Terrain.town:
        _house(c, r, rnd);
      case Terrain.workshop:
        _crate(c, r, rnd);
      case Terrain.tower:
        _shelf(c, r, rnd, gears: true);
      case Terrain.sky:
        _cloud(c, r);
    }
  }

  static void _roundTree(
    ui.Canvas c,
    Rect r,
    Random rnd,
    int color, {
    bool blossoms = false,
  }) {
    final cx = r.center.dx, cy = r.center.dy;
    c.drawRect(Rect.fromLTWH(cx - 2.5, cy + 2, 5, 11), _fill(0xFF8D6E63));
    final blob = ui.Path();
    for (var i = 0; i < 5; i++) {
      final a = i / 5 * 2 * pi;
      blob.addOval(
        Rect.fromCircle(
          center: Offset(cx + cos(a) * 6, cy - 3 + sin(a) * 5),
          radius: 7 + rnd.nextDouble() * 2,
        ),
      );
    }
    c.drawPath(blob, _fill(color));
    c.drawPath(blob, _ink..strokeWidth = 1.2);
    if (blossoms) {
      for (var i = 0; i < 4; i++) {
        c.drawCircle(
          Offset(cx - 6 + rnd.nextDouble() * 12, cy - 8 + rnd.nextDouble() * 9),
          1.6,
          _fill(0xFFE91E63),
        );
      }
    }
  }

  static void _pine(ui.Canvas c, Rect r, int color, {bool snow = false}) {
    final cx = r.center.dx;
    c.drawRect(Rect.fromLTWH(cx - 2, r.bottom - 9, 4, 6), _fill(0xFF6D4C41));
    for (var i = 0; i < 3; i++) {
      final top = r.top + 2 + i * 7.0;
      final half = 6.0 + i * 3;
      final p = ui.Path()
        ..moveTo(cx, top)
        ..lineTo(cx + half, top + 10)
        ..lineTo(cx - half, top + 10)
        ..close();
      c.drawPath(p, _fill(color));
      c.drawPath(p, _ink..strokeWidth = 1);
      if (snow) {
        final s = ui.Path()
          ..moveTo(cx, top)
          ..lineTo(cx + half * 0.5, top + 5)
          ..lineTo(cx - half * 0.5, top + 5)
          ..close();
        c.drawPath(s, _fill(0xFFFFFFFF));
      }
    }
  }

  static void _palm(ui.Canvas c, Rect r) {
    final cx = r.center.dx, cy = r.center.dy;
    final trunk = ui.Path()
      ..moveTo(cx - 2, r.bottom - 3)
      ..quadraticBezierTo(cx + 4, cy + 4, cx + 1, cy - 6)
      ..lineTo(cx + 4, cy - 6)
      ..quadraticBezierTo(cx + 7, cy + 4, cx + 2, r.bottom - 3)
      ..close();
    c.drawPath(trunk, _fill(0xFFB08968));
    final leaf = _fill(0xFF4FA36B);
    for (final a in [-2.6, -2.0, -1.2, -0.5, 0.2]) {
      final p = ui.Path()
        ..moveTo(cx + 2, cy - 7)
        ..quadraticBezierTo(
          cx + 2 + cos(a) * 7,
          cy - 7 + sin(a) * 7 - 3,
          cx + 2 + cos(a) * 13,
          cy - 7 + sin(a) * 9 + 4,
        )
        ..quadraticBezierTo(
          cx + 2 + cos(a) * 6,
          cy - 7 + sin(a) * 5,
          cx + 2,
          cy - 7,
        );
      c.drawPath(p, leaf);
      c.drawPath(p, _ink..strokeWidth = 0.8);
    }
  }

  static void _cactus(ui.Canvas c, Rect r) {
    final cx = r.center.dx;
    final body = ui.RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 4, r.top + 5, 8, r.height - 9),
      const ui.Radius.circular(4),
    );
    c.drawRRect(body, _fill(0xFF66A36B));
    c.drawRRect(body, _ink..strokeWidth = 1.1);
    for (final (dx, y) in [(-1.0, 12.0), (1.0, 16.0)]) {
      final arm = ui.RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + dx * 9 - 2.5, r.top + y - 6, 5, 9),
        const ui.Radius.circular(2.5),
      );
      c.drawRRect(arm, _fill(0xFF66A36B));
      c.drawRRect(arm, _ink..strokeWidth = 1);
    }
  }

  static void _rock(
    ui.Canvas c,
    Rect r, {
    bool crystal = false,
    int color = 0xFF9AD1D4,
  }) {
    final cx = r.center.dx, cy = r.center.dy;
    final rock = ui.Path()
      ..moveTo(cx - 11, r.bottom - 4)
      ..lineTo(cx - 8, cy - 2)
      ..lineTo(cx - 1, cy - 7)
      ..lineTo(cx + 8, cy - 3)
      ..lineTo(cx + 11, r.bottom - 4)
      ..close();
    c.drawPath(rock, _fill(0xFF8E8780));
    c.drawPath(rock, _ink..strokeWidth = 1.2);
    if (crystal) {
      final p = ui.Path()
        ..moveTo(cx + 2, cy - 12)
        ..lineTo(cx + 6, cy - 4)
        ..lineTo(cx + 2, cy)
        ..lineTo(cx - 2, cy - 4)
        ..close();
      c.drawPath(p, _fill(color));
      c.drawPath(p, _ink..strokeWidth = 0.8);
    }
  }

  static void _pillar(ui.Canvas c, Rect r, int color, {bool broken = false}) {
    final cx = r.center.dx;
    final top = broken ? r.top + 12 : r.top + 3;
    c.drawRect(Rect.fromLTWH(cx - 9, r.bottom - 7, 18, 4), _fill(color));
    final body = Rect.fromLTWH(cx - 6, top + 3, 12, r.bottom - 7 - top - 3);
    c.drawRect(body, _fill(color));
    c.drawRect(body, _ink..strokeWidth = 1.1);
    for (final dx in [-2.5, 2.5]) {
      c.drawLine(
        Offset(cx + dx, body.top + 2),
        Offset(cx + dx, body.bottom - 2),
        ui.Paint()
          ..color = const ui.Color(0x33000000)
          ..strokeWidth = 1,
      );
    }
    if (!broken) {
      c.drawRect(Rect.fromLTWH(cx - 9, top, 18, 4), _fill(color));
      c.drawRect(Rect.fromLTWH(cx - 9, top, 18, 4), _ink..strokeWidth = 1);
    } else {
      final p = ui.Path()
        ..moveTo(cx - 6, top + 3)
        ..lineTo(cx - 2, top)
        ..lineTo(cx + 1, top + 4)
        ..lineTo(cx + 6, top + 1);
      c.drawPath(p, _ink..strokeWidth = 1);
    }
  }

  static const _bookColors = [
    0xFFC0504D,
    0xFF4F81BD,
    0xFF9BBB59,
    0xFFF2B84B,
    0xFF8064A2,
    0xFF4BACC6,
  ];

  static void _shelf(ui.Canvas c, Rect r, Random rnd, {bool gears = false}) {
    final box = r.deflate(2);
    c.drawRect(box, _fill(gears ? 0xFF7D7A8C : 0xFF8D6E63));
    c.drawRect(box, _ink..strokeWidth = 1.2);
    if (gears) {
      // 歯車と時計の文字盤
      final center = box.center;
      c.drawCircle(center, 9, _fill(0xFFE0DCE6));
      c.drawCircle(center, 9, _ink..strokeWidth = 1);
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6;
        c.drawCircle(
          center + Offset(cos(a) * 7, sin(a) * 7),
          0.8,
          _fill(0xFF2E2A33),
        );
      }
      final hand = rnd.nextDouble() * 2 * pi;
      c.drawLine(
        center,
        center + Offset(cos(hand) * 6, sin(hand) * 6),
        _ink..strokeWidth = 1.2,
      );
      return;
    }
    for (final y in [box.top + 3, box.top + 16]) {
      var x = box.left + 2;
      while (x < box.right - 3) {
        final bw = 2.5 + rnd.nextDouble() * 2;
        c.drawRect(
          Rect.fromLTWH(x, y, bw, 10),
          _fill(_bookColors[rnd.nextInt(_bookColors.length)]),
        );
        x += bw + 0.6;
      }
    }
  }

  static void _house(ui.Canvas c, Rect r, Random rnd) {
    const roofs = [0xFFB5523B, 0xFF4F81BD, 0xFF6D8B3E, 0xFF8064A2];
    final wall = Rect.fromLTWH(
      r.left + 2,
      r.top + 12,
      r.width - 4,
      r.height - 13,
    );
    c.drawRect(wall, _fill(0xFFF5E6C8));
    c.drawRect(wall, _ink..strokeWidth = 1.1);
    final roof = ui.Path()
      ..moveTo(r.left, r.top + 13)
      ..lineTo(r.center.dx, r.top + 2)
      ..lineTo(r.right, r.top + 13)
      ..close();
    c.drawPath(roof, _fill(roofs[rnd.nextInt(roofs.length)]));
    c.drawPath(roof, _ink..strokeWidth = 1.1);
    c.drawRect(Rect.fromLTWH(r.left + 7, r.top + 16, 6, 5), _fill(0xFF9AD1D4));
  }

  static void _crate(ui.Canvas c, Rect r, Random rnd) {
    final box = r.deflate(4);
    if (rnd.nextBool()) {
      c.drawRect(box, _fill(0xFFC8A165));
      c.drawRect(box, _ink..strokeWidth = 1.1);
      c.drawLine(box.topLeft, box.bottomRight, _ink..strokeWidth = 1);
      c.drawLine(box.topRight, box.bottomLeft, _ink..strokeWidth = 1);
    } else {
      // 歯車
      final center = box.center;
      final teeth = ui.Paint()..color = const ui.Color(0xFF9E9E9E);
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        c.drawCircle(center + Offset(cos(a) * 9, sin(a) * 9), 3, teeth);
      }
      c.drawCircle(center, 9, teeth);
      c.drawCircle(center, 9, _ink..strokeWidth = 1);
      c.drawCircle(center, 3, _fill(0xFF616161));
    }
  }

  static void _cloud(ui.Canvas c, Rect r) {
    final cx = r.center.dx, cy = r.center.dy;
    final p = ui.Path()
      ..addOval(Rect.fromCircle(center: Offset(cx - 6, cy + 2), radius: 7))
      ..addOval(Rect.fromCircle(center: Offset(cx + 5, cy + 1), radius: 8))
      ..addOval(Rect.fromCircle(center: Offset(cx, cy - 5), radius: 7));
    c.drawPath(p, _fill(0xFFFFFFFF));
    c.drawPath(p, _ink..strokeWidth = 1);
  }

  /// 水・溶岩・雲の切れ目
  static void water(ui.Canvas c, Rect r, Terrain t) {
    final color = switch (t) {
      Terrain.lava => 0xFFE4572E,
      Terrain.cave => 0xFF4F6D7A,
      Terrain.crystal => 0xFF6A7FB5,
      Terrain.beach || Terrain.harbor => 0xFF5FA8CC,
      Terrain.snow => 0xFFB9DDF0,
      Terrain.sky => 0xFFB3D4F5,
      Terrain.desert => 0xFF7EC8C0,
      _ => 0xFF9EC6E0,
    };
    c.drawRect(r, _fill(color));
    final wave = ui.Paint()
      ..color = t == Terrain.lava
          ? const ui.Color(0xCCFFD166)
          : const ui.Color(0xAAFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2;
    if (t == Terrain.snow) {
      // 氷：ひびの線
      c.drawLine(
        Offset(r.left + 6, r.top + 8),
        Offset(r.left + 16, r.top + 20),
        wave,
      );
      c.drawLine(
        Offset(r.left + 16, r.top + 20),
        Offset(r.left + 26, r.top + 14),
        wave,
      );
      return;
    }
    for (final y in [r.top + 10, r.top + 22]) {
      final p = ui.Path()..moveTo(r.left + 4, y);
      p.quadraticBezierTo(r.left + 10, y - 4, r.left + 16, y);
      p.quadraticBezierTo(r.left + 22, y + 4, r.left + 28, y);
      c.drawPath(p, wave);
    }
  }

  /// 橋（木の板。雲の上は虹色の板）
  static void bridge(ui.Canvas c, Rect r, Terrain t) {
    water(c, r, t);
    final plank = _fill(t == Terrain.sky ? 0xFFFFF3C4 : 0xFFC8A165);
    final deck = Rect.fromLTWH(r.left, r.top + 3, r.width, r.height - 6);
    c.drawRect(deck, plank);
    final line = ui.Paint()
      ..color = const ui.Color(0x668D6E63)
      ..strokeWidth = 1;
    for (var x = r.left + 6; x < r.right; x += 6) {
      c.drawLine(Offset(x, deck.top), Offset(x, deck.bottom), line);
    }
    c.drawLine(deck.topLeft, deck.topRight, _ink..strokeWidth = 1);
    c.drawLine(deck.bottomLeft, deck.bottomRight, _ink..strokeWidth = 1);
  }

  /// ボスの間のじゅうたん
  static void carpet(ui.Canvas c, Rect r) {
    c.drawRect(r.deflate(2), _fill(0xFFB23A48));
    c.drawRect(
      r.deflate(4),
      ui.Paint()
        ..color = const ui.Color(0xFFF2B84B)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// 目印の飾り（地形ごと）
  static void decoration(ui.Canvas c, Rect r, Terrain t, {bool boss = false}) {
    final cx = r.center.dx, cy = r.center.dy;
    _shadow(c, r, 16);
    if (boss) {
      _brazier(c, r);
      return;
    }
    switch (t) {
      case Terrain.meadow || Terrain.hill:
        // 道しるべの石
        final stone = ui.RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 5, r.top + 6, 10, r.height - 10),
          const ui.Radius.circular(4),
        );
        c.drawRRect(stone, _fill(0xFFB0A898));
        c.drawRRect(stone, _ink..strokeWidth = 1.1);
        c.drawLine(Offset(cx - 2, cy - 4), Offset(cx + 2, cy - 4), _ink);
        c.drawLine(Offset(cx - 2, cy), Offset(cx + 2, cy), _ink);
      case Terrain.flower:
        // 花の鉢
        c.drawRect(Rect.fromLTWH(cx - 6, cy + 2, 12, 9), _fill(0xFFB5763B));
        for (var i = 0; i < 5; i++) {
          c.drawCircle(
            Offset(cx - 6 + i * 3.0, cy - 2 - (i.isEven ? 3 : 0)),
            3,
            _fill(i.isEven ? 0xFFF06292 : 0xFFFFD54F),
          );
        }
      case Terrain.forest:
        // 切り株ときのこ
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 5), width: 16, height: 8),
          _fill(0xFFB08968),
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 5), width: 16, height: 8),
          _ink..strokeWidth = 1,
        );
        c.drawArc(
          Rect.fromCenter(
            center: Offset(cx + 6, cy - 2),
            width: 10,
            height: 10,
          ),
          pi,
          pi,
          true,
          _fill(0xFFE53935),
        );
      case Terrain.river || Terrain.beach || Terrain.harbor:
        // いかり
        final p = ui.Paint()
          ..color = const ui.Color(0xFF546E7A)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3;
        c.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 8), p);
        c.drawArc(
          Rect.fromCenter(center: Offset(cx, cy + 2), width: 18, height: 14),
          0,
          pi,
          false,
          p,
        );
        c.drawCircle(Offset(cx, cy - 11), 2.5, p..strokeWidth = 2);
      case Terrain.cave || Terrain.crystal:
        // 大きな結晶
        final p = ui.Path()
          ..moveTo(cx, r.top + 2)
          ..lineTo(cx + 7, cy)
          ..lineTo(cx, r.bottom - 5)
          ..lineTo(cx - 7, cy)
          ..close();
        c.drawPath(p, _fill(t == Terrain.crystal ? 0xFFB39DDB : 0xFF80DEEA));
        c.drawPath(p, _ink..strokeWidth = 1.1);
      case Terrain.ruins:
        // 石像
        c.drawRect(
          Rect.fromLTWH(cx - 7, r.bottom - 9, 14, 5),
          _fill(0xFFBDB5A6),
        );
        c.drawCircle(Offset(cx, cy - 6), 5, _fill(0xFFBDB5A6));
        c.drawRect(Rect.fromLTWH(cx - 4, cy - 1, 8, 10), _fill(0xFFBDB5A6));
        c.drawCircle(Offset(cx, cy - 6), 5, _ink..strokeWidth = 1);
      case Terrain.shrine:
        // 灯籠
        c.drawRect(Rect.fromLTWH(cx - 2, cy, 4, 10), _fill(0xFF9E9E9E));
        c.drawRect(Rect.fromLTWH(cx - 6, cy - 7, 12, 7), _fill(0xFFFFE082));
        c.drawRect(Rect.fromLTWH(cx - 6, cy - 7, 12, 7), _ink..strokeWidth = 1);
        final roof = ui.Path()
          ..moveTo(cx - 9, cy - 7)
          ..lineTo(cx, cy - 13)
          ..lineTo(cx + 9, cy - 7)
          ..close();
        c.drawPath(roof, _fill(0xFF616161));
      case Terrain.town:
        // 街灯
        c.drawRect(Rect.fromLTWH(cx - 1.5, cy - 6, 3, 17), _fill(0xFF455A64));
        c.drawCircle(Offset(cx, cy - 9), 4.5, _fill(0xFFFFE082));
        c.drawCircle(Offset(cx, cy - 9), 4.5, _ink..strokeWidth = 1);
      case Terrain.workshop:
        // 金床
        final p = ui.Path()
          ..moveTo(cx - 10, cy - 4)
          ..lineTo(cx + 10, cy - 4)
          ..lineTo(cx + 5, cy + 2)
          ..lineTo(cx + 5, cy + 9)
          ..lineTo(cx - 5, cy + 9)
          ..lineTo(cx - 5, cy + 2)
          ..close();
        c.drawPath(p, _fill(0xFF616161));
        c.drawPath(p, _ink..strokeWidth = 1);
      case Terrain.library:
        // 書見台と開いた本
        c.drawRect(Rect.fromLTWH(cx - 1.5, cy, 3, 11), _fill(0xFF8D6E63));
        final book = ui.Path()
          ..moveTo(cx - 10, cy - 6)
          ..lineTo(cx, cy - 3)
          ..lineTo(cx + 10, cy - 6)
          ..lineTo(cx + 10, cy + 1)
          ..lineTo(cx, cy + 3)
          ..lineTo(cx - 10, cy + 1)
          ..close();
        c.drawPath(book, _fill(0xFFFFFDF8));
        c.drawPath(book, _ink..strokeWidth = 1);
      case Terrain.tower:
        // 大時計
        c.drawRect(Rect.fromLTWH(cx - 6, cy - 2, 12, 13), _fill(0xFF8D6E63));
        c.drawCircle(Offset(cx, cy - 6), 7, _fill(0xFFFFFDF8));
        c.drawCircle(Offset(cx, cy - 6), 7, _ink..strokeWidth = 1.1);
        c.drawLine(Offset(cx, cy - 6), Offset(cx, cy - 11), _ink);
        c.drawLine(Offset(cx, cy - 6), Offset(cx + 4, cy - 6), _ink);
      case Terrain.sky:
        // 風見の羽
        c.drawLine(
          Offset(cx, cy - 10),
          Offset(cx, cy + 10),
          _ink..strokeWidth = 1.6,
        );
        final p = ui.Path()
          ..moveTo(cx, cy - 10)
          ..lineTo(cx + 10, cy - 6)
          ..lineTo(cx, cy - 2)
          ..close();
        c.drawPath(p, _fill(0xFF90CAF9));
      case Terrain.snow:
        // 雪だるま
        c.drawCircle(Offset(cx, cy + 5), 7, _fill(0xFFFFFFFF));
        c.drawCircle(Offset(cx, cy - 5), 5, _fill(0xFFFFFFFF));
        c.drawCircle(Offset(cx, cy + 5), 7, _ink..strokeWidth = 1);
        c.drawCircle(Offset(cx, cy - 5), 5, _ink..strokeWidth = 1);
        c.drawLine(
          Offset(cx, cy - 5),
          Offset(cx + 5, cy - 4),
          ui.Paint()
            ..color = const ui.Color(0xFFFF7043)
            ..strokeWidth = 1.6,
        );
      case Terrain.desert:
        // 骨と石
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 4), width: 18, height: 9),
          _fill(0xFFD7C4A0),
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 4), width: 18, height: 9),
          _ink..strokeWidth = 1,
        );
      case Terrain.lava:
        _brazier(c, r);
      case Terrain.castle:
        // 旗
        c.drawLine(
          Offset(cx - 5, cy - 12),
          Offset(cx - 5, cy + 11),
          _ink..strokeWidth = 1.6,
        );
        final flag = ui.Path()
          ..moveTo(cx - 5, cy - 12)
          ..lineTo(cx + 9, cy - 8)
          ..lineTo(cx - 5, cy - 3)
          ..close();
        c.drawPath(flag, _fill(0xFF6A4C93));
    }
  }

  static void _brazier(ui.Canvas c, Rect r) {
    final cx = r.center.dx, cy = r.center.dy;
    c.drawRect(Rect.fromLTWH(cx - 2, cy, 4, 11), _fill(0xFF5D4037));
    c.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 10),
      0,
      pi,
      true,
      _fill(0xFF424242),
    );
    final flame = ui.Path()
      ..moveTo(cx - 6, cy)
      ..quadraticBezierTo(cx - 5, cy - 9, cx, cy - 13)
      ..quadraticBezierTo(cx + 5, cy - 8, cx + 6, cy)
      ..close();
    c.drawPath(flame, _fill(0xFFFF8A3D));
    final inner = ui.Path()
      ..moveTo(cx - 3, cy)
      ..quadraticBezierTo(cx - 2, cy - 5, cx, cy - 8)
      ..quadraticBezierTo(cx + 2, cy - 5, cx + 3, cy)
      ..close();
    c.drawPath(inner, _fill(0xFFFFE082));
  }

  /// ワープ石
  static void warpStone(
    ui.Canvas c,
    Rect r, {
    required bool active,
    double glow = 0,
  }) {
    final cx = r.center.dx, cy = r.center.dy;
    _shadow(c, r, 18);
    if (active) {
      c.drawCircle(
        Offset(cx, cy - 2),
        13 + glow * 2,
        ui.Paint()
          ..color = ui.Color.fromRGBO(120, 200, 255, 0.18 + glow * 0.15),
      );
    }
    final p = ui.Path()
      ..moveTo(cx, r.top + 2)
      ..lineTo(cx + 8, cy - 2)
      ..lineTo(cx + 5, r.bottom - 5)
      ..lineTo(cx - 5, r.bottom - 5)
      ..lineTo(cx - 8, cy - 2)
      ..close();
    c.drawPath(p, _fill(active ? 0xFF64B5F6 : 0xFF90A4AE));
    c.drawPath(p, _ink..strokeWidth = 1.2);
    // 羽のしるし
    c.drawLine(
      Offset(cx - 3, cy + 2),
      Offset(cx + 3, cy - 4),
      _ink..strokeWidth = 1,
    );
  }

  /// 知識の扉（閉じている）
  static void door(ui.Canvas c, Rect r) {
    final box = r.deflate(2);
    c.drawRect(box, _fill(0xFF6D4C41));
    c.drawRect(box, _ink..strokeWidth = 1.3);
    c.drawLine(
      Offset(box.center.dx, box.top),
      Offset(box.center.dx, box.bottom),
      _ink..strokeWidth = 1,
    );
    // 錠前と本のしるし
    c.drawCircle(box.center, 5, _fill(0xFFF2B84B));
    c.drawCircle(box.center, 5, _ink..strokeWidth = 1);
    c.drawRect(
      Rect.fromCenter(
        center: box.center.translate(0, 1.5),
        width: 2,
        height: 4,
      ),
      _fill(0xFF2E2A33),
    );
  }

  /// 開いた知識の扉（床の上に、開いた戸）
  static void doorOpen(ui.Canvas c, Rect r) {
    c.drawRect(
      Rect.fromLTWH(r.left + 1, r.top + 2, 5, r.height - 4),
      _fill(0xFF6D4C41),
    );
    c.drawRect(
      Rect.fromLTWH(r.right - 6, r.top + 2, 5, r.height - 4),
      _fill(0xFF6D4C41),
    );
  }

  /// 隠し通路の目印（障害物にうすいひび）
  static void crack(ui.Canvas c, Rect r) {
    final p = ui.Paint()
      ..color = const ui.Color(0x66000000)
      ..strokeWidth = 0.8
      ..style = ui.PaintingStyle.stroke;
    final path = ui.Path()
      ..moveTo(r.left + 9, r.top + 8)
      ..lineTo(r.left + 13, r.top + 13)
      ..lineTo(r.left + 11, r.top + 18)
      ..lineTo(r.left + 15, r.top + 22);
    c.drawPath(path, p);
  }
}
