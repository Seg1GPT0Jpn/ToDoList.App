import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account/account_screen.dart';
import 'account/account_service.dart';
import 'account/profile_repository.dart';
import 'app/services.dart';
import 'app/theme.dart';
import 'cloud/cloud_sync.dart';
import 'cloud/firebase_account_service.dart';
import 'data/prefs_progress_repository.dart';
import 'study/personal_books.dart';
import 'world/world_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final progress = PrefsProgressRepository(prefs);
  final profiles = ProfileRepository(prefs);
  // Firebase の設定があればクラウドと同期する。なければ端末の中だけで動く
  final cloud = await CloudSync.start(progress: progress, profiles: profiles);
  runApp(
    RpgServices(
      repository: progress,
      personalBooks: PersonalBooks(prefs),
      profiles: profiles,
      account: cloud == null
          ? MockAccountService()
          : FirebaseAccountService(cloud),
      child: const TsuzuriQuestApp(),
    ),
  );
}

/// 画面の出入りを知らせる（フィールドがバトルから戻ったことを知るのに使う）
final routeObserver = RouteObserver<ModalRoute<void>>();

class TsuzuriQuestApp extends StatelessWidget {
  const TsuzuriQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'つづりクエスト',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      navigatorObservers: [routeObserver],
      home: const _FirstRun(child: WorldMapScreen()),
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
