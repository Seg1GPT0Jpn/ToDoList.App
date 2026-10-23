/// アプリに同梱したファイル（assets/…）の場所の前につける文字。
///
/// つづりクエストでは空。つづりクエストLight は、つづりクエストの同梱ファイルを
/// 部品として使うので 'packages/rpg_game_app/' を入れる。
String appAssetPrefix = '';

/// 同梱ファイルの場所（つづりクエスト・Light のどちらでも読めるように）
String appAsset(String path) => '$appAssetPrefix$path';
