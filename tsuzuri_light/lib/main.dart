import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/asset_path.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/classroom/classroom_backend.dart';
import 'package:rpg_game_app/classroom/classroom_store.dart';
import 'package:rpg_game_app/versus/contest_backend.dart';
import 'package:rpg_game_app/cloud/same_device_sync.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'light_app.dart';
import 'light_cloud.dart' deferred as cloud_lib;
import 'remote_assets.dart';

/// つづりクエストLight：定期テストの海・単語帳・クラスルームだけの軽い版。
///
/// つづりクエストと同じ保存場所・同じクラウドの記録を使うので、進み具合は同じになる。
/// 軽くするために：冒険のマップ（Flame）・BGM・効果音・画面の動き・明朝体・色を使わない。
/// 各画面のプログラムは、開くときに読みこむ。クラウド（Firebase）は、ログインしている人はホームを出したあとで、
/// ログインしていない人はログイン・クラスルームの画面を開いたときに読みこむ。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // つづりクエストの同梱ファイル（単語帳・資料など）を部品の中から読む
  appAssetPrefix = 'packages/rpg_game_app/';
  sansOnly = true;
  // 音声を使わないので、単語帳の聞き取り（リスニング）の練習は出さない
  VocabPlanner.listeningAvailable = false;
  PlayerProfile.unnamed = '名前なし';
  // Android 版は、資料・予想問題を APK に入れず、開いたときにネットから読む
  missingAssetLoader = remoteAssetLoader();
  // 本文のフォントは pubspec で Roboto として登録してあり、描画エンジンが起動時に読む
  // （字を描く前に読み終わるので、ネットの別のフォントを取りに行かない）
  bundledSans = 'Roboto';
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL-NotoSansJP.txt');
    yield LicenseEntryWithLineBreaks(['Noto Sans JP'], text);
  });
  TsuzuriColors.mono = true;
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
        return (
          account: c.account,
          classrooms: c.classrooms,
          contests: c.contests,
        );
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
  ContestBackend? contests,
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
  ContestBackend? _contests;

  @override
  void initState() {
    super.initState();
    final connect = widget.connect;
    if (connect == null) {
      _account = MockAccountService();
      return;
    }
    // クラウドの準備ができるまでにログインを押されたら、準備ができるのを待ってからログインする
    _account = PendingAccountService(_ready.future, onNeed: _start);
    cloudRequested.value = false;
    requestCloud = _start;
    // ログインしている人・クラスルームに入っている人は、ホームを描いてからすぐつなぐ。
    // そうでない人は、ログイン・クラスルームの画面を開くまで Firebase を読みこまない
    if (needsCloudAtStart(widget.stores)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  final _ready = Completer<AccountService?>();
  bool _started = false;

  /// クラウドの部品を読みこんでつなぐ（1回だけ）
  Future<void> _start() async {
    final connect = widget.connect;
    if (_started || connect == null) return;
    _started = true;
    cloudRequested.value = true;
    try {
      final c = await connect().timeout(const Duration(seconds: 30));
      _ready.complete(c?.account);
      if (c == null || !mounted) return;
      setState(() {
        _account = c.account;
        _classrooms = c.classrooms;
        _contests = c.contests;
      });
    } catch (e) {
      if (!_ready.isCompleted) _ready.complete(null);
      debugPrint('クラウドにつながらないので、端末の中だけで続けます: $e');
    }
  }

  @override
  void dispose() {
    requestCloud = () {};
    super.dispose();
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
      contests: _contests,
      child: const LightApp(),
    );
  }
}

/// クラウド（Firebase）を読みこみはじめたか
final cloudRequested = ValueNotifier<bool>(false);

/// クラウドを使う画面（ログイン・クラスルーム）を開くときに呼ぶ。まだなら読みこみはじめる
void Function() requestCloud = () {};

/// 起動してすぐクラウドにつなぐか：ログインしている・クラスルームに入っている・招待リンクから来た
bool needsCloudAtStart(LightStores s) =>
    s.profiles.load().isGoogleLinked ||
    inviteClassCode() != null ||
    ClassroomStore(s.books.prefs).codes.isNotEmpty;

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
