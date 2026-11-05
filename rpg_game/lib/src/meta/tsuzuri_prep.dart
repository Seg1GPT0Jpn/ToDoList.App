import '../learning/learning_record.dart';
import '../learning/review_planner.dart';
import '../vocab/vocab_book.dart';
import '../vocab/vocab_progress.dart';

/// つづりのテスト予定から、そのまま対策を組み立てる
class TsuzuriPrep {
  const TsuzuriPrep._();

  /// 範囲の単語で1回に出す数
  static const rangeLimit = 40;

  /// 教科の対策で出す問題の数（これより少なければ、教科の海を開く）
  static const weakLimit = 15;
  static const weakMinimum = 5;

  /// 単語帳のうち、番号が [range] に入る単語
  static List<VocabCard> cardsIn(VocabBook book, (int, int) range) => [
        for (final c in book.cards)
          if (c.number != null &&
              c.number! >= range.$1 &&
              c.number! <= range.$2)
            c,
      ];

  /// 範囲の単語がある単語帳（テストの名前に単語帳の名前が入っているものを先に）
  static VocabBook? bookFor(
    List<VocabBook> books,
    (int, int) range,
    String testTitle,
  ) {
    final title = testTitle.toLowerCase();
    final withCards = [
      for (final b in books)
        if (cardsIn(b, range).isNotEmpty) b,
    ];
    for (final b in withCards) {
      if (title.contains(b.title.toLowerCase()) ||
          title.contains(b.id.toLowerCase())) {
        return b;
      }
    }
    return withCards.isEmpty ? null : withCards.first;
  }

  /// 範囲の単語の練習：苦手 → まだ見ていない → あやふや → 覚えた の順に。
  /// まだ見ていない単語はめくって覚え、ほかは4択（英→日）、苦手な単語は日→英もする
  static List<VocabTask> rangeTasks(
    VocabBook book,
    BookProgress progress,
    (int, int) range, {
    required DateTime now,
    int limit = rangeLimit,
  }) {
    const order = [
      CardStatus.weak,
      CardStatus.unseen,
      CardStatus.shaky,
      CardStatus.stable,
    ];
    CardStatus status(VocabCard c) =>
        progress.cards[c.id]?.status(now) ?? CardStatus.unseen;
    final cards = cardsIn(book, range)
      ..sort((a, b) => order.indexOf(status(a)) - order.indexOf(status(b)));
    final tasks = <VocabTask>[];
    for (final c in cards) {
      if (tasks.length >= limit) break;
      final s = status(c);
      if (s == CardStatus.unseen) {
        tasks.add(VocabTask(c.id, VocabMode.flashcard, isNew: true));
      } else {
        tasks.add(VocabTask(c.id, VocabMode.choiceMeaning));
        if (s == CardStatus.weak && tasks.length < limit) {
          tasks.add(VocabTask(c.id, VocabMode.choiceTerm));
        }
      }
    }
    return tasks;
  }

  /// 教科の対策：その教科で、最近まちがえた・正答率の低い問題（新しい順）
  static List<ReviewItem> weakItems(
    LearningRecord record,
    String worldId, {
    required int today,
    int lookback = 60,
    int limit = weakLimit,
  }) {
    final out = <(ReviewItem, int)>[];
    for (final e in record.stats.entries) {
      final s = e.value;
      if (s.setId.isEmpty || s.attempts == 0) continue;
      if (LearningRecord.subjectOf(s.setId) != worldId) continue;
      if (s.lastDay < today - lookback) continue;
      final shaky = s.missStreak > 0 || s.correct / s.attempts < 0.7;
      if (!shaky) continue;
      out.add((
        ReviewItem(
          questionId: e.key,
          setId: s.setId,
          reason: s.missStreak > 0 ? '最近まちがえた' : '正答率が低い',
          priority: s.missStreak.toDouble(),
        ),
        s.lastDay,
      ));
    }
    out.sort((a, b) {
      final d = b.$2.compareTo(a.$2);
      return d != 0 ? d : b.$1.priority.compareTo(a.$1.priority);
    });
    return [for (final (item, _) in out.take(limit)) item];
  }
}
