import '../learning/learning_record.dart';
import '../models/rpg_progress.dart';
import '../story/scenes.dart';
import '../story/story.dart';
import '../versus/versus_match.dart';
import '../world/elites.dart';
import 'enemy_species.dart';
import 'journal.dart';

/// 実績の判定に使う情報
class AchievementContext {
  const AchievementContext({
    required this.progress,
    required this.record,
    required this.journal,
    required this.today,
  });

  final RpgProgress progress;
  final LearningRecord record;
  final PlayerJournal journal;
  final int today;
}

enum AchievementGroup {
  battle('戦い'),
  learning('学び'),
  habit('習慣'),
  collection('収集');

  const AchievementGroup(this.label);
  final String label;
}

/// 実績。解除すると、その名前を称号として使える。
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.group,
    required this.rarity,
    required this.goal,
    required this.value,
  });

  final String id;

  /// 実績名（＝称号）
  final String title;
  final String description;
  final AchievementGroup group;
  final Rarity rarity;

  /// 目標の値
  final int goal;

  /// 現在の値
  final int Function(AchievementContext c) value;

  bool achieved(AchievementContext c) => value(c) >= goal;
}

class Achievements {
  const Achievements._();

  static int _subjectsAtLevel(AchievementContext c, int level) => [
        'english',
        'science',
        'social',
        'japanese',
        'math',
        'information',
      ].where((s) => c.record.subjectLevel(s) >= level).length;

