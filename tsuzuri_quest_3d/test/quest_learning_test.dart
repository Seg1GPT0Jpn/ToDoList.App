import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri_quest_3d/game/field3d.dart';
import 'package:tsuzuri_quest_3d/game/learning3d.dart';
import 'package:tsuzuri_quest_3d/game/quest3d.dart';
import 'package:tsuzuri_quest_3d/game/save3d.dart';

const _r = Field3DRegion.meadow;

QuestContext _ctx(Field3DState s, {int mastered = 0}) =>
    QuestContext.of(s, _r, mastered: mastered);

QuizQuestion _q(String id) => QuizQuestion(
  id: id,
  category: QuestionCategory.values.first,
  prompt: 'p',
  choices: const ['a', 'b', 'c', 'd'],
);

void main() {
  group('クエスト', () {
    test('案内人と話すと最初のクエストを達成し、次のクエストを受ける', () {
      var s = Field3DState.start(_r);
      expect(QuestBook.proto.current(s.questsDone)!.id, 'q_hello');
      expect(
        QuestBook.proto.objective(s.questsDone, _ctx(s)),
        contains('案内人ノート'),
      );
      s = s.copyWith(talked: {QuestBook.proto.giverId});
      final talk = QuestBook.proto.talk(s.questsDone, _ctx(s));
      expect(talk.completed!.id, 'q_hello');
      expect(talk.lines.join(), contains('はじめてのバトル'));
      s = s.copyWith(questsDone: {...s.questsDone, talk.completed!.id});
      expect(QuestBook.proto.current(s.questsDone)!.id, 'q_first');
      expect(QuestBook.proto.reportable(s.questsDone, _ctx(s)), isFalse);
      // 目的を達成していないうちは、報告にならない
      expect(QuestBook.proto.talk(s.questsDone, _ctx(s)).completed, isNull);
    });

    test('目的を達成すると「報告しよう」になり、報告で称号がもらえる', () {
      var s = Field3DState.start(_r).copyWith(
        talked: {QuestBook.proto.giverId},
        questsDone: {'q_hello', 'q_first'},
        defeated: {for (final e in _r.enemies) e.id},
      );
      expect(QuestBook.proto.reportable(s.questsDone, _ctx(s)), isTrue);
      expect(QuestBook.proto.objective(s.questsDone, _ctx(s)), contains('報告'));
      final talk = QuestBook.proto.talk(s.questsDone, _ctx(s));
      expect(talk.completed!.id, 'q_all');
      s = s.copyWith(questsDone: {...s.questsDone, 'q_all'});
      expect(QuestBook.proto.honors(s.questsDone), ['草原の見張り番']);
      expect(
        QuestBook.proto.objective(s.questsDone, _ctx(s)),
        contains('復習スライム'),
      );
    });

    test('復習・習得のクエストと、すべて終わったあと', () {
      final done = {'q_hello', 'q_first', 'q_all'};
      var s = Field3DState.start(_r).copyWith(questsDone: done);
      expect(QuestBook.proto.objective(done, _ctx(s)), contains('0/1'));
      s = s.copyWith(reviewWins: 1);
      expect(QuestBook.proto.reportable(done, _ctx(s)), isTrue);
      final done2 = {...done, 'q_review'};
      expect(
        QuestBook.proto.objective(done2, _ctx(s, mastered: 4)),
        contains('4/10'),
      );
      expect(QuestBook.proto.reportable(done2, _ctx(s, mastered: 10)), isTrue);
      final all = {for (final q in QuestBook.proto.chain) q.id};
      expect(QuestBook.proto.current(all), isNull);
      expect(QuestBook.proto.talk(all, _ctx(s)).completed, isNull);
      expect(QuestBook.proto.objective(all, _ctx(s)), contains('すべて達成'));
    });

    test('クエストの ID は重複せず、報酬は正の数', () {
      final ids = QuestBook.proto.chain.map((q) => q.id).toSet();
      expect(ids, hasLength(QuestBook.proto.chain.length));
      for (final q in QuestBook.proto.chain) {
        expect(q.rewardExp, greaterThan(0));
        expect(QuestBook.proto.byId(q.id), same(q));
      }
      expect(_r.npcs.map((n) => n.id), contains(QuestBook.proto.giverId));
    });
  });

  group('セーブの互換', () {
    test('クエストと復習の回数を保存・読み込みできる', () {
      final s = Field3DState.start(_r).copyWith(
        questsDone: {'q_hello'},
        reviewWins: 2,
        beatenDay: {'proto_slime_math': 20000, 'unknown': 1},
      );
      final back = Field3DState.decode(s.encode(), _r);
      expect(back.questsDone, {'q_hello'});
      expect(back.reviewWins, 2);
      expect(back.beatenDay, {'proto_slime_math': 20000}, reason: '知らない敵は捨てる');
    });

    test('古い保存データ（クエストの項目なし）も読める', () {
      const old =
          '{"v":1,"region":"meadow_proto","x":1,"y":0,"z":2,"heading":0,'
          '"cameraYaw":0,"defeated":["proto_slime_math"],"talked":[]}';
      final s = Field3DState.decode(old, _r);
      expect(s.x, 1);
      expect(s.defeated, {'proto_slime_math'});
      expect(s.questsDone, isEmpty);
      expect(s.reviewWins, 0);
      expect(s.beatenDay, isEmpty);
    });
  });

  group('学習記録と復習', () {
    LearningRecord answer(
      LearningRecord r,
      String id,
      bool ok,
      int day, {
      String set = 'english_01_a',
    }) => r.recordAll([
      Learning3D.event(
        _q(id),
        setId: set,
        knew: ok,
        elapsed: const Duration(seconds: 3),
      ),
    ], day: day);

    test('答えた日のうちは復習に数えず、次の日から復習になる', () {
      var r = answer(LearningRecord.empty, 'q1', false, 100);
      r = answer(r, 'q2', true, 100);
      expect(Learning3D.dueCount(r, ['english_01_a'], 100), 0);
      expect(Learning3D.dueCount(r, ['english_01_a'], 101), 2);
      expect(Learning3D.dueCount(r, ['math_x'], 101), 0);
      // 次の日に正解すると、間隔がのびて しばらく出ない
      r = answer(r, 'q1', true, 101);
      r = answer(r, 'q2', true, 101);
      expect(Learning3D.dueCount(r, ['english_01_a'], 102), 0);
    });

    test('まちがえた問題ほど先に出る重み', () {
      var r = answer(LearningRecord.empty, 'miss', false, 100);
      r = answer(r, 'ok', true, 100);
      final w = Learning3D.weight(() => r, () => 100);
      expect(w(_q('miss')), greaterThan(w(_q('ok'))));
      expect(w(_q('new')), 1);
    });

    test('復習スライムは、復習の日が来た問題を強く優先する', () {
      var r = answer(LearningRecord.empty, 'old', true, 100);
      r = answer(r, 'today', false, 101);
      final w = Learning3D.reviewWeight(() => r, () => 101);
      expect(w(_q('old')), greaterThanOrEqualTo(50));
      expect(w(_q('today')), 1, reason: '今日答えた問題はあとまわし');
      expect(w(_q('new')), 1);
    });

    test('教科ごとのまとめ', () {
      var r = answer(LearningRecord.empty, 'e1', true, 100);
      r = answer(r, 'e2', false, 100);
      r = answer(r, 'm1', true, 100, set: 'math_m1_01_a');
      final s = Learning3D.subjects(r, 101);
      expect(s.map((x) => x.subject), ['english', 'math']);
      final en = s.first;
      expect(en.answered, 2);
      expect(en.accuracy, 0.5);
      expect(en.weak, 1);
      expect(en.due, 2);
      expect(Learning3D.subjectName('math'), '数学');
    });

    test('学習記録は tq3d_ のキーに保存し、データを消すと消える', () async {
      SharedPreferences.setMockInitialValues({'rpg_learning_v1': '2D'});
      final save = await Save3D.open();
      expect(save.loadLearning().stats, isEmpty);
      await save.saveLearning(answer(LearningRecord.empty, 'q1', true, 5));
      expect(Save3D.learningKey, startsWith('tq3d_'));
      expect(save.loadLearning()['q1']!.attempts, 1);
      await save.prefs.setString(Save3D.learningKey, '{こわれた');
      expect(save.loadLearning().stats, isEmpty);
      await save.saveLearning(answer(LearningRecord.empty, 'q1', true, 5));
      await save.reset();
      expect(save.loadLearning().stats, isEmpty);
      expect(save.prefs.getString('rpg_learning_v1'), '2D');
    });
  });
}
