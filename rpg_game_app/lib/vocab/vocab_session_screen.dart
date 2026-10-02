import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import 'speech.dart';
import 'vocab_store.dart';

/// 単語帳の練習（1回ぶん）。
///
/// 課題を1つずつ出し、答えたら FSRS で次の出題日を決めて保存する。
/// 「忘れた」単語は、この回の最後にもう一度出す。
class VocabSessionScreen extends StatefulWidget {
  const VocabSessionScreen({
    super.key,
    required this.store,
    required this.book,
    required this.tasks,
    required this.title,
    this.random,
  });

  final VocabStore store;
  final VocabBook book;
  final List<VocabTask> tasks;
  final String title;
  final Random? random;

  @override
  State<VocabSessionScreen> createState() => _VocabSessionScreenState();
}

class _VocabSessionScreenState extends State<VocabSessionScreen> {
  late final List<VocabTask> _queue = [...widget.tasks];
  late final Random _random = widget.random ?? Random();
  final _input = TextEditingController();
  final _requeued = <String>{};

  int _index = 0;
  int _answered = 0;
  int _correct = 0;
  int _combo = 0;
  int _xp = 0;
  final _missed = <String>{};
  final _started = DateTime.now();

  late DateTime _shownAt;
  List<String> _choices = const [];

  /// 答えたあと（null ならまだ答えていない）
  bool? _wasCorrect;
  String? _picked;
  bool _flipped = false;
  MistakeReason? _reason;
  Rating? _autoRating;
  String? _damage;

