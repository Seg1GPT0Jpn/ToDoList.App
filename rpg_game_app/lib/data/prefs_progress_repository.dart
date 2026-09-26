import 'dart:async';
import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 端末内に進行状況を保存する（単体アプリ用）。
///
/// school_planner へ移植するときは Firestore 版
/// （users/{uid}/rpg_progress/main）に差し替える。
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository(this._prefs);

  static const _key = 'rpg_progress_v1';
  final SharedPreferences _prefs;
  final _controller = StreamController<RpgProgress>.broadcast();

  RpgProgress _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return RpgProgress.initial;
    try {
      return RpgProgress.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return RpgProgress.initial;
    }
  }

  @override
  Stream<RpgProgress> watch() async* {
    yield _read();
    yield* _controller.stream;
  }

  @override
  Future<RpgProgress> load() async => _read();

  @override
  Future<void> save(RpgProgress progress) async {
    await _prefs.setString(_key, jsonEncode(progress.toMap()));
    _controller.add(progress);
  }

  @override
  Future<void> markWorldPurchased(
    String worldId, {
    required String source,
  }) async {
    final p = _read();
    await save(
      p.copyWith(purchasedWorldIds: {...p.purchasedWorldIds, worldId}),
    );
  }

  Future<void> reset() async {
    await _prefs.remove(_key);
    _controller.add(RpgProgress.initial);
  }
}
