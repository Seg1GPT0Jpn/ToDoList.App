import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

VocabCard _c(int n, String t, String m) =>
    VocabCard(id: '$n', number: n, term: t, meaning: m);

void main() {
  // LEAP のように、意味の近い語が近い番号にまとまっている単語帳
  final cards = [
    _c(1401, 'assert', '[他] ～と断定する，～を主張する'),
    _c(1402, 'defy', '[他] ①～に逆らう ②～を拒む'),
    _c(1403, 'condemn', '[他] ①～を非難する ②～に(刑の)宣告をする'),
    _c(1404, 'cite', '[他] ～を引き合いに出す，引用する'),
    _c(1406, 'refute', '[他] ～を論駁する，～に反論する'),
    _c(1407, 'sue', '[他] ～を訴える'),
    _c(1410, 'advocate', '[名] ①提唱者，支持者 [他] ②～を主張する，支持する'),
    _c(1700, 'harbor', '[名] 港'),
    _c(1701, 'cereal', '[名] 穀物'),
    _c(1702, 'vague', '[形] あいまいな'),
    _c(1850, 'diminish', '[自] 減少する'),
    _c(1851, 'reduce', '[他] ～を減らす'),
  ];

  test('同じ品詞・近い番号の、意味の近い単語が先に来る', () {
    final c = cards.firstWhere((x) => x.term == 'condemn');
    final r = SimilarChoices.rank(c, cards, random: Random(1));
    final top3 = r.take(3).map((x) => x.term).toSet();
    expect(
        top3.difference({'assert', 'defy', 'cite', 'refute', 'sue'}), isEmpty);
    expect(r.map((x) => x.term), isNot(contains('condemn')));
  });

  test('正解と同じ意味をもつ単語は、まちがいの選択肢にしない', () {
    final c = cards.firstWhere((x) => x.term == 'assert');
    final r = SimilarChoices.rank(c, cards, random: Random(2));
    // advocate も「～を主張する」なので、入れると答えが2つになる
    expect(r.map((x) => x.term), isNot(contains('advocate')));
    expect(SimilarChoices.sameMeaning(c, cards.last), isFalse);
  });

  test('番号が離れていても、同じ漢字の意味は近いと見る', () {
    final c = cards.firstWhere((x) => x.term == 'reduce');
    final r = SimilarChoices.rank(c, cards, random: Random(3));
    expect(r.first.term, 'diminish');
  });

  test('4択の選択肢（日→英）は、正解1つと意味の近いまちがい3つ', () {
    final book = VocabBook(
        id: 'leap',
        title: 'LEAP',
        kind: VocabBookKind.protectedImport,
        cards: cards);
    final c = cards.firstWhere((x) => x.term == 'refute');
    for (var seed = 0; seed < 20; seed++) {
      final ch = VocabChoices.build(book, c, VocabMode.choiceTerm,
          random: Random(seed));
      expect(ch, hasLength(4));
      expect(ch.where((t) => t == 'refute'), hasLength(1));
      expect(ch, isNot(contains('harbor')));
      expect(ch, isNot(contains('cereal')));
    }
    final qs = VocabQuizBuilder(random: Random(5))
        .build(book, enToJa: false, count: 12);
    for (final q in qs) {
      expect(q.choices.toSet(), hasLength(4));
    }
  });

  test('つづ単（アルファベット順の単語帳）でも、意味の近い単語から選ぶ', () {
    WordEntry w(int n, String t, String m) =>
        WordEntry(number: n, term: t, meaning: m);
    final list = WordList(
      listId: 'tsuzutan_test',
      title: 'test',
      origin: QuestionOrigin.original,
      words: [
        w(1, 'decrease', '[動] 減少する'),
        w(2, 'decline', '[動] ①減少する ②～を断る'),
        w(3, 'diminish', '[動] 減る、小さくなる'),
        w(4, 'dairy', '[形] 乳製品の'),
        w(5, 'damp', '[形] 湿った'),
        w(6, 'deal', '[名] 取引'),
        w(7, 'debt', '[名] 借金'),
        w(8, 'delay', '[動] ～を遅らせる'),
      ],
    );
    final qs = WordQuizBuilder(random: Random(1))
        .build(list, direction: WordQuizDirection.jaToEn);
    final q = qs.questions.firstWhere((q) => q.prompt.contains('「減少する」'));
    // decline も「減少する」なので、入れると答えが2つになる
    expect(q.choices.where((c) => c == 'decrease' || c == 'decline'),
        hasLength(1));
    expect(q.choices, contains('diminish'));
  });
}
