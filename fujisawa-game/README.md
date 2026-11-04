# ふじさわ散歩 3D

藤沢市と、その周りの鉄道沿線（小田急江ノ島線・相鉄・ブルーライン・東海道線）を実寸で再現した3D散歩ゲームです。
電車は時刻表どおりに走っていて、乗ることもできます。Three.js r160 を使い、HTML 1枚とデータ1つで動きます。

- 公開版（Firebase Hosting）: https://fujisawa-3d.web.app/
- 地図データ © OpenStreetMap contributors (ODbL)
- 建物: 3D都市モデル（Project PLATEAU）藤沢市・横浜市（国土交通省、CC BY 4.0 互換）
- 航空写真: 国土地理院 シームレス空中写真
- 標高・建物種別: 国土地理院（基盤地図情報 DEM5A/5B/10B、ベクトルタイル）

## 動かし方
`index.html` と `fujisawa-data2.wasm` を同じフォルダに置き、HTTP で開きます。
`file://` で直接開くと fetch が使えないので動きません。

```bash
cd fujisawa-game
```

```bash
python3 -m http.server 8000
```

ブラウザで http://localhost:8000/ を開きます。

データの中身は gzip で圧縮したバイナリです。拡張子が `.wasm` なのは、Artifact で配信できるファイル形式に合わせるためで、WebAssembly ではありません。

## 作り込んだ15カ所
駅の構造はウィキペディアの「駅構造」、各社の構内図、OpenStreetMap、航空写真で確認して作っています。図面がないため、細かな配置は推定を含みます。
- **湘南台駅**: 小田急 地上2面2線とガラス屋根／B1 3社のコンコース／B2 ブルーライン／B3 相鉄／地上から歩ける出入口8カ所／湘南台文化センターの球体
- **藤沢駅**: JR 島式2面4線と橋上駅舎、北口・南口デッキ、3・4番線の80系売店／小田急 頭端式2面3線と乗換跨線橋／江ノ電 ODAKYU 湘南 GATE 2階
- **藤沢本町駅**: 相対式2面2線、1番線側の駅舎、跨線橋
- **横浜駅**: JR 4面8線とB1の中央・みなみ・きた通路／相鉄 2F 頭端式4面3線／ブルーライン B3
- **戸塚駅**: JR 2面4線、2F橋上駅舎と東西デッキ、B1自由通路とJR地下改札／ブルーライン B2改札・B3ホーム
- **大和駅**: 小田急 高架島式2面4線／1F共通コンコース／相鉄 地下島式1面2線
- **上大岡駅**: ブルーライン B1コンコース・B2ホーム／ゆめおおおか内の京急駅（景色）
- **学校**: 六会小・湘南台中・六会中・湘南台小・湘南台高・湘南高・秋葉台小・秋葉台中（校舎は PLATEAU の外形と高さ、教室・廊下・階段・体育館は中を歩けます。プール、校庭の道具、門と校名板つき）
- 周辺は PLATEAU の建物（横浜・藤沢駅周辺は屋根形状つき）と航空写真

## 公開（Firebase Hosting）
`main` に push すると GitHub Actions（`.github/workflows/firebase-hosting.yml`）が Firebase プロジェクト `fujisawa-3d` に公開します。
最初の1回だけ、リポジトリの Secrets に `FIREBASE_SERVICE_ACCOUNT_FUJISAWA_3D` を登録してください。いちばん簡単なのは、手元で次を実行する方法です（Secret の登録まで自動でやってくれます）。

```bash
npx firebase-tools login
```

```bash
npx firebase-tools init hosting:github
```

手動で公開する場合は `npx firebase-tools deploy --only hosting` です。

