import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../notice/notice_backend.dart';

/// Firestore を使うお知らせとテスターの申しこみ。
///
/// - `app_notice/main`：お知らせ。だれでも読めて、書けるのは管理者だけ
/// - `tester_signups/{uid}`：Gmail・名前・日時。本人が自分の分だけ書けて、読めるのは本人と管理者
/// - `feedback/{自動のID}`：高校名・クラス・ニックネーム・内容。だれでも送れて、読めるのは管理者だけ
///
/// ルールは firestore.rules。
class FirestoreNoticeBackend extends NoticeBackend {
  FirestoreNoticeBackend(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _notice =>
      _db.collection('app_notice').doc('main');

  CollectionReference<Map<String, dynamic>> get _signups =>
      _db.collection('tester_signups');

  @override
  String? get userId => _auth.currentUser?.uid;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Future<AppNotice?> load() async {
    try {
      return AppNotice.fromMap((await _notice.get()).data());
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<void> save(AppNotice notice) => _notice.set({
    ...notice.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  static TesterSignup _from(String uid, Map<String, dynamic> d) => TesterSignup(
    uid: uid,
    email: d['email'] is String ? d['email'] as String : '',
    name: d['name'] is String ? d['name'] as String : '',
    at: d['at'] is Timestamp ? (d['at'] as Timestamp).toDate() : null,
  );

  @override
  Future<TesterSignup?> mySignup() async {
    final uid = userId;
    if (uid == null) return null;
    try {
      final d = (await _signups.doc(uid).get()).data();
      return d == null ? null : _from(uid, d);
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<void> signup(String email, String name) async {
    final uid = userId;
    if (uid == null) throw StateError('ログインが必要です');
    await _signups.doc(uid).set({
      'email': email.trim(),
      'name': name,
      'at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> sendFeedback(AppFeedback f) => _db.collection('feedback').add({
    ...f.toMap(),
    'uid': userId ?? '',
    'at': FieldValue.serverTimestamp(),
  });

  @override
  Future<List<AppFeedback>> feedbacks() async {
    final q = await _db
        .collection('feedback')
        .orderBy('at', descending: true)
        .limit(200)
        .get();
    String str(Map<String, dynamic> d, String k) =>
        d[k] is String ? d[k] as String : '';
    return [
      for (final doc in q.docs)
        AppFeedback(
          school: str(doc.data(), 'school'),
          className: str(doc.data(), 'class'),
          nickname: str(doc.data(), 'nickname'),
          body: str(doc.data(), 'body'),
          uid: str(doc.data(), 'uid'),
          platform: str(doc.data(), 'platform'),
          at: doc.data()['at'] is Timestamp
              ? (doc.data()['at'] as Timestamp).toDate()
              : null,
        ),
    ];
  }

  @override
  Future<List<TesterSignup>> signups() async {
    final q = await _signups.orderBy('at', descending: true).limit(200).get();
    return [for (final d in q.docs) _from(d.id, d.data())];
  }
}
