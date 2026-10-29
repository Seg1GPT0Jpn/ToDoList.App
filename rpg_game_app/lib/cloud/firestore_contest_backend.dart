import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg_game/rpg_game.dart';

import '../versus/contest_backend.dart';
import '../versus/duel_backend.dart';

/// Firestore を使う週替わり単語バトル。
///
/// - `vocab_contest_config/main`：日程の設定。だれでも読めて、書けるのは管理者だけ
/// - `vocab_contests/{回のID}/entries/{uid}`：ニックネーム・正解数・点数。
///   その日（日本時間）のうちに1人1回作れて、点数を入れられるのは1回だけ
///
/// 単語の中身は置かない。ルールは firestore.rules。
class FirestoreContestBackend extends ContestBackend {
  FirestoreContestBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _config =>
      _db.collection('vocab_contest_config').doc('main');

  CollectionReference<Map<String, dynamic>> _entries(String roundId) =>
      _db.collection('vocab_contests').doc(roundId).collection('entries');

  @override
  String? get userId => _auth.currentUser?.uid;

  @override
  String? get email => _auth.currentUser?.email;

  String _uid() => userId ?? (throw const DuelException(ContestText.needLogin));

  static Never _fail(Object e) {
    if (e is DuelException) throw e;
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw const DuelException(
          'できませんでした（挑戦ずみ・時間切れ・バトルの日ではない、またはサーバーの準備中です）',
        );
      }
      if (e.code == 'unavailable') {
        throw const DuelException('インターネットにつながっていないようです');
      }
    }
    throw DuelException('うまくいきませんでした：$e');
  }

  @override
  Future<ContestConfig> loadConfig() async {
    try {
      final snap = await _config.get();
      return ContestConfig.fromMap(snap.data());
    } on FirebaseException {
      // 読めなければ、はじめの日程で動く
      return ContestConfig.initial;
    }
  }

  @override
  Future<void> saveConfig(ContestConfig config) async {
    if (!isAdmin) throw const DuelException('日程を変えられるのは管理者だけです');
    try {
      await _config.set({
        ...config.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': email,
      });
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ContestEntry?> mine(String roundId) async {
    final uid = _uid();
    try {
      final snap = await _entries(roundId).doc(uid).get();
      return ContestEntry.fromMap(uid, snap.data());
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> start(String roundId, String name) async {
    final uid = _uid();
    try {
      final doc = _entries(roundId).doc(uid);
      await _db.runTransaction((tx) async {
        if ((await tx.get(doc)).exists) {
          throw const DuelException('このバトルは、もう挑戦ずみです');
        }
        tx.set(doc, {
          'name': name,
          'correct': 0,
          'score': 0,
          'done': false,
          'startedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> finish(String roundId, int correct, int score) async {
    final uid = _uid();
    try {
      await _entries(roundId).doc(uid).update({
        'correct': correct,
        'score': score,
        'done': true,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<ContestEntry>> ranking(String roundId, {int limit = 100}) async {
    try {
      // 点数だけで並べる（始めただけの人は 0 点なので下に来る。done は手元で除く）
      final snap = await _entries(roundId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();
      return ContestEntry.rank([
        for (final d in snap.docs) ?ContestEntry.fromMap(d.id, d.data()),
      ]);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<({int players, int above})> standing(String roundId, int score) async {
    try {
      final col = _entries(roundId);
      final players = await col.where('done', isEqualTo: true).count().get();
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
