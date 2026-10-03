import 'dart:collection';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

typedef Cell = ({int col, int row});

/// ほかのマップへの出入口
typedef Portal = ({String target, String label});

/// 宝箱の種類
enum ChestKind {
  /// エリアの奥にある宝箱（難問1問）
  main,

  /// 隠し通路の奥にある宝箱
  secret,

  /// 知識の扉の奥にある宝箱
  vault,
}

/// フィールドのマップ（1文字 = 1マス）。
///
///   #  壁      .  床      T  障害物（地形ごとに木・岩・柱・本棚などになる）
///   ~  水・溶岩・雲の切れ目     B  橋（歩ける）     R  じゅうたん（歩ける）
///   F  目印の飾り（像・灯籠・時計など。通れない）
///   E  ステージの敵（道をふさいでいる）   M  強敵（寄り道の先にいる。倒さなくても進める）
///   P  スタート地点   S  看板   G  ゴール   I  宿（授業）
///   C  宝箱（知識の封印：問題に正解すると開く）   W  泉（問題に答えると次のバトルのHPアップ）
///   H  隠し通路（見た目は障害物。調べると通れるようになる）
///   D  知識の扉（問題に正解すると開く）
///   X  ワープ石（さわった石どうしを行き来できる）
///   N  住人（NPC。話しかけると、この先のことや学び方を教えてくれる）
///   O  出入口（ほかのマップへ移動する）
///
/// エリアごとに、名前（「ばねの林」「助動詞の関所」など）から地形 [Terrain] が決まり、
/// 見た目も組み立て方も変わる。
class FieldMap {
  FieldMap(
    this.rows, {
    required this.id,
    required List<List<Terrain>> terrainGrid,
    required List<List<int>> areaGrid,
    required this.enemySpots,
    required this.safeCells,
    this.areaLabels = const {},
    this.areaThemes = const {},
    this.bossAreas = const {},
    this.chestKinds = const {},
    this.portals = const {},
    this.signText = '',
    this.goalText = 'トロフィーがある。',
  }) : width = rows.first.length,
       _terrain = terrainGrid,
       _area = areaGrid {
    for (final r in rows) {
      if (r.length != width) {
        throw ArgumentError('マップの行の長さがそろっていません: "$r"');
      }
    }
  }

  final String id;
  final List<String> rows;
  final List<List<Terrain>> _terrain;
  final List<List<int>> _area;

  /// エリア番号（ステージの order）→ 敵の位置
  final Map<int, Cell> enemySpots;

  /// エリアごとの「何かを置いても通り道をふさがない床」（亡霊などを置く）
  final Map<int, List<Cell>> safeCells;

  /// エリア番号 → 画面上部に出す名前（なければ地形の名前）
  final Map<int, String> areaLabels;

  /// エリア番号 → そのエリアで学ぶこと（入ったときの演出で出す）
  final Map<int, String> areaThemes;

  /// ボスの間になっているエリア
  final Set<int> bossAreas;

  /// 宝箱の位置 → 種類
  final Map<Cell, ChestKind> chestKinds;

  /// 出入口のマス → 行き先
  final Map<Cell, Portal> portals;

  /// 看板のメッセージ
  final String signText;

  /// ゴールのトロフィーの説明
  final String goalText;

  final int width;
  int get height => rows.length;

  String tileAt(int col, int row) {
    if (row < 0 || row >= height || col < 0 || col >= width) return '#';
    return rows[row][col];
  }

  Terrain terrainAt(int col, int row) =>
      _terrain[row.clamp(0, height - 1)][col.clamp(0, width - 1)];

  /// そのマスが属する部屋の番号（その部屋の先にいる敵の番号）
  int areaAt(int col, int row) =>
      _area[row.clamp(0, height - 1)][col.clamp(0, width - 1)];

  /// 画面上部に出すエリアの名前
  String labelAt(int col, int row) =>
      areaLabels[areaAt(col, row)] ?? terrainAt(col, row).label;

  /// 地形として通れるか（敵の立ち位置も地面は床。敵の有無はゲーム側で判定する）。
  /// 隠し通路（H）と知識の扉（D）は、開けるまでは通れない（ゲーム側で判定する）。
  bool isFloor(int col, int row) =>
      const {'.', 'P', 'E', 'M', 'B', 'R'}.contains(tileAt(col, row));

  Cell find(String ch) {
    for (var r = 0; r < height; r++) {
      final c = rows[r].indexOf(ch);
      if (c >= 0) return (col: c, row: r);
    }
    throw ArgumentError('マップに "$ch" がありません');
  }

  List<Cell> findAll(String ch) => [
    for (var r = 0; r < height; r++)
      for (var c = 0; c < width; c++)
        if (rows[r][c] == ch) (col: c, row: r),
  ];

  /// スタート地点
  Cell get start => find('P');

