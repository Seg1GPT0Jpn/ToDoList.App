import 'dart:math';

import 'question_stat.dart';

/// 1回答えた結果（記録の差分）
class AnswerEvent {
  const AnswerEvent({
    required this.questionId,
    required this.setId,
    required this.isCorrect,
    required this.elapsedMs,
    this.category,
    this.unit,
    this.profile,
  });

  /// 問題の性質（[AnswerProfile.code]。成長の見える化に使う）
  final int? profile;

  /// 学習体系の単元・小単元（QuizQuestion.unit）
  final String? unit;

  /// 問題の種類（文法・意味・読解など。学習ステータスの分野分けに使う）
  final String? category;

  final String questionId;
  final String setId;
  final bool isCorrect;
  final int elapsedMs;
}

/// 学習記録の全体。問題ごとの記録と、勉強した日。
///
/// 保存先は進行状況とは別（Firestore なら users/{uid}/rpg_learning/main）。
class LearningRecord {
  const LearningRecord({this.stats = const {}, this.studyDays = const {}});

  static const empty = LearningRecord();

  final Map<String, QuestionStat> stats;

  /// 1問以上答えた日
  final Set<int> studyDays;

  QuestionStat? operator [](String questionId) => stats[questionId];

  /// 答えを記録した新しい記録を返す
  LearningRecord recordAll(Iterable<AnswerEvent> events, {required int day}) {
    if (events.isEmpty) return this;
    final next = Map<String, QuestionStat>.of(stats);
    for (final e in events) {
      final before = next[e.questionId] ?? const QuestionStat();
      next[e.questionId] = before.record(
        isCorrect: e.isCorrect,
        day: day,
        elapsedMs: e.elapsedMs,
        setId: e.setId,
        category: e.category,
        unit: e.unit,
        profile: e.profile,
      );
    }
    return LearningRecord(stats: next, studyDays: {...studyDays, day});
  }

  /// 単元が空の記録の問題 ID（マイグレーションで補う対象）
  Iterable<String> get missingUnits =>
      stats.entries.where((e) => e.value.unit.isEmpty).map((e) => e.key);

  /// 問題 ID → 単元 の対応で、空の単元を補った記録を返す（古い記録の移行）
  LearningRecord withUnits(Map<String, String> unitOf) {
    if (unitOf.isEmpty) return this;
    var changed = false;
    final next = Map<String, QuestionStat>.of(stats);
    for (final e in stats.entries) {
      final u = unitOf[e.key];
      if (e.value.unit.isEmpty && u != null && u.isNotEmpty) {
        next[e.key] = e.value.withUnit(u);
        changed = true;
      }
    }
    return changed ? LearningRecord(stats: next, studyDays: studyDays) : this;
  }

  /// 教科（ワールド ID）。定期テストの海の英語（sea_…）は英語にまとめる
  static String subjectOf(String setId) {
    final w = setId.split('_').first;
    return const {'sea', 'words', 'idioms'}.contains(w) ? 'english' : w;
  }

  Iterable<QuestionStat> _of(String? subject) => subject == null
      ? stats.values
      : stats.values.where((s) => subjectOf(s.setId) == subject);

  int answeredCount([String? subject]) => _of(subject).length;
  int masteredCount([String? subject]) =>
      _of(subject).where((s) => s.mastered).length;
  int overcomeCount() => stats.values.where((s) => s.overcome).length;
  int totalAnswers() => stats.values.fold(0, (a, s) => a + s.attempts);
  int totalCorrect() => stats.values.fold(0, (a, s) => a + s.correct);

  /// 問題セットごとの習得数
  int masteredInSet(String setId) =>
      stats.values.where((s) => s.setId == setId && s.mastered).length;

  /// 教科レベル：習得した問題数から決まる（勉強した量ではなく、できるようになった量）
  static int levelFor(int mastered) => 1 + sqrt(mastered / 2).floor();

  /// 次の教科レベルに必要な習得数
  static int masteredForLevel(int level) => 2 * (level - 1) * (level - 1);

  int subjectLevel(String subject) => levelFor(masteredCount(subject));

  /// 連続学習日数（今日か昨日まで続いていれば数える）
  int streakDays(int today) {
    var d = studyDays.contains(today) ? today : today - 1;
    var n = 0;
    while (studyDays.contains(d)) {
      n++;
      d--;
    }
    return n;
  }

  Map<String, dynamic> toMap() => {
        'v': 1,
        'stats': {for (final e in stats.entries) e.key: e.value.toList()},
        'days': studyDays.toList()..sort(),
      };

  factory LearningRecord.fromMap(Map<String, dynamic> map) {
    final raw = (map['stats'] as Map?) ?? const {};
    return LearningRecord(
      stats: {
        for (final e in raw.entries)
          e.key as String: QuestionStat.fromList(e.value as List),
      },
      studyDays: {
        for (final d in (map['days'] as List?) ?? const []) (d as num).toInt(),
      },
    );
  }
}
