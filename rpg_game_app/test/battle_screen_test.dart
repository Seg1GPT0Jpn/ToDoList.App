import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/battle/deck_screen.dart';
import 'package:rpg_game_app/meta/bestiary_screen.dart';
import 'package:rpg_game_app/meta/equipment_screen.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';
import 'package:rpg_game_app/meta/review_tower_screen.dart';
import 'package:rpg_game_app/meta/story_screen.dart';
import 'package:rpg_game_app/study/common_test_screens.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Silent implements AudioBackend {
  @override
  Future<void> loop(String channel, String asset, double volume) async {}
  @override
  Future<void> once(String asset, double volume) async {}
  @override
  Future<void> setVolume(String channel, double volume) async {}
  @override
  Future<void> stop(String channel) async {}
}

final _questions = [
  for (var i = 0; i < 8; i++)
    QuizQuestion(
      id: 'q$i',
      category: i.isEven ? QuestionCategory.usage : QuestionCategory.meaning,
      prompt: '問題$i',
      choices: const ['あ', 'い', 'う', 'え'],
      answerIndex: 0,
      explanation: '解説。',
    ),
];

Future<void> _screen(WidgetTester tester, Widget page) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    RpgServices(
      repository: PrefsProgressRepository(prefs),
      personalBooks: PersonalBooks(prefs),
      profiles: ProfileRepository(prefs),
      account: MockAccountService(),
      examWorlds: ExamWorldStore(prefs),
      meta: MetaStore(prefs),
      settings: SettingsStore.memory(),
      music: MusicDirector(_Silent()),
      child: MaterialApp(home: page),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _open(
  WidgetTester tester,
  StageDef stage, {
  bool trial = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    RpgServices(
      repository: PrefsProgressRepository(prefs),
      personalBooks: PersonalBooks(prefs),
      profiles: ProfileRepository(prefs),
      account: MockAccountService(),
      examWorlds: ExamWorldStore(prefs),
      meta: MetaStore(prefs),
      settings: SettingsStore.memory(),
      music: MusicDirector(_Silent()),
      child: MaterialApp(
        home: BattleScreen(
          world: RpgCatalog.world(stage.worldId),
          stage: stage,
          questions: _questions,
          progress: RpgProgress.initial,
          trial: trial,
        ),
      ),
    ),
  );
  // 登場の演出と1問目が出るまで進める
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
  expect(
    find.text('問題0').evaluate().isNotEmpty ||
        find.textContaining('問題').evaluate().isNotEmpty,
    isTrue,
  );
}

void main() {
  final english = RpgCatalog.world(RpgCatalog.englishWorldId).stages;

  testWidgets('ふつうのバトルが開けて、問題が出る', (tester) async {
    await _open(tester, english.first);
  });

  testWidgets('強敵のバトルが開ける', (tester) async {
    await _open(tester, Elites.of(english[2]));
  });

  testWidgets('ボスのバトル（試練）が開ける', (tester) async {
    await _open(tester, english[15]);
  });

  testWidgets('ラスボス（分野横断）のバトルが開ける', (tester) async {
    await _open(tester, english.last);
  });

  testWidgets('復習の塔の苦手克服ボスが開ける', (tester) async {
    await _open(
      tester,
      ReviewTower.stage(
        level: 3,
        floor: 2,
        questionCount: 8,
        worldId: 'english',
        summit: true,
      ),
      trial: true,
    );
  });

  final pages = <String, Widget>{
    '物語': const StoryScreen(),
    '装備・職業': const EquipmentScreen(),
    '学習ステータス': const LearningStatusScreen(),
    '共通テスト遺跡': const CommonTestRuinsScreen(),
    '模試ダンジョン': const MockExamScreen(),
    'デッキ': const DeckScreen(progress: RpgProgress.initial),
    '復習の塔': const ReviewTowerScreen(),
    '魔物図鑑': const BestiaryScreen(),
  };
  for (final e in pages.entries) {
    testWidgets('${e.key}の画面が開ける', (tester) async {
      await _screen(tester, e.value);
    });
  }
}
