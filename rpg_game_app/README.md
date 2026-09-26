# つづりクエスト（仮）— Flutter 版の試作アプリ

`../rpg_game`（ゲームのロジックと問題データ）を使って、実際に遊べる画面を作った単体アプリです。
あとで school_planner の `lib/features/rpg_game/` に組み込みます。

| ワールドマップ | フィールド | 遭遇 |
| --- | --- | --- |
| ![](docs/screenshots/1_world_map.png) | ![](docs/screenshots/2_field.png) | ![](docs/screenshots/3_encounter.png) |

| バトル（正解） | バトル（不正解） | 結果 |
| --- | --- | --- |
| ![](docs/screenshots/4_battle_hit.png) | ![](docs/screenshots/5_battle_miss.png) | ![](docs/screenshots/6_result.png) |

## 動かし方

school_planner を開発している PC（Flutter が入っている PC）で次を実行します。

```
cd rpg_game_app
flutter pub get
flutter run -d chrome     # ブラウザで動かす（いちばん簡単）
flutter run               # Android の実機やエミュレーターをつないでいる場合
```

操作方法:
- **歩く**: 画面左下の十字ボタン（押している間歩き続ける）。PC では矢印キーか WASD キーでも歩けます
- **話しかける**: 敵や看板に向かって歩くと話しかけられます
- **バトル**: 4択をタップして回答します。制限時間を過ぎると時間切れです
- **最初からやり直す**: ワールドマップ右上の「︙」→「データをリセット」

## 画面と演出

| 画面 | 内容 |
| --- | --- |
| ワールドマップ | 6教科の国。英語だけ遊べて、ほかは鍵つきの「準備中」。主人公がその場で足ぶみしている |
| フィールド | 方眼ノートの世界を自由に歩ける見下ろし型マップ（Flame を使用）<br>道をふさぐ敵に話しかけるとバトル。倒した敵は★がついて道の脇へどく<br>近くの敵には「！」、最後にはトロフィーがある |
| バトル | 敵の登場（上から落ちてくる）、待機中のゆれ、えんぴつの斬撃、敵が白く光ってゆれる、ダメージ数字<br>「すばやい！」「◯ COMBO!」表示、被弾時の画面ゆれと赤いふち、HP バーの減少、撃破時のインクしぶき<br>不正解のときは解説を表示 |
| 結果 | 「勝利」「敗北」のはんこ、経験値バーが伸びる演出、LEVEL UP 表示、能力の上昇量<br>次のステージの解放、間違えた問題のふりかえり |

絵はすべてコード（`lib/art/`）で「ノートの落書き風」に描いているので、画像素材はありません。
あとでイラストに差し替えるときは、`paintHero` と `paintEnemy` を画像の描画に置き換えるだけで済みます。

## 構成

```
lib/
├─ main.dart
├─ app/        テーマ（つづりの配色）、サービスの受け渡し
├─ art/        主人公・敵・ノートの紙を描くコード
├─ world/      ワールドマップ画面（購入ダイアログはダミー）
├─ field/      フィールド（Flame のゲーム本体・マップ定義・画面）
├─ battle/     バトル画面・結果画面
└─ data/       進行状況の保存（端末内。移植時は Firestore に差し替え）
```

## school_planner に組み込むときの注意

- UI はこの試作では `package:flutter/material.dart` を使っています。school_planner では `material_ui` パッケージと既存の `lib/app/theme.dart` に合わせて書き換えます
- 保存先（`PrefsProgressRepository`）は、Firestore の `users/{uid}/rpg_progress/main` を読み書きする実装に差し替えます
- 準備中ワールドの購入ダイアログは、デバッグ版でだけ「購入する」ボタンが出ます（ダミー購入）
- マップの形は `lib/field/field_map.dart` の文字の並びで決まります。敵の配置と進行順がおかしくないかは、テスト（`test/field_map_test.dart`）で自動チェックしています
