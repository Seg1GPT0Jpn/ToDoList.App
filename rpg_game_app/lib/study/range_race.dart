import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../versus/duel_backend.dart';

/// 試験範囲の進みぐあい（範囲表の問題セットのうち、最後に答えたとき正解だった問題の割合）。
///
/// 範囲表のシートの問題セットをそのまま使うので、自分で範囲を編集していても、みんな同じ範囲で比べる。
class RangeProgress {
  const RangeProgress(this.subjects);

  /// 科目 ID → (正解ずみの問題数, 範囲の問題数)
  final Map<String, ({int done, int total})> subjects;

  static int permille(int done, int total) =>
      total == 0 ? 0 : (done * 1000 ~/ total);

  /// 全体（科目ごとの割合の平均。問題の多い科目だけが効かないように）
  int get overall {
    final list = subjects.values.where((s) => s.total > 0).toList();
    if (list.isEmpty) return 0;
    return list.map((s) => permille(s.done, s.total)).reduce((a, b) => a + b) ~/
        list.length;
  }

  int get done => subjects.values.fold(0, (a, s) => a + s.done);
  int get total => subjects.values.fold(0, (a, s) => a + s.total);

  /// 範囲の問題を全部正解した科目の数
  int get finished =>
      subjects.values.where((s) => s.total > 0 && s.done == s.total).length;

  /// 範囲表のシート [sheet] の、いまの進みぐあい
  static Future<RangeProgress> of(
    String sheet,
    Future<QuestionSet?> Function(String setId) load,
    Map<String, QuestionStat> stats,
  ) async {
    final plan = ShonanRangeTable.plan(sheet, id: 'race', now: DateTime(2026));
    final out = <String, ({int done, int total})>{};
    for (final s in ShonanSubjects.all) {
      final sp = plan.subject(s.id);
      if (!sp.hasSets) continue;
      final r = await SchoolPractice.build(s, sp, load);
      final qs = r.pool?.questions ?? const <QuizQuestion>[];
      if (qs.isEmpty) continue;
      final p = UnitPractice.of(qs, stats);
      out[s.id] = (done: p.lastCorrect, total: p.total);
    }
    return RangeProgress(out);
  }
}

/// ランキングの1人分。置くのはニックネームと進みぐあいの数字だけ（どの問題を解いたかは置かない）
class RangeRaceEntry {
  const RangeRaceEntry({
    required this.uid,
    required this.name,
    required this.pct,
    required this.done,
    required this.finished,
    this.subjects = const {},
  });

  final String uid;
  final String name;

  /// 全体の進みぐあい（千分率）
  final int pct;

  /// 正解ずみの問題数
  final int done;

  /// 全部正解した科目の数
  final int finished;

  /// 科目 ID → 進みぐあい（千分率）
  final Map<String, int> subjects;

  factory RangeRaceEntry.of(String uid, String name, RangeProgress p) =>
      RangeRaceEntry(
        uid: uid,
        name: name,
        pct: p.overall,
        done: p.done,
        finished: p.finished,
        subjects: {
          for (final e in p.subjects.entries)
            e.key: RangeProgress.permille(e.value.done, e.value.total),
        },
      );

  Map<String, Object> toMap() => {
    'name': name,
    'pct': pct,
    'done': done,
    'finished': finished,
    'subjects': subjects,
  };

  static RangeRaceEntry? fromMap(String uid, Object? m) {
    if (m is! Map) return null;
    final name = m['name'], pct = m['pct'];
    if (name is! String || pct is! num) return null;
    final subs = m['subjects'];
    return RangeRaceEntry(
      uid: uid,
      name: name,
      pct: pct.toInt(),
      done: (m['done'] as num? ?? 0).toInt(),
      finished: (m['finished'] as num? ?? 0).toInt(),
      subjects: {
        if (subs is Map)
          for (final e in subs.entries)
            if (e.key is String && e.value is num)
              e.key as String: (e.value as num).toInt(),
      },
    );
  }

