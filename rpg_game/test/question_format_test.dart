import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

QuizQuestion parse(Map<String, dynamic> j) => QuizQuestion.fromJson(
    {'id': 'f', 'category': 'thinking', 'prompt': 'p', ...j});

void main() {
  group('出題形式：読み書きと正解の表示', () {
    test('正誤', () {
      final q = parse({
        'format': 'trueFalse',
        'sentence': '水は100℃で沸騰する（1気圧）',
        'truth': true
      });
      expect(q.format, QuestionFormat.trueFalse);
      expect(q.isChoice, isFalse);
      expect(q.answer, '正しい（○）');
      expect(Grader.trueFalse(q, true).correct, isTrue);
      expect(Grader.trueFalse(q, false).correct, isFalse);
      expect(parse(q.toJson()).toJson(), q.toJson());
    });

    test('複数選択：部分点は（正しい選択−余分な選択）÷正解の数', () {
      final q = parse({
        'format': 'multiSelect',
        'multiSelect': {
          'options': ['A', 'B', 'C', 'D', 'E'],
          'correct': [0, 2, 3],
        },
      });
      expect(q.answer, 'A・C・D');
      expect(Grader.multiSelect(q, {0, 2, 3}).correct, isTrue);
      final partial = Grader.multiSelect(q, {0, 2});
      expect(partial.correct, isFalse);
      expect(partial.credit, closeTo(2 / 3, 1e-9));
      expect(Grader.multiSelect(q, {0, 1}).credit, 0);
      expect(parse(q.toJson()).toJson(), q.toJson());
    });

    test('並べ替え：となり合う順が合っている割合が部分点', () {
      final q = parse({
        'format': 'order',
        'order': {
          'items': ['I', 'have', 'never', 'seen', 'it'],
        },
      });
      expect(q.answer, 'I have never seen it');
      expect(Grader.order(q, [0, 1, 2, 3, 4]).correct, isTrue);
      final g = Grader.order(q, [0, 1, 3, 2, 4]);
      expect(g.correct, isFalse);
      expect(g.credit, closeTo(1 / 4, 1e-9));
      expect(Grader.order(q, [0, 1, 2]).credit, 0);
    });

    test('数値入力：分数・小数・指数・全角・単位・許容誤差', () {
      final q = parse({
        'format': 'numeric',
        'numeric': {'value': 0.75, 'tolerance': 0.01, 'unit': 'm/s'},
      });
      expect(q.answer, '0.75 m/s');
      for (final ok in [
        '0.75',
        '3/4',
        '０．７５',
        '0.75m/s',
        '7.5×10^-1',
        '0.755'
      ]) {
        expect(Grader.numeric(q, ok).correct, isTrue, reason: ok);
      }
      for (final ng in ['0.8', 'abc', '', '3/0']) {
        expect(Grader.numeric(q, ng).correct, isFalse, reason: ng);
      }
      final big = parse({
        'format': 'numeric',
        'numeric': {'value': 1200},
      });
      expect(Grader.numeric(big, '1,200').correct, isTrue);
      expect(Grader.numeric(big, '1.2e3').correct, isTrue);
    });

    test('穴埋め：空らんごとに採点', () {
      final q = parse({
        'format': 'cloze',
        'cloze': {
          'text': 'He [1] been to Kyoto [2].',
          'blanks': [
            ['has'],
            ['twice', 'two times'],
          ],
        },
      });
      expect(q.cloze!.parts, ['He ', 1, ' been to Kyoto ', 2, '.']);
      expect(Grader.cloze(q, ['has', 'two times']).correct, isTrue);
      final g = Grader.cloze(q, ['Has', 'once']);
      expect(g.credit, 0.5);
      expect(g.correct, isFalse);
      expect(
          () => parse({
                'format': 'cloze',
                'cloze': {
                  'text': 'no blank',
                  'blanks': [
                    ['x'],
                  ],
                },
              }),
          throwsArgumentError);
    });

    test('段階問題：小問は4択。正解した段階の割合が部分点', () {
      final q = parse({
        'format': 'multiStep',
        'subQuestions': [
          {
            'prompt': '(1) 平方完成すると？',
            'choices': ['a', 'b', 'c', 'd'],
            'answerIndex': 1,
          },
          {
            'prompt': '(2) 最小値は？',
            'choices': ['1', '2', '3', '4'],
            'answerIndex': 0,
          },
        ],
      });
      expect(q.subQuestions.map((s) => s.id), ['f_s1', 'f_s2']);
      expect(q.answer, 'b → 1');
      expect(Grader.steps(q, [true, true]).correct, isTrue);
      expect(Grader.steps(q, [true, false]).credit, 0.5);
      expect(parse(q.toJson()).toJson(), q.toJson());
    });

    test('記述：採点基準の点の合計（合格点は省略すると6割）', () {
      final q = parse({
        'format': 'written',
        'written': {
          'kind': 'proof',
          'modelAnswer': '…',
          'rubric': [
            {'point': '場合分けをしている', 'score': 2},
            {'point': '各場合で結論を示している', 'score': 2},
            {'point': '等号の条件を書いている', 'score': 1},
          ],
        },
      });
      expect(q.written!.passScore, 3);
      expect(q.written!.kindLabel, '証明');
      expect(Grader.written(q, {0, 1}).correct, isTrue);
      final g = Grader.written(q, {0});
      expect(g.correct, isFalse);
      expect(g.credit, closeTo(0.4, 1e-9));
      expect(parse(q.toJson()).toJson(), q.toJson());
    });

    test('中身のない形式はエラー', () {
      expect(() => parse({'format': 'trueFalse'}), throwsArgumentError);
      expect(() => parse({'format': 'nope'}), throwsFormatException);
    });
  });

  group('戦闘：採点した結果で答える', () {
    BattleEngine battle(List<QuizQuestion> qs) => BattleEngine(
          player: PlayerStats.forLevel(10),
          enemy: const EnemyDef(id: 'e', name: 'e', maxHp: 500, attack: 10),
          questions: qs,
          timeLimit: const Duration(seconds: 60),
          random: Random(2),
          damage: fixedDamage(),
        );
    final tf = [
      for (var i = 0; i < 4; i++)
        parse({'id': 't$i', 'format': 'trueFalse', 'truth': i.isEven}),
    ];

    test('正解ならふつうにダメージ、まちがいなら反撃', () {
      final b = battle(tf);
      final r = b.answerGraded(Grade.right, elapsed: slow);
      expect(r.correct, isTrue);
      expect(r.timedOut, isFalse);
      expect(r.damageToEnemy, greaterThan(0));
      final w = b.answerGraded(Grade.wrong, elapsed: slow);
      expect(w.correct, isFalse);
      expect(w.timedOut, isFalse);
      expect(w.damageToEnemy, 0);
      expect(w.damageToPlayer, greaterThan(0));
    });

    test('部分点：小さなダメージを与え、受けるダメージは半分', () {
      final b1 = battle(tf);
      final full = b1.answerGraded(Grade.wrong, elapsed: slow).damageToPlayer;
      final b2 = battle(tf);
      final r = b2.answerGraded(
        const Grade(credit: 0.6, correct: false),
        elapsed: slow,
      );
      expect(r.partial, isTrue);
      expect(r.credit, 0.6);
      expect(r.damageToEnemy, greaterThan(0));
      expect(r.damageToPlayer, lessThan(full));
      expect(b2.combo, 0);
    });
  });
}
