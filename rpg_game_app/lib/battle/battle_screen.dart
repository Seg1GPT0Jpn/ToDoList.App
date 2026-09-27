import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../app/toast.dart';
import '../audio/music_director.dart';
import '../art/battle_backdrop.dart';
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
    this.trial = false,
    this.ghost = false,
    this.onFinished,
    this.mode,
  });

  /// 記録のしかた（図鑑・クエスト・学習記録）。省略すると
  /// 亡霊なら [BattleMode.ghost]、確認用なら [BattleMode.trial]、ほかは [BattleMode.rpg]
  final BattleMode? mode;

  /// バトルが終わったときに呼ぶ（試験対策ワールドのクリア記録に使う）
  final void Function(BattleSummary summary)? onFinished;

  /// 確認用のバトル（結果を保存しない）
  final bool trial;

  /// 亡霊（そのステージで間違えた問題）との再戦
  final bool ghost;

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

  /// バトルの舞台の地形
  late final Terrain _terrain = battleTerrainOf(widget.stage);

  /// 亡霊バトルでは、間違えた問題の数に合わせた弱めの亡霊が相手
  late final EnemyDef _enemy = widget.ghost
      ? EnemyDef(
          id: 'ghost_${widget.stage.id}',
          name: '${widget.stage.enemy.name}の亡霊',
          maxHp: max(
            1,
            (_player.attack * widget.questions.length * 0.9).round(),
          ),
          attack: max(1, (widget.stage.enemy.attack * 0.6).round()),
          look: 'ghost',
          introLine: 'あのとき まちがえた問題…おぼえているかな？',
          defeatLine: 'もう まちがえないね…すっきりした…',
        )
      : widget.stage.enemy;

  late final BattleMode _mode =
      widget.mode ??
      (widget.ghost
          ? BattleMode.ghost
          : widget.trial
          ? BattleMode.trial
          : BattleMode.rpg);

  late RpgServices _services;
  bool _audioStarted = false;
  late final String _musicKey = widget.stage.isBoss && !widget.ghost
      ? MusicDirector.boss
      : MusicDirector.battle;

  /// このバトルでの回答（学習記録に残す）
  final List<AnswerEvent> _events = [];

  /// ボス登場の演出
  bool _bossBanner = false;

  /// 単元の熟練度（試験対策など、もとの単元がはっきりしないバトルでは null）
  SkillScore? _skillOf(LearningRecord record) {
    final base = Proficiency.stageOfSet(
      widget.stage.questionSetIds.isEmpty
          ? ''
          : widget.stage.questionSetIds.first,
    );
    if (base == null || widget.stage.questionSetIds.length > 1) return null;
    return Proficiency.ofStage(record, base);
  }

  late final SkillScore? _skillBefore = _skillOf(_services.meta.record);

  late final BattleEngine _engine = BattleEngine(
    // 苦手な問題・復習の日が来た問題ほど出やすくする（確認用のバトルは除く）
    questionWeight: _mode == BattleMode.trial
        ? null
        : AdaptiveWeights.forRecord(_services.meta.record, RpgServices.today()),
    player: _player,
    enemy: _enemy,
    // 共通テスト遺跡：ボスが重なって現れる連戦
    reinforcements: widget.ghost ? const [] : widget.stage.reinforcements,
    questions: widget.questions,
    timeLimit: Duration(seconds: widget.stage.timeLimitSeconds),
    readingTimeLimit: Duration(seconds: widget.stage.readingTimeLimitSeconds),
    deck: [for (final id in widget.progress.battleDeck) CardDef.byId(id)],
    bossRule: widget.ghost ? BossRule.none : BossRules.of(widget.stage),
    // 装備と職業の補正（その教科のバトルで効く装備もある）
    bonus: Gear.bonusFor(widget.progress, widget.stage.worldId),
    // 復習の塔の番人は「10問中8問」の試練
    trialWindow: widget.stage.id.startsWith('review_tower') ? 10 : 5,
    trialNeed: widget.stage.id.startsWith('review_tower') ? 8 : 4,
    companions: {
      for (final id in widget.progress.companions) CompanionDef.byId(id).effect,
    },
    bonusHpRate: widget.progress.springBuff && !widget.ghost
        ? Progression.springHpRate
        : 0,
  );

  /// 敵のセリフ（登場時・撃破時に少しだけ出す）
  String? _speech;

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

  /// 当たったときに飛びちる火花
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  /// 火花の色（クリティカルは金、弱点は緑、ふつうは墨）
  Color _burstColor = TsuzuriColors.ink;

  /// クリティカルの白い光
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final _playerHit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final _defeat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// ボスの連戦で、たおれていくところを見せているボス（次のボスはそのあと前に出る）
  EnemyDef? _fallen;

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
    if (_enemy.introLine.isNotEmpty) _speech = _enemy.introLine;
    _intro.forward().then((_) {
      // セリフを読むあいだ少し待ってから1問目
      Future.delayed(Duration(milliseconds: _speech == null ? 0 : 1400), () {
        if (!mounted) return;
        setState(() => _speech = null);
        _startQuestion();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services = RpgServices.of(context);
    // バトル前の熟練度を、記録が更新される前に読んでおく
    // （サービスが使えるようになった直後。initState ではまだ使えない）
    _skillBefore;
    if (_audioStarted) return;
    _audioStarted = true;
    final music = _services.music;
    music.enter(_musicKey);
    if (_musicKey == MusicDirector.boss) {
      music.se('se_boss_appear');
      _bossBanner = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _bossBanner = false);
      });
    } else {
      final species = EnemySpeciesCatalog.of(_enemy.look);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) music.se(species.sound);
      });
    }
  }

  @override
  void dispose() {
    _services.music.leave(_musicKey);
    for (final c in [
      _idle,
      _intro,
      _timer,
      _enemyHit,
      _slash,
      _burst,
      _flash,
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
    // 長文の設問は制限時間が長い
    _timer.duration = _engine.limitFor(_engine.currentQuestion);
    _timer.forward(from: 0);
  }

  /// 手札のカードを使う（1問に1枚。回答前だけ）
  void _useCard(int index) {
    if (_locked || _engine.pendingCard != null) return;
    final card = _engine.useCard(index);
    if (card.effect == CardEffect.time) {
      // 残り時間を保ったまま、制限時間だけ延ばす
      final elapsed = _stopwatch.elapsed;
      final limit = _engine.limitFor(_engine.currentQuestion);
      _timer.duration = limit;
      _timer.forward(from: elapsed.inMilliseconds / limit.inMilliseconds);
    }
    _popup(
      _Popup(
        '${card.name}！',
        const Color(0xFF6A4BA8),
        const Alignment(0, -0.35),
      ),
    );
    setState(() {});
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
    _record(r);

    if (r.correct) {
      _slash.forward(from: 0);
      _burstColor = r.quick
          ? const Color(0xFFF2B84B)
          : r.weakness
          ? const Color(0xFF2E9E5B)
          : r.blocked
          ? TsuzuriColors.inkSoft
          : TsuzuriColors.ink;
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) _burst.forward(from: 0);
      });
      if (r.quick || r.bossBurst || r.special) _flash.forward(from: 0);
      if (r.special) {
        _burstColor = const Color(0xFFD64545);
        _popup(
          _Popup(
            '必殺技！',
            const Color(0xFFD64545),
            const Alignment(0, 0.05),
            big: true,
          ),
          after: const Duration(milliseconds: 100),
        );
      }
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
          _Popup(
            'クリティカル！',
            const Color(0xFFD64545),
            const Alignment(-0.6, -0.6),
          ),
        );
      }
      if (r.combo >= 2) {
        final rate = DamageCalculator.chainRate(r.combo);
        _popup(
          _Popup(
            rate > 1 ? '${r.combo} CHAIN ×$rate' : '${r.combo} CHAIN',
            const Color(0xFFE08A00),
            const Alignment(0.6, -0.75),
          ),
          after: const Duration(milliseconds: 120),
        );
      }
      if (r.weakness) {
        _popup(
          _Popup('弱点！', const Color(0xFF2E9E5B), const Alignment(-0.55, 0.25)),
          after: const Duration(milliseconds: 200),
        );
      }
      if (r.blocked) {
        _popup(
          _Popup(
            '装甲ではじかれた…',
            TsuzuriColors.inkSoft,
            const Alignment(-0.4, 0.3),
          ),
          after: const Duration(milliseconds: 200),
        );
      }
      if (r.armorBroken) {
        _popup(
          _Popup('装甲が割れた！', const Color(0xFF2E7DB5), const Alignment(0, 0.45)),
          after: const Duration(milliseconds: 260),
        );
      }
      if (r.guardBroken) {
        _popup(
          _Popup('守りがくずれた！', const Color(0xFF2E7DB5), const Alignment(0, 0.45)),
          after: const Duration(milliseconds: 260),
        );
      }
      if (r.bossBurst) {
        _popup(
          _Popup(
            r.trialResult == true ? '試練クリア！大技！' : '大技！',
            TsuzuriColors.stamp,
            const Alignment(0, -0.05),
            big: true,
          ),
          after: const Duration(milliseconds: 320),
        );
      }
      if (r.healed > 0) {
        _popup(
          _Popup(
            '+${r.healed}',
            TsuzuriColors.correct,
            const Alignment(-0.3, 0.84),
            onPlayer: true,
          ),
        );
      }
    } else if (r.guarded) {
      _popup(
        _Popup(
          'ガード！',
          const Color(0xFF2E7DB5),
          const Alignment(0.1, 0.84),
          big: true,
          onPlayer: true,
        ),
      );
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
      if (r.specialMissed) {
        _popup(
          _Popup('必殺技は空振り…', TsuzuriColors.inkSoft, const Alignment(0, 0.35)),
          after: const Duration(milliseconds: 200),
        );
      }
      if (r.disrupted) {
        _popup(
          _Popup(
            '次の問題がむずかしくなった…',
            const Color(0xFF6A4BA8),
            const Alignment(0, 0.5),
          ),
          after: const Duration(milliseconds: 250),
        );
      }
      if (r.comboKept) {
        _popup(
          _Popup(
            'チェインを守った！',
            const Color(0xFFE08A00),
            const Alignment(0.6, -0.75),
          ),
        );
      }
      if (r.survived) {
        _popup(
          _Popup(
            'ねこ先生がかばってくれた！',
            const Color(0xFF6A4BA8),
            const Alignment(0, 0.6),
            onPlayer: true,
          ),
          after: const Duration(milliseconds: 300),
        );
      }
    }

    if (r.defeated != null) {
      _popup(
        _Popup(
          '${r.defeated!.name}をたおした！',
          TsuzuriColors.stamp,
          const Alignment(0, -0.1),
          big: true,
        ),
        after: const Duration(milliseconds: 300),
      );
      _fallen = r.defeated;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _defeat.forward(from: 0);
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        _defeat.reset();
        setState(() {
          _fallen = null;
          if (_engine.enemy.introLine.isNotEmpty) {
            _speech = _engine.enemy.introLine;
          }
        });
        _intro.forward(from: 0);
      });
    }
    if (r.joined != null && r.defeated == null) {
      _services.music.se('se_boss_appear');
      _popup(
        _Popup(
          '${r.joined!.name}が乱入してきた！',
          TsuzuriColors.stamp,
          const Alignment(0, 0.2),
          big: true,
        ),
        after: const Duration(milliseconds: 450),
      );
    }
    if (r.backDamage > 0) {
      _popup(
        _Popup('後ろのボスの追撃！', TsuzuriColors.wrong, const Alignment(0, 0.5)),
        after: const Duration(milliseconds: 250),
      );
    }

    if (r.trialResult == false) {
      _popup(
        _Popup(
          '試練失敗…ボスが${r.enemyHealed}回復した',
          TsuzuriColors.inkSoft,
          const Alignment(0, 0.1),
        ),
        after: const Duration(milliseconds: 350),
      );
    }

    if (_engine.isOver) {
      final won = _engine.phase == BattlePhase.won;
      if (won) {
        Future.delayed(const Duration(milliseconds: 550), () {
          if (mounted) _defeat.forward();
        });
        if (_engine.enemy.defeatLine.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _speech = _engine.enemy.defeatLine);
          });
        }
      }
      Future.delayed(
        Duration(
          milliseconds: won && _engine.enemy.defeatLine.isNotEmpty
              ? 2600
              : 1900,
        ),
        _finish,
      );
    } else if (r.defeated != null) {
      // 次のボスが前に出てきて、ひとこと言ってから次の問題
      Future.delayed(const Duration(milliseconds: 2900), () {
        if (!mounted) return;
        setState(() => _speech = null);
        _startQuestion();
      });
    } else if (r.correct) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _startQuestion();
      });
    }
    // 不正解・時間切れのときは解説を読んでから「つぎへ」
  }

  /// 回答を学習記録用に取っておき、音を鳴らす
  void _record(TurnResult r) {
    final id = r.question.source.id;
    final setId = _services.questions.setIdOf(id);
    // 個人用単語帳（LEAP など）の問題は、どのセットにも入っていないので記録しない
    if (setId != null) {
      _events.add(
        AnswerEvent(
          questionId: id,
          setId: setId,
          category: r.question.source.category.name,
          isCorrect: r.correct,
          elapsedMs: r.timedOut
              ? _engine.limitFor(r.question).inMilliseconds
              : _stopwatch.elapsedMilliseconds,
        ),
      );
    }
    final music = _services.music;
    if (r.correct) {
      music.se(r.quick ? 'se_critical' : 'se_correct');
      Future.delayed(const Duration(milliseconds: 140), () {
        music.se(r.blocked ? 'se_block' : 'se_attack');
      });
    } else if (r.guarded) {
      music.se('se_block');
    } else {
      music.se('se_wrong');
      Future.delayed(const Duration(milliseconds: 160), () {
        music.se('se_damage');
      });
    }
    if (r.healed > 0) music.se('se_heal');
    music.answer(correct: r.correct, combo: r.combo);
  }

  /// 学習記録・図鑑・クエスト・実績にバトルの結果を反映する
  Future<void> _commitMeta(BattleSummary summary, RpgProgress progress) async {
    final meta = _services.meta;
    final report = BattleReport(
      mode: _mode,
      subject: widget.world.id,
      enemyId: _enemy.id,
      look: _enemy.look,
      isBoss: widget.stage.isBoss,
      won: summary.won,
      correct: summary.correctCount,
      answered: summary.answeredCount,
      maxCombo: summary.maxCombo,
      setIds: widget.stage.questionSetIds,
    );
    final u = MetaUpdate.apply(
      record: meta.record,
      journal: meta.journal,
      progress: progress,
      events: _events,
      report: report,
      day: RpgServices.today(),
      subjects: _services.questSubjects(progress),
    );
    if (_mode == BattleMode.trial) return;
    await meta.save(record: u.record, journal: u.journal);
    if (u.newAchievements.isNotEmpty) _services.music.se('se_achievement');
    showMetaToast(achievements: u.newAchievements, quests: u.completedQuests);
  }

  Future<void> _finish() async {
    if (!mounted || _finishing) return;
    _finishing = true;
    final services = _services;
    final summary = _engine.summary();
    services.music.jingle(summary.won ? 'victory' : 'defeat');
    final latest = await services.repository.load();
    final result = widget.trial
        // 練習（確認用・定期テストの海・試験対策）では経験値を出さない
        ? StageClearResult(
            expResult: Progression.addExp(latest, 0),
            firstClear: false,
            newlyUnlockedStageId: null,
          )
        : widget.ghost
        ? StageClearResult(
            expResult: Progression.applyGhostBattle(latest, summary),
            firstClear: false,
            newlyUnlockedStageId: null,
          )
        : Progression.applyBattle(
            progress: latest,
            world: widget.world,
            stage: widget.stage,
            summary: summary,
          );
    if (!widget.trial) await services.repository.save(result.progress);
    var saved = result.progress;
    // 必殺技を決めたことを記録する（実績「必殺の一撃」）
    if (summary.turns.any((t) => t.special)) {
      final latestNow = await services.repository.load();
      saved = latestNow.copyWith(
        fieldFlags: {...latestNow.fieldFlags, VersusRecords.specialHit},
      );
      await services.repository.save(saved);
    }
    await _commitMeta(summary, saved);
    widget.onFinished?.call(summary);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => ResultScreen(
          skillBefore: _skillBefore,
          skillAfter: _skillOf(services.meta.record),
          stage: widget.stage,
          enemy: _engine.enemy,
          summary: summary,
          result: result,
          ghost: widget.ghost,
        ),
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
          final shake = MediaQuery.of(context).disableAnimations
              ? 0.0
              : sin(v * pi * 7) * 9 * (1 - v);
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
              if (_bossBanner) const IgnorePointer(child: _BossBanner()),
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
                if (q.source.passage != null)
                  Expanded(flex: 6, child: _readingArea(q.source.passage!))
                else
                  Expanded(flex: 5, child: _enemyArea()),
                _timerBar(),
                Expanded(
                  flex: q.source.passage != null ? 7 : 6,
                  child: _questionArea(q),
                ),
                _playerBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final enemy = _engine.enemy;
    final back = _engine.backEnemy;
    final rush = _engine.lineup.length > 1;
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
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (enemy.weakness != null)
                      _Tag(
                        '弱点：${enemy.weakness!.label}',
                        const Color(0xFF2E9E5B),
                      ),
                    if (_engine.armor > 0 && enemy.armorCategory != null)
                      _Tag(
                        '装甲×${_engine.armor}（${enemy.armorCategory!.label}で割れる）',
                        const Color(0xFF2E7DB5),
                      ),
                    if (_engine.ability != EnemyAbility.none)
                      _Tag(
                        _engine.guardUp
                            ? '${_engine.ability.label}：守り中（弱点で解ける）'
                            : _engine.ability.label,
                        const Color(0xFF8D5A3B),
                      ),
                    if (_engine.bossRule == BossRule.trial)
                      _Tag(
                        '試練 ${_engine.trialAnswered}/${_engine.trialWindow}問（正解${_engine.trialCorrect}・${_engine.trialNeed}問で大技）',
                        TsuzuriColors.stamp,
                      )
                    else if (_engine.bossRule == BossRule.finale)
                      _Tag(
                        '決戦：${_engine.finaleFocus?.label ?? '総合'}の問題が中心',
                        TsuzuriColors.stamp,
                      )
                    else if (_engine.bossRule == BossRule.chain3)
                      const _Tag('3連続正解で大技', TsuzuriColors.stamp),
                    if (rush)
                      _Tag(
                        'ボス連戦 ${_engine.front + 1} / ${_engine.lineup.length}体目',
                        TsuzuriColors.stamp,
                      ),
                    if (back != null)
                      _Tag(
                        '後ろに${back.name}（HP ${_engine.backEnemyHp}）',
                        const Color(0xFF6A4BA8),
                      ),
                    if (widget.progress.springBuff && !widget.ghost)
                      const _Tag('泉の加護 HP+30%', Color(0xFF3B8FB5)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'にげる',
            onPressed: _finishing ? null : _confirmFlee,
            icon: Icon(Icons.directions_run, color: TsuzuriColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _enemyArea() {
    return LayoutBuilder(
      builder: (context, box) {
        final size = min(box.maxWidth * 0.62, box.maxHeight * 0.92);
        final shown = _fallen ?? _engine.enemy;
        final back = _fallen == null ? _engine.backEnemy : null;
        return Stack(
          alignment: Alignment.center,
          children: [
            // 地形ごとの舞台（ノートに貼った絵）
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 6, 10, 2),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, _) => CustomPaint(
                      painter: BattleBackdropPainter(
                        _terrain,
                        _idle.value * 120,
                        boss: widget.stage.isBoss && !widget.ghost,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 乱入してきたボス（前のボスの後ろに重なって控える）
            if (back != null)
              Align(
                alignment: const Alignment(0.85, -0.6),
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (context, _) => Opacity(
                    opacity: 0.8,
                    child: SizedBox.square(
                      dimension: size * 0.62,
                      child: CustomPaint(
                        painter: _EnemyPainter(back, _idle.value * 120 + 3),
                      ),
                    ),
                  ),
                ),
              ),
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
                              shown,
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
            // 当たったときの火花
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, _) => SizedBox.square(
                  dimension: size * 1.2,
                  child: CustomPaint(
                    painter: _BurstPainter(
                      _burst.value,
                      _burstColor,
                      big: _last?.quick ?? false,
                    ),
                  ),
                ),
              ),
            ),
            // クリティカル・大技の白い光
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flash,
                builder: (_, _) => _flash.value == 0 || _flash.value == 1
                    ? const SizedBox.shrink()
                    : Container(
                        color: Colors.white.withValues(
                          alpha: 0.55 * (1 - _flash.value),
                        ),
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
            if (_speech != null)
              Align(
                alignment: const Alignment(0, -0.95),
                child: _SpeechBubble(text: _speech!),
              ),
          ],
        );
      },
    );
  }

  /// 長文の巻物。右上に小さく敵がいて、正解すると攻撃が当たる。
  Widget _readingArea(Passage passage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 4, 12, 4),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: TsuzuriColors.tint(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC9A96E), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Scrollbar(
              child: ListView(
                key: PageStorageKey(passage.id),
                padding: const EdgeInsets.fromLTRB(14, 12, 72, 14),
                children: [
                  Text(
                    '📜 ${passage.title}',
                    style: serif(15, color: TsuzuriColors.accent),
                  ),
                  const SizedBox(height: 8),
                  for (final (i, p) in passage.paragraphs.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '[${i + 1}] ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: TsuzuriColors.accent,
                              ),
                            ),
                            TextSpan(text: p),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: TsuzuriColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 右上の小さな敵（攻撃が当たるとゆれて光る）
          Positioned(
            right: 4,
            top: 4,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _enemyHit, _defeat]),
              builder: (context, _) {
                final hit = _enemyHit.value;
                final d = _defeat.value;
                return Opacity(
                  opacity: 1 - d,
                  child: Transform.translate(
                    offset: Offset(sin(hit * pi * 6) * 6 * (1 - hit), 0),
                    child: SizedBox.square(
                      dimension: 64,
                      child: CustomPaint(
                        painter: _EnemyPainter(
                          _fallen ?? _engine.enemy,
                          _idle.value * 120,
                          flash: hit > 0 && hit < 1 ? (1 - hit) : 0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          for (final p in _popups.where((p) => !p.onPlayer))
            Align(
              key: p.key,
              alignment: const Alignment(0.75, -0.55),
              child: _PopupText(popup: p),
            ),
        ],
      ),
    );
  }

  Widget _timerBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 4, 16, 4),
      child: AnimatedBuilder(
        animation: _timer,
        builder: (_, _) {
          final left = 1 - _timer.value;
          final limit = _engine.limitFor(
            _last?.question ?? _engine.currentQuestion,
          );
          final secs = (limit.inSeconds * left).ceil();
          return Row(
            children: [
              Icon(
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
                    backgroundColor: TsuzuriColors.tint(0xFFEDE3D1),
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
            if (!showExplanation) _cardHand(),
            const SizedBox(height: 6),
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

  /// 必殺技を構える
  void _armSpecial() {
    if (_locked || !_engine.specialReady) return;
    _engine.armSpecial();
    _services.music.se('se_magic');
    _popup(
      _Popup(
        '必殺技の構え！ 次に正解すると${BattleEngine.specialRate}倍！',
        const Color(0xFFD64545),
        const Alignment(0, -0.35),
      ),
    );
    setState(() {});
  }

  /// 必殺技ゲージのボタン
  Widget _specialButton() {
    final ready = _engine.specialReady && !_locked;
    final armed = _engine.specialArmed;
    final v = _engine.special / 100;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: ready ? _armSpecial : null,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, _) {
            final glow = ready || armed
                ? 0.5 + 0.5 * sin(_idle.value * 120 * 6)
                : 0.0;
            return Container(
              width: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: armed
                      ? const Color(0xFFD64545)
                      : ready
                      ? const Color(0xFFF2B84B)
                      : TsuzuriColors.kraft,
                  width: 2,
                ),
                boxShadow: [
                  if (ready || armed)
                    BoxShadow(
                      color: const Color(0xFFF2B84B)
                          .withValues(alpha: 0.5 * glow),
                      blurRadius: 10,
                    ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [v, v],
                  colors: [
                    armed
                        ? TsuzuriColors.tint(0xFFFFCDD2)
                        : TsuzuriColors.tint(0xFFFFE9A8),
                    TsuzuriColors.card,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                armed
                    ? '構え中'
                    : ready
                    ? '必殺技！'
                    : '必殺 ${_engine.special}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: ready || armed
                      ? const Color(0xFFB23A48)
                      : TsuzuriColors.inkSoft,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 手札（回答前にタップすると、この問題に効果がつく）と、必殺技ゲージ
  Widget _cardHand() {
    final pending = _engine.pendingCard;
    final canUse = !_locked && pending == null && !_engine.isOver;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            if (pending == null && _engine.hand.isEmpty) const Spacer(),
            if (pending != null)
              Expanded(
                child: _CardChip(card: pending, active: true, onTap: null),
              )
            else
              for (final (i, card) in _engine.hand.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _CardChip(
                      card: card,
                      active: false,
                      onTap: canUse ? () => _useCard(i) : null,
                    ),
                  ),
                ),
            _specialButton(),
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
        border: Border.all(color: TsuzuriColors.tint(0xFFE0D4C0)),
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
              style: TextStyle(
                fontSize: 11,
                color: TsuzuriColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q.source.prompt,
            style: TextStyle(fontSize: 14, color: TsuzuriColors.inkSoft),
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
    // 長文や、選択肢が長い問題（理科の説明文など）は縦に並べて全文を見せる
    final reading =
        q.source.passage != null || q.choices.any((c) => c.length > 12);
    Widget choice(int i) {
      // ひらめきの栞で消えた選択肢
      if (last == null && _engine.hiddenChoices.contains(i)) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TsuzuriColors.tint(0xFFE0D4C0)),
              ),
              child: const Center(
                child: Text('✕', style: TextStyle(color: Color(0xFFCBBFAA))),
              ),
            ),
          ),
        );
      }
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
                      textAlign: reading ? TextAlign.left : TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: reading ? 13 : 16,
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

    if (reading) {
      // 長文の選択肢は長いので縦に並べる
      return Column(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [choice(i)],
              ),
            ),
        ],
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
        color: TsuzuriColors.tint(0xFFFFF4F0),
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
                [
                  q.source.hasMoreExplanation
                      ? '${q.source.shortExplanation}\n📓 くわしい解説は復習手帳に書きこんだよ'
                      : q.source.shortExplanation,
                  if (q.source.commonMistakes.isNotEmpty)
                    '⚠ よくあるまちがい：${q.source.commonMistakes.join('／')}',
                  if (q.source.hint != null) '💡 ヒント：${q.source.hint}',
                ].join('\n'),
                style: TextStyle(
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
                  max: _engine.maxHp,
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

/// 小さなラベル（弱点・装甲など）
class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.6)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// 手札のカード
class _CardChip extends StatelessWidget {
  const _CardChip({required this.card, required this.active, this.onTap});
  final CardDef card;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rare = card.rarity == CardRarity.rare;
    final color = rare ? const Color(0xFF6A4BA8) : TsuzuriColors.accent;
    return Tooltip(
      message: card.description,
      child: Material(
        color: active
            ? color.withValues(alpha: 0.18)
            : (rare ? TsuzuriColors.tint(0xFFF3EEFB) : TsuzuriColors.card),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: active ? 2 : 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                active ? '${card.name}：${card.description}' : card.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: onTap == null && !active
                      ? color.withValues(alpha: 0.45)
                      : color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 敵のセリフの吹き出し
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.6, end: 1),
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutBack,
    builder: (_, v, child) => Transform.scale(scale: v, child: child),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TsuzuriColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TsuzuriColors.ink, width: 1.4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: serif(13.5, color: TsuzuriColors.ink),
      ),
    ),
  );
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
            Text(
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
                  color: TsuzuriColors.tint(0xFFEDE3D1),
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
            // 計算の誤差でわずかにマイナスになることがあるので、0〜1 におさめる
            opacity: (v < 0.7 ? 1.0 : 1 - (v - 0.7) / 0.3).clamp(0.0, 1.0),
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
  _EnemyPainter(this.enemy, this.t, {this.flash = 0});
  final EnemyDef enemy;
  final double t;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (flash <= 0) {
      paintEnemy(canvas, s, enemy.look, t, color: enemy.color);
      return;
    }
    // 攻撃が当たった瞬間に白く光らせる
    canvas.saveLayer(Offset.zero & size, Paint());
    paintEnemy(canvas, s, enemy.look, t, color: enemy.color);
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
/// 当たったときに飛びちる火花（星と線）
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.v, this.color, {this.big = false});
  final double v;
  final Color color;
  final bool big;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0 || v >= 1) return;
    final c = size.center(Offset.zero);
    final n = big ? 16 : 10;
    final reach = size.shortestSide * (big ? 0.5 : 0.38);
    final ease = Curves.easeOutCubic.transform(v);
    final fade = (1 - v).clamp(0.0, 1.0);
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * pi + (i.isEven ? 0.15 : -0.1);
      final len = reach * (i.isEven ? 1.0 : 0.72);
      final start = c + Offset(cos(a), sin(a)) * len * ease * 0.45;
      final end = c + Offset(cos(a), sin(a)) * len * ease;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: fade)
          ..strokeWidth = big ? 4 : 3
          ..strokeCap = StrokeCap.round,
      );
      if (i % 3 == 0) {
        _star(
          canvas,
          end,
          (big ? 7 : 5) * fade + 1,
          color.withValues(alpha: fade),
        );
      }
    }
    // 中心の輪
    canvas.drawCircle(
      c,
      reach * 0.35 * ease,
      Paint()
        ..color = color.withValues(alpha: fade * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * fade + 0.5,
    );
  }

  void _star(Canvas canvas, Offset o, double r, Color color) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final rr = i.isEven ? r : r * 0.4;
      final pt = o + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.v != v;
}

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

/// ボス登場の演出
class _BossBanner extends StatelessWidget {
  const _BossBanner();

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, v, _) => Container(
        color: Colors.black.withValues(alpha: 0.35 * v),
        alignment: Alignment.center,
        child: Transform.scale(
          scale: 0.7 + 0.3 * v,
          child: Opacity(
            opacity: v,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1F1F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TsuzuriColors.exp, width: 2),
              ),
              child: Text(
                'BOSS BATTLE',
                style: serif(26, color: TsuzuriColors.exp),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
