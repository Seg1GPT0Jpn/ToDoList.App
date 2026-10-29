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

  /// Firestore の時刻（Timestamp）を DateTime にしてから読む
  static ContestEntry? _entry(String uid, Map<String, dynamic>? data) {
    if (data == null) return null;
    final at = data['startedAt'];
    return ContestEntry.fromMap(uid, {
      ...data,
      'startedAt': at is Timestamp ? at.toDate() : null,
    });
  }

  @override
  Future<ContestEntry?> mine(String roundId) async {
    final uid = _uid();
    try {
      final snap = await _entries(roundId).doc(uid).get();
      return _entry(uid, snap.data());
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ContestEntry> start(String roundId, String name) async {
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
          'points': 0,
          'done': false,
          'section': 0,
          'parts': <int>[],
          'startedAt': FieldValue.serverTimestamp(),
        });
      });
      // サーバーの時刻を読みなおす（続きから解ける時間の計算に使う）
      return (await mine(roundId)) ??
          ContestEntry(
            uid: uid,
            name: name,
            correct: 0,
            score: 0,
            done: false,
            startedAt: DateTime.now(),
          );
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> savePart(String roundId, ContestEntry entry) async {
    final uid = _uid();
    try {
      await _entries(roundId).doc(uid).update({
        'correct': entry.correct,
        'score': entry.score,
        'points': entry.points,
        'done': entry.done,
        'section': entry.section,
        'parts': entry.parts,
        if (entry.parts.isNotEmpty) 'p${entry.parts.length - 1}': entry.parts.last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<ContestEntry>> ranking(
    String roundId, {
    int? part,
    int limit = 100,
  }) async {
    try {
      // 総合は得点（score）、種類ごとは p0〜p3 で並べる（その種類を解いていない人は出ない）。
      // 始めただけの人は 0 なので下に来る。手元で除く
      final snap = await _entries(roundId)
          .orderBy(part == null ? 'score' : 'p$part', descending: true)
          .limit(limit)
          .get();
      return ContestEntry.rankBy([
        for (final d in snap.docs) ?_entry(d.id, d.data()),
      ], part);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<({int players, int above})> standing(
    String roundId,
    int score, {
    int? part,
  }) async {
    try {
      final col = _entries(roundId);
      final field = part == null ? 'score' : 'p$part';
      final players = part == null
          ? await col.where('section', isGreaterThan: 0).count().get()
          : await col.where(field, isGreaterThanOrEqualTo: 0).count().get();
      final above = await col.where(field, isGreaterThan: score).count().get();
      return (players: players.count ?? 0, above: above.count ?? 0);
    } catch (e) {
      _fail(e);
    }
  }
}
