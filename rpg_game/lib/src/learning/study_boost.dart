import 'dart:math';

import '../meta/study_log.dart';
import 'learning_record.dart';
import 'question_stat.dart';
import 'review_planner.dart';

/// 気軽に始めるための練習（「1分だけ」「おかえり」「まぜて練習」）
class StudyBoost {
  const StudyBoost._();

  /// これ以上あいたら「おかえり」を出す（日）
  static const welcomeGap = 3;

  /// 「1分だけ」の問題数
  static const oneMinuteCount = 5;

  /// 「おかえり」「まぜて練習」の問題数
  static const sessionCount = 10;

  /// 最後に問題を解いた日（まだなら null）
  static int? lastDay(LearningRecord record) {
    int? last;
    for (final s in record.stats.values) {
      if (s.attempts == 0) continue;
      if (last == null || s.lastDay > last) last = s.lastDay;
    }
    return last;
  }

  /// 何日ぶりか（まだ解いていなければ 0）
  static int daysAway(LearningRecord record, int today) {
    final last = lastDay(record);
    return last == null ? 0 : today - last;
  }

  /// 答えたことのある問題を、復習の優先度の高い順に
  static List<ReviewItem> _ranked(
    LearningRecord record,
    int today, {
    String? subject,
  }) {
    final items = [
      for (final e in record.stats.entries)
        if (e.value.setId.isNotEmpty &&
            e.value.attempts > 0 &&
            (subject == null ||
                LearningRecord.subjectOf(e.value.setId) == subject))
          ReviewItem(
            questionId: e.key,
            setId: e.value.setId,
            reason: ReviewPlanner.reasonOf(e.value, today),
            priority: ReviewPlanner.priorityOf(e.value, today),
          ),
    ]..sort((a, b) => b.priority.compareTo(a.priority));
    return items;
  }

  static List<ReviewItem> _fill(
    List<ReviewItem> first,
    List<ReviewItem> rest,
    int limit,
  ) {
    final ids = {for (final i in first) i.questionId};
    return [
      ...first,
      for (final i in rest)
        if (ids.add(i.questionId)) i,
    ].take(limit).toList();
  }

  /// ひさしぶりに来たときの、やさしい復習（[welcomeGap] 日未満なら空）
  static List<ReviewItem> welcomeBack(LearningRecord record, int today) {
    if (daysAway(record, today) < welcomeGap) return const [];
    return _fill(
      ReviewPlanner.plan(record, today: today, limit: sessionCount),
      _ranked(record, today),
      sessionCount,
    );
  }

  /// 「1分だけ」：復習の優先度が高い問題を少しだけ
  static List<ReviewItem> oneMinute(LearningRecord record, int today) =>
      _ranked(record, today).take(oneMinuteCount).toList();

  /// 問題の単元（記録に単元がなければ問題セット）
  static String _unitOf(QuestionStat s) => s.unit.isEmpty ? s.setId : s.unit;

  /// まぜて練習できる教科（答えた単元が2つ以上ある教科）
  static List<String> mixSubjects(LearningRecord record) {
    final units = <String, Set<String>>{};
    for (final s in record.stats.values) {
      if (s.setId.isEmpty || s.attempts == 0) continue;
      (units[LearningRecord.subjectOf(s.setId)] ??= {}).add(_unitOf(s));
    }
    return [
      for (final e in units.entries)
        if (e.value.length >= 2) e.key,
    ];
  }

  /// まぜて練習：その教科で答えた単元を交互に出す（同じ単元が続かないように）。
  /// 単元が2つ未満なら空
  static List<ReviewItem> mix(
    LearningRecord record,
    String subject, {
    required int today,
    int limit = sessionCount,
    Random? random,
  }) {
    final byUnit = <String, List<ReviewItem>>{};
    for (final item in _ranked(record, today, subject: subject)) {
      final s = record.stats[item.questionId]!;
      (byUnit[_unitOf(s)] ??= []).add(item);
    }
    if (byUnit.length < 2) return const [];
    final units = byUnit.values.toList()..shuffle(random ?? Random());
    final out = <ReviewItem>[];
    for (var round = 0; out.length < limit; round++) {
      var added = false;
      for (final u in units) {
        if (round < u.length && out.length < limit) {
          out.add(u[round]);
          added = true;
        }
      }
      if (!added) break;
    }
    return out;
  }
}

/// 週1ふりかえり：この1週間と、その前の1週間をくらべる
class WeeklyReflection {
  const WeeklyReflection({
    required this.thisWeek,
    required this.lastWeek,
    required this.daysStudied,
    this.bestSubject,
  });

  final StudyDay thisWeek;
  final StudyDay lastWeek;

  /// この1週間で勉強した日数（0〜7）
  final int daysStudied;

  /// この1週間でいちばん時間をかけた教科（ワールド ID）
  final String? bestSubject;

  /// 先週とくらべた時間の差（分）
  int get deltaMinutes => thisWeek.minutes - lastWeek.minutes;

  /// 2週間とも何もしていなければ null
  static WeeklyReflection? of(StudyLog log, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime back(int n) => DateTime(today.year, today.month, today.day - n);
    final thisWeek = log.total(from: back(6), to: today);
    final lastWeek = log.total(from: back(13), to: back(7));
    if (thisWeek.answered == 0 &&
        thisWeek.seconds == 0 &&
        lastWeek.answered == 0 &&
        lastWeek.seconds == 0) {
      return null;
    }
    var days = 0;
    final bySubject = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final day = log.on(back(i));
      if (day.isNotEmpty) days++;
      for (final e in day.entries) {
        bySubject[e.key] = (bySubject[e.key] ?? 0) + e.value.seconds;
      }
    }
    String? best;
    var top = 0;
    bySubject.forEach((k, v) {
      if (v > top) {
        best = k;
        top = v;
      }
    });
    return WeeklyReflection(
      thisWeek: thisWeek,
      lastWeek: lastWeek,
      daysStudied: days,
      bestSubject: best,
    );
  }
}
