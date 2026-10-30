import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account/account_service.dart';
import 'account/profile_repository.dart';
import 'account/welcome_screen.dart';
import 'classroom/classroom_screens.dart';
import 'versus/duel_screens.dart';
import 'app/services.dart';
import 'app/settings.dart';
import 'app/theme.dart';
import 'app/toast.dart';
import 'audio/music_director.dart';
import 'audio/music_scope.dart';
import 'audio/player_backend.dart';
import 'cloud/cloud_sync.dart';
import 'cloud/same_device_sync.dart';
import 'purchase/google_play_purchase_service.dart';
import 'quiz/question_report.dart';
import 'cloud/firestore_classroom_backend.dart';
import 'cloud/firestore_contest_backend.dart';
import 'cloud/firestore_duel_backend.dart';
import 'cloud/firestore_yosou_ranking.dart';
import 'cloud/firestore_matchmaking.dart';
import 'cloud/firestore_usage_sink.dart';
import 'cloud/firestore_versus_backend.dart';
import 'cloud/firebase_account_service.dart';
import 'cloud/tsuzuri_firebase_backend.dart';
import 'data/meta_store.dart';
import 'data/prefs_progress_repository.dart';
import 'study/exam_world_store.dart';
import 'study/school_exam_store.dart';
import 'study/personal_books.dart';
import 'world/world_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final prefs = await SharedPreferences.getInstance();
  // 学校専用の対策：前から使っていた端末は開いたままにする（ほかの保存より前に確かめる）
  await SchoolExamStore.migrate(prefs);
  final progress = PrefsProgressRepository(prefs);
  final profiles = ProfileRepository(prefs);
  final meta = MetaStore(prefs);
  final settings = SettingsStore(prefs);
  final backend = PlayerBackend();
  final music = MusicDirector(backend, settings.value);
  // バトル・ボスの曲が1つのファイル（bgm_battle.mp3 / bgm_boss.mp3）で置いてあれば、そちらを使う
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    music.singleTracks = {
      for (final key in [MusicDirector.battle, MusicDirector.boss])
        if (assets.contains('assets/${MusicDirector.bgmAsset(key)}')) key,
    };
  } catch (_) {
    // 一覧が読めなければ、これまでどおり4パートで流す
  }
  settings.addListener(() => music.applySettings(settings.value));
  // Firebase の設定があればクラウドと同期する。なければ端末の中だけで動く
  final personalBooks = PersonalBooks(prefs);
  // 通信が遅い・つながらないときは待たずに始める（記録は端末に残り、つながりしだい同期する）
  final cloudReady = CloudSync.start(
    progress: progress,
    profiles: profiles,
    meta: meta,
    books: personalBooks,
  );
  final cloud = await cloudReady.timeout(
    const Duration(seconds: 8),
    onTimeout: () {
      debugPrint('クラウドの準備を待たずに始めます');
      return null;
    },
  );
  // 同じ端末のつづりクエストLight（Web は同じブラウザのほかのタブ）と記録をそろえる
  SameDeviceSync(
    prefs: prefs,
    meta: meta,
    progress: progress,
    books: personalBooks,
    onResume: () async => CloudSync.instance?.refresh(),
    onPause: () async => CloudSync.instance?.flush(),
  ).start();
  if (cloud != null) {
    // 問題の報告は、ログインしていればクラウド（question_reports）にも送る
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
  // Android + Firebase 接続時だけ Google Play Billing を有効にする。
  // 購入成功時は、Play のサーバー検証済み権利を端末の進行状況へ反映する。
  GooglePlayPurchaseService? purchaseService;
  if (!kIsWeb && cloud != null) {
    purchaseService = GooglePlayPurchaseService(
      onVerified: (worldId) =>
          progress.markWorldPurchased(worldId, source: 'google_play'),
    );
    await purchaseService.initialize();
  }

  // 古い学習記録に、学習体系の単元を補う（裏で行い、終わったら保存する）
  unawaited(_migrateUnits(meta));
  runApp(
    RpgServices(
      meta: meta,
      settings: settings,
      music: music,
      repository: progress,
      personalBooks: personalBooks,
      examWorlds: ExamWorldStore(prefs),
      profiles: profiles,
      account: cloud != null
          ? FirebaseAccountService(cloud)
          // まだつながっていなければ、つながりしだい本物のログインを使う
          : PendingAccountService(
              cloudReady.then(
                (c) => c == null ? null : FirebaseAccountService(c),
              ),
            ),
      purchaseService: purchaseService,
      versusRooms: cloud == null
          ? null
          : FirestoreVersusBackend(cloud.auth, FirebaseFirestore.instance),
      classrooms: cloud == null
          ? null
          : FirestoreClassroomBackend(cloud.auth, FirebaseFirestore.instance),
      usageSink: cloud == null
          ? null
          : FirestoreUsageSink(FirebaseFirestore.instance),
      matchmaking: cloud == null
          ? null
          : FirestoreMatchmaking(cloud.auth, FirebaseFirestore.instance),
      duels: cloud == null
          ? null
          : FirestoreDuelBackend(cloud.auth, FirebaseFirestore.instance),
      contests: cloud == null
          ? null
          : FirestoreContestBackend(cloud.auth, FirebaseFirestore.instance),
      yosouRanking: cloud == null
          ? null
          : FirestoreYosouRankBackend(cloud.auth, FirebaseFirestore.instance),
      tsuzuriBackend: cloud == null || !FirebaseTsuzuriBackend.supported
          ? null
          : FirebaseTsuzuriBackend(),
      child: TsuzuriQuestApp(
        onUserGesture: () {
          // ブラウザは、画面にさわるまで音を出させてくれない
          if (backend.blocked) {
            backend.blocked = false;
            music.retry();
          }
        },
      ),
    ),
  );
}

