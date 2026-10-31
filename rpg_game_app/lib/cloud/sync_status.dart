import 'package:flutter/foundation.dart';

/// クラウド同期のようす（アカウント画面の「同期のようす」に出す）。
///
/// 同期がうまくいかないとき、どこで止まっているか（クラウドにつながらない・ログインしていない・
/// 保存が許可されていない など）を利用者が見て伝えられるようにする。
@immutable
class SyncStatus {
  const SyncStatus({
    this.connected,
    this.email,
    this.lastPulled,
    this.lastSent,
    this.lastReceived,
    this.error,
    this.errorAt,
  });

  /// クラウド（Firebase）につながったか（null：まだ準備中）
  final bool? connected;

  /// ログインしているアカウント（null：ログインしていない）
  final String? email;
  final DateTime? lastPulled;
  final DateTime? lastSent;
  final DateTime? lastReceived;

  /// 最後に起きたエラー（利用者向けの説明）
  final String? error;
  final DateTime? errorAt;

  SyncStatus copyWith({
    bool? connected,
    String? email,
    bool clearEmail = false,
    DateTime? lastPulled,
    DateTime? lastSent,
    DateTime? lastReceived,
    String? error,
    DateTime? errorAt,
    bool clearError = false,
  }) => SyncStatus(
    connected: connected ?? this.connected,
    email: clearEmail ? null : (email ?? this.email),
    lastPulled: lastPulled ?? this.lastPulled,
    lastSent: lastSent ?? this.lastSent,
    lastReceived: lastReceived ?? this.lastReceived,
    error: clearError ? null : (error ?? this.error),
    errorAt: clearError ? null : (errorAt ?? this.errorAt),
  );
}

final syncStatus = ValueNotifier<SyncStatus>(const SyncStatus());

void _update(SyncStatus Function(SyncStatus s) f) =>
    syncStatus.value = f(syncStatus.value);

void syncConnected(bool ok, {Object? error}) => _update(
  (s) => s.copyWith(
    connected: ok,
    error: error == null ? null : describeSyncError(error, 'クラウドの準備'),
    errorAt: error == null ? null : DateTime.now(),
  ),
);

void syncSignedIn(String? email) => _update(
  (s) =>
      email == null ? s.copyWith(clearEmail: true) : s.copyWith(email: email),
);

void syncPulled() => _update((s) => s.copyWith(lastPulled: DateTime.now()));

void syncSent() => _update((s) => s.copyWith(lastSent: DateTime.now()));

void syncReceived() => _update((s) => s.copyWith(lastReceived: DateTime.now()));

/// エラーを記録する（開発用のログにも出す）
void syncError(String where, Object e) {
  debugPrint('同期のエラー（$where）: $e');
  _update(
    (s) =>
        s.copyWith(error: describeSyncError(e, where), errorAt: DateTime.now()),
  );
}

void syncClearError() => _update((s) => s.copyWith(clearError: true));

/// エラーを利用者に分かることばにする
String describeSyncError(Object e, String where) {
  final t = '$e';
  final String why;
  if (t.contains('permission-denied') || t.contains('PERMISSION_DENIED')) {
    why = 'クラウドへの保存が許可されていません（Firestore のルールの反映が必要）';
  } else if (t.contains('unauthenticated')) {
    why = 'ログインが切れています。いったんログアウトして、もう一度ログインしてください';
  } else if (t.contains('unavailable') ||
      t.contains('network') ||
      t.contains('Failed to fetch')) {
    why = 'インターネットにつながりません';
  } else if (t.contains('resource-exhausted') || t.contains('quota')) {
    why = 'クラウドの1日の利用上限に達しました（明日またためしてください）';
  } else {
    why = t.length > 160 ? '${t.substring(0, 160)}…' : t;
  }
  return '$where：$why';
}
