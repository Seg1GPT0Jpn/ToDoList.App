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
