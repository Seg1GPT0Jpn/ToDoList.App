// 全問題（読みこみ時に自動で足す問題もふくむ）を JSON に書き出す。問題一覧の Excel を作るのに使う。
//   dart run tool/dump_questions.dart <出力.json>
import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game/src/generated/generated_sets.dart';

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// 正解を1行で
String _answer(QuizQuestion q) {
  switch (q.format) {
    case QuestionFormat.trueFalse:
      return q.truth == true ? '○（正しい）' : '×（誤り）';
    case QuestionFormat.multiSelect:
      final m = q.multiSelect!;
      return [for (final i in m.correct.toList()..sort()) m.options[i]]
          .join(' / ');
    case QuestionFormat.order:
      final o = q.order!;
      return o.items.join(o.joiner);
    case QuestionFormat.numeric:
      final n = q.numeric!;
      return '${_num(n.value)}${n.unit}';
    case QuestionFormat.cloze:
      final c = q.cloze!;
      return [
        for (var i = 0; i < c.blanks.length; i++)
          '[${i + 1}] ${c.blanks[i].first}'
      ].join('　');
    case QuestionFormat.multiStep:
      return [
        for (var i = 0; i < q.subQuestions.length; i++)
          '（${i + 1}）${_answer(q.subQuestions[i])}'
      ].join('　');
    case QuestionFormat.written:
      return q.written!.modelAnswer;
    case QuestionFormat.choice:
      return q.choices.isEmpty ? '' : q.choices[q.answerIndex];
  }
}

/// くわしい解説（解説・ヒント・よくあるまちがい・段階問題の各解説をまとめる）
String _explain(QuizQuestion q) {
  final parts = <String>[
    if ((q.explanation ?? '').trim().isNotEmpty) q.explanation!.trim(),
    for (var i = 0; i < q.subQuestions.length; i++)
      if ((q.subQuestions[i].explanation ?? '').trim().isNotEmpty)
        '（${i + 1}）${q.subQuestions[i].explanation!.trim()}',
    if ((q.hint ?? '').trim().isNotEmpty) '【考え方】${q.hint!.trim()}',
    if (q.commonMistakes.isNotEmpty) '【よくあるまちがい】${q.commonMistakes.join('／')}',
  ];
  return parts.join('\n');
}

String _body(QuizQuestion q) {
  if (q.cloze != null) return q.cloze!.text;
  if ((q.sentence ?? '').isNotEmpty) return q.sentence!;
  final p = q.passage;
  if (p == null) return '';
  final t = '${p.title}\n${p.paragraphs.join('\n')}';
  return t.length > 3000 ? '${t.substring(0, 3000)}…' : t;
}

void main(List<String> args) {
  final out = <Map<String, Object?>>[];
  final files = Directory('assets/questions')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final raw = JsonQuestionSource.parse(f.readAsStringSync());
    final set = GeneratedSets.augment(raw);
    for (final q in set.questions) {
      final generated = q.tags.contains('generated');
      final choices = switch (q.format) {
        QuestionFormat.multiSelect => q.multiSelect!.options,
        QuestionFormat.order => q.order!.items,
        _ => q.choices,
      };
      out.add({
        'world': set.worldId,
        'set': set.setId,
        'id': q.id,
        'unit': q.unit == null || !Curriculum.contains(q.unit!)
            ? (q.unit ?? '')
            : Curriculum.breadcrumb(q.unit!),
        'format': q.format.label,
        'category': q.category.label,
        'prompt': q.prompt,
        'body': _body(q),
        'answer': _answer(q),
        'choices': choices,
        'answerNo': q.format == QuestionFormat.choice && q.choices.isNotEmpty
            ? q.answerIndex + 1
            : null,
        'explanation': _explain(q),
        'generated': generated,
      });
    }
  }
  File(args.single).writeAsStringSync(jsonEncode(out));
  stdout.writeln('${out.length} 問');
}
