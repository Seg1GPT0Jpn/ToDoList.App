import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../story/story_player.dart';
import '../versus/versus_screen.dart';

/// 物語：白紙の聖典と大樹アカデミア。五つの証がそろうと「天空の図書院」の決戦に挑める
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  /// エピローグをもう見せはじめた
  bool _epilogueShown = false;

  /// 道の果てで出会った守護者と、その国の問題で早押し勝負（救った国が多いほど強い）
  Future<void> _rivalMatch(BuildContext context, String worldId) async {
    final story = Story.of(worldId);
    final services = RpgServices.of(context);
    final stages = [...RpgCatalog.world(worldId).stages.where((s) => !s.isBoss)]
      ..shuffle();
    final setIds = [for (final s in stages.take(4)) s.questionSetIds.first];
    final questions = await loadVersusQuestions(services, setIds);
    if (!context.mounted || questions.isEmpty) return;
    final saved = Story.fragments(await services.repository.load()).length;
    if (!context.mounted) return;
    final level = CpuLevel.values[(saved * CpuLevel.values.length) ~/
        (Story.worlds.length + 1)];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VersusScreen(
          questions: questions,
          names: [services.profiles.load().displayName, story.guardian],
          cpu: level,
          rounds: 10,
          rivalLook: story.guardianLook,
          rivalColor: story.guardianColor,
        ),
      ),
    );
  }

  Future<void> _challengeCenter(BuildContext context) async {
    final services = RpgServices.of(context);
    final before = await services.repository.load();
    if (!context.mounted) return;
    if (!StoryScenes.seen(before, StoryScenes.finaleBefore)) {
      await playStoryScenes(context, [StoryScenes.finaleBefore]);
      if (!context.mounted) return;
    }
    final stage = Story.centerStage();
    final pool = await services.loadStagePool(stage);
    final progress = await services.repository.load();
    if (pool == null || !pool.origin.usableInRpg || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(RpgCatalog.englishWorldId),
          stage: stage,
          questions: pool.questions,
          progress: progress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return StreamBuilder<RpgProgress>(
      stream: services.repository.watch(),
      builder: (context, snap) {
        final p = snap.data ?? RpgProgress.initial;
        final got = Story.fragments(p);
        final open = Story.centerOpen(p);
        final won = p.clearedStageIds.contains(Story.centerStageId);
        // ネブラをたおしたら、エピローグを一度だけ見せる
        if (won &&
            !_epilogueShown &&
            !StoryScenes.seen(p, StoryScenes.epilogue)) {
          _epilogueShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) playStoryScenes(context, [StoryScenes.epilogue]);
          });
        }
        final seen = StoryScenes.unlocked(p).map((s) => s.id).toSet();
        return Scaffold(
          appBar: AppBar(title: Text('物語', style: serif(18))),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text(
                  Story.title,
                  style: serif(20, color: TsuzuriColors.accent),
                ),
                const SizedBox(height: 8),
                for (final line in Story.prologue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      line,
                      style: const TextStyle(fontSize: 14, height: 1.7),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => playStoryScenes(context, [
                    StoryScenes.prologue,
                  ], replay: seen.contains(StoryScenes.prologue.id)),
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('序章「白紙の旅立ち」を読む'),
                ),
                const SizedBox(height: 16),
                Text('五つの証（${got.length} / ${Story.worlds.length}）', style: serif(16)),
                const SizedBox(height: 6),
                for (final w in Story.worlds)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        got.contains(w.worldId)
                            ? Icons.auto_awesome
                            : Icons.lock_outline,
                        color: got.contains(w.worldId)
                            ? TsuzuriColors.exp
                            : TsuzuriColors.inkSoft,
                      ),
                      title: Text(
                        '${RpgCatalog.world(w.worldId).name}：${got.contains(w.worldId) ? w.fragment : '？？？'}',
                      ),
                      trailing: StoryScenes.seen(p, StoryScenes.boss(w.worldId))
                          ? IconButton(
                              tooltip: '${w.guardian}と早押し勝負',
                              icon: const Icon(Icons.sports_esports),
                              onPressed: () => _rivalMatch(context, w.worldId),
                            )
                          : null,
                      subtitle: Text(
                        got.contains(w.worldId)
                            ? '${w.clearText}\n手に入れた：${w.fragment}・${GearDef.byId(GearDef.byFragment[w.worldId]!).name}'
                            : '狂気に呑まれた${w.guardian}が、${Story.finalsOf(w.worldId).map((s) => s.name).join('・')}で待っている。すべての道の果てで勝つと、正気にもどる',
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  color: open ? TsuzuriColors.tint(0xFFEDE7F6) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📚 天空の図書院', style: serif(17)),
                        const SizedBox(height: 4),
                        Text(
                          won
                              ? '虚無の霧ネブラを晴らし、大樹アカデミアに満開の花が咲いた。…でも、学びの旅はまだ続く。何度でも挑戦できる。'
                              : open
                              ? '五つの証が光の柱を呼んだ。書架を灰色に染める黒い霧「ネブラ」との最終決戦。5教科の道の果ての範囲すべてから出題される（小中学校の総まとめ）。'
                              : '五つの国の守護者を正気にもどし、五つの証がそろうと、光の柱があらわれる。',
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: open
                              ? () => _challengeCenter(context)
                              : null,
                          icon: const Icon(Icons.local_fire_department),
                          label: Text(won ? 'もう一度挑む' : '決戦に挑む'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '物語の回想（${seen.length} / ${StoryScenes.all.length}）',
                  style: serif(16),
                ),
                const SizedBox(height: 4),
                Text(
                  '読んだ場面は、ここで何度でも読み返せます。国に入る・道の果ての守護者に挑む・守護者から証を受け取ると、新しい場面が読めます。',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
                const SizedBox(height: 6),
                for (final s in StoryScenes.all)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      seen.contains(s.id)
                          ? Icons.menu_book
                          : Icons.lock_outline,
                      color: seen.contains(s.id)
                          ? Color(s.color)
                          : TsuzuriColors.inkSoft,
                    ),
                    title: Text(seen.contains(s.id) ? s.title : '？？？'),
                    onTap: seen.contains(s.id)
                        ? () => playStoryScenes(context, [s], replay: true)
                        : null,
                  ),
                const SizedBox(height: 20),
                Text('5つの国の物語', style: serif(16)),
                const SizedBox(height: 4),
                for (final n in Lore.nations) _NationCard(lore: n, progress: p),
                const SizedBox(height: 16),
                _ArchiveSection(entries: Lore.archive(p)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 国の設定（国民・守護者・狂気に呑まれた理由・学ぶ理由）。国に入ると読める
class _NationCard extends StatelessWidget {
  const _NationCard({required this.lore, required this.progress});

  final NationLore lore;
  final RpgProgress progress;

  @override
  Widget build(BuildContext context) {
    final world = RpgCatalog.world(lore.worldId);
    final visited = Lore.progressOf(progress, lore.worldId) > 0;
    Widget item(String label, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label　',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: TsuzuriColors.accent,
              ),
            ),
            TextSpan(text: text),
          ],
        ),
        style: const TextStyle(fontSize: 13, height: 1.6),
      ),
    );
    return Card(
      key: ValueKey('nation-${lore.worldId}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(
          visited ? Icons.flag : Icons.lock_outline,
          color: visited ? TsuzuriColors.accent : TsuzuriColors.inkSoft,
        ),
        title: Text(world.name, style: serif(15)),
        subtitle: Text(
          visited ? '「${lore.motto}」' : 'この国のエリアを1つクリアすると読める',
          style: const TextStyle(fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: visited
            ? [
                item('国', lore.land),
                item('国民', lore.people),
                item('守護者', '${lore.guardian}。${lore.guardianNote}'),
                item('黒い霧', lore.forgotten),
                item('学ぶ理由', lore.whyLearn),
                item('伏線', '${lore.midBossNote}\n${lore.bossNote}'),
              ]
            : const [],
      ),
    );
  }
}

/// ストーリーアーカイブ：進むと読める短い物語
class _ArchiveSection extends StatelessWidget {
  const _ArchiveSection({required this.entries});

  final List<ArchiveEntry> entries;

  @override
  Widget build(BuildContext context) {
    final read = entries.where((e) => e.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ストーリーアーカイブ（$read / ${entries.length}）', style: serif(16)),
        const SizedBox(height: 4),
        for (final e in entries)
          ListTile(
            key: ValueKey('archive-${e.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              e.unlocked ? Icons.history_edu : Icons.lock_outline,
              color: e.unlocked ? TsuzuriColors.accent : TsuzuriColors.inkSoft,
            ),
            title: Text(e.title),
            subtitle: Text(
              e.unlocked ? e.text : e.hint,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: e.unlocked ? null : TsuzuriColors.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}