## ファイル構成
| パス | 内容 |
|---|---|
| `index.html` | 完成版（`src/build.sh` で作られたもの） |
| `fujisawa-data2.wasm` | 地形・建物・道路・ホーム・線路・路線・駅のデータ（約13MB） |
| `fujisawa-places.wasm` | 15カ所の詳細エリアの建物（PLATEAU） |
| `places/*.jpg` | 15カ所の航空写真（国土地理院 シームレス空中写真） |
| `src/places.js` `src/facade.js` | 詳細エリアの描画、外壁テクスチャ |
| `src/stations_detail.js` `src/st_*.js` | 作り込んだ駅（湘南台など） |
| `src/head.html` | HTML・CSS・HUD（先頭119行だけを使う） |
| `src/engine2_a.js` | ユーティリティ、Path（線路の向きと上下線オフセット）、データ読み込み、高さ関数、路線の定義 `LINES` |
| `src/blk_setup.js` | Three.js の初期化、マテリアル、当たり判定（OBB と多角形、20m グリッド） |
| `src/blk_city.js` | 藤沢市の境界と地区名 |
| `src/blk_land.js` | 名所の手作りモデル（江の島シーキャンドルなど。先頭71行だけを使う） |
| `src/engine2_b.js` | `build()` 全体の流れ、空・遠景・遠方の地形・海・線路 |
| `src/engine2_c.js` | ホーム、駅舎、地下駅、320m チャンク（地形・道路・建物・木）、学校の教室と体育館 |
| `src/engine2_d.js` | 道路の車、**時刻表エンジン**（種別と停車駅、待避、終点の番線割り当て、左側通行） |
| `src/blk_life.js` | サーファー、ヨット、トンビ、ラベル |
| `src/engine2_e.js` | プレイヤー、操作、乗車と降車、発車案内、時間帯、物理、地図、メインループ |
| `src/build.sh` | 上のファイルを連結して `index.html` を作る |
| `bake/` | OSM と国土地理院のデータから `fujisawa-data2` を作る Python（numpy, scipy, shapely など） |
| `tests/` | Playwright の自動テスト |

**改造の流れ:** `src/*.js` を編集 → `bash src/build.sh` → ブラウザで確認。

## 時刻表（src/engine2_d.js の buildTimetable）
- 実際のダイヤではなく、毎時の運行パターンです。`everyHour([発車する分...], t=>addRun(種別, 行先, 車両, [[路線, 始発, 終着, 停車駅一覧], ...], t, 最高速度m/s))`
- 停車駅:
  - ロマンスカー: 片瀬江ノ島・藤沢・大和・相模大野
  - 快速急行: 藤沢・湘南台・大和・中央林間・相模大野
  - 急行: 藤沢・湘南台・長後・大和・南林間・中央林間・相模大野
- 左側通行: 進行方向に対して左側の線路（`laneOff(s,-dir)`）を走ります。
- `resolveOvertakes()`: 後ろの電車が前の電車に追いつかないよう、停車時間を延ばして調整します。速い電車に追いつかれる遅い電車は、OSM の線路で待避線がある駅で待避します。

## データの作り直し（bake/）
`bake4.py` が最終版です。ほかのスクリプトはその前段階や旧版です。
元データは、OSM の API タイル、relation の full、国土地理院の DEM タイルと bvmap タイル（合計で約1GB）で、容量が大きいため含めていません。
作り直す場合は、OSM API と cyberjapandata.gsi.go.jp から改めてダウンロードする必要があります。
`ext/` のダウンロード処理は `dl_st.py` と `dl_aux.py` です。

## テスト
```bash
npm i playwright three@0.160.0
```

```bash
python3 tests/make_test.py
```

```bash
node tests/tt.js tests/q2.js
```

- `q2.js`: 全駅の上り・下りで乗車→降車→再乗車を確認
- `q7.js`: 発車案内と停車駅を確認
- `q8.js`: 電車同士の重なりを確認

## 既知の制限
- 電車の重なりは全時間帯でほぼ0です（21:30ごろ小田急藤沢で約12秒だけ重なる箇所が1つ残っています）。
- 時刻表は毎時パターンで作った近似です。
- 相鉄横浜駅など一部の駅では、OSM の線路位置とホームの位置がずれています。