  BookProgress get _progress => widget.store.progress(widget.book.id);
  VocabTask get _task => _queue[_index];
  VocabCard get _card => widget.book.card(_task.cardId)!;
  bool get _done => _index >= _queue.length;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _input.dispose();
    speaker.stop();
    super.dispose();
  }

  /// 音が出せない環境のために、この回のリスニングをすべて飛ばす
  bool _skipListening = false;

  /// とばしたリスニングの数
  int _skipped = 0;

  /// リスニングを記録せずにとばす（[all] ならこの回のリスニングをすべて）
  void _skip({bool all = false}) {
    speaker.stop();
    setState(() {
      if (all) _skipListening = true;
      _skipped++;
      _index++;
      _prepare();
    });
  }

  void _prepare() {
    while (_skipListening && !_done && _task.mode == VocabMode.listening) {
      _skipped++;
      _index++;
    }
    if (_done) return;
    _shownAt = DateTime.now();
    _wasCorrect = null;
    _picked = null;
    _flipped = false;
    _reason = null;
    _autoRating = null;
    _damage = null;
    _input.clear();
    final m = _task.mode;
    if (m == VocabMode.choiceMeaning ||
        m == VocabMode.choiceTerm ||
        m == VocabMode.listening ||
        m == VocabMode.compare) {
      _choices = VocabChoices.build(
        widget.book,
        _card,
        m,
        random: _random,
        progress: _progress.cards[_card.id],
      );
    }
    if (m == VocabMode.listening) _say(_card.term);
  }

  void _say(String text) {
    final (lang, rate) = widget.store.voice;
    speaker.speak(text, lang: lang, rate: rate);
  }

  String _answerOf(VocabMode m) => switch (m) {
    VocabMode.choiceMeaning => _card.shortMeaning,
    _ => _card.term,
  };

  /// 選択肢・入力で答えた
  void _answer(String value) {
    if (_wasCorrect != null) return;
    final m = _task.mode;
    final ok = switch (m) {
      VocabMode.spelling => _card.spellingMatches(value),
      VocabMode.cloze => _card.clozeMatches(value),
      _ => value == _answerOf(m),
    };
    final secs = DateTime.now().difference(_shownAt).inMilliseconds / 1000;
    final streak = _progress.cards[_card.id]?.skills[m.skill]?.streak ?? 0;
    setState(() {
      _picked = value;
      _wasCorrect = ok;
      _reason = ok ? null : m.defaultReason;
      _autoRating = !ok
          ? Rating.again
          : secs > 12
          ? Rating.hard
          : secs < 3.5 && streak >= 2
          ? Rating.easy
          : Rating.good;
      _hit(ok);
    });
  }

  void _hit(bool ok) {
    if (ok) {
      _combo++;
      final dmg = 20 + min(_combo, 10) * 3;
      _damage = '⚔️ $dmg DAMAGE';
      _xp += dmg ~/ 5;
    } else {
      _combo = 0;
      _damage = '💥 15 DAMAGE';
    }
  }

  /// 記録して次へ
  Future<void> _next(Rating rating) async {
    final m = _task.mode;
    final correct = rating != Rating.again;
    String? confused;
    if (!correct && _picked != null && m != VocabMode.choiceMeaning) {
      final other = widget.book.cards.where((c) => c.term == _picked);
      if (other.isNotEmpty && other.first.id != _card.id) {
        confused = other.first.term;
        // 混同は両方の単語に記録する
        _progress.cards
            .putIfAbsent(other.first.id, CardProgress.new)
            .confusedWith
            .add(_card.term);
      }
    }
    _progress.record(
      cardId: _card.id,
      skill: m.skill,
      rating: rating,
      now: DateTime.now(),
      reason: correct ? null : (_reason ?? m.defaultReason),
      confusedWith: _reason == MistakeReason.confused ? confused : null,
      spent: DateTime.now().difference(_shownAt),
      isNew: _task.isNew,
    );
    await widget.store.saveProgress(widget.book.id);
    _answered++;
    if (correct) {
      _correct++;
    } else {
      _missed.add(_card.id);
      // この回の最後にもう一度（1回だけ）
      if (_requeued.add('${_card.id}:${m.name}')) {
        _queue.add(VocabTask(_card.id, _retryMode(m)));
      }
    }
    if (!mounted) return;
    setState(() {
      _index++;
      _prepare();
    });
  }

  /// もう一度出すときは、見分ける問題にして思い出しやすく
  VocabMode _retryMode(VocabMode m) =>
      m == VocabMode.flashcard ? VocabMode.choiceMeaning : m;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TsuzuriColors.paper,
        title: Text(widget.title, style: serif(17)),
      ),
      body: NotebookPaper(
        child: SafeArea(top: false, child: _done ? _summary() : _question()),
      ),
    );
  }

  Widget _header() {
    final remain = _queue.length - _index;
    final hp = _queue.isEmpty ? 0.0 : remain / _queue.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 10, 16, 0),
      child: Row(
        children: [
          Text(
            '${_index + 1} / ${_queue.length}',
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: hp,
                minHeight: 8,
                color: hp > 0.3 ? TsuzuriColors.hp : TsuzuriColors.hpLow,
                backgroundColor: TsuzuriColors.tint(0xFFE8E0D2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('👾', semanticsLabel: '単語モンスター'),
          const SizedBox(width: 8),
          if (_combo >= 2)
            Text(
              '$_combo連続',
              style: const TextStyle(
                color: TsuzuriColors.exp,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _question() {
    final m = _task.mode;
    final c = _card;
    return Column(
      children: [
        _header(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(40, 12, 16, 24),
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(_task.isNew ? '新しい単語' : m.label),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  if (_damage != null)
                    Text(
                      _damage!,
                      style: TextStyle(
                        color: _wasCorrect == true
                            ? TsuzuriColors.stamp
                            : TsuzuriColors.inkSoft,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ..._prompt(m, c),
              const SizedBox(height: 16),
              ..._answerArea(m, c),
              if (_wasCorrect != null || _flipped) ...[
                const SizedBox(height: 16),
                _explain(c),
              ],
              if (_wasCorrect == false) ...[
                const SizedBox(height: 12),
                _reasonPicker(),
              ],
              const SizedBox(height: 16),
              ..._nextButtons(m),
            ],
          ),
        ),
      ],
    );
  }

  Widget _speakButton(String text, {String tooltip = '発音を聞く'}) => IconButton(
    tooltip: tooltip,
    onPressed: () => _say(text),
    icon: const Icon(Icons.volume_up),
  );

  List<Widget> _prompt(VocabMode m, VocabCard c) {
    Widget big(String s) =>
        Text(s, textAlign: TextAlign.center, style: serif(30));
    switch (m) {
      case VocabMode.flashcard:
      case VocabMode.choiceMeaning:
        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: big(c.term)),
              _speakButton(c.term),
            ],
          ),
          if (c.pron.isNotEmpty)
            Text(
              c.pron,
              textAlign: TextAlign.center,
              style: TextStyle(color: TsuzuriColors.inkSoft),
            ),
          const SizedBox(height: 6),
          Text(
            m == VocabMode.flashcard ? '意味を思い出してから、めくってください' : '意味はどれ？',
            textAlign: TextAlign.center,
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
        ];
      case VocabMode.choiceTerm:
      case VocabMode.spelling:
      case VocabMode.compare:
        return [
          Text(c.shortMeaning, textAlign: TextAlign.center, style: serif(20)),
          const SizedBox(height: 6),
          Text(
            switch (m) {
              VocabMode.spelling => '英単語をつづってください　ヒント: ${c.spellingHint}',
              VocabMode.compare => '似た単語の中から、この意味のものを選んでください',
              _ => '英単語はどれ？',
            },
            textAlign: TextAlign.center,
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
        ];
      case VocabMode.listening:
        return [
          Center(
            child: FilledButton.tonalIcon(
              onPressed: () => _say(c.term),
              icon: const Icon(Icons.volume_up, size: 32),
              label: const Text('もう一度聞く'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '聞こえた単語はどれ？',
            textAlign: TextAlign.center,
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
          // 音が出せない場所（図書館・授業中など）では、記録せずにとばせる
          if (_wasCorrect == null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const ValueKey('vocab-skip-listening'),
                  onPressed: _skip,
                  icon: const Icon(Icons.volume_off, size: 16),
                  label: const Text('音が出せない：とばす'),
                ),
                TextButton(
                  key: const ValueKey('vocab-skip-all-listening'),
                  onPressed: () => _skip(all: true),
                  child: const Text('この回のリスニングをすべてとばす'),
                ),
              ],
            ),
        ];
      case VocabMode.cloze:
        return [
          Row(
            children: [
              Expanded(
                child: Text(
                  VocabCard.clozeOf(c.example, c.term) ?? c.example,
                  style: serif(18, weight: FontWeight.w500),
                ),
              ),
              _speakButton(c.example, tooltip: '例文を聞く'),
            ],
          ),
          if (c.exampleJa.isNotEmpty)
            Text(c.exampleJa, style: TextStyle(color: TsuzuriColors.inkSoft)),
          const SizedBox(height: 6),
          Text(
            '空欄に入る単語をつづってください　ヒント: ${c.spellingHint}',
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
        ];
    }
  }

  List<Widget> _answerArea(VocabMode m, VocabCard c) {
    switch (m) {
      case VocabMode.flashcard:
        return [
          if (!_flipped)
            FilledButton(
              onPressed: () => setState(() => _flipped = true),
              child: const Text('めくる'),
            ),
        ];
      case VocabMode.spelling:
      case VocabMode.cloze:
        return [
          TextField(
            key: const ValueKey('vocab-input'),
            controller: _input,
            enabled: _wasCorrect == null,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '英語で入力',
            ),
            onSubmitted: _answer,
          ),
          const SizedBox(height: 8),
          if (_wasCorrect == null)
            Row(
              children: [
                TextButton(
                  onPressed: () => _answer(''),
                  child: const Text('わからない'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _answer(_input.text),
                  child: const Text('答える'),
                ),
              ],
            ),
        ];
      default:
        final answer = _answerOf(m);
        return [
          for (final ch in _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  backgroundColor: _wasCorrect == null
                      ? null
                      : ch == answer
                      ? TsuzuriColors.correct.withValues(alpha: 0.18)
                      : ch == _picked
                      ? TsuzuriColors.wrong.withValues(alpha: 0.18)
                      : null,
                ),
                onPressed: _wasCorrect == null ? () => _answer(ch) : null,
                child: Text(ch, style: TextStyle(color: TsuzuriColors.ink)),
              ),
            ),
        ];
    }
  }

  Widget _explain(VocabCard c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_wasCorrect != null)
              Text(
                _wasCorrect! ? '○ 正解' : '× 正解は「${c.term}」',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _wasCorrect!
                      ? TsuzuriColors.correct
                      : TsuzuriColors.wrong,
                ),
              ),
            Row(
              children: [
                Text(c.term, style: serif(18)),
                if (c.pron.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(c.pron, style: TextStyle(color: TsuzuriColors.inkSoft)),
                ],
                _speakButton(c.term),
              ],
            ),
            Text(c.meaning, style: const TextStyle(height: 1.5)),
            if (c.example.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.example,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  _speakButton(c.example, tooltip: '例文を聞く'),
                ],
              ),
              if (c.exampleJa.isNotEmpty)
                Text(
                  c.exampleJa,
                  style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
                ),
            ],
            if (c.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '💡 ${c.note}',
                style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reasonPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('なぜ間違えましたか？', style: serif(14)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in MistakeReason.values)
              if (r != MistakeReason.context || _card.hasExample)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}日';
    if (d.inHours >= 1) return '${d.inHours}時間';
    return '${max(1, d.inMinutes)}分';
  }

  List<Widget> _nextButtons(VocabMode m) {
    if (m == VocabMode.flashcard) {
      if (!_flipped) return const [];
      final preview = BookProgress.fsrs.preview(
        _progress.cards[_card.id]?.skills[m.skill],
        DateTime.now(),
      );
      return [
        Text('どれくらい思い出せましたか？', style: serif(14)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final r in Rating.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    key: ValueKey('rate-${r.name}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: r == Rating.again
                          ? TsuzuriColors.wrong
                          : TsuzuriColors.ink,
                    ),
                    onPressed: () {
                      _hit(r != Rating.again);
                      _next(r);
                    },
                    child: Column(
                      children: [
                        Text(r.label, style: const TextStyle(fontSize: 12)),
                        Text(
                          _fmt(preview[r]!),
                          style: TextStyle(
                            fontSize: 10,
                            color: TsuzuriColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ];
    }
    if (_wasCorrect == null) return const [];
    return [
      FilledButton(
        key: const ValueKey('vocab-next'),
        onPressed: () => _next(_autoRating ?? Rating.good),
        child: const Text('次へ'),
      ),
    ];
  }

  Widget _summary() {
    final secs = DateTime.now().difference(_started).inSeconds;
    final pct = _answered == 0 ? 0 : (_correct * 100 / _answered).round();
    final p = _progress;
    final counts = p.counts(widget.book, DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 24, 16, 24),
      children: [
        Center(child: Text('おつかれさま！', style: serif(24))),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '$_answered問　正答率 $pct%　${secs ~/ 60}分${secs % 60}秒　+$_xp XP'
            '${_skipped > 0 ? '\n（リスニング $_skipped 問をとばしました）' : ''}',
            style: TextStyle(color: TsuzuriColors.inkSoft),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '🔴 弱点 ${counts[CardStatus.weak]}語　🟠 あやふや ${counts[CardStatus.shaky]}語　🟢 安定 ${counts[CardStatus.stable]}語',
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text('🔥 ${p.streak(DateTime.now())}日連続')),
        const SizedBox(height: 20),
        if (_missed.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => VocabSessionScreen(
                  store: widget.store,
                  book: widget.book,
                  title: '間違えた単語',
                  tasks: [
                    for (final id in _missed)
                      VocabTask(id, VocabMode.choiceMeaning),
                  ],
                ),
              ),
            ),
            icon: const Icon(Icons.replay),
            label: Text('間違えた${_missed.length}語をもう一度'),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('もどる'),
        ),
      ],
    );
  }
}
