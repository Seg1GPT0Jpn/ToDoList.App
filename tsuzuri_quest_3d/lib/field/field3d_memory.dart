import 'field3d_memory_stub.dart'
    if (dart.library.js_interop) 'field3d_memory_web.dart'
    as impl;

/// 使っているメモリ（MB）。わからない環境では null
class Field3DMemory {
  static int? usedMb() => impl.usedMb();

  /// 計測結果に書く端末の説明（OS とその版、Web はブラウザ）
  static String platform() => impl.platform();
}
