import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'classroom_backend.dart';

/// この端末で入っているクラスルームと、自分の分の記録。
///
/// - 入っているクラスのコード（別の端末では、コードを入れなおすと戻る）
/// - 共闘ボスに自分が与えた正解数（ほかの人には見えない。サーバーには合計だけ）
/// - 送れなかった正解数（通信できないときにためておき、次に送る）
class ClassroomStore {
  ClassroomStore(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'classrooms_v1';

  Map<String, dynamic> _read() {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return {};
      final m = jsonDecode(raw);
      return m is Map<String, dynamic> ? m : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> m) =>
      _prefs.setString(key, jsonEncode(m));

  /// 入っているクラスのコード（新しく入った順）
  List<String> get codes => [
    for (final c in (_read()['codes'] as List?) ?? const [])
      if (c is String) c,
  ];

  Future<void> add(String code) async {
    final m = _read();
    m['codes'] = [code, ...codes.where((c) => c != code)];
    await _write(m);
  }

  Future<void> forget(String code) async {
    final m = _read();
    m['codes'] = codes.where((c) => c != code).toList();
    (m['mine'] as Map?)?.remove(code);
    (m['pending'] as Map?)?.remove(code);
    await _write(m);
  }

  /// コードを作り直したとき、記録を新しいコードへ移す
  Future<void> rename(String from, String to) async {
    final m = _read();
    m['codes'] = [for (final c in codes) c == from ? to : c];
    for (final k in ['mine', 'pending']) {
      final map = m[k];
      if (map is Map && map.containsKey(from)) map[to] = map.remove(from);
    }
    await _write(m);
  }

  /// クラスで使うニックネーム（前に使ったもの）
  String get nickname => (_read()['nickname'] as String?) ?? '';
  Future<void> setNickname(String name) async {
    final m = _read()..['nickname'] = name;
    await _write(m);
  }

  int _get(String bucket, String code, String taskId) {
    final b = _read()[bucket];
    if (b is! Map) return 0;
    final c = b[code];
    if (c is! Map) return 0;
    return (c[taskId] as num?)?.toInt() ?? 0;
  }

  Future<void> _add(String bucket, String code, String taskId, int n) async {
    final m = _read();
    final b = (m[bucket] as Map?)?.cast<String, dynamic>() ?? {};
    final c = (b[code] as Map?)?.cast<String, dynamic>() ?? {};
    final v = ((c[taskId] as num?)?.toInt() ?? 0) + n;
    if (v <= 0) {
      c.remove(taskId);
    } else {
      c[taskId] = v;
    }
    b[code] = c;
    m[bucket] = b;
    await _write(m);
  }

  /// 自分が共闘ボスに与えた正解数
  int mine(String code, String taskId) => _get('mine', code, taskId);

  /// 共闘ボスに正解数を送る。送れなければためておく（次の [flush] で送る）
  Future<void> contribute(
    ClassroomBackend backend,
    String code,
    String taskId,
    int amount,
  ) async {
    if (amount <= 0) return;
    await _add('mine', code, taskId, amount);
    await _add('pending', code, taskId, amount);
    await flush(backend, code);
  }

  /// ためておいた正解数を送る
  Future<void> flush(ClassroomBackend backend, String code) async {
    final b = _read()['pending'];
    if (b is! Map) return;
    final c = b[code];
    if (c is! Map) return;
    for (final e in Map<String, dynamic>.from(c).entries) {
      final n = (e.value as num?)?.toInt() ?? 0;
      if (n <= 0) continue;
      try {
        await backend.hit(code, e.key, n);
        await _add('pending', code, e.key, -n);
      } on ClassroomException {
        return;
      }
    }
  }

  /// まだ送れていない正解数
  int pending(String code, String taskId) => _get('pending', code, taskId);
}
