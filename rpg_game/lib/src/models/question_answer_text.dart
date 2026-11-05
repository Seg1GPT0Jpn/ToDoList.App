import 'question.dart';
import 'question_format.dart';

/// 問題の正解・解説を、一覧で見せるための文にする
abstract final class QuestionAnswerText {
  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// 正解を1行で
  static String answer(QuizQuestion q) {
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
            '（${i + 1}）${answer(q.subQuestions[i])}'
        ].join('　');
      case QuestionFormat.written:
        return q.written!.modelAnswer;
      case QuestionFormat.choice:
        return q.choices.isEmpty ? '' : q.choices[q.answerIndex];
    }
  }

  /// くわしい解説（解説・段階問題の各解説・考え方・よくあるまちがい）
  static String explain(QuizQuestion q) => [
        if ((q.explanation ?? '').trim().isNotEmpty) q.explanation!.trim(),
        for (var i = 0; i < q.subQuestions.length; i++)
          if ((q.subQuestions[i].explanation ?? '').trim().isNotEmpty)
            '（${i + 1}）${q.subQuestions[i].explanation!.trim()}',
        if ((q.hint ?? '').trim().isNotEmpty) '【考え方】${q.hint!.trim()}',
        if (q.commonMistakes.isNotEmpty)
          '【よくあるまちがい】${q.commonMistakes.join('／')}',
      ].join('\n');

  /// 4択以外の問題で、選択肢として見せるもの
  static List<String> options(QuizQuestion q) => switch (q.format) {
        QuestionFormat.multiSelect => q.multiSelect!.options,
        QuestionFormat.order => q.order!.items,
        _ => q.choices,
      };

  /// 一覧で探すときに見る文
  static bool matches(QuizQuestion q, String query) {
    if (query.isEmpty) return true;
    final t = query.toLowerCase();
    return q.prompt.toLowerCase().contains(t) ||
        (q.sentence ?? '').toLowerCase().contains(t) ||
        explain(q).toLowerCase().contains(t) ||
        answer(q).toLowerCase().contains(t) ||
        options(q).any((c) => c.toLowerCase().contains(t));
  }
}
