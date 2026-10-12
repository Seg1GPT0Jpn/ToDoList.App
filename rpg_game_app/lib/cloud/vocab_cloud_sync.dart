import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';

import '../vocab/vocab_store.dart';

/// 単語帳の学習記録を、Google ログイン中はクラウド（users/{uid}/rpg_vocab）にも保存する。
///
/// - 送るのは単語の番号ごとの覚えぐあいと、日ごとの学習数だけ。単語・意味・
///   「似た単語」（英単語そのもの）は送らない
/// - 1冊を [shards] 個の文書に分けて、Firestore の1文書 1MB の上限をこえないようにする
/// - 答えるたびに送ると多すぎるので、[delay] のあいだまとめてから、変わった文書だけ送る
class VocabCloudSync {
  VocabCloudSync({
    required this.write,
    required this.readAll,
    this.delay = const Duration(seconds: 5),
  });

  /// 文書を1つ書く
  final Future<void> Function(String docId, Map<String, dynamic> data) write;

  /// 自分の rpg_vocab の文書をすべて読む（docId → 中身）
  final Future<Map<String, Map<String, dynamic>>> Function() readAll;

  final Duration delay;

  static const shards = 10;

  final _sent = <String, String>{};
  final _pending = <String, VocabStore>{};
  Timer? _timer;

  static String docId(String bookId, int shard) => '$bookId~$shard';

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
    final pending = Map.of(_pending);
    _pending.clear();
    for (final e in pending.entries) {
      for (final doc in encode(e.key, e.value.progress(e.key)).entries) {
        final text = jsonEncode(doc.value);
        if (_sent[doc.key] == text) continue;
        try {
          await write(doc.key, doc.value);
          _sent[doc.key] = text;
        } catch (err) {
          debugPrint('単語帳の記録をクラウドに保存できませんでした: $err');
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
      debugPrint('単語帳の記録をクラウドから読めませんでした: $err');
      return;
    }
    final byBook = <String, List<Map<String, dynamic>>>{};
    for (final e in all.entries) {
      final i = e.key.lastIndexOf('~');
      if (i <= 0) continue;
      byBook.putIfAbsent(e.key.substring(0, i), () => []).add(e.value);
      _sent[e.key] = jsonEncode(e.value);
    }
    for (final e in byBook.entries) {
      await store.mergeProgress(e.key, decode(e.value));
    }
    // クラウドにまだない端末の記録も送る
    for (final id in store.progressBookIds) {
      saved(store, id);
    }
  }
}
