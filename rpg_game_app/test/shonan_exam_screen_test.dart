import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/study/shonan_exam_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('湘南高校モードで定期テストを作成して一覧へ戻れる', (tester) async {
    await openScreen(
      tester,
      const ShonanExamHomeScreen(),
      size: const Size(420, 2400),
    );
    await tester.pumpAndSettle();

    expect(find.text('湘南高校モード'), findsOneWidget);
    await tester.tap(find.text('定期テストを登録'));
    await tester.pumpAndSettle();

    expect(find.text('現代の国語（現代文）'), findsOneWidget);
    expect(find.text('情報Ⅰ'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '後期中間試験');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('後期中間試験'), findsOneWidget);
    expect(find.textContaining('情報登録済み 0/11科目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
