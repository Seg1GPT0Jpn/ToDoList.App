import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../app/usage_meter.dart';
import '../art/paper.dart';
import '../meta/streak_store.dart';
import 'quick_battle.dart';
import 'speech.dart';
import 'vocab_store.dart';
import 'weak_cards_screen.dart';

/// 単語帳の練習（1回ぶん）。
///
/// 課題を1つずつ出し、答えたら FSRS で次の出題日を決めて保存する。
/// まちがえた単語は、少し間をあけて同じ形式でもう一度出す（正解しても覚えた扱いにはしない）。
class VocabSessionScreen extends StatefulWidget {
  const VocabSessionScreen({
    super.key,
    required this.store,
    required this.book,
    required this.tasks,
    required this.title,
    this.random,
    this.onFinished,
  });

  final VocabStore store;
  final VocabBook book;
  final List<VocabTask> tasks;
  final String title;
  final Random? random;

  /// 終わったとき（途中でやめたときも）に、正解した数を知らせる（クラスの共闘ボスなど）
  final void Function(int correct)? onFinished;

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

  /// まちがえた単語の形式（もう一度のときに同じ形式で出す）
  final _missedMode = <String, VocabMode>{};

  /// この回の中では出し直さず、時間をおいてたしかめる単語
  final _later = <String>{};

  /// この回に答えた単語（答えた順）
  final _studied = <String>{};
  final _started = DateTime.now();

  late DateTime _shownAt;
  List<String> _choices = const [];

  /// 答えたあと（null ならまだ答えていない）
  bool? _wasCorrect;
  String? _picked;
  bool _flipped = false;

  /// フラッシュカードで「わからない」を選んでめくった
  bool _unknown = false;

  /// めくる前に書いた（思い出した）意味
  final _guess = TextEditingController();
  MistakeReason? _reason;
  Rating? _autoRating;
  String? _damage;

  BookProgress get _progress => widget.store.progress(widget.book.id);

  /// 日本語の用語の暗記カード
  bool get _terms => widget.book.isTerms;
  VocabTask get _task => _queue[_index];
  VocabCard get _card => widget.book.card(_task.cardId)!;
  bool get _done => _index >= _queue.length;

  /// 始める前に持っていた苦手克服カード（終わったときに、新しくもらえたカードを出す）
  late final Set<String> _overcomeBefore;

  @override
  void initState() {
    super.initState();
    UsageMeter.mark(context, 'vocab_study');
    _services = context.getInheritedWidgetOfExactType<RpgServices>();
    _overcomeBefore = {
      for (final w in WeakCards.collected(widget.book, _progress)) w.card.id,
    };
    _prepare();
  }

  bool _reported = false;

  /// 勉強時間を記録する先（閉じるときには context を使えないので、はじめに覚えておく）
  RpgServices? _services;

  /// 正解した数を一度だけ知らせ、勉強時間を記録する
  void _report() {
    if (_reported) return;
    _reported = true;
    widget.onFinished?.call(_correct);
    if (_answered == 0) return;
    unawaited(
      _services?.studyLog.add(
        widget.book.worldId,
        spent: DateTime.now().difference(_started),
        answered: _answered,
        correct: _correct,
      ),
    );
  }

  @override
  void dispose() {
    _report();
    _input.dispose();
    _guess.dispose();
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
    _unknown = false;
    _guess.clear();
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
    if (_terms) return;
    final (lang, rate) = widget.store.voice;
    speaker.speak(text, lang: lang, rate: rate);
  }

  /// 選んだ答えが、ほかの単語のものなら、その単語
  VocabCard? _otherCard(VocabMode m, String picked) {
    if (m == VocabMode.spelling || m == VocabMode.cloze) {
      return null;
    }
    for (final c in widget.book.cards) {
      if (c.id == _card.id) continue;
      if (m == VocabMode.choiceMeaning
          ? widget.book.meaningOf(c) == picked
          : c.term == picked) {
        return c;
      }
    }
    return null;
  }

  String _answerOf(VocabMode m) => switch (m) {
    VocabMode.choiceMeaning => widget.book.meaningOf(_card),
    _ => _card.term,
  };

