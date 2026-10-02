# つづりクエスト 開発書

高校の全教科を学べるクイズ RPG。Flutter + Flame 製。Web（Firebase Hosting）と Android で動く。

## 1. 構成

| フォルダ | 中身 |
| --- | --- |
| `rpg_game/` | 純粋な Dart のコア（ゲームの計算・問題データ・学習記録）。UI を持たない |
| `rpg_game_app/` | Flutter アプリ（画面・フィールド描画・音・保存・Firebase） |
| `docs/` | 設計書・更新記録（`UPDATE_V4.md` が最新の変更点） |

コアに書けるものはコアに書き、`dart test` で確かめる。アプリは表示と保存だけを担当する。

### コアの主なフォルダ（`rpg_game/lib/src/`）

| フォルダ | 役割 |
| --- | --- |
| `battle/` | バトル計算（ダメージ・カード・出題の山札） |
| `curriculum/` | 学習体系（教科→科目→分野→単元→小単元）、問題の属性（思考レベル・難しさの軸・学習段階） |
| `data/` | 教科ごとのカタログ、問題の読み込み、追加問題のセット一覧（`extra_sets.dart`） |
| `learning/` | 学習記録・間隔反復・熟練度・成長の見える化・学習ルート・複合弱点 |
| `meta/` | 魔物図鑑（67種）・実績・クエスト |
| `models/` | 問題・出題形式（8形式）と採点・敵・ステージ・進行状況 |
| `progression/` | 経験値・レベル・科目の習熟・宝箱 |
| `story/` | 物語・6つの国・住人・装備 |
| `study/` | 定期テストの海・模擬試験の空・共通テスト遺跡・総合演習・試験ワールド |
| `vocab/` | 単語帳・単語の森・つづ単（公開版）の一覧 |
| `world/` | フィールドの地形・ノートの紙と落書き |
| `versus/` | 対戦モード |

### アプリの主なフォルダ（`rpg_game_app/lib/`）

`app/`（共通サービス・テーマ）・`battle/`・`field/`（Flame のフィールド）・`meta/`（ホーム・ステータス・図鑑など）・`study/`（学習モード・総合演習）・`vocab/`（単語の森）・`audio/`・`cloud/`（Firebase）・`data/`（端末保存）

## 2. 環境構築と実行

```
cd rpg_game && dart pub get && dart test          # コアのテスト
cd rpg_game_app && flutter pub get && flutter test  # アプリのテスト
flutter run -d chrome                               # ブラウザで起動
```

## 3. 問題データ

- 元データ：`rpg_game/assets/questions/<教科>/<セット>.json`（約1万問）
- アプリが読むのは教科ごとのまとめファイル `assets/question_bundles/<教科>.json` だけ
- 1問の主な項目：`id`・`unit`（単元）・`category`・`prompt`・`choices`・`answerIndex`・`explanation`・`difficulty`・`thinkingLevel`（1〜8）・`axes`・`phase`・`format`・`combines`
- 出題形式：4択・正誤・複数選択・並べ替え・数値入力・穴埋め・段階問題・記述（ルーブリックで部分点）

### 問題を追加・修正する手順

1. JSON を追加・編集する（すべて自作。`origin` は `original`）
2. 新しいセットは `rpg_game/tool/curriculum/map.txt` に登録（`セットID 範囲 既定の単元`）
3. 練習用セットなら `extra_sets.dart` に追加
4. `python3 rpg_game/tool/curriculum/assign.py`（単元の割り当て・索引の再生成・まとめファイルの再作成）
5. `dart test`（データの検査・まとめ直し忘れ・単元の存在を確認）

学習体系そのものは `tool/curriculum/src/*.txt` を編集して `build.py` で Dart に変換する。

## 4. 主なしくみ

| しくみ | 要点 | 場所 |
| --- | --- | --- |
| 強さ | 冒険Lv（HP・守り）と科目の習熟Lv（攻撃）を分ける。推奨レベルとの差で補正し、1発で倒せないようにする | `progression/`・`battle/` |
| 学習記録 | 問題ごとに正誤・時間・ライトナー式の箱・初回結果・問題の性質・間をあけた回答を保存 | `learning/question_stat.dart` |
| 復習 | 箱ごとに 0→1→2→4→8→16→32 日後に再出題。3箱目以上で「習得」 | `learning/` |
| 学習ルート | 苦手な単元から前提を最大4段さかのぼり、根本の弱点を出す | `learning/learning_route.dart` |
| 総合演習 | 基礎3点×6・標準5点×6・応用12点×2、制限時間・部分点・分野別分析 | `study/comprehensive_exam.dart` |
| 成長 | 初見正答率・応用・初見問題・定着率、学習段階（フェーズ1〜7）のはしご | `learning/growth.dart` |

保存データは古い形式もそのまま読めるように作る（項目は末尾に足す。不明は0）。

## 5. 公開

```
cd rpg_game_app
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting --project <プロジェクトID>
```

`firestore.rules` を変えたときだけ `firebase deploy --only firestore:rules` も行う。

## 6. 守るルール

- 市販教材（LEAP・STEP など）の内容を RPG の問題に使わない。LEAP・EEVI・つづ単は、名前とパスワードで開く単語帳（`rpg_game/tool/vocab_seal.dart` で暗号化して `assets/vocab/` に置く）だけで扱う
- つづ単の公開版（`assets/words/tsuzutan_*.json`）は意味・例文・豆知識がすべて自作。RPG・海・空・単語の森で使う。単語ファイルを直したら `python3 rpg_game/tool/tsuzutan_index.py` で一覧を作り直す
- パスワードや市販教材の本文をコミットしない。プロモーションコードはハッシュ値だけを保存する
- ガチャ・ランダム型の課金は作らない
- 変更したら `dart analyze`・`flutter analyze`・両方のテストを通してからコミットする
