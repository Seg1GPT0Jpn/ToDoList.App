import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../classroom/classroom_screens.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../battle/battle_screen.dart';
import '../study/common_test_screens.dart';
import '../study/comprehensive_exam_screen.dart';
import '../study/sea_home_screen.dart';
import '../study/sky_home_screen.dart';
import '../versus/contest_screens.dart';
import '../versus/duel_screens.dart';
import '../versus/versus_screen.dart';
import '../vocab/vocab_store.dart';
import '../vocab/word_forest_screen.dart';
import 'achievements_screen.dart';
import 'equipment_screen.dart';
import 'growth_screen.dart';
import 'navigator_card.dart';
import 'story_screen.dart';
import 'streak_store.dart';
import 'learning_status_screen.dart';
import 'question_library_screen.dart';
import 'bestiary_screen.dart';
import 'design.dart';
import 'review_tower_screen.dart';
import 'settings_screen.dart';
import '../cloud/cloud_sync.dart';

/// ホームの「冒険の手帳」：称号・連続日数・次の目標・デイリークエスト・教科レベル
class AdventureCard extends StatelessWidget {
  const AdventureCard({super.key, required this.progress});

  final RpgProgress progress;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final meta = services.meta;
    return ListenableBuilder(
      listenable: Listenable.merge([
        meta,
        services.homeFeatures,
        services.settings,
      ]),
      builder: (context, _) {
        final today = RpgServices.today();
        final record = meta.record;
        final journal = meta.journal;
        final quests = DailyQuests.forDay(
          today,
          services.questSubjects(progress),
        );
        final qs = journal.quest.day == today
            ? journal.quest
            : QuestState(day: today);
        // 学習ナビと同じ数え方（復習の日が来た問題の数）
        final due = record.stats.values.where((s) => s.isDue(today)).length;
        final open = HomeFeature.open(
          progress,
          all: services.settings.value.allFeatures,
        );
        services.homeFeatures.prepare(open);
        final next = services.settings.value.allFeatures
            ? null
            : HomeFeature.next(progress);
        return PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 18,
                    color: TsuzuriColors.accent,
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(child: Text('冒険の手帳', style: serif(15))),
                  if (journal.title.isNotEmpty)
                    _Tag('〈${journal.title}〉', TsuzuriColors.accent),
                  const SizedBox(width: Space.xs),
                  const StreakTag(),
                ],
              ),
              const SizedBox(height: Space.s),
              _NextGoal(progress: progress, due: due),
              const SizedBox(height: Space.s),
              NavigatorCard(record: record, today: today),
              const SizedBox(height: Space.s),
              _DailyChallengeCard(progress: progress, day: today),
              const SizedBox(height: Space.s),
              if (quests.isNotEmpty) ...[
                const Text(
                  '今日のクエスト',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                for (final q in quests)
                  _QuestRow(
                    quest: q,
                    value: qs.progress[q.id] ?? 0,
                    claimed: qs.claimed.contains(q.id),
                    onClaim: () => _claim(context, q, qs),
                  ),
              ],
              const SizedBox(height: Space.s),
              _SubjectLevels(record: record),
              const SizedBox(height: Space.s),
              _MenuGroups(progress: progress, open: open, due: due),
              if (next != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.s),
                  child: Text(
                    '🔒 エリアをあと ${next.clears - progress.clearedStageIds.length} つクリアすると「${next.label}」が使えるようになります',
                    key: const ValueKey('home-next-feature'),
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _claim(BuildContext context, QuestDef q, QuestState s) async {
    final services = RpgServices.of(context);
    final latest = await services.repository.load();
    final r = Progression.addExp(latest, q.rewardExp);
    await services.repository.save(r.progress);
    await services.meta.save(
      journal: services.meta.journal.copyWith(
        quest: QuestState(
          day: s.day,
          progress: s.progress,
          claimed: {...s.claimed, q.id},
        ),
      ),
    );
    final leveled = r.after.level > r.before.level;
    if (leveled) {
      services.music.jingle('levelup');
    } else {
      services.music.se('se_chest');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          leveled
              ? '経験値 +${q.rewardExp}！ レベル ${r.after.level} になった！'
              : '経験値 +${q.rewardExp} を受け取った！',
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Radii.chip),
      border: Border.all(color: color),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: color)),
  );
}

