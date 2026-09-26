import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg_game/rpg_game.dart';

import '../data/prefs_progress_repository.dart';
import '../study/personal_books.dart';

/// 画面から使うサービスの入れ物。
class RpgServices extends InheritedWidget {
  RpgServices({
    super.key,
    required this.repository,
    required this.personalBooks,
    required super.child,
  }) : questions = JsonQuestionSource(_loadAsset),
       unlock = WorldUnlockService(
         repository: repository,
         // 購入ダイアログの動作確認用。リリース版では準備中ワールドは売らない。
         allowComingSoonPurchase: kDebugMode,
       );

  final PrefsProgressRepository repository;

  /// パスワード保護の個人用単語帳（LEAP など）
  final PersonalBooks personalBooks;
  final QuestionSource questions;
  final WorldUnlockService unlock;

  /// ステージの出題範囲をまとめて読み込む（エリア16以降は複数セット）。
  /// 1つも読めなければ null。
  Future<QuestionSet?> loadStagePool(StageDef stage) async {
    final sets = <QuestionSet>[];
    for (final id in stage.questionSetIds) {
      final s = await questions.load(id);
      if (s != null) sets.add(s);
    }
    if (sets.isEmpty) return null;
    return sets.length == 1 ? sets.first : QuestionSet.merge(stage.id, sets);
  }

  static RpgServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RpgServices>()!;

  static Future<String?> _loadAsset(String setId) async {
    final world = setId.split('_').first;
    try {
      return await rootBundle.loadString(
        'packages/rpg_game/assets/questions/$world/$setId.json',
      );
    } on FlutterError {
      return null;
    }
  }

  @override
  bool updateShouldNotify(RpgServices oldWidget) =>
      repository != oldWidget.repository;
}
