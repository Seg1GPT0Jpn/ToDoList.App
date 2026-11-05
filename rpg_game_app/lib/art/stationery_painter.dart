part of 'enemy_painter.dart';

// 文房具モンスター。どれも [s] の正方形に、足もとが y ≒ 0.9s になるように描く。
// [t] は経過秒（待機アニメ用）。

const _paper = Color(0xFFFFFDF6);
const _wood = Color(0xFFF1C27D);
const _graphite = Color(0xFF4A4A52);
const _metal = Color(0xFFB8BEC6);

/// 顔（目と口）。[mouth] は 'smile' / 'grin' / 'o' / 'flat'
void _face(
  Canvas c,
  Offset center,
  double s, {
  double gap = 0.1,
  double eye = 0.055,
  bool angry = false,
  String mouth = 'smile',
  Color line = _ink,
}) {
  _eyes(
    c,
    center + Offset(-s * gap, 0),
    center + Offset(s * gap, 0),
    s,
    size: eye,
    angry: angry,
  );
  final m = center + Offset(0, s * 0.1);
  switch (mouth) {
    case 'grin':
      final p = Path()
        ..moveTo(m.dx - s * 0.08, m.dy - s * 0.01)
        ..quadraticBezierTo(
          m.dx,
          m.dy + s * 0.06,
          m.dx + s * 0.08,
          m.dy - s * 0.01,
        )
        ..close();
      c.drawPath(p, _fill(line));
    case 'o':
      c.drawOval(
        Rect.fromCenter(center: m, width: s * 0.06, height: s * 0.07),
        _fill(line),
      );
    case 'flat':
      c.drawLine(
        m + Offset(-s * 0.05, 0),
        m + Offset(s * 0.05, 0),
        _stroke(s * 0.02, line),
      );
    default:
      c.drawArc(
        Rect.fromCenter(center: m, width: s * 0.12, height: s * 0.07),
        0.2,
        pi - 0.4,
        false,
        _stroke(s * 0.02, line),
      );
  }
}

/// 小さな手（丸）
void _hand(Canvas c, Offset o, double s, Color color) {
  c.drawCircle(o, s * 0.04, _fill(color));
  c.drawCircle(o, s * 0.04, _stroke(s * 0.018));
}

/// 消しゴム：白いかたまりにスリーブ。消しカスを飛ばす
void _eraser(Canvas c, double s, double t, Color sleeve) {
  _shadow(c, s, 0.55);
  final wobble = sin(t * 3) * 0.05;
  c.save();
  c.translate(s * 0.5, s * 0.66);
  c.rotate(wobble);
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: s * 0.62, height: s * 0.36),
    Radius.circular(s * 0.07),
  );
  c.drawRRect(body, _fill(_paper));
  // スリーブ（右半分）
  c.save();
  c.clipRRect(body);
  c.drawRect(
    Rect.fromLTWH(s * 0.04, -s * 0.2, s * 0.3, s * 0.4),
    _fill(sleeve),
  );
  c.drawLine(
    Offset(s * 0.08, -s * 0.12),
    Offset(s * 0.26, -s * 0.12),
    _stroke(s * 0.02, const Color(0xAAFFFFFF)),
  );
  c.restore();
  c.drawRRect(body, _stroke(s * 0.03));
  // すり減った角
  c.drawLine(
    Offset(-s * 0.31, s * 0.1),
    Offset(-s * 0.25, s * 0.18),
    _stroke(s * 0.02, const Color(0x55000000)),
  );
  _face(c, Offset(-s * 0.13, -s * 0.03), s, gap: 0.07, eye: 0.045, angry: true);
  c.restore();
  // 消しカス
  for (var i = 0; i < 4; i++) {
    final p = (t * 0.8 + i / 4) % 1;
    final x = s * (0.22 - p * 0.18) - i * s * 0.02;
    final y = s * (0.55 + p * p * 0.3) - i * s * 0.03;
    c.save();
    c.translate(x, y);
    c.rotate(p * 4 + i);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: s * 0.05,
          height: s * 0.022,
        ),
        Radius.circular(s * 0.01),
      ),
      _fill(const Color(0xFFBDB6AA)),
    );
    c.restore();
  }
}

