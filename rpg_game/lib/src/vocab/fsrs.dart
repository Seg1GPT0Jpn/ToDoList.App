import 'dart:math';

/// 自分の手ごたえ（FSRS の評価）
enum Rating {
  /// 忘れた
  again(1, '忘れた'),

  /// 難しかった
  hard(2, '難しかった'),

  /// まあまあ
  good(3, 'まあまあ'),

  /// 簡単だった
  easy(4, '簡単だった');

  const Rating(this.grade, this.label);
  final int grade;
  final String label;
}

/// 1つの記憶（単語 × 力）の状態。
///
/// FSRS（Free Spaced Repetition Scheduler, v4.5）の
/// 「安定度 S（日）」と「難しさ D（1〜10）」で記憶を表す。
/// 安定度は「思い出せる確率が 90% まで下がるのにかかる日数」。
class MemoryState {
  const MemoryState({
    required this.stability,
    required this.difficulty,
    required this.due,
    required this.lastReview,
    this.reps = 0,
    this.lapses = 0,
    this.streak = 0,
  });

  final double stability;
  final double difficulty;

  /// 次に復習する日時
  final DateTime due;
  final DateTime lastReview;

  /// 復習した回数
  final int reps;

  /// 忘れた回数
  final int lapses;

  /// 続けて思い出せた回数
  final int streak;

  Map<String, dynamic> toJson() => {
        's': double.parse(stability.toStringAsFixed(4)),
        'd': double.parse(difficulty.toStringAsFixed(4)),
        'due': due.millisecondsSinceEpoch,
        'last': lastReview.millisecondsSinceEpoch,
        'r': reps,
        'l': lapses,
        'k': streak,
      };

  factory MemoryState.fromJson(Map<String, dynamic> j) => MemoryState(
        stability: (j['s'] as num).toDouble(),
        difficulty: (j['d'] as num).toDouble(),
        due: DateTime.fromMillisecondsSinceEpoch((j['due'] as num).toInt()),
        lastReview:
            DateTime.fromMillisecondsSinceEpoch((j['last'] as num).toInt()),
        reps: (j['r'] as num?)?.toInt() ?? 0,
        lapses: (j['l'] as num?)?.toInt() ?? 0,
        streak: (j['k'] as num?)?.toInt() ?? 0,
      );
}

/// FSRS v4.5 のスケジューラ。
///
/// 1日後・3日後・7日後…と決まった間隔ではなく、その人がどれだけ覚えているか
/// （安定度と難しさ）と、答えたときの手ごたえから次の出題日を決める。
class Fsrs {
  const Fsrs({this.desiredRetention = 0.9, this.maximumInterval = 365});

  /// 復習する日に思い出せる確率の目標
  final double desiredRetention;

  /// 最長の間隔（日）
  final int maximumInterval;

  /// FSRS v4.5 の既定の重み
  static const w = [
    0.4872, 1.4003, 3.7145, 13.8206, 5.1618, 1.2298, 0.8975, 0.031, //
    1.6474, 0.1367, 1.0461, 2.1072, 0.0793, 0.3246, 1.587, 0.2272, 2.8755,
  ];
  static const decay = -0.5;
  static const factor = 19 / 81;

  /// 「忘れた」ときに、同じ日のうちにもう一度出すまでの時間
  static const relearnDelay = Duration(minutes: 10);

  /// [elapsedDays] 日たったときに思い出せる確率
  static double retrievability(double elapsedDays, double stability) =>
      pow(1 + factor * max(0, elapsedDays) / stability, decay).toDouble();

  /// 今この瞬間に思い出せる確率
  static double retrievabilityAt(MemoryState s, DateTime now) =>
      retrievability(_days(now.difference(s.lastReview)), s.stability);

  /// 安定度から次の間隔（日）
  int intervalDays(double stability) {
    final i = stability / factor * (pow(desiredRetention, 1 / decay) - 1);
    return i.round().clamp(1, maximumInterval);
  }

  static double _initStability(Rating r) => w[r.grade - 1];

  static double _initDifficulty(Rating r) =>
      (w[4] - (r.grade - 3) * w[5]).clamp(1, 10).toDouble();

  static double _days(Duration d) => d.inSeconds / 86400;

  /// はじめて覚えたとき
  MemoryState first(Rating r, DateTime now) {
    final s = _initStability(r);
    return MemoryState(
      stability: s,
      difficulty: _initDifficulty(r),
      due: r == Rating.again ? now.add(relearnDelay) : _dueAfter(now, s),
      lastReview: now,
      reps: 1,
      lapses: r == Rating.again ? 1 : 0,
      streak: r == Rating.again ? 0 : 1,
    );
  }

  DateTime _dueAfter(DateTime now, double stability) =>
      now.add(Duration(days: intervalDays(stability)));

  /// 復習したとき
  MemoryState review(MemoryState s, Rating r, DateTime now) {
    final elapsed = _days(now.difference(s.lastReview));
    final retr = retrievability(elapsed, s.stability);
    // 難しさ：評価に応じて上げ下げし、最初の「まあまあ」の値に少し引き戻す
    var d = s.difficulty - w[6] * (r.grade - 3);
    d = w[7] * _initDifficulty(Rating.good) + (1 - w[7]) * d;
    d = d.clamp(1, 10).toDouble();

    double stability;
    if (r == Rating.again) {
      stability = w[11] *
          pow(s.difficulty, -w[12]) *
          (pow(s.stability + 1, w[13]) - 1) *
          exp(w[14] * (1 - retr));
      stability = min(stability, s.stability);
    } else {
      final hard = r == Rating.hard ? w[15] : 1.0;
      final easy = r == Rating.easy ? w[16] : 1.0;
      stability = s.stability *
          (exp(w[8]) *
                  (11 - s.difficulty) *
                  pow(s.stability, -w[9]) *
                  (exp(w[10] * (1 - retr)) - 1) *
                  hard *
                  easy +
              1);
    }
    stability = stability.clamp(0.1, 36500).toDouble();
    return MemoryState(
      stability: stability,
      difficulty: d,
      due:
          r == Rating.again ? now.add(relearnDelay) : _dueAfter(now, stability),
      lastReview: now,
      reps: s.reps + 1,
      lapses: s.lapses + (r == Rating.again ? 1 : 0),
      streak: r == Rating.again ? 0 : s.streak + 1,
    );
  }

  /// 評価ごとの次の間隔（ボタンに「2日後」などと出す用）
  Map<Rating, Duration> preview(MemoryState? s, DateTime now) => {
        for (final r in Rating.values)
          r: (s == null ? first(r, now) : review(s, r, now))
              .due
              .difference(now),
      };
}
