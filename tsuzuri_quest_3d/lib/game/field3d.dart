import 'dart:convert';
import 'dart:math' as math;

/// 3D フィールド（試作）の、描画に依存しない部分。
///
/// 地図の配置・プレイヤーの位置・倒した敵などの状態と、その保存形式を持つ。
/// 3D の描画・物理（flutter_scene）は rpg_game_app/lib/field3d/ にあり、
/// ここは純 Dart なので単体テストできる。
///
/// 座標はメートル。y が上。地面の高さは 0。

/// 地図の上に置く物
enum Prop3DKind { tree, rock, ramp }

/// 地図の上の置き物（木・岩・坂）。すべて動かない障害物
class Prop3D {
  const Prop3D(this.kind, this.x, this.z, {this.size = 1, this.yaw = 0});

  final Prop3DKind kind;
  final double x;
  final double z;

  /// 大きさの倍率
  final double size;

  /// 向き（ラジアン。坂の向きに使う）
  final double yaw;
}

/// 話しかけられる人
class Npc3D {
  const Npc3D({
    required this.id,
    required this.name,
    required this.x,
    required this.z,
    required this.lines,
  });

  final String id;
  final String name;
  final double x;
  final double z;
  final List<String> lines;
}

/// フィールドの敵。触れると、つながっているステージのバトルになる
class Enemy3D {
  const Enemy3D({
    required this.id,
    required this.worldId,
    required this.stageId,
    required this.x,
    required this.z,
  });

  final String id;

  /// バトルで使うワールドとステージ（既存の RpgCatalog の ID）
  final String worldId;
  final String stageId;
  final double x;
  final double z;
}

/// 1つの地域（試作では草原1枚）
class Field3DRegion {
  const Field3DRegion({
    required this.id,
    required this.name,
    required this.halfSize,
    required this.spawnX,
    required this.spawnZ,
    required this.props,
    required this.npcs,
    required this.enemies,
  });

  final String id;
  final String name;

  /// 地面の半分の大きさ（20 なら 40m 四方）
  final double halfSize;
  final double spawnX;
  final double spawnZ;
  final List<Prop3D> props;
  final List<Npc3D> npcs;
  final List<Enemy3D> enemies;

  /// 話しかけられる距離
  static const talkRange = 2.2;

  /// 敵に触れたとみなす距離
  static const touchRange = 1.1;

  static double _dist(double ax, double az, double bx, double bz) =>
      math.sqrt((ax - bx) * (ax - bx) + (az - bz) * (az - bz));

  /// いちばん近くにいる、話しかけられる人（いなければ null）
  Npc3D? npcInRange(double x, double z) {
    Npc3D? best;
    var bestD = talkRange;
    for (final n in npcs) {
      final d = _dist(x, z, n.x, n.z);
      if (d <= bestD) {
        best = n;
        bestD = d;
      }
    }
    return best;
  }

  /// 触れている敵（倒した敵はのぞく）
  Enemy3D? touchedEnemy(double x, double z, Set<String> defeated) {
    for (final e in enemies) {
      if (defeated.contains(e.id)) continue;
      if (_dist(x, z, e.x, e.z) <= touchRange) return e;
    }
    return null;
  }

  /// 負けたときに戻る場所：敵から [distance] だけ離れた、地図の内側の点
  (double, double) retreatFrom(
    Enemy3D e,
    double x,
    double z, {
    double distance = 3.5,
  }) {
    var dx = x - e.x, dz = z - e.z;
    final len = math.sqrt(dx * dx + dz * dz);
    if (len < 1e-6) {
      dx = 0;
      dz = -1;
    } else {
      dx /= len;
      dz /= len;
    }
    final limit = halfSize - 1.5;
    return (
      (e.x + dx * distance).clamp(-limit, limit).toDouble(),
      (e.z + dz * distance).clamp(-limit, limit).toDouble(),
    );
  }

