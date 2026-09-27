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
import 'package:rpg_game_app/study/sky_home_screen.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

ExamWorldPlan _plan({StudyRealm realm = StudyRealm.sea}) {
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
    realm: realm,
  );
}

Map<String, Object> _withPlan({StudyRealm realm = StudyRealm.sea}) => {
  'exam_worlds_v1': jsonEncode([_plan(realm: realm).toMap()]),
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

  testWidgets('模擬試験の空（教科・区切りの切りかえ）', (t) async {
    await openScreen(t, const SkyHomeScreen(), size: const Size(420, 1400));
    expect(find.textContaining('上級者向け'), findsWidgets);
    await t.tap(find.widgetWithText(ChoiceChip, '理科'));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('模試対策ワールド（空）の一覧・作成・遊ぶ画面', (t) async {
    final prefs = _withPlan(realm: StudyRealm.sky);
    await openScreen(
      t,
      const ExamWorldListScreen(realm: StudyRealm.sky),
      prefs: prefs,
    );
    expect(find.text('期末'), findsOneWidget);
    // 海の一覧には、空のワールドは出ない
    await openScreen(t, const ExamWorldListScreen(), prefs: prefs);
    expect(find.text('期末'), findsNothing);
    await openScreen(t, const ExamWorldCreateScreen(realm: StudyRealm.sky));
    await openScreen(t, const ExamWorldPlayScreen(planId: 'p1'), prefs: prefs);
    expect(find.textContaining('飛行船で出発する'), findsOneWidget);
  });

  for (final realm in StudyRealm.values) {
    testWidgets(
      '${realm.title}の航路のフィールド（${realm.vehicle}→${realm.deepVehicle}）',
      (t) async {
        await openScreen(
          t,
          FieldScreen.exam(
            plan: _plan(realm: realm),
            progress: RpgProgress.initial,
          ),
          prefs: _withPlan(realm: realm),
          frames: 30,
        );
        // 船（飛行船）で少し進んでも落ちない
        for (final icon in [
          Icons.keyboard_arrow_up,
          Icons.keyboard_arrow_left,
        ]) {
          await t.drag(find.byIcon(icon).first, Offset.zero);
          for (var i = 0; i < 5; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
        }
        expect(t.takeException(), isNull);
      },
    );
  }

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

  testWidgets('60エリアの試験対策ワールドのフィールドも開ける', (t) async {
    final plan = ExamWorldPlan(
      id: 'big',
      title: '学年末',
      worldId: 'math',
      stageIds: [
        for (final w in RpgCatalog.worlds)
          for (final s in w.stages.where((s) => !s.isBoss).take(10)) s.id,
      ],
      createdAt: DateTime(2026),
    );
    final sw = Stopwatch()..start();
    await openScreen(
      t,
      FieldScreen.exam(plan: plan, progress: RpgProgress.initial),
      frames: 30,
    );
    // 作るのに時間がかかりすぎない
    expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
  });
}
