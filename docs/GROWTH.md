# 成長プラン（2D版）でいれた機能

| 機能 | どこから | サーバー | メモ |
|---|---|---|---|
| ① クラスルーム | 冒険の手帳・単語帳ホーム | `classrooms/{6ケタ}` | 範囲（単語帳の名前・番号・日付）だけ共有。詳しくは CLASSROOM.md |
| ② ゆるい連続記録・お休み券 | 冒険の手帳・単語帳ホーム | なし（端末の中） | RPG と単語帳のどちらで勉強した日も数える。7日で1枚、2枚まで |
| ② 苦手克服カード | 単語帳ホーム | なし | 2回以上間違えた単語を続けて2回正解で1枚。間違えた回数でレア度 |
| ③ 単語チャレンジ | 対戦・単語帳ホーム・クラスの範囲 | `duels/{8文字}` | 先に解いてリンクを送る。友だちは7日以内に1回だけ。`?duel=ID` で開く |
| PWA | Web版 | なし | iPhone の Safari だけにホーム画面追加の案内。読みこみ中の表示 |
| 利用回数 | 自動 | `usage/{YYYY-MM-DD}` | 機能ごとの「その日に開いた端末の数」。名前・ID なし。設定で止められる |

## 利用回数の見かた

Firebase コンソール → Firestore Database → `usage` コレクション。
文書が日付、項目が機能（`app` `vocab` `vocab_study` `battle` `exam_sea` `word_forest` `versus` `classroom` `duel` `weak_cards`）で、
値はその日にその機能を開いた端末の数です（1端末1日1回）。アプリからは読めません。

## ルールの反映

`firestore.rules` は自動では反映されません。変えたら：

```
cd rpg_game_app
firebase deploy --only firestore:rules --project tsuzuri-quest-v2
```

ルールのテスト：`rpg_game_app/test_rules/`（Firestore エミュレーターで実行）。

## まだのもの

- ④ 写真から単語帳（AI）：使う AI・費用・キーの置き場所を決めてから
