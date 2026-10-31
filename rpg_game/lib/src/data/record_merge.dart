import 'dart:convert';
import 'dart:math';

import '../learning/learning_record.dart';
import '../learning/question_stat.dart';
import '../meta/journal.dart';
import '../models/rpg_progress.dart';
import '../study/school_lesson.dart';

/// 2つの端末・2つのアプリ（つづりクエストとつづりクエストLight）の記録を1つにまとめる。
///
/// どちらで勉強しても記録が消えないように、「進んだ方」「多い方」を残す。
/// 同じものを何度まとめても結果は変わらない（何度同期しても増えたり減ったりしない）。
class RecordMerge {
  const RecordMerge._();

  /// 保存する形（toMap）が同じ中身か。Map のキーの順・集合の並びのちがいは気にしない
  static bool same(Object? a, Object? b) =>
      jsonEncode(_canon(a)) == jsonEncode(_canon(b));

  static Object? _canon(Object? v) {
    if (v is Map) {
      final keys = [for (final k in v.keys) '$k']..sort();
      return {for (final k in keys) k: _canon(v[k])};
    }
    if (v is Iterable) {
      final list = [for (final e in v) _canon(e)];
      final texts = [for (final e in list) jsonEncode(e)]..sort();
      return texts;
    }
    return v;
  }

  /// 学習記録：問題ごとに、答えた回数の多い方（同じなら最後に答えた日の新しい方）
  static LearningRecord learning(LearningRecord a, LearningRecord b) {
    if (identical(a, b)) return a;
    final stats = Map<String, QuestionStat>.of(a.stats);
    for (final e in b.stats.entries) {
      final mine = stats[e.key];
      if (mine == null || _newer(e.value, mine)) stats[e.key] = e.value;
    }
    return LearningRecord(
      stats: stats,
      studyDays: {...a.studyDays, ...b.studyDays},
    );
  }

  static bool _newer(QuestionStat x, QuestionStat y) {
    if (x.attempts != y.attempts) return x.attempts > y.attempts;
    if (x.lastDay != y.lastDay) return x.lastDay > y.lastDay;
    return x.totalMs > y.totalMs;
  }

  static Map<String, int> _maxMap(Map<String, int> a, Map<String, int> b) => {
        ...a,
        for (final e in b.entries) e.key: max(a[e.key] ?? e.value, e.value),
      };

  /// 冒険の記録：回数は多い方、実績は早く解除した日、クエストは新しい日の方
  static PlayerJournal journal(PlayerJournal a, PlayerJournal b) {
    if (identical(a, b)) return a;
    final QuestState quest;
    if (a.quest.day != b.quest.day) {
      quest = a.quest.day > b.quest.day ? a.quest : b.quest;
    } else {
      quest = QuestState(
        day: a.quest.day,
        progress: _maxMap(a.quest.progress, b.quest.progress),
        claimed: {...a.quest.claimed, ...b.quest.claimed},
      );
    }
    return PlayerJournal(
      seen: _maxMap(a.seen, b.seen),
      defeated: _maxMap(a.defeated, b.defeated),
      seenLooks: _maxMap(a.seenLooks, b.seenLooks),
      defeatedLooks: _maxMap(a.defeatedLooks, b.defeatedLooks),
      achievements: {
        ...a.achievements,
        for (final e in b.achievements.entries)
          e.key: min(a.achievements[e.key] ?? e.value, e.value),
      },
      title: a.title.isNotEmpty ? a.title : b.title,
      wins: max(a.wins, b.wins),
      bossKills: max(a.bossKills, b.bossKills),
      perfects: max(a.perfects, b.perfects),
      seaWins: max(a.seaWins, b.seaWins),
      reviewCorrect: max(a.reviewCorrect, b.reviewCorrect),
      quest: quest,
    );
  }

  /// 進行状況：レベル・経験値・デッキなどは経験値の多い方をもとにし、
  /// クリアしたステージ・宝箱・購入などは両方を合わせる
  static RpgProgress progress(RpgProgress a, RpgProgress b) {
    if (identical(a, b)) return a;
    final base = b.totalExp > a.totalExp ? b : a;
    final other = identical(base, a) ? b : a;
    final records = Map<String, StageRecord>.of(base.stageRecords);
    for (final e in other.stageRecords.entries) {
      final r = records[e.key];
      records[e.key] = r == null
          ? e.value
          : StageRecord(
              bestCorrect: max(r.bestCorrect, e.value.bestCorrect),
              bestTotal: r.bestCorrect >= e.value.bestCorrect
                  ? r.bestTotal
                  : e.value.bestTotal,
              clearCount: max(r.clearCount, e.value.clearCount),
            );
    }
    final cleared = {...base.clearedStageIds, ...other.clearedStageIds};
    return base.copyWith(
      clearedStageIds: cleared,
      stageRecords: records,
      purchasedWorldIds: {
        ...base.purchasedWorldIds,
        ...other.purchasedWorldIds
      },
      seaBest: _maxMap(base.seaBest, other.seaBest),
      mistakes: {...other.mistakes, ...base.mistakes},
      openedChests: {...base.openedChests, ...other.openedChests},
      companions: {...base.companions, ...other.companions},
      // 負けたステージも、どちらかでクリアしていれば「負けたまま」にしない
      lostStages: base.lostStages.difference(
        other.clearedStageIds.difference(base.clearedStageIds),
      ),
      gear: {...base.gear, ...other.gear},
      claimedRewards: {...base.claimedRewards, ...other.claimedRewards},
      masteryExp: _maxMap(base.masteryExp, other.masteryExp),
      masteryVersion: max(base.masteryVersion, other.masteryVersion),
    );
  }

  /// 授業の記録：読んだところ・確認テストの成績は進んだ方、日付は早く合格・習得した方
  static LessonRecord lesson(LessonRecord a, LessonRecord b) {
    int firstDay(int x, int y) => x == 0 ? y : (y == 0 ? x : min(x, y));
    final later = b.updatedDay > a.updatedDay ? b : a;
    return LessonRecord(
      lessonId: a.lessonId,
      step: max(a.step, b.step),
      viewed: a.viewed || b.viewed,
      quizAttempts: max(a.quizAttempts, b.quizAttempts),
      quizBest: max(a.quizBest, b.quizBest),
      quizLast: later.quizLast,
      quizPassedDay: firstDay(a.quizPassedDay, b.quizPassedDay),
      masteredDay: firstDay(a.masteredDay, b.masteredDay),
      understanding: later.understanding,
      updatedDay: max(a.updatedDay, b.updatedDay),
    );
  }

  /// 授業の記録の一覧（授業 ID → 記録）
  static Map<String, LessonRecord> lessons(
    Map<String, LessonRecord> a,
    Map<String, LessonRecord> b,
  ) =>
      {
        ...a,
        for (final e in b.entries)
          e.key: a[e.key] == null ? e.value : lesson(a[e.key]!, e.value),
      };
}
