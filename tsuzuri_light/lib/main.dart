import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/asset_path.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/cloud/cloud_sync.dart';
import 'package:rpg_game_app/cloud/firebase_account_service.dart';
import 'package:rpg_game_app/cloud/firestore_classroom_backend.dart';
import 'package:rpg_game_app/cloud/same_device_sync.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/quiz/question_report.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'light_app.dart';

/// つづりクエストLight：定期テストの海・単語帳・クラスルームだけの軽い版。
///
/// つづりクエストと同じ保存場所・同じクラウドの記録を使うので、進み具合は同じになる。
/// 冒険のマップ（Flame）・BGM・対戦・購入は読みこまない。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // つづりクエストの同梱ファイル（単語帳・資料など）を部品の中から読む
  appAssetPrefix = 'packages/rpg_game_app/';
  final prefs = await SharedPreferences.getInstance();
  await SchoolExamStore.migrate(prefs);
  final progress = PrefsProgressRepository(prefs);
  final profiles = ProfileRepository(prefs);
  final meta = MetaStore(prefs);
  final settings = SettingsStore(prefs);
  final personalBooks = PersonalBooks(prefs);
  // 通信が遅い・つながらないときは待たずに始める（記録は端末に残り、次に開いたときに同期する）
  final cloud =
      await CloudSync.start(
        progress: progress,
        profiles: profiles,
        meta: meta,
        books: personalBooks,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('クラウドにつながらないので、端末の中だけで始めます');
          return null;
        },
      );
  // 同じ端末のつづりクエスト（Web は同じブラウザのほかのタブ）と記録をそろえる
  SameDeviceSync(
    prefs: prefs,
    meta: meta,
    progress: progress,
    books: personalBooks,
    onResume: cloud?.refresh,
  ).start();
  if (cloud != null) {
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
  }
  runApp(
    RpgServices(
      meta: meta,
      settings: settings,
      // 音は鳴らさない（音のファイルを読みこまない）
      music: MusicDirector(SilentAudio(), settings.value),
      repository: progress,
      personalBooks: personalBooks,
      examWorlds: ExamWorldStore(prefs),
      profiles: profiles,
      account: cloud == null
          ? MockAccountService()
          : FirebaseAccountService(cloud),
      classrooms: cloud == null
          ? null
          : FirestoreClassroomBackend(cloud.auth, FirebaseFirestore.instance),
      child: const LightApp(),
    ),
  );
}

/// 何も鳴らさない音の出し先
class SilentAudio implements AudioBackend {
  @override
  Future<void> loop(String channel, String asset, double volume) async {}
  @override
  Future<void> setVolume(String channel, double volume) async {}
  @override
  Future<void> stop(String channel) async {}
  @override
  Future<void> once(String asset, double volume) async {}
}

/// 招待リンク（?class=123456）のクラス番号（Web だけ）
String? inviteClassCode() {
  final code = kIsWeb ? Uri.base.queryParameters['class'] : null;
  return code != null && Classroom.validCode(code) ? code : null;
}
