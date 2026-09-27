import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/art/hero_painter.dart';
import 'package:rpg_game_app/field/field_game.dart';
import 'package:rpg_game_app/field/field_map.dart';
import 'package:rpg_game_app/field/field_screen.dart';

import 'harness.dart';

FieldGame _game(WidgetTester t) => t
    .widget<GameWidget<FieldGame>>(
      find.byWidgetPredicate((w) => w is GameWidget<FieldGame>),
    )
    .game!;

Future<void> _frames(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// [target] のとなりの床に立って、そちらを向いて話しかける
Future<void> _bump(WidgetTester t, FieldGame g, Cell target) async {
  final map = g.map;
  for (final (dc, dr, dir) in const [
    (0, 1, Facing.up),
    (0, -1, Facing.down),
    (1, 0, Facing.left),
    (-1, 0, Facing.right),
  ]) {
    final c = (col: target.col + dc, row: target.row + dr);
    final tile = map.tileAt(c.col, c.row);
    if (!map.isFloor(c.col, c.row) || tile == 'E' || tile == 'M') continue;
    g.player
      ..cell = c
      ..position = Vector2((c.col + 0.5) * tileSize, (c.row + 0.5) * tileSize);
    g.inputLocked = false;
    g.padDirection = dir;
    await _frames(t, 3);
    g.padDirection = null;
    await _frames(t, 6);
    return;
  }
  fail('となりに床がない: $target');
}

/// ダイアログのボタンを押す（あれば）
Future<bool> _press(WidgetTester t, String label) async {
  final f = find.text(label);
  if (f.evaluate().isEmpty) return false;
  await t.tap(f.first, warnIfMissed: false);
  await _frames(t, 10);
  return true;
}

/// 小さなクイズが出ていたら、最初の選択肢を押して最後まで答える
Future<void> _answerQuiz(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    final choices = find.byType(OutlinedButton);
    if (choices.evaluate().isEmpty) return;
    await t.tap(choices.first, warnIfMissed: false);
    await _frames(t, 12);
    await _press(t, 'つぎへ');
    await _press(t, '次へ');
  }
}

Future<void> _closeAll(WidgetTester t) async {
  for (final label in ['とじる', 'やめておく', 'にげる', 'あとで', 'わかった']) {
    await _press(t, label);
  }
}

void main() {
  testWidgets('フィールドの仕掛けに話しかけても落ちない（英語ワールド）', (t) async {
    await openScreen(
      t,
      FieldScreen(
        world: RpgCatalog.world(RpgCatalog.englishWorldId),
        progress: RpgProgress.initial,
      ),
      frames: 20,
    );
    final g = _game(t);
    final map = g.map;
    final seen = <String>[];
    for (final ch in ['S', 'I', 'W', 'X', 'C', 'H', 'D', 'M', 'E', 'G']) {
      final cells = map.findAll(ch);
      if (cells.isEmpty) continue;
      // 最初のエリア付近（下の方）から選ぶ
      cells.sort((a, b) => b.row.compareTo(a.row));
      await _bump(t, g, cells.first);
      seen.add(ch);
      expect(t.takeException(), isNull, reason: '「$ch」に話しかけた');
      // 押せるボタンを順にためす
      for (final action in ['鍵をあける', '問いに答える', '泉の問いに答える']) {
        if (await _press(t, action)) {
          await _frames(t, 20);
          await _answerQuiz(t);
        }
      }
      expect(t.takeException(), isNull, reason: '「$ch」のダイアログ');
      await _closeAll(t);
      await _frames(t, 5);
    }
    expect(seen, containsAll(['S', 'I', 'X', 'C', 'E', 'G']));
    // エリア名の見出しを消すタイマーが終わるまで待つ
    await _frames(t, 40);
  });

  testWidgets('試験対策ワールドのフィールドでも仕掛けに話しかけられる', (t) async {
    final picked = ExamWorlds.matchAll({'math': '2次関数', 'social': '明治維新'});
    final plan = ExamWorldPlan(
      id: 'f1',
      title: '中間',
      worldId: 'math',
      stageIds: [for (final s in picked) s.id],
      createdAt: DateTime(2026),
    );
    await openScreen(
      t,
      FieldScreen.exam(plan: plan, progress: RpgProgress.initial),
      frames: 20,
    );
    final g = _game(t);
    for (final ch in ['I', 'C', 'W', 'D', 'E']) {
      final cells = g.map.findAll(ch)..sort((a, b) => b.row.compareTo(a.row));
      if (cells.isEmpty) continue;
      await _bump(t, g, cells.first);
      for (final action in ['鍵をあける', '問いに答える', '泉の問いに答える']) {
        if (await _press(t, action)) {
          await _frames(t, 20);
          await _answerQuiz(t);
        }
      }
      expect(t.takeException(), isNull, reason: '試験ワールドの「$ch」');
      await _closeAll(t);
    }
    await _frames(t, 40);
  });

  for (final exam in [false, true]) {
    testWidgets('フィールドから「たたかう」でバトルに入れる（${exam ? '試験ワールド' : '英語ワールド'}）', (
      t,
    ) async {
      final plan = ExamWorldPlan(
        id: 'b1',
        title: '中間',
        worldId: 'math',
        stageIds: [
          for (final s in ExamWorlds.matchAll({'math': '2次関数'})) s.id,
        ],
        createdAt: DateTime(2026),
      );
      await openScreen(
        t,
        exam
            ? FieldScreen.exam(plan: plan, progress: RpgProgress.initial)
            : FieldScreen(
                world: RpgCatalog.world(RpgCatalog.englishWorldId),
                progress: RpgProgress.initial,
              ),
        frames: 20,
      );
      final g = _game(t);
      final gate = g.map.enemySpots.entries
          .reduce((a, b) => a.key < b.key ? a : b)
          .value;
      await _bump(t, g, gate);
      expect(await _press(t, 'たたかう'), isTrue);
      await _frames(t, 40);
      expect(t.takeException(), isNull);
      expect(find.textContaining('HP'), findsWidgets);
      await _frames(t, 40);
    });
  }
}
