import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/field/field_screen.dart';
import 'package:rpg_game_app/vocab/vocab_book_screen.dart';
import 'package:rpg_game_app/world/eiken_door_screen.dart';
import 'package:rpg_game_app/world/gate_screen.dart';
import 'package:rpg_game_app/world/kokka_door_screen.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('資格の塔は地図のワールドに入らず、追加コンテンツとして ID で探せる', () {
    expect(RpgCatalog.worlds.map((w) => w.id), isNot(contains('shikaku')));
    expect(RpgCatalog.extraWorlds.map((w) => w.id), contains('shikaku'));
    expect(RpgCatalog.extraWorlds.map((w) => w.id), contains('eiken'));
    expect(RpgCatalog.extraWorlds.map((w) => w.id), contains('kokka'));
    expect(RpgCatalog.worlds.map((w) => w.id), isNot(contains('kokka')));
    expect(RpgCatalog.world('shikaku').name, '資格の塔');
    expect(RpgCatalog.stage('shikaku_takken_01').worldId, 'shikaku');
    expect(RpgCatalog.isExtra('shikaku'), isTrue);
    expect(RpgCatalog.isExtra('english'), isFalse);
  });

  testWidgets('ホームの「異世界の門」から入り、宅建の扉でフィールドへ', (t) async {
    await openScreen(t, const WorldMapScreen(), size: const Size(420, 2600));
    await _frames(t);
    final banner = find.byKey(const ValueKey('gate-banner'));
    await t.ensureVisible(banner);
    await t.tap(banner);
    await _frames(t);
    expect(find.byType(GateScreen), findsOneWidget);
    expect(find.text('クリア 0 / 16'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('gate-door-takken')));
    await _frames(t, 12);
    final field = t.widget<FieldScreen>(find.byType(FieldScreen));
    expect(field.world.id, 'shikaku');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('英検の扉：級ごとの単語帳が並び、開くと単語帳の画面になる', (t) async {
    await openScreen(t, const GateScreen(), size: const Size(420, 1600));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('gate-door-eiken')));
    await _frames(t);
    expect(find.byType(EikenDoorScreen), findsOneWidget);
    final first = Eiken.ofLevel('p2').first;
    expect(find.byKey(ValueKey('eiken-book-${first.id}')), findsOneWidget);
    await t.runAsync(() => eikenBook(first));
    await t.tap(find.byKey(ValueKey('eiken-book-${first.id}')));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.byType(VocabBookScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('三大国家試験の扉：3つの道とバトル、用語帳のタブ', (t) async {
    await openScreen(t, const GateScreen(), size: const Size(420, 1600));
    await _frames(t);
    expect(find.text('クリア 0 / 24'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('gate-door-national')));
    await _frames(t);
    expect(find.byType(KokkaDoorScreen), findsOneWidget);
    for (final id in ['shiho', 'ishi', 'kaikei']) {
      expect(find.byKey(ValueKey('kokka-route-$id')), findsOneWidget);
    }
    expect(find.text('クリア 0 / 8'), findsNWidgets(3));
    await t.tap(find.text('用語帳'));
    await _frames(t);
    expect(t.takeException(), isNull);
    await t.tap(find.text('バトル'));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('kokka-battle')));
    await _frames(t, 12);
    expect(t.widget<FieldScreen>(find.byType(FieldScreen)).world.id, 'kokka');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  test('三大国家試験の世界：3つの道に8エリアずつ、問題はすべて4択', () {
    final w = RpgCatalog.world('kokka');
    expect(w.routes.map((r) => r.id), ['shiho', 'ishi', 'kaikei']);
    expect(w.stages, hasLength(24));
    expect(w.stages.where((s) => s.isBoss), hasLength(6));
    expect(TermDecks.of('kokka').map((d) => d.id), [
      'kokka_shiho',
      'kokka_ishi',
      'kokka_kaikei',
    ]);
  });

  test('英検の単語帳：4つの級、級の中で同じ単語がなく、意味と例文がある', () async {
    expect(Eiken.levels.keys, ['p2', 'g2', 'p1', 'g1']);
    expect(Eiken.wordCount('p2'), greaterThanOrEqualTo(1400));
    expect(Eiken.wordCount('g2'), greaterThanOrEqualTo(1900));
    expect(Eiken.wordCount('p1'), greaterThanOrEqualTo(2300));
    expect(Eiken.wordCount('g1'), greaterThanOrEqualTo(2800));
    final seen = <String>{};
    for (final l in Eiken.lists) {
      final list = await eikenBook(l);
      expect(list.cards, hasLength(l.count), reason: l.id);
      for (final c in list.cards) {
        expect(seen.add(c.term), isTrue, reason: '${l.id} ${c.term}');
        expect(c.meaning, isNotEmpty, reason: c.term);
        expect(c.example, isNotEmpty, reason: c.term);
      }
    }
  });
}
