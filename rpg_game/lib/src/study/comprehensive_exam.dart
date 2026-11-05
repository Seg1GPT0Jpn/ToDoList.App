import 'dart:math';

import '../curriculum/curriculum.dart';
import '../curriculum/curriculum_progress.dart';
import '../curriculum/question_meta.dart';
import '../data/catalog.dart';
import '../data/extra_sets.dart';
import '../learning/composite_weakness.dart';
import '../models/question.dart';
import '../models/question_format.dart';

/// 総合演習の部（大問）
enum ExamSection {
  basic('第1部 基礎', '知識・基本理解（思考レベル1〜2）', 3),
  standard('第2部 標準', '標準適用・複合問題（思考レベル3〜4）', 5),
  advanced('第3部 応用・発展', '発展・難関（思考レベル5以上）', 12);

  const ExamSection(this.title, this.description, this.points);
  final String title;
  final String description;

  /// 1問の配点
  final int points;

  static ExamSection of(int thinking) => thinking <= 2
      ? basic
      : thinking <= 4
          ? standard
          : advanced;
}

/// 総合演習の1問
class ExamItem {
  const ExamItem({
    required this.question,
    required this.setId,
    required this.section,
    required this.thinking,
    required this.seconds,
  });

  final QuizQuestion question;
  final String setId;
  final ExamSection section;

  /// 思考レベル（1〜8）
  final int thinking;

  /// 目安の時間（秒）
  final int seconds;

  int get points => section.points;
}

/// 総合演習（教科ごとの模擬試験）。
///
/// 3部構成（基礎・標準・応用）で、配点・制限時間つき。4択以外の形式もまじり、
/// 記述や複数選択は部分点がつく。終わったら、分野ごと・思考の種類ごとの得点と、
/// 複合弱点を出す。
class ExamPaper {
  const ExamPaper({
    required this.subject,
    required this.items,
    required this.timeLimitSeconds,
  });

  final String subject;
  final List<ExamItem> items;
  final int timeLimitSeconds;

  /// 部ごとの問題数
  static const counts = {
    ExamSection.basic: 6,
    ExamSection.standard: 6,
    ExamSection.advanced: 2,
  };

  int get totalPoints => items.fold(0, (a, i) => a + i.points);

  List<ExamItem> itemsOf(ExamSection s) =>
      items.where((i) => i.section == s).toList();

  /// 出題に使う問題セットの候補（その教科のステージから [maxStageSets] 個と、
  /// 追加問題のセットすべて）。日ごとに [seed] で入れかわる
  static List<String> candidateSets(
    String subject, {
    required int seed,
    int maxStageSets = 12,
  }) {
    final stage = <String>{
      for (final s in RpgCatalog.world(subject).stages) ...s.questionSetIds,
    }.toList()
      ..sort()
      ..shuffle(Random(seed));
    final extra = [
      for (final e in ExtraSets.all)
        if (e.subject == subject) e.id,
    ];
    return {...stage.take(maxStageSets), ...extra}.toList();
  }

  /// 問題から試験を組む。[sets] は問題セット ID → 問題
  static ExamPaper build({
    required String subject,
    required Map<String, List<QuizQuestion>> sets,
    required int seed,
  }) {
    final pools = {for (final s in ExamSection.values) s: <ExamItem>[]};
    for (final e in sets.entries) {
      for (final q in e.value) {
        if (!_usable(q)) continue;
        final p = QuestionProfiler.of(q);
        final t = p.thinking.number;
        pools[ExamSection.of(t)]!.add(
          ExamItem(
            question: q,
            setId: e.key,
            section: ExamSection.of(t),
            thinking: t,
            seconds: p.estimatedSeconds.clamp(20, 900),
          ),
        );
      }
    }
    final r = Random(seed);
    final items = <ExamItem>[];
    for (final s in ExamSection.values) {
      final pool = pools[s]!
        ..sort((a, b) => a.question.id.compareTo(b.question.id))
        ..shuffle(r);
      items.addAll(_spread(pool, counts[s]!));
    }
    final seconds = items.fold<int>(0, (a, i) => a + i.seconds);
    return ExamPaper(
      subject: subject,
      items: items,
      // 目安の時間の合計を、1分単位に切り上げ
      timeLimitSeconds: max(300, (seconds / 60).ceil() * 60),
    );
  }

