import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('今日の挑戦状：クリアしたエリアから日替わりで強化された魔物。倒すと1日1回ぶんの記録', () {
    expect(DailyChallenge.of(RpgProgress.initial, 100), isNull);
    final stages = RpgCatalog.world(RpgCatalog.englishWorldId).stages;
    final p = RpgProgress.initial.copyWith(
      clearedStageIds: {for (final s in stages.take(6)) s.id},
    );
    final a = DailyChallenge.of(p, 100)!;
    final b = DailyChallenge.of(p, 100)!;
    expect(a.id, b.id, reason: '同じ日は同じ');
    expect(a.id, 'daily_100');
    final base = stages
        .firstWhere((s) => a.questionSetIds.first == s.questionSetIds.first);
    expect(a.enemy.maxHp, greaterThan(base.enemy.maxHp));
    expect(a.expReward, base.expReward * 3);
    expect(a.isBoss, isFalse);
    final days = {
      for (var d = 0; d < 10; d++) DailyChallenge.of(p, d)!.enemy.name
    };
    expect(days.length, greaterThan(2), reason: '日によって変わる');
    // 倒すと、その日は達成
    final summary = BattleSummary(
      won: true,
      correctCount: 10,
      answeredCount: 10,
      maxCombo: 10,
      remainingHp: 10,
      maxHp: 10,
      turns: const [],
    );
    final r = Progression.applyBattle(
      progress: p,
      world: RpgCatalog.world(a.worldId),
      stage: a,
      summary: summary,
    );
    expect(DailyChallenge.done(r.progress, 100), isTrue);
    expect(DailyChallenge.done(r.progress, 101), isFalse);
    expect(r.newlyUnlockedStageId, isNull, reason: 'エリアの解放には数えない');
    expect(r.expResult.expGained, greaterThan(0));
  });
}
