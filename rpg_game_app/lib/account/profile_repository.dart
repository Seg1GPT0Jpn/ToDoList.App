import 'dart:async';
import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// プロフィールを端末内に保存する。
///
/// Firebase につながっているときは、保存のたびに [onSaved] で
/// Firestore（users/{uid}/rpg_profile/main）にも書き込む（`CloudSync`）。
class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _key = 'rpg_profile_v1';
  final SharedPreferences _prefs;
  final _controller = StreamController<PlayerProfile>.broadcast();

  /// 保存したあとに呼ばれる（クラウドへの書き込み用）
  Future<void> Function(PlayerProfile profile)? onSaved;

  PlayerProfile load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return PlayerProfile.empty;
    try {
      return PlayerProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return PlayerProfile.empty;
    }
  }

  Stream<PlayerProfile> watch() async* {
    yield load();
    yield* _controller.stream;
  }

  Future<void> save(PlayerProfile profile) async {
    await replaceLocal(profile);
    await onSaved?.call(profile);
  }

  /// 端末内だけを書きかえる（クラウドから読み込んだときに使う）
  Future<void> replaceLocal(PlayerProfile profile) async {
    await _prefs.setString(_key, jsonEncode(profile.toMap()));
    _controller.add(profile);
  }
}
