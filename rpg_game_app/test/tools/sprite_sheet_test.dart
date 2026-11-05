// 敵のスプライトシートを PNG に書き出す（見た目の確認用）。
// SPRITE_OUT=… flutter test test/tools/sprite_sheet_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/art/enemy_painter.dart';

void main() {
  final out = Platform.environment['SPRITE_OUT'];
  final looks = (Platform.environment['SPRITE_LOOKS'] ?? '').split(',')
    ..removeWhere((e) => e.isEmpty);
  testWidgets('sprite sheet', (t) async {
    if (out == null || looks.isEmpty) return;
    await t.runAsync(() async {
      const cell = 160.0;
      const cols = 7;
      final rows = (looks.length / cols).ceil();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(
        const Rect.fromLTWH(0, 0, cell * cols, 2000),
        Paint()..color = const Color(0xFFFAF6EE),
      );
      for (var i = 0; i < looks.length; i++) {
        c.save();
        c.translate((i % cols) * cell, (i ~/ cols) * cell);
        c.drawRect(
          const Rect.fromLTWH(2, 2, cell - 4, cell - 4),
          Paint()
            ..color = const Color(0x22000000)
            ..style = PaintingStyle.stroke,
        );
        paintEnemy(c, cell, looks[i], 0.7);
        c.restore();
      }
      final img = await rec.endRecording().toImage(
        (cell * cols).toInt(),
        (cell * rows).toInt(),
      );
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
