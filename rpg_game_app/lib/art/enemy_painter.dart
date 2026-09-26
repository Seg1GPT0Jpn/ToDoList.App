import 'dart:math';
import 'dart:ui';

const _ink = Color(0xFF2E2A33);
const _white = Color(0xFFFFFDF8);

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(double w, [Color c = _ink]) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// 敵を [size] の正方形に描く。[t] は経過秒（待機アニメ用）。
///
/// [look]（slime / goblin / bat / golem / knight / dragon）で形を、
/// [color] で体の色を決める。
void paintEnemy(
  Canvas canvas,
  double size,
  String look,
  double t, {
  int? color,
}) {
  final c = color == null ? null : Color(color);
  switch (look) {
    case 'goblin':
      _goblin(canvas, size, t, c ?? const Color(0xFF3A3A58));
    case 'bat':
      _bat(canvas, size, t, c ?? const Color(0xFF7E57C2));
    case 'golem':
      _golem(canvas, size, t, c ?? const Color(0xFFA1887F));
    case 'knight':
      _knight(canvas, size, t, c ?? const Color(0xFF6E7F8A));
    case 'dragon':
      _dragon(canvas, size, t, c ?? const Color(0xFFB23A48));
    case 'ghost':
      _ghost(canvas, size, t, c ?? const Color(0xFFB9C6E8));
    default:
      _slime(canvas, size, t, c ?? const Color(0xFF9CCB8B));
  }
}

void _shadow(Canvas c, double s, [double w = 0.6]) => c.drawOval(
  Rect.fromCenter(
    center: Offset(s * 0.5, s * 0.92),
    width: s * w,
    height: s * 0.1,
  ),
  _fill(const Color(0x33000000)),
);

void _eyes(
  Canvas c,
  Offset l,
  Offset r,
  double s, {
  double size = 0.08,
  Color white = _white,
  bool angry = false,
}) {
  for (final e in [l, r]) {
    c.drawCircle(e, s * size, _fill(white));
    c.drawCircle(e, s * size, _stroke(s * 0.02));
    c.drawCircle(e + Offset(0, s * 0.01), s * size * 0.45, _fill(_ink));
  }
  if (angry) {
    final w = s * 0.03;
    c.drawLine(
      l + Offset(-s * size, -s * size * 1.6),
      l + Offset(s * size, -s * size * 1.0),
      _stroke(w),
    );
    c.drawLine(
      r + Offset(s * size, -s * size * 1.6),
      r + Offset(-s * size, -s * size * 1.0),
      _stroke(w),
    );
  }
}

/// 落書きスライム：ぷるぷる揺れる、ゆるい線の落書き
void _slime(Canvas c, double s, double t, Color body) {
  _shadow(c, s);
  final squish = sin(t * 5) * 0.06;
  c.save();
  c.translate(s * 0.5, s * 0.9);
  c.scale(1 + squish, 1 - squish);
  final p = Path()
    ..moveTo(-s * 0.36, 0)
    ..cubicTo(-s * 0.42, -s * 0.3, -s * 0.2, -s * 0.58, 0, -s * 0.58)
    ..cubicTo(s * 0.22, -s * 0.58, s * 0.42, -s * 0.3, s * 0.36, 0)
    ..close();
  c.drawPath(p, _fill(body));
  // 鉛筆の塗りムラ
  final hatch = _stroke(s * 0.015, const Color(0x3363A35A));
  for (var i = -4; i < 5; i++) {
    c.drawLine(
      Offset(i * s * 0.08 - s * 0.05, -s * 0.05),
      Offset(i * s * 0.08 + s * 0.08, -s * 0.4),
      hatch,
    );
  }
  c.drawPath(p, _stroke(s * 0.03));
  // 落書きの渦
  c.drawArc(
    Rect.fromCircle(center: Offset(s * 0.18, -s * 0.38), radius: s * 0.05),
    0,
    pi * 1.5,
    false,
    _stroke(s * 0.015),
  );
  _eyes(c, Offset(-s * 0.12, -s * 0.3), Offset(s * 0.1, -s * 0.3), s);
  c.drawArc(
    Rect.fromCenter(
      center: Offset(0, -s * 0.18),
      width: s * 0.12,
      height: s * 0.08,
    ),
    0.2,
    pi - 0.4,
    false,
    _stroke(s * 0.02),
  );
  c.restore();
}

