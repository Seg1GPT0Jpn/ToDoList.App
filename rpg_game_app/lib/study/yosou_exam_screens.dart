import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/scratchpad.dart';
import '../vocab/speech.dart';
import 'school_exam_store.dart';
import 'yosou_crop_view.dart';
import 'yosou_exam_store.dart';
import 'yosou_question_view.dart';

/// 予想問題の一覧（60分で解く）
class YosouExamListScreen extends StatefulWidget {
  const YosouExamListScreen({super.key});

  @override
  State<YosouExamListScreen> createState() => _YosouExamListScreenState();
}

class _YosouExamListScreenState extends State<YosouExamListScreen> {
  final _password = TextEditingController();
  List<int>? _key;
  bool _checking = false;
  String? _error;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final saved = _gate.secret;
    if (saved != null) _try(saved, remember: false);
  }

  SchoolExamStore get _gate =>
      SchoolExamStore.of(RpgServices.of(context).personalBooks);
  YosouExamStore get _store =>
      YosouExamStore.of(RpgServices.of(context).personalBooks);

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// パスワードで1つ目の解答用紙が開けるか確かめ、開ければ鍵として使う
  Future<void> _try(String password, {required bool remember}) async {
    if (password.trim().isEmpty || YosouExams.all.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final gate = _gate;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final key = SchoolMaterials.keyFor(password);
    final sheet = await YosouExamFiles(YosouExams.all.first, key).sheet();
    if (sheet != null && remember) await gate.saveSecret(password);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (sheet != null) {
        _key = key;
        YosouImages.key = key;
      } else if (remember) {
        _error = 'パスワードがちがいます';
      }
    });
  }

  Widget _locked() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('学校のパスワードで開きます', style: serif(16)),
          const SizedBox(height: 6),
          Text(
            '一度開けば、この端末では次から入れなくても開けます。',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('yosou-password'),
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'パスワード'),
            onSubmitted: (v) => _try(v, remember: true),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12, color: TsuzuriColors.wrong),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('yosou-unlock'),
              onPressed: _checking
                  ? null
                  : () => _try(_password.text, remember: true),
              child: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('開く'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _examCard(YosouExam e, List<int> key) {
    final a = _store.attempt(e.id);
    final h = _store.history(e.id);
    final status = a != null && !a.submitted
        ? '解いている途中（のこり ${_clock(a.remaining(DateTime.now(), e.minutes))}）'
        : h.isNotEmpty
        ? '前回 ${h.first.score}/${h.first.total} 点'
              '${h.first.unscored > 0 ? '（未採点 ${h.first.unscored}）' : ''}'
              '${h.length > 1 ? '　最高 ${h.map((r) => r.score).reduce((x, y) => x > y ? x : y)} 点' : ''}'
        : 'まだ解いていません';
    return Card(
      child: ListTile(
        key: ValueKey('yosou-exam-${e.id}'),
        leading: Icon(
          a != null && !a.submitted
              ? Icons.timer_outlined
              : Icons.assignment_outlined,
        ),
        title: Text(e.title),
        subtitle: Text(
          '${ShonanSubjects.byId(e.subjectId)?.displayName ?? ''}・${e.minutes}分\n$status',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => YosouExamScreen(exam: e, keyBytes: key),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = _key;
    return Scaffold(
      appBar: AppBar(title: Text('予想問題（60分）', style: serif(17))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              '本番と同じく全体で60分。1問ごとの時間制限はありません。'
              '問題冊子（原本のページ）を見ながら、解答用紙に答えを書きます。'
              '途中で閉じても、答えと残り時間は保存されます。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 12),
            if (key == null)
              _checking && _gate.secret != null
                  ? const Center(child: CircularProgressIndicator())
                  : _locked()
            else
              for (final e in YosouExams.all) _examCard(e, key),
          ],
        ),
      ),
    );
  }
}

String _clock(Duration d) {
  final m = d.inMinutes, s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// 1つの予想問題：はじめる前 → 解く（60分）→ 採点・結果
class YosouExamScreen extends StatefulWidget {
  const YosouExamScreen({
    super.key,
    required this.exam,
    required this.keyBytes,
    this.now = DateTime.now,
  });

  final YosouExam exam;
  final List<int> keyBytes;

  /// 時計（テストで差しかえる）
  final DateTime Function() now;

  @override
  State<YosouExamScreen> createState() => _YosouExamScreenState();
}

class _YosouExamScreenState extends State<YosouExamScreen> {
  late final YosouExamFiles _files = YosouExamFiles(
    widget.exam,
    widget.keyBytes,
  );
  late final Future<MockSheet?> _sheet = _load();
  MockAttempt? _attempt;

  /// 小問ごとの問題（あれば1問ずつ出す。なければ問題冊子と解答用紙で解く）
  List<QuizQuestion>? _qs;

  /// いま出している小問
  int _index = 0;

  /// 計算メモ（問題ごと）
  bool _scratch = false;
  final _strokes = <String, List<List<Offset>>>{};

  /// 小問の音声を流した回数
  final _heard = <String, int>{};
  Timer? _timer;
  final _inputs = <String, TextEditingController>{};

  /// リスニングを流した回数（この画面にいるあいだ）
  final _played = <int, int>{};

  /// 解答用紙で、未記入と見直しだけを出す
  bool _onlyTodo = false;

  YosouExamStore get _store =>
      YosouExamStore.of(RpgServices.of(context).personalBooks);
  YosouExam get _e => widget.exam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attempt != null) return;
    _attempt = _store.attempt(_e.id);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    speaker.stop();
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<MockSheet?> _load() async {
    if (_e.smallQuestions) {
      final qs = await _files.questions();
      if (qs != null && qs.isNotEmpty) {
        YosouImages.key = widget.keyBytes;
        _qs = qs;
        final a = _attempt;
        if (a != null && !a.submitted) {
          // 続きから：まだ答えていない最初の問題へ
          final i = qs.indexWhere((q) => (a.answers[q.id] ?? '').isEmpty);
          _index = i < 0 ? 0 : i;
        }
        return YosouSheet.of(qs);
      }
    }
    return _files.sheet();
  }

  void _startTimer() {
    _timer?.cancel();
    final a = _attempt;
    if (a == null || a.submitted) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final a = _attempt;
    if (a == null || a.submitted || !mounted) return;
    if (!a.paused && a.remaining(widget.now(), _e.minutes) == Duration.zero) {
      _submit(timeUp: true);
      return;
    }
    setState(() {});
  }

  Future<void> _save() async {
    final a = _attempt;
    if (a != null) await _store.save(a);
  }

  Future<void> _start() async {
    for (final c in _inputs.values) {
      c.dispose();
    }
    _inputs.clear();
    _played.clear();
    _heard.clear();
    _strokes.clear();
    _index = 0;
    _scratch = false;
    final a = MockAttempt(examId: _e.id, startedAt: widget.now());
    setState(() => _attempt = a);
    await _save();
    _startTimer();
  }

  Future<void> _submit({bool timeUp = false}) async {
    final a = _attempt;
    final sheet = await _sheet;
    if (a == null || sheet == null || a.submitted) return;
    _timer?.cancel();
    speaker.stop();
    a.submit(widget.now(), _e.minutes);
    await _save();
    await _record(sheet);
    if (!mounted) return;
    setState(() {});
    if (timeUp) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('時間です。答えを提出しました')));
    }
  }

  Future<void> _record(MockSheet sheet) async {
    final a = _attempt!;
    await _store.record(
      _e.id,
      YosouResult(
        startedAt: a.startedAt,
        score: a.score(sheet),
        total: sheet.total,
        spent: a.spent(widget.now()),
        unscored: a.unscored(sheet).length,
      ),
    );
  }

  Future<void> _confirmSubmit(MockSheet sheet) async {
    final a = _attempt!;
    final qs = _qs;
    final unit = qs == null ? '欄' : '問';
    final blank = qs == null
        ? sheet.items.where((i) => !a.answered(i)).length
        : qs.where((q) => (a.answers[q.id] ?? '').trim().isEmpty).length;
    final flagged = a.flags.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('提出しますか？'),
        content: Text(
          [
            if (blank > 0) '未記入が $blank $unitあります。',
            if (flagged > 0) '見直しの印が $flagged $unitあります。',
            '提出すると答えは直せません。',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('もどる'),
          ),
          FilledButton(
            key: const ValueKey('yosou-submit-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('提出する'),
          ),
        ],
      ),
    );
    if (ok == true) await _submit();
  }

  void _togglePause() {
    final a = _attempt!;
    if (a.paused) {
      a.resume(widget.now());
    } else {
      speaker.stop();
      a.pause(widget.now());
    }
    _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MockSheet?>(
      future: _sheet,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(_e.title, style: serif(15))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final sheet = snap.data;
        if (sheet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(_e.title, style: serif(15))),
            body: const Center(child: Text('問題を開けませんでした')),
          );
        }
        final a = _attempt;
        if (a == null) return _intro(sheet);
        if (a.submitted) return _result(sheet, a);
        return _solving(sheet, a);
      },
    );
  }

  // ───────── はじめる前 ─────────

  Widget _intro(MockSheet sheet) {
    final h = _store.history(_e.id);
    return Scaffold(
      appBar: AppBar(title: Text(_e.title, style: serif(15), maxLines: 2)),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(_e.title, style: serif(18)),
            const SizedBox(height: 8),
            Text(
              '時間 ${_e.minutes}分（1問ごとの制限なし）・${sheet.total}点満点・'
              '${_qs == null ? '${sheet.items.length}欄・問題冊子 ${_e.questionPages}ページ' : '小問 ${_qs!.length}問'}',
            ),
            if (sheet.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                sheet.note,
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _qs == null
                  ? '・「問題冊子」と「解答用紙」を切りかえて解きます。\n'
                        '・迷った欄には見直しの印をつけられます。\n'
                        '・時間になると自動で提出します。一時停止もできます（本番のつもりなら止めずに）。\n'
                        '・記述や計算の過程は、提出後に模範解答を見て自分で点をつけます。'
                  : '・小問が1問ずつ出ます。「前へ」「次へ」や問題の一覧で、自由に行き来できます。\n'
                        '・答えはその場では採点しません。全部解いたら「提出」で、最後にまとめて採点します。\n'
                        '・本文・同じ大問の問題・計算メモ・原本の問題冊子は、いつでも開けます。\n'
                        '・迷った問題には見直しの印をつけられます。時間になると自動で提出します。\n'
                        '・記述は、提出後に模範解答と採点基準を見て自分で点をつけます。',
              style: TextStyle(fontSize: 13, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('yosou-start'),
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: Text('はじめる（${_e.minutes}分）'),
            ),
            if (h.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('これまでの結果', style: serif(15)),
              for (final r in h)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text(
                    '${r.score}/${r.total} 点'
                    '${r.unscored > 0 ? '（未採点 ${r.unscored}）' : ''}',
                  ),
                  subtitle: Text(
                    '${r.startedAt.month}/${r.startedAt.day} ${r.startedAt.hour}:${r.startedAt.minute.toString().padLeft(2, '0')}'
                    '・${r.spent.inMinutes}分${r.spent.inSeconds % 60}秒',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────── 解く ─────────

  Widget _solving(MockSheet sheet, MockAttempt a) {
    if (_qs case final qs?) return _smallSolving(sheet, a, qs);
    final left = a.remaining(widget.now(), _e.minutes);
    final done = sheet.items.where(a.answered).length;
    final low = left < const Duration(minutes: 5);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final booklet = YosouPages(
      files: _files,
      from: 1,
      to: _e.questionPages,
      keyPrefix: 'yosou-q',
    );
    final answers = a.paused ? _pausedCover() : _answerSheet(sheet, a);
    final timer = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: Text(
          a.paused ? '一時停止中' : 'のこり ${_clock(left)}',
          key: const ValueKey('yosou-clock'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: low ? TsuzuriColors.wrong : TsuzuriColors.ink,
          ),
        ),
      ),
    );
    final actions = [
      timer,
      IconButton(
        key: const ValueKey('yosou-pause'),
        tooltip: a.paused ? '再開' : '一時停止',
        onPressed: _togglePause,
        icon: Icon(a.paused ? Icons.play_arrow : Icons.pause),
      ),
      TextButton(
        key: const ValueKey('yosou-submit'),
        onPressed: () => _confirmSubmit(sheet),
        child: const Text('提出'),
      ),
    ];
    if (wide) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_e.title, style: serif(15)),
          actions: actions,
        ),
        body: Row(
          children: [
            Expanded(flex: 3, child: a.paused ? _pausedCover() : booklet),
            const VerticalDivider(width: 1),
            Expanded(flex: 2, child: answers),
          ],
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_e.title, style: serif(14), maxLines: 2),
          actions: actions,
          bottom: TabBar(
            tabs: [
              const Tab(key: ValueKey('yosou-tab-booklet'), text: '問題冊子'),
              Tab(
                key: const ValueKey('yosou-tab-sheet'),
                text: '解答用紙（$done/${sheet.items.length}）',
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [a.paused ? _pausedCover() : booklet, answers],
        ),
      ),
    );
  }

  // ───────── 小問を1問ずつ解く ─────────

  void _go(int i) {
    final qs = _qs!;
    if (i < 0 || i >= qs.length) return;
    speaker.stop();
    setState(() {
      _index = i;
      _scratch = false;
    });
  }

  List<QuizQuestion> _siblings(QuizQuestion q) {
    final g = YosouGroup.groupId(q);
    return [
      for (final x in _qs!)
        if (YosouGroup.groupId(x) == g) x,
    ];
  }

  void _openBooklet() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('問題冊子（原本）', style: serif(16))),
        body: YosouPages(
          files: _files,
          from: 1,
          to: _e.questionPages,
          keyPrefix: 'yosou-q',
        ),
      ),
    ),
  );

  /// 問題の一覧（答えた・見直しの印）。タップでその問題へ
  void _openList(MockAttempt a) {
    final qs = _qs!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(c).height * 0.75,
          ),
          child: ListView(
            key: const ValueKey('yosou-list'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                '答えた ${qs.where((q) => (a.answers[q.id] ?? '').trim().isNotEmpty).length}/${qs.length}'
                '・見直し ${a.flags.length}',
                style: serif(15),
              ),
              for (final g in YosouGroup.of(qs)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(g.title, style: const TextStyle(fontSize: 13)),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final q in g.questions) _listChip(c, a, qs.indexOf(q)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _listChip(BuildContext c, MockAttempt a, int i) {
    final q = _qs![i];
    final done = (a.answers[q.id] ?? '').trim().isNotEmpty;
    final flagged = a.flags.contains(q.id);
    return InkWell(
      key: ValueKey('yosou-go-${i + 1}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(c).pop();
        _go(i);
      },
      child: Container(
        width: 46,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? TsuzuriColors.accent.withValues(alpha: 0.22) : null,
          border: Border.all(
            color: i == _index ? TsuzuriColors.accent : TsuzuriColors.inkSoft,
            width: i == _index ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${i + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (flagged)
              const Icon(Icons.flag, size: 12, color: TsuzuriColors.stamp),
          ],
        ),
      ),
    );
  }

  Widget _smallSolving(MockSheet sheet, MockAttempt a, List<QuizQuestion> qs) {
    final left = a.remaining(widget.now(), _e.minutes);
    final low = left < const Duration(minutes: 5);
    final q = qs[_index];
    final flagged = a.flags.contains(q.id);
    final done = qs.where((x) => (a.answers[x.id] ?? '').trim().isNotEmpty);
    final last = _index + 1 >= qs.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '第${_index + 1}問 / ${qs.length}',
          key: const ValueKey('yosou-number'),
          style: serif(15),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                a.paused ? '一時停止中' : 'のこり ${_clock(left)}',
                key: const ValueKey('yosou-clock'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: low ? TsuzuriColors.wrong : TsuzuriColors.ink,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('yosou-pause'),
            tooltip: a.paused ? '再開' : '一時停止',
            onPressed: _togglePause,
            icon: Icon(a.paused ? Icons.play_arrow : Icons.pause),
          ),
          TextButton(
            key: const ValueKey('yosou-submit'),
            onPressed: () => _confirmSubmit(sheet),
            child: const Text('提出'),
          ),
        ],
      ),
      body: a.paused
          ? _pausedCover()
          : NotebookPaper(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              TextButton.icon(
                                key: const ValueKey('yosou-list-open'),
                                onPressed: () => _openList(a),
                                icon: const Icon(Icons.grid_view, size: 18),
                                label: Text('一覧（${done.length}/${qs.length}）'),
                              ),
                              const Spacer(),
                              IconButton(
                                key: const ValueKey('yosou-booklet'),
                                tooltip: '原本の問題冊子',
                                onPressed: _openBooklet,
                                icon: const Icon(Icons.description_outlined),
                              ),
                              IconButton(
                                key: const ValueKey('yosou-memo'),
                                tooltip: '計算メモ',
                                onPressed: () =>
                                    setState(() => _scratch = true),
                                icon: const Icon(Icons.edit_note),
                              ),
                              IconButton(
                                key: ValueKey('yosou-flag-${q.id}'),
                                tooltip: '見直しの印',
                                onPressed: () {
                                  flagged
                                      ? a.flags.remove(q.id)
                                      : a.flags.add(q.id);
                                  _save();
                                  setState(() {});
                                },
                                icon: Icon(
                                  flagged ? Icons.flag : Icons.outlined_flag,
                                  color: flagged
                                      ? TsuzuriColors.stamp
                                      : TsuzuriColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: YosouQuestionView(
                            key: ValueKey('yosou-view-${q.id}'),
                            question: q,
                            number: _index + 1,
                            total: qs.length,
                            siblings: _siblings(q),
                            answers: a.answers,
                            onAnswer: (v) => _set(q.id, v),
                            onJump: (s) => _go(qs.indexOf(s)),
                            heard: _heard[q.id] ?? 0,
                            onListen: () => setState(
                              () => _heard[q.id] = (_heard[q.id] ?? 0) + 1,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                          child: Row(
                            children: [
                              OutlinedButton.icon(
                                key: const ValueKey('yosou-prev'),
                                onPressed: _index == 0
                                    ? null
                                    : () => _go(_index - 1),
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('前へ'),
                              ),
                              const Spacer(),
                              if (last)
                                FilledButton.icon(
                                  key: const ValueKey('yosou-next'),
                                  onPressed: () => _confirmSubmit(sheet),
                                  icon: const Icon(Icons.done_all),
                                  label: const Text('提出する'),
                                )
                              else
                                FilledButton.icon(
                                  key: const ValueKey('yosou-next'),
                                  onPressed: () => _go(_index + 1),
                                  icon: const Icon(Icons.chevron_right),
                                  label: const Text('次へ'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_scratch)
                    Positioned.fill(
                      child: ScratchpadOverlay(
                        strokes: _strokes.putIfAbsent(q.id, () => []),
                        onClose: () => setState(() => _scratch = false),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _pausedCover() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pause_circle_outline, size: 48),
        const SizedBox(height: 8),
        const Text('一時停止中（問題はかくしています）'),
        const SizedBox(height: 12),
        FilledButton(onPressed: _togglePause, child: const Text('再開する')),
      ],
    ),
  );

  TextEditingController _input(String id, String? text) =>
      _inputs[id] ??= TextEditingController(text: text ?? '');

  void _set(String id, String value) {
    _attempt!.answers[id] = value;
    _save();
    setState(() {});
  }

  Widget _answerSheet(MockSheet sheet, MockAttempt a) {
    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              '未記入 ${sheet.items.where((i) => !a.answered(i)).length}・見直し ${a.flags.length}',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
          ),
          FilterChip(
            key: const ValueKey('yosou-only-todo'),
            label: const Text('未記入・見直しだけ'),
            selected: _onlyTodo,
            onSelected: (v) => setState(() => _onlyTodo = v),
          ),
        ],
      ),
    ];
    for (var s = 0; s < sheet.sections.length; s++) {
      final sec = sheet.sections[s];
      final items = [
        for (final i in sec.items)
          if (!_onlyTodo || !a.answered(i) || a.flags.contains(i.id)) i,
      ];
      if (items.isEmpty && sec.speech.isEmpty) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 2, 4),
          child: Text(sec.title, style: serif(15)),
        ),
      );
      if (sec.speech.isNotEmpty) children.add(_listening(s, sec));
      for (final i in items) {
        children.add(_itemInput(i, a));
      }
    }
    return NotebookPaper(
      child: ListView(
        key: const ValueKey('yosou-sheet'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: children,
      ),
    );
  }

  Widget _listening(int s, MockSection sec) {
    final used = _played[s] ?? 0;
    final left = sec.plays - used;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.headphones),
        title: Text(left > 0 ? '音声を流す（あと$left回）' : '音声はもう流せません'),
        subtitle: const Text('英語の読み上げで流します。流れるのは1度に1回分です'),
        trailing: left > 0
            ? IconButton(
                key: ValueKey('yosou-play-$s'),
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  setState(() => _played[s] = used + 1);
                  speaker.speak(
                    sec.speech.join('\n'),
                    lang: 'en-US',
                    rate: 0.5,
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _itemInput(MockItem i, MockAttempt a) {
    final flagged = a.flags.contains(i.id);
    final value = a.answers[i.id];
    Widget field;
    switch (i.type) {
      case MockItemType.choice:
        final picked = i.all ? MockItem.splitChoices(value).toSet() : {value};
        field = Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final o in i.options)
              ChoiceChip(
                key: ValueKey('yosou-${i.id}-$o'),
                label: Text(o),
                selected: picked.contains(o),
                onSelected: (_) {
                  if (i.all) {
                    final next = {...picked.whereType<String>()};
                    next.contains(o) ? next.remove(o) : next.add(o);
                    _set(i.id, MockItem.joinChoices(next));
                  } else {
                    _set(i.id, value == o ? '' : o);
                  }
                },
              ),
          ],
        );
      case MockItemType.text:
      case MockItemType.self:
        final self = i.type == MockItemType.self;
        field = TextField(
          key: ValueKey('yosou-input-${i.id}'),
          controller: _input(i.id, value),
          minLines: 1,
          maxLines: self ? 6 : 2,
          decoration: InputDecoration(
            isDense: true,
            hintText: self ? '答え（記述・計算はノートに書いてもよい。提出後に自分で採点）' : '答えを書く',
          ),
          onChanged: (v) => _set(i.id, v),
        );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                i.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(child: field),
          IconButton(
            key: ValueKey('yosou-flag-${i.id}'),
            tooltip: '見直しの印',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              flagged ? a.flags.remove(i.id) : a.flags.add(i.id);
              _save();
              setState(() {});
            },
            icon: Icon(
              flagged ? Icons.flag : Icons.outlined_flag,
              color: flagged ? TsuzuriColors.stamp : TsuzuriColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  // ───────── 採点・結果 ─────────

  Future<void> _changed(MockSheet sheet) async {
    await _save();
    await _record(sheet);
    if (mounted) setState(() {});
  }

  Widget _result(MockSheet sheet, MockAttempt a) {
    final score = a.score(sheet);
    final unscored = a.unscored(sheet);
    final spent = a.spent(widget.now());
    final children = <Widget>[
      Center(
        child: Text(
          '$score / ${sheet.total} 点',
          key: const ValueKey('yosou-score'),
          style: serif(28),
        ),
      ),
      Center(
        child: Text(
          'かかった時間 ${spent.inMinutes}分${spent.inSeconds % 60}秒'
          '${unscored.isNotEmpty ? '\n自分で採点する欄があと ${unscored.length} 個あります（下で点をつけてください）' : ''}',
          textAlign: TextAlign.center,
          style: TextStyle(color: TsuzuriColors.inkSoft),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('yosou-answer-pages'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('解答・解説', style: serif(16))),
                  body: YosouPages(
                    files: _files,
                    from: _e.questionPages + 1,
                    to: _e.pages,
                    keyPrefix: 'yosou-a',
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('解答・解説のページ'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('問題冊子', style: serif(16))),
                  body: YosouPages(
                    files: _files,
                    from: 1,
                    to: _e.questionPages,
                    keyPrefix: 'yosou-q',
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('問題冊子'),
          ),
          FilledButton.tonalIcon(
            key: const ValueKey('yosou-retry'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('もう一度、60分で解きますか？'),
                  content: const Text('今回の結果は「これまでの結果」に残ります。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('やめる'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('はじめる'),
                    ),
                  ],
                ),
              );
              if (ok == true) await _start();
            },
            icon: const Icon(Icons.replay),
            label: const Text('もう一度解く'),
          ),
        ],
      ),
    ];
    for (final sec in sheet.sections) {
      final got = sec.items.fold(0, (s, i) => s + (a.scoreOf(i) ?? 0));
      final max = sec.items.fold(0, (s, i) => s + i.points);
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 4),
          child: Text('${sec.title}　$got/$max', style: serif(15)),
        ),
      );
      for (final i in sec.items) {
        children.add(_itemResult(sheet, i, a));
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('結果：${_e.title}', style: serif(15), maxLines: 2),
      ),
      body: NotebookPaper(
        child: ListView(
          key: const ValueKey('yosou-result'),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 40),
          children: children,
        ),
      ),
    );
  }

  Widget _itemResult(MockSheet sheet, MockItem i, MockAttempt a) {
    final ok = a.correct(i);
    final got = a.scoreOf(i);
    String yours(MockItem x) {
      final v = (a.answers[x.id] ?? '').trim();
      return x.all ? v.replaceAll(',', '・') : v;
    }

    final mine = i.parts.isEmpty
        ? yours(i)
        : i.parts.any((p) => yours(p).isNotEmpty)
        ? [for (final p in i.parts) yours(p).isEmpty ? '（未記入）' : yours(p)]
              .join(' ／ ')
        : '';
    final mark = ok == null
        ? '？'
        : ok
        ? '○'
        : got != null && got > 0
        ? '△'
        : '×';
    final color = ok == true
        ? TsuzuriColors.stamp
        : ok == null
        ? TsuzuriColors.inkSoft
        : TsuzuriColors.wrong;
    final correctText = i.type == MockItemType.choice && i.all
        ? i.answers.join('・')
        : i.answers.join(' ／ ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  mark,
                  key: ValueKey('yosou-mark-${i.id}'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  i.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${got ?? '−'}/${i.points}点'),
              ],
            ),
            if (i.prompt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  i.prompt,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            const SizedBox(height: 4),
            Text('あなたの答え：${mine.isEmpty ? '（未記入）' : mine}'),
            Text(
              i.type == MockItemType.self
                  ? '模範解答：$correctText'
                  : '正解：$correctText',
              style: TextStyle(color: TsuzuriColors.stamp),
            ),
            if (i.explain.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  i.explain,
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
              ),
            const SizedBox(height: 6),
            if (i.type == MockItemType.self)
              Wrap(
                spacing: 6,
                children: [
                  for (var p = 0; p <= i.points; p++)
                    ChoiceChip(
                      key: ValueKey('yosou-self-${i.id}-$p'),
                      label: Text('$p点'),
                      selected: a.selfScores[i.id] == p,
                      onSelected: (_) {
                        a.selfScores[i.id] = p;
                        _changed(sheet);
                      },
                    ),
                ],
              )
            else if (mine.isNotEmpty || a.overrides.containsKey(i.id))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: ValueKey('yosou-override-${i.id}'),
                  onPressed: () {
                    if (a.overrides.containsKey(i.id)) {
                      a.overrides.remove(i.id);
                    } else {
                      a.overrides[i.id] = !(a.autoCheck(i) ?? false);
                    }
                    _changed(sheet);
                  },
                  child: Text(
                    a.overrides.containsKey(i.id)
                        ? '自動の採点にもどす'
                        : ok == true
                        ? '×に直す'
                        : '○に直す（書き方のちがいなど）',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 問題冊子・解答のページ画像を、たてに並べて見る（タップで拡大）
class YosouPages extends StatelessWidget {
  const YosouPages({
    super.key,
    required this.files,
    required this.from,
    required this.to,
    required this.keyPrefix,
  });

  final YosouExamFiles files;
  final int from;
  final int to;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8E4DA),
      child: ListView.builder(
        key: ValueKey('$keyPrefix-pages'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: to - from + 1,
        itemBuilder: (context, n) {
          final page = from + n;
          return Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: _Page(
              key: ValueKey('$keyPrefix-$page'),
              files: files,
              page: page,
              label: '${n + 1} / ${to - from + 1}',
            ),
          );
        },
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    super.key,
    required this.files,
    required this.page,
    required this.label,
  });

  final YosouExamFiles files;
  final int page;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: files.page(page),
      builder: (context, snap) {
        final bytes = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 0.7,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (bytes == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: Text('このページを開けませんでした')),
          );
        }
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(title: Text(label)),
                body: InteractiveViewer(
                  maxScale: 5,
                  child: Center(child: Image.memory(bytes)),
                ),
              ),
            ),
          ),
          child: Stack(
            children: [
              Material(
                elevation: 1,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: Colors.black54,
                  child: Text(
                    '$label　タップで拡大',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