  static final all = <AchievementDef>[
    AchievementDef(
      id: 'first_win',
      title: 'はじめの一歩',
      description: 'バトルに1回勝つ',
      group: AchievementGroup.battle,
      rarity: Rarity.common,
      goal: 1,
      value: (c) => c.journal.wins,
    ),
    AchievementDef(
      id: 'wins_50',
      title: '歴戦の学徒',
      description: 'バトルに50回勝つ',
      group: AchievementGroup.battle,
      rarity: Rarity.rare,
      goal: 50,
      value: (c) => c.journal.wins,
    ),
    AchievementDef(
      id: 'boss_1',
      title: '番人をこえし者',
      description: 'ボスを1体倒す',
      group: AchievementGroup.battle,
      rarity: Rarity.rare,
      goal: 1,
      value: (c) => c.journal.bossKills,
    ),
    AchievementDef(
      id: 'boss_10',
      title: 'ボスハンター',
      description: 'ボスを10体倒す',
      group: AchievementGroup.battle,
      rarity: Rarity.epic,
      goal: 10,
      value: (c) => c.journal.bossKills,
    ),
    AchievementDef(
      id: 'perfect_1',
      title: 'ノーミス',
      description: '1問もまちがえずにバトルに勝つ',
      group: AchievementGroup.battle,
      rarity: Rarity.rare,
      goal: 1,
      value: (c) => c.journal.perfects,
    ),
    AchievementDef(
      id: 'sea_win',
      title: '荒波の勝者',
      description: '定期テストの海の魔物を倒す',
      group: AchievementGroup.battle,
      rarity: Rarity.epic,
      goal: 1,
      value: (c) => c.journal.seaWins,
    ),
    AchievementDef(
      id: 'correct_100',
      title: '百問の旅人',
      description: '合計100問正解する',
      group: AchievementGroup.learning,
      rarity: Rarity.common,
      goal: 100,
      value: (c) => c.record.totalCorrect(),
    ),
    AchievementDef(
      id: 'correct_1000',
      title: '千問の賢者',
      description: '合計1000問正解する',
      group: AchievementGroup.learning,
      rarity: Rarity.epic,
      goal: 1000,
      value: (c) => c.record.totalCorrect(),
    ),
    AchievementDef(
      id: 'mastered_30',
      title: '身についた！',
      description: '30問を習得する（間隔をあけて3回以上正解）',
      group: AchievementGroup.learning,
      rarity: Rarity.rare,
      goal: 30,
      value: (c) => c.record.masteredCount(),
    ),
    AchievementDef(
      id: 'mastered_300',
      title: '知識の守り手',
      description: '300問を習得する',
      group: AchievementGroup.learning,
      rarity: Rarity.epic,
      goal: 300,
      value: (c) => c.record.masteredCount(),
    ),
    AchievementDef(
      id: 'mastered_1000',
      title: '生きた百科事典',
      description: '1000問を習得する',
      group: AchievementGroup.learning,
      rarity: Rarity.legendary,
      goal: 1000,
      value: (c) => c.record.masteredCount(),
    ),
    AchievementDef(
      id: 'overcome_1',
      title: '苦手を乗りこえて',
      description: '2回以上まちがえた問題を、3回連続で正解する',
      group: AchievementGroup.learning,
      rarity: Rarity.rare,
      goal: 1,
      value: (c) => c.record.overcomeCount(),
    ),
    AchievementDef(
      id: 'overcome_20',
      title: '逆転の達人',
      description: '苦手を20問克服する',
      group: AchievementGroup.learning,
      rarity: Rarity.epic,
      goal: 20,
      value: (c) => c.record.overcomeCount(),
    ),
    AchievementDef(
      id: 'review_50',
      title: '塔の常連',
      description: '復習の塔で50問正解する',
      group: AchievementGroup.learning,
      rarity: Rarity.rare,
      goal: 50,
      value: (c) => c.journal.reviewCorrect,
    ),
    AchievementDef(
      id: 'multi_subject',
      title: '三刀流',
      description: '3つの教科で教科レベル3以上になる',
      group: AchievementGroup.learning,
      rarity: Rarity.epic,
      goal: 3,
      value: (c) => _subjectsAtLevel(c, 3),
    ),
    AchievementDef(
      id: 'streak_3',
      title: '三日坊主こえ',
      description: '3日続けて勉強する',
      group: AchievementGroup.habit,
      rarity: Rarity.common,
      goal: 3,
      value: (c) => c.record.streakDays(c.today),
    ),
    AchievementDef(
      id: 'streak_7',
      title: '一週間の探究者',
      description: '7日続けて勉強する',
      group: AchievementGroup.habit,
      rarity: Rarity.rare,
      goal: 7,
      value: (c) => c.record.streakDays(c.today),
    ),
    AchievementDef(
      id: 'streak_30',
      title: '継続は力なり',
      description: '30日続けて勉強する',
      group: AchievementGroup.habit,
      rarity: Rarity.legendary,
      goal: 30,
      value: (c) => c.record.streakDays(c.today),
    ),
    AchievementDef(
      id: 'level_10',
      title: '見習い冒険者',
      description: 'プレイヤーレベル10になる',
      group: AchievementGroup.habit,
      rarity: Rarity.common,
      goal: 10,
      value: (c) => c.progress.level,
    ),
    AchievementDef(
      id: 'level_30',
      title: '一人前の冒険者',
      description: 'プレイヤーレベル30になる',
      group: AchievementGroup.habit,
      rarity: Rarity.epic,
      goal: 30,
      value: (c) => c.progress.level,
    ),
    AchievementDef(
      id: 'grammar_100',
      title: '文法ハンター',
      description: '文法・語法の問題に100問正解する',
      group: AchievementGroup.learning,
      rarity: Rarity.rare,
      goal: 100,
      value: (c) => c.record.stats.values
          .where((s) => s.category == 'usage')
          .fold(0, (a, s) => a + s.correct),
    ),
    AchievementDef(
      id: 'review_500',
      title: '復習の鬼',
      description: '復習の塔で500問正解する',
      group: AchievementGroup.learning,
      rarity: Rarity.legendary,
      goal: 500,
      value: (c) => c.journal.reviewCorrect,
    ),
    AchievementDef(
      id: 'all_subjects',
      title: '知識の探究者',
      description: '6教科すべての問題に答える',
      group: AchievementGroup.learning,
      rarity: Rarity.rare,
      goal: 6,
      value: (c) => {
        for (final s in c.record.stats.values)
          if (s.setId.isNotEmpty) LearningRecord.subjectOf(s.setId),
      }.length,
    ),
    AchievementDef(
      id: 'english_clear',
      title: '英語の旅人',
      description: '英語ワールドで「ことばの欠片」を取りもどす',
      group: AchievementGroup.battle,
      rarity: Rarity.epic,
      goal: 1,
      value: (c) => Story.fragments(c.progress).contains('english') ? 1 : 0,
    ),
    AchievementDef(
      id: 'fragments_6',
      title: '世界をつなぐ者',
      description: '6つの知識の欠片をすべて取りもどす',
      group: AchievementGroup.collection,
      rarity: Rarity.legendary,
      goal: 6,
      value: (c) => Story.fragments(c.progress).length,
    ),
    AchievementDef(
      id: 'world_center',
      title: '忘却をこえし者',
      description: '世界の中心で、忘却の魔王をたおす',
      group: AchievementGroup.battle,
      rarity: Rarity.legendary,
      goal: 1,
      value: (c) =>
          c.progress.clearedStageIds.contains(Story.centerStageId) ? 1 : 0,
    ),
    AchievementDef(
      id: 'elite_1',
      title: '強敵ハンター',
      description: 'フィールドの強敵を1体たおす',
      group: AchievementGroup.battle,
      rarity: Rarity.common,
      goal: 1,
      value: (c) => c.progress.clearedStageIds.where(Elites.isElite).length,
    ),
    AchievementDef(
      id: 'elite_10',
      title: '強敵キラー',
      description: 'フィールドの強敵を10体たおす',
      group: AchievementGroup.battle,
      rarity: Rarity.epic,
      goal: 10,
      value: (c) => c.progress.clearedStageIds.where(Elites.isElite).length,
    ),
    AchievementDef(
      id: 'explorer_5',
      title: '探検家',
      description: '隠し通路や知識の扉を5か所ひらく',
      group: AchievementGroup.collection,
      rarity: Rarity.rare,
      goal: 5,
      value: (c) =>
          c.progress.fieldFlags.where((f) => f.startsWith('open:')).length,
    ),
    AchievementDef(
      id: 'warp_10',
      title: 'ワープの達人',
      description: 'ワープ石を10個光らせる',
      group: AchievementGroup.collection,
      rarity: Rarity.common,
      goal: 10,
      value: (c) =>
          c.progress.fieldFlags.where((f) => f.startsWith('warp:')).length,
    ),
    AchievementDef(
      id: 'bestiary_10',
      title: '文房具博士の卵',
      description: '10種類の敵を図鑑に登録する',
      group: AchievementGroup.collection,
      rarity: Rarity.rare,
      goal: 10,
      value: (c) => c.journal.seenLooks.length,
    ),
    AchievementDef(
      id: 'bestiary_all',
      title: '文房具博士',
      description: 'すべての種族を倒して図鑑を完成させる',
      group: AchievementGroup.collection,
      rarity: Rarity.legendary,
      goal: EnemySpeciesCatalog.all.length,
      value: (c) => EnemySpeciesCatalog.all
          .where((s) => (c.journal.defeatedLooks[s.look] ?? 0) > 0)
          .length,
    ),
    AchievementDef(
      id: 'special_hit',
      title: '必殺の一撃',
      description: 'バトルで必殺技を決める',
      group: AchievementGroup.battle,
      rarity: Rarity.common,
      goal: 1,
      value: (c) => _flag(c, VersusRecords.specialHit),
    ),
    AchievementDef(
      id: 'versus_played',
      title: '好敵手',
      description: '対戦モードで、最後まで対戦する',
      group: AchievementGroup.battle,
      rarity: Rarity.common,
      goal: 1,
      value: (c) => _flag(c, VersusRecords.played),
    ),
    AchievementDef(
      id: 'versus_hard',
      title: 'はやおし名人',
      description: '対戦モードで、CPU の「つよい」以上に勝つ',
      group: AchievementGroup.battle,
      rarity: Rarity.rare,
      goal: 1,
      value: (c) => _flag(c, VersusRecords.beatHard),
    ),
    AchievementDef(
      id: 'versus_master',
      title: 'はやおしの達人',
      description: '対戦モードで、CPU の「達人」に勝つ',
      group: AchievementGroup.battle,
      rarity: Rarity.epic,
      goal: 1,
      value: (c) => _flag(c, VersusRecords.beatMaster),
    ),
    AchievementDef(
      id: 'versus_online',
      title: 'ネットの向こうの好敵手',
      description: 'オンライン対戦で勝つ',
      group: AchievementGroup.battle,
      rarity: Rarity.rare,
      goal: 1,
      value: (c) => _flag(c, VersusRecords.onlineWin),
    ),
    AchievementDef(
      id: 'story_all',
      title: '物語の語り手',
      description: '物語の場面をすべて読む',
      group: AchievementGroup.collection,
      rarity: Rarity.epic,
      goal: StoryScenes.all.length,
      value: (c) => StoryScenes.unlocked(c.progress).length,
    ),
  ];

  static int _flag(AchievementContext c, String flag) =>
      c.progress.fieldFlags.contains(flag) ? 1 : 0;

  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// まだ解除していないが、条件を満たした実績
  static List<AchievementDef> newlyAchieved(AchievementContext c) => [
        for (final a in all)
          if (!c.journal.achievements.containsKey(a.id) && a.achieved(c)) a,
      ];
}