  /// 試作の草原（40m 四方）
  static const meadow = Field3DRegion(
    id: 'meadow_proto',
    name: 'はじまりの草原（試作）',
    halfSize: 20,
    spawnX: 0,
    spawnZ: -12,
    props: [
      Prop3D(Prop3DKind.tree, -8, -6, size: 1.2),
      Prop3D(Prop3DKind.tree, -12, 3),
      Prop3D(Prop3DKind.tree, -5, 10, size: 1.1),
      Prop3D(Prop3DKind.tree, 6, -8),
      Prop3D(Prop3DKind.tree, 11, -2, size: 1.3),
      Prop3D(Prop3DKind.tree, 14, 9),
      Prop3D(Prop3DKind.tree, 3, 14, size: 0.9),
      Prop3D(Prop3DKind.tree, -15, -14),
      Prop3D(Prop3DKind.tree, 16, -15, size: 1.1),
      Prop3D(Prop3DKind.tree, -2, 4),
      Prop3D(Prop3DKind.rock, 4, -3, size: 1.2),
      Prop3D(Prop3DKind.rock, -9, -12),
      Prop3D(Prop3DKind.rock, 9, 4, size: 0.8),
      Prop3D(Prop3DKind.rock, -13, 12, size: 1.4),
      Prop3D(Prop3DKind.rock, 12, 15),
      Prop3D(Prop3DKind.ramp, -14, -4, size: 1, yaw: math.pi / 2),
    ],
    npcs: [
      Npc3D(
        id: 'proto_guide',
        name: '案内人ノート',
        x: 2.5,
        z: -9,
        lines: [
          'ようこそ、立体の草原へ！ ここは 3D の試作の場所です。',
          '草原のスライムに触れると、いつもの問題バトルになります。',
          '勝てばスライムは消えます。場所と倒した記録は、この端末に残ります。',
        ],
      ),
    ],
    enemies: [
      Enemy3D(
        id: 'proto_slime_english',
        worldId: 'english',
        stageId: 'english_01',
        x: -4,
        z: -1,
      ),
      Enemy3D(
        id: 'proto_slime_math',
        worldId: 'math',
        stageId: 'math_m1_01',
        x: 7,
        z: 2,
      ),
      Enemy3D(
        id: 'proto_slime_social',
        worldId: 'social',
        stageId: 'social_geo_01',
        x: 0,
        z: 9,
      ),
    ],
  );
}

/// 3D フィールドの状態（試作。端末の中にだけ保存する）
class Field3DState {
  const Field3DState({
    required this.regionId,
    required this.x,
    required this.y,
    required this.z,
    this.heading = 0,
    this.cameraYaw = 0,
    this.defeated = const {},
    this.talked = const {},
  });

  factory Field3DState.start(Field3DRegion r) =>
      Field3DState(regionId: r.id, x: r.spawnX, y: 0, z: r.spawnZ);

  static const version = 1;

  final String regionId;
  final double x;
  final double y;
  final double z;

  /// キャラクターの向き（ラジアン）
  final double heading;

  /// カメラの向き（ラジアン）
  final double cameraYaw;
  final Set<String> defeated;
  final Set<String> talked;

  Field3DState copyWith({
    double? x,
    double? y,
    double? z,
    double? heading,
    double? cameraYaw,
    Set<String>? defeated,
    Set<String>? talked,
  }) => Field3DState(
    regionId: regionId,
    x: x ?? this.x,
    y: y ?? this.y,
    z: z ?? this.z,
    heading: heading ?? this.heading,
    cameraYaw: cameraYaw ?? this.cameraYaw,
    defeated: defeated ?? this.defeated,
    talked: talked ?? this.talked,
  );

  Map<String, Object?> toMap() => {
    'v': version,
    'region': regionId,
    'x': x,
    'y': y,
    'z': z,
    'heading': heading,
    'cameraYaw': cameraYaw,
    'defeated': defeated.toList()..sort(),
    'talked': talked.toList()..sort(),
  };

  String encode() => jsonEncode(toMap());

  /// 保存データを読む。壊れている・地域がちがう・地図の外なら、はじめからにする
  static Field3DState decode(String? raw, Field3DRegion region) {
    if (raw == null || raw.isEmpty) return Field3DState.start(region);
    try {
      final m = jsonDecode(raw);
      if (m is! Map || m['region'] != region.id) {
        return Field3DState.start(region);
      }
      double num0(Object? v) => v is num && v.isFinite ? v.toDouble() : 0;
      Set<String> ids(Object? v) => {
        if (v is List)
          for (final e in v)
            if (e is String) e,
      };
      final x = num0(m['x']), z = num0(m['z']);
      if (x.abs() > region.halfSize || z.abs() > region.halfSize) {
        return Field3DState.start(region);
      }
      final known = {for (final e in region.enemies) e.id};
      return Field3DState(
        regionId: region.id,
        x: x,
        y: num0(m['y']).clamp(0, 10).toDouble(),
        z: z,
        heading: num0(m['heading']),
        cameraYaw: num0(m['cameraYaw']),
        defeated: ids(m['defeated']).intersection(known),
        talked: ids(m['talked']),
      );
    } catch (_) {
      return Field3DState.start(region);
    }
  }
}