  /// 進んでいる順（同じなら正解ずみの問題が多い順）
  static List<RangeRaceEntry> rank(Iterable<RangeRaceEntry> all) =>
      [...all]..sort((a, b) {
        final s = b.pct.compareTo(a.pct);
        return s != 0 ? s : b.done.compareTo(a.done);
      });

  static String percent(int permille) =>
      '${(permille / 10).toStringAsFixed(1)}%';
}

/// 進みぐあいランキングの保存先
abstract class RangeRaceBackend {
  String? get userId;

  /// 範囲表のシートごとのランキングの名前
  static const season = '2026';
  static String boardId(String sheet) {
    final i = ShonanRangeTable.sheets.indexWhere((s) => s.$1 == sheet);
    return '$season-s$i';
  }

  /// 自分の記録を出す（何回でも上書き）
  Future<void> submit(String board, RangeRaceEntry entry);

  /// 進んでいる順に [limit] 人
  Future<List<RangeRaceEntry>> ranking(String board, {int limit = 200});
}

/// テストとサーバーのない版の、端末の中だけの保存先
class MemoryRangeRaceBackend extends RangeRaceBackend {
  MemoryRangeRaceBackend({this.userId = 'me'});

  @override
  final String? userId;

  /// ランキング → uid → 記録
  final Map<String, Map<String, RangeRaceEntry>> boards = {};

  @override
  Future<void> submit(String board, RangeRaceEntry entry) async {
    final uid = userId ?? (throw const DuelException(RangeRaceText.needLogin));
    boards.putIfAbsent(board, () => {})[uid] = entry;
  }

  @override
  Future<List<RangeRaceEntry>> ranking(String board, {int limit = 200}) async =>
      RangeRaceEntry.rank(boards[board]?.values ?? const [])
          .take(limit)
          .toList();
}

class RangeRaceText {
  const RangeRaceText._();

  static const title = '範囲の進みぐあいランキング';
  static const needLogin = 'ランキングは、Google でログインすると参加できます';
  static const rule =
      '範囲表の問題セットのうち、最後に答えたとき正解だった問題の割合で競います'
      '（全体は科目ごとの割合の平均）。自分で範囲を編集していても、みんな同じ範囲で比べます。'
      'この画面を開くと、あなたの今の進みぐあいが送られます。'
      'みんなに見えるのはニックネームと、科目ごとの割合だけです。';
  static const noName = 'ニックネーム未設定';
}

/// 進みぐあいランキングの画面
class RangeRaceScreen extends StatefulWidget {
  const RangeRaceScreen({super.key, this.sheet, this.backend});

  /// はじめに開くシート（なければ範囲表のいちばん新しい試験）
  final String? sheet;

  /// テスト用（ふだんは RpgServices.rangeRace）
  final RangeRaceBackend? backend;

  @override
  State<RangeRaceScreen> createState() => _RangeRaceScreenState();
}

class _RangeRaceScreenState extends State<RangeRaceScreen> {
  late String _sheet = widget.sheet ?? _defaultSheet();
  Future<(RangeProgress, List<RangeRaceEntry>, String?)>? _load;
  final _name = TextEditingController();

  /// 範囲が入っている試験のうち、いちばん後ろ（これからの試験）
  static String _defaultSheet() {
    for (final (sheet, _) in ShonanRangeTable.sheets.reversed) {
      final plan = ShonanRangeTable.plan(sheet, id: 'x', now: DateTime(2026));
      if (plan.subjects.values.where((s) => s.hasSets).length >= 3) {
        return sheet;
      }
    }
    return ShonanRangeTable.sheets.first.$1;
  }

