part of 'enemy_painter.dart';

// v4 で増えたモンスター（文房具11・海8・空8）。
// どれも [s] の正方形に、足もとが y ≒ 0.9s になるように描く。[t] は経過秒。

/// 鉛筆の塗りムラ（斜めのハッチング）を、[clip] の中にだけ描く
void _hatchIn(Canvas c, Path clip, double s, Color color, {double gap = 0.07}) {
  c.save();
  c.clipPath(clip);
  final b = clip.getBounds();
  final p = _stroke(s * 0.012, color);
  for (var x = b.left - b.height; x < b.right; x += s * gap) {
    c.drawLine(Offset(x, b.bottom), Offset(x + b.height, b.top), p);
  }
  c.restore();
}

/// 輪郭つきで塗る
void _blob(Canvas c, Path p, double s, Color body, {double w = 0.025}) {
  c.drawPath(p, _fill(body));
  c.drawPath(p, _stroke(s * w));
}

// ---------------------------------------------------------------------------
// 文房具
// ---------------------------------------------------------------------------

/// ノートン：大学ノートの体。ページがぱらぱらめくれる
void _notebook(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final tilt = sin(t * 2) * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.6);
  c.rotate(tilt);
  final cover = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: s * 0.56, height: s * 0.6),
    Radius.circular(s * 0.03),
  );
  c.drawRRect(cover, _fill(body));
  // 中のページ（罫線）
  final page = Rect.fromLTWH(-s * 0.24, -s * 0.26, s * 0.46, s * 0.52);
  c.drawRect(page, _fill(_paper));
  for (var i = 1; i < 7; i++) {
    final y = page.top + i * page.height / 7;
    c.drawLine(
      Offset(page.left, y),
      Offset(page.right, y),
      _stroke(s * 0.006, const Color(0xFF9FB7D0)),
    );
  }
  c.drawLine(
    Offset(page.left + s * 0.07, page.top),
    Offset(page.left + s * 0.07, page.bottom),
    _stroke(s * 0.008, const Color(0xFFE8A5A5)),
  );
  c.drawRRect(cover, _stroke(s * 0.028));
  // 背（とじ）
  c.drawRect(
    Rect.fromLTWH(-s * 0.28, -s * 0.3, s * 0.05, s * 0.6),
    _fill(_darken(body, 0.25)),
  );
  // めくれるページ
  final flip = (sin(t * 3) + 1) / 2;
  final curl = Path()
    ..moveTo(s * 0.22, s * 0.26)
    ..quadraticBezierTo(
      s * (0.22 - 0.1 * flip),
      s * (0.14 - 0.1 * flip),
      s * (0.12 - 0.08 * flip),
      s * 0.26,
    )
    ..close();
  c.drawPath(curl, _fill(const Color(0xFFF4EEE0)));
  c.drawPath(curl, _stroke(s * 0.015));
  _face(c, Offset(-s * 0.01, -s * 0.06), s, gap: 0.09, mouth: 'grin');
  c.restore();
}

/// フデバコング：筆箱のゴリラ。ふたを開けて鉛筆を見せる
void _pencilcase(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.7);
  final open = (sin(t * 2.5) + 1) / 2 * 0.35;
  c.save();
  c.translate(s * 0.5, s * 0.72);
  // 中の鉛筆
  for (var i = 0; i < 4; i++) {
    final x = -s * 0.2 + i * s * 0.12;
    c.drawRect(
      Rect.fromLTWH(x, -s * 0.3, s * 0.07, s * 0.24),
      _fill(
        [
          _wood,
          const Color(0xFF8BC34A),
          const Color(0xFFE57373),
          const Color(0xFF64B5F6),
        ][i],
      ),
    );
    c.drawRect(
      Rect.fromLTWH(x, -s * 0.3, s * 0.07, s * 0.24),
      _stroke(s * 0.012),
    );
  }
  // 箱
  final box = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(0, -s * 0.04),
      width: s * 0.76,
      height: s * 0.3,
    ),
    Radius.circular(s * 0.06),
  );
  c.drawRRect(box, _fill(body));
  _hatchIn(c, Path()..addRRect(box), s, _darken(body, 0.12));
  c.drawRRect(box, _stroke(s * 0.03));
  // ふた（開く）
  c.save();
  c.translate(-s * 0.38, -s * 0.19);
  c.rotate(-open);
  final lid = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, -s * 0.07, s * 0.76, s * 0.08),
    Radius.circular(s * 0.04),
  );
  c.drawRRect(lid, _fill(_darken(body, 0.15)));
  c.drawRRect(lid, _stroke(s * 0.025));
  c.restore();
  // ファスナーの顔
  _face(c, Offset(0, -s * 0.07), s, gap: 0.12, angry: true, mouth: 'flat');
  // 腕
  _hand(c, Offset(-s * 0.42, s * 0.02), s, body);
  _hand(c, Offset(s * 0.42, s * 0.02), s, body);
  c.restore();
}

/// ノリノリスティック：スティックのり。ねばねばの足あと
void _glue(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final squash = sin(t * 4) * 0.03;
  c.save();
  c.translate(s * 0.5, s * 0.88);
  c.scale(1 + squash, 1 - squash);
  final tube = RRect.fromRectAndRadius(
    Rect.fromLTWH(-s * 0.15, -s * 0.56, s * 0.3, s * 0.56),
    Radius.circular(s * 0.06),
  );
  c.drawRRect(tube, _fill(_white));
  // ラベル
  c.save();
  c.clipRRect(tube);
  c.drawRect(
    Rect.fromLTWH(-s * 0.15, -s * 0.36, s * 0.3, s * 0.18),
    _fill(body),
  );
  c.restore();
  c.drawRRect(tube, _stroke(s * 0.028));
  // 出てきたのり
  final top = Path()
    ..moveTo(-s * 0.11, -s * 0.56)
    ..quadraticBezierTo(0, -s * 0.72, s * 0.11, -s * 0.56)
    ..close();
  _blob(c, top, s, const Color(0xFFF7F2D8), w: 0.02);
  _face(c, Offset(0, -s * 0.44), s, gap: 0.06, eye: 0.04, mouth: 'smile');
  c.restore();
  // のりのしずく
  final drip = (t * 0.7) % 1;
  c.drawCircle(
    Offset(s * 0.36, s * (0.5 + drip * 0.35)),
    s * 0.025,
    _fill(const Color(0xCCF7F2D8)),
  );
}

