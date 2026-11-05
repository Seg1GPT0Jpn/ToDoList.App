import 'dart:math';
import 'dart:ui';

import 'package:rpg_game/rpg_game.dart';

import 'hero_painter.dart';

/// 航路で主人公が乗る乗り物
enum Vehicle {
  /// 定期テストの海の前半
  ship,

  /// 定期テストの海の終盤（深海）
  submarine,

  /// 模擬試験の空の前半
  airship,

  /// 模擬試験の空の終盤（宇宙）
  rocket;

  /// その地形で乗る乗り物（歩く地形なら null）
  static Vehicle? of(Terrain t) => switch (t) {
    Terrain.ocean => ship,
    Terrain.abyss => submarine,
    Terrain.cloudSea => airship,
    Terrain.space => rocket,
    _ => null,
  };
}

const _ink = Color(0xFF2E2A33);
const _skin = Color(0xFFF7E1C4);
const _hair = Color(0xFF3E2723);

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(double w, [Color c = _ink]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// 乗り物に乗った主人公を [size] の正方形に描く。[t] は経過秒（ゆれ・プロペラ用）
void paintVehicle(
  Canvas canvas,
  double size,
  Vehicle vehicle, {
  Facing facing = Facing.right,
  double t = 0,
  bool moving = false,
}) {
  final s = size;
  canvas.save();
  // 左を向いているときは左右反転（上下を向いているときは、そのまま）
  if (facing == Facing.left) {
    canvas.translate(s, 0);
    canvas.scale(-1, 1);
  }
  final bob = sin(t * (moving ? 7 : 2.5)) * s * 0.025;
  canvas.translate(0, bob);
  switch (vehicle) {
    case Vehicle.ship:
      _ship(canvas, s, facing, t, moving);
    case Vehicle.submarine:
      _submarine(canvas, s, t);
    case Vehicle.airship:
      _airship(canvas, s, facing, t);
    case Vehicle.rocket:
      _rocket(canvas, s, t, moving);
  }
  canvas.restore();
}

/// 丸窓からのぞく主人公の顔
void _face(Canvas c, Offset center, double r) {
  c.drawCircle(center, r, _fill(_skin));
  final hair = Path()
    ..addArc(Rect.fromCircle(center: center, radius: r), pi * 0.95, pi * 1.1)
    ..close();
  c.drawPath(hair, _fill(_hair));
  c.drawCircle(center + Offset(r * 0.4, r * 0.15), r * 0.14, _fill(_ink));
  c.drawCircle(center, r, _stroke(r * 0.18));
}

/// 小さな帆船。主人公は甲板に立っている
void _ship(Canvas c, double s, Facing facing, double t, bool moving) {
  // 波
  final wave = _stroke(s * 0.03, const Color(0xCCFFFFFF));
  for (final y in [s * 0.9, s * 0.97]) {
    final p = Path()..moveTo(s * 0.02, y);
    for (var x = 0.02; x < 0.98; x += 0.16) {
      p.quadraticBezierTo(
        s * (x + 0.04),
        y - s * 0.035 * sin(t * 3 + x * 9).abs(),
        s * (x + 0.08),
        y,
      );
    }
    c.drawPath(p, wave);
  }
  // マストと帆（主人公の後ろ）
  c.drawLine(
    Offset(s * 0.22, s * 0.75),
    Offset(s * 0.22, s * 0.05),
    _stroke(s * 0.04, const Color(0xFF6D4C41)),
  );
  final billow = moving ? 0.04 : 0.0;
  final sail = Path()
    ..moveTo(s * 0.24, s * 0.08)
    ..quadraticBezierTo(s * (0.46 + billow), s * 0.3, s * 0.24, s * 0.55)
    ..close();
  c.drawPath(sail, _fill(const Color(0xFFFFFDF8)));
  c.drawPath(sail, _stroke(s * 0.025));
  // 旗
  c.drawPath(
    Path()
      ..moveTo(s * 0.22, s * 0.05)
      ..lineTo(s * 0.34, s * 0.08)
      ..lineTo(s * 0.22, s * 0.11)
      ..close(),
    _fill(const Color(0xFFC0504D)),
  );
  // 主人公（甲板の上）
  c.save();
  c.translate(s * 0.3, -s * 0.02);
  paintHero(c, s * 0.62, facing: facing == Facing.left ? Facing.right : facing);
  c.restore();
  // 船体
  final hull = Path()
    ..moveTo(s * 0.04, s * 0.58)
    ..lineTo(s * 0.96, s * 0.58)
    ..lineTo(s * 0.82, s * 0.86)
    ..lineTo(s * 0.16, s * 0.86)
    ..close();
  c.drawPath(hull, _fill(const Color(0xFFA1673F)));
  c.drawLine(
    Offset(s * 0.08, s * 0.66),
    Offset(s * 0.92, s * 0.66),
    _stroke(s * 0.02, const Color(0xFF6D4C41)),
  );
  c.drawPath(hull, _stroke(s * 0.035));
}

/// 黄色い潜水艦。潜望鏡と丸窓、うしろでプロペラがまわる
void _submarine(Canvas c, double s, double t) {
  // 泡
  for (var i = 0; i < 3; i++) {
    final p = (t * 0.8 + i / 3) % 1;
    c.drawCircle(
      Offset(s * (0.08 - 0.02 * i), s * (0.6 - p * 0.5)),
      s * (0.025 + 0.01 * i) * (1 - p * 0.5),
      _stroke(s * 0.015, const Color(0xCCB2EBF2)),
    );
  }
  // 潜望鏡
  c.drawLine(
    Offset(s * 0.58, s * 0.3),
    Offset(s * 0.58, s * 0.12),
    _stroke(s * 0.04),
  );
  c.drawLine(
    Offset(s * 0.58, s * 0.12),
    Offset(s * 0.68, s * 0.12),
    _stroke(s * 0.04),
  );
  // 司令塔
  final tower = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.4, s * 0.24, s * 0.26, s * 0.2),
    Radius.circular(s * 0.05),
  );
  c.drawRRect(tower, _fill(const Color(0xFFFFC107)));
  c.drawRRect(tower, _stroke(s * 0.03));
  // 船体
  final body = Rect.fromLTWH(s * 0.12, s * 0.38, s * 0.8, s * 0.38);
  c.drawOval(body, _fill(const Color(0xFFFFD54F)));
  c.drawOval(body, _stroke(s * 0.035));
  // 丸窓（主人公の顔）と、ほかの窓
  final window = Offset(s * 0.66, s * 0.56);
  c.drawCircle(window, s * 0.12, _fill(const Color(0xFF80DEEA)));
  _face(c, window, s * 0.09);
  c.drawCircle(window, s * 0.12, _stroke(s * 0.03));
  for (final x in [0.3, 0.44]) {
    c.drawCircle(
      Offset(s * x, s * 0.57),
      s * 0.045,
      _fill(const Color(0xFF80DEEA)),
    );
    c.drawCircle(Offset(s * x, s * 0.57), s * 0.045, _stroke(s * 0.02));
  }
  // プロペラ
  final spin = sin(t * 20);
  c.drawLine(
    Offset(s * 0.1, s * 0.57 - s * 0.1 * spin),
    Offset(s * 0.1, s * 0.57 + s * 0.1 * spin),
    _stroke(s * 0.05, const Color(0xFF8D6E63)),
  );
  // ライト
  c.drawPath(
    Path()
      ..moveTo(s * 0.92, s * 0.55)
      ..lineTo(s * 1.0, s * 0.45)
      ..lineTo(s * 1.0, s * 0.68)
      ..close(),
    _fill(const Color(0x66FFF59D)),
  );
}

