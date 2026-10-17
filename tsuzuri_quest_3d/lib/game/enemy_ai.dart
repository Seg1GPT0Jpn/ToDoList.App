import 'dart:math' as math;

import 'geo2d.dart';

/// 敵の動き方
enum EnemyMode { idle, wander, chase, home }

/// フィールドの敵の動き（描画なし・純 Dart）。
///
/// 自分の範囲（中心 [homeX],[homeZ]・半径 [radius]）の中を歩き回り、
/// 近くに主人公が来たら追いかける。範囲から離れすぎたら戻る。
/// 追う速さは主人公が歩くより少しおそいので、離れれば逃げきれる。通れない場所には入らない。
class EnemyBrain {
  EnemyBrain({
    required this.homeX,
    required this.homeZ,
    required this.radius,
    required this.x,
    required this.z,
    required this.walkable,
    int seed = 1,
  }) : _rng = math.Random(seed);

  final double homeX, homeZ, radius;
  double x, z;
  final bool Function(double x, double z) walkable;
  final math.Random _rng;

  EnemyMode mode = EnemyMode.idle;
  double heading = 0;
  double _wait = 0.5;
  double _calm = 0;
  double? _tx, _tz;

  static const wanderSpeed = 1.3;
  static const chaseSpeed = 3.2;
  static const homeSpeed = 2.4;

  /// この距離に主人公が来たら追いかける
  static const aggroRange = 7.0;

  /// 範囲の外へ、これだけ出たら追うのをやめて戻る
  static const leash = 6.0;

  /// しばらく追いかけない（にげた・負けた直後）
  void calm(double seconds) {
    _calm = seconds;
    if (mode == EnemyMode.chase) mode = EnemyMode.home;
  }

  bool get chasing => mode == EnemyMode.chase;

  double get _fromHome => distance(x, z, homeX, homeZ);

  /// 1 フレームぶん動かす。[frozen] のときは動かない（バトル中など）
  void update(
    double dt, {
    required double px,
    required double pz,
    bool frozen = false,
  }) {
    if (frozen || radius <= 0) return;
    if (_calm > 0) _calm -= dt;
    final dp = distance(x, z, px, pz);
    final playerNearHome = distance(px, pz, homeX, homeZ) <= radius + leash;
    if (_calm <= 0 && dp <= aggroRange && playerNearHome) {
      mode = EnemyMode.chase;
    } else if (mode == EnemyMode.chase) {
      mode = EnemyMode.home;
    }
    if (_fromHome > radius + leash) mode = EnemyMode.home;

    switch (mode) {
      case EnemyMode.chase:
        _step(px, pz, chaseSpeed, dt);
      case EnemyMode.home:
        if (_fromHome <= radius * 0.5 || !_step(homeX, homeZ, homeSpeed, dt)) {
          mode = EnemyMode.idle;
          _wait = 0.5;
        }
      case EnemyMode.wander:
        final tx = _tx, tz = _tz;
        if (tx == null ||
            tz == null ||
            distance(x, z, tx, tz) < 0.3 ||
            !_step(tx, tz, wanderSpeed, dt)) {
          mode = EnemyMode.idle;
          _wait = 1 + _rng.nextDouble() * 2;
        }
      case EnemyMode.idle:
        _wait -= dt;
        if (_wait <= 0) _pickTarget();
    }
  }

  /// 範囲の中の、歩ける点を選ぶ
  void _pickTarget() {
    for (var i = 0; i < 8; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final r = math.sqrt(_rng.nextDouble()) * radius;
      final tx = homeX + math.cos(a) * r, tz = homeZ + math.sin(a) * r;
      if (walkable(tx, tz)) {
        _tx = tx;
        _tz = tz;
        mode = EnemyMode.wander;
        return;
      }
    }
    _wait = 1;
  }

  /// 目標へ近づく。通れない場所の手前で止まったら false
  bool _step(double tx, double tz, double speed, double dt) {
    final dx = tx - x, dz = tz - z;
    final len = math.sqrt(dx * dx + dz * dz);
    if (len < 1e-6) return true;
    final s = math.min(len, speed * dt);
    final nx = x + dx / len * s, nz = z + dz / len * s;
    heading = math.atan2(dx, dz);
    if (!walkable(nx, nz)) return false;
    x = nx;
    z = nz;
    return true;
  }

  /// 元の場所へ瞬時に戻す（倒されて復活したときなど）
  void reset(double ax, double az) {
    x = ax;
    z = az;
    mode = EnemyMode.idle;
    _wait = 1;
  }
}
