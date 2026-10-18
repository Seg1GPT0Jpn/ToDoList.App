/// 1日・1教科ぶんの勉強の記録
class StudyDay {
  const StudyDay({this.seconds = 0, this.answered = 0, this.correct = 0});

  /// 勉強した時間（秒）
  final int seconds;

  /// 答えた問題の数と、そのうち正解した数
  final int answered;
  final int correct;

  int get minutes => seconds ~/ 60;

  StudyDay plus(StudyDay o) => StudyDay(
        seconds: seconds + o.seconds,
        answered: answered + o.answered,
        correct: correct + o.correct,
      );

  Map<String, dynamic> toMap() => {'s': seconds, 'a': answered, 'c': correct};

  factory StudyDay.fromMap(Map<String, dynamic> m) => StudyDay(
        seconds: (m['s'] as num?)?.toInt() ?? 0,
        answered: (m['a'] as num?)?.toInt() ?? 0,
        correct: (m['c'] as num?)?.toInt() ?? 0,
      );
}

/// 日ごと・教科ごとの勉強時間と問題数（つづりへ送る勉強時間のもと）。
///
/// バトルや単語帳・暗記カードの練習が終わるたびに足していく。
/// 古い日の記録は [keepDays] 日をこえたら消す。
class StudyLog {
  const StudyLog([this.days = const {}]);

  static const empty = StudyLog();

  /// 残しておく日数
  static const keepDays = 60;

  /// 1回の練習で数える時間の上限（開いたまま放っておいた時間を数えないため）
  static const maxSecondsPerSession = 60 * 60;

  /// 日付（2026-10-18）→ 教科（ワールド ID）→ 記録
  final Map<String, Map<String, StudyDay>> days;

  static String dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// 1回ぶんを足す
  StudyLog add(
    String subject, {
    required DateTime now,
    required Duration spent,
    int answered = 0,
    int correct = 0,
  }) {
    final seconds = spent.inSeconds.clamp(0, maxSecondsPerSession).toInt();
    if (seconds == 0 && answered == 0) return this;
    final key = dayKey(now);
    final day = {...?days[key]};
    day[subject] = (day[subject] ?? const StudyDay()).plus(
      StudyDay(seconds: seconds, answered: answered, correct: correct),
    );
    final oldest = dayKey(now.subtract(const Duration(days: keepDays)));
    return StudyLog({
      for (final e in days.entries)
        if (e.key.compareTo(oldest) > 0 && e.key != key) e.key: e.value,
      key: day,
    });
  }

  /// その日の教科ごとの記録
  Map<String, StudyDay> on(DateTime day) => days[dayKey(day)] ?? const {};

  /// [from] から [to]（含む）までの合計
  StudyDay total({required DateTime from, required DateTime to}) {
    final a = dayKey(from), b = dayKey(to);
    var sum = const StudyDay();
    for (final e in days.entries) {
      if (e.key.compareTo(a) < 0 || e.key.compareTo(b) > 0) continue;
      for (final d in e.value.values) {
        sum = sum.plus(d);
      }
    }
    return sum;
  }

  Map<String, dynamic> toMap() => {
        'v': 1,
        'days': {
          for (final e in days.entries)
            e.key: {for (final s in e.value.entries) s.key: s.value.toMap()},
        },
      };

  factory StudyLog.fromMap(Map<String, dynamic> m) => StudyLog({
        for (final e in ((m['days'] as Map?) ?? const {}).entries)
          e.key as String: {
            for (final s in (e.value as Map).entries)
              s.key as String:
                  StudyDay.fromMap(Map<String, dynamic>.from(s.value as Map)),
          },
      });
}
