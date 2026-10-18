// 全問題（読みこみ時に自動で足す問題もふくむ）を JSON に書き出す。問題一覧の Excel を作るのに使う。
//   dart run tool/dump_questions.dart <出力.json>
import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game/src/generated/generated_sets.dart';

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
      final choices = QuestionAnswerText.options(q);
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
        'answer': QuestionAnswerText.answer(q),
        'choices': choices,
        'answerNo': q.format == QuestionFormat.choice && q.choices.isNotEmpty
            ? q.answerIndex + 1
            : null,
        'explanation': QuestionAnswerText.explain(q),
        'generated': generated,
      });
    }
  }
  File(args.single).writeAsStringSync(jsonEncode(out));
  stdout.writeln('${out.length} 問');
}
