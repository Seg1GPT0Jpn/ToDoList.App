import '../models/question.dart';

/// 学校の定期テスト対策（湘南高校104回生モード）。
///
/// 学校の科目（11科目）と、アプリの教科（[worldId]：英語・数学など6つ）は別に扱う。
/// 科目の表示には [SchoolSubject.displayName] を使い、worldId は問題を読む接続先にだけ使う。

/// 学校の科目の定義
class SchoolSubject {
  const SchoolSubject({
    required this.id,
    required this.category,
    required this.displayName,
    required this.worldId,
  });

  final String id;

  /// 国語・数学・英語・理科・社会・情報
  final String category;
  final String displayName;

  /// 問題データを読む既存の教科（japanese / math / english / science / social / information）
  final String worldId;
}

/// 湘南高校104回生の11科目（科目の定義はここだけに置く）
class ShonanSubjects {
  const ShonanSubjects._();

  static const all = <SchoolSubject>[
    SchoolSubject(
        id: 'gendai_kokugo',
        category: '国語',
        displayName: '現代の国語（現代文）',
        worldId: 'japanese'),
    SchoolSubject(
        id: 'gengo_bunka',
        category: '国語',
        displayName: '言語文化（古文・漢文）',
        worldId: 'japanese'),
    SchoolSubject(
        id: 'math1',
        category: '数学',
        displayName: '数学Ⅰ（数学Ⅰ・Ⅱ）',
        worldId: 'math'),
    SchoolSubject(
        id: 'math_a', category: '数学', displayName: '数学A（数学A）', worldId: 'math'),
    SchoolSubject(
        id: 'ec1',
        category: '英語',
        displayName: 'ECⅠ（English Communication Ⅰ：総合）',
        worldId: 'english'),
    SchoolSubject(
        id: 'ronhyo1',
        category: '英語',
        displayName: '論表Ⅰ（Logic and Expression Ⅰ：文法）',
        worldId: 'english'),
    SchoolSubject(
        id: 'chemistry_basic',
        category: '理科',
        displayName: '化学基礎',
        worldId: 'science'),
    SchoolSubject(
        id: 'biology_basic',
        category: '理科',
        displayName: '生物基礎',
        worldId: 'science'),
    SchoolSubject(
        id: 'geography_general',
        category: '社会',
        displayName: '地理総合',
        worldId: 'social'),
    SchoolSubject(
        id: 'public_economy',
        category: '社会',
        displayName: '公共（政治経済の経済分野）',
        worldId: 'social'),
    SchoolSubject(
        id: 'information1',
        category: '情報',
        displayName: '情報Ⅰ',
        worldId: 'information'),
  ];

  static SchoolSubject? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// 範囲・教材情報の状態（授業の進み具合から推測はしない）
enum RangeStatus {
  empty('未入力'),
  entered('入力済み'),
  confirmed('確認済み');

  const RangeStatus(this.label);
  final String label;

  static RangeStatus parse(Object? v) {
    for (final s in values) {
      if (s.name == v) return s;
    }
    return empty;
  }
}

/// 教材1つ分の範囲（教科書・ワーク・プリントなど）
class StudyMaterial {
  const StudyMaterial({
    this.kind = '',
    this.name = '',
    this.range = '',
    this.note = '',
  });

  /// 教科書・ワーク・授業プリント・配布資料・その他
  final String kind;

  /// 教材名（例：サクシード、LEAP）
  final String name;

  /// ページ・番号・範囲（例：P.38-65）
  final String range;
  final String note;

  bool get isEmpty => name.isEmpty && range.isEmpty && note.isEmpty;

  StudyMaterial copyWith(
          {String? kind, String? name, String? range, String? note}) =>
      StudyMaterial(
        kind: kind ?? this.kind,
        name: name ?? this.name,
        range: range ?? this.range,
        note: note ?? this.note,
      );

  Map<String, dynamic> toMap() => {
        if (kind.isNotEmpty) 'kind': kind,
        if (name.isNotEmpty) 'name': name,
        if (range.isNotEmpty) 'range': range,
        if (note.isNotEmpty) 'note': note,
      };

