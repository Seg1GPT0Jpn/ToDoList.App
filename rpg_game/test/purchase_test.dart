import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final english = RpgCatalog.world('english');
  // 全教科が公開済みになったので、準備中ワールドはテスト用に用意する
  const comingSoon = WorldDef(
    id: 'coming_soon',
    name: '準備中の国',
    subject: 'テスト',
    status: WorldStatus.comingSoon,
    isFree: false,
    priceYen: 250,
  );
  const paidReady = WorldDef(
    id: 'paid_ready',
    name: 'テスト',
    subject: 'テスト',
    status: WorldStatus.available,
    isFree: false,
    priceYen: 250,
  );

  test('無料ワールドは購入不要', () async {
    final repo = InMemoryProgressRepository();
    final service = WorldUnlockService(repository: repo);
    expect(service.availabilityOf(RpgProgress.initial, english),
        WorldAvailability.playable);
    expect(await service.purchase(english), PurchaseOutcome.alreadyOwned);
  });

  test('準備中ワールドは既定では購入できない', () async {
    final repo = InMemoryProgressRepository();
    var called = false;
    final service = WorldUnlockService(
      repository: repo,
      purchase: (_) async => called = true,
    );
    expect(service.availabilityOf(RpgProgress.initial, comingSoon),
        WorldAvailability.comingSoon);
    expect(await service.purchase(comingSoon), PurchaseOutcome.notPurchasable);
    expect(called, isFalse);
  });

  test('購入に成功すると購入フラグが保存される', () async {
    final repo = InMemoryProgressRepository();
    final service = WorldUnlockService(repository: repo);
    expect(await service.purchase(paidReady), PurchaseOutcome.success);
    final p = await repo.load();
    expect(p.purchasedWorldIds, contains('paid_ready'));
    expect(Progression.isWorldPlayable(p, paidReady), isTrue);
    expect(await service.purchase(paidReady), PurchaseOutcome.alreadyOwned);
  });

  test('キャンセル時は何も保存しない', () async {
    final repo = InMemoryProgressRepository();
    final service =
        WorldUnlockService(repository: repo, purchase: (_) async => false);
    expect(await service.purchase(paidReady), PurchaseOutcome.cancelled);
    expect((await repo.load()).purchasedWorldIds, isEmpty);
  });

  test('動作確認モードなら準備中ワールドの購入導線を試せる（購入後も準備中のまま）', () async {
    final repo = InMemoryProgressRepository();
    final service =
        WorldUnlockService(repository: repo, allowComingSoonPurchase: true);
    expect(await service.purchase(comingSoon), PurchaseOutcome.success);
    final p = await repo.load();
    expect(service.availabilityOf(p, comingSoon),
        WorldAvailability.ownedComingSoon);
    expect(Progression.isWorldPlayable(p, comingSoon), isFalse);
  });

  test('課金はランダム要素を持たない（全ワールドが固定価格の買い切り）', () {
    for (final w in RpgCatalog.worlds.where((w) => !w.isFree)) {
      expect(w.priceYen, isNotNull, reason: w.id);
    }
  });
}
