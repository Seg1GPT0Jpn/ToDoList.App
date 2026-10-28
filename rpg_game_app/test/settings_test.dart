import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/app/haptics.dart';
import 'package:rpg_game_app/app/settings.dart';

void main() {
  test('振動・すべての機能の表示は、保存して読みなおせる（振動ははじめ ON）', () {
    expect(const AppSettings().vibration, isTrue);
    expect(const AppSettings().allFeatures, isFalse);
    final s = AppSettings.fromMap(
      const AppSettings(vibration: false, allFeatures: true).toMap(),
    );
    expect(s.vibration, isFalse);
    expect(s.allFeatures, isTrue);
    // 前の版で保存した設定（項目がない）は、はじめの値になる
    expect(AppSettings.fromMap(const {}).vibration, isTrue);
  });

  testWidgets('振動を切ると、ふるえない', (t) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate')
          calls.add('${call.arguments}');
        return null;
      },
    );
    final store = SettingsStore.memory();
    final h = Haptics(store);
    h.hit();
    h.heavy();
    expect(calls, hasLength(2));
    await store.update(const AppSettings(vibration: false));
    h.hit();
    h.strong();
    expect(calls, hasLength(2));
  });
}
