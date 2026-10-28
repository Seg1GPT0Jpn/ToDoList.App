import 'dart:convert';

import '../vocab/vocab_vault.dart';

/// 定期テストの予想問題を、時間を計って解く（全体で [YosouExam.minutes] 分、1問ごとの制限なし）。
///
/// 問題冊子は原本のページ画像をそのまま見せ（図・数式・縦書きもそのまま）、答えはアプリの
/// 解答用紙に書く。ページ画像と解答用紙（答え・配点）は、学校のパスワードから作った鍵で
/// 暗号化して同梱する（[SchoolMaterials] と同じ形式。鍵はアプリの中に置かない）。
class YosouExam {
  const YosouExam({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.questionPages,
    required this.answerPages,
    this.minutes = 60,
    this.smallQuestions = false,
  });

  /// 同梱フォルダの名前（assets/mock_exams/<id>/）
  final String id;
  final String title;

  /// 学校の科目（ShonanSubjects の id）
  final String subjectId;

  /// 問題冊子のページ数（01.bin〜）
  final int questionPages;

  /// 解答・解説のページ数（問題冊子のあとに続く。提出してから見られる）
  final int answerPages;
  final int minutes;

  int get pages => questionPages + answerPages;

  /// [page] ページ目（1から。問題冊子→解答・解説の順）の同梱ファイル
  String asset(int page) =>
      'assets/mock_exams/$id/${page.toString().padLeft(2, '0')}.bin';

  /// 解答用紙（答え・配点）の同梱ファイル
  String get sheetAsset => 'assets/mock_exams/$id/sheet.bin';

  /// 小問ごとの問題データ（QuestionSet の JSON）を同梱しているか
  final bool smallQuestions;

  /// 小問ごとの問題データの同梱ファイル
  String get questionsAsset => 'assets/mock_exams/$id/questions.bin';
}

abstract final class YosouExams {
  static const all = <YosouExam>[
    YosouExam(
      id: 'gendai',
      title: '現代の国語 後期中間 予想問題',
      subjectId: 'gendai_kokugo',
      questionPages: 26,
      answerPages: 6,
    ),
    YosouExam(
      id: 'gengo',
      title: '言語文化 後期中間 予想問題',
      subjectId: 'gengo_bunka',
      questionPages: 14,
      answerPages: 8,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'math1',
      title: '数学Ⅰ 後期中間 予想問題',
      subjectId: 'math1',
      questionPages: 2,
      answerPages: 6,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'mathA',
      title: '数学A 後期中間 予想問題',
      subjectId: 'math_a',
      questionPages: 2,
      answerPages: 6,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'ec',
      title: 'English Communication Ⅰ 後期中間 予想問題',
      subjectId: 'ec1',
      questionPages: 8,
      answerPages: 10,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'le',
      title: 'Logic and Expression Ⅰ 後期中間 予想問題',
      subjectId: 'ronhyo1',
      questionPages: 4,
      answerPages: 3,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'chem',
      title: '化学基礎 後期中間 予想問題',
      subjectId: 'chemistry_basic',
      questionPages: 4,
      answerPages: 3,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'bio',
      title: '生物基礎 後期中間 予想問題',
      subjectId: 'biology_basic',
      questionPages: 5,
      answerPages: 3,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'kokyo',
      title: '公共 後期中間 予想問題',
      subjectId: 'public_economy',
      questionPages: 9,
      answerPages: 4,
      smallQuestions: true,
    ),
    YosouExam(
      id: 'joho',
      title: '情報Ⅰ 後期中間 予想問題',
      subjectId: 'information1',
      questionPages: 6,
      answerPages: 2,
      smallQuestions: true,
    ),
  ];

  static YosouExam? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// 解答用紙の1つの欄の答え方
enum MockItemType {
  /// 選択肢から選ぶ（自動で採点）
  choice,

  /// 書いて答える（自動で採点。書き方のちがいは、あとで自分で直せる）
  text,

  /// 記述・計算の過程など。模範解答を見て自分で点をつける
  self,
}

class MockItem {
  const MockItem({
    required this.id,
    required this.label,
    required this.type,
    required this.points,
    this.options = const [],
    this.answers = const [],
    this.explain = '',
    this.all = false,
  });

