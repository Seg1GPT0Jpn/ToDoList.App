import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// 2D 版の主人公（えんぴつを持った見習い冒険者）を、基本図形で組み立てた 3D モデル。
///
/// 色は 2D 版の hero_painter.dart と同じ（茶色のコート・赤いマフラー・こげ茶の髪）。
/// モデルは +Z 向き（顔が +Z）で作るので、向き [heading] = atan2(x, z) とそのまま合う。
/// 足元が原点。高さは約 1.5m（頭の大きい2頭身半）。
///
/// 歩きの手足の振りは「実際に進んだ距離」で進める（その場で足だけ動く・
/// 後ろ向きに進むムーンウォークにならない）。
class HeroModel {
  HeroModel() {
    _build();
  }

  final root = Node(name: 'hero');
  late final Node _body;
  late final Node _legL, _legR, _armL, _armR;

  double _stride = 0;
  double _swingT = -1;

  /// 剣（えんぴつ）をふっている最中か
  bool get swinging => _swingT >= 0;

  static const _swingTime = 0.42;

  // 2D 版と同じ色（線形にせず、そのまま使う）
  static final _coat = _rgb(0x6D, 0x4C, 0x41);
  static final _coatDark = _rgb(0x4E, 0x34, 0x2E);
  static final _skin = _rgb(0xF7, 0xE1, 0xC4);
  static final _hair = _rgb(0x3E, 0x27, 0x23);
  static final _scarf = _rgb(0xC0, 0x50, 0x4D);
  static final _ink = _rgb(0x2E, 0x2A, 0x33);
  static final _pencil = _rgb(0xF2, 0xC9, 0x4C);
  static final _eraser = _rgb(0xE8, 0xA0, 0xA8);
  static final _wood = _rgb(0xF1, 0xDD, 0xBB);

  static vm.Vector3 _rgb(int r, int g, int b) =>
      vm.Vector3(r / 255, g / 255, b / 255);

  static PhysicallyBasedMaterial _mat(vm.Vector3 c, {double rough = 0.8}) =>
      PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(c.x, c.y, c.z, 1)
        ..roughnessFactor = rough
        ..metallicFactor = 0;

  static Node _part(
    MeshGeometry g,
    vm.Vector3 color,
    vm.Vector3 at, {
    double rough = 0.8,
    vm.Matrix4? rotate,
  }) {
    final m = vm.Matrix4.translation(at);
    if (rotate != null) m.multiply(rotate);
    return Node(
      mesh: Mesh(g, _mat(color, rough: rough)),
      localTransform: m,
    );
  }

  void _build() {
    _body = Node(name: 'hero_body');
    root.add(_body);

    // 足（腰を支点に前後にふる）
    Node leg(double x) {
      final pivot = Node(
        localTransform: vm.Matrix4.translation(vm.Vector3(x, 0.42, 0)),
      );
      pivot.add(
        _part(
          CylinderGeometry(bottomRadius: 0.075, topRadius: 0.085, height: 0.36),
          _coatDark,
          vm.Vector3(0, -0.2, 0),
        ),
      );
      // くつ
      pivot.add(
        _part(
          CuboidGeometry(vm.Vector3(0.15, 0.08, 0.22)),
          _ink,
          vm.Vector3(0, -0.38, 0.03),
        ),
      );
      _body.add(pivot);
      return pivot;
    }

    _legL = leg(0.11);
    _legR = leg(-0.11);

    // 体（コート）
    _body.add(
      _part(
        CylinderGeometry(bottomRadius: 0.27, topRadius: 0.21, height: 0.46),
        _coat,
        vm.Vector3(0, 0.62, 0),
      ),
    );
    // マフラーと、背中に垂れたしっぽ
    _body.add(
      _part(
        CylinderGeometry(bottomRadius: 0.235, topRadius: 0.225, height: 0.09),
        _scarf,
        vm.Vector3(0, 0.86, 0),
      ),
    );
    _body.add(
      _part(
        CuboidGeometry(vm.Vector3(0.09, 0.2, 0.05)),
        _scarf,
        vm.Vector3(0.08, 0.74, -0.22),
      ),
    );

    // 頭・髪・前髪のはね・目
    _body.add(
      _part(SphereGeometry(radius: 0.3), _skin, vm.Vector3(0, 1.17, 0)),
    );
    _body.add(
      _part(SphereGeometry(radius: 0.315), _hair, vm.Vector3(0, 1.235, -0.055)),
    );
    _body.add(
      _part(
        CylinderGeometry(bottomRadius: 0.035, topRadius: 0.0, height: 0.2),
        _hair,
        vm.Vector3(0.03, 1.58, 0.05),
        rotate: vm.Matrix4.rotationZ(-0.5)..rotateX(0.4),
      ),
    );
    for (final x in [-0.11, 0.11]) {
      _body.add(
        _part(
          SphereGeometry(radius: 0.035, segments: 12, rings: 8),
          _ink,
          vm.Vector3(x, 1.14, 0.275),
          rough: 0.4,
        ),
      );
    }
    // ほっぺ
    for (final x in [-0.18, 0.18]) {
      _body.add(
        _part(
          SphereGeometry(radius: 0.04, segments: 12, rings: 8),
          _rgb(0xF0, 0xA8, 0xA8),
          vm.Vector3(x, 1.06, 0.245),
        ),
      );
    }

    // 腕（肩を支点にふる）。右手にえんぴつ
    Node arm(double x) {
      final pivot = Node(
        localTransform: vm.Matrix4.translation(vm.Vector3(x, 0.8, 0)),
      );
      pivot.add(
        _part(
          CylinderGeometry(bottomRadius: 0.06, topRadius: 0.07, height: 0.32),
          _coat,
          vm.Vector3(0, -0.16, 0),
        ),
      );
      pivot.add(
        _part(
          SphereGeometry(radius: 0.07, segments: 16, rings: 10),
          _skin,
          vm.Vector3(0, -0.34, 0),
        ),
      );
      _body.add(pivot);
      return pivot;
    }

    _armL = arm(0.31);
    _armR = arm(-0.31);
    _armR.add(_pencilNode());
    _pose(0, 0);
  }

