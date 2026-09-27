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
import 'terrain_art.dart';

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
    required this.onPortal,
    required this.onSecret,
    required this.onDoor,
    required this.onWarp,
    required this.onNpc,
    this.from,
    this.isCleared,
    this.chestOpened,
    this.darknessOf,
    this.masteredArea,
  });

  /// エリアの暗さ（0〜1）。学力が低い単元のエリアほど暗い
  final double Function(int area)? darknessOf;

  /// その単元を身につけたか（熟練度が高いと、隠し通路がひとりでに開く）
  final bool Function(int area)? masteredArea;

  /// 隠し通路（H）を調べたとき
  final void Function(Cell cell) onSecret;

  /// 閉じた知識の扉（D）に話しかけたとき。引数は扉の先にいる（次に戦う）ステージ
  final void Function(StageDef nextStage, Cell cell) onDoor;

  /// ワープ石（X）にさわったとき
  final void Function(Cell cell) onWarp;

  /// 住人（N）に話しかけたとき。引数はその先にいるステージ（ハブなら null）
  final void Function(StageDef? nextStage, Cell cell) onNpc;

  /// 頼みごとの「！」を出す住人
  bool Function(Cell cell)? npcHasQuest;

  /// ステージをクリアしたか（試験対策ワールドでは、ワールドの中の記録で判定する）
  final bool Function(RpgProgress progress, StageDef stage)? isCleared;

  /// 宝箱を開けたか（試験対策ワールドでは、ワールドの中の記録で判定する）
  final bool Function(RpgProgress progress, String chestId)? chestOpened;

  /// 隠し通路・扉が開いたことを記録する文字列
  static String openKey(String mapId, Cell c) =>
      'open:$mapId:${c.col}:${c.row}';

  /// ワープ石にさわったことを記録する文字列
  static String warpKey(String mapId, Cell c) =>
      'warp:$mapId:${c.col}:${c.row}';

  bool _cleared(RpgProgress p, StageDef s) =>
      isCleared?.call(p, s) ?? p.clearedStageIds.contains(s.id);

  bool _chestOpened(RpgProgress p, String id) =>
      chestOpened?.call(p, id) ?? p.openedChests.contains(id);

  /// その隠し通路・扉が開いているか。
  /// 隠し通路は、その単元の熟練度が高くなると、ひとりでに開く（学力で世界が変わる）
  bool isOpen(Cell c) =>
      _progress.fieldFlags.contains(openKey(map.id, c)) ||
      (map.tileAt(c.col, c.row) == 'H' &&
          (masteredArea?.call(map.areaAt(c.col, c.row)) ?? false));

  /// 前にいたマップ（出入口のとなりから始める）。null ならスタート地点から
  final String? from;

  /// 出入口に入ったとき
  final void Function(Portal portal) onPortal;

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
  final Map<Cell, SealToken> _seals = {};
  final Map<Cell, WarpToken> _warps = {};
  final Map<Cell, EnemyToken> _elites = {};
  final Map<Cell, NpcToken> _npcs = {};

  /// 画面の十字ボタンで押されている方向
  Facing? padDirection;
  Facing? _keyDirection;

  /// ダイアログ表示中などは操作を受け付けない
  bool inputLocked = false;

  /// 今いるエリアの名前（画面上部の表示用）
  late final area = ValueNotifier<String>(map.labelAt(0, 0));

  /// 今いるエリアの番号（入ったときの演出用）
  late final areaNo = ValueNotifier<int>(-1);

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
    for (final ch in const ['H', 'D']) {
      for (final c in map.findAll(ch)) {
        final token = SealToken(
          c,
          door: ch == 'D',
          terrain: map.terrainAt(c.col, c.row),
        );
        _seals[c] = token;
        world.add(token);
      }
    }
    for (final c in map.findAll('N')) {
      final stage = _stageAhead(c);
      final token = NpcToken(
        c,
        color: stage == null
            ? Npcs.storyteller.color
            : Npcs.of(map.terrainAt(c.col, c.row)).color,
      );
      _npcs[c] = token;
      world.add(token);
    }
    for (final c in map.findAll('X')) {
      final token = WarpToken(c);
      _warps[c] = token;
      world.add(token);
    }
    for (final c in map.findAll('M')) {
      final base = _stageAhead(c);
      if (base == null) continue;
      final token = EnemyToken(stage: Elites.of(base), home: c);
      _elites[c] = token;
      world.add(token);
    }
    if (darknessOf != null) world.add(LightLayer(map, darknessOf!));
    player = PlayerToken(from == null ? map.start : map.spawnFrom(from));
    world.add(player);
    applyProgress(_progress);
    camera.follow(player, snap: true);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // スマホ縦持ちで横 9 マス程度が見えるように
    // 小さいマップ（理の国のスタート地点など）は、横幅全体が見えるようにする
    final across = map.width <= 13 ? map.width : 9;
    camera.viewfinder.zoom = min(
      size.x / (across * tileSize),
      size.y / (max(11, across + 2) * tileSize),
    );
  }

  /// 進行状況に合わせて、倒した敵を道の脇へどかす
  void applyProgress(RpgProgress progress) {
    _progress = progress;
    for (final e in _seals.entries) {
      e.value.open = isOpen(e.key);
    }
    for (final e in _warps.entries) {
      e.value.active = progress.fieldFlags.contains(warpKey(map.id, e.key));
    }
    for (final e in _npcs.entries) {
      e.value.quest = npcHasQuest?.call(e.key) ?? false;
    }
    for (final token in _elites.values) {
      final cleared = _cleared(progress, token.stage);
      token.cleared = cleared;
      token.position = _center(token.cell);
      token.priority = token.cell.row * 10 + 4;
      // 倒した強敵はいなくなる
      if (cleared) {
        token.removeFromParent();
      } else if (token.parent == null) {
        world.add(token);
      }
    }
    for (final token in _enemies.values) {
      final cleared = _cleared(progress, token.stage);
      token.cleared = cleared;
      token.cell = cleared ? map.asideOf(token.home) : token.home;
      token.position = _center(token.cell);
      token.priority = token.cell.row * 10 + 4;
    }
    for (final e in _chests.entries) {
      e.value.opened = _chestOpened(progress, chestIdAt(e.key));
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
        final gate = map.enemySpots[stage.order];
        if (gate == null) continue;
        final token = CageToken(map.cageOf(gate));
        _cages[stage.order] = token;
        world.add(token);
      }
    }
  }

  /// 宝箱の保存用 ID（その先にいる敵の番号と、宝箱の種類で決まる）
  String chestIdAt(Cell c) {
    final base = '${rpgWorld.id}_chest_${map.enemyAhead(c)}';
    return switch (map.chestKinds[c]) {
      ChestKind.secret => '${base}_secret',
      ChestKind.vault => '${base}_vault',
      _ => base,
    };
  }

  /// ワープ石から別のワープ石へ飛ぶ（その石のとなりに立つ）
  void warpTo(Cell stone) {
    final spot = map.floorNextTo(stone);
    if (spot == null) return;
    player
      ..cell = spot
      ..position = _center(spot)
      ..facing = Facing.down;
    camera.follow(player, snap: true);
  }

  /// さわったことのあるワープ石（エリアの順）
  List<Cell> get activeWarps => [
    for (final e in _warps.entries)
      if (e.value.active) e.key,
  ]..sort((a, b) => b.row.compareTo(a.row));

  StageDef? _stageAhead(Cell c) {
    final n = map.enemyAhead(c);
    return rpgWorld.stages.where((s) => s.order == n).firstOrNull;
  }

  EnemyToken? _enemyAt(Cell c) {
    for (final e in _enemies.values) {
      if (e.cell == c) return e;
    }
    final elite = _elites[c];
    if (elite != null && !elite.cleared) return elite;
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
    final label = map.labelAt(player.cell.col, player.cell.row);
    if (area.value != label) area.value = label;
    final no = map.areaAt(player.cell.col, player.cell.row);
    if (areaNo.value != no) areaNo.value = no;
    final dir = padDirection ?? _keyDirection;
    if (dir != _bumpedDirection) _bumpedDirection = null;
    if (!inputLocked &&
        !player.moving &&
        dir != null &&
        dir != _bumpedDirection) {
      _tryStep(dir);
    }
    // 近くにいる敵には「！」を出す
    for (final e in [..._enemies.values, ..._elites.values]) {
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
      case 'H' || 'D' when isOpen(target):
        player.walkTo(target);
        return;
      case 'H':
        _bumpedDirection = dir;
        onSecret(target);
        return;
      case 'D':
        _bumpedDirection = dir;
        final stage = _stageAhead(target);
        if (stage != null) onDoor(stage, target);
        return;
      case 'X':
        _bumpedDirection = dir;
        onWarp(target);
        return;
      case 'N':
        _bumpedDirection = dir;
        onNpc(_stageAhead(target), target);
        return;
      case 'I':
        _bumpedDirection = dir;
        final n = map.enemyAhead(target);
        final stage = rpgWorld.stages.where((s) => s.order == n).firstOrNull;
        if (stage != null) onInn(stage);
        return;
      case 'S':
        _bumpedDirection = dir;
        onMessage(map.signText);
        return;
      case 'C':
        _bumpedDirection = dir;
        final stage = _stageAhead(target);
        final id = chestIdAt(target);
        if (stage != null) {
          onChest(stage, id, _chestOpened(_progress, id));
        }
        return;
      case 'W':
        _bumpedDirection = dir;
        final stage = _stageAhead(target);
        if (stage != null) onSpring(stage);
        return;
      case 'G':
        _bumpedDirection = dir;
        final bossCleared = rpgWorld.stages
            .where((s) => map.enemySpots.containsKey(s.order))
            .every((s) => _cleared(_progress, s));
        onMessage(
          bossCleared
              ? '${map.goalText}がきらきら光っている。制覇おめでとう！'
              : '${map.goalText}がある。…でも、まだ手が届かない。',
        );
        return;
      case 'O':
        _bumpedDirection = dir;
        final portal = map.portals[target];
        if (portal != null) onPortal(portal);
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
    final goals = map.findAll('G');
    if (goals.isEmpty) return;
    final g = goals.first;
    final glow = (sin(_t * 3) + 1) / 2;
    canvas.drawCircle(
      Offset((g.col + 0.5) * tileSize, (g.row + 0.5) * tileSize),
      tileSize * (0.55 + glow * 0.1),
      ui.Paint()..color = ui.Color.fromRGBO(255, 214, 90, 0.15 + glow * 0.2),
    );
    _trophy(canvas, g);
  }

  void _paintMap(ui.Canvas c) {
    // 床（方眼ノートの目）をマスごとに描く。地形ごとに色と模様が変わる
    for (var r = 0; r < map.height; r++) {
      for (var col = 0; col < map.width; col++) {
        final terrain = map.terrainAt(col, r);
        final x = col * tileSize, y = r * tileSize;
        final rect = Rect.fromLTWH(x, y, tileSize, tileSize);
        c.drawRect(rect, ui.Paint()..color = TerrainArt.floor(terrain));
        final grid = ui.Paint()..color = TerrainArt.grid(terrain);
        c.drawLine(
          Offset(x, y),
          Offset(x + tileSize, y),
          grid..strokeWidth = 1,
        );
        c.drawLine(
          Offset(x, y),
          Offset(x, y + tileSize),
          grid..strokeWidth = 1,
        );
        c.drawLine(
          Offset(x, y + tileSize / 2),
          Offset(x + tileSize, y + tileSize / 2),
          grid..strokeWidth = 0.4,
        );
        c.drawLine(
          Offset(x + tileSize / 2, y),
          Offset(x + tileSize / 2, y + tileSize),
          grid..strokeWidth = 0.4,
        );
        TerrainArt.floorDetail(c, rect, terrain, col, r);
      }
    }
    final rnd = Random(7);
    for (var r = 0; r < map.height; r++) {
      for (var col = 0; col < map.width; col++) {
        final terrain = map.terrainAt(col, r);
        final rect = Rect.fromLTWH(
          col * tileSize,
          r * tileSize,
          tileSize,
          tileSize,
        );
        switch (map.tileAt(col, r)) {
          case '#':
            TerrainArt.wall(c, rect, rnd, terrain);
          case 'T':
            TerrainArt.obstacle(c, rect, rnd, terrain);
          case '~':
            TerrainArt.water(c, rect, terrain);
          case 'B':
            TerrainArt.bridge(c, rect, terrain);
          case 'R':
            TerrainArt.carpet(c, rect);
          case 'F':
            TerrainArt.decoration(
              c,
              rect,
              terrain,
              boss: map.bossAreas.contains(map.areaAt(col, r)),
            );
          case 'S':
            _sign(c, rect);
          case 'I':
            _inn(c, rect);
          case 'O':
            _portal(c, rect, map.portals[(col: col, row: r)]?.label ?? '');
        }
      }
    }
  }

  static final _ink = ui.Paint()
    ..color = TsuzuriColors.ink
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = ui.StrokeCap.round;

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

  /// 出入口：アーチと行き先の札
  void _portal(ui.Canvas c, Rect r, String label) {
    c.drawRect(r, ui.Paint()..color = const ui.Color(0xFFFFF3C4));
    final arch = ui.Path()
      ..moveTo(r.left + 3, r.bottom)
      ..lineTo(r.left + 3, r.top + 12)
      ..arcToPoint(
        Offset(r.right - 3, r.top + 12),
        radius: ui.Radius.circular(r.width / 2 - 3),
      )
      ..lineTo(r.right - 3, r.bottom);
    c.drawPath(
      arch,
      ui.Paint()
        ..color = const ui.Color(0xFFB5763B)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final b =
        ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
          ..pushStyle(
            ui.TextStyle(
              color: const ui.Color(0xFF6D4C41),
              fontSize: label.length > 3 ? 6 : 9,
              fontWeight: ui.FontWeight.w900,
            ),
          )
          ..addText(label);
    final p = b.build()..layout(ui.ParagraphConstraints(width: r.width));
    c.drawParagraph(p, Offset(r.left, r.center.dy - p.height / 2 + 3));
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

/// 隠し通路（H）と知識の扉（D）。閉じている間は障害物・扉の絵を上に重ねる
class SealToken extends PositionComponent {
  SealToken(this.cell, {required this.door, required this.terrain})
    : super(
        size: Vector2.all(tileSize),
        position: Vector2(cell.col * tileSize, cell.row * tileSize),
        priority: cell.row * 10 + 3,
      );

  final Cell cell;
  final bool door;
  final Terrain terrain;
  bool open = false;

  @override
  void render(ui.Canvas canvas) {
    final r = Rect.fromLTWH(0, 0, tileSize, tileSize);
    if (door) {
      open ? TerrainArt.doorOpen(canvas, r) : TerrainArt.door(canvas, r);
      return;
    }
    if (open) return;
    // 見た目はまわりと同じ障害物。よく見ると小さなひびがある
    TerrainArt.obstacle(canvas, r, Random(cell.col * 31 + cell.row), terrain);
    TerrainArt.crack(canvas, r);
  }
}

/// ワープ石
class WarpToken extends PositionComponent {
  WarpToken(this.cell)
    : super(
        size: Vector2.all(tileSize),
        position: Vector2(cell.col * tileSize, cell.row * tileSize),
        priority: cell.row * 10 + 3,
      );

  final Cell cell;
  bool active = false;
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) => TerrainArt.warpStone(
    canvas,
    Rect.fromLTWH(0, 0, tileSize, tileSize),
    active: active,
    glow: (sin(_t * 2.5) + 1) / 2,
  );
}

/// 学力で世界が変わる：熟練度の低い単元のエリアは暗く、上がると明るくなる
class LightLayer extends PositionComponent {
  LightLayer(this.map, this.darknessOf)
    : super(
        size: Vector2(map.width * tileSize, map.height * tileSize),
        priority: 1 << 20,
      );

  final FieldMap map;
  final double Function(int area) darknessOf;

  @override
  void render(ui.Canvas canvas) {
    // 同じ暗さが横に続くところは、まとめて1つの四角で塗る（大きなマップでも軽く）
    for (var r = 0; r < map.height; r++) {
      var c = 0;
      while (c < map.width) {
        final d = darknessOf(map.areaAt(c, r));
        var end = c + 1;
        while (end < map.width && darknessOf(map.areaAt(end, r)) == d) {
          end++;
        }
        if (d > 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * tileSize,
              r * tileSize,
              (end - c) * tileSize,
              tileSize,
            ),
            ui.Paint()..color = ui.Color.fromRGBO(20, 16, 40, d),
          );
        }
        c = end;
      }
    }
  }
}

/// 住人（NPC）。ゆっくり上下にゆれる
class NpcToken extends PositionComponent {
  NpcToken(this.cell, {required this.color})
    : super(
        size: Vector2.all(tileSize),
        position: Vector2(cell.col * tileSize, cell.row * tileSize),
        priority: cell.row * 10 + 4,
      );

  final Cell cell;
  final int color;

  /// 頼みごとの「！」を出すか
  bool quest = false;
  double _t = Random().nextDouble() * 5;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(ui.Canvas canvas) => TerrainArt.npc(
    canvas,
    Rect.fromLTWH(0, 0, tileSize, tileSize),
    color: color,
    bob: (sin(_t * 2) + 1) * 0.8,
    quest: quest,
  );
}
