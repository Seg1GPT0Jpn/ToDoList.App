# かながわコネクトオーケストラ 公式Webサイト

「すべてのひとのためのオーケストラ」— 学生を中心に活動する、年齢・経験を問わないオーケストラの公式サイトです。
HTML / CSS / JavaScript のみで構成された軽量な静的サイトで、Firebase Hosting で公開できます。

## ファイル構成

```
kanagawa_connect_orchestra/
├── index.html          ホーム
├── about.html          私たちについて
├── recruit.html        団員募集
├── concert.html        第1回演奏会
├── activity.html       活動について
├── contact.html        お問い合わせ
├── suggest.html        曲目候補の提案フォーム（Firestore に保存）
├── admin.html          曲目候補の管理画面（管理者のみ・検索エンジン非掲載）
├── 404.html            ページが見つからない場合の表示（Firebase が自動で使用）
├── css/style.css       スタイル（配色・余白などは先頭の :root 変数で管理）
├── js/main.js          スマホメニュー、フッターの年表示、表示アニメーション
├── js/suggest.bundle.js / admin.bundle.js  曲目候補フォーム・管理画面（_tools/firebase から生成）
├── images/logo.png     楽団ロゴマーク（logo-160.png はヘッダー用の小サイズ）
├── images/ogp.png      SNS共有用画像（1200×630）
├── docs/recruitment-guidelines.pdf  団員募集要項PDF
├── favicon/            ファビコン・アイコン一式
├── robots.txt
├── sitemap.xml
├── _tools/build_site.py  全ページのHTMLとsitemap.xmlを生成するスクリプト（公開対象外）
├── _tools/firebase/    曲目候補フォーム・管理画面のJavaScriptソースとビルド設定（公開対象外）
├── firestore.rules     Firestore セキュリティルール（公開対象外）
├── firebase.json       Firebase Hosting 設定
└── .firebaserc         Firebase プロジェクトID 設定
```

## ローカルで表示する

ビルドは不要です。HTMLファイルをブラウザで直接開くだけでも表示できますが、
本番に近い状態で確認するにはローカルサーバーを使ってください。

**方法1：Python（多くの環境に標準で入っています）**

```bash
cd kanagawa_connect_orchestra
python -m http.server 8080
```

ブラウザで http://localhost:8080 を開きます。

**方法2：Firebase CLI（本番と同じ設定で確認できます）**

```bash
cd kanagawa_connect_orchestra
firebase serve --only hosting
# または
firebase emulators:start --only hosting
```

ブラウザで http://localhost:5000 を開きます。

## Firebase Hosting へデプロイする

### 1. 初回のみ：準備

