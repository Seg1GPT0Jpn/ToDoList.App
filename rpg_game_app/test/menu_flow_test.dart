import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/deck_screen.dart';
import 'package:rpg_game_app/meta/equipment_screen.dart';
import 'package:rpg_game_app/study/common_test_screens.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('デッキ：おまかせで組んで保存できる', (t) async {
    final s = await openScreen(
      t,
      const DeckScreen(progress: RpgProgress.initial),
      size: const Size(420, 2000),
    );
    await t.tap(find.text('防御重視'));
    await _frames(t, 3);
    await t.tap(find.text('このデッキで戦う'));
    await _frames(t, 5);
    expect(t.takeException(), isNull);
    final p = await s.repository.load();
    expect(p.activeDeck, isNotEmpty);
    expect(CardDef.byId(p.activeDeck.first).type, CardType.defense);
    await _frames(t, 40);
  });

  testWidgets('装備・職業：職業を変えられる', (t) async {
    final s = await openScreen(
      t,
      const EquipmentScreen(),
      size: const Size(420, 2400),
    );
    await t.tap(find.widgetWithText(ChoiceChip, '賢者'));
    await _frames(t, 5);
    expect(t.takeException(), isNull);
    expect((await s.repository.load()).job, 'sage');
    await t.tap(find.text('ノートの鎧'));
    await _frames(t, 5);
    expect(t.takeException(), isNull);
  });

  testWidgets('模試ダンジョン：英語を選んで全問答えると、結果と弱点が出る', (t) async {
    final s = await openScreen(
      t,
      const MockExamScreen(),
      size: const Size(420, 1400),
    );
    await t.tap(find.widgetWithText(FilterChip, '英語'));
    await _frames(t, 2);
    await t.tap(find.textContaining('模試を始める'));
    await _frames(t, 20);
    for (var i = 0; i < MockExam.perSubject; i++) {
      final choices = find.byType(OutlinedButton);
      expect(choices, findsWidgets, reason: '$i 問目');
      await t.tap(choices.first);
      await _frames(t, 3);
    }
    await _frames(t, 10);
    expect(find.text('今回の冒険結果'), findsOneWidget);
    expect(find.textContaining('/ 100'), findsWidgets);
    expect(t.takeException(), isNull);
    // 答えた記録が学習記録に残る
    expect(s.meta.record.stats, isNotEmpty);
  });

  testWidgets('共通テスト遺跡：第1階層のバトルを始められる', (t) async {
    await openScreen(
      t,
      const CommonTestRuinsScreen(),
      size: const Size(420, 1400),
    );
    expect(find.textContaining('第1階層'), findsOneWidget);
    // 問題ファイルを先に（本物の非同期で）読み込んでおく。読み込みはキャッシュされる
    // 前のテストが偽の時間の中で始めた読み込みがキャッシュに残らないよう、消しておく
    rootBundle.clear();
    final services = RpgServicesHolder.last!;
    await t.runAsync(() async {
      for (final w in RpgCatalog.worlds) {
        for (final s in w.stages) {
          await services.loadStagePool(s);
        }
      }
    });
    await t.tap(find.textContaining('第1階層'));
    // 問題の読み込み（本物のファイル読み込み）を待つ
    for (
      var i = 0;
      i < 150 && find.textContaining('遺跡の見張り').evaluate().isEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    await _frames(t, 40);
    expect(t.takeException(), isNull);
    expect(find.textContaining('遺跡の見張り'), findsWidgets);
    await _frames(t, 40);
  });
}
