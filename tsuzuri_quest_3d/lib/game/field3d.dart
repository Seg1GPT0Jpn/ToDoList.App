import 'dart:convert';
import 'dart:math' as math;

/// 3D フィールド（試作）の、描画に依存しない部分。
///
/// 地図の配置・プレイヤーの位置・倒した敵などの状態と、その保存形式を持つ。
/// 3D の描画・物理（flutter_scene）は lib/field/ にあり、
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
    this.name,
    this.zoneX,
    this.zoneZ,
    this.zoneR = 0,
    this.boss = false,
    this.triggerR = 0,
    this.hpRate = 1,
    this.bonusExp = 0,
    this.size = 1,
    this.winX,
    this.winZ,
    this.loseX,
    this.loseZ,
  });

  final String id;

  /// バトルで使うワールドとステージ（既存の RpgCatalog の ID）
  final String worldId;
  final String stageId;
  final double x;
  final double z;

  /// 表示名（なければ教科から「英語スライム」など）
  final String? name;

  /// 歩き回る範囲（中心と半径）。半径 0 ならその場から動かない
  final double? zoneX;
  final double? zoneZ;
  final double zoneR;

  /// ボス：近づくと必ずバトルになる（[triggerR] の内側に入ったとき）
  final bool boss;
  final double triggerR;

  /// ステージの敵の HP にかける倍率（ボス用）
  final double hpRate;

  /// たおしたときに上乗せする経験値（ボス用）
  final int bonusExp;

  /// 見た目の大きさ
  final double size;

  /// 勝った・負けた／にげたときに戻る場所（なければ、その場から少し離れる）
  final double? winX;
  final double? winZ;
  final double? loseX;
  final double? loseZ;

  double get homeX => zoneX ?? x;
  double get homeZ => zoneZ ?? z;
  bool get wanders => zoneR > 0;
}

/// しらべられる場所の種類
enum Event3DKind {
  /// 休憩地（記録・負けたときに戻る場所）
  rest,

  /// 宝箱（1 問に正解すると経験値）
  chest,

  /// 石碑（1 問に正解すると、なぞが解ける）
  stele,

  /// 洞窟の入口
  cave,

  /// 遺跡の祭壇
  altar,
}

/// しらべられる場所（休憩地・宝箱・石碑など）
class Event3D {
  const Event3D({
    required this.id,
    required this.kind,
    required this.name,
    required this.x,
    required this.z,
    this.r = 3,
    this.worldId,
    this.stageId,
    this.rewardExp = 0,
    this.needs,
    this.lines = const [],
    this.lockedLines = const [],
  });

  final String id;
  final Event3DKind kind;
  final String name;
  final double x;
  final double z;

  /// しらべられる距離
  final double r;

  /// 問題を出す場所（宝箱・石碑）のステージ
  final String? worldId;
  final String? stageId;
  final int rewardExp;

  /// しらべられるようになる条件（たおした敵の ID か、解いたなぞの ID）
  final String? needs;

  /// しらべたときの文
  final List<String> lines;

  /// 条件を満たしていないときの文
  final List<String> lockedLines;
}

/// 地図の出口（次の地域への道）。いまは予告だけ
class Gate3D {
  const Gate3D({
    required this.id,
    required this.name,
    required this.x,
    required this.z,
    this.r = 5,
    this.opensWith,
    required this.closedText,
    required this.openText,
  });

  final String id;
  final String name;
  final double x;
  final double z;
  final double r;

  /// 開く条件（たおした敵の ID など）。null なら閉じたまま
  final String? opensWith;
  final String closedText;
  final String openText;
}

