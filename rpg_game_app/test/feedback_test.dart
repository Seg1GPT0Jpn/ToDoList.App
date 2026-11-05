import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/meta/settings_screen.dart';
import 'package:rpg_game_app/notice/feedback_screen.dart';
import 'package:rpg_game_app/notice/notice_backend.dart';

import 'harness.dart';

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await _settle(t);
}

void main() {
  testWidgets('高校名・クラス・ニックネーム・内容を送れる', (t) async {
    final b = MemoryNoticeBackend();
    await openScreen(
      t,
      const FeedbackScreen(),
      notices: b,
      size: const Size(420, 1400),
    );
    await _settle(t);
    // 内容がないと送れない
    await _tap(t, 'fb-class-1-3');
    await _tap(t, 'fb-send');
    expect(find.text('内容を入れてください'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('fb-nickname')), 'たろう');
    await t.enterText(
      find.byKey(const ValueKey('fb-body')),
      '古文の問題をもっと増やしてほしい',
    );
    await _tap(t, 'fb-send');
    final f = b.sent.single;
    expect(
      [f.school, f.className, f.nickname, f.body],
      ['湘南', '1-3', 'たろう', '古文の問題をもっと増やしてほしい'],
    );
    expect(f.uid, '');
  });

  testWidgets('その他の高校・クラスは自分で入れる', (t) async {
    final b = MemoryNoticeBackend(userId: 'u1');
    await openScreen(
      t,
      const FeedbackScreen(),
      notices: b,
      size: const Size(420, 1600),
    );
    await _settle(t);
    await _tap(t, 'fb-school-その他');
    await _tap(t, 'fb-class-その他');
    await t.enterText(find.byKey(const ValueKey('fb-body')), 'よかったです');
    await _tap(t, 'fb-send');
    expect(find.text('高校名を入れてください'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('fb-school-other')), '鎌倉高校');
    await _tap(t, 'fb-send');
    expect(find.text('クラスを選んでください'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('fb-class-other')), '2-4');
    await _tap(t, 'fb-send');
    final f = b.sent.single;
    expect([f.school, f.className, f.uid], ['鎌倉高校', '2-4', 'u1']);
  });

  testWidgets('設定から開けて、一覧は管理者にだけ出る', (t) async {
    await openScreen(
      t,
      const SettingsScreen(),
      size: const Size(420, 2800),
      notices: MemoryNoticeBackend(email: 'a@gmail.com'),
    );
    expect(find.byKey(const ValueKey('feedback-open')), findsOneWidget);
    expect(find.byKey(const ValueKey('feedback-admin-open')), findsNothing);
    final admin = MemoryNoticeBackend(email: 'kzmsegawa@gmail.com');
    await admin.sendFeedback(
      const AppFeedback(
        school: '湘南',
        className: '1-1',
        nickname: 'a',
        body: '要望です',
      ),
    );
    await openScreen(t, FeedbackListScreen(backend: admin));
    await _settle(t);
    expect(find.text('要望です'), findsOneWidget);
  });

  testWidgets('クラウドがないときは送れないことを出す', (t) async {
    await openScreen(t, const FeedbackScreen());
    expect(find.textContaining('今は送れません'), findsOneWidget);
    await openScreen(t, const SettingsScreen(), size: const Size(420, 2800));
    expect(find.byKey(const ValueKey('feedback-open')), findsNothing);
  });
}
