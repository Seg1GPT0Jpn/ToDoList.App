import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/meta/settings_screen.dart';
import 'package:rpg_game_app/notice/notice_admin_screen.dart';
import 'package:rpg_game_app/notice/notice_backend.dart';
import 'package:rpg_game_app/notice/notice_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

const _admin = 'kzmsegawa@gmail.com';

Widget _home() =>
    const Scaffold(body: SingleChildScrollView(child: NoticeCard()));

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('お知らせがなければ何も出さない', (t) async {
    await openScreen(t, _home(), notices: MemoryNoticeBackend(userId: 'u1'));
    await _settle(t);
    expect(find.byKey(const ValueKey('notice-card')), findsNothing);
  });

  testWidgets('お知らせを出し、とじると同じお知らせは出さない', (t) async {
    final b = MemoryNoticeBackend(
      userId: 'u1',
      notice: AppNotice.testerTemplate.copyWith(id: '1'),
    );
    await openScreen(t, _home(), notices: b);
    await _settle(t);
    expect(find.text(AppNotice.testerTemplate.title), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('notice-dismiss')));
    await _settle(t);
    expect(find.byKey(const ValueKey('notice-card')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(NoticeCard.dismissedKey), '1');
  });

  testWidgets('止めたお知らせは出さない', (t) async {
    final b = MemoryNoticeBackend(
      notice: AppNotice.testerTemplate.copyWith(id: '1', enabled: false),
    );
    await openScreen(t, _home(), notices: b);
    await _settle(t);
    expect(find.byKey(const ValueKey('notice-card')), findsNothing);
  });

  testWidgets('テスターに申しこむと、Gmail が管理者の一覧に入る', (t) async {
    final b = MemoryNoticeBackend(
      userId: 'u1',
      email: '0095000@gl.pen-kanagawa.ed.jp',
      notice: AppNotice.testerTemplate.copyWith(id: '1'),
    );
    await openScreen(t, _home(), notices: b);
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('notice-signup')));
    await _settle(t);
    await t.enterText(find.byKey(const ValueKey('tester-email')), 'not mail');
    await t.tap(find.byKey(const ValueKey('tester-send')));
    await _settle(t);
    expect(find.text('メールアドレスの形になっていません'), findsOneWidget);
    await t.enterText(
      find.byKey(const ValueKey('tester-email')),
      'taro@gmail.com',
    );
    await t.tap(find.byKey(const ValueKey('tester-send')));
    await _settle(t);
    expect(b.entries['u1']!.email, 'taro@gmail.com');
    expect(find.text('申しこみずみ（変える）'), findsOneWidget);
    // 一覧は管理者だけ
    expect(b.signups, throwsStateError);
    b.email = _admin;
    expect((await b.signups()).single.email, 'taro@gmail.com');
  });

  testWidgets('ログインしていなければ申しこめない', (t) async {
    final b = MemoryNoticeBackend(
      notice: AppNotice.testerTemplate.copyWith(id: '1'),
    );
    await openScreen(t, _home(), notices: b);
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('notice-signup')));
    await _settle(t);
    expect(find.byKey(const ValueKey('tester-email')), findsNothing);
    expect(find.textContaining('Google ログイン'), findsOneWidget);
  });

  testWidgets('設定の管理者の項目は管理者にだけ出る', (t) async {
    await openScreen(
      t,
      const SettingsScreen(),
      size: const Size(420, 2600),
      notices: MemoryNoticeBackend(userId: 'u1', email: 'a@gmail.com'),
    );
    expect(find.byKey(const ValueKey('notice-admin-open')), findsNothing);
    await openScreen(
      t,
      const SettingsScreen(),
      size: const Size(420, 2600),
      notices: MemoryNoticeBackend(userId: 'u1', email: _admin),
    );
    expect(find.byKey(const ValueKey('notice-admin-open')), findsOneWidget);
  });

  testWidgets('管理者がひな形から保存すると、ホームに出る', (t) async {
    final b = MemoryNoticeBackend(userId: 'u1', email: _admin);
    await openScreen(
      t,
      NoticeAdminScreen(backend: b),
      size: const Size(420, 2000),
    );
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('notice-template')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('notice-save-again')));
    await _settle(t);
    expect(b.notice!.title, AppNotice.testerTemplate.title);
    expect(b.notice!.testerSignup, isTrue);
    expect(b.notice!.id, isNotEmpty);
  });
}
