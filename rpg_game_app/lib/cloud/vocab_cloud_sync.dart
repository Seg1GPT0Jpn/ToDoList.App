import 'dart:async';
import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';

import '../vocab/vocab_store.dart';
import 'sync_status.dart';

/// 単語帳の学習記録を、Google ログイン中はクラウド（users/{uid}/rpg_vocab）にも保存する。
///
/// - 送るのは単語の番号ごとの覚えぐあいと、日ごとの学習数だけ。単語・意味・
///   「似た単語」（英単語そのもの）は送らない
/// - 1冊を [shards] 個の文書に分けて、Firestore の1文書 1MB の上限をこえないようにする
/// - 答えるたびに送ると多すぎるので、[delay] のあいだまとめてから、変わった文書だけ送る
///   （アプリを閉じる・ほかのアプリに切りかえるときは、すぐ送る：[flush]）
/// - 自分で作った単語帳は、中身も `book@<単語帳ID>` の文書に送る（新しく書きかえたほうを使う）。
///   アプリに入っている単語帳・名前とパスワードで開く単語帳（LEAP など）の中身は送らない
/// - ほかのアプリ・端末が送った記録は、クラウドの変化を見張って取りこむ（[apply]）
class VocabCloudSync {
  VocabCloudSync({
    required this.write,
    required this.readAll,
    this.delay = const Duration(seconds: 2),
  });

  /// 文書を1つ書く
  final Future<void> Function(String docId, Map<String, dynamic> data) write;

  /// 自分の rpg_vocab の文書をすべて読む（docId → 中身）
  final Future<Map<String, Map<String, dynamic>>> Function() readAll;

  final Duration delay;

  static const shards = 10;

  final _sent = <String, String>{};
  final _pending = <String, VocabStore>{};
  final _pendingBooks = <String>{};
  VocabStore? _store;
  Timer? _timer;

  /// 自分で作った単語帳の中身（最後に送った・受けとったもの）。単語帳 ID → JSON
  final _known = <String, String>{};
  var _knownReady = false;

  static String docId(String bookId, int shard) => '$bookId~$shard';

  /// 単語帳の中身の文書
  static const bookPrefix = 'book@';

  /// 1文書 1MB の上限に近い大きな単語帳は送らない
  static const maxBookBytes = 900000;

  Map<String, String> _customBooks(VocabStore store) => {
    for (final b in store.books)
      if (b.kind == VocabBookKind.custom) b.id: jsonEncode(b.toJson()),
  };

  /// いま端末にある単語帳を「知っている中身」にする（起動したときに1回）
  void initBooks(VocabStore store) {
    if (_knownReady) return;
    _knownReady = true;
    _store = store;
    _known.addAll(_customBooks(store));
  }

  /// 単語帳（中身）を保存したとき：変わった単語帳・消した単語帳を、あとで送る
  void booksSaved(VocabStore store) {
    initBooks(store);
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = _customBooks(store);
    for (final e in current.entries) {
      if (_known[e.key] == e.value) continue;
      unawaited(store.setBookTime(e.key, now));
      _pendingBooks.add(e.key);
    }
    for (final id in _known.keys) {
      if (current.containsKey(id)) continue;
      unawaited(store.setBookTime(id, now));
      _pendingBooks.add(id);
    }
    _known
      ..clear()
      ..addAll(current);
    _store = store;
    _timer ??= Timer(delay, () => unawaited(flush()));
  }

