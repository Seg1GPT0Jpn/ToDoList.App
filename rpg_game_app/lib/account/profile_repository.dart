import 'dart:async';
import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// プロフィールを端末内に保存する（単体アプリ用）。
///
/// school_planner へ移植するときは Firestore の
/// users/{uid}/rpg_profile/main（`RpgFirestorePaths.profileDoc`）に差し替える。
class ProfileRepository {
  ProfileRepository(this._prefs);

  static const _key = 'rpg_profile_v1';
  final SharedPreferences _prefs;
  final _controller = StreamController<PlayerProfile>.broadcast();

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
    await _prefs.setString(_key, jsonEncode(profile.toMap()));
    _controller.add(profile);
  }
}
