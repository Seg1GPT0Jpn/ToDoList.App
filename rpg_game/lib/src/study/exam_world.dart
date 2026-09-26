import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/stage.dart';
import '../models/world.dart';
import 'sea_battle.dart';

/// 試験対策ワールド：試験範囲を入力すると、その範囲のエリアを集めて
/// 1本道のワールドを作る（定期テストの海の機能）。
///
/// 問題はすべて RPG と同じ自作問題を使う。遊んでも RPG の進行は変わらない。
class ExamWorldPlan {
  const ExamWorldPlan({
    required this.id,
    required this.title,
    required this.worldId,
    required this.stageIds,
    required this.createdAt,
    this.rangeText = '',
    this.clearedCount = 0,
  });

  final String id;

  /// 試験の名前（例：2学期中間テスト 数学）
  final String title;

  /// 元にした教科のワールド
  final String worldId;

  /// 集めたエリア（RPG のステージ ID）。この順に並ぶ
  final List<String> stageIds;

  /// 入力した試験範囲（表示用）
  final String rangeText;
  final DateTime createdAt;

  /// 何ステージ目までクリアしたか（最後の「試験本番」をふくむ）
  final int clearedCount;

  /// ボスをふくめたステージ数
  int get length => stageIds.length + 1;
  bool get completed => clearedCount >= length;

  ExamWorldPlan copyWith({int? clearedCount, String? title}) => ExamWorldPlan(
        id: id,
        title: title ?? this.title,
        worldId: worldId,
        stageIds: stageIds,
        createdAt: createdAt,
        rangeText: rangeText,
        clearedCount: clearedCount ?? this.clearedCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'worldId': worldId,
        'stageIds': stageIds,
        'rangeText': rangeText,
        'createdAt': createdAt.toIso8601String(),
        'clearedCount': clearedCount,
      };

  factory ExamWorldPlan.fromMap(Map<String, dynamic> map) => ExamWorldPlan(
        id: map['id'] as String,
        title: map['title'] as String? ?? '試験対策',
        worldId: map['worldId'] as String,
        stageIds: List<String>.from(map['stageIds'] as List? ?? const []),
        rangeText: map['rangeText'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime(2000),
        clearedCount: (map['clearedCount'] as num?)?.toInt() ?? 0,
      );
}

class ExamWorlds {
  const ExamWorlds._();

  /// 1つのワールドに集められるエリアの数
  static const maxAreas = 20;

