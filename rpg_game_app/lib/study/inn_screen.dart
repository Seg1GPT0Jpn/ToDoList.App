import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'practice_view.dart';

/// 宿：次の敵に向けた授業と練習問題
class InnScreen extends StatefulWidget {
  const InnScreen({super.key, required this.stage});

  final StageDef stage;

  @override
  State<InnScreen> createState() => _InnScreenState();
}

enum _Phase { lesson, practice, result }

class _InnScreenState extends State<InnScreen> {
  static const practiceCount = 5;

  late InnLesson lesson = InnLessons.forStage(widget.stage.id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (lesson.points.isEmpty) _buildLessonFromQuestions();
  }

  /// 手書きの授業がないエリアは、そのエリアの問題の解説から要点を3つ作る
  Future<void> _buildLessonFromQuestions() async {
    final set = await RpgServices.of(context).questions
        .load(widget.stage.questionSetIds.last);
    if (!mounted || set == null) return;
    final picks = [
      ...set.questions.where((q) => q.category == QuestionCategory.knowledge),
      ...set.questions.where((q) => q.category != QuestionCategory.knowledge),
    ].where((q) => (q.explanation ?? '').isNotEmpty).take(3);
    setState(() {
      lesson = InnLesson(
        stageId: lesson.stageId,
        teacher: lesson.teacher,
        title: lesson.title,
        points: [
          for (final q in picks)
            LessonPoint(q.answer, q.explanation!, q.sentence ?? q.prompt),
        ],
      );
    });
  }

  _Phase _phase = _Phase.lesson;
  PracticeSession? _session;
  ExpGainResult? _gain;
  String? _error;

  Future<void> _startPractice() async {
    final services = RpgServices.of(context);
    final stage = widget.stage;
    // 理科：そのエリアの単元の問題だけで練習する（ボスでも自分のエリアの問題）
    if (stage.branch.isNotEmpty) {
      final own = await services.questions.load(stage.questionSetIds.last);
      if (!mounted) return;
      if (own == null ||
          !own.origin.usableInRpg ||
          !own.questions.any((q) => q.isChoice)) {
        setState(() => _error = '練習問題を読み込めませんでした');
        return;
      }
      setState(() {
        _session = PracticeSession(own.questions, count: practiceCount);
        _phase = _Phase.practice;
      });
      return;
    }
    final set = await services.loadStagePool(widget.stage);
    if (!mounted) return;
    if (set == null || !set.origin.usableInRpg) {
      setState(() => _error = '練習問題を読み込めませんでした');
      return;
    }
    // 授業のテーマ（文法）の問題から出す。長文エリアではエリア1〜15の文法問題を使う。
    bool grammar(QuizQuestion q) =>
        q.category == QuestionCategory.usage &&
        q.passage == null &&
        q.isChoice;
    var pool = set.questions.where(grammar).toList();
    if (pool.isEmpty) {
      final first = RpgCatalog.englishStages.firstWhere((s) => s.order == 16);
      final all = await services.loadStagePool(first);
      if (!mounted) return;
      pool = all?.questions.where(grammar).toList() ?? [];
    }
    if (pool.isEmpty) {
      setState(() => _error = '練習問題を読み込めませんでした');
      return;
    }
    setState(() {
      _session = PracticeSession(pool, count: practiceCount);
      _phase = _Phase.practice;
    });
  }

  Future<void> _finish() async {
    final repo = RpgServices.of(context).repository;
    final p = await repo.load();
    final gain = Progression.applyTraining(
      p,
      _session!.correctCount,
      stage: widget.stage,
    );
    await repo.save(gain.progress);
    if (!mounted) return;
    setState(() {
      _gain = gain;
      _phase = _Phase.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TsuzuriColors.paper,
        title: Text('宿屋 ― ${lesson.title}', style: serif(17)),
      ),
      body: NotebookPaper(
        child: SafeArea(
          top: false,
          child: switch (_phase) {
            _Phase.lesson => _lessonView(),
            _Phase.practice => PracticeView(
              session: _session!,
              onFinished: _finish,
            ),
            _Phase.result => _resultView(),
          },
        ),
      ),
    );
  }

  Widget _lessonView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TsuzuriColors.tint(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TsuzuriColors.tint(0xFFE8D29A)),
          ),
          child: Text(
            '${lesson.teacher}「この先には${widget.stage.enemy.name}が待っておる。'
            '${lesson.title}のコツを教えてしんぜよう。」',
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, p) in lesson.points.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TsuzuriColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TsuzuriColors.tint(0xFFE0D4C0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}. ${p.heading}',
                  style: serif(16, color: TsuzuriColors.accent),
                ),
                const SizedBox(height: 6),
                Text(p.body, style: const TextStyle(fontSize: 14, height: 1.6)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TsuzuriColors.paper,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '例）${p.example}',
                    style: serif(14, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: TsuzuriColors.wrong)),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _startPractice,
          icon: const Icon(Icons.edit),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '練習問題（$practiceCount問）に挑戦',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '正解1問につき 2 EXP。何度でも受けられます。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
        ),
      ],
    );
  }

  Widget _resultView() {
    final g = _gain!;
    return PracticeSummary(
      session: _session!,
      extra: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TsuzuriColors.tint(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '訓練完了！ +${g.expGained} EXP'
            '${g.leveledUp ? '\nレベルアップ！ Lv${g.after.level}（HP ${g.after.maxHp} / 攻撃 ${g.after.attack}）' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.6),
          ),
        ),
      ],
      actions: [
        OutlinedButton(
          onPressed: () => setState(() => _phase = _Phase.lesson),
          child: const Text('もう一度授業を受ける'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('フィールドにもどる'),
        ),
      ],
    );
  }
}
