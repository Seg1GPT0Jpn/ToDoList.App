import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/account_screen.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../app/usage_meter.dart';
import '../art/paper.dart';
import '../vocab/vocab_store.dart';
import '../vocab/word_forest_screen.dart' show loadWordList;
import 'duel_backend.dart';

class DuelText {
  const DuelText._();

  static const title = '単語チャレンジ';
  static const intro =
      '10問の早押し4択（英→日）。先にあなたが解いて、リンクを友だちに送ります。'
      '友だちは好きなときに同じ問題で挑戦できます（1人1回・7日間）。';
  static const privacy =
      '送るのは単語帳の名前と番号、名前と点数だけ。単語の中身は送りません。'
      '自分の単語帳（LEAP など）で作ったときは、友だちも同じ名前の単語帳を持っていると挑戦できます。';
  static const noBackend = 'この版では、単語チャレンジは使えません（サーバーの設定がありません）';
  static const needLogin = '単語チャレンジは、Google でログインすると使えます';

  static String link(String id) => 'https://tsuzuri-quest-v2.web.app/?duel=$id';

  static String invite(WordDuel d, int score) =>
      '単語チャレンジ「${d.title}」で $score 点！ 勝てるかな？\n${link(d.id)}';

  /// 貼り付けた文字（リンクでも ID だけでも）から ID を取り出す
  static String? idFrom(String text) {
    final t = text.trim();
    final m = RegExp(r'duel=([a-z0-9]{8})').firstMatch(t);
    if (m != null) return m.group(1);
    return WordDuel.validId(t) ? t : null;
  }
}

/// 出題のもとの候補
class _Source {
  const _Source(this.kind, this.id, this.title, {this.book});
  final DuelSource kind;

  /// つづ単の一覧 ID、または自分の単語帳の ID
  final String id;
  final String title;
  final VocabBook? book;
}

/// 単語チャレンジの入口：作る・受け取ったリンクを開く
class DuelHubScreen extends StatefulWidget {
  const DuelHubScreen({
    super.key,
    this.bookId,
    this.from,
    this.to,
    this.backend,
  });

  /// はじめに選んでおく単語帳と範囲（クラスルームから来たとき）
  final String? bookId;
  final int? from;
  final int? to;

  /// テスト用（ふだんは RpgServices.duels）
  final DuelBackend? backend;

  @override
  State<DuelHubScreen> createState() => _DuelHubScreenState();
}

class _DuelHubScreenState extends State<DuelHubScreen> {
  @override
  void initState() {
    super.initState();
    UsageMeter.mark(context, 'duel');
  }

  final _name = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _link = TextEditingController();
  String? _picked;
  String? _error;
  bool _busy = false;

  DuelBackend? get _backend => widget.backend ?? RpgServices.of(context).duels;

