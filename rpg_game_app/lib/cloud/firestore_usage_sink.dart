import 'package:cloud_firestore/cloud_firestore.dart';

import '../app/usage_meter.dart';

/// Firestore の `usage/{YYYY-MM-DD}` に、機能ごとの回数だけを足す。
/// だれのものかは入れない。読めるのは Firebase の管理画面からだけ（firestore.rules）
class FirestoreUsageSink implements UsageSink {
  FirestoreUsageSink(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> count(String day, String feature) => _db
      .collection('usage')
      .doc(day)
      .set({feature: FieldValue.increment(1)}, SetOptions(merge: true));
}
