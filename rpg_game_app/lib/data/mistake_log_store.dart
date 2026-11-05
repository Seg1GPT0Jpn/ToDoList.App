import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// まちがいの種類（うっかり・知らなかった など）を、端末に保存する。
class MistakeLogStore extends ChangeNotifier {
  MistakeLogStore(this._prefs) : _log = _read(_prefs);

  static const _key = 'rpg_mistake_log_v1';
  final SharedPreferences _prefs;
  MistakeLog _log;

  MistakeLog get log => _log;

  static MistakeLog _read(SharedPreferences p) {
    final raw = p.getString(_key);
    if (raw == null) return MistakeLog.empty;
    try {
      return MistakeLog.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return MistakeLog.empty;
    }
  }

  /// 1つ記録する（[subject] はワールド ID）
  Future<void> add(String subject, MistakeKind kind, {required int day}) async {
    _log = _log.add(subject, kind, day: day);
    await _prefs.setString(_key, jsonEncode(_log.toMap()));
    notifyListeners();
  }
}
