import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  const words = [
    UserWordEntry(term: 'apple', meaning: 'りんご'),
    UserWordEntry(term: 'river', meaning: '川'),
    UserWordEntry(term: 'quiet', meaning: '静かな'),
    UserWordEntry(term: 'run', meaning: '走る'),
    UserWordEntry(term: 'bright', meaning: '明るい'),
  ];

  test('自作単語帳から4択問題を作れる', () {
    final set = UserDeckQuestionBuilder(random: Random(1))
        .build(deckId: 'd1', isUserCreated: true, words: words);
    expect(set.origin, QuestionOrigin.userCreated);
    expect(set.questions.length, 5);
    for (final q in set.questions) {
      final w = words.firstWhere((w) => q.prompt.contains(w.term));
      expect(q.answer, w.meaning);
    }
  });

  test('利用者が作成していない（インポートした市販教材など）単語帳は使えない', () {
    expect(
      () => UserDeckQuestionBuilder()
          .build(deckId: 'imported', isUserCreated: false, words: words),
      throwsArgumentError,
    );
  });

  test('単語が4語未満だと作れない', () {
    expect(
      () => UserDeckQuestionBuilder().build(
          deckId: 'd', isUserCreated: true, words: words.take(3).toList()),
      throwsArgumentError,
    );
  });
}
