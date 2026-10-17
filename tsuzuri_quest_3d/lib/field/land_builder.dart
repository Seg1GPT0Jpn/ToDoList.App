import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/physics.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../game/geo2d.dart';
import '../game/map_v2.dart';

/// 色だけの材質（基本図形用）
PhysicallyBasedMaterial pbr(
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
    m.emissiveFactor = vm.Vector4(r * emissive, g * emissive, b * emissive, 1);
  }
  return m;
}

/// 400m の「はじまりの大地」を組み立てる（地形・水・橋・村・森・山・遺跡・目印）。
///
/// 形はすべて MapV2 の設計データから作る。地形は 2m 間隔の高さの格子 [grid] を、
/// 見た目（50m ごとの区画に分けたメッシュ）と当たり判定（高さマップ 1 枚）の両方に使う。
/// 木や岩は同じ形をまとめて描く（InstancedMesh）。森の中の木は「通れない場所」なので
/// 当たり判定を持たず、草原の木と岩だけが持つ。
class LandBuilder {
  LandBuilder(this.scene, this.grid);

  final Scene scene;
  final HeightGrid grid;

  Node? _templeGate;
  Node? _caveSeal;
  final _chestLids = <String, Node>{};
  final _rng = math.Random(20261017);

  double y(double x, double z) => grid.heightAt(x, z);

  void build() {
    _terrain();
    _water();
    _bridge();
    _village();
    _vegetation();
    _temple();
    _rampWalls();
    _arena();
    _landmarks();
    _gates();
  }

  // ---- 状態で変わるもの ----

  /// 遺跡の入口（守護者をたおすまで閉じている）
  void setTempleOpen(bool open) => _setSolid(_templeGate, !open);

  /// 洞窟の封印（石碑のなぞを解くまで光っている）
  void setCaveOpen(bool open) => _setSolid(_caveSeal, !open);

  /// 宝箱のふた
  void setChestOpen(String id, bool open) {
    final lid = _chestLids[id];
    if (lid == null) return;
    lid.rotation = vm.Quaternion.axisAngle(
      vm.Vector3(1, 0, 0),
      open ? -1.9 : 0,
    );
  }

  final _solids = <Node, Node>{};

  void _setSolid(Node? n, bool solid) {
    if (n == null) return;
    n.visible = solid;
    final parent = _solids[n];
    if (solid && n.parent == null && parent != null) parent.add(n);
    if (!solid && n.parent != null) {
      _solids[n] = n.parent!;
      n.parent!.remove(n);
    }
  }

  // ---- 部品 ----

  Node _put(
    Mesh? mesh,
    vm.Matrix4 m,
    Shape? shape, {
    String name = '',
    Node? into,
  }) {
    final node = Node(name: name, localTransform: m, mesh: mesh);
    if (shape != null) {
      node.addComponent(RigidBody(type: BodyType.fixed));
      node.addComponent(Collider(shape: shape));
    }
    node.shadowStatic = true;
    (into ?? scene.root).add(node);
    return node;
  }

  /// 2 点のあいだの細長い箱（柵・壁）。下は地面にうめる
  void _wall(
    double x0,
    double z0,
    double x1,
    double z1,
    double height,
    double thick,
    Material mat, {
    double? baseY,
  }) {
    final len = distance(x0, z0, x1, z1);
    if (len < 0.1) return;
    final mx = (x0 + x1) / 2, mz = (z0 + z1) / 2;
    final by = baseY ?? math.min(y(x0, z0), math.min(y(x1, z1), y(mx, mz)));
    final sink = 0.6;
    final h = height + sink;
    final m = vm.Matrix4.translation(vm.Vector3(mx, by - sink + h / 2, mz))
      ..rotateY(math.atan2(x1 - x0, z1 - z0));
    _put(
      Mesh(CuboidGeometry(vm.Vector3(thick, h, len)), mat),
      m,
      BoxShape(halfExtents: vm.Vector3(thick / 2, h / 2, len / 2)),
      name: 'wall',
    );
  }

