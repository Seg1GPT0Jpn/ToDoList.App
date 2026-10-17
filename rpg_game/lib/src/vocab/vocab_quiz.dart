import 'dart:math';

import '../models/question.dart';
import 'vocab_book.dart';

/// 単語帳（LEAP・EEVI など）から4択問題を作る。
///
/// 定期テストの海・模擬試験の空でだけ使う（RPG では使わない）。
/// 問題は端末の中でその場で作り、どこにも保存しない。
class VocabQuizBuilder {
  VocabQuizBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// [enToJa] が true なら英単語→意味、false なら意味→英単語
  List<QuizQuestion> build(
    VocabBook book, {
    required bool enToJa,
    int count = 20,
    List<VocabCard>? pool,
  }) {
    final all = [
      for (final c in book.cards)
        if (c.term.trim().isNotEmpty && c.shortMeaning.trim().isNotEmpty) c,
    ];
    final targets = [...(pool ?? all)]..shuffle(_random);
    String label(VocabCard c) => enToJa ? c.shortMeaning : c.term;
    final out = <QuizQuestion>[];
    for (final c in targets) {
      if (out.length >= count) break;
      final answer = label(c);
      final others = [
        for (final e in all)
          if (!identical(e, c) && label(e) != answer) e,
      ]..shuffle(_random);
      // 同じ品詞を先に（まぎらわしいほうが練習になる）
      others.sort(
        (a, b) =>
            (a.partOfSpeech == c.partOfSpeech ? 0 : 1) -
            (b.partOfSpeech == c.partOfSpeech ? 0 : 1),
      );
      final wrong = <String>[];
      for (final e in others) {
        final l = label(e);
        if (!wrong.contains(l)) wrong.add(l);
        if (wrong.length == 3) break;
      }
      if (wrong.length < 3) continue;
      final choices = [answer, ...wrong]..shuffle(_random);
      out.add(
        QuizQuestion(
          id: 'vocab_${book.id}_${enToJa ? 'e' : 'j'}_${c.id}',
          category: QuestionCategory.meaning,
          prompt: enToJa ? '「${c.term}」の意味は？' : '「${c.shortMeaning}」を表す英語は？',
          choices: choices,
          answerIndex: choices.indexOf(answer),
          explanation: '${c.term}：${c.meaning}',
          tags: ['vocab', book.id],
        ),
      );
    }
    return out;
  }
}
