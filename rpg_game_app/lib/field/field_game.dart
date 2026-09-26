import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/hero_painter.dart';
import 'field_map.dart';

const double tileSize = 32;

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
    required this.onInn,
    required this.onChest,
    required this.onSpring,
    required this.onGhost,
  });

  final FieldMap map;
  final WorldDef rpgWorld;
  final void Function(StageDef stage, bool cleared) onEncounter;
  final void Function(String message) onMessage;

  /// 宿に話しかけたとき。引数は宿の先にいる（次に戦う）ステージ
  final void Function(StageDef nextStage) onInn;

  /// 宝箱に話しかけたとき（[chestId] は保存用の ID）
  final void Function(StageDef nextStage, String chestId, bool opened) onChest;

  /// 泉に話しかけたとき
  final void Function(StageDef nextStage) onSpring;

  /// 亡霊（そのステージで間違えた問題）に話しかけたとき
  final void Function(StageDef stage, int count) onGhost;

  RpgProgress _progress;
  late final PlayerToken player;
  final Map<int, EnemyToken> _enemies = {};
  final Map<Cell, ChestToken> _chests = {};
  final Map<int, GhostToken> _ghosts = {};
  final Map<int, CageToken> _cages = {};

  /// 画面の十字ボタンで押されている方向
  Facing? padDirection;
  Facing? _keyDirection;

  /// ダイアログ表示中などは操作を受け付けない
  bool inputLocked = false;

  /// 今いる地方（画面上部の表示用）
  final region = ValueNotifier<Region>(Region.grass);

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
    for (final c in map.findAll('C')) {
      final token = ChestToken(c);
      _chests[c] = token;
      world.add(token);
    }
    for (final w in map.findAll('W')) {
      world.add(SpringToken(w));
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
      token.cell = cleared ? map.asideOf(token.home) : token.home;
      token.position = _center(token.cell);
      token.priority = token.cell.row * 10 + 4;
    }
    for (final e in _chests.entries) {
      e.value.opened = progress.openedChests.contains(chestIdAt(e.key));
    }
    // 亡霊：間違えた問題があるステージごとに1体、そのステージの手前の部屋をさまよう
    final counts = <String, int>{};
    for (final stageId in progress.mistakes.values) {
      counts[stageId] = (counts[stageId] ?? 0) + 1;
    }
    for (final stage in rpgWorld.stages) {
      final n = counts[stage.id] ?? 0;
      final cells = map.safeCells[stage.order] ?? const [];
      final existing = _ghosts[stage.order];
      if (n == 0 || cells.isEmpty) {
        existing?.removeFromParent();
        _ghosts.remove(stage.order);
        continue;
      }
      if (existing != null) {
        existing.count = n;
      } else {
        final token = GhostToken(stage, cells[cells.length ~/ 2], n);
        _ghosts[stage.order] = token;
        world.add(token);
      }
    }
    // 負けたステージの仲間は、ゲート横の檻に捕まっている
    for (final stage in rpgWorld.stages) {
      final captive = stage.captiveCompanionId;
      final caught =
          captive != null &&
          progress.lostStages.contains(stage.id) &&
          !progress.companions.contains(captive);
      final existing = _cages[stage.order];
      if (!caught) {
        existing?.removeFromParent();
        _cages.remove(stage.order);
      } else if (existing == null) {
        final gate = map.enemySpots[stage.order]!;
        final aside = map.asideOf(gate);
        final cell = (col: gate.col * 2 - aside.col, row: gate.row);
        final token = CageToken(cell);
        _cages[stage.order] = token;
        world.add(token);
      }
    }
  }

  /// 宝箱の保存用 ID（その先にいる敵の番号で決まる）
  String chestIdAt(Cell c) => '${rpgWorld.id}_chest_${map.enemyAhead(c)}';

  StageDef? _stageAhead(Cell c) {
    final n = map.enemyAhead(c);
    return rpgWorld.stages.where((s) => s.order == n).firstOrNull;
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
    final r = map.regionAt(player.cell.row);
    if (region.value != r) region.value = r;
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
    for (final g in _ghosts.values) {
      if (g.cell == target) {
        _bumpedDirection = dir;
        onGhost(g.stage, g.count);
        return;
      }
    }
    final enemy = _enemyAt(target);
    if (enemy != null) {
      _bumpedDirection = dir;
      onEncounter(enemy.stage, enemy.cleared);
      return;
    }
    switch (map.tileAt(target.col, target.row)) {
      case 'I':
        _bumpedDirection = dir;
        final n = map.enemyAhead(target);
        final stage = rpgWorld.stages.where((s) => s.order == n).firstOrNull;
        if (stage != null) onInn(stage);
        return;
      case 'S':
        _bumpedDirection = dir;
        onMessage(FieldMap.signMessages.first);
        return;
      case 'C':
        _bumpedDirection = dir;
        final stage = _stageAhead(target);
        final id = chestIdAt(target);
        if (stage != null) {
          onChest(stage, id, _progress.openedChests.contains(id));
        }
        return;
      case 'W':
        _bumpedDirection = dir;
        final stage = _stageAhead(target);
        if (stage != null) onSpring(stage);
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

  /// 地方ごとの色
  static const _floor = {
    Region.grass: ui.Color(0xFFFAF6EE),
    Region.coast: ui.Color(0xFFF4E7C6),
    Region.cave: ui.Color(0xFFD6D0C8),
    Region.lava: ui.Color(0xFF4A3530),
  };
  static const _gridColor = {
    Region.grass: ui.Color(0xFFCFDDEA),
    Region.coast: ui.Color(0xFFE6D3A6),
    Region.cave: ui.Color(0xFFBDB5AB),
    Region.lava: ui.Color(0xFF5E4640),
  };
  static const _wallColor = {
    Region.grass: ui.Color(0xFFD9C7A5),
    Region.coast: ui.Color(0xFFD9B98A),
    Region.cave: ui.Color(0xFF7A746E),
    Region.lava: ui.Color(0xFF2B1D1D),
  };

  void _paintMap(ui.Canvas c) {
    final w = map.width * tileSize;
    for (var r = 0; r < map.height; r++) {
      final region = map.regionAt(r);
      final y = r * tileSize;
      c.drawRect(
        Rect.fromLTWH(0, y, w, tileSize),
        ui.Paint()..color = _floor[region]!,
      );
      final grid = ui.Paint()
        ..color = _gridColor[region]!
        ..strokeWidth = 1;
      for (var x = 0.0; x <= w; x += tileSize / 2) {
        c.drawLine(
          Offset(x, y),
          Offset(x, y + tileSize),
          grid..strokeWidth = x % tileSize == 0 ? 1 : 0.4,
        );
      }
      c.drawLine(Offset(0, y), Offset(w, y), grid..strokeWidth = 1);
      c.drawLine(
        Offset(0, y + tileSize / 2),
        Offset(w, y + tileSize / 2),
        grid..strokeWidth = 0.4,
      );
      // 溶岩エリアの床のひび
      if (region == Region.lava) {
        final crack = ui.Paint()
          ..color = const ui.Color(0x66FF7A3D)
          ..strokeWidth = 1;
        for (var x = 8.0; x < w; x += 57) {
          c.drawLine(Offset(x, y + 6), Offset(x + 9, y + 20), crack);
        }
      }
    }
    final rnd = Random(7);
    for (var r = 0; r < map.height; r++) {
      final region = map.regionAt(r);
      for (var col = 0; col < map.width; col++) {
        final rect = Rect.fromLTWH(
          col * tileSize,
          r * tileSize,
          tileSize,
          tileSize,
        );
        switch (map.tileAt(col, r)) {
          case '#':
            _wall(c, rect, rnd, region);
          case 'T':
            _obstacle(c, rect, rnd, region);
          case '~':
            _pond(c, rect, region);
          case 'S':
            _sign(c, rect);
          case 'I':
            _inn(c, rect);
        }
      }
    }
  }

  static final _ink = ui.Paint()
    ..color = TsuzuriColors.ink
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = ui.StrokeCap.round;

  void _wall(ui.Canvas c, Rect r, Random rnd, Region region) {
    c.drawRect(r, ui.Paint()..color = _wallColor[region]!);
    final hatch = ui.Paint()
      ..color = region == Region.lava
          ? const ui.Color(0x55E4572E)
          : const ui.Color(0x558D6E63)
      ..strokeWidth = 1;
    for (var i = -1; i < 4; i++) {
      final x = r.left + i * 9 + rnd.nextDouble() * 3;
      c.drawLine(Offset(x, r.bottom), Offset(x + 12, r.top), hatch);
    }
    c.drawRect(
      r.deflate(0.5),
      ui.Paint()
        ..color = region == Region.lava
            ? const ui.Color(0xFF1A1111)
            : const ui.Color(0xFF8D6E63)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _obstacle(ui.Canvas c, Rect r, Random rnd, Region region) {
    final cx = r.center.dx, cy = r.center.dy;
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, r.bottom - 3), width: 20, height: 6),
      ui.Paint()..color = const ui.Color(0x33000000),
    );
    switch (region) {
      case Region.grass:
        c.drawRect(
          Rect.fromLTWH(cx - 2.5, cy + 2, 5, 11),
          ui.Paint()..color = const ui.Color(0xFF8D6E63),
        );
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
        c.drawPath(blob, ui.Paint()..color = const ui.Color(0xFF8CC06B));
        c.drawPath(blob, _ink..strokeWidth = 1.2);
      case Region.coast:
        // ヤシの木
        final trunk = ui.Path()
          ..moveTo(cx - 2, r.bottom - 3)
          ..quadraticBezierTo(cx + 4, cy + 4, cx + 1, cy - 6)
          ..lineTo(cx + 4, cy - 6)
          ..quadraticBezierTo(cx + 7, cy + 4, cx + 2, r.bottom - 3)
          ..close();
        c.drawPath(trunk, ui.Paint()..color = const ui.Color(0xFFB08968));
        final leaf = ui.Paint()..color = const ui.Color(0xFF4FA36B);
        for (final a in [-2.6, -2.0, -1.2, -0.5, 0.2]) {
          final p = ui.Path()
            ..moveTo(cx + 2, cy - 7)
            ..quadraticBezierTo(
              cx + 2 + cos(a) * 7,
              cy - 7 + sin(a) * 7 - 3,
              cx + 2 + cos(a) * 13,
              cy - 7 + sin(a) * 9 + 4,
            )
            ..quadraticBezierTo(
              cx + 2 + cos(a) * 6,
              cy - 7 + sin(a) * 5,
              cx + 2,
              cy - 7,
            );
          c.drawPath(p, leaf);
          c.drawPath(p, _ink..strokeWidth = 0.8);
        }
      case Region.cave:
        // 岩と水晶
        final rock = ui.Path()
          ..moveTo(cx - 11, r.bottom - 4)
          ..lineTo(cx - 8, cy - 2)
          ..lineTo(cx - 1, cy - 7)
          ..lineTo(cx + 8, cy - 3)
          ..lineTo(cx + 11, r.bottom - 4)
          ..close();
        c.drawPath(rock, ui.Paint()..color = const ui.Color(0xFF8E8780));
        c.drawPath(rock, _ink..strokeWidth = 1.2);
        final crystal = ui.Path()
          ..moveTo(cx + 2, cy - 12)
          ..lineTo(cx + 6, cy - 4)
          ..lineTo(cx + 2, cy)
          ..lineTo(cx - 2, cy - 4)
          ..close();
        c.drawPath(crystal, ui.Paint()..color = const ui.Color(0xFF9AD1D4));
        c.drawPath(crystal, _ink..strokeWidth = 0.8);
      case Region.lava:
        // 黒曜石のとげ
        final spike = ui.Path()
          ..moveTo(cx - 10, r.bottom - 4)
          ..lineTo(cx - 3, cy - 12)
          ..lineTo(cx + 1, cy - 2)
          ..lineTo(cx + 5, cy - 9)
          ..lineTo(cx + 10, r.bottom - 4)
          ..close();
        c.drawPath(spike, ui.Paint()..color = const ui.Color(0xFF1E1414));
        c.drawPath(
          spike,
          ui.Paint()
            ..color = const ui.Color(0xFFE4572E)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1,
        );
    }
  }

  void _pond(ui.Canvas c, Rect r, Region region) {
    final color = switch (region) {
      Region.grass => const ui.Color(0xFF9EC6E0),
      Region.coast => const ui.Color(0xFF5FA8CC),
      Region.cave => const ui.Color(0xFF4F6D7A),
      Region.lava => const ui.Color(0xFFE4572E),
    };
    c.drawRect(r, ui.Paint()..color = color);
    final wave = ui.Paint()
      ..color = region == Region.lava
          ? const ui.Color(0xCCFFD166)
          : const ui.Color(0xAAFFFFFF)
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

  /// 宿：小さな家と「宿」の看板
  void _inn(ui.Canvas c, Rect r) {
    final wall = Rect.fromLTWH(
      r.left + 4,
      r.top + 13,
      r.width - 8,
      r.height - 15,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(r.center.dx, r.bottom - 2),
        width: 28,
        height: 6,
      ),
      ui.Paint()..color = const ui.Color(0x33000000),
    );
    c.drawRect(wall, ui.Paint()..color = const ui.Color(0xFFF5E6C8));
    c.drawRect(wall, _ink..strokeWidth = 1.3);
    final roof = ui.Path()
      ..moveTo(r.left + 1, r.top + 14)
      ..lineTo(r.center.dx, r.top + 2)
      ..lineTo(r.right - 1, r.top + 14)
      ..close();
    c.drawPath(roof, ui.Paint()..color = const ui.Color(0xFFB5523B));
    c.drawPath(roof, _ink..strokeWidth = 1.3);
    // 扉
    c.drawRect(
      Rect.fromLTWH(r.center.dx - 3, r.bottom - 10, 6, 8),
      ui.Paint()..color = const ui.Color(0xFF8D6E63),
    );
    // 看板「宿」
    final b =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(
            ui.TextStyle(
              color: const ui.Color(0xFF6D4C41),
              fontSize: 8,
              fontWeight: ui.FontWeight.w900,
            ),
          )
          ..addText('宿');
    final p = b.build()..layout(ui.ParagraphConstraints(width: r.width));
    c.drawParagraph(p, Offset(r.left, r.top + 15));
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
      super(
        size: Vector2.all(tileSize * (stage.isBoss ? 1.45 : 1.15)),
        anchor: Anchor.center,
      );

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
      paintEnemy(
        canvas,
        s,
        stage.enemy.look,
        _t * 0.5,
        color: stage.enemy.color,
      );
      canvas.restore();
      _badge(canvas, s, '★', const ui.Color(0xFFF2B84B));
    } else {
      paintEnemy(canvas, s, stage.enemy.look, _t, color: stage.enemy.color);
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

/// 宝箱（開けると空っぽになる）
class ChestToken extends PositionComponent {
  ChestToken(this.cell)
    : super(
        size: Vector2.all(tileSize),
        anchor: Anchor.center,
        position: _center(cell),
        priority: cell.row * 10 + 3,
      );

  final Cell cell;
  bool opened = false;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    final c = canvas;
    final s = size.x;
    final ink = ui.Paint()
      ..color = TsuzuriColors.ink
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.4;
    c.drawOval(
      Rect.fromCenter(center: Offset(s / 2, s - 4), width: 24, height: 6),
      ui.Paint()..color = const ui.Color(0x33000000),
    );
    if (!opened) {
      // きらきら
      final glow = (sin(_t * 3) + 1) / 2;
      c.drawCircle(
        Offset(s / 2, s / 2),
        s * 0.5,
        ui.Paint()..color = ui.Color.fromRGBO(255, 214, 90, 0.08 + glow * 0.15),
      );
    }
    final box = Rect.fromLTWH(5, s * 0.45, s - 10, s * 0.4);
    c.drawRect(box, ui.Paint()..color = const ui.Color(0xFFB5763B));
    c.drawRect(box, ink);
    final lid = opened
        ? Rect.fromLTWH(5, s * 0.22, s - 10, s * 0.14)
        : Rect.fromLTWH(5, s * 0.3, s - 10, s * 0.17);
    c.drawRRect(
      ui.RRect.fromRectAndCorners(
        lid,
        topLeft: const ui.Radius.circular(6),
        topRight: const ui.Radius.circular(6),
      ),
      ui.Paint()..color = const ui.Color(0xFFC98A4B),
    );
    c.drawRRect(
      ui.RRect.fromRectAndCorners(
        lid,
        topLeft: const ui.Radius.circular(6),
        topRight: const ui.Radius.circular(6),
      ),
      ink,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(s / 2, s * 0.5), width: 6, height: 7),
      ui.Paint()..color = const ui.Color(0xFFF2B84B),
    );
    if (opened) {
      c.drawRect(
        Rect.fromLTWH(8, s * 0.45, s - 16, 4),
        ui.Paint()..color = const ui.Color(0xFF3A2A1E),
      );
    }
  }
}

