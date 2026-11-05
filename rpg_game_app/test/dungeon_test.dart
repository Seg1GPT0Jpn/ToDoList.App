import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/field/field_game.dart';
import 'package:rpg_game_app/field/field_map.dart';
import 'package:rpg_game_app/field/field_screen.dart';

import 'harness.dart';

/// [from] から歩いて行けるマス（洞くつの主のマスも、たおせば通れるので通れることにする）
Set<Cell> _reach(FieldMap m, Cell from) {
  final seen = {from};
  final q = [from];
  for (var i = 0; i < q.length; i++) {
    final c = q[i];
    for (final (dc, dr) in const [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
      final n = (col: c.col + dc, row: c.row + dr);
      if (seen.contains(n)) continue;
      if (!m.isFloor(n.col, n.row)) continue;
      seen.add(n);
      q.add(n);
    }
  }
  return seen;
}

bool _beside(Set<Cell> reach, Cell c) => [
  (0, 1),
  (0, -1),
  (1, 0),
  (-1, 0),
].any((d) => reach.contains((col: c.col + d.$1, row: c.row + d.$2)));

void main() {
  final ids = [
    'english',
    for (final w in RpgCatalog.worlds)
      if (w.id != RpgCatalog.englishWorldId)
        for (final r in w.routes) '${w.id}_${r.id}',
  ];

  test('寄り道の洞くつ：いくつかのエリアに入口があり、中の宝箱・泉・主・出口に歩いて行ける', () {
    var dungeons = 0;
    for (final id in ids) {
      final parent = FieldMap.byId(id);
      for (final e in parent.portals.entries) {
        if (!e.value.target.contains('~dg')) continue;
        dungeons++;
        // 入口のとなりは床
        expect(
          parent.floorNextTo(e.key),
          isNotNull,
          reason: '${e.value.target} の入口',
        );
        final d = FieldMap.byId(e.value.target);
        expect(d.dungeonOf, isNotNull);
        final exit = d.portals.entries.single;
        expect(exit.value.target, id, reason: '出口は、もとのマップへ');
        final reach = _reach(d, d.floorNextTo(exit.key)!);
        final boss = d.findAll('M');
        expect(boss, hasLength(1), reason: e.value.target);
        expect(reach.contains(boss.single), isTrue, reason: e.value.target);
        final kinds = d.chestKinds.values.toSet();
        expect(kinds, contains(ChestKind.cave2), reason: e.value.target);
        for (final c in d.findAll('C')) {
          expect(_beside(reach, c), isTrue, reason: '${e.value.target} 宝箱 $c');
        }
        for (final ch in const ['W', 'N']) {
          for (final c in d.findAll(ch)) {
            expect(_beside(reach, c), isTrue, reason: '${e.value.target} $ch');
          }
        }
        // 奥の宝箱は、主をたおさないと取れない（主のマスをふさぐと届かない）
        final deep = d.chestKinds.entries
            .firstWhere((x) => x.value == ChestKind.cave2)
            .key;
        final without = reach.difference({boss.single});
        final blocked = [(0, 1), (0, -1), (1, 0), (-1, 0)].any(
          (x) => without.contains((col: deep.col + x.$1, row: deep.row + x.$2)),
        );
        expect(blocked, isFalse, reason: '${e.value.target} 奥の宝箱');
      }
    }
    expect(dungeons, greaterThan(20));
  });

  testWidgets('洞くつに入ると、出口のとなりに立ち、奥には洞くつの主がいる', (t) async {
    final english = RpgCatalog.world(RpgCatalog.englishWorldId);
    final parent = FieldMap.byId('english');
    final cave = parent.portals.values
        .firstWhere((p) => p.target.contains('~dg'))
        .target;
    await openScreen(
      t,
      FieldScreen(
        world: english,
        progress: RpgProgress.initial,
        mapId: cave,
        from: 'english',
      ),
      frames: 20,
    );
    final g = t
        .widget<GameWidget<FieldGame>>(
          find.byWidgetPredicate((w) => w is GameWidget<FieldGame>),
        )
        .game!;
    final exit = g.map.portals.keys.single;
    expect(
      (g.player.cell.col - exit.col).abs() +
          (g.player.cell.row - exit.row).abs(),
      1,
    );
    final bosses = g.world.children.whereType<EnemyToken>().where(
      (e) => CaveBoss.isCaveBoss(e.stage.id),
    );
    expect(bosses, hasLength(1));
    expect(find.textContaining('洞くつ'), findsWidgets);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });
}
