import 'dart:math';

import '../curriculum/curriculum.dart';
import '../learning/question_stat.dart';
import '../models/question.dart';
import 'school_exam.dart';

/// 定期テスト対策の「授業」。
///
/// 授業は学習体系の単元（[unitId]）ごとに1つ。教材データはアプリのコードと分けて
/// assets/lessons/<学校の科目>.json に置く（tool/lessons/ の道具で作り、検査する）。
/// 授業の進み具合は [LessonRecord]、演習の結果は既存の学習記録（[QuestionStat]）を使い、
/// 2つを合わせて単元の状態（[LessonState]）を決める。

/// 授業の説明ブロックの種類
enum LessonBlockKind {
  intro('導入'),
  explain('説明'),
  example('例題'),
  point('重要事項'),
  mistake('よくある間違い'),
  advanced('発展'),
  summary('まとめ');

  const LessonBlockKind(this.label);
  final String label;

  static LessonBlockKind parse(Object? v) {
    for (final k in values) {
      if (k.name == v) return k;
    }
    return explain;
  }
}

/// 授業の途中・確認テストで解く問題（選択式）
class LessonCheck {
  const LessonCheck({
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    this.hint = '',
    this.reteach = '',
  });

  final String prompt;
  final List<String> choices;
  final int answerIndex;

  /// 正解・不正解のあとに見せる解説
  final String explanation;

  /// 1回目にまちがえたときのヒント（なければ解説の前に別の説明を出さない）
  final String hint;

  /// 2回まちがえたときの、別の角度からの説明
  final String reteach;

  String get answer => choices[answerIndex];

  bool isCorrect(int index) => index == answerIndex;

  factory LessonCheck.fromJson(Map<String, dynamic> j) => LessonCheck(
        prompt: j['q'] as String,
        choices: [for (final c in j['c'] as List) '$c'],
        answerIndex: (j['a'] as num).toInt(),
        explanation: j['e'] as String? ?? '',
        hint: j['hint'] as String? ?? '',
        reteach: j['re'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'q': prompt,
        'c': choices,
        'a': answerIndex,
        'e': explanation,
        if (hint.isNotEmpty) 'hint': hint,
        if (reteach.isNotEmpty) 're': reteach,
      };

  /// 形のまちがい（なければ空）
  List<String> problems() => [
        if (prompt.trim().isEmpty) '問題文が空',
        if (choices.length < 2) '選択肢が2つ未満',
        if (answerIndex < 0 || answerIndex >= choices.length) '正解の番号が範囲外',
        if (choices.toSet().length != choices.length) '同じ選択肢がある',
        if (choices.any((c) => c.trim().isEmpty)) '空の選択肢がある',
        if (explanation.trim().isEmpty) '解説が空',
      ];
}

/// 授業の1ステップ（説明か、その場で解く問題）
class LessonStep {
  const LessonStep.block(this.kind, this.heading, this.body) : check = null;
  const LessonStep.check(LessonCheck this.check)
      : kind = null,
        heading = '',
        body = '';

  final LessonBlockKind? kind;
  final String heading;
  final String body;
  final LessonCheck? check;

  bool get isCheck => check != null;

  factory LessonStep.fromJson(Map<String, dynamic> j) => j['t'] == 'check'
      ? LessonStep.check(LessonCheck.fromJson(j))
      : LessonStep.block(
          LessonBlockKind.parse(j['t']),
          j['h'] as String? ?? '',
          j['b'] as String? ?? '',
        );
}

/// 単元1つ分の授業
class SchoolLesson {
  const SchoolLesson({
    required this.id,
    required this.subjectId,
    required this.unitId,
    required this.title,
    required this.goals,
    required this.steps,
    required this.quiz,
    this.prerequisites = const [],
    this.keywords = const [],
    this.reteach = '',
    this.source = '',
    this.review = 'unreviewed',
    this.version = 1,
  });

  final String id;

  /// 学校の科目（ShonanSubjects の id）
  final String subjectId;

  /// 学習体系の単元
  final String unitId;
  final String title;

  /// この授業の到達目標
  final List<String> goals;

  /// 前提となる知識（できていないと分かりにくいこと）
  final List<String> prerequisites;

  /// 重要語句・公式
  final List<String> keywords;
  final List<LessonStep> steps;

  /// 授業の最後の確認テスト
  final List<LessonCheck> quiz;

  /// 確認テストで不合格のときに見せる、別の角度からの説明
  final String reteach;

