import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'personal_books.dart';
import 'sea_quiz_screen.dart';

/// 定期テストの海：単元・単語帳を選ぶ画面
class SeaHomeScreen extends StatelessWidget {
  const SeaHomeScreen({super.key, required this.personalBooks});

  final PersonalBooks personalBooks;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE6F0F5),
          title: Text(
            '定期テストの海',
            style: serif(19, color: const Color(0xFF2F5D7C)),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Color(0xFF2F5D7C),
            indicatorColor: Color(0xFF2F5D7C),
            tabs: [
              Tab(text: '高1'),
              Tab(text: '高2'),
              Tab(text: '高3'),
              Tab(text: '単語・熟語'),
              Tab(icon: Icon(Icons.lock_outline, size: 16), text: 'LEAP'),
            ],
          ),
        ),
        body: NotebookPaper(
          child: StreamBuilder<RpgProgress>(
            stream: RpgServices.of(context).repository.watch(),
            builder: (context, snap) {
              final progress = snap.data ?? RpgProgress.initial;
              return TabBarView(
                children: [
                  _GradeTab(grade: 1, progress: progress),
                  _GradeTab(grade: 2, progress: progress),
                  _GradeTab(grade: 3, progress: progress),
                  _WordsTab(progress: progress),
                  _LeapTab(books: personalBooks, progress: progress),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _bestBadge(int? best) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: best == null
        ? const Color(0xFFEDE3D1)
        : best >= 80
        ? TsuzuriColors.correct.withValues(alpha: 0.15)
        : const Color(0xFFFFF1D6),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    best == null ? '未挑戦' : 'ベスト $best%',
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: best == null ? TsuzuriColors.inkSoft : TsuzuriColors.ink,
    ),
  ),
);

class _GradeTab extends StatelessWidget {
  const _GradeTab({required this.grade, required this.progress});
  final int grade;
  final RpgProgress progress;

  Future<void> _open(BuildContext context, SeaUnit unit) async {
    final set = await RpgServices.of(context).questions.load(unit.id);
    if (set == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeaQuizScreen(
          title: '高$grade ${unit.number}. ${unit.title}',
          recordId: unit.id,
          questions: set.questions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = SeaCatalog.unitsOf(grade);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        Text(
          SeaCatalog.gradeNames[grade]!,
          style: serif(15, color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 8),
        for (final u in units)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(context, u),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF2F5D7C),
                          child: Text(
                            '${u.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(u.title, style: serif(16))),
                        _bestBadge(progress.seaBest[u.id]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in u.topics)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F0F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2F5D7C),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WordsTab extends StatelessWidget {
  const _WordsTab({required this.progress});
  final RpgProgress progress;

  Future<void> _open(
    BuildContext context,
    SeaWordBook book,
    WordQuizDirection dir,
  ) async {
    final raw = await rootBundle.loadString(
      'packages/rpg_game/assets/words/${book.id}.json',
    );
    final list = WordList.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final set = WordQuizBuilder().build(list, direction: dir);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SeaQuizScreen(
          title:
              '${book.title}（${dir == WordQuizDirection.enToJa ? '英→日' : '日→英'}）',
          recordId: '${book.id}_${dir.name}',
          questions: set.questions,
          count: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        Text('1回20問（ランダム）', style: serif(15, color: TsuzuriColors.inkSoft)),
        const SizedBox(height: 8),
        for (final b in SeaCatalog.wordBooks)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title, style: serif(16)),
                  Text(
                    b.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final dir in WordQuizDirection.values) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _open(context, b, dir),
                            child: Column(
                              children: [
                                Text(
                                  dir == WordQuizDirection.enToJa
                                      ? '英→日'
                                      : '日→英',
                                ),
                                const SizedBox(height: 2),
                                _bestBadge(
                                  progress.seaBest['${b.id}_${dir.name}'],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (dir == WordQuizDirection.enToJa)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// LEAP（パスワード保護・端末内に取り込んだ単語帳）
class _LeapTab extends StatefulWidget {
  const _LeapTab({required this.books, required this.progress});
  final PersonalBooks books;
  final RpgProgress progress;

  @override
  State<_LeapTab> createState() => _LeapTabState();
}

class _LeapTabState extends State<_LeapTab> {
  final _password = TextEditingController();
  final _paste = TextEditingController();
  String? _message;
  WordQuizDirection _dir = WordQuizDirection.enToJa;

  PersonalBooks get books => widget.books;

  @override
  void dispose() {
    _password.dispose();
    _paste.dispose();
    super.dispose();
  }

  WordList? get _list {
    final text = books.leapText;
    if (text == null) return null;
    return WordList.parsePasted(listId: 'leap', title: 'LEAP', text: text);
  }

  @override
  Widget build(BuildContext context) {
    if (!books.leapUnlocked) return _gate();
    final list = _list;
    if (list == null || list.words.length < 4) return _importer();
    return _ranges(list);
  }

  Widget _gate() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 24, 16, 24),
      children: [
        const Icon(Icons.lock, size: 40, color: TsuzuriColors.inkSoft),
        const SizedBox(height: 8),
        Center(child: Text('パスワードを入力してください', style: serif(16))),
        const SizedBox(height: 6),
        const Text(
          '市販教材の単語を使うモードです。個人の学習用にだけ使ってください。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'パスワード',
          ),
          onSubmitted: (_) => _unlock(),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: TsuzuriColors.wrong)),
        ],
        const SizedBox(height: 12),
        FilledButton(onPressed: _unlock, child: const Text('ひらく')),
      ],
    );
  }

  void _unlock() {
    setState(() {
      _message = books.tryUnlock(_password.text) ? null : 'パスワードがちがいます';
    });
  }

  Widget _importer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
      children: [
        Text('LEAP の単語リストを取り込む', style: serif(16)),
        const SizedBox(height: 6),
        const Text(
          '「番号・英単語・意味」が並んだ一覧（1行に1語、タブ区切り）をそのまま貼り付けてください。'
          'データはこの端末の中にだけ保存され、インターネットには送られません。',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: TsuzuriColors.inkSoft,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _paste,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '1\tagree\t[自] ①賛成する ...',
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: TsuzuriColors.wrong)),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _import,
          icon: const Icon(Icons.download),
          label: const Text('取り込む'),
        ),
      ],
    );
  }

  Future<void> _import() async {
    final skipped = <int>[];
    final list = WordList.parsePasted(
      listId: 'leap',
      title: 'LEAP',
      text: _paste.text,
      skipped: skipped,
    );
    if (list.words.length < 4) {
      setState(() => _message = '単語を読み取れませんでした。一覧をそのまま貼り付けてください。');
      return;
    }
    await books.saveLeapText(_paste.text);
    _paste.clear();
    if (!mounted) return;
    setState(() => _message = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${list.words.length}語を取り込みました'
          '${skipped.isEmpty ? '' : '（読めなかった行: ${skipped.length}行）'}',
        ),
      ),
    );
  }

  Widget _ranges(WordList list) {
    const size = 100;
    final chunks = <List<WordEntry>>[
      for (var i = 0; i < list.words.length; i += size)
        list.words.sublist(i, (i + size).clamp(0, list.words.length)),
    ];
    String label(List<WordEntry> c) =>
        '${c.first.number ?? list.words.indexOf(c.first) + 1}〜${c.last.number ?? list.words.indexOf(c.last) + 1}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('LEAP（${list.words.length}語）', style: serif(16)),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'reimport') {
                  await books.deleteLeapText();
                } else if (v == 'lock') {
                  await books.lock();
                }
                setState(() {});
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'reimport', child: Text('取り込み直す')),
                PopupMenuItem(value: 'lock', child: Text('鍵をかける')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        SegmentedButton<WordQuizDirection>(
          segments: const [
            ButtonSegment(value: WordQuizDirection.enToJa, label: Text('英→日')),
            ButtonSegment(value: WordQuizDirection.jaToEn, label: Text('日→英')),
          ],
          selected: {_dir},
          onSelectionChanged: (s) => setState(() => _dir = s.first),
        ),
        const SizedBox(height: 10),
        const Text(
          '範囲を選ぶと、その中から20問出題します。',
          style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in chunks)
              ActionChip(
                label: Column(
                  children: [
                    Text(label(c)),
                    Text(
                      widget
                                  .progress
                                  .seaBest['leap_${label(c)}_${_dir.name}'] ==
                              null
                          ? '―'
                          : 'ベスト ${widget.progress.seaBest['leap_${label(c)}_${_dir.name}']}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  if (c.isEmpty) return;
                  final set = WordQuizBuilder().build(
                    list,
                    direction: _dir,
                    only: c,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SeaQuizScreen(
                        title:
                            'LEAP ${label(c)}（${_dir == WordQuizDirection.enToJa ? '英→日' : '日→英'}）',
                        recordId: 'leap_${label(c)}_${_dir.name}',
                        questions: set.questions,
                        count: 20,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
