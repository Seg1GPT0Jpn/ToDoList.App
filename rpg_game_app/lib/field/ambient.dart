import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:rpg_game/rpg_game.dart';

import 'field_map.dart';

/// 舞うものの種類
enum _Kind { leaf, petal, snow, ember, mote, sparkle }

_Kind? _kindOf(Terrain t) => switch (t) {
  Terrain.meadow ||
  Terrain.hill ||
  Terrain.river ||
  Terrain.forest => _Kind.leaf,
  Terrain.flower => _Kind.petal,
  Terrain.snow => _Kind.snow,
  Terrain.lava => _Kind.ember,
  Terrain.crystal || Terrain.sky => _Kind.sparkle,
  Terrain.beach || Terrain.harbor || Terrain.desert => null,
  _ when t.isVoyage => null,
  _ => _Kind.mote,
};

class _Bit {
  _Bit(this.kind, this.p, this.v, this.size, this.life, this.spin);
  final _Kind kind;
  Vector2 p;
  Vector2 v;
  final double size;
  double life;
  double age = 0;
  double spin;
}

/// 画面に見えているあたりに、地形に合わせたものを舞わせる
/// （草原は葉っぱ、花畑は花びら、雪原は雪、火山は火の粉、結晶は光の粒、建物の中はほこり）
class AmbientLayer extends PositionComponent {
  AmbientLayer({
    required this.map,
    required this.focus,
    required this.view,
    required this.tileSize,
  }) : super(priority: 100000);

  final FieldMap map;

  /// 主人公の位置（ここの地形で、舞うものが決まる）
  final Vector2 Function() focus;

  /// 見えている範囲（マップの座標）
  final ui.Rect Function() view;
  final double tileSize;

  final _bits = <_Bit>[];
  final _rnd = Random(5);
  double _spawn = 0;

  static const _max = 36;

  @override
  void update(double dt) {
    final f = focus();
    final t = map.terrainAt((f.x / tileSize).floor(), (f.y / tileSize).floor());
    final kind = _kindOf(t);
    final area = view();
    _spawn += dt;
    final every = switch (kind) {
      _Kind.snow => 0.12,
      _Kind.ember || _Kind.sparkle => 0.25,
      _Kind.mote => 0.5,
      _ => 0.35,
    };
    while (kind != null && _spawn > every && _bits.length < _max) {
      _spawn -= every;
      _bits.add(_make(kind, area));
    }
    if (kind == null) _spawn = 0;
    for (final b in _bits) {
      b.age += dt;
      b.spin += dt;
      b.p += b.v * dt;
      if (b.kind == _Kind.leaf || b.kind == _Kind.petal) {
        b.p.x += sin(b.age * 2 + b.size) * 12 * dt;
      }
    }
    _bits.removeWhere(
      (b) => b.age > b.life || !area.inflate(80).contains(b.p.toOffset()),
    );
  }

  _Bit _make(_Kind kind, ui.Rect a) {
    double rx() => a.left + _rnd.nextDouble() * a.width;
    double ry() => a.top + _rnd.nextDouble() * a.height;
    return switch (kind) {
      // 風に流れて左上から右下へ
      _Kind.leaf || _Kind.petal => _Bit(
        kind,
        Vector2(a.left - 10 + _rnd.nextDouble() * a.width * 0.6, a.top - 10),
        Vector2(18 + _rnd.nextDouble() * 18, 22 + _rnd.nextDouble() * 18),
        3 + _rnd.nextDouble() * 2.5,
        12,
        _rnd.nextDouble() * 6,
      ),
      _Kind.snow => _Bit(
        kind,
        Vector2(rx(), a.top - 6),
        Vector2(-6 + _rnd.nextDouble() * 12, 26 + _rnd.nextDouble() * 20),
        1.2 + _rnd.nextDouble() * 2,
        20,
        0,
      ),
      // 下から上へのぼって消える
      _Kind.ember => _Bit(
        kind,
        Vector2(rx(), a.bottom - _rnd.nextDouble() * a.height * 0.4),
        Vector2(-4 + _rnd.nextDouble() * 8, -(18 + _rnd.nextDouble() * 22)),
        1 + _rnd.nextDouble() * 1.6,
        2.5 + _rnd.nextDouble() * 2,
        0,
      ),
      _Kind.sparkle || _Kind.mote => _Bit(
        kind,
        Vector2(rx(), ry()),
        Vector2(-3 + _rnd.nextDouble() * 6, -2 - _rnd.nextDouble() * 4),
        kind == _Kind.mote
            ? 1 + _rnd.nextDouble()
            : 1.5 + _rnd.nextDouble() * 2,
        3 + _rnd.nextDouble() * 3,
        _rnd.nextDouble() * 6,
      ),
    };
  }

