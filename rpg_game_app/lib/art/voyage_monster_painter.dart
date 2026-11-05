part of 'enemy_painter.dart';

// 定期テストの海・模擬試験の空の魔物（色鉛筆の落書き風）

Color _lighten(Color c, [double k = 0.35]) => Color.lerp(c, _white, k)!;
Color _darken(Color c, [double k = 0.3]) =>
    Color.lerp(c, const Color(0xFF000000), k)!;

/// うっかりクラゲ：ふわふわ上下して、触手がゆれる
void _jellyfish(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.35);
  final float = sin(t * 2.4) * s * 0.05;
  c.save();
  c.translate(0, float);
  // 触手
  for (var i = 0; i < 5; i++) {
    final x = s * (0.3 + i * 0.1);
    final p = Path()..moveTo(x, s * 0.52);
    for (var k = 1; k <= 4; k++) {
      p.quadraticBezierTo(
        x + sin(t * 4 + i + k) * s * 0.05,
        s * (0.52 + k * 0.06),
        x + sin(t * 4 + i + k + 1) * s * 0.03,
        s * (0.55 + k * 0.08),
      );
    }
    c.drawPath(p, _stroke(s * 0.02, _darken(body, 0.15)));
  }
  // かさ
  final bell = Path()
    ..moveTo(s * 0.2, s * 0.55)
    ..quadraticBezierTo(s * 0.2, s * 0.18, s * 0.5, s * 0.18)
    ..quadraticBezierTo(s * 0.8, s * 0.18, s * 0.8, s * 0.55)
    ..quadraticBezierTo(s * 0.5, s * 0.48, s * 0.2, s * 0.55)
    ..close();
  c.drawPath(bell, _fill(body.withValues(alpha: 0.85)));
  c.drawPath(bell, _stroke(s * 0.025));
  c.drawOval(
    Rect.fromLTWH(s * 0.32, s * 0.24, s * 0.14, s * 0.07),
    _fill(const Color(0x88FFFFFF)),
  );
  _eyes(c, Offset(s * 0.42, s * 0.4), Offset(s * 0.58, s * 0.4), s, size: 0.05);
  // ぼんやり口
  c.drawArc(
    Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.47),
      width: s * 0.08,
      height: s * 0.04,
    ),
    0,
    pi,
    false,
    _stroke(s * 0.015),
  );
  c.restore();
}

/// ひっかけガニ：横にゆれて、はさみをちょきちょき
void _crab(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.7);
  final sway = sin(t * 3) * s * 0.03;
  final snip = (sin(t * 6) + 1) / 2 * 0.35;
  c.save();
  c.translate(sway, 0);
  // あし
  for (final d in [-1.0, 1.0]) {
    for (var i = 0; i < 3; i++) {
      final y = s * (0.66 + i * 0.05);
      c.drawLine(
        Offset(s * 0.5 + d * s * 0.2, y),
        Offset(s * 0.5 + d * s * (0.36 + i * 0.03), y + s * 0.12),
        _stroke(s * 0.025, _darken(body)),
      );
    }
  }
  // はさみ
  for (final d in [-1.0, 1.0]) {
    final base = Offset(s * 0.5 + d * s * 0.3, s * 0.38);
    c.drawLine(
      Offset(s * 0.5 + d * s * 0.2, s * 0.58),
      base,
      _stroke(s * 0.04, body),
    );
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(d, 1);
    final upper = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(s * 0.02, -s * 0.2, s * 0.14, -s * 0.16)
      ..lineTo(s * 0.04, -s * 0.02)
      ..close();
    c.save();
    c.rotate(-snip);
    c.drawPath(upper, _fill(body));
    c.drawPath(upper, _stroke(s * 0.02));
    c.restore();
    final lower = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(s * 0.1, s * 0.02, s * 0.14, -s * 0.08)
      ..lineTo(s * 0.03, -s * 0.03)
      ..close();
    c.drawPath(lower, _fill(body));
    c.drawPath(lower, _stroke(s * 0.02));
    c.restore();
  }
  // こうら
  final shell = Rect.fromLTWH(s * 0.24, s * 0.48, s * 0.52, s * 0.28);
  c.drawOval(shell, _fill(body));
  c.drawOval(
    Rect.fromLTWH(s * 0.32, s * 0.52, s * 0.18, s * 0.07),
    _fill(_lighten(body)),
  );
  c.drawOval(shell, _stroke(s * 0.025));
  // 目（棒の先）
  for (final d in [-1.0, 1.0]) {
    c.drawLine(
      Offset(s * 0.5 + d * s * 0.07, s * 0.5),
      Offset(s * 0.5 + d * s * 0.09, s * 0.4),
      _stroke(s * 0.02),
    );
  }
  _eyes(
    c,
    Offset(s * 0.41, s * 0.39),
    Offset(s * 0.59, s * 0.39),
    s,
    size: 0.045,
    angry: true,
  );
  c.restore();
}

