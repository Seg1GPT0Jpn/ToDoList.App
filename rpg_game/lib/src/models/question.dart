import '../curriculum/question_meta.dart';
import 'difficulty.dart';
import 'question_format.dart';

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
  reading('読解'),

  /// 用語・しくみの知識（理科など）
  knowledge('知識'),

  /// 計算
  calculation('計算'),

  /// グラフ・実験の考察
  thinking('考察');

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
    this.choices = const [],
    this.answerIndex = 0,
    this.format = QuestionFormat.choice,
    this.truth,
    this.multiSelect,
    this.order,
    this.numeric,
    this.cloze,
    this.subQuestions = const [],
    this.written,
    this.sentence,
    this.explanation,
    this.passage,
    this.difficulty,
    this.hint,
    this.tags = const [],
    this.commonMistakes = const [],
    this.figure,
    this.accepted,
    this.listen = false,
    this.unit,
    this.unitLocked = false,
    this.thinkingLevel,
    this.axes,
    this.sourceKind = QuestionSourceKind.original,
    this.targetGrade,
    this.phase,
    this.estimatedSeconds,
    this.related = const [],
    this.combines = const [],
    this.steps,
    this.guidance,
  }) {
    if (format != QuestionFormat.choice) {
      _checkSpec();
      return;
    }
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

  void _checkSpec() {
    final ok = switch (format) {
      QuestionFormat.choice => true,
      QuestionFormat.trueFalse => truth != null,
      QuestionFormat.multiSelect => multiSelect != null,
      QuestionFormat.order => order != null,
      QuestionFormat.numeric => numeric != null,
      QuestionFormat.cloze => cloze != null,
      QuestionFormat.multiStep => subQuestions.length >= 2 &&
          subQuestions.every((s) => s.format == QuestionFormat.choice),
      QuestionFormat.written => written != null,
    };
    if (!ok) {
      throw ArgumentError('問題 $id: ${format.label}の中身がありません');
    }
  }

  // ---- 出題形式（4択以外） ----

  /// 出題形式（書かれていなければ4択。accepted があれば入力でも答えられる）
  final QuestionFormat format;

  /// 正誤：[sentence]（または問い）の内容が正しいか
  final bool? truth;
  final MultiSelectSpec? multiSelect;
  final OrderSpec? order;
  final NumericSpec? numeric;
  final ClozeSpec? cloze;

  /// 段階問題（誘導）：順に答える小問（それぞれ4択）
  final List<QuizQuestion> subQuestions;
  final WrittenSpec? written;

  /// 4択（入力式をふくむ）の問題か。4択しか出せない画面（対戦・宝箱など）はこれだけを使う
  bool get isChoice => format == QuestionFormat.choice;

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

  /// 難易度（書かれていなければ null。ステージの難易度を使う）
  final Difficulty? difficulty;

  /// ヒント（ヒントのカードなどで表示する）
  final String? hint;

  /// 分類のためのタグ（例：2次関数、最大・最小）
  final List<String> tags;

  /// よくある間違い（不正解のときに表示する）
  final List<String> commonMistakes;

  /// 図・グラフ（任意）。形式は figure_spec.dart。アプリ側で描く。
  final Map<String, dynamic>? figure;

  /// 入力で答えられる問題なら、正解として受け付ける答え（正解の選択肢も自動で受け付ける）
  final List<String>? accepted;

  /// リスニング問題：本文（sentence）を文字で見せず、読み上げて聞かせる
  final bool listen;

  // ---- 学習体系での位置と、学習上の属性（すべて省略できる） ----

  /// 学習体系の単元・小単元の ID（例：math.m1.quad.maxmin.param）。
  /// tool/curriculum/assign.py が問題文から自動で書き込む
  final String? unit;

  /// [unit] を手で決めた（自動の振り分けで書きかえない）
  final bool unitLocked;

  /// 思考レベル（書かれていなければ [QuestionProfiler] が推定する）
  final ThinkingLevel? thinkingLevel;

  /// 難しさの種類（知識・計算・読解・思考・初見・記述・時間）
  final DifficultyAxes? axes;

  /// 出典の種類（オリジナル・本番形式・改題・練習・過去問）
  final QuestionSourceKind sourceKind;

  /// 対象学年（'1'・'2-3' など。なければ学習体系から決まる）
  final String? targetGrade;

  /// 学習の段階（定期テスト〜東大レベル）
  final LearningPhase? phase;

  /// 解くのにかかる時間の目安（秒）
  final int? estimatedSeconds;

  /// 関連する問題の ID（類題・前の段階の問題）
  final List<String> related;

  /// この問題で組み合わせて使う、ほかの単元の ID（複合問題）
  final List<String> combines;

  /// 答えに至るまでの思考の段階数
  final int? steps;

  /// 誘導への依存度（0：誘導なし 〜 5：小問で細かく誘導）
  final int? guidance;

  /// 入力で答えられる問題か
  bool get isInput => accepted != null;

  /// 正解を1行で表したもの（記述は模範解答）
  String get answer => switch (format) {
        QuestionFormat.choice => choices[answerIndex],
        QuestionFormat.trueFalse => truth! ? '正しい（○）' : '誤り（×）',
        QuestionFormat.multiSelect => [
            for (final i in multiSelect!.correct.toList()..sort())
              multiSelect!.options[i],
          ].join('・'),
        QuestionFormat.order => order!.items.join(order!.joiner),
        QuestionFormat.numeric => numeric!.display,
        QuestionFormat.cloze => [
            for (var i = 0; i < cloze!.blanks.length; i++)
              '(${i + 1}) ${cloze!.blanks[i].first}',
          ].join('　'),
        QuestionFormat.multiStep =>
          [for (final s in subQuestions) s.answer].join(' → '),
        QuestionFormat.written => written!.modelAnswer,
      };

  /// 入力された答えが正解か（全角・半角、大文字・小文字、空白の違いは無視する）
  bool matchesInput(String input) {
    final a = normalizeAnswer(input);
    if (a.isEmpty) return false;
    return [answer, ...?accepted].any((s) => normalizeAnswer(s) == a);
  }

  /// 答えの比較用に、表記の小さな違いをそろえる
  static String normalizeAnswer(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      var c = r;
      if (c >= 0xFF01 && c <= 0xFF5E) c -= 0xFEE0; // 全角英数字・記号 → 半角
      if (c == 0x3000 || c == 0x20 || c == 0x09) continue; // 空白
      if (c == 0x2212 || c == 0x2013 || c == 0x2014) c = 0x2D; // − – — → -
      b.writeCharCode(c);
    }
    var out = b.toString().toLowerCase();
    while (out.isNotEmpty && '。.、,'.contains(out[out.length - 1])) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

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
        choices: List<String>.from((json['choices'] as List?) ?? const []),
        answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
        format: QuestionFormat.parse(json['format'] as String?),
        truth: json['truth'] as bool?,
        multiSelect: json['multiSelect'] == null
            ? null
            : MultiSelectSpec.fromJson(
                Map<String, dynamic>.from(json['multiSelect'] as Map)),
        order: json['order'] == null
            ? null
            : OrderSpec.fromJson(
                Map<String, dynamic>.from(json['order'] as Map)),
        numeric: json['numeric'] == null
            ? null
            : NumericSpec.fromJson(
                Map<String, dynamic>.from(json['numeric'] as Map)),
        cloze: json['cloze'] == null
            ? null
            : ClozeSpec.fromJson(
                Map<String, dynamic>.from(json['cloze'] as Map)),
        subQuestions: [
          for (final (i, s)
              in ((json['subQuestions'] as List?) ?? const []).indexed)
            QuizQuestion.fromJson({
              'id': '${json['id']}_s${i + 1}',
              'category': json['category'],
              ...Map<String, dynamic>.from(s as Map),
            }),
        ],
        written: json['written'] == null
            ? null
            : WrittenSpec.fromJson(
                Map<String, dynamic>.from(json['written'] as Map)),
        explanation: json['explanation'] as String?,
        difficulty: Difficulty.tryParse(json['difficulty'] as String?),
        hint: json['hint'] as String?,
        tags: List<String>.from((json['tags'] as List?) ?? const []),
        commonMistakes:
            List<String>.from((json['commonMistakes'] as List?) ?? const []),
        passage: json['passageId'] == null
            ? null
            : (passages[json['passageId']] ??
                (throw FormatException('本文が見つかりません: ${json['passageId']}'))),
        figure: json['figure'] as Map<String, dynamic>?,
        accepted: (json['accepted'] as List?)?.cast<String>(),
        listen: json['listen'] as bool? ?? false,
        unit: json['unit'] as String?,
        unitLocked: json['unitLocked'] as bool? ?? false,
        thinkingLevel: ThinkingLevel.tryParse(json['thinkingLevel']),
        axes: json['axes'] == null
            ? null
            : DifficultyAxes.fromJson(
                Map<String, dynamic>.from(json['axes'] as Map)),
        sourceKind: QuestionSourceKind.parse(json['sourceKind'] as String?),
        targetGrade: json['targetGrade']?.toString(),
        phase: LearningPhase.tryParse(json['phase'] as String?),
        estimatedSeconds: (json['estimatedSeconds'] as num?)?.toInt(),
        related: List<String>.from((json['related'] as List?) ?? const []),
        combines: List<String>.from((json['combines'] as List?) ?? const []),
        steps: (json['steps'] as num?)?.toInt(),
        guidance: (json['guidance'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (unit != null) 'unit': unit,
        if (unitLocked) 'unitLocked': true,
        'category': category.name,
        if (format != QuestionFormat.choice) 'format': format.name,
        'prompt': prompt,
        if (sentence != null) 'sentence': sentence,
        if (format == QuestionFormat.choice) 'choices': choices,
        if (format == QuestionFormat.choice) 'answerIndex': answerIndex,
        if (truth != null) 'truth': truth,
        if (multiSelect != null) 'multiSelect': multiSelect!.toJson(),
        if (order != null) 'order': order!.toJson(),
        if (numeric != null) 'numeric': numeric!.toJson(),
        if (cloze != null) 'cloze': cloze!.toJson(),
        if (subQuestions.isNotEmpty)
          'subQuestions': [
            for (final s in subQuestions)
              {
                for (final e in s.toJson().entries)
                  if (e.key != 'id' && e.key != 'category') e.key: e.value,
              },
          ],
        if (written != null) 'written': written!.toJson(),
        if (explanation != null) 'explanation': explanation,
        if (passage != null) 'passageId': passage!.id,
        if (difficulty != null) 'difficulty': difficulty!.name,
        if (hint != null) 'hint': hint,
        if (tags.isNotEmpty) 'tags': tags,
        if (commonMistakes.isNotEmpty) 'commonMistakes': commonMistakes,
        if (figure != null) 'figure': figure,
        if (accepted != null) 'accepted': accepted,
        if (listen) 'listen': true,
        if (thinkingLevel != null) 'thinkingLevel': thinkingLevel!.number,
        if (axes != null) 'axes': axes!.toJson(),
        if (sourceKind != QuestionSourceKind.original)
          'sourceKind': sourceKind.name,
        if (targetGrade != null) 'targetGrade': targetGrade,
        if (phase != null) 'phase': phase!.name,
        if (estimatedSeconds != null) 'estimatedSeconds': estimatedSeconds,
        if (related.isNotEmpty) 'related': related,
        if (combines.isNotEmpty) 'combines': combines,
        if (steps != null) 'steps': steps,
        if (guidance != null) 'guidance': guidance,
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