  /// 分野がかたよらないように、分野ごとに順番に取る
  static List<ExamItem> _spread(List<ExamItem> pool, int n) {
    final byField = <String, List<ExamItem>>{};
    for (final i in pool) {
      byField.putIfAbsent(_fieldOf(i.question.unit), () => []).add(i);
    }
    final lanes = byField.values.toList();
    final out = <ExamItem>[];
    var k = 0;
    while (out.length < n && lanes.any((l) => l.isNotEmpty)) {
      final lane = lanes[k % lanes.length];
      if (lane.isNotEmpty) out.add(lane.removeAt(0));
      k++;
    }
    return out;
  }

  /// 試験の画面で出せる問題か（音声・図・長文の問題は、それぞれの専用の画面で）
  static bool _usable(QuizQuestion q) =>
      !q.listen && q.figure == null && q.passage == null;

  static String _fieldOf(String? unit) {
    if (unit == null || !Curriculum.contains(unit)) return '';
    return Curriculum.ancestorAt(unit, CurriculumLevel.field)?.id ?? unit;
  }
}

/// 4択・入力式の採点（それ以外の形式は [Grader]）
abstract final class ExamGrader {
  static Grade choice(QuizQuestion q, int chosen) =>
      chosen == q.answerIndex ? Grade.right : Grade.wrong;

  static Grade input(QuizQuestion q, String text) =>
      q.matchesInput(text) ? Grade.right : Grade.wrong;
}

/// 得点の集計（何点中何点）
class ExamTally {
  ExamTally(this.label);

  final String label;
  double earned = 0;
  int possible = 0;
  int count = 0;

  int get percent => possible == 0 ? 0 : (earned * 100 / possible).round();
}

/// 総合演習の結果と分析
class ExamResult {
  ExamResult({
    required this.paper,
    required this.grades,
    required this.elapsedSeconds,
  });

  final ExamPaper paper;

  /// 問題の番号 → 採点（答えなかった問題は入らない）
  final Map<int, Grade> grades;
  final int elapsedSeconds;

  double creditOf(int i) => grades[i]?.credit ?? 0;

  double get earned {
    var s = 0.0;
    for (var i = 0; i < paper.items.length; i++) {
      s += paper.items[i].points * creditOf(i);
    }
    return s;
  }

  /// 100点満点の点数
  int get score =>
      paper.totalPoints == 0 ? 0 : (earned * 100 / paper.totalPoints).round();

  int get unanswered => paper.items.length - grades.length;

  List<ExamTally> get bySection => _tally((i) => i.section.title);

  /// 分野ごと（科目 ＞ 分野）
  List<ExamTally> get byField => _tally((i) {
        final u = i.question.unit;
        if (u == null || !Curriculum.contains(u)) return 'その他';
        final f = Curriculum.ancestorAt(u, CurriculumLevel.field);
        return f == null
            ? Curriculum.node(u).displayName
            : Curriculum.breadcrumb(f.id);
      });

  /// 思考の種類ごと
  List<ExamTally> get byThinking =>
      _tally((i) => ThinkingLevel.of(i.thinking).label);

  /// 形式ごと（4択・記述など）
  List<ExamTally> get byFormat => _tally((i) => i.question.format.label);

  List<ExamTally> _tally(String Function(ExamItem) keyOf) {
    final out = <String, ExamTally>{};
    for (var n = 0; n < paper.items.length; n++) {
      final it = paper.items[n];
      final t = out.putIfAbsent(keyOf(it), () => ExamTally(keyOf(it)));
      t.earned += it.points * creditOf(n);
      t.possible += it.points;
      t.count++;
    }
    return out.values.toList();
  }

  /// いちばん得点率の低い分野（2問以上ある分野から。なければ null）
  ExamTally? get weakestField {
    final list = byField.where((t) => t.count >= 2).toList()
      ..sort((a, b) => a.percent.compareTo(b.percent));
    return list.isEmpty || list.first.percent >= 80 ? null : list.first;
  }

  /// この試験で見つかった複合弱点
  List<CompositeWeakness> composites(CurriculumProgress progress) =>
      CompositeWeakness.find(
        [for (final i in paper.items) i.question],
        {
          for (var n = 0; n < paper.items.length; n++)
            paper.items[n].question.id: creditOf(n),
        },
        progress,
      );
}