/// ふくれっつらフグ：ぷくっとふくらんだり、しぼんだり
void _puffer(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  final puff = 1 + (sin(t * 2) + 1) / 2 * 0.18;
  c.save();
  c.translate(s * 0.5, s * 0.5);
  c.scale(puff);
  final r = s * 0.24;
  // トゲ
  for (var i = 0; i < 14; i++) {
    final a = i / 14 * 2 * pi;
    c.drawLine(
      Offset(cos(a) * r * 0.95, sin(a) * r * 0.95),
      Offset(cos(a) * r * 1.25, sin(a) * r * 1.25),
      _stroke(s * 0.02),
    );
  }
  // ひれ・しっぽ
  final tail = Path()
    ..moveTo(-r * 0.9, 0)
    ..lineTo(-r * 1.4, -r * 0.35)
    ..lineTo(-r * 1.4, r * 0.35)
    ..close();
  c.drawPath(tail, _fill(_darken(body, 0.1)));
  c.drawPath(tail, _stroke(s * 0.02));
  c.drawCircle(Offset.zero, r, _fill(body));
  // おなか
  c.drawArc(
    Rect.fromCircle(center: Offset.zero, radius: r),
    0.2,
    pi - 0.4,
    true,
    _fill(_lighten(body, 0.6)),
  );
  // 斑点
  for (final p in [
    Offset(-r * 0.3, -r * 0.5),
    Offset(r * 0.1, -r * 0.65),
    Offset(-r * 0.6, -r * 0.1),
  ]) {
    c.drawCircle(p, r * 0.08, _fill(_darken(body, 0.35)));
  }
  c.drawCircle(Offset.zero, r, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(r * 0.15, -r * 0.2),
    Offset(r * 0.6, -r * 0.2),
    s,
    size: 0.05,
    angry: true,
  );
  // ふくれた口
  c.drawCircle(
    Offset(r * 0.85, r * 0.2),
    r * 0.1,
    _fill(const Color(0xFFE57373)),
  );
  c.drawCircle(Offset(r * 0.85, r * 0.2), r * 0.1, _stroke(s * 0.015));
  c.restore();
}

/// 赤点ザメ：水面を泳ぐように左右へゆれる
void _shark(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.7);
  final swim = sin(t * 3) * s * 0.03;
  c.save();
  c.translate(swim, 0);
  // 尾びれ
  final tail = Path()
    ..moveTo(s * 0.2, s * 0.56)
    ..lineTo(s * 0.04, s * 0.38 + sin(t * 6) * s * 0.03)
    ..lineTo(s * 0.1, s * 0.58)
    ..lineTo(s * 0.04, s * 0.76 + sin(t * 6) * s * 0.03)
    ..close();
  c.drawPath(tail, _fill(body));
  c.drawPath(tail, _stroke(s * 0.025));
  // 背びれ
  final fin = Path()
    ..moveTo(s * 0.42, s * 0.42)
    ..lineTo(s * 0.5, s * 0.2)
    ..lineTo(s * 0.6, s * 0.43)
    ..close();
  c.drawPath(fin, _fill(body));
  c.drawPath(fin, _stroke(s * 0.025));
  // 体
  final b = Path()
    ..moveTo(s * 0.16, s * 0.57)
    ..quadraticBezierTo(s * 0.4, s * 0.36, s * 0.78, s * 0.44)
    ..quadraticBezierTo(s * 0.96, s * 0.5, s * 0.92, s * 0.6)
    ..quadraticBezierTo(s * 0.6, s * 0.76, s * 0.16, s * 0.57)
    ..close();
  c.drawPath(b, _fill(body));
  // おなか
  final belly = Path()
    ..moveTo(s * 0.3, s * 0.62)
    ..quadraticBezierTo(s * 0.6, s * 0.72, s * 0.9, s * 0.6)
    ..quadraticBezierTo(s * 0.6, s * 0.64, s * 0.3, s * 0.62)
    ..close();
  c.drawPath(belly, _fill(_lighten(body, 0.7)));
  c.drawPath(b, _stroke(s * 0.025));
  // えら
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(s * (0.6 + i * 0.04), s * 0.5),
      Offset(s * (0.58 + i * 0.04), s * 0.58),
      _stroke(s * 0.012),
    );
  }
  _eyes(
    c,
    Offset(s * 0.78, s * 0.5),
    Offset(s * 0.78, s * 0.5),
    s,
    size: 0.035,
    angry: true,
  );
  // 歯
  final teeth = Path()..moveTo(s * 0.74, s * 0.6);
  for (var i = 0; i < 4; i++) {
    teeth
      ..lineTo(s * (0.76 + i * 0.035), s * 0.64)
      ..lineTo(s * (0.775 + i * 0.035), s * 0.6);
  }
  c.drawPath(teeth, _stroke(s * 0.012));
  // 赤点の「赤」マーク
  c.drawCircle(
    Offset(s * 0.42, s * 0.54),
    s * 0.04,
    _fill(const Color(0xFFD64545)),
  );
  c.restore();
}