  /// [from] のマップから来たときに立つマス（出入口のとなりの床）。なければスタート地点。
  Cell spawnFrom(String? from) {
    for (final e in portals.entries) {
      if (e.value.target != from) continue;
      for (final (dc, dr) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final c = (col: e.key.col + dc, row: e.key.row + dr);
        if (isFloor(c.col, c.row) &&
            !const {'E', 'M'}.contains(tileAt(c.col, c.row))) {
          return c;
        }
      }
    }
    return start;
  }

  /// となりの歩ける床（ワープ石から出るときなど）
  Cell? floorNextTo(Cell c) {
    for (final (dc, dr) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      final n = (col: c.col + dc, row: c.row + dr);
      final t = tileAt(n.col, n.row);
      if (isFloor(n.col, n.row) && t != 'E' && t != 'M') return n;
    }
    return null;
  }

  /// 倒した敵の待機場所。ゲート横の壁のくぼみに寄るので、通り道をふさがない。
  Cell asideOf(Cell gate) {
    for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      if (tileAt(gate.col + dc, gate.row + dr) == '#') {
        return (col: gate.col + dc, row: gate.row + dr);
      }
    }
    return gate;
  }

  /// ゲートをはさんで [asideOf] の反対側の壁（捕まった仲間の檻を置く）
  Cell cageOf(Cell gate) {
    final a = asideOf(gate);
    return (col: gate.col * 2 - a.col, row: gate.row * 2 - a.row);
  }

  /// 宿の位置
  List<Cell> get innSpots => findAll('I');

  /// そのマスの先にいる（次に戦う）敵の番号。ゴールの部屋やハブでは null。
  int? enemyAhead(Cell cell) {
    final a = areaAt(cell.col, cell.row);
    return enemySpots.containsKey(a) ? a : null;
  }

  static const _width = 31;

  static final Map<String, FieldMap> _cache = {};

  /// マップの ID から取り出す。
  /// `<worldId>_hub`（ハブ）、`<worldId>_<ルートID>`（ルートのマップ）
  static FieldMap byId(String id) => _cache.putIfAbsent(id, () {
    final sep = id.indexOf('_');
    final world = RpgCatalog.world(id.substring(0, sep));
    final rest = id.substring(sep + 1);
    if (rest == 'hub') return _hub(world);
    return _route(world, world.route(rest)!);
  });

  /// そのワールドに入ったときの最初のマップ
  static String firstMapOf(String worldId) {
    final w = RpgCatalog.world(worldId);
    return w.routes.length > 1 ? '${w.id}_hub' : '${w.id}_${w.routes.first.id}';
  }


  /// 試験対策ワールドのマップ。集めたエリア（5教科を混ぜてよい）と
  /// 最後の「試験本番」を、同じ組み立て方で1本の航路にする。
  ///
  /// 定期テストの海は、船で大海原を進み、終盤は潜水艦で深海へ。
  /// 高校入試の空は、飛行船で雲海を進み、終盤はロケットで宇宙へ。
  static FieldMap forExam(ExamWorldPlan plan, List<StageDef> stages) {
    final realm = plan.realm;
    final key =
        'exam_${realm.name}_${plan.id}_${stages.map((s) => s.id).join(',')}';
    return _cache.putIfAbsent(
      key,
      () => _build(
        id: 'exam_${plan.id}',
        stages: stages,
        seed: plan.id.hashCode & 0x7fffffff,
        terrainOf: (s) => realm.terrainAt(stages.indexOf(s), stages.length),
        signText:
            '「${plan.title}」の${realm == StudyRealm.sea ? '航海' : '空の旅'}。'
            '範囲は${plan.subjectsLabel}。${realm.vehicle}で進み、'
            '最後は${realm.deepVehicle}で${realm.deep.label}の「試験本番」をめざそう。'
            '宝箱や泉の問題に正解すると、テスト対策ゲージがたまる。',
        goalText: '${plan.title}の合格証',
        label: (s) => s.isBoss
            ? '試験本番'
            : '${RpgCatalog.world(s.worldId).subject}・${s.name}',
      ),
    );
  }

  /// スタート地点のハブ。ルートの向きごとに、辺に出入口を並べる（1辺に3つまで）。
  static FieldMap _hub(WorldDef world) {
    final lines = [
      '###########',
      '#.........#',
      '#.T.....T.#',
      '#....S.N..#',
      '#.........#',
      '#.~.....~.#',
      '#....P....#',
      '#.........#',
      '#.~.....~.#',
      '#.........#',
      '#.T.....T.#',
      '#.........#',
      '###########',
    ].map((l) => l.split('')).toList();
    final h = lines.length, w = lines.first.length;
    final portals = <Cell, Portal>{};
    for (final dir in const ['up', 'left', 'right', 'down']) {
      final rs = world.routes.where((r) => r.direction == dir).toList();
      if (rs.length > 3) throw ArgumentError('1辺の出入口は3つまで: $dir');
      final slots = switch (rs.length) {
        1 => const [0.5],
        2 => const [0.3, 0.7],
        _ => const [0.2, 0.5, 0.8],
      };
      for (final (i, r) in rs.indexed) {
        final Cell cell = switch (dir) {
          'up' => (col: (w * slots[i]).floor(), row: 0),
          'down' => (col: (w * slots[i]).floor(), row: h - 1),
          'left' => (col: 0, row: (h * slots[i]).floor()),
          _ => (col: w - 1, row: (h * slots[i]).floor()),
        };
        lines[cell.row][cell.col] = 'O';
        portals[cell] = (target: '${world.id}_${r.id}', label: r.name);
      }
    }
    return FieldMap(
      [for (final l in lines) l.join()],
      id: '${world.id}_hub',
      terrainGrid: List.generate(h, (_) => List.filled(w, Terrain.town)),
      areaGrid: List.generate(h, (_) => List.filled(w, 0)),
      enemySpots: const {},
      safeCells: const {},
      areaLabels: {0: world.hubName},
      portals: portals,
      signText: world.hubSign,
    );
  }

  /// ルートの1本道。上へ進む形で作ってから、ルートの向きに回転させる。
  static FieldMap _route(WorldDef world, RouteInfo route) {
    final stages = world.stages.where((s) => s.branch == route.id).toList();
    final sections = <String>[];
    for (final s in stages) {
      if (!sections.contains(s.region)) sections.add(s.region);
    }
    final bosses = [
      for (final s in stages)
        if (s.isBoss) 'エリア${s.areaNo}',
    ];
    final hasHub = world.routes.length > 1;
    final up = _build(
      id: '${world.id}_${route.id}',
      stages: stages,
      seed: 3000 + stages.first.order * 7 + route.id.hashCode % 1000,
      label: (s) => '${route.name}・エリア${s.areaNo}・${s.name}',
      goalLabel: '${route.name}の玉座の先',
      backPortal: hasHub
          ? (target: '${world.id}_hub', label: world.hubName)
          : null,
      signText:
          'ここから${route.name}の道。${sections.join('、')}を順に進む。'
          '${bosses.isEmpty ? '' : 'ボスは${bosses.join('と')}。'}'
          '宿で授業を受けてから挑もう。隠し通路や知識の扉も探してみよう。',
      goalText: '${route.name}マスターのトロフィー',
    );
    return up._turned(route.direction);
  }

  /// 上へ進む形のマップを、[dir]（up / down / left / right）へ進む形に向きを変える
  FieldMap _turned(String dir) {
    if (dir == 'up') return this;
    final h = height, w = width;
    // 新しい座標 → もとの座標
    final (int nw, int nh, Cell Function(int c, int r) src) = switch (dir) {
      'down' => (w, h, (c, r) => (col: w - 1 - c, row: h - 1 - r)),
      'left' => (h, w, (c, r) => (col: r, row: c)),
      'right' => (h, w, (c, r) => (col: r, row: h - 1 - c)),
      _ => throw ArgumentError(dir),
    };
    final back = <Cell, Cell>{};
    for (var r = 0; r < nh; r++) {
      for (var c = 0; c < nw; c++) {
        back[src(c, r)] = (col: c, row: r);
      }
    }
    Cell to(Cell old) => back[old]!;
    return FieldMap(
      [
        for (var r = 0; r < nh; r++)
          [for (var c = 0; c < nw; c++) tileAt(src(c, r).col, src(c, r).row)]
              .join(),
      ],
      id: id,
      terrainGrid: [
        for (var r = 0; r < nh; r++)
          [
            for (var c = 0; c < nw; c++)
              terrainAt(src(c, r).col, src(c, r).row),
          ],
      ],
      areaGrid: [
        for (var r = 0; r < nh; r++)
          [for (var c = 0; c < nw; c++) areaAt(src(c, r).col, src(c, r).row)],
      ],
      enemySpots: {for (final e in enemySpots.entries) e.key: to(e.value)},
      safeCells: {
        for (final e in safeCells.entries)
          e.key: [for (final c in e.value) to(c)],
      },
      areaLabels: areaLabels,
      areaThemes: areaThemes,
      bossAreas: bossAreas,
      chestKinds: {for (final e in chestKinds.entries) to(e.key): e.value},
      portals: {for (final e in portals.entries) to(e.key): e.value},
      signText: signText,
      goalText: goalText,
    );
  }

  /// 上へ進む1本道のマップを作る。
  ///
  /// 上から：外壁 → ゴールの部屋 → [ゲートn → 部屋n]（n = 最後 → 1）→ 外壁。
  /// 敵の番号はステージの order。部屋はエリアの地形で組み立て方と見た目が変わる。
  static FieldMap _build({
    required String id,
    required List<StageDef> stages,
    required int seed,
    required String Function(StageDef s) label,
    Terrain Function(StageDef s)? terrainOf,
    String? goalLabel,
    Portal? backPortal,
    String signText = '',
    String goalText = 'トロフィーがある。',
  }) {
    final rnd = Random(seed);
    final areas = stages.length;
    final override = terrainOf;
    Terrain terrainAt(StageDef s) {
      if (override != null) return override(s);
      final t = Terrain.of(s);
      // 「試験本番」など地形の手がかりがないボスは、お城の大広間にする
      if (s.isBoss && t == Terrain.meadow && !s.name.contains('草原')) {
        return Terrain.castle;
      }
      return t;
    }

    // ゲートの列（左右に大きくずらして、寄り道したくなる形にする）
    final gateCols = [
      for (var n = 1; n <= areas; n++) 3 + rnd.nextInt(_width - 6),
    ];
    final rows = <String>[];
    final terrains = <Terrain>[];
    final areaOfRow = <int>[];
    final enemyRows = <int, int>{};
    final safe = <int, List<Cell>>{};
    final chestKinds = <Cell, ChestKind>{};
    String wall() => '#' * _width;

    void add(String line, Terrain terrain, int area) {
      rows.add(line);
      terrains.add(terrain);
      areaOfRow.add(area);
    }

    final lastTerrain = terrainAt(stages.last);
    final goalArea = stages.last.order + 1;
    add(wall(), lastTerrain, goalArea);
    final goal = List.filled(_width, '.')
      ..[0] = '#'
      ..[_width - 1] = '#';
    add(goal.join(), lastTerrain, goalArea);
    add((List.of(goal)..[_width ~/ 2] = 'G').join(), lastTerrain, goalArea);
    add(goal.join(), lastTerrain, goalArea);
    for (var k = areas; k >= 1; k--) {
      final stage = stages[k - 1];
      final terrain = terrainAt(stage);
      final gate = gateCols[k - 1];
      enemyRows[stage.order] = rows.length;
      add((wall().split('')..[gate] = 'E').join(), terrain, stage.order);
      final top = rows.length;
      final room = _Room.generate(
        area: k,
        terrain: terrain,
        boss: stage.isBoss,
        seed: seed + k * 97 + stage.id.hashCode % 991,
        entryCol: k > 1 ? gateCols[k - 2] : _width ~/ 2,
        exitCol: gate,
        isStart: k == 1,
        withSign: signText.isNotEmpty,
      );
      for (final line in room.lines) {
        add(line, terrain, stage.order);
      }
      safe[stage.order] = [
        for (final c in room.safe) (col: c.col, row: c.row + top),
      ];
      for (final e in room.chests.entries) {
        chestKinds[(col: e.key.col, row: e.key.row + top)] = e.value;
      }
    }
    final bottom = wall().split('');
    final portals = <Cell, Portal>{};
    if (backPortal != null) {
      bottom[_width ~/ 2] = 'O';
      portals[(col: _width ~/ 2, row: rows.length)] = backPortal;
    }
    add(bottom.join(), terrainAt(stages.first), stages.first.order);

    return FieldMap(
      rows,
      id: id,
      terrainGrid: [for (final t in terrains) List.filled(_width, t)],
      areaGrid: [for (final a in areaOfRow) List.filled(_width, a)],
      enemySpots: {
        for (final (i, s) in stages.indexed)
          s.order: (col: gateCols[i], row: enemyRows[s.order]!),
      },
      safeCells: safe,
      areaLabels: {
        for (final s in stages) s.order: label(s),
        goalArea: goalLabel ?? '${label(stages.last)}の先',
      },
      areaThemes: {
        for (final s in stages)
          s.order: s.grammarTheme.isEmpty
              ? terrainAt(s).label
              : '${terrainAt(s).label}・${s.grammarTheme}',
      },
      bossAreas: {
        for (final s in stages)
          if (s.isBoss) s.order,
      },
      chestKinds: chestKinds,
      portals: portals,
      signText: signText,
      goalText: goalText,
    );
  }
}

