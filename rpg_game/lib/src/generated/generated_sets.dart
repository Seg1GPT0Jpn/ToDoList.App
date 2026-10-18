import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';
import 'gen_english.dart';
import 'gen_info.dart';
import 'gen_japanese.dart';
import 'gen_math.dart';
import 'gen_music.dart';
import 'gen_science.dart';
import 'gen_social.dart';

/// 問題セットを読みこむときに、計算や表から作れる問題を足す。
///
/// - 足すのは、作り方（[Gen]）がある単元の問題だけ。その単元の問題数の [factor] 倍
/// - 同じセットなら毎回同じ問題になる（学習記録・復習がそのまま使える）
/// - 答えはプログラムが計算するので、答えのまちがいは入らない
/// - 問題ファイルは増えないので、ダウンロードは重くならない
abstract final class GeneratedSets {
  /// 単元 → 作り方
  static final Map<String, List<Gen>> byUnit = {
    ...mathGens,
    ...infoGens,
    ...scienceGens,
    ...musicGens,
    ...englishGens,
    ...socialGens,
    ...japaneseGens,
  };

  /// 単元の上の階層 → 作り方（その下の単元すべてに使う。歴史の時代など）
  static final Map<String, List<Gen>> byPrefix = {
    ...socialPrefixGens,
    ...japanesePrefixGens,
  };

  /// 単元の作り方（なければ null）
  static List<Gen>? gensFor(String unit) {
    final exact = byUnit[unit];
    if (exact != null) return exact;
    var best = '';
    for (final k in byPrefix.keys) {
      if ((unit == k || unit.startsWith('$k.')) && k.length > best.length)
        best = k;
    }
    return best.isEmpty ? null : byPrefix[best];
  }

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
      if (u == null || gensFor(u) == null) continue;
      byUnitCount[u] = (byUnitCount[u] ?? 0) + 1;
      sample.putIfAbsent(u, () => q);
    }
    if (byUnitCount.isEmpty) return set;
    final seen = {for (final q in set.questions) '${q.prompt}|${q.sentence}'};
    final extra = <QuizQuestion>[];
    var k = 0;
    for (final MapEntry(key: unit, value: count) in byUnitCount.entries) {
      final gens = gensFor(unit)!;
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
        if (q == null || !seen.add('${q.prompt}|${q.sentence}')) continue;
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
  static QuizQuestion? build(GenQ g0, String id, QuizQuestion sample) {
    final g = _normalize(g0);
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
      sentence: g.sentence,
      choices: choices,
      answerIndex: pos,
      explanation: g.explanation,
      targetGrade: sample.targetGrade,
      phase: sample.phase,
      tags: [...sample.tags, 'generated'],
    );
  }

  static final _asciiMinus = RegExp(r'(^|[^A-Za-z/])-(\d)');

  /// マイナス記号を「−」にそろえる（プログラムの問題はそのまま）
  static GenQ _normalize(GenQ g) {
    if (g.prompt.contains('print(') || g.prompt.contains('def ')) return g;
    String f(String t) =>
        t.replaceAllMapped(_asciiMinus, (m) => '${m[1]}−${m[2]}');
    return GenQ(
      prompt: f(g.prompt),
      answer: f(g.answer),
      wrong: [for (final w in g.wrong) f(w)],
      explanation: f(g.explanation),
      category: g.category,
      sentence: g.sentence,
    );
  }
}
