import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../audio/music_director.dart';
import '../audio/music_scope.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../main.dart' show routeObserver;
import '../study/inn_screen.dart';
import '../art/enemy_painter.dart';
import '../art/hero_painter.dart';
import '../battle/battle_screen.dart';
import '../battle/deck_screen.dart';
import '../study/review_notebook_screen.dart';
import 'field_game.dart';
import 'field_map.dart';

/// ワールドの中を歩き回る画面
class FieldScreen extends StatefulWidget {
  const FieldScreen({
    super.key,
    required this.world,
    required this.progress,
    String? mapId,
    this.from,
    this.exam,
  }) : mapId = mapId ?? '';

  /// 試験対策ワールドのフィールド（6教科を混ぜたエリアを1本の冒険にする）
  factory FieldScreen.exam({
    Key? key,
    required ExamWorldPlan plan,
    required RpgProgress progress,
  }) => FieldScreen(
    key: key,
    world: WorldDef(
      id: 'exam_${plan.id}',
      name: plan.title,
      subject: plan.subjectsLabel,
      status: WorldStatus.available,
      isFree: true,
      stages: ExamWorlds.build(plan),
    ),
    progress: progress,
    exam: plan,
  );

  final WorldDef world;
  final RpgProgress progress;

  /// 試験対策ワールドのとき、そのプラン
  final ExamWorldPlan? exam;

  /// 表示するマップ（空ならそのワールドの最初のマップ）
  final String mapId;

  /// 出入口から来たときの、前のマップ
  final String? from;

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}

sealed class _Dialog {}

class _EncounterDialog extends _Dialog {
  _EncounterDialog(this.stage, this.cleared);
  final StageDef stage;
  final bool cleared;
}

class _InnDialog extends _Dialog {
  _InnDialog(this.stage);
  final StageDef stage;
}

class _MessageDialog extends _Dialog {
  _MessageDialog(this.text);
  final String text;
}

class _ChestDialog extends _Dialog {
  _ChestDialog(this.stage, this.chestId);
  final StageDef stage;
  final String chestId;
}

class _SpringDialog extends _Dialog {
  _SpringDialog(this.stage);
  final StageDef stage;
}

class _DoorDialog extends _Dialog {
  _DoorDialog(this.stage, this.cell);
  final StageDef stage;
  final Cell cell;
}

class _WarpDialog extends _Dialog {
  _WarpDialog(this.cell);
  final Cell cell;
}

class _GhostDialog extends _Dialog {
  _GhostDialog(this.stage, this.count);
  final StageDef stage;
  final int count;
}

/// 宝箱・泉で出す、その場で解く小さなクイズ
class _QuizDialog extends _Dialog {
  _QuizDialog(this.title, this.questions, this.onDone);
  final String title;
  final List<QuizQuestion> questions;
  final void Function(int correct) onDone;
}

/// 亡霊の見た目（ダイアログの絵用）
const _ghostLook = EnemyDef(
  id: 'ghost',
  name: '亡霊',
  maxHp: 1,
  attack: 1,
  look: 'ghost',
);

class _FieldScreenState extends State<FieldScreen> with RouteAware {
  late RpgProgress _progress = widget.progress;

  /// 試験対策ワールドのプラン（クリア数・ゲージ・開けた宝箱は、ここに記録する）
  late ExamWorldPlan? _plan = widget.exam;
  bool get _isExam => widget.exam != null;

