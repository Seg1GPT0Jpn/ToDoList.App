import 'dart:math';

import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/question.dart';
import 'cards.dart';
import 'damage_calculator.dart';
import 'question_deck.dart';

enum BattlePhase {
  /// 回答待ち
  awaitingAnswer,

  /// 勝利（敵のHPが0）
  won,

  /// 敗北（プレイヤーのHPが0）
  lost,
}

/// 1ターン（1問）の結果。UI はこれを見て演出を出す。
class TurnResult {
  const TurnResult({
    required this.question,
    required this.chosenIndex,
    required this.correct,
    required this.timedOut,
    required this.quick,
    required this.damageToEnemy,
    required this.damageToPlayer,
    required this.combo,
    required this.enemyHp,
    required this.playerHp,
    required this.phase,
    this.weakness = false,
    this.blocked = false,
    this.armorBroken = false,
    this.guarded = false,
    this.healed = 0,
    this.card,
    this.survived = false,
  });

  final PresentedQuestion question;

  /// 選んだ選択肢（時間切れなら null）
  final int? chosenIndex;
  final bool correct;
  final bool timedOut;

  /// クリティカル（すばやい回答、または会心のペン）
  final bool quick;
  final int damageToEnemy;
  final int damageToPlayer;

  /// このターン後の連続正解数（チェイン）
  final int combo;
  final int enemyHp;
  final int playerHp;
  final BattlePhase phase;

  /// 弱点を突いた
  final bool weakness;

  /// 装甲にはじかれた
  final bool blocked;

  /// このターンで装甲が割れた
  final bool armorBroken;

  /// 守りの辞書でダメージを防いだ
  final bool guarded;

  /// 回復の詩で回復した量
  final int healed;

  /// このターンに使ったカード
  final CardDef? card;

  /// ねこ先生のおかげで HP1 で耐えた
  final bool survived;
}

/// バトル終了時の集計。経験値計算や結果画面に使う。
class BattleSummary {
  const BattleSummary({
    required this.won,
    required this.correctCount,
    required this.answeredCount,
    required this.maxCombo,
    required this.remainingHp,
    required this.maxHp,
    required this.turns,
  });

  final bool won;
  final int correctCount;
  final int answeredCount;
  final int maxCombo;
  final int remainingHp;
  final int maxHp;
  final List<TurnResult> turns;

  double get accuracy => answeredCount == 0 ? 0 : correctCount / answeredCount;

  /// ノーミス勝利
  bool get isPerfect => won && correctCount == answeredCount;

  /// 復習用：間違えた問題（重複なし）
  List<QuizQuestion> get missedQuestions {
    final seen = <String>{};
    return [
      for (final t in turns)
        if (!t.correct && seen.add(t.question.source.id)) t.question.source,
    ];
  }

  /// 正解した問題の ID
  Set<String> get correctIds => {
        for (final t in turns)
          if (t.correct) t.question.source.id,
      };
}

/// ターン制クイズバトルの状態機械。
///
/// 使い方:
/// 1. [currentQuestion] を表示し、タイマーを開始する（制限時間は [limitFor]）
/// 2. 必要なら [useCard] で手札を1枚使う
/// 3. 回答したら [answer]、制限時間を過ぎたら [timeout] を呼ぶ
/// 4. [phase] が won / lost になったら [summary] を結果画面へ渡す
class BattleEngine {
  BattleEngine({
    required this.player,
    required this.enemy,
    required List<QuizQuestion> questions,
    required this.timeLimit,
    this.readingTimeLimit,
    List<CardDef> deck = const [],
    this.companions = const {},
    this.bonusHpRate = 0,
    this.handSize = 3,
    Random? random,
    DamageCalculator? damage,
  })  : _random = random ?? Random(),
        _deck = QuestionDeck(questions, random: random),
        _damage = damage ?? DamageCalculator(random: random),
        _armor = enemy.armor,
        _enemyHp = enemy.maxHp {
    maxHp = (player.maxHp * (1 + bonusHpRate)).round();
    _playerHp = maxHp;
    _drawPile.addAll(deck);
    _drawPile.shuffle(_random);
    while (_hand.length < handSize && _drawPile.isNotEmpty) {
      _hand.add(_drawPile.removeLast());
    }
    _current = _deck.draw();
  }

