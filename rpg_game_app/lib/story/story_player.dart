import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/fx.dart';
import '../art/hero_painter.dart';
import '../field/terrain_art.dart';

/// フィールドなどで、まだ読んでいない場面を自動で見せるか（テストでは切る）
bool storyAutoPlay = true;

/// 物語の場面を順に見せ、読んだしるしを進行状況に残す。
/// しるしは見せる前につける（途中で閉じても、同じ場面を何度も出さないように）。
Future<void> playStoryScenes(
  BuildContext context,
  List<StoryScene> scenes, {
  bool replay = false,
}) async {
  if (scenes.isEmpty) return;
  final services = RpgServices.of(context);
  final name = services.profiles.load().displayName;
  if (!replay) {
    var p = await services.repository.load();
    for (final s in scenes) {
      p = StoryScenes.markSeen(p, s);
    }
    await services.repository.save(p);
    if (!context.mounted) return;
  }
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) =>
          StoryPlayerScreen(scenes: scenes, heroName: name),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

/// 物語の場面を見せる画面（絵本のように、せりふを1つずつ送る）
class StoryPlayerScreen extends StatefulWidget {
  const StoryPlayerScreen({
    super.key,
    required this.scenes,
    required this.heroName,
  });

  final List<StoryScene> scenes;
  final String heroName;

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen>
    with TickerProviderStateMixin {
  int _scene = 0;
  int _line = -1; // -1 = 章の題名
  late final _type = AnimationController(vsync: this);
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  StoryScene get _current => widget.scenes[_scene];

  @override
  void initState() {
    super.initState();
    _type.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _type.dispose();
    _ambient.dispose();
    super.dispose();
  }

  String get _text =>
      _line < 0 ? '' : _current.lines[_line].textFor(widget.heroName);

  void _startLine() {
    final len = _text.runes.length;
    _type.duration = Duration(milliseconds: 30 * max(1, len));
    _type.forward(from: 0);
  }

  void _next() {
    // 文字を表示しきっていなければ、まず全部出す
    if (_line >= 0 && _type.isAnimating) {
      _type.value = 1;
      return;
    }
    setState(() {
      if (_line + 1 < _current.lines.length) {
        _line++;
      } else if (_scene + 1 < widget.scenes.length) {
        _scene++;
        _line = -1;
      } else {
        Navigator.of(context).maybePop();
        return;
      }
    });
    if (_line >= 0) _startLine();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _current;
    final base = Color(scene.color);
    final line = _line < 0 ? null : scene.lines[_line];
    final shown = _line < 0
        ? ''
        : String.fromCharCodes(
            _text.runes.take((_text.runes.length * _type.value).ceil()),
          );
    return Scaffold(
      backgroundColor: base,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(
          children: [
            // 背景：章の色のグラデーションと、ただよう光の粒
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (_, _) =>
                    CustomPaint(painter: _AmbientPainter(base, _ambient.value)),
              ),
            ),
            // 差しこむ光の柱（奥行きと光）
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _ambient,
                  builder: (_, _) => CustomPaint(
                    painter: LightRaysPainter(
                      _ambient.value * 30,
                      const Color(0xFFFFF1C9),
                      strength: 0.9,
                    ),
                  ),
                ),
              ),
            ),
            if (_line < 0)
              _TitleCard(scene: scene)
            else ...[
              // 話している人
              if (line!.speaker != StorySpeaker.narrator)
                Align(
                  alignment: line.speaker == StorySpeaker.hero
                      ? const Alignment(-0.7, 0.05)
                      : const Alignment(0.7, 0.05),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('$_scene-$_line'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Transform.translate(
                      offset: Offset(0, (1 - v) * 30),
                      child: Opacity(opacity: v.clamp(0, 1), child: child),
                    ),
                    child: SizedBox.square(
                      dimension: 190,
                      child: AnimatedBuilder(
                        animation: _ambient,
                        builder: (_, _) => CustomPaint(
                          painter: _PortraitPainter(
                            line.speaker,
                            _ambient.value * 30,
                            look: line.look,
                            color: line.color ?? scene.keeperLook,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // 手前のボケた光の粒
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (_, _) => CustomPaint(
                      painter: ForegroundBokehPainter(
                        _ambient.value * 30,
                        const Color(0xFFFFF1C9),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _TextBox(
                  name: line.speakerName(widget.heroName),
                  text: shown,
                  narrator: line.speaker == StorySpeaker.narrator,
                  done: !_type.isAnimating,
                ),
              ),
            ],
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text(
                    'スキップ ▶▶',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.scene});
  final StoryScene scene;

  @override
  Widget build(BuildContext context) {
    final parts = scene.title.split('　');
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(scene.id),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.92 + v * 0.08, child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (parts.length > 1)
              Text(parts.first, style: serif(18, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(width: 160, height: 1.5, color: Colors.white38),
            const SizedBox(height: 12),
            Text(
              parts.last,
              textAlign: TextAlign.center,
              style: serif(30, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(width: 160, height: 1.5, color: Colors.white38),
            const SizedBox(height: 28),
            const Text(
              'タップで進む',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.name,
    required this.text,
    required this.narrator,
    required this.done,
  });

  final String name;
  final String text;
  final bool narrator;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        constraints: const BoxConstraints(minHeight: 150),
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 150),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              decoration: BoxDecoration(
                color: narrator
                    ? const Color(0xE6221C18)
                    : TsuzuriColors.card.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: narrator ? Colors.white24 : TsuzuriColors.kraft,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Color(0x55000000)),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: narrator ? Colors.white : TsuzuriColors.ink,
                  fontStyle: narrator ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            if (name.isNotEmpty)
              Positioned(
                left: 14,
                top: -14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TsuzuriColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(name, style: serif(14, color: Colors.white)),
                ),
              ),
            if (done)
              Positioned(
                right: 12,
                bottom: 8,
                child: Icon(
                  Icons.arrow_drop_down,
                  color: TsuzuriColors.inkSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 章の色のグラデーションと、ただよう光の粒
class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.base, this.t);
  final Color base;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, Colors.black, 0.45)!,
            base,
            Color.lerp(base, Colors.black, 0.2)!,
          ],
        ).createShader(rect),
    );
    // 光の輪
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.55,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.5, size.height * 0.35),
                radius: size.width * 0.55,
              ),
            ),
    );
    final rnd = Random(11);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.3 + rnd.nextDouble();
      final y = (rnd.nextDouble() - t * speed * 3) % 1.0 * size.height;
      final r = 1 + rnd.nextDouble() * 2.2;
      final a = 0.2 + 0.5 * (0.5 + 0.5 * sin(t * 40 + i));
      canvas.drawCircle(
        Offset(x + sin(t * 20 + i) * 8, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: a * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => true;
}

/// 話している人の絵
class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.speaker, this.t, {this.look, this.color});
  final StorySpeaker speaker;
  final double t;

  /// 守護神の姿と色（なければ人の姿）
  final String? look;
  final int? color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    // 足もとの光
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s / 2, s * 0.93),
        width: s * 0.7,
        height: s * 0.12,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    switch (speaker) {
      case StorySpeaker.hero:
        paintHero(canvas, s, facing: Facing.down);
      case StorySpeaker.nebra:
        paintEnemy(canvas, s, 'ghost', t, color: 0xFF4A4660);
      case StorySpeaker.keeper when look != null:
        paintEnemy(canvas, s, look!, t, color: color);
      case StorySpeaker.keeper:
        canvas.save();
        canvas.scale(s / 32);
        TerrainArt.npc(
          canvas,
          const Rect.fromLTWH(0, 2, 32, 30),
          color: color ?? 0xFF8064A2,
        );
        canvas.restore();
      case StorySpeaker.narrator:
        break;
    }
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => true;
}