/// インク染みゴブリン：インクのしずく型、とがった耳
void _goblin(Canvas c, double s, double t, Color body) {
  _shadow(c, s);
  final hop = sin(t * 4).abs() * s * 0.05;
  c.save();
  c.translate(s * 0.5, s * 0.88 - hop);
  // 耳
  for (final d in [-1.0, 1.0]) {
    final ear = Path()
      ..moveTo(d * s * 0.2, -s * 0.42)
      ..lineTo(d * s * 0.44, -s * 0.58 + sin(t * 6 + d) * s * 0.02)
      ..lineTo(d * s * 0.28, -s * 0.3)
      ..close();
    c.drawPath(ear, _fill(body));
    c.drawPath(ear, _stroke(s * 0.025));
  }
  final p = Path()
    ..moveTo(0, -s * 0.72)
    ..cubicTo(s * 0.1, -s * 0.55, s * 0.34, -s * 0.35, s * 0.3, -s * 0.12)
    ..cubicTo(s * 0.27, s * 0.02, -s * 0.27, s * 0.02, -s * 0.3, -s * 0.12)
    ..cubicTo(-s * 0.34, -s * 0.35, -s * 0.1, -s * 0.55, 0, -s * 0.72)
    ..close();
  c.drawPath(p, _fill(body));
  c.drawPath(p, _stroke(s * 0.03));
  // インクのしぶき
  for (final o in [Offset(-s * 0.38, -s * 0.05), Offset(s * 0.4, -s * 0.02)]) {
    c.drawCircle(o, s * 0.03, _fill(body));
  }
  _eyes(
    c,
    Offset(-s * 0.1, -s * 0.3),
    Offset(s * 0.1, -s * 0.3),
    s,
    size: 0.06,
    white: const Color(0xFFF7D35C),
    angry: true,
  );
  // にやり
  final grin = Path()
    ..moveTo(-s * 0.12, -s * 0.15)
    ..quadraticBezierTo(0, -s * 0.07, s * 0.12, -s * 0.15);
  c.drawPath(grin, _stroke(s * 0.025, _white));
  c.restore();
}

/// しおりバット：しおりのリボンの翼をぱたぱた
void _bat(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final flap = sin(t * 10) * 0.45;
  final float = sin(t * 3) * s * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.48 + float);
  const wing = Color(0xFFC0504D);
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.scale(d, 1);
    c.rotate(-flap);
    final w = Path()
      ..moveTo(s * 0.08, -s * 0.05)
      ..lineTo(s * 0.46, -s * 0.2)
      ..lineTo(s * 0.46, s * 0.12)
      ..lineTo(s * 0.38, s * 0.04) // しおりの切り込み
      ..lineTo(s * 0.3, s * 0.12)
      ..lineTo(s * 0.08, s * 0.08)
      ..close();
    c.drawPath(w, _fill(wing));
    c.drawLine(
      Offset(s * 0.12, 0),
      Offset(s * 0.44, -s * 0.1),
      _stroke(s * 0.012, const Color(0x66FFFFFF)),
    );
    c.drawPath(w, _stroke(s * 0.025));
    c.restore();
  }
  c.drawCircle(Offset.zero, s * 0.17, _fill(body));
  // 耳
  for (final d in [-1.0, 1.0]) {
    final ear = Path()
      ..moveTo(d * s * 0.05, -s * 0.15)
      ..lineTo(d * s * 0.12, -s * 0.28)
      ..lineTo(d * s * 0.15, -s * 0.1)
      ..close();
    c.drawPath(ear, _fill(body));
    c.drawPath(ear, _stroke(s * 0.02));
  }
  c.drawCircle(Offset.zero, s * 0.17, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(-s * 0.06, -s * 0.02),
    Offset(s * 0.06, -s * 0.02),
    s,
    size: 0.045,
  );
  // きば
  for (final d in [-1.0, 1.0]) {
    final f = Path()
      ..moveTo(d * s * 0.04, s * 0.08)
      ..lineTo(d * s * 0.02, s * 0.13)
      ..lineTo(0, s * 0.08);
    c.drawPath(f, _fill(_white));
  }
  c.restore();
}

