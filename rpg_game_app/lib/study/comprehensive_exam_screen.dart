import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/format_answer.dart';
import '../meta/design.dart';
import '../meta/growth_screen.dart';

/// 総合演習：教科ごとの模擬試験（3部構成・配点・制限時間・部分点）。
/// 終わると、分野ごと・思考の種類ごとの得点と複合弱点を出し、学習ルートにつなぐ。
class ComprehensiveExamScreen extends StatefulWidget {
  const ComprehensiveExamScreen({super.key, required this.subject});

  final String subject;

  @override
  State<ComprehensiveExamScreen> createState() =>
      _ComprehensiveExamScreenState();
}

enum _Phase { loading, intro, running, done }

class _ComprehensiveExamScreenState extends State<ComprehensiveExamScreen> {
  late String _subject = widget.subject;
  _Phase _phase = _Phase.loading;
  ExamPaper? _paper;
  String? _error;
  int _attempt = 0;

  int _index = 0;
  final Map<int, Grade> _grades = {};
  final Map<int, String> _answers = {};
  final Map<int, int> _ms = {};
  final Stopwatch _clock = Stopwatch();
  final Stopwatch _perQuestion = Stopwatch();
  Timer? _ticker;
  ExamResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    final services = RpgServices.of(context);
    final seed = RpgServices.today() * 31 + _attempt;
    final sets = <String, List<QuizQuestion>>{};
    for (final id in ExamPaper.candidateSets(_subject, seed: seed)) {
      final set = await services.questions.load(id);
      if (set == null || !set.origin.usableInRpg) continue;
      sets[id] = set.questions;
    }
    if (!mounted) return;
    final paper = ExamPaper.build(subject: _subject, sets: sets, seed: seed);
    setState(() {
      if (paper.items.length < 6) {
        _error = 'この教科の問題がまだ少ないため、総合演習を組めませんでした';
      } else {
        _paper = paper;
        _phase = _Phase.intro;
      }
    });
  }

  void _start() {
    _grades.clear();
    _answers.clear();
    _ms.clear();
    _index = 0;
    _clock
      ..reset()
      ..start();
    _perQuestion
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 0) {
        _finish();
      } else {
        setState(() {});
      }
    });
    setState(() => _phase = _Phase.running);
  }

  int get _remaining => _paper!.timeLimitSeconds - _clock.elapsed.inSeconds;

  void _answer(Grade g, String text) {
    if (_phase != _Phase.running) return;
    _grades[_index] = g;
    _answers[_index] = text;
    _next();
  }

  void _next() {
    _ms[_index] = (_ms[_index] ?? 0) + _perQuestion.elapsedMilliseconds;
    _perQuestion
      ..reset()
      ..start();
    if (_index + 1 >= _paper!.items.length) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _finish() async {
    if (_phase != _Phase.running) return;
    _ticker?.cancel();
    _clock.stop();
    _perQuestion.stop();
    final paper = _paper!;
    final result = ExamResult(
      paper: paper,
      grades: Map.of(_grades),
      elapsedSeconds: _clock.elapsed.inSeconds.clamp(0, paper.timeLimitSeconds),
    );
    setState(() {
      _result = result;
      _phase = _Phase.done;
    });
    final services = RpgServices.of(context);
    final events = [
      for (final e in _grades.entries)
        AnswerEvent(
          questionId: paper.items[e.key].question.id,
          setId: paper.items[e.key].setId,
          category: paper.items[e.key].question.category.name,
          unit: paper.items[e.key].question.unit,
          profile: AnswerProfile.of(paper.items[e.key].question).code,
          isCorrect: e.value.correct,
          elapsedMs: _ms[e.key] ?? 0,
        ),
    ];
    await services.meta.save(
      record: services.meta.record.recordAll(events, day: RpgServices.today()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = RpgCatalog.world(_subject).subject;
    return PopScope(
      canPop: _phase != _Phase.running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _phase != _Phase.running) return;
        final quit = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('総合演習をやめますか？'),
            content: const Text('ここまでの答えで採点します。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('続ける'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('採点する'),
              ),
            ],
          ),
        );
        if (quit == true) _finish();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('総合演習・$name', style: serif(18)),
          actions: [
            if (_phase == _Phase.running)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    _clockText(_remaining),
                    key: const ValueKey('exam-clock'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _remaining < 60 ? TsuzuriColors.wrong : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: NotebookPaper(
          child: switch (_phase) {
            _Phase.loading =>
              _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            _Phase.intro => _intro(),
            _Phase.running => _question(),
            _Phase.done => _ExamResultView(
              result: _result!,
              onRetry: () {
                _attempt++;
                _paper = null;
                _result = null;
                _load();
              },
            ),
          },
        ),
      ),
    );
  }

  static String _clockText(int s) {
    final v = s < 0 ? 0 : s;
    return '残り ${v ~/ 60}:${(v % 60).toString().padLeft(2, '0')}';
  }

  Widget _intro() {
    final paper = _paper!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.margin,
        Space.m,
        Space.l,
        Space.xl,
      ),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final id in examSubjects)
              ChoiceChip(
                key: ValueKey('exam-subject-$id'),
                label: Text(RpgCatalog.world(id).subject),
                selected: id == _subject,
                onSelected: (_) {
                  if (id == _subject) return;
                  _subject = id;
                  _paper = null;
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: Space.m),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${RpgCatalog.world(_subject).subject}の総合演習',
                style: serif(18),
              ),
              const SizedBox(height: 4),
              Text(
                '全${paper.items.length}問・${paper.totalPoints}点満点（100点に換算）・'
                '制限時間${paper.timeLimitSeconds ~/ 60}分',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: Space.s),
              for (final s in ExamSection.values)
                if (paper.itemsOf(s).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${s.title}：${paper.itemsOf(s).length}問 × ${s.points}点　${s.description}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              const SizedBox(height: Space.s),
              Text(
                '4択のほか、正誤・複数選択・並べかえ・数値入力・記述などがまじります。'
                '複数選択・並べかえ・段階の問題・記述は部分点があります。'
                '時間切れになると、そこまでの答えで採点します。'
                '終わったら、分野ごと・思考の種類ごとの得点と、複合弱点を分析します。',
                style: TextStyle(
                  fontSize: 12.5,
                  color: TsuzuriColors.inkSoft,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.l),
        FilledButton.icon(
          key: const ValueKey('exam-start'),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('はじめる'),
        ),
      ],
    );
  }

  Widget _question() {
    final paper = _paper!;
    final item = paper.items[_index];
    final q = item.question;
    return ListView(
      key: ValueKey('exam-q-$_index'),
      padding: const EdgeInsets.fromLTRB(
        Space.margin,
        Space.m,
        Space.l,
        Space.xl,
      ),
      children: [
        Row(
          children: [
            Text(
              '${item.section.title}　第${_index + 1}問 / ${paper.items.length}',
              style: serif(14),
            ),
            const Spacer(),
            Text(
              '${item.points}点・${q.isChoice ? '4択' : q.format.label}',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _index / paper.items.length,
          minHeight: 4,
          backgroundColor: TsuzuriColors.gridLine,
        ),
        const SizedBox(height: Space.m),
        Text(q.prompt, style: const TextStyle(fontSize: 16, height: 1.6)),
        if (q.sentence != null) ...[
          const SizedBox(height: Space.s),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: TsuzuriColors.gridLine),
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Text(
              q.sentence!,
              style: const TextStyle(fontSize: 14.5, height: 1.7),
            ),
          ),
        ],
        const SizedBox(height: Space.m),
        if (q.isChoice)
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: OutlinedButton(
                key: ValueKey('exam-choice-$i'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _answer(ExamGrader.choice(q, i), q.choices[i]),
                child: Text('${'ABCD'[i]}　${q.choices[i]}'),
              ),
            )
        else
          FormatAnswerPane(
            key: ValueKey('exam-pane-${q.id}'),
            question: q,
            locked: false,
            onSubmit: (r) => _answer(r.grade, r.yourAnswer),
          ),
        const SizedBox(height: Space.m),
        Row(
          children: [
            TextButton(
              key: const ValueKey('exam-skip'),
              onPressed: _next,
              child: const Text('とばす'),
            ),
            const Spacer(),
            TextButton(
              key: const ValueKey('exam-finish'),
              onPressed: _finish,
              child: const Text('ここで採点する'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExamResultView extends StatelessWidget {
  const _ExamResultView({required this.result, required this.onRetry});

  final ExamResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final r = result;
    final progress = CurriculumProgress.of(services.meta.record);
    final composites = r.composites(progress);
    final weakest = r.weakestField;
    return ListView(
      key: const ValueKey('exam-result'),
      padding: const EdgeInsets.fromLTRB(
        Space.margin,
        Space.m,
        Space.l,
        Space.xl,
      ),
      children: [
        PaperCard(
          child: Column(
            children: [
              Text('得点', style: TextStyle(color: TsuzuriColors.inkSoft)),
              Text(
                '${r.score}',
                key: const ValueKey('exam-score'),
                style: serif(44, color: TsuzuriColors.stamp),
              ),
              Text(
                '${r.earned.toStringAsFixed(1)} / ${r.paper.totalPoints}点・'
                '${r.elapsedSeconds ~/ 60}分${r.elapsedSeconds % 60}秒'
                '${r.unanswered > 0 ? '・未回答${r.unanswered}問' : ''}',
                style: TextStyle(fontSize: 12.5, color: TsuzuriColors.inkSoft),
              ),
            ],
          ),
        ),
        if (weakest != null) ...[
          const SizedBox(height: Space.s),
          Text(
            'いちばん得点率が低かった分野：${weakest.label}（${weakest.percent}%）',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: Space.m),
        _TallyCard(title: '部ごと', tallies: r.bySection),
        _TallyCard(title: '分野ごと', tallies: r.byField),
        _TallyCard(title: '思考の種類ごと', tallies: r.byThinking),
        _TallyCard(title: '形式ごと', tallies: r.byFormat),
        if (composites.isNotEmpty) ...[
          const SectionTitle('複合弱点'),
          for (final c in composites)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      c.advice,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SectionTitle('問題の見直し'),
        for (var i = 0; i < r.paper.items.length; i++)
          _ReviewTile(index: i, item: r.paper.items[i], grade: r.grades[i]),
        const SizedBox(height: Space.l),
        FilledButton.icon(
          key: const ValueKey('exam-to-growth'),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GrowthScreen(subject: r.paper.subject),
            ),
          ),
          icon: const Icon(Icons.alt_route),
          label: const Text('成長と学習ルートを見る'),
        ),
        const SizedBox(height: Space.s),
        OutlinedButton.icon(
          key: const ValueKey('exam-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('別の問題でもう一度'),
        ),
      ],
    );
  }
}

class _TallyCard extends StatelessWidget {
  const _TallyCard({required this.title, required this.tallies});
  final String title;
  final List<ExamTally> tallies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: serif(15)),
            const SizedBox(height: 4),
            for (final t in tallies)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        t.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: t.percent / 100,
                          minHeight: 7,
                          backgroundColor: TsuzuriColors.gridLine,
                          color: t.percent >= 80
                              ? TsuzuriColors.correct
                              : t.percent >= 60
                              ? TsuzuriColors.exp
                              : TsuzuriColors.wrong,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${t.earned.toStringAsFixed(t.earned % 1 == 0 ? 0 : 1)}/${t.possible}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.index,
    required this.item,
    required this.grade,
  });
  final int index;
  final ExamItem item;
  final Grade? grade;

  @override
  Widget build(BuildContext context) {
    final g = grade;
    final q = item.question;
    final mark = g == null
        ? '－'
        : g.correct
        ? '○'
        : g.credit > 0
        ? '△'
        : '×';
    final color = g == null
        ? TsuzuriColors.inkSoft
        : g.correct
        ? TsuzuriColors.correct
        : g.credit > 0
        ? TsuzuriColors.exp
        : TsuzuriColors.wrong;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Text(
        mark,
        style: TextStyle(
          fontSize: 20,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      title: Text(
        '第${index + 1}問　${q.prompt}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${(item.points * (g?.credit ?? 0)).toStringAsFixed(g != null && g.credit % 1 != 0 ? 1 : 0)}/${item.points}点'
        '${q.unit != null && Curriculum.contains(q.unit!) ? '・${Curriculum.node(q.unit!).displayName}' : ''}',
        style: TextStyle(fontSize: 11.5, color: TsuzuriColors.inkSoft),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '正解：${q.answer}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (g != null && g.detail.isNotEmpty)
          Text(
            g.detail,
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
        if (q.explanation != null) ...[
          const SizedBox(height: 4),
          Text(
            q.explanation!,
            style: const TextStyle(fontSize: 12.5, height: 1.6),
          ),
        ],
      ],
    );
  }
}
