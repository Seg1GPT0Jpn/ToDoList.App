import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import 'theme.dart';

/// 画面をまたいでお知らせを出す（実績の解除など）
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// 実績の解除・クエスト達成を知らせる
void showMetaToast({
  List<AchievementDef> achievements = const [],
  List<QuestDef> quests = const [],
}) {
  final m = rootMessengerKey.currentState;
  if (m == null || (achievements.isEmpty && quests.isEmpty)) return;
  final lines = [
    for (final a in achievements) '🏅 実績「${a.title}」を解除！（称号にできます）',
    for (final q in quests) '📜 クエスト達成：${q.title}（ホームで報酬を受け取れます）',
  ];
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: TsuzuriColors.ink,
      duration: Duration(seconds: 3 + lines.length),
      content: Text(lines.join('\n')),
    ),
  );
}
