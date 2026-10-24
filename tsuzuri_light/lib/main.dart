import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/asset_path.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/classroom/classroom_backend.dart';
import 'package:rpg_game_app/cloud/same_device_sync.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'light_app.dart';
import 'light_cloud.dart' deferred as cloud_lib;

/// つづりクエストLight：定期テストの海・単語帳・クラスルームだけの軽い版。
///
/// つづりクエストと同じ保存場所・同じクラウドの記録を使うので、進み具合は同じになる。
/// 軽くするために：冒険のマップ（Flame）・BGM・効果音・画面の動き・明朝体を使わない。
/// クラウド（Firebase）と各画面のプログラムは、ホームを出したあとで必要になったときに読みこむ。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // つづりクエストの同梱ファイル（単語帳・資料など）を部品の中から読む
  appAssetPrefix = 'packages/rpg_game_app/';
  sansOnly = true;
  final prefs = await SharedPreferences.getInstance();
  await SchoolExamStore.migrate(prefs);
  final stores = LightStores(
    progress: PrefsProgressRepository(prefs),
    profiles: ProfileRepository(prefs),
    meta: MetaStore(prefs),
    settings: SettingsStore(prefs),
    books: PersonalBooks(prefs),
    examWorlds: ExamWorldStore(prefs),
  );
  Future<void> Function()? refresh;
  Future<void> Function()? flush;
  // 同じ端末のつづりクエスト（Web は同じブラウザのほかのタブ）と記録をそろえる
  SameDeviceSync(
    prefs: prefs,
    meta: stores.meta,
    progress: stores.progress,
    books: stores.books,
    onResume: () async => refresh?.call(),
    onPause: () async => flush?.call(),
  ).start();
  runApp(
    LightRoot(
      stores: stores,
      connect: () async {
        await cloud_lib.loadLibrary();
        final c = await cloud_lib.startCloud(
          progress: stores.progress,
          profiles: stores.profiles,
          meta: stores.meta,
          books: stores.books,
        );
        if (c == null) return null;
        refresh = c.refresh;
        flush = c.flush;
        return (account: c.account, classrooms: c.classrooms);
      },
    ),
  );
}

/// 端末に保存する記録（つづりクエストと同じ場所）
class LightStores {
  LightStores({
    required this.progress,
    required this.profiles,
    required this.meta,
    required this.settings,
    required this.books,
    required this.examWorlds,
  });
  final PrefsProgressRepository progress;
  final ProfileRepository profiles;
  final MetaStore meta;
  final SettingsStore settings;
  final PersonalBooks books;
  final ExamWorldStore examWorlds;
}

typedef LightConnection = ({
  AccountService account,
  ClassroomBackend classrooms,
});

/// サービスの入れ物。はじめは端末の中だけで動き、クラウドにつながったらログインと
/// クラスルームを差しこむ（画面はつながるのを待たずに出す）
class LightRoot extends StatefulWidget {
  const LightRoot({super.key, required this.stores, this.connect});

  final LightStores stores;

  /// クラウドにつなぐ（テストでは null）
  final Future<LightConnection?> Function()? connect;

  @override
  State<LightRoot> createState() => _LightRootState();
}

class _LightRootState extends State<LightRoot> {
  late final _music = MusicDirector(
    SilentAudio(),
    widget.stores.settings.value,
  );
  late AccountService _account;
  ClassroomBackend? _classrooms;

  @override
  void initState() {
    super.initState();
    final connect = widget.connect;
    if (connect == null) {
      _account = MockAccountService();
      return;
    }
    // クラウドの準備ができるまでにログインを押されたら、準備ができるのを待ってからログインする
    final account = Completer<AccountService?>();
    _account = PendingAccountService(account.future);
    // ホームを描いてから、クラウドの部品を読みこむ
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final c = await connect().timeout(const Duration(seconds: 30));
        account.complete(c?.account);
        if (c == null || !mounted) return;
        setState(() {
          _account = c.account;
          _classrooms = c.classrooms;
        });
      } catch (e) {
        if (!account.isCompleted) account.complete(null);
        debugPrint('クラウドにつながらないので、端末の中だけで続けます: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stores;
    return RpgServices(
      meta: s.meta,
      settings: s.settings,
      // 音は鳴らさない（音のファイルを読みこまない）
      music: _music,
      repository: s.progress,
      personalBooks: s.books,
      examWorlds: s.examWorlds,
      profiles: s.profiles,
      account: _account,
      classrooms: _classrooms,
      child: const LightApp(),
    );
  }
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
