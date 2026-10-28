import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/meta/home_feature_store.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('はじめての人：機能は少しだけ。クリアすると「NEW」つきで増える', (t) async {
    final s = await openScreen(
      t,
      const WorldMapScreen(),
      size: const Size(420, 2400),
    );
    await _frames(t);
    expect(
      find.byKey(const ValueKey('home-feature-classroom')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-feature-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-feature-versus')), findsNothing);
    expect(find.text('模擬試験の空'), findsNothing);
    expect(find.textContaining('エリアをあと 1 つクリアすると「復習の塔」'), findsOneWidget);
    // クエストは、まだ遊んでいない教科（音楽など）を出さない
    expect(find.textContaining('音楽で'), findsNothing);
    expect(find.textContaining('音楽のバトル'), findsNothing);
    // はじめから出ている機能は NEW にしない
    expect(find.byKey(const ValueKey('home-new-classroom')), findsNothing);

    final english = RpgCatalog.world(RpgCatalog.englishWorldId);
    await s.repository.save(
      RpgProgress.initial.copyWith(clearedStageIds: {english.stages.first.id}),
    );
    await _frames(t);
    expect(find.byKey(const ValueKey('home-new-reviewTower')), findsOneWidget);
    await s.homeFeatures.markSeen(HomeFeature.reviewTower);
    await _frames(t);
    expect(find.byKey(const ValueKey('home-new-reviewTower')), findsNothing);
    expect(find.byKey(const ValueKey('home-new-story')), findsOneWidget);
  });

  test('前から遊んでいた人：いま出ている機能は NEW にしない', () async {
    SharedPreferences.setMockInitialValues({});
    final store = HomeFeatureStore(await SharedPreferences.getInstance());
    store.prepare(HomeFeature.values.where((f) => f.clears <= 3));
    expect(store.isNew(HomeFeature.library), isFalse);
    expect(store.isNew(HomeFeature.versus), isTrue);
    // 2回目からは上書きしない
    store.prepare(HomeFeature.values);
    expect(store.isNew(HomeFeature.versus), isTrue);
  });

  testWidgets('「すべての機能を表示」にすると全部出る', (t) async {
    final s = await openScreen(
      t,
      const WorldMapScreen(),
      size: const Size(420, 2400),
    );
    await s.settings.update(const AppSettings(allFeatures: true));
    await _frames(t);
    for (final f in HomeFeature.values) {
      expect(find.byKey(ValueKey('home-feature-${f.name}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('home-next-feature')), findsNothing);
    expect(find.text('模擬試験の空'), findsWidgets);
  });
}
