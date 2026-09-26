/// 問題データの出どころ。
///
/// RPG（課金ワールドを含む）の中身には [original]（自作問題）だけを使う。
/// 市販教材（LEAP など）由来のデータは、利用者が自分の端末に取り込んだものを
/// パスワード保護された学習モードで使う場合に限り [personalImport] として扱う。
/// アプリ同梱のデータ（assets）に [personalImport] を入れてはいけない。
enum QuestionOrigin {
  original,
  userCreated,

  /// 利用者が個人利用のために端末へ取り込んだ単語帳（市販教材を含みうる）。
  /// RPG・課金コンテンツには使えない。
  personalImport;

  /// RPG のバトルや宿の授業で使ってよいか
  bool get usableInRpg => this == original;

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
  usage('語法'),

  /// 長文読解
  reading('読解');

  const QuestionCategory(this.label);
  final String label;

  static QuestionCategory parse(String value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    throw FormatException('不明なカテゴリです: "$value"');
  }
}

/// 長文読解の本文。
class Passage {
  const Passage(
      {required this.id, required this.title, required this.paragraphs});

  final String id;
  final String title;
  final List<String> paragraphs;

  factory Passage.fromJson(Map<String, dynamic> json) => Passage(
        id: json['id'] as String,
        title: json['title'] as String,
        paragraphs: List<String>.from(json['paragraphs'] as List),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'paragraphs': paragraphs};
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
    this.passage,
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

  /// 長文読解の問題なら、その本文
  final Passage? passage;

  String get answer => choices[answerIndex];

  /// バトル中に出す短い解説（最初の1文）。全文は復習手帳で読める。
  String get shortExplanation {
    final e = explanation?.trim() ?? '';
    final end = e.indexOf('。');
    return end < 0 ? e : e.substring(0, end + 1);
  }

  /// 解説に2文目以降があるか（復習手帳に続きがある）
  bool get hasMoreExplanation =>
      shortExplanation.length < (explanation?.trim().length ?? 0);

  factory QuizQuestion.fromJson(Map<String, dynamic> json,
          {Map<String, Passage> passages = const {}}) =>
      QuizQuestion(
        id: json['id'] as String,
        category: QuestionCategory.parse(json['category'] as String),
        prompt: json['prompt'] as String,
        sentence: json['sentence'] as String?,
        choices: List<String>.from(json['choices'] as List),
        answerIndex: json['answerIndex'] as int,
        explanation: json['explanation'] as String?,
        passage: json['passageId'] == null
            ? null
            : (passages[json['passageId']] ??
                (throw FormatException('本文が見つかりません: ${json['passageId']}'))),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'prompt': prompt,
        if (sentence != null) 'sentence': sentence,
        'choices': choices,
        'answerIndex': answerIndex,
        if (explanation != null) 'explanation': explanation,
        if (passage != null) 'passageId': passage!.id,
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

  /// このセットに含まれる長文の本文
  List<Passage> get passages {
    final seen = <String>{};
    return [
      for (final q in questions)
        if (q.passage != null && seen.add(q.passage!.id)) q.passage!,
    ];
  }

  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    final passages = {
      for (final p in (json['passages'] as List?) ?? const [])
        (p as Map<String, dynamic>)['id'] as String: Passage.fromJson(p),
    };
    return QuestionSet(
      setId: json['setId'] as String,
      worldId: json['worldId'] as String,
      origin: QuestionOrigin.parse(json['origin'] as String),
      version: json['version'] as int,
      questions: (json['questions'] as List)
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>,
              passages: passages))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'setId': setId,
        'worldId': worldId,
        'origin': origin.name,
        'version': version,
        if (passages.isNotEmpty)
          'passages': passages.map((p) => p.toJson()).toList(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  /// 複数の問題セットを1つにまとめる（エリア16以降の出題範囲用）。
  /// 出どころが1つでも original 以外なら、まとめたセットもそれに合わせる。
  static QuestionSet merge(String setId, List<QuestionSet> sets) {
    final questions = <QuizQuestion>[];
    final ids = <String>{};
    for (final s in sets) {
      for (final q in s.questions) {
        if (ids.add(q.id)) questions.add(q);
      }
    }
    final origin = sets.every((s) => s.origin == QuestionOrigin.original)
        ? QuestionOrigin.original
        : sets.firstWhere((s) => s.origin != QuestionOrigin.original).origin;
    return QuestionSet(
      setId: setId,
      worldId: sets.first.worldId,
      origin: origin,
      version: 1,
      questions: questions,
    );
  }
}