  final PlayerStats player;
  final EnemyDef enemy;
  final Duration timeLimit;

  /// 長文読解の設問の制限時間（未指定なら [timeLimit]）
  final Duration? readingTimeLimit;

  /// 仲間の常時効果
  final Set<CompanionEffect> companions;

  /// 泉の加護などで増える最大HPの割合（0.3 なら +30%）
  final double bonusHpRate;
  final int handSize;

  final Random _random;
  final QuestionDeck _deck;
  final DamageCalculator _damage;
  late final int maxHp;

  late int _playerHp;
  int _enemyHp;
  int _armor;
  int _combo = 0;
  int _maxCombo = 0;
  int _correct = 0;
  bool _lastStandUsed = false;
  BattlePhase _phase = BattlePhase.awaitingAnswer;
  late PresentedQuestion _current;
  final List<TurnResult> _turns = [];

  final List<CardDef> _hand = [];
  final List<CardDef> _drawPile = [];
  final List<CardDef> _discard = [];
  CardDef? _pending;

  int get playerHp => _playerHp;
  int get enemyHp => _enemyHp;
  int get combo => _combo;

  /// 残りの装甲
  int get armor => _armor;
  BattlePhase get phase => _phase;
  bool get isOver => _phase != BattlePhase.awaitingAnswer;
  List<TurnResult> get turns => List.unmodifiable(_turns);

  /// 手札
  List<CardDef> get hand => List.unmodifiable(_hand);

  /// この問題に使ったカード（1問に1枚まで）
  CardDef? get pendingCard => _pending;

  /// いま出題中の問題。バトル終了後は最後に出した問題のまま。
  PresentedQuestion get currentQuestion => _current;

  /// その問題の制限時間（長文・時の砂・時計うさぎを反映）
  Duration limitFor(PresentedQuestion q) {
    var limit =
        q.source.passage != null ? (readingTimeLimit ?? timeLimit) : timeLimit;
    if (companions.contains(CompanionEffect.moreTime)) {
      limit += const Duration(seconds: 3);
    }
    if (identical(q, _current) && _pending?.effect == CardEffect.time) {
      limit += const Duration(seconds: 10);
    }
    return limit;
  }

  /// ひらめきの栞で消した選択肢（今の問題）
  Set<int> hiddenChoices = {};

  /// 手札の [index] 番目のカードを使う（次の回答に効果がつく）。
  CardDef useCard(int index) {
    _ensureActive();
    if (_pending != null) throw StateError('この問題ではもうカードを使っています');
    final card = _hand.removeAt(index);
    _pending = card;
    if (card.effect == CardEffect.hint) {
      final wrong = [
        for (var i = 0; i < _current.choices.length; i++)
          if (i != _current.correctIndex) i,
      ]..shuffle(_random);
      hiddenChoices = wrong.take(2).toSet();
    }
    return card;
  }

  /// 選択肢 [choiceIndex] で回答する。[elapsed] は出題からの経過時間。
  TurnResult answer(int choiceIndex, {required Duration elapsed}) {
    _ensureActive();
    if (choiceIndex < 0 || choiceIndex >= _current.choices.length) {
      throw RangeError.index(choiceIndex, _current.choices, 'choiceIndex');
    }
    if (elapsed > limitFor(_current)) return timeout();
    return _resolve(choiceIndex: choiceIndex, elapsed: elapsed);
  }

  /// 制限時間切れ。不正解と同じく敵の反撃を受ける。
  TurnResult timeout() {
    _ensureActive();
    return _resolve(choiceIndex: null, elapsed: limitFor(_current));
  }

  BattleSummary summary() => BattleSummary(
        won: _phase == BattlePhase.won,
        correctCount: _correct,
        answeredCount: _turns.length,
        maxCombo: _maxCombo,
        remainingHp: _playerHp,
        maxHp: maxHp,
        turns: turns,
      );

