import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/notice/feedback_screen.dart';
import 'package:rpg_game_app/notice/home_news.dart';
import 'package:rpg_game_app/notice/notice_backend.dart';
import 'package:rpg_game_app/world/world_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('お知らせは3件まで。id は重ならない', () {
    expect(HomeNews.visible(), hasLength(HomeNews.shown));
    expect(
      HomeNewsItem.all.map((i) => i.id).toSet(),
      hasLength(HomeNewsItem.all.length),
    );
    expect(HomeNews.visible().first.title, '【湘南生向け】模試の予想問題が追加されました');
  });

  testWidgets('ホームの上にお知らせが3件。開くと詳しい画面、NEW が消える', (t) async {
    await openScreen(
      t,
      const WorldMapScreen(),
      size: const Size(420, 2400),
      notices: MemoryNoticeBackend(),
    );
    await _frames(t);
    expect(find.byKey(const ValueKey('home-news')), findsOneWidget);
    for (final i in HomeNews.visible()) {
      expect(find.byKey(ValueKey('home-news-${i.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('home-news-new-${i.id}')), findsOneWidget);
    }
    await t.tap(find.byKey(const ValueKey('home-news-feedback-2026-11')));
    await _frames(t);
    expect(find.byType(HomeNewsScreen), findsOneWidget);
    expect(find.textContaining('自分の学校の予想問題がほしい'), findsOneWidget);
    expect(find.textContaining('ご要望・ご意見があれば'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('home-news-feedback')));
    await _frames(t);
    expect(find.byType(FeedbackScreen), findsOneWidget);
    await t.pageBack();
    await _frames(t);
    await t.pageBack();
    await _frames(t);
    expect(
      find.byKey(const ValueKey('home-news-new-feedback-2026-11')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('home-news-new-shinken-2026-11')),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(HomeNews.readKey), ['feedback-2026-11']);
    expect(t.takeException(), isNull);
  });

  testWidgets('ネットにつながっていないときは、フィードバックのボタンを出さない', (t) async {
    await openScreen(t, HomeNewsScreen(item: HomeNewsItem.all[1]));
    expect(find.text('フィードバック機能が使えるようになりました'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-news-feedback')), findsNothing);
  });
}
