import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/vocab/word_forest_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('単語の森：リストを切りかえ、森で戦うと単語のモンスターが出る', (t) async {
    await openScreen(t, const WordForestScreen(), frames: 20);
    expect(find.textContaining('コレクション 0 /'), findsOneWidget);
    expect(find.text('？？？'), findsWidgets);
    // 忘れかけの単語がないので、忘却の塔はまだ押せない
    final tower = t.widget<OutlinedButton>(
      find.byKey(const ValueKey('forest-tower')),
    );
    expect(tower.onPressed, isNull);
    await t.tap(find.byKey(const ValueKey('wordlist-idioms_basic')));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const ValueKey('forest-battle')));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });
}
