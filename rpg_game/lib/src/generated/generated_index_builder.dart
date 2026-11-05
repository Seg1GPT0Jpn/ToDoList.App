import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';
import 'generated_sets.dart';

/// 自動で作る問題の索引をつくる（tool/generated_index.dart とテストで使う）
abstract final class GeneratedIndexBuilder {
  /// 作り方がある「セット|単元」（並び順は固定）
  static List<String> slots(List<QuestionSet> sets) => {
        for (final s in sets)
          if (s.origin == QuestionOrigin.original)
            for (final q in s.questions)
              if (q.unit != null && GeneratedSets.gensFor(q.unit!) != null)
                '${s.setId}|${q.unit}',
      }.toList()
        ..sort();

  /// 収録問題の「問題文|本文」のハッシュ（自動の問題と重ならないように）
  static List<int> recordedKeys(List<QuestionSet> sets) => {
        for (final s in sets)
          if (s.origin == QuestionOrigin.original)
            for (final q in s.questions)
              stableHash(GeneratedSets.keyOf(q.prompt, q.sentence)),
      }.toList()
        ..sort();

  /// 「セット|単元」→（仲間の中の番号, 仲間の数）。
  /// 実際に問題を作ってみて、同じ問題ができる「セット|単元」を仲間にまとめる。
  static Map<String, (int, int)> groups(List<QuestionSet> sets,
      {int samples = 800}) {
    final all = slots(sets);
    final sample = <String, QuizQuestion>{};
    for (final s in sets) {
      for (final q in s.questions) {
        if (q.unit != null) sample.putIfAbsent('${s.setId}|${q.unit}', () => q);
      }
    }
    final parent = List<int>.generate(all.length, (i) => i);
    int find(int i) {
      while (parent[i] != i) {
        parent[i] = parent[parent[i]];
        i = parent[i];
      }
      return i;
    }

    final owner = <String, int>{};
    for (var i = 0; i < all.length; i++) {
      final unit = all[i].split('|').last;
      final gens = GeneratedSets.gensFor(unit)!;
      final r = Random(stableHash('index|${all[i]}'));
      for (var t = 0; t < samples; t++) {
        final g = gens[r.nextInt(gens.length)](r);
        if (g == null) continue;
        final q = GeneratedSets.build(g, 'x', sample[all[i]]!);
        if (q == null) continue;
        final key = GeneratedSets.keyOf(q.prompt, q.sentence);
        final o = owner[key];
        if (o == null) {
          owner[key] = i;
        } else {
          parent[find(i)] = find(o);
        }
      }
    }
    final byRoot = <int, List<int>>{};
    for (var i = 0; i < all.length; i++) {
      (byRoot[find(i)] ??= []).add(i);
    }
    return {
      for (final g in byRoot.values)
        for (final (pos, i) in g.indexed) all[i]: (pos, g.length),
    };
  }

  static String source(List<QuestionSet> sets) {
    final b = StringBuffer()
      ..writeln('// tool/generated_index.dart で自動生成（手で直さない）。')
      ..writeln('// 自動で作る問題が、セットをまたいで重ならないようにするための索引。')
      ..writeln()
      ..writeln('/// 作り方がある「セット|単元」→（同じ問題ができる仲間の中の番号, 仲間の数）')
      ..writeln('const generatedSlots = <String, (int, int)>{');
    final g = groups(sets);
    for (final s in slots(sets)) {
      final (pos, size) = g[s]!;
      b.writeln("  '$s': ($pos, $size),");
    }
    b
      ..writeln('};')
      ..writeln()
      ..writeln('/// 収録問題の「問題文|本文」のハッシュ')
      ..writeln('const recordedKeys = <int>{');
    final keys = recordedKeys(sets);
    for (var i = 0; i < keys.length; i += 8) {
      b.writeln('  ${keys.skip(i).take(8).join(', ')},');
    }
    b.writeln('};');
    return b.toString();
  }
}
