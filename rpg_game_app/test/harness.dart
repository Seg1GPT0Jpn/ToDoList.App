import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/story/story_player.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/main.dart' show routeObserver;
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SilentAudio implements AudioBackend {
  @override
  Future<void> loop(String channel, String asset, double volume) async {}
  @override
  Future<void> once(String asset, double volume) async {}
  @override
  Future<void> setVolume(String channel, double volume) async {}
  @override
  Future<void> stop(String channel) async {}
}

/// 画面を本物と同じサービスの中で開く。開いたあと [frames] × 100ms 進めて、
/// エラーが出ていないことを確かめる。
/// 最後に開いた画面のサービス（テストで保存内容を確かめる用）
class RpgServicesHolder {
  static RpgServices? last;
}

Future<RpgServices> openScreen(
  WidgetTester tester,
  Widget page, {
  Map<String, Object> prefs = const {},
  int frames = 10,
  Size size = const Size(420, 860),
  bool keepPrefs = false,
  bool story = false,
  bool dark = false,
  bool bare = false,
}) async {
  TsuzuriColors.dark = dark;
  // 物語の場面の自動再生は、物語のテストでだけ使う
  storyAutoPlay = story;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (!keepPrefs) SharedPreferences.setMockInitialValues(prefs);
  // ほかのテスト（フェイクの時間）で始めた問題の読み込みを持ちこさない
  RpgServices.clearQuestionBundles();
  final p = await SharedPreferences.getInstance();
  late RpgServices services;
  await tester.pumpWidget(
    RpgServices(
      repository: PrefsProgressRepository(p),
      personalBooks: PersonalBooks(p),
      profiles: ProfileRepository(p),
      account: MockAccountService(),
      examWorlds: ExamWorldStore(p),
      meta: MetaStore(p),
      settings: SettingsStore.memory(),
      music: MusicDirector(SilentAudio()),
      child: Builder(
        builder: (context) {
          services = RpgServices.of(context);
          RpgServicesHolder.last = services;
          // bare のときは、画面そのものが MaterialApp（アプリ全体のテスト）
          if (bare) return page;
          return MaterialApp(
            navigatorObservers: [routeObserver],
            theme: buildTheme(dark ? Brightness.dark : Brightness.light),
            home: page,
          );
        },
      ),
    ),
  );
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
  return services;
}
