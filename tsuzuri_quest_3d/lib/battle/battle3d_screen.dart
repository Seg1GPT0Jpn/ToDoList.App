import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../game/save3d.dart';

/// バトルの結果（フィールドに返す）
class Battle3DResult {
  const Battle3DResult({required this.won, this.clear});
  final bool won;

  /// 経験値・レベルの変化（にげたときは null）
  final StageClearResult? clear;
}

/// つづりクエスト3D のバトル画面（試作）。
///
/// 出題・採点・ダメージは 2D 版と同じ rpg_game の [BattleEngine]、
/// 経験値とレベルは [Progression.applyBattle] を使う。画面だけ 3D 版用に作った簡単なもの。
/// 4択の問題だけに対応する。
class Battle3DScreen extends StatefulWidget {
  const Battle3DScreen({
    super.key,
    required this.save,
    required this.world,
    required this.stage,
    required this.questions,
    required this.enemyLabel,
    required this.color,
  });

  final Save3D save;
  final WorldDef world;
  final StageDef stage;
  final List<QuizQuestion> questions;
  final String enemyLabel;
  final Color color;

  @override
  State<Battle3DScreen> createState() => _Battle3DScreenState();
}

class _Battle3DScreenState extends State<Battle3DScreen> {
  late final RpgProgress _progress = widget.save.loadProgress();
  late final BattleEngine _engine = BattleEngine(
    player: BattlePower.forStage(_progress, widget.stage),
    enemy: widget.stage.enemy,
    questions: widget.questions,
    timeLimit: Duration(seconds: widget.stage.timeLimitSeconds),
  );
  final _clock = Stopwatch();
  Timer? _timer;
  TurnResult? _last;
  StageClearResult? _clear;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _startTurn();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTurn() {
    _clock
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _last != null || _engine.isOver) return;
      if (_clock.elapsed >= _engine.limitFor(_engine.currentQuestion)) {
        _resolve(_engine.timeout());
      } else {
        setState(() {});
      }
    });
  }

  void _answer(int i) {
    if (_last != null || _engine.isOver) return;
    _resolve(_engine.answer(i, elapsed: _clock.elapsed));
  }

  void _resolve(TurnResult r) {
    _clock.stop();
    setState(() => _last = r);
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_engine.isOver) {
        _finish();
      } else {
        setState(() => _last = null);
        _startTurn();
      }
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    final summary = _engine.summary();
    final latest = widget.save.loadProgress();
    final clear = Progression.applyBattle(
      progress: latest,
      world: widget.world,
      stage: widget.stage,
      summary: summary,
    );
    await widget.save.saveProgress(clear.progress);
    if (mounted) setState(() => _clear = clear);
  }

  Future<void> _flee() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('にげますか？'),
        content: const Text('このバトルの経験値はもらえません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('たたかう'),
          ),
          FilledButton(
            key: const ValueKey('battle3d-flee-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('にげる'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(const Battle3DResult(won: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clear = _clear;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E2A3A),
        body: SafeArea(child: clear != null ? _result(clear) : _battle()),
      ),
    );
  }

  Widget _battle() {
    final q = _engine.currentQuestion;
    final enemy = _engine.enemy;
    final limit = _engine.limitFor(q).inMilliseconds;
    final left = 1 - (_clock.elapsedMilliseconds / limit).clamp(0.0, 1.0);
    final last = _last;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.enemyLabel}（${enemy.name}）',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('battle3d-flee'),
                tooltip: 'にげる',
                onPressed: _engine.isOver ? null : _flee,
                icon: const Icon(Icons.directions_run, color: Colors.white70),
              ),
            ],
          ),
          _bar(_engine.enemyHp, enemy.maxHp, const Color(0xFFE5534B)),
          const SizedBox(height: 12),
          Center(
            child: AnimatedScale(
              scale: last != null && last.correct ? 0.85 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 96,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(60),
                    bottom: Radius.circular(24),
                  ),
                ),
                alignment: const Alignment(0, -0.1),
                child: const Text(
                  '•  •',
                  style: TextStyle(color: Colors.black87, fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: left,
            minHeight: 4,
            color: left < 0.3 ? Colors.redAccent : Colors.amber,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    q.source.prompt,
                    key: const ValueKey('battle3d-prompt'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  if (q.source.sentence != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        q.source.sentence!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  for (final (i, c) in q.choices.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonal(
                        key: ValueKey('battle3d-choice-$i'),
                        style: FilledButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(14),
                          backgroundColor: last == null
                              ? null
                              : i == q.correctIndex
                              ? const Color(0xFF3FA66B)
                              : (last.chosenIndex == i
                                    ? const Color(0xFFB54A4A)
                                    : null),
                        ),
                        onPressed: last == null ? () => _answer(i) : null,
                        child: Text(c, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  if (last != null)
                    Text(
                      last.timedOut
                          ? '時間切れ！'
                          : last.correct
                          ? '正解！ ${last.damageToEnemy} のダメージ'
                          : 'ざんねん… ${last.damageToPlayer} のダメージを受けた',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: last.correct
                            ? const Color(0xFF8BE0A4)
                            : const Color(0xFFFFA3A3),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(
            'Lv${_progress.level}　HP ${_engine.playerHp} / ${_engine.maxHp}　コンボ ${_engine.combo}',
            style: const TextStyle(color: Colors.white),
          ),
          _bar(_engine.playerHp, _engine.maxHp, const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _bar(int value, int max, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: max == 0 ? 0 : (value / max).clamp(0.0, 1.0),
        minHeight: 10,
        color: color,
        backgroundColor: Colors.white12,
      ),
    ),
  );

  Widget _result(StageClearResult clear) {
    final won = _engine.phase == BattlePhase.won;
    final exp = clear.expResult;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '勝利！' : '負けてしまった…',
              key: const ValueKey('battle3d-result'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '正解 ${_engine.summary().correctCount} / ${_engine.summary().answeredCount}\n'
              '経験値 +${exp.expGained}\n'
              'Lv${exp.before.level}${exp.leveledUp ? ' → Lv${exp.after.level}（レベルアップ！）' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('battle3d-back'),
              onPressed: () =>
                  Navigator.of(context)
                      .pop(Battle3DResult(won: won, clear: clear)),
              child: const Text('フィールドにもどる'),
            ),
          ],
        ),
      ),
    );
  }
}
