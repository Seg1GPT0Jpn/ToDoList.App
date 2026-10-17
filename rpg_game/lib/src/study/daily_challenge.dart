import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';

/// 今日の挑戦状：毎日1体、クリアしたエリアの中から、強化された魔物が現れる。
/// 倒すと、ふつうの3倍の経験値（1日1回）。能力は日によって変わる。
class DailyChallenge {
  const DailyChallenge._();

  static String stageId(int day) => 'daily_$day';

  /// 今日の挑戦状を倒したか
  static bool done(RpgProgress p, int day) =>
      p.clearedStageIds.contains(stageId(day));

  static const _abilities = [
    EnemyAbility.sturdy,
    EnemyAbility.combo,
    EnemyAbility.disrupt,
    EnemyAbility.chainLock,
    EnemyAbility.none,
  ];

  /// 今日の挑戦状（まだどこもクリアしていなければ null）
  static StageDef? of(RpgProgress p, int day) {
    final candidates = [
      for (final w in RpgCatalog.worlds)
        for (final s in w.stages)
          if (!s.isBoss && p.clearedStageIds.contains(s.id)) s,
    ];
    if (candidates.isEmpty) return null;
    final base = candidates[(day * 7919 + 13) % candidates.length];
    final e = base.enemy;
    final ability = _abilities[day % _abilities.length];
    return StageDef(
      id: stageId(day),
      worldId: base.worldId,
      order: base.order,
      name: '${base.name}（今日の挑戦状）',
      region: base.region,
      branch: base.branch,
      branchOrder: base.branchOrder,
      enemy: EnemyDef(
        id: '${e.id}_daily',
        name: '挑戦状の${e.name}',
        maxHp: (e.maxHp * 1.8).round(),
        attack: (e.attack * 1.3).round(),
        description: '${e.description} 今日だけ、ずっと手ごわい。',
        look: e.look,
        color: e.color,
        weakness: e.weakness,
        ability: ability,
        introLine: '今日の挑戦状を受けとったな。手加減はしないぞ！',
        defeatLine: 'みごと…また明日、別の姿で会おう。',
      ),
      questionSetIds: base.questionSetIds,
      expReward: base.expReward * 3,
      timeLimitSeconds: base.timeLimitSeconds,
      readingTimeLimitSeconds: base.readingTimeLimitSeconds,
      recommendedLevel: base.recommendedLevel + 2,
      grammarTheme: base.grammarTheme,
      vocabLevel: base.vocabLevel,
    );
  }
}