/// 1エリアの部屋（ふつうは 11 行、ボスの間は 13 行 × 31 列）を作る。
///
/// 1. 地形の組み立て方（ひらけた土地・森や洞窟・川と橋・建物）で障害物を置く
/// 2. 入口（下のゲート）から出口（上のゲート）まで、くねくねした道を掘る（水の上は橋）
/// 3. 入口から行けない場所は障害物で埋める（閉じこめられる場所をなくす）
/// 4. 宿・ワープ石・宝箱・泉・隠し通路・知識の扉・目印の飾りを置く
class _Room {
  _Room(this.lines, this.safe, this.chests);

  final List<String> lines;

  /// 部屋の中の座標（row は部屋の中での行）
  final List<Cell> safe;

  /// 部屋の中の宝箱の位置と種類
  final Map<Cell, ChestKind> chests;

  static const w = FieldMap._width;

  static _Room generate({
    required int area,
    required Terrain terrain,
    required bool boss,
    required int seed,
    required int entryCol,
    required int exitCol,
    required bool isStart,
    bool withSign = true,
  }) {
    final h = boss ? 13 : 11;
    final rnd = Random(seed);
    // true = 通れない
    var g = List.generate(h, (r) => List.filled(w, false));
    // 水・溶岩・雲の切れ目
    final water = List.generate(h, (r) => List.filled(w, false));
    bool inside(int r, int c) => r >= 0 && r < h && c > 0 && c < w - 1;

    void smooth(int times, int threshold) {
      for (var i = 0; i < times; i++) {
        g = List.generate(
          h,
          (r) => List.generate(w, (c) {
            if (c == 0 || c == w - 1) return true;
            var n = 0;
            for (var dr = -1; dr <= 1; dr++) {
              for (var dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                final rr = r + dr, cc = c + dc;
                if (rr < 0 || rr >= h || cc < 0 || cc >= w || g[rr][cc]) n++;
              }
            }
            return n >= threshold;
          }),
        );
      }
    }

    switch (terrain.layout) {
      case Layout.dense:
        for (var r = 0; r < h; r++) {
          for (var c = 0; c < w; c++) {
            g[r][c] = c == 0 || c == w - 1 || rnd.nextDouble() < 0.5;
          }
        }
        smooth(2, 5);
      case Layout.open:
        for (var r = 0; r < h; r++) {
          for (var c = 0; c < w; c++) {
            g[r][c] = c == 0 || c == w - 1 || rnd.nextDouble() < 0.14;
          }
        }
        // いくつかの木立・岩場
        for (var i = 0; i < 4 + rnd.nextInt(3); i++) {
          final cr = 1 + rnd.nextInt(h - 2), cc = 2 + rnd.nextInt(w - 4);
          final rad = 1 + rnd.nextInt(2);
          for (var r = cr - rad; r <= cr + rad; r++) {
            for (var c = cc - rad * 2; c <= cc + rad * 2; c++) {
              if (inside(r, c) && rnd.nextDouble() < 0.75) g[r][c] = true;
            }
          }
        }
        if (terrain == Terrain.hill) {
          // 段々の崖：横に長い岩の列（ところどころ切れ目）
          for (var r = 2; r < h - 2; r += 3) {
            for (var c = 1; c < w - 1; c++) {
              if (rnd.nextDouble() < 0.7) g[r][c] = true;
            }
          }
        }
      case Layout.water:
        for (var r = 0; r < h; r++) {
          for (var c = 0; c < w; c++) {
            g[r][c] = c == 0 || c == w - 1 || rnd.nextDouble() < 0.12;
          }
        }
        switch (terrain) {
          case Terrain.beach:
            // 片側が海。波打ちぎわはゆらぐ
            final left = rnd.nextBool();
            for (var r = 0; r < h; r++) {
              final depth = 7 + rnd.nextInt(3);
              for (var i = 1; i <= depth; i++) {
                final c = left ? i : w - 1 - i;
                water[r][c] = true;
              }
            }
          case Terrain.sky:
            // 雲の切れ目が2本
            for (final band in [h ~/ 3, h * 2 ~/ 3]) {
              for (var c = 1; c < w - 1; c++) {
                for (
                  var r = band;
                  r <= band + (rnd.nextDouble() < 0.5 ? 1 : 0);
                  r++
                ) {
                  if (r < h - 1) water[r][c] = true;
                }
              }
            }
          case Terrain.harbor:
            // 港：入り組んだ水路
            for (var c = 1; c < w - 1; c++) {
              water[h ~/ 2][c] = true;
              water[h ~/ 2 + 1][c] = true;
            }
            for (var i = 0; i < 3; i++) {
              final c = 3 + rnd.nextInt(w - 6);
              for (var r = 1; r < h - 1; r++) {
                if (rnd.nextDouble() < 0.8) water[r][c] = true;
              }
            }
          default:
            // 川：くねって横切る
            var r = 2 + rnd.nextInt(h - 5);
            for (var c = 1; c < w - 1; c++) {
              water[r][c] = true;
              water[r + 1][c] = true;
              if (rnd.nextDouble() < 0.3) {
                r = (r + (rnd.nextBool() ? 1 : -1)).clamp(1, h - 3);
                water[r][c] = true;
                water[r + 1][c] = true;
              }
            }
        }
        for (var r = 0; r < h; r++) {
          for (var c = 0; c < w; c++) {
            if (water[r][c]) g[r][c] = true;
          }
        }
      case Layout.grid:
        for (var r = 0; r < h; r++) {
          for (var c = 0; c < w; c++) {
            g[r][c] = c == 0 || c == w - 1;
          }
        }
        switch (terrain) {
          case Terrain.town:
            // 家（横3×縦2）が通りに並ぶ
            for (var r = 1; r < h - 2; r += 4) {
              for (var c = 2 + rnd.nextInt(2); c < w - 4; c += 5) {
                if (rnd.nextDouble() < 0.85) {
                  for (var dr = 0; dr < 2; dr++) {
                    for (var dc = 0; dc < 3; dc++) {
                      g[r + dr][c + dc] = true;
                    }
                  }
                }
              }
            }
          case Terrain.library:
            // 本棚が横に長く並び、ところどころ抜けられる
            for (var r = 2; r < h - 1; r += 3) {
              for (var c = 1; c < w - 1; c++) {
                g[r][c] = rnd.nextDouble() > 0.18;
              }
            }
          case Terrain.tower || Terrain.workshop:
            // 仕切りの壁が縦に並ぶ（迷路のような部屋）
            for (
              var c = 4 + rnd.nextInt(2);
              c < w - 2;
              c += 4 + rnd.nextInt(2)
            ) {
              final door = 1 + rnd.nextInt(h - 2);
              for (var r = 1; r < h - 1; r++) {
                if ((r - door).abs() > 0) g[r][c] = true;
              }
            }
          default:
            // 遺跡・殿堂・城：柱が規則正しく並ぶ
            for (var r = 1; r < h - 1; r += 2) {
              for (var c = (r ~/ 2).isEven ? 2 : 3; c < w - 1; c += 3) {
                if (rnd.nextDouble() < 0.8) g[r][c] = true;
              }
            }
        }
        // くずれた柱・荷物などを少し
        for (var r = 0; r < h; r++) {
          for (var c = 1; c < w - 1; c++) {
            if (rnd.nextDouble() < 0.05) g[r][c] = true;
          }
        }
    }

    // 入口から出口まで道を掘る（横に寄り道しながら）。水の上は橋になる
    final bridge = List.generate(h, (_) => List.filled(w, false));
    final path = <(int, int)>[];
    var r = h - 1, c = entryCol;
    void open(int rr, int cc) {
      if (!inside(rr, cc)) return;
      g[rr][cc] = false;
      if (water[rr][cc]) bridge[rr][cc] = true;
      path.add((rr, cc));
    }

    open(r, c);
    while (r > 0 || c != exitCol) {
      final roll = rnd.nextDouble();
      if (r > 0 && (roll < 0.35 || c == exitCol && roll < 0.8)) {
        r--;
      } else if (c != exitCol && roll < 0.85) {
        c += c < exitCol ? 1 : -1;
      } else {
        final side = rnd.nextBool() ? 1 : -1;
        if (c + side > 1 && c + side < w - 2) c += side;
      }
      open(r, c);
      // ところどころ道幅を広げる（水の上は広げない）
      if (rnd.nextDouble() < 0.4 && inside(r, c + 1) && !water[r][c + 1]) {
        open(r, c + 1);
      }
    }
    open(0, exitCol);
    // 川や海をわたる別の橋（寄り道用）
    if (terrain.layout == Layout.water) {
      for (var i = 0; i < 2; i++) {
        final cc = 2 + rnd.nextInt(w - 4);
        for (var rr = 1; rr < h - 1; rr++) {
          if (water[rr][cc]) {
            g[rr][cc] = false;
            bridge[rr][cc] = true;
          }
        }
      }
    }

    // 小部屋（隠し通路・知識の扉）のための岩場を、部屋の左右の端に取っておく
    final nookDepth = area.isOdd ? 2 : 1;
    final onPath = path.toSet();
    for (var tries = 0; tries < 60; tries++) {
      final left = rnd.nextBool();
      final r0 = 2 + rnd.nextInt(h - 4);
      final len = nookDepth + 1;
      final cols = [for (var i = 0; i < len; i++) left ? 1 + i : w - 2 - i];
      final front = left ? len + 1 : w - 2 - len;
      final cells = [
        for (var rr = r0 - 1; rr <= r0 + 1; rr++)
          for (final cc in cols) (rr, cc),
      ];
      if (cells.any(onPath.contains) || onPath.contains((r0, front))) continue;
      if (cells.any((p) => water[p.$1][p.$2])) continue;
      for (final (rr, cc) in cells) {
        g[rr][cc] = true;
      }
      // 小部屋の入口の前は床にしておく（道とつながっていれば使える）
      g[r0][front] = false;
      break;
    }

    // 入口から行けない床は埋める
    Set<(int, int)> reach(List<List<bool>> grid) {
      final seen = <(int, int)>{};
      final q = Queue<(int, int)>();
      if (!grid[h - 1][entryCol]) {
        q.add((h - 1, entryCol));
        seen.add((h - 1, entryCol));
      }
      while (q.isNotEmpty) {
        final (rr, cc) = q.removeFirst();
        for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nr = rr + dr, nc = cc + dc;
          if (nr < 0 || nr >= h || nc < 0 || nc >= w) continue;
          if (grid[nr][nc] || !seen.add((nr, nc))) continue;
          q.add((nr, nc));
        }
      }
      return seen;
    }

