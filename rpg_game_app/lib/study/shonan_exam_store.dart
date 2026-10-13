import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 湘南高校104回生の定期テスト対策で扱う11科目。
///
/// worldId は既存の問題バンドル（英語・数学・国語・理科・社会・情報）との接続先。
/// 学校科目の区分はこの一覧で管理し、通常のRPGワールド定義を変更しない。
class ShonanExamSubjectDefinition {
  const ShonanExamSubjectDefinition({
    required this.id,
    required this.category,
    required this.name,
    required this.worldId,
  });

  final String id;
  final String category;
  final String name;
  final String worldId;

  static const all = <ShonanExamSubjectDefinition>[
    ShonanExamSubjectDefinition(
      id: 'gendai_kokugo',
      category: '国語',
      name: '現代の国語（現代文）',
      worldId: 'japanese',
    ),
    ShonanExamSubjectDefinition(
      id: 'gengo_bunka',
      category: '国語',
      name: '言語文化（古文・漢文）',
      worldId: 'japanese',
    ),
    ShonanExamSubjectDefinition(
      id: 'math1',
      category: '数学',
      name: '数学Ⅰ（数学Ⅰ・Ⅱ）',
      worldId: 'math',
    ),
    ShonanExamSubjectDefinition(
      id: 'math_a',
      category: '数学',
      name: '数学A（数学A）',
      worldId: 'math',
    ),
    ShonanExamSubjectDefinition(
      id: 'ec1',
      category: '英語',
      name: 'ECⅠ（English Communication Ⅰ：総合）',
      worldId: 'english',
    ),
    ShonanExamSubjectDefinition(
      id: 'ronhyo1',
      category: '英語',
      name: '論表Ⅰ（Logic and Expression Ⅰ：文法）',
      worldId: 'english',
    ),
    ShonanExamSubjectDefinition(
      id: 'chemistry_basic',
      category: '理科',
      name: '化学基礎',
      worldId: 'science',
    ),
    ShonanExamSubjectDefinition(
      id: 'biology_basic',
      category: '理科',
      name: '生物基礎',
      worldId: 'science',
    ),
    ShonanExamSubjectDefinition(
      id: 'geography_general',
      category: '社会',
      name: '地理総合',
      worldId: 'social',
    ),
    ShonanExamSubjectDefinition(
      id: 'public_economy',
      category: '社会',
      name: '公共（政治経済の経済分野）',
      worldId: 'social',
    ),
    ShonanExamSubjectDefinition(
      id: 'information1',
      category: '情報',
      name: '情報Ⅰ',
      worldId: 'information',
    ),
  ];

  static ShonanExamSubjectDefinition? find(String id) {
    for (final subject in all) {
      if (subject.id == id) return subject;
    }
    return null;
  }
}

/// 1科目分の試験範囲と、演習に使う問題セットID。
///
/// 既存問題セットと委員会の新作問題セットを別々に保持する。
/// セットIDはカンマ・読点・改行などで区切って入力できる。
class ShonanSubjectExamPlan {
  const ShonanSubjectExamPlan({
    required this.subjectId,
    this.rangeText = '',
    this.materialsText = '',
    this.existingSetIdsText = '',
    this.committeeSetIdsText = '',
  });

  final String subjectId;
  final String rangeText;
  final String materialsText;
  final String existingSetIdsText;
  final String committeeSetIdsText;

  List<String> get existingSetIds => _parseIds(existingSetIdsText);
  List<String> get committeeSetIds => _parseIds(committeeSetIdsText);

  List<String> get allSetIds => [
        ...existingSetIds,
        ...committeeSetIds,
      ].toSet().toList();

  static List<String> _parseIds(String text) => text
      .split(RegExp(r'[,，、;；\n\r]+'))
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        'rangeText': rangeText,
        'materialsText': materialsText,
        'existingSetIdsText': existingSetIdsText,
        'committeeSetIdsText': committeeSetIdsText,
      };

  factory ShonanSubjectExamPlan.fromMap(Map<String, dynamic> map) =>
      ShonanSubjectExamPlan(
        subjectId: map['subjectId'] as String? ?? '',
        rangeText: map['rangeText'] as String? ?? '',
        materialsText: map['materialsText'] as String? ?? '',
        existingSetIdsText: map['existingSetIdsText'] as String? ?? '',
        committeeSetIdsText: map['committeeSetIdsText'] as String? ?? '',
      );
}

/// 1回分の湘南高校定期テスト計画。
class ShonanExamPlan {
  const ShonanExamPlan({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.subjects,
    this.examDate,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? examDate;
  final Map<String, ShonanSubjectExamPlan> subjects;

  ShonanSubjectExamPlan subject(String subjectId) =>
      subjects[subjectId] ?? ShonanSubjectExamPlan(subjectId: subjectId);

  int get configuredSubjectCount => subjects.values
      .where((s) => s.rangeText.trim().isNotEmpty || s.allSetIds.isNotEmpty)
      .length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        if (examDate != null) 'examDate': examDate!.toIso8601String(),
        'subjects': {
          for (final entry in subjects.entries)
            entry.key: entry.value.toMap(),
        },
      };

  factory ShonanExamPlan.fromMap(Map<String, dynamic> map) {
    final rawSubjects = map['subjects'];
    final decodedSubjects = <String, ShonanSubjectExamPlan>{};
    if (rawSubjects is Map) {
      for (final entry in rawSubjects.entries) {
        if (entry.value is Map) {
          decodedSubjects[entry.key.toString()] =
              ShonanSubjectExamPlan.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    // 将来科目が追加されたり古い保存データが欠けていたりしても、
    // 現在の11科目を画面で扱えるように空の計画を補う。
    for (final subject in ShonanExamSubjectDefinition.all) {
      decodedSubjects.putIfAbsent(
        subject.id,
        () => ShonanSubjectExamPlan(subjectId: subject.id),
      );
    }

    return ShonanExamPlan(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '定期テスト',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime(2000),
      examDate: DateTime.tryParse(map['examDate'] as String? ?? ''),
      subjects: decodedSubjects,
    );
  }
}

/// 湘南高校向けの試験計画を端末内に保存する。
///
/// 既存の ExamWorldStore とは分離し、現在の一般向け機能への影響を避ける。
class ShonanExamStore {
  ShonanExamStore(this._prefs);

  static const _key = 'shonan_exam_plans_v1';

  final SharedPreferences _prefs;
  final StreamController<List<ShonanExamPlan>> _controller =
      StreamController<List<ShonanExamPlan>>.broadcast();

  List<ShonanExamPlan> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            ShonanExamPlan.fromMap(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Stream<List<ShonanExamPlan>> watch() async* {
    yield load();
    yield* _controller.stream;
  }

  Future<void> _write(List<ShonanExamPlan> plans) async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final plan in plans) plan.toMap()]),
    );
    _controller.add(plans);
  }

  Future<void> add(ShonanExamPlan plan) => _write([plan, ...load()]);

  Future<void> update(ShonanExamPlan plan) => _write([
        for (final current in load()) current.id == plan.id ? plan : current,
      ]);

  Future<void> remove(String id) => _write([
        for (final plan in load())
          if (plan.id != id) plan,
      ]);

  ShonanExamPlan? byId(String id) {
    for (final plan in load()) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}
