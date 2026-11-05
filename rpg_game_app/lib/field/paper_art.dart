import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Offset, Rect;
import 'package:rpg_game/rpg_game.dart';

/// ノートの世界の紙と、紙の上の小物・落書きを描く。
///
/// どれも通れるかどうかには関係しない、見た目だけの層。
/// 置き場所はマスの位置から決まるので、開くたびに同じ場所に描かれる。
abstract final class PaperArt {
  /// 紙の種類で、床の色を少し変える
  static ui.Color tintFloor(ui.Color base, PaperStyle p) => switch (p) {
    PaperStyle.blueprint => ui.Color.lerp(
      base,
      const ui.Color(0xFFDCE9F5),
      0.55,
    )!,
    PaperStyle.kraft => ui.Color.lerp(base, const ui.Color(0xFFE8D6B4), 0.45)!,
    PaperStyle.oldPage => ui.Color.lerp(base, const ui.Color(0xFFF0E2BE), 0.4)!,
    PaperStyle.sticky => ui.Color.lerp(base, const ui.Color(0xFFFFF4B8), 0.35)!,
    PaperStyle.manuscript => ui.Color.lerp(
      base,
      const ui.Color(0xFFFFF9EE),
      0.5,
    )!,
    PaperStyle.chalkboard => ui.Color.lerp(
      base,
      const ui.Color(0xFF3B4A3F),
      0.25,
    )!,
    _ => base,
  };