/// 辞書ゴーレム：分厚い本が積み重なった巨体
void _golem(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.7);
  final sway = sin(t * 1.8) * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.9);
  c.rotate(sway);
  void book(Rect r, Color color, {String? label}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(s * 0.02));
    c.drawRRect(rr, _fill(color));
    // ページの線
    final pageY = r.bottom - r.height * 0.28;
    c.drawRect(
      Rect.fromLTRB(
        r.left + s * 0.02,
        pageY,
        r.right - s * 0.02,
        r.bottom - s * 0.01,
      ),
      _fill(const Color(0xFFF5ECD8)),
    );
    for (var i = 1; i < 3; i++) {
      final y = pageY + (r.bottom - pageY) * i / 3;
      c.drawLine(
        Offset(r.left + s * 0.03, y),
        Offset(r.right - s * 0.03, y),
        _stroke(s * 0.008, const Color(0x55000000)),
      );
    }
    c.drawRRect(rr, _stroke(s * 0.025));
  }

  // 腕
  for (final d in [-1.0, 1.0]) {
    book(
      Rect.fromCenter(
        center: Offset(d * s * 0.38, -s * 0.32 + sin(t * 2 + d) * s * 0.02),
        width: s * 0.14,
        height: s * 0.3,
      ),
      const Color(0xFF8D6E63),
    );
  }
  book(
    Rect.fromLTWH(-s * 0.3, -s * 0.2, s * 0.6, s * 0.2),
    const Color(0xFF5D4037),
  );
  book(
    Rect.fromLTWH(-s * 0.27, -s * 0.42, s * 0.54, s * 0.22),
    const Color(0xFFA1887F),
  );
  // 頭（辞書）
  book(
    Rect.fromLTWH(-s * 0.2, -s * 0.7, s * 0.4, s * 0.28),
    const Color(0xFF6D4C41),
  );
  final glow = 0.6 + sin(t * 3) * 0.4;
  for (final d in [-1.0, 1.0]) {
    c.drawCircle(
      Offset(d * s * 0.08, -s * 0.6),
      s * 0.035,
      _fill(Color.fromRGBO(255, 170, 60, glow)),
    );
  }
  c.restore();
}

