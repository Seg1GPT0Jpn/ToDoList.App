import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account/account_screen.dart';
import 'account/account_service.dart';
import 'account/profile_repository.dart';
import 'app/services.dart';
import 'app/settings.dart';
import 'app/theme.dart';
import 'app/toast.dart';
import 'audio/music_director.dart';
import 'audio/music_scope.dart';
import 'audio/player_backend.dart';
import 'cloud/cloud_sync.dart';
import 'cloud/firestore_versus_backend.dart';
import 'cloud/firebase_account_service.dart';
import 'data/meta_store.dart';
import 'data/prefs_progress_repository.dart';
import 'study/exam_world_store.dart';
import 'study/personal_books.dart';
import 'world/world_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final prefs = await SharedPreferences.getInstance();
  final progress = PrefsProgressRepository(prefs);
  final profiles = ProfileRepository(prefs);
  final meta = MetaStore(prefs);
  final settings = SettingsStore(prefs);
  final backend = PlayerBackend();
  final music = MusicDirector(backend, settings.value);
  settings.addListener(() => music.applySettings(settings.value));
  // Firebase の設定があればクラウドと同期する。なければ端末の中だけで動く
  final cloud = await CloudSync.start(
    progress: progress,
    profiles: profiles,
    meta: meta,
  );
  runApp(
    RpgServices(
      meta: meta,
      settings: settings,
      music: music,
      repository: progress,
      personalBooks: PersonalBooks(prefs),
      examWorlds: ExamWorldStore(prefs),
      profiles: profiles,
      account: cloud == null
          ? MockAccountService()
          : FirebaseAccountService(cloud),
      versusRooms: cloud == null
          ? null
          : FirestoreVersusBackend(cloud.auth, FirebaseFirestore.instance),
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

/// 画面の出入りを知らせる（フィールドがバトルから戻ったことを知るのに使う）
final routeObserver = RouteObserver<ModalRoute<void>>();

class TsuzuriQuestApp extends StatelessWidget {
  const TsuzuriQuestApp({super.key, this.onUserGesture});

  /// 画面にさわったとき（音の再生を始めなおすのに使う）
  final VoidCallback? onUserGesture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'つづりクエスト',
      debugShowCheckedModeBanner: false,
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

/// はじめての起動で、冒険者の名前を聞く
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
    if (!RpgServices.of(context).profiles.load().hasName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) askUserName(context);
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
