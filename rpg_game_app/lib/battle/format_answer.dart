import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';

/// 4択以外の問題に答えたときの結果（採点と、自分の答えを1行で表したもの）
class FormatResponse {
  const FormatResponse(this.grade, this.yourAnswer);
  final Grade grade;
  final String yourAnswer;
}

/// 正誤・複数選択・並べ替え・数値入力・穴埋め・段階問題・記述の答え方。
///
/// 答えたら [onSubmit] で採点結果を返す。記述で模範解答を見たときは [onReveal]
/// （時間を止める）。採点は rpg_game の [Grader]。
class FormatAnswerPane extends StatefulWidget {
  const FormatAnswerPane({
    super.key,
    required this.question,
    required this.locked,
    required this.onSubmit,
    this.onReveal,
  });

  final QuizQuestion question;
  final bool locked;
  final ValueChanged<FormatResponse> onSubmit;
  final VoidCallback? onReveal;

  @override
  State<FormatAnswerPane> createState() => _FormatAnswerPaneState();
}

class _FormatAnswerPaneState extends State<FormatAnswerPane> {
  QuizQuestion get q => widget.question;

  // 複数選択
  final Set<int> _picked = {};

  // 並べ替え
  late List<int> _pool = _shuffledOrder();
  final List<int> _arranged = [];

  // 数値・穴埋め・記述
  final _numeric = TextEditingController();
  late final List<TextEditingController> _blanks = [
    for (var i = 0; i < (q.cloze?.blanks.length ?? 0); i++)
      TextEditingController(),
  ];
  final _written = TextEditingController();
  bool _revealed = false;
  final Set<int> _rubric = {};

  // 段階問題
  final List<bool> _stepResults = [];
  final List<String> _stepAnswers = [];
  late List<int> _stepOrder = _shuffleChoices(0);

  @override
  void didUpdateWidget(FormatAnswerPane old) {
    super.didUpdateWidget(old);
    if (old.question.id != q.id) {
      _picked.clear();
      _pool = _shuffledOrder();
      _arranged.clear();
      _numeric.clear();
      for (final c in _blanks) {
        c.clear();
      }
      _written.clear();
      _revealed = false;
      _rubric.clear();
      _stepResults.clear();
      _stepAnswers.clear();
      _stepOrder = _shuffleChoices(0);
    }
  }

  @override
  void dispose() {
    _numeric.dispose();
    for (final c in _blanks) {
      c.dispose();
    }
    _written.dispose();
    super.dispose();
  }

  List<int> _shuffledOrder() {
    final n = q.order?.items.length ?? 0;
    if (n == 0) return [];
    final r = Random(q.id.hashCode);
    final out = List<int>.generate(n, (i) => i);
    // もとの順のままにならないようにまぜる
    do {
      out.shuffle(r);
    } while (n > 1 && List.generate(n, (i) => i).join() == out.join());
    return out;
  }

  List<int> _shuffleChoices(int step) {
    if (q.subQuestions.length <= step) return [];
    final r = Random(q.id.hashCode + step);
    return List<int>.generate(q.subQuestions[step].choices.length, (i) => i)
      ..shuffle(r);
  }