  /// 出典・作り方（例：授業プリントNo.10の用語にそって新しく書いたもの）
  final String source;

  /// 内容の確認状況（unreviewed：作成者の確認のみ。専門家の検証済みとは表示しない）
  final String review;
  final int version;

  List<LessonCheck> get inlineChecks => [
        for (final s in steps)
          if (s.check != null) s.check!,
      ];

  int get blockCount => steps.where((s) => !s.isCheck).length;

  /// 確認テストの合格に必要な正解数（8割、少なくとも1問）
  int get passScore => max(1, (quiz.length * 0.8).ceil());

  factory SchoolLesson.fromJson(Map<String, dynamic> j) => SchoolLesson(
        id: j['id'] as String,
        subjectId: j['subjectId'] as String,
        unitId: j['unitId'] as String,
        title: j['title'] as String,
        goals: [for (final g in j['goals'] as List? ?? const []) '$g'],
        prerequisites: [
          for (final g in j['prerequisites'] as List? ?? const []) '$g'
        ],
        keywords: [for (final g in j['keywords'] as List? ?? const []) '$g'],
        steps: [
          for (final s in j['steps'] as List? ?? const [])
            LessonStep.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
        quiz: [
          for (final s in j['quiz'] as List? ?? const [])
            LessonCheck.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
        reteach: j['reteach'] as String? ?? '',
        source: j['source'] as String? ?? '',
        review: j['review'] as String? ?? 'unreviewed',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  /// 授業として足りないところ（なければ空）。
  /// 説明が3つ未満・途中の問題がない・確認テストが3問未満の授業は「整備済み」と扱わない
  List<String> problems() => [
        if (title.trim().isEmpty) '題名が空',
        if (goals.isEmpty) '到達目標がない',
        if (!Curriculum.contains(unitId)) '単元 $unitId が学習体系にない',
        if (blockCount < 3) '説明が3つ未満',
        if (!steps.any((s) => s.kind == LessonBlockKind.summary)) 'まとめがない',
        if (inlineChecks.isEmpty) '授業の途中で解く問題がない',
        if (quiz.length < 3) '確認テストが3問未満',
        for (final s in steps)
          if (!s.isCheck && s.body.trim().isEmpty) '「${s.heading}」の本文が空',
        for (final (i, c) in [...inlineChecks, ...quiz].indexed)
          for (final p in c.problems()) '問題${i + 1}：$p',
      ];

  bool get isComplete => problems().isEmpty;
}

/// 授業の教材ファイル（科目1つ分）を読む
abstract final class SchoolLessons {
  static List<SchoolLesson> parse(List<dynamic> json) => [
        for (final j in json)
          SchoolLesson.fromJson(Map<String, dynamic>.from(j as Map)),
      ];

  /// 単元 ID → 授業
  static Map<String, SchoolLesson> byUnit(Iterable<SchoolLesson> lessons) =>
      {for (final l in lessons) l.unitId: l};
}

/// 単元の学習状況（授業を開いただけでは「習得」にしない）
enum LessonState {
  notStarted('未着手'),
  studying('学習中'),
  viewed('授業閲覧済み'),
  checked('理解度確認済み'),
  practicing('演習中'),
  needsReview('要復習'),
  mastered('習得'),
  recheck('再確認が必要');

  const LessonState(this.label);
  final String label;

  /// 授業と確認テストまで終えたか（学習完了率に数える）
  bool get learned =>
      this == checked ||
      this == practicing ||
      this == mastered ||
      this == recheck;
}

/// 授業1つ分の進み具合（端末に保存する）
class LessonRecord {
  const LessonRecord({
    required this.lessonId,
    this.step = 0,
    this.viewed = false,
    this.quizAttempts = 0,
    this.quizBest = 0,
    this.quizLast = -1,
    this.quizPassedDay = 0,
    this.masteredDay = 0,
    this.understanding = 0,
    this.updatedDay = 0,
  });

  final String lessonId;

  /// 次に開くステップ（続きから再開する）
  final int step;

  /// 最後のステップまで読んだ
  final bool viewed;
  final int quizAttempts;
  final int quizBest;

  /// 直前の確認テストの正解数（まだなら -1）
  final int quizLast;

  /// 確認テストに合格した日（[dayNumber]。0：まだ）
  final int quizPassedDay;

  /// 初めて習得と判定した日（0：まだ）。このあとまちがえたら「再確認が必要」
  final int masteredDay;

  /// 自己評価（0：未回答、1：わからない、2：少し不安、3：よくわかった）
  final int understanding;
  final int updatedDay;

  LessonRecord copyWith({
    int? step,
    bool? viewed,
    int? quizAttempts,
    int? quizBest,
    int? quizLast,
    int? quizPassedDay,
    int? masteredDay,
    int? understanding,
    int? updatedDay,
  }) =>
      LessonRecord(
        lessonId: lessonId,
        step: step ?? this.step,
        viewed: viewed ?? this.viewed,
        quizAttempts: quizAttempts ?? this.quizAttempts,
        quizBest: quizBest ?? this.quizBest,
        quizLast: quizLast ?? this.quizLast,
        quizPassedDay: quizPassedDay ?? this.quizPassedDay,
        masteredDay: masteredDay ?? this.masteredDay,
        understanding: understanding ?? this.understanding,
        updatedDay: updatedDay ?? this.updatedDay,
      );

  /// 授業のステップを進めた
  LessonRecord advance(int step, int total, {required int day}) => copyWith(
        step: min(step, total),
        viewed: viewed || step >= total,
        updatedDay: day,
      );

  /// 確認テストの結果を記録する
  LessonRecord withQuiz(int score, int passScore, {required int day}) =>
      copyWith(
        quizAttempts: quizAttempts + 1,
        quizBest: max(quizBest, score),
        quizLast: score,
        quizPassedDay:
            score >= passScore && quizPassedDay == 0 ? day : quizPassedDay,
        viewed: true,
        updatedDay: day,
      );

  bool get quizPassed => quizPassedDay > 0;

  /// 直前の確認テストが不合格
  bool failedLast(int passScore) => quizLast >= 0 && quizLast < passScore;

  Map<String, dynamic> toJson() => {
        'id': lessonId,
        if (step > 0) 's': step,
        if (viewed) 'v': 1,
        if (quizAttempts > 0) 'qa': quizAttempts,
        if (quizBest > 0) 'qb': quizBest,
        if (quizLast >= 0) 'ql': quizLast,
        if (quizPassedDay > 0) 'qp': quizPassedDay,
        if (masteredDay > 0) 'm': masteredDay,
        if (understanding > 0) 'u': understanding,
        if (updatedDay > 0) 'd': updatedDay,
      };

  factory LessonRecord.fromJson(Map<String, dynamic> j) {
    int n(String k, [int d = 0]) => (j[k] as num?)?.toInt() ?? d;
    return LessonRecord(
      lessonId: '${j['id']}',
      step: n('s'),
      viewed: n('v') == 1,
      quizAttempts: n('qa'),
      quizBest: n('qb'),
      quizLast: n('ql', -1),
      quizPassedDay: n('qp'),
      masteredDay: n('m'),
      understanding: n('u'),
      updatedDay: n('d'),
    );
  }
}

/// 単元の演習結果のまとめ（既存の学習記録から作る）
class UnitPractice {
  const UnitPractice({
    required this.total,
    required this.answered,
    required this.lastCorrect,
    required this.lastWrongIds,
    required this.laterDay,
  });

  /// 単元の問題数
  final int total;

  /// 1回以上答えた問題数
  final int answered;

  /// 最後に答えたとき正解だった問題数
  final int lastCorrect;

  /// 最後に答えたときまちがえた問題
  final List<String> lastWrongIds;

  /// 一番最近に答えた日（0：まだ）
  final int laterDay;

  double get lastAccuracy => answered == 0 ? 0 : lastCorrect / answered;

  /// 習得の判定に必要な演習の問題数（少ない単元は全部）
  int get needed => min(8, total);

  static UnitPractice of(
    Iterable<QuizQuestion> questions,
    Map<String, QuestionStat> stats,
  ) {
    var total = 0, answered = 0, ok = 0, last = 0;
    final wrong = <String>[];
    for (final q in questions) {
      total++;
      final s = stats[q.id];
      if (s == null || s.attempts == 0) continue;
      answered++;
      if (s.streak > 0) {
        ok++;
      } else {
        wrong.add(q.id);
      }
      last = max(last, s.lastDay);
    }
    return UnitPractice(
      total: total,
      answered: answered,
      lastCorrect: ok,
      lastWrongIds: wrong,
      laterDay: last,
    );
  }
}

/// 単元の状態を決める（純粋な関数。テストしやすいように時刻は日数で受け取る）
abstract final class LessonMastery {
  /// 要復習とする、最後の正解率の下限
  static const weakAccuracy = 0.6;

  /// 習得とする、最後の正解率
  static const masterAccuracy = 0.8;

  static LessonState evaluate({
    required SchoolLesson? lesson,
    required LessonRecord? record,
    required UnitPractice practice,
  }) {
    final r = record;
    final pass = lesson?.passScore ?? 1;
    if (r != null && lesson != null && r.failedLast(pass)) {
      return LessonState.needsReview;
    }
    if (practice.answered >= 4 && practice.lastAccuracy < weakAccuracy) {
      return LessonState.needsReview;
    }
    final quizOk = lesson == null || (r?.quizPassed ?? false);
    // 習得：確認テストに合格し、演習を十分に解き、最後の正解率が8割以上で、
    // 合格した日とは別の日にも演習している（時間をあけた確認）
    final enough = practice.total > 0 &&
        practice.answered >= practice.needed &&
        practice.lastAccuracy >= masterAccuracy;
    final spaced = lesson == null
        ? practice.laterDay > 0
        : (r?.quizPassedDay ?? 0) > 0 && practice.laterDay > r!.quizPassedDay;
    if (quizOk && enough && spaced) return LessonState.mastered;
    if ((r?.masteredDay ?? 0) > 0) return LessonState.recheck;
    if (practice.answered > 0 && (quizOk || r == null)) {
      return LessonState.practicing;
    }
    if (r == null) return LessonState.notStarted;
    if (r.quizPassed) return LessonState.checked;
    if (r.viewed) return LessonState.viewed;
    if (r.step > 0 || r.quizAttempts > 0) return LessonState.studying;
    return LessonState.notStarted;
  }
}

/// 範囲の単元1つ分の状況
class UnitCoverage {
  const UnitCoverage({
    required this.group,
    required this.lesson,
    required this.state,
    required this.practice,
  });

  final SchoolUnitGroup group;

  /// 授業（なければ null）
  final SchoolLesson? lesson;
  final LessonState state;
  final UnitPractice practice;

  String get unitId => group.id;
  String get name => group.name;

  /// 学習体系の単元に対応づいている（「その他」ではない）
  bool get mapped => group.id.isNotEmpty;

  /// 授業が整備済み（説明・途中の問題・確認テストがそろっている）
  bool get hasLesson => lesson != null && lesson!.isComplete;

  /// 演習に足りる問題がある（5問以上、すべて解説つき）
  bool get practiceReady =>
      group.questions.length >= 5 &&
      group.questions.every((q) => (q.explanation ?? '').trim().isNotEmpty);

  /// 範囲の単元として必要なものがそろっている
  bool get ready => mapped && hasLesson && practiceReady;
}

/// 科目の試験範囲全体の網羅状況（教材の整備と、学習者の習得を分けて数える）
class SubjectCoverage {
  const SubjectCoverage(this.units);

  final List<UnitCoverage> units;

  int get total => units.length;
  int _count(bool Function(UnitCoverage u) f) => units.where(f).length;

  /// 学習体系の単元に対応づいた割合（範囲登録率）
  int get mapped => _count((u) => u.mapped);

  /// 授業が整備された単元（授業コンテンツ整備率）
  int get withLesson => _count((u) => u.hasLesson);

  /// 演習問題がそろった単元（演習対応率）
  int get withPractice => _count((u) => u.practiceReady);

  /// 授業と確認テストを終えた単元（学習完了率）
  int get learned => _count((u) => u.state.learned);

  /// 習得を確認できた単元（習得確認率）
  int get mastered => _count((u) => u.state == LessonState.mastered);
  int get needsReview => _count((u) =>
      u.state == LessonState.needsReview || u.state == LessonState.recheck);
  int get notStarted => _count((u) => u.state == LessonState.notStarted);

  /// 教材がまだそろっていない単元
  List<UnitCoverage> get missing => [
        for (final u in units)
          if (!u.ready) u,
      ];

  /// 範囲を完全に攻略した（教材がすべてそろい、すべて習得した）ときだけ true
  bool get complete => total > 0 && missing.isEmpty && mastered == total;

  static double rate(int n, int total) => total == 0 ? 0 : n / total;

  static SubjectCoverage build({
    required List<QuizQuestion> questions,
    required Map<String, SchoolLesson> lessons,
    required Map<String, LessonRecord> records,
    required Map<String, QuestionStat> stats,
  }) {
    final groups = SchoolUnitGroup.of(questions);
    return SubjectCoverage([
      for (final g in groups)
        () {
          final lesson = lessons[g.id];
          final practice = UnitPractice.of(g.questions, stats);
          return UnitCoverage(
            group: g,
            lesson: lesson,
            practice: practice,
            state: LessonMastery.evaluate(
              lesson: lesson,
              record: lesson == null ? null : records[lesson.id],
              practice: practice,
            ),
          );
        }(),
    ]);
  }
}

/// 学習計画の1項目
class PlanItem {
  const PlanItem(this.unit, this.score, this.reason);
  final UnitCoverage unit;
  final double score;
  final String reason;
}

/// 試験日までの残り時間と学習状況から、次に学ぶ単元の順番を決める。
///
/// 実際の出題傾向は分からないので「頻出」とは言わず、未学習・要復習・正解率と、
/// 学習体系の順番（前提知識が先）だけで決める。
abstract final class LessonPlanner {
  static List<PlanItem> plan(
    SubjectCoverage coverage, {
    int? daysLeft,
  }) {
    final items = <PlanItem>[];
    for (final (i, u) in coverage.units.indexed) {
      if (u.state == LessonState.mastered) continue;
      // 学習体系の前の単元ほど少し優先（前提知識になりやすい）
      final order = 1 - i / max(1, coverage.total) * 0.3;
      final (base, reason) = switch (u.state) {
        LessonState.needsReview => (5.0, '確認テストや演習の正解率が低い（要復習）'),
        LessonState.recheck => (4.5, '習得したあとにまちがえた（再確認）'),
        LessonState.studying => (4.0, '授業の途中'),
        LessonState.notStarted => (3.5, 'まだ学習していない'),
        LessonState.viewed => (3.2, '授業は見たが、確認テストがまだ'),
        LessonState.checked => (2.5, '確認テストに合格。演習で定着させる'),
        LessonState.practicing => (2.0, '演習中。正解率を上げて習得へ'),
        LessonState.mastered => (0.0, ''),
      };
      var score = base * order;
      // 試験直前は、まだ授業を受けていない単元と要復習を強く優先する
      if (daysLeft != null && daysLeft <= 3 && !u.state.learned) score += 2;
      if (u.practice.answered > 0) score += (1 - u.practice.lastAccuracy);
      items.add(PlanItem(u, score, reason));
    }
    items.sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  /// 1日に進める単元の目安（残りの単元を残り日数で割る。最低1）
  static int perDay(SubjectCoverage coverage, int daysLeft) {
    final left = coverage.total - coverage.mastered;
    if (left <= 0) return 0;
    return max(1, (left / max(1, daysLeft)).ceil());
  }

  /// 試験日までの日数（当日は0、過ぎたら負）
  static int daysUntil(DateTime exam, DateTime now) =>
      DateTime.utc(exam.year, exam.month, exam.day)
          .difference(DateTime.utc(now.year, now.month, now.day))
          .inDays;
}

/// 演習の出し方（同じ問題データ・学習記録を共有する）
enum LessonPracticeMode {
  weak('苦手克服', '要復習・再確認の単元の問題'),
  mistakes('間違い直し', '最後にまちがえた問題'),
  all('全範囲の総復習', '範囲のすべての問題（30問）'),
  finalCheck('試験直前チェック', 'まちがえた問題と、習得していない単元を中心に20問');

  const LessonPracticeMode(this.label, this.description);
  final String label;
  final String description;

  /// このモードで出す問題の ID（出せる問題がなければ空）
  Set<String> pick(SubjectCoverage c, {Random? random}) {
    final rnd = random ?? Random();
    List<String> ids(Iterable<UnitCoverage> us) => [
          for (final u in us)
            for (final q in u.group.questions) q.id,
        ];
    List<String> take(List<String> xs, int n) =>
        (List.of(xs)..shuffle(rnd)).take(n).toList();
    final wrong = [for (final u in c.units) ...u.practice.lastWrongIds];
    switch (this) {
      case weak:
        return ids(c.units.where((u) =>
            u.state == LessonState.needsReview ||
            u.state == LessonState.recheck)).toSet();
      case mistakes:
        return wrong.toSet();
      case all:
        return take(ids(c.units), 30).toSet();
      case finalCheck:
        final rest = take(
          ids(c.units.where((u) => u.state != LessonState.mastered)),
          20,
        );
        return {...take(wrong, 10), ...rest}.take(20).toSet();
    }
  }
}
