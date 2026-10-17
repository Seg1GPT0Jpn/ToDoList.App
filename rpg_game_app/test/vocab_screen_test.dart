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
  builder: (c) =>
      Scaffold(body: VocabHome(books: RpgServices.of(c).personalBooks)),
);

void main() {
  setUp(() => speaker = SilentSpeaker());

  testWidgets('名前とパスワードを入れると、取り込まずに単語帳が使える', (tester) async {
    final sealed = VocabVault.seal('TEST', VocabParser.parse(_words), 'pw-123');
    VocabStore.assetLoader = (file) async =>
        file == VocabVault.fileName('TEST') ? sealed : null;
    addTearDown(() => VocabStore.assetLoader = (_) async => null);
    await openScreen(tester, _home());
    expect(find.text('TEST'), findsNothing);

    Future<void> tryOpen(String name, String pw) async {
      await tester.enterText(
        find.byKey(const ValueKey('vocab-book-name')),
        name,
      );
      await tester.enterText(find.byKey(const ValueKey('vocab-password')), pw);
      await tester.tap(find.text('追加する'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
    }

    await tryOpen('TEST', 'wrong');
    expect(find.text('名前かパスワードがちがいます'), findsOneWidget);
    await tryOpen('NOPE', 'pw-123');
    expect(find.text('名前かパスワードがちがいます'), findsOneWidget);

    await tryOpen('test', 'pw-123');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TEST'), findsOneWidget);
    expect(find.textContaining('5語　'), findsOneWidget);
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    expect(store.book('test')!.cards.first.term, 'agree');

    // 隠しても、もう一度開けば学習記録は残る
    await store.lock();
    expect(store.visibleBooks.any((b) => b.id == 'test'), isFalse);
  });

  testWidgets('練習：新しい単語をめくって評価、4択、スペル（間違えた理由を記録）', (tester) async {
    await openScreen(tester, const SizedBox());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = await store.createBook('自作');
    book.merge(VocabParser.parse(_words));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
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
      ),
    );
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

  testWidgets('音が出せないときは、リスニングを記録せずにとばせる', (tester) async {
    await openScreen(tester, const SizedBox());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = await store.createBook('自作');
    book.merge(VocabParser.parse(_words));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => VocabSessionScreen(
          store: store,
          book: book,
          title: '練習',
          random: Random(1),
          tasks: const [
            VocabTask('1', VocabMode.listening),
            VocabTask('2', VocabMode.listening),
            VocabTask('3', VocabMode.listening),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('vocab-skip-listening')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('vocab-skip-all-listening')));
    await tester.pumpAndSettle();
    expect(find.text('おつかれさま！'), findsOneWidget);
    expect(find.textContaining('リスニング 3 問をとばしました'), findsOneWidget);
    // とばした問題は記録しない
    expect(store.progress(book.id).cards, isEmpty);
  });

  testWidgets('単語帳の画面：学習・単語・分析のタブが開ける', (tester) async {
    await openScreen(tester, _home());
    final store = VocabStore.of(RpgServicesHolder.last!.personalBooks);
    final book = await store.createBook('英検2級');
    book.merge(VocabParser.parse(_words));
    store
        .progress(book.id)
        .record(
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
    // 問題数「全部」で、単語帳の全部を一気に
    await tester.tap(find.byKey(const ValueKey('drill-count-all')));
    await tester.pump();
    await tester.tap(find.text('番号順'));
    await tester.pump();
    await tester.tap(find.text('スペル入力').first);
    await tester.pumpAndSettle();
    expect(find.text('全体 スペル入力（5問）'), findsOneWidget);
    expect(find.textContaining('1 / 5'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
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
