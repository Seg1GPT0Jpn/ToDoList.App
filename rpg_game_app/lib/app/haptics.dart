import 'package:flutter/services.dart';

import 'settings.dart';

/// 手ざわり（振動）。設定で切れる。対応していない端末（ウェブなど）では何もしない
class Haptics {
  const Haptics(this._settings);

  final SettingsStore _settings;

  bool get _on => _settings.value.vibration;

  /// 選んだ・押した
  void tap() {
    if (_on) HapticFeedback.selectionClick();
  }

  /// 正解・攻撃が当たった
  void hit() {
    if (_on) HapticFeedback.lightImpact();
  }

  /// 会心・必殺技・弱点
  void strong() {
    if (_on) HapticFeedback.mediumImpact();
  }

  /// ダメージを受けた・敵をたおした
  void heavy() {
    if (_on) HapticFeedback.heavyImpact();
  }
}
