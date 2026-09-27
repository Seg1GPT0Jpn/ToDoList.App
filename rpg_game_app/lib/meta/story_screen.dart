import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../story/story_player.dart';

/// 物語：知識の世界と6つの欠片。6つそろうと「世界の中心」の決戦に挑める
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  /// エピローグをもう見せはじめた
  bool _epilogueShown = false;

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
        // 魔王をたおしたら、エピローグを一度だけ見せる
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
                  label: const Text('序章「しおりの精」を読む'),
                ),
                const SizedBox(height: 16),
                Text('知識の欠片（${got.length} / 6）', style: serif(16)),
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
                        '${RpgCatalog.world(w.worldId).name}：${got.contains(w.worldId) ? w.fragment : '？？？の欠片'}',
                      ),
                      subtitle: Text(
                        got.contains(w.worldId)
                            ? '${w.clearText}\n手に入れた：${w.key}・${GearDef.byId(GearDef.byFragment[w.worldId]!).name}'
                            : '${Story.finalsOf(w.worldId).map((s) => s.name).join('・')}のボスをすべて倒すと取りもどせる',
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  color: open ? const Color(0xFFEDE7F6) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🌎 世界の中心', style: serif(17)),
                        const SizedBox(height: 4),
                        Text(
                          won
                              ? '忘却の魔王をたおし、知識の世界はふたたび一つになった。…でも、学びの旅はまだ続く。何度でも挑戦できる。'
                              : open
                              ? '6つの欠片が道を照らしている。知識を奪った「忘却の魔王」との最終決戦。6教科の最後のボスの範囲すべてから出題される（共通テスト総合）。'
                              : '6つの欠片がそろうと、道がひらく。',
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
                const Text(
                  '読んだ場面は、ここで何度でも読み返せます。国に入る・最後のボスに挑む・欠片を取りもどすと、新しい場面が読めます。',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
