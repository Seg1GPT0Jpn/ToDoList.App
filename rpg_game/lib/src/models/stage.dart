import 'difficulty.dart';
import 'enemy.dart';

/// ワールド内の1ステージ。
class StageDef {
  const StageDef({
    required this.id,
    required this.worldId,
    required this.order,
    required this.name,
    required this.enemy,
    required this.questionSetIds,
    required this.expReward,
    this.timeLimitSeconds = 20,
    this.readingTimeLimitSeconds = 60,
    this.region = '',
    this.isBoss = false,
    this.recommendedLevel = 1,
    this.grammarTheme = '',
    this.vocabLevel = '',
    this.captiveCompanionId,
    this.rewardCardId,
    this.branch = '',
    this.branchOrder,
    this.reinforcements = const [],
  });

  /// ボスの連戦で、[enemy] のあとに続けて現れるボス（前のボスが弱ると乱入してくる）
  final List<EnemyDef> reinforcements;

  /// 分かれ道の系統（理科なら physics / chemistry / biology / earth）。
  /// 解放は同じ系統の1つ前のステージで判定する。英語のように1本道なら空。
  final String branch;

  /// 系統の中での番号（1始まり）。null なら [order] と同じ
  final int? branchOrder;

  /// 画面に出すエリア番号
  int get areaNo => branchOrder ?? order;

  /// エリア名から分かる難易度（数学の基本・標準・応用など）
  Difficulty? get difficulty => Difficulty.fromTheme(grammarTheme);

  final String id;
  final String worldId;

  /// 1 始まりの並び順。1つ前のステージをクリアすると解放される。
  final int order;
  final String name;
  final EnemyDef enemy;

  /// 出題に使う問題セット（複数なら合わせて出題）
  final List<String> questionSetIds;

  /// このステージ固有の問題セット（先頭）
  String get questionSetId => questionSetIds.first;

  /// 長文読解の設問1問あたりの制限時間（秒）
  final int readingTimeLimitSeconds;

  /// エリアの地方（草原・海岸・洞窟・溶岩）
  final String region;

  /// 四天王・ラスボス
  final bool isBoss;

  /// 一度負けると横に捕まって現れ、再戦で勝つと仲間になるキャラクター
  final String? captiveCompanionId;

  /// 初めて勝ったときにもらえるカード
  final String? rewardCardId;

  /// 初回クリア時の獲得経験値
  final int expReward;

  /// 1問あたりの制限時間（秒）
  final int timeLimitSeconds;
  final int recommendedLevel;

  /// このステージで扱う文法の単元（例: 準動詞）
  final String grammarTheme;

  /// 単語の難しさの目安（例: 基礎、標準、難関）
  final String vocabLevel;
}
