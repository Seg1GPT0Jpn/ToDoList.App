import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_service.dart';
import 'package:rpg_game_app/account/profile_repository.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/audio/music_director.dart';
import 'package:rpg_game_app/cloud/same_device_sync.dart';
import 'package:rpg_game_app/data/meta_store.dart';
import 'package:rpg_game_app/data/prefs_progress_repository.dart';
import 'package:rpg_game_app/study/exam_world_store.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri_light/light_app.dart';
import 'package:rpg_game_app/classroom/classroom_backend.dart';
import 'package:tsuzuri_light/main.dart';

Future<RpgServices> _open(WidgetTester t, Map<String, Object> prefs) async {
  t.view.physicalSize = const Size(420, 860);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  late RpgServices services;
  await t.pumpWidget(
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
          return const LightApp();
        },
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  return services;
}

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  // 名前を入れてあれば、はじめのログイン画面は出ない
  const named = {'rpg_profile_v1': '{"userName":"テスト"}'};

  testWidgets('ホームに定期テストの海・試験対策・単語帳・クラスルーム・復習が並ぶ', (t) async {
    await _open(t, named);
    if (find.byKey(const ValueKey('light-home')).evaluate().isEmpty) {
      // ログイン画面が出たら閉じる
      await t.pageBack();
      await _frames(t);
    }
    for (final id in ['sea', 'exam', 'vocab', 'class', 'review', 'status']) {
      await t.scrollUntilVisible(
        find.byKey(ValueKey('light-$id')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(ValueKey('light-$id')), findsOneWidget, reason: id);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('定期テストの海と単語帳を開ける', (t) async {
    await _open(t, named);
    if (find.byKey(const ValueKey('light-home')).evaluate().isEmpty) {
      await t.pageBack();
      await _frames(t);
    }
    await t.tap(find.byKey(const ValueKey('light-sea')));
    await _frames(t, 10);
    expect(find.text('定期テストの海'), findsWidgets);
    await t.pageBack();
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('light-vocab')));
    await _frames(t, 10);
    expect(find.text('単語帳'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  test('同じ端末のつづりクエストが保存した学習記録を取りこむ（どちらの記録も消えない）', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final books = PersonalBooks(p);
    final full = MetaStore(p); // つづりクエスト
    final light = MetaStore(p); // つづりクエストLight（読みこみ済みの記録を持っている）
    AnswerEvent a(String id) => AnswerEvent(
      questionId: id,
      setId: 'math_x',
      isCorrect: true,
      elapsedMs: 900,
    );
    await light.save(record: light.record.recordAll([a('q1')], day: 5));
    await full.save(record: full.record.recordAll([a('q2')], day: 5));
    await SameDeviceSync(
      prefs: p,
      meta: light,
      progress: PrefsProgressRepository(p),
      books: books,
    ).absorb();
    expect(light.record.stats.keys, containsAll(['q1', 'q2']));
  });

  testWidgets('クラウドを待たずにホームを出し、つながったらクラスルームを使えるようにする', (t) async {
    t.view.physicalSize = const Size(420, 860);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(named);
    final p = await SharedPreferences.getInstance();
    final done = Completer<LightConnection?>();
    await t.pumpWidget(
      LightRoot(
        stores: LightStores(
          progress: PrefsProgressRepository(p),
          profiles: ProfileRepository(p),
          meta: MetaStore(p),
          settings: SettingsStore.memory(),
          books: PersonalBooks(p),
          examWorlds: ExamWorldStore(p),
        ),
        connect: () => done.future,
      ),
    );
    await _frames(t);
    // まだつながっていない：ホームは出ていて、クラスルームは使えない表示
    expect(find.byKey(const ValueKey('light-home')), findsOneWidget);
    expect(find.text('インターネットにつながると使えます'), findsOneWidget);
    done.complete((
      account: MockAccountService(),
      classrooms: MemoryClassroomBackend(MemoryClassroomHub()),
    ));
    await _frames(t);
    expect(find.text('先生の課題・クラスの範囲'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('白黒のときは、色をすべて同じ明るさの灰色にする', () {
    TsuzuriColors.mono = true;
    addTearDown(() => TsuzuriColors.mono = false);
    for (final c in [
      TsuzuriColors.accent,
      TsuzuriColors.paper,
      TsuzuriColors.marginLine,
      TsuzuriColors.tint(0xFFE3F2FD),
      buildTheme(Brightness.light).colorScheme.primary,
    ]) {
      expect(c.r, c.g);
      expect(c.g, c.b);
    }
  });

  test('本文のフォントは pubspec の Roboto（中身は Noto Sans JP）を使い、google_fonts を使わない', () {
    sansOnly = true;
    bundledSans = 'Roboto';
    addTearDown(() {
      sansOnly = false;
      bundledSans = null;
    });
    final t = buildTheme(Brightness.light).textTheme;
    expect(t.bodyMedium!.fontFamily, 'Roboto');
    expect(t.titleLarge!.fontFamily, 'Roboto');
    expect(t.titleLarge!.fontWeight, FontWeight.w700);
    expect(serif(18).fontFamily, 'Roboto');
  });
}
