import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import '../quiz/figure_view.dart';
import '../vocab/speech.dart';
import 'yosou_crop_view.dart';

/// 予想問題の小問1問（本文・同じ大問の問題・リスニングつき）。
///
/// 答えはその場では採点しない。選んだもの・書いたものを [onAnswer] で返すだけで、
/// 提出したあとにまとめて採点する。
class YosouQuestionView extends StatefulWidget {
  const YosouQuestionView({
    super.key,
    required this.question,
    required this.number,
    required this.total,
    required this.siblings,
    required this.answers,
    required this.onAnswer,
    required this.onJump,
    this.heard = 0,
    this.onListen,
  });

  final QuizQuestion question;

  /// 何問目か（1から）
  final int number;
  final int total;

  /// 同じ大問の問題（[question] をふくむ）
  final List<QuizQuestion> siblings;

  /// これまでの答え（問題 id → 答え）
  final Map<String, String> answers;
  final ValueChanged<String> onAnswer;

  /// 同じ大問のほかの問題へ移る
  final ValueChanged<QuizQuestion> onJump;

  /// この問題の音声を流した回数
  final int heard;
  final VoidCallback? onListen;

  /// 音声を流せる回数（1問ごと）
  static const plays = 2;

  @override
  State<YosouQuestionView> createState() => _YosouQuestionViewState();
}

class _YosouQuestionViewState extends State<YosouQuestionView> {
  QuizQuestion get _q => widget.question;
  late final MockItem _item = YosouSheet.item(_q, widget.number);
  late final _input = TextEditingController(text: _answer);

  /// 並べかえで、ここまでに並べた語
  late final List<String> _picked = _restoreOrder();

  /// リスニングを文字で読む
  bool _showText = false;