/// 次にやること（迷わないように1つだけ示す）
class _NextGoal extends StatelessWidget {
  const _NextGoal({required this.progress, required this.due});
  final RpgProgress progress;
  final int due;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    String text;
    if (due > 0) {
      text = '復習の塔で $due 問の復習が待っています';
    } else {
      text = '全エリア制覇！ 復習の塔で知識をみがこう';
      outer:
      for (final w in RpgCatalog.worlds) {
        if (services.unlock.availabilityOf(progress, w) !=
            WorldAvailability.playable) {
          continue;
        }
        for (final s in w.stages) {
          if (!progress.clearedStageIds.contains(s.id)) {
            text = '${w.subject}「${s.name}」をクリアしよう';
            break outer;
          }
        }
      }
    }
    return Row(
      children: [
        const Icon(Icons.flag, size: 16, color: TsuzuriColors.stamp),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            '次の目標：$text',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.quest,
    required this.value,
    required this.claimed,
    required this.onClaim,
  });

  final QuestDef quest;
  final int value;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final done = value >= quest.goal;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        children: [
          Icon(
            claimed
                ? Icons.check_circle
                : done
                ? Icons.card_giftcard
                : Icons.radio_button_unchecked,
            size: 16,
            color: done ? TsuzuriColors.correct : TsuzuriColors.inkSoft,
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    fontSize: 12,
                    decoration: claimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (value / quest.goal).clamp(0, 1),
                    minHeight: 4,
                    backgroundColor: TsuzuriColors.tint(0xFFEDE3D1),
                    color: TsuzuriColors.exp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s),
          if (done && !claimed)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: onClaim,
              child: Text('+${quest.rewardExp}EXP'),
            )
          else
            Text(
              '${value.clamp(0, quest.goal)}/${quest.goal}',
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }
}

/// 教科レベル（習得した問題の数で上がる）
class _SubjectLevels extends StatelessWidget {
  const _SubjectLevels({required this.record});
  final LearningRecord record;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final w in RpgCatalog.worlds) {
      if (record.answeredCount(w.id) == 0) continue;
      final m = record.masteredCount(w.id);
      final lv = LearningRecord.levelFor(m);
      final next = LearningRecord.masteredForLevel(lv + 1) - m;
      final color = subjectColors[w.id] ?? TsuzuriColors.accent;
      chips.add(
        Tooltip(
          message: '習得 $m 問。あと $next 問でレベル ${lv + 1}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.chip),
              border: Border.all(color: color),
            ),
            child: Text(
              '${w.subject} Lv$lv（あと$next）',
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ),
      );
    }
    if (chips.isEmpty) {
      return Text(
        '問題を解くと、教科ごとのレベルがここに出ます（3回続けて正解で「習得」）',
        style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
      );
    }
    return Wrap(spacing: Space.xs, runSpacing: Space.xs, children: chips);
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    this.feature,
    this.id,
    required this.icon,
    required this.label,
    required this.builder,
    this.highlight = false,
  });

  /// NEW を出す機能（いつも出ている入口は null）
  final HomeFeature? feature;

  /// [feature] がないときのキーの名前
  final String? id;
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
  final bool highlight;

  String get _key => feature?.name ?? id!;

  bool fresh(RpgServices services) =>
      feature != null && services.homeFeatures.isNew(feature!);

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final fresh = this.fresh(services);
    void open() {
      services.music.se('se_tap');
      if (feature != null) services.homeFeatures.markSeen(feature!);
      Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    }

    final text = fresh
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label)),
              const SizedBox(width: 6),
              Container(
                key: ValueKey('home-new-$_key'),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: TsuzuriColors.stamp,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          )
        : Text(label);
    return highlight || fresh
        ? FilledButton.icon(
            key: ValueKey('home-feature-$_key'),
            onPressed: open,
            icon: Icon(icon, size: 18),
            label: text,
          )
        : OutlinedButton.icon(
            key: ValueKey('home-feature-$_key'),
            onPressed: open,
            icon: Icon(icon, size: 18),
            label: text,
          );
  }
}

