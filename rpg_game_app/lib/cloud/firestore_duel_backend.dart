import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg_game/rpg_game.dart';

import '../versus/duel_backend.dart';

/// Firestore の `duels/{ID}` を使う単語チャレンジ。
///
/// 置くのは、出題のもと（つづ単の一覧 ID か単語帳の名前）・番号・種と、
/// 1人ずつの名前・正解数・点数だけ。単語の中身は送らない。ルールは firestore.rules。
class FirestoreDuelBackend implements DuelBackend {
  FirestoreDuelBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const collection = 'duels';

  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      _db.collection(collection).doc(id);

  @override
  String? get userId => _auth.currentUser?.uid;

  String _uid() =>
      userId ?? (throw const DuelException('単語チャレンジは、Google でログインすると使えます'));

  static Never _fail(Object e) {
    if (e is DuelException) throw e;
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw const DuelException('できませんでした（挑戦ずみ・期限切れ・満員、またはサーバーの準備中です）');
      }
      if (e.code == 'unavailable') {
        throw const DuelException('インターネットにつながっていないようです');
      }
    }
    throw DuelException('うまくいきませんでした：$e');
  }

  @override
  Future<WordDuel> create(WordDuel draft, DuelResult mine) async {
    final uid = _uid();
    try {
      for (var tries = 0; tries < 5; tries++) {
        final id = WordDuel.newId();
        final expires = DateTime.now().add(WordDuel.lifetime);
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
          expiresAt: expires,
        );
        final ok = await _db.runTransaction<bool>((tx) async {
          if ((await tx.get(_doc(id))).exists) return false;
          tx.set(_doc(id), {
            ...d.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expires),
          });
          return true;
        });
        if (ok) return d;
      }
    } catch (e) {
      _fail(e);
    }
    throw const DuelException('うまくいきませんでした。もう一度ためしてください');
  }

  @override
  Future<WordDuel?> fetch(String id) async {
    _uid();
    try {
      final snap = await _doc(id).get();
      final data = snap.data();
      if (data == null) return null;
      return WordDuel.fromMap(
        id,
        data,
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> submit(String id, DuelResult result) async {
    final uid = _uid();
    try {
      await _doc(id).update({'results.$uid': result.toMap()});
    } catch (e) {
      _fail(e);
    }
  }
}
