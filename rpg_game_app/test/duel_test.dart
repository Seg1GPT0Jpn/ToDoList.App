import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/versus/duel_backend.dart';
import 'package:rpg_game_app/versus/duel_screens.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<VocabBook> _addBook(RpgServices s) async {
  final store = VocabStore.of(s.personalBooks);
  final b = VocabBook(
    id: 'leap',
    title: 'LEAP',
    kind: VocabBookKind.custom,
    cards: [
      for (var i = 1; i <= 60; i++)
        VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
    ],
  );
  store.books.add(b);
  await store.saveBooks();
  return b;
}

/// 10問を、正しい答えを選んで解く
Future<void> _solve(WidgetTester t) async {
  for (var q = 0; q < WordDuel.count; q++) {
    await _frames(t, 2);
    final term = t.widget<Text>(find.byKey(const ValueKey('duel-term'))).data!;
    final meaning = '意味${term.substring(4)}';
    await t.tap(find.widgetWithText(OutlinedButton, meaning));
    await _frames(t, 9);
  }
  await _frames(t, 5);
}

void main() {
  test('貼り付けた文字からIDを取り出す', () {
    expect(
      DuelText.idFrom(
        '勝てるかな？\nhttps://tsuzuri-quest-v2.web.app/?duel=abcd2345',
      ),
      'abcd2345',
    );
    expect(DuelText.idFrom(' abcd2345 '), 'abcd2345');
    expect(DuelText.idFrom('123'), isNull);
  });

  testWidgets('ログインしていないときは、その説明を出す', (t) async {
    await openScreen(
      t,
      DuelHubScreen(backend: MemoryDuelBackend(userId: null)),
      frames: 5,
    );
    expect(find.text(DuelText.needLogin), findsOneWidget);
    expect(find.byKey(const ValueKey('duel-login')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('先に解いてリンクをつくり、友だちがあとから同じ問題で挑戦して順位が出る', (t) async {
    final shared = <String, WordDuel>{};
    final alice = MemoryDuelBackend(userId: 'alice', store: shared);
    final owner = await openScreen(t, const SizedBox(), frames: 2);
    await _addBook(owner);
    await openScreen(
      t,
      DuelHubScreen(bookId: 'leap', from: 11, to: 40, backend: alice),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 1000),
    );
    await t.enterText(find.byKey(const ValueKey('duel-name')), 'あり');
    await t.tap(find.byKey(const ValueKey('duel-create')));
    await _solve(t);
    final duel = shared.values.single;
    expect(duel.numbers.every((n) => n >= 11 && n <= 40), isTrue);
    expect(duel.sourceId, 'leap');
    expect(duel.results['alice']!.correct, 10);
    expect(find.byKey(const ValueKey('duel-my-score')), findsOneWidget);
    expect(find.textContaining(DuelText.link(duel.id)), findsOneWidget);
    // 自分の単語帳で解いた分は、学習記録にも残る
    expect(
      VocabStore.of(owner.personalBooks).progress('leap').cards,
      hasLength(10),
    );

    // 友だち：同じ単語帳を持っている（別の端末なので、画面も最初から）
    await t.pumpWidget(const SizedBox());
    SharedPreferences.setMockInitialValues({});
    final bob = MemoryDuelBackend(userId: 'bob', store: shared);
    final friend = await openScreen(t, const SizedBox(), frames: 2);
    await _addBook(friend);
    await openScreen(
      t,
      DuelOpenScreen(id: duel.id, backend: bob),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 1000),
    );
    expect(find.text('ありさんからの挑戦'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('duel-open-name')), 'ぼぶ');
    await t.tap(find.byKey(const ValueKey('duel-accept')));
    await _solve(t);
    expect(shared[duel.id]!.results['bob']!.name, 'ぼぶ');
    expect(find.byKey(const ValueKey('duel-row-1')), findsOneWidget);
    expect(find.textContaining('ぼぶ（あなた）'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('つづ単なら、だれでもすぐに作れる', (t) async {
    final shared = <String, WordDuel>{};
    await openScreen(
      t,
      DuelHubScreen(
        backend: MemoryDuelBackend(userId: 'alice', store: shared),
      ),
      frames: 5,
      size: const Size(420, 1000),
    );
    await t.tap(find.byKey(const ValueKey('duel-create')));
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    for (var q = 0; q < WordDuel.count; q++) {
      await _frames(t, 2);
      await t.tap(find.byKey(const ValueKey('duel-choice-0')));
      await _frames(t, 9);
    }
    await _frames(t, 5);
    final d = shared.values.single;
    expect(d.source, DuelSource.tsuzutan);
    expect(d.numbers, hasLength(WordDuel.count));
    expect(t.takeException(), isNull);
  });

  testWidgets('単語帳を持っていない人には、その説明を出す', (t) async {
    final shared = <String, WordDuel>{};
    final alice = MemoryDuelBackend(userId: 'alice', store: shared);
    final d = await alice.create(
      const WordDuel(
        id: '',
        ownerId: '',
        ownerName: 'あり',
        source: DuelSource.book,
        sourceId: 'leap',
        title: 'LEAP 1〜50',
        numbers: [1, 2, 3, 4],
        seed: 1,
      ),
      const DuelResult(name: 'あり', correct: 3, score: 400),
    );
    await openScreen(
      t,
      DuelOpenScreen(
        id: d.id,
        backend: MemoryDuelBackend(userId: 'bob', store: shared),
      ),
      frames: 5,
    );
    expect(find.byKey(const ValueKey('duel-no-book')), findsOneWidget);
    expect(find.byKey(const ValueKey('duel-accept')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('時間切れは不正解（0点）で、次の問題へ進む', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final b = await _addBook(s);
    DuelResult? got;
    await openScreen(
      t,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            got = await Navigator.of(context).push<DuelResult>(
              MaterialPageRoute(
                builder: (_) => DuelPlayScreen(
                  name: 'あ',
                  title: 't',
                  questions: DuelRules.build(b, const [1, 2], 3),
                ),
              ),
            );
          },
          child: const Text('go'),
        ),
      ),
      frames: 2,
      keepPrefs: true,
    );
    await t.tap(find.text('go'));
    await _frames(t, 2);
    await _frames(t, 230);
    expect(got?.correct, 0);
    expect(got?.score, 0);
    expect(t.takeException(), isNull);
  });

  test('1人1回だけ', () async {
    final shared = <String, WordDuel>{};
    final alice = MemoryDuelBackend(userId: 'alice', store: shared);
    final d = await alice.create(
      const WordDuel(
        id: '',
        ownerId: '',
        ownerName: 'あり',
        source: DuelSource.tsuzutan,
        sourceId: 'x',
        title: 'x',
        numbers: [1],
        seed: 1,
      ),
      const DuelResult(name: 'あり', correct: 1, score: 150),
    );
    await expectLater(
      alice.submit(d.id, const DuelResult(name: 'あり', correct: 1, score: 150)),
      throwsA(isA<DuelException>()),
    );
  });
}
