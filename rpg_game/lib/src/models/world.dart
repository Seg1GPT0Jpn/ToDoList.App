import '../data/route_world.dart';
import 'stage.dart';

/// ワールドの公開状態。
enum WorldStatus {
  /// 遊べる（無料 or 購入済みで解放）
  available,

  /// まだ中身がない。マップ上に「準備中」と表示する
  comingSoon,
}

/// 教科ごとの「国」。
class WorldDef {
  const WorldDef({
    required this.id,
    required this.name,
    required this.subject,
    required this.status,
    required this.isFree,
    this.priceYen,
    this.stages = const [],
    this.description = '',
    this.routes = const [],
    this.hubName = '',
    this.hubSign = '',
  });

  /// ルート（2つ以上ならスタート地点のハブから分かれる。1つなら1本道）
  final List<RouteInfo> routes;

  /// ハブの名前と看板の文
  final String hubName;
  final String hubSign;

  RouteInfo? route(String id) => routes.where((r) => r.id == id).firstOrNull;

  final String id;
  final String name;

  /// 教科名（国語・数学・英語…）
  final String subject;
  final WorldStatus status;

  /// 無料で最初から遊べるか。false の場合は買い切りで解放する。
  final bool isFree;

  /// 買い切り価格（円）。ガチャ等のランダム要素は持たない。
  final int? priceYen;
  final List<StageDef> stages;
  final String description;

  bool get isComingSoon => status == WorldStatus.comingSoon;
}
