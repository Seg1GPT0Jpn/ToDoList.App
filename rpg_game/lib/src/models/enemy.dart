import 'question.dart';

/// 敵の特殊能力。敵ごとに戦い方が変わる。
enum EnemyAbility {
  /// とくになし
  none('', ''),

  /// 防御型：弱点の問題に正解するまで、受けるダメージが半分
  guard('防御型', '弱点の問題に正解するまで、ダメージが半分しか通らない'),

  /// 妨害型：まちがえると、次の問題が難しくなる
  disrupt('妨害型', 'まちがえると、次の問題がむずかしくなる'),

  /// コンボ型：連続正解するほど、ダメージが大きく伸びる
  combo('コンボ型', '1問ずつではあまり効かないが、連続正解で一気にくずれる'),

  /// 特化型：弱点の分野にとても弱いが、ほかの分野には強い
  specialist('特化型', '弱点の問題でダメージ2.5倍、ほかの問題は0.6倍'),

  /// 鉄壁：いつも受けるダメージが少し減る（そのぶんHPは低め）
  sturdy('鉄壁', '受けるダメージがいつも0.7倍'),

  /// 連続要求：2問続けて正解しないとダメージが通りにくい
  chainLock('連続要求', '連続正解の2問目からダメージがしっかり通る');

  const EnemyAbility(this.label, this.description);
  final String label;
  final String description;
}

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
    this.ability = EnemyAbility.none,
  });

  /// 特殊能力
  final EnemyAbility ability;

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
