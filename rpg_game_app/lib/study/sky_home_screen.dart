import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'common_test_screens.dart';
import 'exam_world_screens.dart';
import 'realm_style.dart';
import 'sea_battle_launcher.dart';
import 'sea_home_screen.dart';
import 'term_cards.dart';

/// 模擬試験の空：定期テストの海と対になる、もっと難しい学習モード。
///
/// - 単元ごとに空の魔物とバトル（2回まちがえると倒れる・制限時間は RPG の半分）
/// - 「模試対策」：範囲を入力すると、飛行船→ロケットで進む航路ができる
/// - 「採点模試」：制限時間の中で教科を順に解き、100点満点で採点する
class SkyHomeScreen extends StatefulWidget {
  const SkyHomeScreen({super.key});

  @override
  State<SkyHomeScreen> createState() => _SkyHomeScreenState();
}

class _SkyHomeScreenState extends State<SkyHomeScreen> {
  static const _realm = StudyRealm.sky;
  String _subject = RpgCatalog.englishWorldId;

  /// ワールドの区切り（ルートがあればルート、なければ地方）
  static List<(String, List<StageDef>)> _sections(WorldDef world) {
    if (world.routes.isNotEmpty) {
      return [
        for (final r in world.routes)
          (r.name, world.stages.where((s) => s.branch == r.id).toList()),
      ];
    }
    final out = <(String, List<StageDef>)>[];
    for (final s in world.stages) {
      if (out.isEmpty || out.last.$1 != s.region) out.add((s.region, []));
      out.last.$2.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final world = RpgCatalog.world(_subject);
    final sections = _sections(world);
    final english = world.id == RpgCatalog.englishWorldId;
    final cards = TermDecks.of(world.id).isNotEmpty;
    final extraTabs = [
      if (english) const Tab(text: '単語'),
      if (cards) const Tab(text: '暗記カード'),
    ];
    final chooser = SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final w in RpgCatalog.worlds)
            if (!w.isComingSoon)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(w.subject),
                  selected: _subject == w.id,
                  onSelected: (_) => setState(() => _subject = w.id),
                ),
              ),
        ],
      ),
    );
    return DefaultTabController(
      key: ValueKey(_subject),
      length: sections.length + extraTabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _realm.paper,
          title: Text(_realm.title, style: serif(19, color: _realm.ink)),
          actions: [
            IconButton(
              tooltip: '採点模試',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MockExamScreen()),
              ),
              icon: const Icon(Icons.timer_outlined),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExamWorldListScreen(realm: _realm),
                ),
              ),
              icon: Icon(_realm.icon, size: 18),
              label: const Text('模試対策'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44 + 48),
            child: Column(
              children: [
                chooser,
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: _realm.ink,
                  indicatorColor: _realm.ink,
                  tabs: [
                    for (final (name, _) in sections) Tab(text: name),
                    ...extraTabs,
                  ],
                ),
              ],
            ),
          ),
        ),
        body: NotebookPaper(
          child: StreamBuilder<RpgProgress>(
            stream: RpgServices.of(context).repository.watch(),
            builder: (context, snap) {
              final progress = snap.data ?? RpgProgress.initial;
              return TabBarView(
                children: [
                  for (final (name, stages) in sections)
                    _SectionTab(
                      world: world,
                      name: name,
                      stages: stages,
                      progress: progress,
                    ),
                  if (english)
                    WordBooksTab(progress: progress, realm: StudyRealm.sky),
                  if (cards)
                    TermCardsTab(
                      world: world,
                      progress: progress,
                      realm: StudyRealm.sky,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.world,
    required this.name,
    required this.stages,
    required this.progress,
  });

  final WorldDef world;
  final String name;
  final List<StageDef> stages;
  final RpgProgress progress;

  Future<void> _open(BuildContext context, StageDef s) async {
    final pool = await RpgServices.of(context).loadStagePool(s);
    if (pool == null || !pool.origin.usableInRpg || !context.mounted) return;
    await startSeaBattle(
      context,
      title: '$name ${s.areaNo}. ${s.grammarTheme}',
      recordId: s.questionSetIds.last,
      questions: pool.questions,
      worldId: world.id,
      normalTimeLimitSeconds: s.timeLimitSeconds,
      realm: StudyRealm.sky,
    );
  }

  @override
  Widget build(BuildContext context) {
    const realm = StudyRealm.sky;
    final owned = Progression.isWorldPlayable(progress, world);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        Card(
          color: realm.paper,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '☁ 模擬試験の空は、定期テストの海よりさらに難しい上級者向けのモードです。\n'
              '・2回まちがえると倒れる　・制限時間は RPG の半分　・空の魔物は約16回の正解で倒せる\n'
              'RPG の進行や経験値は変わりません。正答率の自己ベストが残ります。',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ),
        ),
        if (!owned)
          Card(
            color: TsuzuriColors.tint(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${world.name}を解放すると、ここで単元ごとに挑戦できます。'
                '（ワールドマップの「${world.name}」から解放できます）',
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
        for (final s in stages)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              enabled: owned,
              onTap: owned ? () => _open(context, s) : null,
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: realm.paper,
                child: Text(
                  '${s.areaNo}',
                  style: TextStyle(
                    fontSize: 12,
                    color: realm.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(s.grammarTheme.isEmpty ? s.name : s.grammarTheme),
              subtitle: s.isBoss ? const Text('ボスのエリア（範囲のまとめ）') : null,
              trailing: owned
                  ? _BestBadge(
                      progress.seaBest[skyRecordId(s.questionSetIds.last)],
                    )
                  : const Icon(Icons.lock_outline, size: 18),
            ),
          ),
      ],
    );
  }
}

class _BestBadge extends StatelessWidget {
  const _BestBadge(this.best);
  final int? best;

  @override
  Widget build(BuildContext context) {
    final b = best;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: b == null
            ? TsuzuriColors.tint(0xFFEDE3D1)
            : b >= 80
            ? TsuzuriColors.correct.withValues(alpha: 0.15)
            : TsuzuriColors.tint(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        b == null ? '未挑戦' : 'ベスト $b%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: b == null ? TsuzuriColors.inkSoft : TsuzuriColors.ink,
        ),
      ),
    );
  }
}