/// 1つの地域（試作の草原・400m の「はじまりの大地」）
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
    this.centerX = 0,
    this.centerZ = 0,
    this.spawnHeading = 0,
    this.terrain = false,
    this.events = const [],
    this.gates = const [],
  });

  final String id;
  final String name;

  /// 地面の半分の大きさ（20 なら 40m 四方）
  final double halfSize;

  /// 地面の中心（試作は 0,0。はじまりの大地は 200,200 で 0〜400m）
  final double centerX;
  final double centerZ;
  final double spawnX;
  final double spawnZ;
  final double spawnHeading;
  final List<Prop3D> props;
  final List<Npc3D> npcs;
  final List<Enemy3D> enemies;

  /// 高低差のある地形（MapV2）を使うか。false なら平らな地面
  final bool terrain;
  final List<Event3D> events;
  final List<Gate3D> gates;

  double get minX => centerX - halfSize;
  double get maxX => centerX + halfSize;
  double get minZ => centerZ - halfSize;
  double get maxZ => centerZ + halfSize;

  bool contains(double x, double z) =>
      x >= minX && x <= maxX && z >= minZ && z <= maxZ;

  Enemy3D? enemyById(String id) {
    for (final e in enemies) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// いちばん近くにある、しらべられる場所（いなければ null）
  Event3D? eventInRange(double x, double z) {
    Event3D? best;
    var bestD = double.infinity;
    for (final e in events) {
      final d = _dist(x, z, e.x, e.z);
      if (d <= e.r && d < bestD) {
        best = e;
        bestD = d;
      }
    }
    return best;
  }

  /// 近くにある出口
  Gate3D? gateInRange(double x, double z) {
    for (final g in gates) {
      if (_dist(x, z, g.x, g.z) <= g.r) return g;
    }
    return null;
  }

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
    const m = 1.5;
    return (
      (e.x + dx * distance).clamp(minX + m, maxX - m).toDouble(),
      (e.z + dz * distance).clamp(minZ + m, maxZ - m).toDouble(),
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
          'ようこそ、立体の草原へ！',
          'スライムに近づいて「たたかう」と、問題バトルになります。',
          '場所と倒した記録は、この端末に残ります。',
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
    this.questsDone = const {},
    this.reviewWins = 0,
    this.beatenDay = const {},
    this.flags = const {},
    this.rest,
  });

  factory Field3DState.start(Field3DRegion r) => Field3DState(
    regionId: r.id,
    x: r.spawnX,
    y: 0,
    z: r.spawnZ,
    heading: r.spawnHeading,
    cameraYaw: r.spawnHeading,
  );

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

  /// 報告まで終えたクエスト（QuestBook の ID）
  final Set<String> questsDone;

  /// 復習スライムをたおした回数
  final int reviewWins;

  /// 敵 ID → 最後にたおした日（dayNumber）。たおした日のうちは復習スライムにしない
  final Map<String, int> beatenDay;

  /// 解いたなぞ・開けた宝箱など（Event3D の ID）
  final Set<String> flags;

  /// 最後に休んだ休憩地（負けたときに戻る）
  final String? rest;

  Field3DState copyWith({
    double? x,
    double? y,
    double? z,
    double? heading,
    double? cameraYaw,
    Set<String>? defeated,
    Set<String>? talked,
    Set<String>? questsDone,
    int? reviewWins,
    Map<String, int>? beatenDay,
    Set<String>? flags,
    String? rest,
  }) => Field3DState(
    regionId: regionId,
    x: x ?? this.x,
    y: y ?? this.y,
    z: z ?? this.z,
    heading: heading ?? this.heading,
    cameraYaw: cameraYaw ?? this.cameraYaw,
    defeated: defeated ?? this.defeated,
    talked: talked ?? this.talked,
    questsDone: questsDone ?? this.questsDone,
    reviewWins: reviewWins ?? this.reviewWins,
    beatenDay: beatenDay ?? this.beatenDay,
    flags: flags ?? this.flags,
    rest: rest ?? this.rest,
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
    'quests': questsDone.toList()..sort(),
    'reviewWins': reviewWins,
    'beaten': beatenDay,
    'flags': flags.toList()..sort(),
    if (rest != null) 'rest': rest,
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
      if (!region.contains(x, z)) return Field3DState.start(region);
      final known = {for (final e in region.enemies) e.id};
      return Field3DState(
        regionId: region.id,
        x: x,
        y: num0(m['y']).clamp(-5, 100).toDouble(),
        z: z,
        heading: num0(m['heading']),
        cameraYaw: num0(m['cameraYaw']),
        defeated: ids(m['defeated']).intersection(known),
        talked: ids(m['talked']),
        // クエストと復習は後から加えた項目。古いデータにはないので空から始める
        questsDone: ids(m['quests']),
        reviewWins: num0(m['reviewWins']).clamp(0, 1 << 30).toInt(),
        beatenDay: {
          if (m['beaten'] case final Map b)
            for (final MapEntry(:key, :value) in b.entries)
              if (key is String && known.contains(key) && value is num)
                key: value.toInt(),
        },
        flags: ids(m['flags']),
        rest: m['rest'] is String ? m['rest'] as String : null,
      );
    } catch (_) {
      return Field3DState.start(region);
    }
  }
}
