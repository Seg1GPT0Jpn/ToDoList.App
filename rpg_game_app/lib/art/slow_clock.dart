import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 飾りの動き（景色・敵のゆれ・歩く主人公）のための、ゆっくりした時計。
///
/// `AnimationController..repeat()` は毎秒60回描きなおすので、スマホでは重く電池も減る。
/// 飾りは毎秒 [fps] 回で十分なので、そのときだけ描きなおす。
/// [value] は 0〜1 を [period] でくり返す（AnimationController と同じ使い方）。
class SlowClock extends ChangeNotifier implements ValueListenable<double> {
  SlowClock({required this.period, this.fps = 15});

  final Duration period;
  final int fps;

  final Stopwatch _watch = Stopwatch();
  Timer? _timer;

  @override
  double get value => period.inMicroseconds == 0
      ? 0
      : (_watch.elapsedMicroseconds % period.inMicroseconds) /
            period.inMicroseconds;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _watch.start();
    _timer = Timer.periodic(
      Duration(microseconds: 1000000 ~/ fps),
      (_) => notifyListeners(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _watch.stop();
  }

  /// 画面に出ているときだけ動かす（下に隠れた画面や「動きを減らす」設定では止める）
  void follow(BuildContext context) {
    final on =
        TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    on ? start() : stop();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
