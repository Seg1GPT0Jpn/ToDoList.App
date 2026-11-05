import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import '../vocab/vocab_store.dart';
import 'contest_backend.dart';
import 'duel_backend.dart';

/// 週替わり単語バトルの本体：[parts] の種類（フラッシュカード・日→英・英→日・例文）を順に解く。
///
/// 種類ごとに、「はじめる」を押したときに始めた記録を送り（1回だけ）、解き終わったら結果を送る。
/// 最後まで解くか、やめたときの記録を返して閉じる。
class ContestPlayScreen extends StatefulWidget {
  const ContestPlayScreen({
    super.key,
    required this.round,
    required this.book,
    required this.entry,
    required this.backend,
    required this.name,
    required this.parts,
    this.store,
  });

  final ContestRound round;
  final VocabBook book;

  /// いまの記録
  final ContestEntry entry;
  final ContestBackend backend;

  /// ニックネーム（はじめて始めるときに記録に入れる）
  final String name;

  /// 解く種類の番号（分野ごとなら1つ、一気になら、まだの種類すべて）
  final List<int> parts;

  /// 学習記録にも残す（テストでは null）
  final VocabStore? store;

  @override
  State<ContestPlayScreen> createState() => _ContestPlayScreenState();
}

class _ContestPlayScreenState extends State<ContestPlayScreen> {
  static const _tick = Duration(milliseconds: 100);

  late final List<List<ContestQuestion>> _parts = widget.round.parts(
    widget.book,
  );
  late final int _total = _parts.fold(0, (n, p) => n + p.length);
  late ContestEntry _entry = widget.entry;

  /// [ContestPlayScreen.parts] の何番目を解いているか
  int _step = 0;

  /// 解いている種類の問題（null なら、種類の説明を出している）
  List<ContestQuestion>? _questions;
  int _index = 0;
  int _correct = 0;
  int _points = 0;
  Duration _took = Duration.zero;
  int? _picked;
  Timer? _timer;
  bool _saving = false;
  String? _error;

  ContestPart get _part => ContestPart.values[widget.parts[_step]];
  ContestQuestion get _q => _questions![_index];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _begin() async {
    final part = _part.index;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // 始めた記録（この種類は、もう挑戦しなおせない）
      _entry = await widget.backend.startPart(
        widget.round.id,
        widget.name,
        part,
      );
    } on DuelException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _questions = _parts[part];
      _index = 0;
      _correct = 0;
      _points = 0;
    });
    if (_questions!.isEmpty) {
      _endPart();
    } else {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _took = Duration.zero;
    _picked = null;
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || _picked != null) return;
      setState(() => _took += _tick);
      if (_took >= _q.part.limit) _answer(-1);
    });
  }

  void _answer(int i) {
    if (_picked != null || _questions == null) return;
    _timer?.cancel();
    final q = _q;
    final ok = i == q.answer;
    widget.store
        ?.progress(widget.book.id)
        .record(
          cardId: q.card.id,
          skill: switch (q.part) {
            ContestPart.jaEn => VocabSkill.recall,
            ContestPart.cloze => VocabSkill.context,
            _ => VocabSkill.meaning,
          },
          rating: ok ? Rating.good : Rating.again,
          now: DateTime.now(),
          spent: _took,
        );
    setState(() {
      _picked = i;
      if (ok) _correct++;
      _points += ContestScoring.points(ok, _took, q.part.limit);
    });
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_index + 1 >= _questions!.length) {
        _endPart();
      } else {
        setState(() => _index++);
        _start();
      }
    });
  }

  Future<void> _endPart() async {
    final qs = _questions!;
    final part = _part.index;
    final next = _entry.next(
      part: part,
      partScore: ContestScoring.score(_points, qs.length),
      partCorrect: _correct,
      partPoints: _points,
      totalQuestions: _total,
    );
    setState(() => _saving = true);
    try {
      await widget.backend.savePart(widget.round.id, next, part);
      await widget.store?.saveProgress(widget.book.id);
      if (!mounted) return;
      _entry = next;
      if (_step + 1 >= widget.parts.length) {
        Navigator.of(context).pop(next);
        return;
      }
      setState(() {
        _step++;
        _questions = null;
      });
    } on DuelException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.round;
    return PopScope(
      // やめたときは、そこまでの記録を返す
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _timer?.cancel();
        Navigator.of(context).pop(_entry);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(r.heading, style: serif(16))),
        body: NotebookPaper(
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : _questions == null
              ? _intro()
              : _play(),
        ),
      ),
    );
  }

  Widget _intro() {
    final part = _part;
    final n = _parts[part.index].length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 24, 16, 24),
      children: [
        Text(
          widget.parts.length > 1
              ? '${_step + 1} / ${widget.parts.length}　${part.label}'
              : part.label,
          key: const ValueKey('contest-part-title'),
          style: serif(22),
        ),
        const SizedBox(height: 8),
        Text(part.how),
        Text(
          '$n問・1問${part.limit.inSeconds}秒。早く正解するほど高得点',
          style: TextStyle(color: TsuzuriColors.inkSoft),
        ),
        if (_entry.section > 0) ...[
          const SizedBox(height: 12),
          Text(
            'ここまでの得点 ${ContestScoring.percent(_entry.score)}'
            '（${[for (final e in _entry.scores.entries) '${ContestPart.values[e.key].label} ${ContestScoring.percent(e.value)}'].join('・')}）',
            key: const ValueKey('contest-so-far'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('contest-part-start'),
          onPressed: _begin,
          icon: const Icon(Icons.play_arrow),
          label: Text(n == 0 ? '次へ（この範囲には例文がありません）' : 'はじめる'),
        ),
        const SizedBox(height: 12),
        Text(
          '「はじめる」を押すと、この種類は1回だけの挑戦になります。'
          '途中でやめると、この種類は記録なしです（ほかの種類には、あとから挑戦できます）。',
          style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _play() {
    final q = _q;
    final qs = _questions!;
    Color? colorOf(int i) => _picked == null
        ? null
        : i == q.answer
        ? Colors.green.withValues(alpha: 0.2)
        : i == _picked
        ? Colors.red.withValues(alpha: 0.2)
        : null;
    Widget choice(int i) => OutlinedButton(
      key: ValueKey('contest-choice-$i'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        backgroundColor: colorOf(i),
      ),
      onPressed: () => _answer(i),
      child: Text(q.choices[i], textAlign: TextAlign.center),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
      children: [
        Text(
          '${q.part.label}　${_index + 1} / ${qs.length}',
          style: TextStyle(color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: 1 - _took.inMilliseconds / q.part.limit.inMilliseconds,
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            q.prompt,
            key: const ValueKey('contest-prompt'),
            textAlign: TextAlign.center,
            style: serif(q.part == ContestPart.cloze ? 20 : 28),
          ),
        ),
        if (q.sub.isNotEmpty) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              q.sub,
              key: const ValueKey('contest-sub'),
              textAlign: TextAlign.center,
              style: q.part == ContestPart.flash
                  ? serif(22, color: TsuzuriColors.accent)
                  : TextStyle(color: TsuzuriColors.inkSoft),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (q.choices.length == 2)
          Row(
            children: [
              Expanded(child: choice(0)),
              const SizedBox(width: 8),
              Expanded(child: choice(1)),
            ],
          )
        else
          for (var i = 0; i < q.choices.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: choice(i),
            ),
      ],
    );
  }
}
