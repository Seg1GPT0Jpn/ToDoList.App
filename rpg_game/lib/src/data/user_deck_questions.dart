import 'dart:math';

import '../models/question.dart';

/// 利用者が自分で作った単語帳の1語。
class UserWordEntry {
  const UserWordEntry({required this.term, required this.meaning});
  final String term;
  final String meaning;
}

/// 利用者が自作した単語帳から「意味」を問う4択問題を作る。
///
/// 著作権上の注意: 市販教材（LEAP・STEP など、copyright_gate.dart で保護している
/// インポート済みデッキ）は絶対に渡さないこと。移植時は呼び出し側で
/// 「ユーザーが自分で作成したデッキ」だけを選べるようにし、
/// [isUserCreated] が false のデッキはここで弾く。
class UserDeckQuestionBuilder {
  UserDeckQuestionBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const minWords = 4;

  QuestionSet build({
    required String deckId,
    required bool isUserCreated,
    required List<UserWordEntry> words,
    String worldId = 'english',
  }) {
    if (!isUserCreated) {
      throw ArgumentError('ゲームには利用者自身が作成した単語帳のみ使用できます（$deckId）');
    }
    final unique = <String, UserWordEntry>{};
    for (final w in words) {
      final term = w.term.trim();
      final meaning = w.meaning.trim();
      if (term.isEmpty || meaning.isEmpty) continue;
      unique.putIfAbsent(
          term, () => UserWordEntry(term: term, meaning: meaning));
    }
    final entries = unique.values.toList();
    final meanings = entries.map((e) => e.meaning).toSet().toList();
    if (entries.length < minWords || meanings.length < minWords) {
      throw ArgumentError('4択を作るには意味の異なる単語が$minWords語以上必要です');
    }

    final questions = <QuizQuestion>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final wrong = meanings.where((m) => m != e.meaning).toList()
        ..shuffle(_random);
      final choices = [e.meaning, ...wrong.take(3)]..shuffle(_random);
      questions.add(QuizQuestion(
        id: '${deckId}_$i',
        category: QuestionCategory.meaning,
        prompt: '「${e.term}」の意味は？',
        choices: choices,
        answerIndex: choices.indexOf(e.meaning),
      ));
    }
    return QuestionSet(
      setId: 'user_$deckId',
      worldId: worldId,
      origin: QuestionOrigin.userCreated,
      version: 1,
      questions: questions,
    );
  }
}
