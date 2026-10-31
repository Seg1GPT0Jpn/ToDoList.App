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

/// 英字だけの単語（例文の中から見つけられるように）
String _w(int i) =>
    'z${String.fromCharCode(97 + i ~/ 26 % 26)}${String.fromCharCode(97 + i % 26)}q';

/// 名前とパスワードで開いた EEVI のかわり（番号 1〜500・例文つき）
Future<void> _addEevi(RpgServices s) async {
  final store = VocabStore.of(s.personalBooks);
  store.books.add(
    VocabBook(
      id: 'eevi',
      title: 'EEVI',
      kind: VocabBookKind.protectedImport,
      cards: [
        for (var i = 1; i <= 500; i++)
          VocabCard(
            id: 'e$i',
            number: i,
            term: _w(i),
            meaning: '意味$i',
            example: 'I like ${_w(i)} very much.',
            exampleJa: '例$i',
          ),
      ],
    ),
  );
  await store.saveBooks();
  await s.personalBooks.prefs.setStringList('vocab_unlocked_books', ['eevi']);
}

/// テストでは1種類5問にする
ContestConfig _small() => ContestConfig({
  for (final e in ContestConfig.initial.plans.entries)
    e.key: e.value.copyWith(count: 5),
});

final _number = {for (var i = 1; i <= 500; i++) _w(i): i};

String _text(WidgetTester t, String key) =>
    t.widget<Text>(find.byKey(ValueKey(key))).data!;

/// いま出ている問題の正しい選択肢
String _right(WidgetTester t) {
  final prompt = _text(t, 'contest-prompt');
  final choices = [
    for (var i = 0; i < 4; i++)
      if (find.byKey(ValueKey('contest-choice-$i')).evaluate().isNotEmpty) i,
  ];
  if (choices.length == 2) {
    final sub = _text(t, 'contest-sub');
    return sub == '意味${_number[prompt]}' ? '〇 合っている' : '× ちがう';
  }
  if (prompt.startsWith('意味')) return _w(int.parse(prompt.substring(2)));
  if (_number.containsKey(prompt)) return '意味${_number[prompt]}';
  // 例文：訳（例123）から答えの単語を決める
  return _w(int.parse(_text(t, 'contest-sub').substring(1)));
}

/// 1種類を、全問正しく解く
Future<void> _solvePart(WidgetTester t, int count) async {
  await t.tap(find.byKey(const ValueKey('contest-part-start')));
  for (var q = 0; q < count; q++) {
    await _frames(t, 2);
    await t.tap(find.widgetWithText(OutlinedButton, _right(t)));
    await _frames(t, 6);
  }
  await _frames(t, 5);
}

/// 日本時間 10/30（金）の朝8時（EEVI の第1回の受付中）
DateTime _eeviDay() => DateTime.utc(2026, 10, 29, 23);

