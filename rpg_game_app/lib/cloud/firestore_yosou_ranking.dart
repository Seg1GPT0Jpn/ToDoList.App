import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../study/yosou_ranking.dart';
import '../versus/duel_backend.dart';

/// Firestore の `yosou_rankings/{予想問題}/entries/{uid}` を使うランキング。
///
/// 置くのはニックネーム・点数・満点・かかった時間・未採点の数だけ。ルールは firestore.rules。
class FirestoreYosouRankBackend extends YosouRankBackend {
  FirestoreYosouRankBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String examId) =>
      _db.collection('yosou_rankings').doc(examId).collection('entries');

  @override
  String? get userId => _auth.currentUser?.uid;

  String _uid() =>
      userId ?? (throw const DuelException(YosouRankText.needLogin));

  static Never _fail(Object e) {
    if (e is DuelException) throw e;
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw const DuelException('できませんでした（登録ずみ・期限切れ、またはサーバーの準備中です）');
      }
      if (e.code == 'unavailable') {
        throw const DuelException('インターネットにつながっていないようです');
      }
    }
    throw DuelException('うまくいきませんでした：$e');
  }

  @override
  Future<YosouRankEntry?> mine(String examId) async {
    final uid = _uid();
    try {
      final snap = await _entries(examId).doc(uid).get();
      return YosouRankEntry.fromMap(uid, snap.data());
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> enter(String examId, YosouRankEntry entry) async {
    final uid = _uid();
    try {
      final doc = _entries(examId).doc(uid);
      await _db.runTransaction((tx) async {
        if ((await tx.get(doc)).exists) {
          throw const DuelException('もう登録ずみです');
        }
        tx.set(doc, {...entry.toMap(), 'at': FieldValue.serverTimestamp()});
      });
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> rescore(String examId, int score, int unscored) async {
    final uid = _uid();
    try {
      await _entries(examId).doc(uid).update({
        'score': score,
        'unscored': unscored,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<YosouRankEntry>> ranking(String examId, {int limit = 100}) async {
    try {
      final snap = await _entries(examId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();
      return YosouRankEntry.rank([
        for (final d in snap.docs) ?YosouRankEntry.fromMap(d.id, d.data()),
      ]);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<({int players, int above})> standing(String examId, int score) async {
    try {
      final col = _entries(examId);
      final players = await col.count().get();
      final above = await col
          .where('score', isGreaterThan: score)
          .count()
          .get();
      return (players: players.count ?? 0, above: above.count ?? 0);
    } catch (e) {
      _fail(e);
    }
  }
}