  late final FieldGame _game = FieldGame(
    map: _isExam
        ? FieldMap.forExam(widget.exam!, widget.world.stages)
        : FieldMap.byId(
            widget.mapId.isEmpty
                ? FieldMap.firstMapOf(widget.world.id)
                : widget.mapId,
          ),
    from: widget.from,
    onPortal: _travel,
    rpgWorld: widget.world,
    progress: widget.progress,
    isCleared: _isExam ? (_, s) => _examCleared(s) : null,
    chestOpened: _isExam
        ? (_, id) => _plan?.openedChests.contains(id) ?? false
        : null,
    onSecret: _revealSecret,
    onDoor: (stage, cell) => _open(_DoorDialog(stage, cell)),
    onWarp: _touchWarp,
    onEncounter: (stage, cleared) => _open(_EncounterDialog(stage, cleared)),
    onMessage: (text) => _open(_MessageDialog(text)),
    onInn: (stage) => _open(_InnDialog(stage)),
    onChest: (stage, id, opened) =>
        _open(opened ? _MessageDialog('宝箱はもう空っぽだ。') : _ChestDialog(stage, id)),
    onSpring: (stage) => _open(
      _progress.springBuff
          ? _MessageDialog('泉の加護が、もう体をつつんでいる。（次のバトルで最大HP+30%）')
          : _SpringDialog(stage),
    ),
    onGhost: (stage, count) => _open(_GhostDialog(stage, count)),
  );
  final _random = Random();
  _Dialog? _dialog;
  bool _starting = false;

  /// エリアに入ったときに出す見出し
  String? _banner;
  String _bannerTheme = '';
  bool _bannerBoss = false;
  int _bannerSerial = 0;

  @override
  void initState() {
    super.initState();
    _game.areaNo.addListener(_onAreaChanged);
  }

