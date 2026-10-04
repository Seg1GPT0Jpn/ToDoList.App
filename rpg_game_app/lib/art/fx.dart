import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hero_painter.dart';

/// 画面の演出（奥行き・光・動き）をまとめたもの。
///
/// - 国ごとの色調補正（言の葉の国はセピア、実験庭園は鮮やか…）
/// - 被写界深度：背景をほんのりぼかし、手前のボケた光の粒で奥行きを出す
/// - 2D ライティング：ボスの魔力のオーラ、当たった瞬間の照り返し
/// - ブルーム：光る文字・火花
/// - 正解の文字が光るプレートになって飛んでいく
/// - 必殺技・浄化のカットイン
abstract final class Fx {
  /// 国ごとの色調補正（背景にかける）
  static ColorFilter? gradeFor(String worldId) => switch (worldId) {
    // 言の葉の国：落ち着いたセピア
    'japanese' => ColorFilter.matrix(_mix(_sepia, 0.32)),
    // 数理の迷宮国：真鍮の金色
    'math' => ColorFilter.matrix(_tint(1.06, 1.0, 0.86)),
    // 異界の港町：海の青
    'english' => ColorFilter.matrix(_tint(0.9, 1.0, 1.1)),
    // 万物の実験庭園：鮮やか
    'science' => ColorFilter.matrix(_saturate(1.35)),
    // 時空の回廊：色あせた琥珀
    'social' => ColorFilter.matrix(
      _mul(_saturate(0.78), _tint(1.08, 0.98, 0.84)),
    ),
    _ => null,
  };

  /// 国ごとの光の色（オーラ・光の粒）
  static Color lightFor(String worldId) => switch (worldId) {
    'japanese' => const Color(0xFFFFE6B8),
    'math' => const Color(0xFFFFD36B),
    'english' => const Color(0xFFA8E1FF),
    'science' => const Color(0xFFB8FFD9),
    'social' => const Color(0xFFFFCF8A),
    _ => const Color(0xFFFFF4C2),
  };

  /// 文字が光って見える影（ブルーム）
  static List<Shadow> bloom(Color color, {double strength = 1}) => [
    Shadow(color: Colors.white, offset: const Offset(2, 2)),
    Shadow(color: color.withValues(alpha: 0.9), blurRadius: 10 * strength),
    Shadow(color: color.withValues(alpha: 0.6), blurRadius: 22 * strength),
  ];

