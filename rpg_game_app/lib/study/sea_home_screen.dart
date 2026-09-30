import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'exam_world_screens.dart';
import 'realm_style.dart';
import 'personal_books.dart';
import 'sea_battle_launcher.dart';
import '../vocab/vocab_home.dart';

/// 定期テストの海：教科を選び、単元・単語帳を選ぶ画面
class SeaHomeScreen extends StatefulWidget {
  const SeaHomeScreen({super.key, required this.personalBooks});

  final PersonalBooks personalBooks;

  @override
  State<SeaHomeScreen> createState() => _SeaHomeScreenState();
}

class _SeaHomeScreenState extends State<SeaHomeScreen> {
  /// 選んでいる教科（english / science / social / japanese / math / information）
  String _subject = 'english';

  static const _subjects = [
    ('english', '英語'),
    ('science', '理科'),
    ('social', '社会'),
    ('japanese', '国語'),
    ('math', '数学'),
    ('information', '情報'),
  ];

  @override
  Widget build(BuildContext context) {
    final chooser = SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final (id, label) in _subjects)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label),
                selected: _subject == id,
                onSelected: (_) => setState(() => _subject = id),
              ),
            ),
        ],
      ),
    );
    final english = _subject == 'english';
    final world = english ? null : RpgCatalog.world(_subject);
    final extras = ExtraSets.of(_subject);
    final tabs = english
        ? const [
            Tab(text: '高1'),
            Tab(text: '高2'),
            Tab(text: '高3'),
            Tab(text: '単語・熟語'),
            Tab(text: '追加問題'),
            Tab(icon: Icon(Icons.style, size: 16), text: '単語帳練習'),
          ]
        : [
            for (final r in world!.routes) Tab(text: r.name),
            if (world.routes.isEmpty) const Tab(text: '準備中'),
            if (extras.isNotEmpty) const Tab(text: '追加問題'),
          ];
    return DefaultTabController(
      key: ValueKey(_subject),
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: TsuzuriColors.tint(0xFFE6F0F5),
          title: Text('定期テストの海', style: serif(19, color: StudyRealm.sea.ink)),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExamWorldListScreen(),
                ),
              ),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('試験対策'),
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
                  labelColor: StudyRealm.sea.ink,
                  indicatorColor: StudyRealm.sea.ink,
                  tabs: tabs,
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
              if (!english) {
                return TabBarView(
                  children: [
                    for (final r in world!.routes)
                      _RouteTab(world: world, route: r, progress: progress),
                    if (world.routes.isEmpty)
                      const Center(child: Text('この教科は準備中です')),
                    if (extras.isNotEmpty)
                      _ExtraTab(world: world, sets: extras, progress: progress),
                  ],
                );
              }
              return TabBarView(
                children: [
                  _GradeTab(grade: 1, progress: progress),
                  _GradeTab(grade: 2, progress: progress),
                  _GradeTab(grade: 3, progress: progress),
                  _WordsTab(progress: progress),
                  _ExtraTab(world: null, sets: extras, progress: progress),
                  VocabHome(books: widget.personalBooks),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 英語以外の教科：ルートごとに、エリアの単元を練習できる。
/// RPG と同じ自作問題を使うので、有料の教科はワールドを解放してから使える。
class _RouteTab extends StatelessWidget {
  const _RouteTab({
    required this.world,
    required this.route,
    required this.progress,
  });

  final WorldDef world;
  final RouteInfo route;
  final RpgProgress progress;

  Future<void> _open(BuildContext context, StageDef s) async {
    final setId = s.questionSetIds.last;
    final set = await RpgServices.of(context).questions.load(setId);
    if (set == null || !context.mounted) return;
    await startSeaBattle(
      context,
      title: '${route.name} ${s.areaNo}. ${s.grammarTheme}',
      recordId: setId,
      questions: set.questions,
      worldId: world.id,
      normalTimeLimitSeconds: s.timeLimitSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final owned = Progression.isWorldPlayable(progress, world);
    final stages = world.stages.where((s) => s.branch == route.id).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        if (!owned)
          Card(
            color: TsuzuriColors.tint(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${world.name}を解放すると、ここで単元ごとに練習できます。'
                '（ワールドマップの「${world.name}」から解放できます）',
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
        for (final (i, s) in stages.indexed) ...[
          if (i == 0 || stages[i - 1].region != s.region)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 0, 6),
              child: Text(
                s.region,
                style: serif(15, color: TsuzuriColors.inkSoft),
              ),
            ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              enabled: owned,
              onTap: owned ? () => _open(context, s) : null,
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: TsuzuriColors.tint(0xFFE6F0F5),
                child: Text(
                  '${s.areaNo}',
                  style: TextStyle(
                    fontSize: 12,
                    color: StudyRealm.sea.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(s.grammarTheme),
              trailing: owned
                  ? _bestBadge(progress.seaBest[s.questionSetIds.last])
                  : const Icon(Icons.lock_outline, size: 18),
            ),
          ),
        ],
      ],
    );
  }
}

/// 追加問題：ルートに入っていない単元別の問題セット
class _ExtraTab extends StatelessWidget {
  const _ExtraTab({
    required this.world,
    required this.sets,
    required this.progress,
  });

  /// 英語は null（無料で使える）
  final WorldDef? world;
  final List<ExtraSet> sets;
  final RpgProgress progress;

  Future<void> _open(BuildContext context, ExtraSet s) async {
    final set = await RpgServices.of(context).questions.load(s.id);
    if (set == null || !context.mounted) return;
    await startSeaBattle(
      context,
      title: '追加問題 ${s.title}',
      recordId: s.id,
      questions: set.questions,
      worldId: world?.id ?? RpgCatalog.englishWorldId,
      normalTimeLimitSeconds: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = world;
    final owned = w == null || Progression.isWorldPlayable(progress, w);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        if (!owned)
          Card(
            color: TsuzuriColors.tint(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${w.name}を解放すると、追加問題も練習できます。',
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
        for (final s in sets)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              key: ValueKey('extra-${s.id}'),
              enabled: owned,
              onTap: owned ? () => _open(context, s) : null,
              leading: Icon(Icons.fiber_new, color: StudyRealm.sea.ink),
              title: Text(s.title),
              trailing: owned
                  ? _bestBadge(progress.seaBest[s.id])
                  : const Icon(Icons.lock_outline, size: 18),
            ),
          ),
      ],
    );
  }
}

Widget _bestBadge(int? best) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: best == null
        ? TsuzuriColors.tint(0xFFEDE3D1)
        : best >= 80
        ? TsuzuriColors.correct.withValues(alpha: 0.15)
        : TsuzuriColors.tint(0xFFFFF1D6),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    best == null ? '未挑戦' : 'ベスト $best%',
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: best == null ? TsuzuriColors.inkSoft : TsuzuriColors.ink,
    ),
  ),
);

