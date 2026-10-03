// フィールドの地図を PNG に書き出す（見た目の確認用）。
// MAP_OUT=… MAP_WORLD=japanese flutter test test/tools/map_shot_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/field/field_game.dart';
import 'package:rpg_game_app/field/field_map.dart';

void main() {
  final out = Platform.environment['MAP_OUT'];
  final world = Platform.environment['MAP_WORLD'] ?? 'english';
  testWidgets('map shot', (t) async {
    if (out == null) return;
    await t.runAsync(() async {
      final id = Platform.environment['MAP_ID'];
      final map = FieldMap.byId(id ?? FieldMap.firstMapOf(world));
      final layer = MapLayer(map, worldId: world);
      await layer.onLoad();
      final rec = ui.PictureRecorder();
      final c = ui.Canvas(rec);
      layer.render(c);
      final w = (map.width * tileSize).toInt();
      final h = (map.height * tileSize).toInt().clamp(0, 6000);
      final img = await rec.endRecording().toImage(w, h);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