/// セロテープス：テープの輪。ぐるぐる回ってからめとる
void _tape(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  c.save();
  c.translate(s * 0.5, s * 0.58);
  c.drawCircle(Offset.zero, s * 0.3, _fill(body.withValues(alpha: 0.75)));
  c.drawCircle(Offset.zero, s * 0.3, _stroke(s * 0.028));
  c.drawCircle(Offset.zero, s * 0.15, _fill(_paper));
  c.drawCircle(Offset.zero, s * 0.15, _stroke(s * 0.022));
  // 光の筋（回る）
  c.save();
  c.rotate(t * 1.5);
  c.drawArc(
    Rect.fromCircle(center: Offset.zero, radius: s * 0.23),
    0,
    1.2,
    false,
    _stroke(s * 0.02, const Color(0x99FFFFFF)),
  );
  c.restore();
  // のびたテープ
  final pull = sin(t * 2) * s * 0.03;
  final strip = Path()
    ..moveTo(s * 0.2, s * 0.22)
    ..lineTo(s * 0.4 + pull, s * 0.3)
    ..lineTo(s * 0.36 + pull, s * 0.36)
    ..lineTo(s * 0.16, s * 0.27)
    ..close();
  c.drawPath(strip, _fill(body.withValues(alpha: 0.6)));
  c.drawPath(strip, _stroke(s * 0.015));
  _face(c, Offset(0, -s * 0.02), s, gap: 0.06, eye: 0.04, mouth: 'o');
  c.restore();
}

/// クリップマン：銀の針金がばねのように跳ねる
void _clip(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.35);
  final hop = (sin(t * 5)).abs() * s * 0.06;
  c.save();
  c.translate(s * 0.5, s * 0.86 - hop);
  final wire = Path()
    ..moveTo(-s * 0.08, 0)
    ..lineTo(-s * 0.08, -s * 0.58)
    ..arcToPoint(Offset(s * 0.12, -s * 0.58), radius: Radius.circular(s * 0.1))
    ..lineTo(s * 0.12, -s * 0.12)
    ..arcToPoint(
      Offset(-s * 0.02, -s * 0.12),
      radius: Radius.circular(s * 0.07),
    )
    ..lineTo(-s * 0.02, -s * 0.46)
    ..arcToPoint(Offset(s * 0.06, -s * 0.46), radius: Radius.circular(s * 0.04))
    ..lineTo(s * 0.06, -s * 0.2);
  c.drawPath(wire, _stroke(s * 0.06, _ink));
  c.drawPath(wire, _stroke(s * 0.04, body));
  c.drawPath(wire, _stroke(s * 0.012, const Color(0xAAFFFFFF)));
  // 顔は頭の輪の中
  _eyes(
    c,
    Offset(-s * 0.0, -s * 0.6),
    Offset(s * 0.06, -s * 0.6),
    s,
    size: 0.03,
    angry: true,
  );
  c.restore();
}

/// ガビョウニ：画びょうのとげとげ。上から刺してくる
void _pushpin(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.3);
  final bob = sin(t * 3) * s * 0.03;
  c.save();
  c.translate(s * 0.5, s * 0.5 + bob);
  // 針
  c.drawLine(
    Offset(0, s * 0.12),
    Offset(0, s * 0.38),
    _stroke(s * 0.03, _metal),
  );
  c.drawLine(Offset(0, s * 0.12), Offset(0, s * 0.38), _stroke(s * 0.012));
  // 頭（円盤）
  c.drawOval(
    Rect.fromCenter(
      center: Offset(0, s * 0.08),
      width: s * 0.5,
      height: s * 0.14,
    ),
    _fill(_darken(body, 0.2)),
  );
  c.drawOval(
    Rect.fromCenter(
      center: Offset(0, s * 0.08),
      width: s * 0.5,
      height: s * 0.14,
    ),
    _stroke(s * 0.02),
  );
  final head = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(0, -s * 0.08),
      width: s * 0.3,
      height: s * 0.3,
    ),
    Radius.circular(s * 0.1),
  );
  c.drawRRect(head, _fill(body));
  c.drawRRect(head, _stroke(s * 0.025));
  c.drawOval(
    Rect.fromLTWH(-s * 0.1, -s * 0.2, s * 0.08, s * 0.05),
    _fill(const Color(0x88FFFFFF)),
  );
  _face(
    c,
    Offset(0, -s * 0.1),
    s,
    gap: 0.06,
    eye: 0.035,
    angry: true,
    mouth: 'grin',
  );
  c.restore();
}

/// ケズリドン：鉛筆削り。ハンドルをぐるぐる回す
void _sharpener(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  c.save();
  c.translate(s * 0.5, s * 0.62);
  final box = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: s * 0.5, height: s * 0.44),
    Radius.circular(s * 0.06),
  );
  c.drawRRect(box, _fill(body));
  _hatchIn(c, Path()..addRRect(box), s, _darken(body, 0.12));
  c.drawRRect(box, _stroke(s * 0.03));
  // 削り穴
  c.drawCircle(Offset(-s * 0.1, s * 0.08), s * 0.05, _fill(_ink));
  // 削りかす入れ（窓）
  c.drawRect(
    Rect.fromLTWH(-s * 0.2, s * 0.14, s * 0.4, s * 0.06),
    _fill(const Color(0xFFE6C79C)),
  );
  // ハンドル（回る）
  c.save();
  c.translate(s * 0.25, -s * 0.05);
  c.rotate(t * 4);
  c.drawLine(Offset.zero, Offset(s * 0.14, 0), _stroke(s * 0.03, _metal));
  c.drawLine(Offset.zero, Offset(s * 0.14, 0), _stroke(s * 0.01));
  c.drawCircle(Offset(s * 0.14, 0), s * 0.035, _fill(const Color(0xFFD64545)));
  c.drawCircle(Offset(s * 0.14, 0), s * 0.035, _stroke(s * 0.012));
  c.restore();
  _face(c, Offset(-s * 0.04, -s * 0.08), s, gap: 0.08, eye: 0.045, angry: true);
  c.restore();
}