  /// 選択肢・入力で答えた
  void _answer(String value) {
    if (_wasCorrect != null) return;
    final m = _task.mode;
    final ok = switch (m) {
      VocabMode.spelling =>
        _terms
            ? widget.book.writingMatches(_card, value)
            : _card.spellingMatches(value),
      VocabMode.cloze => _card.clozeMatches(value),
      _ => value == _answerOf(m),
    };
    final secs = DateTime.now().difference(_shownAt).inMilliseconds / 1000;
    final streak = _progress.cards[_card.id]?.skills[m.skill]?.streak ?? 0;
    setState(() {
      _picked = value;
      _wasCorrect = ok;
      // 選択肢で、ほかの単語を選んだときは「似た単語と混同した」
      _reason = ok
          ? null
          : _otherCard(m, value) != null
          ? MistakeReason.confused
          : m.defaultReason;
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

  /// 記録して次へ（[guessed] は、正解したが勘だったとき）
  Future<void> _next(Rating rating, {bool guessed = false}) async {
    final m = _task.mode;
    final correct = rating != Rating.again;
    // さっき答えを見たばかりの出し直しは、正解しても「覚えた」にしない
    if (_task.relearn && (rating == Rating.good || rating == Rating.easy)) {
      rating = Rating.hard;
    }
    String? confused;
    final other = correct || _picked == null ? null : _otherCard(m, _picked!);
    if (other != null) {
      confused = other.term;
      // 混同は両方の単語に記録する
      _progress.cards
          .putIfAbsent(other.id, CardProgress.new)
          .confusedWith
          .add(_card.term);
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
      guessed: guessed,
      // はじめての単語を「わからない」と言えたのは、まちがいではない
      countMistake: !(_unknown && _task.isNew),
    );
    await widget.store.saveProgress(widget.book.id);
    _studied.add(_card.id);
    _answered++;
    if (correct) {
      _correct++;
    } else {
      _missed.add(_card.id);
      _missedMode[_card.id] = m;
      // 少し間をあけて、同じ形式でもう一度（1回だけ）。すぐ後だと答えを
      // 覚えているだけで正解でき、わかった気になってしまう
      if (_requeued.add('${_card.id}:${m.name}')) {
        final at = VocabTask.retrySlot(_queue.length, _index);
        if (at == null) {
          _later.add(_card.id);
        } else {
          _queue.insert(at, VocabTask(_card.id, m, relearn: true));
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _index++;
      _prepare();
    });
    if (_done) _report();
  }

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
                    label: Text(
                      _task.isNew
                          ? '新しい${widget.book.noun}'
                          : m.labelOf(_terms),
                    ),
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

  Widget _speakButton(String text, {String tooltip = '発音を聞く'}) => _terms
      ? const SizedBox.shrink()
      : IconButton(
          tooltip: tooltip,
          onPressed: () => _say(text),
          icon: const Icon(Icons.volume_up),
        );

  List<Widget> _prompt(VocabMode m, VocabCard c) {
    Widget big(String s) => Text(
      s,
      textAlign: TextAlign.center,
      style: serif(_terms && s.length > 8 ? 22 : 30),
    );
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
            _terms
                ? (m == VocabMode.flashcard
                      ? 'どんな用語か思い出してから、めくってください'
                      : '説明はどれ？')
                : (m == VocabMode.flashcard ? '意味を思い出してから、めくってください' : '意味はどれ？'),
            textAlign: TextAlign.center,
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
        ];
      case VocabMode.choiceTerm:
      case VocabMode.spelling:
      case VocabMode.compare:
        return [
          Text(
            widget.book.meaningOf(c),
            textAlign: TextAlign.center,
            style: serif(_terms ? 18 : 20),
          ),
          const SizedBox(height: 6),
          Text(
            switch (m) {
              VocabMode.spelling when _terms =>
                '用語を書いてください（読みでもよい）　ヒント: ${c.writingHint}',
              VocabMode.spelling => '英単語をつづってください　ヒント: ${c.spellingHint}',
              VocabMode.compare =>
                _choices.length == 2
                    ? '前に間違えた2つの${widget.book.noun}。この${_terms ? '説明' : '意味'}はどっち？'
                    : '似た${widget.book.noun}の中から、この意味のものを選んでください',
              _ => _terms ? '用語はどれ？' : '英単語はどれ？',
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
            '空欄に入る形のまま書いてください（過去形などもそのまま）　ヒント: ${c.clozeHint}',
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
        ];
    }
  }

  List<Widget> _answerArea(VocabMode m, VocabCard c) {
    switch (m) {
      case VocabMode.flashcard:
        if (_flipped) {
          final g = _guess.text.trim();
          return [
            if (g.isNotEmpty)
              Text(
                'あなたの答え: $g',
                key: const ValueKey('flash-your-guess'),
                style: TextStyle(color: TsuzuriColors.inkSoft),
              ),
          ];
        }
        return [
          if (_task.relearn)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'さっきまちがえた${widget.book.noun}です。選択肢なしで、意味を思い出してから答えを見ましょう',
                key: const ValueKey('flash-relearn'),
                style: TextStyle(color: TsuzuriColors.stamp, fontSize: 12),
              ),
            ),
          Text(
            '${_terms ? '説明' : '意味'}を頭の中で（できれば声に出して）言ってから答えを見よう',
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('flash-guess'),
            controller: _guess,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '思い出した意味をメモ（書かなくてもよい）',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('flash-unknown'),
                  onPressed: () => setState(() {
                    _flipped = true;
                    _unknown = true;
                  }),
                  child: const Text('わからない'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('flash-reveal'),
                  onPressed: () => setState(() => _flipped = true),
                  child: const Text('思い出せた・答えを見る'),
                ),
              ),
            ],
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
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _terms ? '用語を入力' : '英語で入力',
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
                _wasCorrect!
                    ? '○ 正解'
                    : _task.mode == VocabMode.cloze &&
                          c.clozeAnswer.toLowerCase() != c.term.toLowerCase()
                    ? '× 正解は「${c.clozeAnswer}」（${c.term} の変化した形）'
                    : '× 正解は「${c.term}」',
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
                  Flexible(
                    child: Text(
                      _terms ? '（${c.pron}）' : c.pron,
                      style: TextStyle(color: TsuzuriColors.inkSoft),
                    ),
                  ),
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
            // ほかの意味の例文（意味ごとに1つずつ）
            for (final x in c.otherExamples) ...[
              const SizedBox(height: 6),
              if (x.sense.isNotEmpty)
                Text(
                  x.sense,
                  style: TextStyle(color: TsuzuriColors.accent, fontSize: 11.5),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      x.en,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  _speakButton(x.en, tooltip: '例文を聞く'),
                ],
              ),
              if (x.ja.isNotEmpty)
                Text(
                  x.ja,
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
            for (final r in MistakeReason.of(widget.book, _card))
              ChoiceChip(
                label: Text(r.labelOf(_terms)),
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
      if (_unknown) {
        return [
          Text(
            '答えを見て「わかった」と思っても、まだ覚えたことにはしません。'
            '時間をおいて、選択肢なしでもう一度出します。',
            style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
          ),
          const SizedBox(height: 6),
          FilledButton(
            key: const ValueKey('flash-learned'),
            onPressed: () {
              _hit(false);
              _next(Rating.again);
            },
            child: const Text('覚えた・次へ'),
          ),
        ];
      }
      final preview = BookProgress.fsrs.preview(
        _progress.cards[_card.id]?.skills[m.skill],
        DateTime.now(),
      );
      return [
        Text('思い出した意味と合っていましたか？', style: serif(14)),
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
                        Text(
                          _recallLabel(r),
                          style: const TextStyle(fontSize: 12),
                        ),
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
      // 勘で当たった単語は、覚えた扱いにせず早めにまた出す
      if (_wasCorrect == true)
        TextButton(
          key: const ValueKey('vocab-guess'),
          onPressed: () => _next(Rating.hard, guessed: true),
          child: const Text('勘で当たった（早めにまた出す）'),
        ),
    ];
  }

  /// 正直に答えやすいよう、思い出せたかどうかで聞く
  static String _recallLabel(Rating r) => switch (r) {
    Rating.again => 'ちがった',
    Rating.hard => 'あいまい',
    Rating.good => '合っていた',
    Rating.easy => '迷わず言えた',
  };

  /// この回で新しくもらえた苦手克服カード
  List<Widget> _newCards(BookProgress p) {
    final got = [
      for (final w in WeakCards.collected(widget.book, p))
        if (!_overcomeBefore.contains(w.card.id)) w,
    ];
    if (got.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      Center(
        child: Text(
          '苦手克服カードを${got.length}枚ゲット！',
          key: const ValueKey('vocab-new-weak-cards'),
          style: serif(16),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [for (final w in got.take(12)) WeakCardTile(w)],
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
            '🔴 弱点 ${counts[CardStatus.weak]}${widget.book.unit}　🟠 あやふや ${counts[CardStatus.shaky]}${widget.book.unit}　🟢 安定 ${counts[CardStatus.stable]}${widget.book.unit}',
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: StreakTag()),
        ..._newCards(p),
        const SizedBox(height: 20),
        // たった今の単語で、1戦だけ冒険（飛ばしてもよい）
        if (_studied.length >= QuickBattle.minWords &&
            context.getInheritedWidgetOfExactType<RpgServices>() != null) ...[
          FilledButton.tonalIcon(
            key: const ValueKey('vocab-quick-battle'),
            onPressed: () => QuickBattle.start(
              context,
              widget.book,
              _studied.toList(),
              _missed,
            ),
            icon: const Icon(Icons.sports_martial_arts),
            label: Text('今の${widget.book.noun}の魔物と、1戦だけ戦う'),
          ),
          const SizedBox(height: 8),
        ],
        if (_later.isNotEmpty) ...[
          Card(
            key: const ValueKey('vocab-later'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('時間をおいてたしかめる${widget.book.noun}', style: serif(14)),
                  const SizedBox(height: 4),
                  Text(
                    '今すぐもう一度やると答えを覚えているだけで正解できるので、'
                    'あとの復習（明日など）で選択肢なしでまた出します。',
                    style: TextStyle(
                      color: TsuzuriColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [for (final id in _later) widget.book.card(id)?.term ?? '']
                        .join('・'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_missed.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => VocabSessionScreen(
                  store: widget.store,
                  book: widget.book,
                  title: '間違えた${widget.book.noun}',
                  tasks: [
                    for (final id in _missed)
                      VocabTask(
                        id,
                        _missedMode[id] ?? VocabMode.choiceMeaning,
                        relearn: true,
                      ),
                  ],
                ),
              ),
            ),
            icon: const Icon(Icons.replay),
            label: Text('間違えた${_missed.length}${widget.book.unit}をもう一度'),
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
