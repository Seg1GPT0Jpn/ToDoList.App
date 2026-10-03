/// Google ログインで使う「ウェブ クライアント ID」（ふだんは空のままでよい）。
///
/// Android では、flutterfire configure をすると google-services.json から自動で
/// 読みこまれる。それでも端末の Google アカウント選択画面が出ないときだけ、
/// Firebase →「Authentication」→「Sign-in method」→「Google」→
/// 「ウェブ SDK 構成」の「ウェブ クライアント ID」（〜.apps.googleusercontent.com）を
/// ここに貼る。空のときや使えないときは、ブラウザでのログインに切りかわる。
const googleWebClientId = '';
