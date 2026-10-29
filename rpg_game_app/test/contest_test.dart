import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/versus/contest_backend.dart';
import 'package:rpg_game_app/versus/contest_screens.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 名前とパスワードで開いた EEVI のかわり（番号 1〜500）
Future<void> _addEevi(RpgServices s) async {
  final store = VocabStore.of(s.personalBooks);
  store.books.add(
    VocabBook(
      id: 'eevi',
      title: 'EEVI',
      kind: VocabBookKind.protectedImport,
      cards: [
        for (var i = 1; i <= 500; i++)
          VocabCard(id: 'e$i', number: i, term: 'word$i', meaning: '意味$i'),
      ],
    ),
  );
  await store.saveBooks();
  await s.personalBooks.prefs.setStringList('vocab_unlocked_books', ['eevi']);
}

/// 全問、正しい答えを選んで解く
Future<void> _solve(WidgetTester t, int count) async {
  for (var q = 0; q < count; q++) {
    await _frames(t, 2);
    final term = t.widget<Text>(find.byKey(const ValueKey('duel-term'))).data!;
    await t.tap(find.widgetWithText(OutlinedButton, '意味${term.substring(4)}'));
    await _frames(t, 9);
  }
  await _frames(t, 5);
}

/// 日本時間 10/30（金）の朝8時（EEVI の第1回の受付中）
DateTime _eeviDay() => DateTime.utc(2026, 10, 29, 23);

