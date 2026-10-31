import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../versus/duel_backend.dart';

/// 予想問題のランキングの1人分。
///
/// 置くのはニックネーム・点数・満点・かかった時間・未採点の欄の数だけ。問題や答えは置かない。
/// 順位に入るのは、その予想問題を1回目に解いた結果だけ（[start] がその回の開始時刻）。
class YosouRankEntry {
  const YosouRankEntry({
    required this.uid,
    required this.name,
    required this.score,
    required this.total,
    required this.spent,
    required this.start,
    this.unscored = 0,
  });

  final String uid;
  final String name;
  final int score;
  final int total;

  /// かかった時間（秒）
  final int spent;

  /// 解きはじめた時刻（ミリ秒）。1回目の結果かどうかを見分ける
  final int start;
  final int unscored;

  Map<String, Object> toMap() => {
    'name': name,
    'score': score,
    'total': total,
    'spent': spent,
    'start': start,
    'unscored': unscored,
  };

  static YosouRankEntry? fromMap(String uid, Object? m) {
    if (m is! Map) return null;
    final name = m['name'], score = m['score'], total = m['total'];
    if (name is! String || score is! num || total is! num) return null;
    return YosouRankEntry(
      uid: uid,
      name: name,
      score: score.toInt(),
      total: total.toInt(),
      spent: (m['spent'] as num? ?? 0).toInt(),
      start: (m['start'] as num? ?? 0).toInt(),
      unscored: (m['unscored'] as num? ?? 0).toInt(),
    );
  }

  /// 点数の高い順（同点は早く解いた順）
  static List<YosouRankEntry> rank(Iterable<YosouRankEntry> all) =>
      [...all]..sort((a, b) {
        final s = b.score.compareTo(a.score);
        return s != 0 ? s : a.spent.compareTo(b.spent);
      });
}

/// 予想問題のランキングの保存先
abstract class YosouRankBackend {
  String? get userId;

  /// 予想問題ごとのランキングの名前（同じ ID の予想問題を作りなおしたら [season] を変える）
  static const season = '2026-2m';
  static String boardId(String examId) => '$season-$examId';

  /// 自分の記録（まだなら null）
  Future<YosouRankEntry?> mine(String examId);

  /// 登録する（1回だけ）
  Future<void> enter(String examId, YosouRankEntry entry);

  /// 自分で採点した点を入れなおす（登録した回と同じ結果だけ。提出から3日のあいだ）
  Future<void> rescore(String examId, int score, int unscored);

  /// 点数の高い順に [limit] 人
  Future<List<YosouRankEntry>> ranking(String examId, {int limit = 100});

  /// 登録した人数と、自分より点数の高い人数
  Future<({int players, int above})> standing(String examId, int score);

  /// 予想問題を開いている人（学校のパスワードを入れた人）の名簿：uid → ランキングでの名前
  Future<Map<String, String>> members();

  /// 名簿に自分を入れる（名前を変えるときも）
  Future<void> join(String name);
}

/// テストとサーバーのない版の、端末の中だけの保存先
class MemoryYosouRankBackend extends YosouRankBackend {
  MemoryYosouRankBackend({
    this.userId = 'me',
    Map<String, Map<String, YosouRankEntry>>? boards,
  }) : boards = boards ?? {};

  @override
  final String? userId;

  /// 予想問題の ID → uid → 記録
  final Map<String, Map<String, YosouRankEntry>> boards;

  String _uid() =>
      userId ?? (throw const DuelException(YosouRankText.needLogin));

  @override
  Future<YosouRankEntry?> mine(String examId) async => boards[examId]?[_uid()];

  @override
  Future<void> enter(String examId, YosouRankEntry entry) async {
    final uid = _uid();
    final b = boards.putIfAbsent(examId, () => {});
    if (b.containsKey(uid)) {
      throw const DuelException('もう登録ずみです');
    }
    b[uid] = entry;
  }

  @override
  Future<void> rescore(String examId, int score, int unscored) async {
    final uid = _uid();
    final e = boards[examId]?[uid];
    if (e == null) return;
    boards[examId]![uid] = YosouRankEntry(
      uid: uid,
      name: e.name,
      score: score,
      total: e.total,
      spent: e.spent,
      start: e.start,
      unscored: unscored,
    );
  }

