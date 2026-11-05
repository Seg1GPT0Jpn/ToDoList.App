import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

/// 委員会の新作問題（setId に `_shonan_` を含むセット）と、全セット共通の決まりを確かめる。
/// 新作問題の追加手順は docs/SHONAN_EXAM_MODE.md。
void main() {
  final files = Directory('assets/questions')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
  final bundles = <String, Map<String, dynamic>>{};
  Map<String, dynamic> bundle(String world) => bundles[world] ??=
      jsonDecode(File('assets/question_bundles/$world.json').readAsStringSync())
          as Map<String, dynamic>;

  test('すべての問題セットは、setId の先頭・worldId・置き場所の教科が一致する', () {
    for (final f in files) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final world = f.parent.path.split(Platform.pathSeparator).last;
      expect(m['worldId'], world, reason: f.path);
      expect((m['setId'] as String).startsWith('${m['worldId']}_'), isTrue,
          reason: f.path);
    }
  });

  final school = [
    for (final f in files)
      if (f.path.contains('_shonan_')) f,
  ];

  test('委員会の新作セットは決まりどおり（${school.length}セット）', () {
    final seen = <String, String>{};
    for (final f in school) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final set = QuestionSet.fromJson(m);
      final where = f.path;
      expect(set.origin, QuestionOrigin.original, reason: where);
      expect(set.setId, f.uri.pathSegments.last.replaceAll('.json', ''),
          reason: where);
      // 問題バンドルに入っていないと、アプリで読めない
      expect(bundle(set.worldId).containsKey(set.setId), isTrue,
          reason: '$where がバンドルにありません（tool/bundle_questions.py を実行）');
      for (final q in set.questions) {
        expect(seen[q.id], isNull, reason: '問題ID ${q.id} が ${seen[q.id]} と重複');
        seen[q.id] = set.setId;
        expect(q.explanation?.trim(), isNotEmpty, reason: '${q.id} に解説がない');
        expect(q.prompt.trim(), isNotEmpty, reason: q.id);
      }
    }
  });

  test('範囲表に登録した問題セットは、その科目の教科のバンドルにある', () {
    var count = 0;
    for (final (sheet, _) in ShonanRangeTable.sheets) {
      final plan = ShonanRangeTable.plan(sheet, id: sheet, now: DateTime(2026));
      for (final sp in plan.subjects.values) {
        final subject = ShonanSubjects.byId(sp.subjectId)!;
        for (final id in [...sp.existingSetIds, ...sp.committeeSetIds]) {
          count++;
          expect(bundle(subject.worldId).containsKey(id), isTrue,
              reason: '$sheet ${sp.subjectId} $id');
        }
      }
    }
    expect(count, greaterThan(0));
  });

  test('後期中間の公共は、委員会の新作14セット（1033問）と既存の経済6セットで演習できる', () async {
    final plan = ShonanRangeTable.plan('後期中間試験', id: 'x', now: DateTime(2026));
    final r = await SchoolPractice.build(
      ShonanSubjects.byId('public_economy')!,
      plan.subject('public_economy'),
      (id) async {
        final m = bundle('social')[id];
        return m == null
            ? null
            : QuestionSet.fromJson(m as Map<String, dynamic>);
      },
    );
    expect(r.issues, isEmpty);
    expect(r.usedSetIds, hasLength(20));
    expect(r.pool!.questions, hasLength(1033 + 6 * 24));
  });

  test('範囲が未定の後期期末の化学基礎も、単元ごと（小単元ごと）に分けて対策できる', () async {
    final plan = ShonanRangeTable.plan('後期期末試験', id: 'x', now: DateTime(2026));
    final r = await SchoolPractice.build(
      ShonanSubjects.byId('chemistry_basic')!,
      plan.subject('chemistry_basic'),
      (id) async {
        final m = bundle('science')[id];
        return m == null
            ? null
            : QuestionSet.fromJson(m as Map<String, dynamic>);
      },
    );
    expect(r.issues, isEmpty);
    final groups = SchoolUnitGroup.of(r.pool!.questions);
    final ids = [for (final g in groups) g.id];
    expect(
        ids,
        containsAll([
          'science.chemistry.change.mole',
          'science.chemistry.change.equation',
          'science.chemistry.change.acid'
        ]));
    final acid =
        groups.firstWhere((g) => g.id == 'science.chemistry.change.acid');
    expect(
        [for (final p in acid.parts) p.id],
        containsAll([
          'science.chemistry.change.acid.define',
          'science.chemistry.change.acid.ph',
          'science.chemistry.change.acid.neutral',
          'science.chemistry.change.acid.salt',
        ]));
    expect(groups.fold(0, (n, g) => n + g.questions.length),
        r.pool!.questions.length);
  });

  test('範囲の問題セットがない科目でも、今年度の範囲表のセットで単元ごとに対策できる', () {
    final all = ShonanSubjectSets.allFor('public_economy');
    expect(
        all.committeeSetIds, contains('social_shonan_104_public_economy_14'));
    expect(ShonanSubjectSets.allFor('gendai_kokugo').hasSets, isTrue);
  });
}
