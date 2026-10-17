import 'dart:async';
import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'personal_books.dart';

/// 学校の定期テスト対策（湘南高校104回生モード）の計画を、この端末の中に保存する。
///
/// 既存の試験対策ワールド（exam_worlds_v1）とは別のキーに置き、互いに読み書きしない。
/// 端末をまたいだ同期や、学年全体への配布はしない（この端末だけ）。
class SchoolExamStore {
  SchoolExamStore(this._prefs);

  factory SchoolExamStore.of(PersonalBooks books) =>
      _cache[books] ??= SchoolExamStore(books.prefs);
  static final _cache = Expando<SchoolExamStore>();

  static const key = 'shonan_exam_plans_v1';
  final SharedPreferences _prefs;
  final _controller = StreamController<List<SchoolExamPlan>>.broadcast();

  /// 保存したデータが壊れていても、読める計画だけを返す
  List<SchoolExamPlan> load() {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final m in list)
          if (m is Map) SchoolExamPlan.fromMap(Map<String, dynamic>.from(m)),
      ];
    } on FormatException {
      return const [];
    }
  }

  Stream<List<SchoolExamPlan>> watch() async* {
    yield load();
    yield* _controller.stream;
  }

  Future<void> _write(List<SchoolExamPlan> plans) async {
    await _prefs.setString(key, jsonEncode([for (final p in plans) p.toMap()]));
    _controller.add(plans);
  }

  Future<void> add(SchoolExamPlan plan) => _write([plan, ...load()]);

  Future<void> update(SchoolExamPlan plan) =>
      _write([for (final p in load()) p.id == plan.id ? plan : p]);

  Future<void> remove(String id) => _write([
    for (final p in load())
      if (p.id != id) p,
  ]);

  SchoolExamPlan? byId(String id) {
    for (final p in load()) {
      if (p.id == id) return p;
    }
    return null;
  }
}
