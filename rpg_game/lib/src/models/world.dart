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
  });

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
