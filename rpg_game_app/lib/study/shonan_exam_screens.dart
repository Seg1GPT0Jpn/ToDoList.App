import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import 'ec_text.dart';
import 'school_exam_store.dart';
import 'school_material_screen.dart';
import 'shonan_question_list.dart';

/// 画面に出す文言（ここにまとめる）
class ShonanText {
  const ShonanText._();
  static const title = '湘南高校104回生 定期テスト対策';
  static const localOnly = 'この端末にだけ保存されます。ほかの端末や友だちとは共有されません。';
  static const empty = 'まだテストがありません。「範囲表から作る」か「新しく作る」で追加してください。';
  static const fromTable = '範囲表から作る';
  static const newPlan = '新しく作る';
  static const noDate = '未設定';
  static const noSets = '問題セット未登録';
  static const noSetsHelp = '「編集」から、この科目の問題セット（既存・委員会の新作）を登録すると演習できます。';
  static const noRange = '範囲は未入力です';
  static const practice = '演習する';
  static const existing = '既存の問題セット';
  static const committee = '委員会の新作問題セット';
  static const titleRequired = 'テスト名を入れてください';
  static const deleteConfirm = 'このテストを削除しますか？（この端末から消えます）';
  static const cannotPlay = '演習できる問題がありません';
  static const materialKinds = ['教科書', 'ワーク', '授業プリント', '配布資料', 'その他'];
}

String _ymd(DateTime? d) =>
    d == null ? ShonanText.noDate : '${d.year}/${d.month}/${d.day}';

SchoolExamStore _store(BuildContext context) =>
    SchoolExamStore.of(RpgServices.of(context).personalBooks);

/// テストの一覧
class ShonanExamListScreen extends StatelessWidget {
  const ShonanExamListScreen({super.key});

