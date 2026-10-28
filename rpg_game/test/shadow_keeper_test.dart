import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final w = RpgCatalog.world(RpgCatalog.englishWorldId);
  final stages = w.stages;

  test('影の番人：最後のボスより強く、マップのすべての問題から出る', () {
    final s = ShadowKeeper.of(stages);
    expect(ShadowKeeper.isShadow(s.id), isTrue);
    expect(s.isBoss, isTrue);
    expect(s.enemy.maxHp, greaterThan(stages.last.enemy.maxHp * 2));
    expect(s.recommendedLevel, greaterThan(stages.last.recommendedLevel));
    expect(
      s.questionSetIds.toSet(),
      {for (final st in stages) ...st.questionSetIds},
    );
    expect(BossRules.of(s), BossRule.finale);
  });

  test('全エリアをクリアすると現れ、倒すと記録が残る。実績も解除', () {
    var p = RpgProgress.initial.copyWith(
      clearedStageIds: {for (final s in stages.take(stages.length - 1)) s.id},
    );
    expect(ShadowKeeper.appears(p, stages), isFalse);
    p = p.copyWith(clearedStageIds: {...p.clearedStageIds, stages.last.id});
    expect(ShadowKeeper.appears(p, stages), isTrue);
    expect(ShadowKeeper.defeated(p, stages), isFalse);
    p = p.copyWith(
      clearedStageIds: {...p.clearedStageIds, ShadowKeeper.of(stages).id},
    );
    expect(ShadowKeeper.defeated(p, stages), isTrue);
    final c = AchievementContext(
      progress: p,
      record: LearningRecord.empty,
      journal: PlayerJournal.empty,
      today: 1,
    );
    expect(Achievements.byId('shadow_1')!.achieved(c), isTrue);
    expect(Achievements.byId('shadow_5')!.achieved(c), isFalse);
  });

  test('影の番人を倒しても、次のエリアの解放やワールドの★には数えない', () {
    final shadow = ShadowKeeper.of(stages);
    expect(stages.any((s) => s.id == shadow.id), isFalse);
  });
}
