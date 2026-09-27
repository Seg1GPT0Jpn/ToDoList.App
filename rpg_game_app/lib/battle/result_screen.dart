import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';

/// バトル結果（経験値・レベルアップの演出）
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.stage,
    required this.summary,
    required this.result,
    this.enemy,
    this.ghost = false,
    this.skillBefore,
    this.skillAfter,
  });

  /// このバトルの前と後の、単元の熟練度（学習ステータス）
  final SkillScore? skillBefore;
  final SkillScore? skillAfter;

  final StageDef stage;

  /// 戦った相手（亡霊バトルでは亡霊）。null ならステージの敵
  final EnemyDef? enemy;

  /// 亡霊との再戦だった
  final bool ghost;
  final BattleSummary summary;
  final StageClearResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late final _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final _exp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final _levelUp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// 勝ったときの紙吹雪
  late final _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  int _shownLevel = 0;

  ExpGainResult get _gain => widget.result.expResult;
  String get _enemyName => (widget.enemy ?? widget.stage.enemy).name;

  @override
  void initState() {
    super.initState();
    _shownLevel = _gain.before.level;
    _exp.addListener(_onExpTick);
    () async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      if (widget.summary.won) _confetti.forward();
      await _stamp.forward();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted && _gain.expGained > 0) _exp.forward();
    }();
  }

  @override
  void dispose() {
    _stamp.dispose();
    _exp.dispose();
    _levelUp.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// バトル前に、そのレベル内で貯まっていた経験値
  late final int _startExp = () {
    var e = _gain.progress.exp - _gain.expGained;
    for (var l = _gain.before.level; l < _gain.after.level; l++) {
      e += PlayerStats.expToNextLevel(l);
    }
    return max(0, e);
  }();

  /// 経験値バーの表示位置（アニメーションの進み具合 [t] に応じたレベルと割合）
  ({int level, double fraction}) _expAt(double t) {
    var level = _gain.before.level;
    var e = _startExp + (_gain.expGained * t).round();
    while (level < PlayerStats.maxLevel &&
        e >= PlayerStats.expToNextLevel(level)) {
      e -= PlayerStats.expToNextLevel(level);
      level++;
    }
    if (level >= PlayerStats.maxLevel) return (level: level, fraction: 1);
    return (level: level, fraction: e / PlayerStats.expToNextLevel(level));
  }

  void _onExpTick() {
    final lv = _expAt(Curves.easeInOut.transform(_exp.value)).level;
    if (lv > _shownLevel) {
      setState(() => _shownLevel = lv);
      _levelUp.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final won = s.won;
    return Scaffold(
      // もどるボタンは常に見えるよう画面下に固定する
      bottomNavigationBar: Container(
        color: TsuzuriColors.paper,
        padding: const EdgeInsets.fromLTRB(44, 8, 16, 12),
        child: SafeArea(
          top: false,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.directions_walk),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('フィールドにもどる', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          NotebookPaper(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(44, 24, 16, 24),
                children: [
                  Text(
                    '${RpgCatalog.stageLabel(widget.stage)}「${widget.stage.name}」',
                    style: const TextStyle(color: TsuzuriColors.inkSoft),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: _Stamp(controller: _stamp, won: won),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      won
                          ? (s.isPerfect
                                ? 'ノーミスで $_enemyName をたおした！'
                                : '$_enemyName をたおした！')
                          : '$_enemyName にやられてしまった…',
                      style: serif(17),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    child: Column(
                      children: [
                        _row(
                          '正解',
                          '${s.correctCount} / ${s.answeredCount}問（${(s.accuracy * 100).round()}%）',
                        ),
                        _row('最大コンボ', '${s.maxCombo}'),
                        _row('獲得経験値', '+${_gain.expGained} EXP'),
                        if (widget.result.firstClear) _row('ボーナス', '初回クリア！'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(child: _expPanel()),
                  if (widget.result.newCard case final card?)
                    _notice(
                      Icons.style,
                      const Color(0xFF6A4BA8),
                      'カード「${card.name}」を手に入れた！',
                      card.description,
                    ),
                  if (widget.result.rescued case final friend?)
                    _notice(
                      Icons.favorite,
                      const Color(0xFFD64545),
                      '${friend.name}を助け出した！ 仲間になった！',
                      friend.description,
                    ),
                  if (widget.ghost && won)
                    _notice(
                      Icons.auto_awesome,
                      const Color(0xFF3B8FB5),
                      '亡霊が成仏した！',
                      '正解した問題は復習手帳から消えたよ。',
                    ),
                  if (widget.result.newMistakes > 0)
                    _notice(
                      Icons.menu_book,
                      TsuzuriColors.inkSoft,
                      '亡霊が${widget.result.newMistakes}体うまれた…',
                      'まちがえた問題はフィールドをさまよっている。話しかけると再戦できるよ。くわしい解説は復習手帳へ。',
                    ),
                  if (!won &&
                      !widget.ghost &&
                      widget.stage.captiveCompanionId != null &&
                      !widget.result.progress.companions.contains(
                        widget.stage.captiveCompanionId,
                      ))
                    _notice(
                      Icons.lock,
                      TsuzuriColors.wrong,
                      '${CompanionDef.byId(widget.stage.captiveCompanionId!).name}が捕まっている！',
                      'リベンジして勝てば助け出せる。仲間になってくれるかも。',
                    ),
                  if (widget.skillAfter case final after? when after.rated) ...[
                    const SizedBox(height: 12),
                    _card(
                      color: const Color(0xFFEAF4EA),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insights,
                            color: TsuzuriColors.correct,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.skillBefore?.rated == true
                                  ? '${after.field} 熟練度 ${widget.skillBefore!.score} → ${after.score}'
                                        '${after.score > widget.skillBefore!.score ? '（+${after.score - widget.skillBefore!.score}）' : ''}'
                                  : '${after.field} 熟練度 ${after.score}（はじめて判定されました）',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.result.newlyUnlockedStageId != null) ...[
                    const SizedBox(height: 12),
                    _card(
                      color: const Color(0xFFFFF8E1),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_open, color: Color(0xFFB8860B)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '「${RpgCatalog.stage(widget.result.newlyUnlockedStageId!).name}」への道がひらけた！',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (s.missedQuestions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('ふりかえり', style: serif(16)),
                    const SizedBox(height: 6),
                    for (final q in s.missedQuestions) _review(q),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 勝ったときの紙吹雪
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, _) => CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_confetti.value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expPanel() {
    return AnimatedBuilder(
      animation: Listenable.merge([_exp, _levelUp]),
      builder: (context, _) {
        final t = _gain.expGained == 0
            ? 1.0
            : Curves.easeInOut.transform(_exp.value);
        final at = _expAt(t);
        final lu = _levelUp.value;
        final leveled = _shownLevel > _gain.before.level;
        final stats = PlayerStats.forLevel(_shownLevel);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform.scale(
                  scale: 1 + sin(lu * pi) * 0.4,
                  child: Text('Lv${at.level}', style: serif(22)),
                ),
                const SizedBox(width: 10),
                if (leveled)
                  Opacity(
                    opacity: min(1, lu * 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TsuzuriColors.exp,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: TsuzuriColors.exp.withValues(
                              alpha: 0.6 * (1 - lu),
                            ),
                            blurRadius: 16 * (1 - lu) + 2,
                            spreadRadius: 6 * (1 - lu),
                          ),
                        ],
                      ),
                      child: const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: at.fraction.clamp(0, 1),
                minHeight: 12,
                backgroundColor: const Color(0xFFEDE3D1),
                color: TsuzuriColors.exp,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              children: [
                _stat('HP', _gain.before.maxHp, stats.maxHp),
                _stat('攻撃', _gain.before.attack, stats.attack),
                _stat('防御', _gain.before.defense, stats.defense),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, int before, int now) {
    final up = now > before;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: TsuzuriColors.inkSoft),
          ),
          TextSpan(
            text: '$now',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (up)
            TextSpan(
              text: ' ▲${now - before}',
              style: const TextStyle(
                color: TsuzuriColors.correct,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _notice(
    IconData icon,
    Color color,
    String title,
    String body,
  ) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: _card(
      color: color.withValues(alpha: 0.07),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 12.5, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _card({required Widget child, Color? color}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color ?? TsuzuriColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE0D4C0)),
    ),
    child: child,
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: TsuzuriColors.inkSoft)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _review(QuizQuestion q) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ExpansionTile(
      shape: const Border(),
      title: Text(q.sentence ?? q.prompt, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        '正解：${q.answer}',
        style: const TextStyle(
          color: TsuzuriColors.correct,
          fontWeight: FontWeight.w700,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Text(
          q.explanation ?? '',
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}

/// はんこ風の「勝利」「敗北」
class _Stamp extends StatelessWidget {
  const _Stamp({required this.controller, required this.won});
  final AnimationController controller;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final color = won ? TsuzuriColors.stamp : TsuzuriColors.inkSoft;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = Curves.easeInBack.transform(controller.value);
        return Opacity(
          opacity: controller.value == 0 ? 0 : 1,
          child: Transform.rotate(
            angle: -0.18 - (1 - v) * 0.3,
            child: Transform.scale(scale: 2.6 - v * 1.6, child: child),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(won ? '勝利' : '敗北', style: serif(34, color: color)),
        ),
      ),
    );
  }
}

/// 勝ったときの紙吹雪（ノートの切れはし・星）
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.v);
  final double v;

  static const _colors = [
    Color(0xFFE57373),
    Color(0xFFF2B84B),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0 || v >= 1) return;
    final rnd = Random(7);
    final fade = v > 0.8 ? (1 - v) / 0.2 : 1.0;
    for (var i = 0; i < 70; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final delay = rnd.nextDouble() * 0.3;
      final p = ((v - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = -20 + p * (size.height * (0.7 + rnd.nextDouble() * 0.5));
      final x = x0 + sin(p * 8 + i) * 24;
      final spin = p * 10 + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      if (i % 4 == 0) {
        canvas.drawCircle(Offset.zero, 3.5, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: 8,
            height: 4 + 3 * cos(spin).abs(),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.v != v;
}
