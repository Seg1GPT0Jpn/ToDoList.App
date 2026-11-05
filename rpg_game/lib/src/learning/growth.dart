import '../curriculum/question_meta.dart';
import 'learning_record.dart';
import 'question_stat.dart';

/// 1つのものさしでの成績（何問中いくつ）
class GrowthMeasure {
  const GrowthMeasure(this.label, this.description, this.tried, this.correct);

  final String label;
  final String description;
  final int tried;
  final int correct;

  /// 判定に足りる数か
  bool get rated => tried >= minTried;
  static const minTried = 5;

  /// 0〜100（まだ答えていなければ null）
  int? get percent => tried == 0 ? null : (correct * 100 / tried).round();
}

/// 成長の見える化：「どれだけ解いたか」ではなく「何ができるようになったか」を、
/// 4つのものさしで表す。
///
/// - 初見正答率：初めて見た問題に、1回目で正解できた割合
/// - 応用問題：思考レベル4（複合問題）以上の問題の正答率
/// - 初見問題：見慣れない形の問題（難しさの軸「初見」が高い）の正答率
/// - 定着率：間をあけて（3日以上）もう一度答えたときに正解できた割合
class GrowthReport {
  const GrowthReport({
    required this.firstTry,
    required this.applied,
    required this.novel,
    required this.retention,
  });

  final GrowthMeasure firstTry;
  final GrowthMeasure applied;
  final GrowthMeasure novel;
  final GrowthMeasure retention;

  List<GrowthMeasure> get all => [firstTry, applied, novel, retention];

  /// [subject] を指定すると、その教科の問題だけで数える
  factory GrowthReport.of(LearningRecord record, {String? subject}) {
    var firstTried = 0, firstCorrect = 0;
    var appliedTried = 0, appliedCorrect = 0;
    var novelTried = 0, novelCorrect = 0;
    var gapTried = 0, gapCorrect = 0;
    for (final s in _stats(record, subject)) {
      final f = s.firstTryCorrect;
      if (f != null) {
        firstTried++;
        if (f) firstCorrect++;
      }
      final p = AnswerProfile.decode(s.profile);
      if (p != null) {
        if (p.applied) {
          appliedTried += s.attempts;
          appliedCorrect += s.correct;
        }
        if (p.novel) {
          novelTried += s.attempts;
          novelCorrect += s.correct;
        }
      }
      gapTried += s.gapTried;
      gapCorrect += s.gapCorrect;
    }
    return GrowthReport(
      firstTry: GrowthMeasure(
        '初見正答率',
        '初めて見た問題に、1回目で正解できた割合',
        firstTried,
        firstCorrect,
      ),
      applied: GrowthMeasure(
        '応用問題',
        '2つ以上の知識を組み合わせる問題（思考レベル4以上）の正答率',
        appliedTried,
        appliedCorrect,
      ),
      novel: GrowthMeasure(
        '初見問題',
        '見慣れない形の問題の正答率',
        novelTried,
        novelCorrect,
      ),
      retention: GrowthMeasure(
        '定着率',
        '3日以上あけてもう一度答えたときに、正解できた割合',
        gapTried,
        gapCorrect,
      ),
    );
  }

  static Iterable<QuestionStat> _stats(
    LearningRecord record,
    String? subject,
  ) =>
      subject == null
          ? record.stats.values
          : record.stats.values
              .where((s) => LearningRecord.subjectOf(s.setId) == subject);
}

/// 学習の段階（基礎 → 東大）の1段
class PhaseStep {
  const PhaseStep({
    required this.phase,
    required this.tried,
    required this.correct,
    required this.questions,
  });

  final LearningPhase phase;

  /// この段階の問題に答えた回数と正解の回数
  final int tried;
  final int correct;

  /// この段階で答えたことのある問題の数
  final int questions;

  int? get percent => tried == 0 ? null : (correct * 100 / tried).round();

  /// 到達：この段階の問題を [clearQuestions] 問以上解き、正答率 [clearPercent]% 以上
  bool get cleared =>
      questions >= clearQuestions && (percent ?? 0) >= clearPercent;

  static const clearQuestions = 10;
  static const clearPercent = 70;
}

/// 学習の段階のはしご（フェーズ1〜7）。いまどの段にいて、次に何をめざすか。
class PhaseLadder {
  const PhaseLadder(this.steps);

  /// 基礎から順に7段
  final List<PhaseStep> steps;

  factory PhaseLadder.of(LearningRecord record, {String? subject}) {
    final tried = List.filled(LearningPhase.values.length, 0);
    final correct = List.filled(LearningPhase.values.length, 0);
    final questions = List.filled(LearningPhase.values.length, 0);
    for (final s in GrowthReport._stats(record, subject)) {
      final p = AnswerProfile.decode(s.profile);
      if (p == null) continue;
      final i = p.phase.number - 1;
      tried[i] += s.attempts;
      correct[i] += s.correct;
      questions[i]++;
    }
    return PhaseLadder([
      for (final p in LearningPhase.values)
        PhaseStep(
          phase: p,
          tried: tried[p.number - 1],
          correct: correct[p.number - 1],
          questions: questions[p.number - 1],
        ),
    ]);
  }

  /// いまの段（下から続けて到達した段の次。全部到達なら最上段）
  PhaseStep get current {
    for (final s in steps) {
      if (!s.cleared) return s;
    }
    return steps.last;
  }

  /// 下から続けて到達した段の数（0〜7）
  int get clearedCount {
    var n = 0;
    for (final s in steps) {
      if (!s.cleared) break;
      n++;
    }
    return n;
  }
}
