import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/stage.dart';

/// 学習ナビの「おすすめ」など、RPG のステージの問題で練習するバトル。
///
/// もとのステージの敵は低いレベル向けなので、そのままだと高レベルでは1問で倒せてしまう。
/// プレイヤーのレベルに合わせて、だいたい [hits] 問正解すると倒せる強さにする。
abstract final class PracticeBattle {
  static const hits = 10;

  static StageDef stage(StageDef base, int level, {int hits = hits}) {
    final p = PlayerStats.forLevel(level);
    final e = base.enemy;
    return StageDef(
      id: base.id,
      worldId: base.worldId,
      order: base.order,
      name: base.name,
      region: base.region,
      grammarTheme: base.grammarTheme,
      questionSetIds: base.questionSetIds,
      expReward: 0,
      timeLimitSeconds: base.timeLimitSeconds,
      readingTimeLimitSeconds: base.readingTimeLimitSeconds,
      enemy: EnemyDef(
        id: e.id,
        name: e.name,
        maxHp: p.attack * hits,
        // 5回まちがえると倒れるくらいの強さ
        attack: (p.maxHp / 5 + p.defense / 2).ceil(),
        description: e.description,
        look: e.look,
        color: e.color,
        weakness: e.weakness,
        introLine: e.introLine,
        defeatLine: e.defeatLine,
      ),
    );
  }
}
