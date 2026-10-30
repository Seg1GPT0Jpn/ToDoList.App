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
| 対戦・ランダムマッチ・単語チャレンジ・購入・物語・図鑑・装備 | 入れない（週替わり単語バトルは使える） |
| 起動するとすぐ Firebase（約0.25MB）を読む | ログインしている人・クラスルームに入っている人だけ。ほかの人は、ログイン・クラスルームの画面を開くときに読む（`requestCloud`） |
| ネットがないと開けない | **Service Worker（`web/sw.js`）でアプリ本体を手元に入れ、2回目からはネットなしで起動する** |
| 色（生成りの紙・こげ茶・色つきの絵や印） | 白黒だけで描く（`TsuzuriColors.mono` と画面全体の灰色フィルター）。罫線も引かない |
| 試験対策の「航路へ出発する」（冒険のマップ・Flame） | ボタンを出さず、プログラムもビルドから外す（`--dart-define=TSUZURI_LIGHT=true` → `lightEdition`） |
| 本文のフォントを読みこむ前に字を描く | エンジンが起動時に読み、読み終えてから描く。先に描くと、足りない字を中国語用の Noto などから十数回取りに行っていた |

### 通信量（2026-10-30・WebAssembly 版・はじめて開いたとき、brotli 圧縮後）

| | 白黒化の前 | 白黒化（c0a3ec5） | 今 |
| --- | --- | --- | --- |
| アプリのプログラム（main.dart.wasm） | 1.39MB | 1.32MB | **1.29MB** |
| 本文のフォント（Noto Sans JP） | 0.73MB | 0.73MB | 0.73MB |
| ネットのフォントの追加読みこみ（Noto Sans SC/TC/JP） | 約0.5MB（約18回） | 0 | 0 |
| エンジンの英字フォント（Roboto）・同梱ファイルの一覧 | 0.08MB | 0.08MB | **0** |
| 描画エンジン（skwasm、本番は Google の CDN） | 1.18MB | 1.18MB | 1.18MB |
| Firebase の部品（gstatic） | 約0.25MB | 約0.25MB | 約0.25MB |
| 合計 | 約4.1MB | 約3.5MB | **約3.4MB** |

本文のフォントは `tsuzuri_light/pubspec.yaml` で **Roboto という名前**で登録している（中身は Noto Sans JP）。
描画エンジンは Roboto がないと別に取りに行くので、そのかわりにこれを起動時に読ませる。google_fonts は使わない（`bundledSans`）。

### 2回目から・オフライン（Service Worker）

| | 通信量 | 最初の画面まで |
| --- | --- | --- |
| はじめて開いたとき | 約3.4MB | 約1.1秒 |
| 2回目から（ログインしていない人） | **0KB**（新しい版がないかの確認1回だけ） | **約0.4秒** |
| ネットがないとき | 0KB | **約0.4秒**（一度開いた単語帳・問題も使える） |

- アプリ本体（プログラム・描画エンジン・フォント）は版ごとの入れ物（`light-shell-<版>`）に入れる。版は公開するときに
  `deploy-web.yml` がビルドの中身から決めて `sw.js` に書きこむ。新しい版は裏で入り、**次に開いたとき**に切りかわる。
- 単語帳・問題などのファイル（`assets/packages/`）は版をまたいで残し（`light-data-v1`）、手元のものをすぐ出して、
  ネットにつながっていれば裏で新しいかを確かめる（変わっていなければほとんど通信しない）。
- フル版の index.html は、古い Service Worker を外すときに Light（`/light/`）のものは残す。
- 描画エンジンは Google の CDN ではなく同じサイトに置く（`--no-web-resources-cdn`。Service Worker に入れるため）。
- **ログインしている人のクラウド同期**：これまでは起動のたびに学習記録・単語帳などをまるごと2回（読みこみ＋見張り）、
  アプリにもどるたびにもう1回読んでいた。いまは Firestore の記録を端末（IndexedDB）に残し、読みこみも見張りと同じ読み方
  （`firstFromServer`）にしたので、起動したときは1回、少し前（目安30分以内）に読んだ分は変わったところだけが届く。
  ログインした状態では計測できていない（この環境では Google でログインできないため）。
- Flutter で作っているので、はじめて開くときの約3.4MB（描画エンジン約1.2MB・プログラム約1.3MB・日本語フォント約0.7MB）より小さくはできない。


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
flutter build web --wasm --release --pwa-strategy=none --no-web-resources-cdn --dart-define=TSUZURI_LIGHT=true --base-href /light/
```

### Android 版

**ビルドするときは必ず `--dart-define=TSUZURI_LIGHT=true` をつける**（つけないと、冒険のマップ・単語チャレンジ・
google_fonts のプログラムが入ったままになる）。`--split-debug-info` でエラー調査用の記号を別のフォルダに分ける（APK が約1.5MB 小さくなる。
フォルダはエラーを調べるときのために残しておく）。

```
flutter build apk --release --split-per-abi --dart-define=TSUZURI_LIGHT=true --split-debug-info=build/symbols
flutter build appbundle --release --dart-define=TSUZURI_LIGHT=true --split-debug-info=build/symbols
```

| APK（arm64） | 大きさ |
| --- | --- |
| 前（`--dart-define` なし・全部入り） | 77.0MB |
| 今 | **31.9MB** |

- つづりクエストの部品から入ってくるが Light では使わないファイル（BGM・効果音、見出しの明朝体、本文フォントの写し）と、
  **資料（materials）・予想問題（mock_exams）の約36MB** は APK に入れない（`android/app/build.gradle.kts` で、Flutter が同梱ファイルを写すときに外す）。
- 資料・予想問題は、**開いたときに**公開サイト（Light の Web 版と同じファイル）から読み、端末に残す（`lib/remote_assets_io.dart`）。
  一度開いたものはネットなしで開ける。7日に1回まで、裏で新しくなっていないかを確かめる。
- Web 版は `deploy-web.yml` で使わないファイルを公開しない。

アプリ ID は `com.kazu.tsuzuri_light`（フル版とは別のアプリとして入る）。端末の保存場所は別なので、
フル版と記録をそろえるには **同じ Google アカウントでログイン**する。Google ログインを Android で使うには、
Firebase コンソールで Android アプリ（`com.kazu.tsuzuri_light`、署名の SHA-1）を追加し、
`flutterfire configure` で `firebase_options.dart` を作りなおす（フル版の手順は `GOOGLE_LOGIN.md`）。
