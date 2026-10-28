import '../models/question.dart';
import '../models/question_format.dart';
import 'mock_exam.dart';

/// 予想問題の小問を、大問ごとのまとまり（本文・前書き＝Passage）に分ける。
///
/// 出てきた順のまま使う（前の小問が次の小問の誘導になっていることがあるため）。
class YosouGroup {
  const YosouGroup(
      {required this.id, required this.title, required this.questions});

  final String id;
  final String title;
  final List<QuizQuestion> questions;

  /// 問題データを大問ごとに分ける（出てきた順。本文がない問題は直前の大問に続ける）
  static List<YosouGroup> of(List<QuizQuestion> questions) {
    final out = <YosouGroup>[];
    final order = <String>[];
    final byId = <String, List<QuizQuestion>>{};
    final titles = <String, String>{};
    for (final q in questions) {
      final id = groupId(q);
      if (!byId.containsKey(id)) {
        order.add(id);
        byId[id] = [];
        titles[id] = q.passage?.title ?? id;
      }
      byId[id]!.add(q);
    }
    for (final id in order) {
      out.add(YosouGroup(id: id, title: titles[id]!, questions: byId[id]!));
    }
    return out;
  }

  /// 大問のまとまりの名前（本文の id。なければ問題 id の先頭）
  static String groupId(QuizQuestion q) =>
      q.passage?.id ??
      q.id.substring(0, q.id.lastIndexOf('_').clamp(0, q.id.length));
}

/// 小問ごとの問題データから、60分で解いて最後にまとめて採点する解答用紙を作る。
///
/// 配点は tags の `pt:N`（なければ1点）。`set:<id>` が同じ小問は完答で1つの欄にまとめる。
abstract final class YosouSheet {
  static MockSheet of(List<QuizQuestion> questions) {
    final number = {
      for (var n = 0; n < questions.length; n++) questions[n].id: n + 1,
    };
    final sections = <MockSection>[];
    for (final g in YosouGroup.of(questions)) {
      final items = <MockItem>[];
      final sets = <String, List<QuizQuestion>>{};
      for (final q in g.questions) {
        final set = _tag(q, 'set:');
        if (set == null) {
          items.add(item(q, number[q.id]!));
        } else if (sets['set:$set'] case final qs?) {
          qs.add(q);
        } else {
          sets['set:$set'] = [q];
          items.add(MockItem(
              id: 'set:$set', label: '', type: MockItemType.text, points: 0));
        }
      }
      sections.add(MockSection(
        title: g.title,
        items: [
          for (final i in items)
            if (sets[i.id] case final qs?) _set(qs, number) else i,
        ],
      ));
    }
    return MockSheet(sections: sections);
  }

  /// 小問の配点
  static int points(QuizQuestion q) => int.tryParse(_tag(q, 'pt:') ?? '') ?? 1;

  static String? _tag(QuizQuestion q, String prefix) {
    for (final t in q.tags) {
      if (t.startsWith(prefix)) return t.substring(prefix.length);
    }
    return null;
  }

  /// 小問1問を解答用紙の欄にする。答えは、選択肢・並べた順・書いた文字そのもの
  static MockItem item(QuizQuestion q, int number) {
    final label = '第$number問';
    final explain = q.explanation ?? '';
    return switch (q.format) {
      QuestionFormat.multiSelect => MockItem(
          id: q.id,
          label: label,
          type: MockItemType.choice,
          points: points(q),
          options: [for (final o in q.multiSelect!.options) multiOption(o)],
          answers: [
            for (final i in q.multiSelect!.correct)
              multiOption(q.multiSelect!.options[i])
          ],
          explain: explain,
          all: true,
          prompt: q.prompt,
        ),
      QuestionFormat.written => MockItem(
          id: q.id,
          label: label,
          type: MockItemType.self,
          points: points(q),
          answers: [q.written!.modelAnswer],
          explain: [
            '採点基準：${[
              for (final r in q.written!.rubric) '${r.point}（${r.score}）'
            ].join('・')}',
            if (explain.isNotEmpty) explain,
          ].join('\n'),
          prompt: q.prompt,
        ),
      QuestionFormat.choice when !q.isInput => MockItem(
          id: q.id,
          label: label,
          type: MockItemType.choice,
          points: points(q),
          options: q.choices,
          answers: [q.choices[q.answerIndex]],
          explain: explain,
          prompt: q.prompt,
        ),
      _ => MockItem(
          id: q.id,
          label: label,
          type: MockItemType.text,
          points: points(q),
          answers: [q.answer, ...?q.accepted],
          explain: explain,
          prompt: q.prompt,
        ),
    };
  }

  /// すべて選ぶ問題の選択肢（答えを「,」でつないで持つので、選択肢の中の「,」は全角にする）
  static String multiOption(String o) => o.replaceAll(',', '，');

  static MockItem _set(List<QuizQuestion> qs, Map<String, int> number) {
    final parts = [for (final q in qs) item(q, number[q.id]!)];
    final self = parts.any((p) => p.type == MockItemType.self);
    return MockItem(
      id: 'set:${_tag(qs.first, 'set:')}',
      label: '第${number[qs.first.id]}〜${number[qs.last.id]}問（完答）',
      type: self ? MockItemType.self : MockItemType.text,
      points: points(qs.first),
      answers: [for (final p in parts) p.answers.first],
      parts: parts,
      prompt: qs.first.prompt,
    );
  }
}