  factory StudyMaterial.fromMap(Map<String, dynamic> m) => StudyMaterial(
        kind: _str(m['kind']),
        name: _str(m['name']),
        range: _str(m['range']),
        note: _str(m['note']),
      );
}

/// 1科目ぶんの試験範囲
class SubjectExamPlan {
  const SubjectExamPlan({
    required this.subjectId,
    this.rangeText = '',
    this.materials = const [],
    this.existingSetIds = const [],
    this.committeeSetIds = const [],
    this.status = RangeStatus.empty,
    this.examDate,
  });

  final String subjectId;
  final String rangeText;
  final List<StudyMaterial> materials;

  /// アプリに最初から入っている問題セット
  final List<String> existingSetIds;

  /// 委員会が作った問題セット
  final List<String> committeeSetIds;
  final RangeStatus status;

  /// この科目の試験日（範囲表に科目ごとの日付があるとき）
  final DateTime? examDate;

  bool get hasRange =>
      rangeText.trim().isNotEmpty || materials.any((m) => !m.isEmpty);
  bool get hasSets => existingSetIds.isNotEmpty || committeeSetIds.isNotEmpty;

  /// 範囲か問題セットのどちらかが入っている
  bool get isFilled => hasRange || hasSets;

  SubjectExamPlan copyWith({
    String? rangeText,
    List<StudyMaterial>? materials,
    List<String>? existingSetIds,
    List<String>? committeeSetIds,
    RangeStatus? status,
    DateTime? examDate,
    bool clearDate = false,
  }) =>
      SubjectExamPlan(
        subjectId: subjectId,
        rangeText: rangeText ?? this.rangeText,
        materials: materials ?? this.materials,
        existingSetIds: existingSetIds ?? this.existingSetIds,
        committeeSetIds: committeeSetIds ?? this.committeeSetIds,
        status: status ?? this.status,
        examDate: clearDate ? null : examDate ?? this.examDate,
      );

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        if (rangeText.isNotEmpty) 'rangeText': rangeText,
        if (materials.isNotEmpty)
          'materials': [for (final m in materials) m.toMap()],
        if (existingSetIds.isNotEmpty) 'existingSetIds': existingSetIds,
        if (committeeSetIds.isNotEmpty) 'committeeSetIds': committeeSetIds,
        'status': status.name,
        if (examDate != null) 'examDate': _date(examDate!),
      };

  factory SubjectExamPlan.fromMap(String subjectId, Map<String, dynamic> m) =>
      SubjectExamPlan(
        subjectId: subjectId,
        rangeText: _str(m['rangeText']),
        materials: [
          for (final x
              in m['materials'] is List ? m['materials'] as List : const [])
            if (x is Map) StudyMaterial.fromMap(Map<String, dynamic>.from(x)),
        ],
        existingSetIds: _strList(m['existingSetIds']),
        committeeSetIds: _strList(m['committeeSetIds']),
        status: RangeStatus.parse(m['status']),
        examDate: _parseDate(m['examDate']),
      );
}

/// 定期テスト1回ぶんの計画（例：1年後期中間試験）
class SchoolExamPlan {
  SchoolExamPlan({
    required this.id,
    required this.title,
    required this.createdAt,
    DateTime? updatedAt,
    this.examDate,
    Map<String, SubjectExamPlan> subjects = const {},
  })  : updatedAt = updatedAt ?? createdAt,
        subjects = Map.unmodifiable(subjects);

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? examDate;
  final Map<String, SubjectExamPlan> subjects;

  /// 科目の範囲（まだなければ空の範囲）
  SubjectExamPlan subject(String subjectId) =>
      subjects[subjectId] ?? SubjectExamPlan(subjectId: subjectId);

  /// 範囲・問題を登録した科目の数（11科目中）
  int get filledCount =>
      ShonanSubjects.all.where((s) => subject(s.id).isFilled).length;

  SchoolExamPlan copyWith({
    String? title,
    DateTime? examDate,
    bool clearDate = false,
    Map<String, SubjectExamPlan>? subjects,
    DateTime? updatedAt,
  }) =>
      SchoolExamPlan(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        examDate: clearDate ? null : examDate ?? this.examDate,
        subjects: subjects ?? this.subjects,
      );

  SchoolExamPlan withSubject(SubjectExamPlan s, {DateTime? now}) => copyWith(
        subjects: {...subjects, s.subjectId: s},
        updatedAt: now ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (examDate != null) 'examDate': _date(examDate!),
        'subjects': {for (final e in subjects.entries) e.key: e.value.toMap()},
      };