void main() {
  testWidgets('ログインしていないときは、その説明を出す', (t) async {
    await openScreen(
      t,
      ContestScreen(backend: MemoryContestBackend(userId: null)),
      frames: 5,
    );
    expect(find.text(ContestText.needLogin), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-login')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('EEVI を開いていない人は参加できない。日程は見える', (t) async {
    await openScreen(
      t,
      ContestScreen(backend: MemoryContestBackend(), now: _eeviDay),
      frames: 5,
      size: const Size(420, 1400),
    );
    expect(find.textContaining('受付中　EEVI 301〜350・20問'), findsOneWidget);
    expect(find.textContaining('10/30（金）19:15まで'), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-no-book-eevi')), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-play-eevi')), findsNothing);
    expect(
      find.textContaining('次回　LEAP 1801〜1900・20問\n10/31（土）18:00〜11/2（月）8:00'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('contest-upcoming-leap-2026-11-01')),
      findsOneWidget,
    );
    // 管理者でなければ、日程を変えるボタンは出ない
    expect(find.byKey(const ValueKey('contest-admin')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('EEVI の日に1回だけ挑戦でき、みんなの中の順位が出る', (t) async {
    final shared = <String, Map<String, ContestEntry>>{
      'eevi-2026-10-30': {
        'rival': const ContestEntry(
          uid: 'rival',
          name: 'らいばる',
          correct: 20,
          score: 99999,
          done: true,
        ),
      },
    };
    final me = MemoryContestBackend(userId: 'alice', entries: shared);
    final s = await openScreen(t, const SizedBox(), frames: 2);
    await _addEevi(s);
    await openScreen(
      t,
      ContestScreen(backend: me, now: _eeviDay),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 1400),
    );
    await t.enterText(find.byKey(const ValueKey('contest-name')), 'あり');
    await t.tap(find.byKey(const ValueKey('contest-play-eevi')));
    await _frames(t, 3);
    await t.tap(find.byKey(const ValueKey('contest-confirm')));
    await _frames(t, 3);
    // 範囲の中の単語だけが出る
    final term = t.widget<Text>(find.byKey(const ValueKey('duel-term'))).data!;
    final n = int.parse(term.substring(4));
    expect(n >= 301 && n <= 350, isTrue);
    await _solve(t, 20);
    final mine = shared['eevi-2026-10-30']!['alice']!;
    expect(mine.done, isTrue);
    expect(mine.correct, 20);
    expect(mine.name, 'あり');
    // 順位表
    expect(find.byKey(const ValueKey('contest-my-rank')), findsOneWidget);
    expect(find.textContaining('2位 / 2人'), findsOneWidget);
    expect(find.textContaining('あり（あなた）'), findsOneWidget);
    // もどると、もう挑戦できない
    await t.pageBack();
    await _frames(t, 5);
    expect(find.byKey(const ValueKey('contest-play-eevi')), findsNothing);
    expect(find.byKey(const ValueKey('contest-mine-eevi')), findsOneWidget);
    expect(
      VocabStore.of(s.personalBooks).progress('eevi').cards,
      hasLength(20),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('始めて途中でやめると、その回は記録なし', (t) async {
    final shared = <String, Map<String, ContestEntry>>{};
    final s = await openScreen(t, const SizedBox(), frames: 2);
    await _addEevi(s);
    await openScreen(
      t,
      ContestScreen(
        backend: MemoryContestBackend(userId: 'bob', entries: shared),
        now: _eeviDay,
      ),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 1400),
    );
    await t.tap(find.byKey(const ValueKey('contest-play-eevi')));
    await _frames(t, 3);
    await t.tap(find.byKey(const ValueKey('contest-confirm')));
    await _frames(t, 5);
    await t.pageBack();
    await _frames(t, 5);
    expect(shared['eevi-2026-10-30']!['bob']!.done, isFalse);
    expect(find.textContaining('記録なし'), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-play-eevi')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('受付が終わると挑戦できなくなり、最終ランキングが出る', (t) async {
    final shared = <String, Map<String, ContestEntry>>{
      'eevi-2026-10-30': {
        'a': const ContestEntry(
          uid: 'a',
          name: 'えー',
          correct: 18,
          score: 2400,
          done: true,
        ),
      },
    };
    final s = await openScreen(t, const SizedBox(), frames: 2);
    await _addEevi(s);
    // 日本時間 10/30（金）19:15（EEVI の受付が終わったところ）
    DateTime after() => DateTime.utc(2026, 10, 30, 10, 15);
    await openScreen(
      t,
      ContestScreen(
        backend: MemoryContestBackend(userId: 'z', entries: shared),
        now: after,
      ),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 1400),
    );
    expect(find.byKey(const ValueKey('contest-play-eevi')), findsNothing);
    expect(find.textContaining('最終ランキング発表！（301〜350）'), findsOneWidget);
    expect(
      find.textContaining('次回　EEVI 351〜400・20問\n11/5（木）18:00〜11/6（金）19:15'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const ValueKey('contest-last-eevi')));
    await _frames(t, 5);
    expect(find.byKey(const ValueKey('contest-final')), findsOneWidget);
    expect(find.textContaining('1位　えー'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('管理者だけが日程と範囲を変えられる', (t) async {
    final admin = MemoryContestBackend(
      userId: 'k',
      email: ContestRules.adminEmail,
    );
    await openScreen(
      t,
      ContestScreen(backend: admin, now: _eeviDay),
      frames: 5,
      size: const Size(420, 2800),
    );
    await t.tap(find.byKey(const ValueKey('contest-admin')));
    await _frames(t, 5);
    // EEVI の範囲の広さを 30 にして、11/6 もお休みにする
    await t.enterText(
      find.byKey(const ValueKey('contest-admin-eevi-範囲の広さ')),
      '30',
    );
    await t.enterText(
      find.byKey(const ValueKey('contest-admin-eevi-お休みの日（1行に1日）')),
      '2026-11-13\n2026-11-06',
    );
    await _frames(t, 2);
    expect(
      find.byKey(const ValueKey('contest-preview-eevi-2026-11-06')),
      findsNothing,
    );
    expect(
      find.textContaining('EEVI 331〜360（20問）\n　11/19（木）18:00〜11/20（金）19:15'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const ValueKey('contest-admin-save')));
    await _frames(t, 5);
    final eevi = admin.config.plans['eevi']!;
    expect(eevi.width, 30);
    expect(eevi.skips, {'2026-11-13', '2026-11-06'});
    // 読めない日付は保存できない
    await t.tap(find.byKey(const ValueKey('contest-admin')));
    await _frames(t, 5);
    await t.enterText(
      find.byKey(const ValueKey('contest-admin-leap-第1回の日付')),
      '11月1日',
    );
    await _frames(t, 2);
    expect(find.textContaining('LEAP：第1回の日付は'), findsOneWidget);
    expect(t.takeException(), isNull);

    // 管理者でなければ保存できない
    final other = MemoryContestBackend(email: 'someone@gmail.com');
    expect(
      () => other.saveConfig(ContestConfig.initial),
      throwsA(isA<Object>()),
    );
  });

  testWidgets('バトルの日は、単語帳練習の入口が目立つ', (t) async {
    // 日付は端末の今日で決まるので、今日が EEVI の日の設定にする
    final today = ContestRules.jstToday(DateTime.now());
    final config = ContestConfig({
      'eevi': ContestConfig.initial.plans['eevi']!.copyWith(
        first: today,
        openMin: -2880,
        closeMin: 2880,
      ),
      'leap': ContestConfig.initial.plans['leap']!.copyWith(
        first: today.add(const Duration(days: 2)),
      ),
    });
    final s2 = await openScreen(t, const SizedBox(), frames: 2);
    await _addEevi(s2);
    await openScreen(
      t,
      Scaffold(
        body: ContestEntryButton(
          store: VocabStore.of(s2.personalBooks),
          backend: MemoryContestBackend(config: config),
        ),
      ),
      frames: 5,
      keepPrefs: true,
    );
    expect(find.textContaining('EEVIバトル受付中！（301〜350・'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
