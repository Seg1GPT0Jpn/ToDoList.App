/// ステージごとの自己ベスト。
class StageRecord {
  const StageRecord({
    required this.bestCorrect,
    required this.bestTotal,
    required this.clearCount,
  });

  final int bestCorrect;
  final int bestTotal;
  final int clearCount;

  double get bestAccuracy => bestTotal == 0 ? 0 : bestCorrect / bestTotal;

  factory StageRecord.fromMap(Map<String, dynamic> map) => StageRecord(
        bestCorrect: (map['bestCorrect'] as num?)?.toInt() ?? 0,
        bestTotal: (map['bestTotal'] as num?)?.toInt() ?? 0,
        clearCount: (map['clearCount'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'bestCorrect': bestCorrect,
        'bestTotal': bestTotal,
        'clearCount': clearCount,
      };
}

/// ユーザーごとのゲーム進行状況。
///
/// Firestore の users/{uid}/rpg_progress/main に保存する想定。
/// Firebase の型（Timestamp 等）には依存させず、更新日時はリポジトリ層で付与する。
class RpgProgress {
  const RpgProgress({
    this.level = 1,
    this.exp = 0,
    this.totalExp = 0,
    this.clearedStageIds = const {},
    this.stageRecords = const {},
    this.purchasedWorldIds = const {},
    this.seaBest = const {},
    this.deck = starterDeck,
    this.mistakes = const {},
    this.openedChests = const {},
    this.companions = const {},
    this.lostStages = const {},
    this.springBuff = false,
    this.fieldFlags = const {},
  });

  /// 最初のデッキ（CardDef.starterDeck と同じ）
  static const starterDeck = [
    'power',
    'power',
    'heal',
    'guard',
    'guard',
    'hint'
  ];

  static const initial = RpgProgress();

  final int level;

  /// 現在のレベル内で貯まっている経験値
  final int exp;

  /// 累計獲得経験値
  final int totalExp;
  final Set<String> clearedStageIds;
  final Map<String, StageRecord> stageRecords;

  /// 購入で解放したワールド。
  /// 本番では users/{uid}/rpg_purchases から組み立てる（サーバー検証済みのもののみ）。
  final Set<String> purchasedWorldIds;

  /// 定期テストの海：単元・単語帳ごとの最高正答率（0〜100）
  final Map<String, int> seaBest;

  /// 知識カードのデッキ（カードIDの並び。同じカードを複数持てる）
  final List<String> deck;

  /// 間違えたまま残っている問題：問題ID → 出題されたステージID（亡霊になる）
  final Map<String, String> mistakes;

  /// 開けた宝箱
  final Set<String> openedChests;

  /// 仲間になったキャラクター
  final Set<String> companions;

  /// 一度でも負けたステージ（捕まった仲間が現れる）
  final Set<String> lostStages;

  /// 泉の加護（次のバトルで最大HP +30%）
  final bool springBuff;

  /// フィールドで見つけた・開けたもの（隠し通路・知識の扉・ワープ石など）。
  /// 例：`open:english:12:40`（そのマスの隠し通路・扉が開いた）、`warp:english:3`
  final Set<String> fieldFlags;

  RpgProgress copyWith({
    int? level,
    int? exp,
    int? totalExp,
    Set<String>? clearedStageIds,
    Map<String, StageRecord>? stageRecords,
    Set<String>? purchasedWorldIds,
    Map<String, int>? seaBest,
    List<String>? deck,
    Map<String, String>? mistakes,
    Set<String>? openedChests,
    Set<String>? companions,
    Set<String>? lostStages,
    bool? springBuff,
    Set<String>? fieldFlags,
  }) =>
      RpgProgress(
        level: level ?? this.level,
        exp: exp ?? this.exp,
        totalExp: totalExp ?? this.totalExp,
        clearedStageIds: clearedStageIds ?? this.clearedStageIds,
        stageRecords: stageRecords ?? this.stageRecords,
        purchasedWorldIds: purchasedWorldIds ?? this.purchasedWorldIds,
        seaBest: seaBest ?? this.seaBest,
        deck: deck ?? this.deck,
        mistakes: mistakes ?? this.mistakes,
        openedChests: openedChests ?? this.openedChests,
        companions: companions ?? this.companions,
        lostStages: lostStages ?? this.lostStages,
        springBuff: springBuff ?? this.springBuff,
        fieldFlags: fieldFlags ?? this.fieldFlags,
      );

  factory RpgProgress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return initial;
    final records = (map['stageRecords'] as Map?) ?? const {};
    return RpgProgress(
      level: (map['level'] as num?)?.toInt() ?? 1,
      exp: (map['exp'] as num?)?.toInt() ?? 0,
      totalExp: (map['totalExp'] as num?)?.toInt() ?? 0,
      clearedStageIds:
          Set<String>.from((map['clearedStageIds'] as List?) ?? const []),
      stageRecords: {
        for (final e in records.entries)
          e.key as String:
              StageRecord.fromMap(Map<String, dynamic>.from(e.value as Map)),
      },
      purchasedWorldIds:
          Set<String>.from((map['purchasedWorldIds'] as List?) ?? const []),
      seaBest: {
        for (final e in ((map['seaBest'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      deck: map['deck'] == null
          ? starterDeck
          : List<String>.from(map['deck'] as List),
      mistakes: {
        for (final e in ((map['mistakes'] as Map?) ?? const {}).entries)
          e.key as String: e.value as String,
      },
      openedChests:
          Set<String>.from((map['openedChests'] as List?) ?? const []),
      companions: Set<String>.from((map['companions'] as List?) ?? const []),
      lostStages: Set<String>.from((map['lostStages'] as List?) ?? const []),
      springBuff: map['springBuff'] as bool? ?? false,
      fieldFlags: Set<String>.from((map['fieldFlags'] as List?) ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'level': level,
        'exp': exp,
        'totalExp': totalExp,
        'clearedStageIds': clearedStageIds.toList()..sort(),
        'stageRecords': {
          for (final e in stageRecords.entries) e.key: e.value.toMap(),
        },
        'purchasedWorldIds': purchasedWorldIds.toList()..sort(),
        'seaBest': seaBest,
        'deck': deck,
        'mistakes': mistakes,
        'openedChests': openedChests.toList()..sort(),
        'companions': companions.toList()..sort(),
        'lostStages': lostStages.toList()..sort(),
        'springBuff': springBuff,
        'fieldFlags': fieldFlags.toList()..sort(),
      };
}