  /// 地面に置く箱（建物など）
  void _box(
    double x,
    double z,
    double w,
    double h,
    double d,
    Material mat, {
    double yaw = 0,
    bool solid = true,
    double? baseY,
  }) {
    final by = baseY ?? y(x, z);
    final m = vm.Matrix4.translation(vm.Vector3(x, by + h / 2 - 0.3, z))
      ..rotateY(yaw);
    _put(
      Mesh(CuboidGeometry(vm.Vector3(w, h + 0.6, d)), mat),
      m,
      solid
          ? BoxShape(halfExtents: vm.Vector3(w / 2, (h + 0.6) / 2, d / 2))
          : null,
    );
  }

  // ---- 地形 ----

  void _terrain() {
    final n = grid.n;
    final step = grid.step;
    final colors = Float32List(n * n * 4);
    for (var j = 0; j < n; j++) {
      for (var i = 0; i < n; i++) {
        final x = i * step, z = j * step;
        final s = MapV2.surface(x, z, grid.at(i, j), grid.slopeAt(i, j));
        // 少しだけ色をゆらす（のっぺりしないように）
        final k = 1 + (_hash(i, j) - 0.5) * 0.08;
        final o = (j * n + i) * 4;
        colors[o] = s.r * k;
        colors[o + 1] = s.g * k;
        colors[o + 2] = s.b * k;
        colors[o + 3] = 1;
      }
    }
    final mat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(1, 1, 1, 1)
      ..roughnessFactor = 0.95
      ..metallicFactor = 0
      ..vertexColorWeight = 1;
    const cells = 25; // 50m ごとの区画
    for (var cj = 0; cj < n - 1; cj += cells) {
      for (var ci = 0; ci < n - 1; ci += cells) {
        final w = math.min(cells, n - 1 - ci) + 1;
        final d = math.min(cells, n - 1 - cj) + 1;
        final pos = Float32List(w * d * 3);
        final nor = Float32List(w * d * 3);
        final col = Float32List(w * d * 4);
        for (var b = 0; b < d; b++) {
          for (var a = 0; a < w; a++) {
            final i = ci + a, j = cj + b;
            final v = b * w + a;
            pos[v * 3] = i * step;
            pos[v * 3 + 1] = grid.at(i, j);
            pos[v * 3 + 2] = j * step;
            final dx = (grid.at(i + 1, j) - grid.at(i - 1, j)) / (2 * step);
            final dz = (grid.at(i, j + 1) - grid.at(i, j - 1)) / (2 * step);
            final len = math.sqrt(dx * dx + 1 + dz * dz);
            nor[v * 3] = -dx / len;
            nor[v * 3 + 1] = 1 / len;
            nor[v * 3 + 2] = -dz / len;
            final o = (j * n + i) * 4;
            for (var c = 0; c < 4; c++) {
              col[v * 4 + c] = colors[o + c];
            }
          }
        }
        final idx = <int>[];
        for (var b = 0; b < d - 1; b++) {
          for (var a = 0; a < w - 1; a++) {
            final v00 = b * w + a, v10 = v00 + 1, v01 = v00 + w, v11 = v01 + 1;
            // 上から見て反時計回り（表が上）。対角線は v10-v01（HeightGrid.heightAt と同じ）
            idx
              ..addAll([v00, v01, v10])
              ..addAll([v10, v01, v11]);
          }
        }
        final geo = MeshGeometry.fromArrays(
          positions: pos,
          normals: nor,
          colors: col,
          indices: idx,
        );
        _put(Mesh(geo, mat), vm.Matrix4.identity(), null, name: 'terrain');
      }
    }
    // 当たり判定：高さマップ 1 枚（中心に置く）
    final ground = Node(
      name: 'terrain_collider',
      localTransform: vm.Matrix4.translation(
        vm.Vector3(MapV2.size / 2, 0, MapV2.size / 2),
      ),
    );
    ground.addComponent(RigidBody(type: BodyType.fixed));
    ground.addComponent(
      Collider(
        shape: HeightFieldShape(
          width: n,
          depth: n,
          heights: grid.heights,
          scale: vm.Vector3(MapV2.size, 1, MapV2.size),
        ),
      ),
    );
    scene.add(ground);
  }

