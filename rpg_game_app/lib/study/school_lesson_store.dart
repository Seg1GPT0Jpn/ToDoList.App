import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'personal_books.dart';

/// 定期テスト対策の授業の進み具合を、この端末の中に保存する。
///
/// テストの計画（[SchoolExamStore]）と同じく端末の中だけに置く。
/// 演習の正誤は既存の学習記録（MetaStore）に残るので、ここには授業と確認テストの結果だけを置く。
class SchoolLessonStore extends ChangeNotifier {
  SchoolLessonStore(this._prefs);

  factory SchoolLessonStore.of(PersonalBooks books) =>
      _cache[books] ??= SchoolLessonStore(books.prefs);
  static final _cache = Expando<SchoolLessonStore>();

  static const key = 'school_lessons_v1';
  final SharedPreferences _prefs;

  /// 授業 ID → 記録（壊れた保存データは読めた分だけ使う）
  Map<String, LessonRecord> load() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return {};
      return {
        for (final e in m.entries)
          if (e.value is Map)
            '${e.key}': LessonRecord.fromJson(
              Map<String, dynamic>.from(e.value as Map),
            ),
      };
    } on FormatException {
      return {};
    }
  }

  LessonRecord record(String lessonId) =>
      load()[lessonId] ?? LessonRecord(lessonId: lessonId);

  Future<void> save(LessonRecord r) async {
    final all = load()..[r.lessonId] = r;
    await _prefs.setString(
      key,
      jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}),
    );
    notifyListeners();
  }

  /// 同梱の授業（科目ごとの教材ファイル）を読む。テストで差しかえる
  static Future<String?> Function(String subjectId) loader = (subjectId) async {
    try {
      return await rootBundle.loadString(
        'packages/rpg_game/assets/lessons/$subjectId.json',
      );
    } catch (_) {
      return null;
    }
  };

  static final Map<String, List<SchoolLesson>> _lessons = {};

  /// 科目の授業（教材がなければ空）
  static Future<List<SchoolLesson>> lessonsFor(String subjectId) async {
    final cached = _lessons[subjectId];
    if (cached != null) return cached;
    final raw = await loader(subjectId);
    var list = const <SchoolLesson>[];
    if (raw != null) {
      try {
        list = SchoolLessons.parse(jsonDecode(raw) as List);
      } catch (_) {
        list = const [];
      }
    }
    return _lessons[subjectId] = list;
  }

  /// テストで教材を差しかえたあとに呼ぶ
  static void clearCache() => _lessons.clear();
}
