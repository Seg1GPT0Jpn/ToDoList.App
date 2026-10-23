# つづりクエストLight

つづりクエストの軽い版。**定期テストの海・試験対策（学校の定期テスト）・単語帳・クラスルーム**と、
最低限の **今日やること・復習・学習ステータス・設定・アカウント** だけを入れた別アプリ。

- Web：`https://tsuzuri-quest-v2.web.app/light/`（フル版と同じサイトの `/light/`）
- ソース：`tsuzuri_light/`（Flutter アプリ。フル版 `rpg_game_app` の画面・保存・同期を部品として使う）

## 軽くしているところ

| フル版 | Light |
| --- | --- |
| 冒険のマップ（Flame の描画ループ）・歩く主人公・ホームの絵 | 読みこまない（ホームは一覧だけ） |
| BGM・効果音 | 鳴らさない（音のファイルを読みこまない） |
| 画面の切りかえなどの動き | いつも止める（`disableAnimations`） |
| 対戦・ランダムマッチ・単語チャレンジ・購入・物語・図鑑・装備 | 入れない |

Web の main.dart.js はフル版 約6.0MB → Light 約5.7MB（問題データと共通部分が大きいため、ダウンロード量はあまり変わらない）。
軽くなるのは主に **動かしているあいだの重さ**（描画ループ・音・アニメーションがない）。

## 進み具合をそろえるしくみ（同時連携）

フル版と Light は、同じ保存場所・同じクラウドの記録を使う。

1. **同じ端末の Web 版**：同じサイトにあるのでブラウザの保存場所を共有している。ほかのタブで保存されたら
   （`storage` イベント）とアプリにもどってきたときに読みなおし、記録をまぜる（`SameDeviceSync`）。ログイン不要。
2. **Google でログイン中**：学習記録・冒険の記録・進行状況・授業の記録をクラウドで見張り（Firestore の snapshots）、
   もう一方のアプリや別の端末で保存されたら、すぐ取りこむ（`CloudSync._listen`）。
   単語帳の覚えぐあいは、アプリにもどってきたときに取りこむ。
3. **まぜ方**（`RecordMerge`）：問題ごとに答えた回数の多い方、回数・実績は多い方（実績の日付は早い方）、
   クリアしたステージ・宝箱・購入は両方、レベル・デッキは経験値の多い方、授業は進んだ方。
   同時に使っても、どちらかで答えた記録が消えないようにしている。何度まぜても結果は同じ。
4. **別のアカウント**でログインしたときは、前の人の記録をまぜずにクラウドの記録を使う。

### 公開するときに必要なこと

- 授業の記録の同期（`users/{uid}/rpg_lessons/main`）には、Firestore のルールの更新が必要：
  `cd rpg_game_app && firebase deploy --only firestore:rules --project tsuzuri-quest-v2`
  （更新するまでは、授業の記録だけ端末の中に残り、ほかの記録は同期される）
- Web 版は、開発ブランチに push すると GitHub Actions がフル版と一緒に `/light/` へ公開する。

## 実行・テスト

```
cd tsuzuri_light
flutter pub get
flutter test
flutter run -d chrome                       # ブラウザで
flutter build web --release --pwa-strategy=none --base-href /light/
```

### Android 版

アプリ ID は `com.kazu.tsuzuri_light`（フル版とは別のアプリとして入る）。端末の保存場所は別なので、
フル版と記録をそろえるには **同じ Google アカウントでログイン**する。Google ログインを Android で使うには、
Firebase コンソールで Android アプリ（`com.kazu.tsuzuri_light`、署名の SHA-1）を追加し、
`flutterfire configure` で `firebase_options.dart` を作りなおす（フル版の手順は `GOOGLE_LOGIN.md`）。
