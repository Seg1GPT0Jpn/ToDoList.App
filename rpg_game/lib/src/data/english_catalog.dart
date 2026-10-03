// このファイルは tool/junior/gen.py が問題データと同時に生成しています。
// 手で直さず tool/junior/<教科>.py を直してください。
import '../models/stage.dart';
import 'route_world.dart';

class EnglishCatalog {
  const EnglishCatalog._();

  static const worldId = 'english';
  static const name = '英語の国';
  static const subject = '英語';
  static const hubName = '';
  static const hubSign = '';
  static const description = '';

  static const routes = <RouteSpec>[];

  static final List<StageDef> stages = RouteWorldBuilder.build(worldId, routes);
}
