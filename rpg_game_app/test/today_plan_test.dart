import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/cloud/tsuzuri_link.dart';
import 'package:rpg_game_app/meta/today_plan.dart';
import 'package:rpg_game_app/vocab/vocab_session_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';

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
      for (var i = 1; i <= 8; i++)
        VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
    ],
  );
  store.books.add(b);
  await store.saveBooks();
  return (store, b);
}

/// 4択の単語の練習を開く
Future<void> _session(
  WidgetTester t,
  VocabStore store,
  VocabBook b,
  List<String> ids,
) async {
  t
      .state<NavigatorState>(find.byType(Navigator))
      .push(
        MaterialPageRoute<void>(
          builder: (_) => VocabSessionScreen(
            store: store,
            book: b,
            title: '練習',
            random: Random(1),
            tasks: [
              for (final id in ids) VocabTask(id, VocabMode.choiceMeaning),
            ],
          ),
        ),
      );
  await _frames(t, 5);
}

/// 今の4択に正しく答える
Future<void> _answerRight(WidgetTester t) async {
  final term = find.textContaining(RegExp(r'^word\d+$'));
  final word = t.widget<Text>(term.first).data!;
  await t.tap(find.text('意味${word.substring(4)}'));
  await t.pump();
}

void main() {
  testWidgets('勘で当たったときは、続けて正解した数に入れない', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final (store, b) = await _book(s);
    await _session(t, store, b, ['w1']);
    await _answerRight(t);
    await t.ensureVisible(find.byKey(const ValueKey('vocab-guess')));
    await t.tap(find.byKey(const ValueKey('vocab-guess')));
    await _frames(t, 5);
    final m = store.progress(b.id).cards['w1']!.skills[VocabSkill.meaning]!;
    expect(m.reps, 1);
    expect(m.streak, 0);
    expect(t.takeException(), isNull);
  });

  testWidgets('練習のあとに、今の単語の魔物と1戦だけ戦える', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final (store, b) = await _book(s);
    await _session(t, store, b, ['w1', 'w2', 'w3']);
    for (var i = 0; i < 3; i++) {
      await _answerRight(t);
      await t.tap(find.byKey(const ValueKey('vocab-next')));
      await _frames(t, 5);
    }
    expect(find.text('おつかれさま！'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('vocab-quick-battle')));
    await t.tap(find.byKey(const ValueKey('vocab-quick-battle')));
    await _frames(t, 20);
    expect(find.byType(BattleScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 30));
  });

  testWidgets('今日やること：単語帳がなければ始め方、あれば今日の3分', (t) async {
    var adventured = false;
    await openScreen(
      t,
      Scaffold(
        body: ListView(
          children: [TodayPlanCard(onAdventure: () => adventured = true)],
        ),
      ),
      frames: 5,
    );
    expect(find.text('単語帳をはじめる'), findsOneWidget);
    expect(find.text('冒険：1戦だけ'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('today-adventure')));
    expect(adventured, isTrue);
    expect(find.byKey(const ValueKey('today-all-done')), findsNothing);

    final s = RpgServicesHolder.last!;
    await _book(s);
    await openScreen(
      t,
      Scaffold(
        body: ListView(children: [TodayPlanCard(onAdventure: () {})]),
      ),
      frames: 5,
      keepPrefs: true,
    );
    expect(find.textContaining('単語の復習：英検2級'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('today-vocab')));
    await _frames(t, 5);
    expect(find.byType(VocabSessionScreen), findsOneWidget);
    expect(find.text('今日の3分'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('試験の前日は、テストの行が最近間違えた問題の最終チェックになる', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final now = DateTime.now();
    await s.examWorlds.add(
      ExamWorldPlan(
        id: 'e1',
        title: '2学期中間',
        worldId: 'math',
        stageIds: const [],
        createdAt: now,
        examDate: DateTime(now.year, now.month, now.day + 1),
      ),
    );
    final today = RpgServices.today();
    await s.meta.save(
      record: LearningRecord(
        stats: {
          'q1': QuestionStat(
            setId: 'math_stage_01',
            attempts: 2,
            correct: 0,
            missStreak: 2,
            lastDay: today,
          ),
        },
      ),
    );
    await openScreen(
      t,
      Scaffold(
        body: ListView(children: [TodayPlanCard(onAdventure: () {})]),
      ),
      frames: 5,
      keepPrefs: true,
    );
    expect(find.text('「2学期中間」の最終チェック：最近間違えた1問'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('前に混同した単語は、正解とその単語の2択で見分ける', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final (store, b) = await _book(s);
    store.progress(b.id).cards.putIfAbsent('w1', CardProgress.new)
      ..confusedWith.add('word5')
      ..mistakes[MistakeReason.confused] = 1;
    t
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => VocabSessionScreen(
              store: store,
              book: b,
              title: '練習',
              random: Random(1),
              tasks: const [VocabTask('w1', VocabMode.compare)],
            ),
          ),
        );
    await _frames(t, 5);
    expect(find.text('前に間違えた2つの単語。この意味はどっち？'), findsOneWidget);
    expect(find.text('word1'), findsOneWidget);
    expect(find.text('word5'), findsOneWidget);
    expect(find.text('word2'), findsNothing);
    // 選択肢でほかの単語を選んだら、混同として両方に記録する
    await t.tap(find.text('word5'));
    await t.pump();
    await t.ensureVisible(find.byKey(const ValueKey('vocab-next')));
    await t.tap(find.byKey(const ValueKey('vocab-next')));
    await _frames(t, 5);
    final p = store.progress(b.id);
    expect(p.cards['w1']!.mistakes[MistakeReason.confused], 2);
    expect(p.cards['w5']!.confusedWith, contains('word1'));
    expect(t.takeException(), isNull);
  });

  testWidgets('今日やること：つづりの3日以内のテストを出し、対策した時間で「おわり」', (t) async {
    final tomorrow = StudyLog.dayKey(
      DateTime.now().add(const Duration(days: 1)),
    );
    final backend = MemoryTsuzuriBackend()
      ..upcomingDoc = {
        'items': [
          {
            'date': tomorrow,
            'title': '化学基礎 小テスト',
            'kind': '小テスト',
            'isTest': true,
            'subject': '化学基礎',
          },
        ],
      };
    final s = await openScreen(
      t,
      Scaffold(
        body: SingleChildScrollView(child: TodayPlanCard(onAdventure: () {})),
      ),
      tsuzuri: backend,
      frames: 2,
    );
    await s.tsuzuri!.connect();
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('「化学基礎 小テスト」（明日）：範囲を対策する'), findsOneWidget);
    await s.tsuzuri!.addPrep(
      s.tsuzuri!.upcoming.first,
      const Duration(minutes: 11),
    );
    await t.pump();
    expect(find.textContaining('対策 11分'), findsOneWidget);
    // 対策のあとは少し待ってつづりへ送る
    await t.pump(const Duration(seconds: 6));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(t.takeException(), isNull);
  });
}
