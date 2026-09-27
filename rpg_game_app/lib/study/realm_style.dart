import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

/// 定期テストの海・模擬試験の空の色
extension RealmStyle on StudyRealm {
  /// 文字・ボタンの色
  Color get ink => switch (this) {
    StudyRealm.sea => const Color(0xFF2F5D7C),
    StudyRealm.sky => const Color(0xFF3949AB),
  };

  /// 見出しの背景の色
  Color get paper => switch (this) {
    StudyRealm.sea => const Color(0xFFE6F0F5),
    StudyRealm.sky => const Color(0xFFE8EAF6),
  };

  /// アイコン
  IconData get icon => switch (this) {
    StudyRealm.sea => Icons.sailing,
    StudyRealm.sky => Icons.rocket_launch,
  };

  /// 試験対策ワールドの呼び名
  String get worldLabel => switch (this) {
    StudyRealm.sea => '試験対策ワールド',
    StudyRealm.sky => '模試対策ワールド',
  };
}
