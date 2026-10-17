import 'dart:io' show Platform, ProcessInfo;

/// ネイティブ（Android など）：このプロセスの常駐メモリ（RSS）
int? usedMb() {
  try {
    return ProcessInfo.currentRss ~/ (1024 * 1024);
  } catch (_) {
    return null;
  }
}

/// 例：android Linux 5.10.x … （OS の名前と版）
String platform() {
  try {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  } catch (_) {
    return '不明';
  }
}
