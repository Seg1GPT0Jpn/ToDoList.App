// マップの絵を PNG に書き出す（見た目を確かめる道具）。ふだんは動かさない。
// MAP_OUT=<出力フォルダ> MAP_IDS=english,science_hub flutter test test/tool/render_map_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/field/field_game.dart';
import 'package:rpg_game_app/field/field_map.dart';

void main() {
  final out = Platform.environment['MAP_OUT'];
  testWidgets('マップを PNG に書き出す', (t) async {
    final ids = (Platform.environment['MAP_IDS'] ?? 'english').split(',');
    final rows = int.tryParse(Platform.environment['MAP_ROWS'] ?? '') ?? 0;
    final from = int.tryParse(Platform.environment['MAP_FROM'] ?? '') ?? 0;
    for (final id in ids) {
      final map = FieldMap.byId(id);
      final layer = MapLayer(map, worldId: id.split('_').first);
      await t.runAsync(() async {
        await layer.onLoad();
        final h = rows > 0 ? rows : map.height - from;
        final rec = ui.PictureRecorder();
        final c = ui.Canvas(rec);
        c.translate(0, -from * tileSize);
        layer.render(c);
        final img = await rec.endRecording().toImage(
          (map.width * tileSize).round(),
          (h * tileSize).round(),
        );
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$id.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  }, skip: out == null);
}