/// 文法ナイト：兜と羽飾り、「A」の盾
void _knight(Canvas c, double s, double t, Color tint) {
  _shadow(c, s, 0.55);
  final breathe = sin(t * 2.2) * s * 0.012;
  c.save();
  c.translate(s * 0.5, s * 0.9);
  const steel = Color(0xFF9AAAB5);
  final steelDark = tint;
  // 体
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(-s * 0.2, -s * 0.42 - breathe, s * 0.4, s * 0.4),
    Radius.circular(s * 0.08),
  );
  c.drawRRect(body, _fill(steelDark));
  c.drawRRect(body, _stroke(s * 0.025));
  // 羽飾り
  final plume = Path()
    ..moveTo(0, -s * 0.8 - breathe)
    ..quadraticBezierTo(
      s * 0.25 + sin(t * 4) * s * 0.03,
      -s * 0.95,
      s * 0.28,
      -s * 0.72,
    )
    ..quadraticBezierTo(s * 0.12, -s * 0.8, 0, -s * 0.72)
    ..close();
  c.drawPath(plume, _fill(const Color(0xFFC0504D)));
  c.drawPath(plume, _stroke(s * 0.02));
  // 兜
  final helm = RRect.fromRectAndRadius(
    Rect.fromLTWH(-s * 0.17, -s * 0.78 - breathe, s * 0.34, s * 0.36),
    Radius.circular(s * 0.12),
  );
  c.drawRRect(helm, _fill(steel));
  c.drawRRect(helm, _stroke(s * 0.025));
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-s * 0.12, -s * 0.64 - breathe, s * 0.24, s * 0.05),
      Radius.circular(s * 0.02),
    ),
    _fill(_ink),
  );
  final eyeGlow = _fill(const Color(0xFF7FD6FF));
  c.drawCircle(Offset(-s * 0.05, -s * 0.615 - breathe), s * 0.015, eyeGlow);
  c.drawCircle(Offset(s * 0.05, -s * 0.615 - breathe), s * 0.015, eyeGlow);
  // 剣（ペン）
  c.save();
  c.translate(s * 0.3, -s * 0.25);
  c.rotate(-0.3 + sin(t * 2) * 0.05);
  c.drawRect(
    Rect.fromLTWH(-s * 0.02, -s * 0.45, s * 0.04, s * 0.45),
    _fill(const Color(0xFF455A64)),
  );
  c.drawRect(
    Rect.fromLTWH(-s * 0.02, -s * 0.45, s * 0.04, s * 0.45),
    _stroke(s * 0.015),
  );
  c.drawRect(
    Rect.fromLTWH(-s * 0.07, -s * 0.03, s * 0.14, s * 0.04),
    _fill(const Color(0xFFF2B84B)),
  );
  c.restore();
  // 盾
  final shield = Path()
    ..moveTo(-s * 0.4, -s * 0.42)
    ..lineTo(-s * 0.12, -s * 0.42)
    ..lineTo(-s * 0.12, -s * 0.2)
    ..quadraticBezierTo(-s * 0.14, -s * 0.05, -s * 0.26, 0)
    ..quadraticBezierTo(-s * 0.38, -s * 0.05, -s * 0.4, -s * 0.2)
    ..close();
  c.drawPath(shield, _fill(const Color(0xFFF5ECD8)));
  c.drawPath(shield, _stroke(s * 0.025));
  final tp = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.center))
    ..pushStyle(
      TextStyle(
        color: const Color(0xFF6D4C41),
        fontSize: s * 0.2,
        fontWeight: FontWeight.w900,
      ),
    )
    ..addText('A');
  final para = tp.build()..layout(ParagraphConstraints(width: s * 0.28));
  c.drawParagraph(para, Offset(-s * 0.4, -s * 0.38));
  c.restore();
}

