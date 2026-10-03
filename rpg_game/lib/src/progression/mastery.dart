import 'dart:math';

import '../battle/battle_engine.dart';
import '../curriculum/curriculum.dart';
import '../curriculum/question_meta.dart';
import '../data/catalog.dart';
import '../models/player_stats.dart';
import '../models/question.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';
import '../story/gear.dart';
import '../story/story.dart';
import '../world/elites.dart';

/// 科目ごとの習熟（習熟Lv）。
///
/// 冒険Lv（全体の経験値）とは別に、学習体系の「科目」（数学Ⅰ・化学・日本史…）ごとに
/// 経験値をためる。その科目のバトルで得た経験値がたまるので、ほかの科目を先に
/// 進めても、まだ学んでいない科目の習熟Lvは低いまま。
abstract final class Mastery {
  /// 習熟のデータの版。読み込み時に、これより古ければ [migrate] で移行する
  static const version = 1;

  /// ワールドのルート（ゲームの道）→ 学習体系の科目 ID
  /// （小中学生版は5教科ともルート＝学年の科目なので、固定の対応はない）
  static const _routeCourse = <String, String>{};

  /// ステージがどの科目のものか（物語の決戦など、科目に属さないなら null）
  static String? courseOfStage(StageDef stage) {
    // 世界の中心（5教科すべての問題）は、ひとつの科目に属さない
    if (stage.id == Story.centerStageId) return null;
    final fixed = _routeCourse[stage.worldId];
    if (fixed != null) return fixed;
    final id = '${stage.worldId}.${stage.branch}';
    final node = Curriculum.tryNode(id);
    return node?.level == CurriculumLevel.course ? id : null;
  }

  /// 単元・小単元がどの科目のものか
  static String? courseOfUnit(String? unit) {
    if (unit == null || !Curriculum.contains(unit)) return null;
    return Curriculum.ancestorAt(unit, CurriculumLevel.course)?.id;
  }

  /// 科目の名前（例：数学Ⅰ）
  static String courseName(String course) =>
      Curriculum.tryNode(course)?.name ?? course;

  /// 累計の経験値から習熟Lv（冒険Lvと同じ曲線。上限も同じ）
  static int levelFor(int exp) {
    var level = 1;
    var rest = exp;
    while (level < PlayerStats.maxLevel &&
        rest >= PlayerStats.expToNextLevel(level)) {
      rest -= PlayerStats.expToNextLevel(level);
      level++;
    }
    return level;
  }

  /// 習熟Lv [level] になるのに必要な累計経験値
  static int expForLevel(int level) {
    var sum = 0;
    for (var l = 1; l < level.clamp(1, PlayerStats.maxLevel); l++) {
      sum += PlayerStats.expToNextLevel(l);
    }
    return sum;
  }

  static int levelOf(RpgProgress progress, String course) =>
      levelFor(progress.masteryExp[course] ?? 0);

  /// ステージの科目の習熟Lv（科目に属さないステージは冒険Lvを使う）
  static int levelForStage(RpgProgress progress, StageDef stage) {
    final course = courseOfStage(stage);
    return course == null ? progress.level : levelOf(progress, course);
  }

  /// 科目に経験値を足す
  static RpgProgress add(RpgProgress progress, String? course, int amount) {
    if (course == null || amount <= 0) return progress;
    return progress.copyWith(
      masteryExp: {
        ...progress.masteryExp,
        course: (progress.masteryExp[course] ?? 0) + amount,
      },
    );
  }

  /// 練習のバトル（海・空・復習の塔・単元の練習など）の経験値を、
  /// 正解した問題の科目に、正解の数の割合で分けて足す
  static RpgProgress addByAnswers(
    RpgProgress progress,
    BattleSummary summary,
    int amount,
  ) {
    if (amount <= 0) return progress;
    final counts = <String, int>{};
    for (final t in summary.turns) {
      if (!t.correct) continue;
      final c = courseOfUnit(t.question.source.unit);
      if (c != null) counts[c] = (counts[c] ?? 0) + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return progress;
    var next = progress;
    for (final e in counts.entries) {
      next = add(next, e.key, (amount * e.value / total).round());
    }
    return next;
  }

  /// 習熟ができる前のセーブデータを移行する：クリアしたエリアの経験値を、
  /// そのエリアの科目の習熟としてたし合わせる（今まで進めた分は、その科目の力になる）
  static RpgProgress migrate(RpgProgress progress) {
    if (progress.masteryVersion >= version) return progress;
    final exp = <String, int>{...progress.masteryExp};
    for (final w in RpgCatalog.worlds) {
      for (final s in w.stages) {
        if (!progress.clearedStageIds.contains(s.id)) continue;
        final course = courseOfStage(s);
        if (course == null) continue;
        exp[course] = (exp[course] ?? 0) + s.expReward;
        if (progress.clearedStageIds.contains(Elites.of(s).id)) {
          exp[course] = exp[course]! + Elites.of(s).expReward;
        }
      }
    }
    return progress.copyWith(masteryExp: exp, masteryVersion: version);
  }
}

/// 戦いの強さ：冒険Lvと、その科目の習熟Lvを組み合わせて決める。
///
/// - 攻撃（正解したときのダメージ）は「戦闘Lv」＝習熟Lv 6割＋冒険Lv 4割で決まる
/// - さらに、ダメージは敵の推奨レベルでの攻撃力を基準に、戦闘Lvとの差で上下する
///   （差が大きくても最大1.5倍・最小0.55倍）。だから、ほかの科目でレベルを上げても
///   新しい科目の最初の敵を1問で倒すことはない（HP をふやして調整しているわけではない）
/// - HP と守り（まちがえたときに受けるダメージ）は冒険Lvで決まる（冒険の経験は体の強さ）
abstract final class BattlePower {
  /// 戦闘Lvに占める習熟Lvの割合
  static const masteryWeight = 0.6;

