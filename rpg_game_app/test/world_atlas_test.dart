import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/field/field_screen.dart';
import 'package:rpg_game_app/world/world_atlas.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('世界地図：すべての国が地図にあり、英語ワールドをタップすると旅立つ', (t) async {
    await openScreen(t, const WorldMapScreen(), size: const Size(420, 2600));
    await _frames(t);
    expect(find.byType(WorldAtlas), findsOneWidget);
    for (final id in WorldAtlas.spots.keys) {
      expect(
        find.byKey(ValueKey('atlas-label-$id')),
        findsOneWidget,
        reason: id,
      );
    }
    // 国の位置は地図の中におさまる
    for (final s in WorldAtlas.spots.values) {
      expect(s.dx, inInclusiveRange(0.05, 0.95));
      expect(s.dy, inInclusiveRange(0.05, 0.95));
    }
    await t.tap(find.byKey(const ValueKey('atlas-label-english')));
    await _frames(t, 10);
    expect(find.byType(FieldScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('まだ行けない国をタップすると、行き方を案内する', (t) async {
    await openScreen(t, const WorldMapScreen(), size: const Size(420, 2600));
    await _frames(t);
    final science = RpgCatalog.world('science');
    await t.tap(find.byKey(const ValueKey('atlas-label-science')));
    await _frames(t);
    expect(find.byType(FieldScreen), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining(science.name), findsWidgets);
  });
}
