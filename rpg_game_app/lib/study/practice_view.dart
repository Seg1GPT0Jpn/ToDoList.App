import 'package:flutter/material.dart';

import '../quiz/figure_view.dart';

import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';

/// 練習問題を1問ずつ解く画面部品（ダメージなし）。
/// 宿の授業と定期テストの海で共通に使う。
class PracticeView extends StatefulWidget {
  const PracticeView({
    super.key,
    required this.session,
    required this.onFinished,
  });

  final PracticeSession session;
  final VoidCallback onFinished;

  @override
  State<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  PracticeAnswer? _last;

  PracticeSession get s => widget.session;

  void _choose(int i) {
    if (_last != null) return;
    setState(() => _last = s.answer(i));
  }

  void _next() {
    if (s.isFinished) {
      widget.onFinished();
      return;
    }
    setState(() => _last = null);
  }

  @override
  Widget build(BuildContext context) {
    final last = _last;
    final q = last?.question ?? s.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '${s.answeredCount + (last == null ? 1 : 0)} / ${s.total}',
                style: serif(15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.answeredCount / s.total,
                    minHeight: 6,
                    backgroundColor: TsuzuriColors.tint(0xFFEDE3D1),
                    color: TsuzuriColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '正解 ${s.correctCount}',
                style: const TextStyle(
                  color: TsuzuriColors.correct,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: TsuzuriColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TsuzuriColors.tint(0xFFE0D4C0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.source.prompt,
                  style: TextStyle(fontSize: 14, color: TsuzuriColors.inkSoft),
                ),
                if (q.source.figure != null) FigureView(q.source.figure!),
                if (q.source.sentence != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    q.source.sentence!,
                    style: serif(18, color: TsuzuriColors.ink),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < q.choices.length; i++) _choice(q, i, last),
          if (last != null) ...[
            const SizedBox(height: 8),
            Expanded(child: _feedback(q, last)),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _choice(PresentedQuestion q, int i, PracticeAnswer? last) {
    Color bg = TsuzuriColors.card;
    Color fg = TsuzuriColors.ink;
    Color border = TsuzuriColors.accent.withValues(alpha: 0.45);
    if (last != null) {
      if (i == q.correctIndex) {
        bg = TsuzuriColors.correct;
        fg = Colors.white;
        border = bg;
      } else if (i == last.chosenIndex) {
        bg = TsuzuriColors.wrong;
        fg = Colors.white;
        border = bg;
      } else {
        fg = TsuzuriColors.inkSoft.withValues(alpha: 0.5);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: last == null ? () => _choose(i) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              q.choices[i],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedback(PresentedQuestion q, PracticeAnswer last) {
    final ok = last.correct;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok
            ? TsuzuriColors.tint(0xFFEFF7EE)
            : TsuzuriColors.tint(0xFFFFF4F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (ok ? TsuzuriColors.correct : TsuzuriColors.wrong).withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ok ? '正解！' : '不正解… 正解は「${q.source.answer}」',
            style: serif(
              15,
              color: ok ? TsuzuriColors.correct : TsuzuriColors.wrong,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                q.source.explanation ?? '',
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward),
              label: Text(s.isFinished ? '結果を見る' : 'つぎへ'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 練習の結果（正答率と間違えた問題）
class PracticeSummary extends StatelessWidget {
  const PracticeSummary({
    super.key,
    required this.session,
    required this.extra,
    required this.actions,
  });

  final PracticeSession session;
  final List<Widget> extra;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final s = session;
    return ListView(
      padding: const EdgeInsets.fromLTRB(44, 20, 16, 24),
      children: [
        Center(
          child: Text(
            '${s.percent}%',
            style: serif(48, color: TsuzuriColors.accent),
          ),
        ),
        Center(
          child: Text(
            '${s.total}問中 ${s.correctCount}問 正解',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 16),
        ...extra,
        if (s.missed.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('ふりかえり', style: serif(16)),
          const SizedBox(height: 6),
          for (final q in s.missed)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(
                  q.sentence ?? q.prompt,
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
                children: [
                  Text(
                    q.explanation ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 12),
        for (final a in actions)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
      ],
    );
  }
}
