# つづりとの連携

つづりクエスト（tsuzuri-quest-v2）から、学校生活アプリ「つづり」（school-planner-30628）の Firebase に
2つ目のアプリとしてログインし、本人の場所 `users/{uid}/` だけを読み書きします。

| 向き | 場所（つづりの Firestore） | 中身 |
|---|---|---|
| つづり → クエスト | `users/{uid}/quest_link/upcoming` | これから2週間のテスト・提出物（日付・名前・科目・範囲・時限） |
| クエスト → つづり | `users/{uid}/study_sessions/quest_{日付}_{教科}` | 1日・1教科ぶんの勉強時間（メモ「つづりクエスト」） |
| クエスト → つづり | `users/{uid}/quest_link/results` | 今日・1週間の時間・問題数・正答率、苦手な単元 |

つづりの `firestore.rules`（本人だけが `users/{uid}/**` を読み書きできる）は変えなくてよいです。

## はじめに1回だけ（手作業）

1. Firebase コンソール（school-planner-30628）→ Authentication → 設定 → **承認済みドメイン** に
   `tsuzuri-quest-v2.web.app` を追加する（クエストの Web 版から、つづりの Google ログインを開くため）。
2. つづりのブランチ `claude/gallant-tesla-kvdjs2` を main に取り込み、いつもどおり公開する。
   ```powershell
   flutter build web --release
   firebase deploy --only hosting
   ```

## 使い方

- クエスト：アカウント → 「つづりと連携」→「つづりのアカウントでつなぐ」（つづりと同じ Google アカウントを選ぶ）
- クエストのホームに「つづりのテスト予定」が出て、「練習」でその教科の定期テストの海が開く
- バトル・単語帳・暗記カードの練習が終わるたびに、5秒後にまとめてつづりへ送る
- つづり：ホームの「つづりクエスト」カードに成果が出る。勉強時間は勉強記録・勉強時間の目標にも入る

## Android 版でも使うとき

1. tq-2d で `powershell -ExecutionPolicy Bypass -File tools\connect_tsuzuri_android.ps1` を実行する
   （つづりの Firebase にクエストの Android アプリを登録し、署名の SHA-1/SHA-256 を登録する）。
2. 最後に出る `tsuzuri android appId: …` の1行を Claude に渡す（登録ずみ：1:1033493674765:android:b03dc83421268044b64e44）
   → `FirebaseTsuzuriBackend.androidAppId` に入れると、Android 版にも「つづりと連携」が出る。
