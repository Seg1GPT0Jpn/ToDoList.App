import 'dart:math';

import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/question.dart';
import '../models/question_format.dart';
import '../progression/mastery.dart';
import '../story/gear.dart';
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
    this.guardBroken = false,
    this.disrupted = false,
    this.bossBurst = false,
    this.trialResult,
    this.enemyHealed = 0,
    this.comboKept = false,
    this.defeated,
    this.joined,
    this.backDamage = 0,
    this.special = false,
    this.specialMissed = false,
    this.challenge = false,
    this.deepThought = false,
    this.credit = 0,
  });

  /// 得点の割合（正解なら1。4択以外の問題では部分点のこともある）
  final double credit;

  /// 部分点（まちがいだが、半分以上は合っていた）
  bool get partial => !correct && credit >= BattleEngine.partialCreditMin;

  /// 苦手な単元の問題に正解した（苦手への挑戦ボーナス）
  final bool challenge;

  /// 思考レベル4以上の問題に正解した（難問ボーナス）
  final bool deepThought;

  /// 必殺技が決まった
  final bool special;

  /// 必殺技を構えていたのに、まちがえて空振りした
  final bool specialMissed;

  /// ボスの連戦で、このターンに倒したボス（まだ次のボスが残っているとき）
  final EnemyDef? defeated;

  /// ボスの連戦で、このターンに乱入してきたボス
  final EnemyDef? joined;

  /// 後ろのボスから受けたダメージ（[damageToPlayer] にふくまれる）
  final int backDamage;

  /// 防御型の守りがこのターンで解けた
  final bool guardBroken;

  /// 妨害型の力で、次の問題がむずかしくなった
  final bool disrupted;

  /// ボスの特別ルールで大ダメージ（3連続正解・試練の合格）
  final bool bossBurst;

  /// 試練（5問ごとの判定）の結果。判定したターンだけ true / false
  final bool? trialResult;

  /// ボスが回復した量（試練に失敗したとき）
  final int enemyHealed;

  /// むすびの栞でチェインが切れなかった
  final bool comboKept;

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
    required EnemyDef enemy,
    required List<QuizQuestion> questions,
    List<EnemyDef> reinforcements = const [],
    this.overlapRate = 0.5,
    required this.timeLimit,
    this.readingTimeLimit,
    List<CardDef> deck = const [],
    this.companions = const {},
    this.bonusHpRate = 0,
    this.handSize = 3,
    this.bossRule = BossRule.none,
    this.trialWindow = 5,
    this.trialNeed = 4,
    this.bonus = BattleBonus.none,
    Random? random,
    DamageCalculator? damage,
    double Function(QuizQuestion)? questionWeight,
    this.weakUnits = const {},
  })  : _random = random ?? Random(),
        _weight = questionWeight,
        _deck = QuestionDeck(questions, random: random, weight: questionWeight),
        _damage = damage ?? DamageCalculator(random: random),
        _armor = enemy.armor,
        lineup = List.unmodifiable([enemy, ...reinforcements]) {
    _hps = [for (final e in lineup) e.maxHp];
    maxHp = (player.maxHp * (1 + bonusHpRate)).round();
    _playerHp = maxHp;
    _drawPile.addAll(deck);
    _drawPile.shuffle(_random);
    while (_hand.length < handSize && _drawPile.isNotEmpty) {
      _hand.add(_drawPile.removeLast());
    }
    _categories = {for (final q in questions) q.category};
    _current = _nextQuestion();
  }

  /// 次の問題を引く。能力・カード・ボスのルールで、引き方が変わる
  PresentedQuestion _nextQuestion() {
    final focusCat = finaleFocus;
    final w = _weight;
    if (_disruptNext) {
      _disruptNext = false;
      // 妨害：苦手な問題・長い問題ほど先に出る
      return _deck.drawPreferred(
        (q) =>
            (w?.call(q) ?? 1) * 2 +
            (q.prompt.length + (q.sentence?.length ?? 0)) / 60,
      );
    }
    if (focusCat != null) {
      return _deck.drawPreferred(
        (q) => (q.category == focusCat ? 10 : 0) + (w?.call(q) ?? 1),
      );
    }
    if (_focus && w != null) return _deck.drawPreferred(w);
    return _deck.draw();
  }

  final PlayerStats player;

  /// 戦う相手の並び（ボスの連戦なら2体以上）。先頭から順に前へ出てくる
  final List<EnemyDef> lineup;

  /// 前のボスの HP がこの割合まで減ると、次のボスが乱入してくる（ボスが重なる）
  final double overlapRate;

  /// いま前に出ている敵
  EnemyDef get enemy => lineup[_front];

  /// 前に出ている敵の番号（0始まり）
  int get front => _front;
  int _front = 0;

  /// 戦いに加わった敵の数（前の敵をふくむ）
  int get joinedCount => _joined;
  int _joined = 1;

  /// 前の敵の後ろに控えている（乱入してきた）敵。いなければ null
  EnemyDef? get backEnemy => _joined > _front + 1 ? lineup[_front + 1] : null;

  /// 後ろの敵の HP
  int get backEnemyHp => backEnemy == null ? 0 : _hps[_front + 1];

  /// 倒した敵の数
  int get defeatedCount => _phase == BattlePhase.won ? lineup.length : _front;

  late final List<int> _hps;
  final Duration timeLimit;

  /// 長文読解の設問の制限時間（未指定なら [timeLimit]）
  final Duration? readingTimeLimit;

  /// 仲間の常時効果
  final Set<CompanionEffect> companions;

  /// ボス戦の特別ルール
  final BossRule bossRule;

  /// 装備と職業の補正
  final BattleBonus bonus;

  /// 苦手な単元（単元か小単元の ID）。その問題に正解するとダメージが増える
  final Set<String> weakUnits;

  /// 試練（[BossRule.trial]）：何問ごとに判定するか、何問正解が必要か
  final int trialWindow;
  final int trialNeed;

  /// 敵の特殊能力
  EnemyAbility get ability => enemy.effectiveAbility;

  final double Function(QuizQuestion)? _weight;

  /// 防御型の守りが残っているか
  bool get guardUp => ability == EnemyAbility.guard && !_guardBroken;
  bool _guardBroken = false;

  /// 苦手の地図を使ったか（このバトルの間、苦手な問題が出やすい）
  bool get focusActive => _focus;
  bool _focus = false;

  /// 妨害型の力で、次の問題がむずかしくなるか
  bool _disruptNext = false;

  /// 試練の、いまの区切りでの回答数と正解数
  int get trialAnswered => _trialAnswered;
  int get trialCorrect => _trialCorrect;
  int _trialAnswered = 0;
  int _trialCorrect = 0;

  /// ラスボスの出題の中心（HPが減るごとに変わる）。null なら総合
  QuestionCategory? get finaleFocus {
    if (bossRule != BossRule.finale) return null;
    final rate = _enemyHp / enemy.maxHp;
    final order = [
      if (_categories.contains(QuestionCategory.reading))
        QuestionCategory.reading,
      if (_categories.contains(QuestionCategory.usage)) QuestionCategory.usage,
      for (final c in const [
        QuestionCategory.meaning,
        QuestionCategory.knowledge,
        QuestionCategory.calculation,
        QuestionCategory.thinking,
      ])
        if (_categories.contains(c)) c,
    ];
    if (order.isEmpty) return null;
    final phase = rate > 0.75
        ? 0
        : rate > 0.5
            ? 1
            : rate > 0.25
                ? 2
                : 3;
    return phase >= order.length || phase == 3 ? null : order[phase];
  }

  late final Set<QuestionCategory> _categories;

  /// 後ろのボスの攻撃の強さ（前のボスに対する割合）
  static const backAttackRate = 0.5;

  /// 必殺技のダメージ倍率
  static const specialRate = 2.5;

  /// 正解でたまる必殺技ゲージ（すばやい正解はもっとたまる）
  static const specialGain = 20;
  static const specialQuickGain = 30;

  /// 必殺技ゲージ（0〜100）。100 で必殺技を構えられる
  int get special => _special;
  int _special = 0;

  /// 必殺技を構えられるか
  bool get specialReady => _special >= 100 && !_specialArmed && !isOver;

  /// 必殺技を構えている（次の正解が必殺技になる）
  bool get specialArmed => _specialArmed;
  bool _specialArmed = false;

  /// 必殺技を構える（次の問題に正解すると、ダメージが [specialRate] 倍）
  void armSpecial() {
    _ensureActive();
    if (!specialReady) throw StateError('必殺技ゲージがたまっていません');
    _specialArmed = true;
  }

  /// 泉の加護などで増える最大HPの割合（0.3 なら +30%）
  final double bonusHpRate;
  final int handSize;

  final Random _random;
  final QuestionDeck _deck;
  final DamageCalculator _damage;
  late final int maxHp;

  late int _playerHp;
  int get _enemyHp => _hps[_front];
  set _enemyHp(int v) => _hps[_front] = v;
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
    // 答え方に手間がかかる形式ほど長くする（入力・リスニング・並べ替え・記述など）
    limit = limit * formatTimeFactor(q.source);
    if (companions.contains(CompanionEffect.moreTime)) {
      limit += const Duration(seconds: 3);
    }
    limit += Duration(seconds: bonus.extraSeconds);
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

  /// 出題形式による制限時間の倍率
  static double formatTimeFactor(QuizQuestion q) => switch (q.format) {
        QuestionFormat.choice => q.isInput || q.listen ? 2 : 1,
        QuestionFormat.trueFalse => 1,
        QuestionFormat.multiSelect => 1.5,
        QuestionFormat.order || QuestionFormat.numeric => 2,
        QuestionFormat.cloze => 1.0 + q.cloze!.blanks.length,
        QuestionFormat.multiStep => 1.0 * q.subQuestions.length,
        QuestionFormat.written => 6,
      };

  /// 4択以外の問題（正誤・並べ替え・記述など）を、採点した結果で回答する。
  /// まちがいでも部分点が半分以上あれば、少しだけダメージを与え、受けるダメージも半分になる。
  TurnResult answerGraded(Grade grade, {required Duration elapsed}) {
    _ensureActive();
    if (elapsed > limitFor(_current)) return timeout();
    return _resolve(choiceIndex: null, elapsed: elapsed, graded: grade);
  }

  /// 部分点でダメージを与えるのに必要な割合と、そのときのダメージの割合
  static const partialCreditMin = 0.5;
  static const partialDamageRate = 0.5;

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

  TurnResult _resolve({
    required int? choiceIndex,
    required Duration elapsed,
    Grade? graded,
  }) {
    final q = _current;
    final card = _pending;
    final effect = card?.effect;
    final correct =
        graded?.correct ?? (choiceIndex != null && q.isCorrect(choiceIndex));
    final partial =
        !correct && graded != null && graded.credit >= partialCreditMin;
    var toEnemy = 0;
    var toPlayer = 0;
    var quick = false;
    var weakness = false;
    var blocked = false;
    var armorBroken = false;
    var guarded = false;
    var healed = 0;
    var survived = false;
    var guardBroken = false;
    var disrupted = false;
    var bossBurst = false;
    bool? trialResult;
    var enemyHealed = 0;
    var comboKept = false;
    var backDamage = 0;
    var specialHit = false;
    var specialMissed = false;
    var challenge = false;
    var deepThought = false;
    EnemyDef? defeated;
    EnemyDef? joined;
    final focusCat = finaleFocus;
    if (effect == CardEffect.focus) _focus = true;

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
      extra *= bonus.attackRate;
      if (_combo >= 3) extra *= 1 + bonus.chainBonus;
      if (_armor > 0) {
        if (category == enemy.armorCategory) {
          _armor--;
          armorBroken = _armor == 0;
        } else {
          blocked = true;
          extra *= DamageCalculator.blockedRate;
        }
      }
      final hitsWeakness = enemy.weakness != null && category == enemy.weakness;
      if (!blocked && hitsWeakness) {
        weakness = true;
        extra *= (ability == EnemyAbility.specialist
                ? 2.5
                : DamageCalculator.weaknessRate) +
            bonus.weaknessBonus;
      }
      if (effect == CardEffect.focus) extra *= 1.3;
      // 学びのボーナス：難しい問題・苦手な単元への挑戦ほど有利
      final thinking = LearningBonus.thinkingRate(q.source);
      if (thinking > 1) {
        extra *= thinking;
        deepThought = true;
      }
      if (LearningBonus.isWeak(q.source, weakUnits)) {
        extra *= LearningBonus.weakRate;
        challenge = true;
      }
      if (_specialArmed) {
        extra *= specialRate;
        specialHit = true;
        _specialArmed = false;
        _special = 0;
      } else {
        _special =
            min(100, _special + (quick ? specialQuickGain : specialGain));
      }
      // 敵の能力
      switch (ability) {
        case EnemyAbility.guard:
          if (!_guardBroken) {
            if (hitsWeakness) {
              _guardBroken = true;
              guardBroken = true;
            } else {
              extra *= 0.5;
            }
          }
        case EnemyAbility.combo:
          extra *= min(3.0, 0.5 + 0.4 * (_combo - 1));
        case EnemyAbility.specialist:
          if (!hitsWeakness) extra *= 0.6;
        case EnemyAbility.sturdy:
          extra *= 0.85;
        case EnemyAbility.chainLock:
          if (_combo < 2) extra *= 0.5;
        case EnemyAbility.disrupt || EnemyAbility.none:
          break;
      }
      // ボスのルール
      switch (bossRule) {
        case BossRule.chain3:
          if (_combo % 3 == 0) {
            extra *= 2.5;
            bossBurst = true;
          }
        case BossRule.trial:
          extra *= 0.7;
        case BossRule.finale:
          if (focusCat != null && category != focusCat) extra *= 0.5;
        case BossRule.none:
          break;
      }
      toEnemy = _damage.playerAttack(
        attack: player.attack + bonus.attack,
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
      if (effect == CardEffect.keep) {
        comboKept = true;
      } else {
        _combo = 0;
      }
      if (_specialArmed) {
        // 構えていた必殺技は空振り。ゲージはなくなる
        _specialArmed = false;
        _special = 0;
        specialMissed = true;
      }
      if (ability == EnemyAbility.disrupt) {
        _disruptNext = true;
        disrupted = true;
      }
      if (partial) {
        // 部分点：考え方の一部は合っていた。小さなダメージを与える
        toEnemy = _damage.playerAttack(
          attack: player.attack + bonus.attack,
          combo: 1,
          elapsed: limitFor(q),
          timeLimit: limitFor(q),
          extra: bonus.attackRate * graded.credit * partialDamageRate,
        );
        _enemyHp = max(0, _enemyHp - toEnemy);
      }
      if (effect == CardEffect.guard) {
        guarded = true;
      } else {
        var extra = partial ? 0.5 : 1.0;
        if (effect == CardEffect.power) extra *= 1.5;
        if (effect == CardEffect.gamble) extra *= 2;
        if (companions.contains(CompanionEffect.defenseUp)) extra *= 0.85;
        extra *= bonus.damageTakenRate;
        toPlayer = _damage.enemyAttack(
            attack: enemy.attack,
            defense: player.defense + bonus.defense,
            extra: extra);
        // 乱入してきた後ろのボスも、少し弱めに攻撃してくる
        final back = backEnemy;
        if (back != null) {
          backDamage = _damage.enemyAttack(
              attack: back.attack,
              defense: player.defense + bonus.defense,
              extra: extra * backAttackRate);
          toPlayer += backDamage;
        }
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

    // 試練：区切りごとに判定する
    if (bossRule == BossRule.trial && _enemyHp > 0) {
      _trialAnswered++;
      if (correct) _trialCorrect++;
      if (_trialAnswered >= trialWindow) {
        trialResult = _trialCorrect >= trialNeed;
        if (trialResult) {
          final burst = (enemy.maxHp * 0.25).round();
          toEnemy += burst;
          _enemyHp = max(0, _enemyHp - burst);
          bossBurst = true;
        } else {
          enemyHealed =
              min(enemy.maxHp - _enemyHp, (enemy.maxHp * 0.06).round());
          _enemyHp += enemyHealed;
        }
        _trialAnswered = 0;
        _trialCorrect = 0;
      }
    }

    if (_enemyHp == 0 && _front + 1 < lineup.length) {
      // ボスの連戦：次のボスが前に出てくる（HP は引き継ぐ）
      defeated = enemy;
      _front++;
      if (_joined < _front + 1) {
        _joined = _front + 1;
        joined = enemy;
      }
      _armor = enemy.armor;
      _guardBroken = false;
      _disruptNext = false;
      _trialAnswered = 0;
      _trialCorrect = 0;
    }
    if (_enemyHp == 0) {
      _phase = BattlePhase.won;
    } else if (_playerHp == 0) {
      _phase = BattlePhase.lost;
    } else if (_joined == _front + 1 &&
        _joined < lineup.length &&
        _enemyHp <= enemy.maxHp * overlapRate) {
      // 前のボスが弱ってきたら、次のボスが乱入する（ボスが重なる）
      joined = lineup[_joined];
      _joined++;
    }

    final result = TurnResult(
      question: q,
      chosenIndex: choiceIndex,
      correct: correct,
      timedOut: choiceIndex == null && graded == null,
      credit: correct ? 1 : (graded?.credit ?? 0),
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
      guardBroken: guardBroken,
      disrupted: disrupted,
      bossBurst: bossBurst,
      trialResult: trialResult,
      enemyHealed: enemyHealed,
      comboKept: comboKept,
      defeated: defeated,
      joined: joined,
      backDamage: backDamage,
      special: specialHit,
      specialMissed: specialMissed,
      challenge: challenge,
      deepThought: deepThought,
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

    if (!isOver) _current = _nextQuestion();
    return result;
  }

  void _ensureActive() {
    if (isOver) throw StateError('バトルはすでに終了しています（$_phase）');
  }
}
