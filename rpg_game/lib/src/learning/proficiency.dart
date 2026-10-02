import 'dart:math';

import '../data/catalog.dart';
import '../models/question.dart';
import '../models/stage.dart';
import '../study/sea_catalog.dart';
import 'learning_record.dart';
import 'question_stat.dart';

/// 1つの分野の熟練度
class SkillScore {
  const SkillScore({
    required this.subject,
    required this.field,
    required this.answered,
    required this.attempts,
    required this.score,
    required this.mastered,
  });

  /// 教科（ワールド ID）
  final String subject;

  /// 分野（例：文法、化学、2次関数）
  final String field;

  /// 答えたことのある問題の数
  final int answered;

  /// 答えた回数の合計
  final int attempts;

  /// 熟練度（0〜100）。実際の正答率から計算する
  final int score;

  /// 習得した問題の数
  final int mastered;

  /// 判定に足りるだけ答えたか（少なすぎるときは熟練度を「—」にする）
  bool get rated => answered >= Proficiency.minAnswered;
}

/// 学習ステータス：ゲームの中で勝手に上がる数字ではなく、
/// 実際に答えた記録（正答率・習得）から計算する。
///
/// - 英語は「文法・単語・長文・熟語」
/// - ほかの教科は、ルート（物理・日本史・古文・数学Ⅱ など）ごと
/// - 単元（ステージ）ごとの熟練度も出せる
class Proficiency {
  const Proficiency._();

  /// 熟練度を出すのに必要な、答えた問題の数
  static const minAnswered = 5;

  static final Map<String, StageDef> _stageOfSet = {
    for (final w in RpgCatalog.worlds)
      for (final s in w.stages) s.questionSetId: s,
  };

  static final Map<String, String> _seaTitle = {
    for (final u in SeaCatalog.units) u.id: u.title,
  };

  /// その問題セットの、もとのステージ（英語の単語帳・定期テストの海は null）
  static StageDef? stageOfSet(String setId) => _stageOfSet[setId];

  /// 教科ごとの分野の並び（画面に出す順）
  static List<String> fieldsOf(String subject) {
    if (subject == RpgCatalog.englishWorldId) {
      return const ['文法', '単語', '長文', '熟語'];
    }
    final w = RpgCatalog.world(subject);
    if (w.routes.length > 1) return [for (final r in w.routes) r.name];
    final out = <String>[];
    for (final s in w.stages) {
      if (!out.contains(s.region)) out.add(s.region);
    }
    return out;
  }

  /// 1問の記録が、どの教科のどの分野か
  static (String subject, String field)? fieldOf(QuestionStat stat) {
    final setId = stat.setId;
    if (setId.startsWith('words_') || setId.startsWith('tsuzutan_')) {
      return (RpgCatalog.englishWorldId, '単語');
    }
    if (setId.startsWith('idioms_')) return (RpgCatalog.englishWorldId, '熟語');
    final subject = LearningRecord.subjectOf(setId);
    if (subject == RpgCatalog.englishWorldId) {
      return (RpgCatalog.englishWorldId, _englishField(stat.category));
    }
    final stage = _stageOfSet[setId];
    if (stage == null) return null;
    final w = RpgCatalog.world(stage.worldId);
    final field = w.routes.length > 1
        ? w.route(stage.branch)?.name ?? stage.branch
        : stage.region;
    return (w.id, field);
  }

  static String _englishField(String category) => switch (category) {
        'meaning' || 'partOfSpeech' => '単語',
        'reading' => '長文',
        _ => '文法',
      };

  static SkillScore _score(
      String subject, String field, List<QuestionStat> xs) {
    final attempts = xs.fold<int>(0, (a, s) => a + s.attempts);
    final correct = xs.fold<int>(0, (a, s) => a + s.correct);
    // 分野全体の実際の正答率
    final avg = attempts == 0 ? 0.0 : correct / attempts;
    return SkillScore(
      subject: subject,
      field: field,
      answered: xs.length,
      attempts: attempts,
      score: (avg * 100).round().clamp(0, 100),
      mastered: xs.where((s) => s.mastered).length,
    );
  }

  /// 教科ごとの分野の熟練度（答えていない分野もふくめて、決まった順に並べる）
  static Map<String, List<SkillScore>> bySubject(LearningRecord record) {
    final groups = <String, Map<String, List<QuestionStat>>>{};
    for (final s in record.stats.values) {
      final f = fieldOf(s);
      if (f == null) continue;
      groups.putIfAbsent(f.$1, () => {}).putIfAbsent(f.$2, () => []).add(s);
    }
    return {
      for (final w in RpgCatalog.worlds)
        w.id: [
          for (final field in fieldsOf(w.id))
            _score(w.id, field, groups[w.id]?[field] ?? const []),
        ],
    };
  }

  /// 単元（ステージ）の熟練度。定期テストの海の同じ単元はふくめない
  static SkillScore ofStage(LearningRecord record, StageDef stage) {
    final sets = stage.questionSetIds.toSet();
    final own = [
      for (final s in record.stats.values)
        if (s.setId == stage.questionSetId ||
            (stage.questionSetIds.length == 1 && sets.contains(s.setId)))
          s,
    ];
    return _score(
      stage.worldId,
      stage.grammarTheme.isEmpty ? stage.name : stage.grammarTheme,
      own,
    );
  }

  /// 単元ごとの熟練度（苦手な順）。判定できるものだけ
  static List<(StageDef, SkillScore)> weakestUnits(
    LearningRecord record, {
    String? subject,
    int limit = 5,
  }) {
    final bySet = <String, List<QuestionStat>>{};
    for (final s in record.stats.values) {
      bySet.putIfAbsent(s.setId, () => []).add(s);
    }
    final out = <(StageDef, SkillScore)>[];
    for (final e in bySet.entries) {
      final stage = _stageOfSet[e.key];
      if (stage == null) continue;
      if (subject != null && stage.worldId != subject) continue;
      final score = _score(stage.worldId, stage.grammarTheme, e.value);
      if (score.rated) out.add((stage, score));
    }
    out.sort((a, b) => a.$2.score.compareTo(b.$2.score));
    return out.take(limit).toList();
  }

  /// 定期テストの海の単元名（英語の分野の中身を説明するのに使う）
  static String? seaUnitTitle(String setId) => _seaTitle[setId];

  /// 教科の学習レベル：習得した問題の数で上がる（ゲームのレベルとは別）
  static int subjectLevel(LearningRecord record, String subject) {
    final mastered = record.stats.values
        .where((s) => s.mastered && (fieldOf(s)?.$1 ?? '') == subject)
        .length;
    return 1 + sqrt(mastered * 2).floor();
  }

  /// 総合力（0〜100）：判定できた分野の熟練度の平均。
  /// 答えていない教科は 0 点として数える（すべての教科をまんべんなく）。
  static int totalPower(LearningRecord record) {
    final subjects = bySubject(record);
    var sum = 0.0;
    for (final fields in subjects.values) {
      final rated = fields.where((f) => f.rated).toList();
      sum += rated.isEmpty
          ? 0
          : rated.map((f) => f.score).reduce((a, b) => a + b) / rated.length;
    }
    return subjects.isEmpty ? 0 : (sum / subjects.length).round();
  }

  /// 問題の種類の日本語名（英語の分野の説明用）
  static String categoryLabel(String name) =>
      QuestionCategory.values.where((c) => c.name == name).firstOrNull?.label ??
      '';
}
