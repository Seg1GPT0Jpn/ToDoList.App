import 'dart:math';

import '../data/catalog.dart';
import '../models/enemy.dart';
import '../models/stage.dart';
import '../models/world.dart';
import 'sea_battle.dart';

/// 試験対策ワールド：試験範囲を入力すると、その範囲のエリアを集めて
/// 1つのワールドを作る（定期テストの海の機能）。
///
/// 6教科（英語・数学・国語・理科・社会・情報）のエリアを1つのワールドに
/// まとめられる。歩けるフィールドも同じ並びで作られる。
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
    this.examDate,
    this.gauge = 0,
    this.openedChests = const {},
  });

  final String id;

  /// 試験の名前（例：2学期中間テスト）
  final String title;

  /// 最初に選んだ教科のワールド（古いデータとの互換用）。
  /// 教科の一覧は [worldIds] を使う。
  final String worldId;

  /// 試験の日（決めていなければ null）
  final DateTime? examDate;

  /// テスト対策ゲージ（0〜[ExamWorlds.gaugeMax]）。
  /// エリアのクリア・宝箱・泉の問題に正解するとたまる。
  final int gauge;

  /// フィールドで開けた宝箱（このワールドの中だけで使う）
  final Set<String> openedChests;

  /// ふくまれる教科のワールド（ステージの並び順）
  List<String> get worldIds {
    final out = <String>[];
    for (final id in stageIds) {
      final s = ExamWorlds.stageById(id);
      if (s != null && !out.contains(s.worldId)) out.add(s.worldId);
    }
    return out.isEmpty ? [worldId] : out;
  }

  /// 画面に出す教科名（例：数学・英語）
  String get subjectsLabel => [
        for (final w in worldIds) RpgCatalog.world(w).subject,
      ].join('・');

  /// 試験まであと何日か（試験日が未設定なら null。当日は 0）
  int? daysLeft(DateTime today) {
    final d = examDate;
    if (d == null) return null;
    final a = DateTime.utc(today.year, today.month, today.day);
    final b = DateTime.utc(d.year, d.month, d.day);
    return b.difference(a).inDays;
  }

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

  ExamWorldPlan copyWith({
    int? clearedCount,
    String? title,
    int? gauge,
    Set<String>? openedChests,
  }) =>
      ExamWorldPlan(
        id: id,
        title: title ?? this.title,
        worldId: worldId,
        stageIds: stageIds,
        createdAt: createdAt,
        rangeText: rangeText,
        clearedCount: clearedCount ?? this.clearedCount,
        examDate: examDate,
        gauge: (gauge ?? this.gauge).clamp(0, ExamWorlds.gaugeMax),
        openedChests: openedChests ?? this.openedChests,
      );

  /// ゲージを [points] ふやした形
  ExamWorldPlan addGauge(int points) => copyWith(gauge: gauge + points);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'worldId': worldId,
        'stageIds': stageIds,
        'rangeText': rangeText,
        'createdAt': createdAt.toIso8601String(),
        'clearedCount': clearedCount,
        if (examDate != null) 'examDate': examDate!.toIso8601String(),
        'gauge': gauge,
        if (openedChests.isNotEmpty) 'openedChests': openedChests.toList(),
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
        examDate: DateTime.tryParse(map['examDate'] as String? ?? ''),
        gauge: (map['gauge'] as num?)?.toInt() ?? 0,
        openedChests:
            Set<String>.from(map['openedChests'] as List? ?? const []),
      );
}

class ExamWorlds {
  const ExamWorlds._();

  /// 1つのワールドに集められるエリアの数（6教科をまとめて、1教科あたり10エリアほど）
  static const maxAreas = 60;

  /// テスト対策ゲージの最大
  static const gaugeMax = 100;

  static final Map<String, StageDef> _stages = {
    for (final w in RpgCatalog.worlds)
      for (final s in w.stages) s.id: s,
  };

  /// すべての教科から、ID でステージを探す
  static StageDef? stageById(String id) => _stages[id];

  /// 教科ごとの試験範囲から、合うエリアを集める（教科の順 → ワールドの並び順）。
  /// [ranges] は ワールドID → 試験範囲の文章。
  static List<StageDef> matchAll(Map<String, String> ranges) => [
        for (final e in ranges.entries)
          ...match(RpgCatalog.world(e.key), e.value),
      ];

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
    final picked = [
      for (final id in plan.stageIds)
        if (stageById(id) != null) stageById(id)!,
    ];
    final curve = RpgCatalog.englishStages;
    final hard = level == null
        ? null
        : SeaBattle.stage(
            id: plan.id,
            title: plan.title,
            worldId: picked.isEmpty ? plan.worldId : picked.first.worldId,
            level: level,
            normalTimeLimitSeconds: 20,
          ).enemy;
    EnemyDef scaled(EnemyDef e, int k, {bool boss = false}) {
      final base = curve[(k - 1).clamp(0, 9)].enemy;
      final hp = hard == null
          ? base.maxHp
          // エリアが進むほど少しずつ強く。60エリアでも強くなりすぎないよう、20で止める
          : (hard.maxHp * (0.7 + 0.03 * min(k, 20))).round();
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
          worldId: picked[i].worldId,
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
    final lastWorld = RpgCatalog.world(last.worldId);
    final bossK = (picked.length + 1).clamp(1, 10);
    stages.add(
      StageDef(
        id: 'exam_${plan.id}_boss',
        worldId: last.worldId,
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
            look: lastWorld.stages
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
