# 湘南高校104回生・定期テスト対策モード

「定期テストの海」の右上「湘南104」から入る、11科目の試験範囲と問題セットを管理・演習するモード。
既存の「試験対策」（試験対策ワールド）・「模擬試験の空」・通常RPGはそのまま残る。

## 保存について（重要）

- 試験計画は **この端末の中だけ**（SharedPreferences のキー `shonan_exam_plans_v1`）に保存する。
  既存の試験対策ワールド（`exam_worlds_v1`）とは別のキーで、互いに読み書きしない。
- 端末をまたいだ同期や、学年全体への配布は **まだない**。画面にも「この端末にだけ保存」と表示している。
- 「範囲表から作る」は、アプリに同梱した2026年度の範囲表（`rpg_game/lib/src/study/shonan_range_table.dart`）から
  その端末に計画をコピーする機能で、共有ではない。

## 11科目

定義は `rpg_game/lib/src/study/school_exam.dart` の `ShonanSubjects.all` だけに置く（画面ごとに持たない）。
表示は学校の科目名、`worldId` は問題を読む接続先（japanese / math / english / science / social / information）。

## 範囲表（Excel）の更新

```
cd rpg_game
python3 tool/shonan_range_table.py <範囲表.xlsx>   # lib/src/study/shonan_range_table.dart を作り直す
dart format lib/src/study/shonan_range_table.dart
dart test test/school_exam_test.dart
```

- 範囲表で空欄の科目は「未入力」のまま。授業の進み具合から推測して埋めない。
- 保健・家庭・芸術は11科目に入らないので取り込まない。
- 前期期末の「時間/日時」は科目ごとの試験日として取り込む（Excel の日付：2026/8/25〜8/29）。

## 委員会の新作問題を追加する手順

1. 委員会で承認された問題だけを JSON にする（下のひな型）。ファイルは
   `rpg_game/assets/questions/<worldId>/<setId>.json`。
2. setId は `<worldId>_shonan_104_<科目>_<番号>`。例：
   `social_shonan_104_public_economy_01`、`science_shonan_104_chem_01`、`math_shonan_104_m1_01`、
   `english_shonan_104_ec1_01`、`japanese_shonan_104_gendai_01`、`information_shonan_104_01`。
   **setId の先頭と `worldId` とフォルダ名を一致させる**（アプリは setId の先頭で教科のバンドルを読む）。
3. 単元を付けるなら `rpg_game/tool/curriculum/map.txt` に登録し、`python3 tool/curriculum/assign.py` を実行
   （手で固定するなら問題に `unitLocked: true`）。詳しくは `rpg_game/tool/curriculum/README.md`。
4. `python3 tool/bundle_questions.py` で `assets/question_bundles/<worldId>.json` に入れる。
5. `dart test test/school_question_sets_test.dart` で検証する（setId・worldId・置き場所の一致、origin が original、
   バンドルに入っているか、問題IDの重複、解説・問題文の有無）。
6. アプリの「編集」→ 科目 →「委員会の新作問題セット」の「追加」から選ぶ（一覧から選ぶか、IDを入力。
   収録されていないIDは入力時に弾く）。

### ひな型

```json
{
  "setId": "social_shonan_104_public_economy_01",
  "worldId": "social",
  "origin": "original",
  "version": 1,
  "questions": [
    {
      "id": "social_shonan_104_public_economy_01_001",
      "category": "knowledge",
      "prompt": "訪問販売のクーリング・オフの期間は？",
      "choices": ["8日間", "3日間", "14日間", "20日間"],
      "answerIndex": 0,
      "explanation": "マルチ商法（連鎖販売取引）は20日間。",
      "sourceKind": "original",
      "targetGrade": "1",
      "phase": "teikiTest",
      "tags": ["shonan-hs-104", "kouki-chukan", "public_economy"]
    }
  ]
}
```

- `origin`（データの出どころ）は必ず `original`。`sourceKind`（作った目的）は既存の値
  （`original` / `officialStyle` / `practice` など）から選ぶ。新しい値を勝手に足さない。
- `category` は既存の `knowledge` / `thinking` / `calculation` / `reading` など。
- 教科書・市販ワーク・授業プリントの問題文や解答をそのまま写さない。

## 演習のしくみ

