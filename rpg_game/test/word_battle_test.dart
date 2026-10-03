import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

WordList load(String id) => WordList.fromJson(
    jsonDecode(File('assets/words/$id.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  final list = load('words_j1');

  test('同じ単語を4つの形で出す（スペルは入力式、発音は読み上げ）', () {
    final w = list.words.first;
    final qs = WordBattle.questionsFor(list, w, random: Random(1));
    expect(qs, hasLength(4));
    expect(qs.map((q) => q.id).toSet(), hasLength(4));
    final spelling = qs.firstWhere((q) => q.id.endsWith('spelling'));
    expect(spelling.isInput, isTrue);
    expect(spelling.matchesInput(w.term), isTrue);
    final listening = qs.firstWhere((q) => q.id.endsWith('listening'));
    expect(listening.listen, isTrue);
    expect(listening.sentence, w.term);
    for (final q in qs) {
      expect(q.unit, 'english.vocab.words.j1.meaning');
      expect(q.choices.toSet(), hasLength(4));
    }
  });

  test('覚えぐあい：形式ごとの記録から★と忘れかけを決める', () {
    final w = list.words.first;
    WordMemory mem(LearningRecord r) => WordBattle.memoryOf(list, w, r, 10);
    expect(mem(LearningRecord.empty).stars, 0);
    var r = LearningRecord.empty;
    for (final f in [
      WordFormat.meaning,
      WordFormat.recall,
      WordFormat.spelling
    ]) {
      r = r.recordAll([
        AnswerEvent(
            questionId: WordBattle.questionId(list, w, f),
            setId: WordBattle.setId(list),
            isCorrect: true,
            elapsedMs: 1),
      ], day: 10);
    }
    expect(mem(r).stars, 2);
    expect(mem(r).collected, isTrue);
    expect(mem(r).fading, isFalse);
    r = r.recordAll([
      AnswerEvent(
          questionId: WordBattle.questionId(list, w, WordFormat.listening),
          setId: WordBattle.setId(list),
          isCorrect: false,
          elapsedMs: 1),
    ], day: 11);
    expect(WordBattle.memoryOf(list, w, r, 11).fading, isTrue);
  });

  test('次の5語：忘れかけの語をまぜ、忘却の塔は忘れかけだけ', () {
    final w = list.words[3];
    final r = LearningRecord.empty.recordAll([
      AnswerEvent(
          questionId: WordBattle.questionId(list, w, WordFormat.meaning),
          setId: WordBattle.setId(list),
          isCorrect: false,
          elapsedMs: 1),
    ], day: 1);
    final next = WordBattle.nextWords(list, r, 1, random: Random(2));
    expect(next, hasLength(WordBattle.wordsPerBattle));
    expect(next.map((e) => e.term), contains(w.term));
    expect(
        WordBattle.nextWords(list, r, 1, reviewOnly: true).single.term, w.term);
  });

  test('単語のモンスター5体と順に戦う。1語あたり約3問で倒せる', () {
    final words = list.words.take(5).toList();
    final s = WordBattle.stage(list, words, 10);
    expect([s.enemy, ...s.reinforcements].map((e) => e.name),
        [for (final w in words) w.term]);
    final hits = s.enemy.maxHp / PlayerStats.forLevel(10).attack;
    expect(hits, inInclusiveRange(2, 3.5));
    expect(Proficiency.fieldOf(QuestionStat(setId: WordBattle.setId(list)))?.$2,
        '単語');
  });

  test('作った問題を登録すると、学習記録に残せる', () {
    final source = JsonQuestionSource((_) async => null);
    final set = QuestionSet(
      setId: WordBattle.setId(list),
      worldId: 'english',
      origin: list.origin,
      version: 1,
      questions: [
        for (final w in list.words) ...WordBattle.questionsFor(list, w),
      ],
    );
    source.adopt(set);
    expect(source.setIdOf(set.questions.first.id), WordBattle.setId(list));
  });
}
