import 'dart:io' show ProcessInfo;

/// ネイティブ（Android など）：このプロセスの常駐メモリ（RSS）
int? usedMb() {
  try {
    return ProcessInfo.currentRss ~/ (1024 * 1024);
  } catch (_) {
    return null;
  }
}
