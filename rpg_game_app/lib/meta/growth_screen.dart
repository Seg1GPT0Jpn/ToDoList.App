import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/practice.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../study/comprehensive_exam_screen.dart';
import 'design.dart';

/// 総合演習と成長の画面で選べる教科
const examSubjects = [
  'english',
  'math',
  'japanese',
  'science',
  'social',
  'information',
];

/// 成長と学習ルート：何ができるようになったか（4つのものさし）、
/// 学習の段階のはしご、苦手からさかのぼる学習ルート、複合弱点。
class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key, this.subject});

  /// 最初に選んでおく教科（null なら全教科）
  final String? subject;

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  late String? _subject = widget.subject;
  final Map<String, List<QuizQuestion>> _composite = {};
  bool _loadingComposite = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadComposite();
  }

  /// 複合問題（combines つき）の多い追加問題のセットを読む
  Future<void> _loadComposite() async {
    if (_loadingComposite) return;
    _loadingComposite = true;
    final services = RpgServices.of(context);
    for (final e in ExtraSets.all) {
      if (_composite.containsKey(e.id)) continue;
      final set = await services.questions.load(e.id);
      _composite[e.id] = [
        for (final q in set?.questions ?? const <QuizQuestion>[])
          if (q.combines.isNotEmpty) q,
      ];
    }
    _loadingComposite = false;
    if (mounted) setState(() {});
  }

  Future<void> _practice(String unitId) async {
    final error = await startUnitPractice(context, unitId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('成長と学習ルート', style: serif(18))),
      body: NotebookPaper(
        child: ListenableBuilder(
          listenable: services.meta,
          builder: (context, _) {
            final record = services.meta.record;
            final progress = CurriculumProgress.of(record);
            final growth = GrowthReport.of(record, subject: _subject);
            final ladder = PhaseLadder.of(record, subject: _subject);
            final routes = LearningRoute.forWeakUnits(
              progress,
              under: _subject,
              limit: 3,
            );
            final composites = CompositeWeakness.find(
              [
                for (final e in _composite.entries)
                  if (_subject == null ||
                      LearningRecord.subjectOf(e.key) == _subject)
                    ...e.value,
              ],
              CompositeWeakness.creditsFrom(record),
              progress,
            );
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
                    ChoiceChip(
                      key: const ValueKey('growth-all'),
                      label: const Text('全教科'),
                      selected: _subject == null,
                      onSelected: (_) => setState(() => _subject = null),
                    ),
                    for (final id in examSubjects)
                      ChoiceChip(
                        key: ValueKey('growth-$id'),
                        label: Text(RpgCatalog.world(id).subject),
                        selected: _subject == id,
                        onSelected: (_) => setState(() => _subject = id),
                      ),
                  ],
                ),
                const SizedBox(height: Space.m),
                const SectionTitle('できるようになったこと'),
                PaperCard(
                  key: const ValueKey('growth-measures'),
                  child: Column(
                    children: [
                      for (final m in growth.all) _MeasureRow(measure: m),
                    ],
                  ),
                ),
                const SizedBox(height: Space.m),
                const SectionTitle('学習の段階'),
                _LadderCard(ladder: ladder),
                const SizedBox(height: Space.m),
                const SectionTitle('学習ルート'),
                if (routes.isEmpty)
                  _Note('正答率60%未満の単元はまだありません（1つの単元で5問以上答えると判定します）。')
                else
                  for (final r in routes)
                    _RouteCard(route: r, onPractice: _practice),
                const SizedBox(height: Space.m),
                const SectionTitle('複合弱点'),
                if (_loadingComposite && _composite.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (composites.isEmpty)
                  _Note('2つの単元を組み合わせる問題（応用・難関の問題）でのつまずきは、まだ見つかっていません。')
                else
                  for (final c in composites.take(5))
                    _CompositeCard(composite: c, onPractice: _practice),
                const SizedBox(height: Space.l),
                FilledButton.icon(
                  key: const ValueKey('open-exam'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ComprehensiveExamScreen(subject: _subject ?? 'math'),
                    ),
                  ),
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(
                    '${RpgCatalog.world(_subject ?? 'math').subject}の総合演習を受ける',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        color: TsuzuriColors.inkSoft,
        height: 1.5,
      ),
    ),
  );
}

Color _rateColor(int p) => p >= 80
    ? TsuzuriColors.correct
    : p >= 60
    ? TsuzuriColors.exp
    : TsuzuriColors.wrong;

