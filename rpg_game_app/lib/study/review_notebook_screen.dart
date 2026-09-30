import 'package:flutter/material.dart';

import '../quiz/figure_view.dart';

import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';

/// 復習手帳：バトルでまちがえた問題（亡霊）を、くわしい解説つきでまとめて見る
class ReviewNotebookScreen extends StatefulWidget {
  const ReviewNotebookScreen({
    super.key,
    required this.world,
    required this.progress,
  });

  final WorldDef world;
  final RpgProgress progress;

  @override
  State<ReviewNotebookScreen> createState() => _ReviewNotebookScreenState();
}

class _ReviewNotebookScreenState extends State<ReviewNotebookScreen> {
  /// ステージ → まちがえた問題
  Future<List<(StageDef, List<QuizQuestion>)>>? _entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entries ??= _load(RpgServices.of(context));
  }

  Future<List<(StageDef, List<QuizQuestion>)>> _load(
    RpgServices services,
  ) async {
    final mistakes = widget.progress.mistakes;
    final result = <(StageDef, List<QuizQuestion>)>[];
    for (final stage in widget.world.stages) {
      final ids = {
        for (final e in mistakes.entries)
          if (e.value == stage.id) e.key,
      };
      if (ids.isEmpty) continue;
      final set = await services.loadStagePool(stage);
      if (set == null) continue;
      final qs = set.questions.where((q) => ids.contains(q.id)).toList();
      if (qs.isNotEmpty) result.add((stage, qs));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('復習手帳', style: serif(18))),
      body: NotebookPaper(
        child: FutureBuilder(
          future: _entries,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'まちがえた問題はまだないよ。\nバトルでまちがえると、ここにくわしい解説が書きこまれる。',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.7),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text(
                  'まちがえた問題は、フィールドで「亡霊」になってさまよっている。'
                  'ここで解説を読んでから話しかけて、成仏させよう。',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TsuzuriColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                for (final (stage, qs) in entries) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${RpgCatalog.stageLabel(stage)}「${stage.name}」（${qs.length}問）',
                    style: serif(15, color: TsuzuriColors.accent),
                  ),
                  const SizedBox(height: 6),
                  for (final q in qs) _item(q),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item(QuizQuestion q) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ExpansionTile(
      shape: const Border(),
      title: Text(
        q.passage != null
            ? '📜 ${q.passage!.title}：${q.prompt}'
            : (q.sentence ?? q.prompt),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '正解：${q.answer}',
        style: const TextStyle(
          color: TsuzuriColors.correct,
          fontWeight: FontWeight.w700,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.sentence != null)
          Text(q.prompt, style: const TextStyle(fontSize: 12.5)),
        if (q.figure != null) FigureView(q.figure!, height: 120),
        const SizedBox(height: 4),
        Text(
          '選択肢：${q.choices.join(' / ')}',
          style: TextStyle(fontSize: 12.5, color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 6),
        Text(
          q.explanation ?? '',
          style: const TextStyle(fontSize: 13.5, height: 1.7),
        ),
      ],
    ),
  );
}
