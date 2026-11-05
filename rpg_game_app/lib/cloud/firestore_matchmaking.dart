import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg_game/rpg_game.dart';

import '../versus/matchmaking.dart';

/// Firestore を使うランダム対戦の待ち合わせ。
///
/// - `match_queue/{uid}`：待っている人（ニックネームと時刻だけ）
/// - `ghosts/{自動ID}`：ゴースト（ニックネームと、問題ごとの時間・正誤）
/// - `player_reports/{自動ID}`：報告（アプリからは読めない）
///
/// ルールは firestore.rules。
class FirestoreMatchmaking implements MatchmakingBackend {
  FirestoreMatchmaking(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _queue =>
      _db.collection('match_queue');

  DocumentReference<Map<String, dynamic>> get _mine => _queue.doc(userId);

  static QueueEntry? _parse(String uid, Map<String, dynamic>? d) {
    if (d == null) return null;
    final since = d['since'], ping = d['ping'];
    if (since is! Timestamp || ping is! Timestamp) return null;
    return QueueEntry(
      uid: uid,
      name: d['name'] as String? ?? '',
      since: since.toDate(),
      ping: ping.toDate(),
      room: d['room'] as String?,
      by: d['by'] as String?,
    );
  }

  @override
  Future<void> enter(String name, DateTime now) => _mine.set({
    'name': name,
    'since': Timestamp.fromDate(now),
    'ping': Timestamp.fromDate(now),
    'room': null,
    'by': null,
  });

  @override
  Future<void> ping(DateTime now) =>
      _mine.update({'ping': Timestamp.fromDate(now)});

  @override
  Future<List<QueueEntry>> waiting() async {
    final snap = await _queue.orderBy('ping', descending: true).limit(20).get();
    return [for (final d in snap.docs) ?_parse(d.id, d.data())];
  }

  @override
  Future<bool> claim(String uid, String room) async {
    try {
      return await _db.runTransaction<bool>((tx) async {
        final ref = _queue.doc(uid);
        final snap = await tx.get(ref);
        final d = snap.data();
        if (d == null || d['room'] != null) return false;
        tx.update(ref, {'room': room, 'by': userId});
        return true;
      });
    } on FirebaseException {
      return false;
    }
  }

  @override
  Stream<QueueEntry?> watchMine() =>
      _mine.snapshots().map((s) => _parse(s.id, s.data()));

  @override
  Future<void> leave() async {
    try {
      await _mine.delete();
    } on FirebaseException {
      // もう消えていてもかまわない
    }
  }

  @override
  Future<GhostRun?> randomGhost(Random random) async {
    final r = random.nextDouble();
    final ghosts = _db.collection('ghosts');
    var snap = await ghosts
        .where('r', isGreaterThanOrEqualTo: r)
        .orderBy('r')
        .limit(5)
        .get();
    if (snap.docs.isEmpty) {
      snap = await ghosts.orderBy('r').limit(5).get();
    }
    final runs = [
      for (final d in snap.docs)
        if (d.data()['uid'] != userId) ?GhostRun.fromMap(d.data()),
    ].where((g) => g.usable).toList();
    return runs.isEmpty ? null : runs[random.nextInt(runs.length)];
  }

  @override
  Future<void> saveGhost(GhostRun run) => _db.collection('ghosts').add({
    ...run.toMap(),
    'uid': userId,
    'r': Random().nextDouble(),
    'at': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> report(String uid, PlayerReportReason reason) =>
      _db.collection('player_reports').add({
        'from': userId,
        'about': uid,
        'reason': reason.name,
        'at': FieldValue.serverTimestamp(),
      });
}
