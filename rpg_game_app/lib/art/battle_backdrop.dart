import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

/// バトルの舞台の地形（エリアの名前・地方・学習モードから決める）
Terrain battleTerrainOf(StageDef stage) {
  for (final t in Terrain.values) {
    if (t.label == stage.region) return t;
  }
  if (stage.region == StudyRealm.sea.title) return Terrain.ocean;
  if (stage.region == StudyRealm.sky.title) return Terrain.cloudSea;
  if (stage.region == '共通テスト遺跡') return Terrain.ruins;
  if (stage.id.startsWith('review_tower')) return Terrain.tower;
  if (stage.id == Story.centerStageId) return Terrain.castle;
  final t = Terrain.of(stage);
  if (stage.isBoss && t == Terrain.meadow && !stage.name.contains('草原')) {
    return Terrain.castle;
  }
  return t;
}

/// 地形ごとのバトルの背景の色（空の上・空の下・地面・遠景・舞う粒）
class _Palette {
  const _Palette(this.skyTop, this.skyBottom, this.ground, this.far, this.mote);
  final int skyTop;
  final int skyBottom;
  final int ground;
  final int far;
  final int mote;
}

_Palette _paletteOf(Terrain t) => switch (t) {
  Terrain.meadow => const _Palette(
    0xFF8EC5F2,
    0xFFE3F2FD,
    0xFFA5D48A,
    0xFF7FB069,
    0xFFFFFFFF,
  ),
  Terrain.flower => const _Palette(
    0xFFF8BBD0,
    0xFFFFF1F4,
    0xFFB5DC8F,
    0xFFE59BB5,
    0xFFFFFFFF,
  ),
  Terrain.forest => const _Palette(
    0xFF5E8C61,
    0xFFB7D3A8,
    0xFF5B7F46,
    0xFF3D6B3A,
    0xFFFFF59D,
  ),
  Terrain.hill => const _Palette(
    0xFF90CAF9,
    0xFFFFF3E0,
    0xFFC5B07F,
    0xFF9C8660,
    0xFFFFFFFF,
  ),
  Terrain.river => const _Palette(
    0xFF81D4FA,
    0xFFE0F7FA,
    0xFF9CCC9C,
    0xFF6FA8C8,
    0xFFFFFFFF,
  ),
  Terrain.beach => const _Palette(
    0xFF64B5F6,
    0xFFFFF8E1,
    0xFFF3DFA2,
    0xFF4F9BD1,
    0xFFFFFFFF,
  ),
  Terrain.harbor => const _Palette(
    0xFF78909C,
    0xFFFFE0B2,
    0xFFBCAAA4,
    0xFF546E7A,
    0xFFFFFFFF,
  ),
  Terrain.cave => const _Palette(
    0xFF2B2622,
    0xFF5D544B,
    0xFF6D6259,
    0xFF3E3731,
    0xFF9AD1D4,
  ),
  Terrain.crystal => const _Palette(
    0xFF1F2340,
    0xFF4A4E7A,
    0xFF5C6290,
    0xFF34385E,
    0xFFB39DDB,
  ),
  Terrain.ruins => const _Palette(
    0xFFD7B98E,
    0xFFF5E6CC,
    0xFFC9B79A,
    0xFFA38E6F,
    0xFFFFF8E1,
  ),
  Terrain.shrine => const _Palette(
    0xFFFFCCBC,
    0xFFFFF3E0,
    0xFFD7CCC8,
    0xFFC0504D,
    0xFFFFFFFF,
  ),
  Terrain.town => const _Palette(
    0xFFFFCC80,
    0xFFFFF3E0,
    0xFFC8B8A0,
    0xFFA1887F,
    0xFFFFFFFF,
  ),
  Terrain.workshop => const _Palette(
    0xFF6D6D6D,
    0xFFBDBDBD,
    0xFF8D8D8D,
    0xFF555555,
    0xFFFFB74D,
  ),
  Terrain.library => const _Palette(
    0xFF6D4C41,
    0xFFD7CCC8,
    0xFF8D6E63,
    0xFF4E342E,
    0xFFFFE082,
  ),
  Terrain.tower => const _Palette(
    0xFF5C6BC0,
    0xFFD1C4E9,
    0xFF9E9AAE,
    0xFF4A4568,
    0xFFFFFFFF,
  ),
  Terrain.sky => const _Palette(
    0xFF64B5F6,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFBBDEFB,
    0xFFFFFFFF,
  ),
  Terrain.snow => const _Palette(
    0xFFB0BEC5,
    0xFFECEFF1,
    0xFFFAFAFA,
    0xFF90A4AE,
    0xFFFFFFFF,
  ),
  Terrain.desert => const _Palette(
    0xFFFFB74D,
    0xFFFFF3E0,
    0xFFE8C07D,
    0xFFC99A58,
    0xFFFFFFFF,
  ),
  Terrain.lava => const _Palette(
    0xFF3E1F1F,
    0xFFB23A2A,
    0xFF4A3530,
    0xFF2B1D1D,
    0xFFFF8A3D,
  ),
  Terrain.castle => const _Palette(
    0xFF3A2F5A,
    0xFF8E7CC3,
    0xFF7A7090,
    0xFF2E2745,
    0xFFF2B84B,
  ),
  Terrain.ocean => const _Palette(
    0xFF4FC3F7,
    0xFFE1F5FE,
    0xFF4A9FD0,
    0xFF2F80B5,
    0xFFFFFFFF,
  ),
  Terrain.abyss => const _Palette(
    0xFF050C1A,
    0xFF1D3557,
    0xFF0D1A2B,
    0xFF12263F,
    0xFF80DEEA,
  ),
  Terrain.cloudSea => const _Palette(
    0xFF7986CB,
    0xFFE8EAF6,
    0xFFFFFFFF,
    0xFFC5CAE9,
    0xFFFFFFFF,
  ),
  Terrain.space => const _Palette(
    0xFF0B0816,
    0xFF2A2156,
    0xFF3A3450,
    0xFF1A1633,
    0xFFFFF59D,
  ),
};

