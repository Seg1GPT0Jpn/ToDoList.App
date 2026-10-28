import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../battle/format_answer.dart';
import '../battle/scratchpad.dart';
import '../quiz/figure_view.dart';
import '../vocab/speech.dart';
import 'yosou_crop_view.dart';
import 'yosou_exam_store.dart';

/// 予想問題を小問ごとに解く：大問を選んで、順番に解く／バトルで解く
class YosouDrillMenu extends StatelessWidget {
  const YosouDrillMenu({
    super.key,
    required this.exam,
    required this.questions,
  });

  final YosouExam exam;
  final List<QuizQuestion> questions;

  String get _worldId =>
      ShonanSubjects.byId(exam.subjectId)?.worldId ?? 'english';

  void _drill(BuildContext context, String title, List<QuizQuestion> qs) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => YosouDrillScreen(title: title, questions: qs),
        ),
      );

  Future<void> _battle(
    BuildContext context,
    String id,
    String title,
    List<QuizQuestion> qs,
  ) async {
    final services = RpgServices.of(context);
    final progress = await services.repository.load();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(_worldId),
          stage: YosouBattle.stage(
            id: id,
            title: title,
            worldId: _worldId,
            level: progress.level,
            questions: qs.length,
          ),
          questions: qs,
          progress: progress,
          trial: true,
          mode: BattleMode.sea,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String id,
    String title,
    List<QuizQuestion> qs, {
    bool all = false,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: serif(all ? 16 : 15)),
          Text(
            '${qs.length}問',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton.icon(
                key: ValueKey('yosou-drill-$id'),
                onPressed: () => _drill(context, title, qs),
                icon: const Icon(Icons.format_list_numbered, size: 18),
                label: const Text('順番に解く'),
              ),
              TextButton.icon(
                key: ValueKey('yosou-battle-$id'),
                onPressed: () => _battle(context, '${exam.id}_$id', title, qs),
                icon: const Icon(Icons.sports_martial_arts, size: 18),
                label: const Text('バトルで解く'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final groups = YosouGroup.of(questions);
    return Scaffold(
      appBar: AppBar(title: Text('小問ごとに解く', style: serif(17))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              '予想問題の小問を、1問ずつ解きます。「順番に解く」は大問の中の順番どおり（前の小問が誘導になっている問題もそのまま）。'
              '「バトルで解く」はいつもの RPG のバトルで、順番はばらばらになります。'
              '本文・同じ大問の問題・計算メモは、どちらでも開けます。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 10),
            _row(context, 'all', '${exam.title}（全部）', questions, all: true),
            for (final g in groups) _row(context, g.id, g.title, g.questions),
          ],
        ),
      ),
    );
  }
}

/// 答えた結果（1問ぶん）
class _Answer {
  const _Answer(this.correct, this.yours);
  final bool correct;
  final String yours;
}

/// 予想問題を順番に1問ずつ解く（大問の本文・同じ大問の問題・計算メモつき）
class YosouDrillScreen extends StatefulWidget {
  const YosouDrillScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  final String title;
  final List<QuizQuestion> questions;

  @override
  State<YosouDrillScreen> createState() => _YosouDrillScreenState();
}

class _YosouDrillScreenState extends State<YosouDrillScreen> {
  late List<QuizQuestion> _qs = widget.questions;
  int _index = 0;
  final _answers = <String, _Answer>{};
  final _input = TextEditingController();
  bool _scratch = false;

  /// リスニングを文字で読む
  bool _showText = false;

  /// 問題ごとのメモ
  final _strokes = <String, List<List<Offset>>>{};

  QuizQuestion get _q => _qs[_index];
  bool get _done => _index >= _qs.length;

  @override
  void dispose() {
    speaker.stop();
    _input.dispose();
    super.dispose();
  }

  void _answer(bool correct, String yours) {
    setState(() => _answers[_q.id] = _Answer(correct, yours));
  }