/// フデマル：習字の筆。墨のしずくを飛ばす
void _brush(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.35);
  final sway = sin(t * 2.2) * 0.12;
  c.save();
  c.translate(s * 0.5, s * 0.88);
  c.rotate(sway);
  // 穂先
  final tip = Path()
    ..moveTo(-s * 0.08, -s * 0.24)
    ..quadraticBezierTo(-s * 0.1, -s * 0.06, 0, 0)
    ..quadraticBezierTo(s * 0.1, -s * 0.06, s * 0.08, -s * 0.24)
    ..close();
  _blob(c, tip, s, const Color(0xFF2B2B30), w: 0.02);
  // 軸
  final shaft = RRect.fromRectAndRadius(
    Rect.fromLTWH(-s * 0.07, -s * 0.66, s * 0.14, s * 0.44),
    Radius.circular(s * 0.04),
  );
  c.drawRRect(shaft, _fill(body));
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(-s * 0.07, -s * (0.32 + i * 0.1)),
      Offset(s * 0.07, -s * (0.32 + i * 0.1)),
      _stroke(s * 0.008, _darken(body, 0.3)),
    );
  }
  c.drawRRect(shaft, _stroke(s * 0.025));
  _face(c, Offset(0, -s * 0.5), s, gap: 0.035, eye: 0.03, mouth: 'flat');
  c.restore();
  // 墨のしずく
  for (var i = 0; i < 3; i++) {
    final p = (t * 0.9 + i / 3) % 1;
    c.drawCircle(
      Offset(s * (0.62 + p * 0.2), s * (0.86 - p * 0.25 + p * p * 0.3)),
      s * 0.018,
      _fill(const Color(0xCC2B2B30)),
    );
  }
}

/// シュウセイテープ：修正テープ。白い帯でまちがいを消してまわる
void _correction(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.55);
  final roll = sin(t * 3) * s * 0.02;
  c.save();
  c.translate(s * 0.5 + roll, s * 0.6);
  final shell = Path()
    ..moveTo(-s * 0.26, -s * 0.18)
    ..lineTo(s * 0.16, -s * 0.18)
    ..quadraticBezierTo(s * 0.32, -s * 0.18, s * 0.32, 0)
    ..lineTo(s * 0.36, s * 0.14)
    ..lineTo(-s * 0.26, s * 0.14)
    ..close();
  _blob(c, shell, s, body, w: 0.028);
  // 窓（中のリール）
  c.drawCircle(Offset(-s * 0.06, -s * 0.02), s * 0.09, _fill(_white));
  c.drawCircle(Offset(-s * 0.06, -s * 0.02), s * 0.09, _stroke(s * 0.015));
  c.save();
  c.translate(-s * 0.06, -s * 0.02);
  c.rotate(t * 3);
  c.drawLine(Offset(-s * 0.06, 0), Offset(s * 0.06, 0), _stroke(s * 0.012));
  c.restore();
  // 白い帯
  c.drawRect(
    Rect.fromLTWH(s * 0.36, s * 0.12, s * 0.12, s * 0.04),
    _fill(_white),
  );
  c.drawRect(
    Rect.fromLTWH(s * 0.36, s * 0.12, s * 0.12, s * 0.04),
    _stroke(s * 0.008),
  );
  _eyes(
    c,
    Offset(s * 0.1, -s * 0.06),
    Offset(s * 0.2, -s * 0.06),
    s,
    size: 0.035,
  );
  c.restore();
}

/// インクボトル：インク瓶。ふたを跳ね上げて黒い波を吐く
void _inkpot(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  c.save();
  c.translate(s * 0.5, s * 0.88);
  final bottle = Path()
    ..moveTo(-s * 0.22, 0)
    ..lineTo(-s * 0.24, -s * 0.32)
    ..quadraticBezierTo(-s * 0.24, -s * 0.4, -s * 0.12, -s * 0.42)
    ..lineTo(s * 0.12, -s * 0.42)
    ..quadraticBezierTo(s * 0.24, -s * 0.4, s * 0.24, -s * 0.32)
    ..lineTo(s * 0.22, 0)
    ..close();
  c.drawPath(bottle, _fill(const Color(0xFFDDE7EE)));
  // 中のインク（ゆれる）
  final level = -s * 0.24 + sin(t * 3) * s * 0.015;
  c.save();
  c.clipPath(bottle);
  c.drawRect(Rect.fromLTRB(-s * 0.3, level, s * 0.3, 0), _fill(body));
  c.restore();
  c.drawPath(bottle, _stroke(s * 0.028));
  // ふた
  final hop = (sin(t * 4)).clamp(0, 1) * s * 0.06;
  c.drawRect(
    Rect.fromLTWH(-s * 0.1, -s * 0.52 - hop, s * 0.2, s * 0.1),
    _fill(_ink),
  );
  _face(
    c,
    Offset(0, -s * 0.12),
    s,
    gap: 0.08,
    eye: 0.045,
    line: _white,
    mouth: 'o',
  );
  c.restore();
}

/// デンタクン：電卓。ボタンの目がチカチカ光る
void _calculator(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  final tilt = sin(t * 1.8) * 0.05;
  c.save();
  c.translate(s * 0.5, s * 0.58);
  c.rotate(tilt);
  final case_ = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: s * 0.46, height: s * 0.62),
    Radius.circular(s * 0.06),
  );
  c.drawRRect(case_, _fill(body));
  c.drawRRect(case_, _stroke(s * 0.03));
  // 画面
  final screen = Rect.fromLTWH(-s * 0.18, -s * 0.26, s * 0.36, s * 0.12);
  c.drawRect(screen, _fill(const Color(0xFFCFE3C2)));
  c.drawRect(screen, _stroke(s * 0.012));
  // 画面の中の目
  _eyes(
    c,
    Offset(-s * 0.07, -s * 0.2),
    Offset(s * 0.07, -s * 0.2),
    s,
    size: 0.03,
    angry: true,
  );
  // ボタン
  final blink = (t * 4).floor() % 9;
  for (var r = 0; r < 3; r++) {
    for (var k = 0; k < 3; k++) {
      final o = Offset(-s * 0.13 + k * s * 0.13, -s * 0.03 + r * s * 0.1);
      final lit = r * 3 + k == blink;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: o, width: s * 0.09, height: s * 0.07),
          Radius.circular(s * 0.015),
        ),
        _fill(lit ? const Color(0xFFF2B84B) : _white),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: o, width: s * 0.09, height: s * 0.07),
          Radius.circular(s * 0.015),
        ),
        _stroke(s * 0.01),
      );
    }
  }
  c.restore();
}

// ---------------------------------------------------------------------------
// 海
// ---------------------------------------------------------------------------

