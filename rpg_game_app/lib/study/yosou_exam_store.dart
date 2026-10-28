import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/asset_path.dart';
import 'personal_books.dart';

/// 予想問題の受験中の答えと、これまでの結果を、この端末に保存する
class YosouExamStore {
  YosouExamStore(this._prefs);

  factory YosouExamStore.of(PersonalBooks books) =>
      _cache[books] ??= YosouExamStore(books.prefs);
  static final _cache = Expando<YosouExamStore>();

  static const attemptsKey = 'yosou_attempts_v1';
  static const historyKey = 'yosou_history_v1';
  final SharedPreferences _prefs;

  Map<String, dynamic> _read(String key) {
    try {
      final m = jsonDecode(_prefs.getString(key) ?? '{}');
      return m is Map ? Map<String, dynamic>.from(m) : {};
    } on FormatException {
      return {};
    }
  }

  /// 受験中・採点中の回（なければ null）
  MockAttempt? attempt(String examId) {
    final m = _read(attemptsKey)[examId];
    if (m is! Map) return null;
    try {
      return MockAttempt.fromMap(Map<String, dynamic>.from(m));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(MockAttempt a) {
    final all = _read(attemptsKey)..[a.examId] = a.toMap();
    return _prefs.setString(attemptsKey, jsonEncode(all));
  }

  Future<void> clear(String examId) {
    final all = _read(attemptsKey)..remove(examId);
    return _prefs.setString(attemptsKey, jsonEncode(all));
  }

  /// 解いている途中の答えと、これまでの結果を消す
  Future<void> reset(String examId) async {
    await clear(examId);
    final all = _read(historyKey)..remove(examId);
    await _prefs.setString(historyKey, jsonEncode(all));
  }

  /// すべての予想問題の答えと結果を消す
  Future<void> resetAll() async {
    await _prefs.remove(attemptsKey);
    await _prefs.remove(historyKey);
  }

  /// 消せる記録があるか
  bool hasData(String examId) =>
      attempt(examId) != null || history(examId).isNotEmpty;

  /// これまでの結果（新しい順）
  List<YosouResult> history(String examId) {
    final list = _read(historyKey)[examId];
    if (list is! List) return const [];
    return [
      for (final m in list)
        if (m is Map) YosouResult.fromMap(Map<String, dynamic>.from(m)),
    ];
  }

  /// 結果を記録する（同じ回なら書きかえる。自分でつけた点が変わったとき）
  Future<void> record(String examId, YosouResult r) {
    final all = _read(historyKey);
    final list = [
      r,
      for (final x in history(examId))
        if (x.startedAt != r.startedAt) x,
    ];
    all[examId] = [for (final x in list.take(20)) x.toMap()];
    return _prefs.setString(historyKey, jsonEncode(all));
  }
}

class YosouResult {
  const YosouResult({
    required this.startedAt,
    required this.score,
    required this.total,
    required this.spent,
    this.unscored = 0,
  });

  final DateTime startedAt;
  final int score;
  final int total;
  final Duration spent;

  /// まだ自分で点をつけていない欄の数
  final int unscored;

  Map<String, Object> toMap() => {
    'start': startedAt.millisecondsSinceEpoch,
    'score': score,
    'total': total,
    'spent': spent.inSeconds,
    'unscored': unscored,
  };

  static YosouResult fromMap(Map<String, dynamic> m) => YosouResult(
    startedAt: DateTime.fromMillisecondsSinceEpoch((m['start'] as num).toInt()),
    score: (m['score'] as num).toInt(),
    total: (m['total'] as num).toInt(),
    spent: Duration(seconds: (m['spent'] as num? ?? 0).toInt()),
    unscored: (m['unscored'] as num? ?? 0).toInt(),
  );
}

/// 暗号化して同梱した予想問題（解答用紙・ページ画像）を開く
class YosouExamFiles {
  YosouExamFiles(this.exam, this.key);

  final YosouExam exam;
  final List<int> key;

  /// 同梱ファイルを読む（テストで差しかえる）
  static Future<List<int>> Function(String asset) loader = (asset) async =>
      (await rootBundle.load(appAsset(asset))).buffer.asUint8List();

  /// 解答用紙を開く（鍵がちがえば null）
  Future<MockSheet?> sheet() async {
    try {
      final bytes = SchoolMaterials.open(
        await loader(exam.sheetAsset),
        key: key,
      );
      if (bytes == null) return null;
      return MockSheet.fromJson(utf8.decode(bytes));
    } catch (_) {
      return null;
    }
  }

  /// 小問ごとの問題データを開く（ないとき・鍵がちがうときは null）
  Future<List<QuizQuestion>?> questions() => _questions ??= () async {
    if (!exam.smallQuestions) return null;
    try {
      final bytes = SchoolMaterials.open(
        await loader(exam.questionsAsset),
        key: key,
      );
      if (bytes == null) return null;
      final json = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(bytes)) as Map,
      );
      return QuestionSet.fromJson(json).questions;
    } catch (_) {
      return null;
    }
  }();
  Future<List<QuizQuestion>?>? _questions;

  final _pages = <int, Future<Uint8List?>>{};

  /// [page] ページ目（1から）の画像
  Future<Uint8List?> page(int page) => _pages[page] ??= () async {
    try {
      final bytes = SchoolMaterials.open(
        await loader(exam.asset(page)),
        key: key,
      );
      return bytes != null && SchoolMaterials.looksLikeImage(bytes)
          ? bytes
          : null;
    } catch (_) {
      return null;
    }
  }();
}
