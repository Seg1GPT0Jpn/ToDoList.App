import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../study/shonan_question_list.dart';

/// 問題集：アプリに入っている全問題を、教科 → 問題セットの順に、答え・解説つきで見る
class QuestionLibraryScreen extends StatelessWidget {
  const QuestionLibraryScreen({super.key});

  /// 教科（worldId, 名前, アイコン）
  static const subjects = [
    ('math', '数学', Icons.functions),
    ('science', '理科', Icons.science_outlined),
    ('social', '社会', Icons.public),
    ('japanese', '国語', Icons.menu_book_outlined),
    ('english', '英語', Icons.translate),
    ('sea', '英文法', Icons.sailing_outlined),
    ('information', '情報', Icons.computer),
    ('music', '音楽', Icons.music_note_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('問題集・解説', style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'アプリに入っている問題を、答えと解説つきで見られます。'
              '計算や表から作る問題（自動）もふくみます。',
              style: TextStyle(
                fontSize: 12,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final (world, name, icon) in subjects)
              Card(
                child: ListTile(
                  key: ValueKey('library-subject-$world'),
                  leading: Icon(icon, color: TsuzuriColors.accent),
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuestionLibrarySubjectScreen(
                        world: world,
                        name: name,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 問題セットの見出し（いちばん多い単元の名前）
String _setLabel(QuestionSet s) {
  final count = <String, int>{};
  for (final q in s.questions) {
    final u = q.unit;
    if (u == null || !Curriculum.contains(u)) continue;
    count[u] = (count[u] ?? 0) + 1;
  }
  if (count.isEmpty) return s.setId;
  final top = count.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  final path = Curriculum.breadcrumb(top).split(' ＞ ');
  return path.skip(path.length > 2 ? path.length - 2 : 0).join(' ＞ ');
}

/// 教科の問題セットの一覧。教科全体からことばで探せる
class QuestionLibrarySubjectScreen extends StatefulWidget {
  const QuestionLibrarySubjectScreen({
    super.key,
    required this.world,
    required this.name,
  });

  final String world;
  final String name;

  @override
  State<QuestionLibrarySubjectScreen> createState() =>
      _QuestionLibrarySubjectScreenState();
}

class _QuestionLibrarySubjectScreenState
    extends State<QuestionLibrarySubjectScreen> {
  List<QuestionSet>? _sets;
  String _query = '';
  bool _hideAnswers = false;
  var _started = false;

  /// 探したときに出す問題の上限（多すぎると重くなる）
  static const _maxHits = 200;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final source = RpgServices.of(context).questions;
    final ids = (await RpgServices.questionSetsOf(widget.world)).keys.toList()
      ..sort();
    final sets = <QuestionSet>[];
    for (final id in ids) {
      final s = await source.load(id);
      if (s != null) sets.add(s);
    }
    if (mounted) setState(() => _sets = sets);
  }

  @override
  Widget build(BuildContext context) {
    final sets = _sets;
    final total = sets?.fold<int>(0, (n, s) => n + s.questions.length) ?? 0;
    final hits = <QuizQuestion>[];
    if (sets != null && _query.isNotEmpty) {
      for (final s in sets) {
        for (final q in s.questions) {
          if (QuestionAnswerText.matches(q, _query)) hits.add(q);
          if (hits.length > _maxHits) break;
        }
        if (hits.length > _maxHits) break;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('問題集｜${widget.name}', style: serif(17)),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: _hideAnswers ? '答えを見せる' : '答えをかくす',
              icon: Icon(
                _hideAnswers ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _hideAnswers = !_hideAnswers),
            ),
        ],
      ),
      body: NotebookPaper(
        child: sets == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                children: [
                  TextField(
                    key: const ValueKey('library-search'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '${widget.name}の全$total問から探す',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                  const SizedBox(height: 8),
                  if (_query.isNotEmpty) ...[
                    Text(
                      hits.length > _maxHits
                          ? '$_maxHits問以上見つかりました。ことばを足してしぼりこんでください。'
                          : '${hits.length}問見つかりました',
                      style: TextStyle(
                        fontSize: 12,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ),
                    for (final (i, q) in hits.take(_maxHits).indexed)
                      QuestionAnswerTile(
                        key: ValueKey('library-hit-${q.id}'),
                        number: i + 1,
                        question: q,
                        hideAnswer: _hideAnswers,
                        passage: q.passage,
                      ),
                  ] else
                    for (final s in sets)
                      Card(
                        child: ListTile(
                          key: ValueKey('library-set-${s.setId}'),
                          title: Text(_setLabel(s)),
                          subtitle: Text(
                            '${s.setId}・${s.questions.length}問',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuestionLibrarySetScreen(set: s),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}

/// 1つの問題セットの問題を、答え・解説つきで見る
class QuestionLibrarySetScreen extends StatefulWidget {
  const QuestionLibrarySetScreen({super.key, required this.set});

  final QuestionSet set;

  @override
  State<QuestionLibrarySetScreen> createState() =>
      _QuestionLibrarySetScreenState();
}

class _QuestionLibrarySetScreenState extends State<QuestionLibrarySetScreen> {
  bool _hideAnswers = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final qs = [
      for (final q in widget.set.questions)
        if (QuestionAnswerText.matches(q, _query)) q,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_setLabel(widget.set), style: serif(16)),
        actions: [
          IconButton(
            key: const ValueKey('library-hide'),
            tooltip: _hideAnswers ? '答えを見せる' : '答えをかくす',
            icon: Icon(_hideAnswers ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hideAnswers = !_hideAnswers),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        itemCount: qs.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const ValueKey('library-set-search'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ことばで探す（問題・選択肢・解説）',
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.set.setId}・${qs.length}問　'
                  '${_hideAnswers ? '答えをかくしています（右上の目のボタンで切りかえ）' : '問題を開くと、正解（✓）と解説が見られます'}',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
              ],
            );
          }
          final q = qs[i - 1];
          return QuestionAnswerTile(
            key: ValueKey('library-q-${q.id}'),
            number: i,
            question: q,
            hideAnswer: _hideAnswers,
            passage: q.passage,
            passageKeyPrefix: 'library-q-passage-',
          );
        },
      ),
    );
  }
}
