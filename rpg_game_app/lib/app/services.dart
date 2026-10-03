import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/account_service.dart';
import '../account/profile_repository.dart';
import '../audio/music_director.dart';
import '../data/meta_store.dart';
import '../data/prefs_progress_repository.dart';
import '../purchase/google_play_purchase_service.dart';
import '../study/exam_world_store.dart';
import '../study/personal_books.dart';
import '../versus/online_room.dart';
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
    this.versusRooms,
    this.purchaseService,
    required super.child,
  }) : questions = JsonQuestionSource(loadQuestionAsset),
       unlock = WorldUnlockService(
         repository: repository,
         // 本物の Google Play Billing がある Android 版だけ購入ボタンを有効にする。
         allowComingSoonPurchase: false,
         allowPurchase: purchaseService?.isAvailable == true,
         purchase: purchaseService?.purchaseWorld,
         purchaseSource:
             purchaseService != null ? 'google_play' : 'mock',
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

  /// オンライン対戦の部屋（Firebase の設定がなければ null）
  final VersusRoomBackend? versusRooms;

  /// Google Play Billing。Web 版や Firebase 未設定版では null。
  final GooglePlayPurchaseService? purchaseService;

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
    // 英語のバトルには、エリアの語彙レベルに合ったつづ単の単語問題も混ぜる
    if (stage.worldId == RpgCatalog.englishWorldId) {
      final vocab = await _tsuzutanSets(stage);
      for (final v in vocab) {
        questions.adopt(v);
      }
      sets.addAll(vocab);
    }
    return sets.length == 1 ? sets.first : QuestionSet.merge(stage.id, sets);
  }

  /// つづ単（公開版）から、エリアに合うレベルの単語問題を少しだけ作る
  Future<List<QuestionSet>> _tsuzutanSets(StageDef stage) async {
    final levels = Tsuzutan.levelsForStage(stage.vocabLevel);
    final candidates = [
      for (final l in Tsuzutan.lists)
        if (levels.contains(l.level)) l.id,
    ]..shuffle();
    final lists = <WordList>[];
    for (final id in candidates.take(2)) {
      try {
        final raw = utf8.decode(
          (await rootBundle.load('packages/rpg_game/assets/words/$id.json'))
              .buffer
              .asUint8List(),
        );
        lists.add(WordList.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // 読めなければ単語問題なしで続ける
      }
    }
    return Tsuzutan.battleSets(lists, count: 10);
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

  /// 同梱の問題を読む。問題は教科ごとに1つのファイル
  /// （packages/rpg_game/assets/question_bundles/<教科>.json）にまとめてあり、
  /// 教科ごとに1回だけ読んで覚えておく。
  static Future<String?> loadQuestionAsset(String setId) async {
    final world = setId.split('_').first;
    final bundle = await (_bundles[world] ??= _loadBundle(world));
    // 読めなかったときは覚えず、次にもう一度読みにいく（通信の一時的な失敗など）
    if (bundle == null) _bundles.remove(world);
    final set = bundle?[setId];
    return set == null ? null : jsonEncode(set);
  }

  static final Map<String, Future<Map<String, dynamic>?>> _bundles = {};

  static Future<Map<String, dynamic>?> _loadBundle(String world) async {
    try {
      // loadString は大きなファイルを別の isolate で文字に直すので、
      // ここではバイト列を読んでその場で直す（1MB 未満なので一瞬）
      final data = await rootBundle.load(
        'packages/rpg_game/assets/question_bundles/$world.json',
      );
      final raw = utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FlutterError {
      return null;
    }
  }

  /// 読み込んだ教科のまとめファイルを忘れる（テスト用）
  @visibleForTesting
  static void clearQuestionBundles() => _bundles.clear();

  @override
  bool updateShouldNotify(RpgServices oldWidget) =>
      repository != oldWidget.repository ||
      purchaseService != oldWidget.purchaseService;
}
