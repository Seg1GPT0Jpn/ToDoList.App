import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/term_cards.dart';

import 'harness.dart';

void main() {
  const deck = TermDeck(
    id: 'physics',
    worldId: 'science',
    title: '物理',
    cards: [
      TermCard(
        term: '速さ',
        meaning: '単位時間あたりの移動距離',
        related: ['速度'],
        trivia: '10m/s＝36km/h',
        section: '運動',
      ),
      TermCard(
        term: '速度',
        meaning: '速さと向きをあわせた量',
        related: ['速さ'],
        trivia: 'ベクトル量',
        section: '運動',
      ),
      TermCard(
        term: '仕事',
        meaning: '力×移動距離',
        related: ['仕事率'],
        trivia: '単位はJ',
        section: 'エネルギー',
      ),
    ],
  );

  testWidgets('暗記カードを見る：意味・関連語・豆知識・検索・かくす', (t) async {
    await openScreen(t, const TermCardBrowserScreen(deck: deck));
    expect(find.text('単位時間あたりの移動距離'), findsOneWidget);
    expect(find.text('豆知識：10m/s＝36km/h'), findsOneWidget);
    expect(find.text('3枚'), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('cards-search')), '仕事');
    await t.pump();
    expect(find.text('1枚'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('cards-search')), '');
    await t.pump();

    // 意味をかくして、タップでめくる
    await t.tap(find.byKey(const ValueKey('cards-hide')));
    await t.pump();
    expect(find.text('単位時間あたりの移動距離'), findsNothing);
    await t.tap(find.byKey(const ValueKey('card-速さ')));
    await t.pump();
    expect(find.text('単位時間あたりの移動距離'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cards-hide')));
    await t.pump();

    // 関連語をタップすると、そのカードが出る
    await t.tap(find.widgetWithText(ActionChip, '速度').first);
    await t.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('暗記カードのタブ：理科を解放するまではロック', (t) async {
    final science = RpgCatalog.world('science');
    await openScreen(
      t,
      Scaffold(
        body: TermCardsTab(world: science, progress: RpgProgress.initial),
      ),
      frames: 20,
    );
    expect(find.textContaining('解放すると、暗記カード'), findsOneWidget);
    await openScreen(
      t,
      Scaffold(
        body: TermCardsTab(
          world: science,
          progress: RpgProgress.initial.copyWith(purchasedWorldIds: {'science'}),
        ),
      ),
      frames: 20,
    );
    expect(find.textContaining('解放すると'), findsNothing);
    expect(find.byKey(const ValueKey('deck-physics')), findsOneWidget);
  });
}
