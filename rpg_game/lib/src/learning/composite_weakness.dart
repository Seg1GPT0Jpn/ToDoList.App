import '../curriculum/curriculum.dart';
import '../curriculum/curriculum_progress.dart';
import '../models/question.dart';
import 'learning_record.dart';
import 'learning_route.dart';

/// 複合弱点：2つの単元を組み合わせる問題でつまずいていること。
///
/// - 組み合わせる単元そのものが弱点 → 先にその単元を固める（土台の弱点）
/// - どちらの単元も1つずつならできる → 組み合わせ方の練習が必要（複合の弱点）
class CompositeWeakness {
  const CompositeWeakness({
    required this.unit,
    required this.combined,
    required this.tried,
    required this.missed,
    required this.unitStatus,
    required this.combinedStatus,
  });

  /// 問題の単元
  final String unit;

  /// 組み合わせて使う単元
  final String combined;

  /// その組み合わせの問題の数と、つまずいた数
  final int tried;
  final int missed;

  final RouteStatus unitStatus;
  final RouteStatus combinedStatus;

  /// 土台（組み合わせる単元そのもの）が弱点か
  bool get foundationWeak => combinedStatus.needsWork || unitStatus.needsWork;

  String get title =>
      '${Curriculum.node(unit).displayName} × ${Curriculum.node(combined).displayName}';

  String get advice {
    if (combinedStatus.needsWork) {
      return '「${Curriculum.node(combined).displayName}」そのものが弱点です。先にこちらを固めましょう。';
    }
    if (unitStatus.needsWork) {
      return '「${Curriculum.node(unit).displayName}」そのものが弱点です。先にこちらを固めましょう。';
    }
    return '1つずつならできています。2つを組み合わせる複合問題で、方針の立て方を練習しましょう。';
  }

  /// 問題ごとの得点の割合（0〜1）から、複合弱点を探す。
  /// [credits] は問題 ID → 得点の割合。半分未満を「つまずいた」とする。
  static List<CompositeWeakness> find(
    Iterable<QuizQuestion> questions,
    Map<String, double> credits,
    CurriculumProgress progress,
  ) {
    final tried = <(String, String), int>{};
    final missed = <(String, String), int>{};
    for (final q in questions) {
      final unit = q.unit;
      final credit = credits[q.id];
      if (unit == null || credit == null || !Curriculum.contains(unit)) {
        continue;
      }
      for (final c in q.combines) {
        if (!Curriculum.contains(c) || c == unit) continue;
        final key = (unit, c);
        tried[key] = (tried[key] ?? 0) + 1;
        if (credit < 0.5) missed[key] = (missed[key] ?? 0) + 1;
      }
    }
    final out = [
      for (final e in missed.entries)
        CompositeWeakness(
          unit: e.key.$1,
          combined: e.key.$2,
          tried: tried[e.key]!,
          missed: e.value,
          unitStatus: RouteStatus.of(progress[e.key.$1]),
          combinedStatus: RouteStatus.of(progress[e.key.$2]),
        ),
    ]..sort((a, b) => b.missed.compareTo(a.missed));
    return out;
  }

  /// 学習記録の正答率を、[find] に渡す得点の割合にする
  static Map<String, double> creditsFrom(LearningRecord record) => {
        for (final e in record.stats.entries)
          if (e.value.attempts > 0) e.key: e.value.accuracy,
      };
}