    final reachable = reach(g);
    for (var rr = 0; rr < h; rr++) {
      for (var cc = 0; cc < w; cc++) {
        if (!reachable.contains((rr, cc))) {
          g[rr][cc] = true;
          bridge[rr][cc] = false;
        }
      }
    }

    // 文字にする。水の地形でなくても、洞窟・火山などは障害物の一部を池にする
    final pondRate = switch (terrain) {
      Terrain.cave || Terrain.crystal || Terrain.lava => 0.5,
      Terrain.meadow ||
      Terrain.flower ||
      Terrain.forest ||
      Terrain.snow => 0.35,
      // 航路：島や雲のかたまりの一部が、うずしお・雷雲・ブラックホールになる
      Terrain.ocean || Terrain.cloudSea => 0.4,
      Terrain.abyss || Terrain.space => 0.45,
      _ => 0.0,
    };
    var pond = List.generate(
      h,
      (_) => List.generate(w, (_) => rnd.nextDouble() < pondRate),
    );
    for (var i = 0; i < 2; i++) {
      pond = List.generate(
        h,
        (r) => List.generate(w, (c) {
          var n = 0;
          for (var dr = -1; dr <= 1; dr++) {
            for (var dc = -1; dc <= 1; dc++) {
              final rr = r + dr, cc = c + dc;
              if (rr >= 0 && rr < h && cc >= 0 && cc < w && pond[rr][cc]) n++;
            }
          }
          return n >= 5;
        }),
      );
    }
    final tiles = List.generate(
      h,
      (rr) => List.generate(w, (cc) {
        if (cc == 0 || cc == w - 1) return '#';
        if (bridge[rr][cc]) return 'B';
        if (!g[rr][cc]) return '.';
        if (water[rr][cc] || pond[rr][cc]) return '~';
        return 'T';
      }),
    );

