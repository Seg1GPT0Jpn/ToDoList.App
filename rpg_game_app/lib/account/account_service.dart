import 'package:flutter/material.dart';

/// 連携した Google アカウントの表示用の情報
typedef GoogleAccount = ({String email, String displayName});

/// Google アカウントでの登録（ログイン）。
///
/// Firebase の設定（lib/firebase_options.dart）があれば [FirebaseAccountService] で
/// 本物の Google ログインをする。なければ [MockAccountService] が手順を案内する。
abstract class AccountService {
  /// Google アカウントを選んでもらう。キャンセルなら null
  Future<GoogleAccount?> signInWithGoogle(BuildContext context);

  Future<void> signOut();

  /// 本物のログインか（false なら Firebase が未設定）
  bool get isReal;
}

/// Firebase が設定されていないとき。
///
/// 以前はメールアドレスを入れるだけで「連携した」ことにしていたが、本当につながったと
/// まちがえやすいので、つなぐための手順を案内するだけにした。
class MockAccountService implements AccountService {
  @override
  bool get isReal => false;

  @override
  Future<GoogleAccount?> signInWithGoogle(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _SetupNeededDialog(),
    );
    return null;
  }

  @override
  Future<void> signOut() async {}
}

class _SetupNeededDialog extends StatelessWidget {
  const _SetupNeededDialog();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Firebase のサイトでプロジェクトを作り、Authentication の「Google」を有効にする',
      'Firestore Database を作る（場所は東京 asia-northeast1）',
      'PC で `flutterfire configure` を実行して、設定ファイル（lib/firebase_options.dart）を作る',
      'Android で使うときは、署名の SHA-1 を Firebase に登録する',
      'アプリをビルドし直す',
    ];
    return AlertDialog(
      icon: const Icon(Icons.cloud_off, size: 36),
      title: const Text('Google ログインの準備がまだです'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'このアプリには、まだ Firebase（Google ログインとクラウド保存のしくみ）の'
              '設定が入っていません。今は、記録はこの端末の中だけに保存されます。',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 10),
            const Text(
              'つなぐ手順（最初の1回だけ）',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final (i, s) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${i + 1}. $s',
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'くわしい手順は、リポジトリの docs/GOOGLE_LOGIN.md にあります。',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('わかった'),
        ),
      ],
    );
  }
}
