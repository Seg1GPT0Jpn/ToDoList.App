import 'dart:math';

import 'question.dart';

/// 問題の出題形式。
///
/// [choice]（4択）と入力式（choice の問題に accepted を書いたもの）は、
/// これまでの問題の形。そのほかは、問題ごとの中身（[QuizQuestion] の各 spec）で答え方が決まる。
enum QuestionFormat {
  choice('4択'),
  trueFalse('正誤'),
  multiSelect('複数選択'),
  order('並べ替え'),
  numeric('数値入力'),
  cloze('穴埋め'),
  multiStep('段階問題'),
  written('記述');

  const QuestionFormat(this.label);
  final String label;

  static QuestionFormat parse(String? v) {
    if (v == null) return choice;
    for (final f in values) {
      if (f.name == v) return f;
    }
    throw FormatException('不明な出題形式です: "$v"');
  }
}

/// 複数選択：選択肢から、正しいものをすべて選ぶ
class MultiSelectSpec {
  MultiSelectSpec({required this.options, required this.correct}) {
    if (options.length < 3 || options.length > 8) {
      throw ArgumentError('複数選択の選択肢は3〜8個');
    }
    if (options.toSet().length != options.length) {
      throw ArgumentError('複数選択の選択肢が重複しています');
    }
    if (correct.isEmpty || correct.any((i) => i < 0 || i >= options.length)) {
      throw ArgumentError('複数選択の正解が範囲外です');
    }
  }

  final List<String> options;
  final Set<int> correct;

  factory MultiSelectSpec.fromJson(Map<String, dynamic> j) => MultiSelectSpec(
        options: List<String>.from(j['options'] as List),
        correct: {for (final i in j['correct'] as List) (i as num).toInt()},
      );

  Map<String, dynamic> toJson() =>
      {'options': options, 'correct': correct.toList()..sort()};
}

/// 並べ替え：[items] を正しい順（書かれた順）に並べる
class OrderSpec {
  OrderSpec({required this.items, this.joiner = ' '}) {
    if (items.length < 3 || items.length > 10) {
      throw ArgumentError('並べ替えの項目は3〜10個');
    }
    if (items.toSet().length != items.length) {
      throw ArgumentError('並べ替えの項目が重複しています');
    }
  }

  final List<String> items;

  /// 答えを1行で見せるときのつなぎ（英文なら空白、年代順なら「→」）
  final String joiner;

  factory OrderSpec.fromJson(Map<String, dynamic> j) => OrderSpec(
        items: List<String>.from(j['items'] as List),
        joiner: j['joiner'] as String? ?? ' ',
      );

  Map<String, dynamic> toJson() =>
      {'items': items, if (joiner != ' ') 'joiner': joiner};
}

/// 数値入力：数で答える（分数・小数・指数表記・全角も受け付ける）
class NumericSpec {
  NumericSpec({required this.value, this.tolerance = 0, this.unit = ''}) {
    if (tolerance < 0) throw ArgumentError('許容誤差は0以上');
  }

  final double value;

  /// 許容する誤差（絶対値）
  final double tolerance;

  /// 単位（表示用。答えに書いてもよい）
  final String unit;

  factory NumericSpec.fromJson(Map<String, dynamic> j) => NumericSpec(
        value: (j['value'] as num).toDouble(),
        tolerance: (j['tolerance'] as num?)?.toDouble() ?? 0,
        unit: j['unit'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        if (tolerance > 0) 'tolerance': tolerance,
        if (unit.isNotEmpty) 'unit': unit,
      };

  String get display {
    final v = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return unit.isEmpty ? v : '$v $unit';
  }
}

/// 穴埋め：本文の [1] [2] … の空らんに入る語を書く
class ClozeSpec {
  ClozeSpec({required this.text, required this.blanks}) {
    for (var i = 1; i <= blanks.length; i++) {
      if (!text.contains('[$i]')) throw ArgumentError('本文に [$i] がありません');
    }
    if (blanks.isEmpty || blanks.any((b) => b.isEmpty)) {
      throw ArgumentError('穴埋めの答えがありません');
    }
  }

  /// 本文（空らんは [1] [2] … と書く）
  final String text;

