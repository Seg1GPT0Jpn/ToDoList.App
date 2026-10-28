import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/cached_paint.dart';
import '../art/hero_painter.dart';
import '../art/slow_clock.dart';

/// ノートの世界の地図：英語ワールドを中心に、教科の国が道と橋でつながる。
///
/// 国をタップすると、その国へ旅立つ（まだ行けない国は、行き方を教える）。
class WorldAtlas extends StatefulWidget {
  const WorldAtlas({super.key, required this.progress, required this.onOpen});

  final RpgProgress progress;
  final void Function(WorldDef world) onOpen;

  /// 地図の上の国の位置（横・縦とも 0〜1）
  static const spots = <String, Offset>{
    'english': Offset(0.5, 0.53),
    'science': Offset(0.5, 0.17),
    'japanese': Offset(0.17, 0.4),
    'math': Offset(0.83, 0.4),
    'social': Offset(0.5, 0.86),
    'music': Offset(0.17, 0.77),
    'information': Offset(0.85, 0.79),
  };

  /// 地図の縦横比（縦 / 横）
  static const aspect = 1.12;

  @override
  State<WorldAtlas> createState() => _WorldAtlasState();
}

class _WorldAtlasState extends State<WorldAtlas>
    with SingleTickerProviderStateMixin {
  late final _clock = SlowClock(period: const Duration(seconds: 6), fps: 15);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock.follow(context);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  int _cleared(WorldDef w) => w.stages
      .where((s) => widget.progress.clearedStageIds.contains(s.id))
      .length;

  /// 主人公がいる国：いちばん進んでいる、遊べる国（なければ英語）
  String _here(Map<String, bool> playable) {
    var best = RpgCatalog.englishWorldId;
    var bestN = -1;
    for (final w in RpgCatalog.worlds) {
      if (!(playable[w.id] ?? false)) continue;
      final n = _cleared(w);
      if (n > bestN) {
        best = w.id;
        bestN = n;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final worlds = [
      for (final w in RpgCatalog.worlds)
        if (WorldAtlas.spots.containsKey(w.id)) w,
    ];
    final playable = {
      for (final w in worlds)
        w.id:
            services.unlock.availabilityOf(widget.progress, w) ==
            WorldAvailability.playable,
    };
    final here = _here(playable);
    return LayoutBuilder(
      builder: (context, box) {
        final width = min(box.maxWidth, 520.0);
        final height = width * WorldAtlas.aspect;
        Offset at(String id) {
          final s = WorldAtlas.spots[id]!;
          return Offset(s.dx * width, s.dy * height);
        }

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CachedPaint(
                      cacheKey: playable.toString(),
                      painter: _AtlasPainter(
                        playable: playable,
                        colors: {
                          for (final w in worlds) w.id: atlasColor(w.id),
                        },
                      ),
                    ),
                  ),
                ),
                // 主人公（いまいる国で、ぴょこぴょこ）
                AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) {
                    final o = at(here);
                    final hop = sin(_clock.value * pi * 2 * 3).abs() * 4;
                    return Positioned(
                      left: o.dx - 34,
                      top: o.dy - 40 - hop,
                      child: SizedBox.square(
                        dimension: 26,
                        child: CustomPaint(painter: _Hero(_clock.value)),
                      ),
                    );
                  },
                ),
                for (final w in worlds)
                  Positioned(
                    left: at(w.id).dx - 62,
                    top: at(w.id).dy + 14,
                    width: 124,
                    child: _Label(
                      world: w,
                      playable: playable[w.id]!,
                      cleared: _cleared(w),
                      onTap: () => widget.onOpen(w),
                    ),
                  ),
                // 国そのものもタップできる
                for (final w in worlds)
                  Positioned(
                    left: at(w.id).dx - 46,
                    top: at(w.id).dy - 40,
                    width: 92,
                    height: 54,
                    child: GestureDetector(
                      key: ValueKey('atlas-${w.id}'),
                      behavior: HitTestBehavior.translucent,
                      onTap: () => widget.onOpen(w),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 国の色
Color atlasColor(String id) => switch (id) {
  'japanese' => const Color(0xFFC0504D),
  'math' => const Color(0xFF3F7CAC),
  'english' => const Color(0xFF5B9A5B),
  'science' => const Color(0xFF8E6BBF),
  'social' => const Color(0xFFD9822B),
  'information' => const Color(0xFF4A8C8C),
  'music' => const Color(0xFFD45D8C),
  _ => TsuzuriColors.accent,
};

class _Label extends StatelessWidget {
  const _Label({
    required this.world,
    required this.playable,
    required this.cleared,
    required this.onTap,
  });

  final WorldDef world;
  final bool playable;
  final int cleared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = playable ? atlasColor(world.id) : Colors.grey.shade600;
    return Center(
      child: Material(
        color: TsuzuriColors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        elevation: 1.5,
        child: InkWell(
          key: ValueKey('atlas-label-${world.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 1.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  world.name,
                  style: serif(
                    12.5,
                    color: playable ? TsuzuriColors.ink : color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  playable
                      ? '★ $cleared / ${world.stages.length}'
                      : '🔒 ${world.subject}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: playable ? const Color(0xFFB8860B) : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends CustomPainter {
  _Hero(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) => paintHero(
    canvas,
    size.shortestSide,
    facing: Facing.down,
    walk: t * 6,
    moving: false,
  );

  @override
  bool shouldRepaint(_Hero old) => old.t != t;
}

/// 地図の絵：海・大陸・国の土地と目印・道・橋・方位
class _AtlasPainter extends CustomPainter {
  _AtlasPainter({required this.playable, required this.colors});

  final Map<String, bool> playable;
  final Map<String, Color> colors;

  static final _ink = Paint()
    ..color = const Color(0xFF3E3A4A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    Offset at(String id) {
      final s = WorldAtlas.spots[id]!;
      return Offset(s.dx * w, s.dy * h);
    }

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    c.save();
    c.clipRRect(frame);

    // 海（定期テストの海）と、上のほうの雲（模擬試験の空）
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFDCEBF7), Color(0xFFB9D8EC)],
        ).createShader(Offset.zero & size),
    );
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final rnd = Random(4);
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * w, y = rnd.nextDouble() * h;
      final p = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 6, y - 3, x + 12, y)
        ..quadraticBezierTo(x + 18, y + 3, x + 24, y);
      c.drawPath(p, wave);
    }

    // 大陸：国のまわりの丸をつないだ形（情報の国は橋でつながる小島）
    final continent = <(Offset, double)>[
      (at('english'), w * 0.25),
      (at('science'), w * 0.2),
      (at('japanese'), w * 0.18),
      (at('math'), w * 0.18),
      (at('social'), w * 0.2),
      (at('music'), w * 0.15),
      (Offset(w * 0.33, h * 0.3), w * 0.16),
      (Offset(w * 0.67, h * 0.3), w * 0.16),
      (Offset(w * 0.33, h * 0.68), w * 0.17),
      (Offset(w * 0.62, h * 0.7), w * 0.14),
    ];
    final island = <(Offset, double)>[(at('information'), w * 0.12)];
    for (final group in [continent, island]) {
      for (final (o, r) in group) {
        c.drawCircle(
          o,
          r + 6,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }
    for (final group in [continent, island]) {
      for (final (o, r) in group) {
        c.drawCircle(o, r, Paint()..color = const Color(0xFFEAF0D2));
      }
    }

    // 国の土地の色（水彩のしみ）。まだ行けない国は、霧でかすむ
    for (final e in colors.entries) {
      final o = at(e.key);
      c.drawCircle(
        o,
        w * 0.13,
        Paint()
          ..color = e.value.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // 道（英語ワールドから各国へ。情報の国へは橋）
    for (final id in WorldAtlas.spots.keys) {
      if (id == 'english') continue;
      final a = at('english'), b = at(id);
      final mid =
          Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2) +
          Offset(-(b.dy - a.dy), b.dx - a.dx) * 0.12;
      final road = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      c.drawPath(
        road,
        Paint()
          ..color = const Color(0xFFC9AE7E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      // 点線（歩いた道のしるし）
      final metrics = road.computeMetrics();
      for (final m in metrics) {
        for (var d = 0.0; d < m.length; d += 9) {
          final seg = m.extractPath(d, d + 4);
          c.drawPath(
            seg,
            Paint()
              ..color = const Color(0xFFF6EBD0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4,
          );
        }
      }
    }
    // 情報の国への橋
    final bridgeAt = Offset(w * 0.73, h * 0.72);
    c.save();
    c.translate(bridgeAt.dx, bridgeAt.dy);
    c.rotate(0.6);
    c.drawRect(
      const Rect.fromLTWH(-16, -6, 32, 12),
      Paint()..color = const Color(0xFFB5763B),
    );
    for (var i = -14.0; i < 16; i += 5) {
      c.drawLine(Offset(i, -6), Offset(i, 6), _ink..strokeWidth = 0.8);
    }
    _ink.strokeWidth = 1.4;
    c.restore();

    // 国の目印
    for (final id in WorldAtlas.spots.keys) {
      final o = at(id);
      final open = playable[id] ?? false;
      c.saveLayer(
        Rect.fromCircle(center: o, radius: w * 0.14),
        Paint()
          ..colorFilter = open
              ? null
              : const ColorFilter.matrix([
                  0.33, 0.33, 0.33, 0, 20, //
                  0.33, 0.33, 0.33, 0, 20,
                  0.33, 0.33, 0.33, 0, 20,
                  0, 0, 0, 0.75, 0,
                ]),
      );
      _icon(c, id, o, w * 0.07);
      c.restore();
      if (!open) {
        // 霧
        for (var i = 0; i < 4; i++) {
          c.drawCircle(
            o + Offset(cos(i * 1.7) * w * 0.05, sin(i * 1.7) * w * 0.025 - 6),
            w * 0.045,
            Paint()..color = Colors.white.withValues(alpha: 0.55),
          );
        }
      }
    }

    // 雲（模擬試験の空）
    for (final (o, r) in [
      (Offset(w * 0.12, h * 0.08), w * 0.06),
      (Offset(w * 0.86, h * 0.1), w * 0.07),
    ]) {
      for (final d in [-1.0, 0.0, 1.0]) {
        c.drawCircle(
          o + Offset(d * r * 0.9, d.abs() * r * 0.25),
          r * (d == 0 ? 1 : 0.75),
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
      }
    }

    // 方位
    final compass = Offset(w * 0.9, h * 0.94);
    final needle = Path()
      ..moveTo(compass.dx, compass.dy - 14)
      ..lineTo(compass.dx + 5, compass.dy)
      ..lineTo(compass.dx, compass.dy + 14)
      ..lineTo(compass.dx - 5, compass.dy)
      ..close();
    c.drawPath(needle, Paint()..color = const Color(0xFFF6EBD0));
    c.drawPath(needle, _ink);
    c.drawPath(
      Path()
        ..moveTo(compass.dx, compass.dy - 14)
        ..lineTo(compass.dx + 5, compass.dy)
        ..lineTo(compass.dx - 5, compass.dy)
        ..close(),
      Paint()..color = const Color(0xFFD64545),
    );
    c.restore();
    // ノートに貼った地図のふち
    c.drawRRect(
      frame,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// 国ごとの小さな絵（大きさ [s] くらい）
  void _icon(Canvas c, String id, Offset o, double s) {
    Paint fill(int argb) => Paint()..color = Color(argb);
    void shape(Path p, int argb) {
      c.drawPath(p, fill(argb));
      c.drawPath(p, _ink);
    }

    switch (id) {
      case 'english':
        // 村：家と風車
        shape(
          Path()..addRect(
            Rect.fromCenter(
              center: o + Offset(-s * 0.4, s * 0.1),
              width: s * 0.8,
              height: s * 0.6,
            ),
          ),
          0xFFF6E7C8,
        );
        shape(
          Path()
            ..moveTo(o.dx - s * 0.9, o.dy - s * 0.2)
            ..lineTo(o.dx - s * 0.4, o.dy - s * 0.65)
            ..lineTo(o.dx + s * 0.1, o.dy - s * 0.2)
            ..close(),
          0xFFC0563E,
        );
        shape(
          Path()
            ..moveTo(o.dx + s * 0.35, o.dy + s * 0.4)
            ..lineTo(o.dx + s * 0.45, o.dy - s * 0.35)
            ..lineTo(o.dx + s * 0.75, o.dy - s * 0.35)
            ..lineTo(o.dx + s * 0.85, o.dy + s * 0.4)
            ..close(),
          0xFFF3E3C3,
        );
        final hub = o + Offset(s * 0.6, -s * 0.4);
        for (var i = 0; i < 4; i++) {
          final a = i * pi / 2 + 0.5;
          c.drawLine(
            hub,
            hub + Offset(cos(a), sin(a)) * s * 0.5,
            _ink..strokeWidth = 2.2,
          );
        }
        _ink.strokeWidth = 1.4;
      case 'science':
        // 山と、湯気の出るフラスコ
        shape(
          Path()
            ..moveTo(o.dx - s * 1.2, o.dy + s * 0.4)
            ..lineTo(o.dx - s * 0.4, o.dy - s * 0.7)
            ..lineTo(o.dx + s * 0.2, o.dy + s * 0.1)
            ..lineTo(o.dx + s * 0.6, o.dy - s * 0.4)
            ..lineTo(o.dx + s * 1.2, o.dy + s * 0.4)
            ..close(),
          0xFFB9A8D8,
        );
        shape(
          Path()
            ..moveTo(o.dx - s * 0.55, o.dy - s * 0.45)
            ..lineTo(o.dx - s * 0.4, o.dy - s * 0.7)
            ..lineTo(o.dx - s * 0.25, o.dy - s * 0.45)
            ..close(),
          0xFFFFFFFF,
        );
        shape(
          Path()
            ..moveTo(o.dx + s * 0.05, o.dy + s * 0.5)
            ..lineTo(o.dx + s * 0.2, o.dy + s * 0.05)
            ..lineTo(o.dx + s * 0.2, o.dy - s * 0.15)
            ..lineTo(o.dx + s * 0.4, o.dy - s * 0.15)
            ..lineTo(o.dx + s * 0.4, o.dy + s * 0.05)
            ..lineTo(o.dx + s * 0.55, o.dy + s * 0.5)
            ..close(),
          0xFF9AD1D4,
        );
      case 'japanese':
        // 鳥居と竹
        for (final dx in [-0.35, 0.35]) {
          c.drawRect(
            Rect.fromCenter(
              center: o + Offset(dx * s, s * 0.05),
              width: s * 0.14,
              height: s * 0.9,
            ),
            fill(0xFFD0574F),
          );
        }
        shape(
          Path()..addRect(
            Rect.fromCenter(
              center: o + Offset(0, -s * 0.45),
              width: s * 1.1,
              height: s * 0.16,
            ),
          ),
          0xFFD0574F,
        );
        shape(
          Path()..addRect(
            Rect.fromCenter(
              center: o + Offset(0, -s * 0.22),
              width: s * 0.8,
              height: s * 0.1,
            ),
          ),
          0xFFD0574F,
        );
        for (final dx in [-0.95, -0.8, 0.85]) {
          c.drawLine(
            o + Offset(dx * s, s * 0.5),
            o + Offset(dx * s, -s * 0.6),
            Paint()
              ..color = const Color(0xFF6FAE58)
              ..strokeWidth = 3,
          );
        }
      case 'math':
        // 結晶の形の塔（三角・四角・丸）
        shape(
          Path()
            ..moveTo(o.dx - s * 0.6, o.dy + s * 0.45)
            ..lineTo(o.dx - s * 0.3, o.dy - s * 0.45)
            ..lineTo(o.dx, o.dy + s * 0.45)
            ..close(),
          0xFF7FB3E0,
        );
        shape(
          Path()..addRect(
            Rect.fromCenter(
              center: o + Offset(s * 0.35, s * 0.1),
              width: s * 0.55,
              height: s * 0.7,
            ),
          ),
          0xFFB9D3EC,
        );
        shape(
          Path()..addOval(
            Rect.fromCircle(
              center: o + Offset(s * 0.35, -s * 0.45),
              radius: s * 0.22,
            ),
          ),
          0xFFF2C14E,
        );
      case 'social':
        // ピラミッドと地球儀
        shape(
          Path()
            ..moveTo(o.dx - s * 1.0, o.dy + s * 0.45)
            ..lineTo(o.dx - s * 0.35, o.dy - s * 0.5)
            ..lineTo(o.dx + s * 0.3, o.dy + s * 0.45)
            ..close(),
          0xFFE8C77E,
        );
        shape(
          Path()..addOval(
            Rect.fromCircle(
              center: o + Offset(s * 0.6, -s * 0.05),
              radius: s * 0.35,
            ),
          ),
          0xFF7EB7DA,
        );
        c.drawLine(
          o + Offset(s * 0.6, s * 0.3),
          o + Offset(s * 0.6, s * 0.5),
          _ink,
        );
      case 'information':
        // 電波の塔
        shape(
          Path()
            ..moveTo(o.dx - s * 0.35, o.dy + s * 0.5)
            ..lineTo(o.dx, o.dy - s * 0.6)
            ..lineTo(o.dx + s * 0.35, o.dy + s * 0.5)
            ..close(),
          0xFF9ED0CF,
        );
        for (final r in [0.35, 0.6]) {
          c.drawArc(
            Rect.fromCircle(center: o + Offset(0, -s * 0.6), radius: s * r),
            -2.4,
            1.6,
            false,
            _ink,
          );
          c.drawArc(
            Rect.fromCircle(center: o + Offset(0, -s * 0.6), radius: s * r),
            -0.8,
            -1.6 + 0.8,
            false,
            _ink,
          );
        }
      case 'music':
        // 虹と音符
        for (final (i, col) in [
          0xFFE57373,
          0xFFF2C14E,
          0xFF8CC06B,
          0xFF7EB7DA,
        ].indexed) {
          c.drawArc(
            Rect.fromCircle(
              center: o + Offset(0, s * 0.4),
              radius: s * (0.9 - i * 0.16),
            ),
            pi,
            pi,
            false,
            Paint()
              ..color = Color(col)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.14,
          );
        }
        c.drawCircle(
          o + Offset(-s * 0.05, s * 0.15),
          s * 0.14,
          fill(0xFF3E3A4A),
        );
        c.drawLine(
          o + Offset(s * 0.08, s * 0.15),
          o + Offset(s * 0.08, -s * 0.35),
          _ink..strokeWidth = 2,
        );
        _ink.strokeWidth = 1.4;
    }
  }

  @override
  bool shouldRepaint(_AtlasPainter old) =>
      old.playable.toString() != playable.toString();
}