  /// 大きなえんぴつ（剣のかわり）。手の位置から前に向けて持つ
  Node _pencilNode() {
    final p = Node(
      name: 'pencil',
      // 前に向けつつ、少し上へ立てて持つ（後ろからも見えるように）
      localTransform: vm.Matrix4.translation(vm.Vector3(0, -0.34, 0.02))
        ..rotateX(math.pi / 2 - 0.55),
    );
    // えんぴつは +Y に伸びる（回して前向きにする）
    p.add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.065,
          topRadius: 0.065,
          height: 0.8,
          radialSegments: 6,
        ),
        _pencil,
        vm.Vector3(0, 0.38, 0),
        rough: 0.6,
      ),
    );
    p.add(
      _part(
        CylinderGeometry(
          bottomRadius: 0.065,
          topRadius: 0.0,
          height: 0.2,
          radialSegments: 6,
        ),
        _wood,
        vm.Vector3(0, 0.88, 0),
      ),
    );
    p.add(
      _part(
        CylinderGeometry(bottomRadius: 0.022, topRadius: 0.0, height: 0.06),
        _ink,
        vm.Vector3(0, 1.0, 0),
      ),
    );
    p.add(
      _part(
        CylinderGeometry(bottomRadius: 0.058, topRadius: 0.058, height: 0.1),
        _eraser,
        vm.Vector3(0, -0.05, 0),
      ),
    );
    return p;
  }

  /// 剣（えんぴつ）をふりはじめる
  void swing() {
    if (!swinging) _swingT = 0;
  }

  /// 毎フレーム：[moved] はこのフレームに進んだ距離（m）、[speed] は速さ（m/s）
  void update(double dt, {required double moved, required double speed}) {
    // 1歩（左右で1周期）を約 1.2m に合わせる
    _stride += moved / 1.2 * 2 * math.pi;
    final amount = (speed / 4.0).clamp(0.0, 1.0);
    if (_swingT >= 0) {
      _swingT += dt;
      if (_swingT > _swingTime) _swingT = -1;
    }
    _pose(_stride, amount);
  }

  void _pose(double phase, double amount) {
    final s = math.sin(phase) * 0.7 * amount;
    _legL.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), s);
    _legR.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -s);
    _armL.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -s * 0.8);
    // 右腕：ふっているあいだは、頭の上から前へふり下ろす
    double right;
    if (_swingT >= 0) {
      final t = (_swingT / _swingTime).clamp(0.0, 1.0);
      // 前半で振りかぶり、後半で一気にふり下ろす
      right = t < 0.35
          ? _lerp(-0.4, -3.3, t / 0.35)
          : _lerp(-3.3, -0.5, _easeOut((t - 0.35) / 0.65));
    } else {
      right = -0.45 + s * 0.3;
    }
    _armR.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), right);
    final bob = (math.sin(phase * 2).abs()) * 0.035 * amount;
    _body.position = vm.Vector3(0, bob, 0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();
}
