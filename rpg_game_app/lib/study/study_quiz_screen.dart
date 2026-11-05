import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/format_answer.dart';
import '../quiz/figure_view.dart';
import '../quiz/question_report.dart';

/// 問題を1問ずつ解く学習（バトルなし）。つづりクエストLight で、定期テストの海・復習・試験対策などに使う。
///
/// 単語帳の練習と同じように、苦手な問題・復習の日が来た問題から出し、
/// まちがえた問題は少し間をあけてもう一度出す（1回だけ。正解しても覚えた扱いにはしない）。
/// 答えは学習記録に残し（復習の日が決まる）、勉強時間も記録する。
class StudyQuizScreen extends StatefulWidget {
  const StudyQuizScreen({
    super.key,
    required this.title,
    required this.subject,
    required this.questions,
    this.record = true,
    this.limit,
    this.onFinished,
    this.random,
  });

  final String title;

  /// 教科（worldId。勉強時間の記録に使う）
  final String subject;
  final List<QuizQuestion> questions;

  /// 学習記録に残すか（その場で作った問題の確認などでは残さない）
  final bool record;

  /// 1回に出す問題の数（もう一度出す分はふくまない）。null なら設定の「問題の量」
  final int? limit;

  /// 終わったとき（正解の数・答えた数）
  final void Function(int correct, int answered)? onFinished;
  final Random? random;

  @override
  State<StudyQuizScreen> createState() => _StudyQuizScreenState();
}

class _StudyQuizScreenState extends State<StudyQuizScreen> {
  late final RpgServices _services = RpgServices.of(context);
  late final Random _random = widget.random ?? Random();
  late final List<PresentedQuestion> _queue = _pick();
  final _events = <AnswerEvent>[];
  final _requeued = <String>{};
  final _missed = <String, QuizQuestion>{};
  final _input = TextEditingController();
  final _watch = Stopwatch()..start();
  final _startedAt = DateTime.now();

  int _index = 0;
  int _correct = 0;
  int _answered = 0;

  /// 今の問題に答えた結果（まだなら null）
  bool? _ok;
  int? _chosen;
  FormatResponse? _response;
  String? _typed;
  bool _done = false;

  /// 苦手な問題・復習の日が来た問題ほど先に出す
  List<PresentedQuestion> _pick() {
    final deck = QuestionDeck(
      widget.questions,
      random: _random,
      weight: AdaptiveWeights.forRecord(
        _services.meta.record,
        RpgServices.today(),
      ),
    );
    final limit = widget.limit ?? _services.settings.value.quizCount;
    final n = min(limit, widget.questions.length);
    return [for (var i = 0; i < n; i++) deck.draw()];
  }

