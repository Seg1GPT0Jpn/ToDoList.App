import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';

import '../game/enemy_ai.dart';
import '../game/field3d.dart';
import '../game/map_v2.dart';
import 'hero_model.dart';
import 'land_builder.dart';

import 'package:vector_math/vector_math.dart' as vm;

/// 3D のフィールド（描画と物理）。ルール・保存は game/field3d.dart の [Field3DRegion] と
/// [Field3DState] が持ち、ここは見た目と当たり判定だけを受け持つ。
///
/// 試作の草原は平らな地面。はじまりの大地（[Field3DRegion.terrain]）は MapV2 の
/// 高さの格子から地形を作り、通れない場所（川・崖・森の奥など）には [navigable] で入れない。
class Field3DWorld {
  Field3DWorld._(this.region, this.scene, this._physics);

  final Field3DRegion region;
  final Scene scene;
  final PhysicsWorld _physics;

  late final Node _player;
  late final KinematicCharacterController _kcc;
  late final Node _visual;
  final _hero = HeroModel();
  final _enemies = <String, _Slime>{};
  final _npcMarks = <String, Node>{};

  /// 高さの格子（地形のある地域だけ）
  HeightGrid? grid;
  LandBuilder? land;

  /// 歩けるか（地形のある地域で、画面側が条件つきで渡す）。null なら制限なし
  bool Function(double x, double z)? navigable;

  /// 敵が動いてよいか（バトル中・会話中は止める）
  bool enemiesPaused = false;

  /// 地面の高さ（橋の上は橋の高さ）
  double groundY(double x, double z) {
    final g = grid;
    if (g == null) return 0;
    if (MapV2.onBridge(x, z)) return MapV2.bridgeY;
    return g.heightAt(x, z);
  }

  // 入力と動き
  vm.Vector3 _wish = vm.Vector3.zero();
  bool _run = false;
  double _vy = 0;
  double _heading = 0;
  double _speed = 0;
  double _moved = 0;
  double _time = 0;

  static const _radius = 0.35;
  static const _halfHeight = 0.35;

  /// 足元から体の中心までの高さ
  static const _centerY = _radius + _halfHeight + 0.02;
  static const walkSpeed = 4.0;
  static const runSpeed = 7.0;

  /// 物理とモデルを準備して、草原を組み立てる
  static Future<Field3DWorld> create(
    Field3DRegion region,
    Field3DState state,
  ) async {
    await Scene.initializeStaticResources();
    await RapierWorld.ensureInitialized();
    final scene = Scene();
    final physics = PhysicsWorld(RapierWorld(gravity: vm.Vector3(0, -9.81, 0)));
    scene.root.addComponent(physics);
    final w = Field3DWorld._(region, scene, physics);
    w._buildSky();
    if (region.terrain) {
      final grid = w.grid = HeightGrid.build();
      w.land = LandBuilder(scene, grid)..build();
      w._buildFog();
    } else {
      w._buildGround();
    }
    for (final p in region.props) {
      w._buildProp(p);
    }
    for (final n in region.npcs) {
      w._buildNpc(n, talked: state.talked.contains(n.id));
    }
    for (final e in region.enemies) {
      w._buildEnemy(e);
    }
    w.showDefeated(state.defeated);
    await w._buildPlayer(state);
    return w;
  }

  void dispose() {}

  /// 遠くを霧でぼかす（見える距離を絞って、描く量をへらす）
  void _buildFog() {
    scene.fog
      ..enabled = true
      ..mode = FogMode.linear
      ..start = viewDistance * 0.3
      ..end = viewDistance - 20
      ..color = vm.Vector3(0.72, 0.84, 0.95);
  }

