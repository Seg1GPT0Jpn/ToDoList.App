import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../battle/battle_screen.dart';

/// 定期テストの海の単元で、海の魔物とバトルする（とても難しい）。
///
/// RPG の進行・経験値は変えない。正答率の自己ベストだけを記録する。
Future<void> startSeaBattle(
  BuildContext context, {
  required String title,
  required String recordId,
  required List<QuizQuestion> questions,
  required String worldId,
  required int normalTimeLimitSeconds,
}) async {
  final services = RpgServices.of(context);
  final repo = services.repository;
  final progress = await repo.load();
  if (!context.mounted || questions.isEmpty) return;
  final stage = SeaBattle.stage(
    id: recordId,
    title: title,
    worldId: worldId,
    level: progress.level,
    normalTimeLimitSeconds: normalTimeLimitSeconds,
  );
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BattleScreen(
        world: RpgCatalog.world(worldId),
        stage: stage,
        questions: questions,
        progress: progress,
        trial: true,
        onFinished: (summary) async {
          if (summary.answeredCount == 0) return;
          final latest = await repo.load();
          await repo.save(
            Progression.recordSea(
              latest,
              recordId,
              (summary.accuracy * 100).round(),
            ),
          );
        },
      ),
    ),
  );
}
