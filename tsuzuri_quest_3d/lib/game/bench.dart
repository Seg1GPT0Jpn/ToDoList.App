import 'dart:convert';
import 'dart:math' as math;

/// 自動計測（ベンチマーク）の集計。描画なし・純 Dart なので単体テストできる。
///
/// 画質ごとに「ならし（warmup）→ 計測（measure）」を順に行い、
/// フレームの間隔（画面が実際に更新された間隔）と、エンジンが測った
/// build・raster の時間（FrameTiming。Android の profile／release で取れる）をまとめる。
class BenchPlan {
  const BenchPlan({
    this.qualities = const ['high', 'standard', 'light'],
    this.warmup = 3,
    this.measure = 15,
  });

  final List<String> qualities;

  /// 秒
  final double warmup;

  /// 秒
  final double measure;

  double get total => qualities.length * (warmup + measure);
}

/// 計測の進み具合。毎フレーム [tick] に経過秒を渡す
class BenchRun {
  BenchRun(this.plan, {required this.device});

  final BenchPlan plan;
  final String device;
  final results = <BenchResult>[];

  int _index = 0;
  double _t = 0;
  BenchSampler _sampler = BenchSampler();

  bool get done => _index >= plan.qualities.length;
  String get quality =>
      plan.qualities[math.min(_index, plan.qualities.length - 1)];
  bool get warmingUp => _t < plan.warmup;

  /// 全体の進み（0〜1）
  double get progress => done
      ? 1
      : ((_index * (plan.warmup + plan.measure) + _t) / plan.total).clamp(0, 1);

  /// 計測中だけ記録する
  void addFrame(double ms) {
    if (!done && !warmingUp) _sampler.addFrame(ms);
  }

  void addTiming({required double buildMs, required double rasterMs}) {
    if (!done && !warmingUp) {
      _sampler.addTiming(buildMs: buildMs, rasterMs: rasterMs);
    }
  }

  void addMemory(int? mb) {
    if (!done && !warmingUp) _sampler.addMemory(mb);
  }

  /// 経過を進める。画質が切りかわったら次の画質を返す（終わったら null）
  String? tick(double dt) {
    if (done) return null;
    _t += dt;
    if (_t < plan.warmup + plan.measure) return null;
    results.add(_sampler.result(quality, plan.measure));
    _index++;
    _t = 0;
    _sampler = BenchSampler();
    return done ? null : quality;
  }

  BenchReport report({String? note}) =>
      BenchReport(device: device, results: results, note: note);
}

/// 1 つの画質の記録
class BenchSampler {
  final frames = <double>[];
  final builds = <double>[];
  final rasters = <double>[];
  int? memoryPeak;

  void addFrame(double ms) {
    if (ms > 0) frames.add(ms);
  }

  void addTiming({required double buildMs, required double rasterMs}) {
    builds.add(buildMs);
    rasters.add(rasterMs);
  }

  void addMemory(int? mb) {
    if (mb != null && (memoryPeak == null || mb > memoryPeak!)) memoryPeak = mb;
  }

  BenchResult result(String quality, double seconds) => BenchResult(
    quality: quality,
    seconds: seconds,
    frames: BenchStats.of(frames),
    build: builds.isEmpty ? null : BenchStats.of(builds),
    raster: rasters.isEmpty ? null : BenchStats.of(rasters),
    memoryPeakMb: memoryPeak,
  );
}

/// 時間（ms）の並びの要約
class BenchStats {
  const BenchStats({
    required this.count,
    required this.avg,
    required this.p50,
    required this.p95,
    required this.p99,
    required this.max,
    required this.over17,
    required this.over33,
  });

  final int count;
  final double avg;
  final double p50;
  final double p95;
  final double p99;
  final double max;

  /// 16.7ms（60fps の 1 フレーム）をこえた数
  final int over17;

  /// 33.3ms（30fps の 1 フレーム）をこえた数＝目に見えるカクつき
  final int over33;

  static const empty = BenchStats(
    count: 0,
    avg: 0,
    p50: 0,
    p95: 0,
    p99: 0,
    max: 0,
    over17: 0,
    over33: 0,
  );

