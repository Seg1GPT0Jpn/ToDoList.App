import '../models/question.dart';
import 'learning_record.dart';
import 'question_stat.dart';

/// 出題の重みづけ。苦手な問題・復習の期限が来た問題ほど早く出やすく、
/// 習得した問題はたまにしか出ない。完全に出なくなることはない。
class AdaptiveWeights {
  const AdaptiveWeights._();

  static double of(QuestionStat? s, int today) {
    if (s == null || s.attempts == 0) return 1.0;
    var w = 0.6 + s.weakness * 1.2;
    if (s.isDue(today)) w += 1.0;
    if (s.mastered && !s.isDue(today)) w = 0.35;
    return w.clamp(0.2, 4.0);
  }

  static double Function(QuizQuestion) forRecord(
    LearningRecord record,
    int today,
  ) =>
      (q) => of(record[q.id], today);
}
