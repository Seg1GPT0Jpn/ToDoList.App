import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game/src/generated/gen_core.dart';
import 'package:rpg_game/src/generated/generated_sets.dart';
import 'package:test/test.dart';

/// すべての問題ファイル
List<QuestionSet> _allSets() => [
      for (final f in Directory('assets/questions')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json')))
        JsonQuestionSource.parse(f.readAsStringSync()),
    ];

final _bad = RegExp(r'NaN|null|Infinity|\+−|−−|\+\+|\+\-|\-\-|\^\(\)|\(\)|−0(?![.\d×/])|[×−+]−\d');

void main() {
  test('足した問題は、4択の形がととのい、変な表記がない。毎回同じ問題になる', () {
    final sets = _allSets();
    var before = 0, after = 0;
    final bySubject = <String, (int, int)>{};
    for (final s in sets) {
      final a = GeneratedSets.augment(s);
      final b = GeneratedSets.augment(s);
      expect(a.questions.map((q) => q.prompt), b.questions.map((q) => q.prompt));
      before += s.questions.length;
      after += a.questions.length;
      final (x, y) = bySubject[s.worldId] ?? (0, 0);
      bySubject[s.worldId] = (x + s.questions.length, y + a.questions.length);
      final prompts = <String>{};
      for (final q in a.questions.skip(s.questions.length)) {
        expect(prompts.add(q.prompt), isTrue, reason: '${q.id} 問題文が重複');
        expect(q.choices, hasLength(4));
        for (final c in [q.prompt, ...q.choices, q.explanation ?? '']) {
          expect(_bad.hasMatch(c), isFalse, reason: '${q.id}: $c');
          expect(c.trim(), isNotEmpty, reason: q.id);
        }
        expect(q.tags, contains('generated'));
        // マイナスは「−」で書く（プログラムの問題は除く）
        if (!q.prompt.contains('print(') && !q.prompt.contains('def ')) {
          for (final c in [q.prompt, ...q.choices]) {
            expect(RegExp(r'(^|[^A-Za-z/])-\d').hasMatch(c), isFalse, reason: '${q.id}: $c');
          }
        }
      }
    }
    // ignore: avoid_print
    print('合計 $before → $after');
    // ignore: avoid_print
    bySubject.forEach((k, v) => print('$k ${v.$1} → ${v.$2}'));
  });

  test('作り方ごとに見本を出す（目で確かめる用）', () {
    final out = StringBuffer();
    for (final e in GeneratedSets.byUnit.entries) {
      final r = Random(7);
      for (final g in e.value) {
        for (var i = 0; i < 2; i++) {
          final q = g(r);
          if (q == null) continue;
          out.writeln('[${e.key}] ${q.prompt} → ${q.answer}  ×${q.wrong.take(3).join(' / ')}  // ${q.explanation}');
        }
      }
    }
    File('${Directory.systemTemp.path}/gen_samples.txt').writeAsStringSync(out.toString());
  });
}