  /// 地形の当たり判定と、見た目の高さがそろっているかを調べる（起動後に 1 回）。
  /// いくつかの点で真上から光線を落とし、格子の高さとの差の最大（m）を返す
  double? terrainSelfCheck() {
    final g = grid;
    if (g == null) return null;
    var worst = 0.0;
    for (final (x, z) in const [
      (85.0, 310.0),
      (170.0, 250.0),
      (275.0, 160.0),
      (300.0, 300.0),
      (335.0, 102.0),
      (60.0, 60.0),
      (380.0, 380.0),
      (250.0, 192.0),
    ]) {
      try {
        final hit = _physics.raycast(
          vm.Ray.originDirection(vm.Vector3(x, 80, z), vm.Vector3(0, -1, 0)),
          maxDistance: 200,
          includeKinematic: false,
        );
        if (hit == null) return double.infinity;
        final hy = 80 - hit.distance;
        worst = math.max(worst, (hy - g.heightAt(x, z)).abs());
      } catch (_) {
        return null;
      }
    }
    return worst;
  }

  // ---- 画質（実機での計測用に切りかえられる） ----

  DirectionalLight? _sun;

  /// 'high'：影あり・高画質、'standard'：影あり・中画質、'light'：影なし・低画質・解像度 70%
  /// 見える距離（m）。広い地域では画質に合わせて変え、その先は霧でかくす
  double viewDistance = 260;

  void setQuality(String q) {
    final sun = _sun;
    switch (q) {
      case 'high':
        scene.renderQuality.tier = RenderQualityTier.high;
        scene.renderScale = 1.0;
        sun?.castsShadow = true;
        viewDistance = 300;
      case 'light':
        scene.renderQuality.tier = RenderQualityTier.low;
        scene.renderScale = 0.7;
        sun?.castsShadow = false;
        viewDistance = 150;
      default:
        scene.renderQuality.tier = RenderQualityTier.medium;
        scene.renderScale = 1.0;
        sun?.castsShadow = true;
        viewDistance = 230;
    }
    if (region.terrain) {
      scene.fog
        ..start = viewDistance * 0.3
        ..end = viewDistance - 20;
    }
  }

  // ---- 見た目 ----

  static PhysicallyBasedMaterial _mat(
    double r,
    double g,
    double b, {
    double roughness = 0.85,
    double emissive = 0,
  }) {
    final m = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(r, g, b, 1)
      ..roughnessFactor = roughness
      ..metallicFactor = 0;
    if (emissive > 0) {
      m.emissiveFactor = vm.Vector4(
        r * emissive,
        g * emissive,
        b * emissive,
        1,
      );
    }
    return m;
  }

  void _buildSky() {
    scene.skybox = Skybox(
      GradientSkySource(
        zenithColor: vm.Vector3(0.18, 0.42, 0.85),
        horizonColor: vm.Vector3(0.72, 0.84, 0.95),
        groundColor: vm.Vector3(0.30, 0.38, 0.22),
      ),
    );
    scene.directionalLight = _sun = DirectionalLight(
      direction: vm.Vector3(-0.35, -1.0, 0.45),
      color: vm.Vector3(1.0, 0.96, 0.88),
      intensity: 3.2,
      castsShadow: true,
      shadowMaxDistance: 45,
      shadowCascadeCount: 2,
    );
  }

  /// 動かない物を置く（見た目＋当たり判定）
  Node _static(
    Mesh? mesh,
    vm.Matrix4 transform,
    Shape? shape, {
    String name = '',
  }) {
    final node = Node(name: name, localTransform: transform, mesh: mesh);
    if (shape != null) {
      node.addComponent(RigidBody(type: BodyType.fixed));
      node.addComponent(Collider(shape: shape));
    }
    node.shadowStatic = true;
    scene.add(node);
    return node;
  }

