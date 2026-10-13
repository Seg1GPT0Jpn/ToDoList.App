import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rpg_game_app/study/shonan_exam_store.dart';

void main() {
  group('湘南高校向け定期テスト管理', () {
    test('11科目が安定したIDで定義されている', () {
      expect(ShonanExamSubjectDefinition.all, hasLength(11));
      expect(
        ShonanExamSubjectDefinition.all.map((s) => s.id).toSet(),
        hasLength(11),
      );
      expect(
        ShonanExamSubjectDefinition.find('chemistry_basic')!.worldId,
        'science',
      );
      expect(
        ShonanExamSubjectDefinition.find('math_a')!.name,
        contains('数学A'),
      );
    });

    test('既存問題と新作問題のIDを個別保持し、演習時には重複を除いてまとめる', () {
      final subject = ShonanSubjectExamPlan(
        subjectId: 'chemistry_basic',
        rangeText: '教科書 P.82～119',
        materialsText: '教科書・授業プリント',
        existingSetIdsText: 'science_chem_basic_01、science_chem_basic_01',
        committeeSetIdsText: 'science_shonan_104_chem_01; science_shonan_104_chem_02',
      );

      expect(subject.existingSetIds, ['science_chem_basic_01']);
      expect(
        subject.committeeSetIds,
        ['science_shonan_104_chem_01', 'science_shonan_104_chem_02'],
      );
      expect(subject.allSetIds, [
        'science_chem_basic_01',
        'science_shonan_104_chem_01',
        'science_shonan_104_chem_02',
      ]);
    });

    test('試験計画を保存形式に変換しても内容が保持される', () {
      final plan = ShonanExamPlan(
        id: 'test-1',
        title: '後期中間試験',
        createdAt: DateTime(2026, 10, 13),
        examDate: DateTime(2026, 11, 10),
        subjects: {
          'chemistry_basic': const ShonanSubjectExamPlan(
            subjectId: 'chemistry_basic',
            rangeText: '教科書 P.82～119',
            existingSetIdsText: 'science_chem_basic_01',
            committeeSetIdsText: 'science_shonan_104_chem_01',
          ),
        },
      );

      final restored = ShonanExamPlan.fromMap(plan.toMap());
      expect(restored.id, plan.id);
      expect(restored.title, plan.title);
      expect(restored.examDate, plan.examDate);
      expect(restored.subject('chemistry_basic').rangeText, '教科書 P.82～119');
      expect(
        restored.subject('chemistry_basic').existingSetIds,
        ['science_chem_basic_01'],
      );
      expect(
        restored.subject('chemistry_basic').committeeSetIds,
        ['science_shonan_104_chem_01'],
      );
      expect(restored.subjects, hasLength(11));
    });

    test('試験計画を追加・更新・取得・削除できる', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ShonanExamStore(await SharedPreferences.getInstance());
      final plan = ShonanExamPlan(
        id: 'a',
        title: '中間試験',
        createdAt: DateTime(2026, 10, 13),
        subjects: {
          for (final s in ShonanExamSubjectDefinition.all)
            s.id: ShonanSubjectExamPlan(subjectId: s.id),
        },
      );

      await store.add(plan);
      expect(store.load().single.title, '中間試験');

      final updated = ShonanExamPlan(
        id: plan.id,
        title: '後期中間試験',
        createdAt: plan.createdAt,
        examDate: DateTime(2026, 11, 10),
        subjects: plan.subjects,
      );
      await store.update(updated);
      expect(store.byId('a')!.title, '後期中間試験');

      await store.remove('a');
      expect(store.load(), isEmpty);
    });
  });
}
