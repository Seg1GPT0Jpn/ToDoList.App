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
import '../study/personal_books.dart';
import '../study/school_lesson_store.dart';
import '../vocab/vocab_store.dart';
import 'sync_status.dart';
import 'vocab_cloud_sync.dart';

/// 進行状況とプロフィールを Firestore と同期する。
///
/// - Google でログインしていないあいだは、これまでどおり端末の中だけに保存する
/// - ログインすると、クラウドに記録があればそれを読み込み（クラウド優先）、
///   なければ端末の記録をクラウドに上げる
/// - ログイン中は、保存するたびにクラウドにも書き込む
///
/// つづりクエストとつづりクエストLight は同じ記録を使う。どちらか（または別の端末）で
/// 保存すると、ログイン中のもう一方にもすぐ届く（[_listen]）。記録はまぜて保存する
/// （[RecordMerge]：多い方・進んだ方を残す）ので、同時に使っても答えた記録は消えない。
///
/// 個人用単語帳（LEAP など）の単語は同期しない。端末の中だけに置く。
/// 単語帳の学習記録（覚えぐあい）だけは [VocabCloudSync] でクラウドにも保存する。
class CloudSync {
  CloudSync._(
    this._auth,
    this._db,
    this._progress,
    this._profiles,
    this._meta,
    this._books,
  ) {
    _vocab = VocabCloudSync(
      write: (docId, data) => _db.doc(_vocabPath(_uid!, docId)).set(data),
      readAll: () async {
        final snap = await _db
            .collection('users')
            .doc(_uid)
            .collection(vocabCollection)
            .get();
        return {for (final d in snap.docs) d.id: d.data()};
      },
    );
  }

  static const vocabCollection = 'rpg_vocab';
  static String _vocabPath(String uid, String docId) =>
      'users/$uid/$vocabCollection/$docId';

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final PrefsProgressRepository _progress;
  final ProfileRepository _profiles;
  final MetaStore _meta;
  final PersonalBooks _books;
  late final VocabCloudSync _vocab;

  FirebaseAuth get auth => _auth;

