import '../models/enemy.dart';
import '../models/question.dart';
import '../models/stage.dart';

/// 教科の中の「ルート」（理科なら物理・化学…、社会なら地理・日本史…）。
///
/// スタート地点（ハブ）から [direction] の向きに道がのびる。
/// 同じ向きのルートが複数あるときは、ハブの同じ辺に出入口が並ぶ。
class RouteInfo {
  const RouteInfo(this.id, this.name, this.direction);

  final String id;
  final String name;

  /// up / left / right / down
  final String direction;
}

/// ルートの中の1エリア（1ステージ）の中身。
class RouteArea {
  const RouteArea({
    required this.theme,
    required this.section,
    required this.place,
    required this.enemy,
    required this.look,
    required this.color,
    required this.description,
    required this.intro,
    required this.defeat,
    this.boss = false,
  });

  /// 単元名（宿の授業のタイトル・出題範囲の表示）
  final String theme;

  /// 分野（例：原始・古代、数と式）。マップの地方の区切りにも使う
  final String section;

  /// エリアの地名
  final String place;
  final String enemy;
  final String look;
  final int color;
  final String description;
  final String intro;
  final String defeat;

  /// ボス（装甲あり。前のボスの次のエリアからの問題もまとめて出す）
  final bool boss;
}

/// ルートの定義（中身つき）
class RouteSpec {
  const RouteSpec({
    required this.info,
    required this.areas,
    this.timeLimitSeconds = 25,
    this.primary = QuestionCategory.knowledge,
    this.secondary = QuestionCategory.thinking,
    this.armorCategory = QuestionCategory.knowledge,
  });

  final RouteInfo info;
  final List<RouteArea> areas;
  final int timeLimitSeconds;

  /// 奇数エリアの弱点（数学は calculation）
  final QuestionCategory primary;

  /// 偶数エリアの弱点（計算の多いルートは calculation）
  final QuestionCategory secondary;

  /// ボスの装甲を割る問題の種類
  final QuestionCategory armorCategory;
}

/// ルート制のワールドからステージを作る。強さはどの教科も同じ曲線。
class RouteWorldBuilder {
  const RouteWorldBuilder._();

  static const _hp = [
    40, 51, 64, 77, 102, 136, 155, 190, 213, 237, //
    277, 305, 334, 362, 412, 386, 416, 534, 570, 530,
  ];
  static const _atk = [
    7, 9, 11, 12, 16, 18, 19, 23, 25, 27, //
    31, 34, 36, 38, 43, 46, 48, 53, 57, 60,
  ];
  static const _lv = [
    1, 2, 3, 4, 6, 7, 8, 10, 11, 12, //
    14, 15, 16, 17, 19, 20, 21, 23, 24, 25,
  ];
  static const _exp = [
    20, 35, 50, 145, 95, 110, 265, 155, 170, 385, //
    215, 230, 245, 535, 290, 305, 655, 350, 365, 775,
  ];

  /// 初めて勝ったときのカード
  static const _rewards = {
    3: 'hint',
    6: 'heal',
    9: 'time',
    12: 'power',
    15: 'critical',
    18: 'gamble',
  };

  /// エリア k（1〜20）のふつうの敵の強さ（学習モードの強さの目安にも使う）
  static int hpAt(int k) => _hp[(k - 1).clamp(0, 19)];
  static int attackAt(int k) => _atk[(k - 1).clamp(0, 19)];

  static String setId(String worldId, String route, int k) =>
      '${worldId}_${route}_${k.toString().padLeft(2, '0')}';

  static List<StageDef> build(String worldId, List<RouteSpec> routes) {
    final stages = <StageDef>[];
    var order = 0;
    for (final r in routes) {
      if (r.areas.length > 20) {
        throw ArgumentError('1つのルートは20エリアまで: ${r.info.id}');
      }
      var lastBoss = 0;
      for (final (i, a) in r.areas.indexed) {
        order++;
        final k = i + 1;
        final setIds = [
          for (var n = a.boss ? lastBoss + 1 : k; n <= k; n++)
            setId(worldId, r.info.id, n),
        ];
        if (a.boss) lastBoss = k;
        stages.add(
          StageDef(
            id: '${worldId}_${r.info.id}_${k.toString().padLeft(2, '0')}',
            worldId: worldId,
            order: order,
            branch: r.info.id,
            branchOrder: k,
            name: a.place,
            region: a.section,
            questionSetIds: setIds,
            grammarTheme: a.theme,
            vocabLevel: '${r.info.name}・${a.section}',
            expReward: _exp[k - 1],
            timeLimitSeconds: r.timeLimitSeconds,
            readingTimeLimitSeconds: r.timeLimitSeconds * 2,
            recommendedLevel: _lv[k - 1],
            isBoss: a.boss,
            rewardCardId: _rewards[k],
            enemy: EnemyDef(
              id: 'e_${worldId}_${r.info.id}_$k',
              name: a.enemy,
              look: a.look,
              color: a.color,
              maxHp: a.boss ? (_hp[k - 1] * 1.1).round() : _hp[k - 1],
              attack: _atk[k - 1],
              description: a.description,
              weakness:
                  a.boss ? r.secondary : (k.isOdd ? r.primary : r.secondary),
              armorCategory: a.boss ? r.armorCategory : null,
              armor: a.boss ? (k >= 12 ? 3 : 2) : 0,
              introLine: a.intro,
              defeatLine: a.defeat,
            ),
          ),
        );
      }
    }
    return stages;
  }
}
