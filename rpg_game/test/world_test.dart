import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('エリアの地形', () {
    test('名前から地形が決まる（場所そのものが勉強内容を表す）', () {
      expect(Terrain.fromName('はじまりの草原'), Terrain.meadow);
      expect(Terrain.fromName('ばねの林'), Terrain.forest);
      expect(Terrain.fromName('助動詞の関所'), Terrain.shrine);
      expect(Terrain.fromName('鏡の地底湖'), Terrain.crystal);
      expect(Terrain.fromName('灰の書庫'), Terrain.library);
      expect(Terrain.fromName('最終章の玉座'), Terrain.castle);
      expect(Terrain.fromName('アボガドロの港'), Terrain.harbor);
    });

    test('英語ワールドの20エリアは、10種類以上の地形に分かれる', () {
      final english = RpgCatalog.world(RpgCatalog.englishWorldId);
      final kinds = {for (final s in english.stages) Terrain.of(s)};
      expect(kinds.length, greaterThanOrEqualTo(10));
      // となりあうエリアで、同じ地形が3つ続かない
      for (var i = 2; i < english.stages.length; i++) {
        final a = Terrain.of(english.stages[i - 2]);
        final b = Terrain.of(english.stages[i - 1]);
        final c = Terrain.of(english.stages[i]);
        expect(a == b && b == c, isFalse, reason: english.stages[i].name);
      }
    });

    test('すべての教科で、どの地形にも1つ以上のエリアがある', () {
      final used = {
        for (final w in RpgCatalog.worlds)
          for (final s in w.stages) Terrain.of(s),
      };
      expect(used.length, greaterThanOrEqualTo(Terrain.values.length - 1));
    });
  });

  group('強敵', () {
    final base = RpgCatalog.world(RpgCatalog.englishWorldId).stages[2];
    final elite = Elites.of(base);

    test('もとのエリアより強く、同じ問題で戦い、レアカードがもらえる', () {
      expect(Elites.isElite(elite.id), isTrue);
      expect(Elites.baseId(elite.id), base.id);
      expect(elite.enemy.maxHp, greaterThan(base.enemy.maxHp));
      expect(elite.questionSetIds, base.questionSetIds);
      expect(CardDef.byId(elite.rewardCardId!).rarity, CardRarity.rare);
    });

    test('強敵に勝っても、次のエリアの解放には数えない', () {
      final world = RpgCatalog.world(RpgCatalog.englishWorldId);
      const summary = BattleSummary(
        won: true,
        correctCount: 5,
        answeredCount: 5,
        maxCombo: 5,
        remainingHp: 10,
        maxHp: 10,
        turns: [],
      );
      final r = Progression.applyBattle(
        progress: RpgProgress.initial,
        world: world,
        stage: elite,
        summary: summary,
      );
      expect(r.newlyUnlockedStageId, isNull);
      expect(r.newCard?.id, elite.rewardCardId);
      expect(r.progress.clearedStageIds, contains(elite.id));
      expect(r.progress.clearedStageIds, isNot(contains(base.id)));
    });
  });

  test('フィールドで開けたものは保存しても元にもどる', () {
    final p = RpgProgress.initial.copyWith(
      fieldFlags: {'open:english:3:40', 'warp:english:5:12'},
    );
    expect(RpgProgress.fromMap(p.toMap()).fieldFlags, p.fieldFlags);
  });
}
