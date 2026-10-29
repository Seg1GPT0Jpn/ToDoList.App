import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/account_screen.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../app/usage_meter.dart';
import '../art/paper.dart';
import '../vocab/vocab_store.dart';
import 'contest_backend.dart';
import 'duel_backend.dart';
import 'duel_screens.dart';

/// 名前とパスワードで開いた LEAP・EEVI（開いていなければ null）
VocabBook? contestBook(VocabStore store, String bookId) => store.visibleBooks
    .where((b) => b.id == bookId && b.isProtected && b.cards.isNotEmpty)
    .firstOrNull;

/// 単語帳練習のホームに出す入口。バトルの日は目立たせる
class ContestEntryButton extends StatefulWidget {
  const ContestEntryButton({
    super.key,
    required this.store,
    this.backend,
    this.onlyActive = false,
  });

  final VocabStore store;

  /// 受付中と、最終ランキングが出てから1日のあいだだけ出す（ホーム用）
  final bool onlyActive;

  /// テスト用（ふだんは RpgServices.contests）
  final ContestBackend? backend;

  @override
  State<ContestEntryButton> createState() => _ContestEntryButtonState();
}

class _ContestEntryButtonState extends State<ContestEntryButton> {
  Future<ContestConfig>? _config;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _config ??= _loadConfig();
  }

  Future<ContestConfig> _loadConfig() =>
      (widget.backend ?? RpgServices.of(context).contests)?.loadConfig() ??
      Future.value(ContestConfig.initial);

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContestScreen(backend: widget.backend),
      ),
    );
    if (!mounted) return;
    setState(() => _config = _loadConfig());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContestConfig>(
      future: _config,
      builder: (context, snap) {
        final config = snap.data;
        final now = DateTime.now();
        bool mine(ContestRound r) =>
            contestBook(widget.store, r.bookId) != null;
        final open = config?.openAt(now).where(mine).toList() ?? const [];
        // 受付が終わってから1日のあいだは、最終ランキングへの入口を出す
        final results = [
          for (final id in ContestConfig.books)
            if (config?.plans[id]?.lastClosed(now) case final r?)
              if (mine(r) &&
                  now.difference(r.closeAt) < const Duration(days: 1))
                r,
        ];
        Widget? button;
        if (open.isNotEmpty) {
          button = FilledButton.icon(
            key: const ValueKey('vocab-home-contest'),
            onPressed: _open,
            icon: const Icon(Icons.emoji_events),
            label: Text(
              '${open.map((r) => r.title).join('・')}バトル受付中！'
              '（${open.map((r) => '${r.range}・${ContestRules.time(r.closeAt)}まで').join('／')}）',
            ),
          );
        } else if (results.isNotEmpty) {
          button = FilledButton.tonalIcon(
            key: const ValueKey('vocab-home-contest'),
            onPressed: _open,
            icon: const Icon(Icons.emoji_events),
            label: Text(
              '${results.map((r) => r.title).join('・')}バトルの最終ランキング発表！',
            ),
          );
        }
        if (widget.onlyActive) {
          return button == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: button,
                );
        }
        return button ??
            OutlinedButton.icon(
              key: const ValueKey('vocab-home-contest'),
              onPressed: _open,
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('週替わり単語バトル（LEAP・EEVI）'),
            );
      },
    );
  }
}

/// 週替わり単語バトル：今日の回・次の回・順位
class ContestScreen extends StatefulWidget {
  const ContestScreen({super.key, this.backend, this.now});

  /// テスト用（ふだんは RpgServices.contests）
  final ContestBackend? backend;

  /// テスト用の「今」
  final DateTime Function()? now;

  @override
  State<ContestScreen> createState() => _ContestScreenState();
}

class _ContestScreenState extends State<ContestScreen> {
  final _name = TextEditingController();
  Future<_Board>? _load;
  String? _error;
  bool _busy = false;

  ContestBackend? get _backend =>
      widget.backend ?? RpgServices.of(context).contests;