  Future<void> _fromTable(BuildContext context) async {
    final sheet = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('2026年度（104回生）1年の試験範囲表')),
            for (final (sheet, title) in ShonanRangeTable.sheets)
              ListTile(
                key: ValueKey('shonan-sheet-$sheet'),
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(title),
                onTap: () => Navigator.pop(c, sheet),
              ),
          ],
        ),
      ),
    );
    if (sheet == null || !context.mounted) return;
    final now = DateTime.now();
    final plan = ShonanRangeTable.plan(
      sheet,
      id: 'shonan_${now.microsecondsSinceEpoch}',
      now: now,
    );
    await _store(context).add(plan);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShonanExamDetailScreen(planId: plan.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    return Scaffold(
      appBar: AppBar(title: Text(ShonanText.title, style: serif(17))),
      body: NotebookPaper(
        child: StreamBuilder<List<SchoolExamPlan>>(
          stream: store.watch(),
          builder: (context, snap) {
            final plans = snap.data ?? store.load();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const _Note(
                  text: ShonanText.localOnly,
                  icon: Icons.phone_android,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('shonan-from-table'),
                      onPressed: () => _fromTable(context),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text(ShonanText.fromTable),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('shonan-new'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ShonanExamEditScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text(ShonanText.newPlan),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (SchoolMaterials.all.isNotEmpty) ...[
                  Text('資料（PDF）', style: serif(15)),
                  for (final m in SchoolMaterials.all)
                    Card(
                      child: ListTile(
                        key: ValueKey('shonan-materials-${m.id}'),
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: Text(m.title),
                        subtitle: Text(
                          '${ShonanSubjects.byId(m.subjectId)?.displayName ?? ''}・${m.pages}ページ',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SchoolMaterialScreen(material: m),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                if (plans.isEmpty) const Text(ShonanText.empty),
                for (final p in plans) _PlanCard(plan: p),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final SchoolExamPlan plan;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(plan.title),
        content: const Text(ShonanText.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('shonan-delete-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await _store(context).remove(plan.id);
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: ValueKey('shonan-plan-${plan.id}'),
      title: Text(
        plan.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '試験日：${_ymd(plan.examDate)}\n範囲・問題を登録した科目：${plan.filledCount} / ${ShonanSubjects.all.length}',
      ),
      isThreeLine: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ShonanExamDetailScreen(planId: plan.id),
        ),
      ),
      trailing: PopupMenuButton<String>(
        key: ValueKey('shonan-menu-${plan.id}'),
        onSelected: (v) {
          if (v == 'edit') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ShonanExamEditScreen(plan: plan),
              ),
            );
          } else {
            _delete(context);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('編集')),
          PopupMenuItem(value: 'delete', child: Text('削除')),
        ],
      ),
    ),
  );
}

/// テストの詳細：11科目の範囲・教材と演習
class ShonanExamDetailScreen extends StatelessWidget {
  const ShonanExamDetailScreen({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context) {
    final store = _store(context);
    return StreamBuilder<List<SchoolExamPlan>>(
      stream: store.watch(),
      builder: (context, _) {
        final plan = store.byId(planId);
        if (plan == null) {
          return const Scaffold(body: Center(child: Text('テストが見つかりません')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(plan.title, style: serif(17)),
            actions: [
              TextButton.icon(
                key: const ValueKey('shonan-edit'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShonanExamEditScreen(plan: plan),
                  ),
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('編集'),
              ),
            ],
          ),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text('試験日：${_ymd(plan.examDate)}'),
                Text(
                  '範囲・問題を登録した科目：${plan.filledCount} / ${ShonanSubjects.all.length}',
                ),
                if (ShonanTableSets.missing(plan) case final n when n > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('shonan-add-table-sets'),
                      onPressed: () => store.update(
                        ShonanTableSets.addTo(plan, now: DateTime.now()),
                      ),
                      icon: const Icon(Icons.playlist_add),
                      label: Text('範囲表に合う問題セットを足す（$n個）'),
                    ),
                  ),
                const SizedBox(height: 8),
                for (final s in ShonanSubjects.all)
                  _SubjectCard(plan: plan, subject: s),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.plan, required this.subject});
  final SchoolExamPlan plan;
  final SchoolSubject subject;

  /// 単元ごとに練習する：登録した問題セットの問題を、学習体系の単元ごとに分けて選ぶ
  Future<void> _byUnit(BuildContext context, SubjectExamPlan sp) async {
    final services = RpgServices.of(context);
    final result = await SchoolPractice.build(
      subject,
      sp,
      services.questions.load,
    );
    if (!context.mounted) return;
    final pool = result.pool;
    if (pool == null) return _practice(context, sp);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SchoolUnitScreen(
          title: subject.displayName,
          groups: SchoolUnitGroup.of(pool.questions),
          onPractice: (c, g) => _practice(
            c,
            sp,
            onlyIds: {for (final q in g.questions) q.id},
            label: g.name,
          ),
        ),
      ),
    );
  }

  Future<void> _practice(
    BuildContext context,
    SubjectExamPlan sp, {
    Set<String>? onlyIds,
    String? label,
  }) async {
    final services = RpgServices.of(context);
    final result = await SchoolPractice.build(
      subject,
      sp,
      services.questions.load,
    );
    if (!context.mounted) return;
    if (!result.canPlay) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text(ShonanText.cannotPlay),
          content: Text(
            [
              for (final i in result.issues) '・$i',
              ShonanText.noSetsHelp,
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
      return;
    }
    if (result.issues.isNotEmpty || result.duplicateQuestionIds.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('使えない問題セットがあります'),
          content: Text(
            [
              for (final i in result.issues) '・$i',
              if (result.duplicateQuestionIds.isNotEmpty)
                '・同じ問題IDが複数のセットにあります（1回だけ出題）：${result.duplicateQuestionIds.join('、')}',
              '\n読めたセット（${result.usedSetIds.length}個）だけで演習しますか？',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('やめる'),
            ),
            FilledButton(
              key: const ValueKey('shonan-practice-anyway'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('演習する'),
            ),
          ],
        ),
      );
      if (go != true || !context.mounted) return;
    }
    var questions = [
      for (final q in result.pool!.questions)
        if (onlyIds == null || onlyIds.contains(q.id)) q,
    ];
    // EC は本文を開いていれば、問題の中に本文（その Section）を出す
    if (subject.id == 'ec1') {
      final passages = await EcText.saved(services.personalBooks.prefs);
      if (passages != null) questions = EcText.attach(questions, passages);
    }
    final progress = await services.repository.load();
    if (!context.mounted) return;
    final stage = SeaBattle.stage(
      id: 'shonan_${plan.id}_${subject.id}',
      title: label == null
          ? subject.displayName
          : '${subject.displayName}｜$label',
      worldId: subject.worldId,
      level: progress.level,
      normalTimeLimitSeconds: 20,
      questionSetIds: result.usedSetIds,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(subject.worldId),
          stage: stage,
          questions: questions,
          progress: progress,
          // 通常RPGのレベル・経験値・クリア状況は変えない（練習用）
          trial: true,
          mode: BattleMode.exam,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = plan.subject(subject.id);
    return Card(
      key: ValueKey('shonan-subject-${subject.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${subject.category}｜${subject.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text(sp.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (sp.examDate != null) Text('試験日：${_ymd(sp.examDate)}'),
            if (sp.rangeText.isNotEmpty) Text(sp.rangeText),
            if (!sp.hasRange)
              Text(
                ShonanText.noRange,
                style: TextStyle(color: TsuzuriColors.inkSoft),
              ),
            for (final m in sp.materials)
              if (!m.isEmpty)
                Text(
                  '・${m.name.isEmpty ? m.kind : m.name}：${m.range}${m.note.isEmpty ? '' : '（${m.note}）'}',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
            const SizedBox(height: 6),
            Text(
              '${ShonanText.existing}：${sp.existingSetIds.length}　${ShonanText.committee}：${sp.committeeSetIds.length}',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  key: ValueKey('shonan-practice-${subject.id}'),
                  onPressed: sp.hasSets ? () => _practice(context, sp) : null,
                  icon: const Icon(Icons.sports_esports),
                  label: Text(
                    sp.hasSets ? ShonanText.practice : ShonanText.noSets,
                  ),
                ),
                if (sp.hasSets)
                  OutlinedButton.icon(
                    key: ValueKey('shonan-list-${subject.id}'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ShonanQuestionListScreen(
                          subject: subject,
                          plan: sp,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('問題一覧・解説'),
                  ),
                // 範囲の問題セットがまだなくても、その科目の今年度の問題で単元ごとに対策できる
                if (sp.hasSets || ShonanSubjectSets.allFor(subject.id).hasSets)
                  OutlinedButton.icon(
                    key: ValueKey('shonan-units-${subject.id}'),
                    onPressed: () => _byUnit(
                      context,
                      sp.hasSets ? sp : ShonanSubjectSets.allFor(subject.id),
                    ),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('単元ごとに練習'),
                  ),
                for (final m in SchoolMaterials.of(subject.id))
                  OutlinedButton.icon(
                    key: ValueKey('shonan-material-${m.id}'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SchoolMaterialScreen(material: m),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('資料（PDF）を見る'),
                  ),
                if (subject.id == 'ec1')
                  OutlinedButton.icon(
                    key: const ValueKey('shonan-ec-text'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EcTextScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('本文を見る'),
                  ),
              ],
            ),
            if (!sp.hasSets)
              Text(
                ShonanText.noSetsHelp,
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
          ],
        ),
      ),
    );
  }
}

/// テストの作成・編集（科目ごとに開いて入力）
class ShonanExamEditScreen extends StatefulWidget {
  const ShonanExamEditScreen({super.key, this.plan});
  final SchoolExamPlan? plan;

  @override
  State<ShonanExamEditScreen> createState() => _ShonanExamEditScreenState();
}

class _ShonanExamEditScreenState extends State<ShonanExamEditScreen> {
  late final _title = TextEditingController(text: widget.plan?.title ?? '');
  late DateTime? _date = widget.plan?.examDate;
  late final Map<String, SubjectExamPlan> _subjects = {
    for (final s in ShonanSubjects.all)
      s.id: widget.plan?.subject(s.id) ?? SubjectExamPlan(subjectId: s.id),
  };
  // 教材の行を消したときに入力欄を作り直すための番号
  int _rev = 0;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _set(SubjectExamPlan s) => setState(() => _subjects[s.subjectId] = s);

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = ShonanText.titleRequired);
      return;
    }
    final store = _store(context);
    final now = DateTime.now();
    final subjects = {
      for (final e in _subjects.entries)
        e.key: e.value.copyWith(
          materials: [
            for (final m in e.value.materials)
              if (!m.isEmpty) m,
          ],
          // 何か入力したのに未入力のままなら「入力済み」にする
          status: e.value.status == RangeStatus.empty && e.value.isFilled
              ? RangeStatus.entered
              : null,
        ),
    };
    final old = widget.plan;
    final plan = old == null
        ? SchoolExamPlan(
            id: 'shonan_${now.microsecondsSinceEpoch}',
            title: title,
            createdAt: now,
            examDate: _date,
            subjects: subjects,
          )
        : old.copyWith(
            title: title,
            examDate: _date,
            clearDate: _date == null,
            subjects: subjects,
            updatedAt: now,
          );
    old == null ? await store.add(plan) : await store.update(plan);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _addSet(SchoolSubject subject, {required bool committee}) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => _SetPicker(subject: subject),
    );
    if (id == null || id.isEmpty) return;
    final sp = _subjects[subject.id]!;
    final list = committee ? sp.committeeSetIds : sp.existingSetIds;
    if (list.contains(id)) return;
    _set(
      committee
          ? sp.copyWith(committeeSetIds: [...list, id])
          : sp.copyWith(existingSetIds: [...list, id]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plan == null ? '新しいテスト' : 'テストを編集',
          style: serif(17),
        ),
        actions: [
          TextButton(
            key: const ValueKey('shonan-save'),
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextField(
              key: const ValueKey('shonan-title'),
              controller: _title,
              decoration: InputDecoration(
                labelText: 'テスト名（必須）',
                hintText: '例：1年後期中間試験',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('試験日：${_ymd(_date)}')),
                TextButton(onPressed: _pickDate, child: const Text('日付を選ぶ')),
                if (_date != null)
                  TextButton(
                    onPressed: () => setState(() => _date = null),
                    child: const Text('消す'),
                  ),
              ],
            ),
            const _Note(text: ShonanText.localOnly, icon: Icons.phone_android),
            const SizedBox(height: 8),
            for (final s in ShonanSubjects.all) _subjectTile(s),
          ],
        ),
      ),
    );
  }

  Widget _subjectTile(SchoolSubject s) {
    final sp = _subjects[s.id]!;
    return Card(
      child: ExpansionTile(
        key: ValueKey('shonan-edit-${s.id}'),
        title: Text('${s.category}｜${s.displayName}'),
        subtitle: Text(sp.status.label),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          TextFormField(
            key: ValueKey('shonan-range-${s.id}'),
            initialValue: sp.rangeText,
            maxLines: null,
            decoration: const InputDecoration(labelText: '試験範囲（自由記述）'),
            onChanged: (v) =>
                _subjects[s.id] = _subjects[s.id]!.copyWith(rangeText: v),
          ),
          DropdownButtonFormField<RangeStatus>(
            initialValue: sp.status,
            decoration: const InputDecoration(labelText: '情報の状態'),
            items: [
              for (final st in RangeStatus.values)
                DropdownMenuItem(value: st, child: Text(st.label)),
            ],
            onChanged: (v) => _set(_subjects[s.id]!.copyWith(status: v)),
          ),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: Text('教材の範囲')),
          for (var i = 0; i < sp.materials.length; i++) _materialRow(s.id, i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('shonan-add-material-${s.id}'),
              onPressed: () => _set(
                sp.copyWith(
                  materials: [
                    ...sp.materials,
                    const StudyMaterial(kind: '教科書'),
                  ],
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('教材を足す'),
            ),
          ),
          _setList(s, committee: false),
          _setList(s, committee: true),
        ],
      ),
    );
  }

  Widget _materialRow(String sid, int i) {
    final m = _subjects[sid]!.materials[i];
    void put(StudyMaterial n) {
      final list = [..._subjects[sid]!.materials]..[i] = n;
      _subjects[sid] = _subjects[sid]!.copyWith(materials: list);
    }

    final key = '$sid-$i-$_rev';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: TsuzuriColors.inkSoft.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('kind-$key'),
                  initialValue: ShonanText.materialKinds.contains(m.kind)
                      ? m.kind
                      : 'その他',
                  items: [
                    for (final k in ShonanText.materialKinds)
                      DropdownMenuItem(value: k, child: Text(k)),
                  ],
                  onChanged: (v) =>
                      put(_subjects[sid]!.materials[i].copyWith(kind: v)),
                ),
              ),
              IconButton(
                tooltip: '消す',
                onPressed: () => setState(() {
                  _rev++;
                  _subjects[sid] = _subjects[sid]!.copyWith(
                    materials: [..._subjects[sid]!.materials]..removeAt(i),
                  );
                }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          TextFormField(
            key: ValueKey('name-$key'),
            initialValue: m.name,
            decoration: const InputDecoration(labelText: '教材名（例：サクシード）'),
            onChanged: (v) =>
                put(_subjects[sid]!.materials[i].copyWith(name: v)),
          ),
          TextFormField(
            key: ValueKey('range-$key'),
            initialValue: m.range,
            decoration: const InputDecoration(
              labelText: 'ページ・番号・範囲（例：P.38-65）',
            ),
            onChanged: (v) =>
                put(_subjects[sid]!.materials[i].copyWith(range: v)),
          ),
          TextFormField(
            key: ValueKey('note-$key'),
            initialValue: m.note,
            decoration: const InputDecoration(labelText: '備考（提出など）'),
            onChanged: (v) =>
                put(_subjects[sid]!.materials[i].copyWith(note: v)),
          ),
        ],
      ),
    );
  }

  Widget _setList(SchoolSubject s, {required bool committee}) {
    final sp = _subjects[s.id]!;
    final ids = committee ? sp.committeeSetIds : sp.existingSetIds;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(committee ? ShonanText.committee : ShonanText.existing),
          Wrap(
            spacing: 6,
            children: [
              for (final id in ids)
                InputChip(
                  label: Text(id, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _set(
                    committee
                        ? sp.copyWith(committeeSetIds: [...ids]..remove(id))
                        : sp.copyWith(existingSetIds: [...ids]..remove(id)),
                  ),
                ),
              ActionChip(
                key: ValueKey(
                  'shonan-add-set-${s.id}-${committee ? 'c' : 'e'}',
                ),
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('追加'),
                onPressed: () => _addSet(s, committee: committee),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 問題セットを選ぶ（その科目の教科に収録されているセットから。IDの手入力もできる）
class _SetPicker extends StatefulWidget {
  const _SetPicker({required this.subject});
  final SchoolSubject subject;

  @override
  State<_SetPicker> createState() => _SetPickerState();
}

class _SetPickerState extends State<_SetPicker> {
  late final Future<Map<String, int>> _sets = RpgServices.questionSetsOf(
    widget.subject.worldId,
  );
  final _filter = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.subject.displayName}の問題セット'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: FutureBuilder<Map<String, int>>(
          future: _sets,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snap.data!;
            final q = _filter.text.trim();
            final shown = [
              for (final e in all.entries)
                if (e.key.contains(q)) e,
            ];
            return Column(
              children: [
                TextField(
                  key: const ValueKey('shonan-set-filter'),
                  controller: _filter,
                  decoration: InputDecoration(
                    labelText: '絞り込み・IDの入力',
                    hintText: '例：${widget.subject.worldId}_shonan_104',
                    errorText: _error,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (v) {
                    // 手入力したIDは、収録されているか・教科が合っているかを確かめる
                    if (all.containsKey(v.trim())) {
                      Navigator.pop(context, v.trim());
                    } else {
                      setState(
                        () => _error =
                            '「${v.trim()}」は${widget.subject.category}（${widget.subject.worldId}）に収録されていません',
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: all.isEmpty
                      ? const Center(child: Text('問題セットを読み込めませんでした'))
                      : ListView(
                          children: [
                            for (final e in shown)
                              ListTile(
                                dense: true,
                                title: Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text('${e.value}問'),
                                onTap: () => Navigator.pop(context, e.key),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('やめる'),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: TsuzuriColors.inkSoft),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: TsuzuriColors.inkSoft,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

/// 単元ごとに練習：単元（その中の小単元）を選んで演習する
class SchoolUnitScreen extends StatelessWidget {
  const SchoolUnitScreen({
    super.key,
    required this.title,
    required this.groups,
    required this.onPractice,
  });

  final String title;
  final List<SchoolUnitGroup> groups;
  final Future<void> Function(BuildContext context, SchoolUnitGroup group)
  onPractice;

  @override
  Widget build(BuildContext context) {
    Widget play(SchoolUnitGroup g, {bool all = false}) => TextButton(
      key: ValueKey('unit-play-${g.id}${all ? '-all' : ''}'),
      onPressed: () => onPractice(context, g),
      child: Text(
        all ? 'この単元すべて（${g.questions.length}問）' : '${g.questions.length}問',
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text('単元ごとに練習｜$title', style: serif(16))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              '範囲が決まっていなくても、単元を選んで対策できます。単元を開くと、さらに細かい小単元ごとにも練習できます。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 8),
            for (final g in groups)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: g.parts.isEmpty
                    ? ListTile(
                        key: ValueKey('unit-${g.id}'),
                        title: Text(g.name),
                        trailing: play(g),
                      )
                    : ExpansionTile(
                        key: ValueKey('unit-${g.id}'),
                        title: Text(g.name),
                        subtitle: Text('${g.questions.length}問'),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: play(g, all: true),
                            ),
                          ),
                          for (final p in g.parts)
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(
                                left: 24,
                                right: 8,
                              ),
                              title: Text(p.name),
                              trailing: play(p),
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