1. [Firebase コンソール](https://console.firebase.google.com/) でプロジェクトを作成します。
2. Node.js をインストールし、Firebase CLI を入れます。

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. `.firebaserc` の `"kanagawa-connect-orchestra"` を、作成した **実際のプロジェクトID** に書き換えます。
   （または `firebase use --add` で選択しても構いません）

### 2. デプロイ

```bash
cd kanagawa_connect_orchestra
firebase deploy --only hosting
```

完了すると `https://<プロジェクトID>.web.app` で公開されます。

> `firebase init` は不要です（`firebase.json` は作成済み）。実行する場合は、
> public ディレクトリに `.` を指定し、既存の `index.html` / `404.html` を上書きしないでください。

### 3. 公開URLが決まったら（重要）

canonical・OGP・サイトマップには絶対URLが必要なため、仮のURL
`https://kanagawa-connect-orchestra.web.app` を設定しています。
実際の公開URL（プロジェクトIDや独自ドメイン）と異なる場合は、次のファイルで一括置換してください。

- `*.html`（`canonical`、`og:url`、`og:image`）
- `sitemap.xml`
- `robots.txt`

## 曲目候補の募集機能（Firestore）

第1回演奏会の曲目候補（オープニング・サブメイン・アンコール1・アンコール2）を、
`suggest.html` のフォームから受け付けます。送信内容は Firestore の **`programSuggestions`** コレクションに
1曲＝1件で保存され、管理者だけが `admin.html` で確認できます。

- 保存項目：`timestamp` `name` `email` `category`（opening / submain / encore1 / encore2）`title` `composer` `reason` `participationStatus`
- 一般の閲覧者は、他の人の提案やメールアドレスを読み取れません（Security Rules で拒否）
- 管理者は Google アカウントでログインし、`firestore.rules` に登録したメールアドレスのみ閲覧・削除できます
- 団員募集の Google フォームとは独立しており、既存の団員募集には影響しません

### 初回のみ：Firebase コンソールでの設定

1. **Firestore を作成**：Firebase コンソール →「Firestore Database」→「データベースを作成」
   （本番環境モード、ロケーションは `asia-northeast1（東京）` がおすすめ）
   - すでに Firestore を作成済みで、「ルール」タブに独自のルールがある場合は、
     **デプロイ前に** その内容を `firestore.rules` に統合してください（デプロイするとルールは置き換わります）。
2. **Google ログインを有効化**：「Authentication」→「Sign-in method」→「Google」を有効にする
3. **Web アプリの登録を確認**：「プロジェクトの設定」→「マイアプリ」にウェブアプリ（`</>`）がなければ追加する
   （サイトは Firebase Hosting の `/__/firebase/init.json` から設定を自動で読み込むため、API キーをコードに書く必要はありません）

### デプロイ

```bash
cd kanagawa_connect_orchestra
firebase deploy --only firestore:rules   # セキュリティルール
firebase deploy --only hosting           # サイト
```

### 管理画面

- URL：`https://kanagawa-connect-orchestra.web.app/admin.html`（サイト内からはリンクしていません）
- 管理者：`kanagawaorchestra2026renraku@gmail.com`
- 管理者を追加・変更するときは、`firestore.rules` の `isAdmin()` のリストを編集し、
  `firebase deploy --only firestore:rules` を実行してください。
- カテゴリーごとの絞り込み、CSV ダウンロード（Excel 対応）、迷惑投稿の削除ができます。

### JavaScript を変更したとき

フォーム・管理画面のソースは `_tools/firebase/src/` にあります。編集後に次のコマンドで `js/*.bundle.js` を作り直します。

```bash
cd kanagawa_connect_orchestra/_tools/firebase
npm install
npm run build
```

### ローカルでの動作確認（Firebase エミュレーター）

本物のデータベースを使わずに、フォーム送信や管理画面を試せます（Java が必要です）。

```bash
cd kanagawa_connect_orchestra/_tools/firebase
npm install
npm run emulators
```

http://127.0.0.1:5000/suggest.html を開くと、エミュレーターの Firestore に保存されます。

## 後から情報を更新する

### 更新のしかた（おすすめ）

全ページ共通のヘッダー・フッター・SEO設定と各ページの文章は、`_tools/build_site.py` にまとめてあります。
文章やリンクを変えるときはこのファイルを編集し、次のコマンドで全ページを作り直してください。

```bash
cd kanagawa_connect_orchestra
python _tools/build_site.py
```

全ページのメニュー・フッター・title・OGP・sitemap.xml が自動でそろいます。
HTMLを直接編集しても構いませんが、その後にスクリプトを実行すると上書きされる点に注意してください。

### 連絡先・リンク

| 項目 | 現在の設定 | 変更する場所（`_tools/build_site.py` 冒頭） |
| --- | --- | --- |
| 参加希望フォーム | Googleフォーム | `FORM` |
| Instagram | https://www.instagram.com/for.all.people_orch.kanagawa/ | `INSTAGRAM` / `INSTAGRAM_ID` |
| メール | kanagawaorchestra2026renraku@gmail.com | `MAIL` |
| 公開URL | https://kanagawa-connect-orchestra.web.app | `BASE`（`robots.txt` も合わせて変更） |

### 未決定の情報

以下は現在「決定次第お知らせします」「今後決定予定です」などと表示しています。決まったら書き換えてください。

| 項目 | 掲載ページ |
| --- | --- |
| 演奏会の開催日・会場・チケット | `concert.html`（ホームの演奏会欄にも記載あり） |
| オープニング・メイン前の作品・アンコールの曲目 | `concert.html` |
| 出演者の参加費 | `concert.html` |
| 練習日・曜日・練習会場 | `activity.html`、`recruit.html`、`index.html` |
| 参加費 | `recruit.html`（よくある質問にも記載あり） |

未決定の箇所には `status--tbd` クラスが付いているので、エディタで検索すると見つけられます。

### 募集要項PDF

`docs/recruitment-guidelines.pdf` を団員募集ページからダウンロードできます。内容を更新したら同じファイル名で置き換えてください。

## 配慮していること

- **スマートフォン優先**のレスポンシブ設計（1000px 以上でPC向けナビに切り替え）
- **アクセシビリティ**：本文へのスキップリンク、`aria-current` / `aria-expanded`、キーボード操作（Escでメニューを閉じる）、
  フォーカス表示、十分な文字コントラスト、`prefers-reduced-motion` 対応、JS無効時もメニュー表示
- **SEO**：ページごとの title / description、canonical、OGP / Twitterカード、構造化データ（JSON-LD）、sitemap.xml
- **軽量**：フレームワーク不使用、ページ内の装飾はCSSとインラインSVGのみ。Webフォントは Google Fonts（Noto Serif JP / Noto Sans JP / Cormorant Garamond）のみ。読み込み中は端末のフォントで先に表示します
