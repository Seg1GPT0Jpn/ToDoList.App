/// ログイン・クラウド保存でうまくいかなかったことの、原因と直し方
class LoginProblem {
  const LoginProblem({
    required this.code,
    required this.title,
    required this.cause,
    required this.fixes,
    this.detail,
  });

  final String code;
  final String title;
  final String cause;
  final List<String> fixes;

  /// もとのエラーの文（調べるとき用）
  final String? detail;

  static LoginProblem forCode(String code, {String? detail}) {
    LoginProblem p(String title, String cause, List<String> fixes) =>
        LoginProblem(
          code: code,
          title: title,
          cause: cause,
          fixes: fixes,
          detail: detail,
        );
    switch (code) {
      case 'developer-error':
      case 'invalid-cert-hash':
      case 'app-not-authorized':
        return p(
          'アプリの登録が合っていません',
          'Firebase に登録したアプリの情報（署名の SHA-1／SHA-256、パッケージ名）と、'
              'いま動いているアプリが一致していません。',
          [
            'Firebase の「プロジェクトの設定」→ Android アプリのパッケージ名が com.kazu.tsuzuri_quest_junior か確かめる',
            'アプリをビルドしている PC で keytool を実行し、表示された SHA-1 と SHA-256 を登録する（別の PC の値では動きません）',
            '登録したあと、flutterfire configure をもう一度実行し、アプリをビルドし直す',
          ],
        );
      case 'operation-not-allowed':
        return p(
          'Google ログインが有効になっていません',
          'Firebase の Authentication で、Google のログインがオフになっています。',
          ['Firebase →「Authentication」→「Sign-in method」→「Google」を有効にして保存する'],
        );
      case 'unauthorized-domain':
        return p(
          'このページのアドレスが許可されていません',
          'Web 版を開いているアドレス（ドメイン）が、Firebase に登録されていません。',
          ['Firebase →「Authentication」→「設定」→「承認済みドメイン」に、いま開いているアドレスを追加する'],
        );
      case 'network-request-failed':
        return p('インターネットにつながっていません', '通信ができなかったため、ログインできませんでした。', [
          'Wi-Fi やモバイルデータがつながっているか確かめて、もう一度ためす',
        ]);
      case 'popup-blocked':
        return p('ログイン画面がブロックされました', 'ブラウザがポップアップをブロックしました。', [
          'アドレスバーのポップアップの表示を許可して、もう一度ためす',
        ]);
      case 'user-disabled':
        return p('このアカウントは使えません', 'この Google アカウントは、管理者によって無効にされています。', [
          '別の Google アカウントでためす',
        ]);
      case 'too-many-requests':
        return p('しばらく待ってください', '短い時間にたくさんログインしようとしたため、一時的に止められています。', [
          '数分たってから、もう一度ためす',
        ]);
      case 'interrupted':
        return p('ログインが途中で止まりました', 'Google の画面を開けなかったか、途中で切れました。', [
          'アプリを開き直して、もう一度ためす',
        ]);
      case 'permission-denied':
        return p(
          'ログインできましたが、クラウドに保存できません',
          'Firestore のセキュリティルールが反映されていないため、記録の読み書きが止められています。'
              '冒険の記録は、この端末の中には保存されています。',
          [
            'PC の rpg_game_app フォルダで firebase deploy --only firestore:rules を実行する',
          ],
        );
      case 'firestore-missing':
        return p(
          'ログインできましたが、クラウドに保存できません',
          'Firebase に Firestore Database がまだ作られていません。'
              '冒険の記録は、この端末の中には保存されています。',
          [
            'Firebase →「Firestore Database」→「データベースを作成」（場所は asia-northeast1）',
            '作ったあと firebase deploy --only firestore:rules を実行する',
          ],
        );
      case 'cloud-unavailable':
        return p(
          'ログインできましたが、クラウドの記録を読めませんでした',
          '通信が不安定か、時間がかかりすぎました。冒険の記録は、この端末の中には保存されています。',
          ['インターネットにつながっているか確かめて、アカウント画面で登録し直す'],
        );
      default:
        return p('Google でログインできませんでした', '思いがけないエラーが起きました。', [
          'アプリを開き直して、もう一度ためす',
          'なおらないときは、下の「エラーの記録」を開発者に知らせてください',
        ]);
    }
  }
}
