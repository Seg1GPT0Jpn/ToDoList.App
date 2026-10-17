import 'package:rpg_game/rpg_game.dart';

/// フィールドの上で戦うバトル（つづりクエスト3D）。
///
/// 出題・採点・ダメージの計算は 2D 版と同じ [BattleEngine] に任せ、
/// 「正解したら剣（えんぴつ）をふって当てる」という流れだけをここで持つ。
/// 描画に依存しないので、単体テストできる。
///
/// 1問の流れ：
/// 1. [FieldBattlePhase.asking] 問題に答える（制限時間あり）
/// 2. 正解 → [FieldBattlePhase.swing] [swingWindow] のあいだに剣をふって当てる
///    - 当たった → 正解として攻撃（答えてから当てるまでが速いほどクリティカル）
///    - 時間切れ → ふり遅れ。部分点（ダメージ半分）
///    不正解・時間切れ → 敵の反撃
/// 3. [FieldBattlePhase.feedback] 結果を見せてから次の問題へ（[next]）
enum FieldBattlePhase { asking, swing, feedback, won, lost }

class FieldBattle {
  FieldBattle(this.engine);

  final BattleEngine engine;

  /// 正解してから剣をふれる時間
  static const swingWindow = Duration(seconds: 4);

  /// 剣が届く距離（メートル）
  static const reach = 2.4;

  FieldBattlePhase _phase = FieldBattlePhase.asking;
  FieldBattlePhase get phase => _phase;

  int? _chosen;
  Duration _answeredAt = Duration.zero;

  /// 直前の1ターンの結果（feedback のあいだだけ）
  TurnResult? last;

  /// ふり遅れ（部分点）だったか
  bool lastWasLate = false;

  PresentedQuestion get question => engine.currentQuestion;
  Duration get limit => engine.limitFor(question);
  bool get isOver =>
      _phase == FieldBattlePhase.won || _phase == FieldBattlePhase.lost;

  /// 選択肢を選ぶ。正解なら true（剣をふる時間になる）
  bool choose(int index, Duration elapsed) {
    if (_phase != FieldBattlePhase.asking) return false;
    if (elapsed >= limit) {
      timeout();
      return false;
    }
    if (question.isCorrect(index)) {
      _chosen = index;
      _answeredAt = elapsed;
      _phase = FieldBattlePhase.swing;
      return true;
    }
    _resolve(engine.answer(index, elapsed: elapsed));
    return false;
  }

  /// 問題の制限時間切れ（敵の反撃）
  void timeout() {
    if (_phase != FieldBattlePhase.asking) return;
    _resolve(engine.timeout());
  }

  /// 剣が当たった。[swingDelay] は正解してから当てるまでの時間
  TurnResult hit(Duration swingDelay) {
    if (_phase != FieldBattlePhase.swing) {
      throw StateError('剣をふれるのは正解したあとだけ');
    }
    var at = _answeredAt + swingDelay;
    final latest = limit - const Duration(milliseconds: 1);
    if (at > latest) at = latest;
    lastWasLate = false;
    return _resolve(engine.answer(_chosen!, elapsed: at));
  }

  /// 剣をふる時間が切れた（ふり遅れ：ダメージ半分）
  TurnResult late() {
    if (_phase != FieldBattlePhase.swing) {
      throw StateError('剣をふれるのは正解したあとだけ');
    }
    lastWasLate = true;
    return _resolve(
      engine.answerGraded(
        const Grade(credit: BattleEngine.partialCreditMin, correct: false),
        elapsed: _answeredAt,
      ),
    );
  }

  TurnResult _resolve(TurnResult r) {
    last = r;
    _phase = FieldBattlePhase.feedback;
    return r;
  }

  /// 結果を見せ終わったら次へ（勝ち負けが決まっていれば終わり）
  void next() {
    if (_phase != FieldBattlePhase.feedback) return;
    last = null;
    lastWasLate = false;
    _phase = switch (engine.phase) {
      BattlePhase.won => FieldBattlePhase.won,
      BattlePhase.lost || BattlePhase.escaped => FieldBattlePhase.lost,
      BattlePhase.awaitingAnswer => FieldBattlePhase.asking,
    };
  }

  BattleSummary summary() => engine.summary();
}
