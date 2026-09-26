import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  group('プロモーションコード', () {
    test('正しいコードなら通る（全角数字・空白・ハイフンも許す）', () {
      expect(PromoCodes.unlocksAllSubjects('0951363'), isTrue);
      expect(PromoCodes.unlocksAllSubjects(' ０９５１３６３ '), isTrue);
      expect(PromoCodes.unlocksAllSubjects('095-1363'), isTrue);
    });

    test('ちがうコードは通らない', () {
      for (final c in ['', '0951364', '951363', '09513630', 'LEAP']) {
        expect(PromoCodes.unlocksAllSubjects(c), isFalse, reason: c);
      }
    });

    test('有料の5教科をまとめて受け取れる。英語はもともと無料', () async {
      final repo = InMemoryProgressRepository();
      final service =
          WorldUnlockService(repository: repo, allowPurchase: false);
      final got = <WorldDef>[];
      expect(
        await service.redeemPromoCode('0951363', RpgCatalog.worlds,
            newlyUnlocked: got),
        PromoOutcome.success,
      );
      expect(got.map((w) => w.id).toSet(),
          {'science', 'social', 'japanese', 'math', 'information'});
      final p = await repo.load();
      for (final w in RpgCatalog.worlds) {
        expect(Progression.isWorldPlayable(p, w), isTrue, reason: w.id);
      }
      expect(await service.redeemPromoCode('0951363', RpgCatalog.worlds),
          PromoOutcome.alreadyOwned);
    });

    test('ちがうコードでは何も解放しない', () async {
      final repo = InMemoryProgressRepository();
      final service = WorldUnlockService(repository: repo);
      expect(await service.redeemPromoCode('1234567', RpgCatalog.worlds),
          PromoOutcome.invalid);
      expect((await repo.load()).purchasedWorldIds, isEmpty);
    });

    test('購入を止めた版では、購入ボタンからは解放できない', () async {
      final repo = InMemoryProgressRepository();
      final service =
          WorldUnlockService(repository: repo, allowPurchase: false);
      expect(await service.purchase(RpgCatalog.world('math')),
          PurchaseOutcome.notPurchasable);
      expect((await repo.load()).purchasedWorldIds, isEmpty);
    });
  });
}
