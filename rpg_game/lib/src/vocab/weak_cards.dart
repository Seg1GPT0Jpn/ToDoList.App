import 'vocab_book.dart';
import 'vocab_progress.dart';

/// 苦手克服カード：何度も間違えた単語を、続けて正解できるようになったらもらえるカード。
///
/// ガチャではなく、苦手を克服した記録そのもの。間違えた回数が多い単語ほどレア。
class WeakCard {
  const WeakCard(this.card, this.mistakes, this.stars);
  final VocabCard card;

  /// これまでに間違えた回数
  final int mistakes;

  /// レア度（★1〜3）
  final int stars;
}

class WeakCards {
  const WeakCards._();

  /// カードの対象になる、間違えた回数
  static const minMistakes = 2;

  /// 克服とみなす、続けて正解した回数（意味の力）
  static const needStreak = 2;

  static int starsFor(int mistakes) => mistakes >= 7
      ? 3
      : mistakes >= 4
          ? 2
          : 1;

  /// 苦手だった単語か
  static bool wasWeak(CardProgress? p) =>
      p != null && p.totalMistakes >= minMistakes;

  /// 克服したか：苦手だった単語を、続けて正解できている。
  /// また間違えると連続が切れて、もう一度挑戦になる
  static bool overcome(CardProgress? p) =>
      wasWeak(p) && (p!.skills[VocabSkill.meaning]?.streak ?? 0) >= needStreak;

  /// 集めたカード（レアな順）
  static List<WeakCard> collected(
    VocabBook book,
    BookProgress progress,
  ) {
    final out = [
      for (final c in book.cards)
        if (overcome(progress.cards[c.id]))
          WeakCard(
            c,
            progress.cards[c.id]!.totalMistakes,
            starsFor(progress.cards[c.id]!.totalMistakes),
          ),
    ];
    out.sort((a, b) => b.mistakes.compareTo(a.mistakes));
    return out;
  }

  /// まだ克服していない苦手な単語（あと少しのものから）
  static List<WeakCard> waiting(
    VocabBook book,
    BookProgress progress,
  ) {
    final out = [
      for (final c in book.cards)
        if (wasWeak(progress.cards[c.id]) && !overcome(progress.cards[c.id]))
          WeakCard(
            c,
            progress.cards[c.id]!.totalMistakes,
            starsFor(progress.cards[c.id]!.totalMistakes),
          ),
    ];
    int streak(WeakCard w) =>
        progress.cards[w.card.id]?.skills[VocabSkill.meaning]?.streak ?? 0;
    out.sort((a, b) => streak(b).compareTo(streak(a)));
    return out;
  }

  /// 克服していない苦手な単語を練習する課題（4択 英→日）
  static List<VocabTask> practice(
    VocabBook book,
    BookProgress progress, {
    int count = 20,
  }) =>
      [
        for (final w in waiting(book, progress).take(count))
          VocabTask(w.card.id, VocabMode.choiceMeaning),
      ];
}
