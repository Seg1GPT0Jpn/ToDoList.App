import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../account/account_service.dart';
import 'cloud_sync.dart';

/// Firebase Authentication の Google ログイン。
///
/// Web ではポップアップ、Android では Firebase のログイン画面を開く。
/// ログインできたら、クラウドの記録を読み込む（[CloudSync.pull]）。
class FirebaseAccountService implements AccountService {
  FirebaseAccountService(this._sync);

  final CloudSync _sync;

  FirebaseAuth get _auth => _sync.auth;

  @override
  bool get isReal => true;

  @override
  Future<GoogleAccount?> signInWithGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final user = cred.user;
      if (user == null) return null;
      await _sync.pull();
      final email = user.email ?? '';
      return (
        email: email,
        displayName: user.displayName ?? email.split('@').first,
      );
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return null;
      messenger.showSnackBar(
        SnackBar(content: Text('Google でログインできませんでした（${e.code}）')),
      );
      return null;
    }
  }

  static const _cancelCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'canceled',
  };

  @override
  Future<void> signOut() => _auth.signOut();
}
