import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/meta/streak_store.dart';
import 'package:rpg_game_app/vocab/vocab_session_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
import 'package:rpg_game_app/vocab/weak_cards_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<(VocabStore, VocabBook)> _book(RpgServices s) async {
  final store = VocabStore.of(s.personalBooks);
  final b = VocabBook(
    id: 'my1',
    title: '英検2級',
    kind: VocabBookKind.custom,
    cards: [
      for (var i = 1; i <= 6; i++)
        VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
    ],
  );
  store.books.add(b);
  await store.saveBooks();
  return (store, b);
}

void main() {
  testWidgets('勉強した日は、RPG と単語帳を合わせて数える', (t) async {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1, 12);
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final (store, b) = await _book(s);
    store
        .progress(b.id)
        .record(
          cardId: 'w1',
          skill: VocabSkill.meaning,
          rating: Rating.good,
          now: yesterday,
        );
    final days = StreakStore.studyDays(
      LearningRecord(studyDays: {dayNumber(today)}),
      store,
    );
    expect(days, {dayNumber(today), dayNumber(yesterday)});
  });

  testWidgets('苦手な単語がないときは、その説明を出す', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final (store, _) = await _book(s);
    await openScreen(
      t,
      WeakCardsScreen(store: store),
      frames: 5,
      keepPrefs: true,
    );
    expect(find.byKey(const ValueKey('weak-empty')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('2回間違えた単語を2回続けて正解するとカードになり、一覧に出る', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final (store, b) = await _book(s);
    final p = store.progress(b.id);
    final now = DateTime.now();
    for (final r in [Rating.again, Rating.again, Rating.good]) {
      p.record(cardId: 'w2', skill: VocabSkill.meaning, rating: r, now: now);
    }
    for (var i = 0; i < 2; i++) {
      p.record(
        cardId: 'w3',
        skill: VocabSkill.meaning,
        rating: Rating.again,
        now: now,
      );
    }
    await store.saveProgress(b.id);
    await openScreen(
      t,
      WeakCardsScreen(store: store),
      frames: 5,
      keepPrefs: true,
    );
    expect(find.text('集めたカード 0枚'), findsOneWidget);
    expect(find.textContaining('もう少し：word2、word3'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('weak-practice-my1')));
    await _frames(t);
    expect(find.byType(VocabSessionScreen), findsOneWidget);
    // 練習の1問目（word2）を正解にして、カードになることを確かめる
    p.record(
      cardId: 'w2',
      skill: VocabSkill.meaning,
      rating: Rating.good,
      now: now,
    );
    expect(WeakCards.collected(b, p).single.card.id, 'w2');
    expect(t.takeException(), isNull);
  });

  testWidgets('7日続くとお休み券がもらえて、札に出る', (t) async {
    final today = RpgServices.today();
    final days = [for (var i = 0; i < 7; i++) today - i];
    await openScreen(
      t,
      const Scaffold(body: Center(child: StreakTag())),
      frames: 5,
      prefs: {'rpg_learning_v1': '{"stats":{},"days":[${days.join(',')}]}'},
    );
    expect(find.textContaining('🔥 7 日連続'), findsOneWidget);
    expect(find.textContaining('🎫×1'), findsOneWidget);
    expect(find.textContaining('お休み券を1枚もらいました'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('昨日休んでも、お休み券があれば連続が切れない', (t) async {
    final today = RpgServices.today();
    final days = [for (var i = 2; i < 5; i++) today - i];
    await openScreen(
      t,
      const Scaffold(body: Center(child: StreakTag())),
      frames: 5,
      prefs: {
        'rpg_learning_v1': '{"stats":{},"days":[${days.join(',')}]}',
        'gentle_streak_v1': '{"t":1,"r":[],"a":[]}',
      },
    );
    expect(find.textContaining('🔥 3 日連続'), findsOneWidget);
    expect(find.textContaining('お休み券を1枚使って'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
