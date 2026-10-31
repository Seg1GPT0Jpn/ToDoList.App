import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// 社会・国語・数学・情報（ルート制のワールド）に共通するチェック
void main() {
  final worlds = RpgCatalog.worlds
      .where((w) => w.routes.isNotEmpty && w.id != ScienceCatalog.worldId)
      .toList();

  test('ルート制のワールドがある', () => expect(worlds, isNotEmpty));

  for (final world in worlds) {
    group(world.name, () {
      test('ルートは1〜8本、1本20エリアまで。ハブの1辺に出入口は2つまで', () {
        expect(world.routes.length, inInclusiveRange(1, 8));
        for (final r in world.routes) {
          final n = world.stages.where((s) => s.branch == r.id).length;
          expect(n, inInclusiveRange(4, 20), reason: r.id);
        }
        for (final dir in ['up', 'left', 'right', 'down']) {
          expect(
            world.routes.where((r) => r.direction == dir).length,
            lessThanOrEqualTo(2),
          );
        }
        if (world.routes.length > 1) expect(world.hubName, isNotEmpty);
      });

      test('並び順は通し番号で、各ルートの最後はボス', () {
        expect([for (final s in world.stages) s.order],
            [for (var i = 1; i <= world.stages.length; i++) i]);
        for (final r in world.routes) {
          final stages = world.stages.where((s) => s.branch == r.id).toList();
          expect(stages.last.isBoss, isTrue, reason: r.id);
          expect([for (final s in stages) s.areaNo],
              [for (var i = 1; i <= stages.length; i++) i]);
        }
      });

      final ids = <String>{};
      for (final s in world.stages) {
        final setId = s.questionSetIds.last;
        test('$setId：自作・4択・解説つき', () {
          final set = loadSet(setId);
          expect(set.setId, setId);
          expect(set.origin, QuestionOrigin.original);
          expect(set.questions.length, inInclusiveRange(10, 40));
          for (final q in set.questions) {
            expect(q.choices.length, 4, reason: q.id);
            expect(q.choices.toSet().length, 4, reason: q.id);
            expect(q.explanation, isNotEmpty, reason: q.id);
            expect(
              [
                QuestionCategory.knowledge,
                QuestionCategory.calculation,
                QuestionCategory.thinking,
              ],
              contains(q.category),
            );
            expect(ids.add(q.id), isTrue, reason: '重複ID ${q.id}');
          }
          expect(s.enemy.introLine, isNotEmpty);
          expect(s.enemy.defeatLine, isNotEmpty);
        });
      }

      test('ボスの装甲を割れる種類の問題が十分にある', () {
        for (final s in world.stages.where((s) => s.isBoss)) {
          final pool = loadStagePool(s).questions;
          final n = pool.where((q) => q.category == s.enemy.armorCategory);
          expect(n.length, greaterThan(s.enemy.armor * 4), reason: s.id);
        }
      });

      test('正解の位置がかたよっていない', () {
        final counts = List.filled(4, 0);
        var total = 0;
        for (final s in world.stages) {
          for (final q in loadSet(s.questionSetIds.last).questions) {
            counts[q.answerIndex]++;
            total++;
          }
        }
        for (final c in counts) {
          expect(c / total, inInclusiveRange(0.18, 0.32), reason: '$counts');
        }
      });

      test('購入後、各ルートの最初のエリアから遊べる', () {
        final owned = RpgProgress(purchasedWorldIds: {world.id});
        for (final s in world.stages) {
          expect(
            Progression.isStageUnlocked(owned, world, s),
            s.areaNo == 1,
            reason: s.id,
          );
        }
      });

      test('宿の授業がある（手書きがなければ問題から作る）', () {
        for (final s in world.stages) {
          final l = InnLessons.forStage(s.id);
          expect(l.title, s.grammarTheme);
        }
      });
    });
  }
}
