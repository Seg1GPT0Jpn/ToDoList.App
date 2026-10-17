import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final book = VocabBook(
    id: 'b',
    title: 'B',
    kind: VocabBookKind.custom,
    cards: [
      for (var i = 1; i <= 5; i++)
        VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
    ],
  );
  final t0 = DateTime(2026, 10, 1);

  void answer(BookProgress p, String id, Rating r, int day) => p.record(
        cardId: id,
        skill: VocabSkill.meaning,
        rating: r,
        now: t0.add(Duration(days: day)),
      );

  test('2回以上間違えた単語を、続けて2回正解すると克服カードになる', () {
    final p = BookProgress();
    // w1：間違い1回だけ → 対象外
    answer(p, 'w1', Rating.again, 0);
    answer(p, 'w1', Rating.good, 1);
    answer(p, 'w1', Rating.good, 2);
    // w2：間違い2回 → 正解1回ではまだ
    answer(p, 'w2', Rating.again, 0);
    answer(p, 'w2', Rating.again, 0);
    answer(p, 'w2', Rating.good, 1);
    expect(WeakCards.collected(book, p), isEmpty);
    expect(WeakCards.waiting(book, p).map((w) => w.card.id), ['w2']);
    answer(p, 'w2', Rating.good, 2);
    final got = WeakCards.collected(book, p);
    expect(got.single.card.id, 'w2');
    expect(got.single.stars, 1);
    expect(WeakCards.waiting(book, p), isEmpty);
    // また間違えると、もう一度挑戦
    answer(p, 'w2', Rating.again, 3);
    expect(WeakCards.collected(book, p), isEmpty);
  });

  test('間違えた回数が多いほどレア。練習はあと少しの単語から', () {
    expect(WeakCards.starsFor(2), 1);
    expect(WeakCards.starsFor(4), 2);
    expect(WeakCards.starsFor(7), 3);
    final p = BookProgress();
    for (var i = 0; i < 3; i++) {
      answer(p, 'w3', Rating.again, 0);
    }
    for (var i = 0; i < 2; i++) {
      answer(p, 'w4', Rating.again, 0);
    }
    answer(p, 'w4', Rating.good, 1);
    expect(WeakCards.waiting(book, p).map((w) => w.card.id), ['w4', 'w3']);
    final tasks = WeakCards.practice(book, p, count: 1);
    expect(tasks.single.cardId, 'w4');
    expect(tasks.single.mode, VocabMode.choiceMeaning);
  });
}
