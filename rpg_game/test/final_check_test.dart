import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

void main() {
  test('前日・当日だけ。最近間違えた問題を、新しい順に10問まで', () {
    expect(FinalCheck.isEve(1), isTrue);
    expect(FinalCheck.isEve(0), isTrue);
    expect(FinalCheck.isEve(2), isFalse);
    const today = 1000;
    final record = LearningRecord(
      stats: {
        'old': const QuestionStat(
          setId: 's',
          attempts: 2,
          correct: 0,
          missStreak: 2,
          lastDay: today - 40,
        ),
        'good': const QuestionStat(
          setId: 's',
          attempts: 5,
          correct: 5,
          streak: 5,
          lastDay: today - 1,
        ),
        'recent': const QuestionStat(
          setId: 's',
          attempts: 3,
          correct: 2,
          missStreak: 1,
          lastDay: today - 1,
        ),
        'older': const QuestionStat(
          setId: 's',
          attempts: 4,
          correct: 2,
          lastDay: today - 5,
        ),
        for (var i = 0; i < 20; i++)
          'many$i': QuestionStat(
            setId: 's',
            attempts: 1,
            correct: 0,
            missStreak: 1,
            lastDay: today - 10,
          ),
      },
    );
    final picked = FinalCheck.pick(record, today: today);
    expect(picked, hasLength(FinalCheck.limit));
    expect(picked.first.questionId, 'recent');
    expect(picked[1].questionId, 'older');
    expect(picked.map((p) => p.questionId), isNot(contains('good')));
    expect(picked.map((p) => p.questionId), isNot(contains('old')));
  });
}
