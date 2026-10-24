import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/versus/matchmaking.dart';
import 'package:rpg_game_app/versus/online_room.dart';
import 'package:rpg_game_app/versus/random_match_screen.dart';
import 'package:rpg_game_app/versus/random_matcher.dart';
import 'package:rpg_game_app/versus/versus_screen.dart';

import 'harness.dart';

const _config = VersusRoomConfig(setIds: ['s1'], seed: 5, rounds: 10);

RandomMatcher _matcher(
  MemoryMatchmakingHub q,
  MemoryRoomHub r,
  String uid, {
  Set<String> blocked = const {},
}) => RandomMatcher(
  queue: MemoryMatchmaking(q, userId: uid),
  rooms: MemoryVersusBackend(r, userId: uid),
  name: uid,
  newConfig: () => _config,
  blocked: blocked,
  wait: const Duration(milliseconds: 300),
  tick: const Duration(milliseconds: 20),
  joinWait: const Duration(milliseconds: 100),
  random: Random(1),
);

void main() {
  group('相手さがし', () {
    test('だれもいなければ、ゴースト（なければ CPU のゴースト）と対戦する', () async {
      final q = MemoryMatchmakingHub();
      final r = MemoryRoomHub();
      final first = await _matcher(q, r, 'alice').run();
      expect(first, isA<FoundGhost>());
      expect((first! as FoundGhost).ghost.name, 'CPU');
      expect(q.queue, isEmpty);
      q.ghosts.add(
        const GhostRun(
          name: 'ぼぶ',
          setIds: ['s1'],
          seed: 1,
          rounds: 3,
          answers: [GhostAnswer(900, true), null, GhostAnswer(1500, false)],
        ),
      );
      final second = await _matcher(q, r, 'alice').run();
      expect((second! as FoundGhost).ghost.name, 'ぼぶ');
    });

    test('先に待っていた人を、あとから来た人が見つけて同じ部屋で対戦する', () async {
      final q = MemoryMatchmakingHub();
      final r = MemoryRoomHub();
      final a = _matcher(q, r, 'alice').run();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final b = _matcher(q, r, 'bob').run();
      final ra = await a as FoundPlayer;
      final rb = await b as FoundPlayer;
      expect(ra.side, 1);
      expect(rb.side, 0);
      expect(ra.room.code, rb.room.code);
      expect(ra.opponentId, 'bob');
      expect(rb.opponentId, 'alice');
      expect(q.queue, isEmpty);
    });

    test('ブロックした人とは対戦しない', () async {
      final q = MemoryMatchmakingHub();
      final r = MemoryRoomHub();
      final a = _matcher(q, r, 'alice', blocked: {'bob'}).run();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final b = _matcher(q, r, 'bob').run();
      expect(await a, isA<FoundGhost>());
      expect(await b, isA<FoundGhost>());
    });

    test('やめると、待ち合わせから抜ける', () async {
      final q = MemoryMatchmakingHub();
      final m = _matcher(q, MemoryRoomHub(), 'alice');
      final run = m.run();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(q.queue.keys, ['alice']);
      m.cancel();
      expect(await run, isNull);
      expect(q.queue, isEmpty);
    });
  });

  test('ランダム対戦の出題は全教科から', () {
    final c = randomMatchConfig(Random(2));
    final worlds = {
      for (final id in c.setIds)
        RpgCatalog.worlds
            .firstWhere(
              (w) => w.stages.any((s) => s.questionSetIds.contains(id)),
            )
            .id,
    };
    expect(
      worlds.length,
      RpgCatalog.worlds.where((w) => !w.isComingSoon).length,
    );
    expect(c.rounds, 10);
  });

  testWidgets('ログインしていないときは、その説明を出す', (t) async {
    await openScreen(
      t,
      RandomMatchScreen(
        queue: MemoryMatchmaking(MemoryMatchmakingHub(), userId: null),
        rooms: MemoryVersusBackend(MemoryRoomHub(), userId: null),
      ),
      frames: 5,
    );
    expect(find.text(RandomMatchText.needLogin), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('だれもいないと、ゴーストとの対戦が始まる', (t) async {
    final q = MemoryMatchmakingHub();
    await openScreen(
      t,
      RandomMatchScreen(
        queue: MemoryMatchmaking(q, userId: 'alice'),
        rooms: MemoryVersusBackend(MemoryRoomHub(), userId: 'alice'),
        wait: const Duration(seconds: 4),
      ),
      frames: 5,
      size: const Size(420, 900),
    );
    await t.enterText(find.byKey(const ValueKey('random-name')), 'あり');
    await t.tap(find.byKey(const ValueKey('random-search')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('random-searching')), findsOneWidget);
    for (var i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VersusScreen), findsOneWidget);
    expect(find.text('CPU（ゴースト）'), findsOneWidget);
    // 人との対戦ではないので、スタンプは出ない
    expect(find.byKey(const ValueKey('stamp-0')), findsNothing);
  });

  testWidgets('オンライン対戦では、決まったスタンプだけを送り合える', (t) async {
    final hub = MemoryRoomHub();
    final host = MemoryVersusBackend(hub, userId: 'alice');
    final code = await host.create(_config, 'あり');
    await MemoryVersusBackend(hub, userId: 'bob').join(code, 'ぼぶ');
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final questions = await loadVersusQuestions(s, const ['english_stage_01']);
    await openScreen(
      t,
      VersusScreen(
        questions: questions,
        names: const ['あり', 'ぼぶ'],
        rounds: 10,
        online: OnlineLink(backend: host, code: code, localSide: 0, seed: 5),
      ),
      frames: 3,
      keepPrefs: true,
      size: const Size(420, 900),
    );
    await t.tap(find.byKey(const ValueKey('stamp-1')));
    await t.pump();
    expect(hub.rooms[code]!.stamps[0], (1, 1));
    await MemoryVersusBackend(hub, userId: 'bob').stamp(code, 1, 0, 1);
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('versus-bubble')), findsOneWidget);
    expect(find.text(VersusStamps.all[0]), findsWidgets);
    await t.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('versus-bubble')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
