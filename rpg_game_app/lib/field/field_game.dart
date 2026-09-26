import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/hero_painter.dart';
import 'field_map.dart';

const double tileSize = 32;

typedef Cell = ({int col, int row});

extension on Facing {
  Cell get delta => switch (this) {
    Facing.up => (col: 0, row: -1),
    Facing.down => (col: 0, row: 1),
    Facing.left => (col: -1, row: 0),
    Facing.right => (col: 1, row: 0),
  };
}

Vector2 _center(Cell c) =>
    Vector2((c.col + 0.5) * tileSize, (c.row + 0.5) * tileSize);

/// 見下ろし型のフィールド。マス目単位で歩き、道をふさぐ敵に話しかけるとバトル。
class FieldGame extends FlameGame with KeyboardEvents {
  FieldGame({
    required this.map,
    required this.rpgWorld,
    required this._progress,
    required this.onEncounter,
    required this.onMessage,
  });

  final FieldMap map;
  final WorldDef rpgWorld;
  final void Function(StageDef stage, bool cleared) onEncounter;
  final void Function(String message) onMessage;

  RpgProgress _progress;
  late final PlayerToken player;
  final Map<int, EnemyToken> _enemies = {};

  /// 画面の十字ボタンで押されている方向
  Facing? padDirection;
  Facing? _keyDirection;

  /// ダイアログ表示中などは操作を受け付けない
  bool inputLocked = false;

  /// 話しかけた直後、同じ方向を押しっぱなしで何度も話しかけないようにする
  Facing? _bumpedDirection;

  @override
  ui.Color backgroundColor() => TsuzuriColors.kraft;

  @override
  Future<void> onLoad() async {
    world.add(MapLayer(map));
    for (final e in map.enemySpots.entries) {
      final stage = rpgWorld.stages.where((s) => s.order == e.key).firstOrNull;
      if (stage == null) continue;
      final token = EnemyToken(stage: stage, home: e.value);
      _enemies[e.key] = token;
      world.add(token);
    }
    player = PlayerToken(map.find('P'));
    world.add(player);
    applyProgress(_progress);
    camera.follow(player, snap: true);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // スマホ縦持ちで横 9 マス程度が見えるように
    camera.viewfinder.zoom = min(
      size.x / (9 * tileSize),
      size.y / (11 * tileSize),
    );
  }

  /// 進行状況に合わせて、倒した敵を道の脇へどかす
  void applyProgress(RpgProgress progress) {
    _progress = progress;
    for (final token in _enemies.values) {
      final cleared = progress.clearedStageIds.contains(token.stage.id);
      token.cleared = cleared;
      token.cell = cleared ? _asideOf(token.home) : token.home;
      token.position = _center(token.cell);
      token.priority = token.cell.row * 10 + 4;
    }
  }

  /// 倒した敵の待機場所（ゲートの1つ下の段で、空いている横のマス）
  Cell _asideOf(Cell gate) {
    for (final dc in [1, -1, 2, -2]) {
      final c = (col: gate.col + dc, row: gate.row + 1);
      if (map.isFloor(c.col, c.row)) return c;
    }
    return gate;
  }

  EnemyToken? _enemyAt(Cell c) {
    for (final e in _enemies.values) {
      if (e.cell == c) return e;
    }
    return null;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    Facing? dir;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      dir = Facing.up;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      dir = Facing.down;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      dir = Facing.left;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      dir = Facing.right;
    }
    _keyDirection = dir;
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clampCamera();
    final dir = padDirection ?? _keyDirection;
    if (dir != _bumpedDirection) _bumpedDirection = null;
    if (!inputLocked &&
        !player.moving &&
        dir != null &&
        dir != _bumpedDirection) {
      _tryStep(dir);
    }
    // 近くにいる敵には「！」を出す
    for (final e in _enemies.values) {
      final d =
          (e.cell.col - player.cell.col).abs() +
          (e.cell.row - player.cell.row).abs();
      e.alert = d <= 2 && !e.cleared;
    }
  }

  /// マップの外（無地の部分）が映りすぎないよう、カメラを端で止める
  void _clampCamera() {
    final vf = camera.viewfinder;
    final visible = camera.viewport.virtualSize / vf.zoom;
    final mapSize = Vector2(map.width * tileSize, map.height * tileSize);
    double clamp(double v, double view, double total) =>
        view >= total ? total / 2 : v.clamp(view / 2, total - view / 2);
    vf.position = Vector2(
      clamp(vf.position.x, visible.x, mapSize.x),
      clamp(vf.position.y, visible.y, mapSize.y),
    );
  }

  void _tryStep(Facing dir) {
    player.facing = dir;
    final target = (
      col: player.cell.col + dir.delta.col,
      row: player.cell.row + dir.delta.row,
    );
    final enemy = _enemyAt(target);
    if (enemy != null) {
      _bumpedDirection = dir;
      onEncounter(enemy.stage, enemy.cleared);
      return;
    }
    switch (map.tileAt(target.col, target.row)) {
      case 'S':
        _bumpedDirection = dir;
        onMessage(FieldMap.signMessages.first);
        return;
      case 'G':
        _bumpedDirection = dir;
        final bossCleared = rpgWorld.stages.every(
          (s) => _progress.clearedStageIds.contains(s.id),
        );
        onMessage(
          bossCleared ? '英語ワールド制覇！ トロフィーがきらきら光っている。' : 'トロフィーがある。…でも、まだ手が届かない。',
        );
        return;
    }
    if (map.isFloor(target.col, target.row)) player.walkTo(target);
  }
}

