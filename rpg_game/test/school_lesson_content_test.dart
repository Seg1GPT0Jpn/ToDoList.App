import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

/// 授業の教材（assets/lessons/）を検査する。教材は tool/lessons/ で作る。
void main() {
  final files = Directory('assets/lessons')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
  final lessons = <String, List<SchoolLesson>>{
    for (final f in files)
      f.uri.pathSegments.last.replaceAll('.json', ''):
          SchoolLessons.parse(jsonDecode(f.readAsStringSync()) as List),
  };

  test(
      '教材ファイルは学校の科目ごとにあり、授業はすべて整備済み（${lessons.values.expand((l) => l).length}本）',
      () {
    expect(lessons, isNotEmpty);
    final ids = <String>{};
    for (final MapEntry(key: subject, value: list) in lessons.entries) {
      expect(ShonanSubjects.byId(subject), isNotNull, reason: subject);
      for (final l in list) {
        expect(l.subjectId, subject, reason: l.id);
        expect(ids.add(l.id), isTrue, reason: '${l.id} が重複');
        expect(l.problems(), isEmpty, reason: l.id);
        // 学習体系の単元（unit レベル）に対応している
        expect(
          Curriculum.ancestorAt(l.unitId, CurriculumLevel.unit)?.id,
          l.unitId,
          reason: l.id,
        );
        // 確認テスト・途中の問題の正解は選択肢の中にあり、解説がある
        for (final c in [...l.inlineChecks, ...l.quiz]) {
          expect(c.problems(), isEmpty, reason: '${l.id}: ${c.prompt}');
        }
        // 映像授業：はじめとおわりのあいさつと、説明ごとに先生の話が3つ以上
        expect(l.opening, isNotEmpty, reason: l.id);
        expect(l.closing, isNotEmpty, reason: l.id);
        for (final s in l.steps.where((s) => !s.isCheck)) {
          expect(s.talk.length, greaterThanOrEqualTo(3),
              reason: '${l.id}: ${s.heading}');
        }
        // 専門家の検証済みとは表示しない
        expect(l.review, 'unreviewed');
      }
    }
  });

  final bundles = <String, Map<String, dynamic>>{};
  QuestionSet? load(String world, String id) {
    final b = bundles[world] ??= jsonDecode(
            File('assets/question_bundles/$world.json').readAsStringSync())
        as Map<String, dynamic>;
    final m = b[id];
    return m == null ? null : QuestionSet.fromJson(m as Map<String, dynamic>);
  }

  test('後期の範囲表の科目は、範囲の全単元に授業があり、演習問題もそろっている', () {
    var units = 0;
    final missing = <String>[];
    for (final (sheet, _) in ShonanRangeTable.sheets) {
      if (!sheet.startsWith('後期')) continue;
      final plan = ShonanRangeTable.plan(sheet, id: sheet, now: DateTime(2026));
      for (final sp in plan.subjects.values) {
        if (!sp.hasSets) continue;
        final subject = ShonanSubjects.byId(sp.subjectId)!;
        final questions = [
          for (final id in [...sp.existingSetIds, ...sp.committeeSetIds])
            ...?load(subject.worldId, id)?.questions,
        ];
        final c = SubjectCoverage.build(
          questions: questions,
          lessons: SchoolLessons.byUnit(lessons[subject.id] ?? const []),
          records: const {},
          stats: const {},
        );
        units += c.total;
        missing.addAll([
          for (final u in c.missing)
            '$sheet ${subject.displayName}：${u.name}（${u.group.questions.length}問）',
        ]);
        expect(c.mastered, 0);
      }
    }
    expect(missing, isEmpty);
    expect(units, greaterThan(40));
  });
}