  @override
  void render(ui.Canvas canvas) {
    for (final b in _bits) {
      // 出はじめと消えぎわは、うすく
      final fade = min(1.0, min(b.age / 0.6, (b.life - b.age) / 0.8));
      if (fade <= 0) continue;
      final o = b.p.toOffset();
      switch (b.kind) {
        case _Kind.leaf || _Kind.petal:
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(b.spin * 2);
          canvas.drawOval(
            ui.Rect.fromCenter(
              center: ui.Offset.zero,
              width: b.size * 1.8,
              height: b.size,
            ),
            ui.Paint()
              ..color =
                  (b.kind == _Kind.leaf
                          ? const ui.Color(0xFF8CC06B)
                          : const ui.Color(0xFFF8BBD0))
                      .withValues(alpha: 0.85 * fade),
          );
          canvas.restore();
        case _Kind.snow:
          canvas.drawCircle(
            o,
            b.size,
            ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, 0.9 * fade),
          );
        case _Kind.ember:
          canvas.drawCircle(
            o,
            b.size * 2.2,
            ui.Paint()..color = ui.Color.fromRGBO(255, 140, 50, 0.18 * fade),
          );
          canvas.drawCircle(
            o,
            b.size,
            ui.Paint()..color = ui.Color.fromRGBO(255, 200, 90, 0.9 * fade),
          );
        case _Kind.sparkle:
          final tw = 0.5 + 0.5 * sin(b.spin * 5);
          final p = ui.Paint()
            ..color = ui.Color.fromRGBO(255, 255, 255, 0.85 * fade * tw)
            ..strokeWidth = 1.2;
          canvas.drawLine(
            o.translate(-b.size * 1.6, 0),
            o.translate(b.size * 1.6, 0),
            p,
          );
          canvas.drawLine(
            o.translate(0, -b.size * 1.6),
            o.translate(0, b.size * 1.6),
            p,
          );
        case _Kind.mote:
          canvas.drawCircle(
            o,
            b.size,
            ui.Paint()..color = ui.Color.fromRGBO(255, 244, 214, 0.55 * fade),
          );
      }
    }
  }
}

/// 水面のきらめき（見えている水のマスだけ）
class WaterGlints extends PositionComponent {
  WaterGlints({required this.map, required this.view, required this.tileSize})
    : super(priority: 0);

  final FieldMap map;
  final ui.Rect Function() view;
  final double tileSize;
  late final List<Cell> _water = [
    for (var r = 0; r < map.height; r++)
      for (var c = 0; c < map.width; c++)
        if (map.tileAt(c, r) == '~' && !map.terrainAt(c, r).isVoyage)
          (col: c, row: r),
  ];
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    if (_water.isEmpty) return;
    final a = view().inflate(tileSize);
    for (final w in _water) {
      final x = (w.col + 0.5) * tileSize, y = (w.row + 0.5) * tileSize;
      if (!a.contains(ui.Offset(x, y))) continue;
      final seed = (w.col * 31 + w.row * 17) % 97 / 97.0;
      final k = sin(_t * 1.8 + seed * 12);
      if (k < 0.55) continue;
      final lava = map.terrainAt(w.col, w.row) == Terrain.lava;
      final o = ui.Offset(
        x + (seed - 0.5) * tileSize * 0.6,
        y + (0.3 - seed) * tileSize * 0.5,
      );
      final alpha = (k - 0.55) / 0.45;
      final p = ui.Paint()
        ..color =
            (lava ? const ui.Color(0xFFFFE08A) : const ui.Color(0xFFFFFFFF))
                .withValues(alpha: 0.9 * alpha)
        ..strokeWidth = 1.4
        ..strokeCap = ui.StrokeCap.round;
      canvas.drawLine(o.translate(-4, 0), o.translate(4, 0), p);
      canvas.drawLine(
        o.translate(0, -3),
        o.translate(0, 3),
        p..strokeWidth = 1,
      );
    }
  }
}
