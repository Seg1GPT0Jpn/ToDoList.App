export 'package:rpg_game/rpg_game.dart' show juniorEdition;

/// つづりクエストLight としてビルドしているか（`--dart-define=TSUZURI_LIGHT=true`）。
/// const なので、Light で使わない画面（冒険のマップなど）のプログラムはビルドに入らない
const bool lightEdition = bool.fromEnvironment('TSUZURI_LIGHT');
