import '../data/route_world.dart';
import '../models/question.dart';
import '../models/stage.dart';

part 'eiken_lists.g.dart';
part 'eiken_routes.g.dart';

/// 英検の単語帳の1冊（assets/words/<id>.json）
class EikenList {
  const EikenList({
    required this.id,
    required this.title,
    required this.route,
    required this.count,
    required this.first,
    required this.last,
  });

  final String id;
  final String title;

  /// 級（p2 準2級・g2 2級・p1 準1級・g1 1級）
  final String route;
  final int count;
  final String first;
  final String last;

  String get file => 'assets/words/$id.json';
  String get description => '$count語（$first 〜 $last）';
}

/// 英検（準2級〜1級）の単語帳と、追加コンテンツ「英検の世界」。
///
/// 見出し語は使用頻度の帯から選んだ実在の語。意味・例文はつづ単と自作（tool/eiken/build.py）。
class Eiken {
  const Eiken._();

  static const worldId = 'eiken';

  /// 級（ルート）の順と名前
  static const levels = {'p2': '準2級', 'g2': '2級', 'p1': '準1級', 'g1': '1級'};

  static List<EikenList> get lists => _lists;

  static List<EikenList> ofLevel(String route) => [
        for (final l in _lists)
          if (l.route == route) l,
      ];

  static int wordCount(String route) =>
      ofLevel(route).fold(0, (a, l) => a + l.count);

  static const routes = _routes;

  static final stages = <StageDef>[
    ...RouteWorldBuilder.build(worldId, routes),
  ];
}