/// 英作文ドラゴン：罫線入りの紙の翼を持つ主
void _dragon(Canvas c, double s, double t, Color tint) {
  _shadow(c, s, 0.75);
  final flap = sin(t * 2.5) * 0.15;
  c.save();
  c.translate(s * 0.5, s * 0.9);
  final scale = tint;
  // 翼（ノートの紙）
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.translate(d * s * 0.12, -s * 0.45);
    c.scale(d, 1);
    c.rotate(-flap);
    final w = Path()
      ..moveTo(0, 0)
      ..lineTo(s * 0.42, -s * 0.38)
      ..lineTo(s * 0.46, -s * 0.05)
      ..quadraticBezierTo(s * 0.3, -s * 0.02, s * 0.25, s * 0.12)
      ..close();
    c.drawPath(w, _fill(const Color(0xFFFFFDF8)));
    for (var i = 1; i < 5; i++) {
      c.drawLine(
        Offset(s * 0.06, -s * 0.06 * i + s * 0.04),
        Offset(s * 0.42, -s * 0.07 * i + s * 0.04),
        _stroke(s * 0.008, const Color(0xFF9CC3E0)),
      );
    }
    c.drawPath(w, _stroke(s * 0.025));
    c.restore();
  }
  // 体
  final body = Path()
    ..moveTo(-s * 0.26, 0)
    ..quadraticBezierTo(-s * 0.3, -s * 0.45, 0, -s * 0.5)
    ..quadraticBezierTo(s * 0.3, -s * 0.45, s * 0.26, 0)
    ..close();
  c.drawPath(body, _fill(scale));
  c.drawPath(
    Path()
      ..moveTo(-s * 0.13, 0)
      ..quadraticBezierTo(0, -s * 0.5, s * 0.13, 0)
      ..close(),
    _fill(const Color(0xFFF3C9A0)),
  );
  c.drawPath(body, _stroke(s * 0.03));
  // 頭
  final headY = -s * 0.62 + sin(t * 2.5) * s * 0.015;
  for (final d in [-1.0, 1.0]) {
    final horn = Path()
      ..moveTo(d * s * 0.08, headY - s * 0.1)
      ..lineTo(d * s * 0.18, headY - s * 0.26)
      ..lineTo(d * s * 0.15, headY - s * 0.07)
      ..close();
    c.drawPath(horn, _fill(const Color(0xFFF5ECD8)));
    c.drawPath(horn, _stroke(s * 0.02));
  }
  final head = Rect.fromCenter(
    center: Offset(0, headY),
    width: s * 0.36,
    height: s * 0.26,
  );
  c.drawOval(head, _fill(scale));
  c.drawOval(head, _stroke(s * 0.03));
  _eyes(
    c,
    Offset(-s * 0.08, headY - s * 0.02),
    Offset(s * 0.08, headY - s * 0.02),
    s,
    size: 0.045,
    white: const Color(0xFFF7D35C),
    angry: true,
  );
  // 炎（文字のかけら）
  final flicker = (sin(t * 12) + 1) / 2;
  c.drawCircle(
    Offset(0, headY + s * 0.13),
    s * (0.03 + flicker * 0.02),
    _fill(Color.fromRGBO(255, 150, 50, 0.8)),
  );
  c.restore();
}

/// 亡霊（間違えた問題のなごり）：ふわふわ浮かぶ半透明のおばけ
void _ghost(Canvas c, double s, double t, Color body) {
  final bob = sin(t * 2.2) * s * 0.04;
  _shadow(c, s, 0.4);
  final top = s * 0.2 + bob, bottom = s * 0.8 + bob;
  final path = Path()
    ..moveTo(s * 0.22, bottom)
    ..lineTo(s * 0.22, s * 0.45 + bob)
    ..arcToPoint(
      Offset(s * 0.78, s * 0.45 + bob),
      radius: Radius.circular(s * 0.28),
    )
    ..lineTo(s * 0.78, bottom);
  // すそのぎざぎざ（ゆらゆら動く）
  for (var i = 0; i < 4; i++) {
    final x0 = s * (0.78 - i * 0.14);
    final wob = sin(t * 4 + i) * s * 0.02;
    path.quadraticBezierTo(
      x0 - s * 0.07,
      bottom - s * 0.09 + wob,
      x0 - s * 0.14,
      bottom,
    );
  }
  path.close();
  c.drawPath(path, _fill(body.withValues(alpha: 0.85)));
  c.drawPath(path, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(s * 0.4, top + s * 0.22),
    Offset(s * 0.6, top + s * 0.22),
    s,
    size: 0.06,
  );
  // 「？」マーク
  final b = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.center))
    ..pushStyle(
      TextStyle(color: _ink, fontSize: s * 0.16, fontWeight: FontWeight.w900),
    )
    ..addText('?');
  final p = b.build()..layout(ParagraphConstraints(width: s));
  c.drawParagraph(p, Offset(0, top + s * 0.3));
}
