import 'dart:math';

import '../models/question.dart';

/// 画面に出す形に並べ替えた1問。選択肢の順番は毎回シャッフルする。
class PresentedQuestion {
  const PresentedQuestion({
    required this.source,
    required this.choices,
    required this.correctIndex,
  });

  final QuizQuestion source;
  final List<String> choices;
  final int correctIndex;

  bool isCorrect(int choiceIndex) => choiceIndex == correctIndex;
}

/// 問題の山札。全問出し切ったら再シャッフルして続ける（同じ問題が続かないように）。
///
/// [weight] を渡すと、重いものほど山札の上に来やすい重みつきシャッフルになる
/// （苦手な問題が早く出る）。
class QuestionDeck {
  QuestionDeck(List<QuizQuestion> questions, {Random? random, this.weight})
      : _questions = List.unmodifiable(questions),
        _random = random ?? Random() {
    if (_questions.isEmpty) {
      throw ArgumentError('出題できる問題がありません');
    }
    _refill();
  }

  final List<QuizQuestion> _questions;
  final Random _random;
  final double Function(QuizQuestion)? weight;
  final List<QuizQuestion> _pile = [];
  QuizQuestion? _last;

  int get size => _questions.length;

  PresentedQuestion draw() {
    if (_pile.isEmpty) _refill();
    final q = _pile.removeLast();
    _last = q;
    return _present(q);
  }

  /// 山札の上から [lookahead] 枚を見て、[score] が一番大きい問題を引く
  /// （苦手な問題・特定の分野の問題を優先したいときに使う）。
  /// 長文の設問は本文の順番をくずさないよう、先頭にあるときだけ選ぶ。
  PresentedQuestion drawPreferred(
    double Function(QuizQuestion q) score, {
    int lookahead = 8,
  }) {
    if (_pile.isEmpty) _refill();
    var best = _pile.length - 1;
    var bestScore = score(_pile[best]);
    for (var i = _pile.length - 2;
        i >= 0 && i >= _pile.length - lookahead;
        i--) {
      if (_pile[i].passage != null) continue;
      final sc = score(_pile[i]);
      if (sc > bestScore) {
        best = i;
        bestScore = sc;
      }
    }
    final q = _pile.removeAt(best);
    _last = q;
    return _present(q);
  }

  void _refill() {
    // 長文の設問は本文ごとにまとめ、本文の中では順番どおりに出す。
    // それ以外の問題は1問ずつのまとまりとしてシャッフルする。
    final blocks = <List<QuizQuestion>>[];
    final byPassage = <String, List<QuizQuestion>>{};
    for (final q in _questions) {
      final p = q.passage;
      if (p == null) {
        blocks.add([q]);
      } else {
        byPassage.putIfAbsent(p.id, () {
          final list = <QuizQuestion>[];
          blocks.add(list);
          return list;
        }).add(q);
      }
    }
    final w = weight;
    if (w == null) {
      blocks.shuffle(_random);
    } else {
      // 重みつきランダム順（Efraimidis–Spirakis）：key = u^(1/w) の大きい順
      final keyed = [
        for (final b in blocks)
          (b, pow(_random.nextDouble(), 1 / w(b.first).clamp(0.05, 100))),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
      blocks
        ..clear()
        ..addAll(keyed.map((e) => e.$1));
    }
    // 直前と同じ問題が続かないようにする
    if (blocks.length > 1 && identical(blocks.first.first, _last)) {
      final tmp = blocks.first;
      blocks.first = blocks.last;
      blocks.last = tmp;
    }
    // draw は末尾から取るので逆順に積む
    _pile.addAll([for (final b in blocks) ...b].reversed);
  }

  PresentedQuestion _present(QuizQuestion q) {
    final order = List<int>.generate(q.choices.length, (i) => i)
      ..shuffle(_random);
    return PresentedQuestion(
      source: q,
      choices: [for (final i in order) q.choices[i]],
      correctIndex: order.indexOf(q.answerIndex),
    );
  }
}
