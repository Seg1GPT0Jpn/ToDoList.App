import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('物語', () {
    test('6つの国に1つずつ欠片があり、ルートの最後をすべて倒すと手に入る', () {
      expect(Story.worlds.length, 6);
      expect(Story.fragments(RpgProgress.initial), isEmpty);
      final english = Story.finalsOf('english');
      expect(english.single.id, 'english_20');
      final p = RpgProgress.initial.copyWith(clearedStageIds: {'english_20'});
      expect(Story.fragments(p), {'english'});
      // 数学はルートが6本。1本だけでは手に入らない
      final math = Story.finalsOf('math');
      expect(math.length, 6);
      final p2 = p.copyWith(clearedStageIds: {
        ...p.clearedStageIds,
        math.first.id,
      });
      expect(Story.fragments(p2), {'english'});
      expect(Story.centerOpen(p2), isFalse);
    });

    test('世界の中心は6教科の最後のボスの範囲から出題する、分野横断の決戦', () {
      final c = Story.centerStage();
      expect(c.isBoss, isTrue);
      expect(BossRules.of(c), BossRule.finale);
      final subjects = {for (final id in c.questionSetIds) id.split('_').first};
      expect(
          subjects,
          containsAll([
            'english',
            'math',
            'science',
            'social',
            'japanese',
            'information'
          ]));
    });
  });

  group('装備・職業・連続学習のごほうび', () {
    test('欠片を取りもどすと、その教科の武器が手に入り、その教科のバトルでだけ効く', () {
      final p = RpgProgress.initial.copyWith(
        clearedStageIds: {'english_20'},
        equipped: {'weapon': 'dict_sword'},
      );
      expect(Gear.owned(p), contains('dict_sword'));
      expect(Gear.bonusFor(p, 'english').attackRate, closeTo(1.15, 1e-9));
      expect(Gear.bonusFor(p, 'math').attackRate, 1);
      // 持っていない装備は、装備していても効かない
      final q =
          RpgProgress.initial.copyWith(equipped: {'weapon': 'formula_pen'});
      expect(Gear.equipped(q).first.id, 'wood_pen');
    });

    test('職業の効果', () {
      final w = RpgProgress.initial.copyWith(job: 'warrior');
      expect(Gear.bonusFor(w, 'math').attackRate, closeTo(1.1, 1e-9));
      expect(
          Gear.bonusFor(RpgProgress.initial.copyWith(job: 'guardian'), 'x')
              .damageTakenRate,
          0.85);
      expect(JobDef.parse('nope'), JobDef.adventurer);
    });

    test('連続学習のごほうびは、日数に届いたら1回だけ受け取れる', () {
      var r = LearningRecord.empty;
      for (var d = 100; d < 107; d++) {
        r = r.recordAll([
          AnswerEvent(
              questionId: 'q$d',
              setId: 'math_m1_01',
              isCorrect: true,
              elapsedMs: 1),
        ], day: d);
      }
      final can = Gear.claimable(RpgProgress.initial, r, 106);
      expect(can.map((s) => s.id), ['streak3', 'streak7']);
      final p = Gear.claim(RpgProgress.initial, can.first);
      expect(p.deck, contains('time'));
      expect(Gear.owned(p), contains('clock_brooch'));
      expect(Gear.claimable(p, r, 106).map((s) => s.id), ['streak7']);
      final back = RpgProgress.fromMap(p.toMap());
      expect(back.claimedRewards, {'streak3'});
      expect(back.gear, {'clock_brooch'});
    });

    test('装備の補正がバトルに効く（攻撃・制限時間）', () {
      final b = BattleEngine(
        player: PlayerStats.forLevel(1),
        enemy: testEnemy,
        questions: loadStage01().questions,
        timeLimit: const Duration(seconds: 20),
        random: Random(1),
        damage: fixedDamage(),
        bonus: const BattleBonus(attack: 5, extraSeconds: 2, attackRate: 2),
      );
      expect(b.limitFor(b.currentQuestion), const Duration(seconds: 22));
      final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      expect(r.damageToEnemy, (10 + 5) * 2);
    });
  });

  group('共通テスト遺跡・模試', () {
    final worlds = RpgCatalog.worlds;

    test('階ごとにステージが選ばれ、第4階層は3教科以上をまぜる', () {
      for (final f in RuinsFloor.values) {
        final s = CommonTest.stagesFor(f, worlds, seed: 1);
        expect(s, isNotEmpty, reason: f.name);
      }
      final mixed = CommonTest.stagesFor(RuinsFloor.mixed, worlds, seed: 3);
      expect(
          {for (final s in mixed) s.worldId}.length, greaterThanOrEqualTo(3));
      final real = CommonTest.stage(RuinsFloor.real,
          CommonTest.stagesFor(RuinsFloor.real, worlds, seed: 3),
          level: 20);
      expect(real.isBoss, isTrue);
      expect(real.reinforcements, isNotEmpty);
    });

    test('第3階層からは考察・計算・読解の問題を中心にする', () {
      final picked = CommonTest.stagesFor(
          RuinsFloor.applied, [RpgCatalog.world('math')],
          seed: 2);
      final qs = [for (final s in picked) ...loadStagePool(s).questions];
      final filtered = CommonTest.filter(RuinsFloor.applied, qs);
      expect(
          filtered
              .every((q) => CommonTest.appliedCategories.contains(q.category)),
          isTrue);
    });

    test('模試：教科ごとにステージを選び、100点満点で採点する', () {
      final st = MockExam.stagesFor(RpgCatalog.world('science'), seed: 5);
      expect(st.length, 3);
      expect(MockExam.score(4, 5), 80);
      expect(MockExam.score(0, 0), 0);
    });
  });

  test('学習ナビゲーター：苦手な単元と、まちがえた問題の復習をすすめる', () {
    var r = LearningRecord.empty;
    r = r.recordAll([
      for (var i = 0; i < 8; i++)
        AnswerEvent(
            questionId: 'p$i',
            setId: 'math_ma_05',
            isCorrect: i < 2,
            elapsedMs: 1),
      for (var i = 0; i < 8; i++)
        AnswerEvent(
            questionId: 'g$i',
            setId: 'english_stage_02',
            isCorrect: true,
            elapsedMs: 1,
            category: 'usage'),
    ], day: 200);
    final sig = StudyNavigator.signals(r);
    expect(sig.first.subject, 'math');
    expect(sig.first.signal, Signal.red);
    expect(sig.last.signal, Signal.green);
    final rec = StudyNavigator.today(r, today: 201);
    expect(rec.first.stage?.id, 'math_ma_05');
    expect(rec.any((x) => x.review), isTrue);
    expect(StudyNavigator.insights(r, today: 201).first, contains('まちがえた'));
  });
}
