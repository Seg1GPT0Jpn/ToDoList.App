import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import 'speech.dart';
import 'vocab_import_screen.dart';
import 'vocab_session_screen.dart';
import 'vocab_store.dart';

/// 単語帳1冊：学習・単語一覧（力ごとの熟練度）・分析
class VocabBookScreen extends StatefulWidget {
  const VocabBookScreen({
    super.key,
    required this.store,
    required this.book,
    this.editable = true,
  });

  final VocabStore store;

  /// 取り込み・名前の変更・削除のメニューを出すか（試験対策の単語帳では出さない）
  final bool editable;
  final VocabBook book;

  @override
  State<VocabBookScreen> createState() => _VocabBookScreenState();
}

class _VocabBookScreenState extends State<VocabBookScreen> {
  VocabStore get store => widget.store;
  VocabBook get book => widget.book;
  BookProgress get progress => store.progress(book.id);

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  void _start(String title, List<VocabTask> tasks) {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('いま出せる問題がありません')));
      return;
    }
    _open(
      VocabSessionScreen(store: store, book: book, tasks: tasks, title: title),
    );
  }

  Future<void> _menu(String v) async {
    switch (v) {
      case 'import':
        await _open(VocabImportScreen(store: store, book: book));
      case 'rename':
        final name = await _ask(context, '単語帳の名前', book.title);
        if (name != null && name.isNotEmpty) {
          book.title = name;
          await store.saveBooks();
        }
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(book.isProtected ? '取り込んだ単語を消しますか？' : '単語帳を消しますか？'),
            content: const Text('学習記録も消えます。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('やめる'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('消す'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await store.deleteBook(book.id);
          if (mounted) Navigator.of(context).pop();
          return;
        }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: TsuzuriColors.paper,
          title: Text(
            '${book.title}（${book.cards.length}${book.unit}）',
            style: serif(17),
          ),
          actions: [
            if (!book.isTerms && widget.editable)
              PopupMenuButton<String>(
                onSelected: _menu,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'import',
                    child: Text('単語を取り込む・例文を足す'),
                  ),
                  if (!book.isProtected)
                    const PopupMenuItem(value: 'rename', child: Text('名前を変える')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(book.isProtected ? '取り込んだ単語を消す' : '単語帳を消す'),
                  ),
                ],
              ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: '学習'),
              Tab(text: book.noun),
              const Tab(text: '分析'),
            ],
          ),
        ),
        body: NotebookPaper(
          child: book.cards.isEmpty
              ? _empty()
              : TabBarView(children: [_study(), _words(), _analysis()]),
        ),
      ),
    );
  }

  Widget _empty() => ListView(
    padding: const EdgeInsets.fromLTRB(40, 32, 16, 24),
    children: [
      Text('まだ単語がありません', style: serif(16), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => _open(VocabImportScreen(store: store, book: book)),
        icon: const Icon(Icons.download),
        label: const Text('単語を取り込む'),
      ),
    ],
  );

  // ---------------- 学習 ----------------

  Widget _study() {
    final now = DateTime.now();
    final plan = VocabPlanner.today(book, progress, now);
    final news = plan.where((t) => t.isNew).length;
    final weeks = book.isTerms
        ? VocabCourse.sections(book)
        : VocabCourse.weeks(book, size: _limit ?? 100);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 16, 24),
      children: [
        Card(
          color: TsuzuriColors.tint(0xFFFFF8E1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日の最適学習', style: serif(17)),
                const SizedBox(height: 4),
                Text(
                  '復習 ${plan.length - news}問（忘れかけた順）＋ 新しい${book.noun} $news${book.unit}',
                  style: TextStyle(color: TsuzuriColors.inkSoft),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('vocab-today'),
                  onPressed: () => _start('今日の最適学習', plan),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('はじめる'),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '1日の新しい${book.noun}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      onPressed: progress.newPerDay <= 0
                          ? null
                          : () => _setNew(progress.newPerDay - 5),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text('${progress.newPerDay}${book.unit}'),
                    IconButton(
                      onPressed: () => _setNew(progress.newPerDay + 5),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('形式を選んで練習', style: serif(15)),
        const SizedBox(height: 4),
        _drillOptions(),
        const SizedBox(height: 6),
        _modeGrid(book.cards, '全体'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () =>
              _start('間違いだけ', VocabPlanner.mistakesOnly(book, progress)),
          icon: const Icon(Icons.error_outline),
          label: Text('間違えた${book.noun}だけ'),
        ),
        const SizedBox(height: 16),
        if (VocabCourse.testRangesFor(book).isNotEmpty) ...[
          Text('テスト範囲', style: serif(15)),
          const SizedBox(height: 6),
          for (final (name, cards) in VocabCourse.testRangesFor(book))
            if (cards.isNotEmpty) _weekTile(name, cards, now),
          const SizedBox(height: 10),
        ],
        Text(book.isTerms ? '章ごとに練習' : 'コース', style: serif(15)),
        Text(
          book.isTerms
              ? '章を開くと、その章の用語を上の問題数・順番で練習できます'
              : 'Week を開くと、その${_limit ?? 100}語を上の問題数・順番で練習できます',
          style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 6),
        for (final (name, cards) in weeks) _weekTile(name, cards, now),
      ],
    );
  }

  Future<void> _setNew(int n) async {
    progress.newPerDay = n.clamp(0, 100);
    await store.saveProgress(book.id);
    setState(() {});
  }

  /// 形式を選んで練習するときの問題数（null なら全部）と順番
  int? _drillCount = 20;

  /// 1回に出せる最大の問題数（EEVI は50問まで）
  int? get _limit => book.id == 'eevi' ? 50 : null;
  bool _shuffle = true;

  Widget _drillOptions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('問題数', style: TextStyle(fontSize: 12)),
          for (final n
              in _limit == null
                  ? const <int?>[20, 50, 100, null]
                  : const <int?>[20, 50])
            ChoiceChip(
              key: ValueKey('drill-count-${n ?? 'all'}'),
              label: Text(n == null ? '全部' : '$n問'),
              selected: _drillCount == n,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _drillCount = n),
            ),
        ],
      ),
      Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('順番', style: TextStyle(fontSize: 12)),
          ChoiceChip(
            label: const Text('ランダム'),
            selected: _shuffle,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => setState(() => _shuffle = true),
          ),
          ChoiceChip(
            label: const Text('番号順'),
            selected: !_shuffle,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => setState(() => _shuffle = false),
          ),
        ],
      ),
    ],
  );

  Widget _modeGrid(List<VocabCard> cards, String range) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final m in VocabMode.of(book))
        if (m != VocabMode.compare)
          ActionChip(
            key: ValueKey('vocab-mode-${m.name}'),
            label: Text(m.labelOf(book.isTerms)),
            onPressed: () {
              final tasks = VocabPlanner.drill(
                cards,
                m,
                count: _limit == null
                    ? _drillCount
                    : min(_drillCount ?? _limit!, _limit!),
                shuffle: _shuffle,
              );
              _start(
                '$range ${m.labelOf(book.isTerms)}（${tasks.length}問）',
                tasks,
              );
            },
          ),
    ],
  );

  Widget _weekTile(String name, List<VocabCard> cards, DateTime now) {
    var stable = 0, started = 0;
    for (final c in cards) {
      final s = progress.cards[c.id]?.status(now) ?? CardStatus.unseen;
      if (s != CardStatus.unseen) started++;
      if (s == CardStatus.stable) stable++;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ExpansionTile(
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: cards.isEmpty ? 0 : stable / cards.length,
              color: TsuzuriColors.correct,
              backgroundColor: TsuzuriColors.tint(0xFFE8E0D2),
            ),
            const SizedBox(height: 2),
            Text(
              '${book.isTerms ? '覚えた用語' : '使える単語'} $stable / ${cards.length}　学習ずみ $started',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _modeGrid(cards, book.isTerms ? name : name.split('（').first),
        ],
      ),
    );
  }

  // ---------------- 単語 ----------------

  String _query = '';

  Widget _words() {
    final now = DateTime.now();
    final q = _query.toLowerCase();
    final list = [
      for (final c in book.cards)
        if (q.isEmpty ||
            c.term.toLowerCase().contains(q) ||
            c.meaning.contains(q))
          c,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: book.isTerms ? '用語・説明を検索' : '英単語・意味を検索',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 4, 16, 4),
          child: Text(
            '熟練度：${[for (final k in VocabSkill.of(book)) '${k.labelOf(book.isTerms)}（${k.subOf(book.isTerms)}）'].join('・')}',
            style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(36, 0, 12, 24),
            itemCount: list.length,
            itemBuilder: (_, i) => _wordRow(list[i], now),
          ),
        ),
      ],
    );
  }

  Widget _wordRow(VocabCard c, DateTime now) {
    final p = progress.cards[c.id];
    final status = p?.status(now) ?? CardStatus.unseen;
    final dot = switch (status) {
      CardStatus.weak => '🔴',
      CardStatus.shaky => '🟠',
      CardStatus.stable => '🟢',
      CardStatus.unseen => '⚪',
    };
    return InkWell(
      onTap: () => _detail(c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$dot ', style: const TextStyle(fontSize: 11)),
                if (c.number != null)
                  Text(
                    '${c.number} ',
                    style: TextStyle(
                      fontSize: 11,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                Text(
                  c.term,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    book.meaningOf(c),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ),
                Text(
                  '${p?.overall(now, hasExample: c.hasExample, listening: !book.isTerms) ?? 0}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (p != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  for (final k in VocabSkill.of(book))
                    if (k != VocabSkill.context || c.hasExample)
                      Expanded(
                        child: _skillBar(k, p.mastery(k, now), p.mastered(k)),
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skillBar(VocabSkill k, int v, bool mastered) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${k.labelOf(book.isTerms)} $v%${mastered ? '✓' : ''}',
          style: const TextStyle(fontSize: 9),
        ),
        LinearProgressIndicator(
          value: v / 100,
          minHeight: 3,
          color: v >= 80
              ? TsuzuriColors.correct
              : v >= 50
              ? TsuzuriColors.exp
              : TsuzuriColors.hpLow,
          backgroundColor: TsuzuriColors.tint(0xFFE8E0D2),
        ),
      ],
    ),
  );

  Future<void> _detail(VocabCard c) async {
    if (book.isTerms) return _termDetail(c);
    final pron = TextEditingController(text: c.pron);
    final ex = TextEditingController(text: c.example);
    final exJa = TextEditingController(text: c.exampleJa);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(c.term)),
            IconButton(
              onPressed: () {
                final (lang, rate) = store.voice;
                speaker.speak(c.term, lang: lang, rate: rate);
              },
              icon: const Icon(Icons.volume_up),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.meaning),
              if (c.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('💡 ${c.note}', style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: pron,
                decoration: const InputDecoration(labelText: '発音記号（/…/）'),
              ),
              TextField(
                controller: ex,
                decoration: const InputDecoration(labelText: '例文'),
                maxLines: 2,
              ),
              TextField(
                controller: exJa,
                decoration: const InputDecoration(labelText: '例文の訳'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('とじる'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final i = book.cards.indexOf(c);
      book.cards[i] = c.copyWith(
        pron: pron.text.trim(),
        example: ex.text.trim(),
        exampleJa: exJa.text.trim(),
      );
      await store.saveBooks();
      if (mounted) setState(() {});
    }
    pron.dispose();
    ex.dispose();
    exJa.dispose();
  }

  /// 暗記カードの用語（見るだけ）
  Future<void> _termDetail(VocabCard c) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(c.pron.isEmpty ? c.term : '${c.term}（${c.pron}）'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.group,
              style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 4),
            Text(c.meaning, style: const TextStyle(height: 1.5)),
            if (c.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('💡 ${c.note}', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('とじる'),
        ),
      ],
    ),
  );

  // ---------------- 分析 ----------------

  Widget _analysis() {
    final now = DateTime.now();
    final counts = progress.counts(book, now);
    final week = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    final maxAnswered = week
        .map((d) => progress.days[BookProgress.dayKey(d)]?.answered ?? 0)
        .fold(1, (a, b) => a > b ? a : b);
    final studied = [
      for (final c in book.cards)
        if (progress.cards[c.id] != null) (c, progress.cards[c.id]!),
    ];
    final weekAgo = now.subtract(const Duration(days: 7));
    final missedThisWeek = [
      for (final e in studied)
        if (e.$2.lastMistake != null && e.$2.lastMistake!.isAfter(weekAgo)) e,
    ]..sort((a, b) => b.$2.totalMistakes.compareTo(a.$2.totalMistakes));
    int lapses(CardProgress p) =>
        p.skills.values.fold(0, (a, s) => a + s.lapses);
    final forgetful = [
      for (final e in studied)
        if (lapses(e.$2) > 0) e,
    ]..sort((a, b) => lapses(b.$2).compareTo(lapses(a.$2)));
    final confused = [
      for (final e in studied)
        if (e.$2.confusedWith.isNotEmpty) e,
    ];
    final reasons = <MistakeReason, int>{};
    for (final e in studied) {
      for (final r in e.$2.mistakes.entries) {
        reasons[r.key] = (reasons[r.key] ?? 0) + r.value;
      }
    }
    final today = progress.days[BookProgress.dayKey(now)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 16, 24),
      children: [
        Text('今日のあなた', style: serif(16)),
        const SizedBox(height: 4),
        Text(
          '🔴 弱点 ${counts[CardStatus.weak]}${book.unit}　🟠 あやふや ${counts[CardStatus.shaky]}${book.unit}　'
          '🟢 安定 ${counts[CardStatus.stable]}${book.unit}　⚪ 未学習 ${counts[CardStatus.unseen]}${book.unit}',
        ),
        Text(
          '今日の復習予定 ${progress.dueCount(now)}問　🔥 ${progress.streak(now)}日連続',
        ),
        if (today != null)
          Text(
            '今日：${today.seconds ~/ 60}分　${today.answered}問（新規 ${today.news}・復習 ${today.reviews}）'
            '　正答率 ${today.answered == 0 ? 0 : (today.correct * 100 / today.answered).round()}%',
          ),
        const SizedBox(height: 14),
        Text('この1週間', style: serif(15)),
        const SizedBox(height: 6),
        for (final d in week) _dayBar(d, maxAnswered),
        const SizedBox(height: 14),
        if (reasons.isNotEmpty) ...[
          Text('間違えた理由', style: serif(15)),
          for (final r in MistakeReason.values)
            if ((reasons[r] ?? 0) > 0)
              Text('・${r.labelOf(book.isTerms)}　${reasons[r]}回'),
          const SizedBox(height: 14),
        ],
        _wordSection(
          '今週、最も間違えた${book.noun}',
          missedThisWeek,
          (p) => '${p.totalMistakes}回',
        ),
        _wordSection('忘れやすい${book.noun}', forgetful, (p) => '${lapses(p)}回忘れた'),
        if (confused.isNotEmpty) ...[
          Text('似た${book.noun}との混同', style: serif(15)),
          for (final (c, p) in confused.take(10))
            Text('・${c.term} ⇔ ${p.confusedWith.join(' / ')}'),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => _start('似た${book.noun}の比較', [
              for (final (c, _) in confused.take(20))
                VocabTask(c.id, VocabMode.compare),
            ]),
            child: const Text('比較問題で練習'),
          ),
        ],
      ],
    );
  }

  Widget _dayBar(DateTime d, int maxAnswered) {
    final s = progress.days[BookProgress.dayKey(d)];
    final n = s?.answered ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${d.month}/${d.day}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: n / maxAnswered,
              minHeight: 8,
              color: TsuzuriColors.accent,
              backgroundColor: TsuzuriColors.tint(0xFFEFE8DA),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              n == 0
                  ? '―'
                  : ' $n問 ${s!.seconds ~/ 60}分 ${(s.correct * 100 / n).round()}%',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordSection(
    String title,
    List<(VocabCard, CardProgress)> list,
    String Function(CardProgress) note,
  ) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: serif(15)),
          for (final (c, p) in list.take(10))
            Text(
              '・${c.term}　${book.meaningOf(c)}　（${note(p)}）',
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

Future<String?> _ask(BuildContext context, String title, String initial) async {
  final c = TextEditingController(text: initial);
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('やめる'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  c.dispose();
  return v;
}

Future<String?> askText(
  BuildContext context,
  String title, [
  String initial = '',
]) => _ask(context, title, initial);