/// 回復の泉（ゆらゆら光る）
class SpringToken extends PositionComponent {
  SpringToken(Cell cell)
    : super(
        size: Vector2.all(tileSize),
        anchor: Anchor.center,
        position: _center(cell),
        priority: cell.row * 10 + 2,
      );

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    final c = canvas;
    final s = size.x;
    final rim = Rect.fromCenter(
      center: Offset(s / 2, s * 0.6),
      width: s - 4,
      height: s * 0.62,
    );
    c.drawOval(rim, ui.Paint()..color = const ui.Color(0xFFB8B0A2));
    c.drawOval(rim.deflate(3), ui.Paint()..color = const ui.Color(0xFF7FC8E8));
    c.drawOval(
      rim,
      ui.Paint()
        ..color = TsuzuriColors.ink
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // 立ちのぼる光のつぶ
    for (var i = 0; i < 3; i++) {
      final p = (_t * 0.6 + i / 3) % 1;
      c.drawCircle(
        Offset(s * (0.3 + i * 0.2), s * 0.55 - p * s * 0.5),
        2.2 * (1 - p),
        ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, 0.9 * (1 - p)),
      );
    }
  }
}

/// 亡霊（そのステージで間違えた問題）。話しかけると再戦できる
class GhostToken extends PositionComponent {
  GhostToken(this.stage, this.cell, this.count)
    : super(
        size: Vector2.all(tileSize * 1.05),
        anchor: Anchor.center,
        position: _center(cell),
        priority: cell.row * 10 + 4,
      );

