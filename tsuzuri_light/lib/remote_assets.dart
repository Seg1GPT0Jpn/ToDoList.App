// 同梱しない大きなファイル（資料・予想問題）を、開いたときにネットから読んで端末に残す。
// Android 版だけで使う（Web 版は Service Worker が同じことをする）
export 'remote_assets_stub.dart' if (dart.library.io) 'remote_assets_io.dart';