/// 暗記ダコ：8本の足がうねうね動く
void _octopus(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final bob = sin(t * 2) * s * 0.03;
  c.save();
  c.translate(0, bob);
  for (var i = 0; i < 8; i++) {
    final x = s * (0.24 + i * 0.075);
    final p = Path()..moveTo(x, s * 0.52);
    p.cubicTo(
      x + sin(t * 3 + i) * s * 0.08,
      s * 0.66,
      x - sin(t * 3 + i) * s * 0.08,
      s * 0.76,
      x + sin(t * 3 + i + 1) * s * 0.06,
      s * 0.88,
    );
    c.drawPath(p, _stroke(s * 0.05, body));
    c.drawPath(p, _stroke(s * 0.012, _darken(body)));
  }
  final head = Rect.fromLTWH(s * 0.24, s * 0.12, s * 0.52, s * 0.46);
  c.drawOval(head, _fill(body));
  c.drawOval(
    Rect.fromLTWH(s * 0.34, s * 0.18, s * 0.14, s * 0.08),
    _fill(_lighten(body)),
  );
  c.drawOval(head, _stroke(s * 0.025));
  // はちまき（暗記のしるし）
  c.drawLine(
    Offset(s * 0.26, s * 0.3),
    Offset(s * 0.74, s * 0.3),
    _stroke(s * 0.035, _white),
  );
  _eyes(
    c,
    Offset(s * 0.42, s * 0.41),
    Offset(s * 0.58, s * 0.41),
    s,
    size: 0.05,
  );
  c.drawCircle(Offset(s * 0.5, s * 0.5), s * 0.03, _stroke(s * 0.02));
  c.restore();
}

/// 深海アンコウ：ちょうちんが光る
void _angler(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final glow = (sin(t * 3) + 1) / 2;
  // ちょうちんの光
  final lamp = Offset(s * 0.74, s * 0.18);
  c.drawCircle(
    lamp,
    s * (0.1 + glow * 0.04),
    _fill(Color.fromRGBO(255, 245, 157, 0.3 + glow * 0.3)),
  );
  final rod = Path()
    ..moveTo(s * 0.46, s * 0.3)
    ..quadraticBezierTo(s * 0.6, s * 0.02, lamp.dx, lamp.dy);
  c.drawPath(rod, _stroke(s * 0.02));
  c.drawCircle(lamp, s * 0.05, _fill(const Color(0xFFFFF59D)));
  c.drawCircle(lamp, s * 0.05, _stroke(s * 0.015));
  // 体
  final b = Path()
    ..moveTo(s * 0.14, s * 0.56)
    ..quadraticBezierTo(s * 0.24, s * 0.28, s * 0.54, s * 0.3)
    ..quadraticBezierTo(s * 0.86, s * 0.34, s * 0.88, s * 0.6)
    ..quadraticBezierTo(s * 0.7, s * 0.86, s * 0.34, s * 0.8)
    ..quadraticBezierTo(s * 0.16, s * 0.74, s * 0.14, s * 0.56)
    ..close();
  c.drawPath(b, _fill(body));
  c.drawPath(b, _stroke(s * 0.025));
  // 大きな口と歯
  final mouth = Path()
    ..moveTo(s * 0.5, s * 0.62)
    ..quadraticBezierTo(s * 0.7, s * 0.74, s * 0.88, s * 0.6);
  c.drawPath(mouth, _stroke(s * 0.025));
  for (var i = 0; i < 5; i++) {
    final x = s * (0.55 + i * 0.07);
    c.drawPath(
      Path()
        ..moveTo(x, s * (0.64 + (i == 0 || i == 4 ? -0.01 : 0.02)))
        ..lineTo(x + s * 0.02, s * 0.6)
        ..lineTo(x + s * 0.04, s * (0.65 + (i == 4 ? -0.03 : 0.01)))
        ..close(),
      _fill(_white),
    );
  }
  // しっぽ
  c.drawPath(
    Path()
      ..moveTo(s * 0.16, s * 0.56)
      ..lineTo(s * 0.02, s * 0.44)
      ..lineTo(s * 0.04, s * 0.7)
      ..close(),
    _fill(_darken(body, 0.2)),
  );
  _eyes(
    c,
    Offset(s * 0.62, s * 0.44),
    Offset(s * 0.62, s * 0.44),
    s,
    size: 0.05,
    white: const Color(0xFFFFF59D),
  );
}

