import 'question.dart';

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
    this.weakness,
    this.armorCategory,
    this.armor = 0,
    this.introLine = '',
    this.defeatLine = '',
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

  /// 弱点の問題の種類（正解するとダメージ1.5倍）
  final QuestionCategory? weakness;

  /// 装甲を割るのに必要な問題の種類と回数。
  /// 装甲が残っている間、ほかの種類の正解はほとんど効かない。
  final QuestionCategory? armorCategory;
  final int armor;

  /// バトル開始・撃破時のセリフ
  final String introLine;
  final String defeatLine;
}
