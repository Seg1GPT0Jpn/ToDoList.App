import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';

const _seaBlue = Color(0xFF2F5D7C);

/// 試験対策ワールドの一覧（定期テストの海から入る）
class ExamWorldListScreen extends StatelessWidget {
  const ExamWorldListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RpgServices.of(context).examWorlds;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F0F5),
        title: Text('試験対策ワールド', style: serif(18, color: _seaBlue)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ExamWorldCreateScreen(),
          ),
        ),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('範囲からつくる'),
      ),
      body: NotebookPaper(
        child: StreamBuilder<List<ExamWorldPlan>>(
          stream: store.watch(),
          builder: (context, snap) {
            final plans = snap.data ?? store.load();
            return ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 96),
              children: [
                const Text(
                  '試験範囲を入力すると、その範囲のエリアを集めたワールドができます。'
                  '最後には、範囲全部から出題する「試験本番」のボスが待っています。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 16),
                if (plans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'まだワールドがありません。\n右下の「範囲からつくる」から作ってみよう。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TsuzuriColors.inkSoft),
                    ),
                  ),
                for (final p in plans) _PlanCard(plan: p),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final ExamWorldPlan plan;

  @override
  Widget build(BuildContext context) {
    final world = RpgCatalog.world(plan.worldId);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExamWorldPlayScreen(planId: plan.id),
          ),
        ),
        leading: Icon(
          plan.completed ? Icons.emoji_events : Icons.map_outlined,
          color: plan.completed ? TsuzuriColors.exp : _seaBlue,
        ),
        title: Text(plan.title, style: serif(15)),
        subtitle: Text(
          '${world.subject}・${plan.rangeText.isEmpty ? '${plan.stageIds.length}エリア' : plan.rangeText}\n'
          '${plan.clearedCount} / ${plan.length} クリア',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: '消す',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text('「${plan.title}」を消しますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('やめる'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('消す'),
                  ),
                ],
              ),
            );
            if (ok == true && context.mounted) {
              await RpgServices.of(context).examWorlds.remove(plan.id);
            }
          },
        ),
      ),
    );
  }
}

/// 試験範囲を入力して、ワールドを作る画面
class ExamWorldCreateScreen extends StatefulWidget {
  const ExamWorldCreateScreen({super.key});

  @override
  State<ExamWorldCreateScreen> createState() => _ExamWorldCreateScreenState();
}

class _ExamWorldCreateScreenState extends State<ExamWorldCreateScreen> {
  final _title = TextEditingController();
  final _range = TextEditingController();
  String? _worldId;
  final _selected = <String>{};
  String? _message;

  @override
  void dispose() {
    _title.dispose();
    _range.dispose();
    super.dispose();
  }

  void _search() {
    final world = RpgCatalog.world(_worldId!);
    final found = ExamWorlds.match(world, _range.text);
    setState(() {
      _selected
        ..clear()
        ..addAll(found.take(ExamWorlds.maxAreas).map((s) => s.id));
      _message = found.isEmpty
          ? '合うエリアが見つかりませんでした。単元名（例：2次関数、助動詞、明治維新）で入力するか、下の一覧から選んでください。'
          : found.length > ExamWorlds.maxAreas
          ? '${found.length}エリア見つかりました。多すぎるので、最初の${ExamWorlds.maxAreas}エリアを選びました。'
          : '${found.length}エリア見つかりました。下の一覧で、足したり外したりできます。';
    });
  }

  Future<void> _create() async {
    final world = RpgCatalog.world(_worldId!);
    final ids = [
      for (final s in world.stages)
        if (_selected.contains(s.id)) s.id,
    ];
    final title = _title.text.trim().isEmpty
        ? '${world.subject}の試験対策'
        : _title.text.trim();
    final plan = ExamWorldPlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      worldId: world.id,
      stageIds: ids,
      createdAt: DateTime.now(),
      rangeText: _range.text.trim(),
    );
    await RpgServices.of(context).examWorlds.add(plan);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ExamWorldPlayScreen(planId: plan.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F0F5),
        title: Text('範囲からワールドをつくる', style: serif(17, color: _seaBlue)),
      ),
      body: NotebookPaper(
        child: StreamBuilder<RpgProgress>(
          stream: services.repository.watch(),
          builder: (context, snap) {
            final progress = snap.data ?? RpgProgress.initial;
            final world = _worldId == null ? null : RpgCatalog.world(_worldId!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text('1. 教科', style: serif(15)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final w in RpgCatalog.worlds)
                      if (!w.isComingSoon)
                        ChoiceChip(
                          avatar: Progression.isWorldPlayable(progress, w)
                              ? null
                              : const Icon(Icons.lock, size: 16),
                          label: Text(w.subject),
                          selected: _worldId == w.id,
                          onSelected: Progression.isWorldPlayable(progress, w)
                              ? (_) => setState(() {
                                  _worldId = w.id;
                                  _selected.clear();
                                  _message = null;
                                })
                              : null,
                        ),
                  ],
                ),
                const Text(
                  '🔒 の教科は、RPG でワールドを解放すると使えます。',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),
                Text('2. 試験の名前', style: serif(15)),
                const SizedBox(height: 6),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    hintText: '例：2学期中間テスト',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text('3. 試験範囲', style: serif(15)),
                const SizedBox(height: 6),
                TextField(
                  controller: _range,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '単元名を「、」で区切って入力\n例：2次関数、三角比、データの分析',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: world == null ? null : _search,
                    icon: const Icon(Icons.search),
                    label: const Text('範囲から探す'),
                  ),
                ),
                if (world == null)
                  const Text(
                    'まず教科を選んでください。',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _message!,
                      style: const TextStyle(fontSize: 12.5, height: 1.5),
                    ),
                  ),
                if (world != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '4. 入れるエリア（${_selected.length} / ${ExamWorlds.maxAreas}）',
                    style: serif(15),
                  ),
                  ..._areaList(world),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        _selected.isEmpty ||
                            _selected.length > ExamWorlds.maxAreas
                        ? null
                        : _create,
                    icon: const Icon(Icons.auto_awesome),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _selected.isEmpty
                            ? 'エリアを選んでください'
                            : 'ワールドをつくる（${_selected.length}エリア＋試験本番）',
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _areaList(WorldDef world) {
    final out = <Widget>[];
    String? header;
    for (final s in world.stages) {
      final h = s.branch.isEmpty
          ? s.region
          : '${world.route(s.branch)?.name ?? ''}・${s.region}';
      if (h != header) {
        header = h;
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(
              h,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _seaBlue,
              ),
            ),
          ),
        );
      }
      out.add(
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _selected.contains(s.id),
          onChanged: (v) => setState(() {
            if (v == true) {
              _selected.add(s.id);
            } else {
              _selected.remove(s.id);
            }
          }),
          title: Text(
            s.grammarTheme.isEmpty ? s.name : s.grammarTheme,
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            RpgCatalog.stageLabel(s),
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    }
    return out;
  }
}