  void _next() => setState(() {
    speaker.stop();
    _showText = false;
    _index++;
    _input.clear();
    _scratch = false;
  });

  void _restart(List<QuizQuestion> qs) => setState(() {
    _qs = qs;
    _index = 0;
    _answers.clear();
    _input.clear();
  });

  /// 同じ大問の問題
  List<QuizQuestion> _siblings(QuizQuestion q) {
    final g = YosouGroup.groupId(q);
    return [
      for (final x in widget.questions)
        if (YosouGroup.groupId(x) == g) x,
    ];
  }

  void _openGroup(QuizQuestion q) {
    final sib = _siblings(q);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
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
                  ..._passage(q.passage!),
                  const Divider(height: 28),
                ],
                Text('この大問の問題（${sib.length}問）', style: serif(15)),
                const SizedBox(height: 6),
                for (final s in sib) _siblingCard(s, current: s.id == q.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _siblingCard(QuizQuestion s, {required bool current}) {
    final a = _answers[s.id];
    return Card(
      color: current ? TsuzuriColors.tint(0xFFFFF4D6) : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${current ? '▶ いまの問題　' : ''}${s.prompt}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (s.sentence != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s.sentence!, style: const TextStyle(fontSize: 13)),
              ),
            if (a != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${a.correct ? '○' : '×'}　正解：${s.answer}',
                  style: TextStyle(
                    fontSize: 12,
                    color: a.correct
                        ? TsuzuriColors.stamp
                        : TsuzuriColors.wrong,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _passage(Passage p) => [
    for (final para in p.paragraphs)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: switch (YosouCrop.ofParagraph(para)) {
          final crop? => YosouCropView(crop),
          null => Text(para, style: const TextStyle(fontSize: 14, height: 1.6)),
        },
      ),
  ];

  Widget _choices(QuizQuestion q, _Answer? a) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < q.choices.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: OutlinedButton(
            key: ValueKey('yosou-choice-$i'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: a == null
                  ? null
                  : i == q.answerIndex
                  ? TsuzuriColors.correct.withValues(alpha: 0.18)
                  : a.yours == q.choices[i]
                  ? TsuzuriColors.wrong.withValues(alpha: 0.15)
                  : null,
              foregroundColor: TsuzuriColors.ink,
            ),
            onPressed: a != null
                ? null
                : () => _answer(i == q.answerIndex, q.choices[i]),
            child: Text(q.choices[i], style: const TextStyle(fontSize: 14)),
          ),
        ),
    ],
  );

  Widget _inputField(QuizQuestion q, _Answer? a) => Row(
    children: [
      Expanded(
        child: TextField(
          key: const ValueKey('yosou-drill-input'),
          controller: _input,
          enabled: a == null,
          decoration: const InputDecoration(hintText: '答えを書く'),
          onSubmitted: (v) => _answer(q.matchesInput(v), v.trim()),
        ),
      ),
      const SizedBox(width: 8),
      FilledButton(
        key: const ValueKey('yosou-drill-submit'),
        onPressed: a != null
            ? null
            : () => _answer(q.matchesInput(_input.text), _input.text.trim()),
        child: const Text('答える'),
      ),
    ],
  );