  @override
  Future<List<YosouRankEntry>> ranking(
    String examId, {
    int limit = 100,
  }) async =>
      YosouRankEntry.rank(boards[examId]?.values ?? const [])
          .take(limit)
          .toList();

  /// 名簿：uid → 名前
  final Map<String, String> roster = {};

  @override
  Future<Map<String, String>> members() async => {...roster};

  @override
  Future<void> join(String name) async => roster[_uid()] = name;

  @override
  Future<({int players, int above})> standing(String examId, int score) async {
    final all = boards[examId]?.values ?? const <YosouRankEntry>[];
    return (
      players: all.length,
      above: all.where((e) => e.score > score).length,
    );
  }
}

class YosouRankText {
  const YosouRankText._();

  static const needLogin = 'ランキングは、Google でログインすると参加できます';
  static const rule =
      '予想問題を開いている人は全員ランキングに入り、まだ解いていない人は「未回答」になります。'
      '順位に入るのは、1回目に解いた結果だけです（解き直した回は入りません）。'
      '自分で採点する欄の点は、提出から3日のあいだ直せます。'
      'みんなに見えるのはニックネームと点数・かかった時間だけです。';

  /// 名前がまだないときの名前
  static const noName = 'ニックネーム未設定';
}

/// 結果の画面に出す、ランキングへの登録と自分の順位
class YosouRankCard extends StatefulWidget {
  const YosouRankCard({
    super.key,
    required this.exam,
    required this.attempt,
    required this.score,
    required this.total,
    required this.unscored,
    required this.spent,
    required this.firstStart,
    this.backend,
  });

  final YosouExam exam;
  final MockAttempt attempt;
  final int score;
  final int total;
  final int unscored;
  final Duration spent;

  /// この予想問題を1回目に解いた回の開始時刻（これと同じ回だけ登録できる）
  final DateTime firstStart;

  /// テスト用（ふだんは RpgServices.yosouRanking）
  final YosouRankBackend? backend;

  @override
  State<YosouRankCard> createState() => _YosouRankCardState();
}

class _YosouRankCardState extends State<YosouRankCard> {
  final _name = TextEditingController();
  Future<(YosouRankEntry?, ({int players, int above})?)>? _load;
  String? _error;

  YosouRankBackend? get _backend =>
      widget.backend ?? RpgServices.of(context).yosouRanking;

  String get _board => YosouRankBackend.boardId(widget.exam.id);

