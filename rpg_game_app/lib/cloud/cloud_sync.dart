import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/profile_repository.dart';
import '../data/meta_store.dart';
import '../data/prefs_progress_repository.dart';
import '../firebase_options.dart';
import 'login_problem.dart';

/// 進行状況とプロフィールを Firestore と同期する。
///
/// - Google でログインしていないあいだは、これまでどおり端末の中だけに保存する
/// - ログインすると、クラウドに記録があればそれを読み込み（クラウド優先）、
///   なければ端末の記録をクラウドに上げる
/// - ログイン中は、保存するたびにクラウドにも書き込む
///
/// 個人用単語帳（LEAP など）は同期しない。端末の中だけに置く。
class CloudSync {
  CloudSync._(this._auth, this._db, this._progress, this._profiles, this._meta);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final PrefsProgressRepository _progress;
  final ProfileRepository _profiles;
  final MetaStore _meta;

  FirebaseAuth get auth => _auth;

  /// Firebase を初期化する。設定がない（flutterfire configure をしていない）
  /// ときは null を返し、端末の中だけで動かす。
  static Future<CloudSync?> start({
    required PrefsProgressRepository progress,
    required ProfileRepository profiles,
    required MetaStore meta,
  }) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase を使わずに起動します: $e');
      return null;
    }
    final sync = CloudSync._(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
      progress,
      profiles,
      meta,
    );
    progress.onSaved = sync._pushProgress;
    profiles.onSaved = sync._pushProfile;
    meta.onLearningSaved = (r) =>
        sync._push(RpgFirestorePaths.learningDoc, r.toMap());
    meta.onJournalSaved = (j) =>
        sync._push(RpgFirestorePaths.journalDoc, j.toMap());
    // 前回のログインが残っていれば、クラウドの記録を読み込む
    final user = await sync._auth.authStateChanges().first;
    if (user != null) {
      unawaited(sync._pullAndLink(user));
    } else if (profiles.load().isGoogleLinked) {
      // ログインが切れていたら、登録していない表示にもどす
      await profiles.replaceLocal(profiles.load().copyWith(unlinkGoogle: true));
    }
    return sync;
  }

  String? get _uid => _auth.currentUser?.uid;

  /// 起動したときにログインが残っていたとき（Web でページを移動するログインから
  /// もどってきたときもふくむ）。読み込んだあと、プロフィールを登録ずみの表示にする
  Future<void> _pullAndLink(User user) async {
    await pull();
    final p = _profiles.load();
    if (p.isGoogleLinked) return;
    final email = user.email ?? '';
    await _profiles.save(
      p.copyWith(
        googleEmail: email,
        googleDisplayName: user.displayName ?? email.split('@').first,
        linkedAt: DateTime.now(),
      ),
    );
  }

  /// ログインした直後に呼ぶ。クラウドに記録があれば端末に読み込み、
  /// なければ端末の記録をクラウドに上げる。
  ///
  /// 読み書きできなかったときは、その原因を返す（端末の記録はそのまま使える）。
  Future<LoginProblem?> pull() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      await _pull(uid).timeout(const Duration(seconds: 20));
      return null;
    } on TimeoutException {
      return LoginProblem.forCode('cloud-unavailable', detail: 'timeout');
    } on FirebaseException catch (e) {
      debugPrint('クラウドの記録を読み込めませんでした: $e');
      final text = '${e.code} ${e.message}';
      if (e.code == 'permission-denied') {
        return LoginProblem.forCode('permission-denied', detail: text);
      }
      if (e.code == 'not-found' ||
          (e.message ?? '').contains('does not exist')) {
        return LoginProblem.forCode('firestore-missing', detail: text);
      }
      return LoginProblem.forCode('cloud-unavailable', detail: text);
    } catch (e) {
      debugPrint('クラウドの記録を読み込めませんでした: $e');
      return LoginProblem.forCode('cloud-unavailable', detail: '$e');
    }
  }

  Future<void> _pull(String uid) async {
    final progressSnap = await _db
        .doc(RpgFirestorePaths.progressDoc(uid))
        .get();
    final progressData = progressSnap.data();
    if (progressData != null) {
      await _progress.replaceLocal(RpgProgress.fromMap(_plain(progressData)));
    } else {
      await _pushProgress(await _progress.load());
    }
    final profileSnap = await _db.doc(RpgFirestorePaths.profileDoc(uid)).get();
    final profileData = profileSnap.data();
    if (profileData != null) {
      await _profiles.replaceLocal(PlayerProfile.fromMap(_plain(profileData)));
    } else {
      await _pushProfile(_profiles.load());
    }
    final learning = (await _db.doc(RpgFirestorePaths.learningDoc(uid)).get())
        .data();
    final journal = (await _db.doc(RpgFirestorePaths.journalDoc(uid)).get())
        .data();
    await _meta.replaceLocal(
      record: learning == null
          ? null
          : LearningRecord.fromMap(_plain(learning)),
      journal: journal == null ? null : PlayerJournal.fromMap(_plain(journal)),
    );
    if (learning == null) {
      await _push(RpgFirestorePaths.learningDoc, _meta.record.toMap());
    }
    if (journal == null) {
      await _push(RpgFirestorePaths.journalDoc, _meta.journal.toMap());
    }
  }

  Future<void> _pushProgress(RpgProgress progress) async {
    final uid = _uid;
    if (uid == null) return;
    // 通信を待たずに戻る（オフラインでも画面が止まらないように）。
    // 書き込みは Firestore が送れるようになるまで持っておいてくれる。
    unawaited(
      _db
          .doc(RpgFirestorePaths.progressDoc(uid))
          .set({...progress.toMap(), 'updatedAt': FieldValue.serverTimestamp()})
          .catchError((Object e) => debugPrint('クラウドに保存できませんでした: $e')),
    );
  }

  Future<void> _pushProfile(PlayerProfile profile) async {
    final uid = _uid;
    if (uid == null) return;
    // 通信を待たずに戻る（オフラインでも画面が止まらないように）。
    // 書き込みは Firestore が送れるようになるまで持っておいてくれる。
    unawaited(
      _db
          .doc(RpgFirestorePaths.profileDoc(uid))
          .set({...profile.toMap(), 'updatedAt': FieldValue.serverTimestamp()})
          .catchError((Object e) => debugPrint('クラウドに保存できませんでした: $e')),
    );
  }

  Future<void> _push(
    String Function(String uid) doc,
    Map<String, dynamic> data,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    unawaited(
      _db
          .doc(doc(uid))
          .set({...data, 'updatedAt': FieldValue.serverTimestamp()})
          .catchError((Object e) => debugPrint('クラウドに保存できませんでした: $e')),
    );
  }

  /// Firestore の Timestamp など、JSON にない型を取りのぞく
  static Map<String, dynamic> _plain(Map<String, dynamic> data) =>
      Map.of(data)..remove('updatedAt');
}