/// ヒラメキエイ：大きなひれで水をすべる
void _ray(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.7);
  final wave = sin(t * 3);
  c.save();
  c.translate(s * 0.5, s * 0.5);
  final p = Path()
    ..moveTo(0, -s * 0.18)
    ..quadraticBezierTo(
      s * 0.3,
      -s * (0.16 + wave * 0.06),
      s * 0.44,
      s * (0.02 + wave * 0.06),
    )
    ..quadraticBezierTo(s * 0.2, s * 0.08, 0, s * 0.2)
    ..quadraticBezierTo(-s * 0.2, s * 0.08, -s * 0.44, s * (0.02 + wave * 0.06))
    ..quadraticBezierTo(-s * 0.3, -s * (0.16 + wave * 0.06), 0, -s * 0.18)
    ..close();
  c.drawPath(p, _fill(body));
  _hatchIn(c, p, s, _darken(body, 0.15), gap: 0.09);
  c.drawPath(p, _stroke(s * 0.025));
  // しっぽ
  final tail = Path()
    ..moveTo(0, s * 0.18)
    ..quadraticBezierTo(s * 0.05 * wave, s * 0.3, -s * 0.04, s * 0.4);
  c.drawPath(tail, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(-s * 0.07, -s * 0.04),
    Offset(s * 0.07, -s * 0.04),
    s,
    size: 0.04,
  );
  c.drawArc(
    Rect.fromCenter(
      center: Offset(0, s * 0.04),
      width: s * 0.1,
      height: s * 0.05,
    ),
    0.2,
    pi - 0.4,
    false,
    _stroke(s * 0.015),
  );
  c.restore();
}

/// ノンビリガメ：甲らに方眼のもようがあるウミガメ
void _turtle(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final paddle = sin(t * 2.5) * 0.4;
  c.save();
  c.translate(s * 0.5, s * 0.58);
  // ひれ
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.translate(d * s * 0.22, s * 0.02);
    c.rotate(d * (0.4 + paddle));
    final fin = Rect.fromCenter(
      center: Offset(d * s * 0.1, 0),
      width: s * 0.22,
      height: s * 0.08,
    );
    c.drawOval(fin, _fill(_lighten(body, 0.3)));
    c.drawOval(fin, _stroke(s * 0.018));
    c.restore();
  }
  // 頭
  c.drawCircle(Offset(0, -s * 0.24), s * 0.1, _fill(_lighten(body, 0.3)));
  c.drawCircle(Offset(0, -s * 0.24), s * 0.1, _stroke(s * 0.02));
  _eyes(
    c,
    Offset(-s * 0.04, -s * 0.26),
    Offset(s * 0.04, -s * 0.26),
    s,
    size: 0.025,
  );
  // 甲ら（方眼）
  final shell = Rect.fromCenter(
    center: Offset(0, s * 0.02),
    width: s * 0.5,
    height: s * 0.38,
  );
  final sp = Path()..addOval(shell);
  c.drawPath(sp, _fill(body));
  c.save();
  c.clipPath(sp);
  final grid = _stroke(s * 0.008, _darken(body, 0.25));
  for (var x = shell.left; x < shell.right; x += s * 0.06) {
    c.drawLine(Offset(x, shell.top), Offset(x, shell.bottom), grid);
  }
  for (var y = shell.top; y < shell.bottom; y += s * 0.06) {
    c.drawLine(Offset(shell.left, y), Offset(shell.right, y), grid);
  }
  c.restore();
  c.drawPath(sp, _stroke(s * 0.028));
  c.restore();
}

/// モノシリクジラ：大きなクジラ。潮をふくと文字が舞う
void _whale(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.8);
  final breathe = sin(t * 1.5) * s * 0.015;
  c.save();
  c.translate(s * 0.5, s * 0.62);
  final p = Path()
    ..moveTo(-s * 0.4, s * 0.02)
    ..quadraticBezierTo(-s * 0.4, -s * (0.26 + breathe / s), 0, -s * 0.26)
    ..quadraticBezierTo(s * 0.32, -s * 0.24, s * 0.36, -s * 0.04)
    ..lineTo(s * 0.46, -s * 0.16)
    ..lineTo(s * 0.44, s * 0.06)
    ..quadraticBezierTo(s * 0.2, s * 0.2, -s * 0.2, s * 0.16)
    ..quadraticBezierTo(-s * 0.4, s * 0.14, -s * 0.4, s * 0.02)
    ..close();
  c.drawPath(p, _fill(body));
  // おなか
  final belly = Path()
    ..moveTo(-s * 0.34, s * 0.06)
    ..quadraticBezierTo(-s * 0.1, s * 0.18, s * 0.22, s * 0.08)
    ..quadraticBezierTo(0, s * 0.1, -s * 0.34, s * 0.06);
  c.drawPath(belly, _fill(_lighten(body, 0.5)));
  c.drawPath(p, _stroke(s * 0.028));
  _eyes(
    c,
    Offset(-s * 0.24, -s * 0.06),
    Offset(-s * 0.14, -s * 0.06),
    s,
    size: 0.035,
  );
  // 潮（文字が舞う）
  final up = (t * 0.8) % 1;
  for (var i = 0; i < 3; i++) {
    c.drawCircle(
      Offset(-s * 0.06 + (i - 1) * s * 0.06 * up, -s * (0.3 + up * 0.18)),
      s * 0.02 * (1 - up),
      _fill(const Color(0xAA7FB3D5)),
    );
  }
  c.restore();
}

/// タツノシルベ：タツノオトシゴ。丸いしっぽで矢印を描く
void _seahorse(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.3);
  final bob = sin(t * 2.6) * s * 0.03;
  c.save();
  c.translate(s * 0.5, s * 0.5 + bob);
  final p = Path()
    ..moveTo(-s * 0.02, -s * 0.34)
    ..quadraticBezierTo(s * 0.16, -s * 0.36, s * 0.14, -s * 0.2)
    ..lineTo(s * 0.26, -s * 0.18)
    ..lineTo(s * 0.14, -s * 0.12)
    ..quadraticBezierTo(s * 0.18, s * 0.06, s * 0.06, s * 0.2)
    ..quadraticBezierTo(-s * 0.02, s * 0.32, s * 0.08, s * 0.36)
    ..quadraticBezierTo(s * 0.16, s * 0.4, s * 0.12, s * 0.3)
    ..quadraticBezierTo(-s * 0.14, s * 0.3, -s * 0.1, s * 0.04)
    ..quadraticBezierTo(-s * 0.08, -s * 0.12, -s * 0.12, -s * 0.2)
    ..quadraticBezierTo(-s * 0.16, -s * 0.32, -s * 0.02, -s * 0.34)
    ..close();
  c.drawPath(p, _fill(body));
  _hatchIn(c, p, s, _darken(body, 0.15), gap: 0.05);
  c.drawPath(p, _stroke(s * 0.024));
  // せびれ
  final fin = sin(t * 8) * s * 0.02;
  c.drawPath(
    Path()
      ..moveTo(-s * 0.1, -s * 0.02)
      ..lineTo(-s * 0.2 - fin, 0)
      ..lineTo(-s * 0.1, s * 0.08),
    _stroke(s * 0.018),
  );
  _eyes(
    c,
    Offset(s * 0.02, -s * 0.24),
    Offset(s * 0.08, -s * 0.24),
    s,
    size: 0.028,
  );
  c.restore();
}

