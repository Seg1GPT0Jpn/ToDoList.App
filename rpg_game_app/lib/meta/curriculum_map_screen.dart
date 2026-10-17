import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/practice.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'design.dart';

/// 学びの地図：教科 → 科目 → 分野 → 単元 → 小単元 の学習体系と、
/// それぞれの進みぐあい（問題数・答えた数・正答率・習得率）を見る画面。
///
/// ゲームのマップ（ルート・エリア）よりも細かい「学習の分類」を見せる。
/// 単元を選ぶと、その単元の問題だけで練習できる。
class CurriculumMapScreen extends StatefulWidget {
  const CurriculumMapScreen({super.key, this.initialSubject});

  final String? initialSubject;

  @override
  State<CurriculumMapScreen> createState() => _CurriculumMapScreenState();
}

class _CurriculumMapScreenState extends State<CurriculumMapScreen> {
  late String _subject = widget.initialSubject ?? Curriculum.subjects.first.id;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return ListenableBuilder(
      listenable: services.meta,
      builder: (context, _) {
        final progress = CurriculumProgress.of(services.meta.record);
        final subject = Curriculum.node(_subject);
        final color = subjectColors[_subject] ?? TsuzuriColors.accent;
        final s = progress[_subject];
        return Scaffold(
          appBar: AppBar(title: Text('学びの地図', style: serif(18))),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.margin,
                Space.m,
                Space.l,
                Space.xl,
              ),
              children: [
                _SubjectChips(
                  selected: _subject,
                  onSelected: (id) => setState(() => _subject = id),
                ),
                const SizedBox(height: Space.m),
                PaperCard(
                  border: color,
                  child: Row(
                    children: [
                      Icon(subjectIcons[_subject], color: color, size: 32),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${subject.name}（${subject.displayName}）',
                              style: serif(17),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '問題 ${s.questionCount}問・答えた ${s.answered}問'
                              '${s.accuracy == null ? '' : '・正答率 ${s.accuracy}%'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: TsuzuriColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _Bars(progress: s, color: color),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.s),
                Text(
                  '学習指導要領の分類をもとに、教科 → 科目 → 分野 → 単元 → 小単元 に分けています。'
                  '単元をタップすると、くわしい中身とその単元だけの練習ができます。',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
                const SizedBox(height: Space.m),
                for (final course in subject.children)
                  _CourseCard(
                    course: course,
                    progress: progress,
                    color: color,
                    initiallyExpanded: subject.children.length == 1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubjectChips extends StatelessWidget {
  const _SubjectChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.s,
    runSpacing: Space.s,
    children: [
      for (final s in Curriculum.subjects)
        ChoiceChip(
          key: ValueKey('subject-${s.id}'),
          avatar: Icon(subjectIcons[s.id], size: 16),
          label: Text(s.name),
          selected: s.id == selected,
          selectedColor: (subjectColors[s.id] ?? TsuzuriColors.accent)
              .withValues(alpha: 0.25),
          onSelected: (_) => onSelected(s.id),
        ),
    ],
  );
}

/// 答えた割合（うすい色）と習得した割合（こい色）の2本の帯
class _Bars extends StatelessWidget {
  const _Bars({required this.progress, required this.color});

  final NodeProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '答えた割合 ${progress.coverage}%、習得 ${progress.masteryRate}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 7,
        child: Stack(
          children: [
            Container(color: color.withValues(alpha: 0.12)),
            FractionallySizedBox(
              widthFactor: progress.coverage / 100,
              child: Container(color: color.withValues(alpha: 0.35)),
            ),
            FractionallySizedBox(
              widthFactor: progress.masteryRate / 100,
              child: Container(color: color),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.progress,
    required this.color,
    this.initiallyExpanded = false,
  });

  final CurriculumNode course;
  final CurriculumProgress progress;
  final Color color;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = progress[course.id];
    return Card(
      margin: const EdgeInsets.only(bottom: Space.s),
      child: ExpansionTile(
        key: PageStorageKey('course-${course.id}'),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        title: Text(course.name, style: serif(16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.description,
              style: TextStyle(fontSize: 11.5, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 4),
            _Bars(progress: p, color: color),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          Space.m,
          0,
          Space.m,
          Space.m,
        ),
        children: [
          for (final field in course.children)
            _FieldSection(field: field, progress: progress, color: color),
        ],
      ),
    );
  }
}

class _FieldSection extends StatelessWidget {
  const _FieldSection({
    required this.field,
    required this.progress,
    required this.color,
  });

  final CurriculumNode field;
  final CurriculumProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.s),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(field.name, style: serif(14.5))),
            Text(
              '${progress[field.id].questionCount}問',
              style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
            ),
          ],
        ),
        for (final unit in field.children)
          _UnitTile(unit: unit, progress: progress[unit.id], color: color),
      ],
    ),
  );
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    required this.progress,
    required this.color,
  });

