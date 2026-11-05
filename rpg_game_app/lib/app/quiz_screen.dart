import 'package:flutter/widgets.dart';
import 'package:rpg_game/rpg_game.dart';

import '../battle/battle_screen.dart';
import '../study/study_quiz_screen.dart';
import 'edition.dart';

/// 問題を解く画面。フル版は魔物とのバトル、つづりクエストLight はバトルなしの学習（[StudyQuizScreen]）。
///
/// [title] は Light の画面の題（なければ単元の名前）。
/// Light のビルドでは [lightEdition] が const なので、バトルの画面のプログラムは入らない。
Widget quizScreen({
  String? title,
  required WorldDef world,
  required StageDef stage,
  required List<QuizQuestion> questions,
  required RpgProgress progress,
  bool trial = false,
  BattleMode? mode,
  void Function(BattleSummary summary)? onFinished,
}) {
  if (lightEdition) {
    return StudyQuizScreen(
      title: title ?? stage.name,
      subject: world.id,
      questions: questions,
      // 確認用（その場で作った問題など）は学習記録に残さない（バトルと同じ）
      record: mode != BattleMode.trial,
      onFinished: onFinished == null
          ? null
          : (correct, answered) =>
                onFinished(studySummary(correct: correct, answered: answered)),
    );
  }
  return BattleScreen(
    world: world,
    stage: stage,
    questions: questions,
    progress: progress,
    trial: trial,
    mode: mode,
    onFinished: onFinished,
  );
}

/// 学習の結果を、バトルの結果と同じ形にする（正答率の自己ベストや、試験対策の進み具合に使う）。
/// 6割以上正解したら「勝ち」（つぎの関門へ進める）
BattleSummary studySummary({required int correct, required int answered}) =>
    BattleSummary(
      won: answered > 0 && correct / answered >= 0.6,
      correctCount: correct,
      answeredCount: answered,
      maxCombo: 0,
      remainingHp: 0,
      maxHp: 0,
      turns: const [],
    );
