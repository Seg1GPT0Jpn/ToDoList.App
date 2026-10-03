import 'dart:async';

import '../quiz/figure_view.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/practice.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import 'realm_style.dart';

/// 解放ずみの教科のワールド
List<WorldDef> _playable(RpgProgress p) => [
  for (final w in RpgCatalog.worlds)
    if (Progression.isWorldPlayable(p, w)) w,
];

/// 🏰 共通テスト遺跡：5つの階層を下から順に攻略する
class CommonTestRuinsScreen extends StatelessWidget {
  const CommonTestRuinsScreen({super.key});

  static String _flag(RuinsFloor f) => 'ruins:${f.name}';

  Future<void> _start(BuildContext context, RuinsFloor floor) async {
    final services = RpgServices.of(context);
    // 問題を集めるのに少し時間がかかるので、押したことが分かるようにする
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${floor.label}の問いを集めています…'),
        duration: const Duration(seconds: 2),
      ),
    );
    final progress = await services.repository.load();
    final worlds = _playable(progress);
    final picked = CommonTest.stagesFor(
      floor,
      worlds,
      seed: RpgServices.today() * 7 + floor.index,
    );
    final questions = <QuizQuestion>[];
    for (final s in picked) {
      final pool = await services.loadStagePool(s);
      if (pool != null && pool.origin.usableInRpg) {
        questions.addAll(pool.questions);
      }
    }
    final filtered = CommonTest.filter(floor, questions);
    if (filtered.isEmpty || !context.mounted) return;
    final stage = CommonTest.stage(floor, picked, level: progress.level);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(stage.worldId),
          stage: stage,
          questions: filtered,
          progress: progress,
          trial: true,
          mode: BattleMode.review,
          onFinished: (summary) async {
            if (!summary.won) return;
            final latest = await services.repository.load();
            await services.repository.save(
              latest.copyWith(fieldFlags: {...latest.fieldFlags, _flag(floor)}),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return StreamBuilder<RpgProgress>(
      stream: services.repository.watch(),
      builder: (context, snap) {
        final p = snap.data ?? RpgProgress.initial;
        final subjects = _playable(p).map((w) => w.subject).join('・');
        return Scaffold(
          appBar: AppBar(title: Text('共通テスト遺跡', style: serif(18))),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text(
                  '各階層は「ボスの連戦」。前のボスが弱ると次のボスが乱入してきて、'
                  '2体のボスが重なって攻めてきます（HP は最後まで引き継ぎ）。'
                  'すべてのボスをたおすと、上の階層へ進めます。上の階層ほどボスが多く、'
                  '考察・計算・読解の問題や、教科をまたいだ出題が増えます。\n'
                  '出題する教科：$subjects\n'
                  '※ 問題はすべてオリジナルです（共通テストの過去問ではありません）。',
                  style: const TextStyle(fontSize: 12.5, height: 1.6),
                ),
                const SizedBox(height: 12),
                for (final f in RuinsFloor.values.reversed)
                  _floorCard(context, p, f),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _floorCard(BuildContext context, RpgProgress p, RuinsFloor f) {
    final cleared = p.fieldFlags.contains(_flag(f));
    final open =
        f.index == 0 ||
        p.fieldFlags.contains(_flag(RuinsFloor.values[f.index - 1]));
    final color = f == RuinsFloor.real
        ? TsuzuriColors.stamp
        : TsuzuriColors.accent;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        enabled: open,
        leading: Icon(
          cleared
              ? Icons.check_circle
              : open
              ? Icons.castle
              : Icons.lock_outline,
          color: cleared ? TsuzuriColors.correct : color,
        ),
        title: Text('${f.label}：${f.title}', style: serif(14, color: color)),
        subtitle: Text('${f.description}・ボス${CommonTest.bossCount(f)}体の連戦'),
        trailing: open ? const Icon(Icons.play_arrow_rounded) : null,
        onTap: open ? () => _start(context, f) : null,
      ),
    );
  }
}

/// ⏱ 入試模試（高校入試の空の中）：制限時間の中で教科を順に進み、最後に成績と弱点を出す
class MockExamScreen extends StatefulWidget {
  const MockExamScreen({super.key});

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _Item {
  _Item(this.subject, this.setId, this.question, this.choices, this.answer);
  final String subject;
  final String setId;
  final QuizQuestion question;
  final List<String> choices;
  final int answer;
  int? chosen;
  int ms = 0;
}

class _MockExamScreenState extends State<MockExamScreen> {
  final _chosenSubjects = <String>{};

  /// 問題を読みこんでいる
  bool _loading = false;
  List<_Item>? _items;
  int _index = 0;
  bool _finished = false;
  Timer? _ticker;
  int _secondsLeft = 0;
  final _stopwatch = Stopwatch();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _begin(List<WorldDef> worlds) async {
    final services = RpgServices.of(context);
    setState(() => _loading = true);
    final rnd = Random();
    final items = <_Item>[];
    for (final w in worlds.where((w) => _chosenSubjects.contains(w.id))) {
      final pool = <(String, QuizQuestion)>[];
      for (final s in MockExam.stagesFor(w, seed: rnd.nextInt(1 << 20))) {
        final set = await services.loadStagePool(s);
        if (set == null || !set.origin.usableInRpg) continue;
        for (final q in set.questions.where(
          (q) => q.passage == null && q.isChoice,
        )) {
          pool.add((services.questions.setIdOf(q.id) ?? s.questionSetId, q));
        }
      }
      pool.shuffle(rnd);
      for (final (setId, q) in pool.take(MockExam.perSubject)) {
        final order = [0, 1, 2, 3]..shuffle(rnd);
        items.add(
          _Item(w.id, setId, q, [
            for (final i in order) q.choices[i],
          ], order.indexOf(q.answerIndex)),
        );
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (items.isEmpty) return;
    setState(() {
      _items = items;
      _index = 0;
      _secondsLeft = MockExam.secondsPerSubject * _chosenSubjects.length;
    });
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish();
    });
  }

  void _answer(int i) {
    final item = _items![_index];
    item
      ..chosen = i
      ..ms = _stopwatch.elapsedMilliseconds;
    _stopwatch
      ..reset()
      ..start();
    if (_index + 1 >= _items!.length) {
      _finish();
    } else {
      setState(() => _index++);
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _ticker?.cancel();
    _stopwatch.stop();
    setState(() => _finished = true);
    final services = RpgServices.of(context);
    final events = [
      for (final it in _items!)
        if (it.chosen != null)
          AnswerEvent(
            questionId: it.question.id,
            setId: it.setId,
            category: it.question.category.name,
            unit: it.question.unit,
            profile: AnswerProfile.of(it.question).code,
            isCorrect: it.chosen == it.answer,
            elapsedMs: it.ms,
          ),
    ];
    await services.meta.save(
      record: services.meta.record.recordAll(events, day: RpgServices.today()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StudyRealm.sky.paper,
        title: Text('入試模試', style: serif(18, color: StudyRealm.sky.ink)),
      ),
      body: NotebookPaper(
        child: StreamBuilder<RpgProgress>(
          stream: services.repository.watch(),
          builder: (context, snap) {
            final worlds = _playable(snap.data ?? RpgProgress.initial);
            if (_items == null) return _setup(worlds);
            if (_finished) return _result();
            return _question();
          },
        ),
      ),
    );
  }

  Widget _setup(List<WorldDef> worlds) => ListView(
    padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
    children: [
      const Text(
        '制限時間の中で、選んだ教科を順に進んでいきます（1教科5問・2分30秒）。'
        '最後に教科ごとの点数（100点満点）と、弱点の単元が出ます。',
        style: TextStyle(fontSize: 13, height: 1.6),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final w in worlds)
            FilterChip(
              label: Text(w.subject),
              selected: _chosenSubjects.contains(w.id),
              onSelected: (on) => setState(
                () => on
                    ? _chosenSubjects.add(w.id)
                    : _chosenSubjects.remove(w.id),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _chosenSubjects.isEmpty || _loading
            ? null
            : () => _begin(worlds),
        icon: const Icon(Icons.timer),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            _loading
                ? '問題を集めています…'
                : _chosenSubjects.isEmpty
                ? '教科を選んでください'
                : '模試を始める（${_chosenSubjects.length}教科・${_chosenSubjects.length * MockExam.perSubject}問）',
          ),
        ),
      ),
    ],
  );

  Widget _question() {
    final item = _items![_index];
    final q = item.question;
    final m = _secondsLeft ~/ 60, s = _secondsLeft % 60;
    return ListView(
      padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
      children: [
        Row(
          children: [
            Text(
              '${RpgCatalog.world(item.subject).subject}　${_index + 1} / ${_items!.length}',
              style: serif(15),
            ),
            const Spacer(),
            Text(
              '残り $m:${s.toString().padLeft(2, '0')}',
              style: serif(
                15,
                color: _secondsLeft < 30
                    ? TsuzuriColors.stamp
                    : TsuzuriColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(q.prompt, style: const TextStyle(fontSize: 16, height: 1.6)),
        if (q.figure != null) FigureView(q.figure!),
        if (q.sentence != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              q.sentence!,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => _answer(i),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
              ),
              child: Text(
                item.choices[i],
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _result() {
    final items = _items!;
    final bySubject = <String, (int, int)>{};
    final missedSets = <String, int>{};
    for (final it in items) {
      final (c, n) = bySubject[it.subject] ?? (0, 0);
      final ok = it.chosen == it.answer;
      bySubject[it.subject] = (c + (ok ? 1 : 0), n + 1);
      if (!ok) missedSets[it.setId] = (missedSets[it.setId] ?? 0) + 1;
    }
    final weak = missedSets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
      children: [
        Text('今回の冒険結果', style: serif(20, color: TsuzuriColors.accent)),
        const SizedBox(height: 10),
        for (final e in bySubject.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    RpgCatalog.world(e.key).subject,
                    style: serif(15),
                  ),
                ),
                Text(
                  '${MockExam.score(e.value.$1, e.value.$2)} / 100',
                  style: serif(18),
                ),
                const SizedBox(width: 8),
                Text(
                  '（${e.value.$1}/${e.value.$2}問）',
                  style: TextStyle(color: TsuzuriColors.inkSoft),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text('あなたの弱点', style: serif(16)),
        if (weak.isEmpty)
          const Text('全問正解！ 弱点は見つかりませんでした。')
        else
          for (final e in weak.take(4))
            if (Proficiency.stageOfSet(e.key) case final st?)
              Card(
                margin: const EdgeInsets.only(top: 6),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${RpgCatalog.world(st.worldId).subject}・${st.grammarTheme}',
                  ),
                  subtitle: Text('${e.value}問まちがえた'),
                  trailing: TextButton(
                    onPressed: () => startPractice(context, st),
                    child: const Text('練習'),
                  ),
                ),
              ),
        const SizedBox(height: 14),
        Text('見直し', style: serif(16)),
        for (final it in items)
          if (it.chosen != it.answer)
            Card(
              margin: const EdgeInsets.only(top: 6),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  '${it.question.prompt}${it.question.sentence == null ? '' : '　${it.question.sentence}'}\n'
                  '正解：${it.question.answer}\n${it.question.explanation ?? ''}',
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ),
            ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() {
            _items = null;
            _finished = false;
          }),
          child: const Text('もう一度'),
        ),
      ],
    );
  }
}
