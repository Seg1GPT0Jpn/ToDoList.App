import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ホームの機能のうち、もう開いたもの（まだなら「NEW」を出す）
class HomeFeatureStore extends ChangeNotifier {
  HomeFeatureStore(this._prefs);

  static const key = 'home_seen_features_v1';
  final SharedPreferences _prefs;

  Set<String>? get _seen => _prefs.getStringList(key)?.toSet();

  /// はじめて呼ばれたとき（この機能が入る前から遊んでいた人）は、
  /// いま出ている機能をすべて見たことにする
  void prepare(Iterable<HomeFeature> open) {
    if (_seen != null) return;
    _prefs.setStringList(key, [for (final f in open) f.name]);
  }

  bool isNew(HomeFeature f) => !(_seen ?? const {}).contains(f.name);

  Future<void> markSeen(HomeFeature f) async {
    final s = _seen ?? <String>{};
    if (!s.add(f.name)) return;
    await _prefs.setStringList(key, s.toList());
    notifyListeners();
  }
}
