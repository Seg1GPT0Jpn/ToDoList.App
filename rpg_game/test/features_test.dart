import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

QuizQuestion q(String id, QuestionCategory c) => QuizQuestion(
      id: id,
      category: c,
      prompt: 'p$id',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
      explanation: 'e',
    );

List<QuizQuestion> only(QuestionCategory c, [int n = 6]) =>
    [for (var i = 0; i < n; i++) q('$c$i', c)];

BattleEngine battle({
  EnemyDef enemy = testEnemy,
  List<QuizQuestion>? questions,
  List<CardDef> deck = const [],
  Set<CompanionEffect> companions = const {},
  double bonusHpRate = 0,
}) =>
    BattleEngine(
      player: PlayerStats.forLevel(1),
      enemy: enemy,
      questions: questions ?? only(QuestionCategory.usage),
      timeLimit: const Duration(seconds: 20),
      deck: deck,
      companions: companions,
      bonusHpRate: bonusHpRate,
      random: Random(1),
      damage: fixedDamage(),
    );

TurnResult right(BattleEngine b) =>
    b.answer(b.currentQuestion.correctIndex, elapsed: slow);
TurnResult wrong(BattleEngine b) => b.answer(wrongIndex(b), elapsed: slow);

void main() {
  group('弱点と装甲', () {
    test('弱点の種類に正解すると1.5倍', () {
      const e = EnemyDef(
          id: 'w',
          name: 'w',
          maxHp: 999,
          attack: 5,
          weakness: QuestionCategory.usage);
      final r = right(battle(enemy: e));
      expect(r.weakness, isTrue);
      expect(r.damageToEnemy, 15);
    });

    test('装甲がある間はほかの種類がはじかれ、指定の種類で割れる', () {
      const e = EnemyDef(
          id: 'a',
          name: 'a',
          maxHp: 999,
          attack: 5,
          armorCategory: QuestionCategory.meaning,
          armor: 2);
      final b = battle(enemy: e, questions: [
        ...only(QuestionCategory.usage, 1),
      ]);
      final r1 = right(b);
      expect(r1.blocked, isTrue);
      expect(r1.damageToEnemy, 3); // 10 × 0.3
      expect(b.armor, 2);

      final b2 = battle(enemy: e, questions: only(QuestionCategory.meaning, 4));
      expect(right(b2).armorBroken, isFalse);
      expect(right(b2).armorBroken, isTrue);
      expect(b2.armor, 0);
    });
  });

  group('知識カード', () {
    final power = CardDef.byId('power');
    final heal = CardDef.byId('heal');
    final guard = CardDef.byId('guard');
    final hint = CardDef.byId('hint');

    test('手札は3枚で、使うと補充される', () {
      final b = battle(deck: [power, heal, guard, hint]);
      expect(b.hand.length, 3);
      b.useCard(0);
      expect(b.hand.length, 2);
      right(b);
      expect(b.hand.length, 3);
    });

    test('1問に使えるカードは1枚', () {
      final b = battle(deck: [power, power, power]);
      b.useCard(0);
      expect(() => b.useCard(0), throwsStateError);
    });

    test('強打：正解2倍、不正解は1.5倍のダメージを受ける', () {
      final b = battle(deck: [power, power, power]);
      b.useCard(0);
      expect(right(b).damageToEnemy, 20);
      b.useCard(0);
      expect(wrong(b).damageToPlayer, 9); // 6 × 1.5
    });

    test('守りの辞書：間違えてもダメージなし', () {
      final b = battle(deck: [guard, guard, guard]);
      b.useCard(0);
      final r = wrong(b);
      expect(r.guarded, isTrue);
      expect(r.damageToPlayer, 0);
    });

    test('回復の詩：正解で最大HPの30%回復', () {
      final b = battle(deck: [heal, heal, heal]);
      wrong(b);
      wrong(b);
      final before = b.playerHp;
      b.useCard(0);
      final r = right(b);
      expect(r.healed, 12);
      expect(b.playerHp, before + 12);
    });

    test('ひらめきの栞：間違いの選択肢を2つ消す', () {
      final b = battle(deck: [hint, hint, hint]);
      b.useCard(0);
      expect(b.hiddenChoices.length, 2);
      expect(b.hiddenChoices, isNot(contains(b.currentQuestion.correctIndex)));
    });

    test('時の砂：制限時間+10秒', () {
      final b = battle(deck: [CardDef.byId('time'), power, power]);
      expect(b.limitFor(b.currentQuestion), const Duration(seconds: 20));
      b.useCard(0);
      expect(b.limitFor(b.currentQuestion), const Duration(seconds: 30));
    });
  });

  group('仲間', () {
    test('ねこ先生：1回だけやられる攻撃をHP1で耐える', () {
      const strong = EnemyDef(id: 's', name: 's', maxHp: 999, attack: 200);
      final b = battle(enemy: strong, companions: {CompanionEffect.lastStand});
      final r = wrong(b);
      expect(r.survived, isTrue);
      expect(b.playerHp, 1);
      wrong(b);
      expect(b.phase, BattlePhase.lost);
    });

    test('辞書じいさん：受けるダメージ -15%', () {
      const e = EnemyDef(id: 'e', name: 'e', maxHp: 999, attack: 21);
      final r =
          wrong(battle(enemy: e, companions: {CompanionEffect.defenseUp}));
      expect(r.damageToPlayer, 17); // 20 × 0.85
    });

    test('泉の加護：最大HP +30%', () {
      final b = battle(bonusHpRate: Progression.springHpRate);
      expect(b.maxHp, 65);
      expect(b.playerHp, 65);
    });
  });

  group('進行：亡霊・仲間・宝箱・泉', () {
    final world = RpgCatalog.world(RpgCatalog.englishWorldId);
    final area5 = world.stages[4];

    BattleSummary play(bool win, {int misses = 1}) {
      final b = battle(
          enemy: const EnemyDef(id: 'x', name: 'x', maxHp: 30, attack: 30),
          questions: only(QuestionCategory.usage, 6));
      for (var i = 0; i < misses && !b.isOver; i++) {
        wrong(b);
      }
      while (!b.isOver) {
        win ? right(b) : wrong(b);
      }
      return b.summary();
    }

    test('間違えた問題は亡霊として残り、再戦で正解すると消える', () {
      final r = Progression.applyBattle(
          progress: RpgProgress.initial,
          world: world,
          stage: area5,
          summary: play(true));
      expect(r.newMistakes, 1);
      expect(r.progress.mistakes.values, [area5.id]);

      final ghost = battle(questions: [
        for (final id in r.progress.mistakes.keys)
          q(id, QuestionCategory.usage),
      ], enemy: const EnemyDef(id: 'g', name: 'g', maxHp: 5, attack: 1));
      right(ghost);
      final g = Progression.applyGhostBattle(r.progress, ghost.summary());
      expect(g.progress.mistakes, isEmpty);
      expect(g.expGained,
          Progression.expPerGhostCorrect + Progression.ghostClearBonus);
    });

    test('負けたボスの仲間は、再戦で勝つと仲間になる', () {
      final lost = Progression.applyBattle(
          progress: RpgProgress.initial,
          world: world,
          stage: area5,
          summary: play(false));
      expect(lost.progress.lostStages, contains(area5.id));
      expect(lost.rescued, isNull);
      final won = Progression.applyBattle(
          progress: lost.progress,
          world: world,
          stage: area5,
          summary: play(true));
      expect(won.rescued?.id, area5.captiveCompanionId);
      expect(won.progress.companions, contains(area5.captiveCompanionId));
    });

    test('初クリアでカードがもらえる', () {
      final r = Progression.applyBattle(
          progress: RpgProgress.initial,
          world: world,
          stage: area5,
          summary: play(true));
      expect(r.newCard?.id, area5.rewardCardId);
      expect(r.progress.deck.length, RpgProgress.starterDeck.length + 1);
    });

    test('宝箱は1回きり。正解ならレアカード', () {
      final (p1, c1) =
          Progression.openChest(RpgProgress.initial, 'c1', false, Random(1));
      expect(c1, isNull);
      expect(p1.openedChests, {'c1'});
      final (p2, c2) =
          Progression.openChest(RpgProgress.initial, 'c2', true, Random(1));
      expect(c2!.rarity, CardRarity.rare);
      expect(p2.deck, contains(c2.id));
    });

    test('泉の加護はバトル後に消える', () {
      final p = Progression.blessSpring(RpgProgress.initial);
      expect(p.springBuff, isTrue);
      final r = Progression.applyBattle(
          progress: p, world: world, stage: area5, summary: play(true));
      expect(r.progress.springBuff, isFalse);
    });

    test('新しい項目も保存・読み込みできる', () {
      final p = RpgProgress.initial.copyWith(
          deck: ['power', 'time'],
          mistakes: {'q1': 'english_01'},
          openedChests: {'c'},
          companions: {'kotodama'},
          lostStages: {'english_05'},
          springBuff: true);
      expect(RpgProgress.fromMap(p.toMap()).toMap(), p.toMap());
      expect(RpgProgress.fromMap({}).deck, RpgProgress.starterDeck);
    });
  });

  test('四天王とラスボスには装甲、エリア1〜15には弱点がある', () {
    for (final s in RpgCatalog.englishStages) {
      if (s.order <= 15) expect(s.enemy.weakness, isNotNull, reason: s.name);
      if ([16, 17, 20].contains(s.order)) expect(s.enemy.armor, greaterThan(0));
      expect(s.enemy.introLine, isNotEmpty);
    }
  });

  test('バトルの解説は最初の1文だけ、残りは復習手帳', () {
    final q = QuizQuestion.fromJson({
      'id': 'x',
      'category': 'usage',
      'prompt': 'p',
      'choices': ['a', 'b', 'c', 'd'],
      'answerIndex': 0,
      'explanation': '一文目。二文目の説明。',
    });
    expect(q.shortExplanation, '一文目。');
    expect(q.hasMoreExplanation, isTrue);
  });
}
