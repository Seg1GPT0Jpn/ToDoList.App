import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../main.dart' show routeObserver;
import '../study/inn_screen.dart';
import '../art/enemy_painter.dart';
import '../art/hero_painter.dart';
import '../battle/battle_screen.dart';
import 'field_game.dart';
import 'field_map.dart';

/// ワールドの中を歩き回る画面
class FieldScreen extends StatefulWidget {
  const FieldScreen({super.key, required this.world, required this.progress});

  final WorldDef world;
  final RpgProgress progress;

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

class _FieldScreenState extends State<FieldScreen> with RouteAware {
  late RpgProgress _progress = widget.progress;
  late final FieldGame _game = FieldGame(
    map: FieldMap.english,
    rpgWorld: widget.world,
    progress: widget.progress,
    onEncounter: (stage, cleared) => _open(_EncounterDialog(stage, cleared)),
    onMessage: (text) => _open(_MessageDialog(text)),
    onInn: (stage) => _open(_InnDialog(stage)),
  );
  _Dialog? _dialog;
  bool _starting = false;

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
    final updated = await RpgServices.of(context).repository.load();
    if (!mounted) return;
    setState(() => _progress = updated);
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
    // 戻ってきたときの処理は didPopNext で行う（結果画面へは差し替えで進むため、
    // ここで push の完了を待つと結果画面を閉じる前に戻り処理が走ってしまう）
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => BattleScreen(
          world: widget.world,
          stage: stage,
          questions: set.questions,
          progress: _progress,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            _BattleTransition(animation: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = PlayerStats.forLevel(_progress.level);
    final cleared = widget.world.stages
        .where((s) => _progress.clearedStageIds.contains(s.id))
        .length;
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
                      child: ValueListenableBuilder<Region>(
                        valueListenable: _game.region,
                        builder: (context, region, _) => _Hud(
                          title: '${widget.world.name}・${region.label}',
                          level: stats.level,
                          exp: _progress.exp,
                          expToNext: PlayerStats.expToNextLevel(stats.level),
                          stars: '★ $cleared / ${widget.world.stages.length}',
                        ),
                      ),
                    ),
                  ],
                ),
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
        final lesson = InnLessons.forStage(stage.id);
        return _MessageBox(
          actions: [
            TextButton(onPressed: _close, child: const Text('やめておく')),
            FilledButton.icon(
              onPressed: () {
                _close();
                _game.inputLocked = true;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InnScreen(stage: stage),
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
                'ステージ${stage.order}「${stage.name}」',
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
                '${enemy.description}\n文法：${stage.grammarTheme}／単語：${stage.vocabLevel}\nHP ${enemy.maxHp}・推奨Lv${stage.recommendedLevel}・1問${stage.timeLimitSeconds}秒',
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
