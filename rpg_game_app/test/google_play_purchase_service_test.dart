import 'package:flutter_test/flutter_test.dart';

import '../lib/purchase/google_play_purchase_service.dart';

void main() {
  group('Google Play product IDs', () {
    test('world IDから商品IDを作れる', () {
      expect(
        GooglePlayPurchaseService.productIdForWorld('math'),
        'world_math',
      );
    });

    test('許可された商品IDをworld IDへ戻せる', () {
      expect(
        GooglePlayPurchaseService.worldIdForProduct('world_science'),
        'science',
      );
      expect(
        GooglePlayPurchaseService.worldIdForProduct('world_information'),
        'information',
      );
    });

    test('未許可の商品IDは解放対象にしない', () {
      expect(
        GooglePlayPurchaseService.worldIdForProduct('world_english'),
        isNull,
      );
      expect(
        GooglePlayPurchaseService.worldIdForProduct('other_math'),
        isNull,
      );
    });
  });
}