/// 舞う粒の種類
enum _Mote { none, sparkle, firefly, bubble, snow, ember, star, dust, petal }

_Mote _moteOf(Terrain t) => switch (t) {
  Terrain.forest => _Mote.firefly,
  Terrain.flower => _Mote.petal,
  Terrain.cave || Terrain.crystal => _Mote.sparkle,
  Terrain.ocean || Terrain.abyss || Terrain.river => _Mote.bubble,
  Terrain.snow => _Mote.snow,
  Terrain.lava => _Mote.ember,
  Terrain.space || Terrain.castle => _Mote.star,
  Terrain.desert ||
  Terrain.ruins ||
  Terrain.library ||
  Terrain.workshop => _Mote.dust,
  Terrain.meadow ||
  Terrain.hill ||
  Terrain.sky ||
  Terrain.cloudSea => _Mote.petal,
  _ => _Mote.none,
};

/// バトルの背景。ノートに貼った「絵」のように、角を丸めた窓の中に
/// 地形ごとの空・遠景・地面と、舞う粒（ほたる・泡・雪・火の粉・星など）を描く。
class BattleBackdropPainter extends CustomPainter {
  BattleBackdropPainter(this.terrain, this.t, {this.boss = false});

  final Terrain terrain;

  /// 経過秒
  final double t;

