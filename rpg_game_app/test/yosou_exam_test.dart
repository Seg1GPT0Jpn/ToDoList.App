import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:rpg_game_app/study/school_material_screen.dart';
import 'package:rpg_game_app/study/yosou_exam_screens.dart';
import 'package:rpg_game_app/study/yosou_exam_store.dart';
import 'package:rpg_game_app/vocab/speech.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

const _exam = YosouExam(
  id: 'joho',
  title: 'テスト用の予想問題',
  subjectId: 'information1',
  questionPages: 1,
  answerPages: 1,
);

final _sheetJson = jsonEncode({
  'note': '',
  'sections': [
    {
      'title': '大問1',
      'items': [
        {
          'id': 'a',
          'l': '[01]',
          't': 'text',
          'p': 2,
          'a': ['レジスタ'],
        },
        {
          'id': 'b',
          'l': '[02]',
          't': 'choice',
          'p': 3,
          'o': ['1', '2', '3'],
          'a': ['2'],
        },
        {
          'id': 'c',
          'l': '[03]',
          't': 'self',
          'p': 5,
          'a': ['模範解答'],
        },
      ],
    },
    {
      'title': 'リスニング',
      'speech': ['Hello there.'],
      'plays': 1,
      'items': [
        {
          'id': 'd',
          'l': '1)',
          't': 'choice',
          'p': 2,
          'o': ['1', '2'],
          'a': ['1'],
        },
      ],
    },
  ],
});

void main() {
  late List<int> key;
  late List<int> sealedSheet;
  late List<int> sealedPage;
  final oldLoader = YosouExamFiles.loader;

  setUpAll(() {
    key = SchoolMaterials.keyFor('test-pw');
    sealedSheet = SchoolMaterials.seal(
      utf8.encode(_sheetJson),
      List.filled(16, 1),
      key: key,
    );
  });

  setUp(() => speaker = SilentSpeaker());
  tearDown(() => YosouExamFiles.loader = oldLoader);

  Future<void> useFiles(WidgetTester t) async {
    final real = SchoolMaterials.all.firstWhere((m) => !m.locked);
    final raw = await t.runAsync(
      () => SchoolMaterialScreen.loader(real.asset(1)),
    );
    sealedPage = SchoolMaterials.seal(
      SchoolMaterials.open(raw!)!,
      List.filled(16, 2),
      key: key,
    );
    YosouExamFiles.loader = (asset) async =>
        asset.endsWith('sheet.bin') ? sealedSheet : sealedPage;
  }

  testWidgets('60分で解く：答えて見直しの印、提出して採点、自分で点をつける', (t) async {
    await useFiles(t);
    var now = DateTime(2026, 10, 28, 9);
    final s = await openScreen(
      t,
      YosouExamScreen(exam: _exam, keyBytes: key, now: () => now),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 3,
    );
    await _frames(t);
    expect(find.byKey(const ValueKey('yosou-start')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-start')));
    await _frames(t);
    expect(find.text('のこり 60:00'), findsOneWidget);
    // 問題冊子のページが出る
    expect(find.byKey(const ValueKey('yosou-q-1')), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('yosou-tab-sheet')));
    await _frames(t);
    await t.enterText(find.byKey(const ValueKey('yosou-input-a')), 'れじすた');
    await t.tap(find.byKey(const ValueKey('yosou-b-2')));
    await t.tap(find.byKey(const ValueKey('yosou-flag-b')));
    await t.enterText(find.byKey(const ValueKey('yosou-input-c')), 'メモ');
    await t.pump();
    // リスニングは決まった回数だけ流せる
    await t.ensureVisible(find.byKey(const ValueKey('yosou-play-1')));
    await t.tap(find.byKey(const ValueKey('yosou-play-1')));
    await t.pump();
    expect((speaker as SilentSpeaker).spoken, ['Hello there.']);
    expect(find.byKey(const ValueKey('yosou-play-1')), findsNothing);

    // 閉じても答えと残り時間が残る
    now = now.add(const Duration(minutes: 12, seconds: 30));
    await _frames(t, 12);
    expect(find.text('のこり 47:30'), findsOneWidget);
    final saved = YosouExamStore.of(s.personalBooks).attempt('joho')!;
    expect(saved.answers['b'], '2');
    expect(saved.flags, {'b'});

    await t.tap(find.byKey(const ValueKey('yosou-submit')));
    await _frames(t);
    expect(find.textContaining('未記入が 1 欄'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('yosou-submit-ok')));
    await _frames(t);
    // ひらがなの「れじすた」は×、選択は○。記述は自分で採点
    expect(find.text('3 / 12 点'), findsOneWidget);
    expect(find.text('×'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('yosou-override-a')));
    await _frames(t);
    expect(find.text('5 / 12 点'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('yosou-self-c-4')));
    await t.tap(find.byKey(const ValueKey('yosou-self-c-4')));
    await _frames(t);
    await t.drag(
      find.byKey(const ValueKey('yosou-result')),
      const Offset(0, 3000),
    );
    await _frames(t);
    expect(find.text('9 / 12 点'), findsOneWidget);
    final h = YosouExamStore.of(s.personalBooks).history('joho');
    expect(h.single.score, 9);
    expect(h.single.unscored, 0);
    expect(h.single.spent.inSeconds, 12 * 60 + 30);
    expect(t.takeException(), isNull);
  });

  testWidgets('時間になると自動で提出する。一時停止中は時間が進まない', (t) async {
    await useFiles(t);
    var now = DateTime(2026, 10, 28, 9);
    final s = await openScreen(
      t,
      YosouExamScreen(exam: _exam, keyBytes: key, now: () => now),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 3,
    );
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-start')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('yosou-pause')));
    await _frames(t);
    expect(find.text('一時停止中'), findsOneWidget);
    now = now.add(const Duration(minutes: 30));
    await _frames(t, 12);
    await t.tap(find.byKey(const ValueKey('yosou-pause')));
    await _frames(t, 12);
    expect(find.text('のこり 60:00'), findsOneWidget);
    now = now.add(const Duration(minutes: 61));
    await _frames(t, 12);
    expect(find.byKey(const ValueKey('yosou-score')), findsOneWidget);
    final a = YosouExamStore.of(s.personalBooks).attempt('joho')!;
    expect(a.submitted, isTrue);
    expect(a.spent(now).inMinutes, 60);
    expect(t.takeException(), isNull);
  });

  testWidgets('一覧：学校のパスワードで開くと、予想問題が並ぶ', (t) async {
    await useFiles(t);
    await openScreen(
      t,
      const YosouExamListScreen(),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 3,
    );
    await t.enterText(find.byKey(const ValueKey('yosou-password')), 'nope');
    await t.tap(find.byKey(const ValueKey('yosou-unlock')));
    await _frames(t, 10);
    expect(find.text('パスワードがちがいます'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('yosou-password')), 'TEST-PW');
    await t.tap(find.byKey(const ValueKey('yosou-unlock')));
    await _frames(t, 10);
    for (final e in YosouExams.all) {
      expect(find.byKey(ValueKey('yosou-exam-${e.id}')), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });
}
