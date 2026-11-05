import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 19);
  final leap = VocabBook(
    id: 'leap',
    title: 'LEAP',
    kind: VocabBookKind.custom,
    cards: [
      for (var n = 1195; n <= 1310; n++)
        VocabCard(id: '$n', number: n, term: 'w$n', meaning: '意味$n'),
    ],
  );

  test('範囲の単語帳：テスト名に入っている単語帳を先に、番号が範囲に入る単語だけ', () {
    final other = VocabBook(
      id: 'my0',
      title: '自作',
      kind: VocabBookKind.custom,
      cards: [VocabCard(id: '1', number: 1250, term: 'x', meaning: 'y')],
    );
    expect(TsuzuriPrep.bookFor([other, leap], (1201, 1300), 'ECⅠ LEAP単語テスト'),
        same(leap));
    expect(
        TsuzuriPrep.bookFor([other, leap], (1201, 1300), '単語テスト'), same(other));
    expect(TsuzuriPrep.bookFor([leap], (5000, 5100), 'LEAP'), isNull);
    expect(TsuzuriPrep.cardsIn(leap, (1201, 1300)), hasLength(100));
  });

  test('範囲の練習：苦手な単語から、まだ見ていない単語はめくって覚える', () {
    final p = BookProgress();
    // 1210 は苦手（最近まちがえた）、1220 は一度正解
    p.record(
        cardId: '1210',
        skill: VocabSkill.meaning,
        rating: Rating.again,
        now: now);
    p.record(
        cardId: '1220',
        skill: VocabSkill.meaning,
        rating: Rating.good,
        now: now);
    final tasks = TsuzuriPrep.rangeTasks(leap, p, (1201, 1300), now: now);
    expect(tasks, hasLength(TsuzuriPrep.rangeLimit));
    expect(tasks.first.cardId, '1210');
    expect(tasks[0].mode, VocabMode.choiceMeaning);
    expect(tasks[1].mode, VocabMode.choiceTerm, reason: '苦手な単語は日→英も');
    expect(tasks[2].isNew, isTrue);
    expect(
        tasks.every(
            (t) => int.parse(t.cardId) >= 1201 && int.parse(t.cardId) <= 1300),
        isTrue);
  });

  test('教科の対策：その教科で最近まちがえた問題だけ', () {
    const today = 500;
    final record = LearningRecord(stats: {
      'm1': const QuestionStat(
          setId: 'math_1',
          attempts: 2,
          correct: 0,
          missStreak: 2,
          lastDay: today - 1),
      'm2': const QuestionStat(
          setId: 'math_1', attempts: 3, correct: 3, lastDay: today),
      'm3': const QuestionStat(
          setId: 'math_2', attempts: 4, correct: 2, lastDay: today),
      'm4': const QuestionStat(
          setId: 'math_2',
          attempts: 1,
          correct: 0,
          missStreak: 1,
          lastDay: today - 90),
      'e1': const QuestionStat(
          setId: 'english_1',
          attempts: 1,
          correct: 0,
          missStreak: 1,
          lastDay: today),
      's1': const QuestionStat(
          setId: 'sea_1',
          attempts: 1,
          correct: 0,
          missStreak: 1,
          lastDay: today),
    });
    expect(
        TsuzuriPrep.weakItems(record, 'math', today: today)
            .map((i) => i.questionId),
        ['m3', 'm1']);
    expect(
        TsuzuriPrep.weakItems(record, 'english', today: today)
            .map((i) => i.questionId)
            .toSet(),
        {'e1', 's1'});
  });
}