  /// 解答用紙の中で一意な名前
  final String id;

  /// 欄の名前（「[01]」「問1 ⑴」など）
  final String label;
  final MockItemType type;
  final int points;

  /// 選択肢（[MockItemType.choice]）
  final List<String> options;

  /// 正解。choice は正解の選択肢、text は正解として認める書き方、self は模範解答
  final List<String> answers;

  /// 短い解説（採点基準など）
  final String explain;

  /// choice で、正解をすべて選ぶ（完答・順不同）
  final bool all;

  static MockItem fromMap(Map<String, dynamic> m) => MockItem(
        id: m['id'] as String,
        label: m['l'] as String? ?? m['id'] as String,
        type: MockItemType.values.byName(m['t'] as String? ?? 'text'),
        points: (m['p'] as num?)?.toInt() ?? 1,
        options: [for (final o in m['o'] as List? ?? const []) '$o'],
        answers: [for (final a in m['a'] as List? ?? const []) '$a'],
        explain: m['e'] as String? ?? '',
        all: m['all'] == true,
      );

  /// 選んだ選択肢をつなげた答え（all のとき。選んだ順は問わない）
  static String joinChoices(Iterable<String> picked) {
    final list = picked.toSet().toList()..sort();
    return list.join(',');
  }

  static List<String> splitChoices(String? answer) =>
      answer == null || answer.isEmpty ? const [] : answer.split(',');

  /// 答えが合っているか（self は null。答えていなければ false）
  bool? check(String? answer) {
    if (type == MockItemType.self) return null;
    if (answer == null || answer.trim().isEmpty) return false;
    if (type == MockItemType.choice) {
      if (all) return joinChoices(answers) == joinChoices(splitChoices(answer));
      return answers.contains(answer);
    }
    final a = normalize(answer);
    return answers.any((x) => normalize(x) == a);
  }

  /// 書き方のちがいをそろえる（全角→半角・空白や読点・かっこを除く・小文字・マイナス記号）
  static String normalize(String s) => VocabVault.halfWidth(s)
      .toLowerCase()
      .replaceAll(RegExp('[−‐–—―]'), '-')
      .replaceAll(RegExp('[〜~]'), '~')
      .replaceAll(RegExp(r'[\s、。・「」『』()〔〕\[\]【】]'), '');
}

class MockSection {
  const MockSection({
    required this.title,
    required this.items,
    this.speech = const [],
    this.plays = 1,
  });

  final String title;
  final List<MockItem> items;

  /// リスニングの原稿（読み上げる。段落ごと）
  final List<String> speech;

  /// リスニングを流せる回数
  final int plays;

  static MockSection fromMap(Map<String, dynamic> m) => MockSection(
        title: m['title'] as String,
        items: [
          for (final i in m['items'] as List)
            MockItem.fromMap(Map<String, dynamic>.from(i as Map)),
        ],
        speech: [for (final s in m['speech'] as List? ?? const []) '$s'],
        plays: (m['plays'] as num?)?.toInt() ?? 1,
      );
}

/// 解答用紙（欄・答え・配点）
class MockSheet {
  const MockSheet({required this.sections, this.note = ''});

  final List<MockSection> sections;

  /// 配点などの注意
  final String note;

  Iterable<MockItem> get items => sections.expand((s) => s.items);
  int get total => items.fold(0, (a, i) => a + i.points);

  MockItem? item(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  static MockSheet fromJson(String json) {
    final m = Map<String, dynamic>.from(jsonDecode(json) as Map);
    return MockSheet(
      sections: [
        for (final s in m['sections'] as List)
          MockSection.fromMap(Map<String, dynamic>.from(s as Map)),
      ],
      note: m['note'] as String? ?? '',
    );
  }
}

/// 1回分の受験（答え・見直しの印・時間・採点）。端末に保存して、閉じても続きから再開できる
class MockAttempt {
  MockAttempt({
    required this.examId,
    required this.startedAt,
    Map<String, String>? answers,
    Set<String>? flags,
    this.pausedFor = Duration.zero,
    this.pausedAt,
    this.submittedAt,
    Map<String, int>? selfScores,
    Map<String, bool>? overrides,
  })  : answers = answers ?? {},
        flags = flags ?? {},
        selfScores = selfScores ?? {},
        overrides = overrides ?? {};