/// 飛行船。気球の下のゴンドラに主人公が乗っている
void _airship(Canvas c, double s, Facing facing, double t) {
  // 気球
  final balloon = Rect.fromLTWH(s * 0.06, s * 0.02, s * 0.84, s * 0.42);
  c.drawOval(balloon, _fill(const Color(0xFFEF5350)));
  for (final x in [0.3, 0.48, 0.66]) {
    c.drawLine(
      Offset(s * x, s * 0.04),
      Offset(s * x, s * 0.42),
      _stroke(s * 0.015, const Color(0x88FFFFFF)),
    );
  }
  c.drawOval(balloon, _stroke(s * 0.035));
  // しっぽの羽
  c.drawPath(
    Path()
      ..moveTo(s * 0.1, s * 0.2)
      ..lineTo(s * 0.0, s * 0.08)
      ..lineTo(s * 0.0, s * 0.34)
      ..close(),
    _fill(const Color(0xFFFFB74D)),
  );
  // ロープ
  for (final (x0, x1) in [(0.3, 0.32), (0.66, 0.68)]) {
    c.drawLine(
      Offset(s * x0, s * 0.42),
      Offset(s * x1, s * 0.66),
      _stroke(s * 0.015),
    );
  }
  // 主人公（ゴンドラから上半身が見える）
  c.save();
  c.translate(s * 0.22, s * 0.38);
  paintHero(c, s * 0.52, facing: facing == Facing.left ? Facing.right : facing);
  c.restore();
  // ゴンドラ
  final gondola = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.2, s * 0.66, s * 0.6, s * 0.22),
    Radius.circular(s * 0.05),
  );
  c.drawRRect(gondola, _fill(const Color(0xFF8D6E63)));
  c.drawRRect(gondola, _stroke(s * 0.03));
  // プロペラ
  final spin = sin(t * 18);
  c.drawLine(
    Offset(s * 0.86, s * 0.77 - s * 0.09 * spin),
    Offset(s * 0.86, s * 0.77 + s * 0.09 * spin),
    _stroke(s * 0.04, const Color(0xFF6D4C41)),
  );
}

