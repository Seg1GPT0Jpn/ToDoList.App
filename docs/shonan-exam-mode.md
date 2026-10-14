# 湘南高校104回生・定期テスト対策モード

## 今回追加したもの

- 11科目の管理：試験範囲、使用教材・備考、試験日を登録できます。
- 問題セットの分離：各科目で「既存問題セットID」と「委員会の新作問題セットID」を別々に保持します。
- 問題セットの統合演習：両方のIDを読み込み、重複問題を除いて既存の「定期テストの海」のバトル画面で出題します。
- 保存場所：湘南高校モード専用の SharedPreferences キー（`shonan_exam_plans_v1`）に保存します。現在は端末内保存で、端末間同期には未対応です。
- 一般向けの「定期テストの海」は残し、湘南高校モードは別画面・別保存領域で追加しています。

## 管理する11科目

| ID | 科目 | 既存問題のワールド |
|---|---|---|
| `gendai_kokugo` | 現代の国語（現代文） | `japanese` |
| `gengo_bunka` | 言語文化（古文・漢文） | `japanese` |
| `math1` | 数学Ⅰ（数学Ⅰ・Ⅱ） | `math` |
| `math_a` | 数学A（数学A） | `math` |
| `ec1` | ECⅠ（English Communication Ⅰ：総合） | `english` |
| `ronhyo1` | 論表Ⅰ（Logic and Expression Ⅰ：文法） | `english` |
| `chemistry_basic` | 化学基礎 | `science` |
| `biology_basic` | 生物基礎 | `science` |
| `geography_general` | 地理総合 | `social` |
| `public_economy` | 公共（政治経済の経済分野） | `social` |
| `information1` | 情報Ⅰ | `information` |

## 問題セットIDの入力方法

IDはカンマ、読点、セミコロン、改行で区切って複数入力できます。

- 既存問題セット：アプリに収録済みのセットIDを「既存問題セットID」へ入力します。
- 新作問題セット：委員会で作成し、検証済みのセットIDを「委員会の新作問題セットID」へ入力します。

問題セットを読み込む際、画面は次のチェックを行います。

1. セットIDが見つかること。
2. セットの `worldId` が科目に対応するワールドであること。
3. 問題データの `origin` が `original` であること。

読み込めなかったセット、別ワールドのセット、RPG演習に使用できない出典のセットは出題から除外し、通知します。セットIDの入力誤りや、問題バンドル未再生成を最初に確認してください。

## 委員会の新作問題を追加する手順

1. `rpg_game/assets/questions/<worldId>/<setId>.json` に問題セットを追加します。
2. `setId` は既存セットと重複しないようにします。湘南高校向けの例は `science_shonan_104_chem_01` です。IDの先頭はワールドID（`science`、`math`、`english`、`japanese`、`social`、`information`）にします。
3. セットJSONの `worldId` を同じワールドIDにし、アプリ同梱の独自問題では `origin: "original"` とします。
4. `rpg_game/tool/curriculum/map.txt` に、セットID・学習体系の範囲・既定の単元を追記します。
5. `cd rpg_game/tool/curriculum && python3 assign.py` を実行し、単元IDの割り当てと問題バンドルの更新を行います。必要に応じて `python3 assign.py --check` で確認します。
6. 問題バンドルの整合性テストとカリキュラムのテストを実行します（例：`dart test test/question_bundle_test.dart`、`dart test test/curriculum_test.dart` を `rpg_game` ディレクトリで実行）。
7. 対象の試験計画を開き、該当科目の「委員会の新作問題セットID」にセットIDを登録します。

問題を既存問題バンクに直接混ぜるのではなく、独立したJSONセットとして保管することで、通常の問題と湘南高校向け問題を別々に管理できます。

## 問題セットJSONのひな型

以下は形式例です。角括弧で示したプレースホルダーは実際の問題・正答・解説・単元IDに置き換えてください。ひな型自体は配信対象のアセットではありません。

```json
{
  "setId": "science_shonan_104_chem_01",
  "worldId": "science",
  "origin": "original",
  "version": 1,
  "questions": [
    {
      "id": "science_shonan_104_chem_01_001",
      "unit": "science.chemistry.structure.atom.structure",
      "unitLocked": true,
      "category": "knowledge",
      "prompt": "【問題文を入力】",
      "choices": [
        "【選択肢A】",
        "【選択肢B】",
        "【選択肢C】",
        "【選択肢D】"
      ],
      "answerIndex": 0,
      "explanation": "【正答の根拠と、考え方を入力】",
      "tags": ["shonan-hs-104", "teiki-test"],
      "sourceKind": "original",
      "targetGrade": "1",
      "phase": "teikiTest"
    }
  ]
}
```

## 現段階の制約・次の改善候補

- 試験計画は端末内保存です。クラウド同期は別の作業です。
- 問題セットIDは現在、画面で手入力します。次の段階で、セットのタイトル・単元・出典種別から検索して選択できるカタログUIを追加すると安全です。
- 試験範囲テキストと問題セットは、現在はIDの手動登録で関連づけます。範囲のページ番号から問題を自動選択する機能はまだありません。ページ・単元とセットの対応表を整備してから実装してください。
- 既存の総合カリキュラムは「英語」「数学」「国語」「理科」「社会」「情報」の大区分です。11科目への分割表示は湘南高校モードで行い、通常のカリキュラム・ワールドには変更を加えていません。
- 新作問題は、作成したAIとは別の担当による解答検証と、委員会による最終確認後に収録してください。
