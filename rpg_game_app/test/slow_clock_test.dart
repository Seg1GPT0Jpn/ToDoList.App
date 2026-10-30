import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/art/slow_clock.dart';

void main() {
  testWidgets('飾りの時計は1つのタイマーで進み、描きなおしが同じ時にそろう', (t) async {
    final a = SlowClock(period: const Duration(seconds: 1), fps: 15);
    final b = SlowClock(period: const Duration(seconds: 1), fps: 12);
    final ticksA = <Duration>[], ticksB = <Duration>[];
    var now = Duration.zero;
    a.addListener(() => ticksA.add(now));
    b.addListener(() => ticksB.add(now));
    a.start();
    b.start();
    for (var i = 0; i < 100; i++) {
      now += const Duration(milliseconds: 10);
      await t.pump(const Duration(milliseconds: 10));
    }
    // 1秒で、いちばん細かい 15 回ずつ。どちらも同じ時に進む
    expect(ticksA.length, 15);
    expect(ticksB, ticksA);
    a.stop();
    ticksB.clear();
    await t.pump(const Duration(seconds: 1));
    // 残った時計は自分の回数（12回）で進む
    expect(ticksB.length, 12);
    b.dispose();
    expect(a.isRunning || b.isRunning, isFalse);
    ticksA.clear();
    await t.pump(const Duration(seconds: 1));
    expect(ticksA, isEmpty);
    a.dispose();
  });
}