  void _buildGround() {
    final s = region.halfSize;
    _static(
      Mesh(
        CuboidGeometry(vm.Vector3(s * 2, 0.2, s * 2)),
        _mat(0.36, 0.62, 0.28),
      ),
      vm.Matrix4.translation(vm.Vector3(0, -0.1, 0)),
      BoxShape(halfExtents: vm.Vector3(s + 0.5, 0.1, s + 0.5)),
      name: 'ground',
    );
    // 外周の柵（東西は少し低くして、角で上面が重ならないようにする）
    final wood = _mat(0.55, 0.38, 0.22);
    const t = 0.3;
    for (final sign in [-1.0, 1.0]) {
      _static(
        Mesh(CuboidGeometry(vm.Vector3(s * 2 + t * 2, 1.1, t)), wood),
        vm.Matrix4.translation(vm.Vector3(0, 0.55, sign * (s + t / 2))),
        BoxShape(halfExtents: vm.Vector3(s + t, 1.5, t / 2)),
        name: 'fence',
      );
      _static(
        Mesh(CuboidGeometry(vm.Vector3(t, 1.0, s * 2)), wood),
        vm.Matrix4.translation(vm.Vector3(sign * (s + t / 2), 0.5, 0)),
        BoxShape(halfExtents: vm.Vector3(t / 2, 1.5, s)),
        name: 'fence',
      );
    }
  }

  void _buildProp(Prop3D p) {
    final at = vm.Vector3(p.x, groundY(p.x, p.z), p.z);
    switch (p.kind) {
      case Prop3DKind.tree:
        final h = 2.2 * p.size, r = 0.28 * p.size;
        _static(
          Mesh(
            CylinderGeometry(bottomRadius: r, topRadius: r * 0.8, height: h),
            _mat(0.45, 0.30, 0.18),
          ),
          vm.Matrix4.translation(at + vm.Vector3(0, h / 2, 0)),
          CylinderShape(radius: r, halfHeight: h / 2),
          name: 'tree',
        );
        _static(
          Mesh(
            IcosphereGeometry(radius: 1.3 * p.size, subdivisions: 2),
            _mat(0.20, 0.50, 0.22),
          ),
          vm.Matrix4.translation(at + vm.Vector3(0, h + 0.7 * p.size, 0)),
          null,
          name: 'leaves',
        );
      case Prop3DKind.rock:
        final r = 0.8 * p.size;
        _static(
          Mesh(
            IcosphereGeometry(radius: r, subdivisions: 1),
            _mat(0.52, 0.52, 0.55, roughness: 0.95),
          ),
          vm.Matrix4.translation(at + vm.Vector3(0, r * 0.45, 0)),
          SphereShape(radius: r * 0.95),
          name: 'rock',
        );
      case Prop3DKind.ramp:
        // ゆるい坂（約14度）と、その先の台
        const len = 6.0, width = 3.0, rise = 1.5;
        final angle = math.atan2(rise, len);
        final slope = math.sqrt(len * len + rise * rise);
        final m = vm.Matrix4.translation(at + vm.Vector3(0, rise / 2, 0))
          ..rotateY(p.yaw)
          ..rotateX(-angle);
        final stone = _mat(0.70, 0.66, 0.58);
        _static(
          Mesh(CuboidGeometry(vm.Vector3(width, 0.3, slope)), stone),
          m,
          BoxShape(halfExtents: vm.Vector3(width / 2, 0.15, slope / 2)),
          name: 'ramp',
        );
        final top = vm.Matrix4.translation(at + vm.Vector3(0, rise - 0.15, 0))
          ..rotateY(p.yaw)
          ..translateByVector3(vm.Vector3(0, 0, len / 2 + 1.5));
        _static(
          Mesh(CuboidGeometry(vm.Vector3(width, 0.3, 3.0)), stone),
          top,
          BoxShape(halfExtents: vm.Vector3(width / 2, 0.15, 1.5)),
          name: 'ramp_top',
        );
        // 台の下（空中に浮かないように）
        final base =
            vm.Matrix4.translation(at + vm.Vector3(0, (rise - 0.3) / 2, 0))
              ..rotateY(p.yaw)
              ..translateByVector3(vm.Vector3(0, 0, len / 2 + 1.5));
        _static(
          Mesh(CuboidGeometry(vm.Vector3(width - 0.1, rise - 0.3, 2.9)), stone),
          base,
          BoxShape(
            halfExtents: vm.Vector3(width / 2 - 0.05, (rise - 0.3) / 2, 1.45),
          ),
          name: 'ramp_base',
        );
    }
  }

