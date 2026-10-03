import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

LearningRecord answer(
  LearningRecord r,
  String setId,
  int n, {
  required int correct,
  String category = 'usage',
  String prefix = 'q',
}) =>
    r.recordAll([
      for (var i = 0; i < n; i++)
        AnswerEvent(
          questionId: '$prefix$setId$i',
          setId: setId,
          category: category,
          isCorrect: i < correct,
          elapsedMs: 3000,
        ),
    ], day: 100);

void main() {
  test('英語は文法・単語・長文・熟語、ほかの教科はルートごとの分野に分かれる', () {
    expect(Proficiency.fieldsOf('english'), ['文法', '単語', '長文', '熟語']);
    expect(Proficiency.fieldsOf('science'), contains('中1'));
    expect(Proficiency.fieldsOf('math'), ['小1', '小2', '小3', '小4', '小5', '小6', '中1', '中2', '中3']);
  });

  test('熟練度は実際の正答率から決まり、少ない回答では判定しない', () {
    var r = LearningRecord.empty;
    r = answer(r, 'math_j2_07', 10, correct: 3); // 中2の確率：苦手
    r = answer(r, 'math_j1_01', 10, correct: 9); // 中1の正負の数：得意
    r = answer(r, 'english_j1_02', 8, correct: 6);
    r = answer(r, 'english_j1_02', 6,
        correct: 5, category: 'meaning', prefix: 'w');
    r = answer(r, 'science_j1_03', 3, correct: 3);
    final s = Proficiency.bySubject(r);
    final math = {for (final f in s['math']!) f.field: f};
    expect(math['中2']!.rated, isTrue);
    expect(math['中2']!.score, lessThan(math['中1']!.score));
    expect(math['中1']!.score, greaterThanOrEqualTo(80));
    final en = {for (final f in s['english']!) f.field: f};
    expect(en['文法']!.answered, 8);
    expect(en['単語']!.answered, 6);
    expect(en['長文']!.rated, isFalse);
    // 3問しか答えていない分野は判定しない
    final sci = {for (final f in s['science']!) f.field: f};
    expect(sci['中1']!.rated, isFalse);
    // 苦手な単元が先に来る
    final weak = Proficiency.weakestUnits(r);
    expect(weak.first.$1.id, 'math_j2_07');
    expect(Proficiency.totalPower(r), inInclusiveRange(1, 100));
  });

  test('教科の学習レベルは、習得した問題の数で上がる', () {
    var r = LearningRecord.empty;
    expect(Proficiency.subjectLevel(r, 'math'), 1);
    for (var day = 0; day < 3; day++) {
      r = r.recordAll([
        for (var i = 0; i < 20; i++)
          AnswerEvent(
            questionId: 'm$i',
            setId: 'math_j1_01',
            isCorrect: true,
            elapsedMs: 1000,
          ),
      ], day: day * 10);
    }
    expect(Proficiency.subjectLevel(r, 'math'), greaterThan(1));
    expect(Proficiency.subjectLevel(r, 'english'), 1);
  });

  test('問題の種類は保存しても元にもどる', () {
    final s = const QuestionStat().record(
      isCorrect: true,
      day: 1,
      elapsedMs: 10,
      setId: 'english_j1_01',
      category: 'reading',
    );
    expect(QuestionStat.fromList(s.toList()).category, 'reading');
    expect(QuestionStat.fromList(const QuestionStat().toList()).category, '');
  });

  test('復習の塔：階ごとに集める問題がちがう', () {
    var r = LearningRecord.empty;
    // 2回まちがえた問題（day 90 と 100）
    for (final day in [90, 100]) {
      r = r.recordAll([
        const AnswerEvent(
          questionId: 'twice',
          setId: 'math_j2_07',
          isCorrect: false,
          elapsedMs: 1000,
        ),
      ], day: day);
    }
    // ずっと前に1回だけ正解した問題
    r = r.recordAll([
      const AnswerEvent(
        questionId: 'old',
        setId: 'math_j1_01',
        isCorrect: true,
        elapsedMs: 1000,
      ),
    ], day: 10);
    const today = 102;
    ids(TowerFloor f) => {
          for (final i in ReviewPlanner.planFloor(r, f, today: today))
            i.questionId,
        };
    expect(ids(TowerFloor.recent), {'twice'});
    expect(ids(TowerFloor.repeated), {'twice'});
    expect(ids(TowerFloor.stale), {'old'});
    expect(ids(TowerFloor.forgotten), {'old'});
    expect(ids(TowerFloor.summit), contains('twice'));
    final summit = ReviewTower.stage(
      level: 5,
      floor: 3,
      questionCount: 10,
      worldId: 'math',
      summit: true,
    );
    expect(summit.isBoss, isTrue);
    expect(BossRules.of(summit), BossRule.trial);
  });
}
