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
  });

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

  RpgProgress copyWith({
    int? level,
    int? exp,
    int? totalExp,
    Set<String>? clearedStageIds,
    Map<String, StageRecord>? stageRecords,
    Set<String>? purchasedWorldIds,
  }) =>
      RpgProgress(
        level: level ?? this.level,
        exp: exp ?? this.exp,
        totalExp: totalExp ?? this.totalExp,
        clearedStageIds: clearedStageIds ?? this.clearedStageIds,
        stageRecords: stageRecords ?? this.stageRecords,
        purchasedWorldIds: purchasedWorldIds ?? this.purchasedWorldIds,
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
      };
}