  void _buildNpc(Npc3D n, {required bool talked}) {
    final root = Node(
      name: 'npc_${n.id}',
      localTransform: vm.Matrix4.translation(
        vm.Vector3(n.x, groundY(n.x, n.z), n.z),
      ),
    );
    root.add(
      Node(
        mesh: Mesh(
          CylinderGeometry(bottomRadius: 0.38, topRadius: 0.3, height: 1.1),
          _mat(0.25, 0.40, 0.75),
        ),
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.55, 0)),
      ),
    );
    root.add(
      Node(
        mesh: Mesh(SphereGeometry(radius: 0.28), _mat(0.96, 0.82, 0.68)),
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 1.38, 0)),
      ),
    );
    root.add(
      Node(
        mesh: Mesh(
          CylinderGeometry(bottomRadius: 0.36, topRadius: 0.0, height: 0.45),
          _mat(0.80, 0.20, 0.22),
        ),
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 1.82, 0)),
      ),
    );
    // まだ話していない人の上に「！」
    final mark = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(0.12, 0.4, 0.12)),
        _mat(1.0, 0.85, 0.2, emissive: 1.5),
      ),
      localTransform: vm.Matrix4.translation(vm.Vector3(0, 2.5, 0)),
    )..visible = !talked;
    root.add(mark);
    _npcMarks[n.id] = mark;
    root.addComponent(RigidBody(type: BodyType.fixed));
    root.addComponent(
      Collider(
        shape: const CylinderShape(radius: 0.4, halfHeight: 1.0),
        localPose: null,
      ),
    );
    scene.add(root);
  }

  /// 人の上の「！」（話していない・クエストを報告できる）
  void setNpcMark(String id, bool visible) => _npcMarks[id]?.visible = visible;

  static (double, double, double) _enemyRgb(String worldId) =>
      switch (worldId) {
        'english' => (0.30, 0.55, 0.95),
        'math' => (0.92, 0.35, 0.35),
        'social' => (0.40, 0.80, 0.40),
        'japanese' => (0.95, 0.65, 0.25),
        'science' => (0.65, 0.45, 0.90),
        _ => (0.8, 0.8, 0.8),
      };

  /// バトル画面で使う色
  static Color enemyColor(String worldId) {
    final (r, g, b) = _enemyRgb(worldId);
    return Color.fromARGB(
      255,
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }

  void _buildEnemy(Enemy3D e) {
    var color = _enemyRgb(e.worldId);
    if (e.boss) color = (color.$1 * 0.75, color.$2 * 0.75, color.$3 * 0.75);
    final root = Node(
      name: 'enemy_${e.id}',
      localTransform: vm.Matrix4.translation(
        vm.Vector3(e.x, groundY(e.x, e.z), e.z),
      ),
    );
    // 見た目（向きを変えるための台）。ボスは大きい
    final turn = Node(name: 'turn')..scale = vm.Vector3.all(e.size);
    final body = Node(
      name: 'body',
      mesh: Mesh(
        SphereGeometry(radius: 0.5),
        _mat(color.$1, color.$2, color.$3, roughness: 0.35),
      ),
      localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.5, 0)),
    );
    // 目は +Z（正面）
    for (final dx in [-0.17, 0.17]) {
      body.add(
        Node(
          mesh: Mesh(SphereGeometry(radius: 0.08), _mat(0.05, 0.05, 0.08)),
          localTransform: vm.Matrix4.translation(vm.Vector3(dx, 0.12, 0.44)),
        ),
      );
    }
    turn.add(body);
    root.add(turn);
    // 当たり判定（体当たりしても通り抜けない）。倒したら外す。
    // 歩き回る敵は当たり判定を持たない（ぶつかるとバトルになる）
    final hitbox = Node(
      name: 'hitbox',
      localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.5 * e.size, 0)),
    );
    if (!e.wanders) {
      hitbox.addComponent(RigidBody(type: BodyType.fixed));
      hitbox.addComponent(Collider(shape: SphereShape(radius: 0.5 * e.size)));
      root.add(hitbox);
    }
    scene.add(root);
    final brain = e.wanders
        ? EnemyBrain(
            homeX: e.homeX,
            homeZ: e.homeZ,
            radius: e.zoneR,
            x: e.x,
            z: e.z,
            seed: e.id.hashCode,
            walkable: (x, z) => navigable?.call(x, z) ?? true,
          )
        : null;
    final slime = _Slime(e, root, turn, body, hitbox, brain);
    // はじめは出発点のほうを向いておく
    slime.yaw = math.atan2(region.spawnX - e.x, region.spawnZ - e.z);
    _enemies[e.id] = slime;
  }

  /// 敵のいまの位置
  (double, double)? enemyPosition(String id) {
    final s = _enemies[id];
    if (s == null) return null;
    return (s.px, s.pz);
  }

  /// 主人公を追いかけている敵か
  bool enemyChasing(String id) => _enemies[id]?.brain?.chasing ?? false;

  /// しばらく追いかけさせない（にげた・負けた直後）
  void calmEnemy(String id, double seconds) =>
      _enemies[id]?.brain?.calm(seconds);

  /// 倒した敵を消す（すぐに）
  void showDefeated(Set<String> defeated) {
    for (final MapEntry(:key, :value) in _enemies.entries) {
      final alive = !defeated.contains(key);
      // たおれる途中の敵は、演出が終わってから自分で消える
      if (!alive && value.dying) continue;
      value.setAlive(alive);
    }
  }

  // ---- バトルの演出 ----

  String? _engaged;

  /// 戦っている敵（null で解除）。戦っている敵はこちらを向いて構える
  void engage(String? id) => _engaged = id;

  /// 敵までの水平距離（いなければ無限大）
  double distanceTo(String id) {
    final s = _enemies[id];
    if (s == null || !s.alive) return double.infinity;
    final p = playerFeet;
    final dx = p.x - s.px, dz = p.z - s.pz;
    return math.sqrt(dx * dx + dz * dz);
  }

  /// 剣（えんぴつ）をふる。[targetId] の敵が届く距離にいれば、その敵のほうを向いて true
  bool swingAt(String? targetId, {double reach = 2.4}) {
    if (_hero.swinging) return false;
    _hero.swing();
    if (targetId == null) return false;
    final s = _enemies[targetId]!;
    if (distanceTo(targetId) > reach + 0.5 * (s.enemy.size - 1)) return false;
    facePoint(s.px, s.pz);
    return true;
  }

  bool get swinging => _hero.swinging;

  /// 攻撃が当たった（敵がのけぞる）
  void enemyHurt(String id) => _enemies[id]?.hurt();

  /// 敵の反撃（体当たり）
  void enemyAttack(String id) => _enemies[id]?.lunge();

  /// 敵を倒した（しぼんで消える）
  void enemyDefeat(String id) => _enemies[id]?.defeat();

  Future<void> _buildPlayer(Field3DState s) async {
    _heading = s.heading;
    _player = Node(
      name: 'player',
      localTransform: vm.Matrix4.translation(
        vm.Vector3(
          s.x,
          (grid == null ? s.y : groundY(s.x, s.z) + 0.05) + _centerY,
          s.z,
        ),
      ),
    );
    _player.addComponent(RigidBody(type: BodyType.kinematic));
    _player.addComponent(
      Collider(
        shape: const CapsuleShape(radius: _radius, halfHeight: _halfHeight),
      ),
    );
    _kcc = KinematicCharacterController(
      maxSlopeClimbAngle: 35 * math.pi / 180,
      snapToGround: 0.3,
      autostep: true,
      autostepMaxHeight: 0.25,
    );
    _player.addComponent(_kcc);
    _player.addComponent(_Mover(_fixedStep, _frame));
    _visual = Node(name: 'player_visual');
    _player.add(_visual);
    // 2D 版の主人公の 3D 版（足元を地面に合わせる）
    _hero.root.localTransform = vm.Matrix4.translation(
      vm.Vector3(0, -_centerY, 0),
    );
    _visual.add(_hero.root);
    scene.add(_player);
    _applyHeading();
  }

  // ---- 動き ----

  vm.Vector3 get playerFeet =>
      _player.globalTransform.getTranslation() - vm.Vector3(0, _centerY, 0);

  double get heading => _heading;

  /// 入力（右・前。-1〜1）。カメラの向きを基準に動く
  void setMoveInput(
    double x,
    double y, {
    required double cameraYaw,
    required bool run,
  }) {
    final fwd = vm.Vector3(math.sin(cameraYaw), 0, math.cos(cameraYaw));
    // flutter_scene の画面右向き（左手系）：up × forward
    final right = vm.Vector3(0, 1, 0).cross(fwd)..normalize();
    final wish = right * x + fwd * y;
    if (wish.length > 1) wish.normalize();
    _wish = wish;
    _run = run;
  }

  void _fixedStep(double dt) {
    final speed = _run ? runSpeed : walkSpeed;
    var horiz = _wish * (speed * dt);
    // 通れない場所（川・崖・森の奥など）へは進まない。かべに沿ってすべる
    final nav = navigable;
    if (nav != null && horiz.length2 > 0) {
      final p = playerFeet;
      bool ok(double dx, double dz) {
        final len = math.sqrt(dx * dx + dz * dz);
        if (len < 1e-9) return true;
        final ahead = (len + _radius + 0.05) / len;
        return nav(p.x + dx * ahead, p.z + dz * ahead);
      }

      if (!ok(horiz.x, horiz.z)) {
        if (ok(horiz.x, 0)) {
          horiz = vm.Vector3(horiz.x, 0, 0);
        } else if (ok(0, horiz.z)) {
          horiz = vm.Vector3(0, 0, horiz.z);
        } else {
          horiz = vm.Vector3.zero();
        }
      }
    }
    _vy = math.max(-20, _vy - 9.81 * dt);
    final m = _kcc.move(
      vm.Vector3(horiz.x, _vy * dt, horiz.z),
      deltaSeconds: dt,
    );
    if (m.grounded && _vy < 0) _vy = 0;
    final moved = vm.Vector3(m.translation.x, 0, m.translation.z).length;
    _moved += moved;
    _speed = moved / dt;
    if (_wish.length > 0.05) {
      // 進む向き（入力の向き）を向く。体の正面は +Z
      final target = math.atan2(_wish.x, _wish.z);
      var d = target - _heading;
      while (d > math.pi) {
        d -= 2 * math.pi;
      }
      while (d < -math.pi) {
        d += 2 * math.pi;
      }
      _heading += d * (1 - math.exp(-14 * dt));
      _applyHeading();
    }
    // 地図の外・地面の下に落ちたら出発点へ
    final f = playerFeet;
    if (f.y < groundY(f.x, f.z) - 5) teleport(region.spawnX, region.spawnZ);
  }

  void _frame(double dt) {
    _time += dt;
    _hero.update(dt, moved: _moved, speed: _speed);
    _moved = 0;
    final p = playerFeet;
    var i = 0;
    for (final s in _enemies.values) {
      final b = s.brain;
      if (b != null && s.alive) {
        b.update(
          dt,
          px: p.x,
          pz: p.z,
          frozen: enemiesPaused || _engaged != null,
        );
        if (b.mode != EnemyMode.idle && s.enemy.id != _engaged) {
          s.yaw = b.heading;
        }
        s.root.position = vm.Vector3(b.x, groundY(b.x, b.z), b.z);
      }
      s.update(
        dt,
        _time + i,
        engaged: s.enemy.id == _engaged,
        px: p.x,
        pz: p.z,
      );
      i++;
    }
  }

  void _applyHeading() {
    _visual.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), _heading);
  }

  /// 指定した場所へ瞬間移動（負けたとき・やり直し）
  void teleport(double x, double z, {double? heading}) {
    _player.position = vm.Vector3(x, groundY(x, z) + _centerY + 0.05, z);
    _vy = 0;
    if (heading != null) {
      _heading = heading;
      _applyHeading();
    }
  }

  void facePoint(double x, double z) {
    final p = playerFeet;
    _heading = math.atan2(x - p.x, z - p.z);
    _applyHeading();
  }

  /// カメラと注視点のあいだに物があれば、その手前までの距離
  double cameraDistance(vm.Vector3 target, vm.Vector3 back, double want) {
    try {
      final hit = _physics.raycast(
        vm.Ray.originDirection(target, back.normalized()),
        maxDistance: want,
        includeKinematic: false,
      );
      if (hit == null) return want;
      return math.max(1.2, hit.distance - 0.3);
    } catch (_) {
      return want;
    }
  }
}

