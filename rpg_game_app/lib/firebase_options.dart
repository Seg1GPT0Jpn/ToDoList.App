// Firebase の設定（仮）。
//
// 本物の設定は、Firebase プロジェクトを作ったあとに次のコマンドで作る。
// このファイルがそのまま上書きされる。
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// このままでも動くが、そのときは Firebase を使わず、記録は端末の中だけに保存される。
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase がまだ設定されていません（flutterfire configure を実行してください）',
  );
}
