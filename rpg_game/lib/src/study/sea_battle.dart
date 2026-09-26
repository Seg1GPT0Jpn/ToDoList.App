import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/stage.dart';

/// 定期テストの海のバトル。単元の問題で、海の魔物と戦う。
///
/// 難易度は「とても高い」：
/// - 敵の HP は、ふつうの正解（チェイン・クリティカルなし）で約15回ぶん
/// - 敵の攻撃は、3回まちがえるとほぼ倒れる強さ
/// - 制限時間は RPG の約6割
///
/// 強さはプレイヤーのレベルに合わせて決めるので、レベルを上げても楽にはならない。
/// RPG の進行・経験値は変えない（練習用）。
class SeaBattle {
  const SeaBattle._();

  /// ふつうの正解で倒すのに必要な回数
  static const hitsToWin = 15;

  /// 何回まちがえると倒れるか
  static const missesToLose = 3;

  static const _looks = [
    'ghost', 'slime', 'bat', 'golem', 'knight', 'dragon', 'book', 'page', //
    'pen', 'marker', 'compass', 'scissors', 'stapler', 'binder',
  ];

  static const _names = [
    '深海の試験官', 'うずしおの番人', '赤点クラーケン', '難問リヴァイアサン', //
    '暗記の大ダコ', '満点を拒む海竜', '追試の亡霊', '範囲外シーサーペント',
  ];

  /// 制限時間（RPG の約6割。最低8秒）
  static int timeLimit(int normalSeconds) =>
      (normalSeconds * 0.6).round().clamp(8, 60);

  static StageDef stage({
    required String id,
    required String title,
    required String worldId,
    required int level,
    required int normalTimeLimitSeconds,
    List<String> questionSetIds = const [],
  }) {
    final player = PlayerStats.forLevel(level);
    final h = id.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7fffffff);
    // 3回で倒れる：攻撃 − 防御/2 ≧ 最大HP/3
    final attack =
        (player.maxHp / missesToLose + player.defense / 2).ceil() + 1;
    return StageDef(
      id: 'sea_battle_$id',
      worldId: worldId,
      order: 1,
      name: title,
      region: '定期テストの海',
      isBoss: true,
      expReward: 0,
      questionSetIds: questionSetIds,
      timeLimitSeconds: timeLimit(normalTimeLimitSeconds),
      readingTimeLimitSeconds: timeLimit(normalTimeLimitSeconds * 2),
      grammarTheme: title,
      enemy: EnemyDef(
        id: 'sea_enemy_$id',
        name: _names[h % _names.length],
        maxHp: player.attack * hitsToWin,
        attack: attack,
        look: _looks[h % _looks.length],
        color: 0xFF1F4E79,
        description: '定期テストの海の底から現れた、とても手ごわい魔物。',
        introLine: '「$title」…この海を渡れるのは、満点を取れる者だけだ！',
        defeatLine: 'み、見事だ…その力、本番でも見せてみろ…',
      ),
    );
  }
}