  void _onAreaChanged() {
    final no = _game.areaNo.value;
    final label = _game.map.areaLabels[no];
    if (label == null || !mounted) return;
    final serial = ++_bannerSerial;
    setState(() {
      _banner = label;
      _bannerTheme = _game.map.areaThemes[no] ?? '';
      _bannerBoss = _game.map.bossAreas.contains(no);
    });
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && serial == _bannerSerial) setState(() => _banner = null);
    });
  }

  /// 試験対策ワールドで、そのステージ（強敵をふくむ）をクリアしたか
  bool _examCleared(StageDef s) {
    final plan = _plan;
    if (plan == null) return false;
    if (Elites.isElite(s.id)) return plan.openedChests.contains(s.id);
    return s.order <= plan.clearedCount;
  }

  /// 試験対策ワールドの記録を保存する
  Future<void> _saveExam(ExamWorldPlan plan) async {
    await RpgServices.of(context).examWorlds.update(plan);
    if (!mounted) return;
    setState(() => _plan = plan);
    _game.applyProgress(_progress);
  }

  /// 宿・宝箱などで使う、もとの教科のエリア（試験対策ワールドのとき）
  StageDef _source(StageDef stage) {
    final plan = _plan;
    if (plan == null) return stage;
    final base = Elites.baseId(stage.id);
    final i = widget.world.stages.indexWhere((s) => s.id == base);
    if (i < 0 || plan.stageIds.isEmpty) return stage;
    final id = plan.stageIds[i.clamp(0, plan.stageIds.length - 1)];
    return ExamWorlds.stageById(id) ?? stage;
  }

  /// キーボード操作用。バトルから戻ったときやダイアログを閉じたときに取り戻す
  final _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _focus.dispose();
    super.dispose();
  }

  /// バトル・結果画面を閉じて、フィールドが一番手前に戻ったとき
  @override
  void didPopNext() => _refreshAfterBattle();

  Future<void> _refreshAfterBattle() async {
    final services = RpgServices.of(context);
    final updated = await services.repository.load();
    if (!mounted) return;
    setState(() {
      _progress = updated;
      if (_plan != null) _plan = services.examWorlds.byId(_plan!.id) ?? _plan;
    });
    _game.applyProgress(updated);
    _game.inputLocked = false;
    _focus.requestFocus();
  }

  void _open(_Dialog d) {
    _game.inputLocked = true;
    _game.padDirection = null;
    setState(() => _dialog = d);
  }

  void _close() {
    _game.inputLocked = false;
    setState(() => _dialog = null);
    _focus.requestFocus();
  }

  Future<void> _startBattle(StageDef stage) async {
    if (_starting) return;
    _starting = true;
    final services = RpgServices.of(context);
    final set = await services.loadStagePool(stage);
    if (!mounted) return;
    _starting = false;
    if (set == null) {
      _open(_MessageDialog('このステージの問題はまだ準備中です。'));
      return;
    }
    // RPG には自作の問題だけを使う（取り込んだ市販教材などは使わない）
    if (!set.origin.usableInRpg) {
      _open(_MessageDialog('この問題セットは RPG では使えません。'));
      return;
    }
    _close();
    _game.inputLocked = true;
    final plan = _plan;
    // 戻ってきたときの処理は didPopNext で行う（結果画面へは差し替えで進むため、
    // ここで push の完了を待つと結果画面を閉じる前に戻り処理が走ってしまう）
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => plan == null
            ? BattleScreen(
                world: widget.world,
                stage: stage,
                questions: set.questions,
                progress: _progress,
              )
            : _examBattle(plan, stage, set.questions),
        transitionsBuilder: (_, anim, _, child) =>
            _BattleTransition(animation: anim, child: child),
      ),
    );
  }

  /// 試験対策ワールドのバトル（定期テストの海と同じ「とても難しい」強さ。RPG の進行は変えない）
  Widget _examBattle(
    ExamWorldPlan plan,
    StageDef stage,
    List<QuizQuestion> questions,
  ) {
    final elite = Elites.isElite(stage.id);
    final index = widget.world.stages.indexWhere(
      (s) => s.id == Elites.baseId(stage.id),
    );
    final hard = ExamWorlds.build(plan, level: _progress.level)[index];
    final services = RpgServices.of(context);
    return BattleScreen(
      world: RpgCatalog.world(hard.worldId),
      stage: elite ? Elites.of(hard) : hard,
      questions: questions,
      progress: _progress,
      trial: true,
      mode: BattleMode.exam,
      onFinished: (summary) {
        if (!summary.won) return;
        final latest = services.examWorlds.byId(plan.id);
        if (latest == null) return;
        if (elite) {
          if (latest.openedChests.contains(stage.id)) return;
          services.examWorlds.update(
            latest
                .copyWith(openedChests: {...latest.openedChests, stage.id})
                .addGauge(5),
          );
          return;
        }
        if (latest.clearedCount > index) return;
        services.examWorlds.update(
          latest
              .copyWith(clearedCount: index + 1)
              .addGauge(hard.isBoss ? 15 : 6),
        );
      },
    );
  }

  /// 隠し通路を調べた
  Future<void> _revealSecret(Cell cell) async {
    final key = FieldGame.openKey(_game.map.id, cell);
    await _save(_progress.copyWith(fieldFlags: {..._progress.fieldFlags, key}));
    if (!mounted) return;
    _open(_MessageDialog('よく見ると、ひびが入っている…。押してみると、奥へ続く隠し通路が現れた！'));
  }

  /// 知識の扉：その先のエリアの問題1問に正解すると開く（まちがえても何度でも挑戦できる）
  Future<void> _tryDoor(StageDef stage, Cell cell) async {
    final qs = await _pick(_source(stage), 1, (q) => true);
    if (!mounted || qs.isEmpty) return;
    _open(
      _QuizDialog('知識の扉：${_source(stage).grammarTheme}', qs, (correct) async {
        if (correct == 1) {
          final key = FieldGame.openKey(_game.map.id, cell);
          await _save(
            _progress.copyWith(fieldFlags: {..._progress.fieldFlags, key}),
          );
          if (!mounted) return;
          _open(_MessageDialog('ゴゴゴ…知識の扉が開いた！'));
        } else {
          _open(_MessageDialog('扉はびくともしない…。「封印が強くなった……」\n解説を読んで、もう一度挑戦しよう。'));
        }
      }),
    );
  }

  /// ワープ石にさわった（はじめてなら記録して、ほかの石へ飛べるようにする）
  Future<void> _touchWarp(Cell cell) async {
    final key = FieldGame.warpKey(_game.map.id, cell);
    if (!_progress.fieldFlags.contains(key)) {
      await _save(
        _progress.copyWith(fieldFlags: {..._progress.fieldFlags, key}),
      );
      if (!mounted) return;
    }
    _open(_WarpDialog(cell));
  }

  /// 出入口を通って別のマップへ移動する
  void _travel(Portal portal) {
    _game.inputLocked = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => MusicScope(
          music: MusicDirector.fieldKey(widget.world.id),
          child: FieldScreen(
            world: widget.world,
            progress: _progress,
            mapId: portal.target,
            from: _game.map.id,
          ),
        ),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  /// 進行状況を保存して、フィールドにも反映する
  Future<void> _save(RpgProgress p) async {
    await RpgServices.of(context).repository.save(p);
    if (!mounted) return;
    setState(() => _progress = p);
    _game.applyProgress(p);
  }

  /// その先のステージの問題から、条件に合うものを [n] 問えらぶ（長文は除く）
  Future<List<QuizQuestion>> _pick(
    StageDef stage,
    int n,
    bool Function(QuizQuestion q) where,
  ) async {
    final set = await RpgServices.of(context).loadStagePool(stage);
    if (set == null || !set.origin.usableInRpg) return [];
    final pool = set.questions.where((q) => q.passage == null).toList();
    var picked = pool.where(where).toList();
    if (picked.length < n) picked = pool;
    picked.shuffle(_random);
    return picked.take(n).toList();
  }

  Future<void> _tryChest(StageDef stage, String chestId) async {
    final qs = await _pick(
      _source(stage),
      1,
      (q) => q.category == QuestionCategory.usage,
    );
    if (!mounted || qs.isEmpty) return;
    final plan = _plan;
    if (plan != null) {
      _open(
        _QuizDialog('知識の封印', qs, (correct) async {
          final latest =
              RpgServices.of(context).examWorlds.byId(plan.id) ?? plan;
          final opened = latest.copyWith(
            openedChests: {...latest.openedChests, chestId},
          );
          await _saveExam(correct == 1 ? opened.addGauge(5) : opened);
          if (!mounted) return;
          _open(
            _MessageDialog(
              correct == 1
                  ? '封印がとけた！ 宝箱の中には「要点メモ」。テスト対策ゲージが 5 たまった。'
                  : '「封印が強くなった……」宝箱は砂になって消えてしまった。解説を読んでおこう。',
            ),
          );
        }),
      );
      return;
    }
    _open(
      _QuizDialog('知識の封印', qs, (correct) async {
        final (updated, card) = Progression.openChest(
          _progress,
          chestId,
          correct == 1,
          _random,
        );
        await _save(updated);
        if (!mounted) return;
        _open(
          _MessageDialog(
            card == null
                ? 'カチッ…鍵が合わなかった。宝箱は砂になって消えてしまった…'
                : '宝箱が開いた！ レアカード「${card.name}」を手に入れた！\n${card.description}',
          ),
        );
      }),
    );
  }

  Future<void> _trySpring(StageDef stage) async {
    final qs = await _pick(
      _source(stage),
      3,
      (q) => q.category == QuestionCategory.meaning,
    );
    if (!mounted || qs.isEmpty) return;
    _open(
      _QuizDialog('泉のささやき：基礎の3問', qs, (correct) async {
        if (correct == qs.length) {
          await _save(Progression.blessSpring(_progress));
          final plan = _plan;
          if (plan != null && mounted) {
            final latest =
                RpgServices.of(context).examWorlds.byId(plan.id) ?? plan;
            await _saveExam(latest.addGauge(2));
          }
          if (!mounted) return;
          _open(_MessageDialog('泉が光った！ 次のバトルで最大HPが30%ふえる。'));
        } else {
          _open(_MessageDialog('泉の水がにごってしまった…。全問正解で加護がもらえる。また来よう。'));
        }
      }),
    );
  }

  Future<void> _startGhost(StageDef stage) async {
    if (_starting) return;
    _starting = true;
    final set = await RpgServices.of(context).loadStagePool(stage);
    _starting = false;
    if (!mounted || set == null) return;
    final ids = {
      for (final e in _progress.mistakes.entries)
        if (e.value == stage.id) e.key,
    };
    final questions = set.questions.where((q) => ids.contains(q.id)).toList();
    if (questions.isEmpty) {
      _open(_MessageDialog('亡霊は消えてしまったようだ。'));
      return;
    }
    _close();
    _game.inputLocked = true;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => BattleScreen(
          world: widget.world,
          stage: stage,
          questions: questions,
          progress: _progress,
          ghost: true,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            _BattleTransition(animation: anim, child: child),
      ),
    );
  }

  void _openPage(Widget page) {
    _game.inputLocked = true;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final stats = PlayerStats.forLevel(_progress.level);
    final cleared = widget.world.stages
        .where(
          (s) => _isExam
              ? _examCleared(s)
              : _progress.clearedStageIds.contains(s.id),
        )
        .length;
    final plan = _plan;
    return Scaffold(
      backgroundColor: TsuzuriColors.kraft,
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(game: _game, focusNode: _focus),
          ),
          // 上部の情報バー
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.map_outlined,
                      tooltip: 'ワールドマップへ',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _game.area,
                        builder: (context, area, _) => _Hud(
                          title: '${widget.world.name}・$area',
                          level: stats.level,
                          exp: _progress.exp,
                          expToNext: PlayerStats.expToNextLevel(stats.level),
                          stars: plan == null
                              ? '★ $cleared / ${widget.world.stages.length}'
                              : '★ $cleared / ${widget.world.stages.length}　対策ゲージ ${plan.gauge}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // エリアに入ったときの見出し
          Positioned(
            top: 90,
            left: 24,
            right: 24,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _banner == null ? 0 : 1,
                duration: const Duration(milliseconds: 350),
                child: _AreaBanner(
                  title: _banner ?? '',
                  theme: _bannerTheme,
                  boss: _bannerBoss,
                ),
              ),
            ),
          ),
          // 復習手帳・デッキ
          if (_dialog == null)
            Positioned(
              right: 10,
              bottom: 24,
              child: SafeArea(
                child: Column(
                  children: [
                    _RoundButton(
                      icon: Icons.menu_book,
                      tooltip: '復習手帳（${_progress.mistakes.length}）',
                      onTap: () => _openPage(
                        ReviewNotebookScreen(
                          world: widget.world,
                          progress: _progress,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RoundButton(
                      icon: Icons.style,
                      tooltip: 'デッキと仲間',
                      onTap: () => _openPage(DeckScreen(progress: _progress)),
                    ),
                  ],
                ),
              ),
            ),
          // 十字ボタン
          if (_dialog == null)
            Positioned(
              left: 16,
              bottom: 24,
              child: SafeArea(child: _DPad(game: _game)),
            ),
          if (_dialog != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: SafeArea(child: _buildDialog(_dialog!)),
            ),
        ],
      ),
    );
  }

  Widget _buildDialog(_Dialog d) {
    switch (d) {
      case _MessageDialog(:final text):
        return _MessageBox(
          actions: [FilledButton(onPressed: _close, child: const Text('とじる'))],
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.6)),
        );
      case _InnDialog(:final stage):
        final lesson = InnLessons.forStage(_source(stage).id);
        return _MessageBox(
          actions: [
            TextButton(onPressed: _close, child: const Text('やめておく')),
            FilledButton.icon(
              onPressed: () {
                _close();
                _game.inputLocked = true;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InnScreen(stage: _source(stage)),
                  ),
                );
              },
              icon: const Icon(Icons.school, size: 18),
              label: const Text('授業を受ける'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('宿屋', style: serif(16)),
              const SizedBox(height: 4),
              Text(
                '${lesson.teacher}「この先の${stage.enemy.name}は「${lesson.title}」が弱点じゃ。授業を受けていくかね？」',
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        );
      case _ChestDialog(:final stage, :final chestId):
        return _MessageBox(
          actions: [
            TextButton(onPressed: _close, child: const Text('やめておく')),
            FilledButton.icon(
              onPressed: () => _tryChest(stage, chestId),
              icon: const Icon(Icons.key, size: 18),
              label: const Text('鍵をあける'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔒 知識の封印', style: serif(16)),
              const SizedBox(height: 4),
              Text(
                _isExam
                    ? 'この宝箱を開けるには問題に答えよう！\n正解すればテスト対策ゲージがたまる。まちがえると宝箱は消えてしまう…（1回きり）'
                    : 'この宝箱を開けるには問題に答えよう！\n正解すればレアカードが手に入る。まちがえると「封印が強くなり」、宝箱は消えてしまう…（1回きり）',
                style: const TextStyle(fontSize: 13.5, height: 1.6),
              ),
            ],
          ),
        );
      case _SpringDialog(:final stage):
        return _MessageBox(
          actions: [
            TextButton(onPressed: _close, child: const Text('やめておく')),
            FilledButton.icon(
              onPressed: () => _trySpring(stage),
              icon: const Icon(Icons.water_drop, size: 18),
              label: const Text('泉の問いに答える'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ふしぎな泉', style: serif(16)),
              const SizedBox(height: 4),
              const Text(
                '基礎の単語を3問。全問正解すると、次のバトルで最大HPが30%ふえる。\n何度でも挑戦できる。',
                style: TextStyle(fontSize: 13.5, height: 1.6),
              ),
            ],
          ),
        );
      case _DoorDialog(:final stage, :final cell):
        return _MessageBox(
          actions: [
            TextButton(onPressed: _close, child: const Text('やめておく')),
            FilledButton.icon(
              onPressed: () => _tryDoor(stage, cell),
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('問いに答える'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('知識の扉', style: serif(16)),
              const SizedBox(height: 4),
              Text(
                '扉に文字がきざまれている。「${_source(stage).grammarTheme}」の問いに正解すると開くらしい。\n奥に何かがありそうだ。（何度でも挑戦できる）',
                style: const TextStyle(fontSize: 13.5, height: 1.6),
              ),
            ],
          ),
        );
      case _WarpDialog(:final cell):
        final stones = _game.activeWarps.where((c) => c != cell).toList();
        return _MessageBox(
          actions: [FilledButton(onPressed: _close, child: const Text('とじる'))],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ワープ石', style: serif(16)),
              const SizedBox(height: 4),
              Text(
                stones.isEmpty
                    ? 'ワープ石が青く光った。ほかのエリアのワープ石にもさわると、ここから一瞬で行き来できる。'
                    : 'どのワープ石へ飛ぶ？',
                style: const TextStyle(fontSize: 13.5, height: 1.6),
              ),
              for (final c in stones)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _close();
                      _game.warpTo(c);
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(_game.map.labelAt(c.col, c.row)),
                  ),
                ),
            ],
          ),
        );
      case _GhostDialog(:final stage, :final count):
        return _MessageBox(
          portrait: _ghostLook,
          actions: [
            TextButton(onPressed: _close, child: const Text('あとで')),
            FilledButton.icon(
              onPressed: () => _startGhost(stage),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('再戦する'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('亡霊がさまよっている…', style: serif(16)),
              const SizedBox(height: 4),
              Text(
                '「${stage.name}」でまちがえた$count問のなごり。\n正解すると成仏して、経験値がもらえる。',
                style: const TextStyle(fontSize: 13.5, height: 1.6),
              ),
            ],
          ),
        );
      case _QuizDialog(:final title, :final questions, :final onDone):
        return _MessageBox(
          actions: const [],
          child: _MiniQuiz(
            key: ObjectKey(d),
            title: title,
            questions: questions,
            onDone: onDone,
          ),
        );
      case _EncounterDialog(:final stage, :final cleared):
        final enemy = stage.enemy;
        return _MessageBox(
          portrait: enemy,
          actions: [
            TextButton(onPressed: _close, child: const Text('にげる')),
            FilledButton.icon(
              onPressed: () => _startBattle(stage),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(cleared ? 'もう一度たたかう' : 'たたかう'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${RpgCatalog.stageLabel(stage)}「${stage.name}」',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cleared
                    ? '${enemy.name}「また挑戦するのかい？」'
                    : '${enemy.name}が道をふさいでいる！',
                style: serif(16),
              ),
              const SizedBox(height: 4),
              Text(
                '${enemy.description}\n${RpgCatalog.themeLabel(stage)}\nHP ${enemy.maxHp}・推奨Lv${stage.recommendedLevel}・1問${stage.timeLimitSeconds}秒'
                '${enemy.weakness != null ? '\n弱点：${enemy.weakness!.label}の問題（ダメージ1.5倍）' : ''}'
                '${enemy.armor > 0 ? '\n装甲×${enemy.armor}：${enemy.armorCategory!.label}の問題で割れる' : ''}'
                '${enemy.effectiveAbility != EnemyAbility.none ? '\n${enemy.effectiveAbility.label}：${enemy.effectiveAbility.description}' : ''}'
                '${BossRules.of(stage) != BossRule.none ? '\n★${BossRules.of(stage).label}：${BossRules.of(stage).description}' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: TsuzuriColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// バトル開始時の演出（ノートのページがめくれるように縦に広がる）
class _BattleTransition extends StatelessWidget {
  const _BattleTransition({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => Stack(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: curved.value,
              child: child,
            ),
          ),
          // 一瞬の白いフラッシュ
          IgnorePointer(
            child: Container(
              color: Colors.white.withValues(
                alpha: (1 - (curved.value - 0.3).abs() / 0.3).clamp(0, 1) * 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// エリアに入ったときに出す見出し（場所の名前と、そこで学ぶこと）
class _AreaBanner extends StatelessWidget {
  const _AreaBanner({
    required this.title,
    required this.theme,
    required this.boss,
  });

  final String title;
  final String theme;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final color = boss ? TsuzuriColors.stamp : TsuzuriColors.accent;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: TsuzuriColors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x33000000))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (boss)
              Text(
                '― ボスの間 ―',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: serif(17, color: color),
            ),
            if (theme.isNotEmpty)
              Text(
                theme,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: TsuzuriColors.inkSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.title,
    required this.level,
    required this.exp,
    required this.expToNext,
    required this.stars,
  });

  final String title;
  final int level;
  final int exp;
  final int expToNext;
  final String stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: _paperBox(),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CustomPaint(painter: _HeroIcon()),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Lv$level', style: serif(15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TsuzuriColors.inkSoft,
                        ),
                      ),
                    ),
                    Text(
                      stars,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8860B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: expToNext == 0 ? 0 : exp / expToNext,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDE3D1),
                    color: TsuzuriColors.exp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => paintHero(canvas, size.width);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _paperBox() => BoxDecoration(
  color: TsuzuriColors.card.withValues(alpha: 0.95),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: TsuzuriColors.accent, width: 1.5),
  boxShadow: const [
    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
  ],
);

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: TsuzuriColors.card,
        shape: const CircleBorder(
          side: BorderSide(color: TsuzuriColors.accent, width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: TsuzuriColors.accent),
          ),
        ),
      ),
    );
  }
}