/// ホシノカケラ：ヒトデ。5本の腕で答えを指さす
void _starfish(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  c.save();
  c.translate(s * 0.5, s * 0.56);
  c.rotate(sin(t * 1.5) * 0.15);
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -pi / 2 + i * pi / 5;
    final r = i.isEven ? s * 0.34 : s * 0.15;
    final o = Offset(cos(a) * r, sin(a) * r);
    if (i == 0) {
      p.moveTo(o.dx, o.dy);
    } else {
      p.lineTo(o.dx, o.dy);
    }
  }
  p.close();
  c.drawPath(p, _fill(body));
  for (var i = 0; i < 5; i++) {
    final a = -pi / 2 + i * 2 * pi / 5;
    for (var k = 1; k <= 3; k++) {
      c.drawCircle(
        Offset(cos(a) * s * 0.08 * k, sin(a) * s * 0.08 * k),
        s * 0.012,
        _fill(_lighten(body, 0.5)),
      );
    }
  }
  c.drawPath(p, _stroke(s * 0.026));
  _face(c, Offset(0, -s * 0.02), s, gap: 0.05, eye: 0.035, mouth: 'smile');
  c.restore();
}

/// ウツボルト：ウツボ。岩かげから急に飛び出す
void _eel(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  final strike = (sin(t * 2) + 1) / 2;
  // 岩
  final rock = Path()
    ..moveTo(s * 0.05, s * 0.9)
    ..quadraticBezierTo(s * 0.1, s * 0.6, s * 0.3, s * 0.62)
    ..quadraticBezierTo(s * 0.4, s * 0.58, s * 0.44, s * 0.9)
    ..close();
  _blob(c, rock, s, const Color(0xFF9E9A92), w: 0.022);
  // 体（S字に伸びる）
  final head = Offset(s * (0.42 + strike * 0.3), s * (0.48 - strike * 0.12));
  final body_ = Path()
    ..moveTo(s * 0.28, s * 0.72)
    ..cubicTo(
      s * 0.42,
      s * 0.82,
      s * 0.36,
      s * 0.48,
      head.dx - s * 0.06,
      head.dy,
    );
  c.drawPath(body_, _stroke(s * 0.15, _ink));
  c.drawPath(body_, _stroke(s * 0.12, body));
  c.drawPath(body_, _stroke(s * 0.02, _lighten(body, 0.3)));
  // 頭
  c.drawOval(
    Rect.fromCenter(center: head, width: s * 0.22, height: s * 0.14),
    _fill(body),
  );
  c.drawOval(
    Rect.fromCenter(center: head, width: s * 0.22, height: s * 0.14),
    _stroke(s * 0.022),
  );
  c.drawLine(
    head + Offset(s * 0.02, s * 0.03),
    head + Offset(s * 0.1, s * 0.02),
    _stroke(s * 0.015),
  );
  _eyes(
    c,
    head + Offset(-s * 0.02, -s * 0.03),
    head + Offset(s * 0.03, -s * 0.03),
    s,
    size: 0.022,
    angry: true,
  );
}

/// アンモナイト博士：化石の殻。うずの中に年代が刻まれている
void _ammonite(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.55);
  c.save();
  c.translate(s * 0.48, s * 0.56);
  final spin = sin(t * 1.2) * 0.1;
  c.rotate(spin);
  final shell = Path();
  for (var i = 0; i <= 160; i++) {
    final a = i / 160 * 4 * pi;
    final r = s * 0.04 + s * 0.26 * i / 160;
    final o = Offset(cos(a) * r, sin(a) * r);
    if (i == 0) {
      shell.moveTo(o.dx, o.dy);
    } else {
      shell.lineTo(o.dx, o.dy);
    }
  }
  c.drawCircle(Offset.zero, s * 0.3, _fill(body));
  _hatchIn(
    c,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.3)),
    s,
    _darken(body, 0.15),
  );
  c.drawPath(shell, _stroke(s * 0.02));
  c.drawCircle(Offset.zero, s * 0.3, _stroke(s * 0.028));
  c.restore();
  // 触手と顔（殻の口から）
  for (var i = 0; i < 4; i++) {
    final y = s * (0.6 + i * 0.05);
    c.drawLine(
      Offset(s * 0.74, y),
      Offset(s * (0.86 + sin(t * 4 + i) * 0.03), y + s * 0.04),
      _stroke(s * 0.02, _darken(body, 0.2)),
    );
  }
  _eyes(c, Offset(s * 0.7, s * 0.5), Offset(s * 0.78, s * 0.5), s, size: 0.03);
  // 片めがね
  c.drawCircle(Offset(s * 0.78, s * 0.5), s * 0.045, _stroke(s * 0.012));
}

/// トゲトゲウニ：ウニ。とげが呼吸のように伸び縮みする
void _urchin(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  c.save();
  c.translate(s * 0.5, s * 0.62);
  final pulse = 1 + sin(t * 3) * 0.08;
  for (var i = 0; i < 22; i++) {
    final a = i * 2 * pi / 22;
    final len = s * (i.isEven ? 0.36 : 0.3) * pulse;
    c.drawLine(
      Offset(cos(a) * s * 0.18, sin(a) * s * 0.18),
      Offset(cos(a) * len, sin(a) * len),
      _stroke(s * 0.018, _darken(body, 0.25)),
    );
  }
  c.drawCircle(Offset.zero, s * 0.2, _fill(body));
  c.drawCircle(Offset.zero, s * 0.2, _stroke(s * 0.026));
  _face(
    c,
    Offset(0, -s * 0.02),
    s,
    gap: 0.06,
    eye: 0.04,
    angry: true,
    mouth: 'flat',
  );
  c.restore();
}