    // 話しかける物（宿・宝箱・隠し通路の入口など）。となりに歩ける床が残っていないといけない
    final needsAccess = <(int, int)>[];

    // 置いても道をふさがないマスか（出口まで・すべての床まで行けるままで、
    // 話しかける物のとなりにも床が残るか）
    bool canBlock(int rr, int cc) {
      if (g[rr][cc] || bridge[rr][cc]) return false;
      if ((rr == h - 1 && cc == entryCol) || (rr == 0 && cc == exitCol)) {
        return false;
      }
      final copy = [
        for (final row in g) [...row],
      ];
      copy[rr][cc] = true;
      final after = reach(copy);
      if (after.length != reachable.length - 1) return false;
      for (final (ar, ac) in needsAccess) {
        final ok = const [
          (0, 1),
          (0, -1),
          (1, 0),
          (-1, 0),
        ].any((d) => after.contains((ar + d.$1, ac + d.$2)));
        if (!ok) return false;
      }
      return true;
    }

    void place(String ch, int rr, int cc) {
      tiles[rr][cc] = ch;
      g[rr][cc] = true;
      reachable.remove((rr, cc));
      if (const {'I', 'X', 'C', 'W', 'S', 'N'}.contains(ch)) {
        needsAccess.add((rr, cc));
      }
    }