/// RPG風のメッセージウィンドウ
class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.child,
    required this.actions,
    this.portrait,
  });

  final Widget child;
  final List<Widget> actions;
  final EnemyDef? portrait;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 40),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _paperBox(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (portrait != null) ...[
                  _EnemyPortrait(enemy: portrait!),
                  const SizedBox(width: 12),
                ],
                Expanded(child: child),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final a in actions) ...[const SizedBox(width: 8), a],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EnemyPortrait extends StatefulWidget {
  const _EnemyPortrait({required this.enemy});
  final EnemyDef enemy;

  @override
  State<_EnemyPortrait> createState() => _EnemyPortraitState();
}

class _EnemyPortraitState extends State<_EnemyPortrait>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: TsuzuriColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0D4C0)),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) =>
            CustomPaint(painter: EnemyArt(widget.enemy, _c.value * 60)),
      ),
    );
  }
}

/// 敵の絵を Flutter ウィジェットで描くための CustomPainter
class EnemyArt extends CustomPainter {
  EnemyArt(this.enemy, this.t);
  final EnemyDef enemy;
  final double t;

  @override
  void paint(Canvas canvas, Size size) =>
      paintEnemy(canvas, size.shortestSide, enemy.look, t, color: enemy.color);

  @override
  bool shouldRepaint(EnemyArt old) => old.t != t || old.enemy != enemy;
}