// ---------------------------------------------------------------------------
// 空
// ---------------------------------------------------------------------------

/// テンシノシオリ：しおりの羽をもつ天使。光の輪がまわる
void _angel(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.4);
  final float = sin(t * 2) * s * 0.04;
  final flap = sin(t * 6) * 0.25;
  c.save();
  c.translate(s * 0.5, s * 0.5 + float);
  // 羽（しおりの形）
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.scale(d, 1);
    c.rotate(-0.2 - flap);
    final w = Path()
      ..moveTo(s * 0.06, -s * 0.06)
      ..lineTo(s * 0.34, -s * 0.2)
      ..lineTo(s * 0.34, s * 0.06)
      ..lineTo(s * 0.26, 0)
      ..lineTo(s * 0.18, s * 0.08)
      ..lineTo(s * 0.06, s * 0.04)
      ..close();
    _blob(c, w, s, _white, w: 0.02);
    c.drawLine(
      Offset(s * 0.12, -s * 0.03),
      Offset(s * 0.3, -s * 0.12),
      _stroke(s * 0.008, _darken(body, 0.2)),
    );
    c.restore();
  }
  // 体
  final robe = Path()
    ..moveTo(-s * 0.08, -s * 0.06)
    ..lineTo(s * 0.08, -s * 0.06)
    ..lineTo(s * 0.14, s * 0.24)
    ..lineTo(-s * 0.14, s * 0.24)
    ..close();
  _blob(c, robe, s, body, w: 0.022);
  c.drawCircle(Offset(0, -s * 0.14), s * 0.09, _fill(const Color(0xFFFCE9D6)));
  c.drawCircle(Offset(0, -s * 0.14), s * 0.09, _stroke(s * 0.02));
  _eyes(
    c,
    Offset(-s * 0.035, -s * 0.15),
    Offset(s * 0.035, -s * 0.15),
    s,
    size: 0.022,
  );
  // 光の輪
  c.save();
  c.translate(0, -s * 0.27);
  c.scale(1, 0.35);
  c.drawCircle(
    Offset.zero,
    s * 0.08,
    _stroke(s * 0.03, const Color(0xFFF2B84B)),
  );
  c.restore();
  c.restore();
}

/// ハクシキフクロウ：博識なフクロウ。首をくるりと回す
void _owl(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.45);
  c.save();
  c.translate(s * 0.5, s * 0.6);
  final body_ = Path()
    ..addOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.44, height: s * 0.54),
    );
  c.drawPath(body_, _fill(body));
  // おなかの羽（V字）
  for (var r = 0; r < 3; r++) {
    for (var k = -1; k <= 1; k++) {
      final o = Offset(k * s * 0.07, s * (0.04 + r * 0.06));
      c.drawPath(
        Path()
          ..moveTo(o.dx - s * 0.025, o.dy)
          ..lineTo(o.dx, o.dy + s * 0.025)
          ..lineTo(o.dx + s * 0.025, o.dy),
        _stroke(s * 0.01, _darken(body, 0.3)),
      );
    }
  }
  c.drawPath(body_, _stroke(s * 0.026));
  // 顔（首をかしげる）
  c.save();
  c.translate(0, -s * 0.1);
  c.rotate(sin(t * 1.3) * 0.25);
  for (final d in [-1.0, 1.0]) {
    c.drawCircle(Offset(d * s * 0.08, 0), s * 0.075, _fill(_white));
    c.drawCircle(Offset(d * s * 0.08, 0), s * 0.075, _stroke(s * 0.018));
    c.drawCircle(Offset(d * s * 0.08, s * 0.01), s * 0.035, _fill(_ink));
  }
  // めがね
  c.drawLine(Offset(-s * 0.005, 0), Offset(s * 0.005, 0), _stroke(s * 0.015));
  c.drawPath(
    Path()
      ..moveTo(-s * 0.025, s * 0.06)
      ..lineTo(0, s * 0.1)
      ..lineTo(s * 0.025, s * 0.06)
      ..close(),
    _fill(const Color(0xFFF2B84B)),
  );
  // 耳羽
  for (final d in [-1.0, 1.0]) {
    c.drawPath(
      Path()
        ..moveTo(d * s * 0.14, -s * 0.06)
        ..lineTo(d * s * 0.18, -s * 0.16)
        ..lineTo(d * s * 0.08, -s * 0.08)
        ..close(),
      _fill(_darken(body, 0.15)),
    );
  }
  c.restore();
  c.restore();
}

/// フェニックス：赤ペンの炎の鳥。何度でもよみがえる
void _phoenix(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.5);
  final float = sin(t * 2.4) * s * 0.04;
  c.save();
  c.translate(s * 0.5, s * 0.46 + float);
  // 炎の尾
  for (var i = 0; i < 5; i++) {
    final a = pi / 2 + (i - 2) * 0.28;
    final len = s * (0.36 + sin(t * 6 + i) * 0.04);
    final p = Path()
      ..moveTo(0, s * 0.08)
      ..quadraticBezierTo(
        cos(a) * len * 0.5 + s * 0.06,
        sin(a) * len * 0.5 + s * 0.08,
        cos(a) * len,
        sin(a) * len + s * 0.08,
      );
    c.drawPath(p, _stroke(s * 0.05, i.isEven ? body : const Color(0xFFF2B84B)));
  }
  // 翼
  final flap = sin(t * 7) * 0.4;
  for (final d in [-1.0, 1.0]) {
    c.save();
    c.scale(d, 1);
    c.rotate(-0.3 - flap);
    final w = Path()
      ..moveTo(s * 0.06, 0)
      ..quadraticBezierTo(s * 0.3, -s * 0.28, s * 0.44, -s * 0.18)
      ..quadraticBezierTo(s * 0.3, -s * 0.12, s * 0.36, -s * 0.04)
      ..quadraticBezierTo(s * 0.2, -s * 0.02, s * 0.06, s * 0.06)
      ..close();
    _blob(c, w, s, body, w: 0.02);
    c.restore();
  }
  c.drawOval(
    Rect.fromCenter(center: Offset(0, 0), width: s * 0.2, height: s * 0.26),
    _fill(body),
  );
  c.drawOval(
    Rect.fromCenter(center: Offset(0, 0), width: s * 0.2, height: s * 0.26),
    _stroke(s * 0.022),
  );
  // とさか
  for (var i = -1; i <= 1; i++) {
    c.drawLine(
      Offset(i * s * 0.02, -s * 0.12),
      Offset(i * s * 0.05, -s * 0.2),
      _stroke(s * 0.02, const Color(0xFFF2B84B)),
    );
  }
  _eyes(
    c,
    Offset(-s * 0.035, -s * 0.04),
    Offset(s * 0.035, -s * 0.04),
    s,
    size: 0.025,
    angry: true,
  );
  c.restore();
}

