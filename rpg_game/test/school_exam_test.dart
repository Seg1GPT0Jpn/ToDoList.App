import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

/// テスト用の小さな問題セット（test/fixtures/school_mock_sets.json）
Map<String, QuestionSet> _mockSets() => {
      for (final m in jsonDecode(
              File('test/fixtures/school_mock_sets.json').readAsStringSync())
          as List)
        (m as Map<String, dynamic>)['setId'] as String: QuestionSet.fromJson(m),
    };

Future<QuestionSet?> Function(String) _loader(Map<String, QuestionSet> sets) =>
    (id) async {
      if (id == 'social_broken_01') throw const FormatException('JSON が壊れています');
      return sets[id];
    };

void main() {
  final public = ShonanSubjects.byId('public_economy')!;

  group('11科目', () {
    test('11科目が重複なく定義され、教科は既存の6つのどれか', () {
      expect(ShonanSubjects.all, hasLength(11));
      expect(ShonanSubjects.all.map((s) => s.id).toSet(), hasLength(11));
      expect(
          ShonanSubjects.all.map((s) => s.displayName).toSet(), hasLength(11));
      for (final s in ShonanSubjects.all) {
        expect(RpgCatalog.worlds.map((w) => w.id), contains(s.worldId),
            reason: s.id);
      }
    });
  });

  group('試験計画の保存', () {
    test('保存して読み直しても、範囲・試験日・教材・セットIDが残る', () {
      final now = DateTime(2026, 10, 13, 9);
      final plan = SchoolExamPlan(
        id: 'p1',
        title: '1年後期中間試験',
        createdAt: now,
        examDate: DateTime(2026, 11, 24),
      ).withSubject(
        const SubjectExamPlan(
          subjectId: 'public_economy',
          rangeText: '第4章4〜6・第6章',
          materials: [
            StudyMaterial(kind: '教科書', name: '教科書', range: 'P.203~289')
          ],
          existingSetIds: ['social_mock_existing_01'],
          committeeSetIds: ['social_shonan_104_mock_01'],
          status: RangeStatus.confirmed,
        ),
        now: now,
      );
      final again = SchoolExamPlan.fromMap(
        jsonDecode(jsonEncode(plan.toMap())) as Map<String, dynamic>,
      );
      final s = again.subject('public_economy');
      expect(again.title, '1年後期中間試験');
      expect(again.examDate, DateTime(2026, 11, 24));
      expect(s.rangeText, '第4章4〜6・第6章');
      expect(s.materials.single.range, 'P.203~289');
      expect(s.existingSetIds, ['social_mock_existing_01']);
      expect(s.committeeSetIds, ['social_shonan_104_mock_01']);
      expect(s.status, RangeStatus.confirmed);
      expect(again.filledCount, 1);
    });

    test('試験日なし・範囲なし・欠けた項目・古い形式でも落ちない', () {
      final p = SchoolExamPlan.fromMap({
        'subjects': {
          'math1': {'status': 'unknownStatus', 'materials': 'こわれた値'},
          'ec1': 3,
        },
      });
      expect(p.title, isNotEmpty);
      expect(p.examDate, isNull);
      expect(p.subject('math1').status, RangeStatus.empty);
      expect(p.subject('math1').materials, isEmpty);
      expect(p.subject('ec1').isFilled, isFalse);
      expect(p.filledCount, 0);
    });
  });

  group('範囲表（Excel）からの取り込み', () {
    test('後期中間の公共は教科書・資料集・プリントの範囲が入る', () {
      final p = ShonanRangeTable.plan(
        '後期中間試験',
        id: 'x',
        now: DateTime(2026, 10, 13),
      );
      expect(p.title, '1年後期中間試験');
      final s = p.subject('public_economy');
      expect(s.status, RangeStatus.entered);
      expect(s.materials.map((m) => m.range),
          containsAll(['P.203~289', 'P.250~332', '冊子No.3すべて']));
      // 範囲表で空欄の科目は未入力のまま（推測で埋めない）
      expect(p.subject('biology_basic').status, RangeStatus.empty);
      expect(p.subject('biology_basic').hasRange, isFalse);
    });

    test('前に作ったテストに、範囲表の問題セットを足せる（消さない・二度足さない）', () {
      final old = SchoolExamPlan(
        id: 'old',
        title: '1年後期中間試験',
        createdAt: DateTime(2026, 10, 1),
        subjects: const {
          'math1': SubjectExamPlan(
              subjectId: 'math1', existingSetIds: ['math_m1_01']),
        },
      );
      expect(ShonanTableSets.missing(old), greaterThan(0));
      final p = ShonanTableSets.addTo(old, now: DateTime(2026, 10, 18));
      expect(p.subject('math1').existingSetIds,
          containsAll(['math_m1_01', 'math_m1_16', 'math_m2_04']));
      expect(p.subject('math1').committeeSetIds,
          contains('math_shonan_104_m1_data_01'));
      expect(ShonanTableSets.missing(p), 0);
      expect(ShonanTableSets.addTo(p, now: DateTime(2026, 10, 18)).toMap(),
          p.toMap());
      // 範囲表から作っていないテストは変えない
      final mine = old.copyWith(title: '自分のテスト');
      expect(ShonanTableSets.missing(mine), 0);
      expect(identical(ShonanTableSets.addTo(mine, now: DateTime(2026)), mine),
          isTrue);
    });

    test('範囲表の科目はすべて11科目のどれか', () {
      for (final (sheet, _) in ShonanRangeTable.sheets) {
        final p = ShonanRangeTable.plan(sheet, id: sheet, now: DateTime(2026));
        for (final id in p.subjects.keys) {
          expect(ShonanSubjects.byId(id), isNotNull, reason: '$sheet: $id');
        }
      }
    });
  });

  group('問題セットをまとめて演習', () {
    final sets = _mockSets();

    test('既存セットだけで演習できる', () async {
      final r = await SchoolPractice.build(
        public,
        const SubjectExamPlan(
            subjectId: 'public_economy',
            existingSetIds: ['social_mock_existing_01']),
        _loader(sets),
      );
      expect(r.canPlay, isTrue);
      expect(r.pool!.questions, hasLength(3));
      expect(r.issues, isEmpty);
    });

    test('新作セットだけで演習できる', () async {
      final r = await SchoolPractice.build(
        public,
        const SubjectExamPlan(
            subjectId: 'public_economy',
            committeeSetIds: ['social_shonan_104_mock_01']),
        _loader(sets),
      );
      expect(r.pool!.questions.map((q) => q.id), ['mock_c_1', 'mock_shared_1']);
    });

    test('既存＋新作を混ぜても、同じセット・同じ問題は1回だけ', () async {
      final r = await SchoolPractice.build(
        public,
        const SubjectExamPlan(
          subjectId: 'public_economy',
          existingSetIds: [
            'social_mock_existing_01',
            'social_mock_existing_01'
          ],
          committeeSetIds: ['social_shonan_104_mock_01'],
        ),
        _loader(sets),
      );
      final ids = r.pool!.questions.map((q) => q.id).toList();
      expect(ids,
          containsAll(['mock_e_1', 'mock_e_2', 'mock_c_1', 'mock_shared_1']));
      expect(ids.toSet(), hasLength(ids.length));
      expect(r.usedSetIds,
          ['social_mock_existing_01', 'social_shonan_104_mock_01']);
      expect(r.duplicateQuestionIds, ['mock_shared_1']);
    });

    test('未収録・別の教科・使えない出どころ・壊れたデータは理由つきで除く', () async {
      final r = await SchoolPractice.build(
        public,
        const SubjectExamPlan(
          subjectId: 'public_economy',
          existingSetIds: [
            'social_mock_existing_01',
            'social_nothing_99',
            'science_mock_01'
          ],
          committeeSetIds: ['social_mock_user_01', 'social_broken_01'],
        ),
        _loader(sets),
      );
      expect(r.canPlay, isTrue);
      expect({
        for (final i in r.issues) i.setId: i.reason
      }, {
        'social_nothing_99': SetIssueReason.notFound,
        'science_mock_01': SetIssueReason.wrongWorld,
        'social_mock_user_01': SetIssueReason.notUsable,
        'social_broken_01': SetIssueReason.invalid,
      });
    });

    test('読めるセットが0なら演習できない（落ちない）', () async {
      final r = await SchoolPractice.build(
        public,
        const SubjectExamPlan(
            subjectId: 'public_economy',
            committeeSetIds: ['social_nothing_99']),
        _loader(sets),
      );
      expect(r.canPlay, isFalse);
      expect(r.issues.single.reason, SetIssueReason.notFound);
      final none = await SchoolPractice.build(
        public,
        const SubjectExamPlan(subjectId: 'public_economy'),
        _loader(sets),
      );
      expect(none.canPlay, isFalse);
      expect(none.issues, isEmpty);
    });
  });
}
