import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

final _password = Platform.environment['SCHOOL_PASSWORD'];

QuizQuestion _q(String id,
        {String? passage, int n = 4, List<String> tags = const ['yosou']}) =>
    QuizQuestion(
      id: id,
      category: QuestionCategory.reading,
      prompt: id,
      choices: [for (var i = 0; i < n; i++) '$id-$i'],
      tags: tags,
      passage: passage == null
          ? null
          : Passage(
              id: passage, title: '大問 $passage', paragraphs: const ['本文']),
    );

void main() {
  test('予想問題だけは、選択肢が4つ以外でもよい（2〜10個）', () {
    expect(_q('a', n: 5).choices.length, 5);
    expect(_q('b', n: 2).choices.length, 2);
    expect(() => _q('c', n: 11), throwsArgumentError);
    expect(() => _q('d', n: 5, tags: const []), throwsArgumentError);
  });

  test('原本の切り抜きの書き方', () {
    final c = YosouCrop.tryParse('joho:2:0.1,0.2,0.9,0.5')!;
    expect(c.examId, 'joho');
    expect(c.page, 2);
    expect(c.aspect(0.5), closeTo(0.8 / 0.3 * 0.5, 1e-9));
    expect(YosouCrop.tryParse('joho:2:0.5,0.2,0.4,0.5'), isNull);
    expect(YosouCrop.tryParse('joho:0:0,0,1,1'), isNull);
    expect(YosouCrop.ofParagraph('@yosou:ec:1:0,0,1,1')!.examId, 'ec');
    expect(YosouCrop.ofParagraph('ふつうの段落'), isNull);
    expect(FigureSpec.problems({'yosou': 'ec:1:0,0,1,0.5'}), isEmpty);
    expect(FigureSpec.problems({'yosou': 'ec:1'}), isNotEmpty);
  });

  test('大問ごとに、出てきた順でまとめる', () {
    final g = YosouGroup.of([
      _q('x1', passage: 'A'),
      _q('x2', passage: 'A'),
      _q('y1', passage: 'B'),
      _q('x3', passage: 'A'),
    ]);
    expect([for (final e in g) e.id], ['A', 'B']);
    expect([for (final q in g.first.questions) q.id], ['x1', 'x2', 'x3']);
    expect(g.first.title, '大問 A');
  });

  test('小問から解答用紙を作る：配点・完答・形式ごとの答え', () {
    final sheet = YosouSheet.of([
      _q('a1', passage: 'A', tags: const ['yosou', 'pt:3']),
      _q('a2', passage: 'A', tags: const ['yosou', 'pt:2', 'set:a2']),
      _q('a3', passage: 'A', tags: const ['yosou', 'pt:2', 'set:a2']),
      QuizQuestion(
        id: 'b1',
        category: QuestionCategory.reading,
        prompt: '書こう',
        choices: const ['x', 'y', 'z', 'w'],
        accepted: const ['ex'],
        tags: const ['yosou'],
        passage: const Passage(id: 'B', title: '大問 B', paragraphs: ['本文']),
      ),
      QuizQuestion(
        id: 'b2',
        category: QuestionCategory.reading,
        format: QuestionFormat.written,
        prompt: '説明しよう',
        written:
            WrittenSpec(modelAnswer: '模範', rubric: const [RubricItem('要点', 4)]),
        tags: const ['yosou', 'pt:4'],
        passage: const Passage(id: 'B', title: '大問 B', paragraphs: ['本文']),
      ),
    ]);
    expect([for (final s in sheet.sections) s.title], ['大問 A', '大問 B']);
    expect(sheet.total, 3 + 2 + 1 + 4);
    final items = sheet.items.toList();
    expect(
        [for (final i in items) i.label], ['第1問', '第2〜3問（完答）', '第4問', '第5問']);
    expect(items[0].type, MockItemType.choice);
    expect(items[0].answers, ['a1-0']);
    expect(items[2].type, MockItemType.text);
    expect(items[2].answers, ['x', 'ex']);
    expect(items[3].type, MockItemType.self);
    expect(items[3].prompt, '説明しよう');

    final a = MockAttempt(examId: 'e', startedAt: DateTime(2026))
      ..answers.addAll({'a1': 'a1-0', 'a2': 'a2-0', 'b1': 'ＥＸ'});
    expect(a.answered(items[1]), isTrue);
    expect(a.scoreOf(items[1]), 0, reason: '完答なので片方だけでは0点');
    a.answers['a3'] = 'a3-0';
    expect(a.scoreOf(items[1]), 2);
    expect(a.score(sheet), 3 + 2 + 1);
    expect(a.unscored(sheet), [items[3]]);
  });

  test('同梱の小問データは学校のパスワードで開け、すべて読める', () {
    final key = SchoolMaterials.keyFor(_password!);
    final withSmall = YosouExams.all.where((e) => e.smallQuestions).toList();
    expect(withSmall, isNotEmpty);
    for (final e in withSmall) {
      final raw = File('../rpg_game_app/${e.questionsAsset}').readAsBytesSync();
      final set = QuestionSet.fromJson(
        jsonDecode(utf8.decode(SchoolMaterials.open(raw, key: key)!))
            as Map<String, dynamic>,
      );
      expect(set.questions.length, greaterThan(10), reason: e.id);
      expect(YosouSheet.of(set.questions).total, 100, reason: e.id);
      for (final q in set.questions) {
        expect(q.tags, contains(QuizQuestion.yosouTag), reason: q.id);
        expect(q.passage, isNotNull, reason: q.id);
        expect(q.tags.where((t) => t.startsWith('pt:')), hasLength(1),
            reason: q.id);
        if (q.figure != null) {
          expect(FigureSpec.problems(q.figure!), isEmpty, reason: q.id);
        }
        for (final p in q.passage!.paragraphs) {
          if (p.startsWith(YosouCrop.paragraphPrefix)) {
            expect(YosouCrop.ofParagraph(p), isNotNull, reason: q.id);
          }
        }
      }
    }
  }, skip: _password == null ? 'SCHOOL_PASSWORD がないので中身は確かめない' : false);
}
