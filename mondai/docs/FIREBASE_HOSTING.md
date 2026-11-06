# Firebase Hosting で公開する

教材制作アプリ（`mondai/`）を Firebase Hosting に公開する手順です。設定が済むと、`main` ブランチに変更が入るたびに GitHub Actions が自動で公開します。公開先は `https://<プロジェクトID>.web.app/` です（アプリはサイトのトップに置かれます）。

GitHub Pages（`https://seg1gpt0jpn.github.io/ToDoList.App/mondai/`）での公開はそのまま続きます。両方とも同じ内容です。

用意してあるもの：
- `firebase.json`（リポジトリのいちばん上）：`mondai/` を公開します。テスト・Supabase の設定・開発用のファイルは公開しません。HTML・JS・CSS・JSON は毎回新しいかを確かめるので、更新がすぐ届きます。
- `.github/workflows/firebase-hosting.yml`：テスト（単体・データベースの権限）が通ったら公開します。下の2つを登録するまでは何もしません。

## 1. Firebase のプロジェクトを作る（無料）
1. https://console.firebase.google.com を開き、Google アカウントでログインします。
2. 「プロジェクトを作成」（または「プロジェクトを追加」）。名前は例えば `mondai`。Google アナリティクスは使わなくてかまいません。
3. できたプロジェクトの **プロジェクト ID**（例：`mondai-1a2b3`）を控えます（歯車 → プロジェクトの設定 に表示されます）。
4. 左のメニュー「構築」→「Hosting」→「始める」を押し、表示される説明は「次へ」で最後まで進めます（コマンドの実行は不要です）。

料金プランは無料の **Spark** のままで使えます。無料枠は保存 10 GB・転送 1 日 360 MB です。このアプリは初めて開いたときに約 1.5 MB（圧縮後）を読み込むので、1 日に新しい端末で 200 回程度開いても収まります。

## 2. 公開用の鍵（サービスアカウント）を作る
1. https://console.cloud.google.com/iam-admin/serviceaccounts を開き、上の欄で 1 のプロジェクトを選びます。
2. 「サービスアカウントを作成」→ 名前に `github-deploy` などと入れて「作成して続行」。
3. ロールに **「Firebase Hosting 管理者」**・**「API キー閲覧者」**・**「Service Usage ユーザー」**（英語表示では Service Usage Consumer）の3つを追加して「完了」。
   - あとから足すときは https://console.cloud.google.com/iam-admin/iam で `github-deploy@…` の鉛筆マークから追加します。
4. 作ったアカウントを開き、「鍵」→「鍵を追加」→「新しい鍵を作成」→「JSON」。JSON ファイルがダウンロードされます。

この JSON はパスワードと同じです。**リポジトリ・チャット・メールには貼らないでください。** 次の手順で GitHub の Secrets にだけ登録し、登録したらパソコンからは削除してかまいません。

## 3. GitHub に登録する
リポジトリの「Settings」→「Secrets and variables」→「Actions」を開きます。
1. 「Secrets」タブ →「New repository secret」：名前 `FIREBASE_SERVICE_ACCOUNT`、値に 2 の JSON ファイルの中身をすべて貼り付け。
2. 「Variables」タブ →「New repository variable」：名前 `FIREBASE_PROJECT_ID`、値に 1 のプロジェクト ID。

## 4. 公開する
「Actions」タブ →「Firebase Hosting に公開」→「Run workflow」。数分で `https://<プロジェクトID>.web.app/` に公開されます。以後は `main` に変更が入るたびに自動で公開されます。

## 5. チーム機能（Supabase）を使っている場合
ログインのメールのリンクが Firebase の URL に戻れるように、Supabase の「Authentication」→「URL Configuration」の **Redirect URLs** に `https://<プロジェクトID>.web.app/` を追加します（Firebase を主に使うなら Site URL もこれにします）。

## うまくいかないとき
| 症状 | 確認すること |
| --- | --- |
| Actions に何も起きない | Variables の `FIREBASE_PROJECT_ID` が登録されているか（未登録だと公開の処理を飛ばします） |
| 「Permission denied to get service [firebasehosting.googleapis.com]」 | 「Service Usage ユーザー」のロールがない（手順 2-3）。追加して1〜2分待ち、Actions で「Re-run all jobs」 |
| そのほかの「Permission denied」「403」 | サービスアカウントのロール（手順 2-3）。それでも出るときは「Cloud Run 閲覧者」も追加 |
| 「Failed to get Firebase project」 | プロジェクト ID のつづり、手順 1-4 で Hosting を始めたか |
| 古い画面のまま | ブラウザを再読み込み（HTML・JS は毎回確認する設定なので、通常はすぐ新しくなります） |

データ（作った教材・問題）は端末のブラウザに保存されるため、GitHub Pages と Firebase では別々になります。移すときは「設定・データ → バックアップを保存」して、もう一方で「バックアップから復元」してください。
