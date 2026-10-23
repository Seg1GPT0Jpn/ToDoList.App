import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/classroom/classroom_backend.dart';
import 'package:rpg_game_app/cloud/cloud_sync.dart';
import 'package:rpg_game_app/cloud/firebase_account_service.dart';
import 'package:rpg_game_app/cloud/firestore_classroom_backend.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/quiz/question_report.dart';
import 'package:rpg_game_app/study/personal_books.dart';

/// クラウド（Firebase）につないだあとに使うもの
class LightCloud {
  LightCloud(this.account, this.classrooms, this.refresh, this.flush);
  final AccountService account;
  final ClassroomBackend classrooms;
  final Future<void> Function() refresh;
  final Future<void> Function() flush;
}

/// Firebase を読みこんでつなぐ。この部分は画面が出たあとに読みこむ（起動を軽くするため）。
/// つながらなければ null（端末の中だけで続ける）
Future<LightCloud?> startCloud({
  required PrefsProgressRepository progress,
  required ProfileRepository profiles,
  required MetaStore meta,
  required PersonalBooks books,
}) async {
  final cloud = await CloudSync.start(
    progress: progress,
    profiles: profiles,
    meta: meta,
    books: books,
  );
  if (cloud == null) return null;
  reportSink = ReportSink(
    upload: (r) async {
      final uid = cloud.auth.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('question_reports').add({
        ...r.toJson(),
        'uid': uid,
      });
    },
  );
  return LightCloud(
    FirebaseAccountService(cloud),
    FirestoreClassroomBackend(cloud.auth, FirebaseFirestore.instance),
    cloud.refresh,
    cloud.flush,
  );
}
