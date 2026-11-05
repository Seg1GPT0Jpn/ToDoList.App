import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/quiz_screen.dart';

/// 単語の練習のあとの「1戦だけの冒険」。
///
/// たった今練習した単語（最大5語）が魔物になって現れる。確認用のバトルなので、
/// 結果は保存せず、飛ばしても何も失わない。単語は端末の中の単語帳から作り、送らない。
class QuickBattle {
  const QuickBattle._();

  /// 戦える単語の数の下限
  static const minWords = 3;

  static WordList listOf(VocabBook book) => WordList(
    listId: 'vocab_${book.id}_quick',
    title: book.title,
    origin: book.isProtected
        ? QuestionOrigin.personalImport
        : book.isTerms
        ? QuestionOrigin.original
        : QuestionOrigin.userCreated,
    words: [
      for (final c in book.cards)
        WordEntry(term: c.term, meaning: c.meaning, number: c.number),
    ],
  );

  /// 練習した単語から、戦う単語を選ぶ（間違えた単語を先に）
  static List<WordEntry> pick(
    WordList list,
    List<String> studied,
    Set<String> missed,
    VocabBook book,
  ) {
    final terms = <String>[
      for (final id in [...missed, ...studied])
        if (book.card(id) != null) book.card(id)!.term,
    ];
    final seen = <String>{};
    return [
      for (final t in terms)
        if (seen.add(t))
          for (final w in list.words)
            if (w.term == t) w,
    ].take(WordBattle.wordsPerBattle).toList();
  }

  static Future<void> start(
    BuildContext context,
    VocabBook book,
    List<String> studied,
    Set<String> missed,
  ) async {
    final services = RpgServices.of(context);
    final list = listOf(book);
    final words = pick(list, studied, missed, book);
    if (words.length < minWords) return;
    final questions = [
      for (final w in words)
        ...WordBattle.questionsFor(
          list,
          w,
          formats: const {WordFormat.meaning, WordFormat.recall},
          terms: book.isTerms,
        ),
    ];
    final progress = await services.repository.load();
    if (!context.mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => quizScreen(
          world: RpgCatalog.world(book.worldId),
          stage: WordBattle.stage(
            list,
            words,
            progress.level,
            worldId: book.worldId,
            name: book.isTerms ? '暗記カード：${book.title}' : null,
            noun: book.noun,
          ),
          questions: questions,
          progress: progress,
          trial: true,
          mode: BattleMode.trial,
        ),
      ),
    );
  }
}
