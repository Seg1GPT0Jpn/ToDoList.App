import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';
import 'package:rpg_game_app/study/ec_text.dart';
import 'package:rpg_game_app/study/school_drive_folder_screen.dart';
import 'package:rpg_game_app/study/school_drive_screen.dart';
import 'package:rpg_game_app/study/school_exam_store.dart';
import 'package:rpg_game_app/study/school_material_screen.dart';
import 'package:rpg_game_app/study/sea_home_screen.dart';
import 'package:rpg_game_app/study/shonan_exam_screens.dart';
import 'package:rpg_game_app/study/shonan_question_list.dart';
import 'package:rpg_game_app/vocab/vocab_book_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
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
  testWidgets('学校専用の対策は、定期テストの海の上には出ず、試験対策で学校名とパスワードを入れて開く', (t) async {
    await openScreen(
      t,
      Builder(
        builder: (c) =>
            SeaHomeScreen(personalBooks: RpgServices.of(c).personalBooks),
      ),
      frames: 20,
      size: const Size(900, 900),
    );
    expect(find.byIcon(Icons.school), findsNothing);
    await t.tap(find.text('試験対策'));
    await _frames(t);
    expect(find.byKey(const ValueKey('school-exam-open')), findsNothing);
    await t.enterText(find.byKey(const ValueKey('school-name')), 'どこか高校');
    await t.enterText(find.byKey(const ValueKey('school-password')), 'abc');
    await t.tap(find.byKey(const ValueKey('school-unlock')));
    await _frames(t, 3);
    expect(find.text('学校名かパスワードがちがいます'), findsOneWidget);
    expect(find.byKey(const ValueKey('school-exam-open')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('開いた端末では、試験対策から学校の定期テスト対策に入れる', (t) async {
    await openScreen(
      t,
      Builder(
        builder: (c) =>
            SeaHomeScreen(personalBooks: RpgServices.of(c).personalBooks),
      ),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 20,
      size: const Size(900, 900),
    );
    await t.tap(find.text('試験対策'));
    await _frames(t);
    await t.tap(find.byKey(const ValueKey('school-exam-open')));
    await _frames(t);
    expect(find.byType(ShonanExamListScreen), findsOneWidget);
    expect(find.text(ShonanText.localOnly), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('この更新より前から使っていた端末は、合言葉なしで開いたまま。新しい端末は閉じている', () async {
    SharedPreferences.setMockInitialValues({'rpg_progress_v1': '{}'});
    final old = await SharedPreferences.getInstance();
    await SchoolExamStore.migrate(old);
    expect(SchoolExamStore(old).unlocked, isTrue);

    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    await SchoolExamStore.migrate(fresh);
    expect(SchoolExamStore(fresh).unlocked, isFalse);
    // 2回目の起動では、保存があっても開かない（最初の1回だけ確かめる）
    await fresh.setString('something', 'x');
    await SchoolExamStore.migrate(fresh);
    expect(SchoolExamStore(fresh).unlocked, isFalse);
    expect(await SchoolExamStore(fresh).unlock('どこか高校', 'abc'), isFalse);
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
    expect(find.textContaining('委員会の新作問題セット：14'), findsOneWidget);
    // 生物基礎も、授業プリントの新作セットが登録済みなので演習できる
    final bio = t.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('shonan-practice-biology_basic')),
    );
    expect(bio.onPressed, isNotNull);
    // 地理総合は範囲も問題セットもないので押せない
    final geo = t.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('shonan-practice-geography_general')),
    );
    expect(geo.onPressed, isNull);
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
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('shonan-practice-public_economy')),
      400,
      scrollable: find.byType(Scrollable).first,
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

  testWidgets('前に範囲表から作ったテストに、範囲表に合う問題セットをボタンで足せる', (t) async {
    final old = SchoolExamPlan(
      id: 'old',
      title: '1年後期中間試験',
      createdAt: DateTime(2026, 10, 1),
    );
    await openScreen(
      t,
      const ShonanExamDetailScreen(planId: 'old'),
      prefs: {
        SchoolExamStore.key: jsonEncode([old.toMap()]),
      },
      frames: 10,
    );
    final add = find.byKey(const ValueKey('shonan-add-table-sets'));
    expect(add, findsOneWidget);
    await t.tap(add);
    await _frames(t);
    expect(add, findsNothing);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('shonan-subject-public_economy')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('既存の問題セット：6'), findsOneWidget);
    expect(t.takeException(), isNull);
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

  testWidgets('配布資料（PDF）をページごとにめくって見られる', (t) async {
    await openScreen(
      t,
      const ShonanExamListScreen(),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 10,
    );
    final m = SchoolMaterials.all.first;
    // 同梱の画像は暗号化してあり、開くと WebP の画像になる
    final raw = await t.runAsync(() => SchoolMaterialScreen.loader(m.asset(1)));
    final page = SchoolMaterials.open(raw!)!;
    expect(String.fromCharCodes(page.sublist(8, 12)), 'WEBP');

    await t.tap(find.byKey(const ValueKey('shonan-materials')));
    await _frames(t, 5);
    await t.ensureVisible(find.byKey(ValueKey('shonan-materials-${m.id}')));
    await _frames(t, 2);
    await t.tap(find.byKey(ValueKey('shonan-materials-${m.id}')));
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.byType(SchoolMaterialScreen), findsOneWidget);
    expect(find.text('1 / ${m.pages}'), findsOneWidget);
    expect(find.byKey(const ValueKey('material-image-1')), findsOneWidget);
    await t.drag(find.byType(PageView), const Offset(-500, 0));
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.text('2 / ${m.pages}'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('鍵のかかった国語の資料は、パスワードを入れると開け、次からは入れなくてよい', (t) async {
    final m = SchoolMaterials.all.firstWhere((m) => m.locked);
    // 本物の画像（公共の資料の1ページ目）を、テスト用のパスワードで暗号化して出す
    final real = SchoolMaterials.all.firstWhere((m) => !m.locked);
    final raw = await t.runAsync(
      () => SchoolMaterialScreen.loader(real.asset(1)),
    );
    final image = SchoolMaterials.open(raw!)!;
    final sealed = SchoolMaterials.seal(
      image,
      List.filled(16, 3),
      key: SchoolMaterials.keyFor('test-pw'),
    );
    final old = SchoolMaterialScreen.loader;
    SchoolMaterialScreen.loader = (_) async => sealed;
    addTearDown(() => SchoolMaterialScreen.loader = old);

    final s = await openScreen(
      t,
      SchoolMaterialScreen(material: m),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 5,
    );
    expect(find.byKey(const ValueKey('material-password')), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('material-password')), 'abc');
    await t.tap(find.byKey(const ValueKey('material-unlock')));
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.text('パスワードがちがいます'), findsOneWidget);

    await t.enterText(
      find.byKey(const ValueKey('material-password')),
      'TEST-PW',
    );
    await t.tap(find.byKey(const ValueKey('material-unlock')));
    for (var i = 0; i < 8; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.byKey(const ValueKey('material-image-1')), findsOneWidget);
    expect(SchoolExamStore.of(s.personalBooks).secret, 'test-pw');
    expect(t.takeException(), isNull);
  });

  testWidgets('ドライブの資料：パスワードで教科ごとのフォルダが出て、タップで開く', (t) async {
    final oldData = SchoolDriveScreen.data,
        oldOpener = SchoolDriveScreen.opener;
    SchoolDriveScreen.data = SchoolDrive.seal(
      const [
        SchoolDriveLink(
          title: 'フォルダ全体',
          url: 'https://drive.google.com/drive/folders/all',
        ),
        SchoolDriveLink(
          title: '情報Ⅰ',
          url: 'https://drive.google.com/drive/folders/info',
          group: '情報',
        ),
      ],
      List.filled(16, 5),
      SchoolMaterials.keyFor('test-pw'),
    );
    final opened = <Uri>[];
    SchoolDriveScreen.opener = (u) async {
      opened.add(u);
      return true;
    };
    final oldFetcher = SchoolDriveFolderScreen.fetcher;
    final oldEmbed = SchoolDriveFolderScreen.embed;
    String entry(String id, String href, String title) =>
        '<div class="flip-entry" id="entry-$id"><div class="flip-entry-info">'
        '<a href="$href" target="_blank"><div class="flip-entry-title">$title</div></a></div>'
        '<div class="flip-entry-last-modified"><div>Oct 27</div></div></div>';
    final fetched = <String>[];
    SchoolDriveFolderScreen.embed = (_) => null;
    SchoolDriveFolderScreen.fetcher = (u) async {
      final id = u.queryParameters['id']!;
      fetched.add(id);
      return id == 'info'
          ? entry('sub', 'https://drive.google.com/drive/folders/sub', '過去問') +
                entry(
                  'f1',
                  'https://drive.google.com/file/d/f1/view',
                  '予想問題.pdf',
                )
          : entry('f2', 'https://drive.google.com/file/d/f2/view', '解答.pdf');
    };
    addTearDown(() {
      SchoolDriveScreen.data = oldData;
      SchoolDriveScreen.opener = oldOpener;
      SchoolDriveFolderScreen.fetcher = oldFetcher;
      SchoolDriveFolderScreen.embed = oldEmbed;
    });

    final s = await openScreen(
      t,
      const ShonanExamListScreen(),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 5,
    );
    await t.tap(find.byKey(const ValueKey('shonan-drive')));
    await _frames(t, 5);
    await t.enterText(find.byKey(const ValueKey('drive-password')), 'abc');
    await t.tap(find.byKey(const ValueKey('drive-unlock')));
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.text('パスワードがちがいます'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('drive-password')), 'TEST-PW');
    await t.tap(find.byKey(const ValueKey('drive-unlock')));
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _frames(t, 2);
    }
    expect(find.text('情報'), findsOneWidget);
    // フォルダの中のファイルが、アプリの中で一覧になる
    await t.tap(find.byKey(const ValueKey('drive-link-情報Ⅰ')));
    await _frames(t, 5);
    expect(find.text('予想問題.pdf'), findsOneWidget);
    expect(find.text('更新 Oct 27'), findsNWidgets(2));
    // 中のフォルダもアプリの中で開ける
    await t.tap(find.byKey(const ValueKey('drive-entry-sub')));
    await _frames(t, 5);
    expect(fetched, ['info', 'sub']);
    expect(find.text('解答.pdf'), findsOneWidget);
    // ファイルはドライブで開く
    await t.tap(find.byKey(const ValueKey('drive-entry-f2')));
    await _frames(t, 2);
    expect(opened.single.toString(), 'https://drive.google.com/file/d/f2/view');
    expect(SchoolExamStore.of(s.personalBooks).secret, 'test-pw');
    expect(t.takeException(), isNull);
  });

  testWidgets('単元ごとに練習：単元と小単元に分かれ、押すとその問題だけで練習する', (t) async {
    QuizQuestion q(String id, String unit) => QuizQuestion(
      id: id,
      category: QuestionCategory.meaning,
      prompt: id,
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      unit: unit,
    );
    final groups = SchoolUnitGroup.of([
      q('q1', 'science.chemistry.change.acid.define'),
      q('q2', 'science.chemistry.change.acid.ph'),
      q('q3', 'science.chemistry.change.acid.ph'),
      q('q4', 'science.chemistry.change.equation.write'),
    ]);
    SchoolUnitGroup? picked;
    await openScreen(
      t,
      SchoolUnitScreen(
        title: '化学基礎',
        groups: groups,
        onPractice: (c, g) async => picked = g,
      ),
    );
    expect(
      find.byKey(const ValueKey('unit-science.chemistry.change.acid')),
      findsOneWidget,
    );
    await t.tap(
      find.byKey(const ValueKey('unit-science.chemistry.change.acid')),
    );
    await _frames(t, 5);
    await t.tap(
      find.byKey(const ValueKey('unit-play-science.chemistry.change.acid-all')),
    );
    await _frames(t, 2);
    expect(picked?.questions.length, 3);
    expect(t.takeException(), isNull);
  });

  testWidgets('テスト範囲の単語帳：学校のパスワードで開き、ふつうの単語帳と同じ画面で練習できる', (t) async {
    // 学校のパスワードはテストに書かないので、テスト用のパスワードで暗号化した単語帳を出す
    final sealed = {
      for (final w in SchoolWordBooks.all)
        w.file: VocabVault.seal(
          w.id == 'leap' ? 'LEAP' : '漢字・語彙',
          [
            const VocabCard(id: '1', number: 1, term: '輪郭', meaning: '物の外形'),
            const VocabCard(id: '2', number: 2, term: '襲う', meaning: '急に攻める'),
          ],
          'test-pw',
          worldId: w.id == 'leap' ? 'english' : 'japanese',
        ),
    };
    final old = VocabStore.assetLoader;
    VocabStore.assetLoader = (file) async => sealed[file];
    addTearDown(() => VocabStore.assetLoader = old);
    final s = await openScreen(
      t,
      const ShonanExamListScreen(),
      prefs: {SchoolExamStore.gateKey: true},
      frames: 10,
    );
    final tile = find.byKey(const ValueKey('shonan-wordbook-kanji'));
    await t.ensureVisible(tile);
    await _frames(t, 3);
    await t.tap(tile);
    await _settle(t);
    // 前の版から開いていた端末なので、パスワードを一度だけたずねる
    await t.enterText(
      find.byKey(const ValueKey('school-words-password')),
      'abc',
    );
    await t.tap(find.byKey(const ValueKey('school-words-open')));
    await _frames(t, 3);
    expect(find.text('パスワードがちがいます'), findsOneWidget);
    await t.enterText(
      find.byKey(const ValueKey('school-words-password')),
      'TEST-PW',
    );
    await t.tap(find.byKey(const ValueKey('school-words-open')));
    await _settle(t);
    expect(find.byType(VocabBookScreen), findsOneWidget);
    expect(find.textContaining('漢字・語彙'), findsWidgets);
    expect(SchoolExamStore.of(s.personalBooks).secret, 'test-pw');
    // ふつうの単語帳の一覧には出ない
    expect(VocabStore.of(s.personalBooks).visibleBooks, isEmpty);

    // 次からはパスワードなしで開く（英語の LEAP も同じ）
    await t.pageBack();
    await _frames(t, 5);
    final leap = find.byKey(const ValueKey('shonan-wordbook-leap'));
    await t.ensureVisible(leap);
    await _frames(t, 3);
    await t.tap(leap);
    await _settle(t);
    expect(find.byKey(const ValueKey('school-words-password')), findsNothing);
    expect(find.byType(VocabBookScreen), findsOneWidget);
    expect(find.textContaining('LEAP'), findsWidgets);
    await t.pumpWidget(const SizedBox());
    await _frames(t, 3);
    expect(t.takeException(), isNull);
  });
}