  /// 空らんごとの、正解として受け付ける答え（先頭が模範の答え）
  final List<List<String>> blanks;

  factory ClozeSpec.fromJson(Map<String, dynamic> j) => ClozeSpec(
        text: j['text'] as String,
        blanks: [
          for (final b in j['blanks'] as List) List<String>.from(b as List),
        ],
      );

  Map<String, dynamic> toJson() => {'text': text, 'blanks': blanks};

  /// 本文を、文と空らんの番号に分ける（例：['The ', 1, ' is ', 2, '.']）
  List<Object> get parts {
    final out = <Object>[];
    final re = RegExp(r'\[(\d+)\]');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) out.add(text.substring(last, m.start));
      out.add(int.parse(m.group(1)!));
      last = m.end;
    }
    if (last < text.length) out.add(text.substring(last));
    return out;
  }
}

/// 記述の採点基準の1項目
class RubricItem {
  const RubricItem(this.point, this.score);

  /// 答えにふくまれているべき内容
  final String point;
  final int score;

  factory RubricItem.fromJson(Map<String, dynamic> j) =>
      RubricItem(j['point'] as String, (j['score'] as num?)?.toInt() ?? 1);

  Map<String, dynamic> toJson() => {'point': point, 'score': score};
}

/// 記述・論述・証明・英作文・和訳・要約：書いた答えを、模範解答と採点基準で採点する。
///
/// 端末の中では正しく自動採点できないので、模範解答と採点基準を見て自分で採点する
/// （[Grader] で、満たした項目の点を合計する）。将来、自動採点をつなげるための形。
class WrittenSpec {
  WrittenSpec({
    required this.modelAnswer,
    required this.rubric,
    int? passScore,
    this.kind = 'descriptive',
  }) : passScore = passScore ??
            (rubric.fold<int>(0, (a, r) => a + r.score) * 0.6).ceil() {
    if (rubric.isEmpty) throw ArgumentError('採点基準がありません');
    if (this.passScore < 1 || this.passScore > totalScore) {
      throw ArgumentError('合格点が範囲外です');
    }
  }

  final String modelAnswer;
  final List<RubricItem> rubric;

  /// 正解（合格）とみなす点
  final int passScore;

  /// 種類（descriptive 記述 / essay 論述 / proof 証明 / composition 英作文 /
  /// translation 和訳 / summary 要約）。表示に使う
  final String kind;

  int get totalScore => rubric.fold(0, (a, r) => a + r.score);

  static const kindLabels = {
    'descriptive': '記述',
    'essay': '論述',
    'proof': '証明',
    'composition': '英作文',
    'translation': '和訳',
    'summary': '要約',
  };

  String get kindLabel => kindLabels[kind] ?? '記述';

  factory WrittenSpec.fromJson(Map<String, dynamic> j) => WrittenSpec(
        modelAnswer: j['modelAnswer'] as String,
        rubric: [
          for (final r in j['rubric'] as List)
            RubricItem.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
        passScore: (j['passScore'] as num?)?.toInt(),
        kind: j['kind'] as String? ?? 'descriptive',
      );

  Map<String, dynamic> toJson() => {
        'modelAnswer': modelAnswer,
        'rubric': [for (final r in rubric) r.toJson()],
        'passScore': passScore,
        if (kind != 'descriptive') 'kind': kind,
      };
}

/// 採点の結果
class Grade {
  const Grade({required this.credit, required this.correct, this.detail = ''});

  /// 得点の割合（0〜1。部分点）
  final double credit;

  /// 正解（合格）か
  final bool correct;

  /// どこが合っていて、どこがちがったか（表示用）
  final String detail;

  static const wrong = Grade(credit: 0, correct: false);
  static const right = Grade(credit: 1, correct: true);
}

/// 新しい出題形式の答えを採点する（4択・入力式は、これまでどおり問題が採点する）。
abstract final class Grader {
  static Grade trueFalse(QuizQuestion q, bool answer) =>
      answer == q.truth ? Grade.right : Grade.wrong;