  /// Firebase を初期化する。設定がない（flutterfire configure をしていない）
  /// ときは null を返し、端末の中だけで動かす。
  static Future<CloudSync?> start({
    required PrefsProgressRepository progress,
    required ProfileRepository profiles,
    required MetaStore meta,
    required PersonalBooks books,
  }) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase を使わずに起動します: $e');
      syncConnected(false, error: e);
      return null;
    }
    final sync = CloudSync._(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
      progress,
      profiles,
      meta,
      books,
    );
    VocabStore.onProgressSaved = (store, bookId) {
      if (sync._uid != null) sync._vocab.saved(store, bookId);
    };
    VocabStore.onBooksSaved = (store) {
      if (sync._uid != null) sync._vocab.booksSaved(store);
    };
    sync._vocab.initBooks(VocabStore.of(books));
    progress.onSaved = sync._pushProgress;
    profiles.onSaved = sync._pushProfile;
    meta.onLearningSaved = (r) =>
        sync._push(RpgFirestorePaths.learningDoc, r.toMap());
    meta.onJournalSaved = (j) =>
        sync._push(RpgFirestorePaths.journalDoc, j.toMap());
    SchoolLessonStore.onSaved = (all) =>
        sync._push(RpgFirestorePaths.lessonsDoc, _lessonsMap(all));
    // ログイン中は、ほかのアプリ・端末の保存をすぐ受け取る
    sync._auth.authStateChanges().listen(sync._listen);
    // 前回のログインが残っていれば、クラウドの記録を読み込む
    final user = await sync._auth.authStateChanges().first;
    if (user != null) {
      unawaited(sync.pull());
    } else if (profiles.load().isGoogleLinked) {
      // ログインが切れていたら、登録していない表示にもどす
      await profiles.replaceLocal(profiles.load().copyWith(unlinkGoogle: true));
    }
    syncConnected(true);
    instance = sync;
    return sync;
  }

  /// 動いている同期（アカウント画面の「今すぐ同期」が使う）
  static CloudSync? instance;

  /// 今すぐ同期する：たまっている分を送り、クラウドの記録をまぜる
  Future<void> syncNow() async {
    syncClearError();
    await _vocab.flush();
    _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
    await pull();
  }

  String? get _uid => _auth.currentUser?.uid;

  static Map<String, dynamic> _lessonsMap(Map<String, LessonRecord> all) => {
    'lessons': {for (final e in all.entries) e.key: e.value.toJson()},
  };

  static Map<String, LessonRecord> _lessonsOf(Map<String, dynamic> data) => {
    for (final e in ((data['lessons'] as Map?) ?? const {}).entries)
      if (e.value is Map)
        '${e.key}': LessonRecord.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        ),
  };

  /// 最後にクラウドと同期したアカウント
  static const _uidKey = 'cloud_sync_uid';

  final _subs = <StreamSubscription<Object?>>[];
  String? _listening;

  /// ログインした人の記録の変化を受け取る（ログアウトしたら止める）
  void _listen(User? user) {
    syncSignedIn(user == null ? null : (user.email ?? 'ログイン中'));
    if (user?.uid == _listening) return;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _listening = user?.uid;
    if (user == null) return;
    void watch(
      String path,
      Future<void> Function(Map<String, dynamic> remote) apply,
    ) {
      _subs.add(
        _db.doc(path).snapshots().listen((snap) {
          // 自分が送った書き込みのこだまは無視する
          final data = snap.data();
          if (snap.metadata.hasPendingWrites || data == null) return;
          unawaited(
            apply(_plain(data))
                .then((_) => syncReceived())
                .catchError((Object e) => syncError('受けとった記録の反映', e)),
          );
        }, onError: (Object e) => syncError('記録の受けとり（$path）', e)),
      );
    }

    final uid = user.uid;
    // 単語帳：変わった文書だけを取りこむ（自分が送ったこだまは無視）
    _subs.add(
      _db
          .collection('users')
          .doc(uid)
          .collection(vocabCollection)
          .snapshots()
          .listen((snap) {
            final changed = {
              for (final c in snap.docChanges)
                if (!c.doc.metadata.hasPendingWrites) c.doc.id,
            };
            if (changed.isEmpty) return;
            final all = {for (final d in snap.docs) d.id: d.data()};
            unawaited(
              _vocab
                  .apply(VocabStore.of(_books), all, changed: changed)
                  .then((_) => syncReceived())
                  .catchError((Object e) => syncError('単語帳の反映', e)),
            );
          }, onError: (Object e) => syncError('単語帳の受けとり', e)),
    );
    watch(RpgFirestorePaths.progressDoc(uid), _applyProgress);
    watch(RpgFirestorePaths.learningDoc(uid), _applyLearning);
    watch(RpgFirestorePaths.journalDoc(uid), _applyJournal);
    watch(RpgFirestorePaths.lessonsDoc(uid), _applyLessons);
  }

  /// クラウドの記録を端末の記録とまぜる。まぜた結果がクラウドとちがえば送りなおす
  Future<void> _applyProgress(Map<String, dynamic> remote) async {
    final cloud = RpgProgress.fromMap(remote);
    await _progress.absorb(cloud);
    final merged = await _progress.load();
    if (!RecordMerge.same(merged.toMap(), cloud.toMap())) {
      await _pushProgress(merged);
    }
  }

  Future<void> _applyLearning(Map<String, dynamic> remote) async {
    final cloud = LearningRecord.fromMap(remote);
    await _meta.absorb(record: cloud);
    if (!RecordMerge.same(_meta.record.toMap(), cloud.toMap())) {
      await _push(RpgFirestorePaths.learningDoc, _meta.record.toMap());
    }
  }

  Future<void> _applyJournal(Map<String, dynamic> remote) async {
    final cloud = PlayerJournal.fromMap(remote);
    await _meta.absorb(journal: cloud);
    if (!RecordMerge.same(_meta.journal.toMap(), cloud.toMap())) {
      await _push(RpgFirestorePaths.journalDoc, _meta.journal.toMap());
    }
  }

  Future<void> _applyLessons(Map<String, dynamic> remote) async {
    final lessons = SchoolLessonStore.of(_books);
    final cloud = _lessonsOf(remote);
    await lessons.absorb(cloud);
    final mine = _lessonsMap(lessons.load());
    if (!RecordMerge.same(mine, _lessonsMap(cloud))) {
      await _push(RpgFirestorePaths.lessonsDoc, mine);
    }
  }

  /// アプリを閉じる・ほかのアプリに切りかえるとき：たまっている単語帳の記録をすぐ送る
  Future<void> flush() => _vocab.flush();

  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  /// アプリにもどってきたとき：クラウドの記録をもう一度まぜる（単語帳もふくめて）
  Future<void> refresh() async {
    if (_uid == null) return;
    final now = DateTime.now();
    if (now.difference(_lastRefresh) < const Duration(seconds: 15)) return;
    _lastRefresh = now;
    await pull();
  }

  /// ログインした直後に呼ぶ。クラウドに記録があれば端末に読み込み、
  /// なければ端末の記録をクラウドに上げる。
  Future<void> pull() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      // 前に別のアカウントでログインしていた端末では、その人の記録をまぜない（クラウドを優先）
      final prefs = _books.prefs;
      final before = prefs.getString(_uidKey);
      if (before != null && before != uid) {
        await _progress.replaceLocal(RpgProgress.initial);
        await _meta.replaceLocal(
          record: LearningRecord.empty,
          journal: PlayerJournal.empty,
        );
        await SchoolLessonStore.of(_books).replaceAll(const {});
      }
      await prefs.setString(_uidKey, uid);
      final serverPurchaseIds = await _loadPurchaseIds(uid);
      final progressData =
          (await _db.doc(RpgFirestorePaths.progressDoc(uid)).get()).data();
      final local = await _progress.load();
      await _progress.replaceLocal(
        local.copyWith(
          purchasedWorldIds: {...local.purchasedWorldIds, ...serverPurchaseIds},
        ),
      );
      if (progressData != null) {
        await _applyProgress(_plain(progressData));
      } else {
        await _pushProgress(await _progress.load());
      }
      final profileSnap = await _db
          .doc(RpgFirestorePaths.profileDoc(uid))
          .get();
      final profileData = profileSnap.data();
      if (profileData != null) {
        await _profiles.replaceLocal(
          PlayerProfile.fromMap(_plain(profileData)),
        );
      } else {
        await _pushProfile(_profiles.load());
      }
      // 学習記録・冒険の記録・授業の記録は、端末とクラウドをまぜる（どちらも消さない）
      for (final (path, apply, mine) in [
        (
          RpgFirestorePaths.learningDoc,
          _applyLearning,
          () => _meta.record.toMap(),
        ),
        (
          RpgFirestorePaths.journalDoc,
          _applyJournal,
          () => _meta.journal.toMap(),
        ),
        (
          RpgFirestorePaths.lessonsDoc,
          _applyLessons,
          () => _lessonsMap(SchoolLessonStore.of(_books).load()),
        ),
      ]) {
        try {
          final data = (await _db.doc(path(uid)).get()).data();
          if (data != null) {
            await apply(_plain(data));
          } else {
            await _push(path, mine());
          }
        } catch (e) {
          // 授業の記録の置き場所をまだ許可していないクラウドでも、ほかは続ける
          syncError('記録の読みこみ', e);
        }
      }
      await _vocab.pull(VocabStore.of(_books));
      syncPulled();
    } catch (e) {
      syncError('クラウドの記録の読みこみ', e);
    }
  }

  /// サーバーで検証済みの買い切りワールドだけを端末へ復元する。
  ///
  /// rpg_purchases はクライアントから書き込めない Firestore コレクションで、
  /// 実際の購入は Google Play Developer API で検証した Cloud Function だけが作る。
  Future<Set<String>> _loadPurchaseIds(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection(RpgFirestorePaths.purchasesCollection)
          .get();
      return {
        for (final doc in snapshot.docs)
          if (doc.data()['revokedAt'] == null) doc.id,
      };
    } catch (e) {
      // オフライン時は端末側のセーブだけで続行できるようにする。
      debugPrint('購入情報を復元できませんでした: $e');
      return {};
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
          .then((_) => syncSent())
          .catchError((Object e) => syncError('クラウドへの保存', e)),
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
          .then((_) => syncSent())
          .catchError((Object e) => syncError('クラウドへの保存', e)),
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
          .then((_) => syncSent())
          .catchError((Object e) => syncError('クラウドへの保存', e)),
    );
  }

  /// Firestore の Timestamp など、JSON にない型を取りのぞく
  static Map<String, dynamic> _plain(Map<String, dynamic> data) =>
      Map.of(data)..remove('updatedAt');
}
