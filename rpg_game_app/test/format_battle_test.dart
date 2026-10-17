import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/battle/battle_screen.dart';

import 'harness.dart';

QuizQuestion parse(Map<String, dynamic> j) => QuizQuestion.fromJson({
  'category': 'thinking',
  'prompt': '問題',
  'explanation': '解説。',
  ...j,
});

Future<void> openBattle(WidgetTester t, List<QuizQuestion> qs) async {
  final world = RpgCatalog.world('math');
  await openScreen(
    t,
    BattleScreen(
      world: world,
      stage: world.stages.first,
      questions: qs,
      progress: RpgProgress.initial,
      trial: true,
    ),
    frames: 30,
  );
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 残っている演出のタイマーを流しきる
Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('正誤：○ を押すと正解になり、正解が表示される', (t) async {
    await openBattle(t, [
      for (var i = 0; i < 3; i++)
        parse({'id': 'tf$i', 'format': 'trueFalse', 'truth': true}),
    ]);
    expect(find.text('考察・正誤'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('tf-true')));
    await settle(t);
    expect(find.textContaining('正しい（○）'), findsWidgets);
    expect(t.takeException(), isNull);
    await drain(t);
  });

  testWidgets('並べ替え：語句をタップして並べ、答える', (t) async {
    await openBattle(t, [
      for (var i = 0; i < 3; i++)
        parse({
          'id': 'or$i',
          'format': 'order',
          'order': {
            'items': ['A', 'B', 'C'],
          },
        }),
    ]);
    for (final i in [0, 1, 2]) {
      await t.tap(find.byKey(ValueKey('order-pool-$i')));
      await t.pump();
    }
    await t.tap(find.byKey(const ValueKey('format-submit')));
    await settle(t);
    expect(find.textContaining('あなたの答え'), findsOneWidget);
    expect(find.textContaining('A B C'), findsWidgets);
    await drain(t);
  });

  testWidgets('数値入力：分数でも正解できる', (t) async {
    await openBattle(t, [
      for (var i = 0; i < 3; i++)
        parse({
          'id': 'nu$i',
          'format': 'numeric',
          'numeric': {'value': 0.75},
        }),
    ]);
    await t.enterText(find.byKey(const ValueKey('numeric-input')), '3/4');
    await t.tap(find.byKey(const ValueKey('format-submit')));
    await settle(t);
    expect(find.textContaining('あなたの答え'), findsOneWidget);
    expect(find.textContaining('3/4'), findsWidgets);
    await drain(t);
  });

  testWidgets('段階問題：小問に順に答える。1つまちがえると部分点', (t) async {
    await openBattle(t, [
      for (var i = 0; i < 3; i++)
        parse({
          'id': 'st$i',
          'format': 'multiStep',
          'subQuestions': [
            {
              'prompt': '(1) 一つ目',
              'choices': ['a', 'b', 'c', 'd'],
              'answerIndex': 0,
            },
            {
              'prompt': '(2) 二つ目',
              'choices': ['e', 'f', 'g', 'h'],
              'answerIndex': 1,
            },
          ],
        }),
    ]);
    expect(find.text('(1) 一つ目'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('step-0-0')));
    await t.pump();
    expect(find.text('(2) 二つ目'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('step-1-0'))); // まちがい
    await settle(t);
    expect(find.textContaining('部分点 50%'), findsWidgets);
    await drain(t);
  });

  testWidgets('記述：模範解答と採点基準を見て自己採点する（見ている間は時間が止まる）', (t) async {
    await openBattle(t, [
      for (var i = 0; i < 3; i++)
        parse({
          'id': 'wr$i',
          'format': 'written',
          'written': {
            'kind': 'proof',
            'modelAnswer': '模範の証明',
            'rubric': [
              {'point': '方針', 'score': 2},
              {'point': '結論', 'score': 1},
            ],
          },
        }),
    ]);
    await t.enterText(find.byKey(const ValueKey('written-input')), 'わたしの証明');
    await t.tap(find.byKey(const ValueKey('written-reveal')));
    await t.pump();
    expect(find.text('模範の証明'), findsOneWidget);
    // 時間が止まっているので、しばらく待っても時間切れにならない
    await t.pump(const Duration(seconds: 200));
    expect(find.textContaining('時間切れ'), findsNothing);
    for (final k in ['rubric-0', 'rubric-1']) {
      await t.ensureVisible(find.byKey(ValueKey(k)));
      await t.pump();
      await t.tap(find.byKey(ValueKey(k)));
      await t.pump();
    }
    await t.ensureVisible(find.byKey(const ValueKey('format-submit')));
    await t.tap(find.byKey(const ValueKey('format-submit')));
    await settle(t);
    expect(find.textContaining('わたしの証明'), findsWidgets);
    expect(find.textContaining('3 / 3 点'), findsWidgets);
    await drain(t);
  });

  testWidgets('複数選択と穴埋め：チェックして答える／空らんに書いて答える', (t) async {
    await openBattle(t, [
      parse({
        'id': 'ms0',
        'format': 'multiSelect',
        'multiSelect': {
          'options': ['X', 'Y', 'Z'],
          'correct': [0, 2],
        },
      }),
      parse({
        'id': 'ms1',
        'format': 'multiSelect',
        'multiSelect': {
          'options': ['X', 'Y', 'Z'],
          'correct': [0, 2],
        },
      }),
    ]);
    await t.tap(find.byKey(const ValueKey('ms-0')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('ms-2')));
    await t.pump();
    await t.ensureVisible(find.byKey(const ValueKey('format-submit')));
    await t.tap(find.byKey(const ValueKey('format-submit')));
    await settle(t);
    expect(find.textContaining('X・Z'), findsWidgets);
    await drain(t);

    await openBattle(t, [
      for (var i = 0; i < 2; i++)
        parse({
          'id': 'cz$i',
          'format': 'cloze',
          'cloze': {
            'text': 'He [1] there [2].',
            'blanks': [
              ['went'],
              ['yesterday'],
            ],
          },
        }),
    ]);
    await t.enterText(find.byKey(const ValueKey('cloze-1')), 'went');
    await t.enterText(find.byKey(const ValueKey('cloze-2')), 'today');
    await t.tap(find.byKey(const ValueKey('format-submit')));
    await settle(t);
    expect(find.textContaining('部分点 50%'), findsWidgets);
    await drain(t);
  });
}