    // 入口からの距離
    Map<(int, int), int> distances() {
      final d = <(int, int), int>{(h - 1, entryCol): 0};
      final q = Queue<(int, int)>()..add((h - 1, entryCol));
      while (q.isNotEmpty) {
        final (rr, cc) = q.removeFirst();
        for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final nr = rr + dr, nc = cc + dc;
          if (nr < 0 || nr >= h || nc < 0 || nc >= w || g[nr][nc]) continue;
          if (d.containsKey((nr, nc))) continue;
          d[(nr, nc)] = d[(rr, cc)]! + 1;
          q.add((nr, nc));
        }
      }
      return d;
    }

    // ボスの間：道にじゅうたんを敷き、出口の両わきにかがり火
    if (boss) {
      for (final (rr, cc) in path) {
        if (tiles[rr][cc] == '.') tiles[rr][cc] = 'R';
      }
      for (final dc in const [-2, 2]) {
        if (inside(1, exitCol + dc) && canBlock(1, exitCol + dc)) {
          place('F', 1, exitCol + dc);
        }
      }
    }

    final chests = <Cell, ChestKind>{};

    // スタート地点と看板
    if (isStart) {
      place('P', h - 2, entryCol);
      g[h - 2][entryCol] = false; // P は歩ける
      reachable.add((h - 2, entryCol));
      if (withSign && canBlock(h - 3, entryCol - 2)) {
        place('S', h - 3, entryCol - 2);
      }
    }
    // 宿とワープ石：入口に近い床
    for (final ch in const ['I', 'X', 'N']) {
      final d = distances();
      // 入口から2マス以上はなれた床を、近い順に（見つからなければ遠くても置く）
      final cand =
          d.entries.where((e) => e.value >= 2).map((e) => e.key).toList()
            ..sort((a, b) => d[a]!.compareTo(d[b]!));
      for (final (rr, cc) in cand) {
        if (tiles[rr][cc] != '.') continue;
        if (canBlock(rr, cc)) {
          place(ch, rr, cc);
          break;
        }
      }
    }
    // 宝箱：入口から一番遠い床（行き止まりの奥）
    var d = distances();
    final far = d.keys.toList()..sort((a, b) => d[b]!.compareTo(d[a]!));
    for (final (rr, cc) in far) {
      if (rr == 0 && cc == exitCol) continue;
      if (tiles[rr][cc] != '.' && tiles[rr][cc] != 'R') continue;
      if (canBlock(rr, cc)) {
        place('C', rr, cc);
        chests[(col: cc, row: rr)] = ChestKind.main;
        break;
      }
    }
    // 泉：2エリアに1つ、真ん中くらいの距離に
    if (area.isEven) {
      d = distances();
      final maxD = d.values.reduce(max);
      final mid = d.keys.where((k) => (d[k]! - maxD ~/ 2).abs() <= 3).toList()
        ..shuffle(rnd);
      for (final (rr, cc) in mid) {
        if (tiles[rr][cc] != '.') continue;
        if (canBlock(rr, cc)) {
          place('W', rr, cc);
          break;
        }
      }
    }

    // 小部屋（隠し通路・知識の扉）：障害物の中に、入口 → 床 → 宝箱 の袋小路を掘る
    bool nook(String entrance, int depth, ChestKind kind) {
      final d = distances();
      final order = d.keys.toList()..sort((a, b) => d[b]!.compareTo(d[a]!));
      for (final (fr, fc) in order) {
        if (tiles[fr][fc] != '.' && tiles[fr][fc] != 'R') continue;
        for (final (dr, dc) in const [(0, 1), (0, -1), (-1, 0), (1, 0)]) {
          final cells = [
            for (var i = 1; i <= depth + 1; i++) (fr + dr * i, fc + dc * i),
          ];
          final ok = cells.every((p) {
            final (rr, cc) = p;
            if (rr < 1 || rr > h - 2 || cc < 1 || cc > w - 2) return false;
            if (!g[rr][cc] || tiles[rr][cc] != 'T') return false;
            // まわりに、ほかの床（歩ける所）がないこと
            for (final (ar, ac) in const [(0, 1), (0, -1), (-1, 0), (1, 0)]) {
              final nr = rr + ar, nc = cc + ac;
              if ((nr, nc) == (fr, fc)) continue;
              if (cells.contains((nr, nc))) continue;
              if (nr < 0 || nr >= h || nc < 0 || nc >= w) return false;
              if (!g[nr][nc] ||
                  tiles[nr][nc] != 'T' &&
                      tiles[nr][nc] != '~' &&
                      tiles[nr][nc] != '#') {
                return false;
              }
            }
            return true;
          });
          if (!ok) continue;
          final (er, ec) = cells.first;
          tiles[er][ec] = entrance;
          needsAccess.add((er, ec));
          for (final (rr, cc) in cells.skip(1).take(depth - 1)) {
            tiles[rr][cc] = '.';
          }
          final (cr, cc) = cells.last;
          tiles[cr][cc] = 'C';
          chests[(col: cc, row: cr)] = kind;
          return true;
        }
      }
      return false;
    }

    if (area.isOdd) {
      nook('H', nookDepth, ChestKind.secret);
    } else {
      nook('D', nookDepth, ChestKind.vault);
    }

    // 目印の飾り：エリアに2つ
    d = distances();
    final spots = d.keys.where((k) => d[k]! >= 4).toList()..shuffle(rnd);
    var decorations = 0;
    for (final (rr, cc) in spots) {
      if (decorations >= 2) break;
      if (tiles[rr][cc] != '.') continue;
      // 道の真ん中はさけて、障害物のそばに置く
      final nearWall = [
        (0, 1),
        (0, -1),
        (1, 0),
        (-1, 0),
      ].any((p) => rr + p.$1 >= 0 && rr + p.$1 < h && g[rr + p.$1][cc + p.$2]);
      if (nearWall && canBlock(rr, cc)) {
        place('F', rr, cc);
        decorations++;
      }
    }

    // 強敵：3エリアに1つ、行き止まりの奥の床に
    if (area % 3 == 2 && !boss) {
      d = distances();
      final cand = d.keys.toList()..sort((a, b) => d[b]!.compareTo(d[a]!));
      for (final (rr, cc) in cand) {
        if (tiles[rr][cc] != '.') continue;
        if (rr == 0 || rr == h - 1) continue;
        if (canBlock(rr, cc)) {
          place('M', rr, cc);
          break;
        }
      }
    }

    // 亡霊などを置いても道をふさがないマス（入口から近すぎない床）
    d = distances();
    final safe = <Cell>[
      for (final e in d.entries)
        if (e.value >= 3 &&
            tiles[e.key.$1][e.key.$2] == '.' &&
            canBlock(e.key.$1, e.key.$2))
          (col: e.key.$2, row: e.key.$1),
    ]..sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);

    return _Room([for (final row in tiles) row.join()], safe, chests);
  }
}