  /// 入力のゆれをそろえる（全角英数字→半角、漢数字の「二次」→「2次」など）
  static String normalize(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0xFF10 && r <= 0xFF19) {
        buf.writeCharCode(r - 0xFF10 + 0x30);
      } else if (r >= 0xFF21 && r <= 0xFF3A) {
        buf.writeCharCode(r - 0xFF21 + 0x41);
      } else if (r >= 0xFF41 && r <= 0xFF5A) {
        buf.writeCharCode(r - 0xFF41 + 0x61);
      } else if (r == 0x20 || r == 0x3000) {
        continue;
      } else {
        buf.writeCharCode(r);
      }
    }
    var out = buf.toString().toLowerCase();
    const kanji = {'一': '1', '二': '2', '三': '3', '四': '4', '五': '5'};
    for (final e in kanji.entries) {
      out = out.replaceAll('${e.key}次', '${e.value}次');
    }
    const roman = {
      'ⅰ': 'i',
      'ⅱ': 'ii',
      'ⅲ': 'iii',
      'Ⅰ': 'i',
      'Ⅱ': 'ii',
      'Ⅲ': 'iii'
    };
    for (final e in roman.entries) {
      out = out.replaceAll(e.key.toLowerCase(), e.value);
    }
    return out;
  }

  /// 試験範囲の文章を、キーワードに分ける
  static List<String> keywords(String rangeText) => [
        for (final t in rangeText.split(RegExp(r'[、,，。．.・/／\n\r\t;；]+|と|や')))
          if (normalize(t).runes.length >= 2) normalize(t),
      ];

  /// そのステージを探すときに見る文字（単元名・場所・分野・ルート名）
  static String searchText(WorldDef world, StageDef s) => normalize(
        [
          s.grammarTheme,
          s.name,
          s.region,
          s.vocabLevel,
          if (s.branch.isNotEmpty) world.route(s.branch)?.name ?? '',
        ].join(' '),
      );

  /// 試験範囲に合うエリアを探す（ワールドの並び順のまま）
  static List<StageDef> match(WorldDef world, String rangeText) {
    final words = keywords(rangeText);
    if (words.isEmpty) return const [];
    return [
      for (final s in world.stages)
        if (words.any((w) => searchText(world, s).contains(w))) s,
    ];
  }

  /// プランから、実際に戦うステージを作る。
  ///
  /// 敵の強さは元のエリアではなく、ワールドの中の順番で決める
  /// （英語ワールドの曲線をなぞる）。最後に「試験本番」のボスがいて、
  /// 範囲のすべての問題から出題する。
  ///
  /// [level] を渡すと、定期テストの海と同じ「とても難しい」強さにする
  /// （エリアが進むほど少しずつ HP が増え、試験本番はさらに強い）。
  static List<StageDef> build(ExamWorldPlan plan, {int? level}) {
    final world = RpgCatalog.world(plan.worldId);
    final byId = {for (final s in world.stages) s.id: s};
    final picked = [
      for (final id in plan.stageIds)
        if (byId[id] != null) byId[id]!,
    ];
    final curve = RpgCatalog.englishStages;
    final hard = level == null
        ? null
        : SeaBattle.stage(
            id: plan.id,
            title: plan.title,
            worldId: plan.worldId,
            level: level,
            normalTimeLimitSeconds: 20,
          ).enemy;
    EnemyDef scaled(EnemyDef e, int k, {bool boss = false}) {
      final base = curve[(k - 1).clamp(0, 9)].enemy;
      final hp =
          hard == null ? base.maxHp : (hard.maxHp * (0.7 + 0.03 * k)).round();
      return EnemyDef(
        id: 'exam_${plan.id}_$k',
        name: e.name,
        maxHp: boss ? (hp * 1.3).round() : hp,
        attack: hard?.attack ?? base.attack,
        description: e.description,
        look: e.look,
        color: e.color,
        weakness: e.weakness,
        introLine: e.introLine,
        defeatLine: e.defeatLine,
      );
    }

    final stages = <StageDef>[
      for (var i = 0; i < picked.length; i++)
        StageDef(
          id: 'exam_${plan.id}_${i + 1}',
          worldId: world.id,
          order: i + 1,
          name: picked[i].name,
          region: plan.title,
          enemy: scaled(picked[i].enemy, i + 1),
          questionSetIds: picked[i].questionSetIds,
          expReward: 0,
          timeLimitSeconds: level == null
              ? picked[i].timeLimitSeconds
              : SeaBattle.timeLimit(picked[i].timeLimitSeconds),
          readingTimeLimitSeconds: level == null
              ? picked[i].readingTimeLimitSeconds
              : SeaBattle.timeLimit(picked[i].readingTimeLimitSeconds),
          grammarTheme: picked[i].grammarTheme,
          vocabLevel: picked[i].vocabLevel,
        ),
    ];
    if (picked.isEmpty) return stages;
    final last = picked.last;
    final bossK = (picked.length + 1).clamp(1, 10);
    stages.add(
      StageDef(
        id: 'exam_${plan.id}_boss',
        worldId: world.id,
        order: picked.length + 1,
        name: '試験本番',
        region: plan.title,
        isBoss: true,
        enemy: scaled(
          EnemyDef(
            id: 'boss',
            name: '範囲の番人',
            maxHp: 1,
            attack: 1,
            look: world.stages
                .lastWhere((s) => s.isBoss, orElse: () => last)
                .enemy
                .look,
            color: 0xFF37474F,
            description: '試験範囲のすべてを知る番人。',
            introLine: '${plan.title}の範囲、すべてから出題する。準備はいいか！',
            defeatLine: 'この調子なら、本番も大丈夫だ…',
          ),
          bossK,
          boss: true,
        ),
        questionSetIds: [
          for (final s in picked) ...s.questionSetIds,
        ].toSet().toList(),
        expReward: 0,
        timeLimitSeconds: level == null
            ? last.timeLimitSeconds
            : SeaBattle.timeLimit(last.timeLimitSeconds),
        readingTimeLimitSeconds: level == null
            ? last.readingTimeLimitSeconds
            : SeaBattle.timeLimit(last.readingTimeLimitSeconds),
        grammarTheme: '範囲のまとめ',
        vocabLevel: plan.rangeText,
      ),
    );
    return stages;
  }
}
