import 'dart:math';

/// 日付を「1970-01-01 からの日数」で表す（端末の暦の日付で数える）
int dayNumber(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// 1問ごとの学習記録。
///
/// 復習の間隔はライトナー方式：正解するたびに「箱」が1つ上がり、
/// 次に出題する日までの間隔が 0→1→2→4→8→16→32 日と伸びる。
/// まちがえると箱は1に戻り、次の日にまた出てくる。
class QuestionStat {
  const QuestionStat({
    this.setId = '',
    this.attempts = 0,
    this.correct = 0,
    this.streak = 0,
    this.missStreak = 0,
    this.lastDay = 0,
    this.totalMs = 0,
    this.box = 0,
    this.dueDay = 0,
    this.overcome = false,
    this.category = '',
  });

  /// 問題の種類（QuestionCategory の name。古い記録では空）
  final String category;

  /// どの問題セットの問題か（復習のときに読み込むため）
  final String setId;
  final int attempts;
  final int correct;

  /// 連続正解数
  final int streak;

  /// 連続ミス数
  final int missStreak;

  /// 最後に答えた日
  final int lastDay;

  /// 回答にかかった時間の合計（ミリ秒）
  final int totalMs;

  /// 間隔反復の箱（0〜[maxBox]）
  final int box;

  /// 次に復習する日
  final int dueDay;

  /// 苦手を克服したことがあるか（実績用）
  final bool overcome;

  static const maxBox = 6;
  static const intervals = [0, 1, 2, 4, 8, 16, 32];

  int get wrong => attempts - correct;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  int get averageMs => attempts == 0 ? 0 : totalMs ~/ attempts;

  /// 習得した（3回以上間隔をあけて正解した）
  bool get mastered => box >= 3;

  /// 復習の期限が来ているか
  bool isDue(int today) => attempts > 0 && dueDay <= today;

  /// 苦手度（0〜おおよそ3）。まちがいが多く、連続ミスしているほど大きい
  double get weakness {
    if (attempts == 0) return 0;
    return (1 - accuracy) * 2 + min(missStreak, 3) * 0.3;
  }

  /// 1回答えたあとの記録
  QuestionStat record({
    required bool isCorrect,
    required int day,
    required int elapsedMs,
    String? setId,
    String? category,
  }) {
    final newBox = isCorrect ? min(box + 1, maxBox) : 1;
    final newStreak = isCorrect ? streak + 1 : 0;
    // 2回以上まちがえた問題を3回連続で正解したら「苦手克服」
    final nowOvercome = overcome || (wrong >= 2 && newStreak >= 3);
    return QuestionStat(
      setId: setId ?? this.setId,
      attempts: attempts + 1,
      correct: correct + (isCorrect ? 1 : 0),
      streak: newStreak,
      missStreak: isCorrect ? 0 : missStreak + 1,
      lastDay: day,
      totalMs: totalMs + max(0, elapsedMs),
      box: newBox,
      dueDay: day + intervals[newBox],
      overcome: nowOvercome,
      category: category ?? this.category,
    );
  }

  /// 保存用の短い形（問題数が増えても小さく保つ）
  List<Object> toList() => [
        setId,
        attempts,
        correct,
        streak,
        missStreak,
        lastDay,
        totalMs,
        box,
        dueDay,
        overcome ? 1 : 0,
        if (category.isNotEmpty) category,
      ];

  factory QuestionStat.fromList(List<dynamic> v) {
    int n(int i) => i < v.length ? (v[i] as num).toInt() : 0;
    return QuestionStat(
      setId: v.isEmpty ? '' : v[0] as String,
      attempts: n(1),
      correct: n(2),
      streak: n(3),
      missStreak: n(4),
      lastDay: n(5),
      totalMs: n(6),
      box: n(7),
      dueDay: n(8),
      overcome: n(9) == 1,
      category: v.length > 10 ? v[10] as String : '',
    );
  }
}
