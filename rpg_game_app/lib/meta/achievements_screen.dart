import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'design.dart';

/// 実績と称号。解除した実績は、名前の上に出す称号にできる。
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final meta = services.meta;
    return Scaffold(
      appBar: AppBar(title: const Text('実績・称号')),
      body: NotebookPaper(
        child: StreamBuilder<RpgProgress>(
          stream: services.repository.watch(),
          builder: (context, snap) => ListenableBuilder(
            listenable: meta,
            builder: (context, _) {
              final c = AchievementContext(
                progress: snap.data ?? RpgProgress.initial,
                record: meta.record,
                journal: meta.journal,
                today: RpgServices.today(),
              );
              final got = meta.journal.achievements;
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.margin,
                  Space.m,
                  Space.m,
                  Space.xl,
                ),
                children: [
                  Text(
                    '解除 ${got.length} / ${Achievements.all.length}'
                    '　いまの称号：${meta.journal.title.isEmpty ? 'なし' : meta.journal.title}',
                    style: const TextStyle(color: TsuzuriColors.inkSoft),
                  ),
                  for (final g in AchievementGroup.values) ...[
                    const SizedBox(height: Space.m),
                    SectionTitle(g.label),
                    for (final a in Achievements.all.where((a) => a.group == g))
                      _AchievementTile(
                        def: a,
                        value: a.value(c),
                        unlocked: got.containsKey(a.id),
                        selected: meta.journal.title == a.title,
                        onSelect: () => meta.save(
                          journal: meta.journal.copyWith(
                            title: meta.journal.title == a.title ? '' : a.title,
                          ),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.def,
    required this.value,
    required this.unlocked,
    required this.selected,
    required this.onSelect,
  });

  final AchievementDef def;
  final int value;
  final bool unlocked;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(def.rarity);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: PaperCard(
        border: unlocked ? color : TsuzuriColors.kraft,
        child: Row(
          children: [
            Icon(
              unlocked ? Icons.emoji_events : Icons.lock_outline,
              color: unlocked ? color : TsuzuriColors.inkSoft,
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.title, style: serif(14)),
                  Text(
                    '${def.description}　${stars(def.rarity)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: Space.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (value / def.goal).clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEDE3D1),
                        color: color,
                      ),
                    ),
                    Text(
                      '${value.clamp(0, def.goal)} / ${def.goal}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (unlocked)
              TextButton(
                onPressed: onSelect,
                child: Text(selected ? '称号をはずす' : '称号にする'),
              ),
          ],
        ),
      ),
    );
  }
}
