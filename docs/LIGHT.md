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
| 見出しの明朝体（Noto Serif JP、約2MB） | 読みこまない（本文の Noto Sans JP を太字で描く：`sansOnly`） |
| 起動時にすべてのプログラムを読む | ホームに必要な分だけ先に読み、各画面（`light_pages.dart`）とクラウド（`light_cloud.dart`）はあとから読む（deferred import） |
| Firebase の準備ができるまで起動を待つ | 待たずにホームを出し、つながったらログイン・クラスルームを差しこむ（`LightRoot`） |
| 対戦・ランダムマッチ・単語チャレンジ・購入・物語・図鑑・装備 | 入れない |

### 計測（Chromium・CPU を4倍遅くしてスマホ相当に。2026-10 時点）

| | フル版 | Light（軽量化前） | Light（今） |
| --- | --- | --- | --- |
| 最初の画面が出るまで | 約10秒* | 約10秒* | **約1.2秒** |
| 起動時のプログラム（main.dart.js） | 6.0MB | 5.6MB | **3.7MB**（残り約2MBは画面を開いたとき） |
| 読みこむ量の合計 | 15.0MB | 14.4MB | **12.4MB** |
| メモリ（JavaScript） | 約30MB | 約18MB | 約19MB |
| 何もしていないときの CPU（10秒あたり） | 約10秒 | 0 | 0 |

\* 検証環境では Firebase につながらないため、フル版と軽量化前の Light はつながるのを待つ時間（最大8秒）がふくまれる。
読みこむ量には描画エンジン（CanvasKit 約5.3MB）がふくまれる。本番ではこれは Google の CDN から読み、一度読めばブラウザに残る。

WebAssembly 版（`flutter build web --wasm`）も試した：読みこむ量 10.0MB・メモリ 約11MB とさらに軽く、画面も正しく動いた。
ただし Firebase（ログイン・同期）を WebAssembly で動かす確認ができていないので、公開は JS 版のまま。

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