  static double _hash(int i, int j) {
    final v = math.sin(i * 12.9898 + j * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  // ---- 川 ----

  void _water() {
    // 川の帯（中心線の左右 11m）。両端は地図の外までのばす
    final pts = <P2>[
      (MapV2.river.first.$1 - 4, -20),
      ...MapV2.river,
      (MapV2.river.last.$1 + 3, 420),
    ];
    const half = MapV2.riverHalfWidth + 1;
    final pos = <double>[], nor = <double>[], idx = <int>[];
    for (var i = 0; i < pts.length; i++) {
      final prev = pts[math.max(0, i - 1)],
          next = pts[math.min(pts.length - 1, i + 1)];
      var tx = next.$1 - prev.$1, tz = next.$2 - prev.$2;
      final l = math.sqrt(tx * tx + tz * tz);
      tx /= l;
      tz /= l;
      final (x, z) = pts[i];
      pos.addAll([x - tz * half, MapV2.waterY, z + tx * half]);
      pos.addAll([x + tz * half, MapV2.waterY, z - tx * half]);
      nor.addAll([0, 1, 0, 0, 1, 0]);
      if (i > 0) {
        final a = (i - 1) * 2, b = a + 1, c = i * 2, d = c + 1;
        idx.addAll([a, c, b, b, c, d]);
      }
    }
    final water = pbr(0.16, 0.40, 0.70, roughness: 0.12)..doubleSided = true;
    _put(
      Mesh(
        MeshGeometry.fromArrays(
          positions: Float32List.fromList(pos),
          normals: Float32List.fromList(nor),
          indices: idx,
        ),
        water,
      ),
      vm.Matrix4.identity(),
      null,
      name: 'river',
    );
    // 浅瀬（水深 0.2m・歩ける）
    _put(
      Mesh(
        DiscGeometry(radius: 1, segments: 40),
        pbr(0.42, 0.70, 0.86, roughness: 0.1),
      ),
      vm.Matrix4.translation(
        vm.Vector3(MapV2.shallowX, MapV2.waterY + 0.04, MapV2.shallowZ),
      )..scaleByVector3(
        vm.Vector3(MapV2.shallowRx - 0.5, 1, MapV2.shallowRz - 0.5),
      ),
      null,
      name: 'shallows',
    );
  }

  // ---- 古橋 ----

  void _bridge() {
    const x0 = MapV2.bridgeX0, x1 = MapV2.bridgeX1;
    const len = x1 - x0, cx = (x0 + x1) / 2, cz = 210.0, top = MapV2.bridgeY;
    final wood = pbr(0.50, 0.34, 0.20);
    final stone = pbr(0.78, 0.74, 0.68);
    // 床（外寸の幅 10m。上面が橋の高さ）
    _put(
      Mesh(CuboidGeometry(vm.Vector3(len, 0.5, 10)), wood),
      vm.Matrix4.translation(vm.Vector3(cx, top - 0.25, cz)),
      BoxShape(halfExtents: vm.Vector3(len / 2, 0.25, 5)),
      name: 'bridge_deck',
    );
    // 欄干（幅 1m・高さ 1.2m）。内側が通れる幅 8m
    for (final z in [MapV2.bridgeZ0 - 0.5, MapV2.bridgeZ1 + 0.5]) {
      _put(
        Mesh(CuboidGeometry(vm.Vector3(len, 1.2, 0.8)), stone),
        vm.Matrix4.translation(vm.Vector3(cx, top + 0.6, z)),
        BoxShape(halfExtents: vm.Vector3(len / 2, 0.9, 0.4)),
        name: 'bridge_rail',
      );
    }
    // 橋脚
    for (final x in [cx - 6, cx + 6]) {
      _put(
        Mesh(CuboidGeometry(vm.Vector3(2, top + 2, 8)), stone),
        vm.Matrix4.translation(vm.Vector3(x, (top - 0.5 - 2) / 2, cz)),
        null,
        name: 'bridge_pier',
      );
    }
  }

  // ---- 村 ----

  void _village() {
    final fence = pbr(0.55, 0.38, 0.22);
    final (ex, ez) = MapV2.villageEastGate;
    final (nx, _) = MapV2.villageNorthGate;
    const gate = 4.0;
    // 北（門をあける）・東（門をあける）・南・西
    _wall(48, 265, nx - gate, 265, 1.1, 0.3, fence, baseY: 2.0);
    _wall(nx + gate, 265, 138, 265, 1.1, 0.3, fence, baseY: 2.0);
    _wall(ex, 265, ex, ez - gate, 1.1, 0.3, fence, baseY: 2.0);
    _wall(ex, ez + gate, ex, 355, 1.1, 0.3, fence, baseY: 2.0);
    _wall(48, 355, 138, 355, 1.1, 0.3, fence, baseY: 2.0);
    _wall(48, 265, 48, 355, 1.1, 0.3, fence, baseY: 2.0);
    // 門の柱
    for (final (x, z) in [
      (ex, ez - gate),
      (ex, ez + gate),
      (nx - gate, 265.0),
      (nx + gate, 265.0),
    ]) {
      _box(x, z, 0.6, 2.6, 0.6, fence, baseY: 2.0);
    }
    // 家（村長の家・民家 2 軒）と商人のテント
    final wall = pbr(0.86, 0.80, 0.68);
    final roof = pbr(0.62, 0.24, 0.18);
    void house(double x, double z, double w, double d, double h) {
      _box(x, z, w, h, d, wall, baseY: 2.0);
      final r = math.sqrt(w * w + d * d) / 2 + 0.6;
      _put(
        Mesh(
          CylinderGeometry(
            bottomRadius: r,
            topRadius: 0,
            height: 3,
            radialSegments: 4,
          ),
          roof,
        ),
        vm.Matrix4.translation(vm.Vector3(x, 2.0 + h + 1.5, z))
          ..rotateY(math.pi / 4)
          ..scaleByVector3(
            vm.Vector3(w / (r * 1.414) * 1.1, 1, d / (r * 1.414) * 1.1),
          ),
        null,
        name: 'roof',
      );
    }

    house(115, 292, 14, 12, 6); // 村長の家
    house(73, 325, 10, 10, 4.5);
    house(104, 344.5, 12, 9, 4.5);
    _put(
      Mesh(
        CylinderGeometry(
          bottomRadius: 4,
          topRadius: 0.2,
          height: 4,
          radialSegments: 8,
        ),
        pbr(0.86, 0.48, 0.20),
      ),
      vm.Matrix4.translation(vm.Vector3(125, 2.0 + 2, 330)),
      CylinderShape(radius: 3.2, halfHeight: 2),
      name: 'tent',
    );
    // 言の葉の泉（S1）
    final stone = pbr(0.75, 0.73, 0.70);
    _put(
      Mesh(CylinderGeometry(bottomRadius: 3, topRadius: 3, height: 0.8), stone),
      vm.Matrix4.translation(vm.Vector3(100, 2.0 + 0.4, 315)),
      CylinderShape(radius: 3, halfHeight: 0.6),
      name: 'fountain',
    );
    _put(
      Mesh(
        DiscGeometry(radius: 2.6),
        pbr(0.30, 0.62, 0.92, roughness: 0.1, emissive: 0.4),
      ),
      vm.Matrix4.translation(vm.Vector3(100, 2.0 + 0.82, 315)),
      null,
    );
    _put(
      Mesh(
        CylinderGeometry(bottomRadius: 0.4, topRadius: 0.3, height: 2.2),
        stone,
      ),
      vm.Matrix4.translation(vm.Vector3(100, 2.0 + 1.5, 315)),
      null,
    );
    // 川辺の野営テント（S2）とたき火
    _put(
      Mesh(
        CylinderGeometry(
          bottomRadius: 2.2,
          topRadius: 0.1,
          height: 2.4,
          radialSegments: 6,
        ),
        pbr(0.30, 0.52, 0.70),
      ),
      vm.Matrix4.translation(vm.Vector3(163, y(163, 256) + 1.2, 256)),
      CylinderShape(radius: 1.8, halfHeight: 1.2),
      name: 'camp',
    );
    _put(
      Mesh(
        IcosphereGeometry(radius: 0.4, subdivisions: 1),
        pbr(1.0, 0.55, 0.15, emissive: 3),
      ),
      vm.Matrix4.translation(vm.Vector3(167, y(167, 253) + 0.3, 253)),
      null,
      name: 'campfire',
    );
  }

  // ---- 木と岩 ----

  bool _nearRoad(double x, double z, double pad) {
    for (final r in MapV2.roads) {
      if (r.distance(x, z) <= r.width / 2 + pad) return true;
    }
    for (final p in MapV2.plazas) {
      if (distance(x, z, p.x, p.z) <= p.r + pad) return true;
    }
    return false;
  }

  void _vegetation() {
    final trunk = InstancedMesh(
      geometry: CylinderGeometry(
        bottomRadius: 0.32,
        topRadius: 0.22,
        height: 2.4,
        radialSegments: 6,
      ),
      material: pbr(0.42, 0.29, 0.18),
    );
    final crown = InstancedMesh(
      geometry: IcosphereGeometry(radius: 1.7, subdivisions: 1),
      material: pbr(0.22, 0.48, 0.20),
    );
    final rocks = InstancedMesh(
      geometry: IcosphereGeometry(radius: 1, subdivisions: 1),
      material: pbr(0.55, 0.53, 0.52, roughness: 0.95),
    );
    void tree(double x, double z, double s, {bool solid = false}) {
      final gy = y(x, z);
      trunk.addInstance(
        vm.Matrix4.translation(vm.Vector3(x, gy + 1.2 * s, z))
          ..scaleByVector3(vm.Vector3.all(s)),
      );
      final g = 0.85 + _rng.nextDouble() * 0.3;
      crown.addInstance(
        vm.Matrix4.translation(vm.Vector3(x, gy + 2.4 * s + 1.1 * s, z))
          ..rotateY(_rng.nextDouble() * 6.28)
          ..scaleByVector3(vm.Vector3(s * 1.1, s * 1.25, s * 1.1)),
        color: vm.Vector4(g, g * (0.95 + _rng.nextDouble() * 0.1), g, 1),
      );
      if (solid) {
        _put(
          null,
          vm.Matrix4.translation(vm.Vector3(x, gy + 1.5 * s, z)),
          CylinderShape(radius: 0.4 * s, halfHeight: 1.5 * s),
          name: 'tree_collider',
        );
      }
    }

    void rock(double x, double z, double s) {
      final gy = y(x, z);
      rocks.addInstance(
        vm.Matrix4.translation(vm.Vector3(x, gy + 0.15 * s, z))
          ..rotateY(_rng.nextDouble() * 6.28)
          ..scaleByVector3(vm.Vector3(s, s * 0.65, s * 1.1)),
      );
      _put(
        null,
        vm.Matrix4.translation(vm.Vector3(x, gy + 0.2 * s, z)),
        SphereShape(radius: s * 0.75),
        name: 'rock_collider',
      );
    }

    // 森：7m ごとに少しずらして植える。道・広場のそばは空ける（通れない場所なので当たり判定なし）
    for (var z = 4.0; z < 196; z += 7) {
      for (var x = 4.0; x < 160; x += 7) {
        final px = x + (_rng.nextDouble() - 0.5) * 5;
        final pz = z + (_rng.nextDouble() - 0.5) * 5;
        if (signedPolygonDistance(px, pz, MapV2.forest) < 0.5) continue;
        if (_nearRoad(px, pz, 2.5)) continue;
        tree(px, pz, 1.0 + _rng.nextDouble() * 0.6);
      }
    }
    // 古の大樹（T1）
    _put(
      Mesh(
        CylinderGeometry(
          bottomRadius: 2.5,
          topRadius: 1.6,
          height: 10,
          radialSegments: 12,
        ),
        pbr(0.40, 0.27, 0.16),
      ),
      vm.Matrix4.translation(vm.Vector3(55, y(55, 118) + 5, 118)),
      CylinderShape(radius: 2.5, halfHeight: 5),
      name: 'great_tree',
    );
    _put(
      Mesh(
        IcosphereGeometry(radius: 8, subdivisions: 2),
        pbr(0.24, 0.52, 0.22),
      ),
      vm.Matrix4.translation(vm.Vector3(55, y(55, 118) + 13, 118))
        ..scaleByVector3(vm.Vector3(1, 0.7, 1)),
      null,
      name: 'great_tree_crown',
    );
    // 草原・台地の木と岩（当たり判定あり）
    var trees = 0, stones = 0;
    for (var tries = 0; tries < 2000 && (trees < 70 || stones < 50); tries++) {
      final x = 4 + _rng.nextDouble() * (MapV2.size - 8);
      final z = 4 + _rng.nextDouble() * (MapV2.size - 8);
      if (!MapV2.walkable(x, z, open: const {MapV2.bridgeKey})) continue;
      if (_nearRoad(x, z, 3)) continue;
      if (MapV2.riverDistance(x, z) < 15) continue;
      if (signedPolygonDistance(x, z, MapV2.village) > -3) continue;
      if (insidePolygon(x, z, MapV2.summit)) continue;
      final onMountain =
          insidePolygon(x, z, MapV2.mountainBase) ||
          insidePolygon(x, z, MapV2.rockWall);
      if (trees < 70 && !onMountain && _rng.nextDouble() < 0.6) {
        tree(x, z, 0.9 + _rng.nextDouble() * 0.5, solid: true);
        trees++;
      } else if (stones < 50) {
        rock(x, z, 0.6 + _rng.nextDouble() * 1.0);
        stones++;
      }
    }
    for (final (mesh, name) in [
      (trunk, 'trunks'),
      (crown, 'crowns'),
      (rocks, 'rocks'),
    ]) {
      final node = Node(name: name)..addComponent(InstancedMeshComponent(mesh));
      node.shadowStatic = true;
      scene.add(node);
    }
  }

  // ---- 山上の遺跡（T2） ----

  void _temple() {
    final stone = pbr(0.86, 0.84, 0.80);
    const top = 28.0, h = 6.0, t = 1.2;
    const x0 = MapV2.templeX0, x1 = MapV2.templeX1;
    const z0 = MapV2.templeZ0, z1 = MapV2.templeZ1;
    _wall(x0, z0, x1, z0, h, t, stone, baseY: top);
    _wall(x0, z0, x0, z1, h, t, stone, baseY: top);
    _wall(x1, z0, x1, z1, h, t, stone, baseY: top);
    _wall(x0, z1, MapV2.templeGateX0, z1, h, t, stone, baseY: top);
    _wall(MapV2.templeGateX1, z1, x1, z1, h, t, stone, baseY: top);
    // 柱
    for (final (x, z) in [
      (x0, z0),
      (x1, z0),
      (x0, z1),
      (x1, z1),
      (MapV2.templeGateX0, z1),
      (MapV2.templeGateX1, z1),
    ]) {
      _put(
        Mesh(
          CylinderGeometry(
            bottomRadius: 0.9,
            topRadius: 0.8,
            height: h + 1.5,
            radialSegments: 10,
          ),
          stone,
        ),
        vm.Matrix4.translation(vm.Vector3(x, top + (h + 1.5) / 2, z)),
        CylinderShape(radius: 0.9, halfHeight: (h + 1.5) / 2),
      );
    }
    // 祭壇と星
    _box(335, 70, 2.4, 1.2, 1.4, pbr(0.70, 0.66, 0.62), baseY: top);
    _put(
      Mesh(
        IcosphereGeometry(radius: 0.6, subdivisions: 1),
        pbr(1.0, 0.92, 0.4, emissive: 2.5),
      ),
      vm.Matrix4.translation(vm.Vector3(335, top + 2.2, 70)),
      null,
      name: 'star',
    );
    // 入口をふさぐ光の扉（守護者をたおすと消える）
    _templeGate = _put(
      Mesh(
        CuboidGeometry(
          vm.Vector3(MapV2.templeGateX1 - MapV2.templeGateX0, 5, 0.5),
        ),
        pbr(0.45, 0.65, 1.0, emissive: 1.6),
      ),
      vm.Matrix4.translation(
        vm.Vector3(
          (MapV2.templeGateX0 + MapV2.templeGateX1) / 2,
          top + 2.5,
          z1,
        ),
      ),
      BoxShape(
        halfExtents: vm.Vector3(
          (MapV2.templeGateX1 - MapV2.templeGateX0) / 2,
          2.5,
          0.25,
        ),
      ),
      name: 'temple_gate',
    );
  }

  /// 登山道の坂の両側の石壁（高さ 1.1m）
  void _rampWalls() {
    final stone = pbr(0.62, 0.58, 0.52);
    for (final (a, b) in MapV2.guardedRamps) {
      final dx = b.$1 - a.$1, dz = b.$2 - a.$2;
      final run = math.sqrt(dx * dx + dz * dz);
      final rise = b.$3 - a.$3;
      final len = math.sqrt(run * run + rise * rise);
      final nx = dz / run, nz = -dx / run;
      for (final side in [-1.0, 1.0]) {
        final cx = (a.$1 + b.$1) / 2 + nx * MapV2.rampWallOffset * side;
        final cz = (a.$2 + b.$2) / 2 + nz * MapV2.rampWallOffset * side;
        final cy = (a.$3 + b.$3) / 2 + 0.55;
        final m = vm.Matrix4.translation(vm.Vector3(cx, cy, cz))
          ..rotateY(math.atan2(dx, dz))
          ..rotateX(-math.atan2(rise, run));
        _put(
          Mesh(CuboidGeometry(vm.Vector3(0.7, 2.3, len)), stone),
          m,
          BoxShape(halfExtents: vm.Vector3(0.35, 1.15, len / 2)),
          name: 'ramp_wall',
        );
      }
    }
  }

  /// 山頂の闘技場（B2）の石柱。南（登山道）と北（遺跡の入口）は空ける
  void _arena() {
    final stone = pbr(0.80, 0.78, 0.74);
    for (var k = 0; k < 14; k++) {
      final a = k / 14 * 2 * math.pi;
      final dz = math.cos(a);
      if (dz.abs() > 0.88) continue;
      final x = 335 + math.sin(a) * 16.5, z = 102 + dz * 16.5;
      _put(
        Mesh(
          CylinderGeometry(
            bottomRadius: 0.7,
            topRadius: 0.6,
            height: 4.5,
            radialSegments: 8,
          ),
          stone,
        ),
        vm.Matrix4.translation(vm.Vector3(x, 28 + 2.25, z)),
        CylinderShape(radius: 0.7, halfHeight: 2.25),
      );
    }
  }

  // ---- 目印（石碑群・洞窟・宝箱） ----

  void _landmarks() {
    // 古代の石碑群（T3）：半径 14m の円に 7 基。道が通る向きは空ける
    final stone = pbr(0.72, 0.72, 0.70);
    var placed = 0;
    for (var k = 0; k < 24 && placed < 7; k++) {
      final a = k / 24 * 2 * math.pi + 0.1;
      final x = 290 + math.sin(a) * 14, z = 330 + math.cos(a) * 14;
      var clear = true;
      for (final r in MapV2.roads) {
        if (r.distance(x, z) <= r.width / 2 + 1.5) clear = false;
      }
      if (!clear) continue;
      _box(x, z, 1.4, 3.2, 0.6, stone, yaw: a);
      placed++;
      k += 2;
    }
    // 中央の石碑（しらべる）
    _box(298.5, 324, 2.0, 2.4, 0.7, pbr(0.60, 0.62, 0.68), yaw: -0.6);
    // 封印の石窟（T4）：谷道の東の岩壁にあいた口（西向き）
    const cx = 362.5, cz = 245.0, cy = 6.0;
    _put(
      Mesh(
        CuboidGeometry(vm.Vector3(1.5, 4.2, 5.2)),
        pbr(0.04, 0.04, 0.05, roughness: 1),
      ),
      vm.Matrix4.translation(vm.Vector3(cx, cy + 2.1, cz)),
      null,
      name: 'cave_mouth',
    );
    final rockMat = pbr(0.45, 0.40, 0.36);
    for (final dz in [-3.3, 3.3]) {
      _box(cx - 0.6, cz + dz, 1.4, 5.0, 1.4, rockMat, baseY: cy);
    }
    _box(cx - 0.6, cz, 1.4, 1.2, 8.0, rockMat, baseY: cy + 4.2, solid: false);
    _caveSeal = _put(
      Mesh(
        CuboidGeometry(vm.Vector3(0.4, 4.0, 5.0)),
        pbr(0.70, 0.40, 1.0, emissive: 1.4),
      ),
      vm.Matrix4.translation(vm.Vector3(cx - 1.0, cy + 2.0, cz)),
      BoxShape(halfExtents: vm.Vector3(0.2, 2.0, 2.5)),
      name: 'cave_seal',
    );
    // 宝箱
    for (final (id, x, z, yaw) in [
      ('T1', 58.5, 121.5, 0.6),
      ('E4C', 346.0, 142.0, -0.8),
    ]) {
      final gy = y(x, z);
      final base = _put(
        Mesh(CuboidGeometry(vm.Vector3(1.2, 0.7, 0.8)), pbr(0.55, 0.32, 0.14)),
        vm.Matrix4.translation(vm.Vector3(x, gy + 0.35, z))..rotateY(yaw),
        BoxShape(halfExtents: vm.Vector3(0.6, 0.35, 0.4)),
        name: 'chest_$id',
      );
      final hinge = Node(
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.35, -0.4)),
      );
      hinge.add(
        Node(
          mesh: Mesh(
            CuboidGeometry(vm.Vector3(1.25, 0.3, 0.85)),
            pbr(0.85, 0.65, 0.2, emissive: 0.3),
          ),
          localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.15, 0.4)),
        ),
      );
      base.add(hinge);
      _chestLids[id] = hinge;
    }
  }

  // ---- 出口（ゲート） ----

  void _gates() {
    final stone = pbr(0.70, 0.68, 0.64);
    // G1：東の渓谷へのゲート（石の門）
    for (final z in [215.0, 225.0]) {
      _box(394, z, 1.2, 6, 1.2, stone);
    }
    _box(394, 220, 1.4, 1.2, 11.4, stone, baseY: y(394, 220) + 6, solid: false);
    // G2：南の湖畔への道（木のさく）
    final wood = pbr(0.50, 0.34, 0.20);
    _wall(244, 396.5, 256, 396.5, 1.4, 0.4, wood);
    // G3：北の深森への小道（倒木）
    final gy = y(90, 5);
    _put(
      Mesh(
        CylinderGeometry(
          bottomRadius: 0.8,
          topRadius: 0.7,
          height: 12,
          radialSegments: 10,
        ),
        pbr(0.38, 0.26, 0.16),
      ),
      vm.Matrix4.translation(vm.Vector3(90, gy + 0.7, 5))..rotateZ(math.pi / 2),
      CylinderShape(radius: 0.8, halfHeight: 6),
      name: 'fallen_log',
    );
  }
}