  Widget _result(QuizQuestion q, _Answer a) => Card(
    color: a.correct
        ? TsuzuriColors.correct.withValues(alpha: 0.12)
        : TsuzuriColors.wrong.withValues(alpha: 0.10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.correct ? '○ 正解' : '× 不正解',
            key: const ValueKey('yosou-drill-mark'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: a.correct ? TsuzuriColors.stamp : TsuzuriColors.wrong,
            ),
          ),
          if (a.yours.isNotEmpty) Text('あなたの答え：${a.yours}'),
          Text('正解：${q.answer}'),
          if ((q.explanation ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                q.explanation!,
                style: TextStyle(fontSize: 13, color: TsuzuriColors.inkSoft),
              ),
            ),
          if (!a.correct && q.isInput)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('yosou-drill-override'),
                onPressed: () => _answer(true, a.yours),
                child: const Text('○に直す（書き方のちがいなど）'),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _question(QuizQuestion q) {
    final a = _answers[q.id];
    final sib = _siblings(q);
    final pos = sib.indexWhere((s) => s.id == q.id) + 1;
    return ListView(
      key: ValueKey('yosou-drill-${q.id}'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_index + 1} / ${_qs.length}　${q.passage?.title ?? ''}（$pos/${sib.length}）',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('yosou-open-group'),
              onPressed: () => _openGroup(q),
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
              children: _passage(q.passage!),
            ),
          ),
        const SizedBox(height: 8),
        Text(q.prompt, style: serif(16)),
        if (q.listen && q.sentence != null && a == null && !_showText)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('yosou-drill-listen'),
                  onPressed: () =>
                      speaker.speak(q.sentence!, lang: 'en-US', rate: 0.5),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('音声を聞く'),
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
        if (q.isChoice && q.isInput)
          _inputField(q, a)
        else if (q.isChoice)
          _choices(q, a)
        else if (a == null)
          FormatAnswerPane(
            key: ValueKey('yosou-format-${q.id}'),
            question: q,
            locked: false,
            onSubmit: (r) => _answer(r.grade.correct, r.yourAnswer),
          ),
        if (a != null) ...[
          const SizedBox(height: 10),
          _result(q, a),
          const SizedBox(height: 10),
          FilledButton(
            key: const ValueKey('yosou-drill-next'),
            onPressed: _next,
            child: Text(_index + 1 >= _qs.length ? '結果を見る' : '次の問題へ'),
          ),
        ],
      ],
    );
  }

  Widget _summary() {
    final ok = _qs.where((q) => _answers[q.id]?.correct ?? false).length;
    final wrong = [
      for (final q in _qs)
        if (!(_answers[q.id]?.correct ?? false)) q,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        Center(
          child: Text(
            '$ok / ${_qs.length} 問正解',
            key: const ValueKey('yosou-drill-score'),
            style: serif(26),
          ),
        ),
        const SizedBox(height: 16),
        if (wrong.isNotEmpty)
          FilledButton.icon(
            key: const ValueKey('yosou-drill-retry-wrong'),
            onPressed: () => _restart(wrong),
            icon: const Icon(Icons.replay),
            label: Text('まちがえた${wrong.length}問をもう一度'),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _restart(widget.questions),
          child: const Text('はじめからもう一度'),
        ),
        const SizedBox(height: 16),
        for (final q in wrong)
          Card(
            child: ListTile(
              title: Text(
                q.prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('正解：${q.answer}'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: serif(15), maxLines: 2),
        actions: [
          if (!_done)
            IconButton(
              key: const ValueKey('yosou-drill-memo'),
              tooltip: '計算メモ',
              onPressed: () => setState(() => _scratch = true),
              icon: const Icon(Icons.edit_note),
            ),
        ],
      ),
      body: NotebookPaper(
        child: Stack(
          children: [
            Positioned.fill(child: _done ? _summary() : _question(_q)),
            if (_scratch && !_done)
              Positioned.fill(
                child: ScratchpadOverlay(
                  strokes: _strokes.putIfAbsent(_q.id, () => []),
                  onClose: () => setState(() => _scratch = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 予想問題の画面から、小問ごとの問題を開く
Future<void> openYosouDrill(
  BuildContext context,
  YosouExam exam,
  YosouExamFiles files,
) async {
  final qs = await files.questions();
  if (!context.mounted) return;
  if (qs == null || qs.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('この教科の小問の問題は、まだ準備中です')));
    return;
  }
  YosouImages.key = files.key;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => YosouDrillMenu(exam: exam, questions: qs),
    ),
  );
}
