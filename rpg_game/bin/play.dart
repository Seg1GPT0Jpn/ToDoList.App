// ターミナルで英語ワールドを遊ぶお試し版。
//   dart run bin/play.dart          ステージ選択から始める
//   dart run bin/play.dart --reset  セーブデータを消して最初から
//
// 進行状況は .rpg_save.json に保存する（アプリ版では Firestore に保存する部分）。
import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';

final _saveFile = File('.rpg_save.json');
Passage? _shownPassage;

Future<void> main(List<String> args) async {
  if (args.contains('--reset') && _saveFile.existsSync()) {
    _saveFile.deleteSync();
    stdout.writeln('セーブデータを消しました。\n');
  }

  final source = JsonQuestionSource((id) async {
    final folder = id.startsWith('sea_') ? 'sea' : 'english';
    final f = File('assets/questions/$folder/$id.json');
    return f.existsSync() ? f.readAsStringSync() : null;
  });
  final world = RpgCatalog.world(RpgCatalog.englishWorldId);
  var progress = _load();

  while (true) {
    final stage = _chooseStage(world, progress);
    if (stage == null) break;
    final sets = [
      for (final id in stage.questionSetIds) await source.load(id),
    ].whereType<QuestionSet>().toList();
    final set = sets.isEmpty ? null : QuestionSet.merge(stage.id, sets);
    if (set == null) {
      stdout.writeln('このステージの問題はまだ準備中です。\n');
      continue;
    }
    progress = _playBattle(world, stage, set, progress);
    _save(progress);
  }
  stdout.writeln('またね！');
}

StageDef? _chooseStage(WorldDef world, RpgProgress progress) {
  final stats = PlayerStats.forLevel(progress.level);
  stdout.writeln('==== ${world.name} ====');
  stdout.writeln(
      'Lv${stats.level}  HP ${stats.maxHp} / 攻撃 ${stats.attack} / 防御 ${stats.defense}'
      '  （次のレベルまで ${PlayerStats.expToNextLevel(progress.level) - progress.exp} EXP）\n');
  for (final s in world.stages) {
    final unlocked = Progression.isStageUnlocked(progress, world, s);
    final cleared = progress.clearedStageIds.contains(s.id);
    final mark = cleared ? '★' : (unlocked ? '　' : '🔒');
    stdout.writeln(
        '$mark ${s.order}. ${s.name}（${s.enemy.name} / 推奨Lv${s.recommendedLevel}）');
  }
  while (true) {
    stdout.write('\n挑戦するステージの番号（q で終了）> ');
    final input = stdin.readLineSync()?.trim();
    if (input == null || input == 'q') return null;
    final n = int.tryParse(input);
    final matches = world.stages.where((s) => s.order == n);
    if (matches.isEmpty) {
      stdout.writeln('1〜${world.stages.length} の番号を入力してください');
      continue;
    }
    final stage = matches.first;
    if (!Progression.isStageUnlocked(progress, world, stage)) {
      stdout.writeln('まだ挑戦できません。1つ前のステージをクリアしよう');
      continue;
    }
    stdout.writeln();
    return stage;
  }
}

RpgProgress _playBattle(
    WorldDef world, StageDef stage, QuestionSet set, RpgProgress progress) {
  final player = PlayerStats.forLevel(progress.level);
  final battle = BattleEngine(
    player: player,
    enemy: stage.enemy,
    questions: set.questions,
    timeLimit: Duration(seconds: stage.timeLimitSeconds),
    readingTimeLimit: Duration(seconds: stage.readingTimeLimitSeconds),
  );

  stdout.writeln('== ${stage.order}. ${stage.name} ==');
  stdout.writeln('${stage.enemy.name} があらわれた！ ${stage.enemy.description}');
  stdout.writeln('（文法: ${stage.grammarTheme} ／ 単語: ${stage.vocabLevel}）');
  stdout.writeln('（制限時間 ${stage.timeLimitSeconds} 秒。1〜4 を入力。それ以外は時間切れ扱い）\n');

  while (!battle.isOver) {
    final q = battle.currentQuestion;
    stdout.writeln('あなた HP ${battle.playerHp}/${player.maxHp}   '
        '${stage.enemy.name} HP ${battle.enemyHp}/${stage.enemy.maxHp}');
    final passage = q.source.passage;
    if (passage != null && passage != _shownPassage) {
      _shownPassage = passage;
      stdout.writeln('―― 長文「${passage.title}」 ――');
      for (final (i, p) in passage.paragraphs.indexed) {
        stdout.writeln('［${i + 1}］$p');
      }
      stdout.writeln();
    }
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
  stdout.writeln(summary.won ? '${stage.enemy.name} をたおした！' : 'やられてしまった…');
  stdout.writeln('正解 ${summary.correctCount}/${summary.answeredCount}  '
      '最大コンボ ${summary.maxCombo}  経験値 +${result.expResult.expGained}');
  if (result.expResult.leveledUp) {
    final a = result.expResult.after;
    stdout.writeln('レベルアップ！ Lv${a.level}'
        '（HP ${a.maxHp} / 攻撃 ${a.attack} / 防御 ${a.defense}）');
  }
  if (result.newlyUnlockedStageId != null) {
    stdout.writeln(
        '「${RpgCatalog.stage(result.newlyUnlockedStageId!).name}」に挑戦できるようになった！');
  }
  if (summary.missedQuestions.isNotEmpty) {
    stdout.writeln('\n― 復習 ―');
    for (final q in summary.missedQuestions) {
      stdout.writeln('・${q.sentence ?? q.prompt} → ${q.answer}');
    }
  }
  stdout.writeln();
  return result.progress;
}

RpgProgress _load() {
  if (!_saveFile.existsSync()) return RpgProgress.initial;
  try {
    return RpgProgress.fromMap(
        jsonDecode(_saveFile.readAsStringSync()) as Map<String, dynamic>);
  } on FormatException {
    return RpgProgress.initial;
  }
}

void _save(RpgProgress progress) =>
    _saveFile.writeAsStringSync(jsonEncode(progress.toMap()));
