import 'dart:math';

import 'journal.dart';

enum QuestKind {
  /// 教科で N 問正解する
  correctInSubject,

  /// 教科のバトルで N 問連続正解する
  comboInSubject,

  /// バトルに N 回勝つ
  winBattles,

  /// 復習の塔で N 問正解する
  reviewCorrect,

  /// ボスを倒す
  defeatBoss,

  /// 定期テストの海で N 問正解する
  seaCorrect,
}

/// デイリークエスト
class QuestDef {
  const QuestDef({
    required this.id,
    required this.kind,
    required this.title,
    required this.goal,
    required this.rewardExp,
    this.subject,
    this.subjectName,
  });

  final String id;
  final QuestKind kind;
  final String title;
  final int goal;
  final int rewardExp;

  /// 対象の教科（ワールド ID）
  final String? subject;
  final String? subjectName;
}

/// その日のクエストを決め、進み具合を数える。
///
/// 同じ日なら、いつ開いても同じクエストになる（日付を種にした乱数）。
/// 教科は、遊べるワールドの中から選ぶ。
class DailyQuests {
  const DailyQuests._();

  static List<QuestDef> forDay(
    int day,
    Map<String, String> subjects, // worldId → 教科名
  ) {
    final rng = Random(day * 7919 + 17);
    final ids = subjects.keys.toList()..sort();
    if (ids.isEmpty) return const [];
    final a = ids[rng.nextInt(ids.length)];
    final b = ids[rng.nextInt(ids.length)];
    final third = [
      QuestDef(
        id: 'd$day-review',
        kind: QuestKind.reviewCorrect,
        title: '復習の塔で 8 問正解する',
        goal: 8,
        rewardExp: 40,
      ),
      QuestDef(
        id: 'd$day-boss',
        kind: QuestKind.defeatBoss,
        title: 'ボスを 1 体倒す',
        goal: 1,
        rewardExp: 50,
      ),
      QuestDef(
        id: 'd$day-sea',
        kind: QuestKind.seaCorrect,
        title: '定期テストの海で 10 問正解する',
        goal: 10,
        rewardExp: 45,
      ),
      QuestDef(
        id: 'd$day-win',
        kind: QuestKind.winBattles,
        title: 'バトルに 3 回勝つ',
        goal: 3,
        rewardExp: 35,
      ),
    ][rng.nextInt(4)];
    final combo = 3 + rng.nextInt(3);
    return [
      QuestDef(
        id: 'd$day-correct-$a',
        kind: QuestKind.correctInSubject,
        title: '${subjects[a]}で 15 問正解する',
        goal: 15,
        rewardExp: 30,
        subject: a,
        subjectName: subjects[a],
      ),
      QuestDef(
        id: 'd$day-combo-$b',
        kind: QuestKind.comboInSubject,
        title: '${subjects[b]}のバトルで $combo 問連続正解する',
        goal: combo,
        rewardExp: 35,
        subject: b,
        subjectName: subjects[b],
      ),
      third,
    ];
  }

  /// バトルの報告から、その日のクエストを進める
  static QuestState apply(
    QuestState state,
    int day,
    List<QuestDef> quests,
    BattleReport r,
  ) {
    var s = state.day == day ? state : QuestState(day: day);
    if (r.mode == BattleMode.trial) return s;
    final p = Map<String, int>.of(s.progress);
    for (final q in quests) {
      final now = p[q.id] ?? 0;
      int next = now;
      switch (q.kind) {
        case QuestKind.correctInSubject:
          if (q.subject == r.subject) next = now + r.correct;
        case QuestKind.comboInSubject:
          if (q.subject == r.subject) next = max(now, r.maxCombo);
        case QuestKind.winBattles:
          if (r.won) next = now + 1;
        case QuestKind.reviewCorrect:
          if (r.mode == BattleMode.review) next = now + r.correct;
        case QuestKind.defeatBoss:
          if (r.won && r.isBoss) next = now + 1;
        case QuestKind.seaCorrect:
          if (r.mode == BattleMode.sea) next = now + r.correct;
      }
      p[q.id] = min(next, q.goal);
    }
    return QuestState(day: day, progress: p, claimed: s.claimed);
  }

  static bool isDone(QuestState s, QuestDef q) =>
      (s.progress[q.id] ?? 0) >= q.goal;
}
