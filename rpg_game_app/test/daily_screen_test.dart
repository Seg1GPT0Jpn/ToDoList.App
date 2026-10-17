import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('今日の挑戦状：エリアをクリアするとホームに出て、挑むとバトルになる', (t) async {
    final s = await openScreen(
      t,
      const WorldMapScreen(),
      size: const Size(420, 2400),
    );
    expect(find.textContaining('今日の挑戦状'), findsNothing);
    final stages = RpgCatalog.world(RpgCatalog.englishWorldId).stages;
    await t.runAsync(
      () => s.repository.save(
        RpgProgress.initial.copyWith(
          clearedStageIds: {for (final st in stages.take(3)) st.id},
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('今日の挑戦状'), findsOneWidget);
    await t.tap(find.text('挑む'));
    for (
      var i = 0;
      i < 20 && find.byType(BattleScreen).evaluate().isEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BattleScreen), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
  });
}