  /// 選んだ正解の数から、まちがって選んだ数を引いた割合が部分点
  static Grade multiSelect(QuizQuestion q, Set<int> chosen) {
    final spec = q.multiSelect!;
    final hits = chosen.intersection(spec.correct).length;
    final misses = chosen.difference(spec.correct).length;
    final credit =
        ((hits - misses) / spec.correct.length).clamp(0.0, 1.0).toDouble();
    final exact = misses == 0 && hits == spec.correct.length;
    return Grade(
      credit: exact ? 1 : credit,
      correct: exact,
      detail: '正しい選択 $hits/${spec.correct.length}・余分な選択 $misses',
    );
  }

  /// 並べた順（もとの項目の番号の並び）。となり合う2つの順が合っている割合が部分点
  static Grade order(QuizQuestion q, List<int> arranged) {
    final n = q.order!.items.length;
    if (arranged.length != n || arranged.toSet().length != n)
      return Grade.wrong;
    var good = 0;
    for (var i = 0; i + 1 < n; i++) {
      if (arranged[i] + 1 == arranged[i + 1]) good++;
    }
    final exact = good == n - 1 && arranged.first == 0;
    return Grade(
      credit: exact ? 1 : good / (n - 1),
      correct: exact,
      detail: 'となり合う順 $good/${n - 1} が正しい',
    );
  }

  static Grade numeric(QuizQuestion q, String input) {
    final spec = q.numeric!;
    final v = parseNumber(input, unit: spec.unit);
    if (v == null) return Grade.wrong;
    final tol = max(spec.tolerance, 1e-9 * max(1, spec.value.abs()));
    return (v - spec.value).abs() <= tol ? Grade.right : Grade.wrong;
  }

  /// 空らんごとに採点。合っている空らんの割合が部分点
  static Grade cloze(QuizQuestion q, List<String> inputs) {
    final spec = q.cloze!;
    var good = 0;
    for (var i = 0; i < spec.blanks.length; i++) {
      final a =
          i < inputs.length ? QuizQuestion.normalizeAnswer(inputs[i]) : '';
      if (a.isNotEmpty &&
          spec.blanks[i].any((s) => QuizQuestion.normalizeAnswer(s) == a)) {
        good++;
      }
    }
    final n = spec.blanks.length;
    return Grade(
      credit: good / n,
      correct: good == n,
      detail: '空らん $good/$n が正しい',
    );
  }

  /// 段階問題：段階ごとの正誤（true が正解）。正解した段階の割合が部分点
  static Grade steps(QuizQuestion q, List<bool> results) {
    final n = q.subQuestions.length;
    final good = results.where((r) => r).length;
    return Grade(
      credit: n == 0 ? 0 : good / n,
      correct: n > 0 && good == n && results.length == n,
      detail: '段階 $good/$n を正解',
    );
  }

  /// 記述：満たした採点基準の項目（番号）の点の合計
  static Grade written(QuizQuestion q, Set<int> satisfied) {
    final spec = q.written!;
    var score = 0;
    for (final i in satisfied) {
      if (i >= 0 && i < spec.rubric.length) score += spec.rubric[i].score;
    }
    return Grade(
      credit: score / spec.totalScore,
      correct: score >= spec.passScore,
      detail: '$score / ${spec.totalScore} 点（合格 ${spec.passScore} 点）',
    );
  }

  /// 数の答えを読む：整数・小数・分数（3/4）・指数（1.2e3, 1.2×10^3）・全角・単位つき
  static double? parseNumber(String input, {String unit = ''}) {
    var s = QuizQuestion.normalizeAnswer(input)
        .replaceAll('，', '')
        .replaceAll(',', '')
        .replaceAll('−', '-')
        .replaceAll('－', '-');
    if (unit.isNotEmpty) {
      s = s.replaceAll(QuizQuestion.normalizeAnswer(unit), '');
    }
    s = s.replaceAll(RegExp(r'[×x\*]10\^'), 'e');
    final frac = RegExp(r'^(-?\d+(?:\.\d+)?)/(\d+(?:\.\d+)?)$').firstMatch(s);
    if (frac != null) {
      final d = double.parse(frac.group(2)!);
      return d == 0 ? null : double.parse(frac.group(1)!) / d;
    }
    return double.tryParse(s);
  }
}
