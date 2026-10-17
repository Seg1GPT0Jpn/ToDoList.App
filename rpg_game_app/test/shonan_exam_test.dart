import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/study/ec_text.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:rpg_game_app/study/sea_home_screen.dart';
import 'package:rpg_game_app/study/shonan_exam_screens.dart';
import 'package:rpg_game_app/study/shonan_question_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 問題データの読み込み（本物の非同期）を待つ
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await _frames(t, 2);
  }
}

void main() {
  testWidgets('定期テストの海から湘南104の画面に入れる（既存の試験対策ボタンも残る）', (t) async {
    await openScreen(
      t,
      Builder(
        builder: (c) =>
            SeaHomeScreen(personalBooks: RpgServices.of(c).personalBooks),
      ),
      frames: 20,
      size: const Size(900, 900),
    );
    expect(find.text('試験対策'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sea-shonan')));
    await _frames(t);
    expect(find.byType(ShonanExamListScreen), findsOneWidget);
    expect(find.text(ShonanText.localOnly), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('範囲表から後期中間を作ると、11科目の範囲と教材が見える', (t) async {
    await openScreen(t, const ShonanExamListScreen(), frames: 10);
    await t.tap(find.byKey(const ValueKey('shonan-from-table')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('shonan-sheet-後期中間試験')));
    await _frames(t);
    expect(find.byType(ShonanExamDetailScreen), findsOneWidget);
    expect(find.text('1年後期中間試験'), findsOneWidget);
    // 公共（下のほう）までスクロールして、範囲表の内容を確かめる
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('shonan-subject-public_economy')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('冊子No.3すべて'), findsOneWidget);
    // 公共は委員会の新作セットが登録済みなので演習できる
    final pub = t.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('shonan-practice-public_economy')),
    );
    expect(pub.onPressed, isNotNull);
    expect(find.textContaining('委員会の新作問題セット：8'), findsOneWidget);
    // 生物基礎は範囲も問題セットもないので押せない
    final bio = t.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('shonan-practice-biology_basic')),
    );
    expect(bio.onPressed, isNull);
    expect(t.takeException(), isNull);
  });

  testWidgets('テストを作る：名前が空だと保存できず、入れると一覧に出る。削除は確認してから', (t) async {
    final s = await openScreen(t, const ShonanExamListScreen(), frames: 10);
    await t.tap(find.byKey(const ValueKey('shonan-new')));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('shonan-save')));
    await _frames(t, 3);
    expect(find.text(ShonanText.titleRequired), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('shonan-title')), '1年後期中間試験');
    // 公共を開いて範囲を書く
    await t.scrollUntilVisible(
      find.text('社会｜公共（政治経済の経済分野）'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('社会｜公共（政治経済の経済分野）'));
    await _frames(t, 5);
    await t.enterText(
      find.byKey(const ValueKey('shonan-range-public_economy')),
      '第4章・第6章',
    );
    await t.tap(find.byKey(const ValueKey('shonan-save')));
    await _frames(t);
    final store = SchoolExamStore.of(s.personalBooks);
    final plan = store.load().single;
    expect(plan.title, '1年後期中間試験');
    expect(plan.subject('public_economy').rangeText, '第4章・第6章');
    expect(plan.subject('public_economy').status, RangeStatus.entered);
    expect(find.textContaining('1 / 11'), findsOneWidget);

    await t.tap(find.byKey(ValueKey('shonan-menu-${plan.id}')));
    await _frames(t, 3);
    await t.tap(find.text('削除'));
    await _frames(t, 3);
    await t.tap(find.byKey(const ValueKey('shonan-delete-ok')));
    await _frames(t, 3);
    expect(store.load(), isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets('既存＋未収録のセット：理由を見せてから、読めたセットで演習できる', (t) async {
    final s = await openScreen(t, const SizedBox(), frames: 2);
    final store = SchoolExamStore.of(s.personalBooks);
    await store.add(
      SchoolExamPlan(
        id: 'p1',
        title: 'テスト',
        createdAt: DateTime(2026, 10, 13),
      ).withSubject(
        const SubjectExamPlan(
          subjectId: 'public_economy',
          existingSetIds: ['social_chirisogo_01'],
          committeeSetIds: ['social_shonan_104_nothing_01'],
        ),
      ),
    );
    await openScreen(
      t,
      const ShonanExamDetailScreen(planId: 'p1'),
      frames: 5,
      keepPrefs: true,
      size: const Size(420, 3000),
    );
    await t.ensureVisible(
      find.byKey(const ValueKey('shonan-practice-public_economy')),
    );
    await _frames(t, 2);
    await t.tap(find.byKey(const ValueKey('shonan-practice-public_economy')));
    await _settle(t);
    expect(
      find.textContaining('social_shonan_104_nothing_01：アプリに収録されていない'),
      findsOneWidget,
    );
    await t.tap(find.byKey(const ValueKey('shonan-practice-anyway')));
    await _settle(t);
    await _frames(t, 10);
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('既存の試験対策ワールドのデータとは別のキーに保存し、壊さない', (t) async {
    SharedPreferences.setMockInitialValues({
      'exam_worlds_v1': '[]',
      SchoolExamStore.key: '{"こわれた": true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = SchoolExamStore(prefs);
    expect(store.load(), isEmpty);
    await store.add(
      SchoolExamPlan(id: 'a', title: 'A', createdAt: DateTime(2026)),
    );
    expect(prefs.getString('exam_worlds_v1'), '[]');
    expect(
      (jsonDecode(prefs.getString(SchoolExamStore.key)!) as List).single['id'],
      'a',
    );
  });

  testWidgets('問題一覧：委員会セットの問題が答え・解説つきで見られ、答えをかくせる', (t) async {
    await openScreen(
      t,
      ShonanQuestionListScreen(
        subject: ShonanSubjects.byId('math_a')!,
        plan: const SubjectExamPlan(
          subjectId: 'math_a',
          committeeSetIds: ['math_shonan_104_ma_integer_01'],
        ),
      ),
      frames: 2,
      size: const Size(500, 1400),
    );
    await _settle(t);
    expect(
      find.textContaining('math_shonan_104_ma_integer_01（'),
      findsOneWidget,
    );
    await t.tap(find.textContaining('Q1. '));
    await _frames(t, 5);
    expect(find.textContaining('解説：'), findsOneWidget);
    expect(find.textContaining('✓ '), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('shonan-list-hide')));
    await _frames(t, 3);
    expect(find.textContaining('解説：'), findsNothing);
    expect(find.textContaining('✓ '), findsNothing);
    expect(t.takeException(), isNull);
  });

  group('EC の本文', () {
    // テストでは本物のパスワードを使わず、テスト用に暗号化した本文を使う
    const pw = 'test-password';
    final sealed = VocabVault.seal('t', const [
      VocabCard(
        id: 'ec1_l5_s1',
        term: 'Lesson 5 Roots & Shoots — Section 1',
        meaning: 'Ken: Hello.\nJane: Hi.',
      ),
    ], pw);
    setUp(() => EcText.assetLoader = (_) async => sealed);

    testWidgets('パスワードがちがうと開かず、正しいと Lesson ごとに読める', (t) async {
      final s = await openScreen(t, const EcTextScreen(), frames: 5);
      await _settle(t);
      await t.enterText(find.byKey(const ValueKey('ec-text-password')), 'x');
      await t.tap(find.byKey(const ValueKey('ec-text-open')));
      await _settle(t);
      expect(find.text('パスワードがちがいます'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('ec-text-password')), pw);
      await t.tap(find.byKey(const ValueKey('ec-text-open')));
      await _settle(t);
      await t.tap(find.text('Lesson 5 Roots & Shoots'));
      await _frames(t, 5);
      await t.tap(find.text('Section 1'));
      await _frames(t, 5);
      expect(find.text('Jane: Hi.'), findsOneWidget);
      expect(s.personalBooks.prefs.getString(EcText.key), pw);
      await EcText.forget(s.personalBooks.prefs);
      expect(t.takeException(), isNull);
    });

    test('問題のタグ（lesson・section）から本文をつける', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final ps = (await EcText.unlock(prefs, pw))!;
      final q = QuizQuestion(
        id: 'q',
        category: QuestionCategory.values.first,
        prompt: 'p',
        choices: const ['a', 'b', 'c', 'd'],
        tags: const ['ec1', 'lesson5', 'section1'],
      );
      final other = QuizQuestion(
        id: 'o',
        category: QuestionCategory.values.first,
        prompt: 'p',
        choices: const ['a', 'b', 'c', 'd'],
        tags: const ['ec1', 'lesson6', 'section1'],
      );
      final out = EcText.attach([q, other], ps);
      expect(out[0].passage?.id, 'ec1_l5_s1');
      expect(out[0].prompt, 'p');
      expect(out[1].passage, isNull);
      await EcText.forget(prefs);
    });
  });
}
