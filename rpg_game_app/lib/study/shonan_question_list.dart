import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import 'ec_text.dart';

/// 科目に登録した問題セットの問題を、答え・解説つきで一覧にする
class ShonanQuestionListScreen extends StatefulWidget {
  const ShonanQuestionListScreen({
    super.key,
    required this.subject,
    required this.plan,
  });

  final SchoolSubject subject;
  final SubjectExamPlan plan;

  @override
  State<ShonanQuestionListScreen> createState() =>
      _ShonanQuestionListScreenState();
}

class _ShonanQuestionListScreenState extends State<ShonanQuestionListScreen> {
  List<QuestionSet>? _sets;
  List<SetIssue> _issues = const [];
  List<Passage> _passages = const [];
  bool _hideAnswers = false;
  String _query = '';

  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final services = RpgServices.of(context);
    final r = await SchoolPractice.build(
      widget.subject,
      widget.plan,
      services.questions.load,
    );
    final sets = <QuestionSet>[];
    for (final id in r.usedSetIds) {
      final s = await services.questions.load(id);
      if (s != null) sets.add(s);
    }
    final passages = widget.subject.id == 'ec1'
        ? await EcText.saved(services.personalBooks.prefs) ?? const <Passage>[]
        : const <Passage>[];
    if (!mounted) return;
    setState(() {
      _sets = sets;
      _issues = r.issues;
      _passages = passages;
    });
  }

  bool _match(QuizQuestion q) {
    if (_query.isEmpty) return true;
    final t = _query.toLowerCase();
    return q.prompt.toLowerCase().contains(t) ||
        (q.explanation ?? '').toLowerCase().contains(t) ||
        q.choices.any((c) => c.toLowerCase().contains(t));
  }

  @override
  Widget build(BuildContext context) {
    final sets = _sets;
    final seen = <String>{};
    var n = 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('問題一覧｜${widget.subject.displayName}'),
        actions: [
          IconButton(
            key: const ValueKey('shonan-list-hide'),
            tooltip: _hideAnswers ? '答えを見せる' : '答えをかくす',
            icon: Icon(_hideAnswers ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hideAnswers = !_hideAnswers),
          ),
        ],
      ),
      body: sets == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              children: [
                TextField(
                  key: const ValueKey('shonan-list-search'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ことばで探す（問題・選択肢・解説）',
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 6),
                Text(
                  _hideAnswers
                      ? '答えをかくしています。問題を開くと選択肢だけ出ます（右上の目のボタンで切りかえ）。'
                      : '問題を開くと、正解（✓）と解説が見られます。',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
                for (final i in _issues)
                  Text(
                    '・$i',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                if (sets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('読める問題セットがありません。'),
                  ),
                for (final s in sets) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Text(
                      '${s.setId}（${s.questions.length}問）',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: TsuzuriColors.accent,
                      ),
                    ),
                  ),
                  for (final q in s.questions)
                    if (seen.add(q.id) && _match(q))
                      _QuestionTile(
                        key: ValueKey('shonan-q-${q.id}'),
                        number: ++n,
                        question: q,
                        hideAnswer: _hideAnswers,
                        passage: q.passage ?? EcText.passageFor(q, _passages),
                      ),
                ],
              ],
            ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    super.key,
    required this.number,
    required this.question,
    required this.hideAnswer,
    this.passage,
  });

  final int number;
  final QuizQuestion question;
  final bool hideAnswer;
  final Passage? passage;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final style = const TextStyle(fontSize: 14, height: 1.5);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text('Q$number. ${q.prompt}', style: style),
        children: [
          if (q.sentence != null) Text(q.sentence!, style: style),
          for (final (i, c) in q.choices.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${!hideAnswer && i == q.answerIndex ? '✓' : '　'} ${String.fromCharCode(0x2460 + i)} $c',
                style: style.copyWith(
                  fontWeight: !hideAnswer && i == q.answerIndex
                      ? FontWeight.w800
                      : FontWeight.normal,
                  color: !hideAnswer && i == q.answerIndex
                      ? TsuzuriColors.accent
                      : null,
                ),
              ),
            ),
          if (!hideAnswer && (q.explanation ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('解説：${q.explanation}', style: style.copyWith(fontSize: 13)),
          ],
          if (passage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey('shonan-q-passage-${q.id}'),
                icon: const Icon(Icons.menu_book, size: 18),
                label: Text('本文（${passage!.title.split('—').last.trim()}）'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PassageScreen(passages: [passage!]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 本文を読む画面
class PassageScreen extends StatelessWidget {
  const PassageScreen({super.key, required this.passages, this.title});

  final List<Passage> passages;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? '本文')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            for (final p in passages) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Text(
                  p.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TsuzuriColors.accent,
                  ),
                ),
              ),
              for (final para in p.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    para,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// EC の本文：はじめはパスワードを入れて開く。開いたら Lesson ごとに読める
class EcTextScreen extends StatefulWidget {
  const EcTextScreen({super.key});

  @override
  State<EcTextScreen> createState() => _EcTextScreenState();
}

class _EcTextScreenState extends State<EcTextScreen> {
  final _pw = TextEditingController();
  List<Passage>? _passages;
  bool _loading = true;
  String? _error;

  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    EcText.saved(RpgServices.of(context).personalBooks.prefs).then((p) {
      if (mounted) {
        setState(() {
          _passages = p;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _loading = true);
    final p = await EcText.unlock(
      RpgServices.of(context).personalBooks.prefs,
      _pw.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _passages = p;
      _error = p == null ? 'パスワードがちがいます' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ps = _passages;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (ps == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EC 本文')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '教科書の本文なので、パスワードで守っています。\n'
              '一度開くと、この端末では次から自動で開きます。開くと、演習の問題の中にも本文が出ます。',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('ec-text-password'),
              controller: _pw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'パスワード',
                errorText: _error,
              ),
              onSubmitted: (_) => _open(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('ec-text-open'),
              onPressed: _open,
              child: const Text('開く'),
            ),
          ],
        ),
      );
    }
    final lessons = <String, List<Passage>>{};
    for (final p in ps) {
      (lessons[p.title.split('—').first.trim()] ??= []).add(p);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('EC 本文')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final MapEntry(key: lesson, value: list) in lessons.entries)
            Card(
              child: ExpansionTile(
                key: ValueKey('ec-lesson-$lesson'),
                title: Text(
                  lesson,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                children: [
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('ぜんぶ通して読む'),
                    onTap: () => _read(context, list, lesson),
                  ),
                  for (final p in list)
                    ListTile(
                      dense: true,
                      title: Text(p.title.split('—').last.trim()),
                      subtitle: Text(
                        p.paragraphs.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _read(context, [p], lesson),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _read(BuildContext context, List<Passage> ps, String title) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PassageScreen(passages: ps, title: title),
        ),
      );
}
