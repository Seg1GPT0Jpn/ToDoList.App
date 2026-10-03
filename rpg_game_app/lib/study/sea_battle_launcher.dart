import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../battle/battle_screen.dart';

/// 定期テストの海（高校入試の空）の単元で、海（空）の魔物とバトルする（とても難しい）。
///
/// RPG の進行・経験値は変えない。正答率の自己ベストだけを記録する。
/// 高校入試の空の記録は [skyRecordId] の ID で、海とは別に残す。
Future<void> startSeaBattle(
  BuildContext context, {
  required String title,
  required String recordId,
  required List<QuizQuestion> questions,
  required String worldId,
  required int normalTimeLimitSeconds,
  StudyRealm realm = StudyRealm.sea,
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
    realm: realm,
  );
  final bestId = realm == StudyRealm.sea ? recordId : skyRecordId(recordId);
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BattleScreen(
        world: RpgCatalog.world(worldId),
        stage: stage,
        questions: questions,
        progress: progress,
        trial: true,
        mode: BattleMode.sea,
        onFinished: (summary) async {
          if (summary.answeredCount == 0) return;
          final latest = await repo.load();
          await repo.save(
            Progression.recordSea(
              latest,
              bestId,
              (summary.accuracy * 100).round(),
            ),
          );
        },
      ),
    ),
  );
}

/// 高校入試の空での自己ベストの ID
String skyRecordId(String id) => 'sky:$id';