  /// ボス戦（空が少し暗く、赤い光がさす）
  final bool boss;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(2),
      const Radius.circular(18),
    );
    final p = _paletteOf(terrain);
    canvas.save();
    canvas.clipRRect(r);
    final rect = r.outerRect;
    // 空
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(p.skyTop), Color(p.skyBottom)],
        ).createShader(rect),
    );
    final w = rect.width, h = rect.height;
    _sky(canvas, rect, p);
    _far(canvas, rect, p);
    // 地面
    final horizon = rect.top + h * 0.68;
    final ground = Path()
      ..moveTo(rect.left, horizon)
      ..quadraticBezierTo(
        rect.left + w * 0.5,
        horizon - h * 0.05,
        rect.right,
        horizon,
      )
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(
      ground,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(p.ground),
                Color.lerp(Color(p.ground), Colors.black, 0.25)!,
              ],
            ).createShader(
              Rect.fromLTRB(rect.left, horizon, rect.right, rect.bottom),
            ),
    );
    _waves(canvas, rect, horizon);
    // 敵の立つ台（光の輪）
    final stage = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + h * 0.84),
      width: w * 0.55,
      height: h * 0.1,
    );
    canvas.drawOval(
      stage,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawOval(
      stage.deflate(4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _motes(canvas, rect, p);
    if (boss) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.1,
            colors: [
              Colors.transparent,
              const Color(0xFF8B0000)
                  .withValues(alpha: 0.28 + 0.06 * sin(t * 2)),
            ],
          ).createShader(rect),
      );
    }
    canvas.restore();
    // 絵のふち（ノートに貼った写真のように）
    canvas.drawRRect(
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRRect(
      r.inflate(2),
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // マスキングテープ
    _tape(canvas, Offset(rect.left + 18, rect.top + 4), -0.5);
    _tape(canvas, Offset(rect.right - 18, rect.top + 4), 0.5);
  }

  void _tape(Canvas canvas, Offset at, double angle) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 44, height: 14),
      Paint()..color = const Color(0xAAF2D680),
    );
    canvas.restore();
  }

  /// 太陽・月・雲・オーロラなど
  void _sky(Canvas canvas, Rect rect, _Palette p) {
    final w = rect.width, h = rect.height;
    final dark = Color(p.skyTop).computeLuminance() < 0.15;
    final sun = Offset(rect.left + w * 0.8, rect.top + h * 0.2);
    if (terrain.isVoyage && terrain.isDeep && terrain == Terrain.abyss) {
      // 深海：上から差しこむ光のすじ
      for (var i = 0; i < 4; i++) {
        final x = rect.left + w * (0.15 + i * 0.22) + sin(t * 0.5 + i) * 10;
        final path = Path()
          ..moveTo(x, rect.top)
          ..lineTo(x + 30, rect.top)
          ..lineTo(x + 70, rect.top + h * 0.7)
          ..lineTo(x + 20, rect.top + h * 0.7)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = Colors.white.withValues(alpha: 0.05),
        );
      }
      return;
    }
    // 洞窟・地底湖・火山は天井があるので、空は見えない
    if (terrain == Terrain.cave ||
        terrain == Terrain.crystal ||
        terrain == Terrain.lava) {
      return;
    }
    if (dark) {
      // 月と星
      canvas.drawCircle(sun, 16, Paint()..color = const Color(0xFFFFF8E1));
      canvas.drawCircle(
        sun + const Offset(6, -4),
        14,
        Paint()..color = Color(p.skyTop),
      );
      final rnd = Random(3);
      for (var i = 0; i < 30; i++) {
        final s = Offset(
          rect.left + rnd.nextDouble() * w,
          rect.top + rnd.nextDouble() * h * 0.55,
        );
        final a = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 3 + i));
        canvas.drawCircle(
          s,
          rnd.nextDouble() * 1.4 + 0.4,
          Paint()..color = Colors.white.withValues(alpha: a),
        );
      }
      if (terrain == Terrain.space) {
        // 輪のある惑星
        final planet = Offset(rect.left + w * 0.2, rect.top + h * 0.28);
        canvas.drawCircle(planet, 18, Paint()..color = const Color(0xFFFFB74D));
        canvas.drawOval(
          Rect.fromCenter(center: planet, width: 60, height: 14),
          Paint()
            ..color = const Color(0xFFFFE0B2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      return;
    }
    // 太陽
    canvas.drawCircle(
      sun,
      34,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x66FFF59D), const Color(0x00FFF59D)],
        ).createShader(Rect.fromCircle(center: sun, radius: 34)),
    );
    canvas.drawCircle(sun, 13, Paint()..color = const Color(0xFFFFF59D));
    // 流れる雲
    final rnd = Random(9);
    for (var i = 0; i < 4; i++) {
      final y = rect.top + h * (0.08 + rnd.nextDouble() * 0.35);
      final speed = 6 + rnd.nextDouble() * 10;
      final x =
          rect.left + ((rnd.nextDouble() * w + t * speed) % (w + 120)) - 60;
      final c = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 60, height: 18),
        c,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 14, y - 7), width: 34, height: 18),
        c,
      );
    }
  }

  /// 遠景（山・木・柱・建物・波など）のシルエット
  void _far(Canvas canvas, Rect rect, _Palette p) {
    final w = rect.width, h = rect.height;
    final base = rect.top + h * 0.68;
    final paint = Paint()..color = Color(p.far).withValues(alpha: 0.85);
    final rnd = Random(terrain.index + 5);
    switch (terrain) {
      case Terrain.forest || Terrain.snow:
        for (var i = 0; i < 9; i++) {
          final x = rect.left + w * (i / 8) + rnd.nextDouble() * 12;
          final th = h * (0.18 + rnd.nextDouble() * 0.12);
          canvas.drawPath(
            Path()
              ..moveTo(x - 16, base)
              ..lineTo(x, base - th)
              ..lineTo(x + 16, base)
              ..close(),
            paint,
          );
          if (terrain == Terrain.snow) {
            canvas.drawPath(
              Path()
                ..moveTo(x - 5, base - th * 0.7)
                ..lineTo(x, base - th)
                ..lineTo(x + 5, base - th * 0.7)
                ..close(),
              Paint()..color = Colors.white,
            );
          }
        }
      case Terrain.ruins || Terrain.shrine || Terrain.castle || Terrain.tower:
        for (var i = 0; i < 6; i++) {
          final x = rect.left + w * (0.05 + i * 0.18);
          final ph = h * (0.2 + rnd.nextDouble() * 0.2);
          canvas.drawRect(Rect.fromLTWH(x, base - ph, 14, ph), paint);
          canvas.drawRect(Rect.fromLTWH(x - 4, base - ph - 6, 22, 6), paint);
        }
        if (terrain == Terrain.castle) {
          final cx = rect.center.dx;
          canvas.drawRect(
            Rect.fromLTWH(cx - 40, base - h * 0.4, 80, h * 0.4),
            paint,
          );
          for (var i = 0; i < 5; i++) {
            canvas.drawRect(
              Rect.fromLTWH(cx - 40 + i * 18, base - h * 0.45, 10, 8),
              paint,
            );
          }
        }
      case Terrain.town ||
          Terrain.harbor ||
          Terrain.workshop ||
          Terrain.library:
        for (var i = 0; i < 7; i++) {
          final x = rect.left + w * (i / 7);
          final bh = h * (0.12 + rnd.nextDouble() * 0.15);
          canvas.drawRect(Rect.fromLTWH(x, base - bh, w / 7 - 4, bh), paint);
          canvas.drawPath(
            Path()
              ..moveTo(x - 3, base - bh)
              ..lineTo(x + (w / 7 - 4) / 2, base - bh - 14)
              ..lineTo(x + w / 7 - 1, base - bh)
              ..close(),
            paint,
          );
        }
      case Terrain.cave || Terrain.crystal || Terrain.lava:
        // つらら・岩の天井
        final top = Path()..moveTo(rect.left, rect.top);
        for (var i = 0; i <= 10; i++) {
          top.lineTo(
            rect.left + w * i / 10,
            rect.top + h * (0.08 + rnd.nextDouble() * 0.14),
          );
        }
        top
          ..lineTo(rect.right, rect.top)
          ..close();
        canvas.drawPath(top, paint);
        if (terrain == Terrain.lava) {
          // 火山
          canvas.drawPath(
            Path()
              ..moveTo(rect.left + w * 0.15, base)
              ..lineTo(rect.left + w * 0.38, base - h * 0.35)
              ..lineTo(rect.left + w * 0.46, base - h * 0.35)
              ..lineTo(rect.left + w * 0.7, base)
              ..close(),
            paint,
          );
          canvas.drawCircle(
            Offset(rect.left + w * 0.42, base - h * 0.37),
            10 + 3 * sin(t * 3),
            Paint()..color = const Color(0xAAFF8A3D),
          );
        }
      case Terrain.ocean || Terrain.beach || Terrain.river || Terrain.abyss:
        // 遠くの島や海藻
        if (terrain == Terrain.abyss) {
          for (var i = 0; i < 7; i++) {
            final x = rect.left + w * (i / 6);
            final kh = h * (0.15 + rnd.nextDouble() * 0.2);
            final path = Path()..moveTo(x, base);
            path.quadraticBezierTo(
              x + 10 * sin(t + i),
              base - kh / 2,
              x,
              base - kh,
            );
            canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFF26A69A).withValues(alpha: 0.6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4,
            );
          }
        } else {
          canvas.drawOval(
            Rect.fromLTWH(rect.left + w * 0.1, base - 14, w * 0.25, 20),
            paint,
          );
        }
      case Terrain.cloudSea || Terrain.sky:
        for (var i = 0; i < 6; i++) {
          final x = rect.left + w * (i / 5);
          canvas.drawCircle(
            Offset(x, base - 4),
            30 + rnd.nextDouble() * 16,
            Paint()..color = Colors.white.withValues(alpha: 0.9),
          );
        }
      case Terrain.space:
        break;
      default:
        // なだらかな山なみ
        final hills = Path()..moveTo(rect.left, base);
        for (var i = 0; i <= 6; i++) {
          hills.quadraticBezierTo(
            rect.left + w * (i / 6 - 1 / 12),
            base - h * (0.12 + rnd.nextDouble() * 0.16),
            rect.left + w * i / 6,
            base,
          );
        }
        canvas.drawPath(hills, paint);
    }
  }

  /// 海の地形は、地面の代わりに波を重ねる
  void _waves(Canvas canvas, Rect rect, double horizon) {
    if (terrain != Terrain.ocean && terrain != Terrain.beach) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var row = 0; row < 3; row++) {
      final y = horizon + 14 + row * 16.0;
      final path = Path()..moveTo(rect.left, y);
      for (var x = rect.left; x < rect.right; x += 24) {
        path.quadraticBezierTo(
          x + 6,
          y - 5 * sin(t * 2 + x / 30 + row),
          x + 12,
          y,
        );
        path.quadraticBezierTo(x + 18, y + 3, x + 24, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// 舞う粒
  void _motes(Canvas canvas, Rect rect, _Palette p) {
    final kind = _moteOf(terrain);
    if (kind == _Mote.none) return;
    final rnd = Random(21);
    final w = rect.width, h = rect.height;
    for (var i = 0; i < 26; i++) {
      final bx = rnd.nextDouble(), by = rnd.nextDouble();
      final speed = 0.02 + rnd.nextDouble() * 0.05;
      final phase = rnd.nextDouble() * 6;
      double x = rect.left + bx * w, y = rect.top + by * h;
      final color = Color(p.mote);
      switch (kind) {
        case _Mote.bubble:
          y = rect.bottom - ((by + t * speed * 3) % 1) * h;
          x += sin(t * 2 + phase) * 6;
          canvas.drawCircle(
            Offset(x, y),
            2 + rnd.nextDouble() * 3,
            Paint()
              ..color = color.withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        case _Mote.snow || _Mote.petal:
          y = rect.top + ((by + t * speed * 2) % 1) * h;
          x += sin(t + phase) * 12;
          canvas.drawCircle(
            Offset(x, y),
            kind == _Mote.snow ? 2 : 1.6,
            Paint()
              ..color = (kind == _Mote.petal ? const Color(0xFFF8BBD0) : color)
                  .withValues(alpha: 0.85),
          );
        case _Mote.ember:
          y = rect.bottom - ((by + t * speed * 4) % 1) * h;
          x += sin(t * 3 + phase) * 5;
          canvas.drawCircle(
            Offset(x, y),
            1.8,
            Paint()..color = color.withValues(alpha: 0.9),
          );
        case _Mote.firefly || _Mote.sparkle || _Mote.star || _Mote.dust:
          x += sin(t * 0.7 + phase) * 14;
          y += cos(t * 0.5 + phase) * 10;
          final a = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * 3 + phase * 2));
          canvas.drawCircle(
            Offset(x, y),
            kind == _Mote.dust ? 1.2 : 2,
            Paint()
              ..color = color.withValues(
                alpha: a * (kind == _Mote.dust ? 0.5 : 0.9),
              ),
          );
        case _Mote.none:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(BattleBackdropPainter old) => true;
}
