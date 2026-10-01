import 'dart:math';

import '../battle/battle_engine.dart';
import '../battle/cards.dart';
import '../world/elites.dart';
import '../models/player_stats.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';
import '../models/world.dart';
import 'mastery.dart';

/// 経験値付与の結果。結果画面のレベルアップ演出に使う。
class ExpGainResult {
  const ExpGainResult({
    required this.progress,
    required this.expGained,
    required this.before,
    required this.after,
  });

  final RpgProgress progress;
  final int expGained;
  final PlayerStats before;
  final PlayerStats after;

  bool get leveledUp => after.level > before.level;
  int get levelsGained => after.level - before.level;
}

/// ステージクリア処理の結果。
class StageClearResult {
  const StageClearResult({
    required this.expResult,
    required this.firstClear,
    required this.newlyUnlockedStageId,
    this.newCard,
    this.rescued,
    this.newMistakes = 0,
    this.learningBonusExp = 0,
    this.masteryCourse,
    this.masteryBefore = 0,
    this.masteryAfter = 0,
  });

  /// 学びのボーナス（難しい問題・苦手な単元への正解）でふえた経験値
  final int learningBonusExp;

  /// 習熟がふえた科目（なければ null）と、そのバトルの前後の習熟Lv
  final String? masteryCourse;
  final int masteryBefore;
  final int masteryAfter;

  bool get masteryLeveledUp =>
      masteryCourse != null && masteryAfter > masteryBefore;

  /// 初クリアでもらったカード
  final CardDef? newCard;

  /// 助け出した仲間
  final CompanionDef? rescued;

  /// 新しく亡霊になった（間違えた）問題の数
  final int newMistakes;

  final ExpGainResult expResult;
  final bool firstClear;

  /// この勝利で新たに挑戦できるようになったステージ（なければ null）
  final String? newlyUnlockedStageId;

  RpgProgress get progress => expResult.progress;
}

/// レベル・経験値・ステージ解放のルール。すべて副作用のない関数。
class Progression {
  const Progression._();

  /// 敗北時でも正解1問につきもらえる経験値（勉強した分は無駄にしない）
  static const expPerCorrectOnLoss = 2;

  /// 2回目以降のクリアで得られる経験値の割合
  static const replayExpRate = 0.5;

  /// ノーミスクリア時の上乗せ割合
  static const perfectBonusRate = 0.2;

  /// [progress] に [amount] の経験値を加え、必要ならレベルを上げる。
  static ExpGainResult addExp(RpgProgress progress, int amount) {
    final before = PlayerStats.forLevel(progress.level);
    var level = progress.level;
    var exp = progress.exp + amount;
    while (level < PlayerStats.maxLevel &&
        exp >= PlayerStats.expToNextLevel(level)) {
      exp -= PlayerStats.expToNextLevel(level);
      level++;
    }
    if (level >= PlayerStats.maxLevel) exp = 0;
    final updated = progress.copyWith(
      level: level,
      exp: exp,
      totalExp: progress.totalExp + amount,
    );
    return ExpGainResult(
      progress: updated,
      expGained: amount,
      before: before,
      after: PlayerStats.forLevel(level),
    );
  }

  /// 練習のバトル（海・空・復習の塔・おすすめの練習）で得る経験値。
  /// 正解した数に応じて、レベルが高くても 0 にならないようにする。
  static int practiceExp(BattleSummary summary, int level) =>
      summary.correctCount * (2 + level ~/ 2);

  /// バトル結果から獲得経験値を計算する。
  static int expFor(StageDef stage, BattleSummary summary,
      {required bool alreadyCleared}) {
    if (!summary.won) return summary.correctCount * expPerCorrectOnLoss;
    var exp = stage.expReward.toDouble();
    if (alreadyCleared) exp *= replayExpRate;
    if (summary.isPerfect) exp *= 1 + perfectBonusRate;
    return exp.round();
  }