  static const _sepia = <double>[
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const _identity = <double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static List<double> _mix(List<double> m, double a) => [
    for (var i = 0; i < 20; i++) _identity[i] * (1 - a) + m[i] * a,
  ];

  static List<double> _tint(double r, double g, double b) => [
    r, 0, 0, 0, 0, //
    0, g, 0, 0, 0,
    0, 0, b, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static List<double> _saturate(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final i = 1 - s;
    return [
      lr * i + s, lg * i, lb * i, 0, 0, //
      lr * i, lg * i + s, lb * i, 0, 0,
      lr * i, lg * i, lb * i + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// 色の行列のかけ算（a のあとに b）
  static List<double> _mul(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 5; c++) {
        var v = c == 4 ? b[r * 5 + 4] : 0.0;
        for (var k = 0; k < 4; k++) {
          v += b[r * 5 + k] * a[k * 5 + c];
        }
        out[r * 5 + c] = v;
      }
    }
    return out;
  }
}

/// 舞台の背景に、色調補正と被写界深度（ほんのりボケ）をかける
class GradedBackdrop extends StatelessWidget {
  const GradedBackdrop({
    super.key,
    required this.worldId,
    required this.child,
    this.blur = 1.3,
  });

  final String worldId;
  final Widget child;

  /// ぼかしの強さ（0 でぼかさない）
  final double blur;

  @override
  Widget build(BuildContext context) {
    var w = child;
    if (blur > 0) {
      w = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: w,
      );
    }
    final grade = Fx.gradeFor(worldId);
    if (grade != null) w = ColorFiltered(colorFilter: grade, child: w);
    return w;
  }
}

/// 光の柱（ゴッドレイ）。左上から斜めに差しこみ、ゆっくり揺れる
class LightRaysPainter extends CustomPainter {
  LightRaysPainter(this.t, this.color, {this.strength = 1});
  final double t;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.15, -size.height * 0.15);
    for (var i = 0; i < 4; i++) {
      final sway = sin(t * 0.4 + i * 1.7) * 0.05;
      final a = 0.55 + i * 0.16 + sway;
      final w = 0.05 + (i % 2) * 0.04;
      final len = size.longestSide * 1.6;
      final p = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(origin.dx + cos(a - w) * len, origin.dy + sin(a - w) * len)
        ..lineTo(origin.dx + cos(a + w) * len, origin.dy + sin(a + w) * len)
        ..close();
      final pulse = 0.5 + 0.5 * sin(t * 0.7 + i * 2.1);
      canvas.drawPath(
        p,
        Paint()
          ..shader = ui.Gradient.linear(
            origin,
            origin + Offset(cos(a), sin(a)) * len * 0.8,
            [
              color.withValues(alpha: 0.22 * strength * (0.6 + 0.4 * pulse)),
              color.withValues(alpha: 0),
            ],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(LightRaysPainter old) => old.t != t;
}

/// 手前のボケた光の粒（フォアグラウンド）。カメラの前を横切るように流れる
class ForegroundBokehPainter extends CustomPainter {
  ForegroundBokehPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    for (var i = 0; i < 14; i++) {
      final big = i < 4;
      final speed = (big ? 10 : 18) + rnd.nextDouble() * 14;
      final x =
          (rnd.nextDouble() * size.width + t * speed) % (size.width + 80) - 40;
      final baseY = big
          ? size.height * (0.78 + rnd.nextDouble() * 0.25)
          : rnd.nextDouble() * size.height;
      final y = baseY + sin(t * 0.9 + i) * 8;
      final r = big ? 18 + rnd.nextDouble() * 16 : 2 + rnd.nextDouble() * 3.5;
      final twinkle = 0.5 + 0.5 * sin(t * 2 + i * 1.3);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = color.withValues(alpha: big ? 0.16 : 0.35 + 0.4 * twinkle)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, big ? 10 : 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(ForegroundBokehPainter old) => old.t != t;
}

/// 敵の後ろの魔力のオーラ（2D ライティング）。当たった瞬間は白く照り返す
class AuraPainter extends CustomPainter {
  AuraPainter(this.t, this.color, {this.strength = 1, this.hitLight = 0});
  final double t;
  final Color color;
  final double strength;

  /// 当たった瞬間の照り返し（0〜1）
  final double hitLight;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset(0, size.height * 0.05));
    final pulse = 0.85 + 0.15 * sin(t * 2.2);
    final r = size.shortestSide * 0.5 * pulse;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          r,
          [
            color.withValues(alpha: 0.42 * strength),
            color.withValues(alpha: 0.14 * strength),
            color.withValues(alpha: 0),
          ],
          [0, 0.55, 1],
        ),
    );
    // ボスのまわりをまわる魔力の粒
    if (strength > 1) {
      for (var i = 0; i < 10; i++) {
        final a = t * 0.9 + i * pi / 5;
        final rr = r * (0.75 + 0.12 * sin(t * 1.7 + i));
        canvas.drawCircle(
          c + Offset(cos(a) * rr, sin(a) * rr * 0.45),
          2.5 + (i % 3),
          Paint()
            ..color = color.withValues(alpha: 0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
    if (hitLight > 0) {
      final hr = size.shortestSide * 0.6;
      canvas.drawCircle(
        c,
        hr,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(c, hr, [
            const Color(0xFFFFF4D6).withValues(alpha: 0.75 * hitLight),
            const Color(0xFFFFE08A).withValues(alpha: 0),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(AuraPainter old) => old.t != t || old.hitLight != hitLight;
}

/// 正解の文字が、光るプレートになって敵に飛んでいく
class FlyingPlate extends StatelessWidget {
  const FlyingPlate({
    super.key,
    required this.text,
    required this.v,
    required this.color,
  });

  final String text;

  /// 0（下から出る）〜 1（敵に刺さる）
  final double v;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (v <= 0 || v >= 1) return const SizedBox.shrink();
    final e = Curves.easeInCubic.transform(v);
    final label = text.length > 14 ? '${text.substring(0, 13)}…' : text;
    return Align(
      alignment: Alignment(0, 1.25 - e * 1.35),
      child: Opacity(
        opacity: v > 0.85 ? (1 - v) / 0.15 : 1,
        child: Transform(
          alignment: Alignment.center,
          // 奥へ倒れながら飛ぶ（立体のプレート）
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0025)
            ..rotateX(-0.9 * e)
            ..rotateZ(sin(v * pi) * 0.12)
            ..scaleByDouble(1 - e * 0.35, 1 - e * 0.35, 1, 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, color.withValues(alpha: 0.9)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 18),
                const BoxShadow(
                  color: Color(0x55000000),
                  offset: Offset(0, 6),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B2118),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 必殺技・浄化のカットイン（斜めの帯・集中線・主人公とグリモワール）
class CutIn extends StatelessWidget {
  const CutIn({
    super.key,
    required this.v,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  /// 0〜1（帯が入る→止まる→抜ける）
  final double v;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (v <= 0 || v >= 1) return const SizedBox.shrink();
    // 入り（0〜0.2）・止め（〜0.8）・抜け（〜1）
    final inT = Curves.easeOutCubic.transform((v / 0.2).clamp(0, 1));
    final outT = Curves.easeInCubic.transform(((v - 0.8) / 0.2).clamp(0, 1));
    final slide = (1 - inT) - outT;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            children: [
              // 画面を少し暗くする
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: 0.35 * inT * (1 - outT),
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(slide * w * 1.2, 0),
                  child: Transform.rotate(
                    angle: -0.12,
                    // 帯は画面より広い（はみ出しを許す）
                    child: OverflowBox(
                      minWidth: w * 1.4,
                      maxWidth: w * 1.4,
                      child: SizedBox(
                        width: w * 1.4,
                        height: 150,
                        child: CustomPaint(
                          painter: _CutInPainter(v, color),
                          child: Row(
                            children: [
                              SizedBox(width: w * 0.2 + 20),
                              SizedBox.square(
                                dimension: 120,
                                child: CustomPaint(painter: _CutInHero(v)),
                              ),
                              const SizedBox(width: 8),
                              // 画面の幅に入るよう、長い題は縮める
                              SizedBox(
                                width: max(80, w - 175),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      Text(
                                        title,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          shadows: Fx.bloom(
                                            color,
                                            strength: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CutInPainter extends CustomPainter {
  _CutInPainter(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topLeft,
          r.bottomLeft,
          [
            Color.lerp(color, Colors.black, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.5)!,
          ],
          [0, 0.5, 1],
        ),
    );
    // 上下のふち
    final edge = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 4), edge);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 4, size.width, 4), edge);
    // 流れる集中線
    final rnd = Random(3);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var i = 0; i < 24; i++) {
      final y = rnd.nextDouble() * size.height;
      final len = 40 + rnd.nextDouble() * 120;
      final x =
          (rnd.nextDouble() * size.width - v * size.width * 3) % size.width;
      canvas.drawLine(Offset(x, y), Offset(x + len, y), line);
    }
  }

  @override
  bool shouldRepaint(_CutInPainter old) => old.v != v;
}

/// カットインの主人公：開いたグリモワールが光る
class _CutInHero extends CustomPainter {
  _CutInHero(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // 背中の光
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.5),
      s * 0.5,
      Paint()
        ..shader = ui.Gradient.radial(Offset(s * 0.5, s * 0.5), s * 0.5, [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0),
        ]),
    );
    canvas.save();
    canvas.translate(s * 0.08, s * 0.05);
    paintHero(canvas, s * 0.84);
    canvas.restore();
    // 開いたグリモワール（白いページに光る文字）
    final book = Rect.fromCenter(
      center: Offset(s * 0.72, s * 0.72),
      width: s * 0.42,
      height: s * 0.26,
    );
    final cover = Paint()..color = const Color(0xFF6B3E1F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(book.inflate(3), const Radius.circular(3)),
      cover,
    );
    final page = Paint()..color = const Color(0xFFFFFBEF);
    canvas.drawRect(
      Rect.fromLTRB(book.left, book.top, book.center.dx - 1, book.bottom),
      page,
    );
    canvas.drawRect(
      Rect.fromLTRB(book.center.dx + 1, book.top, book.right, book.bottom),
      page,
    );
    final glow = 0.6 + 0.4 * sin(v * pi * 6);
    final ink = Paint()
      ..color = const Color(0xFFFFC94A).withValues(alpha: glow)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (var i = 0; i < 3; i++) {
      final y = book.top + book.height * (0.3 + i * 0.22);
      canvas.drawLine(
        Offset(book.left + 4, y),
        Offset(book.center.dx - 5, y),
        ink,
      );
      canvas.drawLine(
        Offset(book.center.dx + 5, y),
        Offset(book.right - 4, y),
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(_CutInHero old) => old.v != v;
}

/// フィールドの空気（光の粒・ふちの暗がり・国の色）
class AtmospherePainter extends CustomPainter {
  AtmospherePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(11);
    for (var i = 0; i < 18; i++) {
      final speed = 6 + rnd.nextDouble() * 10;
      final x =
          (rnd.nextDouble() * size.width + sin(t * 0.3 + i) * 20) % size.width;
      final y = (rnd.nextDouble() * size.height - t * speed) % size.height;
      final tw = 0.5 + 0.5 * sin(t * 1.6 + i * 0.9);
      canvas.drawCircle(
        Offset(x, y < 0 ? y + size.height : y),
        1.5 + rnd.nextDouble() * 2.5,
        Paint()
          ..color = color.withValues(alpha: 0.25 + 0.45 * tw)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    // ふちの暗がり（ビネット）
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          r.center,
          size.longestSide * 0.75,
          [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
          [0.6, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(AtmospherePainter old) => old.t != t;
}

/// フィールドの上にかける空気（ただよう光の粒・ふちの暗がり）。さわっても下に届く
class FieldAtmosphere extends StatefulWidget {
  const FieldAtmosphere({super.key, required this.worldId});

  final String worldId;

  @override
  State<FieldAtmosphere> createState() => _FieldAtmosphereState();
}

class _FieldAtmosphereState extends State<FieldAtmosphere>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _t.stop();
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: AtmospherePainter(
            _t.value * 120,
            Fx.lightFor(widget.worldId),
          ),
        ),
      ),
    ),
  );
}
