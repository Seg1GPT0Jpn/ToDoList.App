# つづりクエスト for elementary and junior high school 開発書

小学1年生〜中学3年生の5教科を学べるクイズ RPG。高校生向けの「つづりクエスト」
（`claude/gallant-tesla-kvdjs2` ブランチ）をもとに作った別アプリ。Flutter + Flame 製で、
Web（Firebase Hosting）と Android で動く。

## 1. 構成

| フォルダ | 中身 |
| --- | --- |
| `rpg_game/` | 純粋な Dart のコア（ゲームの計算・問題データ・学習記録）。UI を持たない |
| `rpg_game/tool/junior/` | **問題データの生成ツール**（5教科の問題・ワールド・学習体系をここから作る） |
| `rpg_game_app/` | Flutter アプリ（画面・フィールド描画・音・保存・Firebase） |
| `docs/` | 設計書（`EVOLUTION.md`・`UPDATE_V4.md` は高校版のときの記録） |

## 2. ワールドと学年の道

5教科とも「教科 → 学年の道（ルート） → エリア」。広場から上下左右の門（1辺に3つまで）で道に入る。

| ワールド | 教科 | 道（左／下／右／上） | 料金 |
| --- | --- | --- | --- |
| 英語の国 | 英語 | 小3・4 ／ 小5・小6 ／ ― ／ 中1・中2・中3 | 無料 |
| 数の国 | 算数・数学 | 小1・小2 ／ 小3・小4 ／ 小5・小6 ／ 中1・中2・中3 | 買い切り |
| 言の葉の国 | 国語 | 小1・小2 ／ 小3・小4 ／ 小5・小6 ／ 中1・中2・中3 | 買い切り |
| 理の国 | 理科 | 小3・小4 ／ 小5・小6 ／ ― ／ 中1・中2・中3 | 買い切り |
| 時と地の国 | 社会 | 小3・小4 ／ 小5・小6 ／ ― ／ 地理・歴史・公民 | 買い切り |

- 1つの道は 8〜11 エリア。途中と最後にボス（装甲あり・前のエリアの問題もまとめて出す）
- ボスの装甲は、その道でいちばん多い種類の問題で割れる（`tool/junior/lib.py` の `route_categories`）
- 道の最初のボスに負けると仲間が捕まり、再戦で勝つと仲間になる
- 公開版の有料4教科は、プロモーションコードでまとめて受け取れる（コードは本家と同じ）

学習モード：
- **定期テストの海**：各教科の学年の道をエリアごとに練習。英語は中1〜中3の文法23単元と単語帳4冊
- **高校入試の空**：海より難しい上級者向け。入試模試（制限時間つき・100点満点）もここから
- **単語の森**：中1・中2・中3の単語と、中学の熟語（各60語）
- **対戦モード**・**総合演習**・**復習の塔**・**試験対策ワールド** は本家と同じしくみ

## 3. 問題データの作り方

問題は JSON を手で書かず、`rpg_game/tool/junior/` の Python で書いて生成する。

| ファイル | 教科 |
| --- | --- |
| `english.py`・`sea.py` | 英語の国・定期テストの海（英語）・単語帳 |
| `math_e.py`・`math_j.py` | 算数（小1〜小6）・数学（中1〜中3）。計算問題はプログラムで作る |
| `japanese.py` | 国語。漢字の読み書きは学年ごとの語のリストから作る |
| `science.py`・`social.py` | 理科・社会 |
| `lib.py`・`helpers.py`・`gen.py` | 共通の道具と出力 |

```
R.area('一次方程式', '数と式', [
    Q('c', '3x + 5 = 20 を解くと？', 'x = 5', ['x = 3', 'x = 15', 'x = 25'], '移項して 3x = 15'),
    ...
])
```

- `Q(種類, 問い, 正解, まちがい3つ, 解説, s=英文など)`。種類は k=知識・c=計算・t=考察・m=意味・u=語法
- ふつうのエリアは10問以上、ボスは8問以上（`area()` が確かめる）
- 同じ道で同じ問いを2度出すと `gen.py` が止まる
- `lesson=[(見出し, 説明, 例)]` を書くと宿の授業になる（書かないエリアは問題から自動で作る）

問題を直したら：

```
cd rpg_game/tool/junior
python3 gen.py            # 問題 JSON・カタログ・学習体系・まとめファイルを作り直す
cd ../.. && dart test     # コアのテスト（問題データの検査をふくむ）
```

`gen.py` が書き出すもの：`assets/questions/<教科>/*.json`、`lib/src/data/<教科>_catalog.dart`、
`lib/src/study/junior_lessons.dart`、`tool/curriculum/src/*.txt`・`map.txt`、
`assets/question_bundles/*.json`（アプリが読むのはこのまとめファイルだけ）。

## 4. 環境構築と実行

```
cd rpg_game && dart pub get && dart test          # コアのテスト
cd rpg_game_app && flutter pub get && flutter test  # アプリのテスト
flutter run -d chrome                               # ブラウザで起動
```

## 5. 公開

```
cd rpg_game_app
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting --project tsuzuri-quest-junior-26426
```

- アプリ ID は `com.kazu.tsuzuri_quest_junior`（Android）・`com.kazu.tsuzuriQuestJunior`（iOS）
- `.firebaserc` は新しいプロジェクト `tsuzuri-quest-junior-26426` を指している。`lib/firebase_options.dart` は
  まだ仮（Firebase なしで動き、記録は端末の中だけ）。Firebase で高校版とは別のプロジェクトを作り、
  `flutterfire configure` で作り直す（手順は `docs/GOOGLE_LOGIN.md`）

## 6. 守るルール

- 問題はすべて自作（`origin` は `original`）。市販教材の内容は使わない
- 漢字・語句・年号など事実を書いた問題は、教科書の範囲と照らして確かめてから足す
- ガチャ・ランダム型の課金は作らない
- 変更したら `dart analyze`・`flutter analyze`・両方のテストを通してからコミットする
