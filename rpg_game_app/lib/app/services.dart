import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/account_service.dart';
import '../account/profile_repository.dart';
import '../audio/music_director.dart';
import '../data/meta_store.dart';
import '../data/prefs_progress_repository.dart';
import '../study/exam_world_store.dart';
import '../study/personal_books.dart';
import 'settings.dart';

/// 画面から使うサービスの入れ物。
class RpgServices extends InheritedWidget {
  RpgServices({
    super.key,
    required this.repository,
    required this.personalBooks,
    required this.profiles,
    required this.account,
    required this.examWorlds,
    required this.meta,
    required this.settings,
    required this.music,
    required super.child,
  }) : questions = JsonQuestionSource(_loadAsset),
       unlock = WorldUnlockService(
         repository: repository,
         // 購入ダイアログの動作確認用。リリース版では準備中ワールドは売らない。
         allowComingSoonPurchase: kDebugMode,
         // 本物の決済がまだないので、公開版（リリースビルド）では購入ボタンで買えない。
         // 有料ワールドはプロモーションコードでだけ受け取れる。
         allowPurchase: kDebugMode,
       );

  final PrefsProgressRepository repository;

  /// ユーザー名と Google アカウント
  final ProfileRepository profiles;
  final AccountService account;

  /// 作った試験対策ワールド（端末の中に保存）
  final ExamWorldStore examWorlds;

  /// 学習記録と冒険の記録（図鑑・実績・クエスト）
  final MetaStore meta;

  /// 遊びやすさの設定（音・文字の大きさなど）
  final SettingsStore settings;

  /// BGM・効果音
  final MusicDirector music;

  /// パスワード保護の個人用単語帳（LEAP など）
  final PersonalBooks personalBooks;
  final JsonQuestionSource questions;
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

  /// デイリークエストで選ぶ教科（持っている、遊べるワールド）
  Map<String, String> questSubjects(RpgProgress progress) => {
    for (final w in RpgCatalog.worlds)
      if (unlock.availabilityOf(progress, w) == WorldAvailability.playable)
        w.id: w.subject,
  };

  /// 今日（学習記録の日付の数え方）
  static int today() => dayNumber(DateTime.now());

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
