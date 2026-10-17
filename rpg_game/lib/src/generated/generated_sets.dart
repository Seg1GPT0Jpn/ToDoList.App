import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';
import 'gen_math.dart';

/// 問題セットを読みこむときに、計算や表から作れる問題を足す。
///
/// - 足すのは、作り方（[Gen]）がある単元の問題だけ。その単元の問題数の [factor] 倍
/// - 同じセットなら毎回同じ問題になる（学習記録・復習がそのまま使える）
/// - 答えはプログラムが計算するので、答えのまちがいは入らない
/// - 問題ファイルは増えないので、ダウンロードは重くならない
abstract final class GeneratedSets {
  /// 単元 → 作り方
  static final Map<String, List<Gen>> byUnit = {...mathGens};

  /// 作り方の版（作り方を変えたら上げる。問題 ID に入る）
  static const version = 1;

  static const factor = 9;

  /// 1つのセットに足す問題の上限
  static const maxPerSet = 600;

  static QuestionSet augment(QuestionSet set) {
    if (set.origin != QuestionOrigin.original) return set;
    final byUnitCount = <String, int>{};
    final sample = <String, QuizQuestion>{};
    for (final q in set.questions) {
      final u = q.unit;
      if (u == null || !byUnit.containsKey(u)) continue;
      byUnitCount[u] = (byUnitCount[u] ?? 0) + 1;
      sample.putIfAbsent(u, () => q);
    }
    if (byUnitCount.isEmpty) return set;
    final seen = {for (final q in set.questions) q.prompt};
    final extra = <QuizQuestion>[];
    var k = 0;
    for (final MapEntry(key: unit, value: count) in byUnitCount.entries) {
      final gens = byUnit[unit]!;
      final r = Random(stableHash('${set.setId}|$unit|$version'));
      final want = count * factor;
      var made = 0;
      for (var tries = 0; tries < want * 10 && made < want; tries++) {
        if (extra.length >= maxPerSet) break;
        final g = gens[r.nextInt(gens.length)](r);
        if (g == null) continue;
        final q = build(
            g,
            '${set.setId}_g${version}_${k.toString().padLeft(4, '0')}',
            sample[unit]!);
        if (q == null || !seen.add(q.prompt)) continue;
        extra.add(q);
        k++;
        made++;
      }
    }
    if (extra.isEmpty) return set;
    return QuestionSet(
      setId: set.setId,
      worldId: set.worldId,
      origin: set.origin,
      version: set.version,
      questions: [...set.questions, ...extra],
    );
  }

  /// 1問を4択の問題にする（まちがいが3つそろわなければ null）
  static QuizQuestion? build(GenQ g, String id, QuizQuestion sample) {
    final wrong = <String>[];
    for (final w in g.wrong) {
      if (w.isEmpty || w == g.answer || wrong.contains(w)) continue;
      wrong.add(w);
      if (wrong.length == 3) break;
    }
    if (wrong.length < 3 || g.answer.isEmpty) return null;
    // 正解の位置は問題文から決める（毎回同じ）
    final pos = stableHash(g.prompt) % 4;
    final choices = [...wrong]..insert(pos, g.answer);
    return QuizQuestion(
      id: id,
      unit: sample.unit,
      category: g.category,
      prompt: g.prompt,
      choices: choices,
      answerIndex: pos,
      explanation: g.explanation,
      targetGrade: sample.targetGrade,
      phase: sample.phase,
      tags: [...sample.tags, 'generated'],
    );
  }
}
