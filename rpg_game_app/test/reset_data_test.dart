import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/meta/reset_data_screen.dart';
import 'package:rpg_game_app/meta/settings_screen.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

void main() {
  Future<void> openReset(WidgetTester t) async {
    await openScreen(t, const SettingsScreen(), size: const Size(420, 2400));
    await t.tap(find.byKey(const ValueKey('reset-data-open')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('ホーム右上のメニューにはデータのリセットがない', (t) async {
    await openScreen(t, const WorldMapScreen(), size: const Size(420, 1600));
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('データをリセット'), findsNothing);
  });

  testWidgets('数秒待つと赤いボタンが出て、本当に削除するか聞いてから消す', (t) async {
    await openReset(t);
    final services = RpgServicesHolder.last!;
    await services.repository.save(RpgProgress.initial.copyWith(level: 5));
    // すぐには押せない
    expect(find.byKey(const ValueKey('reset-data')), findsNothing);
    expect(find.textContaining('あと3秒'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('reset-data')), findsNothing);
    await t.pump(ResetDataScreen.wait);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('reset-data')), findsOneWidget);

    // 確かめる画面で「やめる」なら消さない
    await t.tap(find.byKey(const ValueKey('reset-data')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('データを本当に削除しますか？'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('reset-cancel')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect((await services.repository.load()).level, 5);

    // 「削除する」で消して、設定にもどる
    await t.tap(find.byKey(const ValueKey('reset-data')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const ValueKey('reset-delete')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect((await services.repository.load()).level, RpgProgress.initial.level);
    expect(find.byType(ResetDataScreen), findsNothing);
    expect(find.text('データをリセットしました'), findsOneWidget);
  });
}
