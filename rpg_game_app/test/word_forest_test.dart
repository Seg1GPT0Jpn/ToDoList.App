import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/vocab/word_forest_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('単語の森：リストを切りかえ、森で戦うと単語のモンスターが出る', (t) async {
    await openScreen(t, const WordForestScreen(), frames: 20);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await t.pump(const Duration(milliseconds: 100));
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

  testWidgets('単語の森：つづ単を選んで読み込める', (t) async {
    await openScreen(t, const WordForestScreen(), frames: 20);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const ValueKey('wordlist-tsuzutan')));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.textContaining('つづ単 基礎 1（').last);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('コレクション 0 / 200'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('RPG の英語バトルに、つづ単の単語問題が混ざる', (t) async {
    final services = await openScreen(t, const SizedBox(), frames: 2);
    final pool = await t.runAsync(
      () => services.loadStagePool(RpgCatalog.englishStages.first),
    );
    expect(pool, isNotNull);
    expect(
      pool!.questions.where((q) => q.id.startsWith('tsuzutan_1_')),
      isNotEmpty,
    );
    // 学習記録に残せるよう、もとの単語帳がわかる
    final q = pool.questions.firstWhere((q) => q.id.startsWith('tsuzutan_'));
    expect(services.questions.setIdOf(q.id), startsWith('tsuzutan_1_'));
  });
}
