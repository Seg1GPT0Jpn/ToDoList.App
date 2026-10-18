import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/meta/question_library_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 問題データの読み込み（本物の非同期）を待つ
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await _frames(t, 2);
  }
}

void main() {
  testWidgets('問題集：教科 → 問題セット → 問題を開くと正解と解説。答えをかくせる', (t) async {
    await openScreen(
      t,
      const QuestionLibraryScreen(),
      frames: 5,
      size: const Size(500, 1200),
    );
    await t.tap(find.byKey(const ValueKey('library-subject-japanese')));
    await _settle(t);
    final set = find.byKey(const ValueKey('library-set-japanese_gendai_05'));
    await t.scrollUntilVisible(
      set,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(set);
    await _frames(t);
    expect(find.byType(QuestionLibrarySetScreen), findsOneWidget);
    // 自動で作った敬語の問題もふくむ（収録24問より多い）
    expect(
      find.textContaining(RegExp(r'japanese_gendai_05・\d{3}問')),
      findsOneWidget,
    );
    await t.tap(find.textContaining('Q1. '));
    await _frames(t, 5);
    expect(find.textContaining('解説：'), findsOneWidget);
    expect(find.textContaining('✓'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('library-hide')));
    await _frames(t, 3);
    expect(find.textContaining('解説：'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('問題集：教科の全問題からことばで探せる', (t) async {
    await openScreen(
      t,
      const QuestionLibraryScreen(),
      frames: 5,
      size: const Size(500, 1200),
    );
    await t.tap(find.byKey(const ValueKey('library-subject-japanese')));
    await _settle(t);
    await t.enterText(find.byKey(const ValueKey('library-search')), '召し上がる');
    await _frames(t, 3);
    expect(find.textContaining('問見つかりました'), findsOneWidget);
    expect(find.textContaining('Q1. '), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
