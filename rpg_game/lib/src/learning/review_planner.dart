import 'learning_record.dart';
import 'question_stat.dart';

/// 復習に選ばれた問題と、その理由
class ReviewItem {
  const ReviewItem({
    required this.questionId,
    required this.setId,
    required this.reason,
    required this.priority,
  });

  final String questionId;
  final String setId;
  final String reason;
  final double priority;
}

/// 復習する問題を選ぶ。
///
/// 「間違えた」だけでなく、「時間がかかった」「復習の期限が来た」
/// 「長く触れていない」問題を組み合わせて優先度をつける（間隔反復の土台）。
class ReviewPlanner {
  const ReviewPlanner._();

  /// これより時間がかかった問題は「時間がかかった」とみなす（ミリ秒）
  static const slowMs = 15000;

  /// これ以上触れていない問題は「ひさしぶり」
  static const staleDays = 14;

  static double priorityOf(QuestionStat s, int today) {
    if (s.attempts == 0) return 0;
    var p = 0.0;
    if (s.missStreak > 0) p += 2 + s.missStreak * 0.5;
    if (s.isDue(today)) p += 1 + (today - s.dueDay) * 0.1;
    if (s.averageMs > slowMs) p += 0.6;
    if (today - s.lastDay >= staleDays && s.box < QuestionStat.maxBox) {
      p += 0.5;
    }
    p += s.weakness * 0.5;
    return p;
  }

  static String reasonOf(QuestionStat s, int today) {
    if (s.missStreak > 0) return 'まちがえた';
    if (s.isDue(today)) return '復習の日';
    if (s.averageMs > slowMs) return '時間がかかった';
    if (today - s.lastDay >= staleDays) return 'ひさしぶり';
    return '念のため';
  }

  /// 優先度の高い順に選ぶ。[subject] を指定すると、その教科だけ
  static List<ReviewItem> plan(
    LearningRecord record, {
    required int today,
    int limit = 20,
    String? subject,
  }) {
    final items = <ReviewItem>[];
    for (final e in record.stats.entries) {
      final s = e.value;
      if (s.setId.isEmpty) continue;
      if (subject != null && LearningRecord.subjectOf(s.setId) != subject) {
        continue;
      }
      final p = priorityOf(s, today);
      if (p <= 0.5) continue;
      items.add(
        ReviewItem(
          questionId: e.key,
          setId: s.setId,
          reason: reasonOf(s, today),
          priority: p,
        ),
      );
    }
    items.sort((a, b) => b.priority.compareTo(a.priority));
    return items.take(limit).toList();
  }
}
