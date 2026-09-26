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
class QuestionDeck {
  QuestionDeck(List<QuizQuestion> questions, {Random? random})
      : _questions = List.unmodifiable(questions),
        _random = random ?? Random() {
    if (_questions.isEmpty) {
      throw ArgumentError('出題できる問題がありません');
    }
    _refill();
  }

  final List<QuizQuestion> _questions;
  final Random _random;
  final List<QuizQuestion> _pile = [];
  QuizQuestion? _last;

  int get size => _questions.length;

  PresentedQuestion draw() {
    if (_pile.isEmpty) _refill();
    final q = _pile.removeLast();
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
    blocks.shuffle(_random);
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
