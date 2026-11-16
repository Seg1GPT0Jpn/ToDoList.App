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
  }) {
    final rnd = random ?? Random();
    final mine = _info(card);
    final scored = <(VocabCard, double)>[];
    for (final o in pool) {
      if (identical(o, card) || o.id == card.id) continue;
      if (o.meaning == card.meaning || o.term == card.term) continue;
      final other = _info(o);
      if (_overlaps(mine.senses, other.senses)) continue;
      // 少しだけゆらぎを入れて、毎回同じ3つにならないようにする
      scored.add((o, _score(card, mine, o, other) + rnd.nextDouble() * 0.35));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored) s.$1];
  }

  /// [a] と [b] は同じ意味をもつか（どちらかを正解にすると、もう一方も正解になってしまう）
  static bool sameMeaning(VocabCard a, VocabCard b) =>
      _overlaps(_info(a).senses, _info(b).senses);

  static double _score(VocabCard a, _Info ia, VocabCard b, _Info ib) {
    var s = 0.0;
    if (ia.pos.isNotEmpty && ia.pos == ib.pos) s += 2;
    if (a.group.isNotEmpty && a.group == b.group) s += 1;
    final na = a.number, nb = b.number;
    if (na != null && nb != null) {
      s += max(0.0, 1.6 - (na - nb).abs() / 8);
    }
    if (ia.kanji.isNotEmpty && ib.kanji.isNotEmpty) {
      final common = ia.kanji.intersection(ib.kanji).length;
      final all = ia.kanji.union(ib.kanji).length;
      s += 2.2 * common / all;
    }
    return s;
  }

  static bool _overlaps(Set<String> a, Set<String> b) {
    for (final x in a) {
      for (final y in b) {
        if (x == y || x.contains(y) || y.contains(x)) return true;
      }
    }
    return false;
  }

  static final _cache = Expando<_Info>();

  static _Info _info(VocabCard c) => _cache[c] ??= _Info.of(c);
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

  static _Info of(VocabCard c) {
    final raw = partOfSpeechOf(c.meaning);
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
    final body = c.meaning.replaceAll(_tag, '');
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