  /// 欠けた項目や古い形式があっても落ちないように読む
  factory SchoolExamPlan.fromMap(Map<String, dynamic> m) {
    final created = DateTime.tryParse(_str(m['createdAt'])) ?? DateTime(2026);
    final subjects = <String, SubjectExamPlan>{};
    final raw = m['subjects'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is Map) {
          final id = '${e.key}';
          subjects[id] = SubjectExamPlan.fromMap(
              id, Map<String, dynamic>.from(e.value as Map));
        }
      }
    }
    return SchoolExamPlan(
      id: _str(m['id']).isEmpty
          ? 'plan_${created.millisecondsSinceEpoch}'
          : _str(m['id']),
      title: _str(m['title']).isEmpty ? '（名前なしのテスト）' : _str(m['title']),
      createdAt: created,
      updatedAt: DateTime.tryParse(_str(m['updatedAt'])),
      examDate: _parseDate(m['examDate']),
      subjects: subjects,
    );
  }
}

String _str(Object? v) => v is String ? v : '';
List<String> _strList(Object? v) => [
      for (final x in v is List ? v : const [])
        if (x is String && x.isNotEmpty) x,
    ];
String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime? _parseDate(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// 演習で読めなかった問題セットとその理由
enum SetIssueReason {
  notFound('アプリに収録されていない（問題バンドルにない）'),
  wrongWorld('科目の教科と、問題セットの教科がちがう'),
  notUsable('出どころが original ではないので使えない'),
  invalid('問題データの形式が正しくない');

  const SetIssueReason(this.label);
  final String label;
}

class SetIssue {
  const SetIssue(this.setId, this.reason, [this.detail = '']);
  final String setId;
  final SetIssueReason reason;
  final String detail;

  @override
  String toString() =>
      '$setId：${reason.label}${detail.isEmpty ? '' : '（$detail）'}';
}

/// 科目の演習用に、既存セットと委員会セットをまとめた結果
class SchoolPractice {
  const SchoolPractice({
    required this.subject,
    required this.pool,
    required this.issues,
    required this.usedSetIds,
    required this.duplicateQuestionIds,
  });

  final SchoolSubject subject;

  /// 出題できる問題（読めるセットが1つもなければ null）
  final QuestionSet? pool;
  final List<SetIssue> issues;
  final List<String> usedSetIds;

  /// 別のセットにも同じ問題IDがあったもの（1回だけ出題する）
  final List<String> duplicateQuestionIds;

  bool get canPlay => pool != null;

  /// 科目に登録したセットを読み、検証してまとめる。
  ///
  /// [load] は setId から問題セットを返す（なければ null、壊れていれば例外）。
  static Future<SchoolPractice> build(
    SchoolSubject subject,
    SubjectExamPlan plan,
    Future<QuestionSet?> Function(String setId) load,
  ) async {
    final ids = <String>[];
    for (final id in [...plan.existingSetIds, ...plan.committeeSetIds]) {
      if (!ids.contains(id)) ids.add(id);
    }
    final issues = <SetIssue>[];
    final sets = <QuestionSet>[];
    for (final id in ids) {
      QuestionSet? set;
      try {
        set = await load(id);
      } catch (e) {
        issues.add(SetIssue(id, SetIssueReason.invalid, '$e'));
        continue;
      }
      if (set == null) {
        issues.add(SetIssue(id, SetIssueReason.notFound));
      } else if (set.worldId != subject.worldId) {
        issues.add(SetIssue(id, SetIssueReason.wrongWorld, set.worldId));
      } else if (!set.origin.usableInRpg) {
        issues.add(SetIssue(id, SetIssueReason.notUsable, set.origin.name));
      } else {
        sets.add(set);
      }
    }
    final seen = <String>{};
    final dups = <String>[];
    for (final s in sets) {
      for (final q in s.questions) {
        if (!seen.add(q.id)) dups.add(q.id);
      }
    }
    return SchoolPractice(
      subject: subject,
      pool: sets.isEmpty
          ? null
          : sets.length == 1
              ? sets.first
              : QuestionSet.merge('school_${subject.id}', sets),
      issues: issues,
      usedSetIds: [for (final s in sets) s.setId],
      duplicateQuestionIds: dups,
    );
  }
}