/// ダイオウ難問イカ：長い触手をくねらせる
void _squid(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  final bob = sin(t * 1.6) * s * 0.03;
  c.save();
  c.translate(0, bob);
  // 触手（2本は長い）
  for (var i = 0; i < 8; i++) {
    final x = s * (0.34 + i * 0.045);
    final long = i == 1 || i == 6;
    final p = Path()..moveTo(x, s * 0.58);
    p.cubicTo(
      x + sin(t * 2.5 + i) * s * 0.1,
      s * 0.72,
      x - sin(t * 2.5 + i) * s * 0.1,
      s * 0.8,
      x + (long ? (i == 1 ? -s * 0.25 : s * 0.25) : 0),
      s * (long ? 0.94 : 0.86),
    );
    c.drawPath(p, _stroke(s * (long ? 0.03 : 0.035), body));
  }
  // 胴（上向きの三角の頭）
  final mantle = Path()
    ..moveTo(s * 0.5, s * 0.04)
    ..quadraticBezierTo(s * 0.72, s * 0.3, s * 0.68, s * 0.6)
    ..lineTo(s * 0.32, s * 0.6)
    ..quadraticBezierTo(s * 0.28, s * 0.3, s * 0.5, s * 0.04)
    ..close();
  c.drawPath(mantle, _fill(body));
  // ひれ
  for (final d in [-1.0, 1.0]) {
    c.drawPath(
      Path()
        ..moveTo(s * 0.5 + d * s * 0.08, s * 0.12)
        ..lineTo(s * 0.5 + d * s * 0.26, s * 0.2)
        ..lineTo(s * 0.5 + d * s * 0.14, s * 0.3)
        ..close(),
      _fill(_darken(body, 0.1)),
    );
  }
  c.drawPath(mantle, _stroke(s * 0.025));
  // 斑点
  for (final p in [
    Offset(s * 0.46, s * 0.28),
    Offset(s * 0.56, s * 0.36),
    Offset(s * 0.44, s * 0.44),
  ]) {
    c.drawCircle(p, s * 0.018, _fill(_darken(body, 0.3)));
  }
  _eyes(
    c,
    Offset(s * 0.4, s * 0.52),
    Offset(s * 0.6, s * 0.52),
    s,
    size: 0.06,
    angry: true,
  );
  c.restore();
}