/// 今日の挑戦状：クリアしたエリアから、日替わりで強化された魔物が1体現れる
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.progress, required this.day});

  final RpgProgress progress;
  final int day;

  Future<void> _start(BuildContext context, StageDef stage) async {
    final services = RpgServices.of(context);
    final pool = await services.loadStagePool(stage);
    final latest = await services.repository.load();
    if (pool == null || !pool.origin.usableInRpg || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(stage.worldId),
          stage: stage,
          questions: pool.questions,
          progress: latest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = DailyChallenge.of(progress, day);
    if (stage == null) return const SizedBox.shrink();
    final done = DailyChallenge.done(progress, day);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TsuzuriColors.tint(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9822B), width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: CustomPaint(painter: _LookPainter(stage.enemy)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📜 今日の挑戦状',
                  style: serif(13, color: const Color(0xFFB0601A)),
                ),
                Text(
                  '${stage.enemy.name}（${RpgCatalog.world(stage.worldId).subject}・${stage.enemy.effectiveAbility == EnemyAbility.none ? '能力なし' : stage.enemy.effectiveAbility.label}）',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  done
                      ? '今日はたおした！ また明日、別の魔物が現れる'
                      : 'たおすと経験値 ${stage.expReward}（ふつうの3倍）',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9822B),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: done ? null : () => _start(context, stage),
            child: Text(done ? '達成' : '挑む'),
          ),
        ],
      ),
    );
  }
}

class _LookPainter extends CustomPainter {
  _LookPainter(this.enemy);
  final EnemyDef enemy;
  @override
  void paint(Canvas canvas, Size size) => paintEnemy(
    canvas,
    size.shortestSide,
    enemy.look,
    0.5,
    color: enemy.color,
  );
  @override
  bool shouldRepaint(_LookPainter old) => false;
}

/// ホームの入口のまとまり
enum _Group {
  rpg('RPG', Icons.shield_outlined),
  exam('定期テスト・模擬試験', Icons.sailing_outlined),
  common('共通テスト・総合演習', Icons.account_balance_outlined),
  versus('対戦・クラスルーム', Icons.sports_esports_outlined),
  records('記録・設定', Icons.insights);

