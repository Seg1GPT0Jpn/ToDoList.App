/// 答える前に選ぶ「自信」（メタ認知：自分が分かっているかを判断する練習）。
///
/// - 自信あり：正解なら攻撃が強くなるが、まちがえると大きなダメージ。
///   自信があったのにまちがえた問題は「思いこみ」として記録し、早めに復習する
/// - あやふや：正解でも攻撃は少し弱いが、まちがえてもダメージが小さい。
///   あやふやで正解した問題は「たまたま」かもしれないので、覚えた扱いにしない
enum Confidence {
  sure('自信あり', attackRate: 1.3, damageTakenRate: 1.5),
  normal('ふつう', attackRate: 1, damageTakenRate: 1),
  unsure('あやふや', attackRate: 0.8, damageTakenRate: 0.5);

  const Confidence(
    this.label, {
    required this.attackRate,
    required this.damageTakenRate,
  });

  final String label;

  /// 正解したときの攻撃の倍率
  final double attackRate;

  /// まちがえたときに受けるダメージの倍率
  final double damageTakenRate;
}
