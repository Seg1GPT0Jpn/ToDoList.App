/// 問題データの出どころ。
///
/// 課金ゲームの中身には [original]（自作問題）と [userCreated]（利用者が
/// 自分で作った単語帳）だけを使う。市販教材（LEAP・STEP 等）由来のデータは
/// 著作権上の理由から、この列挙に値を持たせず、そもそも読み込めないようにしている。
enum QuestionOrigin {
  original,
  userCreated;

  static QuestionOrigin parse(String value) {
    for (final origin in values) {
      if (origin.name == value) return origin;
    }
    throw FormatException('使用できない問題データの出どころです: "$value"');
  }
}

/// 出題カテゴリ。
enum QuestionCategory {
  /// 品詞
  partOfSpeech('品詞'),

  /// 意味
  meaning('意味'),

  /// 語法・文法
  usage('語法');

  const QuestionCategory(this.label);
  final String label;

  static QuestionCategory parse(String value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    throw FormatException('不明なカテゴリです: "$value"');
  }
}

/// 4択クイズの1問。
class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.category,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    this.sentence,
    this.explanation,
  }) {
    if (choices.length != 4) {
      throw ArgumentError('問題 $id: 選択肢は4つ必要です（${choices.length}個）');
    }
    if (answerIndex < 0 || answerIndex >= choices.length) {
      throw ArgumentError('問題 $id: answerIndex が範囲外です');
    }
    if (choices.toSet().length != choices.length) {
      throw ArgumentError('問題 $id: 選択肢が重複しています');
    }
  }

  final String id;
  final QuestionCategory category;

  /// 問いかけ（例: 「次のうち名詞はどれ？」）
  final String prompt;

  /// 英文など、問いかけとは別に大きく表示する本文（任意）
  final String? sentence;
  final List<String> choices;
  final int answerIndex;
  final String? explanation;

  String get answer => choices[answerIndex];

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] as String,
        category: QuestionCategory.parse(json['category'] as String),
        prompt: json['prompt'] as String,
        sentence: json['sentence'] as String?,
        choices: List<String>.from(json['choices'] as List),
        answerIndex: json['answerIndex'] as int,
        explanation: json['explanation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'prompt': prompt,
        if (sentence != null) 'sentence': sentence,
        'choices': choices,
        'answerIndex': answerIndex,
        if (explanation != null) 'explanation': explanation,
      };
}

/// ステージ1つ分の問題セット。
class QuestionSet {
  QuestionSet({
    required this.setId,
    required this.worldId,
    required this.origin,
    required this.version,
    required this.questions,
  }) {
    if (questions.isEmpty) {
      throw ArgumentError('問題セット $setId に問題がありません');
    }
    final ids = questions.map((q) => q.id).toSet();
    if (ids.length != questions.length) {
      throw ArgumentError('問題セット $setId に重複した問題IDがあります');
    }
  }

  final String setId;
  final String worldId;
  final QuestionOrigin origin;
  final int version;
  final List<QuizQuestion> questions;

  factory QuestionSet.fromJson(Map<String, dynamic> json) => QuestionSet(
        setId: json['setId'] as String,
        worldId: json['worldId'] as String,
        origin: QuestionOrigin.parse(json['origin'] as String),
        version: json['version'] as int,
        questions: (json['questions'] as List)
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'setId': setId,
        'worldId': worldId,
        'origin': origin.name,
        'version': version,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
