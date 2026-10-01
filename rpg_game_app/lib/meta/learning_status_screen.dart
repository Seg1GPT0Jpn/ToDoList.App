import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../app/practice.dart';
import 'curriculum_map_screen.dart';

/// 学習ステータス：実際の正答率から計算した、分野ごとの熟練度。
///
/// ゲームのレベル（冒険Lv）とは別に、教科ごとの学習Lvと総合力を出す。
/// 「冒険Lv.35 だけど数学の確率が苦手」がひと目で分かるようにする。
class LearningStatusScreen extends StatelessWidget {
  const LearningStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return StreamBuilder<RpgProgress>(
      stream: services.repository.watch(),
      builder: (context, snap) {
        final progress = snap.data ?? RpgProgress.initial;
        final record = services.meta.record;
        final subjects = Proficiency.bySubject(record);
        final total = Proficiency.totalPower(record);
        final weak = Proficiency.weakestUnits(record);
        return Scaffold(
          appBar: AppBar(title: Text('学習ステータス', style: serif(18))),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Row(
                  children: [
                    _BigStat(label: '冒険Lv', value: '${progress.level}'),
                    const SizedBox(width: 10),
                    _BigStat(
                      label: '総合力',
                      value: '$total',
                      color: TsuzuriColors.stamp,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '熟練度は、ゲームで勝手に上がる数字ではなく、実際に答えた正答率から計算しています。'
                  '5問以上答えた分野だけ判定します。総合力は、6教科すべての熟練度の平均（答えていない教科は0）。',
                  style: TextStyle(
                    fontSize: 12,
                    color: TsuzuriColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    key: const ValueKey('open-curriculum-map'),
                    leading: Icon(
                      Icons.map_outlined,
                      color: TsuzuriColors.accent,
                    ),
                    title: const Text('学びの地図'),
                    subtitle: const Text('教科→科目→分野→単元→小単元ごとの進みぐあいと、単元ごとの練習'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CurriculumMapScreen(),
                      ),
                    ),
                  ),
                ),
                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('苦手な単元', style: serif(16)),
                  for (final (stage, score) in weak)
                    Card(
                      margin: const EdgeInsets.only(top: 6),
                      child: ListTile(
                        dense: true,
                        leading: _ScoreBadge(score.score),
                        title: Text(
                          '${RpgCatalog.world(stage.worldId).subject}・${stage.grammarTheme}',
                        ),
                        subtitle: Text(
                          '${stage.name}・${score.attempts}回答えて正答率${score.score}%',
                        ),
                        trailing: TextButton(
                          onPressed: () => startPractice(context, stage),
                          child: const Text('練習'),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 14),
                for (final w in RpgCatalog.worlds)
                  _SubjectCard(
                    world: w,
                    level: Proficiency.subjectLevel(record, w.id),
                    fields: subjects[w.id] ?? const [],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            Text(value, style: serif(26, color: color ?? TsuzuriColors.accent)),
          ],
        ),
      ),
    ),
  );
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge(this.score);
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? TsuzuriColors.correct
        : score >= 60
        ? TsuzuriColors.exp
        : TsuzuriColors.wrong;
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.world,
    required this.level,
    required this.fields,
  });

  final WorldDef world;
  final int level;
  final List<SkillScore> fields;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(world.subject, style: serif(16)),
                const SizedBox(width: 8),
                Text(
                  '学習Lv $level',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TsuzuriColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final f in fields)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        f.field,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: f.rated ? f.score / 100 : 0,
                          minHeight: 8,
                          backgroundColor: TsuzuriColors.gridLine,
                          color: f.score >= 80
                              ? TsuzuriColors.correct
                              : f.score >= 60
                              ? TsuzuriColors.exp
                              : TsuzuriColors.wrong,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        f.rated ? '${f.score}' : '—',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
