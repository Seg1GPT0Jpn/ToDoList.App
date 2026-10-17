import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/practice.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../classroom/classroom_screens.dart';
import '../study/personal_books.dart';
import '../vocab/vocab_home.dart';
import '../vocab/vocab_session_screen.dart';
import '../vocab/vocab_store.dart';
import 'design.dart';
import 'review_tower_screen.dart';

/// 今日の単語の復習の上限（約3分）
const todayVocabCount = 15;

/// ホームの「今日やること」：単語・テスト・冒険の3行だけ。
/// 1つ終えるごとにチェックがつき、全部終わったら「今日はこれでOK」。
/// それ以上は追い立てない。
class TodayPlanCard extends StatefulWidget {
  const TodayPlanCard({super.key, required this.onAdventure});

  /// 冒険に出る
  final VoidCallback onAdventure;

  @override
  State<TodayPlanCard> createState() => _TodayPlanCardState();
}

/// クラスルームの、いちばん近い範囲
class _ClassPlan {
  const _ClassPlan(this.room, this.task, this.left);
  final Classroom room;
  final ClassTask task;

  /// 今日の分の残り（単語帳がなければ null）
  final int? left;
}

class _TodayPlanCardState extends State<TodayPlanCard> {
  Future<_ClassPlan?>? _classPlan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _classPlan ??= _loadClass();
  }

  /// 入っているクラスから、今準備中のいちばん近い範囲をさがす
  Future<_ClassPlan?> _loadClass() async {
    final services = RpgServices.of(context);
    final backend = services.classrooms;
    final codes = services.classroomStore.codes;
    if (backend == null || backend.userId == null || codes.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    final store = VocabStore.of(services.personalBooks);
    _ClassPlan? best;
    for (final code in codes) {
      Classroom? room;
      try {
        room = await backend.fetch(code);
      } catch (_) {
        continue;
      }
      if (room == null || room.closed) continue;
      for (final t in room.upcoming(now)) {
        if (!t.active(now)) continue;
        if (best != null && !t.date.isBefore(best.task.date)) continue;
        final book = ClassBooks.match(t, store.visibleBooks);
        best = _ClassPlan(
          room,
          t,
          book == null
              ? null
              : ClassPlanner.today(
                  t,
                  t.cardsIn(book),
                  store.progress(book.id),
                  now,
                ).length,
        );
      }
    }
    return best;
  }

  static const _finalKey = 'final_check_day';

  /// 明日か今日が試験の日なら、その試験の名前
  String? _eveExam(_ClassPlan? plan, DateTime now) {
    if (plan != null && FinalCheck.isEve(plan.task.daysLeft(now))) {
      final t = plan.task;
      return t.title.isEmpty ? t.kind.label : t.title;
    }
    final today = DateTime(now.year, now.month, now.day);
    for (final w in RpgServices.of(context).examWorlds.load()) {
      final d = w.examDate;
      if (d == null) continue;
      final left = DateTime(d.year, d.month, d.day).difference(today).inDays;
      if (FinalCheck.isEve(left)) return w.title;
    }
    return null;
  }

  /// 最終チェック：最近間違えた問題で、確認用のバトル
  Future<void> _finalCheck(List<ReviewItem> items) async {
    final services = RpgServices.of(context);
    final questions = <QuizQuestion>[];
    for (final item in items) {
      final set = await services.questions.load(item.setId);
      final q = set?.questions.where((q) => q.id == item.questionId);
      if (q != null && q.isNotEmpty) questions.add(q.first);
    }
    final progress = await services.repository.load();
    if (!mounted || questions.isEmpty) return;
    final worldId = LearningRecord.subjectOf(items.first.setId);
    final world = RpgCatalog.worlds.firstWhere(
      (w) => w.id == worldId,
      orElse: () => RpgCatalog.worlds.first,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: world,
          stage: ReviewTower.stage(
            level: progress.level,
            floor: 1,
            questionCount: questions.length,
            worldId: world.id,
          ),
          questions: questions,
          progress: progress,
          trial: true,
          mode: BattleMode.review,
        ),
      ),
    );
    await services.personalBooks.prefs.setInt(_finalKey, RpgServices.today());
    if (mounted) setState(() {});
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() => _classPlan = _loadClass());
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return ListenableBuilder(
      listenable: services.meta,
      builder: (context, _) {
        final now = DateTime.now();
        final today = RpgServices.today();
        final record = services.meta.record;
        final store = VocabStore.of(services.personalBooks);
        final vocab = _vocabRow(store, now);
        final adventureDone = record.studyDays.contains(today);
        return FutureBuilder<_ClassPlan?>(
          future: _classPlan,
          builder: (context, snap) {
            final test = _testRow(snap.data, record, today, now);
            final rows = [vocab, test, _adventureRow(adventureDone)];
            final allDone = rows.every((r) => r.done);
            return PaperCard(
              key: const ValueKey('today-plan'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('今日やること', style: serif(16)),
                  const SizedBox(height: 4),
                  for (final r in rows) _row(r),
                  if (allDone)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '今日はこれでOK！ おつかれさま',
                        key: const ValueKey('today-all-done'),
                        textAlign: TextAlign.center,
                        style: serif(15, color: TsuzuriColors.stamp),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(_Row r) => InkWell(
    key: ValueKey('today-${r.id}'),
    onTap: r.onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(
            r.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: r.done ? TsuzuriColors.correct : TsuzuriColors.inkSoft,
            size: 22,
          ),
          const SizedBox(width: 10),
          Icon(r.icon, size: 20, color: TsuzuriColors.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              r.text,
              style: TextStyle(
                fontSize: 14,
                color: r.done ? TsuzuriColors.inkSoft : TsuzuriColors.ink,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: TsuzuriColors.inkSoft),
        ],
      ),
    ),
  );

  /// 単語：復習の日が来た単語から、約3分ぶん
  _Row _vocabRow(VocabStore store, DateTime now) {
    final services = RpgServices.of(context);
    final books = [
      for (final b in store.visibleBooks)
        if (b.cards.isNotEmpty) b,
    ];
    if (books.isEmpty) {
      return _Row(
        id: 'vocab',
        icon: Icons.menu_book,
        text: '単語帳をはじめる',
        done: false,
        onTap: () => _push(_VocabPage(books: services.personalBooks)),
      );
    }
    var answered = 0;
    VocabBook? best;
    var bestTasks = const <VocabTask>[];
    for (final b in books) {
      final p = store.progress(b.id);
      answered += p.days[BookProgress.dayKey(now)]?.answered ?? 0;
      final tasks = VocabPlanner.today(b, p, now);
      if (tasks.length > bestTasks.length) {
        best = b;
        bestTasks = tasks;
      }
    }
    final done = answered >= todayVocabCount || bestTasks.isEmpty;
    final n = bestTasks.length.clamp(0, todayVocabCount);
    return _Row(
      id: 'vocab',
      icon: Icons.menu_book,
      text: done
          ? '単語：今日は $answered問（おわり）'
          : '単語の復習：${best!.title} $n問（約${(n / 5).ceil()}分）',
      done: done,
      onTap: done || best == null
          ? () => _push(_VocabPage(books: services.personalBooks))
          : () => _push(
              VocabSessionScreen(
                store: store,
                book: best!,
                title: '今日の3分',
                tasks: bestTasks.take(todayVocabCount).toList(),
              ),
            ),
    );
  }

  /// テスト：クラスの範囲があればその今日の分、なければ復習のおすすめ
  _Row _testRow(
    _ClassPlan? plan,
    LearningRecord record,
    int today,
    DateTime now,
  ) {
    final eve = _eveExam(plan, now);
    if (eve != null) {
      final prefs = RpgServices.of(context).personalBooks.prefs;
      final done = prefs.getInt(_finalKey) == today;
      final items = FinalCheck.pick(record, today: today);
      if (done || items.isNotEmpty) {
        return _Row(
          id: 'test',
          icon: Icons.nightlight_round,
          text: done
              ? '「$eve」の最終チェック：おわり。今日は早めに休もう'
              : '「$eve」の最終チェック：最近間違えた${items.length}問',
          done: done,
          onTap: done ? () {} : () => _finalCheck(items),
        );
      }
    }
    if (plan != null) {
      final t = plan.task;
      final name = t.title.isEmpty ? t.kind.label : t.title;
      final left = plan.left;
      final days = t.daysLeft(now);
      final when = days <= 0 ? '今日' : 'あと$days日';
      return _Row(
        id: 'test',
        icon: Icons.edit_note,
        text: left == null
            ? '「$name」（$when）：単語帳を開くと準備できます'
            : left == 0
            ? '「$name」（$when）：今日の分はおわり'
            : '「$name」（$when）：今日の分 $left問',
        done: left == 0,
        onTap: () => _push(ClassroomScreen(code: plan.room.code)),
      );
    }
    final r = StudyNavigator.today(record, today: today).firstOrNull;
    if (r == null) {
      return _Row(
        id: 'test',
        icon: Icons.edit_note,
        text: 'テスト対策：今日の復習はありません',
        done: true,
        onTap: () {},
      );
    }
    return _Row(
      id: 'test',
      icon: Icons.edit_note,
      text: 'テスト対策：${r.text}',
      done: false,
      onTap: () async {
        if (r.stage != null) {
          await startPractice(context, r.stage!);
          if (mounted) setState(() {});
        } else {
          await _push(const ReviewTowerScreen());
        }
      },
    );
  }

  _Row _adventureRow(bool done) => _Row(
    id: 'adventure',
    icon: Icons.sports_martial_arts,
    text: done ? '冒険：今日も戦った' : '冒険：1戦だけ',
    done: done,
    onTap: widget.onAdventure,
  );
}

class _Row {
  const _Row({
    required this.id,
    required this.icon,
    required this.text,
    required this.done,
    required this.onTap,
  });
  final String id;
  final IconData icon;
  final String text;
  final bool done;
  final VoidCallback onTap;
}

/// ホームから開く単語帳
class _VocabPage extends StatelessWidget {
  const _VocabPage({required this.books});
  final PersonalBooks books;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('単語帳', style: serif(18))),
    body: NotebookPaper(child: VocabHome(books: books)),
  );
}
