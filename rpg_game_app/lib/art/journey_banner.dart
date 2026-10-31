import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import 'battle_backdrop.dart';
import 'hero_painter.dart';
import 'slow_clock.dart';

/// 主人公が左から右へ旅をする横長の絵（時間で景色が変わる）
class JourneyBanner extends StatefulWidget {
  const JourneyBanner({super.key, this.height = 96});

  final double height;

  @override
  State<JourneyBanner> createState() => _JourneyBannerState();
}

class _JourneyBannerState extends State<JourneyBanner>
    with SingleTickerProviderStateMixin {
  late final _t = SlowClock(period: const Duration(seconds: 40), fps: 15);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t.follow(context);
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// 朝〜昼は草原、夕方は砂漠の夕やけ、夜は星空の城
  static Terrain _terrainNow() {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 16) return Terrain.meadow;
    if (h >= 16 && h < 19) return Terrain.desert;
    return Terrain.castle;
  }

  @override
  Widget build(BuildContext context) {
    final terrain = _terrainNow();
    return SizedBox(
      height: widget.height,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final v = _t.value;
            return LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BattleBackdropPainter(
                          terrain,
                          v * 40,
                          showStage: false,
                        ),
                      ),
                    ),
                    // 主人公が、左から右へ旅をする
                    Positioned(
                      left:
                          -widget.height * 0.42 +
                          (w + widget.height * 0.84) * v,
                      bottom: widget.height * 0.125,
                      child: SizedBox.square(
                        dimension: widget.height * 0.42,
                        child: CustomPaint(painter: _BannerHero(v * 40)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BannerHero extends CustomPainter {
  _BannerHero(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) => paintHero(
    canvas,
    size.shortestSide,
    facing: Facing.right,
    walk: t * 1.2,
    moving: true,
  );
  @override
  bool shouldRepaint(_BannerHero old) => true;
}
