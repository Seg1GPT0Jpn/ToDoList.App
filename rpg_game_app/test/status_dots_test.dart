import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/vocab/status_dots.dart';

void main() {
  testWidgets('覚えぐあいの絵文字は、色を塗った丸として描く（絵文字のフォントを使わない）', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: DotText('🔴 弱点 2語　🟢 安定 5語'))),
    );
    final dots = t
        .widgetList<Container>(find.byType(Container))
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toList();
    expect(dots, [statusDotColors['🔴'], statusDotColors['🟢']]);
    expect(find.textContaining('弱点 2語'), findsOneWidget);
    expect(find.textContaining('🔴'), findsNothing);
  });
}
