import '../battle/cards.dart';
import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';

/// クリア後の裏ボス「影の番人」。
///
/// ワールド（ルート）のエリアをすべてクリアすると、ゴールの間に現れる。
/// そのマップのすべての問題から出題され、最後のボスよりずっと強い。
/// 倒すと、たくさんの経験値とレアカード、実績がもらえる（はじめて倒したときだけ）。
class ShadowKeeper {
  const ShadowKeeper._();

  static const idSuffix = '_shadow';

  static bool isShadow(String stageId) => stageId.endsWith(idSuffix);

  /// [stages]（1枚のマップのエリア。順番どおり）の影の番人
  static StageDef of(List<StageDef> stages) {
    final last = stages.last;
    final boss = last.enemy;
    final rares = CardDef.rares;
    return StageDef(
      id: '${last.id}$idSuffix',
      worldId: last.worldId,
      order: last.order + 1,
      name: '影の番人',
      region: last.region,
      branch: last.branch,
      branchOrder: last.branchOrder,
      isBoss: true,
      enemy: EnemyDef(
        id: '${boss.id}$idSuffix',
        name: '影の番人',
        maxHp: (boss.maxHp * 2.2).round(),
        attack: (boss.attack * 1.4).round(),
        description: 'すべてのエリアを越えた者の前にだけ現れる、忘却の魔王の影。'
            'ここで学んだすべてを問いかけてくる。',
        look: boss.look,
        color: 0xFF3A2F4F,
        weakness: boss.weakness,
        armorCategory: boss.armorCategory,
        armor: boss.armor,
        ability: boss.ability,
        introLine: 'ここまで学んだすべてを、わたしに見せてみよ…！',
        defeatLine: '見事だ…。その知識、決して忘れるな…。',
      ),
      questionSetIds: [
        for (final s in stages) ...s.questionSetIds,
      ].toSet().toList(),
      expReward: last.expReward * 3,
      timeLimitSeconds: last.timeLimitSeconds,
      readingTimeLimitSeconds: last.readingTimeLimitSeconds,
      recommendedLevel: last.recommendedLevel + 6,
      grammarTheme: '総まとめ',
      vocabLevel: last.vocabLevel,
      rewardCardId: rares[stages.length % rares.length].id,
    );
  }

  /// 影の番人が現れているか（マップのエリアをすべてクリアした）
  static bool appears(RpgProgress p, List<StageDef> stages) =>
      stages.isNotEmpty &&
      stages.every((s) => p.clearedStageIds.contains(s.id));

  /// 影の番人を倒したか
  static bool defeated(RpgProgress p, List<StageDef> stages) =>
      stages.isNotEmpty && p.clearedStageIds.contains(of(stages).id);
}
