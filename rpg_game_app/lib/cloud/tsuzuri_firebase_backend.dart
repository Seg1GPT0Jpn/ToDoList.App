import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'tsuzuri_link.dart';

/// つづり（school-planner-30628）の Firebase に、2つ目のアプリとしてつなぐ。
///
/// つづりと同じ Google アカウントでログインすると、つづりの
/// `users/{uid}/` の中（本人だけが読み書きできる場所）を使える。
/// クエスト本体のログイン（tsuzuri-quest-v2）とは別に、ログインの状態を持つ。
///
/// 使う前に、つづりの Firebase コンソールで
/// 「Authentication ＞ 設定 ＞ 承認済みドメイン」に tsuzuri-quest-v2.web.app を足しておく。
class FirebaseTsuzuriBackend implements TsuzuriBackend {
  FirebaseTsuzuriBackend();

  static const appName = 'tsuzuri';

  /// つづりの Web 版の設定（公開してよい値。データは Firestore のルールで本人だけに守られる）
  static const options = FirebaseOptions(
    apiKey: 'AIzaSyCiNJNzTVEwj9sbgWB4kQ3xIrHTT7vAPyo',
    appId: '1:1033493674765:web:4c18a5093c438be2b64e44',
    messagingSenderId: '1033493674765',
    projectId: 'school-planner-30628',
    authDomain: 'school-planner-30628.firebaseapp.com',
    storageBucket: 'school-planner-30628.firebasestorage.app',
  );

  /// つづりの Firebase に登録した、クエストの Android アプリの ID
  /// （tools/connect_tsuzuri_android.ps1 で登録した値）
  static const androidAppId = '1:1033493674765:android:b03dc83421268044b64e44';

  /// つづりの Firebase の Android 用 API キー
  static const androidApiKey = 'AIzaSyBFEsu05iHKjeRSBfoT5QAweKveboFxZTA';

  /// この端末でつづりと連携できるか（Web 版と Android 版）
  static bool get supported =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  static FirebaseOptions get _options => kIsWeb
      ? options
      : FirebaseOptions(
          apiKey: androidApiKey,
          appId: androidAppId,
          messagingSenderId: options.messagingSenderId,
          projectId: options.projectId,
          storageBucket: options.storageBucket,
        );

  FirebaseApp? _app;

  Future<FirebaseApp> _ensure() async {
    final app = _app;
    if (app != null) return app;
    for (final a in Firebase.apps) {
      if (a.name == appName) return _app = a;
    }
    return _app = await Firebase.initializeApp(
      name: appName,
      options: _options,
    );
  }

  Future<FirebaseAuth> _auth() async =>
      FirebaseAuth.instanceFor(app: await _ensure());

  Future<DocumentReference<Map<String, dynamic>>> _user() async {
    final auth = await _auth();
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('つづりにログインしていません');
    return FirebaseFirestore.instanceFor(app: await _ensure())
        .collection('users')
        .doc(uid);
  }

  @override
  Future<String?> restore() async {
    final auth = await _auth();
    final user = await auth.authStateChanges().first;
    return user?.email ?? user?.uid;
  }

  @override
  Future<String?> connect() async {
    final auth = await _auth();
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    final cred = kIsWeb
        ? await auth.signInWithPopup(provider)
        : await auth.signInWithProvider(provider);
    return cred.user?.email ?? cred.user?.uid;
  }

  @override
  Future<void> disconnect() async => (await _auth()).signOut();

  @override
  Future<Map<String, dynamic>?> readUpcoming() async {
    final snap = await (await _user())
        .collection('quest_link')
        .doc('upcoming')
        .get();
    return snap.data();
  }

  @override
  Future<void> writeSession(String id, Map<String, Object?> data) async {
    final day = data['date'] as DateTime;
    await (await _user()).collection('study_sessions').doc(id).set({
      'subject': data['subject'],
      'start': Timestamp.fromDate(day),
      'minutes': data['minutes'],
      'memo': data['memo'],
    });
  }

  @override
  Future<void> deleteSession(String id) async =>
      (await _user()).collection('study_sessions').doc(id).delete();

  @override
  Future<void> writeResults(Map<String, dynamic> data) async {
    await (await _user()).collection('quest_link').doc('results').set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
