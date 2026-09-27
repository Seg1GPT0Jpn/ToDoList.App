import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/versus/online_lobby_screen.dart';
import 'package:rpg_game_app/versus/online_room.dart';
import 'package:rpg_game_app/versus/versus_screen.dart';

import 'harness.dart';

final _qs = [
  for (var i = 0; i < 12; i++)
    QuizQuestion(
      id: 'english_q$i',
      category: QuestionCategory.usage,
      prompt: '問題$i',
      choices: const ['せいかい', 'はずれA', 'はずれB', 'はずれC'],
      answerIndex: 0,
      explanation: '解説',
    ),
];

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  onlineTests();
  testWidgets('対戦の準備画面が開ける', (t) async {
    await openScreen(t, const VersusSetupScreen(), size: const Size(420, 1200));
    expect(find.text('対戦スタート！'), findsOneWidget);
    await t.tap(find.text('この端末で2人'));
    await _frames(t, 2);
    expect(find.text('相手の名前（上）'), findsOneWidget);
  });

  testWidgets('CPU と対戦して、正解し続ければ勝てる', (t) async {
    await openScreen(
      t,
      VersusScreen(
        questions: _qs,
        names: const ['あお', 'CPU'],
        cpu: CpuLevel.easy,
        rounds: 10,
        random: Random(1),
      ),
      size: const Size(420, 900),
      frames: 5,
    );
    for (var i = 0; i < 12; i++) {
      if (find.text('もう一度').evaluate().isNotEmpty) break;
      final c = find.widgetWithText(OutlinedButton, 'せいかい');
      if (c.evaluate().isNotEmpty) await t.tap(c.first, warnIfMissed: false);
      await _frames(t, 20);
      expect(t.takeException(), isNull);
    }
    expect(find.text('あなたの勝ち！'), findsOneWidget);
    await t.tap(find.text('もう一度'));
    await _frames(t, 5);
    expect(find.text('あなたの勝ち！'), findsNothing);
    await t.tap(find.byIcon(Icons.close));
    await _frames(t, 10);
  });

  testWidgets('2人対戦：上の人（さかさま）が先に正解すると、下の人がダメージ', (t) async {
    await openScreen(
      t,
      VersusScreen(
        questions: _qs,
        names: const ['あお', 'あか'],
        rounds: 10,
        random: Random(1),
      ),
      size: const Size(420, 900),
      frames: 5,
    );
    // 選択肢は上と下に2組ある。上の人（1番目にある）の「せいかい」を押す
    final buttons = find.widgetWithText(OutlinedButton, 'せいかい');
    expect(buttons, findsNWidgets(2));
    final top = t.getCenter(buttons.at(0)).dy < t.getCenter(buttons.at(1)).dy
        ? buttons.at(0)
        : buttons.at(1);
    await t.tap(top);
    await _frames(t, 3);
    expect(find.textContaining('あかに先をこされた'), findsOneWidget);
    expect(
      find.text('${100 - VersusMatch.baseDamage - VersusMatch.fastBonus}'),
      findsOneWidget,
    );
    await _frames(t, 20);
    // 下の人がお手つき → 上の人だけが答えられる
    final wrong = find.widgetWithText(OutlinedButton, 'はずれA');
    final bottom = t.getCenter(wrong.at(0)).dy > t.getCenter(wrong.at(1)).dy
        ? wrong.at(0)
        : wrong.at(1);
    await t.tap(bottom);
    await _frames(t, 3);
    expect(find.textContaining('お手つき'), findsOneWidget);
    await _frames(t, 200);
    expect(t.takeException(), isNull);
  });
}

void onlineTests() {
  testWidgets('オンライン：相手（ホスト）の正解が届き、自分（ゲスト）の答えも部屋に書きこまれる', (t) async {
    final hub = MemoryRoomHub();
    final host = MemoryVersusBackend(hub, userId: 'host');
    final guest = MemoryVersusBackend(hub, userId: 'guest');
    const config = VersusRoomConfig(setIds: [], seed: 5, rounds: 5);
    final code = await host.create(config, 'ホスト');
    await guest.join(code, 'ゲスト');
    // ホストの端末と同じ並びで問題を作る（答えを知るため）
    VersusMatch replica() => VersusMatch(
      questions: _qs,
      names: const ['ホスト', 'ゲスト'],
      rounds: 5,
      random: Random(5),
    );
    final mirror = replica();
    await openScreen(
      t,
      VersusScreen(
        questions: _qs,
        names: const ['ホスト', 'ゲスト'],
        rounds: 5,
        online: OnlineLink(backend: guest, code: code, localSide: 1, seed: 5),
      ),
      size: const Size(420, 900),
      frames: 3,
    );
    // ホストが1問目に正解
    final e1 = VersusEvent(
      round: 1,
      side: 0,
      choice: mirror.current.correctIndex,
      ms: 5000,
    );
    await t.runAsync(() => host.send(code, e1, (b) => true));
    mirror.apply(e1);
    await _frames(t, 3);
    expect(find.textContaining('ホストに先をこされた'), findsOneWidget);
    expect(find.text('${100 - VersusMatch.baseDamage}'), findsOneWidget);
    await _frames(t, 20);
    // ゲスト（自分）が2問目に正解する
    await t.tap(find.widgetWithText(OutlinedButton, 'せいかい').first);
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await _frames(t, 3);
    expect(hub.rooms[code]!.events.length, 2);
    expect(hub.rooms[code]!.events.last.side, 1);
    expect(find.textContaining('正解！'), findsOneWidget);
    // ホストが部屋を出ると知らせる
    await t.runAsync(() => host.close(code));
    await _frames(t, 30);
    expect(find.text('相手が部屋を出ました'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('オンライン：部屋をつくると番号が出て、相手が入ると対戦がはじまる', (t) async {
    final hub = MemoryRoomHub();
    final host = MemoryVersusBackend(hub, userId: 'host');
    await openScreen(
      t,
      OnlineLobbyScreen(
        name: 'ホスト',
        setIds: const ['english_stage_01'],
        rounds: 5,
        backend: host,
      ),
      size: const Size(420, 900),
    );
    await t.tap(find.text('部屋をつくる').last);
    await _frames(t, 3);
    final code = hub.rooms.keys.single;
    expect(find.text(code), findsOneWidget);
    await t.runAsync(
      () => MemoryVersusBackend(hub, userId: 'guest').join(code, 'ゲスト'),
    );
    for (
      var i = 0;
      i < 30 && find.byType(VersusScreen).evaluate().isEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VersusScreen), findsOneWidget);
    await _frames(t, 5);
    expect(t.takeException(), isNull);
    await t.tap(find.byIcon(Icons.close));
    await _frames(t, 10);
  });

  testWidgets('オンライン：ログインしていないと、案内が出る', (t) async {
    await openScreen(
      t,
      OnlineLobbyScreen(
        name: 'わたし',
        setIds: const [],
        rounds: 5,
        backend: MemoryVersusBackend(MemoryRoomHub(), userId: null),
      ),
    );
    expect(find.textContaining('Google でログインすると'), findsOneWidget);
  });
}
