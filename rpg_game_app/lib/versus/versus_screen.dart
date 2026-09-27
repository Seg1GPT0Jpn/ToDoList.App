import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/hero_painter.dart';
import '../art/paper.dart';

/// 対戦の相手
enum VersusOpponent {
  /// 同じ端末で2人（上と下に分かれて向かい合う）
  friend,

  /// CPU
  cpu,
}

/// 対戦モードの準備画面：相手・教科・問題数を選ぶ
class VersusSetupScreen extends StatefulWidget {
  const VersusSetupScreen({super.key});

  @override
  State<VersusSetupScreen> createState() => _VersusSetupScreenState();
}

class _VersusSetupScreenState extends State<VersusSetupScreen> {
  VersusOpponent _opponent = VersusOpponent.cpu;
  CpuLevel _level = CpuLevel.normal;
  final Set<String> _subjects = {RpgCatalog.englishWorldId};
  int _rounds = 15;
  bool _loading = false;
  final _nameA = TextEditingController(text: 'あお');
  final _nameB = TextEditingController(text: 'あか');

  @override
  void dispose() {
    _nameA.dispose();
    _nameB.dispose();
    super.dispose();
  }

  /// 選んだ教科から、問題を集める（1教科あたり4エリアぶん）
  Future<List<QuizQuestion>> _collect() async {
    final services = RpgServices.of(context);
    final rnd = Random();
    final out = <QuizQuestion>[];
    for (final id in _subjects) {
      final stages = [...RpgCatalog.world(id).stages]..shuffle(rnd);
      var used = 0;
      for (final s in stages) {
        if (used >= 4) break;
        final pool = await services.loadStagePool(s);
        if (pool == null || !pool.origin.usableInRpg) continue;
        // 長文読解は対戦には向かないので外す
        out.addAll(pool.questions.where((q) => q.passage == null));
        used++;
      }
    }
    return out;
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    final questions = await _collect();
    if (!mounted) return;
    setState(() => _loading = false);
    if (questions.isEmpty) return;
    final me = _nameA.text.trim().isEmpty ? 'あなた' : _nameA.text.trim();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VersusScreen(
          questions: questions,
          names: [
            me,
            _opponent == VersusOpponent.cpu
                ? 'CPU（${_level.label}）'
                : (_nameB.text.trim().isEmpty ? '相手' : _nameB.text.trim()),
          ],
          cpu: _opponent == VersusOpponent.cpu ? _level : null,
          rounds: _rounds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('対戦モード', style: serif(18))),
      body: NotebookPaper(
        child: StreamBuilder<RpgProgress>(
          stream: services.repository.watch(),
          builder: (context, snap) {
            final progress = snap.data ?? RpgProgress.initial;
            return ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                const Text(
                  '早押しクイズで対決！ 先に正しく答えた人が相手にダメージ。'
                  'はやく答えるほど、続けて正解するほど強い一撃になる。'
                  'まちがえると「お手つき」で自分が少しダメージを受け、その問題は相手だけが答えられる。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 16),
                Text('1. 相手', style: serif(15)),
                const SizedBox(height: 6),
                SegmentedButton<VersusOpponent>(
                  segments: const [
                    ButtonSegment(
                      value: VersusOpponent.cpu,
                      icon: Icon(Icons.smart_toy_outlined),
                      label: Text('CPU'),
                    ),
                    ButtonSegment(
                      value: VersusOpponent.friend,
                      icon: Icon(Icons.people_outline),
                      label: Text('この端末で2人'),
                    ),
                  ],
                  selected: {_opponent},
                  onSelectionChanged: (s) =>
                      setState(() => _opponent = s.first),
                ),
                const SizedBox(height: 8),
                if (_opponent == VersusOpponent.cpu)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final l in CpuLevel.values)
                        ChoiceChip(
                          label: Text(l.label),
                          selected: _level == l,
                          onSelected: (_) => setState(() => _level = l),
                        ),
                    ],
                  )
                else
                  const Text(
                    '端末を机に置いて、向かい合って遊びます。上の人の画面はさかさまに表示されます。',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameA,
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'あなたの名前（下）',
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_opponent == VersusOpponent.friend) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nameB,
                          maxLength: 8,
                          decoration: const InputDecoration(
                            labelText: '相手の名前（上）',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text('2. 出題する教科（いくつでも）', style: serif(15)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final w in RpgCatalog.worlds)
                      if (!w.isComingSoon)
                        FilterChip(
                          avatar: Progression.isWorldPlayable(progress, w)
                              ? null
                              : const Icon(Icons.lock, size: 16),
                          label: Text(w.subject),
                          selected: _subjects.contains(w.id),
                          onSelected: Progression.isWorldPlayable(progress, w)
                              ? (on) => setState(() {
                                  if (on) {
                                    _subjects.add(w.id);
                                  } else if (_subjects.length > 1) {
                                    _subjects.remove(w.id);
                                  }
                                })
                              : null,
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('3. 問題数', style: serif(15)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final n in const [10, 15, 20])
                      ChoiceChip(
                        label: Text('$n問'),
                        selected: _rounds == n,
                        onSelected: (_) => setState(() => _rounds = n),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loading ? null : _start,
                  icon: const Icon(Icons.flash_on),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_loading ? '問題を集めています…' : '対戦スタート！'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 早押しクイズ対戦の画面。
///
/// 2人のときは画面を上下に分け、上の人の側はさかさまに表示する（向かい合って遊ぶ）。
/// CPU のときは、上に CPU、下に自分の問題が出る。
class VersusScreen extends StatefulWidget {
  const VersusScreen({
    super.key,
    required this.questions,
    required this.names,
    this.cpu,
    this.rounds = 15,
    this.onFinished,
    this.random,
  });

  final List<QuizQuestion> questions;
  final List<String> names;

  /// CPU の強さ（2人で遊ぶときは null）
  final CpuLevel? cpu;
  final int rounds;
  final void Function(VersusMatch match)? onFinished;

  /// テスト用
  final Random? random;

  @override
  State<VersusScreen> createState() => _VersusScreenState();
}

class _VersusScreenState extends State<VersusScreen>
    with TickerProviderStateMixin {
  late VersusMatch _match;
  late VersusCpu? _cpu;
  late final _timer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  );
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();
  final _stopwatch = Stopwatch();
  Timer? _cpuTimer;

  /// いま表示している結果（次の問題に進むまで）
  VersusTurn? _last;

  /// 問題の結果を見せている間（答えを受け付けない）
  bool _reveal = false;

  /// それぞれが最後に選んだ答え（色をつける）
  final Map<int, int> _picked = {};

  @override
  void initState() {
    super.initState();
    _newMatch();
    _timer.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_reveal && !_match.isOver) {
        _show(_match.timeout());
      }
    });
    _startRound();
  }

  void _newMatch() {
    _match = VersusMatch(
      questions: widget.questions,
      names: widget.names,
      rounds: widget.rounds,
      random: widget.random,
    );
    _cpu = widget.cpu == null
        ? null
        : VersusCpu(widget.cpu!, random: widget.random);
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    _timer.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _reveal = false;
      _last = null;
      _picked.clear();
    });
    _stopwatch
      ..reset()
      ..start();
    _timer.duration = _match.timeLimit;
    _timer.forward(from: 0);
    _scheduleCpu();
  }

