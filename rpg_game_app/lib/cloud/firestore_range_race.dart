import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../study/range_race.dart';
import '../versus/duel_backend.dart';

/// Firestore の `range_race/{試験}/entries/{uid}` を使う、範囲の進みぐあいランキング。
///
/// 置くのはニックネームと進みぐあいの数字だけ。ルールは firestore.rules。
class FirestoreRangeRaceBackend extends RangeRaceBackend {
  FirestoreRangeRaceBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String board) =>
      _db.collection('range_race').doc(board).collection('entries');

  @override
  String? get userId => _auth.currentUser?.uid;

  static Never _fail(Object e) {
    if (e is DuelException) throw e;
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw const DuelException('ランキングに送れませんでした（サーバーの準備中かもしれません）');
      }
      if (e.code == 'unavailable') {
        throw const DuelException('インターネットにつながっていないようです');
      }
    }
    throw DuelException('うまくいきませんでした：$e');
  }

  @override
  Future<void> submit(String board, RangeRaceEntry entry) async {
    final uid = userId ?? (throw const DuelException(RangeRaceText.needLogin));
    try {
      await _entries(board)
          .doc(uid)
          .set({...entry.toMap(), 'at': FieldValue.serverTimestamp()});
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<RangeRaceEntry>> ranking(String board, {int limit = 200}) async {
    try {
      final snap = await _entries(board)
          .orderBy('pct', descending: true)
          .limit(limit)
          .get();
      return RangeRaceEntry.rank([
        for (final d in snap.docs) ?RangeRaceEntry.fromMap(d.id, d.data()),
      ]);
    } catch (e) {
      _fail(e);
    }
  }
}
