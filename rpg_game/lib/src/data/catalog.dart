import '../models/enemy.dart';
import '../models/stage.dart';
import '../models/world.dart';

/// ワールド・ステージのマスターデータ。
///
/// 教科を追加するときは、ここで status を available にして stages を足し、
/// assets/questions/<worldId>/ に問題セットを置くだけでよい。
class RpgCatalog {
  const RpgCatalog._();

  static const englishWorldId = 'english';

  /// 教科ワールドの予定価格（買い切り・円）。ランダム要素は持たない。
  static const defaultWorldPriceYen = 250;

  static const englishStages = <StageDef>[
    StageDef(
      id: 'english_01',
      worldId: englishWorldId,
      order: 1,
      name: 'はじまりの余白',
      questionSetId: 'english_stage_01',
      expReward: 30,
      timeLimitSeconds: 20,
      recommendedLevel: 1,
      enemy: EnemyDef(
        id: 'doodle_slime',
        name: '落書きスライム',
        maxHp: 40,
        attack: 8,
        description: 'ノートの端から生まれた、ゆるい落書き。',
      ),
    ),
    StageDef(
      id: 'english_02',
      worldId: englishWorldId,
      order: 2,
      name: 'にじむ罫線の小道',
      questionSetId: 'english_stage_02',
      expReward: 40,
      timeLimitSeconds: 20,
      recommendedLevel: 2,
      enemy: EnemyDef(
        id: 'ink_goblin',
        name: 'インク染みゴブリン',
        maxHp: 60,
        attack: 11,
        description: 'こぼれたインクにひそむいたずら者。',
      ),
    ),
    StageDef(
      id: 'english_03',
      worldId: englishWorldId,
      order: 3,
      name: 'しおりの森',
      questionSetId: 'english_stage_03',
      expReward: 55,
      timeLimitSeconds: 18,
      recommendedLevel: 3,
      enemy: EnemyDef(
        id: 'bookmark_bat',
        name: 'しおりバット',
        maxHp: 85,
        attack: 14,
        description: 'ページの間を飛び回り、読みかけの場所を隠す。',
      ),
    ),
    StageDef(
      id: 'english_04',
      worldId: englishWorldId,
      order: 4,
      name: '索引の洞窟',
      questionSetId: 'english_stage_04',
      expReward: 70,
      timeLimitSeconds: 18,
      recommendedLevel: 4,
      enemy: EnemyDef(
        id: 'dictionary_golem',
        name: '辞書ゴーレム',
        maxHp: 110,
        attack: 17,
        description: '分厚い紙が固まってできた巨体。',
      ),
    ),
    StageDef(
      id: 'english_05',
      worldId: englishWorldId,
      order: 5,
      name: '文法の城門',
      questionSetId: 'english_stage_05',
      expReward: 90,
      timeLimitSeconds: 15,
      recommendedLevel: 6,
      enemy: EnemyDef(
        id: 'grammar_knight',
        name: '文法ナイト',
        maxHp: 150,
        attack: 22,
        description: '語順の乱れを決して見逃さない騎士。',
      ),
    ),
    StageDef(
      id: 'english_06',
      worldId: englishWorldId,
      order: 6,
      name: '最終章の塔',
      questionSetId: 'english_stage_06',
      expReward: 150,
      timeLimitSeconds: 15,
      recommendedLevel: 8,
      enemy: EnemyDef(
        id: 'essay_dragon',
        name: '英作文ドラゴン',
        maxHp: 200,
        attack: 27,
        description: '英語ワールドの主。長文の炎を吐く。',
      ),
    ),
  ];

  static const worlds = <WorldDef>[
    WorldDef(
      id: 'japanese',
      name: '言の葉の国',
      subject: '国語',
      status: WorldStatus.comingSoon,
      isFree: false,
      priceYen: defaultWorldPriceYen,
    ),
    WorldDef(
      id: 'math',
      name: '数理の国',
      subject: '数学',
      status: WorldStatus.comingSoon,
      isFree: false,
      priceYen: defaultWorldPriceYen,
    ),
    WorldDef(
      id: englishWorldId,
      name: '英語ワールド',
      subject: '英語',
      status: WorldStatus.available,
      isFree: true,
      stages: englishStages,
      description: '品詞・意味・語法の4択で、ノートの魔物たちを倒そう。',
    ),
    WorldDef(
      id: 'science',
      name: '理の国',
      subject: '理科',
      status: WorldStatus.comingSoon,
      isFree: false,
      priceYen: defaultWorldPriceYen,
    ),
    WorldDef(
      id: 'social',
      name: '時と地の国',
      subject: '地歴公民',
      status: WorldStatus.comingSoon,
      isFree: false,
      priceYen: defaultWorldPriceYen,
    ),
    WorldDef(
      id: 'information',
      name: '情報の国',
      subject: '情報',
      status: WorldStatus.comingSoon,
      isFree: false,
      priceYen: defaultWorldPriceYen,
    ),
  ];

  static WorldDef world(String id) => worlds.firstWhere(
        (w) => w.id == id,
        orElse: () => throw ArgumentError('不明なワールドです: $id'),
      );

  static StageDef stage(String id) =>
      worlds.expand((w) => w.stages).firstWhere((s) => s.id == id,
          orElse: () => throw ArgumentError('不明なステージです: $id'));
}
