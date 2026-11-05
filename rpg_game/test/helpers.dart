import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

QuestionSet loadSet(String setId) => JsonQuestionSource.parse(
    File('assets/questions/${setId.split('_').first}/$setId.json')
        .readAsStringSync());

/// ステージの出題範囲（複数セットをまとめたもの）
QuestionSet loadStagePool(StageDef stage) => QuestionSet.merge(
    stage.id, [for (final id in stage.questionSetIds) loadSet(id)]);

QuestionSet loadStage01() => loadSet('english_stage_01');

/// ダメージのブレを 0 にした計算機（期待値をそのまま検証できる）
DamageCalculator fixedDamage() =>
    DamageCalculator(random: Random(1), variance: 0);

/// 弱点も装甲もない、テスト用の敵
const testEnemy = EnemyDef(id: 'test', name: 'テスト', maxHp: 40, attack: 7);

BattleEngine newBattle({
  int level = 1,
  EnemyDef? enemy,
  List<QuizQuestion>? questions,
  int seed = 42,
}) =>
    BattleEngine(
      player: PlayerStats.forLevel(level),
      enemy: enemy ?? testEnemy,
      questions: questions ?? loadStage01().questions,
      timeLimit: const Duration(seconds: 20),
      random: Random(seed),
      damage: fixedDamage(),
    );

int wrongIndex(BattleEngine b) => (b.currentQuestion.correctIndex + 1) % 4;

const slow = Duration(seconds: 10);
const fast = Duration(seconds: 2);
