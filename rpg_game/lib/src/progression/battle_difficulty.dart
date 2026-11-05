import 'dart:math';

import '../models/enemy.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';

/// バトルのむずかしさ（冒険の途中でも、いつでも切りかえられる）。
///
/// 「ふつう」は、正答率が5割くらいでも少しずつ進めるように作ってある。
/// 「むずかしい」は、よく解ける人むけ。敵が強く、答える時間が短いかわりに、
/// 経験値が多く、クリアするとエリアに「むずかしいの証」がつく。
enum BattleDifficulty {
  normal('ふつう', hp: 1, attack: 1, time: 1, exp: 1),
  hard('むずかしい', hp: 2.0, attack: 1.7, time: 0.75, exp: 1.3);

  const BattleDifficulty(
    this.label, {
    required this.hp,
    required this.attack,
    required this.time,
    required this.exp,
  });

  final String label;

  /// 敵の HP・攻撃の倍率
  final double hp;
  final double attack;

  /// 答える時間の倍率
  final double time;

  /// 経験値の倍率
  final double exp;

  EnemyDef enemy(EnemyDef e) => this == normal
      ? e
      : e.copyWith(
          maxHp: max(1, (e.maxHp * hp).round()),
          attack: max(1, (e.attack * attack).round()),
        );

  int seconds(int s) => this == normal ? s : max(5, (s * time).round());

  static BattleDifficulty byName(String? name) =>
      values.where((d) => d.name == name).firstOrNull ?? normal;

  /// むずかしいでクリアしたことを残す印（fieldFlags に入れる。クラウドにも残る）
  static String hardFlag(String stageId) => 'hard:$stageId';

  static bool hardCleared(RpgProgress p, StageDef s) =>
      p.fieldFlags.contains(hardFlag(s.id));

  /// むずかしいでクリアしたエリアの数（ワールドの中で）
  static int hardClears(RpgProgress p, Iterable<StageDef> stages) =>
      stages.where((s) => hardCleared(p, s)).length;
}
