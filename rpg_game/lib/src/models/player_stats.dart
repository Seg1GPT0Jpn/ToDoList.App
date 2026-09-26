/// レベルから決まるプレイヤーの能力値。
class PlayerStats {
  const PlayerStats({
    required this.level,
    required this.maxHp,
    required this.attack,
    required this.defense,
  });

  /// レベルの上限
  static const maxLevel = 50;

  factory PlayerStats.forLevel(int level) {
    final l = level.clamp(1, maxLevel);
    return PlayerStats(
      level: l,
      maxHp: 50 + (l - 1) * 8,
      attack: 10 + (l - 1) * 2,
      defense: 2 + (l - 1),
    );
  }

  final int level;
  final int maxHp;
  final int attack;
  final int defense;

  /// 次のレベルまでに必要な経験値（そのレベル内での必要量）
  static int expToNextLevel(int level) => 20 + (level - 1) * 15;
}
