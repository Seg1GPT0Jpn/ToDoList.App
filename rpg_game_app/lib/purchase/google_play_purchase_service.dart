import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play の買い切り商品を購入し、Firebase Functions で検証する。
///
/// 重要:
/// - Google Play から返された購入トークンをクライアント側で信用しない。
/// - 購入トークンは Firebase Functions に送り、Google Play Developer API
///   で検証・承認してからワールドを解放する。
/// - Web では Google Play Billing を使えないため、このサービスは無効になる。
class GooglePlayPurchaseService {
  GooglePlayPurchaseService({
    required Future<void> Function(String worldId) onVerified,
    InAppPurchase? store,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _store = store ?? InAppPurchase.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _onVerified = onVerified;

  static const _productPrefix = 'world_';

  /// Google Play Console に登録する買い切り商品 ID。
  static String productIdForWorld(String worldId) => '$_productPrefix$worldId';

  /// 商品 ID からワールド ID を取り出す。
  static String? worldIdForProduct(String productId) {
    if (!productId.startsWith(_productPrefix)) return null;
    final worldId = productId.substring(_productPrefix.length);
    if (const {
      'science',
      'social',
      'japanese',
      'math',
      'information',
    }.contains(worldId)) {
      return worldId;
    }
    return null;
  }

  final InAppPurchase _store;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final Future<void> Function(String worldId) _onVerified;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, Completer<bool>> _pending = {};
  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;
  bool get isSignedIn => _auth.currentUser != null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    try {
      _available = await _store.isAvailable();
      if (!_available) return;
      _subscription = _store.purchaseStream.listen(
        _handlePurchases,
        onError: (Object error, StackTrace stack) {
          debugPrint('Google Play 購入ストリームのエラー: $error');
        },
      );
    } catch (e) {
      _available = false;
      debugPrint('Google Play Billing の初期化に失敗しました: $e');
    }
  }

  /// Google Play に登録されている表示価格を取得する。
  Future<String?> priceForWorld(String worldId) async {
    await initialize();
    if (!_available) return null;

    try {
      final response = await _store.queryProductDetails({
        productIdForWorld(worldId),
      });
      if (response.productDetails.isEmpty) return null;
      return response.productDetails.single.price;
    } catch (e) {
      debugPrint('商品情報の取得に失敗しました: $e');
      return null;
    }
  }

  /// ワールドを買い切りで購入する。
  Future<bool> purchaseWorld(String worldId) async {
    await initialize();
    if (!_available || !_isAndroidPurchaseReady) return false;

    final productId = productIdForWorld(worldId);
    final response = await _store.queryProductDetails({productId});
    if (response.error != null || response.productDetails.length != 1) {
      debugPrint(
        'Google Play の商品情報を取得できませんでした: ' +
        (response.error?.message ?? 'product not found'),
      );
      return false;
    }

    if (_pending.containsKey(worldId)) {
      return _pending[worldId]!.future;
    }

    final completer = Completer<bool>();
    _pending[worldId] = completer;

    try {
      final started = await _store.buyNonConsumable(
        purchaseParam:
            PurchaseParam(productDetails: response.productDetails.single),
      );
      if (!started) {
        _pending.remove(worldId);
        completer.complete(false);
      }
    } catch (e) {
      _pending.remove(worldId);
      completer.complete(false);
      debugPrint('Google Play の購入開始に失敗しました: $e');
    }

    return completer.future;
  }

  /// Google Play 側に残っている買い切り商品の購入情報を再送してもらう。
  Future<void> restorePurchases() async {
    await initialize();
    if (!_available || !_isAndroidPurchaseReady) return;
    try {
      await _store.restorePurchases();
    } catch (e) {
      debugPrint('Google Play 購入情報の復元に失敗しました: $e');
    }
  }

  bool get _isAndroidPurchaseReady =>
      !kIsWeb && _auth.currentUser != null;

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final worldId = worldIdForProduct(purchase.productID);
      if (worldId == null) continue;

      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        _completePending(worldId, false);
        if (purchase.pendingCompletePurchase) {
          try {
            await _store.completePurchase(purchase);
          } catch (e) {
            debugPrint('キャンセル済み購入の完了処理に失敗しました: $e');
          }
        }
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final verified = await _verifyWithServer(purchase, worldId);
      if (!verified) {
        // 検証に失敗した場合は completePurchase しない。
        // 次回の購入ストリームで再試行できるようにする。
        _completePending(worldId, false);
        continue;
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (e) {
          debugPrint('Google Play 購入の完了処理に失敗しました: $e');
        }
      }

      try {
        await _onVerified(worldId);
        _completePending(worldId, true);
      } catch (e) {
        debugPrint('購入済みワールドの保存に失敗しました: $e');
        _completePending(worldId, false);
      }
    }
  }

  Future<bool> _verifyWithServer(
    PurchaseDetails purchase,
    String worldId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return false;

    try {
      final callable =
          _functions.httpsCallable('verifyGooglePlayPurchase');
      final response = await callable.call(<String, dynamic>{
        'productId': purchase.productID,
        'purchaseToken': token,
        'worldId': worldId,
      });
      final data = response.data;
      return data is Map &&
          data['ok'] == true &&
          data['worldId'] == worldId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'Google Play 購入のサーバー検証に失敗しました: ' +
        e.code +
        ' ' +
        (e.message ?? ''),
      );
      return false;
    } catch (e) {
      debugPrint('Google Play 購入のサーバー検証に失敗しました: $e');
      return false;
    }
  }

  void _completePending(String worldId, bool success) {
    final completer = _pending.remove(worldId);
    if (completer == null || completer.isCompleted) return;
    completer.complete(success);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}