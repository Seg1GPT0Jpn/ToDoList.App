import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/hero_painter.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../field/field_screen.dart';
import '../study/sea_home_screen.dart';

const _subjectIcons = <String, IconData>{
  'japanese': Icons.menu_book,
  'math': Icons.functions,
  'english': Icons.translate,
  'science': Icons.science_outlined,
  'social': Icons.public,
  'information': Icons.memory,
};

const _subjectColors = <String, Color>{
  'japanese': Color(0xFFC0504D),
  'math': Color(0xFF3F7CAC),
  'english': Color(0xFF5B9A5B),
  'science': Color(0xFF8E6BBF),
  'social': Color(0xFFD9822B),
  'information': Color(0xFF4A8C8C),
};

/// ワールドマップ（教科ごとの国を選ぶ）
class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      body: NotebookPaper(
        child: SafeArea(
          child: StreamBuilder<RpgProgress>(
            stream: services.repository.watch(),
            builder: (context, snap) {
              final progress = snap.data ?? RpgProgress.initial;
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(44, 20, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _header(context, progress),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(40, 8, 12, 24),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: [
                        for (final (i, w) in RpgCatalog.worlds.indexed)
                          _WorldCard(world: w, progress: progress, index: i),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, RpgProgress progress) {
    final stats = PlayerStats.forLevel(progress.level);
    final services = RpgServices.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'つづりクエスト',
                    style: serif(28, color: TsuzuriColors.accent),
                  ),
                  const Text(
                    'ノートの世界を旅して、魔物をクイズでたおそう',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: TsuzuriColors.inkSoft),
              onSelected: (v) async {
                if (v == 'trial') {
                  await _pickTrial(context);
                  return;
                }
                if (v != 'reset') return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('データをリセット'),
                    content: const Text('レベル・クリア状況・購入状況をすべて消して、最初からにします。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('やめる'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('リセット'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await services.repository.reset();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'trial', child: Text('エリアを選んでバトル（確認用）')),
                PopupMenuItem(value: 'reset', child: Text('データをリセット')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TsuzuriColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TsuzuriColors.accent, width: 1.5),
          ),
          child: Row(
            children: [
              const _WalkingHero(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lv${stats.level}  見習い冒険者', style: serif(16)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            progress.exp /
                            PlayerStats.expToNextLevel(stats.level),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDE3D1),
                        color: TsuzuriColors.exp,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HP ${stats.maxHp}　攻撃 ${stats.attack}　防御 ${stats.defense}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SeaBanner(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SeaHomeScreen(personalBooks: services.personalBooks),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('冒険の行き先をえらぶ', style: serif(16)),
      ],
    );
  }
}

/// 確認用：好きなエリアの敵とすぐに戦う（結果は保存しない）
Future<void> _pickTrial(BuildContext context) async {
  final services = RpgServices.of(context);
  final world = RpgCatalog.world(RpgCatalog.englishWorldId);
  final stage = await showDialog<StageDef>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text('エリアを選んでバトル（確認用）'),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            '結果は保存されません。レベルは今のまま戦います。',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
        ),
        for (final s in world.stages)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, s),
            child: Text('${s.order}. ${s.name}（${s.grammarTheme}）'),
          ),
      ],
    ),
  );
  if (stage == null || !context.mounted) return;
  final pool = await services.loadStagePool(stage);
  final progress = await services.repository.load();
  if (pool == null || !pool.origin.usableInRpg || !context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BattleScreen(
        world: world,
        stage: stage,
        questions: pool.questions,
        progress: progress,
        trial: true,
      ),
    ),
  );
}

/// その場で足ぶみしている主人公
class _WalkingHero extends StatefulWidget {
  const _WalkingHero();
  @override
  State<_WalkingHero> createState() => _WalkingHeroState();
}

class _WalkingHeroState extends State<_WalkingHero>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(painter: _HeroPainter(_c.value)),
    ),
  );
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.walk);
  final double walk;
  @override
  void paint(Canvas canvas, Size size) => paintHero(
    canvas,
    size.width,
    facing: Facing.down,
    walk: walk,
    moving: true,
  );
  @override
  bool shouldRepaint(_HeroPainter old) => old.walk != walk;
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.progress,
    required this.index,
  });

  final WorldDef world;
  final RpgProgress progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final availability = services.unlock.availabilityOf(progress, world);
    final playable = availability == WorldAvailability.playable;
    final color = _subjectColors[world.id] ?? TsuzuriColors.accent;
    final cleared = world.stages
        .where((s) => progress.clearedStageIds.contains(s.id))
        .length;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 30),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Material(
        color: playable ? TsuzuriColors.card : const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => playable
              ? Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        FieldScreen(world: world, progress: progress),
                  ),
                )
              : _showLocked(context, availability),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: playable ? color : const Color(0xFFD8CFC0),
                width: playable ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (playable ? color : Colors.grey).withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _subjectIcons[world.id],
                        color: playable ? color : Colors.grey,
                        size: 26,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      world.subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: playable ? color : Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      world.name,
                      style: serif(
                        16,
                        color: playable
                            ? TsuzuriColors.ink
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (playable) ...[
                      Row(
                        children: [
                          for (var i = 0; i < world.stages.length; i++)
                            Icon(
                              i < cleared ? Icons.star : Icons.star_border,
                              size: 14,
                              color: const Color(0xFFE0A800),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '冒険する →',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          availability == WorldAvailability.ownedComingSoon
                              ? '解放済み・準備中'
                              : '準備中',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!playable)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Transform.rotate(
                      angle: -pi / 16,
                      child: Icon(
                        availability == WorldAvailability.ownedComingSoon
                            ? Icons.lock_open
                            : Icons.lock,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLocked(
    BuildContext context,
    WorldAvailability availability,
  ) async {
    final services = RpgServices.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (availability == WorldAvailability.ownedComingSoon) {
      messenger.showSnackBar(
        const SnackBar(content: Text('解放済みです。公開されたら遊べるようになります。')),
      );
      return;
    }
    final purchasable = availability == WorldAvailability.purchasable;
    final buy = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: Icon(_subjectIcons[world.id], size: 36),
        title: Text(
          purchasable ? '${world.name}を解放しますか？' : '${world.name}は準備中です',
        ),
        content: Text(
          purchasable
              ? '${world.subject}のワールドを解放します。\n価格：¥${world.priceYen}（買い切り・1回のみ）\n\n※ テスト用のダミー購入です。実際にお金はかかりません。'
              : '公開までもうしばらくお待ちください。\n予定価格：¥${world.priceYen}（買い切り）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(purchasable ? 'やめる' : 'とじる'),
          ),
          if (purchasable)
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('購入する'),
            ),
        ],
      ),
    );
    if (buy != true) return;
    final outcome = await services.unlock.purchase(world);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          PurchaseOutcome.success => '${world.name}を解放しました（ダミー購入）',
          PurchaseOutcome.cancelled => '購入をキャンセルしました',
          PurchaseOutcome.alreadyOwned => 'すでに解放済みです',
          PurchaseOutcome.notPurchasable => '現在は購入できません',
        }),
      ),
    );
  }
}

/// 定期テストの海への入口
class _SeaBanner extends StatelessWidget {
  const _SeaBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFFE6F0F5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2F5D7C), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.sailing, size: 36, color: Color(0xFF2F5D7C)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '定期テストの海',
                      style: serif(18, color: const Color(0xFF2F5D7C)),
                    ),
                    const Text(
                      '単元ごとに文法・単語・熟語をチェック',
                      style: TextStyle(
                        fontSize: 12,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF2F5D7C)),
            ],
          ),
        ),
      ),
    );
  }
}
