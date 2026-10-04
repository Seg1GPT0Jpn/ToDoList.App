# かながわコネクトオーケストラ 公式Webサイト

「すべてのひとのためのオーケストラ」— 神奈川県を中心に活動する学生主体のオーケストラの公式サイトです。
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
├── 404.html            ページが見つからない場合の表示（Firebase が自動で使用）
├── css/style.css       スタイル（配色・余白などは先頭の :root 変数で管理）
├── js/main.js          スマホメニュー、Instagramリンク設定、表示アニメーション
├── images/ogp.png      SNS共有用画像（1200×630）
├── favicon/            ファビコン・アイコン一式
├── robots.txt
├── sitemap.xml
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

## 後から情報を更新する

### Instagram のURL

設定済み：https://www.instagram.com/for.all.people_orch.kanagawa/

変更する場合は、全HTMLのURLを置換したうえで、`js/main.js` 冒頭の `SITE_CONFIG` も更新してください。

```js
const SITE_CONFIG = {
  instagramUrl: "https://www.instagram.com/for.all.people_orch.kanagawa/",
  ...
};
```

`instagramUrl` を空文字にすると、Instagramのリンクは「Instagram（準備中）」の表示に戻ります。

### 未決定の情報

以下は現在「決定次第お知らせします」「現在調整中です」と表示しています。決まったら該当ページのHTMLを書き換えてください。

| 項目 | 掲載ページ |
| --- | --- |
| 演奏会の日時・会場・チケット | `concert.html`（ホームの演奏会欄にも記載あり） |
| Opening / Pre-main / Encore の曲目 | `concert.html` |
| 練習日時・練習会場 | `activity.html`、`recruit.html`、`index.html` |
| 参加費・募集パート | `recruit.html`（よくある質問にも記載あり） |
| 正式な連絡先 | `contact.html` |

未決定の箇所は `class="pending"` が付いているので、エディタで `pending` を検索すると見つけられます。

### 参加希望フォームのURL

各ページのボタンに直接記載しています。変更する場合は全HTMLのフォームURLと、`js/main.js` の `joinFormUrl` を置換してください。

## 配慮していること

- **スマートフォン優先**のレスポンシブ設計（960px 以上でPC向けナビに切り替え）
- **アクセシビリティ**：本文へのスキップリンク、`aria-current` / `aria-expanded`、キーボード操作（Escでメニューを閉じる）、
  フォーカス表示、十分な文字コントラスト、`prefers-reduced-motion` 対応、JS無効時もメニュー表示
- **SEO**：ページごとの title / description、canonical、OGP / Twitterカード、構造化データ（JSON-LD）、sitemap.xml
- **軽量**：フレームワーク不使用、ページ内の装飾はCSSとインラインSVGのみ。Webフォントは Google Fonts（Noto Serif JP / Noto Sans JP）のみ
