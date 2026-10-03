import '../models/stage.dart';
import 'route_world.dart';
import '../models/world.dart';
import 'english_catalog.dart';
import 'japanese_catalog.dart';
import 'math_catalog.dart';
import 'science_catalog.dart';
import 'social_catalog.dart';

/// ワールド・ステージのマスターデータ（小中学生版）。
///
/// 5教科とも「教科 → 学年のルート → エリア」のルート制ワールド。
/// 中身は tool/junior/gen.py が生成する <教科>_catalog.dart にある。
class RpgCatalog {
  const RpgCatalog._();

  static const englishWorldId = EnglishCatalog.worldId;

  /// 教科ワールドの予定価格（買い切り・円）。ランダム要素は持たない。
  static const defaultWorldPriceYen = 250;

  /// 英語の国のステージ（強さの曲線などで使う）
  static List<StageDef> get englishStages => EnglishCatalog.stages;

  static WorldDef _world({
    required String id,
    required String name,
    required String subject,
    required List<StageDef> stages,
    required List<RouteInfo> routes,
    required String hubName,
    required String hubSign,
    required String description,
    bool isFree = false,
  }) =>
      WorldDef(
        id: id,
        name: name,
        subject: subject,
        // 問題をまだ用意していない教科は準備中（購入もできない）
        status: stages.isEmpty ? WorldStatus.comingSoon : WorldStatus.available,
        isFree: isFree,
        priceYen: isFree ? null : defaultWorldPriceYen,
        stages: stages,
        routes: routes,
        hubName: hubName,
        hubSign: hubSign,
        description: description,
      );

  static final worlds = <WorldDef>[
    _world(
      id: EnglishCatalog.worldId,
      name: EnglishCatalog.name,
      subject: EnglishCatalog.subject,
      stages: EnglishCatalog.stages,
      routes: [for (final r in EnglishCatalog.routes) r.info],
      hubName: EnglishCatalog.hubName,
      hubSign: EnglishCatalog.hubSign,
      description: EnglishCatalog.description,
      isFree: true,
    ),
    _world(
      id: MathCatalog.worldId,
      name: MathCatalog.name,
      subject: MathCatalog.subject,
      stages: MathCatalog.stages,
      routes: [for (final r in MathCatalog.routes) r.info],
      hubName: MathCatalog.hubName,
      hubSign: MathCatalog.hubSign,
      description: MathCatalog.description,
    ),
    _world(
      id: JapaneseCatalog.worldId,
      name: JapaneseCatalog.name,
      subject: JapaneseCatalog.subject,
      stages: JapaneseCatalog.stages,
      routes: [for (final r in JapaneseCatalog.routes) r.info],
      hubName: JapaneseCatalog.hubName,
      hubSign: JapaneseCatalog.hubSign,
      description: JapaneseCatalog.description,
    ),
    _world(
      id: ScienceCatalog.worldId,
      name: ScienceCatalog.name,
      subject: ScienceCatalog.subject,
      stages: ScienceCatalog.stages,
      routes: [for (final r in ScienceCatalog.routes) r.info],
      hubName: ScienceCatalog.hubName,
      hubSign: ScienceCatalog.hubSign,
      description: ScienceCatalog.description,
    ),
    _world(
      id: SocialCatalog.worldId,
      name: SocialCatalog.name,
      subject: SocialCatalog.subject,
      stages: SocialCatalog.stages,
      routes: [for (final r in SocialCatalog.routes) r.info],
      hubName: SocialCatalog.hubName,
      hubSign: SocialCatalog.hubSign,
      description: SocialCatalog.description,
    ),
  ];

  static WorldDef world(String id) => worlds.firstWhere(
        (w) => w.id == id,
        orElse: () => throw ArgumentError('不明なワールドです: $id'),
      );

  /// 画面に出すステージの名前（例：小3・エリア3）
  static String stageLabel(StageDef s) => s.branch.isEmpty
      ? 'エリア${s.order}'
      : '${world(s.worldId).route(s.branch)?.name ?? s.branch}・エリア${s.areaNo}';

  /// 画面に出す出題範囲
  static String themeLabel(StageDef s) =>
      '単元：${s.grammarTheme}（${s.vocabLevel}）';

  static StageDef stage(String id) =>
      worlds.expand((w) => w.stages).firstWhere((s) => s.id == id,
          orElse: () => throw ArgumentError('不明なステージです: $id'));
}
