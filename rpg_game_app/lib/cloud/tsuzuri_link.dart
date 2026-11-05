import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// つづり（学校生活アプリ）の Firebase とのやりとり
abstract class TsuzuriBackend {
  /// 前につないだアカウントが残っていれば、そのメールアドレス
  Future<String?> restore();

  /// Google でログインしてつなぐ（やめたときは null）
  Future<String?> connect();

  Future<void> disconnect();

  /// つづりが書いた「これからのテスト」の文書
  Future<Map<String, dynamic>?> readUpcoming();

  /// 勉強記録を書く（data['date'] はその日の 0:00）
  Future<void> writeSession(String id, Map<String, Object?> data);

  Future<void> deleteSession(String id);

  /// クエストの成果を書く
  Future<void> writeResults(Map<String, dynamic> data);

  /// つづりの目標（goals の文書）
  Future<List<Map<String, dynamic>>> readGoals();
}

/// つづりとの連携：つながっているか・テスト予定・最後に同期した時刻。
///
/// テスト予定はこの端末にも残すので、電波がなくても表示できる。
class TsuzuriLinkController extends ChangeNotifier {
  TsuzuriLinkController(
    this._backend,
    this._prefs, {
    required this.log,
    required this.record,
    this.syncDelay = const Duration(seconds: 5),
  }) {
    _readCache();
  }

  final TsuzuriBackend _backend;
  final SharedPreferences _prefs;

  /// 送る勉強時間と、学習記録（苦手な単元を出すため）
  final StudyLog Function() log;
  final LearningRecord Function() record;

  /// 練習のあと、まとめて送るまでの待ち時間
  final Duration syncDelay;

  static const _upcomingKey = 'tsuzuri_upcoming_v1';
  static const _goalsKey = 'tsuzuri_goals_v1';
  static const _prepKey = 'tsuzuri_prep_v1';
  static const _sentKey = 'tsuzuri_sent_v1';
  static const _syncedKey = 'tsuzuri_synced_at';

  String? _email;
  List<TsuzuriUpcoming> _upcoming = const [];
  Map<String, List<TsuzuriLesson>> _lessons = const {};
  List<TsuzuriGoal> _goals = const [];
  bool _busy = false;
  String? _error;
  Timer? _timer;
  bool _started = false;

  /// つないでいる Google アカウント（つないでいなければ null）
  String? get email => _email;
  bool get connected => _email != null;
  bool get busy => _busy;

  /// 最後の同期でうまくいかなかったこと
  String? get error => _error;

  /// これからのテスト（今日より前は除く）
  List<TsuzuriUpcoming> get upcoming {
    final today = DateTime.now();
    return [
      for (final u in _upcoming)
        if (u.daysFrom(today) >= 0) u,
    ];
  }

  /// その日のつづりの時間割（つづりが新しい版でなければ空）
  List<TsuzuriLesson> lessonsOn(DateTime day) =>
      _lessons[StudyLog.dayKey(day)] ?? const [];

  /// つづりの目標（達成していないもの）
  List<TsuzuriGoal> get goals => _goals;

  /// そのテストのために、クエストで対策した時間（分）
  int prepMinutes(TsuzuriUpcoming t) =>
      (_readPrep()[TsuzuriLink.testKey(t)] ?? 0) ~/ 60;

  /// テスト対策をした時間を足す（つづりの「クエストで対策した時間」になる）
  Future<void> addPrep(TsuzuriUpcoming t, Duration spent) async {
    final secs = spent.inSeconds.clamp(0, StudyLog.maxSecondsPerSession);
    if (secs == 0) return;
    final prep = _readPrep();
    final key = TsuzuriLink.testKey(t);
    prep[key] = (prep[key] ?? 0) + secs.toInt();
    // 2週間より前のテストの記録は消す
    final oldest = StudyLog.dayKey(
      DateTime.now().subtract(const Duration(days: 14)),
    );
    prep.removeWhere((k, _) => k.compareTo(oldest) < 0);
    await _prefs.setString(_prepKey, jsonEncode(prep));
    notifyListeners();
    scheduleSync();
  }

  Map<String, int> _readPrep() {
    final raw = _prefs.getString(_prepKey);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          e.key as String: (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  DateTime? get syncedAt {
    final ms = _prefs.getInt(_syncedKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void _readCache() {
    try {
      final raw = _prefs.getString(_upcomingKey);
      if (raw != null) {
        final doc = jsonDecode(raw) as Map<String, dynamic>;
        _upcoming = TsuzuriLink.parseUpcoming(doc, today: DateTime.now());
        _lessons = TsuzuriLink.parseLessons(doc);
      }
      final goals = _prefs.getString(_goalsKey);
      if (goals != null) {
        _goals = TsuzuriLink.parseGoals([
          for (final g in jsonDecode(goals) as List)
            Map<String, dynamic>.from(g as Map),
        ]);
      }
    } catch (_) {
      _upcoming = const [];
      _lessons = const {};
      _goals = const [];
    }
  }

  /// 前回の接続を確かめて、つながっていれば同期する（1回だけ）
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _email = await _backend.restore();
    } catch (e) {
      debugPrint('つづりの接続を確かめられませんでした: $e');
    }
    notifyListeners();
    if (connected) await sync();
  }

  /// Google でログインしてつなぐ。つながったら true
  Future<bool> connect() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _email = await _backend.connect();
    } catch (e) {
      _error = connectErrorMessage(e);
    }
    _busy = false;
    notifyListeners();
    if (connected) await sync();
    return connected;
  }