/// クレヨン：紙を巻いた太い棒。色がそのまま性格
void _crayon(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final hop = sin(t * 5).abs() * s * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.88 - hop);
  c.rotate(sin(t * 2.5) * 0.08);
  final w = s * 0.3;
  // 本体
  final stick = Rect.fromLTWH(-w / 2, -s * 0.62, w, s * 0.62);
  c.drawRRect(
    RRect.fromRectAndCorners(
      stick,
      bottomLeft: Radius.circular(s * 0.04),
      bottomRight: Radius.circular(s * 0.04),
    ),
    _fill(body),
  );
  // 先端
  final tip = Path()
    ..moveTo(-w / 2, -s * 0.62)
    ..lineTo(-w * 0.2, -s * 0.78)
    ..lineTo(w * 0.2, -s * 0.78)
    ..lineTo(w / 2, -s * 0.62)
    ..close();
  c.drawPath(tip, _fill(body));
  c.drawPath(tip, _stroke(s * 0.025));
  // 巻き紙（ぎざぎざのふち）
  final wrap = Path()..moveTo(-w / 2, -s * 0.5);
  for (var i = 0; i <= 6; i++) {
    wrap.lineTo(-w / 2 + w * i / 6, -s * 0.5 + (i.isOdd ? -s * 0.03 : 0));
  }
  wrap
    ..lineTo(w / 2, -s * 0.12)
    ..lineTo(-w / 2, -s * 0.12)
    ..close();
  c.drawPath(wrap, _fill(Color.lerp(body, _paper, 0.72)!));
  c.drawPath(wrap, _stroke(s * 0.02));
  c.drawLine(
    Offset(-w / 2 + s * 0.03, -s * 0.2),
    Offset(w / 2 - s * 0.03, -s * 0.2),
    _stroke(s * 0.015, body),
  );
  c.drawRRect(
    RRect.fromRectAndCorners(
      stick,
      bottomLeft: Radius.circular(s * 0.04),
      bottomRight: Radius.circular(s * 0.04),
    ),
    _stroke(s * 0.03),
  );
  _face(c, Offset(0, -s * 0.36), s, gap: 0.065, eye: 0.042, mouth: 'grin');
  // ぐりぐり描いた線
  c.restore();
  final scribble = Path()..moveTo(s * 0.12, s * 0.86);
  for (var i = 0; i < 5; i++) {
    scribble.relativeQuadraticBezierTo(s * 0.03, -s * 0.05, s * 0.06, 0);
  }
  c.drawPath(scribble, _stroke(s * 0.02, body.withValues(alpha: 0.7)));
}

/// 付箋モンスター：何枚も重なった付箋。「ここ重要！」
void _sticky(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  c.save();
  c.translate(s * 0.5, s * 0.55);
  c.rotate(sin(t * 2) * 0.06);
  final colors = [
    Color.lerp(body, const Color(0xFFFF8FA3), 0.6)!,
    Color.lerp(body, const Color(0xFF8FD3FF), 0.6)!,
    body,
  ];
  for (var i = 0; i < 3; i++) {
    c.save();
    c.translate(-s * 0.04 + i * s * 0.04, -s * 0.04 + i * s * 0.04);
    c.rotate((i - 1) * 0.1);
    final r = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.52,
      height: s * 0.52,
    );
    final note = Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.bottom - s * 0.1)
      ..lineTo(r.right - s * 0.1, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..close();
    c.drawPath(note, _fill(colors[i]));
    // のりの部分
    c.drawRect(
      Rect.fromLTWH(r.left, r.top, r.width, s * 0.08),
      _fill(const Color(0x22000000)),
    );
    c.drawPath(note, _stroke(s * 0.025));
    c.restore();
  }
  // めくれた角
  final curl = Path()
    ..moveTo(s * 0.26, s * 0.18)
    ..lineTo(s * 0.16, s * 0.3)
    ..quadraticBezierTo(s * 0.26, s * 0.3, s * 0.26, s * 0.18);
  c.drawPath(curl, _fill(Color.lerp(body, _paper, 0.5)!));
  c.drawPath(curl, _stroke(s * 0.018));
  _face(c, Offset(s * 0.02, s * 0.02), s, gap: 0.09, mouth: 'o');
  c.restore();
  // 「！」の吹き出し
  final bob = sin(t * 6).abs() * s * 0.03;
  final b = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.center))
    ..pushStyle(
      TextStyle(
        color: const Color(0xFFC0392B),
        fontSize: s * 0.16,
        fontWeight: FontWeight.w900,
      ),
    )
    ..addText('!');
  final p = b.build()..layout(ParagraphConstraints(width: s * 0.2));
  c.drawParagraph(p, Offset(s * 0.74, s * 0.08 - bob));
}

