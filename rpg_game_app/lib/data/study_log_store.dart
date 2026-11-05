import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日ごと・教科ごとの勉強時間と問題数を、端末に保存する。
///
/// つづりと連携しているときは、保存のたびに [onSaved] でつづりへ送る（`TsuzuriLinkController`）。
class StudyLogStore extends ChangeNotifier {
  StudyLogStore(this._prefs) : _log = _read(_prefs);

  static const _key = 'rpg_study_log_v1';
  final SharedPreferences _prefs;
  StudyLog _log;

  StudyLog get log => _log;

  /// 保存したとき
  VoidCallback? onSaved;

  static StudyLog _read(SharedPreferences p) {
    final raw = p.getString(_key);
    if (raw == null) return StudyLog.empty;
    try {
      return StudyLog.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return StudyLog.empty;
    }
  }

  /// 1回ぶんの練習を足す（[subject] はワールド ID）
  Future<void> add(
    String subject, {
    required Duration spent,
    int answered = 0,
    int correct = 0,
    DateTime? now,
  }) async {
    final next = _log.add(
      subject,
      now: now ?? DateTime.now(),
      spent: spent,
      answered: answered,
      correct: correct,
    );
    if (identical(next, _log)) return;
    _log = next;
    await _prefs.setString(_key, jsonEncode(_log.toMap()));
    notifyListeners();
    onSaved?.call();
  }
}