/// ロケット。窓から主人公がのぞき、うしろから炎が出る
void _rocket(Canvas c, double s, double t, bool moving) {
  // 炎
  final flicker = 0.8 + 0.2 * sin(t * 25);
  final len = s * (moving ? 0.32 : 0.2) * flicker;
  c.drawPath(
    Path()
      ..moveTo(s * 0.16, s * 0.42)
      ..lineTo(s * 0.16 - len, s * 0.53)
      ..lineTo(s * 0.16, s * 0.64)
      ..close(),
    _fill(const Color(0xFFFF8A3D)),
  );
  c.drawPath(
    Path()
      ..moveTo(s * 0.16, s * 0.47)
      ..lineTo(s * 0.16 - len * 0.55, s * 0.53)
      ..lineTo(s * 0.16, s * 0.59)
      ..close(),
    _fill(const Color(0xFFFFE082)),
  );
  // 翼
  for (final (y0, y1) in [(0.34, 0.2), (0.72, 0.86)]) {
    c.drawPath(
      Path()
        ..moveTo(s * 0.34, s * y0)
        ..lineTo(s * 0.16, s * y1)
        ..lineTo(s * 0.18, s * 0.53)
        ..close(),
      _fill(const Color(0xFFE53935)),
    );
  }
  // 機体
  final body = Path()
    ..moveTo(s * 0.16, s * 0.38)
    ..lineTo(s * 0.7, s * 0.38)
    ..quadraticBezierTo(s * 0.98, s * 0.46, s * 0.98, s * 0.53)
    ..quadraticBezierTo(s * 0.98, s * 0.6, s * 0.7, s * 0.68)
    ..lineTo(s * 0.16, s * 0.68)
    ..close();
  c.drawPath(body, _fill(const Color(0xFFF5F5F5)));
  c.drawPath(body, _stroke(s * 0.035));
  // 窓（主人公の顔）
  final window = Offset(s * 0.56, s * 0.53);
  c.drawCircle(window, s * 0.11, _fill(const Color(0xFF90CAF9)));
  _face(c, window, s * 0.085);
  c.drawCircle(window, s * 0.11, _stroke(s * 0.03));
  // 先の赤いしるし
  c.drawLine(
    Offset(s * 0.78, s * 0.41),
    Offset(s * 0.78, s * 0.65),
    _stroke(s * 0.03, const Color(0xFFE53935)),
  );
}
