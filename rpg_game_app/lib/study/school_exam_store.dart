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

  /// 学校専用の定期テスト対策を開いたか（試験対策で学校名とパスワードを入れる）
  static const gateKey = 'school_gate_shonan_v1';
  static const _gateCheckedKey = 'school_gate_checked_v1';

  /// この更新より前からアプリを使っていた端末では、合言葉なしで開いたままにする。
  /// 起動して最初に（ほかの保存より前に）呼ぶ。保存が1つでもあれば、前から使っていた端末
  static Future<void> migrate(SharedPreferences prefs) async {
    if (prefs.containsKey(_gateCheckedKey)) return;
    final usedBefore = prefs.getKeys().isNotEmpty;
    await prefs.setBool(_gateCheckedKey, true);
    if (usedBefore) await prefs.setBool(gateKey, true);
  }

  bool get unlocked => _prefs.getBool(gateKey) ?? false;

  /// 学校名とパスワードで開く。ちがえば false
  Future<bool> unlock(String school, String password) async {
    if (!SchoolGate.matches(school, password)) return false;
    await _prefs.setBool(gateKey, true);
    await saveSecret(password);
    return true;
  }

  /// 鍵のかかった資料を開くためのパスワード（この端末の中だけに覚える）
  static const _secretKey = 'school_gate_secret_v1';

  String? get secret => _prefs.getString(_secretKey);

  Future<void> saveSecret(String password) =>
      _prefs.setString(_secretKey, SchoolGate.normalize(password));

  SchoolExamPlan? byId(String id) {
    for (final p in load()) {
      if (p.id == id) return p;
    }
    return null;
  }
}
