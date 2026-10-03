import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/study/exam_world_screens.dart';

import 'harness.dart';

void main() {
  testWidgets('試験対策ワールドを作る：教科を選ぶ・外す・範囲を探す・つくる', (t) async {
    final services = await openScreen(
      t,
      const ExamWorldCreateScreen(),
      size: const Size(420, 2400),
    );
    // 英語（無料）を選んで、外して、また選ぶ
    for (var i = 0; i < 3; i++) {
      await t.tap(find.widgetWithText(FilterChip, '英語'));
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull, reason: '英語のチップ $i 回目');
    }
    await t.enterText(find.byType(TextField).last, '関係代名詞、仮定法');
    await t.tap(find.text('範囲から探す'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('エリア見つかりました'), findsOneWidget);
    // 英語の国は56エリアあるので、ボタンまでスクロールする
    final make = find.textContaining('ワールドとフィールドをつくる');
    await t.scrollUntilVisible(make, 400, scrollable: find.byType(Scrollable).first);
    await t.tap(make);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
    expect(services.examWorlds.load(), hasLength(1));
    expect(services.examWorlds.load().first.stageIds, isNotEmpty);
  });
}
