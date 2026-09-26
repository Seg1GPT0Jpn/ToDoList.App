import 'dart:math';

import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/question.dart';
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
  });

  final PresentedQuestion question;

  /// 選んだ選択肢（時間切れなら null）
  final int? chosenIndex;
  final bool correct;
  final bool timedOut;
  final bool quick;
  final int damageToEnemy;
  final int damageToPlayer;

  /// このターン後の連続正解数
  final int combo;
  final int enemyHp;
  final int playerHp;
  final BattlePhase phase;
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
}

/// ターン制クイズバトルの状態機械。
///
/// 使い方:
/// 1. [currentQuestion] を表示し、タイマーを開始する
/// 2. 回答したら [answer]、制限時間を過ぎたら [timeout] を呼ぶ
/// 3. [phase] が won / lost になったら [summary] を結果画面へ渡す
class BattleEngine {
  BattleEngine({
    required this.player,
    required this.enemy,
    required List<QuizQuestion> questions,
    required this.timeLimit,
    Random? random,
    DamageCalculator? damage,
  })  : _deck = QuestionDeck(questions, random: random),
        _damage = damage ?? DamageCalculator(random: random),
        _playerHp = player.maxHp,
        _enemyHp = enemy.maxHp {
    _current = _deck.draw();
  }

  final PlayerStats player;
  final EnemyDef enemy;
  final Duration timeLimit;
  final QuestionDeck _deck;
  final DamageCalculator _damage;

  int _playerHp;
  int _enemyHp;
  int _combo = 0;
  int _maxCombo = 0;
  int _correct = 0;
  BattlePhase _phase = BattlePhase.awaitingAnswer;
  late PresentedQuestion _current;
  final List<TurnResult> _turns = [];

  int get playerHp => _playerHp;
  int get enemyHp => _enemyHp;
  int get combo => _combo;
  BattlePhase get phase => _phase;
  bool get isOver => _phase != BattlePhase.awaitingAnswer;
  List<TurnResult> get turns => List.unmodifiable(_turns);

  /// いま出題中の問題。バトル終了後は最後に出した問題のまま。
  PresentedQuestion get currentQuestion => _current;

  /// 選択肢 [choiceIndex] で回答する。[elapsed] は出題からの経過時間。
  TurnResult answer(int choiceIndex, {required Duration elapsed}) {
    _ensureActive();
    if (choiceIndex < 0 || choiceIndex >= _current.choices.length) {
      throw RangeError.index(choiceIndex, _current.choices, 'choiceIndex');
    }
    if (elapsed > timeLimit) return timeout();
    return _resolve(choiceIndex: choiceIndex, elapsed: elapsed);
  }

  /// 制限時間切れ。不正解と同じく敵の反撃を受ける。
  TurnResult timeout() {
    _ensureActive();
    return _resolve(choiceIndex: null, elapsed: timeLimit);
  }

  BattleSummary summary() => BattleSummary(
        won: _phase == BattlePhase.won,
        correctCount: _correct,
        answeredCount: _turns.length,
        maxCombo: _maxCombo,
        remainingHp: _playerHp,
        maxHp: player.maxHp,
        turns: turns,
      );

  TurnResult _resolve({required int? choiceIndex, required Duration elapsed}) {
    final q = _current;
    final correct = choiceIndex != null && q.isCorrect(choiceIndex);
    var toEnemy = 0;
    var toPlayer = 0;
    var quick = false;

    if (correct) {
      _combo++;
      _correct++;
      _maxCombo = max(_maxCombo, _combo);
      quick = _damage.isQuick(elapsed, timeLimit);
      toEnemy = _damage.playerAttack(
        attack: player.attack,
        combo: _combo,
        elapsed: elapsed,
        timeLimit: timeLimit,
      );
      _enemyHp = max(0, _enemyHp - toEnemy);
    } else {
      _combo = 0;
      toPlayer =
          _damage.enemyAttack(attack: enemy.attack, defense: player.defense);
      _playerHp = max(0, _playerHp - toPlayer);
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
      quick: quick,
      damageToEnemy: toEnemy,
      damageToPlayer: toPlayer,
      combo: _combo,
      enemyHp: _enemyHp,
      playerHp: _playerHp,
      phase: _phase,
    );
    _turns.add(result);
    if (!isOver) _current = _deck.draw();
    return result;
  }

  void _ensureActive() {
    if (isOver) throw StateError('バトルはすでに終了しています（$_phase）');
  }
}