  VocabStore get _store => VocabStore.of(RpgServices.of(context).personalBooks);

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    UsageMeter.mark(context, 'duel');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_load != null) return;
    _name.text = RpgServices.of(context).classroomStore.nickname;
    _reload();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reload() {
    final backend = _backend;
    if (backend == null || backend.userId == null) return;
    final now = _now();
    _load = () async {
      final config = await backend.loadConfig();
      final rounds = config.openAt(now);
      return _Board(
        config: config,
        now: now,
        mine: {for (final r in rounds) r.id: await backend.mine(r.id)},
      );
    }();
  }

  Future<void> _play(ContestRound round, VocabBook book) async {
    final backend = _backend!;
    final questions = round.questions(book);
    if (questions.length < 4) {
      setState(
        () => _error = '範囲 ${round.range} の単語が、この端末の ${book.title} にありません',
      );
      return;
    }
    final name = Classroom.cleanName(_name.text, fallback: 'あなた');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${round.heading}・${questions.length}問'),
        content: const Text(
          '1人1回だけです。始めたら途中でやめないでください'
          '（やめると、この回は記録なしになります）。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('contest-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('はじめる'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await backend.start(round.id, name);
      if (!mounted) return;
      await RpgServices.of(context).classroomStore.setNickname(name);
      if (!mounted) return;
      final result = await Navigator.of(context).push<DuelResult>(
        MaterialPageRoute(
          builder: (_) => DuelPlayScreen(
            name: name,
            title: round.heading,
            questions: questions,
            store: _store,
            book: book,
          ),
        ),
      );
      if (result != null) {
        await backend.finish(round.id, result.correct, result.score);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ContestRankingScreen(round: round, backend: backend, now: _now),
          ),
        );
      }
    } on DuelException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _reload();
        });
      }
    }
  }

  void _ranking(ContestRound round) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ContestRankingScreen(round: round, backend: _backend!, now: _now),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    return Scaffold(
      appBar: AppBar(title: Text(ContestText.title, style: serif(18))),
      body: NotebookPaper(
        child: backend == null
            ? const Padding(
                padding: EdgeInsets.fromLTRB(40, 16, 16, 24),
                child: Text(ContestText.noBackend),
              )
            : backend.userId == null
            ? ListView(
                padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
                children: [
                  const Text(ContestText.intro, style: TextStyle(height: 1.5)),
                  const SizedBox(height: 12),
                  const Text(ContestText.needLogin),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const ValueKey('contest-login'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                      if (mounted) setState(_reload);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('ログインする'),
                  ),
                ],
              )
            : FutureBuilder<_Board>(
                future: _load,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
                      child: Text('読みこめませんでした：${snap.error}'),
                    );
                  }
                  final board = snap.data;
                  if (board == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _body(board, backend);
                },
              ),
      ),
    );
  }

  Widget _body(_Board board, ContestBackend backend) {
    final small = TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
      children: [
        const Text(ContestText.intro, style: TextStyle(height: 1.5)),
        const SizedBox(height: 4),
        Text(ContestText.privacy, style: small),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('contest-name'),
          controller: _name,
          maxLength: Classroom.maxName,
          decoration: const InputDecoration(
            labelText: 'ニックネーム（みんなに見えます）',
            isDense: true,
          ),
        ),
        for (final id in ContestConfig.books)
          if (board.config.plans[id] case final plan?)
            _planCard(plan, board, small),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            key: const ValueKey('contest-error'),
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 16),
        Text('これからの日程', style: serif(16)),
        const SizedBox(height: 4),
        for (final r in board.config.upcoming(
          ContestRules.jstToday(board.now),
          8,
        ))
          if (!r.isClosed(board.now))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${r.heading}（${r.count}問）\n　${r.window}',
                key: ValueKey('contest-upcoming-${r.id}'),
              ),
            ),
        if (backend.isAdmin) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const ValueKey('contest-admin'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ContestAdminScreen(
                    backend: backend,
                    config: board.config,
                    today: ContestRules.jstToday(board.now),
                  ),
                ),
              );
              if (mounted) setState(_reload);
            },
            icon: const Icon(Icons.edit_calendar),
            label: const Text('日程と範囲を変える（管理者）'),
          ),
        ],
      ],
    );
  }

  Widget _planCard(ContestPlan plan, _Board board, TextStyle small) {
    final now = board.now;
    final book = contestBook(_store, plan.bookId);
    final round = plan.openAt(now);
    final next = plan.nextAt(now);
    final last = plan.lastClosed(now);
    final weekday = ContestRules.weekdays[plan.weekday - 1];
    final mine = round == null ? null : board.mine[round.id];
    final fresh =
        last != null && now.difference(last.closeAt) < const Duration(days: 1);
    return Card(
      key: ValueKey('contest-plan-${plan.bookId}'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${plan.title} バトル（毎週$weekday曜）', style: serif(17)),
            Text(
              '受付：${ContestRules.offset(plan.openMin)}〜${ContestRules.offset(plan.closeMin)}',
              style: small,
            ),
            const SizedBox(height: 4),
            if (!plan.enabled)
              const Text('いまはお休み中です')
            else if (round != null) ...[
              Text(
                '受付中　${round.heading}・${round.count}問',
                key: ValueKey('contest-open-${plan.bookId}'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${ContestRules.time(round.closeAt)}まで', style: small),
              const SizedBox(height: 6),
              if (book == null)
                Text(
                  '${plan.title} を開いている人だけが参加できます'
                  '（単語帳練習で、名前とパスワードを入れて追加）。',
                  key: ValueKey('contest-no-book-${plan.bookId}'),
                )
              else if (mine == null)
                FilledButton.icon(
                  key: ValueKey('contest-play-${plan.bookId}'),
                  onPressed: _busy ? null : () => _play(round, book),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('挑戦する（1回だけ）'),
                )
              else if (!mine.done)
                const Text('この回は途中でやめたため、記録なしです。次の回でがんばろう！')
              else
                Text(
                  'あなたは ${mine.correct}問正解・${mine.score}点',
                  key: ValueKey('contest-mine-${plan.bookId}'),
                  style: serif(16),
                ),
              TextButton(
                key: ValueKey('contest-ranking-${plan.bookId}'),
                onPressed: () => _ranking(round),
                child: const Text('いまの順位を見る（暫定）'),
              ),
            ] else if (next != null)
              Text(
                '次回　${next.heading}・${next.count}問\n${next.window}',
                key: ValueKey('contest-next-${plan.bookId}'),
              ),
            if (last != null) ...[
              const SizedBox(height: 6),
              if (fresh)
                FilledButton.tonalIcon(
                  key: ValueKey('contest-last-${plan.bookId}'),
                  onPressed: () => _ranking(last),
                  icon: const Icon(Icons.emoji_events),
                  label: Text('最終ランキング発表！（${last.range}）'),
                )
              else
                TextButton(
                  key: ValueKey('contest-last-${plan.bookId}'),
                  onPressed: () => _ranking(last),
                  child: Text(
                    '前回（${ContestRules.label(last.date)}・${last.range}）の最終ランキング',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Board {
  const _Board({required this.config, required this.now, required this.mine});
  final ContestConfig config;
  final DateTime now;

  /// 受付中の回の ID → 自分の記録
  final Map<String, ContestEntry?> mine;
}

/// 順位表（上位100人と、自分の順位）
class ContestRankingScreen extends StatefulWidget {
  const ContestRankingScreen({
    super.key,
    required this.round,
    required this.backend,
    this.now,
  });

  final ContestRound round;
  final ContestBackend backend;

  /// テスト用の「今」
  final DateTime Function()? now;

  @override
  State<ContestRankingScreen> createState() => _ContestRankingScreenState();
}

class _ContestRankingScreenState extends State<ContestRankingScreen> {
  late Future<(List<ContestEntry>, ContestEntry?, ({int players, int above})?)>
  _load = _fetch();

  Future<(List<ContestEntry>, ContestEntry?, ({int players, int above})?)>
  _fetch() async {
    final b = widget.backend, id = widget.round.id;
    final rows = await b.ranking(id);
    final mine = await b.mine(id);
    final standing = mine != null && mine.done
        ? await b.standing(id, mine.score)
        : null;
    return (rows, mine, standing);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.round;
    final me = widget.backend.userId;
    final closed = r.isClosed(widget.now?.call() ?? DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${r.title} ${ContestRules.label(r.date)}',
          style: serif(17),
        ),
        actions: [
          IconButton(
            tooltip: '最新にする',
            onPressed: () => setState(() => _load = _fetch()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: NotebookPaper(
        child: FutureBuilder(
          future: _load,
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
                child: Text('読みこめませんでした：${snap.error}'),
              );
            }
            final data = snap.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final (rows, mine, standing) = data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
              children: [
                Text(
                  closed ? '「${r.heading}」最終ランキング' : '「${r.heading}」いまの順位（暫定）',
                  key: ValueKey(closed ? 'contest-final' : 'contest-interim'),
                  style: serif(18),
                ),
                Text(
                  closed
                      ? '受付は ${ContestRules.time(r.closeAt)} に終わりました'
                      : '受付は ${ContestRules.time(r.closeAt)} まで。終わると最終ランキングになります',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
                const SizedBox(height: 6),
                if (mine != null && mine.done && standing != null)
                  Text(
                    'あなたは ${standing.above + 1}位 / ${standing.players}人'
                    '（${mine.correct}問正解・${mine.score}点）',
                    key: const ValueKey('contest-my-rank'),
                    style: serif(17),
                  ),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const Text('まだだれも挑戦していません')
                else
                  for (final (i, e) in rows.indexed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${i + 1}位　${e.name}${e.uid == me ? '（あなた）' : ''}　'
                        '${e.correct}問正解・${e.score}点',
                        key: ValueKey('contest-row-$i'),
                        style: TextStyle(
                          fontWeight: e.uid == me
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 日程と範囲を変える（管理者だけ）
class ContestAdminScreen extends StatefulWidget {
  const ContestAdminScreen({
    super.key,
    required this.backend,
    required this.config,
    required this.today,
  });

  final ContestBackend backend;
  final ContestConfig config;
  final DateTime today;

  @override
  State<ContestAdminScreen> createState() => _ContestAdminScreenState();
}

/// 1冊分の入力欄
class _PlanForm {
  _PlanForm(this.plan)
    : first = TextEditingController(text: ContestRules.dayKey(plan.first)),
      from = TextEditingController(text: '${plan.firstFrom}'),
      width = TextEditingController(text: '${plan.width}'),
      count = TextEditingController(text: '${plan.count}'),
      skips = TextEditingController(
        text: (plan.skips.toList()..sort()).join('\n'),
      ),
      ranges = TextEditingController(text: _lines(plan.ranges)),
      extras = TextEditingController(text: _lines(plan.extras)),
      openAt = TextEditingController(text: ContestRules.offset(plan.openMin)),
      closeAt = TextEditingController(text: ContestRules.offset(plan.closeMin)),
      enabled = plan.enabled;

  final ContestPlan plan;
  final TextEditingController first, from, width, count, skips, ranges, extras;
  final TextEditingController openAt, closeAt;
  bool enabled;

  static String _lines(Map<String, ContestRange> m) =>
      [for (final k in m.keys.toList()..sort()) '$k ${m[k]!.from}-${m[k]!.to}']
          .join('\n');

  List<TextEditingController> get all => [
    first,
    from,
    width,
    count,
    skips,
    ranges,
    extras,
    openAt,
    closeAt,
  ];

  /// 入力を読む。まちがいがあれば、その説明を返す
  (ContestPlan?, String?) read() {
    final t = plan.title;
    final f = ContestRules.parseDay(first.text);
    if (f == null) return (null, '$t：第1回の日付は 2026-11-01 の形で入れてください');
    final a = int.tryParse(from.text.trim());
    final w = int.tryParse(width.text.trim());
    final c = int.tryParse(count.text.trim());
    if (a == null || a < 1) return (null, '$t：範囲のはじめは1以上の数にしてください');
    if (w == null || w < 1) return (null, '$t：範囲の広さは1以上の数にしてください');
    if (c == null || c < 4 || c > ContestRules.maxCount) {
      return (null, '$t：問題数は4〜${ContestRules.maxCount}にしてください');
    }
    final skipSet = <String>{};
    for (final line in _split(skips.text)) {
      final d = ContestRules.parseDay(line);
      if (d == null) return (null, '$t：お休みの日「$line」が読めません');
      skipSet.add(ContestRules.dayKey(d));
    }
    final o = ContestRules.parseOffset(openAt.text);
    final cl = ContestRules.parseOffset(closeAt.text);
    if (o == null || cl == null) {
      return (null, '$t：受付の時間は「前日 18:00」「翌日 8:00」の形で入れてください');
    }
    if (cl <= o) return (null, '$t：受付の終わりは、始まりより後にしてください');
    final (r, re) = _dated(ranges.text, '範囲を変える日');
    if (re != null) return (null, '$t：$re');
    final (x, xe) = _dated(extras.text, '追加の日');
    if (xe != null) return (null, '$t：$xe');
    return (
      plan.copyWith(
        first: f,
        firstFrom: a,
        width: w,
        count: c,
        skips: skipSet,
        ranges: r,
        extras: x,
        enabled: enabled,
        openMin: o,
        closeMin: cl,
      ),
      null,
    );
  }

  static Iterable<String> _split(String s) => s
      .split(RegExp(r'[\n,、]'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty);

  /// 「2026-11-08 1-100」の行を読む
  static (Map<String, ContestRange>, String?) _dated(String s, String what) {
    final out = <String, ContestRange>{};
    for (final line
        in s.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty)) {
      final parts = line.split(RegExp(r'\s+'));
      final d = parts.isEmpty ? null : ContestRules.parseDay(parts.first);
      final r = parts.length < 2
          ? null
          : ContestRange.parse(parts.sublist(1).join());
      if (d == null || r == null) {
        return (const {}, '$what「$line」が読めません（例：2026-11-08 1-100）');
      }
      out[ContestRules.dayKey(d)] = r;
    }
    return (out, null);
  }
}

class _ContestAdminScreenState extends State<ContestAdminScreen> {
  late final Map<String, _PlanForm> _forms = {
    for (final id in ContestConfig.books)
      id: _PlanForm(
        widget.config.plans[id] ?? ContestConfig.initial.plans[id]!,
      ),
  };
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final f in _forms.values) {
      for (final c in f.all) {
        c.addListener(_changed);
      }
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final f in _forms.values) {
      for (final c in f.all) {
        c.dispose();
      }
    }
    super.dispose();
  }

  (ContestConfig?, String?) _read() {
    final plans = <String, ContestPlan>{};
    for (final e in _forms.entries) {
      final (p, err) = e.value.read();
      if (err != null) return (null, err);
      plans[e.key] = p!;
    }
    return (ContestConfig(plans), null);
  }

  Future<void> _save() async {
    final (config, err) = _read();
    if (config == null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.backend.saveConfig(config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日程と範囲を保存しました（みんなの画面に反映されます）')),
      );
      Navigator.of(context).pop();
    } on DuelException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (preview, previewError) = _read();
    final small = TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft);
    return Scaffold(
      appBar: AppBar(title: Text('バトルの日程と範囲', style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
          children: [
            Text(
              '第1回の日付から毎週同じ曜日に行い、1回ごとに範囲を「広さ」ずつ進めます。'
              'お休みの日は範囲も進めません。範囲を変える日・追加の日は、その日だけの範囲です。',
              style: small,
            ),
            for (final f in _forms.values) _form(f, small),
            const SizedBox(height: 16),
            Text('これからの日程（保存するとこうなります）', style: serif(16)),
            const SizedBox(height: 4),
            if (preview == null)
              Text(
                previewError ?? '',
                style: const TextStyle(color: Colors.red),
              )
            else
              for (final r in preview.upcoming(widget.today, 12))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${r.heading}（${r.count}問）\n　${r.window}',
                    key: ValueKey('contest-preview-${r.id}'),
                  ),
                ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('contest-admin-save'),
              onPressed: _busy || preview == null ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_busy ? '保存しています…' : '保存する'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(_PlanForm f, TextStyle small) {
    final id = f.plan.bookId;
    Widget field(
      TextEditingController c,
      String label, {
      String? hint,
      bool number = false,
      int lines = 1,
    }) => TextField(
      key: ValueKey('contest-admin-$id-$label'),
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.multiline,
      minLines: lines,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
      ),
    );
    final weekday = ContestRules.parseDay(f.first.text)?.weekday;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(f.plan.title, style: serif(17))),
                const Text('行う'),
                Switch(
                  key: ValueKey('contest-admin-$id-enabled'),
                  value: f.enabled,
                  onChanged: (v) => setState(() => f.enabled = v),
                ),
              ],
            ),
            field(f.first, '第1回の日付', hint: '2026-11-01'),
            if (weekday != null)
              Text('毎週${ContestRules.weekdays[weekday - 1]}曜', style: small),
            Row(
              children: [
                Expanded(child: field(f.from, '第1回の範囲のはじめ', number: true)),
                const SizedBox(width: 8),
                Expanded(child: field(f.width, '範囲の広さ', number: true)),
                const SizedBox(width: 8),
                Expanded(child: field(f.count, '問題数', number: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: field(f.openAt, '受付の始まり', hint: '前日 18:00')),
                const SizedBox(width: 8),
                Expanded(child: field(f.closeAt, '受付の終わり', hint: '翌日 8:00')),
              ],
            ),
            Text('バトルの日から見て「2日前・前日・当日・翌日・2日後」と時刻で入れます', style: small),
            const SizedBox(height: 6),
            field(f.skips, 'お休みの日（1行に1日）', hint: '2026-11-22', lines: 2),
            field(
              f.ranges,
              '範囲を変える日（日付 はじめ-おわり）',
              hint: '2026-11-08 1-100',
              lines: 2,
            ),
            field(
              f.extras,
              '追加の日（日付 はじめ-おわり）',
              hint: '2026-11-14 401-450',
              lines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
