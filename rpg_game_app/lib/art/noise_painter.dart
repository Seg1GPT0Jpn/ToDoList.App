import 'dart:math';

import 'package:flutter/material.dart';

/// ノイズ：フードをかぶった、白い仮面の少年
void paintNoise(Canvas c, double s, double t) {
  final sway = sin(t * 1.5) * s * 0.01;
  final ink = Paint()
    ..color = const Color(0xFF2E2A33)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.018
    ..strokeJoin = StrokeJoin.round;
  c.save();
  c.translate(sway, 0);
  // マント
  final cloak = Path()
    ..moveTo(s * 0.5, s * 0.2)
    ..quadraticBezierTo(s * 0.26, s * 0.3, s * 0.22, s * 0.88)
    ..lineTo(s * 0.78, s * 0.88)
    ..quadraticBezierTo(s * 0.74, s * 0.3, s * 0.5, s * 0.2)
    ..close();
  c.drawPath(cloak, Paint()..color = const Color(0xFF37474F));
  // ぎざぎざの裾（ノイズのしるし）
  final hem = Path()..moveTo(s * 0.22, s * 0.88);
  for (var i = 0; i < 8; i++) {
    hem.lineTo(s * (0.255 + i * 0.07), s * (i.isEven ? 0.83 : 0.9));
  }
  hem.lineTo(s * 0.78, s * 0.88);
  c.drawPath(hem, ink);
  c.drawPath(cloak, ink);
  // フードの中の顔と仮面
  final head = Offset(s * 0.5, s * 0.36);
  c.drawCircle(head, s * 0.13, Paint()..color = const Color(0xFF263238));
  final mask = Path()
    ..moveTo(head.dx - s * 0.1, head.dy - s * 0.06)
    ..quadraticBezierTo(
      head.dx,
      head.dy - s * 0.1,
      head.dx + s * 0.1,
      head.dy - s * 0.06,
    )
    ..quadraticBezierTo(
      head.dx + s * 0.1,
      head.dy + s * 0.08,
      head.dx,
      head.dy + s * 0.1,
    )
    ..quadraticBezierTo(
      head.dx - s * 0.1,
      head.dy + s * 0.08,
      head.dx - s * 0.1,
      head.dy - s * 0.06,
    )
    ..close();
  c.drawPath(mask, Paint()..color = const Color(0xFFF5F5F5));
  c.drawPath(mask, ink..strokeWidth = s * 0.012);
  // 仮面の目と、ひびの線
  for (final d in [-1.0, 1.0]) {
    c.drawOval(
      Rect.fromCenter(
        center: head + Offset(d * s * 0.045, -s * 0.01),
        width: s * 0.05,
        height: s * 0.022,
      ),
      Paint()..color = const Color(0xFF263238),
    );
  }
  c.drawLine(
    head + Offset(s * 0.02, -s * 0.08),
    head + Offset(s * 0.04, s * 0.02),
    ink..strokeWidth = s * 0.008,
  );
  // ノート（胸にかかえている）
  c.drawRect(
    Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.62),
      width: s * 0.2,
      height: s * 0.14,
    ),
    Paint()..color = const Color(0xFF8D6E63),
  );
  c.drawRect(
    Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.62),
      width: s * 0.2,
      height: s * 0.14,
    ),
    ink..strokeWidth = s * 0.012,
  );
  c.restore();
}
