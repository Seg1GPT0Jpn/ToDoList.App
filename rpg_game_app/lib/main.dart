import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/services.dart';
import 'app/theme.dart';
import 'data/prefs_progress_repository.dart';
import 'world/world_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    RpgServices(
      repository: PrefsProgressRepository(prefs),
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
      home: const WorldMapScreen(),
    );
  }
}