/// 学習記録のマイグレーション：単元が書かれていない古い記録に単元を補う
Future<void> _migrateUnits(MetaStore meta) async {
  try {
    final units = await UnitMigration.unitsFor(
      meta.record,
      JsonQuestionSource(RpgServices.loadQuestionAsset),
    );
    if (units.isEmpty) return;
    final migrated = meta.record.withUnits(units);
    if (!identical(migrated, meta.record)) await meta.save(record: migrated);
  } catch (e) {
    debugPrint('学習記録の単元の移行に失敗: $e');
  }
}

/// 画面の出入りを知らせる（フィールドがバトルから戻ったことを知るのに使う）
final routeObserver = RouteObserver<ModalRoute<void>>();

class TsuzuriQuestApp extends StatefulWidget {
  const TsuzuriQuestApp({super.key, this.onUserGesture});

  /// 画面にさわったとき（音の再生を始めなおすのに使う）
  final VoidCallback? onUserGesture;

  @override
  State<TsuzuriQuestApp> createState() => _TsuzuriQuestAppState();
}

class _TsuzuriQuestAppState extends State<TsuzuriQuestApp>
    with WidgetsBindingObserver {
  VoidCallback? get onUserGesture => widget.onUserGesture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 端末のライト・ダークが切りかわったとき
  @override
  void didChangePlatformBrightness() => setState(() {});

  /// 設定と端末の設定から、ダークモードで表示するかを決める
  bool _isDark(AppSettings s) => switch (s.theme) {
    'dark' => true,
    'light' => false,
    _ =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  /// 色が切りかわったら、画面をすべて描きなおす（const の部品もふくめて）
  void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    final settings = RpgServices.of(context).settings;
    return ValueListenableBuilder<AppSettings>(
      valueListenable: settings,
      builder: (context, s, _) {
        final dark = _isDark(s);
        if (dark != TsuzuriColors.dark) {
          TsuzuriColors.dark = dark;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _rebuildAll();
          });
        }
        return _app(dark);
      },
    );
  }

  Widget _app(bool dark) {
    return MaterialApp(
      title: 'つづりクエスト',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      navigatorObservers: [routeObserver],
      scaffoldMessengerKey: rootMessengerKey,
      builder: (context, child) {
        final settings = RpgServices.of(context).settings;
        return Listener(
          onPointerDown: (_) => onUserGesture?.call(),
          child: ValueListenableBuilder<AppSettings>(
            valueListenable: settings,
            builder: (context, s, _) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(s.textScale),
                  disableAnimations: mq.disableAnimations || s.reduceMotion,
                ),
                child: child!,
              );
            },
          ),
        );
      },
      home: const _FirstRun(
        child: MusicScope(music: 'home', child: WorldMapScreen()),
      ),
    );
  }
}

/// はじめての起動で、ログイン画面（Google／ログインせずにはじめる）を出す
class _FirstRun extends StatefulWidget {
  const _FirstRun({required this.child});
  final Widget child;

  @override
  State<_FirstRun> createState() => _FirstRunState();
}

class _FirstRunState extends State<_FirstRun> {
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;
    final p = RpgServices.of(context).profiles.load();
    RpgServices.of(context).usage.open('app');
    // 招待リンク（?class=123456）から来たら、クラスルームを開いてコードを入れておく
    final classCode = kIsWeb ? Uri.base.queryParameters['class'] : null;
    final needWelcome = !p.hasName && !p.isGoogleLinked;
    if (classCode != null && Classroom.validCode(classCode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClassroomHubScreen(joinCode: classCode),
          ),
        );
      });
    }
    // 単語チャレンジのリンク（?duel=abcd2345）から来たら、そのチャレンジを開く
    final duelId = kIsWeb ? Uri.base.queryParameters['duel'] : null;
    if (duelId != null && WordDuel.validId(duelId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => DuelOpenScreen(id: duelId)),
        );
      });
    }
    if (needWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => const WelcomeScreen(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 同梱した Noto フォント（SIL OFL）のライセンスをライセンス画面に載せる。
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in [
      ('Noto Sans JP', 'OFL-NotoSansJP.txt'),
      ('Noto Serif JP', 'OFL-NotoSerifJP.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
