# 3D フィールド（試作）の素材

## fox.glb
出典：Khronos glTF Sample Assets「Fox」
https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/Fox

- モデル：PixelMannen（CC0 1.0）
- リグ・アニメーション：tomkranis（CC BY 4.0）
- glTF への変換：@AsoboStudio・@scurest（CC BY 4.0）

CC BY 4.0 の素材なので、アプリの中（3D フィールドの「素材」表示）にもクレジットを出す。
https://creativecommons.org/licenses/by/4.0/

## そのほか
地面・木・岩・柵・NPC・スライムは、flutter_scene の基本図形（箱・円柱・球など）をコードで組み立てている（外部素材なし）。

## web/field3d/flutter_scene_rapier_native.wasm
flutter_scene_rapier 0.5.2 のリリースの WebAssembly（MIT。Rapier などの依存はそれぞれのライセンス）。
sha256: 907f7f4aa7de32bd3871f5ed9ebc638364ddc698c76206dcb99ef6d1c8b169b8（パッケージに書かれた値と一致を確認）
外部の配信サーバー（workers.dev）に頼らず、自分のサイトから読むために置いている。
