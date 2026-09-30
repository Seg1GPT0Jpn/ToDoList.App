import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/vocab/speech.dart';
import 'package:rpg_game_app/vocab/vocab_home.dart';
import 'package:rpg_game_app/vocab/vocab_session_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';

import 'harness.dart';

const _words = '''1\tagree\t[自] ①賛成する
2\toppose\t[他] ～に反対する
3\tadvise\t[他] ～に忠告する
4\ttip\t[名] ①助言，ヒント
5\tdiscuss\t[他] ～について話し合う''';

Widget _home() => Builder(
      builder: (c) => Scaffold(
        body: VocabHome(books: RpgServices.of(c).personalBooks),
      ),
    );

void main() {
  setUp(() => speaker = SilentSpeaker());

  testWidgets('LEAP・EEVI はパスワード shonanonly で開き、貼り付けて取り込める', (tester) async {
    await openScreen(tester, _home());
    expect(find.text('LEAP'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('vocab-password')), 'LEAP');
    await tester.tap(find.text('ひらく'));
    await tester.pump();
    expect(find.text('パスワードがちがいます'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('vocab-password')), 'shonanonly');
    await tester.tap(find.text('ひらく'));
    await tester.pump();
    expect(find.text('LEAP'), findsOneWidget);
    expect(find.text('EEVI'), findsOneWidget);

    // EEVI に STEP の形で取り込む
    await tester.tap(find.text('EEVI'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('vocab-import-text')),
      '1\nrise\n■動詞：上がる　■名詞：上昇\n›\n\n2\nraise\n■動詞：～を上げる\n›\n\n'
      '3\nlie\n■動詞：横たわる\n›\n\n4\nlay\n■動詞：～を横たえる\n›\n\n5\nreach\n■動詞：～に到着する\n›',
    );
    await tester.ensureVisible(find.text('取り込む'));
    await tester.tap(find.text('取り込む'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5語　'), findsOneWidget);
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    expect(store.book('eevi')!.cards.first.meaning, '[動] 上がる [名] 上昇');
  });

  testWidgets('以前の LEAP タブに取り込んだ単語を引きつぐ', (tester) async {
    await openScreen(
      tester,
      _home(),
      prefs: {'personal_book_leap': _words, 'vocab_unlocked': true},
    );
    expect(find.textContaining('5語　'), findsOneWidget);
  });

  testWidgets('練習：新しい単語をめくって評価、4択、スペル（間違えた理由を記録）', (tester) async {
    await openScreen(tester, const SizedBox());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = await store.createBook('自作');
    book.merge(VocabParser.parse(_words));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(
      builder: (_) => VocabSessionScreen(
        store: store,
        book: book,
        title: '練習',
        random: Random(1),
        tasks: const [
          VocabTask('1', VocabMode.flashcard, isNew: true),
          VocabTask('2', VocabMode.choiceMeaning),
          VocabTask('3', VocabMode.spelling),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    // 1. フラッシュカード
    expect(find.text('agree'), findsOneWidget);
    await tester.tap(find.text('めくる'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rate-good')));
    await tester.pumpAndSettle();
    final p = store.progress(book.id);
    expect(p.cards['1']!.skills[VocabSkill.meaning]!.reps, 1);
    expect(p.newToday(DateTime.now()), 1);

    // 2. 4択 英→日
    expect(find.text('oppose'), findsOneWidget);
    await tester.tap(find.text('～に反対する'));
    await tester.pump();
    expect(find.text('○ 正解'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('vocab-next')));
    await tester.pumpAndSettle();

    // 3. スペルをまちがえる → 理由を選ぶ
    await tester.enterText(find.byKey(const ValueKey('vocab-input')), 'advice');
    await tester.tap(find.text('答える'));
    await tester.pump();
    expect(find.text('× 正解は「advise」'), findsOneWidget);
    expect(find.text('なぜ間違えましたか？'), findsOneWidget);
    await tester.ensureVisible(find.text('似た単語と混同した'));
    await tester.tap(find.text('似た単語と混同した'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('vocab-next')));
    await tester.tap(find.byKey(const ValueKey('vocab-next')));
    await tester.pumpAndSettle();
    expect(p.cards['3']!.mistakes[MistakeReason.confused], 1);

    // 間違えた単語は最後にもう一度出る
    expect(find.textContaining('4 / 4'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('vocab-input')), 'Advise');
    await tester.tap(find.text('答える'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('vocab-next')));
    await tester.pumpAndSettle();
    expect(find.text('おつかれさま！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('単語帳の画面：学習・単語・分析のタブが開ける', (tester) async {
    await openScreen(tester, _home());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = await store.createBook('英検2級');
    book.merge(VocabParser.parse(_words));
    store.progress(book.id).record(
          cardId: '1',
          skill: VocabSkill.meaning,
          rating: Rating.again,
          now: DateTime.now(),
          reason: MistakeReason.meaning,
        );
    await store.saveBooks();
    await store.saveProgress(book.id);
    await tester.pumpWidget(Container());
    await openScreen(tester, _home(), keepPrefs: true);
    await tester.tap(find.text('英検2級'));
    await tester.pumpAndSettle();
    expect(find.text('今日の最適学習'), findsOneWidget);
    await tester.tap(find.text('単語'));
    await tester.pumpAndSettle();
    expect(find.text('agree'), findsOneWidget);
    await tester.tap(find.text('分析'));
    await tester.pumpAndSettle();
    expect(find.text('今日のあなた'), findsOneWidget);
    expect(find.text('今週、最も間違えた単語'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
