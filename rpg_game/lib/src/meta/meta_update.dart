import '../learning/learning_record.dart';
import '../models/rpg_progress.dart';
import 'achievements.dart';
import 'journal.dart';
import 'quests.dart';

/// 1回のバトルを、学習記録・冒険の記録・デイリークエスト・実績にまとめて反映した結果
class MetaUpdate {
  const MetaUpdate({
    required this.record,
    required this.journal,
    required this.newAchievements,
    required this.completedQuests,
  });

  final LearningRecord record;
  final PlayerJournal journal;

  /// このバトルで新しく解除した実績
  final List<AchievementDef> newAchievements;

  /// このバトルで達成したデイリークエスト（報酬はまだ受け取っていない）
  final List<QuestDef> completedQuests;

  /// バトルの結果を反映する。
  ///
  /// 確認用のバトル（[BattleMode.trial] 以外で [events] が空のものも含む）は、
  /// 図鑑やクエストを進めない。学習記録（正誤）は、確認用でなければ残す。
  static MetaUpdate apply({
    required LearningRecord record,
    required PlayerJournal journal,
    required RpgProgress progress,
    required Iterable<AnswerEvent> events,
    required BattleReport report,
    required int day,
    required Map<String, String> subjects,
  }) {
    if (report.mode == BattleMode.trial) {
      return MetaUpdate(
        record: record,
        journal: journal,
        newAchievements: const [],
        completedQuests: const [],
      );
    }
    final nextRecord =
        events.isEmpty ? record : record.recordAll(events, day: day);
    var nextJournal = journal.applyBattle(report);

    final quests = DailyQuests.forDay(day, subjects);
    final before =
        journal.quest.day == day ? journal.quest : QuestState(day: day);
    final after = DailyQuests.apply(before, day, quests, report);
    nextJournal = nextJournal.copyWith(quest: after);
    final completed = [
      for (final q in quests)
        if (!DailyQuests.isDone(before, q) && DailyQuests.isDone(after, q)) q,
    ];

    final unlocked = Achievements.newlyAchieved(
      AchievementContext(
        progress: progress,
        record: nextRecord,
        journal: nextJournal,
        today: day,
      ),
    );
    if (unlocked.isNotEmpty) {
      nextJournal = nextJournal.unlock(unlocked.map((a) => a.id), day);
    }
    return MetaUpdate(
      record: nextRecord,
      journal: nextJournal,
      newAchievements: unlocked,
      completedQuests: completed,
    );
  }
}