/// 範囲の海竜リヴァイアサン：波間から首をもたげる
void _leviathan(Canvas c, double s, double t, Color body) {
  final sway = sin(t * 1.5) * s * 0.03;
  // 波
  final wave = Path()..moveTo(0, s * 0.8);
  for (var i = 0; i <= 8; i++) {
    wave.quadraticBezierTo(
      s * (i / 8 + 1 / 16),
      s * (0.74 + 0.02 * sin(t * 3 + i)),
      s * ((i + 1) / 8),
      s * 0.8,
    );
  }
  wave
    ..lineTo(s, s)
    ..lineTo(0, s)
    ..close();
  // 背中のこぶ
  for (final x in [0.16, 0.34]) {
    c.drawArc(
      Rect.fromCenter(
        center: Offset(s * x, s * 0.8),
        width: s * 0.16,
        height: s * 0.2,
      ),
      pi,
      pi,
      true,
      _fill(body),
    );
    c.drawArc(
      Rect.fromCenter(
        center: Offset(s * x, s * 0.8),
        width: s * 0.16,
        height: s * 0.2,
      ),
      pi,
      pi,
      false,
      _stroke(s * 0.02),
    );
  }
  // 首
  final neck = Path()
    ..moveTo(s * 0.5, s * 0.82)
    ..quadraticBezierTo(s * 0.52 + sway, s * 0.4, s * 0.64 + sway, s * 0.26)
    ..lineTo(s * 0.78 + sway, s * 0.32)
    ..quadraticBezierTo(s * 0.7 + sway, s * 0.5, s * 0.72, s * 0.82)
    ..close();
  c.drawPath(neck, _fill(body));
  c.drawPath(neck, _stroke(s * 0.025));
  // たてがみ（背びれ）
  for (var i = 0; i < 4; i++) {
    final y = s * (0.66 - i * 0.1);
    final x = s * (0.5 + i * 0.03) + sway * i / 3;
    c.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x - s * 0.08, y - s * 0.03)
        ..lineTo(x, y - s * 0.07)
        ..close(),
      _fill(_lighten(body, 0.4)),
    );
  }
  // 頭
  final head = Path()
    ..moveTo(s * 0.6 + sway, s * 0.28)
    ..quadraticBezierTo(s * 0.66 + sway, s * 0.12, s * 0.8 + sway, s * 0.14)
    ..lineTo(s * 0.96 + sway, s * 0.22)
    ..lineTo(s * 0.8 + sway, s * 0.34)
    ..close();
  c.drawPath(head, _fill(body));
  c.drawPath(head, _stroke(s * 0.025));
  // 角
  c.drawLine(
    Offset(s * 0.68 + sway, s * 0.15),
    Offset(s * 0.62 + sway, s * 0.04),
    _stroke(s * 0.025, const Color(0xFFF2B84B)),
  );
  _eyes(
    c,
    Offset(s * 0.76 + sway, s * 0.2),
    Offset(s * 0.76 + sway, s * 0.2),
    s,
    size: 0.04,
    white: const Color(0xFFFFE082),
    angry: true,
  );
  c.drawPath(wave, _fill(const Color(0xCC5FA8CC)));
  c.drawPath(wave, _stroke(s * 0.02, const Color(0xFF2F5D7C)));
}

/// 雨雲ぼうず：頭の上から雨がふる
void _cloudling(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final float = sin(t * 2) * s * 0.04;
  // 雨
  for (var i = 0; i < 6; i++) {
    final p = (t * 1.5 + i / 6) % 1;
    final x = s * (0.28 + i * 0.09);
    final y = s * (0.62 + p * 0.28);
    c.drawLine(
      Offset(x, y),
      Offset(x - s * 0.015, y + s * 0.05),
      _stroke(s * 0.015, const Color(0xFF64B5F6)),
    );
  }
  c.save();
  c.translate(0, float);
  Path oval(Offset o, double r) =>
      Path()..addOval(Rect.fromCircle(center: o, radius: r));
  var cloud = Path.combine(
    PathOperation.union,
    oval(Offset(s * 0.34, s * 0.5), s * 0.15),
    oval(Offset(s * 0.66, s * 0.5), s * 0.15),
  );
  cloud = Path.combine(
    PathOperation.union,
    cloud,
    oval(Offset(s * 0.5, s * 0.38), s * 0.2),
  );
  cloud = Path.combine(
    PathOperation.union,
    cloud,
    Path()..addRect(Rect.fromLTWH(s * 0.34, s * 0.45, s * 0.32, s * 0.2)),
  );
  c.drawPath(cloud, _fill(body));
  c.drawPath(cloud, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(s * 0.43, s * 0.45),
    Offset(s * 0.57, s * 0.45),
    s,
    size: 0.045,
  );
  // なみだ
  c.drawCircle(
    Offset(s * 0.38, s * 0.53),
    s * 0.02,
    _fill(const Color(0xFF64B5F6)),
  );
  c.drawArc(
    Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.56),
      width: s * 0.08,
      height: s * 0.05,
    ),
    pi,
    pi,
    false,
    _stroke(s * 0.015),
  );
  c.restore();
}

