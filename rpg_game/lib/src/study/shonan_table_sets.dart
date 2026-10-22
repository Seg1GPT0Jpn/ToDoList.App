import 'school_exam.dart';
import 'shonan_range_table.dart';

/// 範囲表から作ったテストに、あとから範囲表に足された問題セットを入れる。
///
/// 前に「範囲表から作る」で作ったテストは端末に保存されているので、
/// 範囲表の問題セットが増えても自動では変わらない。足すだけで、消さない。
abstract final class ShonanTableSets {
  /// テスト名から範囲表のシートを探す（範囲表から作ったテストでなければ null）
  static String? sheetOf(SchoolExamPlan plan) {
    for (final (sheet, title) in ShonanRangeTable.sheets) {
      if (plan.title == title) return sheet;
    }
    return null;
  }

  /// まだ入っていない範囲表の問題セットの数
  static int missing(SchoolExamPlan plan) {
    final sheet = sheetOf(plan);
    if (sheet == null) return 0;
    final table = ShonanRangeTable.plan(sheet, id: '', now: DateTime(2026));
    var n = 0;
    for (final t in table.subjects.values) {
      final s = plan.subject(t.subjectId);
      n += t.existingSetIds.where((x) => !s.existingSetIds.contains(x)).length;
      n +=
          t.committeeSetIds.where((x) => !s.committeeSetIds.contains(x)).length;
    }
    return n;
  }

  /// 範囲表の問題セットを足したテスト
  static SchoolExamPlan addTo(SchoolExamPlan plan, {required DateTime now}) {
    final sheet = sheetOf(plan);
    if (sheet == null) return plan;
    final table = ShonanRangeTable.plan(sheet, id: '', now: now);
    var out = plan;
    for (final t in table.subjects.values) {
      final s = out.subject(t.subjectId);
      final ex = [
        ...s.existingSetIds,
        ...t.existingSetIds.where((x) => !s.existingSetIds.contains(x)),
      ];
      final cm = [
        ...s.committeeSetIds,
        ...t.committeeSetIds.where((x) => !s.committeeSetIds.contains(x)),
      ];
      if (ex.length == s.existingSetIds.length &&
          cm.length == s.committeeSetIds.length) {
        continue;
      }
      out = out.withSubject(s.copyWith(existingSetIds: ex, committeeSetIds: cm),
          now: now);
    }
    return out;
  }
}

/// 範囲表のすべての試験に入っている、その科目の問題セット（範囲が未定のテストで単元ごとに対策するため）
abstract final class ShonanSubjectSets {
  static SubjectExamPlan allFor(String subjectId) {
    final existing = <String>[];
    final committee = <String>[];
    for (final (sheet, _) in ShonanRangeTable.sheets) {
      final s = ShonanRangeTable.plan(sheet, id: '', now: DateTime(2026))
          .subject(subjectId);
      existing.addAll(s.existingSetIds.where((x) => !existing.contains(x)));
      committee.addAll(s.committeeSetIds.where((x) => !committee.contains(x)));
    }
    return SubjectExamPlan(
      subjectId: subjectId,
      existingSetIds: existing,
      committeeSetIds: committee,
    );
  }
}