/// 鉛筆：六角の軸にとがった芯。[short] なら削られて短くなった老兵
void _pencil(Canvas c, double s, double t, Color body, {bool short = false}) {
  _shadow(c, s, 0.4);
  final sway = sin(t * 2.4) * 0.07;
  c.save();
  c.translate(s * 0.5, s * 0.9);
  c.rotate(sway);
  final w = s * 0.24;
  final len = short ? s * 0.34 : s * 0.54;
  // 消しゴムと金具
  final eraser = Rect.fromLTWH(-w / 2, -s * 0.08, w, s * 0.08);
  c.drawRRect(
    RRect.fromRectAndCorners(
      eraser,
      bottomLeft: Radius.circular(s * 0.03),
      bottomRight: Radius.circular(s * 0.03),
    ),
    _fill(const Color(0xFFF4A6B5)),
  );
  c.drawRect(Rect.fromLTWH(-w / 2, -s * 0.14, w, s * 0.06), _fill(_metal));
  c.drawRect(Rect.fromLTWH(-w / 2, -s * 0.14, w, s * 0.06), _stroke(s * 0.02));
  // 軸（六角の面を線で）
  final shaft = Rect.fromLTWH(-w / 2, -s * 0.14 - len, w, len);
  c.drawRect(shaft, _fill(body));
  for (final x in [-w / 6, w / 6]) {
    c.drawLine(
      Offset(x, shaft.top),
      Offset(x, shaft.bottom),
      _stroke(s * 0.012, const Color(0x33000000)),
    );
  }
  c.drawRect(shaft, _stroke(s * 0.03));
  // 削った木と芯
  final cone = Path()
    ..moveTo(-w / 2, shaft.top)
    ..lineTo(0, shaft.top - s * 0.17)
    ..lineTo(w / 2, shaft.top)
    ..close();
  c.drawPath(cone, _fill(_wood));
  final lead = Path()
    ..moveTo(-w * 0.14, shaft.top - s * 0.12)
    ..lineTo(0, shaft.top - s * 0.17)
    ..lineTo(w * 0.14, shaft.top - s * 0.12)
    ..close();
  c.drawPath(lead, _fill(_graphite));
  c.drawPath(cone, _stroke(s * 0.025));
  final faceY = shaft.top + len * (short ? 0.5 : 0.32);
  _face(
    c,
    Offset(0, faceY),
    s,
    gap: 0.055,
    eye: 0.04,
    angry: !short,
    mouth: short ? 'flat' : 'smile',
  );
  if (short) {
    // 歴戦のばんそうこうと白いひげ
    c.save();
    c.translate(w * 0.2, shaft.top + s * 0.05);
    c.rotate(-0.5);
    c.drawRect(
      Rect.fromCenter(center: Offset.zero, width: s * 0.1, height: s * 0.035),
      _fill(const Color(0xFFF3D2A2)),
    );
    c.restore();
    final beard = Path()
      ..moveTo(-w * 0.35, faceY + s * 0.12)
      ..quadraticBezierTo(0, faceY + s * 0.26, w * 0.35, faceY + s * 0.12)
      ..quadraticBezierTo(0, faceY + s * 0.16, -w * 0.35, faceY + s * 0.12);
    c.drawPath(beard, _fill(_white));
    c.drawPath(beard, _stroke(s * 0.015));
  }
  // 手
  _hand(c, Offset(-w / 2 - s * 0.05, -s * 0.28), s, body);
  _hand(c, Offset(w / 2 + s * 0.05, -s * 0.3 + sin(t * 5) * s * 0.03), s, body);
  c.restore();
}

/// ボールペン・万年筆：キャップとクリップ、ペン先
void _pen(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.35);
  final float = sin(t * 3) * s * 0.03;
  c.save();
  c.translate(s * 0.5, s * 0.5 + float);
  c.rotate(0.35 + sin(t * 2) * 0.05);
  final w = s * 0.16;
  // 軸
  final barrel = RRect.fromRectAndRadius(
    Rect.fromLTWH(-w / 2, -s * 0.3, w, s * 0.62),
    Radius.circular(w / 2),
  );
  c.drawRRect(barrel, _fill(body));
  // グリップ
  c.drawRect(
    Rect.fromLTWH(-w / 2, s * 0.14, w, s * 0.12),
    _fill(const Color(0x33000000)),
  );
  c.drawRRect(barrel, _stroke(s * 0.025));
  // ペン先
  final nib = Path()
    ..moveTo(-w * 0.35, s * 0.32)
    ..lineTo(0, s * 0.44)
    ..lineTo(w * 0.35, s * 0.32)
    ..close();
  c.drawPath(nib, _fill(_metal));
  c.drawPath(nib, _stroke(s * 0.02));
  c.drawCircle(Offset(0, s * 0.44), s * 0.012, _fill(body));
  // クリップとノック
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w / 2 - s * 0.01, -s * 0.26, s * 0.03, s * 0.22),
      Radius.circular(s * 0.01),
    ),
    _fill(_metal),
  );
  c.drawRect(
    Rect.fromLTWH(-w * 0.3, -s * 0.36, w * 0.6, s * 0.07),
    _fill(_metal),
  );
  c.rotate(-0.35);
  _face(c, Offset(-s * 0.02, -s * 0.06), s, gap: 0.05, eye: 0.04, angry: true);
  c.restore();
  // インクのしずく
  final p = (t * 0.7) % 1;
  c.drawCircle(
    Offset(s * 0.33, s * 0.72 + p * s * 0.12),
    s * 0.02 * (1 - p),
    _fill(body),
  );
}

