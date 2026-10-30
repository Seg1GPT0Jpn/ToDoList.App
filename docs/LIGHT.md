# つづりクエストLight

つづりクエストの軽い版。**定期テストの海・試験対策（学校の定期テスト）・単語帳・クラスルーム**と、
最低限の **今日やること・復習・学習ステータス・設定・アカウント** だけを入れた別アプリ。

- Web：`https://tsuzuri-quest-v2.web.app/light/`（フル版と同じサイトの `/light/`）
- ホーム画面に別のアプリとして置くとき：`https://tsuzuri-quest-v2.firebaseapp.com/light/`
  （フル版を web.app でホーム画面に追加していると、同じサイトの `/light/` はフル版の中で開いてしまう。
  firebaseapp.com は同じ公開内容の別のアドレスなので、別のアプリとして追加できる。保存場所はフル版と別になるので、
  Google でログインして記録をそろえる）
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
| 色（生成りの紙・こげ茶・色つきの絵や印） | 白黒だけで描く（`TsuzuriColors.mono` と画面全体の灰色フィルター）。罫線も引かない |
| 試験対策の「航路へ出発する」（冒険のマップ・Flame） | ボタンを出さず、プログラムもビルドから外す（`--dart-define=TSUZURI_LIGHT=true` → `lightEdition`） |
| 本文のフォントを読みこむ前に字を描く | 読み終えてから描く（`loadBodyFont`）。先に描くと、足りない字を中国語用の Noto などから十数回取りに行っていた |

### 通信量（2026-10-30・WebAssembly 版・はじめて開いたとき、brotli 圧縮後）

| | 白黒化の前 | 今 |
| --- | --- | --- |
| アプリのプログラム（main.dart.wasm） | 1.39MB | **1.32MB** |
| 本文のフォント（Noto Sans JP） | 0.73MB | 0.73MB |
| ネットのフォントの追加読みこみ（Noto Sans SC/TC/JP） | 約0.5MB（約18回） | **0** |
| 描画エンジン（skwasm、本番は Google の CDN） | 1.18MB | 1.18MB |
| Firebase の部品（gstatic） | 約0.25MB | 約0.25MB |
| 合計 | 約4.1MB | **約3.5MB** |

2回目からはブラウザに残ったファイルを使う（`no-cache` なので変わっていないかを確かめるだけで、中身はほとんど送らない）。

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

**WebAssembly 版で公開している**（`flutter build web --wasm`。対応していないブラウザでは自動で JS 版を使う）。
Firebase の部品を読みこんだ条件で計測すると：

| | JS 版 | WebAssembly 版 |
| --- | --- | --- |
| 最初の画面が出るまで | 約3.6秒 | **約1.6秒** |
| 読みこむ量の合計（Firebase をふくむ） | 13.4MB | **11.2MB** |
| メモリ | 約20MB | **約13MB** |

ログイン前のクラウド接続（Firebase の初期化・クラスルーム）が WebAssembly 版で動くことも確かめた
（Firebase の部品は npm の同じ版を使って確認）。

## 進み具合をそろえるしくみ（同時連携）

フル版と Light は、同じ保存場所・同じクラウドの記録を使う。

1. **同じ端末の Web 版**：同じサイトにあるのでブラウザの保存場所を共有している。ほかのタブで保存されたら
   （`storage` イベント）とアプリにもどってきたときに読みなおし、記録をまぜる（`SameDeviceSync`）。ログイン不要。
2. **Google でログイン中**：学習記録・冒険の記録・進行状況・授業の記録をクラウドで見張り（Firestore の snapshots）、
   もう一方のアプリや別の端末で保存されたら、すぐ取りこむ（`CloudSync._listen`）。
   単語帳の覚えぐあいもクラウドを見張ってすぐ取りこむ（`VocabCloudSync.apply`）。答えた分は2秒まとめて送り、
   アプリを閉じる・切りかえるときはすぐ送る。自分で作った単語帳は中身も送る（`book@<ID>`、新しく書きかえたほうを使い、
   消したことも伝える）。アプリに入っている単語帳・LEAP などパスワードで開く単語帳の中身は送らない（覚えぐあいだけ）。
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
flutter build web --wasm --release --pwa-strategy=none --dart-define=TSUZURI_LIGHT=true --base-href /light/
```

### Android 版

アプリ ID は `com.kazu.tsuzuri_light`（フル版とは別のアプリとして入る）。端末の保存場所は別なので、
フル版と記録をそろえるには **同じ Google アカウントでログイン**する。Google ログインを Android で使うには、
Firebase コンソールで Android アプリ（`com.kazu.tsuzuri_light`、署名の SHA-1）を追加し、
`flutterfire configure` で `firebase_options.dart` を作りなおす（フル版の手順は `GOOGLE_LOGIN.md`）。
