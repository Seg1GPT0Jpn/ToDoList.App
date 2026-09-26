import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

BattleSummary winAll({int level = 1}) {
  final b = newBattle(level: level);
  while (!b.isOver) {
    b.answer(b.currentQuestion.correctIndex, elapsed: slow);
  }
  return b.summary();
}

BattleSummary winWithOneMiss() {
  final b = newBattle();
  b.answer(wrongIndex(b), elapsed: slow);
  while (!b.isOver) {
    b.answer(b.currentQuestion.correctIndex, elapsed: slow);
  }
  return b.summary();
}

BattleSummary loseAll() {
  final b = newBattle();
  while (!b.isOver) {
    b.answer(wrongIndex(b), elapsed: slow);
  }
  return b.summary();
}

void main() {
  final world = RpgCatalog.world(RpgCatalog.englishWorldId);
  final stage1 = world.stages[0];
  final stage2 = world.stages[1];

  group('PlayerStats', () {
    test('レベルが上がると HP・攻撃・防御が上がる', () {
      final l1 = PlayerStats.forLevel(1);
      final l2 = PlayerStats.forLevel(2);
      expect(l2.maxHp, greaterThan(l1.maxHp));
      expect(l2.attack, greaterThan(l1.attack));
      expect(l2.defense, greaterThan(l1.defense));
    });
  });

  group('Progression.addExp', () {
    test('必要経験値に届くとレベルアップし、余りは持ち越す', () {
      final r = Progression.addExp(RpgProgress.initial, 25);
      expect(r.leveledUp, isTrue);
      expect(r.progress.level, 2);
      expect(r.progress.exp, 5);
      expect(r.progress.totalExp, 25);
    });

    test('一度に複数レベル上がる', () {
      // Lv1→2: 20, Lv2→3: 35
      final r = Progression.addExp(RpgProgress.initial, 60);
      expect(r.progress.level, 3);
      expect(r.levelsGained, 2);
      expect(r.progress.exp, 5);
    });

    test('最大レベルで止まる', () {
      final r = Progression.addExp(RpgProgress.initial, 1000000);
      expect(r.progress.level, PlayerStats.maxLevel);
      expect(r.progress.exp, 0);
    });
  });

  group('Progression.applyBattle', () {
    test('初回ノーミスクリア: 20 × 1.2 = 24 経験値、次ステージ解放', () {
      final r = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: stage1,
        summary: winAll(),
      );
      expect(r.firstClear, isTrue);
      expect(r.expResult.expGained, 24);
      expect(r.newlyUnlockedStageId, stage2.id);
      expect(r.progress.clearedStageIds, contains(stage1.id));
      expect(r.progress.level, 2);
      expect(Progression.isStageUnlocked(r.progress, world, stage2), isTrue);
    });

    test('ミスありクリアはボーナスなし', () {
      final r = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: stage1,
        summary: winWithOneMiss(),
      );
      expect(r.expResult.expGained, 20);
    });

    test('2回目以降のクリアは半分、次ステージは再解放扱いにしない', () {
      final first = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: stage1,
        summary: winWithOneMiss(),
      );
      final second = Progression.applyBattle(
        progress: first.progress,
        world: world,
        stage: stage1,
        summary: winWithOneMiss(),
      );
      expect(second.firstClear, isFalse);
      expect(second.expResult.expGained, 10);
      expect(second.newlyUnlockedStageId, isNull);
      expect(second.progress.stageRecords[stage1.id]!.clearCount, 2);
    });

    test('敗北でも正解数×2の経験値。クリア扱いにはならない', () {
      final b = newBattle();
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      while (!b.isOver) {
        b.answer(wrongIndex(b), elapsed: slow);
      }
      final r = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: stage1,
        summary: b.summary(),
      );
      expect(r.expResult.expGained, 4);
      expect(r.progress.clearedStageIds, isEmpty);
      expect(Progression.isStageUnlocked(r.progress, world, stage2), isFalse);
    });

    test('自己ベストは正答率が上がったときだけ更新', () {
      var p = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: stage1,
        summary: winAll(),
      ).progress;
      p = Progression.applyBattle(
        progress: p,
        world: world,
        stage: stage1,
        summary: winWithOneMiss(),
      ).progress;
      expect(p.stageRecords[stage1.id]!.bestAccuracy, 1.0);
    });

    test('全敗の結果には経験値 0', () {
      final r = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: stage1,
        summary: loseAll(),
      );
      expect(r.expResult.expGained, 0);
    });
  });

  group('ステージ・ワールドの解放', () {
    test('最初は英語ワールドのステージ1だけ挑戦できる', () {
      const p = RpgProgress.initial;
      expect(Progression.isStageUnlocked(p, world, stage1), isTrue);
      for (final s in world.stages.skip(1)) {
        expect(Progression.isStageUnlocked(p, world, s), isFalse);
      }
    });

    test('英語は無料、ほかの公開済みワールドは購入後に遊べる。残りは準備中', () {
      for (final w in RpgCatalog.worlds) {
        if (w.id == RpgCatalog.englishWorldId) {
          expect(Progression.isWorldPlayable(RpgProgress.initial, w), isTrue);
        } else if (!w.isComingSoon) {
          expect(Progression.isWorldPlayable(RpgProgress.initial, w), isFalse);
          final bought =
              RpgProgress.initial.copyWith(purchasedWorldIds: {w.id});
          expect(Progression.isWorldPlayable(bought, w), isTrue);
        } else {
          expect(w.isComingSoon, isTrue);
          expect(Progression.isWorldPlayable(RpgProgress.initial, w), isFalse);
        }
      }
    });

    test('英語ワールドは20エリアで、敵がだんだん強くなる', () {
      expect(world.stages.length, 20);
      for (var i = 1; i < world.stages.length; i++) {
        final prev = world.stages[i - 1].enemy;
        final cur = world.stages[i].enemy;
        expect(cur.attack, greaterThan(prev.attack));
        // 装甲のある敵は、そのぶん HP が前の敵より低いこともある
        if (cur.armor == 0 || prev.armor > 0) {
          expect(cur.maxHp, greaterThan(prev.maxHp));
        }
        expect(world.stages[i].order, i + 1);
      }
    });
  });

  group('RpgProgress の保存形式', () {
    test('toMap / fromMap の往復', () {
      final p = Progression.applyBattle(
        progress: RpgProgress.initial.copyWith(purchasedWorldIds: {'math'}),
        world: world,
        stage: stage1,
        summary: winAll(),
      ).progress;
      final again = RpgProgress.fromMap(p.toMap());
      expect(again.toMap(), p.toMap());
    });

    test('null や欠けたフィールドは初期値', () {
      expect(RpgProgress.fromMap(null).level, 1);
      expect(RpgProgress.fromMap({'level': 3}).clearedStageIds, isEmpty);
    });
  });
}
