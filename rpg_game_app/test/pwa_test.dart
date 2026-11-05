import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/app/pwa.dart';

import 'harness.dart';

void main() {
  testWidgets('ブラウザの iPhone だけに、ホーム画面に追加する案内を出す。閉じたら出さない', (t) async {
    const safari = PwaInfo(ios: true, standalone: false);
    await openScreen(t, const AddToHomeHint(info: safari), frames: 3);
    expect(find.byKey(const ValueKey('pwa-hint')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('pwa-hint-close')));
    await t.pump();
    expect(find.byKey(const ValueKey('pwa-hint')), findsNothing);
    await openScreen(
      t,
      const AddToHomeHint(info: safari),
      frames: 3,
      keepPrefs: true,
    );
    expect(find.byKey(const ValueKey('pwa-hint')), findsNothing);
    // ホーム画面から開いているとき・iPhone でないときは出さない
    for (final info in const [
      PwaInfo(ios: true, standalone: true),
      PwaInfo(ios: false, standalone: false),
    ]) {
      await openScreen(t, AddToHomeHint(info: info), frames: 3);
      expect(find.byKey(const ValueKey('pwa-hint')), findsNothing);
    }
  });
}