  final String examId;
  final DateTime startedAt;
  final Map<String, String> answers;

  /// あとで見直す欄
  final Set<String> flags;

  /// 一時停止していた時間の合計（今の一時停止はふくまない）
  Duration pausedFor;
  DateTime? pausedAt;
  DateTime? submittedAt;

  /// 自分でつけた点（self の欄）
  final Map<String, int> selfScores;

  /// 自動採点を自分で直した（書き方のちがいなど）
  final Map<String, bool> overrides;

  bool get paused => pausedAt != null;
  bool get submitted => submittedAt != null;

  /// 解いていた時間（一時停止をのぞく）
  Duration spent(DateTime now) {
    final end = submittedAt ?? pausedAt ?? now;
    final d = end.difference(startedAt) - pausedFor;
    return d.isNegative ? Duration.zero : d;
  }

  /// 残り時間
  Duration remaining(DateTime now, int minutes) {
    final r = Duration(minutes: minutes) - spent(now);
    return r.isNegative ? Duration.zero : r;
  }

  void pause(DateTime now) {
    if (paused || submitted) return;
    pausedAt = now;
  }

  void resume(DateTime now) {
    final at = pausedAt;
    if (at == null) return;
    pausedFor += now.difference(at);
    pausedAt = null;
  }

  /// 時間切れのときは、ちょうど時間が来たときに出したことにする
  void submit(DateTime now, int minutes) {
    if (submitted) return;
    resume(now);
    final limit = startedAt.add(Duration(minutes: minutes) + pausedFor);
    submittedAt = now.isAfter(limit) ? limit : now;
  }

  bool answered(MockItem i) => (answers[i.id] ?? '').trim().isNotEmpty;

  /// 欄が正解か（self は自分でつけた点が満点か。まだなら null）
  bool? correct(MockItem i) {
    final o = overrides[i.id];
    if (o != null) return o;
    if (i.type == MockItemType.self) {
      final s = selfScores[i.id];
      return s == null ? null : s >= i.points;
    }
    return i.check(answers[i.id]);
  }

  /// 欄の点（self でまだ点をつけていなければ null）
  int? scoreOf(MockItem i) {
    final o = overrides[i.id];
    if (o != null) return o ? i.points : 0;
    if (i.type == MockItemType.self) {
      final s = selfScores[i.id];
      return s?.clamp(0, i.points);
    }
    return i.check(answers[i.id]) == true ? i.points : 0;
  }

  int score(MockSheet sheet) =>
      sheet.items.fold(0, (a, i) => a + (scoreOf(i) ?? 0));

  /// まだ自分で点をつけていない欄
  List<MockItem> unscored(MockSheet sheet) => [
        for (final i in sheet.items)
          if (scoreOf(i) == null) i,
      ];

  Map<String, Object?> toMap() => {
        'exam': examId,
        'start': startedAt.millisecondsSinceEpoch,
        'answers': answers,
        'flags': flags.toList(),
        'paused': pausedFor.inMilliseconds,
        if (pausedAt != null) 'pausedAt': pausedAt!.millisecondsSinceEpoch,
        if (submittedAt != null)
          'submitted': submittedAt!.millisecondsSinceEpoch,
        'self': selfScores,
        'over': overrides,
      };

  static MockAttempt fromMap(Map<String, dynamic> m) {
    DateTime? t(Object? v) =>
        v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
    return MockAttempt(
      examId: m['exam'] as String,
      startedAt: t(m['start'])!,
      answers: {
        for (final e in (m['answers'] as Map? ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
      flags: {for (final f in m['flags'] as List? ?? const []) '$f'},
      pausedFor: Duration(milliseconds: (m['paused'] as num? ?? 0).toInt()),
      pausedAt: t(m['pausedAt']),
      submittedAt: t(m['submitted']),
      selfScores: {
        for (final e in (m['self'] as Map? ?? const {}).entries)
          '${e.key}': (e.value as num).toInt(),
      },
      overrides: {
        for (final e in (m['over'] as Map? ?? const {}).entries)
          '${e.key}': e.value == true,
      },
    );
  }
}
