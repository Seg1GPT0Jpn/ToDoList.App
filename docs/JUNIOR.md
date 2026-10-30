# つづりクエスト 小中学生版（for elementary and junior high school）

- Web：https://tsuzuri-quest-junior-26426.web.app/
- 小1〜中3・5教科（英語・算数数学・国語・理科・社会）の学年ルート制ワールド、4,270問。物語は「白紙の聖典と大樹アカデミア」。

## しくみ

小中学生版は、**高校生版（rpg_game・rpg_game_app）と同じプログラム**で動き、**中身だけ**を入れかえて作る。
高校生版に入れた改良（画面・軽量化・同期など）は、小中学生版にもそのまま入る。

| 置き場所 | 中身 |
| --- | --- |
| `editions/junior/files/` | 小中学生版の中身。リポジトリと同じ場所の名前で置いてある（ワールド・問題・学習体系・授業・物語・定期テストの海の単元・アイコン・問題の生成ツール `rpg_game/tool/junior/`・中身のテスト） |
| `editions/junior/apply.sh` | リポジトリの写しを小中学生版の中身に入れかえる（高校生版だけの同梱ファイルを外し、中身を重ね、Web 版の題名を変える） |
| `juniorEdition`（`rpg_game/lib/src/edition.dart`） | `--dart-define=TSUZURI_JUNIOR=true` のとき true。高校向けの機能を出さない・文言を変える |

小中学生版で出さないもの：共通テスト遺跡・総合演習・LEAP/EEVI（パスワードで開く単語帳と週替わり単語バトル）・
学校専用の対策（湘南）。Firebase を設定するまでは、クラスルーム・単語チャレンジ・Google ログインも出さない（記録は端末の中だけ）。

もとは `claude/todolist-app-update-ynuzwf` ブランチ（10/2 の高校生版から作りかえたもの）。そこから中身だけを取り出した。

## ビルド・テスト（手元）

リポジトリをそのまま書きかえるので、**別の写しで**行う（もとにもどすときは `git checkout -- . && git clean -fd`）。

```
sh editions/junior/apply.sh
cd rpg_game && dart test test/junior_data_test.dart     # 小中学生版の中身のテスト
cd ../rpg_game_app
flutter run -d chrome --dart-define=TSUZURI_JUNIOR=true
flutter build web --wasm --release --dart-define=TSUZURI_JUNIOR=true
```

高校生版のテスト（`rpg_game/test` のほかのテスト）は高校生版の中身を前提にしているので、小中学生版の写しでは落ちる。

## 自動公開

`deploy-web.yml` の `deploy-junior` が、開発ブランチに push するたびに小中学生版を作って公開する。
GitHub に秘密鍵 **`FIREBASE_SERVICE_ACCOUNT_TSUZURI_QUEST_JUNIOR_26426`** を登録すると動く（未登録の間は何もしない）。

鍵の登録（PC で、高校生版のときと同じ）：

```
cd C:\\Users\\kzmse\\tq-2d\\rpg_game_app
firebase login
firebase init hosting:github --project tsuzuri-quest-junior-26426
```

- 「For which GitHub repository…」には `Seg1GPT0Jpn/ToDoList.App` と入れる
- 鍵が GitHub に自動で登録される。そのあとの質問（ビルドのスクリプト・自動デプロイの設定ファイルを作るか）は **No**
  （公開は `deploy-web.yml` が行う）。`firebase.json`・`.firebaserc` を書きかえるかを聞かれたら **No**

## Google ログイン・クラスルームを使えるようにする（あとで）

小中学生版の Firebase の設定（`firebase_options.dart`）はまだ仮で、記録は端末の中だけに保存される。
使えるようにするには、Firebase コンソールで `tsuzuri-quest-junior-26426` に Web アプリを追加して Authentication（Google）と
Firestore を有効にし、`flutterfire configure --project tsuzuri-quest-junior-26426` で作った `lib/firebase_options.dart` を
`editions/junior/files/rpg_game_app/lib/firebase_options.dart` に置く（Firestore のルールも高校生版と同じものを反映する）。
設定すると、ログイン・クラスルーム・単語チャレンジが自動で出る。
