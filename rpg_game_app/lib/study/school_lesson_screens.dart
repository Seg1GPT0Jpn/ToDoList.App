import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../vocab/speech.dart';
import 'school_lesson_store.dart';
import 'shonan_exam_screens.dart';

/// 試験範囲の授業：範囲の単元ごとに「授業 → 確認テスト → 演習 → 復習」を進める画面。
///
/// 教材（授業）の整備状況と、学習者の習得状況を分けて表示する。
class SchoolCourseScreen extends StatefulWidget {
  const SchoolCourseScreen({
    super.key,
    required this.plan,
    required this.subject,
    required this.sp,
  });

  final SchoolExamPlan plan;
  final SchoolSubject subject;

  /// この科目の範囲（問題セット）
  final SubjectExamPlan sp;

  @override
  State<SchoolCourseScreen> createState() => _SchoolCourseScreenState();
}

class _CourseData {
  const _CourseData(this.questions, this.lessons, this.issues);
  final List<QuizQuestion> questions;
  final Map<String, SchoolLesson> lessons;
  final List<SetIssue> issues;
}

class _SchoolCourseScreenState extends State<SchoolCourseScreen> {
  late Future<_CourseData> _data;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _data = _load();
  }

  Future<_CourseData> _load() async {
    final services = RpgServices.of(context);
    final result = await SchoolPractice.build(
      widget.subject,
      widget.sp,
      services.questions.load,
    );
    final lessons = await SchoolLessonStore.lessonsFor(widget.subject.id);
    return _CourseData(
      result.pool?.questions ?? const [],
      SchoolLessons.byUnit(lessons),
      result.issues,
    );
  }

  DateTime? get _examDate => widget.sp.examDate ?? widget.plan.examDate;

  SchoolLessonStore get _store =>
      SchoolLessonStore.of(RpgServices.of(context).personalBooks);

  Future<void> _practice(Set<String> ids, String label) => startSchoolPractice(
    context,
    plan: widget.plan,
    subject: widget.subject,
    sp: widget.sp,
    onlyIds: ids,
    label: label,
  );

  Future<void> _openLesson(UnitCoverage u, {bool quiz = false}) async {
    final lesson = u.lesson;
    if (lesson == null) return;
    final ids = {for (final q in u.group.questions) q.id};
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => quiz
            ? LessonQuizScreen(
                lesson: lesson,
                onPractice: () => _practice(ids, u.name),
              )
            : SchoolLessonScreen(
                lesson: lesson,
                onPractice: () => _practice(ids, u.name),
              ),
      ),
    );
  }

  /// 習得したと初めて判定した単元に日付を残す（あとでまちがえたら「再確認が必要」にする）
  void _markMastered(SubjectCoverage c, Map<String, LessonRecord> records) {
    final now = RpgServices.today();
    for (final u in c.units) {
      final l = u.lesson;
      if (l == null || u.state != LessonState.mastered) continue;
      final r = records[l.id] ?? LessonRecord(lessonId: l.id);
      if (r.masteredDay == 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _store.save(r.copyWith(masteredDay: now)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '授業で学ぶ｜${widget.subject.displayName}',
          style: serif(16),
          maxLines: 2,
        ),
      ),
      body: NotebookPaper(
        child: FutureBuilder<_CourseData>(
          future: _data,
          builder: (context, snap) {
            if (snap.hasError) {
              return _Message('範囲の問題を読み込めませんでした：${snap.error}');
            }
            final data = snap.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (data.questions.isEmpty) {
              return _Message(
                [
                  'この科目は、範囲の問題セットがまだ登録されていません。',
                  'テストの「編集」から範囲と問題セットを登録すると、単元ごとの授業と演習が始められます。',
                  for (final i in data.issues) '・$i',
                ].join('\n'),
              );
            }
            return ListenableBuilder(
              listenable: Listenable.merge([_store, services.meta]),
              builder: (context, _) {
                final records = _store.load();
                final c = SubjectCoverage.build(
                  questions: data.questions,
                  lessons: data.lessons,
                  records: records,
                  stats: services.meta.record.stats,
                );
                _markMastered(c, records);
                return _course(c, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _course(SubjectCoverage c, _CourseData data) {
    final exam = _examDate;
    final days = exam == null
        ? null
        : LessonPlanner.daysUntil(exam, DateTime.now());
    final plan = LessonPlanner.plan(c, daysLeft: days);
    final wrong = LessonPracticeMode.mistakes.pick(c);
    final weak = LessonPracticeMode.weak.pick(c);
    return ListView(
      key: const ValueKey('course-list'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
      children: [
        Text(widget.plan.title, style: serif(15)),
        if (days != null)
          Text(
            days >= 0
                ? '試験まであと$days日　1日の目安：${LessonPlanner.perDay(c, days)}単元'
                : '試験日は過ぎています',
            style: TextStyle(color: TsuzuriColors.inkSoft),
          ),
        const SizedBox(height: 8),
        _CoverageCard(c),
        const SizedBox(height: 12),
        Text('次に学ぶ', style: serif(15)),
        if (plan.isEmpty) const Text('範囲の単元をすべて習得しました。直前チェックで仕上げましょう。'),
        for (final p in plan.take(3))
          Card(
            child: ListTile(
              key: ValueKey('course-next-${p.unit.unitId}'),
              title: Text(p.unit.name),
              subtitle: Text('${p.unit.state.label}｜${p.reason}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _unitAction(p.unit),
            ),
          ),
        const SizedBox(height: 12),
        Text('学習モード', style: serif(15)),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _mode(
              'course-mode-weak',
              Icons.healing,
              '苦手克服（${weak.length}問）',
              weak.isEmpty
                  ? null
                  : () => _practice(weak, LessonPracticeMode.weak.label),
            ),
            _mode(
              'course-mode-mistakes',
              Icons.replay,
              '間違い直し（${wrong.length}問）',
              wrong.isEmpty
                  ? null
                  : () => _practice(wrong, LessonPracticeMode.mistakes.label),
            ),
            _mode(
              'course-mode-points',
              Icons.push_pin_outlined,
              '重要事項の確認',
              data.lessons.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LessonKeyPointsScreen(
                          title: widget.subject.displayName,
                          lessons: [
                            for (final u in c.units)
                              if (u.lesson != null) u.lesson!,
                          ],
                        ),
                      ),
                    ),
            ),
            _mode(
              'course-mode-all',
              Icons.all_inclusive,
              '全範囲の総復習',
              () => _practice(
                LessonPracticeMode.all.pick(c),
                LessonPracticeMode.all.label,
              ),
            ),
            _mode(
              'course-mode-final',
              Icons.alarm,
              '試験直前チェック',
              () => _practice(
                LessonPracticeMode.finalCheck.pick(c),
                LessonPracticeMode.finalCheck.label,
              ),
            ),
            _mode(
              'course-mode-total',
              Icons.sports_esports,
              '範囲内の総合演習',
              () => _practice({
                for (final u in c.units)
                  for (final q in u.group.questions) q.id,
              }, '総合演習'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('範囲の単元（${c.total}）', style: serif(15)),
        for (final u in c.units) _unitCard(u),
        if (c.missing.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('教材がまだそろっていない単元', style: serif(14)),
          for (final u in c.missing)
            Text(
              '・${u.name}：${[if (!u.mapped) '学習体系に未対応', if (!u.hasLesson) '授業なし', if (!u.practiceReady) '演習問題が5問未満か解説なし'].join('・')}',
              style: TextStyle(fontSize: 12.5, color: TsuzuriColors.inkSoft),
            ),
        ],
      ],
    );
  }

  Widget _mode(String key, IconData icon, String label, VoidCallback? onTap) =>
      OutlinedButton.icon(
        key: ValueKey(key),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );

  /// 単元で次にすること（授業が途中なら続き、合格していれば演習）
  void _unitAction(UnitCoverage u) {
    final ids = {for (final q in u.group.questions) q.id};
    switch (u.state) {
      case LessonState.checked ||
          LessonState.practicing ||
          LessonState.mastered ||
          LessonState.recheck:
        _practice(ids, u.name);
      case LessonState.viewed:
        u.lesson == null ? _practice(ids, u.name) : _openLesson(u, quiz: true);
      default:
        u.lesson == null ? _practice(ids, u.name) : _openLesson(u);
    }
  }

  Widget _unitCard(UnitCoverage u) {
    final p = u.practice;
    final color = switch (u.state) {
      LessonState.mastered => TsuzuriColors.correct,
      LessonState.needsReview || LessonState.recheck => TsuzuriColors.wrong,
      _ => TsuzuriColors.inkSoft,
    };
    final record = u.lesson == null ? null : _store.load()[u.lesson!.id];
    return Card(
      key: ValueKey('course-unit-${u.unitId}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    u.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  u.state.label,
                  key: ValueKey('course-state-${u.unitId}'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              [
                u.hasLesson ? '授業あり' : '授業なし（演習のみ）',
                '問題${u.group.questions.length}問',
                if (p.answered > 0)
                  '演習${p.answered}問・最後の正解率${(p.lastAccuracy * 100).round()}％',
                if (record != null && record.quizAttempts > 0)
                  '確認テスト最高${record.quizBest}/${u.lesson!.quiz.length}',
              ].join('　'),
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            Wrap(
              spacing: 4,
              children: [
                if (u.lesson != null)
                  TextButton.icon(
                    key: ValueKey('course-lesson-${u.unitId}'),
                    onPressed: () => _openLesson(u),
                    icon: const Icon(Icons.school_outlined, size: 18),
                    label: Text(
                      (record?.step ?? 0) > 0 && !(record?.viewed ?? false)
                          ? '続きから'
                          : '授業',
                    ),
                  ),
                if (u.lesson != null)
                  TextButton.icon(
                    key: ValueKey('course-quiz-${u.unitId}'),
                    onPressed: () => _openLesson(u, quiz: true),
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('確認テスト'),
                  ),
                TextButton.icon(
                  key: ValueKey('course-practice-${u.unitId}'),
                  onPressed: () => _practice({
                    for (final q in u.group.questions) q.id,
                  }, u.name),
                  icon: const Icon(Icons.sports_esports, size: 18),
                  label: const Text('演習'),
                ),
                if (p.lastWrongIds.isNotEmpty)
                  TextButton.icon(
                    key: ValueKey('course-wrong-${u.unitId}'),
                    onPressed: () =>
                        _practice(p.lastWrongIds.toSet(), '${u.name}の間違い直し'),
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text('間違い直し${p.lastWrongIds.length}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [Text(text, style: const TextStyle(height: 1.6))],
  );
}

/// 範囲の網羅状況（教材の整備と、習得を別々に出す）
class _CoverageCard extends StatelessWidget {
  const _CoverageCard(this.c);
  final SubjectCoverage c;

  @override
  Widget build(BuildContext context) {
    Widget row(String key, String label, int n, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: const TextStyle(fontSize: 12.5)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: SubjectCoverage.rate(n, c.total),
              color: color,
              minHeight: 7,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$n/${c.total}',
            key: ValueKey('coverage-$key'),
            style: const TextStyle(fontSize: 12.5),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.complete
                  ? '試験範囲を完全攻略！'
                  : '範囲の${c.total}単元　要復習${c.needsReview}・未学習${c.notStarted}',
              key: const ValueKey('coverage-summary'),
              style: serif(14),
            ),
            const SizedBox(height: 6),
            Text(
              '教材の整備',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            row('mapped', '学習体系との対応', c.mapped, TsuzuriColors.accent),
            row('lesson', '授業の整備', c.withLesson, TsuzuriColors.accent),
            row('practice', '演習問題の整備', c.withPractice, TsuzuriColors.accent),
            const SizedBox(height: 4),
            Text(
              'あなたの学習',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            row('learned', '授業と確認テスト', c.learned, TsuzuriColors.exp),
            row('mastered', '習得の確認', c.mastered, TsuzuriColors.correct),
            const SizedBox(height: 4),
            Text(
              '習得：確認テストに合格し、別の日の演習でも8割以上正解した単元。',
              style: TextStyle(fontSize: 11.5, color: TsuzuriColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// 授業1つ分を、ステップごとに進める画面（目標 → 説明・例題・途中の問題 → 自己評価 → 確認テストへ）
class SchoolLessonScreen extends StatefulWidget {
  const SchoolLessonScreen({
    super.key,
    required this.lesson,
    this.onPractice,
    this.fromStart = false,
  });

  final SchoolLesson lesson;

  /// 確認テストに合格したあと、この単元の演習を始める
  final VoidCallback? onPractice;

  /// 続きからではなく最初から開く
  final bool fromStart;

  @override
  State<SchoolLessonScreen> createState() => _SchoolLessonScreenState();
}

class _SchoolLessonScreenState extends State<SchoolLessonScreen> {
  SchoolLesson get _l => widget.lesson;

  /// 0：目標のページ、1〜n：ステップ、n+1：おわりのページ
  int _page = 0;
  var _started = false;

  /// 途中の問題ごとの、まちがえた回数・解けたか・答えを見たか
  final Map<int, int> _tries = {};
  final Set<int> _solved = {};
  final Set<int> _revealed = {};
  final Map<int, Set<int>> _picked = {};
  int _understanding = 0;

  /// 先生の話：今のページで何番目まで話したか・自動で進めるか・読み上げるか・全文を出すか
  int _line = 0;
  var _auto = false;
  var _voice = false;
  var _transcript = false;
  Timer? _timer;

  static const _autoKey = 'school_lesson_auto';
  static const _voiceKey = 'school_lesson_voice';

  SchoolLessonStore get _store =>
      SchoolLessonStore.of(RpgServices.of(context).personalBooks);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final prefs = RpgServices.of(context).personalBooks.prefs;
    _auto = prefs.getBool(_autoKey) ?? false;
    _voice = prefs.getBool(_voiceKey) ?? false;
    final r = _store.record(_l.id);
    // 続きから：前に読んだステップの次を開く（読み終わっていれば最初から）
    if (!widget.fromStart && r.step > 0 && r.step < _l.steps.length) {
      _page = r.step;
      // すでに通った途中の問題は解けた扱い（もう一度答えなくても進める）
      for (var i = 0; i < r.step - 1; i++) {
        _solved.add(i);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_voice) speaker.stop();
    super.dispose();
  }

  int get _last => _l.steps.length + 1;

  /// このページで先生が話すこと
  List<String> get _talk {
    if (_page == 0) return _l.opening;
    if (_page >= _last) return _l.closing;
    final s = _l.steps[_page - 1];
    if (s.isCheck) {
      return const ['ここで問題です。今の説明を思い出しながら、自分で解いてみましょう。'];
    }
    return s.talk;
  }

  bool get _talkDone => _line >= _talk.length - 1;

  /// 話を1つ進める（最後まで話したら、自動再生ならページを進める）
  void _say(int line) {
    _timer?.cancel();
    final talk = _talk;
    if (talk.isEmpty) return;
    setState(() => _line = line.clamp(0, talk.length - 1));
    final text = talk[_line];
    if (_voice) speaker.speak(text, lang: 'ja-JP', rate: 0.55);
    if (!_auto) return;
    // 1文字あたりの時間で次の話へ（読み上げ中はゆっくり）
    final ms = 1400 + text.length * (_voice ? 190 : 120);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || !_auto) return;
      if (!_talkDone) {
        _say(_line + 1);
      } else if (_page > 0 && _page < _last && _canNext) {
        _go(_page + 1);
      }
    });
  }

  Future<void> _setAuto(bool v) async {
    setState(() => _auto = v);
    await RpgServices.of(context).personalBooks.prefs.setBool(_autoKey, v);
    if (v) {
      _say(_line);
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _setVoice(bool v) async {
    setState(() => _voice = v);
    await RpgServices.of(context).personalBooks.prefs.setBool(_voiceKey, v);
    if (v) {
      _say(_line);
    } else {
      await speaker.stop();
    }
  }

  bool get _canNext {
    if (_page == 0 || _page == _last) return true;
    final i = _page - 1;
    return !_l.steps[i].isCheck || _solved.contains(i) || _revealed.contains(i);
  }

  Future<void> _go(int page) async {
    _timer?.cancel();
    setState(() {
      _page = page.clamp(0, _last);
      _line = 0;
    });
    if (_auto || _voice) _say(0);
    if (_page == 0) return;
    // 次に開くページを残す（おわりのページまで来たら「授業閲覧済み」）
    final r = _store.record(_l.id);
    final step = _page >= _last ? _l.steps.length : _page;
    if (step > r.step || (_page >= _last && !r.viewed)) {
      await _store.save(
        r.advance(step, _l.steps.length, day: RpgServices.today()),
      );
    }
  }

  Future<void> _toQuiz() async {
    final r = _store.record(_l.id);
    await _store.save(
      r
          .advance(_l.steps.length, _l.steps.length, day: RpgServices.today())
          .copyWith(understanding: _understanding),
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            LessonQuizScreen(lesson: _l, onPractice: widget.onPractice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_l.title, style: serif(16), maxLines: 2)),
      body: NotebookPaper(
        child: Column(
          children: [
            LinearProgressIndicator(value: _page / _last, minHeight: 4),
            Expanded(
              child: ListView(
                key: ValueKey('lesson-page-$_page'),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  if (_page == 0)
                    ..._overview()
                  else if (_page == _last)
                    ..._finish()
                  else
                    _step(_page - 1),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        key: const ValueKey('lesson-back'),
                        onPressed: () => _go(_page - 1),
                        child: const Text('もどる'),
                      ),
                    const Spacer(),
                    Text(
                      '${_page.clamp(0, _l.steps.length)}/${_l.steps.length}',
                      style: TextStyle(color: TsuzuriColors.inkSoft),
                    ),
                    const SizedBox(width: 12),
                    if (_page < _last)
                      FilledButton(
                        key: const ValueKey('lesson-next'),
                        onPressed: _canNext ? () => _go(_page + 1) : null,
                        child: Text(_page == 0 ? '授業を始める' : '次へ'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 先生（アバター・吹き出し・操作）
  Widget _teacher() {
    final talk = _talk;
    if (talk.isEmpty) return const SizedBox.shrink();
    final line = _line.clamp(0, talk.length - 1);
    return _TeacherTalk(
      lines: talk,
      index: line,
      transcript: _transcript,
      auto: _auto,
      voice: _voice,
      onPrev: line > 0 ? () => _say(line - 1) : null,
      onNext: line < talk.length - 1 ? () => _say(line + 1) : null,
      onTranscript: () => setState(() => _transcript = !_transcript),
      onAuto: () => _setAuto(!_auto),
      onVoice: () => _setVoice(!_voice),
    );
  }

  List<Widget> _overview() => [
    _teacher(),
    const SizedBox(height: 14),
    Text('この授業の目標', style: serif(16)),
    for (final g in _l.goals) Text('・$g', style: const TextStyle(height: 1.6)),
    if (_l.prerequisites.isNotEmpty) ...[
      const SizedBox(height: 12),
      Text('前提となる知識', style: serif(14)),
      for (final p in _l.prerequisites)
        Text('・$p', style: const TextStyle(height: 1.6)),
    ],
    if (_l.keywords.isNotEmpty) ...[
      const SizedBox(height: 12),
      Text('重要語句', style: serif(14)),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final k in _l.keywords)
            Chip(label: Text(k), visualDensity: VisualDensity.compact),
        ],
      ),
    ],
    const SizedBox(height: 12),
    Text(
      '説明${_l.blockCount}・途中の問題${_l.inlineChecks.length}・確認テスト${_l.quiz.length}問（${_l.passScore}問正解で合格）',
      style: TextStyle(fontSize: 12.5, color: TsuzuriColors.inkSoft),
    ),
    if (_l.source.isNotEmpty)
      Text(
        '教材：${_l.source}',
        style: TextStyle(fontSize: 11.5, color: TsuzuriColors.inkSoft),
      ),
  ];

  Widget _step(int i) {
    final s = _l.steps[i];
    final check = s.check;
    if (check == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Blackboard(
            label: s.kind!.label,
            heading: s.heading,
            body: s.body,
            warn: s.kind == LessonBlockKind.mistake,
          ),
          const SizedBox(height: 12),
          _teacher(),
        ],
      );
    }
    final tries = _tries[i] ?? 0;
    final solved = _solved.contains(i);
    final revealed = _revealed.contains(i);
    final done = solved || revealed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _teacher(),
        const SizedBox(height: 12),
        Text(
          '自分で解いてみよう',
          style: TextStyle(
            fontSize: 12,
            color: TsuzuriColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(check.prompt, style: const TextStyle(fontSize: 16, height: 1.6)),
        const SizedBox(height: 10),
        for (final (j, c) in check.choices.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton(
              key: ValueKey('lesson-choice-$i-$j'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                backgroundColor: done && check.isCorrect(j)
                    ? TsuzuriColors.correct.withValues(alpha: 0.15)
                    : (_picked[i]?.contains(j) ?? false)
                    ? TsuzuriColors.wrong.withValues(alpha: 0.12)
                    : null,
              ),
              onPressed: done || (_picked[i]?.contains(j) ?? false)
                  ? null
                  : () => setState(() {
                      (_picked[i] ??= {}).add(j);
                      if (check.isCorrect(j)) {
                        _solved.add(i);
                      } else {
                        _tries[i] = tries + 1;
                        if (tries + 1 >= 2) _revealed.add(i);
                      }
                    }),
              child: Text(c, style: const TextStyle(fontSize: 15)),
            ),
          ),
        if (!done && tries == 1)
          _Feedback(
            key: const ValueKey('lesson-hint'),
            title: 'ヒント',
            text: check.hint.isNotEmpty ? check.hint : 'もう一度、ここまでの説明を思い出してみよう。',
            color: TsuzuriColors.exp,
          ),
        if (!done)
          TextButton(
            key: ValueKey('lesson-giveup-$i'),
            onPressed: () => setState(() => _revealed.add(i)),
            child: const Text('わからない（答えと説明を見る）'),
          ),
        if (done)
          _Feedback(
            key: const ValueKey('lesson-feedback'),
            title: solved && tries == 0
                ? '正解！'
                : solved
                ? '正解（2回目）'
                : '答え：${check.answer}',
            text: [
              check.explanation,
              if (revealed && check.reteach.isNotEmpty)
                '\n別の見方：${check.reteach}',
            ].join(),
            color: solved ? TsuzuriColors.correct : TsuzuriColors.wrong,
          ),
      ],
    );
  }

  List<Widget> _finish() => [
    _teacher(),
    const SizedBox(height: 14),
    Text('授業のまとめ', style: serif(17)),
    for (final s in _l.steps)
      if (s.kind == LessonBlockKind.point || s.kind == LessonBlockKind.summary)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('・${s.heading}', style: const TextStyle(height: 1.6)),
        ),
    const SizedBox(height: 16),
    Text('ここまでの理解度は？', style: serif(15)),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      children: [
        for (final (v, label) in [(3, 'よくわかった'), (2, '少し不安'), (1, 'わからない')])
          ChoiceChip(
            key: ValueKey('lesson-understanding-$v'),
            label: Text(label),
            selected: _understanding == v,
            onSelected: (_) => setState(() => _understanding = v),
          ),
      ],
    ),
    if (_understanding == 1) ...[
      const SizedBox(height: 10),
      _Feedback(
        title: '別の角度から',
        text: [
          if (_l.reteach.isNotEmpty) _l.reteach,
          if (_l.prerequisites.isNotEmpty)
            '前提の知識（${_l.prerequisites.join('・')}）があやふやなら、先にそこを見直そう。',
        ].join('\n\n'),
        color: TsuzuriColors.exp,
      ),
      TextButton(
        key: const ValueKey('lesson-restart'),
        onPressed: () => setState(() {
          _page = 1;
          _line = 0;
          _solved.clear();
          _revealed.clear();
          _tries.clear();
          _picked.clear();
        }),
        child: const Text('授業を最初からもう一度'),
      ),
    ],
    const SizedBox(height: 16),
    FilledButton.icon(
      key: const ValueKey('lesson-to-quiz'),
      onPressed: _toQuiz,
      icon: const Icon(Icons.fact_check_outlined),
      label: Text('確認テストへ（${_l.quiz.length}問）'),
    ),
  ];
}

/// 板書：黒板にチョークで書いたような説明
class _Blackboard extends StatelessWidget {
  const _Blackboard({
    required this.label,
    required this.heading,
    required this.body,
    this.warn = false,
  });

  final String label;
  final String heading;
  final String body;
  final bool warn;

  static const _board = Color(0xFF24463A);
  static const _chalk = Color(0xFFF3F1E6);
  static const _yellow = Color(0xFFF2D46B);
  static const _pink = Color(0xFFF2A6A0);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('lesson-board'),
      decoration: BoxDecoration(
        color: _board,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8A6239), width: 6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: warn ? _pink : _yellow,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(heading, style: serif(18).copyWith(color: _chalk)),
          Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: _chalk.withValues(alpha: 0.35),
          ),
          SelectableText(
            body,
            style: const TextStyle(fontSize: 15, height: 1.8, color: _chalk),
          ),
        ],
      ),
    );
  }
}

/// 先生の話：アバターと吹き出しで、1つずつ話す（映像授業のナレーション）
class _TeacherTalk extends StatelessWidget {
  const _TeacherTalk({
    required this.lines,
    required this.index,
    required this.transcript,
    required this.auto,
    required this.voice,
    required this.onPrev,
    required this.onNext,
    required this.onTranscript,
    required this.onAuto,
    required this.onVoice,
  });

  final List<String> lines;
  final int index;
  final bool transcript;
  final bool auto;
  final bool voice;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTranscript;
  final VoidCallback onAuto;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final single = lines.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: TsuzuriColors.accent.withValues(alpha: 0.15),
                  child: Icon(Icons.school, color: TsuzuriColors.accent),
                ),
                const SizedBox(height: 2),
                Text(
                  'つづり先生',
                  style: TextStyle(fontSize: 10, color: TsuzuriColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  key: const ValueKey('lesson-talk'),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                      color: TsuzuriColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: transcript
                        ? Column(
                            key: const ValueKey('all'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (i, t) in lines.indexed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.65,
                                      color: i == index
                                          ? TsuzuriColors.ink
                                          : TsuzuriColors.inkSoft,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            lines[index],
                            key: ValueKey(index),
                            style: const TextStyle(fontSize: 15.5, height: 1.7),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!single)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 52),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                IconButton(
                  key: const ValueKey('lesson-talk-prev'),
                  tooltip: '前の話',
                  visualDensity: VisualDensity.compact,
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${index + 1}/${lines.length}',
                  key: const ValueKey('lesson-talk-count'),
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
                IconButton(
                  key: const ValueKey('lesson-talk-next'),
                  tooltip: '次の話',
                  visualDensity: VisualDensity.compact,
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton(
                  key: const ValueKey('lesson-talk-auto'),
                  tooltip: auto ? '自動再生を止める' : '自動再生',
                  visualDensity: VisualDensity.compact,
                  isSelected: auto,
                  onPressed: onAuto,
                  icon: Icon(auto ? Icons.pause_circle : Icons.play_circle),
                ),
                IconButton(
                  key: const ValueKey('lesson-talk-voice'),
                  tooltip: voice ? '読み上げを止める' : '読み上げる',
                  visualDensity: VisualDensity.compact,
                  isSelected: voice,
                  onPressed: onVoice,
                  icon: Icon(voice ? Icons.volume_up : Icons.volume_off),
                ),
                TextButton(
                  key: const ValueKey('lesson-talk-all'),
                  onPressed: onTranscript,
                  child: Text(transcript ? '1つずつ' : '話をすべて表示'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    super.key,
    required this.title,
    required this.text,
    required this.color,
  });
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      border: Border.all(color: color.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(height: 1.6)),
      ],
    ),
  );
}

/// 授業の確認テスト（合格すると「理解度確認済み」、不合格なら「要復習」）
class LessonQuizScreen extends StatefulWidget {
  const LessonQuizScreen({super.key, required this.lesson, this.onPractice});

  final SchoolLesson lesson;
  final VoidCallback? onPractice;

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  int _i = 0;
  int _score = 0;
  int? _picked;
  bool _saved = false;

  SchoolLesson get _l => widget.lesson;
  bool get _done => _i >= _l.quiz.length;

  Future<void> _next() async {
    setState(() {
      _i++;
      _picked = null;
    });
    if (_done && !_saved) {
      _saved = true;
      final store = SchoolLessonStore.of(RpgServices.of(context).personalBooks);
      await store.save(
        store
            .record(_l.id)
            .withQuiz(_score, _l.passScore, day: RpgServices.today()),
      );
    }
  }

  void _retry() => setState(() {
    _i = 0;
    _score = 0;
    _picked = null;
    _saved = false;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('確認テスト｜${_l.title}', style: serif(15))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: _done ? _result() : _question(),
        ),
      ),
    );
  }

  List<Widget> _question() {
    final q = _l.quiz[_i];
    final picked = _picked;
    return [
      Text(
        '${_i + 1} / ${_l.quiz.length}',
        style: TextStyle(color: TsuzuriColors.inkSoft),
      ),
      const SizedBox(height: 6),
      Text(q.prompt, style: const TextStyle(fontSize: 16, height: 1.6)),
      const SizedBox(height: 10),
      for (final (j, c) in q.choices.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: OutlinedButton(
            key: ValueKey('quiz-choice-$j'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: picked == null
                  ? null
                  : q.isCorrect(j)
                  ? TsuzuriColors.correct.withValues(alpha: 0.15)
                  : picked == j
                  ? TsuzuriColors.wrong.withValues(alpha: 0.12)
                  : null,
            ),
            onPressed: picked != null
                ? null
                : () => setState(() {
                    _picked = j;
                    if (q.isCorrect(j)) _score++;
                  }),
            child: Text(c, style: const TextStyle(fontSize: 15)),
          ),
        ),
      if (picked != null) ...[
        _Feedback(
          title: q.isCorrect(picked) ? '正解！' : '答え：${q.answer}',
          text: q.explanation,
          color: q.isCorrect(picked)
              ? TsuzuriColors.correct
              : TsuzuriColors.wrong,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const ValueKey('quiz-next'),
            onPressed: _next,
            child: Text(_i + 1 >= _l.quiz.length ? '結果を見る' : '次の問題'),
          ),
        ),
      ],
    ];
  }

  List<Widget> _result() {
    final pass = _score >= _l.passScore;
    return [
      Text(
        '${_l.quiz.length}問中$_score問正解',
        key: const ValueKey('quiz-score'),
        style: serif(20),
      ),
      Text(
        pass ? '合格！（理解度確認済み）' : '不合格（${_l.passScore}問正解で合格）。要復習になりました。',
        style: TextStyle(
          color: pass ? TsuzuriColors.correct : TsuzuriColors.wrong,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      if (pass)
        const Text(
          'このあと、この単元の演習問題を解きましょう。別の日の演習でも8割以上正解すると「習得」になります。',
          style: TextStyle(height: 1.6),
        )
      else if (_l.reteach.isNotEmpty)
        _Feedback(title: '別の角度から', text: _l.reteach, color: TsuzuriColors.exp),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (pass && widget.onPractice != null)
            FilledButton.icon(
              key: const ValueKey('quiz-practice'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPractice!();
              },
              icon: const Icon(Icons.sports_esports),
              label: const Text('この単元の演習へ'),
            ),
          if (!pass)
            FilledButton.icon(
              key: const ValueKey('quiz-relesson'),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => SchoolLessonScreen(
                    lesson: _l,
                    onPractice: widget.onPractice,
                    fromStart: true,
                  ),
                ),
              ),
              icon: const Icon(Icons.school_outlined),
              label: const Text('授業をもう一度'),
            ),
          OutlinedButton(
            key: const ValueKey('quiz-retry'),
            onPressed: _retry,
            child: const Text('もう一度テスト'),
          ),
          TextButton(
            key: const ValueKey('quiz-close'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('単元の一覧へ'),
          ),
        ],
      ),
    ];
  }
}

/// 重要事項の確認：範囲の授業の重要語句・重要事項・まとめを一覧で見る
class LessonKeyPointsScreen extends StatelessWidget {
  const LessonKeyPointsScreen({
    super.key,
    required this.title,
    required this.lessons,
  });

  final String title;
  final List<SchoolLesson> lessons;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('重要事項の確認｜$title', style: serif(15))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            for (final l in lessons) ...[
              Text(l.title, style: serif(16)),
              if (l.keywords.isNotEmpty)
                Text(
                  l.keywords.join('・'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
              for (final s in l.steps)
                if (s.kind == LessonBlockKind.point ||
                    s.kind == LessonBlockKind.summary ||
                    s.kind == LessonBlockKind.mistake)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.kind!.label}｜${s.heading}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(s.body, style: const TextStyle(height: 1.6)),
                      ],
                    ),
                  ),
              const Divider(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}
