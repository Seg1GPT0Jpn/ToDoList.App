import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/main.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('設定で「ダーク」にすると、アプリ全体がダークモードの色になる', (t) async {
    // 名前があればはじめてのログイン画面は出ない
    final first = await openScreen(t, const SizedBox(), frames: 1);
    await first.profiles.save(first.profiles.load().copyWith(userName: 'つづり'));
    final s = await openScreen(
      t,
      const TsuzuriQuestApp(),
      frames: 20,
      bare: true,
      keepPrefs: true,
    );
    expect(TsuzuriColors.dark, isFalse);
    expect(find.byType(WorldMapScreen), findsOneWidget);
    await s.settings.update(s.settings.value.copyWith(theme: 'dark'));
    await _frames(t, 5);
    expect(TsuzuriColors.dark, isTrue);
    expect(TsuzuriColors.paper, TsuzuriColors.darkBg);
    final theme = Theme.of(t.element(find.byType(WorldMapScreen)));
    expect(theme.brightness, Brightness.dark);
    await s.settings.update(s.settings.value.copyWith(theme: 'light'));
    await _frames(t, 5);
    expect(TsuzuriColors.dark, isFalse);
    expect(t.takeException(), isNull);
  });
}
