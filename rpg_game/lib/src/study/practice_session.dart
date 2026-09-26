import 'dart:math';

import '../battle/question_deck.dart';
import '../models/question.dart';

/// 1問分の回答結果
class PracticeAnswer {
  const PracticeAnswer({
    required this.question,
    required this.chosenIndex,
    required this.correct,
  });

  final PresentedQuestion question;
  final int chosenIndex;
  final bool correct;
}

/// 定期テストの海・宿の授業で使う、ダメージのない練習セッション。
class PracticeSession {
  PracticeSession(List<QuizQuestion> questions, {int? count, Random? random})
      : _random = random ?? Random() {
    if (questions.isEmpty) throw ArgumentError('問題がありません');
    final picked = [...questions]..shuffle(_random);
    final n = count == null ? picked.length : min(count, picked.length);
    final deck = QuestionDeck(picked.take(n).toList(), random: _random);
    _queue = [for (var i = 0; i < n; i++) deck.draw()];
  }

  final Random _random;
  late final List<PresentedQuestion> _queue;
  final List<PracticeAnswer> _answers = [];

  int get total => _queue.length;
  int get answeredCount => _answers.length;
  int get correctCount => _answers.where((a) => a.correct).length;
  bool get isFinished => _answers.length >= _queue.length;
  List<PracticeAnswer> get answers => List.unmodifiable(_answers);

  /// 今の問題（終了後は最後の問題）
  PresentedQuestion get current =>
      _queue[min(_answers.length, _queue.length - 1)];

  /// 正答率（0〜100）
  int get percent => total == 0 ? 0 : (correctCount * 100 / total).round();

  PracticeAnswer answer(int choiceIndex) {
    if (isFinished) throw StateError('練習は終わっています');
    final q = current;
    if (choiceIndex < 0 || choiceIndex >= q.choices.length) {
      throw RangeError.index(choiceIndex, q.choices, 'choiceIndex');
    }
    final a = PracticeAnswer(
      question: q,
      chosenIndex: choiceIndex,
      correct: q.isCorrect(choiceIndex),
    );
    _answers.add(a);
    return a;
  }

  /// 間違えた問題（重複なし）
  List<QuizQuestion> get missed {
    final seen = <String>{};
    return [
      for (final a in _answers)
        if (!a.correct && seen.add(a.question.source.id)) a.question.source,
    ];
  }
}