/// 偏差値ガラス：はばたきながら、数字をくわえている
void _bird(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final flap = sin(t * 9) * 0.5;
  final float = sin(t * 3) * s * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.46 + float);
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.scale(d, 1);
    c.rotate(-flap);
    final w = Path()
      ..moveTo(s * 0.06, -s * 0.02)
      ..quadraticBezierTo(s * 0.26, -s * 0.22, s * 0.44, -s * 0.12)
      ..lineTo(s * 0.36, -s * 0.06)
      ..lineTo(s * 0.4, 0)
      ..lineTo(s * 0.3, s * 0.02)
      ..lineTo(s * 0.32, s * 0.08)
      ..quadraticBezierTo(s * 0.14, s * 0.08, s * 0.06, s * 0.06)
      ..close();
    c.drawPath(w, _fill(_darken(body, 0.1)));
    c.drawPath(w, _stroke(s * 0.02));
    c.restore();
  }
  c.drawOval(
    Rect.fromCenter(
      center: Offset(0, s * 0.04),
      width: s * 0.28,
      height: s * 0.32,
    ),
    _fill(body),
  );
  c.drawOval(
    Rect.fromCenter(
      center: Offset(0, s * 0.04),
      width: s * 0.28,
      height: s * 0.32,
    ),
    _stroke(s * 0.025),
  );
  // くちばし
  c.drawPath(
    Path()
      ..moveTo(-s * 0.04, -s * 0.02)
      ..lineTo(0, s * 0.08)
      ..lineTo(s * 0.04, -s * 0.02)
      ..close(),
    _fill(const Color(0xFFF2B84B)),
  );
  _eyes(
    c,
    Offset(-s * 0.06, -s * 0.06),
    Offset(s * 0.06, -s * 0.06),
    s,
    size: 0.035,
    angry: true,
  );
  // 数字の札
  c.drawRect(
    Rect.fromCenter(
      center: Offset(0, s * 0.2),
      width: s * 0.16,
      height: s * 0.09,
    ),
    _fill(_white),
  );
  c.drawRect(
    Rect.fromCenter(
      center: Offset(0, s * 0.2),
      width: s * 0.16,
      height: s * 0.09,
    ),
    _stroke(s * 0.012),
  );
  c.drawLine(
    Offset(-s * 0.04, s * 0.2),
    Offset(s * 0.04, s * 0.2),
    _stroke(s * 0.015, const Color(0xFFD64545)),
  );
  c.restore();
}

/// 雷鳴のカミナリ玉：ばちばち光る
void _thunder(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final flash = sin(t * 12) > 0.6;
  final center = Offset(s * 0.5, s * 0.46 + sin(t * 2.5) * s * 0.03);
  if (flash) {
    c.drawCircle(center, s * 0.34, _fill(const Color(0x33FFF176)));
  }
  // 稲妻
  for (var i = 0; i < 4; i++) {
    final a = i / 4 * 2 * pi + t;
    final p = Path()
      ..moveTo(center.dx + cos(a) * s * 0.2, center.dy + sin(a) * s * 0.2)
      ..lineTo(
        center.dx + cos(a + 0.2) * s * 0.3,
        center.dy + sin(a + 0.2) * s * 0.3,
      )
      ..lineTo(
        center.dx + cos(a - 0.1) * s * 0.34,
        center.dy + sin(a - 0.1) * s * 0.34,
      )
      ..lineTo(
        center.dx + cos(a + 0.1) * s * 0.44,
        center.dy + sin(a + 0.1) * s * 0.44,
      );
    c.drawPath(p, _stroke(s * 0.02, const Color(0xFFFFB300)));
  }
  c.drawCircle(center, s * 0.22, _fill(body));
  c.drawCircle(
    center + Offset(-s * 0.07, -s * 0.08),
    s * 0.05,
    _fill(_lighten(body, 0.6)),
  );
  c.drawCircle(center, s * 0.22, _stroke(s * 0.025));
  _eyes(
    c,
    center + Offset(-s * 0.08, 0),
    center + Offset(s * 0.08, 0),
    s,
    size: 0.05,
    angry: true,
  );
  // ぎざぎざの口
  final m = Path()..moveTo(center.dx - s * 0.08, center.dy + s * 0.1);
  for (var i = 0; i < 4; i++) {
    m.lineTo(
      center.dx - s * 0.06 + i * s * 0.04,
      center.dy + s * (i.isEven ? 0.07 : 0.11),
    );
  }
  c.drawPath(m, _stroke(s * 0.018));
}