/// 地形をまとめて1枚の絵にしておくレイヤー
class MapLayer extends PositionComponent {
  MapLayer(this.map)
    : super(
        size: Vector2(map.width * tileSize, map.height * tileSize),
        priority: -1,
      );

  final FieldMap map;
  late final ui.Picture _picture;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    final recorder = ui.PictureRecorder();
    _paintMap(ui.Canvas(recorder));
    _picture = recorder.endRecording();
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    canvas.drawPicture(_picture);
    // ゴールのトロフィーだけきらめかせる
    final g = map.find('G');
    final glow = (sin(_t * 3) + 1) / 2;
    canvas.drawCircle(
      Offset((g.col + 0.5) * tileSize, (g.row + 0.5) * tileSize),
      tileSize * (0.55 + glow * 0.1),
      ui.Paint()..color = ui.Color.fromRGBO(255, 214, 90, 0.15 + glow * 0.2),
    );
    _trophy(canvas, g);
  }

  void _paintMap(ui.Canvas c) {
    final w = map.width * tileSize;
    final h = map.height * tileSize;
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      ui.Paint()..color = TsuzuriColors.paper,
    );
    final grid = ui.Paint()
      ..color = TsuzuriColors.gridLine
      ..strokeWidth = 1;
    for (var x = 0.0; x <= w; x += tileSize / 2) {
      c.drawLine(
        Offset(x, 0),
        Offset(x, h),
        grid..strokeWidth = x % tileSize == 0 ? 1 : 0.4,
      );
    }
    for (var y = 0.0; y <= h; y += tileSize / 2) {
      c.drawLine(
        Offset(0, y),
        Offset(w, y),
        grid..strokeWidth = y % tileSize == 0 ? 1 : 0.4,
      );
    }
    final rnd = Random(7);
    for (var r = 0; r < map.height; r++) {
      for (var col = 0; col < map.width; col++) {
        final rect = Rect.fromLTWH(
          col * tileSize,
          r * tileSize,
          tileSize,
          tileSize,
        );
        switch (map.tileAt(col, r)) {
          case '#':
            _wall(c, rect, rnd);
          case 'T':
            _tree(c, rect, rnd);
          case '~':
            _pond(c, rect);
          case 'S':
            _sign(c, rect);
        }
      }
    }
  }

  static final _ink = ui.Paint()
    ..color = TsuzuriColors.ink
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = ui.StrokeCap.round;

  void _wall(ui.Canvas c, Rect r, Random rnd) {
    c.drawRect(r, ui.Paint()..color = TsuzuriColors.kraft);
    final hatch = ui.Paint()
      ..color = const ui.Color(0x558D6E63)
      ..strokeWidth = 1;
    for (var i = -1; i < 4; i++) {
      final x = r.left + i * 9 + rnd.nextDouble() * 3;
      c.drawLine(Offset(x, r.bottom), Offset(x + 12, r.top), hatch);
    }
    c.drawRect(
      r.deflate(0.5),
      ui.Paint()
        ..color = const ui.Color(0xFF8D6E63)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _tree(ui.Canvas c, Rect r, Random rnd) {
    final cx = r.center.dx, cy = r.center.dy;
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, r.bottom - 3), width: 20, height: 6),
      ui.Paint()..color = const ui.Color(0x33000000),
    );
    c.drawRect(
      Rect.fromLTWH(cx - 2.5, cy + 2, 5, 11),
      ui.Paint()..color = const ui.Color(0xFF8D6E63),
    );
    final leaf = ui.Paint()..color = const ui.Color(0xFF8CC06B);
    final blob = ui.Path();
    for (var i = 0; i < 5; i++) {
      final a = i / 5 * 2 * pi;
      blob.addOval(
        Rect.fromCircle(
          center: Offset(cx + cos(a) * 6, cy - 3 + sin(a) * 5),
          radius: 7 + rnd.nextDouble() * 2,
        ),
      );
    }
    c.drawPath(blob, leaf);
    c.drawPath(blob, _ink..strokeWidth = 1.2);
    // 鉛筆の影
    final hatch = ui.Paint()
      ..color = const ui.Color(0x44507A3A)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset(cx + 1 + i * 3, cy + 2),
        Offset(cx + 5 + i * 3, cy - 6),
        hatch,
      );
    }
  }

  void _pond(ui.Canvas c, Rect r) {
    c.drawRect(r, ui.Paint()..color = const ui.Color(0xFF9EC6E0));
    final wave = ui.Paint()
      ..color = const ui.Color(0xAAFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final y in [r.top + 10, r.top + 22]) {
      final p = ui.Path()..moveTo(r.left + 4, y);
      p.quadraticBezierTo(r.left + 10, y - 4, r.left + 16, y);
      p.quadraticBezierTo(r.left + 22, y + 4, r.left + 28, y);
      c.drawPath(p, wave);
    }
  }

  void _sign(ui.Canvas c, Rect r) {
    c.drawRect(
      Rect.fromLTWH(r.center.dx - 2, r.center.dy, 4, 13),
      ui.Paint()..color = const ui.Color(0xFF8D6E63),
    );
    final board = Rect.fromCenter(
      center: r.center.translate(0, -3),
      width: 24,
      height: 15,
    );
    c.drawRect(board, ui.Paint()..color = const ui.Color(0xFFE6CFA3));
    c.drawRect(board, _ink..strokeWidth = 1.4);
    for (final dy in [-2.0, 2.0]) {
      c.drawLine(
        Offset(board.left + 5, board.center.dy + dy),
        Offset(board.right - 5, board.center.dy + dy),
        _ink..strokeWidth = 1,
      );
    }
  }

  void _trophy(ui.Canvas c, Cell g) {
    final cx = (g.col + 0.5) * tileSize, cy = (g.row + 0.5) * tileSize;
    final gold = ui.Paint()..color = const ui.Color(0xFFF2B84B);
    final cup = ui.Path()
      ..moveTo(cx - 9, cy - 10)
      ..lineTo(cx + 9, cy - 10)
      ..quadraticBezierTo(cx + 9, cy + 2, cx, cy + 3)
      ..quadraticBezierTo(cx - 9, cy + 2, cx - 9, cy - 10)
      ..close();
    c.drawRect(Rect.fromLTWH(cx - 2, cy + 2, 4, 6), gold);
    c.drawRect(Rect.fromLTWH(cx - 7, cy + 8, 14, 4), gold);
    c.drawPath(cup, gold);
    c.drawPath(cup, _ink..strokeWidth = 1.4);
  }
}