/// 定規：目盛りの入った長い板。剣のように構える
void _ruler(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.45);
  c.save();
  c.translate(s * 0.5, s * 0.88);
  c.rotate(sin(t * 2) * 0.06);
  final w = s * 0.24, h = s * 0.74;
  final r = Rect.fromLTWH(-w / 2, -h, w, h);
  c.drawRect(r, _fill(body.withValues(alpha: 0.85)));
  // 目盛り
  for (var i = 1; i < 15; i++) {
    final y = -h + h * i / 15;
    final long = i % 5 == 0;
    c.drawLine(
      Offset(-w / 2, y),
      Offset(-w / 2 + (long ? w * 0.4 : w * 0.2), y),
      _stroke(s * 0.01),
    );
  }
  c.drawRect(r, _stroke(s * 0.03));
  // ツヤ
  c.drawLine(
    Offset(w * 0.3, -h + s * 0.05),
    Offset(w * 0.3, -s * 0.05),
    _stroke(s * 0.02, const Color(0x66FFFFFF)),
  );
  _face(c, Offset(w * 0.05, -h * 0.72), s, gap: 0.05, eye: 0.04, angry: true);
  // 盾（小さな分度器）
  final shield = Path()
    ..moveTo(-w / 2 - s * 0.2, -s * 0.28)
    ..arcToPoint(
      Offset(-w / 2 - s * 0.02, -s * 0.28),
      radius: Radius.circular(s * 0.09),
    )
    ..close();
  c.drawPath(shield, _fill(const Color(0xCCE8F4FF)));
  c.drawPath(shield, _stroke(s * 0.02));
  c.restore();
}

/// 三角定規：まんなかに穴のあいた三角形。刃のように鋭い
void _triangle(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  c.save();
  c.translate(s * 0.5, s * 0.86);
  c.rotate(sin(t * 3) * 0.05);
  final tri = Path()
    ..moveTo(-s * 0.32, 0)
    ..lineTo(s * 0.32, 0)
    ..lineTo(-s * 0.32, -s * 0.66)
    ..close();
  final hole = Path()
    ..moveTo(-s * 0.2, -s * 0.1)
    ..lineTo(s * 0.02, -s * 0.1)
    ..lineTo(-s * 0.2, -s * 0.33)
    ..close();
  c.drawPath(
    Path.combine(PathOperation.difference, tri, hole),
    _fill(body.withValues(alpha: 0.85)),
  );
  for (var i = 1; i < 12; i++) {
    final x = -s * 0.32 + s * 0.64 * i / 12;
    c.drawLine(
      Offset(x, 0),
      Offset(x, -s * (i % 4 == 0 ? 0.05 : 0.03)),
      _stroke(s * 0.01),
    );
  }
  c.drawPath(tri, _stroke(s * 0.03));
  c.drawPath(hole, _stroke(s * 0.02));
  _face(
    c,
    Offset(-s * 0.2, -s * 0.44),
    s,
    gap: 0.045,
    eye: 0.035,
    angry: true,
    mouth: 'grin',
  );
  c.restore();
}

/// 分度器：半円の盾を持つ重装兵
void _protractor(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.65);
  c.save();
  c.translate(s * 0.5, s * 0.84);
  final lift = sin(t * 2) * s * 0.02;
  c.translate(0, -lift);
  final r = s * 0.4;
  final half = Path()
    ..moveTo(-r, 0)
    ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
    ..close();
  c.drawPath(half, _fill(body.withValues(alpha: 0.8)));
  // 角度の目盛り
  for (var d = 0; d <= 180; d += 10) {
    final a = pi + d * pi / 180;
    final long = d % 30 == 0;
    c.drawLine(
      Offset(cos(a) * r, sin(a) * r),
      Offset(
        cos(a) * r * (long ? 0.84 : 0.9),
        sin(a) * r * (long ? 0.84 : 0.9),
      ),
      _stroke(s * 0.01),
    );
  }
  // 内側の窓と中心
  final inner = Path()
    ..moveTo(-r * 0.45, 0)
    ..arcToPoint(Offset(r * 0.45, 0), radius: Radius.circular(r * 0.45))
    ..close();
  c.drawPath(inner, _fill(const Color(0x55FFFFFF)));
  c.drawPath(half, _stroke(s * 0.03));
  c.drawPath(inner, _stroke(s * 0.015));
  c.drawCircle(Offset.zero, s * 0.02, _fill(_ink));
  // 回る針
  final a = pi + (sin(t * 1.5) + 1) / 2 * pi;
  c.drawLine(
    Offset.zero,
    Offset(cos(a) * r * 0.8, sin(a) * r * 0.8),
    _stroke(s * 0.02, const Color(0xFFC0392B)),
  );
  _face(c, Offset(0, -r * 0.62), s, gap: 0.08, eye: 0.05);
  c.restore();
}