/// 模試ワイバーン：大きなつばさで羽ばたく
void _wyvern(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final flap = sin(t * 4) * 0.35;
  final float = sin(t * 2) * s * 0.03;
  c.save();
  c.translate(0, float);
  // つばさ
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.translate(s * 0.5, s * 0.42);
    c.scale(d, 1);
    c.rotate(-flap);
    final w = Path()
      ..moveTo(0, 0)
      ..lineTo(s * 0.44, -s * 0.28)
      ..lineTo(s * 0.4, -s * 0.04)
      ..lineTo(s * 0.32, s * 0.02)
      ..lineTo(s * 0.26, -s * 0.02)
      ..lineTo(s * 0.18, s * 0.06)
      ..close();
    c.drawPath(w, _fill(_lighten(body, 0.25)));
    c.drawLine(
      Offset.zero,
      Offset(s * 0.44, -s * 0.28),
      _stroke(s * 0.025, _darken(body)),
    );
    c.drawPath(w, _stroke(s * 0.02));
    c.restore();
  }
  // しっぽ
  final tail = Path()
    ..moveTo(s * 0.46, s * 0.62)
    ..quadraticBezierTo(s * 0.3, s * 0.86, s * 0.14, s * 0.8);
  c.drawPath(tail, _stroke(s * 0.05, body));
  c.drawPath(
    Path()
      ..moveTo(s * 0.14, s * 0.74)
      ..lineTo(s * 0.06, s * 0.8)
      ..lineTo(s * 0.14, s * 0.86)
      ..close(),
    _fill(_darken(body)),
  );
  // 体
  c.drawOval(Rect.fromLTWH(s * 0.38, s * 0.38, s * 0.24, s * 0.3), _fill(body));
  c.drawOval(
    Rect.fromLTWH(s * 0.38, s * 0.38, s * 0.24, s * 0.3),
    _stroke(s * 0.025),
  );
  // 首と頭
  c.drawLine(
    Offset(s * 0.52, s * 0.42),
    Offset(s * 0.6, s * 0.26),
    _stroke(s * 0.07, body),
  );
  final head = Path()
    ..moveTo(s * 0.54, s * 0.2)
    ..lineTo(s * 0.8, s * 0.24)
    ..lineTo(s * 0.62, s * 0.32)
    ..close();
  c.drawPath(head, _fill(body));
  c.drawPath(head, _stroke(s * 0.02));
  c.drawLine(
    Offset(s * 0.56, s * 0.21),
    Offset(s * 0.5, s * 0.12),
    _stroke(s * 0.02),
  );
  _eyes(
    c,
    Offset(s * 0.63, s * 0.24),
    Offset(s * 0.63, s * 0.24),
    s,
    size: 0.03,
    white: const Color(0xFFFFE082),
    angry: true,
  );
  c.restore();
}

/// 隕石ゴーレム：燃えながらゆっくり回る岩
void _meteor(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  // 炎の尾
  for (var i = 0; i < 3; i++) {
    final len = s * (0.3 + 0.05 * sin(t * 10 + i));
    c.drawPath(
      Path()
        ..moveTo(s * 0.4, s * (0.34 + i * 0.1))
        ..lineTo(s * 0.4 - len, s * (0.2 + i * 0.1))
        ..lineTo(s * 0.46, s * (0.4 + i * 0.1))
        ..close(),
      _fill(
        [
          const Color(0xFFFF7043),
          const Color(0xFFFFA726),
          const Color(0xFFFFE082),
        ][i],
      ),
    );
  }
  c.save();
  c.translate(s * 0.56, s * 0.52);
  c.rotate(sin(t) * 0.15);
  final rock = Path()
    ..moveTo(-s * 0.24, -s * 0.04)
    ..lineTo(-s * 0.14, -s * 0.24)
    ..lineTo(s * 0.1, -s * 0.26)
    ..lineTo(s * 0.26, -s * 0.06)
    ..lineTo(s * 0.2, s * 0.2)
    ..lineTo(-s * 0.06, s * 0.26)
    ..lineTo(-s * 0.22, s * 0.14)
    ..close();
  c.drawPath(rock, _fill(body));
  c.drawCircle(Offset(-s * 0.1, -s * 0.12), s * 0.05, _fill(_darken(body)));
  c.drawCircle(Offset(s * 0.12, s * 0.1), s * 0.04, _fill(_darken(body)));
  c.drawPath(rock, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(-s * 0.06, 0),
    Offset(s * 0.08, 0),
    s,
    size: 0.045,
    white: const Color(0xFFFFCC80),
    angry: true,
  );
  c.restore();
}