  final CurriculumNode unit;
  final NodeProgress progress;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('unit-${unit.id}'),
    borderRadius: BorderRadius.circular(Radii.chip),
    onTap: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UnitSheet(unit: unit, color: color),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.name, style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 3),
                _Bars(progress: progress, color: color),
              ],
            ),
          ),
          const SizedBox(width: Space.s),
          SizedBox(
            width: 64,
            child: Text(
              progress.accuracy == null
                  ? '${progress.questionCount}問'
                  : '正答${progress.accuracy}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: TsuzuriColors.inkSoft),
        ],
      ),
    ),
  );
}

/// 単元のくわしい中身（小単元・学習指導要領での位置・前提）と練習ボタン
class _UnitSheet extends StatelessWidget {
  const _UnitSheet({required this.unit, required this.color});

  final CurriculumNode unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final progress = CurriculumProgress.of(services.meta.record);
    final p = progress[unit.id];
    final field = Curriculum.parent(unit.id);
    final reference = [
      field?.curriculumReference ?? '',
      unit.curriculumReference,
    ].where((s) => s.isNotEmpty).join('／');
    final grade = Curriculum.gradeOf(unit.id);
    final pre = Curriculum.prerequisitesOf(unit.id);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        children: [
          Text(
            Curriculum.breadcrumb(unit.parentId!),
            style: TextStyle(fontSize: 11.5, color: TsuzuriColors.inkSoft),
          ),
          Text(unit.name, style: serif(20)),
          if (unit.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(unit.description),
            ),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.xs,
            children: [
              if (grade.isNotEmpty) _Tag('高$grade', color),
              _Tag('問題 ${p.questionCount}問', color),
              _Tag('答えた ${p.answered}問', color),
              if (p.accuracy != null) _Tag('正答率 ${p.accuracy}%', color),
              if (p.firstTryAccuracy != null)
                _Tag('初回正答率 ${p.firstTryAccuracy}%', color),
              _Tag('習得 ${p.mastered}問', color),
            ],
          ),
          if (reference.isNotEmpty) ...[
            const SizedBox(height: Space.s),
            Text(
              '学習指導要領：$reference',
              style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
            ),
          ],
          if (pre.isNotEmpty) ...[
            const SizedBox(height: Space.m),
            Text('先に学んでおきたいこと', style: serif(14)),
            for (final id in pre)
              if (Curriculum.tryNode(id) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '・${Curriculum.breadcrumb(id)}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
          ],
          const SizedBox(height: Space.m),
          Text('小単元', style: serif(14)),
          for (final sub in unit.children)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(child: Text(sub.name)),
                  Text(
                    progress[sub.id].accuracy == null
                        ? '${progress[sub.id].questionCount}問'
                        : '${progress[sub.id].questionCount}問・'
                              '正答${progress[sub.id].accuracy}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.l),
          FilledButton.icon(
            key: const ValueKey('unit-practice'),
            onPressed: p.questionCount < 4
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final reason = await startUnitPractice(context, unit.id);
                    if (reason != null) {
                      messenger.showSnackBar(SnackBar(content: Text(reason)));
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: color),
            icon: const Icon(Icons.sports_martial_arts),
            label: Text(p.questionCount < 4 ? '問題を準備中' : 'この単元で練習バトル'),
          ),
        ],
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Radii.chip),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11.5)),
  );
}
