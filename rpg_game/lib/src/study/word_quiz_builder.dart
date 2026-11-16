import 'dart:math';

import '../curriculum/curriculum.dart';
import '../models/question.dart';
import '../vocab/similar_choices.dart';
import 'word_list.dart';

enum WordQuizDirection {
  /// 英語を見て意味を選ぶ
  enToJa,

  /// 意味を見て英語を選ぶ
  jaToEn,
}

/// 単語帳から4択問題を作る。
class WordQuizBuilder {
  WordQuizBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  QuestionSet build(
    WordList list, {
    required WordQuizDirection direction,
    List<WordEntry>? only,
  }) {
    final pool = list.words;
    final targets = only ?? pool;
    if (pool.length < 4) {
      throw ArgumentError('4択を作るには4語以上必要です（${list.title}）');
    }
    final questions = <QuizQuestion>[];
    for (final w in targets) {
      final answer =
          direction == WordQuizDirection.enToJa ? w.shortMeaning : w.term;
      String label(WordEntry e) =>
          direction == WordQuizDirection.enToJa ? e.shortMeaning : e.term;
      // 意味の近い単語（同じ品詞・同じ漢字）から、まちがいの選択肢を3つ選ぶ。
      // 正解と同じ意味をもつ単語は、答えが2つになるので入れない
      final candidates = SimilarChoices.rankBy<WordEntry>(
        w,
        pool,
        term: (e) => e.term,
        meaning: (e) => e.meaning,
        random: _random,
      );
      final wrong = <String>[];
      for (final c in candidates) {
        final l = label(c);
        if (l != answer && !wrong.contains(l)) wrong.add(l);
        if (wrong.length == 3) break;
      }
      if (wrong.length < 3) continue;
      final choices = [answer, ...wrong]..shuffle(_random);
      final id =
          '${list.listId}_${direction.name}_${w.number ?? pool.indexOf(w)}';
      questions.add(QuizQuestion(
        id: id,
        category: QuestionCategory.meaning,
        prompt: direction == WordQuizDirection.enToJa
            ? '「${w.term}」の意味は？'
            : '「${w.shortMeaning}」を表す英語は？',
        choices: choices,
        answerIndex: choices.indexOf(answer),
        explanation: [
          '${w.term}：${w.meaning}',
          if (w.example.isNotEmpty) '例）${w.example}',
          if (w.exampleJa.isNotEmpty) '　${w.exampleJa}',
          if (w.note.isNotEmpty) '💡 ${w.note}',
        ].join('\n'),
        unit: Curriculum.unitForGeneratedSet(list.listId),
      ));
    }
    return QuestionSet(
      setId: '${list.listId}_${direction.name}',
      worldId: 'study',
      origin: list.origin,
      version: 1,
      questions: questions,
    );
  }
}