  VocabStore get _store => VocabStore.of(RpgServices.of(context).personalBooks);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_picked != null) return;
    final services = RpgServices.of(context);
    _name.text = services.classroomStore.nickname;
    if (widget.bookId != null) {
      _picked = 'book:${widget.bookId}';
      if (widget.from != null) _from.text = '${widget.from}';
      if (widget.to != null) _to.text = '${widget.to}';
    } else {
      _picked = 'tsuzutan:${Tsuzutan.lists.first.id}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _from.dispose();
    _to.dispose();
    _link.dispose();
    super.dispose();
  }

  List<_Source> _sources() => [
    for (final l in Tsuzutan.lists)
      _Source(DuelSource.tsuzutan, l.id, 'つづ単 ${l.title}'),
    for (final b in _store.visibleBooks)
      if (b.cards.any((c) => c.number != null))
        _Source(DuelSource.book, b.id, b.title, book: b),
  ];

  Future<void> _create() async {
    final backend = _backend;
    if (backend == null) return;
    final src = _sources().where((s) => '${s.kind.name}:${s.id}' == _picked);
    if (src.isEmpty) return;
    final s = src.first;
    final name = Classroom.cleanName(_name.text, fallback: 'あなた');
    final classes = RpgServices.of(context).classroomStore;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final book = s.book ?? DuelRules.bookOf(await loadWordList(s.id));
      final from = int.tryParse(_from.text.trim());
      final to = int.tryParse(_to.text.trim());
      final random = Random();
      final numbers = DuelRules.pick(
        book,
        random,
        from: s.book == null ? null : from,
        to: s.book == null ? null : to,
      );
      if (numbers.length < 4) {
        throw const DuelException('その範囲には単語が少なすぎます（4語以上にしてください）');
      }
      final range = s.book != null && (from != null || to != null)
          ? ' ${from ?? 1}〜${to ?? ''}'
          : '';
      final draft = WordDuel(
        id: '',
        ownerId: '',
        ownerName: name,
        source: s.kind,
        sourceId: s.book == null ? s.id : ClassBooks.keyOf(s.book!),
        title: Classroom.cleanName('${s.title}$range', fallback: '単語'),
        numbers: numbers,
        seed: random.nextInt(1 << 30),
      );
      if (!mounted) return;
      final result = await Navigator.of(context).push<DuelResult>(
        MaterialPageRoute(
          builder: (_) => DuelPlayScreen(
            name: name,
            title: draft.title,
            questions: DuelRules.build(book, numbers, draft.seed),
            store: s.book == null ? null : _store,
            book: s.book,
          ),
        ),
      );
      if (result == null || !mounted) return;
      final duel = await backend.create(draft, result);
      await classes.setNickname(name);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DuelResultScreen(duel: duel, backend: backend),
        ),
      );
    } on DuelException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'うまくいきませんでした：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLink() {
    final id = DuelText.idFrom(_link.text);
    if (id == null) {
      setState(() => _error = 'リンクか8文字のIDを貼り付けてください');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DuelOpenScreen(id: id, backend: widget.backend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    final sources = _sources();
    final picked = sources
        .where((s) => '${s.kind.name}:${s.id}' == _picked)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(DuelText.title, style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
          children: [
            const Text(DuelText.intro, style: TextStyle(height: 1.5)),
            const SizedBox(height: 6),
            Text(
              DuelText.privacy,
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 16),
            if (backend == null)
              const Text(DuelText.noBackend)
            else if (backend.userId == null)
              _LoginPrompt(onBack: () => setState(() {}))
            else ...[
              Text('チャレンジをつくる', style: serif(16)),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('duel-name'),
                controller: _name,
                maxLength: Classroom.maxName,
                decoration: const InputDecoration(
                  labelText: 'ニックネーム（友だちに見えます）',
                  isDense: true,
                ),
              ),
              DropdownButton<String>(
                key: const ValueKey('duel-source'),
                isExpanded: true,
                value: picked == null ? null : _picked,
                items: [
                  for (final s in sources)
                    DropdownMenuItem(
                      value: '${s.kind.name}:${s.id}',
                      child: Text(s.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _picked = v),
              ),
              if (picked?.book != null)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('duel-from'),
                        controller: _from,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '番号（から）',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('duel-to'),
                        controller: _to,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '番号（まで）',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('duel-create'),
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.flash_on),
                label: Text(_busy ? '準備しています…' : '先に解いて、リンクをつくる'),
              ),
              const SizedBox(height: 24),
              Text('受け取ったチャレンジ', style: serif(16)),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('duel-link'),
                controller: _link,
                decoration: const InputDecoration(
                  labelText: 'リンクかIDを貼り付け',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('duel-open'),
                onPressed: _openLink,
                child: const Text('ひらく'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(DuelText.needLogin),
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const ValueKey('duel-login'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
          );
          onBack();
        },
        icon: const Icon(Icons.login),
        label: const Text('ログインする'),
      ),
    ],
  );
}

/// 受け取ったリンクから開く：まだなら挑戦、挑戦ずみなら順位
class DuelOpenScreen extends StatefulWidget {
  const DuelOpenScreen({super.key, required this.id, this.backend});

  final String id;
  final DuelBackend? backend;

  @override
  State<DuelOpenScreen> createState() => _DuelOpenScreenState();
}

class _DuelOpenScreenState extends State<DuelOpenScreen> {
  @override
  void initState() {
    super.initState();
    UsageMeter.mark(context, 'duel');
  }

  final _name = TextEditingController();
  Future<(WordDuel?, VocabBook?)>? _load;
  String? _error;
  bool _busy = false;

  DuelBackend? get _backend => widget.backend ?? RpgServices.of(context).duels;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_load != null) return;
    _name.text = RpgServices.of(context).classroomStore.nickname;
    _reload();
  }

  void _reload() {
    final backend = _backend;
    if (backend == null || backend.userId == null) return;
    final store = VocabStore.of(RpgServices.of(context).personalBooks);
    _load = () async {
      final d = await backend.fetch(widget.id);
      if (d == null) return (null, null);
      VocabBook? book;
      if (d.source == DuelSource.tsuzutan) {
        if (Tsuzutan.lists.any((l) => l.id == d.sourceId)) {
          book = DuelRules.bookOf(await loadWordList(d.sourceId));
        }
      } else {
        book = store.visibleBooks
            .where((b) => ClassBooks.keyOf(b) == d.sourceId)
            .firstOrNull;
      }
      return (d, book);
    }();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _play(WordDuel d, VocabBook book) async {
    final backend = _backend!;
    final name = Classroom.cleanName(_name.text, fallback: 'あなた');
    final store = d.source == DuelSource.book
        ? VocabStore.of(RpgServices.of(context).personalBooks)
        : null;
    final result = await Navigator.of(context).push<DuelResult>(
      MaterialPageRoute(
        builder: (_) => DuelPlayScreen(
          name: name,
          title: d.title,
          questions: DuelRules.build(book, d.numbers, d.seed),
          store: store,
          book: store == null ? null : book,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await backend.submit(d.id, result);
      if (!mounted) return;
      await RpgServices.of(context).classroomStore.setNickname(name);
      setState(_reload);
    } on DuelException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    return Scaffold(
      appBar: AppBar(title: Text(DuelText.title, style: serif(18))),
      body: NotebookPaper(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
          child: backend == null
              ? const Text(DuelText.noBackend)
              : backend.userId == null
              ? _LoginPrompt(onBack: () => setState(_reload))
              : FutureBuilder<(WordDuel?, VocabBook?)>(
                  future: _load,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text('読みこめませんでした：${snap.error}');
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final (d, book) = snap.data!;
                    if (d == null) {
                      return const Text(
                        'チャレンジが見つかりません（リンクがまちがっているか、消えました）',
                        key: ValueKey('duel-missing'),
                      );
                    }
                    final uid = backend.userId!;
                    if (d.played(uid)) {
                      return DuelRanking(duel: d, me: uid);
                    }
                    return ListView(
                      children: [
                        Text('${d.ownerName}さんからの挑戦', style: serif(18)),
                        const SizedBox(height: 4),
                        Text('「${d.title}」 ${d.numbers.length}問'),
                        const SizedBox(height: 12),
                        DuelRanking(duel: d, me: uid, compact: true),
                        const SizedBox(height: 12),
                        if (d.expired(DateTime.now()))
                          const Text('このチャレンジは期限切れです')
                        else if (d.full)
                          const Text('このチャレンジは満員です')
                        else if (book == null)
                          Text(
                            '「${d.title}」の単語帳がこの端末にありません。'
                            '同じ名前の単語帳を開く（取り込む）と挑戦できます。',
                            key: const ValueKey('duel-no-book'),
                          )
                        else ...[
                          TextField(
                            key: const ValueKey('duel-open-name'),
                            controller: _name,
                            maxLength: Classroom.maxName,
                            decoration: const InputDecoration(
                              labelText: 'ニックネーム（みんなに見えます）',
                              isDense: true,
                            ),
                          ),
                          FilledButton.icon(
                            key: const ValueKey('duel-accept'),
                            onPressed: _busy ? null : () => _play(d, book),
                            icon: const Icon(Icons.flash_on),
                            label: const Text('挑戦する（1回だけ）'),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// 作ったあと：点数と、友だちに送るリンク
class DuelResultScreen extends StatelessWidget {
  const DuelResultScreen({
    super.key,
    required this.duel,
    required this.backend,
  });

  final WordDuel duel;
  final DuelBackend backend;

  @override
  Widget build(BuildContext context) {
    final mine = duel.results[backend.userId];
    return Scaffold(
      appBar: AppBar(title: Text(DuelText.title, style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
          children: [
            Text('「${duel.title}」', style: serif(18)),
            const SizedBox(height: 8),
            Text(
              'あなたは ${mine?.correct ?? 0}問正解・${mine?.score ?? 0}点',
              key: const ValueKey('duel-my-score'),
              style: serif(22),
            ),
            const SizedBox(height: 16),
            const Text('このリンクを友だちに送ろう（7日間・30人まで）'),
            const SizedBox(height: 4),
            SelectableText(DuelText.link(duel.id)),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('duel-copy'),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: DuelText.invite(duel, mine?.score ?? 0)),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('招待の文をコピーしました。LINE などに貼り付けて送ってね'),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('招待の文をコピー'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('duel-see-ranking'),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => DuelOpenScreen(id: duel.id, backend: backend),
                ),
              ),
              child: const Text('順位を見る'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 順位表
class DuelRanking extends StatelessWidget {
  const DuelRanking({
    super.key,
    required this.duel,
    required this.me,
    this.compact = false,
  });

  final WordDuel duel;
  final String me;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = duel.ranking;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(compact ? 'いまの順位' : '「${duel.title}」の順位', style: serif(16)),
        const SizedBox(height: 6),
        for (final (i, (uid, r)) in rows.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${i + 1}位　${r.name}${uid == me ? '（あなた）' : ''}　'
              '${r.correct}問正解・${r.score}点',
              key: ValueKey('duel-row-$i'),
              style: TextStyle(
                fontWeight: uid == me ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
    if (compact) return list;
    return ListView(
      children: [
        list,
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: DuelText.link(duel.id))),
          icon: const Icon(Icons.copy),
          label: const Text('リンクをコピー（ほかの友だちにも）'),
        ),
      ],
    );
  }
}

/// 早押しの本体：1問10秒の4択。早く正解するほど点が高い。
/// 終わると [DuelResult] を返して閉じる（途中でやめたら null）
class DuelPlayScreen extends StatefulWidget {
  const DuelPlayScreen({
    super.key,
    required this.name,
    required this.title,
    required this.questions,
    this.store,
    this.book,
  });

  final String name;
  final String title;
  final List<DuelQuestion> questions;

  /// 自分の単語帳で解くときは、学習記録にも残す
  final VocabStore? store;
  final VocabBook? book;

  @override
  State<DuelPlayScreen> createState() => _DuelPlayScreenState();
}

class _DuelPlayScreenState extends State<DuelPlayScreen> {
  static const _tick = Duration(milliseconds: 100);

  int _index = 0;
  int _correct = 0;
  int _score = 0;
  Duration _took = Duration.zero;
  int? _picked;
  Timer? _timer;

  bool get _done => _index >= widget.questions.length;
  DuelQuestion get _q => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _took = Duration.zero;
    _picked = null;
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted || _picked != null) return;
      setState(() => _took += _tick);
      if (_took >= DuelRules.limit) _answer(-1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _answer(int i) {
    if (_picked != null || _done) return;
    _timer?.cancel();
    final ok = i == _q.answer;
    final store = widget.store, book = widget.book;
    if (store != null && book != null) {
      store
          .progress(book.id)
          .record(
            cardId: _q.card.id,
            skill: VocabSkill.meaning,
            rating: ok ? Rating.good : Rating.again,
            now: DateTime.now(),
            spent: _took,
          );
    }
    setState(() {
      _picked = i;
      if (ok) _correct++;
      _score += DuelRules.points(ok, _took);
    });
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _index++);
      if (_done) {
        _finish();
      } else {
        _start();
      }
    });
  }

  Future<void> _finish() async {
    final store = widget.store, book = widget.book;
    if (store != null && book != null) await store.saveProgress(book.id);
    if (!mounted) return;
    Navigator.of(context)
        .pop(DuelResult(name: widget.name, correct: _correct, score: _score));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: serif(16))),
      body: NotebookPaper(
        child: _done
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
                children: [
                  Text(
                    '${_index + 1} / ${widget.questions.length}　$_score点',
                    style: TextStyle(color: TsuzuriColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value:
                        1 -
                        _took.inMilliseconds / DuelRules.limit.inMilliseconds,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      _q.card.term,
                      key: const ValueKey('duel-term'),
                      style: serif(30),
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final (i, c) in _q.choices.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        key: ValueKey('duel-choice-$i'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(14),
                          backgroundColor: _picked == null
                              ? null
                              : i == _q.answer
                              ? Colors.green.withValues(alpha: 0.2)
                              : i == _picked
                              ? Colors.red.withValues(alpha: 0.2)
                              : null,
                        ),
                        onPressed: () => _answer(i),
                        child: Text(c, textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