  /// 1マス分の紙の線
  static void lines(
    ui.Canvas c,
    Rect r,
    PaperStyle p,
    ui.Color grid,
    int col,
    int row,
  ) {
    final thin = ui.Paint()
      ..color = grid
      ..strokeWidth = 0.4;
    final line = ui.Paint()
      ..color = grid
      ..strokeWidth = 1;
    switch (p) {
      case PaperStyle.grid || PaperStyle.chalkboard:
        final g = p == PaperStyle.chalkboard
            ? (ui.Paint()
                ..color = const ui.Color(0x33FFFFFF)
                ..strokeWidth = 0.8)
            : line;
        c.drawLine(r.topLeft, r.topRight, g);
        c.drawLine(r.topLeft, r.bottomLeft, g);
        c.drawLine(
          Offset(r.left, r.center.dy),
          Offset(r.right, r.center.dy),
          thin,
        );
        c.drawLine(
          Offset(r.center.dx, r.top),
          Offset(r.center.dx, r.bottom),
          thin,
        );
      case PaperStyle.ruled || PaperStyle.looseLeaf || PaperStyle.sticky:
        // 横の罫線だけ（1マスに2本）
        for (final f in const [0.0, 0.5]) {
          c.drawLine(
            Offset(r.left, r.top + r.height * f),
            Offset(r.right, r.top + r.height * f),
            f == 0 ? line : thin,
          );
        }
        // 左の赤い余白線（12マスごと）
        if (col % 12 == 1) {
          c.drawLine(
            Offset(r.left + r.width * 0.3, r.top),
            Offset(r.left + r.width * 0.3, r.bottom),
            ui.Paint()
              ..color = const ui.Color(0x66E57373)
              ..strokeWidth = 1.2,
          );
        }
        // ルーズリーフの穴（12マスごと・2行ごと）
        if (p == PaperStyle.looseLeaf && col % 12 == 0 && row.isEven) {
          c.drawCircle(
            r.center,
            r.width * 0.12,
            ui.Paint()..color = const ui.Color(0x22000000),
          );
        }
      case PaperStyle.manuscript:
        // 原稿用紙のマス目（小さなすき間をあける）
        final box = r.deflate(r.width * 0.1);
        c.drawRect(
          box,
          ui.Paint()
            ..color = const ui.Color(0x55C0504D)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      case PaperStyle.staff:
        // 五線譜（4マスごとに5本の線）
        if (row % 4 != 3) {
          for (var i = 0; i < 2; i++) {
            c.drawLine(
              Offset(r.left, r.top + r.height * (0.25 + i * 0.5)),
              Offset(r.right, r.top + r.height * (0.25 + i * 0.5)),
              line,
            );
          }
        }
      case PaperStyle.blueprint:
        final b = ui.Paint()
          ..color = const ui.Color(0x553F7CAC)
          ..strokeWidth = 0.9;
        c.drawLine(r.topLeft, r.topRight, b);
        c.drawLine(r.topLeft, r.bottomLeft, b);
        for (final f in const [0.25, 0.5, 0.75]) {
          c.drawLine(
            Offset(r.left, r.top + r.height * f),
            Offset(r.right, r.top + r.height * f),
            thin..color = const ui.Color(0x223F7CAC),
          );
          c.drawLine(
            Offset(r.left + r.width * f, r.top),
            Offset(r.left + r.width * f, r.bottom),
            thin,
          );
        }
      case PaperStyle.kraft:
        // 紙のせんい
        final h = _hash(col, row, 3);
        final fiber = ui.Paint()
          ..color = const ui.Color(0x228D6E63)
          ..strokeWidth = 0.7;
        for (var i = 0; i < 3; i++) {
          final x = r.left + ((h >> (i * 4)) & 15) / 15 * r.width;
          final y = r.top + ((h >> (i * 4 + 12)) & 15) / 15 * r.height;
          c.drawLine(Offset(x, y), Offset(x + 4, y + 1.5), fiber);
        }
      case PaperStyle.oldPage:
        c.drawLine(r.topLeft, r.topRight, thin);
        // しみ
        if (_hash(col, row, 5) % 37 == 0) {
          c.drawCircle(
            r.center,
            r.width * 0.45,
            ui.Paint()..color = const ui.Color(0x18A1887F),
          );
        }
    }
  }

  static int _hash(int col, int row, int salt) {
    var h = col * 73856093 ^ row * 19349663 ^ salt * 83492791;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  /// そのマスに小物を置くなら、その種類（置かないなら null）
  static NotebookMark? markAt(int col, int row, PaperStyle p, int seed) {
    final h = _hash(col, row, seed);
    if ((h % 1000) / 1000 >= NotebookWorld.markDensity(p)) return null;
    final marks = NotebookMark.values;
    return marks[(h ~/ 1000) % marks.length];
  }

  /// 床の上の小物・落書き。[scribbles] は手書きのメモに書く言葉
  static void mark(
    ui.Canvas c,
    Rect r,
    NotebookMark m,
    List<String> scribbles,
    int col,
    int row, {
    bool dark = false,
  }) {
    final ink = dark ? const ui.Color(0x99FFFFFF) : const ui.Color(0x882E2A33);
    final pen = ui.Paint()
      ..color = ink
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = ui.StrokeCap.round;
    final s = r.width;
    final o = r.center;
    switch (m) {
      case NotebookMark.doodleStar:
        final p = ui.Path();
        for (var i = 0; i < 10; i++) {
          final a = -pi / 2 + i * pi / 5;
          final rr = i.isEven ? s * 0.22 : s * 0.09;
          final v = o + Offset(cos(a) * rr, sin(a) * rr);
          if (i == 0) {
            p.moveTo(v.dx, v.dy);
          } else {
            p.lineTo(v.dx, v.dy);
          }
        }
        p.close();
        c.drawPath(p, pen..color = const ui.Color(0x99F2B84B));
      case NotebookMark.doodleHeart:
        final p = ui.Path()
          ..moveTo(o.dx, o.dy + s * 0.16)
          ..cubicTo(
            o.dx - s * 0.3,
            o.dy - s * 0.05,
            o.dx - s * 0.1,
            o.dy - s * 0.25,
            o.dx,
            o.dy - s * 0.08,
          )
          ..cubicTo(
            o.dx + s * 0.1,
            o.dy - s * 0.25,
            o.dx + s * 0.3,
            o.dy - s * 0.05,
            o.dx,
            o.dy + s * 0.16,
          );
        c.drawPath(p, pen..color = const ui.Color(0x99E57373));
      case NotebookMark.doodleArrow:
        c.drawLine(
          o + Offset(-s * 0.22, s * 0.1),
          o + Offset(s * 0.2, -s * 0.1),
          pen,
        );
        c.drawLine(
          o + Offset(s * 0.2, -s * 0.1),
          o + Offset(s * 0.06, -s * 0.12),
          pen,
        );
        c.drawLine(o + Offset(s * 0.2, -s * 0.1), o + Offset(s * 0.12, 0), pen);
      case NotebookMark.doodleSpiral:
        final p = ui.Path()..moveTo(o.dx, o.dy);
        for (var i = 1; i <= 30; i++) {
          final a = i * 0.45;
          final rr = s * 0.007 * i;
          p.lineTo(o.dx + cos(a) * rr, o.dy + sin(a) * rr);
        }
        c.drawPath(p, pen);
      case NotebookMark.smiley:
        c.drawCircle(o, s * 0.17, pen);
        c.drawCircle(o + Offset(-s * 0.06, -s * 0.04), s * 0.015, pen);
        c.drawCircle(o + Offset(s * 0.06, -s * 0.04), s * 0.015, pen);
        c.drawArc(
          Rect.fromCircle(center: o, radius: s * 0.09),
          0.3,
          pi - 0.6,
          false,
          pen,
        );
      case NotebookMark.eraserSmudge:
        c.drawOval(
          Rect.fromCenter(center: o, width: s * 0.6, height: s * 0.22),
          ui.Paint()..color = const ui.Color(0x14000000),
        );
      case NotebookMark.coffeeRing:
        c.drawCircle(
          o,
          s * 0.3,
          ui.Paint()
            ..color = const ui.Color(0x228D6E63)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case NotebookMark.tape:
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(((col + row) % 5 - 2) * 0.15);
        c.drawRect(
          Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.2),
          ui.Paint()..color = const ui.Color(0x55F48FB1),
        );
        c.restore();
      case NotebookMark.sticker:
        c.drawCircle(
          o,
          s * 0.14,
          ui.Paint()..color = const ui.Color(0x99FFD54F),
        );
        c.drawCircle(o, s * 0.14, pen..strokeWidth = 0.8);
        c.drawCircle(o + Offset(-s * 0.04, -s * 0.02), s * 0.012, pen);
        c.drawCircle(o + Offset(s * 0.04, -s * 0.02), s * 0.012, pen);
      case NotebookMark.highlighter:
        c.drawLine(
          o + Offset(-s * 0.35, 0),
          o + Offset(s * 0.35, 0),
          ui.Paint()
            ..color = const ui.Color(0x4466BB6A)
            ..strokeWidth = s * 0.16
            ..strokeCap = ui.StrokeCap.round,
        );
      case NotebookMark.paperclip:
        final p = ui.Path()
          ..moveTo(o.dx - s * 0.04, o.dy + s * 0.18)
          ..lineTo(o.dx - s * 0.04, o.dy - s * 0.14)
          ..arcToPoint(
            Offset(o.dx + s * 0.08, o.dy - s * 0.14),
            radius: ui.Radius.circular(s * 0.06),
          )
          ..lineTo(o.dx + s * 0.08, o.dy + s * 0.12)
          ..arcToPoint(
            Offset(o.dx, o.dy + s * 0.12),
            radius: ui.Radius.circular(s * 0.04),
          )
          ..lineTo(o.dx, o.dy - s * 0.08);
        c.drawPath(p, pen..color = const ui.Color(0xAA8A929C));
      case NotebookMark.shavings:
        for (var i = 0; i < 3; i++) {
          final a = i * 2.1 + col;
          c.drawArc(
            Rect.fromCircle(
              center: o + Offset(cos(a) * s * 0.12, sin(a) * s * 0.1),
              radius: s * 0.07,
            ),
            a,
            pi,
            false,
            ui.Paint()
              ..color = const ui.Color(0x88D7A86E)
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      case NotebookMark.note:
        final word = scribbles[(col * 7 + row * 3) % scribbles.length];
        final b =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(textAlign: ui.TextAlign.center),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: dark
                      ? const ui.Color(0xAAFFFFFF)
                      : const ui.Color(0x995B6B8A),
                  fontSize: s * 0.26,
                  fontStyle: ui.FontStyle.italic,
                ),
              )
              ..addText(word);
        final para = b.build()..layout(ui.ParagraphConstraints(width: s * 1.6));
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(-0.12);
        c.drawParagraph(para, Offset(-s * 0.8, -para.height / 2));
        c.restore();
      case NotebookMark.checkmark:
        c.drawPath(
          ui.Path()
            ..moveTo(o.dx - s * 0.16, o.dy)
            ..lineTo(o.dx - s * 0.04, o.dy + s * 0.12)
            ..lineTo(o.dx + s * 0.2, o.dy - s * 0.16),
          pen
            ..color = const ui.Color(0x99D64545)
            ..strokeWidth = 1.6,
        );
    }
  }
}
