import 'dart:async';
import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 作った試験対策ワールドを端末の中に保存する
class ExamWorldStore {
  ExamWorldStore(this._prefs);

  static const _key = 'exam_worlds_v1';
  final SharedPreferences _prefs;
  final _controller = StreamController<List<ExamWorldPlan>>.broadcast();

  List<ExamWorldPlan> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final m in jsonDecode(raw) as List)
          ExamWorldPlan.fromMap(Map<String, dynamic>.from(m as Map)),
      ];
    } on FormatException {
      return const [];
    }
  }

  Stream<List<ExamWorldPlan>> watch() async* {
    yield load();
    yield* _controller.stream;
  }

  Future<void> _write(List<ExamWorldPlan> plans) async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final p in plans) p.toMap()]),
    );
    _controller.add(plans);
  }

  Future<void> add(ExamWorldPlan plan) => _write([plan, ...load()]);

  Future<void> update(ExamWorldPlan plan) =>
      _write([for (final p in load()) p.id == plan.id ? plan : p]);

  Future<void> remove(String id) => _write([
    for (final p in load())
      if (p.id != id) p,
  ]);

  ExamWorldPlan? byId(String id) {
    for (final p in load()) {
      if (p.id == id) return p;
    }
    return null;
  }
}
