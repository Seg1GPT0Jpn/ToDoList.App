import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services.dart';

/// 回数の送り先（Firebase がなければ null）
abstract class UsageSink {
  /// [day]（YYYY-MM-DD）の [feature] を1つ増やす
  Future<void> count(String day, String feature);
}

/// どの機能が使われているかを数える。
///
/// 送るのは「その日にその機能を開いた端末の数」を1つ増やすことだけ。
/// 名前・ID・学習の中身は送らない。1つの端末から、1つの機能につき1日1回まで。
/// 設定の「使った機能の回数を送る」で止められる。
class UsageMeter {
  UsageMeter(this._prefs, this._sink, this._enabled);

  final SharedPreferences _prefs;
  final UsageSink? _sink;
  final bool Function() _enabled;

  static const _key = 'usage_sent_v1';

  /// 数える機能（firestore.rules と同じ並び）
  static const features = {
    'app',
    'battle',
    'vocab',
    'vocab_study',
    'exam_sea',
    'word_forest',
    'versus',
    'classroom',
    'duel',
    'weak_cards',
  };

  /// 画面を開いたときに呼ぶ
  static void mark(BuildContext context, String feature) {
    context.getInheritedWidgetOfExactType<RpgServices>()?.usage.open(feature);
  }

  Future<void> open(String feature, {DateTime? now}) async {
    final sink = _sink;
    if (sink == null || !features.contains(feature) || !_enabled()) return;
    final day = BookProgress.dayKey(now ?? DateTime.now());
    Map<String, dynamic> m;
    try {
      m = jsonDecode(_prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      m = {};
    }
    final sent = m['d'] == day
        ? {...(m['f'] as List? ?? const [])}
        : <Object?>{};
    if (sent.contains(feature)) return;
    sent.add(feature);
    await _prefs.setString(_key, jsonEncode({'d': day, 'f': sent.toList()}));
    try {
      await sink.count(day, feature);
    } catch (_) {
      // 送れなくても何もしない（数はおおよそでよい）
    }
  }
}
