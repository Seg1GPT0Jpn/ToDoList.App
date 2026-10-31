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

/// 「(人)を[名]の状態に」のように、[名] のすぐ後に助詞が続くときは品詞ではない
final _particle = RegExp('[のをにがとでへはも]');
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
  // かっこの中（「時間(①時刻 ②期間)」の ② など）では切らない。
  // 「(人)を[名]の状態に」のように文の中にある [名] も品詞ではないので切らない
  final next = _posTag.allMatches(m).where(
        (t) =>
            t.start > 0 &&
            _depthAt(m, t.start) == 0 &&
            (t.end == m.length || !_particle.hasMatch(m[t.end])),
      );
  if (next.isNotEmpty) m = m.substring(0, next.first.start);
  final marks = [
    for (final k in _senseMark.allMatches(m))
      if (_depthAt(m, k.start) == 0) k,
  ];
  if (marks.length >= 2) m = m.substring(0, marks[1].start);
  m = _tidy(m);
  if (!_japanese.hasMatch(m.replaceAll(_parens, '')) || !_balanced(m)) {
    m = _tidy(all);
  }
  return m.isEmpty ? meaning.trim() : m;
}

/// [i] の位置が、いくつのかっこの中にあるか
int _depthAt(String s, int i) {
  var d = 0;
  for (var k = 0; k < i; k++) {
    final c = s[k];
    if (c == '(' || c == '（') d++;
    if ((c == ')' || c == '）') && d > 0) d--;
  }
  return d;
}

/// かっこが閉じているか
bool _balanced(String s) => _depthAt(s, s.length) == 0;

String _tidy(String s) =>
    s.replaceAll(_senseMark, '').replaceAll(RegExp(r'\s+'), ' ').trim();

final _hasText = RegExp(r'[A-Za-z0-9぀-ヿ一-鿿]');

/// 4択の選択肢に出してよい文字か（「（」や「～」だけのような、記号しかないものは出さない）
bool usableChoiceText(String s) => _hasText.hasMatch(s);