  const _Group(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 冒険の手帳の下の入口。まとまりごとのタブで切りかえて、1つのまとまりだけを出す
class _MenuGroups extends StatefulWidget {
  const _MenuGroups({
    required this.progress,
    required this.open,
    required this.due,
  });

  final RpgProgress progress;
  final List<HomeFeature> open;
  final int due;

  @override
  State<_MenuGroups> createState() => _MenuGroupsState();
}

class _MenuGroupsState extends State<_MenuGroups> {
  /// アプリを開いているあいだは、最後に選んだまとまりを覚えておく
  static _Group _last = _Group.rpg;
  _Group _group = _last;

  /// クラウド（Firebase）を使う機能を出すか（小中学生版は Firebase を設定するまで出さない）
  static bool get _cloud => !juniorEdition || CloudSync.configured;

  Map<_Group, List<_MenuButton>> _items(BuildContext context) {
    final services = RpgServices.of(context);
    final progress = widget.progress, open = widget.open, due = widget.due;
    final record = services.meta.record;
    final today = RpgServices.today();
    final claimable = Gear.claimable(progress, record, today).isNotEmpty;
    final tower = _MenuButton(
      feature: HomeFeature.reviewTower,
      icon: Icons.castle_outlined,
      label: due > 0 ? '復習の塔（$due）' : '復習の塔',
      highlight: due > 0,
      builder: (_) => const ReviewTowerScreen(),
    );
    bool has(HomeFeature f) => open.contains(f);
    return {
      _Group.rpg: [
        if (has(HomeFeature.story))
          _MenuButton(
            feature: HomeFeature.story,
            icon: Icons.menu_book_outlined,
            label:
                '物語（${juniorEdition ? '証' : '欠片'} ${Story.fragments(progress).length}/${Story.worlds.length}）',
            builder: (_) => const StoryScreen(),
          ),
        if (has(HomeFeature.gear))
          _MenuButton(
            feature: HomeFeature.gear,
            icon: Icons.shield_outlined,
            label: claimable ? '装備・職業（ごほうび！）' : '装備・職業',
            highlight: claimable,
            builder: (_) => const EquipmentScreen(),
          ),
        if (has(HomeFeature.reviewTower)) tower,
      ],
      _Group.exam: [
        _MenuButton(
          id: 'sea',
          icon: Icons.sailing_outlined,
          label: '定期テストの海',
          builder: (_) => SeaHomeScreen(personalBooks: services.personalBooks),
        ),
        if (has(HomeFeature.sky))
          _MenuButton(
            feature: HomeFeature.sky,
            icon: Icons.rocket_launch_outlined,
            label: StudyRealm.sky.title,
            builder: (_) => const SkyHomeScreen(),
          ),
        if (has(HomeFeature.reviewTower)) tower,
        if (has(HomeFeature.wordForest))
          _MenuButton(
            feature: HomeFeature.wordForest,
            icon: Icons.forest_outlined,
            label: '単語の森',
            builder: (_) => const WordForestScreen(),
          ),
      ],
      // 小中学生版には共通テスト・総合演習（高校生向け）はない
      _Group.common: [
        if (!juniorEdition && has(HomeFeature.commonTest))
          _MenuButton(
            feature: HomeFeature.commonTest,
            icon: Icons.account_balance_outlined,
            label: '共通テスト遺跡',
            builder: (_) => const CommonTestRuinsScreen(),
          ),
        if (!juniorEdition && has(HomeFeature.comprehensive))
          _MenuButton(
            feature: HomeFeature.comprehensive,
            icon: Icons.assignment_outlined,
            label: '総合演習',
            builder: (_) => const ComprehensiveExamScreen(subject: 'math'),
          ),
      ],
      _Group.versus: [
        if (has(HomeFeature.versus))
          _MenuButton(
            feature: HomeFeature.versus,
            icon: Icons.sports_esports_outlined,
            label: '対戦モード',
            builder: (_) => const VersusSetupScreen(),
          ),
        // クラスルーム・単語チャレンジは Firebase が必要（小中学生版は設定するまで出さない）
        if (has(HomeFeature.classroom) && _cloud)
          _MenuButton(
            feature: HomeFeature.classroom,
            icon: Icons.groups_outlined,
            label: 'クラスルーム',
            builder: (_) => const ClassroomHubScreen(),
          ),
        if (!juniorEdition)
          _MenuButton(
            id: 'contest',
            icon: Icons.emoji_events_outlined,
            label: '週替わり単語バトル（LEAP・EEVI）',
            builder: (_) => const ContestScreen(),
          ),
        if (_cloud)
          _MenuButton(
            id: 'duel',
            icon: Icons.flash_on,
            label: '単語チャレンジ',
            builder: (_) => const DuelHubScreen(),
          ),
      ],
      _Group.records: [
        if (has(HomeFeature.learningStatus))
          _MenuButton(
            feature: HomeFeature.learningStatus,
            icon: Icons.insights,
            label: '学習ステータス',
            builder: (_) => const LearningStatusScreen(),
          ),
        if (has(HomeFeature.library))
          _MenuButton(
            feature: HomeFeature.library,
            icon: Icons.library_books_outlined,
            label: '問題集・解説',
            builder: (_) => const QuestionLibraryScreen(),
          ),
        if (has(HomeFeature.growth))
          _MenuButton(
            feature: HomeFeature.growth,
            icon: Icons.alt_route,
            label: '成長と学習ルート',
            builder: (_) => const GrowthScreen(),
          ),
        if (has(HomeFeature.bestiary))
          _MenuButton(
            feature: HomeFeature.bestiary,
            icon: Icons.pets,
            label: '魔物図鑑',
            builder: (_) => const BestiaryScreen(),
          ),
        if (has(HomeFeature.achievements))
          _MenuButton(
            feature: HomeFeature.achievements,
            icon: Icons.emoji_events_outlined,
            label: '実績・称号',
            builder: (_) => const AchievementsScreen(),
          ),
        if (has(HomeFeature.settings))
          _MenuButton(
            feature: HomeFeature.settings,
            icon: Icons.settings_outlined,
            label: '設定',
            builder: (_) => const SettingsScreen(),
          ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final items = _items(context);
    final groups = [
      for (final g in _Group.values)
        if (items[g]!.isNotEmpty) g,
    ];
    final group = groups.contains(_group) ? _group : groups.first;
    final store = VocabStore.of(services.personalBooks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEAP・EEVI のバトルの日は、どのまとまりを見ていても出す
        if (store.unlocked) ContestEntryButton(store: store, onlyActive: true),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final g in groups)
              ChoiceChip(
                key: ValueKey('home-group-${g.name}'),
                avatar: Icon(g.icon, size: 16),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(g.label, style: const TextStyle(fontSize: 12)),
                    // まだ開いていない機能や、やることがあるまとまりに印をつける
                    if (g != group &&
                        items[g]!.any((b) => b.highlight || b.fresh(services)))
                      Container(
                        key: ValueKey('home-group-dot-${g.name}'),
                        margin: const EdgeInsets.only(left: 4),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: TsuzuriColors.stamp,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                selected: g == group,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _group = _last = g),
              ),
          ],
        ),
        const SizedBox(height: Space.s),
        Wrap(
          key: ValueKey('home-group-body-${group.name}'),
          spacing: Space.s,
          runSpacing: Space.xs,
          children: items[group]!,
        ),
      ],
    );
  }
}
