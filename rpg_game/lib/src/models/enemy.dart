/// 敵キャラクターの定義。
class EnemyDef {
  const EnemyDef({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.attack,
    this.description = '',
    this.look = '',
    this.color,
  });

  final String id;
  final String name;
  final int maxHp;

  /// 反撃（不正解・時間切れ）時の攻撃力
  final int attack;
  final String description;

  /// 見た目の元になる形（slime / goblin / bat / golem / knight / dragon）
  final String look;

  /// 体の色（ARGB）。null なら形ごとの既定色
  final int? color;
}
