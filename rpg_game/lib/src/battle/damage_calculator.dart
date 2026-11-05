import 'dart:math';

/// ダメージ計算。乱数は [Random] を注入できるのでテストで固定できる。
///
/// ※ 乱数はダメージの小さなブレ（±10%）にだけ使い、課金や報酬には一切使わない。
class DamageCalculator {
  DamageCalculator({Random? random, this.variance = 0.1})
      : _random = random ?? Random();

  final Random _random;

  /// ダメージのブレ幅（0.1 なら ±10%）
  final double variance;

  /// 制限時間の何割以内に答えるとクリティカルになるか
  static const quickRatio = 1 / 3;

  /// クリティカル・弱点の倍率
  static const criticalRate = 1.5;
  static const weaknessRate = 1.5;

  /// 装甲にはじかれたときの倍率
  static const blockedRate = 0.3;

  /// チェイン（連続正解）の倍率：3チェインで1.5倍、5チェインで2倍
  static double chainRate(int chain) => chain >= 5
      ? 2.0
      : chain >= 3
          ? 1.5
          : 1.0;

  /// 正解時にプレイヤーが敵へ与えるダメージ。
  ///
  /// [combo] はこの正解を含めた連続正解数（1 以上）。
  /// [extra] はカード・弱点・装甲などの追加倍率。
  int playerAttack({
    required int attack,
    required int combo,
    required Duration elapsed,
    required Duration timeLimit,
    bool forceCritical = false,
    double extra = 1.0,
  }) {
    final critical = forceCritical || isQuick(elapsed, timeLimit);
    final multiplier =
        chainRate(combo) * (critical ? criticalRate : 1.0) * extra;
    return max(1, (attack * multiplier * _roll()).round());
  }

  /// 不正解・時間切れ時に敵がプレイヤーへ与えるダメージ。
  int enemyAttack(
      {required int attack, required int defense, double extra = 1.0}) {
    final base = attack - defense / 2;
    return max(1, (base * extra * _roll()).round());
  }

  bool isQuick(Duration elapsed, Duration timeLimit) =>
      elapsed <= timeLimit * quickRatio;

  double _roll() => 1 + (_random.nextDouble() * 2 - 1) * variance;
}
