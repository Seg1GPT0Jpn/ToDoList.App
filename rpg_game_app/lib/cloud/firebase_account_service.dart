import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../account/account_service.dart';
import 'cloud_sync.dart';
import 'google_client_id.dart';
import 'login_problem.dart';

/// Firebase Authentication の Google ログイン。
///
/// - Web：ポップアップ（ブロックされたら、ページを移動するログインに切りかえる）
/// - Android：端末の Google アカウント選択画面（google_sign_in）。
///   設定が足りずに使えないときは、ブラウザでのログイン（signInWithProvider）に切りかえる
/// - iOS：ブラウザでのログイン
///
/// ログインできたら、クラウドの記録を読み込む（[CloudSync.pull]）。
/// うまくいかないときは、原因と直し方をダイアログで知らせる。
class FirebaseAccountService implements AccountService {
  FirebaseAccountService(this._sync);

  final CloudSync _sync;

  FirebaseAuth get _auth => _sync.auth;

  bool _nativeReady = false;

  @override
  bool get isReal => true;

  @override
  Future<GoogleAccount?> signInWithGoogle(BuildContext context) async {
    final User? user;
    try {
      user = await _signIn();
    } on _Canceled {
      return null;
    } catch (e) {
      debugPrint('Google ログインに失敗: $e');
      if (context.mounted) await _showError(context, _describe(e));
      return null;
    }
    if (user == null) return null;
    final pullError = await _sync.pull();
    if (pullError != null && context.mounted) {
      await _showError(context, pullError);
    }
    final email = user.email ?? '';
    return (
      email: email,
      displayName: user.displayName ?? email.split('@').first,
    );
  }

  Future<User?> _signIn() async {
    if (kIsWeb) return _signInWeb();
    // iOS は Info.plist に URL スキームを足さないと端末のログイン画面が落ちるので、
    // ブラウザでのログインにする
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _signInWithProvider();
    }
    try {
      return await _signInNative();
    } on _Canceled {
      rethrow;
    } on FirebaseAuthException {
      // Google のアカウントは選べたが、Firebase が受けつけなかった（設定の問題）
      rethrow;
    } catch (e) {
      // 端末の選択画面が使えない（Web クライアント ID がないなど）ときは、ブラウザで
      debugPrint('端末の Google ログインが使えないので、ブラウザで行います: $e');
      return _signInWithProvider();
    }
  }

  Future<User?> _signInWeb() async {
    final provider = _provider();
    try {
      return (await _auth.signInWithPopup(provider)).user;
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) throw const _Canceled();
      if (e.code == 'popup-blocked' ||
          e.code == 'operation-not-supported-in-this-environment') {
        // ページごと Google の画面に移動する。もどってきたら CloudSync.start が続きをする
        await _auth.signInWithRedirect(provider);
        return null;
      }
      rethrow;
    }
  }

  Future<User?> _signInNative() async {
    final google = GoogleSignIn.instance;
    if (!_nativeReady) {
      await google.initialize(
        serverClientId: googleWebClientId.isEmpty ? null : googleWebClientId,
      );
      _nativeReady = true;
    }
    if (!google.supportsAuthenticate()) {
      throw UnsupportedError('この端末では Google のアカウント選択画面を使えません');
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const _Canceled();
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google から本人確認のしるし（ID トークン）を受け取れませんでした');
    }
    final cred = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return cred.user;
  }

  Future<User?> _signInWithProvider() async {
    try {
      return (await _auth.signInWithProvider(_provider())).user;
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) throw const _Canceled();
      rethrow;
    }
  }

  GoogleAuthProvider _provider() =>
      GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});

  static const _cancelCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'web-context-cancelled',
    'canceled',
    'user-cancelled',
  };

  @override
  Future<void> signOut() async {
    if (!kIsWeb && _nativeReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google からのログアウトに失敗: $e');
      }
    }
    await _auth.signOut();
  }

  /// エラーを、原因と直し方の文にする
  static LoginProblem _describe(Object e) {
    if (e is FirebaseAuthException) {
      return LoginProblem.forCode(e.code, detail: e.message);
    }
    if (e is GoogleSignInException) {
      return switch (e.code) {
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          LoginProblem.forCode('developer-error', detail: e.description),
        GoogleSignInExceptionCode.uiUnavailable ||
        GoogleSignInExceptionCode.interrupted => LoginProblem.forCode(
          'interrupted',
          detail: e.description,
        ),
        _ => LoginProblem.forCode('unknown', detail: e.description),
      };
    }
    if (e is PlatformException) {
      final text = '${e.code} ${e.message}';
      // Google Play 開発者サービスの「10」「DEVELOPER_ERROR」は、SHA-1 などの設定ちがい
      if (RegExp(r'ApiException: 10\b|DEVELOPER_ERROR').hasMatch(text)) {
        return LoginProblem.forCode('developer-error', detail: text);
      }
      if (RegExp(
        r'ApiException: 7\b|network',
        caseSensitive: false,
      ).hasMatch(text)) {
        return LoginProblem.forCode('network-request-failed', detail: text);
      }
      return LoginProblem.forCode('unknown', detail: text);
    }
    return LoginProblem.forCode('unknown', detail: '$e');
  }

  static Future<void> _showError(
    BuildContext context,
    LoginProblem p,
  ) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.error_outline, size: 36),
      title: Text(p.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.cause, style: const TextStyle(fontSize: 13, height: 1.6)),
            const SizedBox(height: 10),
            const Text('直し方', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final s in p.fixes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '・$s',
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ),
            const SizedBox(height: 10),
            SelectableText(
              'エラーの記録：${p.code}${p.detail == null ? '' : '\n${p.detail}'}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('わかった'),
        ),
      ],
    ),
  );
}

/// ユーザーがキャンセルした
class _Canceled implements Exception {
  const _Canceled();
}