  RangeRaceBackend? get _backend =>
      widget.backend ?? RpgServices.of(context).rangeRace;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_load != null) return;
    _name.text = RpgServices.of(context).classroomStore.nickname;
    _load = _fetch();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<(RangeProgress, List<RangeRaceEntry>, String?)> _fetch() async {
    final services = RpgServices.of(context);
    final progress = await RangeProgress.of(
      _sheet,
      services.questions.load,
      services.meta.record.stats,
    );
    final b = _backend;
    if (b == null) {
      return (progress, const <RangeRaceEntry>[], 'この版では、ランキングは使えません');
    }
    final uid = b.userId;
    if (uid == null) {
      return (progress, const <RangeRaceEntry>[], RangeRaceText.needLogin);
    }
    final board = RangeRaceBackend.boardId(_sheet);
    try {
      final name = Classroom.cleanName(
        _name.text,
        fallback: RangeRaceText.noName,
      );
      await b.submit(board, RangeRaceEntry.of(uid, name, progress));
      return (progress, await b.ranking(board), null);
    } on DuelException catch (e) {
      return (progress, const <RangeRaceEntry>[], e.message);
    }
  }

  void _reload() => setState(() => _load = _fetch());

  Future<void> _rename() async {
    final store = RpgServices.of(context).classroomStore;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ランキングでの名前'),
        content: TextField(
          key: const ValueKey('race-name'),
          controller: _name,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'ニックネーム（本名は入れない）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('race-name-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('決める'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await store.setNickname(_name.text.trim());
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _backend?.userId;
    return Scaffold(
      appBar: AppBar(title: Text(RangeRaceText.title, style: serif(17))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (sheet, title) in ShonanRangeTable.sheets)
                  ChoiceChip(
                    key: ValueKey('race-sheet-$sheet'),
                    label: Text(title),
                    selected: _sheet == sheet,
                    onSelected: (_) {
                      if (_sheet == sheet) return;
                      _sheet = sheet;
                      _reload();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder(
              future: _load,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Text('読みこめませんでした：${snap.error}');
                }
                final data = snap.data;
                if (data == null) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final (progress, rows, note) = data;
                final myRank = rows.indexWhere((e) => e.uid == uid);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Mine(
                      progress: progress,
                      rank: myRank,
                      players: rows.length,
                    ),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(note, key: const ValueKey('race-note')),
                      ),
                    if (uid != null && note == null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const ValueKey('race-rename'),
                          onPressed: _rename,
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text(
                            '名前：${_name.text.trim().isEmpty ? RangeRaceText.noName : _name.text.trim()}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final (i, e) in rows.indexed)
                      _Row(rank: i + 1, entry: e, me: e.uid == uid),
                    const SizedBox(height: 12),
                    Text(
                      RangeRaceText.rule,
                      style: TextStyle(
                        fontSize: 12,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Mine extends StatelessWidget {
  const _Mine({
    required this.progress,
    required this.rank,
    required this.players,
  });

  final RangeProgress progress;
  final int rank;
  final int players;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('race-mine'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなた：${RangeRaceEntry.percent(progress.overall)}'
              '${rank >= 0 ? '（${rank + 1}位 / $players人）' : ''}',
              key: const ValueKey('race-mine-total'),
              style: serif(18),
            ),
            Text(
              '正解ずみ ${progress.done} / ${progress.total}問・全部正解した科目 ${progress.finished}',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 8),
            if (progress.subjects.isEmpty) const Text('この試験は、範囲の問題セットがまだありません'),
            for (final MapEntry(key: id, value: s) in progress.subjects.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        ShonanSubjects.byId(id)?.displayName ?? id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: s.total == 0 ? 0 : s.done / s.total,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        RangeRaceEntry.percent(
                          RangeProgress.permille(s.done, s.total),
                        ),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
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

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entry, required this.me});

  final int rank;
  final RangeRaceEntry entry;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final best = [...entry.subjects.entries]
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      key: ValueKey('race-row-$rank'),
      color: me ? TsuzuriColors.accent.withValues(alpha: 0.12) : null,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('$rank', style: const TextStyle(fontSize: 12)),
        ),
        title: Text('${entry.name}${me ? '（あなた）' : ''}'),
        subtitle: best.isEmpty
            ? null
            : Text(
                'いちばん進んでいる：${ShonanSubjects.byId(best.first.key)?.displayName ?? best.first.key} '
                '${RangeRaceEntry.percent(best.first.value)}'
                '${entry.finished > 0 ? '・全部正解 ${entry.finished}科目' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
        trailing: Text(RangeRaceEntry.percent(entry.pct), style: serif(16)),
      ),
    );
  }
}