  void _submit(Grade g, String answer) {
    if (widget.locked) return;
    widget.onSubmit(FormatResponse(g, answer));
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (q.format) {
      QuestionFormat.trueFalse => _trueFalse(),
      QuestionFormat.multiSelect => _multiSelect(),
      QuestionFormat.order => _order(),
      QuestionFormat.numeric => _numericPane(),
      QuestionFormat.cloze => _cloze(),
      QuestionFormat.multiStep => _steps(),
      QuestionFormat.written => _writtenPane(),
      QuestionFormat.choice => const SizedBox.shrink(),
    };
    return SingleChildScrollView(child: body);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: TsuzuriColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            q.format == QuestionFormat.written
                ? q.written!.kindLabel
                : q.format.label,
            style: TextStyle(fontSize: 11.5, color: TsuzuriColors.accent),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
        ),
      ],
    ),
  );

  Widget _submitButton(String label, VoidCallback? onPressed, {Key? key}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: key ?? const ValueKey('format-submit'),
            onPressed: widget.locked ? null : onPressed,
            icon: const Icon(Icons.check),
            label: Text(label),
          ),
        ),
      );

  // ---- 正誤 ----
  Widget _trueFalse() => Column(
    children: [
      _label('内容が正しければ○、誤りなら×'),
      Row(
        children: [
          for (final (value, mark, color) in [
            (true, '○', TsuzuriColors.correct),
            (false, '×', TsuzuriColors.wrong),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: 72,
                  child: OutlinedButton(
                    key: ValueKey('tf-$value'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.locked
                        ? null
                        : () => _submit(Grader.trueFalse(q, value), mark),
                    child: Text(mark, style: const TextStyle(fontSize: 30)),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  // ---- 複数選択 ----
  Widget _multiSelect() {
    final spec = q.multiSelect!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('正しいものをすべて選ぶ（${spec.correct.length}つとは限らない）'),
        for (var i = 0; i < spec.options.length; i++)
          CheckboxListTile(
            key: ValueKey('ms-$i'),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: _picked.contains(i),
            onChanged: widget.locked
                ? null
                : (v) => setState(
                    () => v == true ? _picked.add(i) : _picked.remove(i),
                  ),
            title: Text(spec.options[i], style: const TextStyle(fontSize: 14)),
          ),
        _submitButton(
          '答える',
          _picked.isEmpty
              ? null
              : () => _submit(
                  Grader.multiSelect(q, _picked),
                  [for (final i in _picked.toList()..sort()) spec.options[i]]
                      .join('・'),
                ),
        ),
      ],
    );
  }

  // ---- 並べ替え ----
  Widget _order() {
    final spec = q.order!;
    Widget chip(int i, {required bool placed}) => Padding(
      padding: const EdgeInsets.all(3),
      child: ActionChip(
        key: ValueKey(placed ? 'order-placed-$i' : 'order-pool-$i'),
        label: Text(spec.items[i]),
        backgroundColor: placed
            ? TsuzuriColors.accent.withValues(alpha: 0.15)
            : TsuzuriColors.card,
        onPressed: widget.locked
            ? null
            : () => setState(() {
                if (placed) {
                  _arranged.remove(i);
                  _pool.add(i);
                } else {
                  _pool.remove(i);
                  _arranged.add(i);
                }
              }),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('下の語句をタップして、正しい順に並べる（並べたものをタップで戻す）'),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TsuzuriColors.accent, width: 1.5),
            ),
          ),
          child: Wrap(
            children: [for (final i in _arranged) chip(i, placed: true)],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(children: [for (final i in _pool) chip(i, placed: false)]),
        _submitButton(
          '答える',
          _pool.isNotEmpty
              ? null
              : () => _submit(
                  Grader.order(q, _arranged),
                  [for (final i in _arranged) spec.items[i]].join(spec.joiner),
                ),
        ),
      ],
    );
  }

  // ---- 数値入力 ----
  Widget _numericPane() {
    final spec = q.numeric!;
    void send() =>
        _submit(Grader.numeric(q, _numeric.text), _numeric.text.trim());
    return Column(
      children: [
        _label('数で答える（分数 3/4・小数・1.2×10^3 も可）'),
        TextField(
          key: const ValueKey('numeric-input'),
          controller: _numeric,
          enabled: !widget.locked,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => send(),
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: '答え',
            suffixText: spec.unit.isEmpty ? null : spec.unit,
            border: const OutlineInputBorder(),
          ),
        ),
        _submitButton('答える', send),
      ],
    );
  }

  // ---- 穴埋め ----
  Widget _cloze() {
    final spec = q.cloze!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('空らん（1）〜（${spec.blanks.length}）に入る語を書く'),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 6,
          children: [
            for (final p in spec.parts)
              if (p is String)
                Text(p, style: const TextStyle(fontSize: 15, height: 1.6))
              else
                SizedBox(
                  width: 110,
                  child: TextField(
                    key: ValueKey('cloze-${p as int}'),
                    controller: _blanks[p - 1],
                    enabled: !widget.locked,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '($p) ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
          ],
        ),
        _submitButton(
          '答える',
          () => _submit(
            Grader.cloze(q, [for (final c in _blanks) c.text]),
            [
              for (var i = 0; i < _blanks.length; i++)
                '(${i + 1}) ${_blanks[i].text.trim()}',
            ].join('　'),
          ),
        ),
      ],
    );
  }

  // ---- 段階問題 ----
  Widget _steps() {
    final step = _stepResults.length;
    final total = q.subQuestions.length;
    if (step >= total) return const SizedBox.shrink();
    final sub = q.subQuestions[step];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('小問 ${step + 1} / $total（前の小問が次のヒントになる）'),
        if (_stepResults.isNotEmpty)
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < _stepResults.length; i++)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    _stepResults[i] ? Icons.check : Icons.close,
                    size: 16,
                    color: _stepResults[i]
                        ? TsuzuriColors.correct
                        : TsuzuriColors.wrong,
                  ),
                  label: Text('(${i + 1}) ${q.subQuestions[i].answer}'),
                ),
            ],
          ),
        Text(sub.prompt, style: serif(15)),
        if (sub.sentence != null)
          Text(sub.sentence!, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        for (final i in _stepOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton(
              key: ValueKey('step-$step-$i'),
              onPressed: widget.locked
                  ? null
                  : () => setState(() {
                      _stepResults.add(i == sub.answerIndex);
                      _stepAnswers.add(sub.choices[i]);
                      _stepOrder = _shuffleChoices(_stepResults.length);
                      if (_stepResults.length == total) {
                        _submit(
                          Grader.steps(q, _stepResults),
                          _stepAnswers.join(' → '),
                        );
                      }
                    }),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(sub.choices[i]),
              ),
            ),
          ),
      ],
    );
  }

  // ---- 記述 ----
  Widget _writtenPane() {
    final spec = q.written!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(
          _revealed
              ? '模範解答と採点基準を見て、自分の答えにふくまれている項目にチェック'
              : '答えを書いてから、模範解答と採点基準で自己採点する',
        ),
        TextField(
          key: const ValueKey('written-input'),
          controller: _written,
          enabled: !widget.locked && !_revealed,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'ここに答えを書く（書かなくても採点基準は見られる）',
            border: OutlineInputBorder(),
          ),
        ),
        if (!_revealed)
          _submitButton('模範解答と採点基準を見る', () {
            setState(() => _revealed = true);
            widget.onReveal?.call();
          }, key: const ValueKey('written-reveal'))
        else ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TsuzuriColors.correct.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: TsuzuriColors.correct.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('模範解答', style: serif(14)),
                const SizedBox(height: 4),
                Text(
                  spec.modelAnswer,
                  style: const TextStyle(fontSize: 13.5, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '採点基準（合格 ${spec.passScore} / ${spec.totalScore} 点）',
            style: serif(14),
          ),
          for (var i = 0; i < spec.rubric.length; i++)
            CheckboxListTile(
              key: ValueKey('rubric-$i'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _rubric.contains(i),
              onChanged: widget.locked
                  ? null
                  : (v) => setState(
                      () => v == true ? _rubric.add(i) : _rubric.remove(i),
                    ),
              title: Text(spec.rubric[i].point),
              secondary: Text('${spec.rubric[i].score}点'),
            ),
          _submitButton(
            '採点して答える',
            () => _submit(
              Grader.written(q, _rubric),
              _written.text.trim().isEmpty ? '（書かずに採点）' : _written.text.trim(),
            ),
          ),
        ],
      ],
    );
  }
}
