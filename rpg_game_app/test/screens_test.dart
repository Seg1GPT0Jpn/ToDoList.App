import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_screen.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/field/field_screen.dart';
import 'package:rpg_game_app/meta/achievements_screen.dart';
import 'package:rpg_game_app/meta/settings_screen.dart';
import 'package:rpg_game_app/study/exam_world_screens.dart';
import 'package:rpg_game_app/study/inn_screen.dart';
import 'package:rpg_game_app/study/review_notebook_screen.dart';
import 'package:rpg_game_app/study/sea_home_screen.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

ExamWorldPlan _plan() {
  final picked = ExamWorlds.matchAll({
    'math': '2次関数',
    RpgCatalog.englishWorldId: '関係詞',
  });
  return ExamWorldPlan(
    id: 'p1',
    title: '期末',
    worldId: 'math',
    stageIds: [for (final s in picked) s.id],
    createdAt: DateTime(2026),
    examDate: DateTime.now().add(const Duration(days: 5)),
  );
}

Map<String, Object> _withPlan() => {
  'exam_worlds_v1': jsonEncode([_plan().toMap()]),
};

void main() {
  final english = RpgCatalog.world(RpgCatalog.englishWorldId);
  final science = RpgCatalog.world('science');

  testWidgets('ホーム（ワールドマップ）', (t) async {
    await openScreen(t, const WorldMapScreen(), size: const Size(420, 1600));
  });
  testWidgets('実績', (t) => openScreen(t, const AchievementsScreen()));
  testWidgets('設定', (t) => openScreen(t, const SettingsScreen()));
  testWidgets('アカウント', (t) => openScreen(t, const AccountScreen()));
  testWidgets(
    '定期テストの海',
    (t) => openScreen(
      t,
      Builder(
        builder: (c) =>
            SeaHomeScreen(personalBooks: RpgServices.of(c).personalBooks),
      ),
    ),
  );
  testWidgets(
    '宿の授業',
    (t) => openScreen(t, InnScreen(stage: english.stages[1])),
  );
  testWidgets(
    '復習手帳',
    (t) => openScreen(
      t,
      ReviewNotebookScreen(world: english, progress: RpgProgress.initial),
    ),
  );

  testWidgets('試験対策ワールドの一覧・作成・遊ぶ画面', (t) async {
    await openScreen(t, const ExamWorldListScreen(), prefs: _withPlan());
    await openScreen(t, const ExamWorldCreateScreen());
    await openScreen(
      t,
      const ExamWorldPlayScreen(planId: 'p1'),
      prefs: _withPlan(),
    );
  });

  testWidgets('英語ワールドのフィールド', (t) async {
    await openScreen(
      t,
      FieldScreen(world: english, progress: RpgProgress.initial),
      frames: 30,
    );
  });

  testWidgets('理の国のハブと、各ルートのフィールド', (t) async {
    await openScreen(
      t,
      FieldScreen(world: science, progress: RpgProgress.initial),
    );
    for (final r in science.routes) {
      await openScreen(
        t,
        FieldScreen(
          world: science,
          progress: RpgProgress.initial,
          mapId: 'science_${r.id}',
        ),
      );
    }
  });

  testWidgets('試験対策ワールドのフィールド（6教科ミックス）', (t) async {
    await openScreen(
      t,
      FieldScreen.exam(plan: _plan(), progress: RpgProgress.initial),
      prefs: _withPlan(),
      frames: 30,
    );
  });

  testWidgets('フィールドで歩いても落ちない', (t) async {
    await openScreen(
      t,
      FieldScreen(world: english, progress: RpgProgress.initial),
      frames: 5,
    );
    for (final key in ['up', 'up', 'left', 'up', 'right', 'right', 'down']) {
      await t.drag(
        find.byIcon(switch (key) {
          'up' => Icons.keyboard_arrow_up,
          'down' => Icons.keyboard_arrow_down,
          'left' => Icons.keyboard_arrow_left,
          _ => Icons.keyboard_arrow_right,
        }).first,
        Offset.zero,
      );
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }
    expect(t.takeException(), isNull);
  });
}
