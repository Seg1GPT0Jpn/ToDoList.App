import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final world = RpgCatalog.world(ScienceCatalog.worldId);

  group('理の国の構成', () {
    test('4系統 × 16エリア＝64エリアで、並び順は1〜64', () {
      expect(world.stages.length, 64);
      expect([for (final s in world.stages) s.order],
          [for (var i = 1; i <= 64; i++) i]);
      for (final b in ScienceCatalog.branches) {
        final stages = world.stages.where((s) => s.branch == b.id).toList();
        expect(stages.length, 16, reason: b.id);
        expect([for (final s in stages) s.areaNo],
            [for (var i = 1; i <= 16; i++) i]);
      }
    });

    test('道の向きは 上＝物理・左＝化学・右＝地学・下＝生物', () {
      expect({
        for (final b in ScienceCatalog.branches) b.direction: b.id
      }, {
        'up': 'physics',
        'left': 'chemistry',
        'right': 'earth',
        'down': 'biology',
      });
    });

    test('エリア1〜8は基礎、9〜16は発展科目（1:1）', () {
      for (final s in world.stages) {
        final b = ScienceCatalog.branch(s.branch);
        expect(s.region, s.areaNo <= 8 ? b.basic : b.advanced);
      }
    });

    test('エリア8・16はボスで装甲があり、範囲の問題をまとめて出す', () {
      for (final s in world.stages) {
        final boss = s.areaNo == 8 || s.areaNo == 16;
        expect(s.isBoss, boss, reason: s.id);
        expect(s.enemy.armor > 0, boss, reason: s.id);
        if (s.areaNo == 8) expect(s.questionSetIds.length, 8);
        if (s.areaNo == 16) expect(s.questionSetIds.length, 8);
        if (!boss) expect(s.questionSetIds.length, 1);
        expect(s.enemy.introLine, isNotEmpty);
        expect(s.enemy.defeatLine, isNotEmpty);
      }
    });

    test('有料の買い切りワールド（ランダム要素なし）', () {
      expect(world.isFree, isFalse);
      expect(world.priceYen, RpgCatalog.defaultWorldPriceYen);
      expect(world.isComingSoon, isFalse);
    });
  });

  group('理科の問題データ', () {
    final allIds = <String>{};
    for (final s in world.stages) {
      final setId = s.questionSetIds.last;
      test('$setId：16〜40問・自作・4択・解説つき', () {
        final set = loadSet(setId);
        expect(set.setId, setId);
        expect(set.origin, QuestionOrigin.original);
        expect(set.origin.usableInRpg, isTrue);
        expect(set.questions.length, inInclusiveRange(16, 40));
        for (final q in set.questions) {
          expect(q.choices.length, 4, reason: q.id);
          expect(q.choices.toSet().length, 4, reason: q.id);
          expect(q.answerIndex, inInclusiveRange(0, 3));
          expect(q.explanation, isNotEmpty, reason: q.id);
          expect(q.shortExplanation, isNotEmpty, reason: q.id);
          expect(
            [
              QuestionCategory.knowledge,
              QuestionCategory.calculation,
              QuestionCategory.thinking,
            ],
            contains(q.category),
            reason: q.id,
          );
          expect(allIds.add(q.id), isTrue, reason: '重複ID ${q.id}');
        }
        final again = QuestionSet.fromJson(set.toJson());
        expect(again.toJson(), set.toJson());
      });
    }

    test('正解の位置がかたよっていない', () {
      final counts = List.filled(4, 0);
      for (final s in world.stages) {
        for (final q in loadSet(s.questionSetIds.last).questions) {
          counts[q.answerIndex]++;
        }
      }
      final total = counts.fold<int>(0, (a, b) => a + b);
      for (final c in counts) {
        expect(c / total, inInclusiveRange(0.2, 0.3), reason: '$counts');
      }
    });

    test('ボスの装甲を割れる種類の問題が十分にある', () {
      for (final s in world.stages.where((s) => s.isBoss)) {
        final pool = loadStagePool(s).questions;
        final n = pool.where((q) => q.category == s.enemy.armorCategory);
        expect(n.length, greaterThan(s.enemy.armor * 5), reason: s.id);
      }
    });
  });

  group('理の国の進行', () {
    final owned = RpgProgress(purchasedWorldIds: {ScienceCatalog.worldId});

    test('買う前は遊べず、買うと4系統の最初のエリアがすべて解放される', () {
      expect(Progression.isWorldPlayable(const RpgProgress(), world), isFalse);
      for (final s in world.stages) {
        expect(Progression.isStageUnlocked(owned, world, s), s.areaNo == 1,
            reason: s.id);
      }
    });

    test('同じ系統の1つ前をクリアすると次が解放される（他の系統には影響しない）', () {
      final phy1 = world.stages.firstWhere((s) => s.id == 'science_physics_01');
      final phy2 = world.stages.firstWhere((s) => s.id == 'science_physics_02');
      final chm2 =
          world.stages.firstWhere((s) => s.id == 'science_chemistry_02');
      final p = owned.copyWith(clearedStageIds: {phy1.id});
      expect(Progression.isStageUnlocked(p, world, phy2), isTrue);
      expect(Progression.isStageUnlocked(p, world, chm2), isFalse);
      expect(Progression.nextInBranch(world, phy1)?.id, phy2.id);
      final phy16 =
          world.stages.firstWhere((s) => s.id == 'science_physics_16');
      expect(Progression.nextInBranch(world, phy16), isNull);
      expect(Progression.previousInBranch(world, chm2)?.id,
          'science_chemistry_01');
    });

    test('勝つと同じ系統の次のエリアが「解放された」と出る', () {
      final phy1 = world.stages.first;
      final summary = BattleSummary(
        won: true,
        correctCount: 5,
        answeredCount: 5,
        maxCombo: 5,
        remainingHp: 10,
        maxHp: 50,
        turns: const [],
      );
      final r = Progression.applyBattle(
          progress: owned, world: world, stage: phy1, summary: summary);
      expect(r.newlyUnlockedStageId, 'science_physics_02');
    });
  });

  test('理科の全エリアに宿の授業（要点3つ）がある', () {
    for (final s in world.stages) {
      final lesson = InnLessons.forStage(s.id);
      expect(lesson.points.length, 3, reason: s.id);
      expect(lesson.title, s.grammarTheme);
    }
  });
}
