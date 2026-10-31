import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// カテゴリだけちがう、かんたんな問題
QuizQuestion q(String id, QuestionCategory c) => QuizQuestion(
      id: id,
      category: c,
      prompt: 'Q$id',
      choices: const ['a', 'b', 'c', 'd'],
      answerIndex: 0,
    );

final mixed = [
  for (var i = 0; i < 12; i++)
    q('m$i', i.isEven ? QuestionCategory.usage : QuestionCategory.meaning),
];

BattleEngine battle(
  EnemyDef enemy, {
  List<QuizQuestion>? questions,
  BossRule rule = BossRule.none,
  List<CardDef> deck = const [],
  double Function(QuizQuestion)? weight,
}) =>
    BattleEngine(
      player: PlayerStats.forLevel(1),
      enemy: enemy,
      questions: questions ?? mixed,
      timeLimit: const Duration(seconds: 20),
      random: Random(3),
      damage: fixedDamage(),
      bossRule: rule,
      deck: deck,
      handSize: deck.length,
      questionWeight: weight,
    );

EnemyDef foe(String look,
        {QuestionCategory? weakness, int hp = 1000, EnemyAbility? ability}) =>
    EnemyDef(
      id: 'f',
      name: 'f',
      maxHp: hp,
      attack: 5,
      look: look,
      weakness: weakness,
      ability: ability ?? EnemyAbility.none,
    );

