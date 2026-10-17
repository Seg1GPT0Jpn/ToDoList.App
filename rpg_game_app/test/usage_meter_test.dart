import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/app/usage_meter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sink implements UsageSink {
  final sent = <String>[];
  @override
  Future<void> count(String day, String feature) async =>
      sent.add('$day $feature');
}

void main() {
  test('1つの機能につき1日1回だけ送る。知らない機能・止めたときは送らない', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sink = _Sink();
    var on = true;
    final meter = UsageMeter(prefs, sink, () => on);
    final d1 = DateTime(2026, 10, 17, 9);
    await meter.open('vocab', now: d1);
    await meter.open('vocab', now: d1.add(const Duration(hours: 3)));
    await meter.open('duel', now: d1);
    await meter.open('secret', now: d1);
    await meter.open('vocab', now: DateTime(2026, 10, 18));
    on = false;
    await meter.open('battle', now: DateTime(2026, 10, 18));
    expect(sink.sent, [
      '2026-10-17 vocab',
      '2026-10-17 duel',
      '2026-10-18 vocab',
    ]);
  });
}
