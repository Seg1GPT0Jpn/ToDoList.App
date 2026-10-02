import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg_game/rpg_game.dart';

import '../versus/online_room.dart';

/// Firestore の `versus_rooms/{部屋番号}` を使うオンライン対戦。
///
/// Google でログインしている人どうしで遊べる。ルールは firestore.rules を参照。
class FirestoreVersusBackend implements VersusRoomBackend {
  FirestoreVersusBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const collection = 'versus_rooms';

  /// この時間より古い部屋は、使われていないとみなして上書きしてよい
  static const staleAfter = Duration(hours: 3);

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _db.collection(collection).doc(code);

  @override
  String? get userId => _auth.currentUser?.uid;

  String _requireUser() {
    final uid = userId;
    if (uid == null) {
      throw const RoomException('オンライン対戦は、Google でログインすると遊べます');
    }
    return uid;
  }

  @override
  Future<String> create(VersusRoomConfig config, String hostName) async {
    final uid = _requireUser();
    for (var tries = 0; tries < 8; tries++) {
      final code = VersusRoomBackend.newCode();
      bool ok;
      try {
        ok = await _db.runTransaction<bool>((tx) async {
          final snap = await tx.get(_doc(code));
          final data = snap.data();
          if (data != null) {
            final at = (data['createdAt'] as Timestamp?)?.toDate();
            final stale =
                at == null || DateTime.now().difference(at) > staleAfter;
            if (!stale && data['closed'] != true) return false;
          }
          tx.set(_doc(code), {
            ...OnlineRoom(
              code: code,
              config: config,
              hostName: hostName,
              hostId: uid,
            ).toMap(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          return true;
        });
      } on FirebaseException {
        // ほかの人の古い部屋など、使えない番号だった
        ok = false;
      }
      if (ok) return code;
    }
    throw const RoomException('部屋を作れませんでした。もう一度ためしてください');
  }

  @override
  Future<OnlineRoom> join(String code, String guestName) async {
    final uid = _requireUser();
    return _db.runTransaction<OnlineRoom>((tx) async {
      final snap = await tx.get(_doc(code));
      final data = snap.data();
      if (data == null || data['closed'] == true) {
        throw const RoomException('その番号の部屋は見つかりません');
      }
      final room = OnlineRoom.fromMap(data);
      if (room.hostId == uid) {
        throw const RoomException('自分の部屋には入れません（別の端末・別のアカウントで入ってください）');
      }
      if (room.full && room.guestId != uid) {
        throw const RoomException('その部屋はもう満員です');
      }
      tx.update(_doc(code), {'guest': uid, 'guestName': guestName});
      return room.copyWith(guestId: uid, guestName: guestName);
    });
  }

  @override
  Stream<OnlineRoom?> watch(String code) => _doc(code).snapshots().map((s) {
    final data = s.data();
    return data == null ? null : OnlineRoom.fromMap(data);
  });

  @override
  Future<bool> send(
    String code,
    VersusEvent event,
    bool Function(List<VersusEvent> before) accepts,
  ) async {
    try {
      return await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(_doc(code));
        final data = snap.data();
        if (data == null) return false;
        final room = OnlineRoom.fromMap(data);
        if (room.closed || !accepts(room.events)) return false;
        // arrayUnion は同じ中身の出来事をまとめてしまうので、配列ごと書きこむ
        tx.update(_doc(code), {
          'events': [
            for (final e in [...room.events, event]) e.toMap(),
          ],
        });
        return true;
      });
    } on FirebaseException {
      return false;
    }
  }

  @override
  Future<void> close(String code) async {
    try {
      await _doc(code).update({'closed': true});
    } on FirebaseException {
      // すでに消えていてもかまわない
    }
  }
}
