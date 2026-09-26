import '../battle/battle_engine.dart';
import '../models/player_stats.dart';
import '../models/rpg_progress.dart';
import '../models/stage.dart';
import '../models/world.dart';

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
  });

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
  static StageClearResult applyBattle({
    required RpgProgress progress,
    required WorldDef world,
    required StageDef stage,
    required BattleSummary summary,
  }) {
    final alreadyCleared = progress.clearedStageIds.contains(stage.id);
    final gained = expFor(stage, summary, alreadyCleared: alreadyCleared);

    var updated = progress;
    String? unlocked;
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
        final next = world.stages.where((s) => s.order == stage.order + 1);
        if (next.isNotEmpty) unlocked = next.first.id;
      }
    }

    return StageClearResult(
      expResult: addExp(updated, gained),
      firstClear: summary.won && !alreadyCleared,
      newlyUnlockedStageId: unlocked,
    );
  }

  /// ステージに挑戦できるか。1つ目のステージか、1つ前をクリア済みなら挑戦できる。
  static bool isStageUnlocked(
      RpgProgress progress, WorldDef world, StageDef stage) {
    if (!isWorldPlayable(progress, world)) return false;
    if (stage.order == 1) return true;
    return world.stages.any((s) =>
        s.order == stage.order - 1 && progress.clearedStageIds.contains(s.id));
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
