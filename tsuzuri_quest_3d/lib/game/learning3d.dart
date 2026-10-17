import 'package:rpg_game/rpg_game.dart';

/// 3D 版の学習記録まわり（描画なし・純 Dart）。
///
/// 1問ごとの記録・間隔反復（ライトナー方式）・復習の優先度は、2D 版と同じ
/// rpg_game の [LearningRecord]・[QuestionStat]・[ReviewPlanner] を使う。
/// 保存は 3D 版だけ（Save3D.learningKey）。
class Learning3D {
  Learning3D._();

  /// 出題の重み：まちがえた・復習の日が来た問題ほど先に出る
  static double Function(QuizQuestion) weight(
    LearningRecord Function() record,
    int Function() today,
  ) => (q) {
    final s = record()[q.id];
    if (s == null) return 1;
    return 1 + ReviewPlanner.priorityOf(s, today());
  };

  /// 復習スライムの出題の重み：復習の日が来た問題を、ほぼ必ず先に出す
  static double Function(QuizQuestion) reviewWeight(
    LearningRecord Function() record,
    int Function() today,
  ) => (q) {
    final s = record()[q.id];
    final t = today();
    if (s == null) return 1;
    final due = s.isDue(t) && s.lastDay < t;
    return due ? 50 + ReviewPlanner.priorityOf(s, t) : 1;
  };

  /// 1問の結果を記録の形に
  static AnswerEvent event(
    QuizQuestion q, {
    required String setId,
    required bool knew,
    required Duration elapsed,
  }) => AnswerEvent(
    questionId: q.id,
    setId: setId,
    isCorrect: knew,
    elapsedMs: elapsed.inMilliseconds,
    category: q.category.name,
    unit: q.unit,
  );

  /// [setIds] の問題のうち、復習の日が来ている問題の数。
  /// その日に答えたばかりの問題は数えない（時間をあけてから出す）
  static int dueCount(LearningRecord r, Iterable<String> setIds, int today) {
    final sets = setIds.toSet();
    var n = 0;
    for (final s in r.stats.values) {
      if (sets.contains(s.setId) && s.isDue(today) && s.lastDay < today) n++;
    }
    return n;
  }

  /// 冒険の記録に出す、教科ごとのまとめ
  static List<SubjectSummary> subjects(LearningRecord r, int today) {
    final by = <String, List<QuestionStat>>{};
    for (final s in r.stats.values) {
      if (s.setId.isEmpty) continue;
      by.putIfAbsent(LearningRecord.subjectOf(s.setId), () => []).add(s);
    }
    final out = [
      for (final MapEntry(:key, :value) in by.entries)
        SubjectSummary(
          subject: key,
          answered: value.length,
          mastered: value.where((s) => s.mastered).length,
          attempts: value.fold(0, (a, s) => a + s.attempts),
          correct: value.fold(0, (a, s) => a + s.correct),
          due: value.where((s) => s.isDue(today) && s.lastDay < today).length,
          weak: value.where((s) => s.missStreak > 0).length,
        ),
    ];
    out.sort((a, b) => a.subject.compareTo(b.subject));
    return out;
  }

  static String subjectName(String id) => switch (id) {
    'english' => '英語',
    'math' => '数学',
    'social' => '社会',
    'science' => '理科',
    'japanese' => '国語',
    _ => id,
  };
}

class SubjectSummary {
  const SubjectSummary({
    required this.subject,
    required this.answered,
    required this.mastered,
    required this.attempts,
    required this.correct,
    required this.due,
    required this.weak,
  });

  final String subject;

  /// 答えたことのある問題の数
  final int answered;

  /// 習得した問題（日をあけて正解を重ねた）
  final int mastered;
  final int attempts;
  final int correct;

  /// 今日が復習の日の問題
  final int due;

  /// 最後にまちがえたままの問題
  final int weak;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}
