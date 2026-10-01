import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../battle/battle_screen.dart';
import 'services.dart';

/// 単元の練習バトルを始める（RPG の進行は変えない。答えた記録は熟練度に反映される）
Future<void> startPractice(BuildContext context, StageDef stage) async {
  final services = RpgServices.of(context);
  final pool = await services.loadStagePool(stage);
  final progress = await services.repository.load();
  if (pool == null || !pool.origin.usableInRpg || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BattleScreen(
        world: RpgCatalog.world(stage.worldId),
        // 高いレベルでも1問で終わらないよう、レベルに合わせた強さにする
        stage: PracticeBattle.stage(stage, progress.level),
        questions: pool.questions,
        progress: progress,
        trial: true,
        mode: BattleMode.review,
      ),
    ),
  );
}

/// 学習体系の単元・小単元だけで練習バトルをする（学びの地図から）。
///
/// 戻り値：始められなかった理由（始められたら null）
Future<String?> startUnitPractice(BuildContext context, String unitId) async {
  final services = RpgServices.of(context);
  final node = Curriculum.node(unitId);
  final world = RpgCatalog.worlds
      .where((w) => w.id == node.subjectId)
      .firstOrNull;
  if (world == null) return 'この教科の冒険はまだありません';
  final progress = await services.repository.load();
  if (services.unlock.availabilityOf(progress, world) !=
      WorldAvailability.playable) {
    return '${world.name}を解放すると練習できます';
  }
  final questions = <QuizQuestion>[];
  StageDef? base;
  for (final setId in CurriculumProgress.setsFor(unitId)) {
    final set = await services.questions.load(setId);
    if (set == null || !set.origin.usableInRpg) continue;
    questions.addAll(
      set.questions.where(
        (q) => q.unit == unitId || (q.unit?.startsWith('$unitId.') ?? false),
      ),
    );
    base ??= Proficiency.stageOfSet(setId);
  }
  if (questions.length < 4) return 'この単元の問題はまだ少ないため、練習できません';
  if (!context.mounted) return null;
  base ??= world.stages.first;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BattleScreen(
        world: world,
        stage: PracticeBattle.stage(
          base!,
          progress.level,
          hits: questions.length.clamp(4, PracticeBattle.hits),
        ),
        questions: questions,
        progress: progress,
        trial: true,
        mode: BattleMode.review,
      ),
    ),
  );
  return null;
}