/// コンパス：2本の脚で歩く。針と鉛筆の脚
void _compass(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.45);
  final step = sin(t * 4);
  c.save();
  c.translate(s * 0.5, s * 0.3);
  // 脚
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.rotate(d * (0.35 + step * d * 0.12));
    final leg = Rect.fromLTWH(-s * 0.035, 0, s * 0.07, s * 0.5);
    c.drawRect(leg, _fill(_metal));
    c.drawRect(leg, _stroke(s * 0.02));
    if (d < 0) {
      c.drawLine(Offset(0, s * 0.5), Offset(0, s * 0.6), _stroke(s * 0.02));
    } else {
      final tip = Path()
        ..moveTo(-s * 0.035, s * 0.5)
        ..lineTo(0, s * 0.6)
        ..lineTo(s * 0.035, s * 0.5)
        ..close();
      c.drawPath(tip, _fill(_wood));
      c.drawPath(tip, _stroke(s * 0.015));
    }
    c.restore();
  }
  // 頭（ちょうつがい）
  c.drawCircle(Offset.zero, s * 0.15, _fill(body));
  c.drawCircle(Offset.zero, s * 0.15, _stroke(s * 0.03));
  c.drawRect(
    Rect.fromLTWH(-s * 0.03, -s * 0.24, s * 0.06, s * 0.1),
    _fill(body),
  );
  c.drawRect(
    Rect.fromLTWH(-s * 0.03, -s * 0.24, s * 0.06, s * 0.1),
    _stroke(s * 0.02),
  );
  _face(
    c,
    Offset(0, -s * 0.02),
    s,
    gap: 0.055,
    eye: 0.04,
    angry: true,
    mouth: 'flat',
  );
  c.restore();
  // 描いた円の軌跡
  c.drawArc(
    Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.9),
      width: s * 0.7,
      height: s * 0.14,
    ),
    0,
    (t % 3) / 3 * 2 * pi,
    false,
    _stroke(s * 0.012, body.withValues(alpha: 0.6)),
  );
}

/// ステープラー：口をぱくぱくさせて針を飛ばす
void _stapler(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final open = (sin(t * 3) + 1) / 2 * 0.35;
  c.save();
  c.translate(s * 0.2, s * 0.8);
  // 台
  final base = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, -s * 0.08, s * 0.62, s * 0.08),
    Radius.circular(s * 0.03),
  );
  c.drawRRect(base, _fill(_metal));
  c.drawRRect(base, _stroke(s * 0.025));
  // 上あご（うしろの支点で開く）
  c.save();
  c.translate(s * 0.04, -s * 0.1);
  c.rotate(-open);
  final top = Path()
    ..moveTo(0, 0)
    ..lineTo(s * 0.6, 0)
    ..quadraticBezierTo(s * 0.64, -s * 0.12, s * 0.5, -s * 0.16)
    ..lineTo(s * 0.05, -s * 0.16)
    ..quadraticBezierTo(-s * 0.03, -s * 0.1, 0, 0)
    ..close();
  c.drawPath(top, _fill(body));
  c.drawPath(top, _stroke(s * 0.03));
  c.drawLine(
    Offset(s * 0.1, -s * 0.12),
    Offset(s * 0.45, -s * 0.12),
    _stroke(s * 0.015, const Color(0x55FFFFFF)),
  );
  _face(
    c,
    Offset(s * 0.36, -s * 0.07),
    s,
    gap: 0.055,
    eye: 0.038,
    angry: true,
    mouth: 'flat',
  );
  c.restore();
  c.drawCircle(Offset(s * 0.04, -s * 0.1), s * 0.025, _fill(_graphite));
  c.restore();
  // 飛んでいく針
  final p = (t * 0.9) % 1;
  final x = s * (0.82 + p * 0.1);
  final y = s * (0.58 - p * 0.2);
  final staple = Path()
    ..moveTo(x, y + s * 0.03)
    ..lineTo(x, y)
    ..lineTo(x + s * 0.06, y)
    ..lineTo(x + s * 0.06, y + s * 0.03);
  c.drawPath(staple, _stroke(s * 0.012, _graphite.withValues(alpha: 1 - p)));
}

