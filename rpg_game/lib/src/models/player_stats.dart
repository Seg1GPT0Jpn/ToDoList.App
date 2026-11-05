import 'dart:math' as math;

/// レベルから決まるプレイヤーの能力値。
class PlayerStats {
  const PlayerStats({
    required this.level,
    required this.maxHp,
    required this.attack,
    required this.defense,
  });

  /// レベルの上限
  static const maxLevel = 100;

  /// ここから先は上がりにくくなる（Lv50までの曲線・能力は前と同じ）
  static const softCap = 50;

  factory PlayerStats.forLevel(int level) {
    final l = level.clamp(1, maxLevel);
    final low = l.clamp(1, softCap);
    // Lv50を超えた分は伸びをゆるやかに（強くなりすぎないように）
    final high = l - low;
    return PlayerStats(
      level: l,
      maxHp: 50 + (low - 1) * 8 + high * 4,
      attack: 10 + (low - 1) * 2 + high,
      defense: 2 + (low - 1) + high ~/ 2,
    );
  }

  final int level;
  final int maxHp;
  final int attack;
  final int defense;

  /// 次のレベルまでに必要な経験値（そのレベル内での必要量）
  ///
  /// Lv49までは少しずつ増えるだけ。Lv50からは1レベルごとに5%ずつ重くなり、
  /// Lv99→100 は Lv49→50 の約11倍かかる（後半ほど上げにくい）。
  static int expToNextLevel(int level) {
    if (level < softCap) return 20 + (level - 1) * 15;
    final base = 20 + (softCap - 1) * 15;
    return (base * math.pow(1.05, level - softCap + 1)).round();
  }
}