/// 物理の固定ステップと毎フレームの処理を、草原に渡す
class _Mover extends Component {
  _Mover(this.onFixed, this.onFrame);
  final void Function(double dt) onFixed;
  final void Function(double dt) onFrame;

  @override
  void fixedUpdate(double fixedDt) => onFixed(fixedDt);

  @override
  void update(double deltaSeconds) => onFrame(deltaSeconds);
}

/// 草原のスライム（見た目・ぴょこぴょこ・バトルの演出）
class _Slime {
  _Slime(this.enemy, this.root, this.turn, this.body, this.hitbox, this.brain);

  final Enemy3D enemy;
  final Node root, turn, body, hitbox;

  /// 歩き回る敵の動き（その場にいる敵は null）
  final EnemyBrain? brain;

  double get px => brain?.x ?? enemy.x;
  double get pz => brain?.z ?? enemy.z;
  double yaw = 0;
  bool alive = true;
  double _hurt = -1, _lunge = -1, _die = -1;

  void setAlive(bool v) {
    if (v == alive && _die < 0) return;
    alive = v;
    _die = -1;
    root.visible = v;
    body.scale = vm.Vector3.all(1);
    if (v) {
      if (hitbox.parent == null && brain == null) root.add(hitbox);
      // 復活したら自分の場所から
      brain?.reset(enemy.x, enemy.z);
    } else if (hitbox.parent != null) {
      root.remove(hitbox);
    }
  }