/// 蛍光ペン：太い軸と光るペン先。弱点を照らしてくる
void _marker(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final glow = (sin(t * 4) + 1) / 2;
  c.drawCircle(
    Offset(s * 0.5, s * 0.16),
    s * (0.14 + glow * 0.05),
    _fill(body.withValues(alpha: 0.25 + glow * 0.2)),
  );
  c.save();
  c.translate(s * 0.5, s * 0.88);
  c.rotate(sin(t * 2) * 0.05);
  final w = s * 0.3;
  final bodyR = RRect.fromRectAndRadius(
    Rect.fromLTWH(-w / 2, -s * 0.6, w, s * 0.6),
    Radius.circular(s * 0.06),
  );
  c.drawRRect(bodyR, _fill(Color.lerp(body, _white, 0.55)!));
  // 色つきの帯
  c.drawRect(Rect.fromLTWH(-w / 2, -s * 0.2, w, s * 0.12), _fill(body));
  c.drawRRect(bodyR, _stroke(s * 0.03));
  // キャップ部分とチゼル型のペン先
  c.drawRect(
    Rect.fromLTWH(-w * 0.35, -s * 0.66, w * 0.7, s * 0.06),
    _fill(body),
  );
  final tip = Path()
    ..moveTo(-w * 0.2, -s * 0.66)
    ..lineTo(-w * 0.2, -s * 0.72)
    ..lineTo(w * 0.2, -s * 0.78)
    ..lineTo(w * 0.2, -s * 0.66)
    ..close();
  c.drawPath(tip, _fill(body));
  c.drawPath(tip, _stroke(s * 0.02));
  _face(c, Offset(0, -s * 0.42), s, gap: 0.07, eye: 0.045, mouth: 'grin');
  c.restore();
  // 塗った跡
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.1, s * 0.82, s * 0.28 * glow + s * 0.05, s * 0.05),
      Radius.circular(s * 0.02),
    ),
    _fill(body.withValues(alpha: 0.5)),
  );
}

/// ページャー：ぱたぱたはためく紙のモンスター
void _page(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.45);
  final float = sin(t * 2.6) * s * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.5 + float);
  c.rotate(sin(t * 1.8) * 0.08);
  final w = s * 0.5, h = s * 0.62;
  final wave = sin(t * 5) * s * 0.03;
  final sheet = Path()
    ..moveTo(-w / 2, -h / 2)
    ..lineTo(w / 2 - s * 0.12, -h / 2)
    ..lineTo(w / 2, -h / 2 + s * 0.12)
    ..quadraticBezierTo(w / 2 + wave, 0, w / 2, h / 2)
    ..lineTo(-w / 2, h / 2)
    ..quadraticBezierTo(-w / 2 - wave, 0, -w / 2, -h / 2)
    ..close();
  c.drawPath(sheet, _fill(_paper));
  // 罫線と赤い余白線
  for (var i = 1; i < 7; i++) {
    final y = -h / 2 + h * i / 7;
    c.drawLine(
      Offset(-w / 2 + s * 0.02, y),
      Offset(w / 2 - s * 0.02, y),
      _stroke(s * 0.008, const Color(0xFFA9C7E8)),
    );
  }
  c.drawLine(
    Offset(-w / 2 + s * 0.08, -h / 2),
    Offset(-w / 2 + s * 0.08, h / 2),
    _stroke(s * 0.01, const Color(0xFFE8A0A8)),
  );
  // 折れた角
  final fold = Path()
    ..moveTo(w / 2 - s * 0.12, -h / 2)
    ..lineTo(w / 2 - s * 0.12, -h / 2 + s * 0.12)
    ..lineTo(w / 2, -h / 2 + s * 0.12)
    ..close();
  c.drawPath(fold, _fill(body));
  c.drawPath(fold, _stroke(s * 0.018));
  c.drawPath(sheet, _stroke(s * 0.028));
  // 落書き
  final doodle = Path()..moveTo(-w * 0.2, h * 0.3);
  for (var i = 0; i < 4; i++) {
    doodle.relativeQuadraticBezierTo(s * 0.025, -s * 0.04, s * 0.05, 0);
  }
  c.drawPath(doodle, _stroke(s * 0.015, body));
  _face(
    c,
    Offset(0, -h * 0.12),
    s,
    gap: 0.09,
    eye: 0.05,
    angry: true,
    mouth: 'o',
  );
  c.restore();
}

