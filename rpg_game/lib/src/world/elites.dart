import '../battle/cards.dart';
import '../models/enemy.dart';
import '../models/stage.dart';

/// フィールドの寄り道にいる「強敵」。
///
/// そのエリアと同じ問題で戦うが、HP も攻撃も高い。倒さなくても先へ進めるが、
/// 倒すとレアカードと多めの経験値がもらえる（はじめて倒したときだけ）。
class Elites {
  const Elites._();

  static const idSuffix = '_elite';

  static bool isElite(String stageId) => stageId.endsWith(idSuffix);

  /// 強敵のステージ ID から、もとのエリアの ID
  static String baseId(String stageId) => isElite(stageId)
      ? stageId.substring(0, stageId.length - idSuffix.length)
      : stageId;

  /// エリアの強敵
  static StageDef of(StageDef base) {
    final e = base.enemy;
    final rares = CardDef.rares;
    final card = rares[base.order % rares.length];
    return StageDef(
      id: '${base.id}$idSuffix',
      worldId: base.worldId,
      order: base.order,
      name: '${base.name}の奥',
      region: base.region,
      branch: base.branch,
      branchOrder: base.branchOrder,
      enemy: EnemyDef(
        id: '${e.id}$idSuffix',
        name: '強敵・${e.name}',
        maxHp: (e.maxHp * 1.6).round(),
        attack: (e.attack * 1.25).round(),
        description: '${e.description} ふつうの個体よりずっと手ごわい。',
        look: e.look,
        color: e.color,
        weakness: e.weakness,
        armorCategory: e.armorCategory,
        armor: e.armor,
        ability: e.ability,
        introLine: 'ここまで来るとは…。だが、この先の宝はわたさない！',
        defeatLine: 'おまえの知識、本物だ…。これを持っていけ。',
      ),
      questionSetIds: base.questionSetIds,
      expReward: base.expReward * 2,
      timeLimitSeconds: base.timeLimitSeconds,
      readingTimeLimitSeconds: base.readingTimeLimitSeconds,
      recommendedLevel: base.recommendedLevel + 2,
      grammarTheme: base.grammarTheme,
      vocabLevel: base.vocabLevel,
      rewardCardId: card.id,
    );
  }
}
