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

  /// 動いている時計。1つのタイマーでまとめて進め、描きなおしを同じフレームにそろえる
  /// （時計ごとにタイマーがあると、15回＋12回で毎秒27回描くことになる）
  static final Set<SlowClock> _running = {};
  static Timer? _shared;
  static int _sharedFps = 0;

  @override
  double get value => period.inMicroseconds == 0
      ? 0
      : (_watch.elapsedMicroseconds % period.inMicroseconds) /
            period.inMicroseconds;

  bool get isRunning => _running.contains(this);

  void start() {
    if (!_running.add(this)) return;
    _watch.start();
    _retime();
  }

  void stop() {
    if (!_running.remove(this)) return;
    _watch.stop();
    _retime();
  }

  /// 動いている時計のうち、いちばん細かい回数でタイマーを回す
  static void _retime() {
    final fps = _running.fold(0, (m, c) => c.fps > m ? c.fps : m);
    if (fps == _sharedFps && (_shared != null) == (fps > 0)) return;
    _shared?.cancel();
    _shared = null;
    _sharedFps = fps;
    if (fps == 0) return;
    _shared = Timer.periodic(Duration(microseconds: 1000000 ~/ fps), (_) {
      for (final c in _running.toList()) {
        c.notifyListeners();
      }
    });
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
