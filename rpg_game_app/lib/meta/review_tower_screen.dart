import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import 'design.dart';

/// 復習の塔。まちがえた問題・復習の日が来た問題・時間がかかった問題で戦う。
class ReviewTowerScreen extends StatefulWidget {
  const ReviewTowerScreen({super.key});

  @override
  State<ReviewTowerScreen> createState() => _ReviewTowerScreenState();
}

class _ReviewTowerScreenState extends State<ReviewTowerScreen> {
  /// null ならすべての教科
  String? _subject;

  /// 1回の挑戦で出す問題の数
  static const _size = 10;

  Future<List<(ReviewItem, QuizQuestion)>> _load(RpgServices services) async {
    final plan = ReviewPlanner.plan(
      services.meta.record,
      today: RpgServices.today(),
      limit: _size,
      subject: _subject,
    );
    final out = <(ReviewItem, QuizQuestion)>[];
    for (final item in plan) {
      final set = await services.questions.load(item.setId);
      final q = set?.questions.where((q) => q.id == item.questionId);
      if (q != null && q.isNotEmpty) out.add((item, q.first));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final meta = services.meta;
    return Scaffold(
      appBar: AppBar(title: const Text('復習の塔')),
      body: NotebookPaper(
        child: ListenableBuilder(
          listenable: meta,
          builder: (context, _) {
            final floor = ReviewTower.floorOf(meta.journal.reviewCorrect);
            final subjects = {
              for (final s in meta.record.stats.values)
                if (s.setId.isNotEmpty) LearningRecord.subjectOf(s.setId),
            }.toList()..sort();
            return FutureBuilder<List<(ReviewItem, QuizQuestion)>>(
              future: _load(services),
              builder: (context, snap) {
                final items = snap.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Space.margin,
                    Space.m,
                    Space.m,
                    Space.xl,
                  ),
                  children: [
                    PaperCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.castle_outlined,
                            size: 40,
                            color: TsuzuriColors.accent,
                          ),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('いま $floor 階', style: serif(18)),
                                Text(
                                  '復習で ${ReviewTower.correctPerFloor} 問正解するごとに1階上へ。'
                                  '5階ごとに塔の番人が待っています。',
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
                    const SizedBox(height: Space.m),
                    Wrap(
                      spacing: Space.s,
                      children: [
                        ChoiceChip(
                          label: const Text('すべて'),
                          selected: _subject == null,
                          onSelected: (_) => setState(() => _subject = null),
                        ),
                        for (final id in subjects)
                          ChoiceChip(
                            avatar: Icon(subjectIcons[id], size: 16),
                            label: Text(_subjectName(id)),
                            selected: _subject == id,
                            onSelected: (_) => setState(() => _subject = id),
                          ),
                      ],
                    ),
                    const SizedBox(height: Space.m),
                    if (snap.connectionState != ConnectionState.done)
                      const Center(child: CircularProgressIndicator())
                    else if (items.isEmpty)
                      const PaperCard(
                        child: Text(
                          'いまは復習する問題がありません。\n'
                          'バトルでまちがえた問題や、しばらく解いていない問題が、'
                          'ここに集まってきます。',
                          style: TextStyle(height: 1.6),
                        ),
                      )
                    else ...[
                      SectionTitle(
                        '今回の相手：${items.length} 問',
                        trailing: FilledButton.icon(
                          onPressed: () => _start(context, floor, [
                            for (final (_, q) in items) q,
                          ], items.first.$1.setId),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('挑戦する'),
                        ),
                      ),
                      for (final (item, q) in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.xs),
                          child: PaperCard(
                            border: TsuzuriColors.kraft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.m,
                              vertical: Space.s,
                            ),
                            child: Row(
                              children: [
                                _ReasonChip(item.reason),
                                const SizedBox(width: Space.s),
                                Expanded(
                                  child: Text(
                                    q.sentence == null
                                        ? q.prompt
                                        : '${q.prompt}　${q.sentence}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _subjectName(String id) {
    for (final w in RpgCatalog.worlds) {
      if (w.id == id) return w.subject;
    }
    return id;
  }

  Future<void> _start(
    BuildContext context,
    int floor,
    List<QuizQuestion> questions,
    String firstSetId,
  ) async {
    final services = RpgServices.of(context);
    final progress = await services.repository.load();
    final worldId = LearningRecord.subjectOf(firstSetId);
    final world = RpgCatalog.worlds.firstWhere(
      (w) => w.id == worldId,
      orElse: () => RpgCatalog.worlds.first,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: world,
          stage: ReviewTower.stage(
            level: progress.level,
            floor: floor,
            questionCount: questions.length,
            worldId: world.id,
          ),
          questions: questions,
          progress: progress,
          // 経験値はデイリークエストの報酬で受け取る
          trial: true,
          mode: BattleMode.review,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip(this.reason);
  final String reason;

  @override
  Widget build(BuildContext context) {
    final color = switch (reason) {
      'まちがえた' => TsuzuriColors.wrong,
      '復習の日' => const Color(0xFF3F7CAC),
      '時間がかかった' => const Color(0xFFD9822B),
      _ => TsuzuriColors.inkSoft,
    };
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: color),
      ),
      alignment: Alignment.center,
      child: Text(reason, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
