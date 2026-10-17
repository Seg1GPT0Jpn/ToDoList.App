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
  static const fieldKey = 'tq3d_field_v1';
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

  Field3DState loadField(Field3DRegion region) =>
      Field3DState.decode(prefs.getString(fieldKey), region);

  Future<void> saveField(Field3DState s) =>
      prefs.setString(fieldKey, s.encode());

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

  bool get hasField => prefs.containsKey(fieldKey);

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
    await prefs.remove(learningKey);
  }
}