  static int shardOf(String cardId) =>
      cardId.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff) % shards;

  /// 学習記録を、クラウドに置く文書に分ける
  static Map<String, Map<String, dynamic>> encode(
    String bookId,
    BookProgress p,
  ) {
    final out = {
      for (var i = 0; i < shards; i++)
        docId(bookId, i): <String, dynamic>{'cards': <String, dynamic>{}},
    };
    for (final e in p.cards.entries) {
      // 似た単語（英単語そのもの）は送らない
      final j = e.value.toJson()..remove('c');
      (out[docId(bookId, shardOf(e.key))]!['cards'] as Map)[e.key] = j;
    }
    out[docId(bookId, 0)]!['days'] = {
      for (final e in p.days.entries) e.key: e.value.toJson(),
    };
    return out;
  }

  /// クラウドの文書から学習記録をもどす
  static BookProgress decode(Iterable<Map<String, dynamic>> docs) {
    final cards = <String, dynamic>{};
    final days = <String, dynamic>{};
    for (final d in docs) {
      // 端末によって入れ子の Map の型がちがうので、JSON を通してそろえる
      final j = jsonDecode(jsonEncode(d)) as Map<String, dynamic>;
      cards.addAll(j['cards'] as Map<String, dynamic>? ?? {});
      days.addAll(j['days'] as Map<String, dynamic>? ?? {});
    }
    return BookProgress.fromJson({'cards': cards, 'days': days});
  }

  /// 学習記録を保存したとき（まとめて、あとで送る）
  void saved(VocabStore store, String bookId) {
    _pending[bookId] = store;
    _timer ??= Timer(delay, () => unawaited(flush()));
  }

  /// たまっている分を今すぐ送る
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final books = Set.of(_pendingBooks);
    _pendingBooks.clear();
    final store = _store;
    if (store != null) {
      for (final id in books) {
        final b = store.book(id);
        final at = store.bookTime(id);
        final data = b == null || b.kind != VocabBookKind.custom
            ? <String, dynamic>{'deleted': true, 'at': at}
            : <String, dynamic>{'book': b.toJson(), 'at': at};
        final text = jsonEncode(data);
        if (text.length > maxBookBytes) continue;
        if (_sent['$bookPrefix$id'] == text) continue;
        try {
          await write('$bookPrefix$id', data);
          _sent['$bookPrefix$id'] = text;
          syncSent();
        } catch (err) {
          syncError('単語帳の保存', err);
        }
      }
    }
    final pending = Map.of(_pending);
    _pending.clear();
    for (final e in pending.entries) {
      for (final doc in encode(e.key, e.value.progress(e.key)).entries) {
        final text = jsonEncode(doc.value);
        if (_sent[doc.key] == text) continue;
        try {
          await write(doc.key, doc.value);
          _sent[doc.key] = text;
          syncSent();
        } catch (err) {
          syncError('単語帳の記録の保存', err);
        }
      }
    }
  }

  /// ログインした直後：クラウドの記録を端末の記録とまぜる
  Future<void> pull(VocabStore store) async {
    final Map<String, Map<String, dynamic>> all;
    try {
      all = await readAll();
    } catch (err) {
      syncError('単語帳の記録の読みこみ', err);
      return;
    }
    await apply(store, all, first: true);
    // クラウドにまだない端末の記録・単語帳も送る
    for (final id in store.progressBookIds) {
      saved(store, id);
    }
    for (final id in _customBooks(store).keys) {
      if (!all.containsKey('$bookPrefix$id')) _pendingBooks.add(id);
    }
    if (_pendingBooks.isNotEmpty) {
      _timer ??= Timer(delay, () => unawaited(flush()));
    }
  }

  /// クラウドの文書（docId → 中身）を端末にまぜる。
  /// [changed] があれば、その文書がふくまれる単語帳だけを見る（クラウドの変化を受けとったとき）。
  /// [first] はログイン直後：まだ一度も同期していない端末の単語帳は、消さずに単語を合わせる
  Future<void> apply(
    VocabStore store,
    Map<String, Map<String, dynamic>> all, {
    Set<String>? changed,
    bool first = false,
  }) async {
    initBooks(store);
    // 単語帳の中身（新しく書きかえたほうを使う）
    for (final e in all.entries) {
      if (!e.key.startsWith(bookPrefix)) continue;
      if (changed != null && !changed.contains(e.key)) continue;
      _sent[e.key] = jsonEncode(e.value);
      final id = e.key.substring(bookPrefix.length);
      final at = (e.value['at'] as num?)?.toInt() ?? 0;
      final mine = store.bookTime(id);
      final local = store.book(id);
      final raw = e.value['book'];
      final remote = raw is Map
          ? VocabBook.fromJson(
              jsonDecode(jsonEncode(raw)) as Map<String, dynamic>,
            )
          : null;
      if (mine == 0 && first && local != null && remote != null) {
        // 両方にあって、この端末ではまだ同期したことがない：単語を合わせる
        local.merge(remote.cards);
        await store.saveBooks();
        continue;
      }
      if (at <= mine) continue;
      if (local != null && local.kind != VocabBookKind.custom) continue;
      await store.putBookFromCloud(id, remote);
      await store.setBookTime(id, at);
      if (remote == null) {
        _known.remove(id);
      } else {
        _known[id] = jsonEncode(remote.toJson());
      }
    }
    // 覚えぐあい（単語ごと・日ごとに、たくさん答えているほう）
    final byBook = <String, List<Map<String, dynamic>>>{};
    final touched = <String>{};
    for (final e in all.entries) {
      final i = e.key.lastIndexOf('~');
      if (e.key.startsWith(bookPrefix) || i <= 0) continue;
      final bookId = e.key.substring(0, i);
      byBook.putIfAbsent(bookId, () => []).add(e.value);
      if (changed == null || changed.contains(e.key)) touched.add(bookId);
    }
    for (final id in touched) {
      // クラウドにある中身を、この端末で作るのと同じ形に直して覚えておく
      // （数字の書き方のちがいで、同じ中身を何度も送りなおさないように）
      final cloud = decode(byBook[id]!);
      for (final doc in encode(id, cloud).entries) {
        if (all.containsKey(doc.key)) _sent[doc.key] = jsonEncode(doc.value);
      }
      await store.mergeProgress(id, cloud);
      // 端末のほうが進んでいれば、その分を送りかえす（同じなら送らない）
      saved(store, id);
    }
  }
}