  final StageDef stage;
  final Cell cell;
  int count;
  double _t = Random().nextDouble() * 10;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    final c = canvas;
    final s = size.x;
    c.saveLayer(null, ui.Paint()..color = const ui.Color(0xD0FFFFFF));
    paintEnemy(c, s, 'ghost', _t);
    c.restore();
    final center = Offset(s * 0.85, s * 0.1);
    c.drawCircle(center, 8, ui.Paint()..color = const ui.Color(0xFF6A4BA8));
    final b =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(
            ui.TextStyle(
              color: const ui.Color(0xFFFFFFFF),
              fontSize: 9,
              fontWeight: ui.FontWeight.w900,
            ),
          )
          ..addText('$count');
    final p = b.build()..layout(const ui.ParagraphConstraints(width: 16));
    c.drawParagraph(p, center - Offset(8, p.height / 2));
  }
}

/// 捕まった仲間の檻（ゲート横の壁ぎわ）
class CageToken extends PositionComponent {
  CageToken(Cell cell)
    : super(
        size: Vector2.all(tileSize),
        anchor: Anchor.center,
        position: _center(cell),
        priority: cell.row * 10 + 6,
      );

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) {
    final c = canvas;
    final s = size.x;
    // 中の仲間（小さな妖精の影）
    final bob = sin(_t * 5) * 1.5;
    c.drawCircle(
      Offset(s / 2, s * 0.55 + bob),
      s * 0.18,
      ui.Paint()..color = const ui.Color(0xFFF7D9A8),
    );
    c.drawCircle(
      Offset(s * 0.44, s * 0.52 + bob),
      1.6,
      ui.Paint()..color = TsuzuriColors.ink,
    );
    c.drawCircle(
      Offset(s * 0.56, s * 0.52 + bob),
      1.6,
      ui.Paint()..color = TsuzuriColors.ink,
    );
    final bar = ui.Paint()
      ..color = const ui.Color(0xFF3A3A3A)
      ..strokeWidth = 2;
    c.drawRect(
      Rect.fromLTWH(4, s * 0.2, s - 8, 3),
      ui.Paint()..color = const ui.Color(0xFF3A3A3A),
    );
    for (var x = 6.0; x <= s - 6; x += 5) {
      c.drawLine(Offset(x, s * 0.2), Offset(x, s * 0.9), bar);
    }
    c.drawRect(
      Rect.fromLTWH(4, s * 0.88, s - 8, 3),
      ui.Paint()..color = const ui.Color(0xFF3A3A3A),
    );
    // 「たすけて」の吹き出し
    final b =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(
            ui.TextStyle(
              color: TsuzuriColors.stamp,
              fontSize: 7,
              fontWeight: ui.FontWeight.w900,
            ),
          )
          ..addText('たすけて！');
    final p = b.build()..layout(ui.ParagraphConstraints(width: s * 1.6));
    c.drawParagraph(p, Offset(-s * 0.3, -2 + bob));
  }
}
