import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../vocab/vocab_book_screen.dart';
import '../vocab/vocab_session_screen.dart';
import '../vocab/vocab_store.dart';
import '../vocab/weak_cards_screen.dart';
import 'realm_style.dart';
import 'sea_battle_launcher.dart';
import '../vocab/status_dots.dart';

/// 暗記カード（物理・日本史など）を読み込む。読めなければ null。
Future<TermDeck?> loadTermDeck(TermDeckInfo info) async {
  final hit = _decks[info.id];
  if (hit != null) return hit;
  try {
    final raw = await rootBundle.loadString(info.assetPath);
    return _decks[info.id] = TermDeck.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  } catch (_) {
    return null;
  }
}

final _decks = <String, TermDeck>{};

Widget _badge(int? best) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: best == null
        ? TsuzuriColors.tint(0xFFEDE3D1)
        : best >= 80
        ? TsuzuriColors.correct.withValues(alpha: 0.15)
        : TsuzuriColors.tint(0xFFFFF1D6),
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

/// 暗記カードを単語帳の形にしたもの（学習記録は英語の単語帳と同じしくみで残る）
VocabBook termBook(TermDeck deck) => _books[deck.id] ??= deck.toBook();

final _books = <String, VocabBook>{};

/// 定期テストの海・模擬試験の空の「暗記カード」タブ。
///
/// 教科のワールドを解放すると使える。英語の単語帳と同じように、
/// 忘れかけた順の復習（今日の最適学習）・用語を書く練習・熟練度・分析・苦手克服カードが使える。
/// カードから作った4択問題で魔物とも戦える（RPG では出ない）。
class TermCardsTab extends StatefulWidget {
  const TermCardsTab({
    super.key,
    required this.world,
    required this.progress,
    this.realm = StudyRealm.sea,
  });

  final WorldDef world;
  final RpgProgress progress;
  final StudyRealm realm;

  @override
  State<TermCardsTab> createState() => _TermCardsTabState();
}

