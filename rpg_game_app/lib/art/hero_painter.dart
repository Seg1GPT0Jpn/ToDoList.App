import 'dart:math';
import 'dart:ui';

/// 主人公の向き
enum Facing { down, up, left, right }

const _coat = Color(0xFF6D4C41);
const _coatDark = Color(0xFF4E342E);
const _skin = Color(0xFFF7E1C4);
const _hair = Color(0xFF3E2723);
const _scarf = Color(0xFFC0504D);
const _ink = Color(0xFF2E2A33);
const _pencil = Color(0xFFF2C94C);
const _eraser = Color(0xFFE8A0A8);

/// 主人公（えんぴつを持った見習い冒険者）を描く。
///
/// [size] の正方形に収まるように描く。[walk] は歩行アニメの位相（0〜1 で1歩分×2）、
/// [moving] が false のときは立ち姿。
void paintHero(
  Canvas canvas,
  double size, {
  Facing facing = Facing.down,
  double walk = 0,
  bool moving = false,
}) {
  final s = size;
  final swing = moving ? sin(walk * 2 * pi) : 0.0;
  final bob = moving ? (sin(walk * 4 * pi).abs() * s * 0.04) : 0.0;
  final stroke = Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.035
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  Paint fill(Color c) => Paint()..color = c;

  // 影
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.93),
      width: s * 0.5,
      height: s * 0.12,
    ),
    fill(const Color(0x33000000)),
  );

  canvas.save();
  canvas.translate(0, -bob);

  // 足
  final legW = s * 0.1;
  final legTop = s * 0.72;
  for (final side in [-1, 1]) {
    final dx = facing == Facing.left || facing == Facing.right
        ? swing * side * s * 0.08
        : 0.0;
    final lift = facing == Facing.down || facing == Facing.up
        ? max(0.0, swing * side) * s * 0.05
        : 0.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        s * 0.5 + side * s * 0.1 - legW / 2 + dx,
        legTop,
        legW,
        s * 0.17 - lift,
      ),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(r, fill(_coatDark));
  }

  // えんぴつ（後ろ向き以外は体の横に）
  void pencil() {
    final hx = facing == Facing.left ? s * 0.2 : s * 0.8;
    canvas.save();
    canvas.translate(hx, s * 0.6 + swing * s * 0.02);
    canvas.rotate(facing == Facing.left ? -0.5 : 0.5);
    final body = Rect.fromLTWH(-s * 0.045, -s * 0.34, s * 0.09, s * 0.3);
    canvas.drawRect(body, fill(_pencil));
    canvas.drawRect(
      Rect.fromLTWH(-s * 0.045, -s * 0.4, s * 0.09, s * 0.06),
      fill(_eraser),
    );
    final tip = Path()
      ..moveTo(-s * 0.045, -s * 0.04)
      ..lineTo(s * 0.045, -s * 0.04)
      ..lineTo(0, s * 0.06)
      ..close();
    canvas.drawPath(tip, fill(const Color(0xFFF1DDBB)));
    canvas.drawRect(body, stroke..strokeWidth = s * 0.025);
    canvas.restore();
    stroke.strokeWidth = s * 0.035;
  }

  if (facing == Facing.up) pencil();

  // 体（コート）
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.27, s * 0.45, s * 0.46, s * 0.32),
    Radius.circular(s * 0.12),
  );
  canvas.drawRRect(body, fill(_coat));
  canvas.drawRRect(body, stroke);

  // マフラー
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.3, s * 0.43, s * 0.4, s * 0.08),
      Radius.circular(s * 0.04),
    ),
    fill(_scarf),
  );
  if (facing != Facing.up) {
    final tailX = facing == Facing.left ? s * 0.6 : s * 0.36;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tailX, s * 0.47, s * 0.08, s * 0.14 + swing * s * 0.02),
        Radius.circular(s * 0.03),
      ),
      fill(_scarf),
    );
  }

  // 頭
  final head = Offset(s * 0.5, s * 0.3);
  final r = s * 0.21;
  canvas.drawCircle(head, r, fill(_skin));
  // 髪
  final hair = Path();
  switch (facing) {
    case Facing.up:
      hair.addOval(Rect.fromCircle(center: head, radius: r));
    case Facing.down:
      hair.addArc(Rect.fromCircle(center: head, radius: r), pi, pi);
      hair.close();
    case Facing.left:
    case Facing.right:
      final dir = facing == Facing.left ? 1.0 : -1.0;
      hair.addArc(
        Rect.fromCircle(center: head, radius: r),
        pi * 0.95,
        pi * 1.1,
      );
      hair.lineTo(head.dx + dir * r * 0.9, head.dy + r * 0.3);
      hair.close();
  }
  canvas.drawPath(hair, fill(_hair));
  // 前髪のはね
  canvas.drawLine(
    Offset(head.dx - r * 0.1, head.dy - r),
    Offset(head.dx + r * 0.25, head.dy - r * 1.35),
    stroke,
  );
  canvas.drawCircle(head, r, stroke);

  // 顔
  final eye = fill(_ink);
  switch (facing) {
    case Facing.down:
      canvas.drawCircle(
        Offset(head.dx - r * 0.38, head.dy + r * 0.2),
        s * 0.025,
        eye,
      );
      canvas.drawCircle(
        Offset(head.dx + r * 0.38, head.dy + r * 0.2),
        s * 0.025,
        eye,
      );
      canvas.drawCircle(
        Offset(head.dx - r * 0.6, head.dy + r * 0.5),
        s * 0.03,
        fill(const Color(0x55E57373)),
      );
      canvas.drawCircle(
        Offset(head.dx + r * 0.6, head.dy + r * 0.5),
        s * 0.03,
        fill(const Color(0x55E57373)),
      );
    case Facing.left:
      canvas.drawCircle(
        Offset(head.dx - r * 0.45, head.dy + r * 0.2),
        s * 0.025,
        eye,
      );
    case Facing.right:
      canvas.drawCircle(
        Offset(head.dx + r * 0.45, head.dy + r * 0.2),
        s * 0.025,
        eye,
      );
    case Facing.up:
      break;
  }

  if (facing != Facing.up) pencil();
  canvas.restore();
}