class _MeasureRow extends StatelessWidget {
  const _MeasureRow({required this.measure});
  final GrowthMeasure measure;

  @override
  Widget build(BuildContext context) {
    final m = measure;
    final p = m.percent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                p == null
                    ? '—'
                    : m.rated
                    ? '$p%'
                    : '$p%（${m.tried}回・判定はまだ）',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: p == null || !m.rated
                      ? TsuzuriColors.inkSoft
                      : _rateColor(p),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (p ?? 0) / 100,
              minHeight: 7,
              backgroundColor: TsuzuriColors.gridLine,
              color: _rateColor(p ?? 0),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            m.description,
            style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _LadderCard extends StatelessWidget {
  const _LadderCard({required this.ladder});
  final PhaseLadder ladder;

  @override
  Widget build(BuildContext context) {
    final current = ladder.current.phase;
    return PaperCard(
      key: const ValueKey('phase-ladder'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'いまの段：フェーズ${current.number}「${current.label}」',
            style: serif(15),
          ),
          Text(
            'その段階の問題を${PhaseStep.clearQuestions}問以上解き、正答率${PhaseStep.clearPercent}%以上で到達。'
            '下の段から順にのぼります。',
            style: TextStyle(fontSize: 11.5, color: TsuzuriColors.inkSoft),
          ),
          const SizedBox(height: Space.s),
          for (final s in ladder.steps.reversed)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: s.phase == current
                    ? TsuzuriColors.accent.withValues(alpha: 0.12)
                    : null,
                borderRadius: BorderRadius.circular(Radii.chip),
                border: Border.all(
                  color: s.cleared
                      ? TsuzuriColors.correct
                      : s.phase == current
                      ? TsuzuriColors.accent
                      : TsuzuriColors.gridLine,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    s.cleared
                        ? Icons.check_circle
                        : s.phase == current
                        ? Icons.flag
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: s.cleared
                        ? TsuzuriColors.correct
                        : s.phase == current
                        ? TsuzuriColors.accent
                        : TsuzuriColors.inkSoft,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'フェーズ${s.phase.number} ${s.phase.label}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    s.questions == 0 ? '未挑戦' : '${s.questions}問・${s.percent}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Color _statusColor(RouteStatus s) => switch (s) {
  RouteStatus.mastered => TsuzuriColors.correct,
  RouteStatus.solid => TsuzuriColors.exp,
  RouteStatus.weak => TsuzuriColors.wrong,
  _ => TsuzuriColors.inkSoft,
};

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onPractice});
  final LearningRoute route;
  final ValueChanged<String> onPractice;

  @override
  Widget build(BuildContext context) {
    final root = route.rootCause;
    final next = route.nextStep;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: PaperCard(
        key: ValueKey('route-${route.target.node.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '苦手：${Curriculum.breadcrumb(route.target.node.id)}'
              '（正答率${route.target.progress.accuracy}%）',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              root != null
                  ? '根本の原因は前提の「${root.node.displayName}」かもしれません。ここから学び直すのが近道です。'
                  : route.prerequisites.isEmpty
                  ? 'この単元そのものを練習しましょう。'
                  : '前提の単元はおおむね大丈夫です。この単元そのものを練習しましょう。',
              style: TextStyle(
                fontSize: 12.5,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < route.steps.length; i++) ...[
                  if (i > 0)
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: TsuzuriColors.inkSoft,
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.chip),
                      border: Border.all(
                        color: _statusColor(route.steps[i].status),
                        width: route.steps[i] == next ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${route.steps[i].node.displayName}・${route.steps[i].status.label}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _statusColor(route.steps[i].status),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: ValueKey('route-practice-${route.target.node.id}'),
                onPressed: () => onPractice(next.node.id),
                icon: const Icon(Icons.play_arrow),
                label: Text('「${next.node.displayName}」を練習'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompositeCard extends StatelessWidget {
  const _CompositeCard({required this.composite, required this.onPractice});
  final CompositeWeakness composite;
  final ValueChanged<String> onPractice;

  @override
  Widget build(BuildContext context) {
    final c = composite;
    final target = c.combinedStatus.needsWork ? c.combined : c.unit;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '${c.tried}問中${c.missed}問でつまずき。${c.advice}',
              style: TextStyle(
                fontSize: 12.5,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onPractice(target),
                child: Text('「${Curriculum.node(target).displayName}」を練習'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
