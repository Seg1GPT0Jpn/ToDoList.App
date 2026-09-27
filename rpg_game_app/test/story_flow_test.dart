import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/field/field_screen.dart';
import 'package:rpg_game_app/meta/story_screen.dart';
import 'package:rpg_game_app/story/story_player.dart';
import 'package:rpg_game_app/versus/versus_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('はじめて英語ワールドに入ると、序章と導入の物語が流れ、読んだしるしが残る', (t) async {
    final s = await openScreen(
      t,
      FieldScreen(
        world: RpgCatalog.world(RpgCatalog.englishWorldId),
        progress: RpgProgress.initial,
      ),
      story: true,
      frames: 20,
    );
    expect(find.byType(StoryPlayerScreen), findsOneWidget);
    expect(find.text('しおりの精'), findsOneWidget);
    // タップで最後まで読む（文字送り→全部表示→次へ）
    for (var i = 0; i < 80; i++) {
      if (find.byType(StoryPlayerScreen).evaluate().isEmpty) break;
      await t.tap(find.byType(StoryPlayerScreen), warnIfMissed: false);
      await _frames(t, 2);
    }
    await _frames(t, 10);
    expect(find.byType(StoryPlayerScreen), findsNothing);
    final p = await s.repository.load();
    expect(StoryScenes.seen(p, StoryScenes.prologue), isTrue);
    expect(StoryScenes.seen(p, StoryScenes.intro('english')), isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('物語の画面：回想の一覧と、序章を読むボタン', (t) async {
    await openScreen(t, const StoryScreen(), size: const Size(420, 2600));
    expect(find.textContaining('物語の回想'), findsOneWidget);
    await t.tap(find.text('序章「しおりの精」を読む'));
    await _frames(t, 12);
    expect(find.byType(StoryPlayerScreen), findsOneWidget);
    await t.tap(find.text('スキップ ▶▶'));
    await _frames(t, 10);
    expect(find.byType(StoryPlayerScreen), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('すべての場面を最後まで読んでも落ちない', (t) async {
    await openScreen(
      t,
      Builder(
        builder: (c) => Center(
          child: FilledButton(
            onPressed: () => playStoryScenes(c, StoryScenes.all, replay: true),
            child: const Text('読む'),
          ),
        ),
      ),
    );
    await t.tap(find.text('読む'));
    await _frames(t, 10);
    for (var i = 0; i < 600; i++) {
      if (find.byType(StoryPlayerScreen).evaluate().isEmpty) break;
      // 下のボタンをおさないよう、画面のはしをタップする
      await t.tapAt(const Offset(40, 300));
      await t.pump(const Duration(milliseconds: 60));
    }
    await _frames(t, 10);
    expect(find.byType(StoryPlayerScreen), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('物語の画面：ボスの前の場面を読んだ国では、ノイズと早押し勝負ができる', (t) async {
    final s = await openScreen(
      t,
      const StoryScreen(),
      size: const Size(420, 2600),
    );
    expect(find.byTooltip('ノイズと早押し勝負'), findsNothing);
    await t.runAsync(
      () => s.repository.save(
        StoryScenes.markSeen(RpgProgress.initial, StoryScenes.boss('english')),
      ),
    );
    await _frames(t, 5);
    await t.tap(find.byTooltip('ノイズと早押し勝負'));
    for (
      var i = 0;
      i < 20 && find.byType(VersusScreen).evaluate().isEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VersusScreen), findsOneWidget);
    expect(find.text('ノイズ'), findsOneWidget);
    await _frames(t, 5);
    await t.tap(find.byIcon(Icons.close));
    await _frames(t, 10);
    expect(t.takeException(), isNull);
  });
}
