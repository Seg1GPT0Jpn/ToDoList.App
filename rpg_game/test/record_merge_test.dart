import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

LearningRecord _rec(Map<String, List<bool>> answers, int day) {
  var r = LearningRecord.empty;
  for (final e in answers.entries) {
    for (final ok in e.value) {
      r = r.recordAll(
        [
          AnswerEvent(
              questionId: e.key,
              setId: 'math_x',
              isCorrect: ok,
              elapsedMs: 1000)
        ],
        day: day,
      );
    }
  }
  return r;
}

void main() {
  test('学習記録：どちらで答えた問題も残り、多く答えた方を使う。何度まとめても同じ', () {
    final main = _rec({
      'q1': [true],
      'q2': [false, true]
    }, 10);
    final light = _rec({
      'q1': [true, true, false],
      'q3': [true]
    }, 11);
    final m = RecordMerge.learning(main, light);
    expect(m.stats.keys, containsAll(['q1', 'q2', 'q3']));
    expect(m.stats['q1']!.attempts, 3);
    expect(m.stats['q2']!.attempts, 2);
    expect(m.studyDays, {10, 11});
    expect(RecordMerge.learning(m, light).toMap(), m.toMap());
    expect(RecordMerge.learning(light, main).toMap(), m.toMap());
  });

  test('冒険の記録と進行状況：回数は多い方、クリアは両方', () {
    const a = PlayerJournal(wins: 5, seen: {'e1': 2}, achievements: {'x': 9});
    const b = PlayerJournal(
        wins: 3, seen: {'e1': 4, 'e2': 1}, achievements: {'x': 7, 'y': 8});
    final j = RecordMerge.journal(a, b);
    expect(j.wins, 5);
    expect(j.seen, {'e1': 4, 'e2': 1});
    expect(j.achievements, {'x': 7, 'y': 8});

    final p1 = RpgProgress.initial.copyWith(
      totalExp: 100,
      exp: 10,
      level: 3,
      clearedStageIds: {'s1'},
      seaBest: {'u': 3},
      lostStages: {'s2'},
    );
    final p2 = RpgProgress.initial.copyWith(
      totalExp: 50,
      clearedStageIds: {'s2'},
      seaBest: {'u': 5, 'v': 1},
    );
    final p = RecordMerge.progress(p2, p1);
    expect(p.level, 3);
    expect(p.totalExp, 100);
    expect(p.clearedStageIds, {'s1', 's2'});
    expect(p.seaBest, {'u': 5, 'v': 1});
    expect(p.lostStages, isEmpty);
  });

  test('授業の記録：進んだ方と、早く合格した日', () {
    const a =
        LessonRecord(lessonId: 'l', step: 3, quizPassedDay: 0, updatedDay: 5);
    const b = LessonRecord(
        lessonId: 'l',
        step: 1,
        viewed: true,
        quizBest: 4,
        quizLast: 4,
        quizPassedDay: 6,
        updatedDay: 6);
    final m = RecordMerge.lessons({'l': a}, {'l': b})['l']!;
    expect(m.step, 3);
    expect(m.viewed, isTrue);
    expect(m.quizPassedDay, 6);
    expect(m.quizLast, 4);
  });

  test('同じ中身かどうかは、キーや集合の並びに左右されない', () {
    expect(
        RecordMerge.same({
          'a': 1,
          'b': [2, 1]
        }, {
          'b': [1, 2],
          'a': 1
        }),
        isTrue);
    expect(RecordMerge.same({'a': 1}, {'a': 2}), isFalse);
  });
}
