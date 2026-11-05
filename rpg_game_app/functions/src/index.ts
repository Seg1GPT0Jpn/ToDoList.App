import { createHash } from 'node:crypto';

import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2/options';
import { google } from 'googleapis';

initializeApp();
setGlobalOptions({
  region: 'asia-northeast1',
  maxInstances: 10,
});

const PACKAGE_NAME = 'com.kazu.rpg_game_app';

const PRODUCT_TO_WORLD = new Map<string, string>([
  ['world_science', 'science'],
  ['world_social', 'social'],
  ['world_japanese', 'japanese'],
  ['world_math', 'math'],
  ['world_information', 'information'],
]);

const db = getFirestore();

const playAuth = new google.auth.GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/androidpublisher'],
});

const androidPublisher = google.androidpublisher({
  version: 'v3',
  auth: playAuth,
});

function assertString(value: unknown, name: string): asserts value is string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', name + ' が不正です');
  }
}

export const verifyGooglePlayPurchase = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Google ログインが必要です');
  }

  const uid = request.auth.uid;
  const data = request.data as Record<string, unknown> | undefined;
  const productId = data?.productId;
  const purchaseToken = data?.purchaseToken;

  assertString(productId, 'productId');
  assertString(purchaseToken, 'purchaseToken');

  const worldId = PRODUCT_TO_WORLD.get(productId);
  if (!worldId) {
    throw new HttpsError('invalid-argument', '許可されていない商品です');
  }

  const product = await androidPublisher.purchases.products.get({
    packageName: PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });

  const purchase = product.data;
  if (purchase.purchaseState !== 0) {
    throw new HttpsError(
      'failed-precondition',
      '購入がまだ確定していません',
    );
  }

  const tokenHash = createHash('sha256').update(purchaseToken).digest('hex');
  const tokenRef = db.doc('play_purchase_tokens/' + tokenHash);
  const entitlementRef = db.doc(
    'users/' + uid + '/rpg_purchases/' + worldId,
  );

  await db.runTransaction(async (tx) => {
    const existing = await tx.get(tokenRef);
    const existingUid = existing.data()?.uid as string | undefined;
    if (existingUid && existingUid !== uid) {
      throw new HttpsError(
        'already-exists',
        'この購入は別のアカウントに関連付けられています',
      );
    }

    tx.set(
      tokenRef,
      {
        uid,
        productId,
        packageName: PACKAGE_NAME,
        purchaseToken,
        orderId: purchase.orderId ?? null,
        purchaseTimeMillis: purchase.purchaseTimeMillis ?? null,
        verifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    tx.set(
      entitlementRef,
      {
        productId,
        purchaseTokenHash: tokenHash,
        orderId: purchase.orderId ?? null,
        purchaseTimeMillis: purchase.purchaseTimeMillis ?? null,
        acknowledged: purchase.acknowledgementState === 1,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  if (purchase.acknowledgementState !== 1) {
    await androidPublisher.purchases.products.acknowledge({
      packageName: PACKAGE_NAME,
      productId,
      token: purchaseToken,
      requestBody: {},
    });
  }

  return {
    ok: true,
    worldId,
    productId,
  };
});