  /// つなげなかったときの説明（よくある原因は、なおし方もいっしょに）
  static String connectErrorMessage(Object e) {
    final text = '$e';
    if (text.contains('unauthorized-domain')) {
      return 'つづりの Firebase の「承認済みドメイン」に tsuzuri-quest-v2.web.app が'
          '入っていないため、つなげませんでした（Firebase コンソール → Authentication → 設定）。';
    }
    if (text.contains('popup-blocked')) {
      return 'ログインの画面（ポップアップ）がブロックされました。ブラウザの設定でポップアップを許可してください。';
    }
    if (text.contains('popup-closed') || text.contains('cancelled')) {
      return 'ログインがとちゅうで閉じられました。もう一度ためしてください。';
    }
    if (text.contains('invalid-cert-hash') ||
        text.contains('app-not-authorized')) {
      return 'この Android アプリの署名が、つづりの Firebase に登録されていません'
          '（tools/connect_tsuzuri_android.ps1 を、このアプリを作ったPCで実行してください）。';
    }
    return 'つづりにつなげませんでした（$e）';
  }

  /// つなぐのをやめる（つづりに送った記録は消さない）
  Future<void> disconnect() async {
    _timer?.cancel();
    await _backend.disconnect();
    _email = null;
    _upcoming = const [];
    _lessons = const {};
    _goals = const [];
    await _prefs.remove(_upcomingKey);
    await _prefs.remove(_goalsKey);
    await _prefs.remove(_prepKey);
    await _prefs.remove(_sentKey);
    await _prefs.remove(_syncedKey);
    notifyListeners();
  }

  /// 練習のあとに呼ぶ（少し待ってからまとめて送る）
  void scheduleSync() {
    if (!connected) return;
    _timer?.cancel();
    _timer = Timer(syncDelay, () => unawaited(sync()));
  }

  /// テスト予定を受け取り、勉強時間と成果を送る
  Future<void> sync() async {
    if (!connected || _busy) return;
    _timer?.cancel();
    _busy = true;
    _error = null;
    notifyListeners();
    final now = DateTime.now();
    try {
      final doc = await _backend.readUpcoming();
      _upcoming = TsuzuriLink.parseUpcoming(doc, today: now);
      _lessons = TsuzuriLink.parseLessons(doc);
      await _prefs.setString(
        _upcomingKey,
        jsonEncode({
          'items': [for (final u in _upcoming) u.toMap()],
          'lessons': {
            for (final e in _lessons.entries)
              e.key: [for (final l in e.value) l.toMap()],
          },
        }),
      );
      _goals = TsuzuriLink.parseGoals(await _backend.readGoals());
      await _prefs.setString(
        _goalsKey,
        jsonEncode([for (final g in _goals) g.toMap()]),
      );

      // 勉強時間：変わったものだけ書き、なくなったものは消す
      final sessions = TsuzuriLink.sessions(log(), now: now);
      final sent = _readSent();
      for (final e in sessions.entries) {
        final minutes = e.value['minutes'] as int;
        if (sent[e.key] == minutes) continue;
        await _backend.writeSession(e.key, e.value);
        sent[e.key] = minutes;
      }
      final windowStart = TsuzuriLink.sessionId(
        DateTime(now.year, now.month, now.day - (TsuzuriLink.syncDays - 1)),
        '',
      );
      for (final id in TsuzuriLink.staleSessions(sent.keys, sessions)) {
        // さかのぼれる範囲より古いものは、そのまま残す
        if (id.compareTo(windowStart) >= 0) {
          await _backend.deleteSession(id);
        }
        sent.remove(id);
      }
      await _prefs.setString(_sentKey, jsonEncode(sent));

      await _backend.writeResults(
        TsuzuriLink.results(
          log(),
          record(),
          now: now,
          prepMinutes: {
            for (final e in _readPrep().entries) e.key: e.value ~/ 60,
          },
        ),
      );
      await _prefs.setInt(_syncedKey, now.millisecondsSinceEpoch);
    } catch (e) {
      _error = 'つづりと同期できませんでした（$e）';
      debugPrint(_error);
    }
    _busy = false;
    notifyListeners();
  }

  Map<String, int> _readSent() {
    final raw = _prefs.getString(_sentKey);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          e.key as String: (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// テスト用：メモリの中だけで動くつづり
class MemoryTsuzuriBackend implements TsuzuriBackend {
  MemoryTsuzuriBackend({this.account = 'student@example.com'});

  /// ログインに使うアカウント（null ならログインをやめた）
  String? account;
  String? _signedIn;
  Map<String, dynamic>? upcomingDoc;
  List<Map<String, dynamic>> goalDocs = [];
  final sessions = <String, Map<String, Object?>>{};
  Map<String, dynamic>? results;
  int writes = 0;

  @override
  Future<String?> restore() async => _signedIn;

  @override
  Future<String?> connect() async => _signedIn = account;

  @override
  Future<void> disconnect() async => _signedIn = null;

  @override
  Future<Map<String, dynamic>?> readUpcoming() async => upcomingDoc;

  @override
  Future<List<Map<String, dynamic>>> readGoals() async => goalDocs;

  @override
  Future<void> writeSession(String id, Map<String, Object?> data) async {
    writes++;
    sessions[id] = data;
  }

  @override
  Future<void> deleteSession(String id) async => sessions.remove(id);

  @override
  Future<void> writeResults(Map<String, dynamic> data) async => results = data;
}
