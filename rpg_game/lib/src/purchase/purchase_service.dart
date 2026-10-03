import '../data/progress_repository.dart';
import '../models/rpg_progress.dart';
import '../models/world.dart';
import '../progression/progression.dart';
import 'promo_code.dart';

/// 開発用のダミー購入処理。
///
/// 本番の Android ビルドでは、Flutter 側から Google Play Billing の
/// 購入処理を注入する。コア層自体は Flutter / Firebase に依存しない。
Future<bool> mockPurchaseWorld(String worldId) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return true;
}

/// ワールドの購入可否。
enum WorldAvailability {
  /// 無料または購入済みで、遊べる
  playable,

  /// 購入済みだが、まだ中身が準備中
  ownedComingSoon,

  /// 購入すれば遊べる
  purchasable,

  /// 準備中のため、まだ購入できない
  comingSoon,
}

enum PurchaseOutcome { success, cancelled, notPurchasable, alreadyOwned }

/// プロモーションコードを入力した結果
enum PromoOutcome {
  /// 新しく受け取った
  success,

  /// コードは正しいが、すでに全部持っている
  alreadyOwned,

  /// コードがちがう
  invalid,
}

/// 購入導線とロック解除をまとめる。
class WorldUnlockService {
  WorldUnlockService({
    required this.repository,
    Future<bool> Function(String worldId)? purchase,
    this.allowComingSoonPurchase = false,
    this.allowPurchase = true,
    this.purchaseSource = 'mock',
  }) : _purchase = purchase ?? mockPurchaseWorld;

  /// 購入ボタンを表示してよいか。
  ///
  /// Android の Google Play Billing が利用可能なビルドでは true、
  /// Web 版などでは false にする。
  final bool allowPurchase;

  final ProgressRepository repository;
  final Future<bool> Function(String worldId) _purchase;

  /// 準備中のワールドを購入できるようにするか。
  ///
  /// 本番では false のままにする。
  final bool allowComingSoonPurchase;

  /// [purchasedWorldIds] に記録する購入元。
  final String purchaseSource;

  WorldAvailability availabilityOf(RpgProgress progress, WorldDef world) {
    final owned = Progression.isWorldOwned(progress, world);
    if (world.isComingSoon) {
      if (owned) return WorldAvailability.ownedComingSoon;
      return allowComingSoonPurchase
          ? WorldAvailability.purchasable
          : WorldAvailability.comingSoon;
    }
    return owned ? WorldAvailability.playable : WorldAvailability.purchasable;
  }

  /// 購入ダイアログで「購入する」が押されたときに呼ぶ。
  Future<PurchaseOutcome> purchase(WorldDef world) async {
    final progress = await repository.load();
    switch (availabilityOf(progress, world)) {
      case WorldAvailability.playable:
      case WorldAvailability.ownedComingSoon:
        return PurchaseOutcome.alreadyOwned;
      case WorldAvailability.comingSoon:
        return PurchaseOutcome.notPurchasable;
      case WorldAvailability.purchasable:
        break;
    }
    if (!allowPurchase || world.priceYen == null) {
      return PurchaseOutcome.notPurchasable;
    }
    final ok = await _purchase(world.id);
    if (!ok) return PurchaseOutcome.cancelled;
    await repository.markWorldPurchased(world.id, source: purchaseSource);
    return PurchaseOutcome.success;
  }

  /// プロモーションコードで有料ワールドを受け取る。
  ///
  /// [worlds] のうち、公開済みの有料ワールドをまとめて解放する。
  /// 受け取ったワールドは [newlyUnlocked] に入る。
  Future<PromoOutcome> redeemPromoCode(
    String code,
    Iterable<WorldDef> worlds, {
    List<WorldDef>? newlyUnlocked,
  }) async {
    if (!PromoCodes.unlocksAllSubjects(code)) return PromoOutcome.invalid;
    final progress = await repository.load();
    final targets = [
      for (final w in worlds)
        if (!w.isFree &&
            !w.isComingSoon &&
            !Progression.isWorldOwned(progress, w))
          w,
    ];
    if (targets.isEmpty) return PromoOutcome.alreadyOwned;
    await repository.save(
      progress.copyWith(
        purchasedWorldIds: {
          ...progress.purchasedWorldIds,
          for (final w in targets) w.id,
        },
      ),
    );
    newlyUnlocked?.addAll(targets);
    return PromoOutcome.success;
  }
}