  PresentedQuestion get _q => _queue[_index];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _answer(bool correct, {int? chosen, FormatResponse? response}) {
    if (_ok != null) return;
    final q = _q;
    final setId = _services.questions.setIdOf(q.source.id);
    if (widget.record && setId != null) {
      _events.add(
        AnswerEvent(
          questionId: q.source.id,
          setId: setId,
          category: q.source.category.name,
          unit: q.source.unit,
          profile: AnswerProfile.of(
            q.source,
            sea: setId.startsWith('sea_'),
          ).code,
          isCorrect: correct,
          elapsedMs: _watch.elapsedMilliseconds,
        ),
      );
    }
    _answered++;
    if (correct) _correct++;
    if (!correct) {
      _missed[q.source.id] = q.source;
      // 少し間をあけて、もう一度（1回だけ）
      if (_requeued.add(q.source.id)) {
        final at = min(_index + 3, _queue.length);
        _queue.insert(at, q);
      }
    }
    setState(() {
      _ok = correct;
      _chosen = chosen;
      _response = response;
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _queue.length) {
      _input.clear();
      _watch
        ..reset()
        ..start();
      setState(() {
        _index++;
        _ok = null;
        _chosen = null;
        _response = null;
        _typed = null;
      });
      return;
    }
    await _finish();
  }

  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final services = _services;
    final meta = services.meta;
    if (_events.isNotEmpty) {
      await meta.save(
        record: meta.record.recordAll(_events, day: RpgServices.today()),
      );
    }
    if (_answered > 0) {
      await services.studyLog.add(
        widget.subject,
        spent: DateTime.now().difference(_startedAt),
        answered: _answered,
        correct: _correct,
      );
    }
    widget.onFinished?.call(_correct, _answered);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      // 途中でやめても、答えた分は残す
      if (didPop && !_done) _finish();
    },
    child: Scaffold(
      appBar: AppBar(title: Text(widget.title, style: serif(17))),
      body: NotebookPaper(child: SafeArea(child: _done ? _summary() : _body())),
    ),
  );

  Widget _body() {
    final q = _q;
    final total = _queue.length;
    return ListView(
      key: const ValueKey('study-quiz'),
      padding: const EdgeInsets.fromLTRB(40, 8, 14, 24),
      children: [
        Row(
          children: [
            Text('${_index + 1} / $total', style: serif(15)),
            const SizedBox(width: 10),
            Expanded(
              child: LinearProgressIndicator(
                value: _index / total,
                minHeight: 6,
                backgroundColor: TsuzuriColors.tint(0xFFEDE3D1),
                color: TsuzuriColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Text('正解 $_correct'),
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
              if (_requeued.contains(q.source.id) && _ok == null)
                Text(
                  'もう一度',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
              if (q.source.passage case final p?) ...[
                Text(p.title, style: serif(15)),
                const SizedBox(height: 4),
                for (final para in p.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      para,
                      style: const TextStyle(fontSize: 14, height: 1.7),
                    ),
                  ),
                const Divider(),
              ],
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
        ..._answerPane(q),
        if (_ok != null) ...[const SizedBox(height: 8), _feedback(q)],
      ],
    );
  }

  List<Widget> _answerPane(PresentedQuestion q) {
    if (!q.source.isChoice) {
      if (_ok != null) return const [];
      return [
        FormatAnswerPane(
          key: ValueKey('study-format-${q.source.id}-$_index'),
          question: q.source,
          locked: false,
          onSubmit: (r) => _answer(r.grade.correct, response: r),
        ),
      ];
    }
    if (q.source.isInput) {
      return [
        TextField(
          key: const ValueKey('study-input'),
          controller: _input,
          enabled: _ok == null,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitTyped(q),
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: '答えを入力',
            border: OutlineInputBorder(),
          ),
        ),
        if (_ok == null) ...[
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('study-input-submit'),
            onPressed: () => _submitTyped(q),
            child: const Text('答える'),
          ),
        ],
      ];
    }
    return [for (var i = 0; i < q.choices.length; i++) _choice(q, i)];
  }

  void _submitTyped(PresentedQuestion q) {
    if (_ok != null) return;
    _typed = _input.text;
    _answer(q.source.matchesInput(_input.text));
  }

  Widget _choice(PresentedQuestion q, int i) {
    var bg = TsuzuriColors.card;
    var fg = TsuzuriColors.ink;
    var border = TsuzuriColors.accent.withValues(alpha: 0.45);
    if (_ok != null) {
      if (i == q.correctIndex) {
        bg = TsuzuriColors.correct;
        fg = Colors.white;
        border = bg;
      } else if (i == _chosen) {
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
          key: ValueKey('study-choice-$i'),
          borderRadius: BorderRadius.circular(12),
          onTap: _ok == null ? () => _answer(q.isCorrect(i), chosen: i) : null,
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

  Widget _feedback(PresentedQuestion q) {
    final ok = _ok!;
    final mine = _response?.yourAnswer ?? _typed;
    return Container(
      key: const ValueKey('study-feedback'),
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
            ok ? '正解！' : '不正解…',
            style: serif(
              15,
              color: ok ? TsuzuriColors.correct : TsuzuriColors.wrong,
            ),
          ),
          if (mine != null && !q.source.isChoice || _typed != null)
            Text('あなたの答え：${mine == null || mine.isEmpty ? '（なし）' : mine}'),
          Text(
            '${q.source.format == QuestionFormat.written ? '模範解答' : '正解'}：${q.source.answer}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (_response?.grade.detail.isNotEmpty ?? false)
            Text(_response!.grade.detail, style: const TextStyle(fontSize: 13)),
          if ((q.source.explanation ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              q.source.explanation!,
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
          Row(
            children: [
              TextButton.icon(
                key: const ValueKey('study-report'),
                onPressed: () => showReportDialog(context, q.source),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('報告', style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const ValueKey('study-next'),
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_index + 1 < _queue.length ? 'つぎへ' : '結果を見る'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final percent = _answered == 0 ? 0 : (_correct * 100 / _answered).round();
    return ListView(
      key: const ValueKey('study-summary'),
      padding: const EdgeInsets.fromLTRB(44, 20, 16, 24),
      children: [
        Center(child: Text('$percent%', style: serif(48))),
        Center(
          child: Text(
            '$_answered問中 $_correct問 正解',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'まちがえた問題は、復習の日が来たら「復習」に出てきます',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
        ),
        if (_missed.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('ふりかえり', style: serif(16)),
          const SizedBox(height: 6),
          for (final q in _missed.values)
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
        FilledButton(
          key: const ValueKey('study-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('もどる'),
        ),
      ],
    );
  }
}
