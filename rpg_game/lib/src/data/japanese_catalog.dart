// このファイルは tool/junior/gen.py が問題データと同時に生成しています。
// 手で直さず tool/junior/<教科>.py を直してください。
import '../models/stage.dart';
import 'route_world.dart';

class JapaneseCatalog {
  const JapaneseCatalog._();

  static const worldId = 'japanese';
  static const name = '言の葉の国';
  static const subject = '国語';
  static const hubName = '';
  static const hubSign = '';
  static const description = '';

  static const routes = <RouteSpec>[
  ];

  static final List<StageDef> stages =
      RouteWorldBuilder.build(worldId, routes);
}
