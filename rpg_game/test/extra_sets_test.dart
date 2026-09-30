import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('追加問題のセットがすべて読み込める', () {
    final ids = <String>{};
    for (final s in ExtraSets.all) {
      final f = File('assets/questions/${s.subject}/${s.id}.json');
      final set = JsonQuestionSource.parse(f.readAsStringSync());
      expect(set.setId, s.id);
      expect(set.questions, isNotEmpty, reason: s.id);
      for (final q in set.questions) {
        expect(ids.add(q.id), isTrue, reason: q.id);
        expect(q.explanation, isNotEmpty, reason: q.id);
      }
    }
    expect(ids.length, 276);
  });
}