  factory BenchStats.of(List<double> ms) {
    if (ms.isEmpty) return empty;
    final s = [...ms]..sort();
    double pct(double p) => s[((s.length - 1) * p).round()];
    return BenchStats(
      count: s.length,
      avg: s.fold<double>(0, (a, b) => a + b) / s.length,
      p50: pct(0.5),
      p95: pct(0.95),
      p99: pct(0.99),
      max: s.last,
      over17: s.where((v) => v > 1000 / 60 + 0.5).length,
      over33: s.where((v) => v > 1000 / 30 + 0.5).length,
    );
  }

  double get fps => avg <= 0 ? 0 : 1000 / avg;

  /// 1 フレームが 33ms をこえた割合（%）
  double get jankPercent => count == 0 ? 0 : over33 * 100 / count;

  Map<String, Object> toMap() => {
    'n': count,
    'avg': _r(avg),
    'p50': _r(p50),
    'p95': _r(p95),
    'p99': _r(p99),
    'max': _r(max),
    'over17': over17,
    'over33': over33,
  };

  static double _r(double v) => (v * 10).roundToDouble() / 10;
}

class BenchResult {
  const BenchResult({
    required this.quality,
    required this.seconds,
    required this.frames,
    this.build,
    this.raster,
    this.memoryPeakMb,
  });

  final String quality;
  final double seconds;

  /// 画面の更新の間隔（見た目のなめらかさ）
  final BenchStats frames;

  /// UI スレッドの時間（FrameTiming。取れない環境では null）
  final BenchStats? build;

  /// 描画（GPU への命令）の時間。3D の重さはおもにここに出る
  final BenchStats? raster;
  final int? memoryPeakMb;

  Map<String, Object?> toMap() => {
    'quality': quality,
    'seconds': seconds,
    'fps': BenchStats._r(frames.fps),
    'frame': frames.toMap(),
    'build': build?.toMap(),
    'raster': raster?.toMap(),
    'memoryPeakMb': memoryPeakMb,
  };
}

/// 結果の文章（画面に出す・コピーする・ログに出す）
class BenchReport {
  const BenchReport({required this.device, required this.results, this.note});

  final String device;
  final List<BenchResult> results;
  final String? note;

  static String qualityLabel(String q) => switch (q) {
    'high' => '高',
    'light' => '軽量',
    _ => '標準',
  };

  String text() {
    final b = StringBuffer('つづりクエスト3D 自動計測\n端末：$device\n');
    if (note != null) b.writeln(note);
    for (final r in results) {
      final f = r.frames;
      b.writeln(
        '[${qualityLabel(r.quality)}] ${f.fps.toStringAsFixed(1)}fps'
        '　フレーム 平均${f.avg.toStringAsFixed(1)} p95 ${f.p95.toStringAsFixed(1)} 最大${f.max.toStringAsFixed(0)}ms'
        '　カクつき(>33ms) ${f.over33}回 ${f.jankPercent.toStringAsFixed(1)}%',
      );
      final ra = r.raster, bu = r.build;
      if (ra != null && bu != null) {
        b.writeln(
          '　　描画 平均${ra.avg.toStringAsFixed(1)} p95 ${ra.p95.toStringAsFixed(1)}ms'
          '　UI 平均${bu.avg.toStringAsFixed(1)} p95 ${bu.p95.toStringAsFixed(1)}ms'
          '　メモリ最大 ${r.memoryPeakMb ?? '-'}MB',
        );
      } else {
        b.writeln('　　メモリ最大 ${r.memoryPeakMb ?? '-'}MB（描画時間は取れない環境）');
      }
    }
    return b.toString().trimRight();
  }

  String json() => jsonEncode({
    'device': device,
    if (note != null) 'note': note,
    'results': [for (final r in results) r.toMap()],
  });

  /// ログ用の 1 行（`TQ3D_BENCH {...}`）。adb logcat で拾える
  String logLine() => 'TQ3D_BENCH ${json()}';
}