/// 作ったワールドを遊ぶ画面（1本道）
class ExamWorldPlayScreen extends StatelessWidget {
  const ExamWorldPlayScreen({super.key, required this.planId});
  final String planId;

  Future<void> _start(
    BuildContext context,
    ExamWorldPlan plan,
    StageDef stage,
    int index,
  ) async {
    final services = RpgServices.of(context);
    final pool = await services.loadStagePool(stage);
    final progress = await services.repository.load();
    if (pool == null || !pool.origin.usableInRpg || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(plan.worldId),
          stage: stage,
          questions: pool.questions,
          progress: progress,
          // RPG の進行・経験値は変えない（練習用）
          trial: true,
          onFinished: (summary) {
            if (!summary.won) return;
            final latest = services.examWorlds.byId(plan.id);
            if (latest == null || latest.clearedCount > index) return;
            services.examWorlds.update(
              latest.copyWith(clearedCount: index + 1),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = RpgServices.of(context).examWorlds;
    return StreamBuilder<List<ExamWorldPlan>>(
      stream: store.watch(),
      builder: (context, snap) {
        final plan = store.byId(planId);
        if (plan == null) {
          return const Scaffold(body: Center(child: Text('ワールドが見つかりません')));
        }
        final world = RpgCatalog.world(plan.worldId);
        final stages = ExamWorlds.build(plan);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFE6F0F5),
            title: Text(plan.title, style: serif(18, color: _seaBlue)),
          ),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text(
                  '${world.subject}・${plan.rangeText.isEmpty ? '選んだエリア' : plan.rangeText}',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: plan.clearedCount / plan.length,
                    minHeight: 8,
                    backgroundColor: TsuzuriColors.gridLine,
                    color: TsuzuriColors.exp,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.clearedCount} / ${plan.length} クリア　'
                  '※ RPG の進行や経験値には影響しません。何度でも挑戦できます。',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
                if (plan.completed)
                  Card(
                    color: const Color(0xFFFFF4D6),
                    margin: const EdgeInsets.only(top: 12),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('🎉 試験本番のボスまで全部クリア！ 本番もこの調子でがんばろう。'),
                    ),
                  ),
                const SizedBox(height: 12),
                for (var i = 0; i < stages.length; i++)
                  _StageNode(
                    stage: stages[i],
                    index: i,
                    cleared: i < plan.clearedCount,
                    open: i <= plan.clearedCount,
                    last: i == stages.length - 1,
                    onTap: () => _start(context, plan, stages[i], i),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.index,
    required this.cleared,
    required this.open,
    required this.last,
    required this.onTap,
  });

  final StageDef stage;
  final int index;
  final bool cleared;
  final bool open;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = stage.isBoss ? TsuzuriColors.stamp : _seaBlue;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: open
                      ? (cleared ? TsuzuriColors.correct : color)
                      : Colors.grey.shade400,
                  child: cleared
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : open
                      ? (stage.isBoss
                            ? const Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ))
                      : const Icon(Icons.lock, color: Colors.white, size: 16),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 3, color: TsuzuriColors.kraft),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  enabled: open,
                  onTap: open ? onTap : null,
                  title: Text(
                    stage.isBoss ? '試験本番（範囲全部から出題）' : stage.grammarTheme,
                    style: serif(14),
                  ),
                  subtitle: Text(
                    '${stage.name}・${stage.enemy.name}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: open
                      ? const Icon(Icons.play_arrow_rounded)
                      : const Text(
                          '前のエリアを\nクリアで解放',
                          style: TextStyle(fontSize: 10),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
