import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';

import '../game/field3d.dart';

import 'package:vector_math/vector_math.dart' as vm;

/// 3D の草原（描画と物理）。ルール・保存は game/field3d.dart の [Field3DRegion] と
/// [Field3DState] が持ち、ここは見た目と当たり判定だけを受け持つ。
class Field3DWorld {
  Field3DWorld._(this.region, this.scene, this._physics);

  final Field3DRegion region;
  final Scene scene;
  final PhysicsWorld _physics;

  late final Node _player;
  late final KinematicCharacterController _kcc;
  late final Node _visual;
  AnimationClip? _idle;
  AnimationClip? _walk;
  AnimationClip? _runClip;
  final _enemies = <String, Node>{};
  final _npcMarks = <String, Node>{};

  // 入力と動き
  vm.Vector3 _wish = vm.Vector3.zero();
  bool _run = false;
  double _vy = 0;
  double _heading = 0;
  double _speed = 0;
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
    w._buildGround();
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

  // ---- 画質（実機での計測用に切りかえられる） ----

  DirectionalLight? _sun;

  /// 'high'：影あり・高画質、'standard'：影あり・中画質、'light'：影なし・低画質・解像度 70%
  void setQuality(String q) {
    final sun = _sun;
    switch (q) {
      case 'high':
        scene.renderQuality.tier = RenderQualityTier.high;
        scene.renderScale = 1.0;
        sun?.castsShadow = true;
      case 'light':
        scene.renderQuality.tier = RenderQualityTier.low;
        scene.renderScale = 0.7;
        sun?.castsShadow = false;
      default:
        scene.renderQuality.tier = RenderQualityTier.medium;
        scene.renderScale = 1.0;
        sun?.castsShadow = true;
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
    final at = vm.Vector3(p.x, 0, p.z);
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
      localTransform: vm.Matrix4.translation(vm.Vector3(n.x, 0, n.z)),
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

  void markTalked(String id) => _npcMarks[id]?.visible = false;

  static (double, double, double) _enemyRgb(String worldId) =>
      switch (worldId) {
        'english' => (0.30, 0.55, 0.95),
        'math' => (0.92, 0.35, 0.35),
        'social' => (0.40, 0.80, 0.40),
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
    final color = _enemyRgb(e.worldId);
    final root = Node(
      name: 'enemy_${e.id}',
      localTransform: vm.Matrix4.translation(vm.Vector3(e.x, 0, e.z)),
    );
    final body = Node(
      name: 'body',
      mesh: Mesh(
        SphereGeometry(radius: 0.5),
        _mat(color.$1, color.$2, color.$3, roughness: 0.35),
      ),
      localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.5, 0)),
    );
    for (final dx in [-0.17, 0.17]) {
      body.add(
        Node(
          mesh: Mesh(SphereGeometry(radius: 0.08), _mat(0.05, 0.05, 0.08)),
          localTransform: vm.Matrix4.translation(vm.Vector3(dx, 0.12, -0.44)),
        ),
      );
    }
    root.add(body);
    scene.add(root);
    _enemies[e.id] = root;
  }

  /// 倒した敵を消す
  void showDefeated(Set<String> defeated) {
    for (final MapEntry(:key, :value) in _enemies.entries) {
      value.visible = !defeated.contains(key);
    }
  }

  Future<void> _buildPlayer(Field3DState s) async {
    _heading = s.heading;
    _player = Node(
      name: 'player',
      localTransform: vm.Matrix4.translation(
        vm.Vector3(s.x, s.y + _centerY, s.z),
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
    scene.add(_player);
    try {
      final fox = await loadScene('assets/models/fox.glb');
      // 大きさをそろえる（高さ約 0.9m）。スキンつきのモデルなので、親のノードを動かす
      final holder = Node(name: 'fox_holder');
      holder.add(fox);
      final b = fox.combinedWorldBounds;
      final height = b == null ? 0 : (b.max.y - b.min.y);
      final k = height > 0 ? 0.9 / height : 0.01;
      holder.localTransform = vm.Matrix4.translation(
        vm.Vector3(0, -_centerY, 0),
      )..scaleByVector3(vm.Vector3.all(k));
      _visual.add(holder);
      Animation? anim(String name) => fox.findAnimationByName(name);
      final survey = anim('Survey'), walk = anim('Walk'), run = anim('Run');
      if (survey != null) {
        _idle = fox.createAnimationClip(survey)
          ..loop = true
          ..play();
      }
      if (walk != null) {
        _walk = fox.createAnimationClip(walk)
          ..loop = true
          ..weight = 0
          ..play();
      }
      if (run != null) {
        _runClip = fox.createAnimationClip(run)
          ..loop = true
          ..weight = 0
          ..play();
      }
    } catch (e) {
      // モデルが読めなくても、仮の体で遊べるようにする
      debugPrint('キツネのモデルを読めませんでした: $e');
      _visual.add(
        Node(
          mesh: Mesh(
            CapsuleGeometry(radius: _radius, height: _halfHeight * 2),
            _mat(0.95, 0.55, 0.20),
          ),
        ),
      );
    }
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
    final horiz = _wish * (speed * dt);
    _vy = math.max(-20, _vy - 9.81 * dt);
    final m = _kcc.move(
      vm.Vector3(horiz.x, _vy * dt, horiz.z),
      deltaSeconds: dt,
    );
    if (m.grounded && _vy < 0) _vy = 0;
    _speed = vm.Vector3(m.translation.x, 0, m.translation.z).length / dt;
    if (_wish.length > 0.05) {
      final target = math.atan2(_wish.x, _wish.z);
      var d = target - _heading;
      while (d > math.pi) {
        d -= 2 * math.pi;
      }
      while (d < -math.pi) {
        d += 2 * math.pi;
      }
      _heading += d * (1 - math.exp(-12 * dt));
      _applyHeading();
    }
    // 地図の外に落ちたら出発点へ
    if (playerFeet.y < -5) teleport(region.spawnX, region.spawnZ);
  }

  void _frame(double dt) {
    _time += dt;
    // 歩く速さでアニメーションを混ぜる
    final t = (_speed / walkSpeed).clamp(0.0, 1.0);
    final r = ((_speed - walkSpeed) / (runSpeed - walkSpeed)).clamp(0.0, 1.0);
    _idle?.weight = 1 - t;
    _walk?.weight = t * (1 - r);
    _runClip?.weight = t * r;
    // スライムがぴょこぴょこ動く
    var i = 0;
    for (final n in _enemies.values) {
      final body = n.children.first;
      final y = 0.5 + (math.sin(_time * 3 + i) * 0.5 + 0.5) * 0.25;
      body.position = vm.Vector3(0, y, 0);
      i++;
    }
  }

  void _applyHeading() {
    _visual.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), _heading);
  }

  /// 指定した場所へ瞬間移動（負けたとき・やり直し）
  void teleport(double x, double z, {double? heading}) {
    _player.position = vm.Vector3(x, _centerY + 0.05, z);
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