- 科目に登録した「既存セット」と「委員会セット」をまとめて1回の演習にする（`SchoolPractice.build`）。
  同じセットIDは1回、同じ問題IDは1回だけ出題する（重複は画面に出す）。
- 収録されていない・教科がちがう・origin が original でない・データが壊れているセットは、
  理由を表示して除く。読めるセットが0なら演習は始めず、理由と解決方法を表示する。
- バトルは練習扱い（`trial: true`）なので、通常RPGのレベル・経験値・クリア状況は変わらない。
  答えた問題は既存の学習記録に残る。

## まだないもの（後続）

- 学年共通の範囲配信・端末間の同期（Firestore など。権限設計が必要）
- 科目ごとの演習数・正答率・間違いの復習（Phase 4）
- 教科書のページから問題セットを自動で選ぶこと、記述式など未対応の出題形式

## 範囲表に合う既存セット

- `tool/shonan_range_table.py` の `EXISTING` に、範囲（教材名・単元名・ページ）から内容が読みとれる既存セットだけを書く。
  LEAP など市販教材の中身や、範囲が空欄の科目は推測で埋めない。
- 前に「範囲表から作る」で作ったテストは端末に保存済みなので、範囲表のセットが増えても自動では変わらない。
  テストの画面に「範囲表に合う問題セットを足す（N個）」が出るので、押すと足りないセットだけ足す（消さない）。

## 授業（授業で学ぶ）

科目カードの「授業で学ぶ」から、範囲の単元ごとに **授業 → 確認テスト → 演習 → 復習** を進める。

- **教材**：`rpg_game/assets/lessons/<学校の科目>.json`（単元1つに授業1本）。`rpg_game/tool/lessons/<科目>.py` に書き、`python3 build.py` で検査して書き出す。本文・例題・問題はすべて新しく書いたもの（教科書・問題集の文は写さない）。`review` は `unreviewed`（作成者の確認のみ。専門家の検証済みとは表示しない）。
- **授業の中身**：目標・前提知識・重要語句 → 導入・説明・例題・重要事項・よくある間違い・まとめ → 途中の問題（1回まちがえるとヒント、2回で答えと別の説明）→ 理解度の自己評価（「わからない」なら別の角度からの説明）→ 確認テスト（8割で合格）。
- **映像授業の形**：説明ブロックは「黒板（板書＝`body`）」と「つづり先生の話（`talk`）」で見せる。先生の話は1つずつ吹き出しで進み（◀▶・全文表示）、自動再生（話し終えると次の説明へ。途中の問題では止まる）と読み上げ（端末の音声、日本語）を選べる。どちらも初期はオフで、設定は端末に残る。はじめ（`opening`）とおわり（`closing`）のあいさつつき。先生の話は `rpg_game/tool/lessons/talk_<科目>.py` に書き、`build.py` が説明ブロックの見出しと照らし合わせて、すべての説明に3つ以上の話があるか検査する。
- **状態**（`LessonState`）：未着手・学習中・授業閲覧済み・理解度確認済み・演習中・要復習・習得・再確認が必要。授業を開いただけでは習得にしない。**習得**＝確認テストに合格し、範囲の問題を8問（少なければ全部）以上解いて最後の正解率8割以上、しかも合格した日とは別の日にも演習していること。習得のあとにまちがえると「再確認が必要」。
- **保存**：授業の進み具合は端末の中（`school_lessons_v1`）。演習の正誤は既存の学習記録（MetaStore）をそのまま使う（定期テストの演習は経験値なし）。
- **網羅状況**：教材の整備（学習体系との対応・授業の整備・演習問題5問以上）と、学習者の学習（授業と確認テスト・習得）を別々に数える。教材が足りない単元が残っていたり、未習得の単元があれば「完全攻略」と表示しない。
- **学習計画**：要復習 → 再確認 → 授業の途中 → 未学習 … の順に「次に学ぶ」を出す。試験日があれば残り日数と1日の目安。出題傾向は分からないので「頻出」とは言わない。
- **学習モード**：苦手克服・間違い直し・重要事項の確認・全範囲の総復習・試験直前チェック・範囲内の総合演習（どれも同じ問題データと学習記録を使う）。
- **検査**：`rpg_game/test/school_lesson_content_test.dart` が、すべての授業が整備条件を満たすこと、後期の範囲表の全単元に授業と演習問題（5問以上）があることを確かめる。
