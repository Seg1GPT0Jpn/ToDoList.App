import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/quiz_screen.dart';
import '../study/sea_home_screen.dart';
import '../vocab/vocab_session_screen.dart';
import '../vocab/vocab_store.dart';

/// つづりのテスト予定から、そのまま対策を始める。
///
/// - 範囲が番号（LEAP の 1201〜1300 など）で、その単語帳を開いていれば、範囲の単語だけで練習
/// - それ以外は、その教科で最近まちがえた問題で確認のバトル
/// - まちがえた問題が少なければ、その教科の定期テストの海を開く
///
/// 対策にかけた時間は、つづりの「クエストで対策した時間」として送る。
Future<void> startTsuzuriPrep(
  BuildContext context,
  TsuzuriUpcoming test,
) async {
  final services = RpgServices.of(context);
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final started = DateTime.now();
  final world = test.worldId;
  final range = TsuzuriLink.numberRange(test.detail);
  final store = VocabStore.of(services.personalBooks);
  final book = range == null
      ? null
      : TsuzuriPrep.bookFor(
          [
            for (final b in store.visibleBooks)
              if (!b.isTerms) b,
          ],
          range,
          test.title,
        );

  Future<void> open(Widget page) =>
      nav.push(MaterialPageRoute<void>(builder: (_) => page));

  if (book != null && range != null) {
    final tasks = TsuzuriPrep.rangeTasks(
      book,
      store.progress(book.id),
      range,
      now: started,
    );
    await open(
      VocabSessionScreen(
        store: store,
        book: book,
        title: '${test.title}（${range.$1}〜${range.$2}）',
        tasks: tasks,
      ),
    );
  } else if (world != null) {
    final items = TsuzuriPrep.weakItems(
      services.meta.record,
      world,
      today: RpgServices.today(),
    );
    final questions = <QuizQuestion>[];
    for (final item in items) {
      final set = await services.questions.load(item.setId);
      final q = set?.questions.where((q) => q.id == item.questionId);
      if (q != null && q.isNotEmpty) questions.add(q.first);
    }
    if (questions.length >= TsuzuriPrep.weakMinimum) {
      final progress = await services.repository.load();
      await open(
        quizScreen(
          title: '復習',
          world: RpgCatalog.world(world),
          stage: ReviewTower.stage(
            level: progress.level,
            floor: 1,
            questionCount: questions.length,
            worldId: world,
          ),
          questions: questions,
          progress: progress,
          trial: true,
          mode: BattleMode.review,
        ),
      );
    } else {
      if (range != null && world == 'english') {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('単語帳（LEAP など）を開いておくと、範囲の番号の単語だけで練習できます'),
          ),
        );
      }
      await open(
        SeaHomeScreen(
          personalBooks: services.personalBooks,
          initialSubject: world,
        ),
      );
    }
  } else {
    messenger?.showSnackBar(
      SnackBar(
        content: Text('「${test.subject ?? test.title}」の問題は、まだクエストにありません'),
      ),
    );
    return;
  }
  await services.tsuzuri?.addPrep(test, DateTime.now().difference(started));
}
