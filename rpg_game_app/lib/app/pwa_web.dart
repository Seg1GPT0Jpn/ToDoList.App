import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'pwa_stub.dart' show PwaInfo;

export 'pwa_stub.dart' show PwaInfo;

@JS('navigator.standalone')
external JSBoolean? get _iosStandalone;

/// Web 版：iPhone かどうかと、ホーム画面から開いているか
PwaInfo pwaInfo() {
  try {
    final ua = web.window.navigator.userAgent;
    final touchMac =
        ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1;
    final ios = RegExp('iPhone|iPad|iPod').hasMatch(ua) || touchMac;
    final standalone =
        web.window.matchMedia('(display-mode: standalone)').matches ||
        (_iosStandalone?.toDart ?? false);
    return PwaInfo(ios: ios, standalone: standalone);
  } catch (_) {
    return const PwaInfo(ios: false, standalone: true);
  }
}
