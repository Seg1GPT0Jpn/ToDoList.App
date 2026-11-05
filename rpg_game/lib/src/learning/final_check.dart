import 'learning_record.dart';
import 'review_planner.dart';

/// 試験の前日・当日の「最終チェック」：最近間違えた問題だけを、新しい順に少しだけ。
///
/// 新しい問題は出さない。まだ克服していない、最近つまずいた問題を確かめる。
class FinalCheck {
  const FinalCheck._();

  static const limit = 10;

  /// さかのぼる日数
  static const lookback = 30;

  /// 前日・当日なら true（[daysLeft] は試験日までの日数）
  static bool isEve(int daysLeft) => daysLeft == 0 || daysLeft == 1;

  static List<ReviewItem> pick(LearningRecord record, {required int today}) {
    final out = <(ReviewItem, int)>[];
    for (final e in record.stats.entries) {
      final s = e.value;
      if (s.setId.isEmpty || s.attempts == 0) continue;
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
    // 最近のものから。同じ日なら、続けて間違えている問題から
    out.sort((a, b) {
      final d = b.$2.compareTo(a.$2);
      return d != 0 ? d : b.$1.priority.compareTo(a.$1.priority);
    });
    return [for (final (item, _) in out.take(limit)) item];
  }
}
