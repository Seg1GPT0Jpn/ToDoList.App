import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'field_map.dart';
import 'terrain_art.dart';

/// 村や町を歩き回る住人。道はふさがない（主人公は通りぬけられる）。
/// 主人公が近づくと、ふきだしでひとこと話す。
class VillagerToken extends PositionComponent {
  VillagerToken({
    required this.home,
    required this.color,
    required this.tileSize,
    required this.canWalk,
    required this.seed,
  }) : cell = home,
       super(size: Vector2.all(tileSize)) {
    position = Vector2(home.col * tileSize, home.row * tileSize);
  }

  final Cell home;
  final int color;
  final double tileSize;

  /// 歩けるマスか（壁・敵・ほかの住人のいるマスは歩かない）
  final bool Function(Cell c) canWalk;
  final int seed;

  Cell cell;
  late final Random _rnd = Random(seed);
  double _t = 0;
  double _wait = 1;
  Vector2? _from;
  Vector2? _to;
  double _p = 0;

  /// ふきだしの言葉と、残りの時間
  String? _line;
  double _lineLeft = 0;

  /// もう一度話すまでの時間
  double cooldown = 0;

  bool get talking => _line != null;

  void say(String line) {
    _line = line;
    _lineLeft = 4.5;
    cooldown = 14;
  }

  @override
  void update(double dt) {
    _t += dt;
    priority = cell.row * 10 + 4;
    cooldown = max(0, cooldown - dt);
    if (_line != null) {
      _lineLeft -= dt;
      if (_lineLeft <= 0) _line = null;
    }
    final from = _from, to = _to;
    if (from != null && to != null) {
      _p = min(1, _p + dt / 0.45);
      position = from + (to - from) * _p;
      if (_p >= 1) {
        _from = null;
        _to = null;
      }
      return;
    }
    // 話しているあいだは立ち止まる
    if (talking) return;
    _wait -= dt;
    if (_wait > 0) return;
    _wait = 1.2 + _rnd.nextDouble() * 2.5;
    const dirs = [(0, 1), (0, -1), (1, 0), (-1, 0)];
    final (dc, dr) = dirs[_rnd.nextInt(4)];
    final next = (col: cell.col + dc, row: cell.row + dr);
    // 家から遠くへは行かない
    if ((next.col - home.col).abs() + (next.row - home.row).abs() > 3) return;
    if (!canWalk(next)) return;
    _from = position.clone();
    _to = Vector2(next.col * tileSize, next.row * tileSize);
    _p = 0;
    cell = next;
  }

  @override
  void render(ui.Canvas canvas) {
    final walking = _to != null;
    TerrainArt.npc(
      canvas,
      ui.Rect.fromLTWH(0, 0, tileSize, tileSize),
      color: color,
      bob: walking ? sin(_t * 14).abs() * 2 : (sin(_t * 2) + 1) * 0.6,
      bubble: false,
    );
    final line = _line;
    if (line == null) return;
    // ふきだし
    final b =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(textAlign: ui.TextAlign.left, maxLines: 4),
          )
          ..pushStyle(
            ui.TextStyle(
              color: const ui.Color(0xFF3E3A4A),
              fontSize: 9.5,
              height: 1.3,
            ),
          )
          ..addText(line);
    final p = b.build()..layout(const ui.ParagraphConstraints(width: 150));
    final w = p.longestLine + 14, h = p.height + 10;
    final box = ui.Rect.fromLTWH(tileSize / 2 - w / 2, -h - 8, w, h);
    final rr = ui.RRect.fromRectAndRadius(box, const ui.Radius.circular(8));
    canvas.drawRRect(
      rr.shift(const ui.Offset(1.5, 2)),
      ui.Paint()..color = const ui.Color(0x33000000),
    );
    canvas.drawRRect(rr, ui.Paint()..color = const ui.Color(0xFFFFFDF8));
    final tail = ui.Path()
      ..moveTo(tileSize / 2 - 5, box.bottom - 1)
      ..lineTo(tileSize / 2, box.bottom + 6)
      ..lineTo(tileSize / 2 + 5, box.bottom - 1)
      ..close();
    canvas.drawPath(tail, ui.Paint()..color = const ui.Color(0xFFFFFDF8));
    canvas.drawRRect(
      rr,
      ui.Paint()
        ..color = const ui.Color(0xFF8D6E63)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawParagraph(p, ui.Offset(box.left + 7, box.top + 5));
  }
}