  bool get dying => _die >= 0;

  void hurt() => _hurt = 0;
  void lunge() => _lunge = 0;
  void defeat() {
    _die = 0;
    if (hitbox.parent != null) root.remove(hitbox);
  }

  void update(
    double dt,
    double t, {
    required bool engaged,
    required double px,
    required double pz,
  }) {
    if (!alive) return;
    if (engaged) {
      // こちらを向く
      final target = math.atan2(px - this.px, pz - this.pz);
      var d = target - yaw;
      while (d > math.pi) {
        d -= 2 * math.pi;
      }
      while (d < -math.pi) {
        d += 2 * math.pi;
      }
      yaw += d * (1 - math.exp(-8 * dt));
    }
    turn.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw);
    var y =
        0.5 +
        (math.sin(t * (engaged ? 6 : 3)) * 0.5 + 0.5) * (engaged ? 0.1 : 0.25);
    var z = 0.0;
    var scale = 1.0;
    if (_hurt >= 0) {
      // のけぞる（後ろへ少し下がって、つぶれる）
      _hurt += dt;
      final k = math.sin((_hurt / 0.35).clamp(0.0, 1.0) * math.pi);
      z -= 0.45 * k;
      scale = 1 - 0.25 * k;
      if (_hurt > 0.35) _hurt = -1;
    }
    if (_lunge >= 0) {
      // 体当たり（前へ飛びかかる）
      _lunge += dt;
      final k = math.sin((_lunge / 0.4).clamp(0.0, 1.0) * math.pi);
      z += 0.9 * k;
      y += 0.35 * k;
      if (_lunge > 0.4) _lunge = -1;
    }
    if (_die >= 0) {
      _die += dt;
      scale = (1 - _die / 0.5).clamp(0.0, 1.0);
      y = 0.5 * scale;
      if (_die > 0.5) setAlive(false);
    }
    body.position = vm.Vector3(0, y, z);
    body.scale = vm.Vector3.all(math.max(0.01, scale));
  }
}
