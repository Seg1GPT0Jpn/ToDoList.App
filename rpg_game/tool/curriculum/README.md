# 学習体系（カリキュラム）の書き方

つづりクエストの学習内容は、ゲームのマップとは別に、次の5段の木で管理しています。

```
教科（数学）→ 科目（数学Ⅰ）→ 分野（2次関数）→ 単元（2次関数の最大・最小）→ 小単元（文字を含む場合分け）
```

- ゲームのマップ（ルート・エリア）は遊びやすさ優先で大きくまとめ、学習の分類はここで細かく分けます。
- すべての問題は、この木の「単元」か「小単元」に属します（問題 JSON の `"unit"`）。

## ファイル

| ファイル | 役割 |
| --- | --- |
| `src/<教科>.txt` | 学習体系の本体（手で書く） |
| `map.txt` | 問題セット（問題ファイル）→ 学習体系の範囲 |
| `build.py` | `src/*.txt` → `lib/src/curriculum/data/curriculum_*.dart` |
| `assign.py` | 問題 JSON に `"unit"` を書き込み、`curriculum_index.dart`（節ごとの問題数・単元→問題セット）を作る |

## src/<教科>.txt の書き方

```
@subject math|数学|数理の国|ref=高等学校学習指導要領（平成30年告示）第2章第4節 数学
course m1|数学Ⅰ|grade=1|game=数学Ⅰの道|desc=…
  field quad|2次関数|ref=数学Ⅰ 内容(3) 2次関数
    unit maxmin|2次関数の最大・最小|pre=math.m1.quad.graph|desc=…
      sub param|文字を含む場合分け|kw=場合分け,定義域が
```

- 行の種類と字下げ：`course`（0）・`field`（2）・`unit`（4）・`sub`（6）。単元には小単元が1つ以上必要です。
- `id` は英小文字・数字・`_`。正式な ID は親とつないだもの（例：`math.m1.quad.maxmin.param`）。**一度使った ID は変えないでください**（学習記録が ID で残るため）。
- 属性（`key=value` を `|` で区切る。すべて省略可）

| 属性 | 意味 |
| --- | --- |
| `game` | ゲームの中で見せる名前 |
| `desc` | 何を学ぶかの短い説明 |
| `ref` | 学習指導要領のどこに当たるか（curriculumReference） |
| `source` / `url` | 出典と URL（なければ教科の値＝学習指導要領を受け継ぐ） |
| `grade` | 主に学ぶ学年（`1`・`2`・`3`・`1-3`） |
| `pre` | 先に学んでおきたい節の ID（`,` 区切り）。学習ルートの逆算に使う |
| `kw` | 問題を小単元に振り分けるときの手がかりの言葉（`,` 区切り。`|` は `{bar}` と書く） |

## 新しい問題を足すとき

1. 問題ファイル（`assets/questions/<教科>/<セットID>.json`）を作り、`map.txt` に「セットID 範囲 [既定の単元]」を1行足す。
2. `python3 assign.py` を実行すると、各問題の `"unit"` が自動で入ります（題名・タグ・解説と `kw` を照らし合わせます）。
3. 自動の振り分けを手で直したい問題には `"unit": "…"` と `"unitLocked": true` を書きます。
4. `python3 assign.py --check` が通ること、`dart test test/curriculum_test.dart` が通ることを確かめます。

## 問題に書ける学習上の属性（すべて省略可）

| キー | 意味 |
| --- | --- |
| `thinkingLevel` | 思考レベル 1〜8（1 知識確認 … 6 難関大学・7 最難関大学・8 東大レベル）。省略すると種類と難易度から控えめに推定（6以上にはならない） |
| `axes` | 難しさの種類（各0〜5）：`knowledge` `calculation` `reading` `thinking` `novelty` `writing` `time` |
| `sourceKind` | `original`（既定）・`officialStyle`（本番形式の自作）・`adapted`・`practice`・`officialPastExam`（利用条件を確認したものだけ） |
| `targetGrade` | 対象学年（省略すると学習体系から） |
| `phase` | 学習段階：`basics` `teikiTest` `commonTest` `standardUniv` `difficultUniv` `topUniv` `todai` |
| `estimatedSeconds` | 解く時間の目安 |
| `related` | 関連問題の ID |
| `combines` | 組み合わせて使うほかの単元の ID（複合問題） |
| `steps` | 思考の段階数 |
| `guidance` | 誘導への依存度（0〜5） |
