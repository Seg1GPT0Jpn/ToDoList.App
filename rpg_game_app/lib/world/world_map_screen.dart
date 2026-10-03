import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../meta/navigator_card.dart';
import '../account/account_screen.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/battle_backdrop.dart';
import '../art/hero_painter.dart';
import '../audio/music_director.dart';
import '../audio/music_scope.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../field/field_screen.dart';
import '../meta/adventure_card.dart';
import '../study/realm_style.dart';
import '../study/sea_home_screen.dart';
import '../study/sky_home_screen.dart';
import 'promo_code_dialog.dart';

const _subjectIcons = <String, IconData>{
  'japanese': Icons.menu_book,
  'math': Icons.functions,
  'english': Icons.translate,
  'science': Icons.science_outlined,
  'social': Icons.public,
  'information': Icons.memory,
  'music': Icons.music_note,
};

const _subjectColors = <String, Color>{
  'japanese': Color(0xFFC0504D),
  'math': Color(0xFF3F7CAC),
  'english': Color(0xFF5B9A5B),
  'science': Color(0xFF8E6BBF),
  'social': Color(0xFFD9822B),
  'information': Color(0xFF4A8C8C),
  'music': Color(0xFFD45D8C),
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
                    // 横に広い画面でもカードが縦に伸びすぎないよう、高さを決めておく
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 176,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      delegate: SliverChildListDelegate([
                        for (final (i, w) in RpgCatalog.worlds.indexed)
                          _WorldCard(world: w, progress: progress, index: i),
                      ]),
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
                  Text(
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
              icon: Icon(Icons.more_vert, color: TsuzuriColors.inkSoft),
              onSelected: (v) async {
                if (v == 'account') {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountScreen(),
                    ),
                  );
                  return;
                }
                if (v == 'promo') {
                  await showPromoCodeDialog(context);
                  return;
                }
                if (v == 'trial') {
                  await _pickTrial(context);
                  return;
                }
                if (v != 'reset') return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('データをリセット'),
                    content: const Text(
                      'レベル・クリア状況・購入状況・学習記録・図鑑をすべて消して、最初からにします。',
                    ),
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
                if (ok == true) {
                  await services.repository.reset();
                  await services.meta.reset();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'account',
                  child: Text('アカウント（名前・Google）'),
                ),
                const PopupMenuItem(value: 'promo', child: Text('プロモーションコード')),
                // どのエリアとも戦える確認用メニューは、開発中だけ出す
                if (kDebugMode)
                  const PopupMenuItem(
                    value: 'trial',
                    child: Text('エリアを選んでバトル（確認用）'),
                  ),
                const PopupMenuItem(value: 'reset', child: Text('データをリセット')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _HomeBanner(),
        const SizedBox(height: 10),
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
                    StreamBuilder<PlayerProfile>(
                      stream: services.profiles.watch(),
                      builder: (context, p) => InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AccountScreen(),
                          ),
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Lv${stats.level}  ${(p.data ?? services.profiles.load()).displayName}',
                                overflow: TextOverflow.ellipsis,
                                style: serif(16),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              (p.data ?? services.profiles.load())
                                      .isGoogleLinked
                                  ? Icons.verified_user
                                  : Icons.edit,
                              size: 15,
                              color: TsuzuriColors.inkSoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            progress.exp /
                            PlayerStats.expToNextLevel(stats.level),
                        minHeight: 8,
                        backgroundColor: TsuzuriColors.tint(0xFFEDE3D1),
                        color: TsuzuriColors.exp,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HP ${stats.maxHp}　攻撃 ${stats.attack}　防御 ${stats.defense}',
                      style: TextStyle(
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
        const SizedBox(height: 12),
        TodayButton(
          record: services.meta.record,
          today: RpgServices.today(),
          onAdventure: () {
            final w = RpgCatalog.world(RpgCatalog.englishWorldId);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MusicScope(
                  music: MusicDirector.fieldKey(w.id),
                  child: FieldScreen(world: w, progress: progress),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        AdventureCard(progress: progress),
        const SizedBox(height: 14),
        _RealmBanner(
          realm: StudyRealm.sea,
          subtitle: '学年・単元ごとに定期テスト対策。船で進み、最後は潜水艦で深海へ',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MusicScope(
                music: 'field_science',
                child: SeaHomeScreen(personalBooks: services.personalBooks),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _RealmBanner(
          realm: StudyRealm.sky,
          subtitle: '高校入試レベルの上級者向け。飛行船で雲の上へ、最後はロケットで宇宙へ',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MusicScope(
                music: 'field_information',
                child: SkyHomeScreen(),
              ),
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
  // 教科 →（理科なら系統）→ エリア の順に選ぶ
  Future<T?> choose<T>(String title, List<(String, T)> items) => showDialog<T>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(title),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            '結果は保存されません。レベルは今のまま戦います。',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
        ),
        for (final (label, value) in items)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, value),
            child: Text(label),
          ),
      ],
    ),
  );

  final world = await choose('教科を選ぶ（確認用）', [
    for (final w in RpgCatalog.worlds)
      if (!w.isComingSoon) ('${w.subject}：${w.name}', w),
  ]);
  if (world == null || !context.mounted) return;
  var stages = world.stages;
  if (world.routes.length > 1) {
    final branch = await choose('ルートを選ぶ（確認用）', [
      for (final r in world.routes) (r.name, r.id),
    ]);
    if (branch == null || !context.mounted) return;
    stages = stages.where((s) => s.branch == branch).toList();
  }
  final stage = await choose('エリアを選んでバトル（確認用）', [
    for (final s in stages)
      ('${RpgCatalog.stageLabel(s)}. ${s.name}（${s.grammarTheme}）', s),
  ]);
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
        // 確認用でも、エリアの敵は決まった HP なので、科目の習熟で強さを決める
        relativePower: true,
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
        color: playable ? TsuzuriColors.card : TsuzuriColors.tint(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => playable
              ? Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MusicScope(
                      music: MusicDirector.fieldKey(world.id),
                      child: FieldScreen(world: world, progress: progress),
                    ),
                  ),
                )
              : _showLocked(context, availability),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: playable ? color : TsuzuriColors.tint(0xFFD8CFC0),
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
                      // エリア数が多い（数学は90）ので、★は数とバーで表す
                      Text(
                        '★ $cleared / ${world.stages.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB8860B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: world.stages.isEmpty
                              ? 0
                              : cleared / world.stages.length,
                          minHeight: 5,
                          backgroundColor: TsuzuriColors.gridLine,
                          color: const Color(0xFFE0A800),
                        ),
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
                          switch (availability) {
                            WorldAvailability.ownedComingSoon => '解放済み・準備中',
                            WorldAvailability.purchasable
                                when !world.isComingSoon &&
                                    !RpgServices.of(context)
                                        .unlock
                                        .allowPurchase =>
                              '有料・コードで解放（${world.stages.length}エリア）',
                            WorldAvailability.purchasable
                                when !world.isComingSoon =>
                              '¥${world.priceYen}で解放（${world.stages.length}エリア）',
                            _ => '準備中',
                          },
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
    if (purchasable && !services.unlock.allowPurchase) {
      final useCode = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: Icon(_subjectIcons[world.id], size: 36),
          title: Text('${world.name}はロックされています'),
          content: Text(
            '${world.subject}のワールド（${world.stages.length}エリア）は有料です。\n'
            '購入はまだ準備中です。\n\n'
            'プロモーションコードを持っている人は、コードを入力すると受け取れます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('とじる'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(c, true),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('コードを入力'),
            ),
          ],
        ),
      );
      if (useCode == true && context.mounted) {
        await showPromoCodeDialog(context);
      }
      return;
    }
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

/// 定期テストの海・高校入試の空への入口
class _RealmBanner extends StatelessWidget {
  const _RealmBanner({
    required this.realm,
    required this.subtitle,
    required this.onTap,
  });
  final StudyRealm realm;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: realm.paper,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: realm.ink, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(realm.icon, size: 36, color: realm.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(realm.title, style: serif(18, color: realm.ink)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: realm.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// ホームの上の、時間で変わる景色の帯。主人公が歩いて旅をしている
class _HomeBanner extends StatefulWidget {
  const _HomeBanner();

  @override
  State<_HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<_HomeBanner>
    with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

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
      height: 96,
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
                      left: -40 + (w + 80) * v,
                      bottom: 12,
                      child: SizedBox.square(
                        dimension: 40,
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
