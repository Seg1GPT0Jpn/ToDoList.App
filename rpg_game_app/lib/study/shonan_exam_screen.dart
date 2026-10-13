import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'realm_style.dart';
import 'sea_battle_launcher.dart';
import 'shonan_exam_store.dart';

/// 湘南高校104回生向けの試験計画・範囲・問題セット管理。
///
/// 既存の「定期テストの海」と別の保存領域を使うため、一般向けの計画には影響しない。
class ShonanExamHomeScreen extends StatefulWidget {
  const ShonanExamHomeScreen({super.key});

  @override
  State<ShonanExamHomeScreen> createState() => _ShonanExamHomeScreenState();
}

class _ShonanExamHomeScreenState extends State<ShonanExamHomeScreen> {
  late final Future<ShonanExamStore> _storeFuture =
      SharedPreferences.getInstance().then(ShonanExamStore.new);

  Future<void> _create(BuildContext context, ShonanExamStore store) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShonanExamEditorScreen(store: store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShonanExamStore>(
      future: _storeFuture,
      builder: (context, snapshot) {
        final store = snapshot.data;
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('試験対策データを開けませんでした。')),
          );
        }
        if (store == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: TsuzuriColors.tint(0xFFE6F0F5),
            title: Text(
              '湘南高校モード',
              style: serif(19, color: StudyRealm.sea.ink),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _create(context, store),
            icon: const Icon(Icons.add),
            label: const Text('定期テストを登録'),
          ),
          body: NotebookPaper(
            child: StreamBuilder<List<ShonanExamPlan>>(
              stream: store.watch(),
              builder: (context, snap) {
                final plans = snap.data ?? store.load();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 100),
                  children: [
                    Text(
                      '湘南高校104回生の定期テスト範囲と演習問題を管理します。'
                      '既存問題と委員会の新作問題を別々に登録し、科目ごとにまとめて演習できます。',
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    const _InfoNote(
                      text: '問題セットIDは、アプリに収録されたJSON問題セットのIDを入力します。'
                          '新作問題は所定のJSON形式で追加し、問題バンドルを再生成してから利用できます。',
                    ),
                    const SizedBox(height: 16),
                    if (plans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'まだ定期テストが登録されていません。\n'
                          '「定期テストを登録」から最初のテストを作成してください。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: TsuzuriColors.inkSoft),
                        ),
                      ),
                    for (final plan in plans)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            Icons.school_outlined,
                            color: StudyRealm.sea.ink,
                          ),
                          title: Text(plan.title, style: serif(15)),
                          subtitle: Text(
                            '${plan.examDate == null ? '試験日未設定' : _dateLabel(plan.examDate!)}'
                            '・情報登録済み ${plan.configuredSubjectCount}/11科目',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ShonanExamPlanScreen(
                                store: store,
                                planId: plan.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// 試験の日付・各科目の範囲・使用教材・既存/新作問題IDを入力する。
class ShonanExamEditorScreen extends StatefulWidget {
  const ShonanExamEditorScreen({
    super.key,
    required this.store,
    this.plan,
  });

  final ShonanExamStore store;
  final ShonanExamPlan? plan;

  @override
  State<ShonanExamEditorScreen> createState() => _ShonanExamEditorScreenState();
}

class _ShonanExamEditorScreenState extends State<ShonanExamEditorScreen> {
  final _title = TextEditingController();
  final _ranges = <String, TextEditingController>{};
  final _materials = <String, TextEditingController>{};
  final _existingIds = <String, TextEditingController>{};
  final _committeeIds = <String, TextEditingController>{};
  DateTime? _examDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _title.text = plan?.title ?? '湘南高校104回生 定期テスト';
    _examDate = plan?.examDate;
    for (final definition in ShonanExamSubjectDefinition.all) {
      final subject = plan?.subject(definition.id) ??
          ShonanSubjectExamPlan(subjectId: definition.id);
      _ranges[definition.id] = TextEditingController(text: subject.rangeText);
      _materials[definition.id] =
          TextEditingController(text: subject.materialsText);
      _existingIds[definition.id] =
          TextEditingController(text: subject.existingSetIdsText);
      _committeeIds[definition.id] =
          TextEditingController(text: subject.committeeSetIdsText);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    for (final map in [_ranges, _materials, _existingIds, _committeeIds]) {
      for (final controller in map.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 4),
      helpText: '定期テストの日付',
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'テスト名を入力してください。');
      return;
    }

    final previous = widget.plan;
    final plan = ShonanExamPlan(
      id: previous?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      createdAt: previous?.createdAt ?? DateTime.now(),
      examDate: _examDate,
      subjects: {
        for (final definition in ShonanExamSubjectDefinition.all)
          definition.id: ShonanSubjectExamPlan(
            subjectId: definition.id,
            rangeText: _ranges[definition.id]!.text.trim(),
            materialsText: _materials[definition.id]!.text.trim(),
            existingSetIdsText: _existingIds[definition.id]!.text.trim(),
            committeeSetIdsText: _committeeIds[definition.id]!.text.trim(),
          ),
      },
    );

    if (previous == null) {
      await widget.store.add(plan);
    } else {
      await widget.store.update(plan);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? '定期テストを登録' : 'テスト情報を編集'),
      ),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 32),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'テスト名',
                hintText: '例：後期中間試験',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(
                _examDate == null ? '試験日を登録（任意）' : _dateLabel(_examDate!),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoNote(
              text: '各科目の範囲と教材を記録します。問題セットIDは複数入力できます。'
                  'IDはカンマ、読点、セミコロン、改行のいずれかで区切ってください。'
                  '範囲が未確定なら空欄のままで構いません。',
            ),
            const SizedBox(height: 12),
            for (final (index, definition)
                in ShonanExamSubjectDefinition.all.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  key: PageStorageKey('shonan-subject-${definition.id}'),
                  initiallyExpanded: index == 0,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: TsuzuriColors.tint(0xFFE6F0F5),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: StudyRealm.sea.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(definition.name),
                  subtitle: Text(definition.category),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _ranges[definition.id],
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '試験範囲',
                        hintText: '例：教科書P.42～72、プリントNo.3～8',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _materials[definition.id],
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '使用教材・備考',
                        hintText: '教科書・ワーク・授業プリントなど',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _existingIds[definition.id],
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '既存問題セットID',
                        hintText: '例：science_chem_basic_01',
                        helperText: '現在のつづりクエストに収録済みのセット',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _committeeIds[definition.id],
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '委員会の新作問題セットID',
                        hintText: '例：science_shonan_104_chem_01',
                        helperText: '委員会で検証・承認し、アプリに追加したセット',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('保存する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 登録内容・科目ごとの演習入口。
class ShonanExamPlanScreen extends StatelessWidget {
  const ShonanExamPlanScreen({
    super.key,
    required this.store,
    required this.planId,
  });

  final ShonanExamStore store;
  final String planId;

  Future<void> _practice(
    BuildContext context,
    ShonanExamPlan plan,
    ShonanExamSubjectDefinition definition,
  ) async {
    final subjectPlan = plan.subject(definition.id);
    final ids = subjectPlan.allSetIds;
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${definition.name}に問題セットIDが登録されていません。')),
      );
      return;
    }

    final source = RpgServices.of(context).questions;
    final sets = <QuestionSet>[];
    final missing = <String>[];
    final wrongWorld = <String>[];
    final nonOriginal = <String>[];

    for (final id in ids) {
      try {
        final set = await source.load(id);
        if (set == null) {
          missing.add(id);
        } else if (set.worldId != definition.worldId) {
          wrongWorld.add(id);
        } else if (set.origin != QuestionOrigin.original) {
          nonOriginal.add(id);
        } else {
          sets.add(set);
        }
      } catch (_) {
        missing.add(id);
      }
    }

    if (!context.mounted) return;
    if (sets.isEmpty) {
      final reason = [
        if (missing.isNotEmpty) '見つからないID：${missing.join('、')}',
        if (wrongWorld.isNotEmpty) '科目の問題バンドルと一致しないID：${wrongWorld.join('、')}',
        if (nonOriginal.isNotEmpty) 'RPG演習に使えない出典のID：${nonOriginal.join('、')}',
      ].join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason.isEmpty ? '使用できる問題がありません。' : reason),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final merged = QuestionSet.merge(
      'shonan_${plan.id}_${definition.id}',
      sets,
    );
    await startSeaBattle(
      context,
      title: '${plan.title}・${definition.name}',
      recordId: merged.setId,
      questions: merged.questions,
      worldId: definition.worldId,
      normalTimeLimitSeconds: 30,
    );

    if (!context.mounted) return;
    final skipped = missing.length + wrongWorld.length + nonOriginal.length;
    if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('利用できるセットのみで出題しました。利用できなかったID：$skipped件')),
      );
    }
  }

  Future<void> _delete(BuildContext context, ShonanExamPlan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('「${plan.title}」を削除しますか？'),
        content: const Text('登録した範囲と問題セットIDを削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await store.remove(plan.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShonanExamPlan>>(
      stream: store.watch(),
      builder: (context, snapshot) {
        final plan = store.byId(planId);
        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('試験計画が見つかりません。')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(plan.title, style: serif(18)),
            actions: [
              IconButton(
                tooltip: '編集',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShonanExamEditorScreen(
                      store: store,
                      plan: plan,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '削除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, plan),
              ),
            ],
          ),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 32),
              children: [
                Text(
                  '${plan.examDate == null ? '試験日未設定' : '試験日：${_dateLabel(plan.examDate!)}'}'
                  '・登録済み ${plan.configuredSubjectCount}/11科目',
                  style: TextStyle(color: TsuzuriColors.inkSoft, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const _InfoNote(
                  text: '科目を選んで演習すると、登録した既存問題セットと委員会の新作問題セットを統合して出題します。'
                      'セットが読み込めない場合や、別教科のセットは自動で除外します。',
                ),
                const SizedBox(height: 12),
                for (final definition in ShonanExamSubjectDefinition.all)
                  Builder(
                    builder: (context) {
                      final subject = plan.subject(definition.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(definition.name, style: serif(15)),
                              if (subject.rangeText.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text('範囲：${subject.rangeText}'),
                              ],
                              if (subject.materialsText.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '教材：${subject.materialsText}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: TsuzuriColors.inkSoft,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '既存 ${subject.existingSetIds.length}セット'
                                '・新作 ${subject.committeeSetIds.length}セット'
                                '・合計 ${subject.allSetIds.length}セット',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TsuzuriColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                onPressed: subject.allSetIds.isEmpty
                                    ? null
                                    : () => _practice(context, plan, definition),
                                icon: const Icon(Icons.sailing),
                                label: const Text('登録した問題で演習'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TsuzuriColors.tint(0xFFF6F0E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, height: 1.6),
        ),
      );
}

String _dateLabel(DateTime date) => '${date.year}年${date.month}月${date.day}日';
