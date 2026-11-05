import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rpg_game/rpg_game.dart';

import '../classroom/classroom_backend.dart';

/// Firestore の `classrooms/{6ケタのコード}` を使うクラスルーム。
///
/// - クラスの文書：名前・作った人・メンバー（ID → ニックネーム）・範囲・期限
/// - `classrooms/{コード}/boss/{範囲ID}`：共闘ボスに与えた正解数の合計
///
/// 共有するのは範囲（単語帳の名前・番号・日付）だけで、単語の中身は送らない。
/// だれが何問正解したかもサーバーには置かない（合計だけ）。ルールは firestore.rules。
class FirestoreClassroomBackend implements ClassroomBackend {
  FirestoreClassroomBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const collection = 'classrooms';

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _db.collection(collection).doc(code);

  @override
  String? get userId => _auth.currentUser?.uid;

  String _uid() {
    final u = userId;
    if (u == null) {
      throw const ClassroomException('クラスルームは、Google でログインすると使えます');
    }
    return u;
  }

  static Classroom _parse(String code, Map<String, dynamic> data) =>
      Classroom.fromMap(
        code,
        data,
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      );

  /// Firestore のエラーを、画面に出せる言葉にする
  static Never _fail(Object e) {
    if (e is ClassroomException) throw e;
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        throw const ClassroomException(
          'できませんでした（クラスに入れない・期限切れ・満員、またはサーバーの準備中です）',
        );
      }
      if (e.code == 'unavailable') {
        throw const ClassroomException('インターネットにつながっていないようです');
      }
    }
    throw ClassroomException('うまくいきませんでした：$e');
  }

  @override
  Future<Classroom> create(String name, String ownerName) async {
    final uid = _uid();
    final owner = Classroom.cleanName(ownerName, fallback: 'なまえ');
    for (var tries = 0; tries < 8; tries++) {
      final code = Classroom.newCode();
      try {
        final ok = await _db.runTransaction<bool>((tx) async {
          final snap = await tx.get(_doc(code));
          if (snap.exists) return false;
          tx.set(_doc(code), {
            'code': code,
            'name': Classroom.cleanName(name),
            'ownerId': uid,
            'ownerName': owner,
            'members': {uid: owner},
            'tasks': <Object>[],
            'closed': false,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(Classroom.lifetime),
            ),
          });
          return true;
        });
        if (ok) return (await fetch(code))!;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') _fail(e);
        // 同じコードがあったなど。別のコードでもう一度
      }
    }
    throw const ClassroomException('クラスを作れませんでした。もう一度ためしてください');
  }

  @override
  Future<Classroom> join(String code, String nickname) async {
    final uid = _uid();
    if (!Classroom.validCode(code)) {
      throw const ClassroomException('コードは6ケタの数字です');
    }
    try {
      final snap = await _doc(code).get();
      final data = snap.data();
      if (data == null) {
        throw const ClassroomException('そのコードのクラスは見つかりません');
      }
      final room = _parse(code, data);
      if (room.isMember(uid)) return room;
      if (room.closed || room.expired(DateTime.now())) {
        throw const ClassroomException('このクラスは、もう新しく入れません');
      }
      if (room.full) throw const ClassroomException('このクラスは満員です');
      await _doc(code).update({
        'members.$uid': Classroom.cleanName(nickname, fallback: 'なまえ'),
      });
      return (await fetch(code))!;
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<Classroom?> fetch(String code) async {
    try {
      final snap = await _doc(code).get();
      final data = snap.data();
      return data == null ? null : _parse(code, data);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Stream<Classroom?> watch(String code) =>
      _doc(code)
          .snapshots()
          .map((s) => s.data() == null ? null : _parse(code, s.data()!))
          .handleError((Object _) {});

  Future<void> _update(String code, Map<String, Object?> data) async {
    _uid();
    try {
      await _doc(code).update(data);
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> saveTasks(String code, List<ClassTask> tasks) => _update(code, {
    'tasks': [for (final t in tasks.take(Classroom.maxTasks)) t.toMap()],
  });

  @override
  Future<void> rename(String code, String name) =>
      _update(code, {'name': Classroom.cleanName(name)});

  @override
  Future<void> leave(String code) =>
      _update(code, {'members.${_uid()}': FieldValue.delete()});

  @override
  Future<void> remove(String code, String userId) =>
      _update(code, {'members.$userId': FieldValue.delete()});

  @override
  Future<void> close(String code) => _update(code, {'closed': true});

  @override
  Future<String> renew(String code) async {
    final uid = _uid();
    final old = await fetch(code);
    if (old == null) throw const ClassroomException('クラスが見つかりません');
    if (!old.isOwner(uid)) {
      throw const ClassroomException('これは作った人だけができます');
    }
    for (var tries = 0; tries < 8; tries++) {
      final next = Classroom.newCode();
      try {
        final ok = await _db.runTransaction<bool>((tx) async {
          final snap = await tx.get(_doc(next));
          if (snap.exists) return false;
          tx.set(_doc(next), {
            'code': next,
            'name': old.name,
            'ownerId': uid,
            'ownerName': old.ownerName,
            // 作るときは自分だけ（ルール）。メンバーはあとから移す
            'members': {uid: old.ownerName},
            'tasks': [for (final t in old.tasks) t.toMap()],
            'closed': false,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(Classroom.lifetime),
            ),
          });
          return true;
        });
        if (ok) {
          await _doc(next).update({'members': old.members});
          await close(code);
          return next;
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') _fail(e);
      }
    }
    throw const ClassroomException('新しいコードを作れませんでした。もう一度ためしてください');
  }

  @override
  Stream<Map<String, int>> watchBoss(String code) => _doc(code)
      .collection('boss')
      .snapshots()
      .map(
        (q) => {
          for (final d in q.docs)
            d.id: (d.data()['dealt'] as num?)?.toInt() ?? 0,
        },
      )
      .handleError((Object _) {});

  @override
  Future<void> hit(String code, String taskId, int amount) async {
    _uid();
    var left = amount;
    try {
      // ルールで1回に足せる数が決まっているので、分けて書きこむ
      while (left > 0) {
        final n = left > ClassBoss.maxPerWrite ? ClassBoss.maxPerWrite : left;
        await _doc(code)
            .collection('boss')
            .doc(taskId)
            .set({'dealt': FieldValue.increment(n)}, SetOptions(merge: true));
        left -= n;
      }
    } catch (e) {
      _fail(e);
    }
  }
}
