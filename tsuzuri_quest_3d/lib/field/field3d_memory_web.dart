import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web：Chrome 系の performance.memory.usedJSHeapSize（JS のヒープだけ。GPU は含まない）
int? usedMb() {
  try {
    final perf = globalContext['performance'] as JSObject?;
    final mem = perf?['memory'] as JSObject?;
    final used = mem?['usedJSHeapSize'] as JSNumber?;
    if (used == null) return null;
    return used.toDartDouble ~/ (1024 * 1024);
  } catch (_) {
    return null;
  }
}

/// Web：ブラウザの userAgent
String platform() {
  try {
    final nav = globalContext['navigator'] as JSObject?;
    final ua = nav?['userAgent'] as JSString?;
    return 'web ${ua?.toDart ?? ''}'.trim();
  } catch (_) {
    return 'web';
  }
}
