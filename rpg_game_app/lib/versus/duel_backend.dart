import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

/// 単語チャレンジができなかった理由（画面に出す言葉）
class DuelException implements Exception {
  const DuelException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 単語チャレンジ（リンクで遊ぶ早押し）の保存先
abstract class DuelBackend {
  String? get userId;

  /// 作って ID をつける（作った人の結果も一緒に入れる）
  Future<WordDuel> create(WordDuel draft, DuelResult mine);

  /// 見る（なければ null）
  Future<WordDuel?> fetch(String id);

  /// 自分の結果を入れる（1人1回）
  Future<void> submit(String id, DuelResult result);
}

/// テストとサーバーのない版の、端末の中だけの保存先
class MemoryDuelBackend implements DuelBackend {
  MemoryDuelBackend({
    this.userId = 'me',
    Map<String, WordDuel>? store,
    Random? random,
  }) : duels = store ?? {},
       _random = random ?? Random(1);

  final Map<String, WordDuel> duels;
  final Random _random;

  @override
  final String? userId;

  String _uid() =>
      userId ?? (throw const DuelException('単語チャレンジは、Google でログインすると使えます'));

  @override
  Future<WordDuel> create(WordDuel draft, DuelResult mine) async {
    final uid = _uid();
    final id = WordDuel.newId(_random);
    final d = WordDuel(
      id: id,
      ownerId: uid,
      ownerName: draft.ownerName,
      source: draft.source,
      sourceId: draft.sourceId,
      title: draft.title,
      numbers: draft.numbers,
      seed: draft.seed,
      results: {uid: mine},
      expiresAt: DateTime.now().add(WordDuel.lifetime),
    );
    duels[id] = d;
    return d;
  }

  @override
  Future<WordDuel?> fetch(String id) async {
    _uid();
    return duels[id];
  }

  @override
  Future<void> submit(String id, DuelResult result) async {
    final uid = _uid();
    final d = duels[id];
    if (d == null) throw const DuelException('チャレンジが見つかりません');
    if (d.played(uid)) throw const DuelException('このチャレンジは、もう挑戦ずみです');
    if (d.full) throw const DuelException('このチャレンジは満員です');
    if (d.expired(DateTime.now())) {
      throw const DuelException('このチャレンジは期限切れです');
    }
    duels[id] = d.withResult(uid, result);
  }
}