void main() {
  test('見た目から能力が決まる（装甲をもつ敵は能力なし）', () {
    expect(foe('eraser').effectiveAbility, EnemyAbility.guard);
    expect(foe('book').effectiveAbility, EnemyAbility.disrupt);
    expect(foe('pencil').effectiveAbility, EnemyAbility.combo);
    expect(foe('ruler').effectiveAbility, EnemyAbility.specialist);
    expect(foe('knight').effectiveAbility, EnemyAbility.sturdy);
    expect(foe('scissors').effectiveAbility, EnemyAbility.chainLock);
    expect(foe('slime').effectiveAbility, EnemyAbility.none);
    const armored = EnemyDef(
      id: 'a',
      name: 'a',
      maxHp: 10,
      attack: 1,
      look: 'eraser',
      armor: 2,
      armorCategory: QuestionCategory.usage,
    );
    expect(armored.effectiveAbility, EnemyAbility.none);
  });

  test('防御型：弱点の問題に正解するまでダメージ半分、正解すると守りが解ける', () {
    final b = battle(foe('eraser', weakness: QuestionCategory.usage));
    var sawHalf = false;
    var broke = false;
    while (!broke) {
      final isWeak =
          b.currentQuestion.source.category == QuestionCategory.usage;
      final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
      if (!isWeak) {
        expect(r.damageToEnemy,
            (10 * 0.5 * DamageCalculator.chainRate(r.combo)).round());
        sawHalf = true;
      } else {
        expect(r.guardBroken, isTrue);
        broke = true;
      }
    }
    expect(b.guardUp, isFalse);
    expect(sawHalf || broke, isTrue);
  });

  test('妨害型：まちがえると次の問題がむずかしく（苦手な問題に）なる', () {
    final hard = {'m5', 'm7'};
    final b = battle(
      foe('book'),
      weight: (q) => hard.contains(q.id) ? 5 : 1,
    );
    final r = b.answer(wrongIndex(b), elapsed: slow);
    expect(r.disrupted, isTrue);
    expect(hard.contains(b.currentQuestion.source.id), isTrue);
  });

  test('コンボ型：1問目は半分、連続正解でどんどん効く', () {
    final b = battle(foe('pencil'));
    final d1 =
        b.answer(b.currentQuestion.correctIndex, elapsed: slow).damageToEnemy;
    final d2 =
        b.answer(b.currentQuestion.correctIndex, elapsed: slow).damageToEnemy;
    final d3 =
        b.answer(b.currentQuestion.correctIndex, elapsed: slow).damageToEnemy;
    expect(d1, 5);
    expect(d2, greaterThan(d1));
    expect(d3, greaterThan(d2));
  });

  test('特化型：弱点はダメージ2.5倍、ほかは0.6倍', () {
    final b = battle(foe('ruler', weakness: QuestionCategory.usage));
    final weak = b.currentQuestion.source.category == QuestionCategory.usage;
    final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    expect(r.damageToEnemy, weak ? 25 : 6);
  });

  test('中ボス（3連続正解）：3問目ごとにダメージ2.5倍', () {
    final b = battle(foe('slime'), rule: BossRule.chain3);
    final ds = [
      for (var i = 0; i < 3; i++)
        b.answer(b.currentQuestion.correctIndex, elapsed: slow),
    ];
    expect(ds[2].bossBurst, isTrue);
    expect(ds[2].damageToEnemy, (10 * 1.5 * 2.5).round());
    expect(ds[0].bossBurst || ds[1].bossBurst, isFalse);
  });

  test('大ボス（5問中4問）：合格で最大HPの25%、不合格でボスが回復', () {
    final pass = battle(foe('slime', hp: 400), rule: BossRule.trial);
    TurnResult? last;
    for (var i = 0; i < 5; i++) {
      last = i == 2
          ? pass.answer(wrongIndex(pass), elapsed: slow)
          : pass.answer(pass.currentQuestion.correctIndex, elapsed: slow);
    }
    expect(last!.trialResult, isTrue);
    expect(last.bossBurst, isTrue);

    final fail = battle(foe('slime', hp: 400), rule: BossRule.trial);
    for (var i = 0; i < 5; i++) {
      last = i < 2
          ? fail.answer(fail.currentQuestion.correctIndex, elapsed: slow)
          : fail.answer(wrongIndex(fail), elapsed: slow);
    }
    expect(last!.trialResult, isFalse);
    expect(last.enemyHealed, greaterThan(0));
  });

  test('ラスボス（分野横断）：HPが減るごとに出題の中心の分野が変わる', () {
    final qs = [
      for (var i = 0; i < 20; i++)
        q(
            'f$i',
            [
              QuestionCategory.usage,
              QuestionCategory.meaning,
            ][i % 2]),
    ];
    final b =
        battle(foe('dragon', hp: 200), questions: qs, rule: BossRule.finale);
    expect(b.finaleFocus, QuestionCategory.usage);
    // 最初の数問は中心の分野から出る
    for (var i = 0; i < 3; i++) {
      expect(b.currentQuestion.source.category, QuestionCategory.usage);
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    }
    while (!b.isOver && b.enemyHp > 200 * 0.75) {
      b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    }
    expect(b.finaleFocus, QuestionCategory.meaning);
  });

  test('むすびの栞：間違えてもチェインが切れない', () {
    final b = battle(foe('slime'), deck: [CardDef.byId('keep')]);
    b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    b.useCard(0);
    final r = b.answer(wrongIndex(b), elapsed: slow);
    expect(r.comboKept, isTrue);
    expect(r.combo, 2);
  });

  test('苦手の地図：苦手な問題が出やすくなり、正解でダメージ1.3倍', () {
    final weak = {'m3', 'm9'};
    final b = battle(
      foe('slime'),
      deck: [CardDef.byId('focus')],
      weight: (q) => weak.contains(q.id) ? 9 : 1,
    );
    b.useCard(0);
    final r = b.answer(b.currentQuestion.correctIndex, elapsed: slow);
    expect(r.damageToEnemy, 13);
    expect(b.focusActive, isTrue);
    expect(weak.contains(b.currentQuestion.source.id), isTrue);
  });

  test('ボスのルール：強敵・ボス・ラスボス・試験本番', () {
    final english = RpgCatalog.world(RpgCatalog.englishWorldId).stages;
    expect(BossRules.of(english.first), BossRule.none);
    expect(BossRules.of(Elites.of(english.first)), BossRule.chain3);
    expect(BossRules.of(english[15]), BossRule.trial);
    expect(BossRules.of(english.last), BossRule.finale);
  });

  test('カードには種類があり、デッキは10枚', () {
    expect(CardDef.byId('power').type, CardType.attack);
    expect(CardDef.byId('guard').type, CardType.defense);
    expect(CardDef.byId('heal').type, CardType.heal);
    expect(CardDef.byId('focus').type, CardType.study);
    expect(CardDef.byId('keep').type, CardType.combo);
    expect(CardDef.deckSize, 10);
  });

  test('おまかせデッキ：型に合わせて10枚まで選び、持っていないカードは入れない', () {
    final owned = [
      ...RpgProgress.starterDeck,
      'focus',
      'focus',
      'keep',
      'critical',
      'time',
      'chain',
      'heal',
      'gamble',
    ];
    for (final style in DeckStyle.values) {
      final deck = DeckBuilder.preset(owned, style);
      expect(deck.length, lessThanOrEqualTo(CardDef.deckSize));
      final rest = [...owned];
      for (final id in deck) {
        expect(rest.remove(id), isTrue, reason: '$style $id');
      }
    }
    final attack = DeckBuilder.preset(owned, DeckStyle.attack);
    expect(CardDef.byId(attack.first).type, CardType.attack);
    final study = DeckBuilder.preset(owned, DeckStyle.study);
    expect(CardDef.byId(study.first).type, CardType.study);
    final p = RpgProgress.initial.copyWith(deck: owned, activeDeck: study);
    expect(p.battleDeck, study);
    expect(RpgProgress.fromMap(p.toMap()).activeDeck, study);
    // 持っていないカードは、デッキに入れていてもバトルには出ない
    expect(
      RpgProgress.initial.copyWith(activeDeck: ['gamble']).battleDeck,
      RpgProgress.starterDeck,
    );
  });
}
