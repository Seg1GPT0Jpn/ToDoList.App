import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/account/account_screen.dart';
import 'package:rpg_game_app/account/tsuzuri_link_card.dart';
import 'package:rpg_game_app/cloud/tsuzuri_link.dart';
import 'package:rpg_game_app/study/sea_home_screen.dart';
import 'package:rpg_game_app/vocab/vocab_session_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

String _day(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return StudyLog.dayKey(d);
}

Map<String, dynamic> _upcoming() => {
  'items': [
    {
      'date': _day(1),
      'title': 'ECⅠ LEAP単語テスト',
      'kind': '小テスト',
      'isTest': true,
      'subject': 'ECⅠ',
      'detail': '1201〜1300',
    },
    {
      'date': _day(3),
      'title': '化学基礎 小テスト',
      'kind': '小テスト',
      'isTest': true,
      'subject': '化学基礎',
    },
    {'date': _day(2), 'title': '美術 提出物', 'kind': '提出物', 'isTest': false},
  ],
};

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('アカウント画面：つづりのアカウントでつなぐと、テスト予定を受け取り勉強時間を送る', (t) async {
    final backend = MemoryTsuzuriBackend()..upcomingDoc = _upcoming();
    final s = await openScreen(t, const AccountScreen(), tsuzuri: backend);
    await s.studyLog.add(
      'english',
      spent: const Duration(minutes: 25),
      answered: 30,
      correct: 24,
    );
    await s.studyLog.add(
      'math',
      spent: const Duration(minutes: 10),
      answered: 8,
      correct: 4,
    );
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('tsuzuri-connect')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const ValueKey('tsuzuri-connect')));
    await _settle(t);
    expect(find.text('つないでいるアカウント：student@example.com'), findsOneWidget);
    final link = s.tsuzuri!;
    expect(link.upcoming, hasLength(3));
    final today = StudyLog.dayKey(DateTime.now());
    expect(backend.sessions['quest_${today}_英語']!['minutes'], 25);
    expect(backend.sessions['quest_${today}_数学']!['minutes'], 10);
    expect((backend.results!['today'] as Map)['answered'], 38);

    // 変わっていない勉強時間は、もう一度は書かない
    final writes = backend.writes;
    await link.sync();
    expect(backend.writes, writes);
    await s.studyLog.add('english', spent: const Duration(minutes: 5));
    await link.sync();
    expect(backend.sessions['quest_${today}_英語']!['minutes'], 30);
    expect(backend.writes, writes + 1);

    // 連携をやめると、テスト予定も消える
    await t.tap(find.byKey(const ValueKey('tsuzuri-disconnect')));
    await _settle(t);
    expect(link.connected, isFalse);
    expect(link.upcoming, isEmpty);
    expect(find.byKey(const ValueKey('tsuzuri-connect')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('ホーム：つづりのテストだけを近い順に出し、練習で教科の海を開く', (t) async {
    final backend = MemoryTsuzuriBackend()..upcomingDoc = _upcoming();
    final s = await openScreen(
      t,
      const Scaffold(body: SingleChildScrollView(child: TsuzuriUpcomingCard())),
      tsuzuri: backend,
      frames: 2,
    );
    expect(
      find.byKey(const ValueKey('tsuzuri-upcoming')),
      findsNothing,
      reason: 'つないでいない',
    );
    await s.tsuzuri!.connect();
    await _settle(t);
    expect(find.text('テスト予定'), findsOneWidget);
    expect(find.text('明日'), findsOneWidget);
    expect(find.text('1201〜1300'), findsOneWidget);
    expect(find.text('美術 提出物'), findsNothing, reason: 'テストだけ');
    await t.tap(find.byKey(const ValueKey('tsuzuri-practice-化学基礎 小テスト')));
    await _settle(t);
    final sea = t.widget<SeaHomeScreen>(find.byType(SeaHomeScreen));
    expect(sea.initialSubject, 'science');
    expect(t.takeException(), isNull);
  });

  testWidgets('連携できない版では、案内だけ出す', (t) async {
    await openScreen(
      t,
      const Scaffold(body: SingleChildScrollView(child: TsuzuriLinkCard())),
    );
    expect(find.textContaining('この版ではつづりと連携できません'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('つなげなかった理由を、なおし方といっしょに出す', () {
    expect(
      TsuzuriLinkController.connectErrorMessage(
        Exception('[firebase_auth/unauthorized-domain] ...'),
      ),
      contains('承認済みドメイン'),
    );
    expect(
      TsuzuriLinkController.connectErrorMessage(Exception('popup-blocked')),
      contains('ポップアップ'),
    );
    expect(
      TsuzuriLinkController.connectErrorMessage(Exception('x')),
      startsWith('つづりにつなげませんでした'),
    );
  });

  testWidgets('ホームのつづりカード：今日の授業・目標・LEAP の範囲で対策（時間を記録）', (t) async {
    final today = DateTime.now();
    final lessonDay = today.hour >= 17
        ? today.add(const Duration(days: 1))
        : today;
    final backend = MemoryTsuzuriBackend()
      ..upcomingDoc = {
        ..._upcoming(),
        'lessons': {
          StudyLog.dayKey(lessonDay): [
            {'period': 1, 'subject': 'ECⅠ'},
            {'period': 2, 'subject': '数学Ⅰ'},
          ],
        },
      }
      ..goalDocs = [
        {'title': '今月30時間', 'type': 'studyTime', 'current': 12, 'target': 30},
      ];
    final s = await openScreen(
      t,
      const Scaffold(body: SingleChildScrollView(child: TsuzuriUpcomingCard())),
      tsuzuri: backend,
      frames: 2,
    );
    final store = VocabStore.of(s.personalBooks);
    final leap = await store.createBook('LEAP');
    leap.cards = [
      for (var n = 1195; n <= 1305; n++)
        VocabCard(id: '$n', number: n, term: 'word$n', meaning: '意味$n'),
    ];
    await s.tsuzuri!.connect();
    await _settle(t);
    expect(find.text('1限 ECⅠ'), findsOneWidget);
    expect(find.text('目標：今月30時間'), findsOneWidget);
    expect(find.text('12/30時間'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('tsuzuri-practice-ECⅠ LEAP単語テスト')));
    await _settle(t);
    final session = t.widget<VocabSessionScreen>(
      find.byType(VocabSessionScreen),
    );
    expect(session.title, contains('1201〜1300'));
    expect(session.tasks, hasLength(TsuzuriPrep.rangeLimit));
    expect(
      session.tasks.every(
        (x) => int.parse(x.cardId) >= 1201 && int.parse(x.cardId) <= 1300,
      ),
      isTrue,
    );
    expect(t.takeException(), isNull);
  });

  test('対策の時間を記録して、つづりへの成果に入れる', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = MemoryTsuzuriBackend()..upcomingDoc = _upcoming();
    final c = TsuzuriLinkController(
      backend,
      prefs,
      log: () => StudyLog.empty,
      record: () => LearningRecord.empty,
    );
    await c.connect();
    final test = c.upcoming.first;
    await c.addPrep(test, const Duration(minutes: 12));
    expect(c.prepMinutes(test), 12);
    await c.sync();
    expect((backend.results!['tests'] as Map)[TsuzuriLink.testKey(test)], 12);
    c.dispose();
  });
}