Future<RpgServices> _open(
  WidgetTester t,
  MemoryContestBackend backend, {
  DateTime Function() now = _eeviDay,
}) async {
  final s = await openScreen(t, const SizedBox(), frames: 2);
  await _addEevi(s);
  backend.now = now;
  await openScreen(
    t,
    ContestScreen(backend: backend, now: now),
    frames: 5,
    keepPrefs: true,
    size: const Size(420, 1400),
  );
  return s;
}

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
    expect(find.textContaining('受付中　EEVI 301〜350・4種類×50問'), findsOneWidget);
    expect(find.textContaining('10/30（金）19:15まで'), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-no-book-eevi')), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-all-eevi')), findsNothing);
    expect(
      find.textContaining(
        '次回　LEAP 1801〜1900・4種類×100問\n10/31（土）18:00〜11/2（月）8:00',
      ),
      findsOneWidget,
    );
    // 管理者でなければ、日程を変えるボタンは出ない
    expect(find.byKey(const ValueKey('contest-admin')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('4種類を順に解き、総合と分野ごとの順位が出る', (t) async {
    final shared = <String, Map<String, ContestEntry>>{
      'eevi-2026-10-30': {
        'rival': const ContestEntry(
          uid: 'rival',
          name: 'らいばる',
          correct: 20,
          score: 10000,
          scores: {0: 10000, 1: 10000, 2: 10000, 3: 10000},
        ),
      },
    };
    final me = MemoryContestBackend(
      userId: 'alice',
      entries: shared,
      config: _small(),
    );
    final s = await _open(t, me);
    await t.enterText(find.byKey(const ValueKey('contest-name')), 'あり');
    expect(find.textContaining('一気に挑戦（4種類×5問）'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('contest-all-eevi')));
    await _frames(t, 3);
    expect(find.textContaining('一気に挑戦・20問'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('contest-confirm')));
    await _frames(t, 3);
    for (final part in ContestPart.values) {
      expect(_text(t, 'contest-part-title'), contains(part.label));
      await _solvePart(t, 5);
      final e = shared['eevi-2026-10-30']!['alice']!;
      expect(e.section, part.index + 1);
      expect(e.correct, 5 * (part.index + 1));
    }
    final mine = shared['eevi-2026-10-30']!['alice']!;
    expect(mine.done, isTrue);
    expect(mine.name, 'あり');
    expect(mine.scores, hasLength(4));
    // 速く正解したので、ほぼ満点（100% には少し届かない）
    expect(mine.score, inInclusiveRange(9000, 9999));
    // 総合の順位表
    expect(find.byKey(const ValueKey('contest-interim')), findsOneWidget);
    expect(find.textContaining('総合であなたは 2位 / 2人'), findsOneWidget);
    expect(find.textContaining('あり（あなた）'), findsOneWidget);
    // 分野ごとの順位表
    await t.tap(find.byKey(const ValueKey('contest-tab-cloze')));
    await _frames(t, 5);
    expect(find.textContaining('例文であなたは 2位 / 2人'), findsOneWidget);
    expect(find.textContaining('1位　らいばる　100.00%'), findsOneWidget);
    // もどると、もう挑戦できない
    await t.pageBack();
    await _frames(t, 5);
    expect(find.byKey(const ValueKey('contest-all-eevi')), findsNothing);
    expect(find.byKey(const ValueKey('contest-part-eevi-flash')), findsNothing);
    expect(
      find.byKey(const ValueKey('contest-part-done-eevi-cloze')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('contest-mine-eevi')), findsOneWidget);
    expect(VocabStore.of(s.personalBooks).progress('eevi').cards, isNotEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('分野ごとに好きな順で1回ずつ。途中でやめた分野は記録なし', (t) async {
    final shared = <String, Map<String, ContestEntry>>{};
    final me = MemoryContestBackend(
      userId: 'bob',
      entries: shared,
      config: _small(),
    );
    var clock = _eeviDay();
    await _open(t, me, now: () => clock);
    // 英→日だけ挑戦する
    await t.tap(find.byKey(const ValueKey('contest-part-eevi-enJa')));
    await _frames(t, 3);
    expect(find.textContaining('英→日・5問'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('contest-confirm')));
    await _frames(t, 3);
    expect(_text(t, 'contest-part-title'), '英→日');
    await _solvePart(t, 5);
    final e = shared['eevi-2026-10-30']!['bob']!;
    expect(e.section, 1);
    expect(e.partScore(ContestPart.enJa.index), isNotNull);
    expect(e.partScore(ContestPart.flash.index), isNull);
    // 1種類だけでも順位表に出る
    expect(find.byKey(const ValueKey('contest-my-rank')), findsOneWidget);
    await t.pageBack();
    await _frames(t, 12);
    expect(
      find.byKey(const ValueKey('contest-part-done-eevi-enJa')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('contest-part-eevi-enJa')), findsNothing);
    expect(find.textContaining('一気に挑戦（のこり3種類）'), findsOneWidget);
    // フラッシュカードを始めて、途中でやめる
    await t.tap(find.byKey(const ValueKey('contest-part-eevi-flash')));
    await _frames(t, 3);
    await t.tap(find.byKey(const ValueKey('contest-confirm')));
    await _frames(t, 3);
    await t.tap(find.byKey(const ValueKey('contest-part-start')));
    await _frames(t, 3);
    await t.pageBack();
    await _frames(t, 12);
    expect(find.byKey(const ValueKey('contest-part-eevi-flash')), findsNothing);
    expect(find.textContaining('フラッシュカード　挑戦中'), findsOneWidget);
    // 30分たつと記録なし。のこりの2種類には、まだ挑戦できる
    clock = clock.add(const Duration(minutes: 31));
    await t.pumpWidget(const SizedBox());
    await openScreen(
      t,
      ContestScreen(backend: me, now: () => clock),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 1400),
    );
    expect(find.textContaining('フラッシュカード　途中でやめたため記録なし'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('contest-part-eevi-jaEn')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('contest-part-eevi-cloze')),
      findsOneWidget,
    );
    expect(find.textContaining('一気に挑戦（のこり2種類）'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('受付が終わると挑戦できなくなり、最終ランキングが出る', (t) async {
    final shared = <String, Map<String, ContestEntry>>{
      'eevi-2026-10-30': {
        'a': const ContestEntry(
          uid: 'a',
          name: 'えー',
          correct: 380,
          score: 9123,
          scores: {0: 9000, 1: 9100, 2: 9200, 3: 9192},
        ),
      },
    };
    // 日本時間 10/30（金）19:15（EEVI の受付が終わったところ）
    DateTime after() => DateTime.utc(2026, 10, 30, 10, 15);
    await _open(
      t,
      MemoryContestBackend(userId: 'z', entries: shared),
      now: after,
    );
    expect(find.byKey(const ValueKey('contest-all-eevi')), findsNothing);
    expect(find.textContaining('最終ランキング発表！（301〜350）'), findsOneWidget);
    expect(
      find.textContaining('次回　EEVI 351〜400・4種類×50問\n11/5（木）18:00〜11/6（金）19:15'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const ValueKey('contest-last-eevi')));
    await _frames(t, 5);
    expect(find.byKey(const ValueKey('contest-final')), findsOneWidget);
    expect(find.textContaining('1位　えー　91.23%（正解 380問）'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('contest-tab-jaEn')));
    await _frames(t, 5);
    expect(find.textContaining('1位　えー　91.00%'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('最終ランキングで入賞すると、報酬を1回だけ受け取れる', (t) async {
    ContestEntry e(String uid, int score) => ContestEntry(
      uid: uid,
      name: uid,
      correct: 300,
      score: score,
      scores: {
        for (final (i, x) in [score, score, score, score].indexed) i: x,
      },
    );
    // 5人なので上位2人が入賞。自分（me）は2位
    final shared = {
      'eevi-2026-10-30': {
        for (final x in [
          e('a', 9500),
          e('me', 9000),
          e('c', 8000),
          e('d', 7000),
          e('f', 6000),
        ])
          x.uid: x,
      },
    };
    DateTime after() => DateTime.utc(2026, 10, 30, 11);
    final s = await _open(
      t,
      MemoryContestBackend(userId: 'me', entries: shared),
      now: after,
    );
    expect(find.textContaining('2位の報酬を受け取る（+1200EXP・称号）'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('contest-prize-eevi')));
    await _frames(t, 8);
    final p = await s.repository.load();
    expect(ContestPrizes.claimed(p, 'eevi-2026-10-30'), 2);
    expect(p.totalExp, greaterThanOrEqualTo(1200));
    // 入賞の実績が解除され、称号として選べる
    expect(find.textContaining('「表彰台の学徒」'), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-prize-eevi')), findsNothing);
    expect(find.textContaining('🥈 EEVI 2位に入賞！（報酬は受け取りずみ）'), findsOneWidget);
    // 最終ランキングでは、入賞した2人にメダル
    await t.tap(find.byKey(const ValueKey('contest-last-eevi')));
    await _frames(t, 5);
    expect(find.textContaining('🥇 1位　a'), findsOneWidget);
    expect(find.textContaining('🥈 2位　me（あなた）'), findsOneWidget);
    expect(find.textContaining('🥉'), findsNothing);
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
    // EEVI の範囲の広さを 30 にして、11/6 もお休みにする。受付は当日 20:00 まで
    await t.enterText(
      find.byKey(const ValueKey('contest-admin-eevi-範囲の広さ')),
      '30',
    );
    await t.enterText(
      find.byKey(const ValueKey('contest-admin-eevi-お休みの日（1行に1日）')),
      '2026-11-13\n2026-11-06',
    );
    await t.enterText(
      find.byKey(const ValueKey('contest-admin-eevi-受付の終わり')),
      '当日 20:00',
    );
    await _frames(t, 2);
    expect(
      find.byKey(const ValueKey('contest-preview-eevi-2026-11-06')),
      findsNothing,
    );
    expect(
      find.textContaining(
        'EEVI 331〜360（4種類×50問）\n　11/19（木）18:00〜11/20（金）20:00',
      ),
      findsOneWidget,
    );
    await t.tap(find.byKey(const ValueKey('contest-admin-save')));
    await _frames(t, 5);
    final eevi = admin.config.plans['eevi']!;
    expect(eevi.width, 30);
    expect(eevi.skips, {'2026-11-13', '2026-11-06'});
    expect(eevi.closeMin, 20 * 60);
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

  testWidgets('受付中は、単語帳練習の入口が目立つ', (t) async {
    // 受付中かどうかは端末の今で決まるので、いつも受付中の設定にする
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
