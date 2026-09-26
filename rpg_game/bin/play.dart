// ターミナルで英語ワールドのステージ1を遊ぶお試し版。
//   dart run bin/play.dart
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';

Future<void> main() async {
  final source = JsonQuestionSource((id) async {
    final f = File('assets/questions/english/$id.json');
    return f.existsSync() ? f.readAsStringSync() : null;
  });
  final world = RpgCatalog.world(RpgCatalog.englishWorldId);
  final stage = world.stages.first;
  final set = await source.load(stage.questionSetId);
  if (set == null) {
    stdout.writeln('問題セットが見つかりません');
    return;
  }

  var progress = RpgProgress.initial;
  final player = PlayerStats.forLevel(progress.level);
  final battle = BattleEngine(
    player: player,
    enemy: stage.enemy,
    questions: set.questions,
    timeLimit: Duration(seconds: stage.timeLimitSeconds),
  );

  stdout.writeln('== ${world.name} / ${stage.name} ==');
  stdout.writeln(
      '${stage.enemy.name} があらわれた！（制限時間 ${stage.timeLimitSeconds} 秒）\n');

  while (!battle.isOver) {
    final q = battle.currentQuestion;
    stdout.writeln(
        'あなた HP ${battle.playerHp}/${player.maxHp}   敵 HP ${battle.enemyHp}/${stage.enemy.maxHp}');
    stdout.writeln('[${q.source.category.label}] ${q.source.prompt}');
    if (q.source.sentence != null) stdout.writeln('  ${q.source.sentence}');
    for (var i = 0; i < q.choices.length; i++) {
      stdout.writeln('  ${i + 1}. ${q.choices[i]}');
    }
    stdout.write('> ');
    final watch = Stopwatch()..start();
    final input = int.tryParse(stdin.readLineSync()?.trim() ?? '');
    final r = input == null || input < 1 || input > 4
        ? battle.timeout()
        : battle.answer(input - 1, elapsed: watch.elapsed);

    if (r.correct) {
      stdout.writeln('正解！ ${r.quick ? 'すばやい！ ' : ''}'
          '${r.combo >= 2 ? '${r.combo}連続！ ' : ''}${r.damageToEnemy} のダメージ！');
    } else {
      stdout.writeln('${r.timedOut ? '時間切れ…' : '不正解…'} 正解は「${q.source.answer}」。'
          '${stage.enemy.name} の反撃！ ${r.damageToPlayer} のダメージ！');
      if (q.source.explanation != null) {
        stdout.writeln('  解説: ${q.source.explanation}');
      }
    }
    stdout.writeln();
  }

  final summary = battle.summary();
  final result = Progression.applyBattle(
      progress: progress, world: world, stage: stage, summary: summary);
  progress = result.progress;
  stdout.writeln(summary.won ? '${stage.enemy.name} をたおした！' : 'やられてしまった…');
  stdout.writeln('正解 ${summary.correctCount}/${summary.answeredCount}  '
      '最大コンボ ${summary.maxCombo}  経験値 +${result.expResult.expGained}');
  if (result.expResult.leveledUp) {
    final a = result.expResult.after;
    stdout.writeln(
        'レベルアップ！ Lv${a.level}（HP ${a.maxHp} / 攻撃 ${a.attack} / 防御 ${a.defense}）');
  }
}