/// 画面左下の十字ボタン（押している間歩き続ける）
class _DPad extends StatelessWidget {
  const _DPad({required this.game});
  final FieldGame game;

  @override
  Widget build(BuildContext context) {
    Widget button(Facing dir, IconData icon) => Listener(
      onPointerDown: (_) => game.padDirection = dir,
      onPointerUp: (_) {
        if (game.padDirection == dir) game.padDirection = null;
      },
      onPointerCancel: (_) => game.padDirection = null,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: TsuzuriColors.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TsuzuriColors.accent, width: 1.5),
        ),
        child: Icon(icon, color: TsuzuriColors.accent, size: 30),
      ),
    );
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: button(Facing.up, Icons.keyboard_arrow_up),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: button(Facing.down, Icons.keyboard_arrow_down),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: button(Facing.left, Icons.keyboard_arrow_left),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: button(Facing.right, Icons.keyboard_arrow_right),
          ),
        ],
      ),
    );
  }
}

/// 宝箱・泉のミニクイズ（ダイアログの中で解く）
class _MiniQuiz extends StatefulWidget {
  const _MiniQuiz({
    super.key,
    required this.title,
    required this.questions,
    required this.onDone,
  });

  final String title;
  final List<QuizQuestion> questions;
  final void Function(int correct) onDone;