class _GradeTab extends StatelessWidget {
  const _GradeTab({required this.grade, required this.progress});
  final int grade;
  final RpgProgress progress;

  Future<void> _open(BuildContext context, SeaUnit unit) async {
    final set = await RpgServices.of(context).questions.load(unit.id);
    if (set == null || !context.mounted) return;
    await startSeaBattle(
      context,
      title: '高$grade ${unit.number}. ${unit.title}',
      recordId: unit.id,
      questions: set.questions,
      worldId: RpgCatalog.englishWorldId,
      normalTimeLimitSeconds: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = SeaCatalog.unitsOf(grade);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        Text(
          SeaCatalog.gradeNames[grade]!,
          style: serif(15, color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 8),
        for (final u in units)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(context, u),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: StudyRealm.sea.ink,
                          child: Text(
                            '${u.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(u.title, style: serif(16))),
                        _bestBadge(progress.seaBest[u.id]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in u.topics)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TsuzuriColors.tint(0xFFE6F0F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 11,
                                color: StudyRealm.sea.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WordsTab extends StatelessWidget {
  const _WordsTab({required this.progress});
  final RpgProgress progress;

  Future<void> _open(
    BuildContext context,
    SeaWordBook book,
    WordQuizDirection dir,
  ) async {
    final raw = await rootBundle.loadString(
      'packages/rpg_game/assets/words/${book.id}.json',
    );
    final list = WordList.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final set = WordQuizBuilder().build(list, direction: dir);
    if (!context.mounted) return;
    await startSeaBattle(
      context,
      title:
          '${book.title}（${dir == WordQuizDirection.enToJa ? '英→日' : '日→英'}）',
      recordId: '${book.id}_${dir.name}',
      questions: set.questions,
      worldId: RpgCatalog.englishWorldId,
      normalTimeLimitSeconds: 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        Text('1回20問（ランダム）', style: serif(15, color: TsuzuriColors.inkSoft)),
        const SizedBox(height: 8),
        for (final b in SeaCatalog.wordBooks)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title, style: serif(16)),
                  Text(
                    b.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final dir in WordQuizDirection.values) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _open(context, b, dir),
                            child: Column(
                              children: [
                                Text(
                                  dir == WordQuizDirection.enToJa
                                      ? '英→日'
                                      : '日→英',
                                ),
                                const SizedBox(height: 2),
                                _bestBadge(
                                  progress.seaBest['${b.id}_${dir.name}'],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (dir == WordQuizDirection.enToJa)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