  /// バトル終了後の進行状況を計算する（勝敗どちらでも呼ぶ）。
  ///
  /// 経験値は冒険Lv（全体）と、そのエリアの科目の習熟の両方に入る。
  /// 難しい問題・苦手な単元（[weakUnits]）への正解には、学びのボーナスがつく。
  static StageClearResult applyBattle({
    required RpgProgress progress,
    required WorldDef world,
    required StageDef stage,
    required BattleSummary summary,
    Set<String> weakUnits = const {},
  }) {
    progress = Mastery.migrate(progress);
    final alreadyCleared = progress.clearedStageIds.contains(stage.id);
    final learningBonus = LearningBonus.bonusExp(summary, weakUnits: weakUnits);
    final gained =
        expFor(stage, summary, alreadyCleared: alreadyCleared) + learningBonus;

    // 間違えた問題は亡霊として残し、正解した問題は亡霊から外す
    final mistakes = {...progress.mistakes};
    var newMistakes = 0;
    for (final q in summary.missedQuestions) {
      if (!mistakes.containsKey(q.id)) newMistakes++;
      // 強敵でまちがえた問題は、そのエリアの亡霊になる
      mistakes[q.id] = Elites.baseId(stage.id);
    }
    for (final id in summary.correctIds) {
      if (!summary.missedQuestions.any((q) => q.id == id)) mistakes.remove(id);
    }

    var updated = progress.copyWith(mistakes: mistakes, springBuff: false);
    String? unlocked;
    CardDef? newCard;
    CompanionDef? rescued;
    if (summary.won) {
      final prev = progress.stageRecords[stage.id];
      final better = prev == null || summary.accuracy > prev.bestAccuracy;
      updated = updated.copyWith(
        clearedStageIds: {...progress.clearedStageIds, stage.id},
        stageRecords: {
          ...progress.stageRecords,
          stage.id: StageRecord(
            bestCorrect: better ? summary.correctCount : prev.bestCorrect,
            bestTotal: better ? summary.answeredCount : prev.bestTotal,
            clearCount: (prev?.clearCount ?? 0) + 1,
          ),
        },
      );
      if (!alreadyCleared) {
        // 強敵・世界の中心は、次のエリアの解放には数えない
        final next = Elites.isElite(stage.id) ||
                !world.stages.any((s) => s.id == stage.id)
            ? null
            : nextInBranch(world, stage);
        if (next != null) unlocked = next.id;
        if (stage.rewardCardId != null) {
          newCard = CardDef.byId(stage.rewardCardId!);
          updated = updated.copyWith(deck: [...updated.deck, newCard.id]);
        }
      }
      final captive = stage.captiveCompanionId;
      if (captive != null &&
          progress.lostStages.contains(stage.id) &&
          !progress.companions.contains(captive)) {
        rescued = CompanionDef.byId(captive);
        updated =
            updated.copyWith(companions: {...updated.companions, captive});
      }
    } else {
      updated = updated.copyWith(lostStages: {...updated.lostStages, stage.id});
    }

    updated = Mastery.add(updated, Mastery.courseOfStage(stage), gained);
    return StageClearResult(
      learningBonusExp: learningBonus,
      masteryBefore: Mastery.levelForStage(progress, stage),
      masteryAfter: Mastery.levelForStage(updated, stage),
      masteryCourse: Mastery.courseOfStage(stage),
      expResult: addExp(updated, gained),
      firstClear: summary.won && !alreadyCleared,
      newlyUnlockedStageId: unlocked,
      newCard: newCard,
      rescued: rescued,
      newMistakes: newMistakes,
    );
  }

  /// 亡霊（間違えた問題）との再戦：正解1問につき 8 EXP、全部倒せばさらに 30 EXP。
  static const expPerGhostCorrect = 8;
  static const ghostClearBonus = 30;