/// ペガサスパート：翼のある馬。蹄の音で拍子をとる
void _pegasus(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  final gallop = sin(t * 5);
  c.save();
  c.translate(s * 0.5, s * 0.6);
  // 脚
  for (var i = 0; i < 4; i++) {
    final x = -s * 0.16 + i * s * 0.1;
    final swing = (i.isEven ? gallop : -gallop) * s * 0.03;
    c.drawLine(
      Offset(x, s * 0.06),
      Offset(x + swing, s * 0.28),
      _stroke(s * 0.045, _ink),
    );
    c.drawLine(
      Offset(x, s * 0.06),
      Offset(x + swing, s * 0.28),
      _stroke(s * 0.03, body),
    );
  }
  // 胴
  final torso = Rect.fromCenter(
    center: Offset(0, 0),
    width: s * 0.46,
    height: s * 0.2,
  );
  c.drawOval(torso, _fill(body));
  c.drawOval(torso, _stroke(s * 0.024));
  // 首と頭
  final neck = Path()
    ..moveTo(s * 0.14, -s * 0.04)
    ..lineTo(s * 0.24, -s * 0.26)
    ..lineTo(s * 0.36, -s * 0.22)
    ..lineTo(s * 0.34, -s * 0.16)
    ..lineTo(s * 0.24, -s * 0.16)
    ..lineTo(s * 0.22, -s * 0.02)
    ..close();
  _blob(c, neck, s, body, w: 0.022);
  _eyes(
    c,
    Offset(s * 0.27, -s * 0.22),
    Offset(s * 0.3, -s * 0.22),
    s,
    size: 0.018,
  );
  // たてがみ（五線譜の色）
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(s * (0.2 + i * 0.02), -s * (0.24 - i * 0.06)),
      Offset(s * (0.13 + i * 0.02), -s * (0.2 - i * 0.06)),
      _stroke(s * 0.015, const Color(0xFF3949AB)),
    );
  }
  // 翼
  final flap = sin(t * 6) * 0.35;
  c.save();
  c.translate(-s * 0.02, -s * 0.08);
  c.rotate(-0.5 - flap);
  final wing = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-s * 0.1, -s * 0.3, -s * 0.3, -s * 0.28)
    ..quadraticBezierTo(-s * 0.2, -s * 0.14, -s * 0.24, -s * 0.06)
    ..quadraticBezierTo(-s * 0.12, -s * 0.04, 0, 0)
    ..close();
  _blob(c, wing, s, _white, w: 0.02);
  c.restore();
  c.restore();
}

/// フウセンオバケ：風船のおばけ。ふわふわ逃げていく
void _balloon(Canvas c, double s, double t, Color body) {
  final float = sin(t * 1.8) * s * 0.05;
  final sway = sin(t * 1.2) * 0.12;
  c.save();
  c.translate(s * 0.5, s * 0.42 + float);
  c.rotate(sway);
  // ひも
  c.drawPath(
    Path()
      ..moveTo(0, s * 0.22)
      ..quadraticBezierTo(s * 0.06, s * 0.32, -s * 0.02, s * 0.44),
    _stroke(s * 0.012),
  );
  final b = Rect.fromCenter(
    center: Offset.zero,
    width: s * 0.4,
    height: s * 0.46,
  );
  c.drawOval(b, _fill(body));
  c.drawOval(
    Rect.fromLTWH(-s * 0.12, -s * 0.16, s * 0.08, s * 0.12),
    _fill(const Color(0x88FFFFFF)),
  );
  c.drawOval(b, _stroke(s * 0.025));
  c.drawPath(
    Path()
      ..moveTo(-s * 0.03, s * 0.23)
      ..lineTo(s * 0.03, s * 0.23)
      ..lineTo(0, s * 0.19)
      ..close(),
    _fill(_darken(body, 0.2)),
  );
  _face(c, Offset(0, -s * 0.02), s, gap: 0.07, eye: 0.04, mouth: 'o');
  c.restore();
}

/// タコアゲ：凧。しっぽに「問一」「問二」の札をつけて舞う
void _kite(Canvas c, double s, double t, Color body) {
  final sway = sin(t * 1.6) * 0.15;
  c.save();
  c.translate(s * 0.5, s * 0.36);
  c.rotate(sway);
  final p = Path()
    ..moveTo(0, -s * 0.24)
    ..lineTo(s * 0.2, 0)
    ..lineTo(0, s * 0.24)
    ..lineTo(-s * 0.2, 0)
    ..close();
  c.drawPath(p, _fill(body));
  c.drawLine(
    Offset(0, -s * 0.24),
    Offset(0, s * 0.24),
    _stroke(s * 0.012, _darken(body, 0.3)),
  );
  c.drawLine(
    Offset(-s * 0.2, 0),
    Offset(s * 0.2, 0),
    _stroke(s * 0.012, _darken(body, 0.3)),
  );
  c.drawPath(p, _stroke(s * 0.025));
  _eyes(
    c,
    Offset(-s * 0.06, -s * 0.06),
    Offset(s * 0.06, -s * 0.06),
    s,
    size: 0.035,
    angry: true,
  );
  // しっぽ
  final tail = Path()..moveTo(0, s * 0.24);
  for (var i = 1; i <= 4; i++) {
    tail.quadraticBezierTo(
      sin(t * 3 + i) * s * 0.06,
      s * (0.24 + i * 0.07 - 0.035),
      sin(t * 3 + i + 0.5) * s * 0.04,
      s * (0.24 + i * 0.07),
    );
  }
  c.drawPath(tail, _stroke(s * 0.012));
  for (var i = 1; i <= 2; i++) {
    final o = Offset(
      sin(t * 3 + i * 2 + 0.5) * s * 0.04,
      s * (0.24 + i * 0.14),
    );
    c.drawRect(
      Rect.fromCenter(center: o, width: s * 0.06, height: s * 0.05),
      _fill(_white),
    );
    c.drawRect(
      Rect.fromCenter(center: o, width: s * 0.06, height: s * 0.05),
      _stroke(s * 0.008),
    );
  }
  c.restore();
}

