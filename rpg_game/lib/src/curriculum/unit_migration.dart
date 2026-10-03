import '../data/question_source.dart';
import '../learning/learning_record.dart';
import '../models/question.dart';
import 'curriculum.dart';

/// 古い学習記録（単元が書かれていない記録）に、学習体系の単元を補う。
///
/// 記録には問題 ID と問題セット ID しかないので、問題セットを読み込んで
/// 問題の "unit" を調べる。読めないセット（個人用単語帳など）は飛ばす。
abstract final class UnitMigration {
  /// 単元を補った記録を返す（補うものがなければ [record] をそのまま返す）
  static Future<LearningRecord> run(
    LearningRecord record,
    QuestionSource source,
  ) async =>
      record.withUnits(await unitsFor(record, source));

  /// 単元が空の記録について、問題 ID → 単元 の対応を調べる。
  /// 調べている間に記録が増えてもよいように、対応だけを返す
  /// （呼び出す側が最新の記録に [LearningRecord.withUnits] で当てる）。
  static Future<Map<String, String>> unitsFor(
    LearningRecord record,
    QuestionSource source,
  ) async {
    final missing = record.missingUnits.toList();
    if (missing.isEmpty) return const {};
    final bySet = <String, List<String>>{};
    for (final id in missing) {
      final setId = record[id]!.setId;
      if (setId.isEmpty) continue;
      bySet.putIfAbsent(setId, () => []).add(id);
    }
    final unitOf = <String, String>{};
    for (final e in bySet.entries) {
      final generated = Curriculum.unitForGeneratedSet(e.key);
      if (generated != null) {
        for (final id in e.value) {
          unitOf[id] = generated;
        }
        continue;
      }
      final set = await _tryLoad(source, e.key);
      if (set == null) continue;
      final units = {
        for (final q in set.questions)
          if (q.unit != null) q.id: q.unit!,
      };
      for (final id in e.value) {
        final u = units[id];
        if (u != null) unitOf[id] = u;
      }
    }
    return unitOf;
  }

  static Future<QuestionSet?> _tryLoad(
      QuestionSource source, String setId) async {
    try {
      return await source.load(setId);
    } catch (_) {
      return null;
    }
  }
}
