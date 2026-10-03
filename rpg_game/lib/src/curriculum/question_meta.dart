import 'dart:math';

import '../models/difficulty.dart';
import '../models/question.dart';
import 'curriculum.dart';

/// 思考レベル（1〜8）。数字だけでなく「求められる考え方の質」が変わる。
///
/// 1・2 は覚えたことを思い出す・説明する、3 は型どおりに使う、
/// 4 以上は複数の知識を組み合わせる・初めて見る形に対応する。
enum ThinkingLevel {
  knowledge(1, '知識確認', '覚えた知識をそのまま思い出す'),
  comprehension(2, '基本理解', '意味や理由を理解して説明できる'),
  application(3, '標準適用', '学んだ方法を標準的な問題に使う'),
  analysis(4, '複合問題', '2つ以上の知識・条件を組み合わせて整理する'),
  synthesis(5, '発展問題', '見慣れない形でも、方針を自分で組み立てる'),
  evaluation(6, '難関大学', '長い条件・資料から必要な情報を選び、筋道を立てる'),
  problemSolving(7, '最難関大学', '複数分野を横断し、誘導が少なくても解決する'),
  todai(8, '東大レベル', '初見の問題を、知識から方針を立てて論理的に説明しきる');

  const ThinkingLevel(this.number, this.label, this.description);
  final int number;
  final String label;
  final String description;

  static ThinkingLevel of(int number) =>
      values[number.clamp(1, values.length) - 1];

  static ThinkingLevel? tryParse(Object? v) {
    if (v is num) return of(v.toInt());
    if (v is String) {
      for (final t in values) {
        if (t.name == v) return t;
      }
      final n = int.tryParse(v);
      if (n != null) return of(n);
    }
    return null;
  }
}

/// 難しさの種類（それぞれ 0〜5）。難易度を1本の数字にしないための軸。
class DifficultyAxes {
  const DifficultyAxes({
    this.knowledge = 0,
    this.calculation = 0,
    this.reading = 0,
    this.thinking = 0,
    this.novelty = 0,
    this.writing = 0,
    this.time = 0,
  });

  /// 知識難度（覚えている量・細かさ）
  final int knowledge;

  /// 計算難度（計算の量・重さ）
  final int calculation;

  /// 読解難度（読む量・文章の難しさ）
  final int reading;

  /// 思考難度（筋道を立てる難しさ）
  final int thinking;

  /// 初見難度（見たことのない形か）
  final int novelty;

  /// 記述難度（書いて説明する量）
  final int writing;

  /// 時間負荷（制限時間に対する重さ）
  final int time;

  static const labels = {
    'knowledge': '知識',
    'calculation': '計算',
    'reading': '読解',
    'thinking': '思考',
    'novelty': '初見',
    'writing': '記述',
    'time': '時間',
  };

  Map<String, int> toMap() => {
        'knowledge': knowledge,
        'calculation': calculation,
        'reading': reading,
        'thinking': thinking,
        'novelty': novelty,
        'writing': writing,
        'time': time,
      };

  /// いちばん重い軸（同じなら知識→計算→…の順）
  String get dominant {
    final m = toMap();
    return m.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  factory DifficultyAxes.fromJson(Map<String, dynamic> json) {
    int v(String k) => ((json[k] as num?)?.toInt() ?? 0).clamp(0, 5);
    return DifficultyAxes(
      knowledge: v('knowledge'),
      calculation: v('calculation'),
      reading: v('reading'),
      thinking: v('thinking'),
      novelty: v('novelty'),
      writing: v('writing'),
      time: v('time'),
    );
  }

  Map<String, dynamic> toJson() => {
        for (final e in toMap().entries)
          if (e.value > 0) e.key: e.value
      };
}

/// 問題の出典の種類。
enum QuestionSourceKind {
  /// オリジナル問題（このアプリのために作った問題）
  original('オリジナル'),

  /// 本番の形式にそろえたオリジナル問題
  officialStyle('本番形式'),

  /// 既存の問題を作り変えた問題（出典の利用条件を確認したものだけ）
  adapted('改題'),

  /// 反復練習用の問題
  practice('練習'),

  /// 実際の過去問（利用条件を確認できたものだけ。今は同梱していない）
  officialPastExam('過去問');

  const QuestionSourceKind(this.label);
  final String label;

  static QuestionSourceKind parse(String? v) {
    for (final k in values) {
      if (k.name == v) return k;
    }
    return original;
  }
}

/// 学習の段階（高1の基礎から東大レベルまでの7段階）。
enum LearningPhase {
  basics(1, '基礎', '高校内容の基礎'),
  teikiTest(2, '定期テスト', '学校の定期テストに対応'),
  commonTest(3, '共通テスト', '大学入学共通テストレベル'),
  standardUniv(4, '標準大学', '標準的な大学入試'),
  difficultUniv(5, '難関大学', '難関大学の入試'),
  topUniv(6, '最難関大学', '最難関大学の入試'),
  todai(7, '東大', '東京大学レベル');

  const LearningPhase(this.number, this.label, this.description);
  final int number;
  final String label;
  final String description;

  static LearningPhase? tryParse(String? v) {
    for (final p in values) {
      if (p.name == v) return p;
    }
    return null;
  }
}

/// 1問の学習上の属性（データに書かれた値と、書かれていない値の推定をまとめたもの）。
class QuestionProfile {
  const QuestionProfile({
    required this.unitId,
    required this.thinking,
    required this.axes,
    required this.phase,
    required this.estimatedSeconds,
    required this.sourceKind,
    required this.grade,
    required this.estimated,
  });

  /// 学習体系の単元・小単元（不明なら null）
  final String? unitId;
  final ThinkingLevel thinking;
  final DifficultyAxes axes;
  final LearningPhase phase;
  final int estimatedSeconds;
  final QuestionSourceKind sourceKind;

