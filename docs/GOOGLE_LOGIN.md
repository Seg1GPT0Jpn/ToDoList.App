# Google ログインを本当につなぐ手順

つづりクエスト for elementary and junior high school（小中学生版）の Google ログインとクラウド保存は、**あなたの Firebase プロジェクト**につなぐと動きます。
コード側の準備はできているので、あとは最初の1回だけ、次の設定をします（PC の PowerShell で行います）。

設定する前は、アカウント画面で「Google アカウントで登録」を押すと、この手順の案内が出るだけです（記録は端末の中だけに保存されます）。

---

## 1. Firebase のプロジェクトを作る（ブラウザ）

1. https://console.firebase.google.com を開いて、Google アカウントでログインする
2. 「プロジェクトを作成」
   - 名前：`tsuzuri-quest-junior`（高校版とは**別のプロジェクト**にする。使われていて作れないときは、うしろに数字などをつける）
   - Google アナリティクス：オフでよい
3. 左のメニュー「構築」→「**Authentication**」→「始める」
   - 「Sign-in method」タブ →「**Google**」→「有効にする」をオン
   - 「プロジェクトのサポートメール」に自分のアドレスを選んで「保存」
4. 左のメニュー「構築」→「**Firestore Database**」→「データベースを作成」
   - ロケーション：`asia-northeast1`（東京）
   - 「本番環境モードで開始」

## 2. PC にツールを入れる（最初の1回だけ）

Node.js が入っていなければ、https://nodejs.org から LTS 版を入れてください。そのあと PowerShell で：

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

`flutterfire` が見つからないと言われたら、この PowerShell で次を実行してから、もう一度ためしてください。

```powershell
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
```

## 3. 設定ファイルを作る

`rpg_game_app` のフォルダ（例 `C:\develop\projects\rpg_test\rpg_game_app`）で：

```powershell
flutterfire configure --project=<プロジェクトID> --platforms=android,ios,web
```

- `<プロジェクトID>` は、Firebase のプロジェクトの設定に書いてある ID（例 `tsuzuri-quest-junior` または `tsuzuri-quest-junior-12ab3`）
- 途中でアプリ ID を聞かれたら、Android は `com.kazu.tsuzuri_quest_junior`、iOS は `com.kazu.tsuzuriQuestJunior`
- `android/app/google-services.json`・`ios/Runner/GoogleService-Info.plist` も作られます（iOS は Mac で行うときだけ）
- 終わると `lib/firebase_options.dart` が本物の設定に置きかわります（これはコミットしてかまいません。秘密の情報ではありません）

プロジェクト ID が `tsuzuri-quest-junior` 以外のときは、`.firebaserc` の `"default"` もその ID に書きかえてください。

## 4. Android で使うとき：署名の SHA-1 を登録する

Pixel などの Android 端末で Google ログインするには、アプリの署名（SHA-1）を Firebase に知らせる必要があります。

1. PowerShell で、デバッグ用の署名を表示する：

   ```powershell
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

   `keytool` が見つからないときは、Android Studio に入っているものを使います：

   ```powershell
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

2. 表示された `SHA1:` と `SHA256:` の値をコピーする
3. Firebase のサイト →（左上の歯車）「プロジェクトの設定」→「マイアプリ」の Android アプリ →「フィンガープリントを追加」で、SHA1 と SHA256 をそれぞれ追加する

## 5. セキュリティルールを反映する

本人だけが自分の記録を読み書きできるルール（`firestore.rules`）を反映します。`rpg_game_app` のフォルダで：

```powershell
firebase deploy --only firestore:rules
```

## 6. 動かしてみる

```powershell
flutter pub get
flutter run -d <Pixelの名前かID>
# Web なら
flutter run -d chrome
```

アプリのホーム →（右上の︙）→「アカウント（名前・Google）」→「**Google アカウントで登録**」。
Google のアカウント選択画面が開くので、アカウントを選べば完了です。

- ログイン中は、冒険の記録・プロフィール・学習記録がクラウドにも保存されます
- 別の端末でも同じ Google アカウントで登録すれば、続きから遊べます
- 個人用単語帳（LEAP）はクラウドに送りません。端末の中だけです

---

## うまくいかないとき

| 表示 | 原因と直し方 |
| --- | --- |
| 「Google ログインの準備がまだです」 | `lib/firebase_options.dart` が仮のまま。手順3をやり直して、アプリをビルドし直す |
| `operation-not-allowed` | Authentication で Google が有効になっていない（手順1-3） |
| `unauthorized-domain` | Web の URL が許可されていない。Authentication →「設定」→「承認済みドメイン」に追加する（`localhost` は最初から入っています） |
| Android でアカウントを選んだあとエラー（`invalid-cert-hash` など） | SHA-1 が未登録か、別のPCの署名。手順4をそのPCで行う |
| 「アプリの登録が合っていません」（`developer-error`） | SHA-1／SHA-256 が、アプリをビルドしている PC のものと合っていない、またはパッケージ名がちがう。手順4をそのPCでやり直し、`flutterfire configure` をもう一度実行してビルドし直す |
| 「ログインできましたが、クラウドに保存できません」 | Firestore が未作成（手順1-4）か、ルールが未反映（手順5） |
| `network-request-failed` | 端末がインターネットにつながっていない |
| `permission-denied`（保存のとき） | 手順5のルールが反映されていない |

メモ：
- Android では、端末の Google アカウント選択画面でログインします（使えないときは自動でブラウザに切りかわります）。
  選択画面が出ないときは、Firebase →「Authentication」→「Google」→「ウェブ SDK 構成」の「ウェブ クライアント ID」を
  `lib/cloud/google_client_id.dart` に貼ってビルドし直してください
- うまくいかないときは、アプリに出るダイアログに「原因」「直し方」「エラーの記録」が表示されます
- claude.ai の成果物（アーティファクト）として公開した Web 版は、安全のためポップアップが使えないので、Google ログインはできません。Google ログインは `flutter run`、Android アプリ、または Firebase Hosting で公開した Web 版で使ってください（公開のしかたは `rpg_game_app/README.md` の「公開する」）
- リリース版の APK を作るときは、リリース用の署名の SHA-1 も同じように登録してください
