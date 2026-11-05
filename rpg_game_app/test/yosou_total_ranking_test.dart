import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/study/yosou_ranking.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

YosouRankEntry _e(String uid, int score, {int spent = 3000}) => YosouRankEntry(
  uid: uid,
  name: uid,
  score: score,
  total: 100,
  spent: spent,
  start: 1,
);

void main() {
  test('総合：合計点の順。同点は解いた教科が多い順、時間の短い順。名前は名簿のもの', () {
    final rows = YosouTotalRow.combine(
      {
        'ja': [_e('a', 80), _e('b', 90), _e('c', 60, spent: 100)],
        'math': [_e('a', 70), _e('c', 100, spent: 100)],
        'en': [_e('b', 60), _e('d', 160)],
      },
      roster: {'a': 'あおい'},
    );
    expect([for (final r in rows) r.uid], ['c', 'd', 'a', 'b']);
    // c と d は 160 点で同点。c は2教科なので上
    expect([for (final r in rows) r.total], [160, 160, 150, 150]);
    expect([for (final r in rows) YosouTotalRow.rankOf(rows, r)], [1, 1, 3, 3]);
    expect(rows[2].name, 'あおい');
    expect(rows[2].scores, {'ja': 80, 'math': 70});
    expect(rows[0].spent, 200);
  });

  testWidgets('進研模試の総合ランキング：3教科の合計と内訳、自分の順位、未回答', (t) async {
    final exams = YosouExams.shinken;
    String board(int i) => YosouRankBackend.boardId(exams[i].id);
    final backend = MemoryYosouRankBackend(
      boards: {
        board(0): {'me': _e('me', 70), 'x': _e('x', 90)},
        board(1): {'me': _e('me', 80)},
        board(2): {'x': _e('x', 50)},
      },
    );
    backend.roster.addAll({'me': 'わたし', 'x': 'ともだち', 'y': 'まだの人'});
    await openScreen(
      t,
      YosouTotalRankingScreen(
        exams: exams,
        title: '予想問題（進研模試・11月）',
        backend: backend,
      ),
    );
    await _frames(t);
    expect(find.text('あなたは 1位 / 2人（合計 150/300 点・2教科）'), findsOneWidget);
    expect(find.text('回答 2人・未回答 1人'), findsOneWidget);
    expect(
      find.textContaining('1位　わたし（あなた）　合計 150/300 点（2/3教科）'),
      findsOneWidget,
    );
    expect(find.text('国語 70・数学 80・英語 −'), findsOneWidget);
    expect(find.textContaining('2位　ともだち　合計 140/300 点'), findsOneWidget);
    expect(find.textContaining('まだの人'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('ログインしていないときは、その説明を出す', (t) async {
    await openScreen(
      t,
      YosouTotalRankingScreen(
        exams: YosouExams.all,
        title: '予想問題',
        backend: MemoryYosouRankBackend(userId: null),
      ),
    );
    expect(find.text(YosouRankText.needLogin), findsOneWidget);
  });
}
