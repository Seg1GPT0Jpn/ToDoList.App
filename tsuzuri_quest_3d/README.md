# つづりクエスト3D（技術検証の試作）

2D 版「つづりクエスト」（`../rpg_game_app`）とは**別のゲーム**です。2D 版のコード・保存データには一切触れません。

- 3D 描画：flutter_scene 0.24.3（Android は Impeller＋Flutter GPU、Web は WebGL2）
- 物理・当たり判定：flutter_scene_rapier 0.5.2（Rapier）
- 問題データ・バトルの計算・経験値とレベル：共通のコア `../rpg_game`（2D 版と同じもの）
- セーブ：この端末だけ（`tq3d_progress_v1`・`tq3d_field_v1`・`tq3d_quality_v1`）。クラウドには送らない

## フォルダ

| 場所 | 中身 |
|---|---|
| `lib/game/field3d.dart` | 草原の配置・位置と倒した敵の保存形式（描画なし。単体テストあり） |
| `lib/game/save3d.dart` | 3D 版のセーブ（2D 版とは別のキー） |
| `lib/game/questions.dart` | 問題の読み込み（rpg_game の問題まとめファイル） |
| `lib/field/` | 3D 画面（描画・物理・カメラ・操作・計測表示） |
| `lib/game/field_battle.dart` | その場で戦うバトルの流れ（正解→剣をふる→当てる）。計算は rpg_game の BattleEngine |
| `lib/field/hero_model.dart` | 2D 版の主人公を基本図形で組み立てた 3D モデル（歩き・剣のふり） |
| `CREDITS.md` | 素材の出典とライセンス |
| `web/field3d/` | Web 用の物理エンジン（wasm）。外部サーバーに頼らず自分のサイトから読む |

## 動かし方（PC・PowerShell）

```
cd C:\Users\kzmse\ToDoList.App
git fetch origin claude/field3d-proto
git checkout claude/field3d-proto
cd tsuzuri_quest_3d
flutter pub get
```

### Android 実機（Wi-Fi デバッグ）
```
adb connect <スマホのIP>:<ポート>
flutter run --profile -d <デバイスID>
```
- 性能を測るときは `--profile`（debug は遅く出るので測定に使わない）
- 初回は物理エンジン（Rapier）のビルド済みファイルを自動でダウンロードする

### PC ブラウザ
```
flutter run -d chrome --profile --dart-define=FLUTTER_SCENE_RAPIER_WASM_URL=field3d/flutter_scene_rapier_native.wasm
```

## 操作
- PC：WASD／矢印で移動、Shift で走る、マウスのドラッグ・Q/E でカメラ、ホイールで距離、Space/E で話す、Esc で戻る
- スマホ：左下のスティックで移動（端まで倒すと走る）、画面の右側をドラッグでカメラ、「はなす」ボタン

## バトル（その場で戦う）
1. スライムに近づいて Space（スマホは「たたかう」ボタン）でバトル開始。画面は切りかわらない
2. 問題に答える（PC は 1〜4 キーかクリック）。制限時間あり
3. 正解すると 4 秒間「剣（えんぴつ）をふれる時間」。クリック／Space／J（スマホは右下の えんぴつボタン）でふる
   - 届く距離（2.4m）で当てると攻撃。答えてから当てるまでが速いとクリティカル
   - ふれずに時間切れ → ふり遅れ（ダメージ半分・反撃も半分）
   - 届かないときは近づいてもう一度ふれる
4. 不正解・時間切れは敵の体当たり（反撃）
5. 勝つと経験値・レベル（2D 版と同じ計算。保存は 3D 版だけ）。Esc／「にげる」で離脱、遠くへ離れても離脱

計算は rpg_game の BattleEngine。剣の流れは `lib/game/field_battle.dart`（単体テストあり）。

## 計測
右上に fps・平均と最大のフレーム時間・初回表示までの時間・メモリを常に表示する。
メニュー（︙）で画質を「高／標準／軽量」に切りかえられる（計測用）。
- メモリ：Android はアプリ全体の常駐メモリ（RSS）、Web は JS のヒープだけ（GPU のメモリは含まない）