  String get _answer => widget.answers[_q.id] ?? '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<String> _restoreOrder() {
    final o = _q.order;
    if (o == null || _answer.isEmpty) return [];
    final parts = _answer.split(o.joiner);
    final left = [...o.items];
    for (final p in parts) {
      if (!left.remove(p)) return [];
    }
    return parts;
  }

  void _set(String v) => widget.onAnswer(v);

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final pos = widget.siblings.indexWhere((s) => s.id == q.id) + 1;
    return ListView(
      key: ValueKey('yosou-q-${q.id}'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${q.passage?.title ?? ''}（$pos/${widget.siblings.length}）',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('yosou-open-group'),
              onPressed: _openGroup,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('大問を見る'),
            ),
          ],
        ),
        if (q.passage != null)
          Card(
            color: TsuzuriColors.tint(0xFFFFF8E7),
            child: ExpansionTile(
              key: PageStorageKey('passage-${q.passage!.id}'),
              initiallyExpanded: pos == 1,
              title: Text('📜 ${q.passage!.title}', style: serif(14)),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: yosouPassage(q.passage!),
            ),
          ),
        const SizedBox(height: 8),
        Text(q.prompt, style: serif(16)),
        if (q.listen && q.sentence != null && !_showText)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('yosou-listen'),
                  onPressed: widget.heard >= YosouQuestionView.plays
                      ? null
                      : () {
                          widget.onListen?.call();
                          speaker.speak(q.sentence!, lang: 'en-US', rate: 0.5);
                        },
                  icon: const Icon(Icons.volume_up),
                  label: Text(
                    '音声を聞く（あと${YosouQuestionView.plays - widget.heard}回）',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showText = true),
                  child: const Text('音が出せない：文字で読む'),
                ),
              ],
            ),
          )
        else if (q.sentence != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(q.sentence!, style: const TextStyle(fontSize: 15)),
          ),
        if (q.figure != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FigureView(q.figure!, height: 180),
          ),
        const SizedBox(height: 12),
        _field(),
      ],
    );
  }

  Widget _option(int i, String text, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: OutlinedButton(
          key: ValueKey('yosou-choice-$i'),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            backgroundColor: selected
                ? TsuzuriColors.accent.withValues(alpha: 0.18)
                : null,
            side: selected
                ? BorderSide(color: TsuzuriColors.accent, width: 2)
                : null,
            foregroundColor: TsuzuriColors.ink,
          ),
          onPressed: onTap,
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: selected ? TsuzuriColors.accent : TsuzuriColors.inkSoft,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
            ],
          ),
        ),
      );

  Widget _field() {
    final q = _q;
    final item = _item;
    switch (q.format) {
      case QuestionFormat.choice when !q.isInput:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < item.options.length; i++)
              _option(
                i,
                item.options[i],
                _answer == item.options[i],
                () => _set(_answer == item.options[i] ? '' : item.options[i]),
              ),
          ],
        );
      case QuestionFormat.multiSelect:
        final picked = MockItem.splitChoices(_answer).toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'あてはまるものをすべて選ぶ',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < item.options.length; i++)
              _option(i, item.options[i], picked.contains(item.options[i]), () {
                final o = item.options[i];
                final next = {...picked};
                next.contains(o) ? next.remove(o) : next.add(o);
                _set(MockItem.joinChoices(next));
              }),
          ],
        );
      case QuestionFormat.order:
        return _orderField(q.order!);
      case QuestionFormat.written:
        return TextField(
          key: const ValueKey('yosou-answer-input'),
          controller: _input,
          minLines: 3,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '答えを書く（ノートに書いてもよい。提出後に模範解答を見て自分で採点）',
          ),
          onChanged: _set,
        );
      default:
        return TextField(
          key: const ValueKey('yosou-answer-input'),
          controller: _input,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '答えを書く',
          ),
          onChanged: _set,
        );
    }
  }

  /// 並べかえ：語をタップした順に並べる
  Widget _orderField(OrderSpec o) {
    final shuffled = [...o.items]
      ..sort((a, b) => '${_q.id}$a'.hashCode.compareTo('${_q.id}$b'.hashCode));
    final left = [...shuffled];
    for (final p in _picked) {
      left.remove(p);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: TsuzuriColors.inkSoft),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _picked.isEmpty ? '下の語をタップした順に並びます' : _picked.join(o.joiner),
            key: const ValueKey('yosou-order-answer'),
            style: TextStyle(
              fontSize: 15,
              color: _picked.isEmpty ? TsuzuriColors.inkSoft : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final w in left)
              ActionChip(
                key: ValueKey('yosou-order-$w'),
                label: Text(w),
                onPressed: () {
                  setState(() => _picked.add(w));
                  _set(_picked.join(o.joiner));
                },
              ),
          ],
        ),
        if (_picked.isNotEmpty)
          TextButton.icon(
            key: const ValueKey('yosou-order-reset'),
            onPressed: () {
              setState(_picked.clear);
              _set('');
            },
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('並べなおす'),
          ),
      ],
    );
  }

  void _openGroup() {
    final q = _q;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (c) => Scaffold(
          appBar: AppBar(
            title: Text(q.passage?.title ?? '同じ大問', style: serif(15)),
          ),
          body: NotebookPaper(
            child: ListView(
              key: const ValueKey('yosou-group-view'),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
              children: [
                if (q.passage != null) ...[
                  Text('本文・前書き', style: serif(15)),
                  const SizedBox(height: 6),
                  ...yosouPassage(q.passage!),
                  const Divider(height: 28),
                ],
                Text(
                  'この大問の問題（${widget.siblings.length}問）・タップでその問題へ',
                  style: serif(15),
                ),
                const SizedBox(height: 6),
                for (final s in widget.siblings)
                  Card(
                    color: s.id == q.id ? TsuzuriColors.tint(0xFFFFF4D6) : null,
                    child: InkWell(
                      key: ValueKey('yosou-sibling-${s.id}'),
                      onTap: () {
                        Navigator.of(c).pop();
                        if (s.id != q.id) widget.onJump(s);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.id == q.id ? '▶ いまの問題　' : ''}${s.prompt}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.sentence != null && !s.listen)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  s.sentence!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            if ((widget.answers[s.id] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'あなたの答え：${widget.answers[s.id]!.replaceAll(',', '・')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: TsuzuriColors.inkSoft,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 大問の本文・前書き（原本の切り抜きもそのまま出す）
List<Widget> yosouPassage(Passage p) => [
  for (final para in p.paragraphs)
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: switch (YosouCrop.ofParagraph(para)) {
        final crop? => YosouCropView(crop),
        null => Text(para, style: const TextStyle(fontSize: 14, height: 1.6)),
      },
    ),
];
