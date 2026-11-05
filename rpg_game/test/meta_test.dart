import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

BattleReport report({
  BattleMode mode = BattleMode.rpg,
  String subject = 'math',
  bool won = true,
  bool boss = false,
  int correct = 5,
  int answered = 5,
  int combo = 5,
  String look = 'compass',
}) =>
    BattleReport(
      mode: mode,
      subject: subject,
      enemyId: 'e_$look',
      look: look,
      isBoss: boss,
      won: won,
      correct: correct,
      answered: answered,
      maxCombo: combo,
    );

void main() {
  group('敵の種族', () {
    test('ゲームに登場するすべての見た目に種族データがある', () {
      final looks = {
        for (final w in RpgCatalog.worlds)
          for (final s in w.stages) s.enemy.look,
      }..remove('');
      final known = {for (final s in EnemySpeciesCatalog.all) s.look};
      expect(known.containsAll(looks), isTrue,
          reason: '${looks.difference(known)}');
    });

    test('種族名は重複せず、図鑑説明・攻撃・SE がそろっている', () {
      final names = EnemySpeciesCatalog.all.map((s) => s.name).toSet();
      expect(names.length, EnemySpeciesCatalog.all.length);
      for (final s in EnemySpeciesCatalog.all) {
        expect(s.lore, isNotEmpty, reason: s.look);
        expect(s.attack, isNotEmpty, reason: s.look);
        expect(s.sound, startsWith('se_'), reason: s.look);
      }
    });
  });

  group('記録帳（図鑑・回数）', () {
    test('バトルで図鑑と回数が増え、確認用のバトルは記録しない', () {
      var j = PlayerJournal.empty.applyBattle(report(boss: true));
      j = j.applyBattle(report(won: false, look: 'ruler'));
      j = j.applyBattle(report(mode: BattleMode.trial, look: 'dragon'));
      expect(j.seenLooks.keys.toSet(), {'compass', 'ruler'});
      expect(j.defeatedLooks.keys.toSet(), {'compass'});
      expect(j.wins, 1);
      expect(j.bossKills, 1);
      expect(j.perfects, 1);
      final back = PlayerJournal.fromMap(j.toMap());
      expect(back.toMap(), j.toMap());
    });
  });

  group('実績', () {
    test('条件を満たした実績だけが新しく解除され、二重には解除されない', () {
      final j = PlayerJournal.empty.applyBattle(report(boss: true));
      final c = AchievementContext(
        progress: RpgProgress.initial,
        record: LearningRecord.empty,
        journal: j,
        today: 10,
      );
      final ids = Achievements.newlyAchieved(c).map((a) => a.id).toSet();
      expect(ids, containsAll(['first_win', 'boss_1', 'perfect_1']));
      expect(ids.contains('boss_10'), isFalse);
      final unlocked = j.unlock(ids, 10);
      final again = Achievements.newlyAchieved(
        AchievementContext(
          progress: RpgProgress.initial,
          record: LearningRecord.empty,
          journal: unlocked,
          today: 10,
        ),
      );
      expect(again, isEmpty);
    });

    test('実績 ID は重複しない', () {
      final ids = Achievements.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('デイリークエスト', () {
    const subjects = {'math': '数学', 'english': '英語', 'science': '理科'};

    test('同じ日なら同じクエスト、日が変わると変わる', () {
      final a = DailyQuests.forDay(100, subjects).map((q) => q.id).toList();
      final b = DailyQuests.forDay(100, subjects).map((q) => q.id).toList();
      expect(a, b);
      expect(a.length, 3);
      final days = {
        for (var d = 100; d < 110; d++)
          DailyQuests.forDay(d, subjects).map((q) => q.title).join(),
      };
      expect(days.length, greaterThan(3));
    });

    test('バトルの結果でクエストが進み、目標で止まる', () {
      final qs = [
        const QuestDef(
          id: 'c',
          kind: QuestKind.correctInSubject,
          title: '',
          goal: 15,
          rewardExp: 30,
          subject: 'math',
        ),
        const QuestDef(
          id: 'k',
          kind: QuestKind.comboInSubject,
          title: '',
          goal: 4,
          rewardExp: 30,
          subject: 'math',
        ),
        const QuestDef(
          id: 'b',
          kind: QuestKind.defeatBoss,
          title: '',
          goal: 1,
          rewardExp: 30,
        ),
      ];
      var s = const QuestState();
      s = DailyQuests.apply(s, 5, qs, report(correct: 10, combo: 3));
      s = DailyQuests.apply(
          s, 5, qs, report(correct: 10, combo: 6, boss: true));
      s = DailyQuests.apply(s, 5, qs, report(subject: 'english', correct: 9));
      expect(s.progress['c'], 15);
      expect(s.progress['k'], 4);
      expect(DailyQuests.isDone(s, qs[2]), isTrue);
      // 日が変わるとリセット
      s = DailyQuests.apply(s, 6, qs, report(correct: 1, combo: 1));
      expect(s.progress['c'], 1);
    });
  });

  group('バトルの反映（MetaUpdate）', () {
    test('学習記録・図鑑・クエスト・実績がまとめて進む', () {
      final events = [
        for (var i = 0; i < 5; i++)
          AnswerEvent(
            questionId: 'q$i',
            setId: 'math_m1_01',
            isCorrect: true,
            elapsedMs: 3000,
          ),
      ];
      final u = MetaUpdate.apply(
        record: LearningRecord.empty,
        journal: PlayerJournal.empty,
        progress: RpgProgress.initial,
        events: events,
        report: report(),
        day: 100,
        subjects: const {'math': '数学'},
      );
      expect(u.record.stats.length, 5);
      expect(u.journal.wins, 1);
      expect(u.journal.defeatedLooks['compass'], 1);
      expect(u.journal.quest.day, 100);
      expect(u.newAchievements.map((a) => a.id), contains('first_win'));
      expect(u.journal.achievements.containsKey('first_win'), isTrue);

      // 同じ実績は二度出ない
      final again = MetaUpdate.apply(
        record: u.record,
        journal: u.journal,
        progress: RpgProgress.initial,
        events: events,
        report: report(),
        day: 100,
        subjects: const {'math': '数学'},
      );
      expect(
          again.newAchievements.map((a) => a.id), isNot(contains('first_win')));
    });

    test('確認用バトルは何も記録しない', () {
      final u = MetaUpdate.apply(
        record: LearningRecord.empty,
        journal: PlayerJournal.empty,
        progress: RpgProgress.initial,
        events: const [
          AnswerEvent(
            questionId: 'q',
            setId: 's',
            isCorrect: true,
            elapsedMs: 1,
          ),
        ],
        report: report(mode: BattleMode.trial),
        day: 1,
        subjects: const {'math': '数学'},
      );
      expect(u.record.stats, isEmpty);
      expect(u.journal.wins, 0);
      expect(u.newAchievements, isEmpty);
    });
  });
}
