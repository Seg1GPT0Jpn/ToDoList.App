import '../learning/learning_record.dart';
import 'curriculum.dart';
import 'data/curriculum_index.dart';

/// 学習体系の1つの節での、学習の進みぐあい。
class NodeProgress {
  const NodeProgress({
    required this.node,
    required this.questionCount,
    this.answered = 0,
    this.attempts = 0,
    this.correct = 0,
    this.mastered = 0,
    this.firstTried = 0,
    this.firstCorrect = 0,
  });

  final CurriculumNode node;

  /// この節（下の節をふくむ）にある問題の数
  final int questionCount;

  /// 答えたことのある問題の数
  final int answered;
  final int attempts;
  final int correct;

  /// 習得した（間隔をあけて3回正解した）問題の数
  final int mastered;

  /// 初回の結果が分かる問題の数と、そのうち初回で正解した数
  final int firstTried;
  final int firstCorrect;

  /// 判定に足りるだけ答えたか
  bool get rated => answered >= minAnswered;
  static const minAnswered = 5;

  /// 正答率（0〜100。答えていなければ null）
  int? get accuracy =>
      attempts == 0 ? null : (correct * 100 / attempts).round();

  /// 初回正答率（0〜100。分からなければ null）
  int? get firstTryAccuracy =>
      firstTried == 0 ? null : (firstCorrect * 100 / firstTried).round();

  /// 問題のうち、答えたことのある割合（0〜100）
  int get coverage => questionCount == 0
      ? 0
      : (answered * 100 / questionCount).round().clamp(0, 100);

  /// 問題のうち、習得した割合（0〜100）
  int get masteryRate => questionCount == 0
      ? 0
      : (mastered * 100 / questionCount).round().clamp(0, 100);
}

/// 学習記録を、学習体系の節ごとにまとめる。
class CurriculumProgress {
  CurriculumProgress._(this._acc);

  final Map<String, _Acc> _acc;

  /// 学習記録から、すべての節の進みぐあいを計算する
  factory CurriculumProgress.of(LearningRecord record) {
    final acc = <String, _Acc>{};
    for (final s in record.stats.values) {
      final unit = s.unit;
      if (unit.isEmpty || !Curriculum.contains(unit)) continue;
      final parts = unit.split('.');
      for (var i = 1; i <= parts.length; i++) {
        final a = acc.putIfAbsent(parts.take(i).join('.'), _Acc.new);
        a.answered++;
        a.attempts += s.attempts;
        a.correct += s.correct;
        if (s.mastered) a.mastered++;
        final first = s.firstTryCorrect;
        if (first != null) {
          a.firstTried++;
          if (first) a.firstCorrect++;
        }
      }
    }
    return CurriculumProgress._(acc);
  }

  /// 節の問題数（下の節をふくむ）
  static int questionCount(String id) => curriculumQuestionCounts[id] ?? 0;

  /// 単元・小単元の問題が入っている問題セット（下の節をふくむ）
  static List<String> setsFor(String id) {
    final out = <String>{};
    for (final e in curriculumUnitSets.entries) {
      if (e.key == id || e.key.startsWith('$id.')) out.addAll(e.value);
    }
    return out.toList()..sort();
  }

  NodeProgress operator [](String id) {
    final a = _acc[id];
    return NodeProgress(
      node: Curriculum.node(id),
      questionCount: questionCount(id),
      answered: a?.answered ?? 0,
      attempts: a?.attempts ?? 0,
      correct: a?.correct ?? 0,
      mastered: a?.mastered ?? 0,
      firstTried: a?.firstTried ?? 0,
      firstCorrect: a?.firstCorrect ?? 0,
    );
  }

  /// 判定できる単元を、正答率の低い順に（苦手な単元）
  List<NodeProgress> weakest({String? under, int limit = 5}) {
    final out = <NodeProgress>[
      for (final n in Curriculum.all)
        if (n.level == CurriculumLevel.unit &&
            (under == null || n.id == under || n.id.startsWith('$under.')))
          this[n.id],
    ]..removeWhere((p) => !p.rated);
    out.sort((a, b) => a.accuracy!.compareTo(b.accuracy!));
    return out.take(limit).toList();
  }
}

class _Acc {
  int answered = 0;
  int attempts = 0;
  int correct = 0;
  int mastered = 0;
  int firstTried = 0;
  int firstCorrect = 0;
}
