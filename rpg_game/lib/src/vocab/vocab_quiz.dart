import 'dart:math';

import '../models/question.dart';
import 'meaning_text.dart';
import 'similar_choices.dart';
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
        if (usableChoiceText(c.term) && usableChoiceText(c.shortMeaning)) c,
    ];
    final targets = [...(pool ?? all)]..shuffle(_random);
    String label(VocabCard c) => enToJa ? c.shortMeaning : c.term;
    final out = <QuizQuestion>[];
    for (final c in targets) {
      if (out.length >= count) break;
      final answer = label(c);
      // 意味の近い単語（同じ品詞・近い番号・同じ漢字）から選ぶ。まぎらわしいほうが練習になる。
      // 正解と同じ意味をもつ単語は、答えが2つになるので入れない
      final others = SimilarChoices.rank(c, all, random: _random);
      final wrong = <String>[];
      for (final e in others) {
        final l = label(e);
        if (l != answer && !wrong.contains(l)) wrong.add(l);
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
