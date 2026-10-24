import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/term_cards.dart';
import 'package:rpg_game_app/vocab/speech.dart';
import 'package:rpg_game_app/vocab/vocab_book_screen.dart';
import 'package:rpg_game_app/vocab/vocab_session_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';

import 'harness.dart';

const _deck = TermDeck(
  id: 'testdeck',
  worldId: 'japanese',
  title: '古文テスト',
  cards: [
    TermCard(
      term: '艮',
      reading: 'うしとら',
      meaning: '北東',
      related: ['巽'],
      trivia: '鬼門とされた方角',
      section: '方角',
    ),
    TermCard(
      term: '巽',
      reading: 'たつみ',
      meaning: '南東',
      related: ['艮'],
      trivia: '辰と巳の間',
      section: '方角',
    ),
    TermCard(
      term: '坤',
      reading: 'ひつじさる',
      meaning: '南西',
      related: ['艮'],
      trivia: '未と申の間',
      section: '方角',
    ),
    TermCard(
      term: '乾',
      reading: 'いぬゐ',
      meaning: '北西',
      related: ['艮'],
      trivia: '戌と亥の間',
      section: '方角',
    ),
    TermCard(
      term: '睦月',
      meaning: '1月（旧暦）',
      related: ['如月'],
      trivia: '旧暦では1〜3月が春',
      section: '月',
    ),
  ],
);

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => speaker = SilentSpeaker());

  testWidgets('暗記カードの練習：めくる・4択（説明→用語）・用語を書く（読みでもよい）', (t) async {
    await openScreen(t, const SizedBox());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = _deck.toBook();
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => VocabSessionScreen(
          store: store,
          book: book,
          title: '練習',
          random: Random(1),
          tasks: const [
            VocabTask('艮', VocabMode.flashcard, isNew: true),
            VocabTask('巽', VocabMode.choiceTerm),
            VocabTask('坤', VocabMode.spelling),
            VocabTask('乾', VocabMode.spelling),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();

    // 発音のボタンは出さない
    expect(find.byIcon(Icons.volume_up), findsNothing);
    expect(find.text('新しい用語'), findsOneWidget);
    expect(find.text('艮'), findsOneWidget);
    await t.tap(find.text('めくる'));
    await t.pump();
    expect(find.text('（うしとら）'), findsOneWidget);
    expect(find.textContaining('鬼門'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('rate-good')));
    await t.pumpAndSettle();

    // 説明 → 用語
    expect(find.text('南東'), findsOneWidget);
    expect(find.text('用語はどれ？'), findsOneWidget);
    await t.tap(find.widgetWithText(OutlinedButton, '巽'));
    await t.pump();
    expect(find.text('○ 正解'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('vocab-next')));
    await t.pumpAndSettle();

    // 用語を書く：カタカナの読みでも正解
    expect(find.textContaining('「坤」で始まる1文字'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('vocab-input')), 'ヒツジサル');
    await t.tap(find.text('答える'));
    await t.pump();
    expect(find.text('○ 正解'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('vocab-next')));
    await t.pumpAndSettle();

    // まちがえる：理由に「発音」は出さない
    await t.enterText(find.byKey(const ValueKey('vocab-input')), '艮');
    await t.tap(find.text('答える'));
    await t.pump();
    expect(find.text('× 正解は「乾」'), findsOneWidget);
    expect(find.text('書けなかった'), findsOneWidget);
    expect(find.text('発音が分からない'), findsNothing);
    await t.ensureVisible(find.byKey(const ValueKey('vocab-next')));
    await t.tap(find.byKey(const ValueKey('vocab-next')));
    await t.pumpAndSettle();
    final p = store.progress(book.id);
    expect(p.cards['乾']!.mistakes[MistakeReason.spelling], 1);
    expect(p.cards['坤']!.skills[VocabSkill.spelling]!.reps, 1);
    expect(t.takeException(), isNull);
  });

  testWidgets('暗記カードの学習画面：章ごとの練習・用語の熟練度（発音・例文なし）', (t) async {
    await openScreen(t, const SizedBox());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = _deck.toBook();
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => VocabBookScreen(store: store, book: book),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('古文テスト（5枚）'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byKey(const ValueKey('vocab-mode-spelling')), findsOneWidget);
    expect(find.text('用語を書く'), findsOneWidget);
    expect(find.byKey(const ValueKey('vocab-mode-listening')), findsNothing);
    expect(find.byKey(const ValueKey('vocab-mode-cloze')), findsNothing);
    await t.dragUntilVisible(
      find.text('章ごとに練習'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.text('方角'), findsOneWidget);

    await t.tap(find.text('用語'));
    await t.pumpAndSettle();
    expect(find.textContaining('書き（用語を書く）'), findsOneWidget);
    expect(find.textContaining('発音'), findsNothing);
    await t.tap(find.text('艮'));
    await t.pumpAndSettle();
    expect(find.text('艮（うしとら）'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('暗記カードのタブ：今日の最適学習・苦手克服カード・学習する', (t) async {
    final science = RpgCatalog.world('science');
    await openScreen(
      t,
      Scaffold(
        body: TermCardsTab(
          world: science,
          progress: RpgProgress.initial.copyWith(
            purchasedWorldIds: {'science'},
          ),
        ),
      ),
      frames: 5,
    );
    await _settle(t);
    expect(find.byKey(const ValueKey('term-today')), findsOneWidget);
    expect(find.byKey(const ValueKey('term-weak-cards')), findsOneWidget);
    expect(find.textContaining('今日のあなた（理科）'), findsOneWidget);
    final study = find.byKey(const ValueKey('deck-study-physics'));
    await t.scrollUntilVisible(study, 200);
    await t.tap(study);
    await _settle(t);
    expect(find.byType(VocabBookScreen), findsOneWidget);
    expect(find.textContaining('物理（'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('国語・情報にも暗記カードがある', (t) async {
    for (final id in ['japanese', 'information']) {
      await openScreen(
        t,
        Scaffold(
          body: TermCardsTab(
            world: RpgCatalog.world(id),
            progress: RpgProgress.initial.copyWith(purchasedWorldIds: {id}),
          ),
        ),
        frames: 5,
      );
      await _settle(t);
      for (final info in TermDecks.of(id)) {
        await t.scrollUntilVisible(
          find.byKey(ValueKey('deck-${info.id}')),
          200,
        );
        expect(find.textContaining('${info.title}（'), findsWidgets);
      }
    }
    expect(t.takeException(), isNull);
  });
}
