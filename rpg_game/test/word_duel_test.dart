import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final book = VocabBook(
    id: 'leap',
    title: 'LEAP',
    kind: VocabBookKind.custom,
    cards: [
      for (var i = 1; i <= 50; i++)
        VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
    ],
  );

  test('範囲から10語を選び、同じ種ならみんな同じ選択肢の並び', () {
    final nums = DuelRules.pick(book, Random(1), from: 11, to: 30);
    expect(nums, hasLength(10));
    expect(nums.every((n) => n >= 11 && n <= 30), isTrue);
    expect(nums.toSet(), hasLength(10));
    final a = DuelRules.build(book, nums, 42);
    final b = DuelRules.build(book, nums, 42);
    expect(a.map((q) => q.choices.join()), b.map((q) => q.choices.join()));
    for (final q in a) {
      expect(q.choices, hasLength(4));
      expect(q.choices.toSet(), hasLength(4));
      expect(q.choices[q.answer], q.card.meaning);
    }
    // 自分の単語帳にない番号はとばす
    expect(DuelRules.build(book, [1, 999], 1), hasLength(1));
  });

  test('点数：正解100点＋早さで最大50点。時間切れ・不正解は0点', () {
    expect(DuelRules.points(true, Duration.zero), 150);
    expect(DuelRules.points(true, const Duration(seconds: 5)), 125);
    expect(DuelRules.points(true, const Duration(seconds: 12)), 100);
    expect(DuelRules.points(false, Duration.zero), 0);
  });

  test('IDは8文字。保存して戻せて、順位は点数の高い順', () {
    final id = WordDuel.newId(Random(3));
    expect(WordDuel.validId(id), isTrue);
    expect(WordDuel.validId('ABC'), isFalse);
    final d = WordDuel(
      id: id,
      ownerId: 'a',
      ownerName: 'あり',
      source: DuelSource.book,
      sourceId: 'leap',
      title: 'LEAP 1〜50',
      numbers: const [3, 1, 2],
      seed: 9,
    )
        .withResult('a', const DuelResult(name: 'あり', correct: 8, score: 1000))
        .withResult('b', const DuelResult(name: 'ぼぶ', correct: 9, score: 1200));
    final back = WordDuel.fromMap(id, d.toMap())!;
    expect(back.numbers, [3, 1, 2]);
    expect(back.source, DuelSource.book);
    expect(back.ranking.map((e) => e.$1), ['b', 'a']);
    expect(back.played('a'), isTrue);
    expect(WordDuel.fromMap(id, {'source': 'x'}), isNull);
  });

  test('つづ単の一覧を番号つきの単語帳にする', () {
    final list = WordList(
      listId: 'tz1',
      title: 'つづ単',
      origin: QuestionOrigin.parse('original'),
      words: const [
        WordEntry(term: 'apple', meaning: 'りんご'),
        WordEntry(term: 'book', meaning: '本'),
      ],
    );
    final b = DuelRules.bookOf(list);
    expect(b.cards.map((c) => c.number), [1, 2]);
  });
}
