import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import 'vocab_session_screen.dart';
import 'vocab_store.dart';

/// 苦手克服カードの一覧。
///
/// 2回以上間違えた単語を、続けて2回正解すると1枚。間違えた回数が多いほどレア（★1〜3）。
/// また間違えると、カードはいったん「挑戦中」に戻る
class WeakCardsScreen extends StatefulWidget {
  const WeakCardsScreen({super.key, required this.store});

  final VocabStore store;

  @override
  State<WeakCardsScreen> createState() => _WeakCardsScreenState();
}

class _WeakCardsScreenState extends State<WeakCardsScreen> {
  Future<void> _practice(VocabBook b) async {
    final tasks = WeakCards.practice(b, widget.store.progress(b.id));
    if (tasks.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocabSessionScreen(
          store: widget.store,
          book: b,
          title: '${b.title} 苦手克服',
          tasks: tasks,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final books = [
      for (final b in widget.store.visibleBooks)
        if (b.cards.isNotEmpty) b,
    ];
    var total = 0;
    final sections = <Widget>[];
    for (final b in books) {
      final p = widget.store.progress(b.id);
      final got = WeakCards.collected(b, p);
      final waiting = WeakCards.waiting(b, p);
      if (got.isEmpty && waiting.isEmpty) continue;
      total += got.length;
      sections.addAll([
        const SizedBox(height: 12),
        Text(
          '${b.title}　${got.length}枚（挑戦中 ${waiting.length}語）',
          style: serif(16),
        ),
        const SizedBox(height: 6),
        if (got.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final w in got) WeakCardTile(w)],
          ),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'もう少し：${waiting.take(8).map((w) => w.card.term).join('、')}'
            '${waiting.length > 8 ? ' ほか' : ''}',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            key: ValueKey('weak-practice-${b.id}'),
            onPressed: () => _practice(b),
            icon: const Icon(Icons.fitness_center),
            label: Text(
              '苦手な単語を練習（${waiting.length > 20 ? 20 : waiting.length}語）',
            ),
          ),
        ],
      ]);
    }
    return Scaffold(
      appBar: AppBar(title: Text('苦手克服カード', style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
          children: [
            Text('集めたカード $total枚', style: serif(18)),
            const SizedBox(height: 4),
            Text(
              '2回以上間違えた単語を、続けて2回正解すると1枚。'
              '間違えた回数が多い単語ほどレア（★〜★★★）。また間違えたら、もう一度挑戦です。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            if (sections.isEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'まだ苦手な単語はありません。間違えた単語が、ここで克服を待ちます。',
                key: ValueKey('weak-empty'),
              ),
            ],
            ...sections,
          ],
        ),
      ),
    );
  }
}

/// 1枚の苦手克服カード
class WeakCardTile extends StatelessWidget {
  const WeakCardTile(this.card, {super.key});

  final WeakCard card;

  static const _colors = [
    Color(0xFF7FA8C9),
    Color(0xFFB08AD8),
    Color(0xFFE0A93B),
  ];

  @override
  Widget build(BuildContext context) {
    final c = _colors[card.stars - 1];
    return Container(
      key: ValueKey('weak-card-${card.card.id}'),
      width: 104,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c, width: card.stars == 3 ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('★' * card.stars, style: TextStyle(color: c, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            card.card.term,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: serif(15),
          ),
          Text(
            card.card.meaning,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
          ),
          Text(
            '${card.mistakes}回まちがえた',
            style: TextStyle(fontSize: 10, color: TsuzuriColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