  @override
  State<_MiniQuiz> createState() => _MiniQuizState();
}

class _MiniQuizState extends State<_MiniQuiz> {
  int _index = 0;
  int _correct = 0;
  int? _chosen;

  QuizQuestion get _q => widget.questions[_index];

  void _choose(int i) {
    if (_chosen != null) return;
    setState(() {
      _chosen = i;
      if (i == _q.answerIndex) _correct++;
    });
  }

  void _next() {
    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _chosen = null;
      });
    } else {
      widget.onDone(_correct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.title}（${_index + 1}/${widget.questions.length}）',
          style: serif(15),
        ),
        const SizedBox(height: 4),
        Text(q.prompt, style: const TextStyle(fontSize: 13)),
        if (q.sentence != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(q.sentence!, style: serif(15)),
          ),
        const SizedBox(height: 8),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _chosen == null
                      ? null
                      : i == q.answerIndex
                      ? TsuzuriColors.correct.withValues(alpha: 0.2)
                      : i == _chosen
                      ? TsuzuriColors.wrong.withValues(alpha: 0.2)
                      : null,
                ),
                onPressed: _chosen == null ? () => _choose(i) : null,
                child: Text(q.choices[i]),
              ),
            ),
          ),
        if (_chosen != null) ...[
          Text(
            _chosen == q.answerIndex
                ? '正解！'
                : '正解は「${q.answer}」。${q.shortExplanation}',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _chosen == q.answerIndex
                  ? TsuzuriColors.correct
                  : TsuzuriColors.wrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _next, child: const Text('つぎへ')),
          ),
        ],
      ],
    );
  }
}