/// シャーペンロボ：ノックすると芯が伸びる機械のモンスター
void _mechpencil(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final knock = max(0.0, sin(t * 4)) * s * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.9);
  final w = s * 0.2;
  // 芯（下）
  c.drawLine(
    Offset(0, -s * 0.02),
    Offset(0, -s * 0.08 + knock),
    _stroke(s * 0.02, _graphite),
  );
  // 先金
  final cone = Path()
    ..moveTo(-w * 0.2, -s * 0.08)
    ..lineTo(-w / 2, -s * 0.2)
    ..lineTo(w / 2, -s * 0.2)
    ..lineTo(w * 0.2, -s * 0.08)
    ..close();
  c.drawPath(cone, _fill(_metal));
  c.drawPath(cone, _stroke(s * 0.02));
  // グリップ（ぎざぎざ）
  final grip = Rect.fromLTWH(-w / 2, -s * 0.36, w, s * 0.16);
  c.drawRect(grip, _fill(_graphite));
  for (var i = 1; i < 6; i++) {
    final y = grip.top + grip.height * i / 6;
    c.drawLine(
      Offset(-w / 2, y),
      Offset(w / 2, y),
      _stroke(s * 0.01, const Color(0x66FFFFFF)),
    );
  }
  // 軸
  final barrel = Rect.fromLTWH(-w / 2, -s * 0.74, w, s * 0.38);
  c.drawRect(barrel, _fill(body));
  c.drawRect(barrel, _stroke(s * 0.025));
  c.drawRect(grip, _stroke(s * 0.025));
  // クリップ
  c.drawRect(
    Rect.fromLTWH(w / 2 - s * 0.005, -s * 0.72, s * 0.035, s * 0.2),
    _fill(_metal),
  );
  // ノックボタン
  c.drawRect(
    Rect.fromLTWH(-w * 0.3, -s * 0.8 + knock, w * 0.6, s * 0.07),
    _fill(_metal),
  );
  c.drawRect(
    Rect.fromLTWH(-w * 0.3, -s * 0.8 + knock, w * 0.6, s * 0.07),
    _stroke(s * 0.018),
  );
  // ロボの目（光る四角）
  final eye = _fill(const Color(0xFF7FE3FF));
  for (final d in [-1.0, 1.0]) {
    final r = Rect.fromCenter(
      center: Offset(d * s * 0.045, -s * 0.6),
      width: s * 0.05,
      height: s * 0.035,
    );
    c.drawRect(r, eye);
    c.drawRect(r, _stroke(s * 0.012));
  }
  c.drawLine(
    Offset(-s * 0.04, -s * 0.52),
    Offset(s * 0.04, -s * 0.52),
    _stroke(s * 0.015),
  );
  // アーム
  for (final d in [-1.0, 1.0]) {
    final a = Offset(d * w / 2, -s * 0.5);
    final b = Offset(
      d * (w / 2 + s * 0.1),
      -s * 0.44 + sin(t * 5 + d) * s * 0.03,
    );
    c.drawLine(a, b, _stroke(s * 0.02, _metal));
    _hand(c, b, s, _metal);
  }
  c.restore();
}

/// はさみ：刃をしゃきしゃき鳴らす双剣士。持ち手の輪が目
void _scissors(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.45);
  final open = 0.32 + (sin(t * 5) + 1) / 2 * 0.22;
  const ringDist = 0.24;
  c.save();
  c.translate(s * 0.5, s * 0.46);
  for (final d in [-1.0, 1.0]) {
    final a = d * open;
    c.save();
    c.rotate(a);
    // 刃（上へ）
    final blade = Path()
      ..moveTo(-s * 0.05, s * 0.02)
      ..quadraticBezierTo(-s * 0.04, -s * 0.25, 0, -s * 0.4)
      ..quadraticBezierTo(s * 0.03, -s * 0.2, s * 0.03, s * 0.02)
      ..close();
    c.drawPath(blade, _fill(_metal));
    c.drawLine(
      Offset(-s * 0.01, -s * 0.05),
      Offset(0, -s * 0.33),
      _stroke(s * 0.01, const Color(0x88FFFFFF)),
    );
    c.drawPath(blade, _stroke(s * 0.02));
    // 持ち手の輪（刃と反対の下側）
    final ring = Rect.fromCenter(
      center: Offset(0, s * ringDist),
      width: s * 0.2,
      height: s * 0.2,
    );
    c.drawLine(
      Offset.zero,
      Offset(0, s * (ringDist - 0.1)),
      _stroke(s * 0.05, body),
    );
    c.drawOval(ring, _stroke(s * 0.055, body));
    c.drawOval(ring.inflate(s * 0.028), _stroke(s * 0.012));
    c.drawOval(ring.deflate(s * 0.028), _stroke(s * 0.012));
    c.restore();
    // 輪の中の目（刃と同じだけ回した位置）
    final eye = Offset(-sin(a) * s * ringDist, cos(a) * s * ringDist);
    c.drawCircle(eye, s * 0.04, _fill(_white));
    c.drawCircle(eye, s * 0.04, _stroke(s * 0.012));
    c.drawCircle(eye + Offset(0, s * 0.01), s * 0.02, _fill(_ink));
  }
  c.drawCircle(Offset.zero, s * 0.03, _fill(_graphite));
  c.drawCircle(Offset.zero, s * 0.03, _stroke(s * 0.012));
  c.restore();
}

