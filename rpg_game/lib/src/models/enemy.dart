/// 敵キャラクターの定義。
class EnemyDef {
  const EnemyDef({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.attack,
    this.description = '',
  });

  final String id;
  final String name;
  final int maxHp;

  /// 反撃（不正解・時間切れ）時の攻撃力
  final int attack;
  final String description;
}
