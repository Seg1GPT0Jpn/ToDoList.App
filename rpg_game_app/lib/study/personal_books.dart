import 'package:shared_preferences/shared_preferences.dart';

/// パスワードで保護する個人用単語帳（LEAP など）。
///
/// 単語データはアプリや GitHub には含めず、利用者が貼り付けたものを
/// この端末の中（SharedPreferences）にだけ保存する。
/// school_planner へ移植するときは、既存の copyright_gate.dart の仕組みに合わせる。
class PersonalBooks {
  PersonalBooks(this._prefs);

  final SharedPreferences _prefs;

  /// TODO(leap-gate): 仮のパスワード。アプリ内に書かれた合言葉なので強い保護ではない。
  /// school_planner の copyright_gate.dart と同じ方式に差し替えること。
  static const leapPassword = 'LEAP';

  static const _unlockedKey = 'leap_unlocked';
  static const _leapTextKey = 'personal_book_leap';

  bool get leapUnlocked => _prefs.getBool(_unlockedKey) ?? false;

  bool tryUnlock(String input) {
    final ok = input.trim().toUpperCase() == leapPassword;
    if (ok) _prefs.setBool(_unlockedKey, true);
    return ok;
  }

  Future<void> lock() => _prefs.remove(_unlockedKey);

  String? get leapText => _prefs.getString(_leapTextKey);

  Future<void> saveLeapText(String text) =>
      _prefs.setString(_leapTextKey, text);

  Future<void> deleteLeapText() => _prefs.remove(_leapTextKey);
}