  /// この結果が、1回目に解いた回か
  bool get _first =>
      widget.attempt.startedAt.millisecondsSinceEpoch ==
      widget.firstStart.millisecondsSinceEpoch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_load != null) return;
    _name.text = RpgServices.of(context).classroomStore.nickname;
    _reload(enter: true);
  }

  @override
  void didUpdateWidget(YosouRankCard old) {
    super.didUpdateWidget(old);
    // 自分で採点して点が変わったら、ランキングの点も入れなおす
    if (old.score != widget.score || old.unscored != widget.unscored) {
      _rescore();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// 自分の順位を読む。[enter] なら、1回目の結果をまだ登録していなければ登録する
  void _reload({bool enter = false}) {
    final b = _backend;
    if (b == null || b.userId == null) return;
    final name = Classroom.cleanName(
      _name.text,
      fallback: YosouRankText.noName,
    );
    _load = () async {
      var m = await b.mine(_board);
      if (m == null && enter && _first) {
        try {
          await b.enter(_board, _entry(b.userId!, name));
          // 名簿の名前があれば、そちらを使う
          final roster = await b.members();
          if (!roster.containsKey(b.userId)) await b.join(name);
        } on DuelException {
          // もう登録ずみなど
        }
        m = await b.mine(_board);
      }
      return (m, m == null ? null : await b.standing(_board, m.score));
    }();
  }

  YosouRankEntry _entry(String uid, String name) => YosouRankEntry(
    uid: uid,
    name: name,
    score: widget.score,
    total: widget.total,
    spent: widget.spent.inSeconds,
    start: widget.attempt.startedAt.millisecondsSinceEpoch,
    unscored: widget.unscored,
  );

  Future<void> _rescore() async {
    final b = _backend;
    if (b == null || b.userId == null || !_first) return;
    try {
      final m = await b.mine(_board);
      if (m == null ||
          m.start != widget.attempt.startedAt.millisecondsSinceEpoch) {
        return;
      }
      await b.rescore(_board, widget.score, widget.unscored);
      if (mounted) setState(_reload);
    } on DuelException {
      // 3日たったなど。表示は前の点のまま
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _backend;
    final small = TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft);
    Widget body;
    if (b == null) {
      body = const Text('この版では、ランキングは使えません');
    } else if (b.userId == null) {
      body = const Text(YosouRankText.needLogin);
    } else {
      body = FutureBuilder(
        future: _load,
        builder: (context, snap) {
          if (snap.hasError) return Text('読みこめませんでした：${snap.error}');
          if (snap.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
          }
          final (mine, st) = snap.data ?? (null, null);
          if (mine != null && st != null) {
            return Text(
              'あなたは ${st.above + 1}位 / ${st.players}人'
              '（${mine.score}/${mine.total} 点）',
              key: const ValueKey('yosou-rank-mine'),
              style: serif(16),
            );
          }
          if (!_first) {
            return const Text(
              'ランキングに入るのは1回目の結果だけです（この回は解き直しなので入りません）',
              key: ValueKey('yosou-rank-retry'),
            );
          }
          return const Text('ランキングに登録できませんでした。あとで開きなおしてください');
        },
      );
    }
    return Card(
      key: const ValueKey('yosou-rank-card'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ランキング', style: serif(16)),
            const SizedBox(height: 6),
            body,
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 4),
            Text(YosouRankText.rule, style: small),
            if (b != null && b.userId != null)
              TextButton(
                key: const ValueKey('yosou-rank-open'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        YosouRankingScreen(exam: widget.exam, backend: b),
                  ),
                ),
                child: const Text('ランキングを見る'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 予想問題のランキング（上位100人と、自分の順位）
class YosouRankingScreen extends StatefulWidget {
  const YosouRankingScreen({super.key, required this.exam, this.backend});

  final YosouExam exam;
  final YosouRankBackend? backend;

  @override
  State<YosouRankingScreen> createState() => _YosouRankingScreenState();
}

class _YosouRankingScreenState extends State<YosouRankingScreen> {
  Future<
    (
      List<YosouRankEntry>,
      YosouRankEntry?,
      ({int players, int above})?,
      Map<String, String>,
    )
  >?
  _load;

  YosouRankBackend? get _backend =>
      widget.backend ?? RpgServices.of(context).yosouRanking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _fetch();
  }

  Future<
    (
      List<YosouRankEntry>,
      YosouRankEntry?,
      ({int players, int above})?,
      Map<String, String>,
    )
  >
  _fetch() async {
    final b = _backend;
    if (b == null || b.userId == null) {
      return (const <YosouRankEntry>[], null, null, const <String, String>{});
    }
    final id = YosouRankBackend.boardId(widget.exam.id);
    final rows = await b.ranking(id, limit: 500);
    final mine = await b.mine(id);
    final st = mine == null ? null : await b.standing(id, mine.score);
    return (rows, mine, st, await b.members());
  }

  @override
  Widget build(BuildContext context) {
    final b = _backend;
    final me = b?.userId;
    return Scaffold(
      appBar: AppBar(
        title: Text('ランキング', style: serif(17)),
        actions: [
          IconButton(
            tooltip: '最新にする',
            onPressed: () => setState(() => _load = _fetch()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: NotebookPaper(
        child: b == null || me == null
            ? const Padding(
                padding: EdgeInsets.fromLTRB(40, 16, 16, 24),
                child: Text(YosouRankText.needLogin),
              )
            : FutureBuilder(
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
                  final (rows, mine, st, roster) = data;
                  // 名前は名簿のもの（変えていればそちら）
                  String nameOf(String uid, String fallback) =>
                      roster[uid] ?? fallback;
                  final answered = {for (final e in rows) e.uid};
                  final waiting = [
                    for (final e in roster.entries)
                      if (!answered.contains(e.key)) e,
                  ]..sort((a, b) => a.value.compareTo(b.value));
                  int rankOf(YosouRankEntry e) =>
                      1 + rows.where((o) => o.score > e.score).length;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
                    children: [
                      Text(widget.exam.title, style: serif(18)),
                      const SizedBox(height: 4),
                      Text(
                        YosouRankText.rule,
                        style: TextStyle(
                          fontSize: 12,
                          color: TsuzuriColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (mine != null && st != null)
                        Text(
                          'あなたは ${st.above + 1}位 / ${st.players}人'
                          '（${mine.score}/${mine.total} 点）',
                          key: const ValueKey('yosou-ranking-mine'),
                          style: serif(17),
                        ),
                      Text(
                        '回答 ${rows.length}人・未回答 ${waiting.length}人',
                        key: const ValueKey('yosou-ranking-count'),
                      ),
                      const SizedBox(height: 8),
                      if (rows.isEmpty)
                        const Text('まだだれも解いていません')
                      else
                        for (final (i, e) in rows.indexed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${rankOf(e)}位　${nameOf(e.uid, e.name)}${e.uid == me ? '（あなた）' : ''}　'
                              '${e.score}/${e.total} 点'
                              '　${e.spent ~/ 60}分${e.unscored > 0 ? '　未採点${e.unscored}' : ''}',
                              key: ValueKey('yosou-ranking-row-$i'),
                              style: TextStyle(
                                fontWeight: e.uid == me
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                      if (waiting.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('未回答', style: serif(15)),
                        for (final w in waiting)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '−　${w.value}${w.key == me ? '（あなた）' : ''}　未回答',
                              key: ValueKey('yosou-ranking-waiting-${w.key}'),
                              style: TextStyle(color: TsuzuriColors.inkSoft),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// 予想問題の一覧に出す、ランキングでの名前（開いたら名簿に入る）
class YosouMemberCard extends StatefulWidget {
  const YosouMemberCard({super.key, this.backend});

  /// テスト用（ふだんは RpgServices.yosouRanking）
  final YosouRankBackend? backend;

  @override
  State<YosouMemberCard> createState() => _YosouMemberCardState();
}

class _YosouMemberCardState extends State<YosouMemberCard> {
  Future<String?>? _load;

  YosouRankBackend? get _backend =>
      widget.backend ?? RpgServices.of(context).yosouRanking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load ??= _joined();
  }

  /// 名簿の自分の名前（まだ入っていなければ、ニックネームで入る）
  Future<String?> _joined() async {
    final b = _backend;
    if (b == null || b.userId == null) return null;
    final nick = RpgServices.of(context).classroomStore.nickname;
    final roster = await b.members();
    final mine = roster[b.userId];
    if (mine != null) return mine;
    final name = Classroom.cleanName(nick, fallback: YosouRankText.noName);
    await b.join(name);
    return name;
  }

  Future<void> _rename(String now) async {
    final c = TextEditingController(
      text: now == YosouRankText.noName ? '' : now,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('ランキングでの名前'),
        content: TextField(
          key: const ValueKey('yosou-member-name'),
          controller: c,
          maxLength: Classroom.maxName,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('yosou-member-save'),
            onPressed: () => Navigator.pop(d, c.text),
            child: const Text('決める'),
          ),
        ],
      ),
    );
    // 閉じるアニメーションのあいだも入力欄が使われるので、ここでは捨てない
    if (name == null || !mounted) return;
    final clean = Classroom.cleanName(name, fallback: YosouRankText.noName);
    final services = RpgServices.of(context);
    try {
      await _backend!.join(clean);
      await services.classroomStore.setNickname(clean);
    } on DuelException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    if (mounted) {
      setState(() {
        _load = _joined();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _backend;
    if (b == null) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('yosou-member-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: b.userId == null
            ? const Text(YosouRankText.needLogin)
            : FutureBuilder<String?>(
                future: _load,
                builder: (context, snap) {
                  final name = snap.data;
                  return Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snap.hasError
                              ? 'ランキングの名簿を読めませんでした'
                              : name == null
                              ? 'ランキングの名簿を読んでいます…'
                              : 'ランキングでの名前：$name',
                          key: const ValueKey('yosou-member-label'),
                        ),
                      ),
                      if (name != null)
                        TextButton(
                          key: const ValueKey('yosou-member-rename'),
                          onPressed: () => _rename(name),
                          child: const Text('変える'),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
