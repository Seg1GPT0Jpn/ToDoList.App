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

  /// 連続正解ボーナスの1回あたりの上昇率と上限
  static const comboStep = 0.1;
  static const comboMaxBonus = 0.5;

  /// 制限時間の何割以内に答えると「すばやい回答」になるか
  static const quickRatio = 1 / 3;
  static const quickBonus = 0.2;

  /// 正解時にプレイヤーが敵へ与えるダメージ。
  ///
  /// [combo] はこの正解を含めた連続正解数（1 以上）。
  int playerAttack({
    required int attack,
    required int combo,
    required Duration elapsed,
    required Duration timeLimit,
  }) {
    final comboBonus = min((combo - 1) * comboStep, comboMaxBonus);
    final isQuick = elapsed <= timeLimit * quickRatio;
    final multiplier = 1 + comboBonus + (isQuick ? quickBonus : 0);
    return max(1, (attack * multiplier * _roll()).round());
  }

  /// 不正解・時間切れ時に敵がプレイヤーへ与えるダメージ。
  int enemyAttack({required int attack, required int defense}) {
    final base = attack - defense / 2;
    return max(1, (base * _roll()).round());
  }

  bool isQuick(Duration elapsed, Duration timeLimit) =>
      elapsed <= timeLimit * quickRatio;

  double _roll() => 1 + (_random.nextDouble() * 2 - 1) * variance;
}
