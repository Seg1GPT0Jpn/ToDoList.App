import 'dart:math';

import 'meaning_text.dart';
import 'vocab_book.dart';

/// 4択のまちがいの選択肢を「意味の近い単語」から選ぶ。
///
/// 次の3つで近さを測る：
/// - 品詞が同じ（他動詞・自動詞は同じ「動詞」として扱う）
/// - 単語帳の番号が近い（LEAP などは、意味の近い語が近い番号にまとまっている）
/// - 意味に同じ漢字を使っている（「減少する」と「減らす」など）
///
/// 正解と同じ意味をもつ語（「～を主張する」の assert と advocate など）は、
/// 答えが2つになってしまうので、まちがいの選択肢にしない。
abstract final class SimilarChoices {
  /// [card] のまちがいの選択肢の候補を、まぎらわしい順に並べる。
  /// 正解と意味が重なる語・[card] 自身は入れない。
  static List<VocabCard> rank(
    VocabCard card,
    Iterable<VocabCard> pool, {
    Random? random,
  }) =>
      rankBy(
        card,
        pool,
        term: (c) => c.term,
        meaning: (c) => c.meaning,
        number: (c) => c.number,
        group: (c) => c.group,
        random: random,
      );

  /// [rank] の、どんな単語の形にも使える版。
  /// [number] は、番号が近いほど意味も近い単語帳（LEAP など）でだけ渡す
  /// （アルファベット順の単語帳では、番号の近さは意味の近さにならない）。
  static List<T> rankBy<T extends Object>(
    T item,
    Iterable<T> pool, {
    required String Function(T) term,
    required String Function(T) meaning,
    int? Function(T)? number,
    String Function(T)? group,
    Random? random,
  }) {
    final rnd = random ?? Random();
    final mine = _info(item, meaning(item));
    final scored = <(T, double)>[];
    for (final o in pool) {
      if (identical(o, item)) continue;
      if (meaning(o) == meaning(item) || term(o) == term(item)) continue;
      final other = _info(o, meaning(o));
      if (_overlaps(mine.senses, other.senses)) continue;
      var s = 0.0;
      if (mine.pos.isNotEmpty && mine.pos == other.pos) s += 2;
      if (group != null) {
        final ga = group(item);
        if (ga.isNotEmpty && ga == group(o)) s += 1;
      }
      final na = number?.call(item), nb = number?.call(o);
      if (na != null && nb != null) {
        s += max(0.0, 1.6 - (na - nb).abs() / 8);
      }
      if (mine.kanji.isNotEmpty && other.kanji.isNotEmpty) {
        final common = mine.kanji.intersection(other.kanji).length;
        final all = mine.kanji.union(other.kanji).length;
        s += 2.2 * common / all;
      }
      // 少しだけゆらぎを入れて、毎回同じ3つにならないようにする
      scored.add((o, s + rnd.nextDouble() * 0.35));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final x in scored) x.$1];
  }

  /// [a] と [b] は同じ意味をもつか（どちらかを正解にすると、もう一方も正解になってしまう）
  static bool sameMeaning(VocabCard a, VocabCard b) =>
      _overlaps(_info(a, a.meaning).senses, _info(b, b.meaning).senses);

  static bool _overlaps(Set<String> a, Set<String> b) {
    for (final x in a) {
      for (final y in b) {
        if (x == y || x.contains(y) || y.contains(x)) return true;
      }
    }
    return false;
  }

  static final _cache = Expando<_Info>();

  static _Info _info(Object c, String meaning) =>
      _cache[c] ??= _Info.of(meaning);
}

class _Info {
  const _Info(this.pos, this.senses, this.kanji);

  /// 品詞（名・動・形・副・熟 など。わからなければ空）
  final String pos;

  /// 意味を語義ごとに分けたもの（「～を」などの助詞・かっこ書きを除く）
  final Set<String> senses;

  /// 意味に使われている漢字
  final Set<String> kanji;

  static final _tag = RegExp(r'\[[^\]]*\]');
  static final _split = RegExp(r'[①②③④⑤⑥⑦⑧⑨，,、;；／/]');
  static final _paren = RegExp(r'（[^）]*）|\([^)]*\)|［[^］]*］');
  static final _lead = RegExp(r'^(を|に|が|の|と|で|から|より|は)+');
  static final _kanji = RegExp(r'[一-鿿]');

  static _Info of(String meaning) {
    final raw = partOfSpeechOf(meaning);
    final pos = raw.contains('名')
        ? '名'
        : raw.contains('形')
            ? '形'
            : raw.contains('副')
                ? '副'
                : raw.contains('熟')
                    ? '熟'
                    : (raw.contains('他') ||
                            raw.contains('自') ||
                            raw.contains('動'))
                        ? '動'
                        : raw;
    final body = meaning.replaceAll(_tag, '');
    final senses = <String>{};
    for (final part in body.split(_split)) {
      var p = part.replaceAll(_paren, '').trim();
      p = p.replaceAll(RegExp(r'^[\s　～~…]+|[\s　～~…]+$'), '');
      p = p.replaceFirst(_lead, '').trim();
      if (p.runes.length >= 2) senses.add(p);
    }
    final kanji = {for (final m in _kanji.allMatches(body)) m.group(0)!};
    return _Info(pos, senses, kanji);
  }
}