class _TermCardsTabState extends State<TermCardsTab> {
  /// 教科の暗記カード（読み込めたもの）
  List<(TermDeckInfo, TermDeck?)>? _decks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TermCardsTab old) {
    super.didUpdateWidget(old);
    if (old.world.id != widget.world.id) {
      _decks = null;
      _load();
    }
  }

  Future<void> _load() async {
    final world = widget.world.id;
    final out = <(TermDeckInfo, TermDeck?)>[];
    for (final info in TermDecks.of(world)) {
      out.add((info, await loadTermDeck(info)));
    }
    if (mounted && world == widget.world.id) setState(() => _decks = out);
    // 開いた単語帳（古文など）を、アプリに入っている新しい版にそろえる
    if (await _store?.refreshOpened() ?? false) {
      if (mounted) setState(() {});
    }
  }

  VocabStore? get _store {
    final services = context.getInheritedWidgetOfExactType<RpgServices>();
    return services == null ? null : VocabStore.of(services.personalBooks);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final world = widget.world;
    final owned = Progression.isWorldPlayable(widget.progress, world);
    final store = _store;
    // 名前とパスワードで開いた、この教科の単語帳（古文単語など）
    final unlocked = [
      for (final b in store?.visibleBooks ?? const <VocabBook>[])
        if (b.isProtected && b.worldId == world.id) b,
    ];
    final books = [
      for (final (_, d) in _decks ?? const <(TermDeckInfo, TermDeck?)>[])
        if (d != null) termBook(d),
      ...unlocked,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 12, 24),
      children: [
        if (!owned)
          Card(
            color: TsuzuriColors.tint(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${world.name}を解放すると、暗記カードも使えるようになります。',
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
        if (owned && store != null && books.isNotEmpty) _today(store, books),
        if (store != null)
          for (final b in unlocked)
            Card(
              key: ValueKey('unlocked-book-${b.id}'),
              child: ListTile(
                leading: Icon(Icons.lock_open, color: TsuzuriColors.accent),
                title: Text(b.title),
                subtitle: Text('${b.cards.length}${b.unit}・パスワードで開いた単語帳'),
                trailing: FilledButton(
                  onPressed: () =>
                      _open(VocabBookScreen(store: store, book: b)),
                  child: const Text('学習する'),
                ),
              ),
            ),
        for (final info in TermDecks.of(world.id))
          _DeckCard(
            info: info,
            deck: _deckOf(info),
            loading: _decks == null,
            owned: owned,
            progress: widget.progress,
            realm: widget.realm,
            store: store,
            onOpen: _open,
          ),
      ],
    );
  }

  TermDeck? _deckOf(TermDeckInfo info) {
    for (final (i, d) in _decks ?? const <(TermDeckInfo, TermDeck?)>[]) {
      if (i.id == info.id) return d;
    }
    return null;
  }

  /// 教科全体の「今日のあなた」と、今日の最適学習・苦手克服カード
  Widget _today(VocabStore store, List<VocabBook> books) {
    final now = DateTime.now();
    final totals = {for (final s in CardStatus.values) s: 0};
    var due = 0, minutes = 0;
    VocabBook? best;
    var bestCount = 0, bestDue = -1;
    for (final b in books) {
      final p = store.progress(b.id);
      p.counts(b, now).forEach((k, v) => totals[k] = totals[k]! + v);
      final d = p.dueCount(now);
      due += d;
      minutes += (p.days[BookProgress.dayKey(now)]?.seconds ?? 0) ~/ 60;
      final plan = VocabPlanner.today(b, p, now).length;
      // 復習がたまっている暗記カードを先に
      if (plan > 0 && (d > bestDue || (d == bestDue && plan > bestCount))) {
        best = b;
        bestCount = plan;
        bestDue = d;
      }
    }
    return Card(
      color: TsuzuriColors.tint(0xFFFFF8E1),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日のあなた（${widget.world.subject}）', style: serif(17)),
            const SizedBox(height: 4),
            DotText(
              '🔴 弱点 ${totals[CardStatus.weak]}枚　🟠 あやふや ${totals[CardStatus.shaky]}枚　'
              '🟢 安定 ${totals[CardStatus.stable]}枚',
              key: const ValueKey('term-today-counts'),
            ),
            Text('今日の復習予定 $due問　今日 $minutes分'),
            if (best != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('term-today'),
                onPressed: () {
                  final b = best!;
                  _open(
                    VocabSessionScreen(
                      store: store,
                      book: b,
                      title: '${b.title} 今日の最適学習',
                      tasks: VocabPlanner.today(
                        b,
                        store.progress(b.id),
                        DateTime.now(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('今日の最適学習（${best.title}・$bestCount問）'),
              ),
            ],
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const ValueKey('term-weak-cards'),
              onPressed: () =>
                  _open(WeakCardsScreen(store: store, books: books)),
              icon: const Icon(Icons.style_outlined),
              label: const Text('苦手克服カード'),
            ),
            const SizedBox(height: 4),
            Text(
              '「学習する」を開くと、忘れかけた順の復習・用語を書く練習・熟練度・分析が使えます。',
              style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.info,
    required this.deck,
    required this.loading,
    required this.owned,
    required this.progress,
    required this.realm,
    required this.store,
    required this.onOpen,
  });

  final TermDeckInfo info;

  /// 読み込んだ暗記カード（読めなければ null）
  final TermDeck? deck;
  final bool loading;
  final bool owned;
  final RpgProgress progress;
  final StudyRealm realm;
  final VocabStore? store;
  final Future<void> Function(Widget page) onOpen;

  String _recordId(String? section) =>
      'card_${info.id}${section == null ? '' : '_$section'}';

  int? _best(String? section) {
    final id = _recordId(section);
    return progress.seaBest[realm == StudyRealm.sea ? id : skyRecordId(id)];
  }

  Future<void> _quiz(
    BuildContext context,
    TermDeck deck, {
    String? section,
  }) async {
    final qs = TermQuizBuilder().build(
      deck,
      pool: section == null ? null : deck.inSection(section),
      count: 20,
    );
    if (!context.mounted || qs.isEmpty) return;
    await startSeaBattle(
      context,
      title: '暗記カード ${deck.title}${section == null ? '' : '・$section'}',
      recordId: _recordId(section),
      questions: qs,
      worldId: info.worldId,
      normalTimeLimitSeconds: 25,
      realm: realm,
    );
  }

  /// 覚えぐあい（🟢安定・🟠あやふや・🔴弱点・復習予定）
  String? _status(TermDeck deck) {
    final s = store;
    if (s == null) return null;
    final b = termBook(deck);
    final p = s.progress(b.id);
    if (p.cards.isEmpty) return null;
    final now = DateTime.now();
    final c = p.counts(b, now);
    return '🟢${c[CardStatus.stable]} 🟠${c[CardStatus.shaky]} 🔴${c[CardStatus.weak]}'
        '　復習 ${p.dueCount(now)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('deck-${info.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Builder(
        builder: (context) {
          final deck = this.deck;
          if (deck == null) {
            return ListTile(
              title: Text(info.title),
              subtitle: Text(loading ? '読み込み中…' : '準備中'),
            );
          }
          final status = owned ? _status(deck) : null;
          return ExpansionTile(
            leading: Icon(Icons.style, color: realm.ink),
            title: Text('${deck.title}（${deck.cards.length}枚）'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: DotText(
                        status,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (store != null)
                        FilledButton.icon(
                          key: ValueKey('deck-study-${info.id}'),
                          onPressed: owned
                              ? () => onOpen(
                                  VocabBookScreen(
                                    store: store!,
                                    book: termBook(deck),
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('学習する'),
                        ),
                      FilledButton.tonalIcon(
                        key: ValueKey('deck-view-${info.id}'),
                        onPressed: owned
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TermCardBrowserScreen(deck: deck),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('カードを見る'),
                      ),
                      OutlinedButton(
                        key: ValueKey('deck-quiz-${info.id}'),
                        onPressed: owned ? () => _quiz(context, deck) : null,
                        child: const Text('全範囲から20問'),
                      ),
                      if (owned) _badge(_best(null)),
                      if (!owned) const Icon(Icons.lock_outline, size: 18),
                    ],
                  ),
                ],
              ),
            ),
            children: [
              for (final s in deck.sections)
                ListTile(
                  dense: true,
                  enabled: owned,
                  title: Text(s),
                  subtitle: Text('${deck.inSection(s).length}枚'),
                  onTap: owned ? () => _quiz(context, deck, section: s) : null,
                  trailing: owned
                      ? _badge(_best(s))
                      : const Icon(Icons.lock_outline, size: 18),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 暗記カードを1枚ずつ見る画面（用語・意味・関連語・豆知識）。
class TermCardBrowserScreen extends StatefulWidget {
  const TermCardBrowserScreen({super.key, required this.deck});

  final TermDeck deck;

  @override
  State<TermCardBrowserScreen> createState() => _TermCardBrowserScreenState();
}

class _TermCardBrowserScreenState extends State<TermCardBrowserScreen> {
  String _query = '';
  String? _section;

  /// 意味をかくして、自分で思い出す練習をする
  bool _hide = false;
  final _open = <String>{};

  List<TermCard> get _cards {
    final q = _query.trim();
    return [
      for (final c in widget.deck.cards)
        if ((_section == null || c.section == _section) &&
            (q.isEmpty ||
                c.term.contains(q) ||
                c.reading.contains(q) ||
                c.meaning.contains(q) ||
                c.related.any((r) => r.contains(q))))
          c,
    ];
  }

  void _jump(String term) {
    final hit = widget.deck.cards.where((c) => c.term == term);
    if (hit.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: SingleChildScrollView(
          child: _CardBody(card: hit.first, onRelated: null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('とじる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    return Scaffold(
      appBar: AppBar(
        title: Text('暗記カード ${widget.deck.title}'),
        actions: [
          IconButton(
            key: const ValueKey('cards-hide'),
            tooltip: _hide ? '意味を見せる' : '意味をかくす（タップで1枚ずつめくる）',
            onPressed: () => setState(() {
              _hide = !_hide;
              _open.clear();
            }),
            icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              key: const ValueKey('cards-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '用語・意味でさがす',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('すべて'),
                    selected: _section == null,
                    onSelected: (_) => setState(() => _section = null),
                  ),
                ),
                for (final s in widget.deck.sections)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: _section == s,
                      onSelected: (_) => setState(() => _section = s),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${cards.length}枚',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: cards.length,
              itemBuilder: (context, i) {
                final c = cards[i];
                final hidden = _hide && !_open.contains(c.term);
                return Card(
                  key: ValueKey('card-${c.term}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: _hide
                        ? () => setState(() {
                            _open.contains(c.term)
                                ? _open.remove(c.term)
                                : _open.add(c.term);
                          })
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: hidden
                          ? _Term(card: c, extra: '（タップで意味を見る）')
                          : _CardBody(card: c, onRelated: _jump),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  const _Term({required this.card, this.extra = ''});
  final TermCard card;
  final String extra;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: card.term, style: serif(17)),
          if (card.reading.isNotEmpty)
            TextSpan(
              text: '（${card.reading}）',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
          if (extra.isNotEmpty)
            TextSpan(
              text: '  $extra',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.card, required this.onRelated});
  final TermCard card;
  final void Function(String term)? onRelated;

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Term(card: card),
        const SizedBox(height: 6),
        Text(card.meaning, style: const TextStyle(height: 1.5)),
        if (card.related.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('関連語', style: small),
              for (final r in card.related)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(r, style: const TextStyle(fontSize: 12)),
                  onPressed: onRelated == null ? null : () => onRelated!(r),
                ),
            ],
          ),
        ],
        if (card.trivia.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TsuzuriColors.tint(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '豆知識：${card.trivia}',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// 名前とパスワードで開いた単語帳（LEAP・EEVI）から、海・空で戦う問題を作る。
/// RPG では使わない。問題はその場で作り、どこにも保存しない。
class VocabBookQuizSection extends StatelessWidget {
  const VocabBookQuizSection({
    super.key,
    required this.progress,
    this.realm = StudyRealm.sea,
  });

  final RpgProgress progress;
  final StudyRealm realm;

  Future<void> _quiz(BuildContext context, VocabBook b, bool enToJa) async {
    final qs = VocabQuizBuilder().build(b, enToJa: enToJa, count: 20);
    if (qs.isEmpty) return;
    await startSeaBattle(
      context,
      title: '${b.title}（${enToJa ? '英→日' : '日→英'}）',
      recordId: 'vocab_${b.id}_${enToJa ? 'e' : 'j'}',
      questions: qs,
      worldId: RpgCatalog.englishWorldId,
      normalTimeLimitSeconds: 15,
      realm: realm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = VocabStore.of(RpgServices.of(context).personalBooks);
    final books = [
      for (final b in store.visibleBooks)
        if (b.isProtected && !b.isTerms && b.cards.length >= 4) b,
    ];
    if (books.isEmpty) {
      return Card(
        color: TsuzuriColors.tint(0xFFFFF8E1),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'LEAP・EEVI は、定期テストの海の「単語帳練習」で名前とパスワードを入れて開くと、'
            'ここでも4択問題として出てきます（RPG には出ません）。',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
      );
    }
    String id(VocabBook b, bool e) => 'vocab_${b.id}_${e ? 'e' : 'j'}';
    int? best(VocabBook b, bool e) =>
        progress.seaBest[realm == StudyRealm.sea
            ? id(b, e)
            : skyRecordId(id(b, e))];
    return Column(
      children: [
        for (final b in books)
          Card(
            key: ValueKey('vocab-quiz-${b.id}'),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${b.title}（${b.cards.length}語）', style: serif(16)),
                  Text(
                    '1回20問（ランダム）',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final e in [true, false]) ...[
                        Expanded(
                          child: OutlinedButton(
                            key: ValueKey(
                              'vocab-quiz-${b.id}-${e ? 'e' : 'j'}',
                            ),
                            onPressed: () => _quiz(context, b, e),
                            child: Column(
                              children: [
                                Text(e ? '英→日' : '日→英'),
                                const SizedBox(height: 2),
                                _badge(best(b, e)),
                              ],
                            ),
                          ),
                        ),
                        if (e) const SizedBox(width: 8),
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