  /// 主に学ぶ学年（'1'・'2-3' など。不明なら空）
  final String grade;

  /// 思考レベル・難しさの軸が、データに書かれていないので推定した値か
  final bool estimated;

  /// 学習体系の節（データにない ID なら null）
  CurriculumNode? get node =>
      unitId == null ? null : Curriculum.tryNode(unitId!);
}

/// 問題の属性を決める。データに書かれていればそれを使い、
/// なければ問題の種類・難易度・文章量から控えめに推定する
/// （推定では思考レベル6以上にはしない。難関・東大レベルは問題を作る人が決める）。
class QuestionProfiler {
  const QuestionProfiler._();

  static const _baseThinking = {
    QuestionCategory.partOfSpeech: 1,
    QuestionCategory.meaning: 1,
    QuestionCategory.knowledge: 1,
    QuestionCategory.usage: 2,
    QuestionCategory.calculation: 2,
    QuestionCategory.reading: 3,
    QuestionCategory.thinking: 3,
  };

  static int _difficultyStep(Difficulty? d) => switch (d) {
        Difficulty.basic => 0,
        Difficulty.standard => 1,
        Difficulty.advanced => 2,
        Difficulty.challenge => 3,
        null => 1,
      };

  /// [fallbackDifficulty] は問題に難易度が書かれていないときに使う難易度
  /// （ステージ名の「（応用）」など）。[sea] は定期テストの海の問題か。
  static QuestionProfile of(
    QuizQuestion q, {
    Difficulty? fallbackDifficulty,
    bool sea = false,
  }) {
    final difficulty = q.difficulty ?? fallbackDifficulty;
    final step = _difficultyStep(difficulty);
    final estimated = q.thinkingLevel == null || q.axes == null;

    final thinking = q.thinkingLevel ??
        ThinkingLevel.of(min(6, (_baseThinking[q.category] ?? 1) + step));

    final textLength = q.prompt.length +
        (q.sentence?.length ?? 0) +
        (q.passage?.paragraphs.fold<int>(0, (a, p) => a + p.length) ?? 0);
    final axes = q.axes ??
        DifficultyAxes(
          knowledge: switch (q.category) {
            QuestionCategory.knowledge ||
            QuestionCategory.meaning ||
            QuestionCategory.partOfSpeech =>
              min(5, 2 + step),
            _ => min(5, 1 + step ~/ 2),
          },
          calculation:
              q.category == QuestionCategory.calculation ? min(5, 2 + step) : 0,
          reading: q.passage != null
              ? min(5, 3 + step ~/ 2)
              : textLength > 120
                  ? 2
                  : textLength > 50
                      ? 1
                      : 0,
          thinking: min(5, max(0, thinking.number - 1)),
          novelty: thinking.number >= 5 ? 2 : (thinking.number >= 4 ? 1 : 0),
          writing: q.isInput ? 1 : 0,
          time: 0,
        );

    final seconds = q.estimatedSeconds ??
        switch (q.category) {
          QuestionCategory.reading => 60 + textLength ~/ 10,
          QuestionCategory.calculation => 45 + 15 * step,
          QuestionCategory.thinking => 45 + 15 * step,
          _ => 15 + 5 * step,
        };

    final phase = q.phase ??
        (sea
            ? LearningPhase.teikiTest
            : switch (difficulty) {
                Difficulty.basic => LearningPhase.basics,
                Difficulty.standard || null => LearningPhase.teikiTest,
                Difficulty.advanced => LearningPhase.commonTest,
                Difficulty.challenge => LearningPhase.standardUniv,
              });

    final unit = q.unit;
    final grade = q.targetGrade ??
        (unit != null && Curriculum.contains(unit)
            ? Curriculum.gradeOf(unit)
            : '');

    return QuestionProfile(
      unitId: unit,
      thinking: thinking,
      axes: axes,
      phase: phase,
      estimatedSeconds: seconds,
      sourceKind: q.sourceKind,
      grade: grade,
      estimated: estimated,
    );
  }
}

/// 学習記録に残す、問題の性質（思考レベル・初見度・学習の段階）。
///
/// 成長の見える化（応用問題・初見問題の正答率、段階ごとの到達）に使う。
/// 保存するときは [code] の1つの数にまとめる。
class AnswerProfile {
  const AnswerProfile({
    required this.thinking,
    required this.novel,
    required this.phase,
  });

  /// 思考レベル（1〜8）
  final int thinking;

  /// 初見の度合いが高い問題（難しさの軸「初見」が2以上）
  final bool novel;
  final LearningPhase phase;

  /// 応用問題（複合問題＝思考レベル4以上）
  bool get applied => thinking >= 4;

  /// 1つの数にまとめた形（下位4ビット：思考レベル、16：初見、32の倍数：段階）
  int get code => thinking.clamp(1, 8) | (novel ? 16 : 0) | (phase.number << 5);

  /// [code] から戻す（0 や壊れた値は null）
  static AnswerProfile? decode(int code) {
    final t = code & 15;
    final p = code >> 5;
    if (t < 1 || t > 8 || p < 1 || p > LearningPhase.values.length) return null;
    return AnswerProfile(
      thinking: t,
      novel: code & 16 != 0,
      phase: LearningPhase.values[p - 1],
    );
  }

  factory AnswerProfile.of(
    QuizQuestion q, {
    Difficulty? fallbackDifficulty,
    bool sea = false,
  }) {
    final p = QuestionProfiler.of(
      q,
      fallbackDifficulty: fallbackDifficulty,
      sea: sea,
    );
    return AnswerProfile(
      thinking: p.thinking.number,
      novel: p.axes.novelty >= 2,
      phase: p.phase,
    );
  }
}
