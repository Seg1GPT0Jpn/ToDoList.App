// 小中学生版（tsuzuri-quest-junior-26426）の Firebase の設定。
// Web アプリの設定（https://tsuzuri-quest-junior-26426.web.app/__/firebase/init.json と同じ値）。
// Android 版はまだ Firebase に登録していないので、Firebase を使わず記録は端末の中だけに保存される。
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      '小中学生版の Firebase は Web だけ設定してあります（flutterfire configure で追加できます）',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyr_HEODDVakbaetI1-lIdtGz0sNLFI6U',
    appId: '1:122778955975:web:7d299f5b81a0eda4444ee2',
    messagingSenderId: '122778955975',
    projectId: 'tsuzuri-quest-junior-26426',
    authDomain: 'tsuzuri-quest-junior-26426.firebaseapp.com',
    storageBucket: 'tsuzuri-quest-junior-26426.firebasestorage.app',
  );
}