  static ExpGainResult applyGhostBattle(
      RpgProgress progress, BattleSummary summary) {
    final mistakes = {...progress.mistakes};
    for (final id in summary.correctIds) {
      if (!summary.missedQuestions.any((q) => q.id == id)) mistakes.remove(id);
    }
    final exp = summary.correctCount * expPerGhostCorrect +
        (summary.won ? ghostClearBonus : 0);
    final updated = Mastery.addByAnswers(
        Mastery.migrate(progress).copyWith(mistakes: mistakes), summary, exp);
    return addExp(updated, exp);
  }

  /// 練習のバトル（海・空・復習の塔・単元の練習など）の経験値。
  /// 冒険Lvと、正解した問題の科目の習熟に入る。
  static ExpGainResult applyPractice(
      RpgProgress progress, BattleSummary summary) {
    final exp = practiceExp(summary, progress.level);
    return addExp(
        Mastery.addByAnswers(Mastery.migrate(progress), summary, exp), exp);
  }

  /// 宝箱：難問1問に正解するとレアカード。失敗すると空っぽになる（1回きり）。
  static (RpgProgress, CardDef?) openChest(
      RpgProgress progress, String chestId, bool correct, Random random) {
    final opened =
        progress.copyWith(openedChests: {...progress.openedChests, chestId});
    if (!correct) return (opened, null);
    final rares = CardDef.rares;
    final card = rares[random.nextInt(rares.length)];
    return (opened.copyWith(deck: [...opened.deck, card.id]), card);
  }

  /// 泉：基礎問題に全問正解すると、次のバトルで最大HP +30%
  static const springHpRate = 0.3;

  static RpgProgress blessSpring(RpgProgress progress) =>
      progress.copyWith(springBuff: true);

  /// 宿の授業（練習問題）で得られる経験値：正解1問につき
  static const expPerTrainingCorrect = 2;

  /// 宿の授業を終えたときの経験値付与（[stage] の科目の習熟にも入る）
  static ExpGainResult applyTraining(RpgProgress progress, int correctCount,
      {StageDef? stage}) {
    final exp = correctCount * expPerTrainingCorrect;
    final course = stage == null ? null : Mastery.courseOfStage(stage);
    return addExp(Mastery.add(Mastery.migrate(progress), course, exp), exp);
  }

  /// 定期テストの海の結果を記録する（最高正答率だけ残す）
  static RpgProgress recordSea(RpgProgress progress, String id, int percent) {
    final best = progress.seaBest[id];
    if (best != null && best >= percent) return progress;
    return progress.copyWith(seaBest: {...progress.seaBest, id: percent});
  }

  /// ステージに挑戦できるか。1つ目のステージか、1つ前をクリア済みなら挑戦できる。
  static bool isStageUnlocked(
      RpgProgress progress, WorldDef world, StageDef stage) {
    if (!isWorldPlayable(progress, world)) return false;
    final prev = previousInBranch(world, stage);
    return prev == null || progress.clearedStageIds.contains(prev.id);
  }

  /// 同じ系統で1つ前のステージ（系統の最初なら null）
  static StageDef? previousInBranch(WorldDef world, StageDef stage) {
    StageDef? best;
    for (final s in world.stages) {
      if (s.branch != stage.branch || s.order >= stage.order) continue;
      if (best == null || s.order > best.order) best = s;
    }
    return best;
  }

  /// 同じ系統で1つ次のステージ（系統の最後なら null）
  static StageDef? nextInBranch(WorldDef world, StageDef stage) {
    StageDef? best;
    for (final s in world.stages) {
      if (s.branch != stage.branch || s.order <= stage.order) continue;
      if (best == null || s.order < best.order) best = s;
    }
    return best;
  }

  /// ワールドの中身があり、かつ無料または購入済みか。
  static bool isWorldPlayable(RpgProgress progress, WorldDef world) {
    if (world.isComingSoon) return false;
    return isWorldOwned(progress, world);
  }

  /// 無料または購入済みか（準備中でも購入済みなら true）。
  static bool isWorldOwned(RpgProgress progress, WorldDef world) =>
      world.isFree || progress.purchasedWorldIds.contains(world.id);
}
