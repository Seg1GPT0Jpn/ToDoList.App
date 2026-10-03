import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/account/welcome_screen.dart';
import 'package:rpg_game_app/main.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('はじめての起動ではログイン画面が出て、ログインせずにはじめられる', (t) async {
    final s = await openScreen(
      t,
      const TsuzuriQuestApp(),
      frames: 20,
      bare: true,
    );
    expect(find.byType(WelcomeScreen), findsOneWidget);
    // Firebase 未設定（テスト）では Google ボタンは出さない
    expect(find.byKey(const ValueKey('welcome-google')), findsNothing);

    await t.tap(find.byKey(const ValueKey('welcome-guest')));
    await _frames(t, 5);
    expect(find.text('ようこそ、つづりクエストへ！'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'つづり');
    await t.tap(find.text('決定'));
    await _frames(t, 10);

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(WorldMapScreen), findsOneWidget);
    expect(s.profiles.load().userName, 'つづり');
    expect(t.takeException(), isNull);
  });

  testWidgets('名前がある（2回目以降の）起動ではログイン画面を出さない', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 1);
    await s.profiles.save(s.profiles.load().copyWith(userName: 'つづり'));
    await openScreen(
      t,
      const TsuzuriQuestApp(),
      frames: 20,
      bare: true,
      keepPrefs: true,
    );
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(WorldMapScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