  /// 1Lv の差でダメージが変わる割合と、その上限・下限
  static const perLevel = 0.05;
  static const maxAdvantage = 1.5;
  static const minAdvantage = 0.55;

  static int effectiveLevel({
    required int playerLevel,
    required int masteryLevel,
  }) =>
      (masteryLevel * masteryWeight + playerLevel * (1 - masteryWeight))
          .round()
          .clamp(1, PlayerStats.maxLevel);

  /// 戦闘Lv と推奨レベルの差による、ダメージの倍率
  static double advantage(int effectiveLevel, int recommendedLevel) =>
      (1 + perLevel * (effectiveLevel - recommendedLevel))
          .clamp(minAdvantage, maxAdvantage)
          .toDouble();

  /// RPG のエリア（推奨レベルと決まった HP をもつ敵）での能力値
  static PlayerStats forStage(RpgProgress progress, StageDef stage) {
    final body = PlayerStats.forLevel(progress.level);
    final eff = effectiveLevel(
      playerLevel: progress.level,
      masteryLevel: Mastery.levelForStage(progress, stage),
    );
    final base = PlayerStats.forLevel(stage.recommendedLevel).attack;
    return PlayerStats(
      level: body.level,
      maxHp: body.maxHp,
      defense: body.defense,
      attack: max(1, (base * advantage(eff, stage.recommendedLevel)).round()),
    );
  }

  /// 装備の攻撃（足し算の値）を、冒険Lvの攻撃力に対する割合に直す。
  /// 推奨レベルを基準にしたダメージに、強い装備の値をそのまま足すと
  /// 序盤の敵を1問で倒せてしまうため。
  static BattleBonus bonusForStage(BattleBonus bonus, RpgProgress progress) {
    if (bonus.attack == 0) return bonus;
    final own = PlayerStats.forLevel(progress.level).attack;
    return BattleBonus(
      attack: 0,
      defense: bonus.defense,
      attackRate: bonus.attackRate * (1 + bonus.attack / own),
      damageTakenRate: bonus.damageTakenRate,
      weaknessBonus: bonus.weaknessBonus,
      chainBonus: bonus.chainBonus,
      extraSeconds: bonus.extraSeconds,
    );
  }

  /// 推奨レベルちょうどの戦闘Lvで、ふつうに正解したときに敵を倒すのに必要な正解数
  static double baseHits(StageDef stage) =>
      stage.enemy.maxHp / PlayerStats.forLevel(stage.recommendedLevel).attack;
}

/// 正解したときの「学び」のボーナス（難しい問題・苦手への挑戦ほど有利）。
abstract final class LearningBonus {
  /// 思考レベルによるダメージの倍率（レベル4から1段ごとに +10%、最大 +50%）
  static double thinkingRate(QuizQuestion q) {
    final t = (q.thinkingLevel ?? QuestionProfiler.of(q).thinking).number;
    return 1 + 0.1 * (t - 3).clamp(0, 5);
  }

  /// 苦手な単元の問題に正解したときのダメージの倍率
  static const weakRate = 1.2;

  /// 苦手な単元か（[weakUnits] は単元か小単元の ID）
  static bool isWeak(QuizQuestion q, Set<String> weakUnits) {
    final u = q.unit;
    if (u == null || weakUnits.isEmpty) return false;
    for (final w in weakUnits) {
      if (u == w || u.startsWith('$w.')) return true;
    }
    return false;
  }

  /// バトルの正解から得られる、学びのボーナス経験値
  /// （思考レベル4以上の正解：レベル−3 ×3、苦手な単元の正解：+3）
  static int bonusExp(BattleSummary summary,
      {Set<String> weakUnits = const {}}) {
    var exp = 0;
    final seen = <String>{};
    for (final t in summary.turns) {
      if (!t.correct || !seen.add(t.question.source.id)) continue;
      final q = t.question.source;
      final level = (q.thinkingLevel ?? QuestionProfiler.of(q).thinking).number;
      exp += 3 * (level - 3).clamp(0, 5);
      if (isWeak(q, weakUnits)) exp += 3;
    }
    return exp;
  }
}
