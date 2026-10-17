import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri_quest_3d/game/bench.dart';
import 'package:tsuzuri_quest_3d/game/save3d.dart';

void main() {
  test('BenchStats：平均・分位・カクつきの数', () {
    final ms = [for (var i = 0; i < 98; i++) 16.0, 20.0, 50.0];
    final s = BenchStats.of(ms);
    expect(s.count, 100);
    expect(s.p50, 16);
    expect(s.max, 50);
    expect(s.over17, 2);
    expect(s.over33, 1);
    expect(s.jankPercent, 1);
    expect(s.avg, closeTo((98 * 16 + 70) / 100, 1e-9));
    expect(BenchStats.of(const []).count, 0);
    expect(BenchStats.empty.fps, 0);
  });

  test('BenchRun：ならしは数えず、画質を順に切りかえる', () {
    final run = BenchRun(
      const BenchPlan(qualities: ['high', 'light'], warmup: 1, measure: 2),
      device: 'テスト端末',
    );
    final changes = <String>[];
    expect(run.quality, 'high');
    // 60fps で 1 秒ならし → 2 秒計測
    for (var i = 0; i < 180 + 2; i++) {
      run.addFrame(i < 60 ? 100 : 16.7);
      run.addTiming(buildMs: 2, rasterMs: 8);
      run.addMemory(i < 60 ? 999 : 300 + i % 3);
      final next = run.tick(1 / 60);
      if (next != null) changes.add(next);
    }
    expect(changes, ['light']);
    expect(run.results, hasLength(1));
    final r = run.results.single;
    expect(r.quality, 'high');
    expect(r.frames.max, closeTo(16.7, 1e-9)); // ならしの 100ms は入らない
    expect(r.raster!.avg, 8);
    expect(r.memoryPeakMb, 302);
    while (!run.done) {
      run.addFrame(33.4);
      run.tick(1 / 30);
    }
    expect(run.results.map((r) => r.quality), ['high', 'light']);
    expect(run.progress, 1);
    expect(run.tick(1), isNull);
    // FrameTiming が来ない環境（Web など）
    expect(run.results.last.raster, isNull);
  });

  test('BenchReport：文章とログの 1 行', () {
    final run = BenchRun(
      const BenchPlan(qualities: ['standard'], warmup: 0, measure: 1),
      device: 'android 14',
    );
    while (!run.done) {
      run.addFrame(16);
      run.tick(0.016);
    }
    final rep = run.report(note: '初回表示 1.2秒');
    expect(rep.text(), contains('[標準] 62.5fps'));
    expect(rep.text(), contains('android 14'));
    expect(rep.logLine(), startsWith('TQ3D_BENCH {'));
    final m = jsonDecode(rep.json()) as Map<String, dynamic>;
    expect(m['device'], 'android 14');
    expect((m['results'] as List).single['quality'], 'standard');
  });

  test('Save3D：計測の記録は tq3d_ のキーに、新しい順で最大10件', () async {
    SharedPreferences.setMockInitialValues({});
    final save = await Save3D.open();
    for (var i = 0; i < 12; i++) {
      await save.addBench('{"n":$i}');
    }
    expect(Save3D.benchKey, startsWith('tq3d_'));
    expect(save.benchHistory, hasLength(10));
    expect(save.benchHistory.first, '{"n":11}');
  });
}