  void _scheduleCpu() {
    _cpuTimer?.cancel();
    final cpu = _cpu;
    if (cpu == null || _match.isOver) return;
    final q = _match.current;
    _cpuTimer = Timer(cpu.thinkTime(q), () {
      if (!mounted || _reveal || _match.isOver) return;
      if (!identical(_match.current, q) || _match.isLocked(1)) return;
      final choice = cpu.choose(
        q,
        avoid: {if (_picked[0] != null) _picked[0]!},
      );
      _answer(1, choice);
    });
  }

  void _answer(int side, int choice) {
    if (_reveal || _match.isOver || _match.isLocked(side)) return;
    final t = _match.answer(side, choice, elapsed: _stopwatch.elapsed);
    _picked[side] = choice;
    _show(t);
  }

  void _show(VersusTurn t) {
    final music = RpgServices.of(context).music;
    if (t.correct) {
      music.se(t.fast ? 'se_critical' : 'se_attack');
    } else if (!t.timedOut) {
      music.se('se_wrong');
    }
    setState(() => _last = t);
    if (!t.roundOver) return;
    _cpuTimer?.cancel();
    _timer.stop();
    _stopwatch.stop();
    setState(() => _reveal = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_match.isOver) {
        music.jingle(
          _match.winner == 0 || widget.cpu == null ? 'victory' : 'defeat',
        );
        widget.onFinished?.call(_match);
        setState(() {});
        return;
      }
      _startRound();
    });
  }

  void _rematch() {
    setState(_newMatch);
    _startRound();
  }

  @override
  Widget build(BuildContext context) {
    final twoPlayers = widget.cpu == null;
    return Scaffold(
      backgroundColor: TsuzuriColors.paper,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: twoPlayers
                      ? RotatedBox(quarterTurns: 2, child: _panel(1))
                      : _cpuPanel(),
                ),
                _centerBar(),
                Expanded(flex: twoPlayers ? 1 : 2, child: _panel(0)),
              ],
            ),
            Positioned(
              left: 4,
              top: 4,
              child: IconButton(
                tooltip: 'やめる',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: TsuzuriColors.inkSoft),
              ),
            ),
            if (_match.isOver && _reveal) _resultOverlay(),
          ],
        ),
      ),
    );
  }

  /// 真ん中の帯：何問目か・残り時間
  Widget _centerBar() {
    return Container(
      color: TsuzuriColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            '${min(_match.round, _match.rounds)} / ${_match.rounds}問',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _timer,
              builder: (_, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1 - _timer.value,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  color: _timer.value > 0.7
                      ? TsuzuriColors.wrong
                      : TsuzuriColors.exp,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.flash_on, color: TsuzuriColors.exp, size: 18),
        ],
      ),
    );
  }

  Widget _hpBar(VersusPlayer p, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: p.hp / p.maxHp),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 10,
          backgroundColor: TsuzuriColors.gridLine,
          color: v < 0.3 ? TsuzuriColors.hpLow : color,
        ),
      ),
    );
  }

  /// CPU の側（上）：CPU の姿と HP
  Widget _cpuPanel() {
    final p = _match.players[1];
    final last = _last;
    final thinking = !_reveal && !_match.isLocked(1);
    return Container(
      color: const Color(0xFFF1EBE0),
      padding: const EdgeInsets.fromLTRB(48, 8, 16, 8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 84,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, _) => CustomPaint(
                painter: _LookPainter(_cpuLook(widget.cpu!), _idle.value * 60),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: serif(16)),
                const SizedBox(height: 4),
                _hpBar(p, const Color(0xFFD9822B)),
                const SizedBox(height: 4),
                Text(
                  'HP ${p.hp}　正解 ${p.correct}　${p.combo >= 2 ? '${p.combo}連続！' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  last != null && last.side == 1
                      ? (last.correct
                            ? '正解！ ${last.damage}ダメージ${last.fast ? '（はやおし）' : ''}'
                            : 'お手つき…')
                      : thinking
                      ? '考え中…'
                      : '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: last != null && last.side == 1 && last.correct
                        ? TsuzuriColors.stamp
                        : TsuzuriColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _cpuLook(CpuLevel l) => switch (l) {
    CpuLevel.easy => 'eraser',
    CpuLevel.normal => 'pencil',
    CpuLevel.hard => 'knight',
    CpuLevel.master => 'dragon',
  };

  /// プレイヤーの側：名前・HP・問題・選択肢
  Widget _panel(int side) {
    final p = _match.players[side];
    final q = _match.current;
    final locked = _match.isLocked(side);
    final last = _last;
    final color = side == 0 ? const Color(0xFF3B7DD8) : const Color(0xFFD64545);
    String? banner;
    Color bannerColor = TsuzuriColors.inkSoft;
    if (last != null) {
      if (last.side == side && last.correct) {
        banner =
            '正解！ ${last.damage}ダメージ${last.fast ? '・はやおし' : ''}${last.combo >= 2 ? '・${last.combo}連続' : ''}';
        bannerColor = TsuzuriColors.correct;
      } else if (last.side == 1 - side && last.correct) {
        banner = '${_match.players[1 - side].name}に先をこされた！ -${last.damage}';
        bannerColor = TsuzuriColors.wrong;
      } else if (locked) {
        banner = 'お手つき！ -${VersusMatch.missDamage}（この問題はもう答えられない）';
        bannerColor = TsuzuriColors.wrong;
      } else if (last.timedOut) {
        banner = '時間切れ！';
      }
    }
    return Container(
      color: side == 0 ? TsuzuriColors.card : const Color(0xFFFFF6F4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: 28,
                child: CustomPaint(painter: _HeroMini(side == 0)),
              ),
              const SizedBox(width: 6),
              Text(p.name, style: serif(15, color: color)),
              const SizedBox(width: 8),
              Expanded(child: _hpBar(p, color)),
              const SizedBox(width: 6),
              Text(
                '${p.hp}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (q.source.sentence != null)
                    Text(
                      q.source.sentence!,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  Text(q.source.prompt, style: serif(15)),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 22,
            child: banner == null
                ? null
                : Text(
                    banner,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: bannerColor,
                    ),
                  ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 3.4,
            children: [
              for (var i = 0; i < q.choices.length; i++)
                _choice(side, i, q, locked),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choice(int side, int i, PresentedQuestion q, bool locked) {
    final picked = _picked[side] == i;
    Color? bg;
    if (_reveal && i == q.correctIndex) {
      bg = TsuzuriColors.correct.withValues(alpha: 0.25);
    } else if (picked) {
      bg = TsuzuriColors.wrong.withValues(alpha: 0.2);
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      onPressed: locked || _reveal || _match.isOver
          ? null
          : () => _answer(side, i),
      child: Text(
        q.choices[i],
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: TsuzuriColors.ink),
      ),
    );
  }

  Widget _resultOverlay() {
    final w = _match.winner;
    final a = _match.players[0], b = _match.players[1];
    final title = w == null
        ? '引き分け！'
        : widget.cpu != null
        ? (w == 0 ? 'あなたの勝ち！' : 'CPU の勝ち…')
        : '${_match.players[w].name}の勝ち！';
    Widget card() => Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TsuzuriColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TsuzuriColors.stamp, width: 2),
          boxShadow: const [
            BoxShadow(blurRadius: 12, color: Color(0x44000000)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: serif(24, color: TsuzuriColors.stamp)),
            const SizedBox(height: 12),
            for (final p in [a, b])
              Text(
                '${p.name}：HP ${p.hp}・正解 ${p.correct}・最大 ${p.maxCombo}連続・お手つき ${p.misses}',
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('もどる'),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _rematch, child: const Text('もう一度')),
              ],
            ),
          ],
        ),
      ),
    );
    return Container(color: const Color(0x66000000), child: card());
  }
}

class _LookPainter extends CustomPainter {
  _LookPainter(this.look, this.t);
  final String look;
  final double t;
  @override
  void paint(Canvas canvas, Size size) =>
      paintEnemy(canvas, size.shortestSide, look, t);
  @override
  bool shouldRepaint(_LookPainter old) => true;
}

class _HeroMini extends CustomPainter {
  _HeroMini(this.front);
  final bool front;
  @override
  void paint(Canvas canvas, Size size) => paintHero(
    canvas,
    size.shortestSide,
    facing: front ? Facing.down : Facing.left,
  );
  @override
  bool shouldRepaint(_HeroMini old) => false;
}
