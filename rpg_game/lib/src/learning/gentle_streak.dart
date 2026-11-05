import 'dart:math';

/// ゆるい連続記録（やりすぎない Duolingo 風）。
///
/// - 勉強した日（RPG・単語帳のどちらでも）が続くと連続日数が伸びる
/// - **お休み券**：休んだ日に自動で使われ、連続が切れない（数えるのは勉強した日だけ）
///   7日続けるごとに1枚もらえて、2枚まで持てる
/// - 券がなくて切れても、責めない。また1日目から
///
/// 日は [dayNumber]（UTC の通算日）で数える。
class GentleStreak {
  const GentleStreak({
    this.tickets = 0,
    this.restDays = const {},
    this.awardedAt = const {},
  });

  /// 持っているお休み券
  final int tickets;

  /// お休み券を使った日
  final Set<int> restDays;

  /// お休み券をもらったときの連続日数（同じ節目で2回もらわない）
  final Set<int> awardedAt;

  static const maxTickets = 2;

  /// 何日続けると1枚もらえるか
  static const awardEvery = 7;

  /// 連続日数（勉強した日だけを数える。お休み券の日はつなぐだけ）。
  /// 今日まだ勉強していなくても、昨日まで続いていれば数える
  int length(Set<int> studyDays, int today) {
    var d = studyDays.contains(today) ? today : today - 1;
    var n = 0;
    while (true) {
      if (studyDays.contains(d)) {
        n++;
      } else if (!restDays.contains(d)) {
        break;
      }
      d--;
    }
    return n;
  }

  /// 休んだ日にお休み券を使い、節目でお休み券を渡す。
  /// アプリを開いたときや、勉強したあとに呼ぶ
  (GentleStreak, StreakNews) settle(Set<int> studyDays, int today) {
    var tickets = this.tickets;
    final rest = {...restDays};
    final awarded = {...awardedAt};
    var used = 0;
    // 昨日までの休んだ日を、前の連続がある場合だけ券でつなぐ（古いほうから）
    final last = studyDays.isEmpty ? null : studyDays.reduce(max);
    if (last != null && last < today - 1) {
      final gap = [for (var d = last + 1; d < today; d++) d];
      if (gap.length <= tickets) {
        for (final d in gap) {
          if (rest.add(d)) {
            tickets--;
            used++;
          }
        }
      }
    }
    final next0 = GentleStreak(
      tickets: tickets,
      restDays: rest,
      awardedAt: awarded,
    );
    // 節目（7日・14日…）でお休み券
    final len = next0.length(studyDays, today);
    var earned = 0;
    for (var m = awardEvery; m <= len; m += awardEvery) {
      if (awarded.add(_milestoneKey(studyDays, today, m, next0))) {
        if (tickets < maxTickets) {
          tickets++;
          earned++;
        }
      }
    }
    // 古いお休みの記録は捨てる（1年分だけ残す）
    rest.removeWhere((d) => d < today - 366);
    awarded.removeWhere((k) => k < today - 366);
    return (
      GentleStreak(tickets: tickets, restDays: rest, awardedAt: awarded),
      StreakNews(used: used, earned: earned),
    );
  }

  /// 節目を一意にする鍵：その連続が m 日目になった日
  static int _milestoneKey(
    Set<int> studyDays,
    int today,
    int m,
    GentleStreak s,
  ) {
    var d = studyDays.contains(today) ? today : today - 1;
    // 連続の始まりを探す
    final days = <int>[];
    while (true) {
      if (studyDays.contains(d)) {
        days.add(d);
      } else if (!s.restDays.contains(d)) {
        break;
      }
      d--;
    }
    // days は新しい順。m 日目の日
    return days.length >= m ? days[days.length - m] : today;
  }

  Map<String, Object?> toMap() => {
        't': tickets,
        'r': restDays.toList()..sort(),
        'a': awardedAt.toList()..sort(),
      };

  factory GentleStreak.fromMap(Object? m) {
    if (m is! Map) return const GentleStreak();
    Set<int> ints(Object? v) => {
          if (v is List)
            for (final e in v)
              if (e is num) e.toInt(),
        };
    final t = m['t'];
    return GentleStreak(
      tickets: t is num ? t.toInt().clamp(0, maxTickets) : 0,
      restDays: ints(m['r']),
      awardedAt: ints(m['a']),
    );
  }
}

/// 連続記録の知らせ（画面に出す）
class StreakNews {
  const StreakNews({this.used = 0, this.earned = 0});

  /// 休んだ日に使ったお休み券の数
  final int used;

  /// もらったお休み券の数
  final int earned;

  bool get isEmpty => used == 0 && earned == 0;
}