/// バインダーゴーレム：リングでとじた分厚いファイル
void _binder(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.65);
  final stomp = sin(t * 3).abs() * s * 0.025;
  c.save();
  c.translate(s * 0.5, s * 0.88 - stomp);
  final cover = RRect.fromRectAndRadius(
    Rect.fromLTWH(-s * 0.3, -s * 0.66, s * 0.6, s * 0.62),
    Radius.circular(s * 0.04),
  );
  // うしろの紙
  c.drawRect(
    Rect.fromLTWH(-s * 0.26, -s * 0.7, s * 0.54, s * 0.62),
    _fill(_paper),
  );
  c.drawRect(
    Rect.fromLTWH(-s * 0.26, -s * 0.7, s * 0.54, s * 0.62),
    _stroke(s * 0.015),
  );
  c.drawRRect(cover, _fill(body));
  c.drawRRect(cover, _stroke(s * 0.03));
  // 背とリング
  c.drawRect(
    Rect.fromLTWH(-s * 0.3, -s * 0.66, s * 0.08, s * 0.62),
    _fill(const Color(0x33000000)),
  );
  for (final y in [-0.56, -0.36, -0.16]) {
    c.drawArc(
      Rect.fromCenter(
        center: Offset(-s * 0.26, y * s),
        width: s * 0.12,
        height: s * 0.08,
      ),
      pi / 2,
      pi * 1.5,
      false,
      _stroke(s * 0.025, _metal),
    );
  }
  // ラベル
  final label = Rect.fromLTWH(-s * 0.1, -s * 0.6, s * 0.3, s * 0.1);
  c.drawRect(label, _fill(_paper));
  c.drawRect(label, _stroke(s * 0.015));
  _face(
    c,
    Offset(s * 0.05, -s * 0.34),
    s,
    gap: 0.09,
    eye: 0.05,
    angry: true,
    mouth: 'flat',
  );
  // 腕
  for (final d in [-1.0, 1.0]) {
    _hand(
      c,
      Offset(d * s * 0.36, -s * 0.24 + sin(t * 3 + d) * s * 0.02),
      s * 1.4,
      body,
    );
  }
  c.restore();
}

/// 教科書（ブック・ゴーレム）：ページを翼のように広げて浮かぶ本
void _book(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  final float = sin(t * 2.2) * s * 0.04;
  final flap = sin(t * 4) * 0.15;
  c.save();
  c.translate(s * 0.5, s * 0.52 + float);
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.scale(d, 1);
    c.rotate(-flap);
    // 表紙
    final coverP = Path()
      ..moveTo(0, -s * 0.2)
      ..lineTo(s * 0.4, -s * 0.28)
      ..lineTo(s * 0.4, s * 0.16)
      ..lineTo(0, s * 0.22)
      ..close();
    c.drawPath(coverP, _fill(body));
    c.drawPath(coverP, _stroke(s * 0.025));
    // ページ
    final pageP = Path()
      ..moveTo(0, -s * 0.17)
      ..quadraticBezierTo(s * 0.18, -s * 0.26, s * 0.36, -s * 0.24)
      ..lineTo(s * 0.36, s * 0.13)
      ..quadraticBezierTo(s * 0.18, s * 0.11, 0, s * 0.19)
      ..close();
    c.drawPath(pageP, _fill(_paper));
    for (var i = 0; i < 4; i++) {
      final y = -s * 0.14 + i * s * 0.07;
      c.drawLine(
        Offset(s * 0.06, y),
        Offset(s * 0.3, y - s * 0.03),
        _stroke(s * 0.01, const Color(0xFF9E9E9E)),
      );
    }
    c.drawPath(pageP, _stroke(s * 0.02));
    c.restore();
  }
  // しおりのひも
  c.drawLine(
    Offset(0, s * 0.2),
    Offset(s * 0.02, s * 0.34),
    _stroke(s * 0.02, const Color(0xFFC0392B)),
  );
  _face(
    c,
    Offset(0, -s * 0.04),
    s,
    gap: 0.09,
    eye: 0.05,
    angry: true,
    mouth: 'grin',
  );
  c.restore();
}
