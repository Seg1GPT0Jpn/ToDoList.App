import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../app/quiz_screen.dart';

/// 選んだ問題で、確認用のバトルを始める
Future<void> startItemsBattle(
  BuildContext context,
  List<ReviewItem> items,
) async {
  final services = RpgServices.of(context);
  final nav = Navigator.of(context);
  final questions = <QuizQuestion>[];
  for (final item in items) {
    final set = await services.questions.load(item.setId);
    final q = set?.questions.where((q) => q.id == item.questionId);
    if (q != null && q.isNotEmpty) questions.add(q.first);
  }
  if (questions.isEmpty) return;
  final progress = await services.repository.load();
  final worldId = LearningRecord.subjectOf(items.first.setId);
  final world = RpgCatalog.worlds.firstWhere(
    (w) => w.id == worldId,
    orElse: () => RpgCatalog.worlds.first,
  );
  await nav.push(
    MaterialPageRoute<void>(
      builder: (_) => quizScreen(
        title: '復習',
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
}

String _minutes(int m) => m < 60 ? '$m分' : '${m ~/ 60}時間${m % 60}分';

/// ホームの「ひと息で」：おかえり・1分だけ・まぜて練習・週のふりかえり
class StudyBoostCard extends StatelessWidget {
  const StudyBoostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([services.meta, services.studyLog]),
      builder: (context, _) {
        final record = services.meta.record;
        final today = RpgServices.today();
        final oneMinute = StudyBoost.oneMinute(record, today);
        if (oneMinute.length < 3) return const SizedBox.shrink();
        final away = StudyBoost.daysAway(record, today);
        final welcome = StudyBoost.welcomeBack(record, today);
        final mixSubjects = StudyBoost.mixSubjects(record);
        final week = WeeklyReflection.of(services.studyLog.log, DateTime.now());
        final next = StudyNavigator.today(record, today: today);
        final small = TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft);
        return Card(
          key: const ValueKey('study-boost'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (welcome.isNotEmpty) ...[
                  Text('おかえり！ $away日ぶりだね', style: serif(16)),
                  const SizedBox(height: 2),
                  Text(
                    'まずは前に解いた問題を${welcome.length}問だけ。思い出すところから始めよう',
                    style: small,
                  ),
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    key: const ValueKey('welcome-back'),
                    onPressed: () => startItemsBattle(context, welcome),
                    icon: const Icon(Icons.waving_hand_outlined, size: 18),
                    label: const Text('おかえり復習'),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('one-minute'),
                      onPressed: () => startItemsBattle(context, oneMinute),
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('1分だけ'),
                    ),
                    if (mixSubjects.isNotEmpty)
                      OutlinedButton.icon(
                        key: const ValueKey('mix-practice'),
                        onPressed: () => _pickMix(context, mixSubjects),
                        icon: const Icon(Icons.shuffle, size: 18),
                        label: const Text('まぜて練習'),
                      ),
                  ],
                ),
                if (week != null) ...[
                  const SizedBox(height: 10),
                  Text('この1週間のふりかえり', style: serif(14)),
                  const SizedBox(height: 2),
                  Text(
                    '${_minutes(week.thisWeek.minutes)}・${week.thisWeek.answered}問'
                    '（先週より${week.deltaMinutes >= 0 ? '+' : '−'}${_minutes(week.deltaMinutes.abs())}）'
                    '　勉強した日 ${week.daysStudied}/7日',
                    key: const ValueKey('weekly-reflection'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (week.bestSubject case final s?)
                    Text(
                      'いちばんがんばった教科：${RpgCatalog.worlds.where((w) => w.id == s).firstOrNull?.subject ?? s}',
                      style: small,
                    ),
                  if (next.isNotEmpty)
                    Text('次の1手：${next.first.text}', style: small),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickMix(BuildContext context, List<String> subjects) async {
    final services = RpgServices.of(context);
    final subject = subjects.length == 1
        ? subjects.single
        : await showModalBottomSheet<String>(
            context: context,
            builder: (c) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text('まぜて練習'),
                    subtitle: Text('解いたことのある単元を交互に出します。見分ける力がつきます'),
                  ),
                  for (final s in subjects)
                    ListTile(
                      key: ValueKey('mix-$s'),
                      title: Text(
                        RpgCatalog.worlds
                                .where((w) => w.id == s)
                                .firstOrNull
                                ?.subject ??
                            s,
                      ),
                      onTap: () => Navigator.of(c).pop(s),
                    ),
                ],
              ),
            ),
          );
    if (subject == null || !context.mounted) return;
    final items = StudyBoost.mix(
      services.meta.record,
      subject,
      today: RpgServices.today(),
    );
    if (items.isEmpty) return;
    await startItemsBattle(context, items);
  }
}