  TurnResult _resolve({required int? choiceIndex, required Duration elapsed}) {
    final q = _current;
    final card = _pending;
    final effect = card?.effect;
    final correct = choiceIndex != null && q.isCorrect(choiceIndex);
    var toEnemy = 0;
    var toPlayer = 0;
    var quick = false;
    var weakness = false;
    var blocked = false;
    var armorBroken = false;
    var guarded = false;
    var healed = 0;
    var survived = false;

    if (correct) {
      _combo += effect == CardEffect.chain ? 3 : 1;
      _correct++;
      _maxCombo = max(_maxCombo, _combo);
      final category = q.source.category;
      final forceCritical = effect == CardEffect.critical;
      quick = forceCritical || _damage.isQuick(elapsed, limitFor(q));
      var extra = 1.0;
      if (effect == CardEffect.power) extra *= 2;
      if (effect == CardEffect.gamble) extra *= 3;
      if (companions.contains(CompanionEffect.attackUp)) extra *= 1.1;
      if (_armor > 0) {
        if (category == enemy.armorCategory) {
          _armor--;
          armorBroken = _armor == 0;
        } else {
          blocked = true;
          extra *= DamageCalculator.blockedRate;
        }
      }
      if (!blocked && enemy.weakness != null && category == enemy.weakness) {
        weakness = true;
        extra *= DamageCalculator.weaknessRate;
      }
      toEnemy = _damage.playerAttack(
        attack: player.attack,
        combo: _combo,
        elapsed: elapsed,
        timeLimit: limitFor(q),
        forceCritical: forceCritical,
        extra: extra,
      );
      _enemyHp = max(0, _enemyHp - toEnemy);
      if (effect == CardEffect.heal) {
        healed = min(maxHp - _playerHp, (maxHp * 0.3).round());
        _playerHp += healed;
      }
    } else {
      _combo = 0;
      if (effect == CardEffect.guard) {
        guarded = true;
      } else {
        var extra = 1.0;
        if (effect == CardEffect.power) extra *= 1.5;
        if (effect == CardEffect.gamble) extra *= 2;
        if (companions.contains(CompanionEffect.defenseUp)) extra *= 0.85;
        toPlayer = _damage.enemyAttack(
            attack: enemy.attack, defense: player.defense, extra: extra);
        if (toPlayer >= _playerHp &&
            companions.contains(CompanionEffect.lastStand) &&
            !_lastStandUsed) {
          _lastStandUsed = true;
          survived = true;
          toPlayer = _playerHp - 1;
        }
        _playerHp = max(0, _playerHp - toPlayer);
      }
    }

    if (_enemyHp == 0) {
      _phase = BattlePhase.won;
    } else if (_playerHp == 0) {
      _phase = BattlePhase.lost;
    }

    final result = TurnResult(
      question: q,
      chosenIndex: choiceIndex,
      correct: correct,
      timedOut: choiceIndex == null,
      quick: correct && quick,
      damageToEnemy: toEnemy,
      damageToPlayer: toPlayer,
      combo: _combo,
      enemyHp: _enemyHp,
      playerHp: _playerHp,
      phase: _phase,
      weakness: weakness,
      blocked: blocked,
      armorBroken: armorBroken,
      guarded: guarded,
      healed: healed,
      card: card,
      survived: survived,
    );
    _turns.add(result);

    // 使ったカードは捨て札へ。手札を補充する（山札が切れたら捨て札を混ぜ直す）
    if (card != null) {
      _discard.add(card);
      _pending = null;
    }
    hiddenChoices = {};
    while (_hand.length < handSize) {
      if (_drawPile.isEmpty) {
        if (_discard.isEmpty) break;
        _drawPile.addAll(_discard..shuffle(_random));
        _discard.clear();
      }
      _hand.add(_drawPile.removeLast());
    }

    if (!isOver) _current = _deck.draw();
    return result;
  }

  void _ensureActive() {
    if (isOver) throw StateError('バトルはすでに終了しています（$_phase）');
  }
}
