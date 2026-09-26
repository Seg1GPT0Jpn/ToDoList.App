import 'package:flutter/material.dart';

/// 連携した Google アカウントの表示用の情報
typedef GoogleAccount = ({String email, String displayName});

/// Google アカウントでの登録（ログイン）。
///
/// school_planner へ移植するときは、Firebase Authentication の
/// GoogleAuthProvider（google_sign_in パッケージ）を使う実装に差し替える。
/// 試作アプリには Firebase の設定ファイルがないため、[MockAccountService] で
/// 画面の流れだけを確認できるようにしている。
abstract class AccountService {
  /// Google アカウントを選んでもらう。キャンセルなら null
  Future<GoogleAccount?> signInWithGoogle(BuildContext context);

  Future<void> signOut();

  /// 本物のログインか（false ならテスト用のダミー）
  bool get isReal;
}

/// テスト用のダミー。メールアドレスを入力するだけで「連携した」ことにする。
class MockAccountService implements AccountService {
  @override
  bool get isReal => false;

  @override
  Future<GoogleAccount?> signInWithGoogle(BuildContext context) =>
      showDialog<GoogleAccount>(
        context: context,
        builder: (_) => const _MockGoogleDialog(),
      );

  @override
  Future<void> signOut() async {}
}

class _MockGoogleDialog extends StatefulWidget {
  const _MockGoogleDialog();

  @override
  State<_MockGoogleDialog> createState() => _MockGoogleDialogState();
}

class _MockGoogleDialogState extends State<_MockGoogleDialog> {
  final _email = TextEditingController();
  String? _error;

  static final _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    if (!_pattern.hasMatch(email)) {
      setState(() => _error = 'メールアドレスの形になっていません');
      return;
    }
    Navigator.pop(context, (email: email, displayName: email.split('@').first));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.account_circle, size: 36),
      title: const Text('Google アカウントで登録'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '※ テスト用のダミーです。実際に Google にはつながりません。'
            '本番では Google のログイン画面が開きます。',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Gmail アドレス',
              hintText: 'example@gmail.com',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('やめる'),
        ),
        FilledButton(onPressed: _submit, child: const Text('登録する')),
      ],
    );
  }
}
