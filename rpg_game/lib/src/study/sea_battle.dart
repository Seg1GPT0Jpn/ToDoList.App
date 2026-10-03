import '../models/player_stats.dart';
import '../models/stage.dart';
import 'realm.dart';

/// 定期テストの海・高校入試の空のバトル。単元の問題で、海（空）の魔物と戦う。
///
/// 定期テストの海の難易度は「とても高い」：
/// - 敵の HP は、ふつうの正解（チェイン・クリティカルなし）で約15回ぶん
/// - 敵の攻撃は、3回まちがえるとほぼ倒れる強さ
/// - 制限時間は RPG の約6割
///
/// 高校入試の空は、さらに難しい（上級者向け）：
/// - 敵の HP は約16回ぶん
/// - 2回まちがえると倒れる
/// - 制限時間は RPG の半分
///
/// 強さはプレイヤーのレベルに合わせて決めるので、レベルを上げても楽にはならない。
/// RPG の進行・経験値は変えない（練習用）。
class SeaBattle {
  const SeaBattle._();

  /// ふつうの正解で倒すのに必要な回数（定期テストの海）
  static int get hitsToWin => StudyRealm.sea.hitsToWin;

  /// 何回まちがえると倒れるか（定期テストの海）
  static int get missesToLose => StudyRealm.sea.missesToLose;

  /// 制限時間（RPG の約6割。高校入試の空は半分。最低8秒）
  static int timeLimit(int normalSeconds,
          [StudyRealm realm = StudyRealm.sea]) =>
      (normalSeconds * realm.timeRate).round().clamp(8, 60);

  static StageDef stage({
    required String id,
    required String title,
    required String worldId,
    required int level,
    required int normalTimeLimitSeconds,
    List<String> questionSetIds = const [],
    StudyRealm realm = StudyRealm.sea,
  }) {
    final player = PlayerStats.forLevel(level);
    final h = id.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7fffffff);
    // [missesToLose] 回で倒れる：攻撃 − 防御/2 ≧ 最大HP/回数
    final attack =
        (player.maxHp / realm.missesToLose + player.defense / 2).ceil() + 1;
    // 海（空）の魔物から選ぶ。4回に1回は、終盤の深海（宇宙）の魔物が出る
    final monsters = [
      ...VoyageMonsters.surface(realm),
      ...VoyageMonsters.deep(realm),
    ];
    final m = monsters[h % monsters.length];
    return StageDef(
      id: '${realm == StudyRealm.sea ? 'sea' : 'sky'}_battle_$id',
      worldId: worldId,
      order: 1,
      name: title,
      region: realm.title,
      isBoss: true,
      expReward: 0,
      questionSetIds: questionSetIds,
      timeLimitSeconds: timeLimit(normalTimeLimitSeconds, realm),
      readingTimeLimitSeconds: timeLimit(normalTimeLimitSeconds * 2, realm),
      grammarTheme: title,
      enemy: m.toEnemy(
        id: '${realm.name}_enemy_$id',
        maxHp: player.attack * realm.hitsToWin,
        attack: attack,
        introLine: realm == StudyRealm.sea
            ? '「$title」…この海を渡れるのは、満点を取れる者だけだ！'
            : '「$title」…この空をこえられるのは、合格圏の者だけだ！',
      ),
    );
  }
}