/// E判定UFO：ぴかぴか光りながら、ふわふわ飛ぶ
void _ufo(Canvas c, double s, double t, Color body) {
  final float = sin(t * 2.5) * s * 0.04;
  // 光線
  c.drawPath(
    Path()
      ..moveTo(s * 0.4, s * 0.56 + float)
      ..lineTo(s * 0.26, s * 0.94)
      ..lineTo(s * 0.74, s * 0.94)
      ..lineTo(s * 0.6, s * 0.56 + float)
      ..close(),
    _fill(Color.fromRGBO(255, 245, 157, 0.25 + 0.15 * sin(t * 6))),
  );
  c.save();
  c.translate(0, float);
  // ドーム
  final dome = Rect.fromLTWH(s * 0.34, s * 0.24, s * 0.32, s * 0.3);
  c.drawArc(dome, pi, pi, true, _fill(const Color(0xAAB3E5FC)));
  c.drawArc(dome, pi, pi, false, _stroke(s * 0.02));
  // 乗っている目玉
  _eyes(c, Offset(s * 0.5, s * 0.33), Offset(s * 0.5, s * 0.33), s, size: 0.06);
  // 円盤
  final disc = Rect.fromLTWH(s * 0.12, s * 0.38, s * 0.76, s * 0.2);
  c.drawOval(disc, _fill(body));
  c.drawOval(disc, _stroke(s * 0.025));
  // ランプ
  for (var i = 0; i < 5; i++) {
    final on = ((t * 4).floor() + i) % 2 == 0;
    c.drawCircle(
      Offset(s * (0.22 + i * 0.14), s * 0.49),
      s * 0.03,
      _fill(on ? const Color(0xFFFFEB3B) : _darken(body)),
    );
  }
  // 「E」の文字
  final e = _stroke(s * 0.02, const Color(0xFFD64545));
  c.drawLine(Offset(s * 0.47, s * 0.41), Offset(s * 0.47, s * 0.47), e);
  for (final y in [0.41, 0.44, 0.47]) {
    c.drawLine(Offset(s * 0.47, s * y), Offset(s * 0.53, s * y), e);
  }
  c.restore();
}

/// 天空の審判アストラル：星をつないだ体に、大きな目
void _astral(Canvas c, double s, double t, Color body) {
  final pulse = (sin(t * 2) + 1) / 2;
  final center = Offset(s * 0.5, s * 0.46);
  // 後光
  c.drawCircle(
    center,
    s * (0.4 + pulse * 0.04),
    _fill(Color.fromRGBO(159, 168, 218, 0.2 + pulse * 0.15)),
  );
  // 星座の線
  final stars = [
    for (var i = 0; i < 6; i++)
      center +
          Offset(
            cos(i / 6 * 2 * pi + t * 0.3) * s * 0.36,
            sin(i / 6 * 2 * pi + t * 0.3) * s * 0.3,
          ),
  ];
  final line = _stroke(s * 0.012, const Color(0xFFE8EAF6));
  for (var i = 0; i < stars.length; i++) {
    c.drawLine(stars[i], stars[(i + 1) % stars.length], line);
    c.drawLine(stars[i], center, line);
  }
  for (final p in stars) {
    _star(c, p, s * 0.045, const Color(0xFFFFF59D));
  }
  // 体（星形）
  _star(c, center, s * 0.22, body);
  final path = _starPath(center, s * 0.22);
  c.drawPath(path, _stroke(s * 0.025));
  // 大きな目
  c.drawOval(
    Rect.fromCenter(center: center, width: s * 0.18, height: s * 0.12),
    _fill(_white),
  );
  c.drawCircle(center, s * 0.04, _fill(const Color(0xFF1A237E)));
  c.drawCircle(
    center + Offset(s * 0.012, -s * 0.012),
    s * 0.012,
    _fill(_white),
  );
  c.drawOval(
    Rect.fromCenter(center: center, width: s * 0.18, height: s * 0.12),
    _stroke(s * 0.02),
  );
}

Path _starPath(Offset c, double r) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    final pt = c + Offset(cos(a) * rr, sin(a) * rr);
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  return p..close();
}

void _star(Canvas c, Offset center, double r, Color color) =>
    c.drawPath(_starPath(center, r), _fill(color));
