import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../audio/music_director.dart';
import '../audio/music_scope.dart';
import '../battle/battle_screen.dart';
import '../field/field_screen.dart';

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
    final days = plan.daysLeft(DateTime.now());
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
          '${plan.subjectsLabel}・${plan.rangeText.isEmpty ? '${plan.stageIds.length}エリア' : plan.rangeText}\n'
          '${plan.clearedCount} / ${plan.length} クリア・対策ゲージ ${plan.gauge}'
          '${days == null
              ? ''
              : days < 0
              ? '・試験は終了'
              : days == 0
              ? '・今日が試験！'
              : '・あと$days日'}',
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

  /// 選んだ教科（ワールドID）→ その教科の試験範囲の入力欄
  final _ranges = <String, TextEditingController>{};
  final _selected = <String>{};
  DateTime? _examDate;
  String? _message;

  @override
  void dispose() {
    _title.dispose();
    for (final c in _ranges.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// 選んだ教科の並び（ワールドの並び順）
  List<WorldDef> get _worlds => [
    for (final w in RpgCatalog.worlds)
      if (_ranges.containsKey(w.id)) w,
  ];

  void _toggleWorld(WorldDef w, bool on) => setState(() {
    if (on) {
      _ranges[w.id] = TextEditingController();
    } else {
      _ranges.remove(w.id)?.dispose();
      _selected.removeWhere((id) => ExamWorlds.stageById(id)?.worldId == w.id);
    }
    _message = null;
  });

  void _search() {
    final found = ExamWorlds.matchAll({
      for (final w in _worlds) w.id: _ranges[w.id]!.text,
    });
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: '試験の日',
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _create() async {
    final ids = [
      for (final w in _worlds)
        for (final s in w.stages)
          if (_selected.contains(s.id)) s.id,
    ];
    final subjects = _worlds.map((w) => w.subject).join('・');
    final title = _title.text.trim().isEmpty
        ? '$subjectsの試験対策'
        : _title.text.trim();
    final plan = ExamWorldPlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      worldId: _worlds.first.id,
      stageIds: ids,
      createdAt: DateTime.now(),
      rangeText: [
        for (final w in _worlds)
          if (_ranges[w.id]!.text.trim().isNotEmpty)
            '${w.subject}：${_ranges[w.id]!.text.trim()}',
      ].join('／'),
      examDate: _examDate,
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
            final worlds = _worlds;
            return ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text('1. 教科（いくつでも）', style: serif(15)),
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
                          selected: _ranges.containsKey(w.id),
                          onSelected: Progression.isWorldPlayable(progress, w)
                              ? (on) => _toggleWorld(w, on)
                              : null,
                        ),
                  ],
                ),
                const Text(
                  '6教科を1つのワールドにまとめられます。🔒 の教科は、RPG でワールドを解放すると使えます。',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 16),
                Text('2. 試験の名前と日にち', style: serif(15)),
                const SizedBox(height: 6),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    hintText: '例：2学期中間テスト',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _examDate == null
                        ? '試験の日を決める（任意）'
                        : '試験の日：${_examDate!.month}月${_examDate!.day}日',
                  ),
                ),
                const SizedBox(height: 16),
                Text('3. 教科ごとの試験範囲', style: serif(15)),
                const SizedBox(height: 6),
                if (worlds.isEmpty)
                  const Text(
                    'まず教科を選んでください。',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                for (final w in worlds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _ranges[w.id],
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: w.subject,
                        hintText: _hintFor(w.id),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: worlds.isEmpty ? null : _search,
                    icon: const Icon(Icons.search),
                    label: const Text('範囲から探す'),
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
                if (worlds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '4. 入れるエリア（${_selected.length} / ${ExamWorlds.maxAreas}）',
                    style: serif(15),
                  ),
                  for (final w in worlds) ..._areaList(w),
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
                            : 'ワールドとフィールドをつくる（${_selected.length}エリア＋試験本番）',
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

  static String _hintFor(String worldId) => switch (worldId) {
    'math' => '例：2次関数、三角比、データの分析',
    'english' => '例：関係詞、仮定法',
    'japanese' => '例：助動詞、敬語、漢字',
    'science' => '例：化学基礎、物質量、酸と塩基',
    'social' => '例：明治維新、日本国憲法',
    'information' => '例：ネットワーク、アルゴリズム',
    _ => '単元名を「、」で区切って入力',
  };

  List<Widget> _areaList(WorldDef world) {
    final out = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          '— ${world.subject}（${world.name}）',
          style: serif(14, color: _seaBlue),
        ),
      ),
    ];
    String? header;
    for (final s in world.stages) {
      final h = s.branch.isEmpty
          ? s.region
          : '${world.route(s.branch)?.name ?? ''}・${s.region}';
      if (h != header) {
        header = h;
        out.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
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
            '${RpgCatalog.stageLabel(s)}・${s.name}',
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
    // 定期テストの海と同じ「とても難しい」強さで戦う
    final hard = ExamWorlds.build(plan, level: progress.level)[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(hard.worldId),
          stage: hard,
          questions: pool.questions,
          progress: progress,
          // RPG の進行・経験値は変えない（練習用）
          trial: true,
          mode: BattleMode.exam,
          onFinished: (summary) {
            if (!summary.won) return;
            final latest = services.examWorlds.byId(plan.id);
            if (latest == null || latest.clearedCount > index) return;
            services.examWorlds.update(
              latest
                  .copyWith(clearedCount: index + 1)
                  .addGauge(hard.isBoss ? 15 : 6),
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
        final stages = ExamWorlds.build(plan);
        final days = plan.daysLeft(DateTime.now());
        // 今日のおすすめ：まだクリアしていないエリアから、試験までの日数で割った数
        final remaining = stages.length - plan.clearedCount;
        final perDay = days == null || days <= 0
            ? remaining.clamp(0, 3)
            : (remaining / days).ceil().clamp(1, remaining);
        final today = [
          for (
            var i = plan.clearedCount;
            i < stages.length && i < plan.clearedCount + perDay;
            i++
          )
            stages[i],
        ];
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
                  '${plan.subjectsLabel}・${plan.rangeText.isEmpty ? '選んだエリア' : plan.rangeText}',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                if (days != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days < 0
                          ? '試験は終わりました。おつかれさま！'
                          : days == 0
                          ? '⚠️ 今日が試験の日！'
                          : '⚠️ 試験まであと $days 日',
                      style: serif(16, color: TsuzuriColors.stamp),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'テスト対策ゲージ ${plan.gauge} / ${ExamWorlds.gaugeMax}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: plan.gauge / ExamWorlds.gaugeMax,
                    minHeight: 10,
                    backgroundColor: TsuzuriColors.gridLine,
                    color: _seaBlue,
                  ),
                ),
                if (today.isNotEmpty && !plan.completed)
                  Card(
                    margin: const EdgeInsets.only(top: 12),
                    color: const Color(0xFFE6F0F5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('今日のおすすめ学習', style: serif(14)),
                          const SizedBox(height: 4),
                          for (final st in today)
                            Text(
                              '・${RpgCatalog.world(st.worldId).subject}：${st.isBoss ? '試験本番（範囲全部）' : st.grammarTheme}',
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _seaBlue),
                  onPressed: () async {
                    final services = RpgServices.of(context);
                    final progress = await services.repository.load();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MusicScope(
                          music: MusicDirector.fieldKey(stages.first.worldId),
                          child: FieldScreen.exam(
                            plan: plan,
                            progress: progress,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('フィールドで冒険する'),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '歩いて進むフィールドでも、下の一覧からでも、同じ記録で遊べます。',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 12),
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
                    '${RpgCatalog.world(stage.worldId).subject}・${stage.name}・${stage.enemy.name}',
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
