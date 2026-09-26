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
    _pile
      ..addAll(_questions)
      ..shuffle(_random);
    // 山札の切れ目で直前と同じ問題が続かないようにする（draw は末尾から取る）
    if (_pile.length > 1 && identical(_pile.last, _last)) {
      final tmp = _pile.first;
      _pile.first = _pile.last;
      _pile.last = tmp;
    }
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
