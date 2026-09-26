import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/hero_painter.dart';
import '../art/paper.dart';
import 'result_screen.dart';

/// ターン制クイズバトル
class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.world,
    required this.stage,
    required this.questions,
    required this.progress,
  });

  final WorldDef world;
  final StageDef stage;
  final List<QuizQuestion> questions;
  final RpgProgress progress;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _Popup {
  _Popup(
    this.text,
    this.color,
    this.alignment, {
    this.big = false,
    this.onPlayer = false,
  }) : key = UniqueKey();
  final Key key;
  final String text;
  final Color color;
  final Alignment alignment;
  final bool big;

  /// true なら主人公のそば（画面下）に出す
  final bool onPlayer;
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {
  late final PlayerStats _player = PlayerStats.forLevel(widget.progress.level);
  late final BattleEngine _engine = BattleEngine(
    player: _player,
    enemy: widget.stage.enemy,
    questions: widget.questions,
    timeLimit: Duration(seconds: widget.stage.timeLimitSeconds),
  );

  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  )..repeat();
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _timer = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.stage.timeLimitSeconds),
  );
  late final _enemyHit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final _slash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final _playerHit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final _defeat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  final _stopwatch = Stopwatch();
  final List<_Popup> _popups = [];
  TurnResult? _last;
  bool _locked = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _timer.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_locked) _resolve(null);
    });
    _intro.forward().then((_) {
      if (mounted) _startQuestion();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _idle,
      _intro,
      _timer,
      _enemyHit,
      _slash,
      _playerHit,
      _defeat,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startQuestion() {
    setState(() {
      _last = null;
      _locked = false;
    });
    _stopwatch
      ..reset()
      ..start();
    _timer.forward(from: 0);
  }

  void _popup(_Popup p, {Duration after = Duration.zero}) {
    Future.delayed(after, () {
      if (!mounted) return;
      setState(() => _popups.add(p));
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _popups.remove(p));
      });
    });
  }

  void _resolve(int? choice) {
    if (_locked) return;
    _locked = true;
    _timer.stop();
    _stopwatch.stop();
    final r = choice == null
        ? _engine.timeout()
        : _engine.answer(choice, elapsed: _stopwatch.elapsed);
    setState(() => _last = r);

    if (r.correct) {
      _slash.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) _enemyHit.forward(from: 0);
      });
      _popup(
        _Popup(
          '${r.damageToEnemy}',
          TsuzuriColors.ink,
          const Alignment(0.25, -0.2),
          big: true,
        ),
        after: const Duration(milliseconds: 160),
      );
      if (r.quick) {
        _popup(
          _Popup('すばやい！', const Color(0xFF2E7DB5), const Alignment(-0.6, -0.6)),
        );
      }
      if (r.combo >= 2) {
        _popup(
          _Popup(
            '${r.combo} COMBO!',
            const Color(0xFFE08A00),
            const Alignment(0.6, -0.75),
          ),
          after: const Duration(milliseconds: 120),
        );
      }
    } else {
      _playerHit.forward(from: 0);
      _popup(
        _Popup(
          '-${r.damageToPlayer}',
          TsuzuriColors.wrong,
          const Alignment(0.1, 0.84),
          big: true,
          onPlayer: true,
        ),
      );
    }

    if (_engine.isOver) {
      if (_engine.phase == BattlePhase.won) {
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted) _defeat.forward();
        });
      }
      Future.delayed(const Duration(milliseconds: 1900), _finish);
    } else if (r.correct) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _startQuestion();
      });
    }
    // 不正解・時間切れのときは解説を読んでから「つぎへ」
  }

  Future<void> _finish() async {
    if (!mounted || _finishing) return;
    _finishing = true;
    final services = RpgServices.of(context);
    final summary = _engine.summary();
    final latest = await services.repository.load();
    final result = Progression.applyBattle(
      progress: latest,
      world: widget.world,
      stage: widget.stage,
      summary: summary,
    );
    await services.repository.save(result.progress);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) =>
            ResultScreen(stage: widget.stage, summary: summary, result: result),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _confirmFlee() async {
    final flee = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('にげますか？'),
        content: const Text('このバトルの経験値はもらえません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('たたかう'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('にげる'),
          ),
        ],
      ),
    );
    if (flee == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 回答後は、次の問題に進むまで答えた問題を表示し続ける
    final q = _last?.question ?? _engine.currentQuestion;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _playerHit,
        builder: (context, child) {
          final v = _playerHit.value;
          final shake = sin(v * pi * 7) * 9 * (1 - v);
          return Stack(
            children: [
              Transform.translate(offset: Offset(shake, 0), child: child),
              for (final p in _popups.where((p) => p.onPlayer))
                IgnorePointer(
                  key: p.key,
                  child: Align(
                    alignment: p.alignment,
                    child: _PopupText(popup: p),
                  ),
                ),
              // 被ダメージ時の赤いふち
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        TsuzuriColors.wrong.withValues(
                          alpha: 0.45 * (1 - v) * (v > 0 ? 1 : 0),
                        ),
                      ],
                      stops: const [0.55, 1],
                      radius: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: NotebookPaper(
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(flex: 5, child: _enemyArea()),
                _timerBar(),
                Expanded(flex: 6, child: _questionArea(q)),
                _playerBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final enemy = widget.stage.enemy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(enemy.name, style: serif(17)),
                const SizedBox(height: 4),
                _HpBar(
                  value: _engine.enemyHp,
                  max: enemy.maxHp,
                  color: const Color(0xFFD9822B),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'にげる',
            onPressed: _finishing ? null : _confirmFlee,
            icon: const Icon(
              Icons.directions_run,
              color: TsuzuriColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enemyArea() {
    return LayoutBuilder(
      builder: (context, box) {
        final size = min(box.maxWidth * 0.62, box.maxHeight * 0.92);
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_idle, _intro, _enemyHit, _defeat]),
              builder: (context, _) {
                final intro = Curves.bounceOut.transform(_intro.value);
                final hit = _enemyHit.value;
                final d = Curves.easeIn.transform(_defeat.value);
                return Transform.translate(
                  offset: Offset(
                    sin(hit * pi * 6) * 12 * (1 - hit),
                    -(1 - intro) * box.maxHeight,
                  ),
                  child: Transform.rotate(
                    angle: d * 0.6,
                    child: Transform.scale(
                      scale: 1 - d * 0.7,
                      child: Opacity(
                        opacity: 1 - d,
                        child: SizedBox.square(
                          dimension: size,
                          child: CustomPaint(
                            painter: _EnemyPainter(
                              widget.stage.enemy.id,
                              _idle.value * 120,
                              flash: hit > 0 && hit < 1 ? (1 - hit) : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // えんぴつの斬撃
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _slash,
                builder: (_, _) => SizedBox.square(
                  dimension: size,
                  child: CustomPaint(painter: _SlashPainter(_slash.value)),
                ),
              ),
            ),
            // 撃破時のインクしぶき
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _defeat,
                builder: (_, _) => SizedBox.square(
                  dimension: size * 1.4,
                  child: CustomPaint(painter: _SplashPainter(_defeat.value)),
                ),
              ),
            ),
            for (final p in _popups.where((p) => !p.onPlayer))
              Align(
                key: p.key,
                alignment: p.alignment,
                child: _PopupText(popup: p),
              ),
          ],
        );
      },
    );
  }

  Widget _timerBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 4, 16, 4),
      child: AnimatedBuilder(
        animation: _timer,
        builder: (_, _) {
          final left = 1 - _timer.value;
          final secs = (widget.stage.timeLimitSeconds * left).ceil();
          return Row(
            children: [
              const Icon(
                Icons.hourglass_bottom,
                size: 16,
                color: TsuzuriColors.inkSoft,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: left,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEDE3D1),
                    color: left < 0.25
                        ? TsuzuriColors.wrong
                        : TsuzuriColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '$secs',
                  textAlign: TextAlign.right,
                  style: serif(14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _questionArea(PresentedQuestion q) {
    final last = _last;
    final showExplanation = last != null && !last.correct && !_engine.isOver;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 4, 12, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey(q.hashCode),
          children: [
            _questionCard(q),
            const SizedBox(height: 10),
            Expanded(
              child: showExplanation
                  ? _explanation(q, last)
                  : _choices(q, last),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(PresentedQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: TsuzuriColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D4C0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: TsuzuriColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              q.source.category.label,
              style: const TextStyle(
                fontSize: 11,
                color: TsuzuriColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q.source.prompt,
            style: const TextStyle(fontSize: 14, color: TsuzuriColors.inkSoft),
          ),
          if (q.source.sentence != null) ...[
            const SizedBox(height: 6),
            Text(
              q.source.sentence!,
              style: serif(17, color: TsuzuriColors.ink),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choices(PresentedQuestion q, TurnResult? last) {
    Widget choice(int i) {
      Color bg = TsuzuriColors.card;
      Color border = TsuzuriColors.accent.withValues(alpha: 0.5);
      Color fg = TsuzuriColors.ink;
      if (last != null) {
        if (i == q.correctIndex) {
          bg = TsuzuriColors.correct;
          border = TsuzuriColors.correct;
          fg = Colors.white;
        } else if (i == last.chosenIndex) {
          bg = TsuzuriColors.wrong;
          border = TsuzuriColors.wrong;
          fg = Colors.white;
        } else {
          fg = TsuzuriColors.inkSoft.withValues(alpha: 0.5);
        }
      }
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1.5),
              boxShadow: last == null
                  ? const [
                      BoxShadow(color: Color(0x1F6D4C41), offset: Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _locked ? null : () => _resolve(i),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      q.choices[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [choice(0), choice(1)],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [choice(2), choice(3)],
          ),
        ),
      ],
    );
  }

  Widget _explanation(PresentedQuestion q, TurnResult last) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TsuzuriColors.wrong.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            last.timedOut ? '時間切れ…' : 'ざんねん！',
            style: serif(15, color: TsuzuriColors.wrong),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '正解：'),
                TextSpan(
                  text: q.source.answer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TsuzuriColors.correct,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                q.source.explanation ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: TsuzuriColors.ink,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _startQuestion,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('つぎへ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerBar() {
    return AnimatedBuilder(
      animation: _slash,
      builder: (context, child) {
        // 攻撃時に少し前へ踏み込む
        final lunge = sin(_slash.value * pi) * 10;
        return Container(
          margin: const EdgeInsets.fromLTRB(36, 0, 12, 10),
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(
            color: TsuzuriColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TsuzuriColors.accent, width: 1.5),
          ),
          child: Row(
            children: [
              Transform.translate(
                offset: Offset(0, -lunge),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CustomPaint(painter: _HeroPainter(Facing.down)),
                ),
              ),
              const SizedBox(width: 10),
              Text('Lv${_player.level}', style: serif(15)),
              const SizedBox(width: 12),
              Expanded(
                child: _HpBar(
                  value: _engine.playerHp,
                  max: _player.maxHp,
                  color: TsuzuriColors.hp,
                  showNumbers: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.value,
    required this.max,
    required this.color,
    this.showNumbers = false,
  });

  final int value;
  final int max;
  final Color color;
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value / max),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final c = v < 0.3 ? TsuzuriColors.hpLow : color;
        return Row(
          children: [
            const Text(
              'HP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: TsuzuriColors.inkSoft,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE3D1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: TsuzuriColors.ink.withValues(alpha: 0.6),
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            if (showNumbers) ...[
              const SizedBox(width: 8),
              Text(
                '$value / $max',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PopupText extends StatelessWidget {
  const _PopupText({required this.popup});
  final _Popup popup;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, v, _) {
        final pop = Curves.elasticOut.transform((v * 2).clamp(0, 1));
        return Transform.translate(
          offset: Offset(0, -v * 40),
          child: Opacity(
            opacity: v < 0.7 ? 1 : (1 - (v - 0.7) / 0.3),
            child: Transform.scale(
              scale: 0.4 + pop * 0.6,
              child: Text(
                popup.text,
                style: serif(popup.big ? 40 : 20, color: popup.color).copyWith(
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 0,
                      offset: Offset(2, 2),
                    ),
                    Shadow(color: Colors.white, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnemyPainter extends CustomPainter {
  _EnemyPainter(this.enemyId, this.t, {this.flash = 0});
  final String enemyId;
  final double t;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (flash <= 0) {
      paintEnemy(canvas, s, enemyId, t);
      return;
    }
    // 攻撃が当たった瞬間に白く光らせる
    canvas.saveLayer(Offset.zero & size, Paint());
    paintEnemy(canvas, s, enemyId, t);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.white.withValues(alpha: flash * 0.85)
        ..blendMode = BlendMode.srcATop,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EnemyPainter old) => true;
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.facing);
  final Facing facing;
  @override
  void paint(Canvas canvas, Size size) =>
      paintHero(canvas, size.width, facing: facing);
  @override
  bool shouldRepaint(_HeroPainter old) => false;
}

/// えんぴつで斜めに斬る線
class _SlashPainter extends CustomPainter {
  _SlashPainter(this.v);
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0 || v >= 1) return;
    final s = size.width;
    final start = Offset(s * 0.1, s * 0.15);
    final end = Offset(s * 0.9, s * 0.85);
    final head = Offset.lerp(
      start,
      end,
      Curves.easeOut.transform(min(1, v * 1.6)),
    )!;
    final tail = Offset.lerp(
      start,
      end,
      Curves.easeIn.transform(max(0, v * 1.6 - 0.6)),
    )!;
    final fade = v < 0.7 ? 1.0 : (1 - v) / 0.3;
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..color = TsuzuriColors.ink.withValues(alpha: 0.85 * fade)
        ..strokeWidth = s * 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      tail + Offset(s * 0.03, -s * 0.02),
      head + Offset(s * 0.03, -s * 0.02),
      Paint()
        ..color = const Color(0xFFF2C94C).withValues(alpha: 0.9 * fade)
        ..strokeWidth = s * 0.015
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SlashPainter old) => old.v != v;
}

/// 撃破時に飛び散るインク
class _SplashPainter extends CustomPainter {
  _SplashPainter(this.v);
  final double v;
  static final _dirs = List.generate(12, (i) {
    final r = Random(i * 31 + 5);
    return (
      angle: i / 12 * 2 * pi + r.nextDouble() * 0.4,
      dist: 0.25 + r.nextDouble() * 0.2,
      size: 0.02 + r.nextDouble() * 0.03,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0.05 || v >= 1) return;
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final e = Curves.easeOut.transform(v);
    final paint = Paint()
      ..color = TsuzuriColors.ink.withValues(alpha: (1 - v) * 0.9);
    for (final d in _dirs) {
      final p = c + Offset(cos(d.angle), sin(d.angle)) * s * d.dist * e;
      canvas.drawCircle(p, s * d.size * (1 - v * 0.5), paint);
    }
    canvas.drawCircle(
      c,
      s * 0.3 * e,
      Paint()
        ..color = const Color(0xFFF2B84B).withValues(alpha: (1 - v) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.v != v;
}
