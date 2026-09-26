import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';

/// enemy_painter.dart で描ける見た目
const knownLooks = {
  'slime', 'goblin', 'bat', 'golem', 'knight', 'dragon', 'ghost', //
  'eraser', 'crayon', 'sticky', 'pencil', 'stubpencil', 'pen', 'ruler',
  'triangle', 'protractor', 'compass', 'stapler', 'marker', 'page',
  'mechpencil', 'scissors', 'binder', 'book',
};

void main() {
  for (final w in RpgCatalog.worlds.where((w) => w.stages.isNotEmpty)) {
    test('${w.name}：敵の見た目はすべて描けるもので、となりのエリアと同じにならない', () {
      final byBranch = <String, List<StageDef>>{};
      for (final s in w.stages) {
        expect(knownLooks, contains(s.enemy.look), reason: s.enemy.name);
        byBranch.putIfAbsent(s.branch, () => []).add(s);
      }
      for (final stages in byBranch.values) {
        for (var i = 1; i < stages.length; i++) {
          expect(
            stages[i].enemy.look,
            isNot(stages[i - 1].enemy.look),
            reason: '${stages[i - 1].enemy.name} と ${stages[i].enemy.name}',
          );
        }
        // 1つの道で同じ見た目は3体まで
        final counts = <String, int>{};
        for (final s in stages) {
          counts[s.enemy.look] = (counts[s.enemy.look] ?? 0) + 1;
        }
        expect(counts.values.every((n) => n <= 3), isTrue, reason: '$counts');
      }
    });
  }
}
