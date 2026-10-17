import 'dart:async';

import '../models/rpg_progress.dart';

/// 進行状況の保存先。
///
/// 移植時は Firestore 版（users/{uid}/rpg_progress/main を snapshots() で監視）を
/// 実装し、画面は既存と同じく StreamBuilder で [watch] を購読する。
abstract class ProgressRepository {
  Stream<RpgProgress> watch();
  Future<RpgProgress> load();
  Future<void> save(RpgProgress progress);

  /// 購入済みフラグを保存する。
  Future<void> markWorldPurchased(String worldId, {required String source});
}

/// テスト・プロトタイプ用のメモリ上の実装。
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([RpgProgress initial = RpgProgress.initial])
      : _progress = initial;

  RpgProgress _progress;
  final _controller = StreamController<RpgProgress>.broadcast();

  @override
  Stream<RpgProgress> watch() async* {
    yield _progress;
    yield* _controller.stream;
  }

  @override
  Future<RpgProgress> load() async => _progress;

  @override
  Future<void> save(RpgProgress progress) async {
    // Firestore と同じくシリアライズを通して保存し、toMap/fromMap の抜けを検出する
    _progress = RpgProgress.fromMap(progress.toMap());
    _controller.add(_progress);
  }

  @override
  Future<void> markWorldPurchased(String worldId,
      {required String source}) async {
    await save(_progress.copyWith(
      purchasedWorldIds: {..._progress.purchasedWorldIds, worldId},
    ));
  }

  Future<void> dispose() => _controller.close();
}