/// グリフォンガード：わしの頭としし体の番人。宝の問題を守る
void _griffin(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.65);
  final flap = sin(t * 4) * 0.3;
  c.save();
  c.translate(s * 0.5, s * 0.6);
  // 翼
  c.save();
  c.translate(-s * 0.04, -s * 0.12);
  c.rotate(-0.6 - flap);
  final wing = Path()
    ..moveTo(0, 0)
    ..lineTo(-s * 0.1, -s * 0.3)
    ..lineTo(-s * 0.18, -s * 0.22)
    ..lineTo(-s * 0.26, -s * 0.26)
    ..lineTo(-s * 0.24, -s * 0.12)
    ..lineTo(-s * 0.3, -s * 0.06)
    ..close();
  _blob(c, wing, s, _lighten(body, 0.25), w: 0.02);
  c.restore();
  // 胴（しし）
  final torso = Rect.fromCenter(
    center: Offset(0, s * 0.02),
    width: s * 0.5,
    height: s * 0.24,
  );
  c.drawOval(torso, _fill(body));
  _hatchIn(c, Path()..addOval(torso), s, _darken(body, 0.12));
  c.drawOval(torso, _stroke(s * 0.024));
  for (final x in [-0.16, 0.14]) {
    c.drawLine(
      Offset(s * x, s * 0.12),
      Offset(s * x, s * 0.28),
      _stroke(s * 0.05, _ink),
    );
    c.drawLine(
      Offset(s * x, s * 0.12),
      Offset(s * x, s * 0.28),
      _stroke(s * 0.035, body),
    );
  }
  // 頭（わし）
  final head = Offset(s * 0.22, -s * 0.14);
  c.drawCircle(head, s * 0.1, _fill(_white));
  c.drawCircle(head, s * 0.1, _stroke(s * 0.022));
  c.drawPath(
    Path()
      ..moveTo(head.dx + s * 0.08, head.dy - s * 0.02)
      ..lineTo(head.dx + s * 0.17, head.dy + s * 0.02)
      ..lineTo(head.dx + s * 0.07, head.dy + s * 0.05)
      ..close(),
    _fill(const Color(0xFFF2B84B)),
  );
  _eyes(
    c,
    head + Offset(-s * 0.02, -s * 0.02),
    head + Offset(s * 0.04, -s * 0.02),
    s,
    size: 0.022,
    angry: true,
  );
  c.restore();
}

/// ニジヘビ：虹色の帯のヘビ。7色の問題を順に出す
void _rainbow(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.6);
  const colors = [
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFFFFF176),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFF7986CB),
    Color(0xFFBA68C8),
  ];
  final pts = <Offset>[
    for (var i = 0; i <= 24; i++)
      Offset(
        s * (0.16 + i / 24 * 0.66),
        s * (0.7 + sin(i / 24 * 2 * pi + t * 3) * 0.08 - i / 24 * 0.22),
      ),
  ];
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  c.drawPath(path, _stroke(s * 0.13, _ink));
  for (var k = 0; k < colors.length; k++) {
    c.drawPath(path, _stroke(s * (0.11 - k * 0.014), colors[k]));
  }
  final head = pts.last;
  c.drawCircle(head, s * 0.08, _fill(body));
  c.drawCircle(head, s * 0.08, _stroke(s * 0.022));
  _eyes(
    c,
    head + Offset(-s * 0.03, -s * 0.02),
    head + Offset(s * 0.03, -s * 0.02),
    s,
    size: 0.022,
  );
  final tongue = (sin(t * 8) + 1) / 2 * s * 0.05;
  c.drawLine(
    head + Offset(s * 0.06, s * 0.03),
    head + Offset(s * 0.1 + tongue, s * 0.04),
    _stroke(s * 0.012, const Color(0xFFD64545)),
  );
}

/// ミミック：宝箱のふりをした魔物。ふたのすき間から舌が見える
void _mimic(Canvas c, double s, double t, Color body) {
  _shadow(c, s, 0.65);
  final chomp = (sin(t * 3) + 1) / 2 * 0.35;
  c.save();
  c.translate(s * 0.5, s * 0.8);
  final box = RRect.fromRectAndRadius(
    Rect.fromLTWH(-s * 0.32, -s * 0.3, s * 0.64, s * 0.3),
    Radius.circular(s * 0.03),
  );
  c.drawRRect(box, _fill(body));
  _hatchIn(c, Path()..addRRect(box), s, _darken(body, 0.15), gap: 0.05);
  c.drawRRect(box, _stroke(s * 0.028));
  // 歯
  for (var i = 0; i < 6; i++) {
    final x = -s * 0.28 + i * s * 0.11;
    c.drawPath(
      Path()
        ..moveTo(x, -s * 0.3)
        ..lineTo(x + s * 0.05, -s * 0.24)
        ..lineTo(x + s * 0.1, -s * 0.3)
        ..close(),
      _fill(_white),
    );
  }
  // 舌
  c.drawPath(
    Path()
      ..moveTo(-s * 0.08, -s * 0.3)
      ..quadraticBezierTo(0, -s * (0.36 + chomp * 0.3), s * 0.1, -s * 0.28),
    _stroke(s * 0.05, const Color(0xFFD64545)),
  );
  // ふた（ぱくぱく）
  c.save();
  c.translate(-s * 0.32, -s * 0.3);
  c.rotate(-chomp);
  final lid = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, -s * 0.18, s * 0.64, s * 0.18),
    Radius.circular(s * 0.08),
  );
  c.drawRRect(lid, _fill(_darken(body, 0.1)));
  c.drawRRect(lid, _stroke(s * 0.028));
  c.drawRect(
    Rect.fromLTWH(s * 0.28, -s * 0.1, s * 0.08, s * 0.1),
    _fill(const Color(0xFFF2B84B)),
  );
  c.drawRect(
    Rect.fromLTWH(s * 0.28, -s * 0.1, s * 0.08, s * 0.1),
    _stroke(s * 0.012),
  );
  _eyes(
    c,
    Offset(s * 0.2, -s * 0.12),
    Offset(s * 0.44, -s * 0.12),
    s,
    size: 0.035,
    angry: true,
  );
  c.restore();
  c.restore();
}
