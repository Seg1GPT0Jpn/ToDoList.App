import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// アプリに同梱したファイル（assets/…）の場所の前につける文字。
///
/// つづりクエストでは空。つづりクエストLight は、つづりクエストの同梱ファイルを
/// 部品として使うので 'packages/rpg_game_app/' を入れる。
String appAssetPrefix = '';

/// 同梱ファイルの場所（つづりクエスト・Light のどちらでも読めるように）
String appAsset(String path) => '$appAssetPrefix$path';

/// 同梱されていないファイルを、ほかの場所（ネット）から読む。null なら読まない。
/// つづりクエストLight の Android 版は、大きな資料・予想問題を APK に入れず、開いたときにネットから読んで端末に残す
Future<List<int>> Function(String path)? missingAssetLoader;

/// 同梱ファイル（assets/…）をバイト列で読む。同梱されていなければ [missingAssetLoader] にまかせる
Future<List<int>> loadAppAssetBytes(String path) async {
  try {
    return (await rootBundle.load(appAsset(path))).buffer.asUint8List();
  } on FlutterError {
    final other = missingAssetLoader;
    if (other == null) rethrow;
    return other(path);
  }
}
