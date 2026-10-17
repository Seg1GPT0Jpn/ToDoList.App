/// 単語の意味の文字列（「[動] ①～と主張する ②… [名] ③主張」など）を読む。
library;

/// 先頭の品詞（[名] [動] など。全角の［］も）
final _leadPos = RegExp(r'^\s*[\[［]([^\]］]+)[\]］]');

/// 2つ目以降の品詞。[接続詞で] [the ～] のような使い方の注記では切らない
final _posTag = RegExp(
  r'[\[［]\s*(名|動|他|自|形|副|前|接|代|助|間|冠|熟|句|助動|自他|他自|'
  r'名詞|動詞|他動|自動|形容詞|副詞|前置詞|接続詞|代名詞|助動詞|間投詞|熟語|成句)'
  r'\s*[\]］]',
);

final _senseMark = RegExp('[①②③④⑤⑥⑦⑧⑨⑩]');
final _japanese = RegExp(r'[぀-ヿ一-鿿]');
final _parens = RegExp(r'[（(][^）)]*[）)]');

/// 品詞（なければ空）
String partOfSpeechOf(String meaning) =>
    _leadPos.firstMatch(meaning)?.group(1)?.trim() ?? '';

/// 4択や答え合わせに出す短い意味（最初の品詞・最初の語義だけ）。
///
/// 切った結果に日本語の訳が残らない（「（as）」だけ など）ときは、切らずに全部を返す。
String shortMeaningOf(String meaning) {
  final all = meaning.replaceFirst(_leadPos, '').trim();
  var m = all;
  final next = _posTag.firstMatch(m);
  if (next != null && next.start > 0) m = m.substring(0, next.start);
  final marks = _senseMark.allMatches(m).toList();
  if (marks.length >= 2) m = m.substring(0, marks[1].start);
  m = _tidy(m);
  if (!_japanese.hasMatch(m.replaceAll(_parens, ''))) m = _tidy(all);
  return m.isEmpty ? meaning.trim() : m;
}

String _tidy(String s) =>
    s.replaceAll(_senseMark, '').replaceAll(RegExp(r'\s+'), ' ').trim();