/// フィールド上の敵
class EnemyToken extends PositionComponent {
  EnemyToken({required this.stage, required this.home})
    : cell = home,
      super(size: Vector2.all(tileSize * 1.15), anchor: Anchor.center);

  final StageDef stage;
  final Cell home;
  Cell cell;
  bool cleared = false;
  bool alert = false;
  double _t = Random().nextDouble() * 10;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    final s = size.x;
    if (cleared) {
      canvas.saveLayer(null, ui.Paint()..color = const ui.Color(0xB0FFFFFF));
      canvas.translate(s * 0.1, s * 0.15);
      canvas.scale(0.8);
      paintEnemy(canvas, s, stage.enemy.id, _t * 0.5);
      canvas.restore();
      _badge(canvas, s, '★', const ui.Color(0xFFF2B84B));
    } else {
      paintEnemy(canvas, s, stage.enemy.id, _t);
      if (alert) {
        final jump = sin(_t * 8).abs() * 3;
        _badge(canvas, s, '！', TsuzuriColors.stamp, dy: -jump);
      }
    }
  }

  void _badge(
    ui.Canvas canvas,
    double s,
    String text,
    ui.Color color, {
    double dy = 0,
  }) {
    final center = Offset(s * 0.82, s * 0.05 + dy);
    canvas.drawCircle(center, 7, ui.Paint()..color = TsuzuriColors.card);
    canvas.drawCircle(
      center,
      7,
      ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final b =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(
            ui.TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: ui.FontWeight.w900,
            ),
          )
          ..addText(text);
    final p = b.build()..layout(const ui.ParagraphConstraints(width: 14));
    canvas.drawParagraph(p, center - Offset(7, p.height / 2));
  }
}

/// プレイヤー（マス目単位でなめらかに歩く）
class PlayerToken extends PositionComponent {
  PlayerToken(this.cell)
    : super(
        size: Vector2.all(tileSize),
        anchor: Anchor.center,
        position: _center(cell),
      );

  static const stepSeconds = 0.18;

  Cell cell;
  Facing facing = Facing.up;
  bool moving = false;
  double _walk = 0;
  double _idle = 1;
  late Vector2 _from;
  late Vector2 _to;
  double _p = 0;

  void walkTo(Cell target) {
    _from = position.clone();
    _to = _center(target);
    cell = target;
    _p = 0;
    moving = true;
  }

  @override
  void update(double dt) {
    priority = cell.row * 10 + 5;
    if (!moving) {
      _idle += dt;
      return;
    }
    _idle = 0;
    _p = min(1, _p + dt / stepSeconds);
    _walk += dt / (stepSeconds * 2);
    position = _from + (_to - _from) * _p;
    if (_p >= 1) moving = false;
  }

  @override
  void render(ui.Canvas canvas) => paintHero(
    canvas,
    size.x,
    facing: facing,
    walk: _walk,
    moving: moving || _idle < 0.08,
  );
}
