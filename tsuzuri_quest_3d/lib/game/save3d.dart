import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'field3d.dart';

/// つづりクエスト3D のセーブデータ（この端末の中だけ）。
///
/// 2D 版（rpg_game_app）とは別のゲームなので、キーも別にしている。
/// Web で同じサイトに置いても、2D 版のデータ（rpg_progress_v1 など）とは混ざらない。
/// クラウド（Firestore）には送らない。
class Save3D {
  Save3D(this.prefs);

  final SharedPreferences prefs;

  static const progressKey = 'tq3d_progress_v1';

  /// 試作の草原だけだったころの保存（読むだけ。消さずに残す）
  static const fieldKey = 'tq3d_field_v1';

  /// 地域ごとの保存 {"v":2,"current":地域ID,"regions":{地域ID:状態}}
  static const fieldsKey = 'tq3d_field_v2';
  static const qualityKey = 'tq3d_quality_v1';
  static const benchKey = 'tq3d_bench_v1';
  static const learningKey = 'tq3d_learning_v1';

  /// 自動計測の結果をいくつ残すか
  static const benchKeep = 10;

  static Future<Save3D> open() async =>
      Save3D(await SharedPreferences.getInstance());

  /// レベル・経験値など（2D 版と同じ形式の RpgProgress を、別のキーに保存）
  RpgProgress loadProgress() {
    final raw = prefs.getString(progressKey);
    if (raw == null) return RpgProgress.initial;
    try {
      return RpgProgress.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return RpgProgress.initial;
    }
  }

  Future<void> saveProgress(RpgProgress p) =>
      prefs.setString(progressKey, jsonEncode(p.toMap()));

  Map<String, dynamic> _fields() {
    final raw = prefs.getString(fieldsKey);
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw);
      return m is Map<String, dynamic> ? m : {};
    } catch (_) {
      return {};
    }
  }

  /// 地域の状態。新しい形式になければ、古い形式（tq3d_field_v1）から引き継ぐ
  Field3DState loadField(Field3DRegion region) {
    final regions = _fields()['regions'];
    if (regions is Map && regions[region.id] is Map) {
      return Field3DState.decode(jsonEncode(regions[region.id]), region);
    }
    return Field3DState.decode(prefs.getString(fieldKey), region);
  }

  Future<void> saveField(Field3DState s) {
    final all = _fields();
    final regions = all['regions'] is Map
        ? Map<String, dynamic>.from(all['regions'] as Map)
        : <String, dynamic>{};
    regions[s.regionId] = s.toMap();
    return prefs.setString(
      fieldsKey,
      jsonEncode({'v': 2, 'current': s.regionId, 'regions': regions}),
    );
  }

  /// 最後に遊んだ地域（なければ null）
  String? get currentRegion {
    final c = _fields()['current'];
    if (c is String) return c;
    return prefs.containsKey(fieldKey) ? 'meadow_proto' : null;
  }

  /// 1問ごとの学習記録（間隔反復の箱・まちがえた回数など。2D 版と同じ形式を別のキーに）
  LearningRecord loadLearning() {
    final raw = prefs.getString(learningKey);
    if (raw == null) return LearningRecord.empty;
    try {
      return LearningRecord.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return LearningRecord.empty;
    }
  }

  Future<void> saveLearning(LearningRecord r) =>
      prefs.setString(learningKey, jsonEncode(r.toMap()));

  /// その地域の保存があるか
  bool hasRegion(String regionId) {
    final regions = _fields()['regions'];
    if (regions is Map && regions.containsKey(regionId)) return true;
    if (regionId != 'meadow_proto') return false;
    return prefs.containsKey(fieldKey);
  }

  bool get hasField =>
      prefs.containsKey(fieldKey) || prefs.containsKey(fieldsKey);

  String get quality => prefs.getString(qualityKey) ?? 'standard';
  Future<void> setQuality(String q) => prefs.setString(qualityKey, q);

  /// 自動計測の結果（新しい順。1 件は BenchReport.logLine の JSON 部分）
  List<String> get benchHistory => prefs.getStringList(benchKey) ?? const [];

  Future<void> addBench(String json) => prefs.setStringList(
    benchKey,
    [json, ...benchHistory].take(benchKeep).toList(),
  );

  /// 3D 版のデータだけを消す（2D 版のデータには触らない）
  Future<void> reset() async {
    await prefs.remove(progressKey);
    await prefs.remove(fieldKey);
    await prefs.remove(fieldsKey);
    await prefs.remove(learningKey);
  }
}
