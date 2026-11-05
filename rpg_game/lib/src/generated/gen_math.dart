import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 数学の問題の作り方。答えはすべて計算で出す。

String _p(List<int> c) => Fmt.poly(c);
String _n(int v) => Fmt.n(v);

/// かけ算の中の負の数はかっこに入れる
String _pn(int v) => v < 0 ? '(${Fmt.n(v)})' : '$v';

/// 「x=3」「x=−1/2」
String _xeq(Rat v) => 'x=$v';

// ---------------- 数学Ⅰ：式 ----------------

/// (ax+b)(cx+d) の展開
GenQ? _expand(Random r) {
  final a = r.pick([1, 1, 1, 2, 3]), c = r.pick([1, 1, 2, 3]);
  final b = r.nonZero(-7, 7), d = r.nonZero(-7, 7);
  final ans = _p([a * c, a * d + b * c, b * d]);
  return GenQ(
    prompt: '(${_p([a, b])})(${_p([c, d])}) を展開すると？',
    answer: ans,
    wrong: [
      _p([a * c, a * d - b * c, b * d]),
      _p([a * c, a * d + b * c, -b * d]),
      _p([a * c, b + d, b * d]),
      _p([a * c, -(a * d + b * c), b * d]),
      _p([a * c, a * d + b * c, b + d]),
    ],
    explanation:
        '(${_p([a, b])})(${_p([c, d])})＝${_p([a * c, a * d + b * c, b * d])}',
  );
}

/// (x+a)³ の展開
GenQ? _cube(Random r) {
  final a = r.nonZero(-4, 4);
  final ans = _p([1, 3 * a, 3 * a * a, a * a * a]);
  return GenQ(
    prompt: '(${Fmt.linear(a)})³ を展開すると？',
    answer: ans,
    wrong: [
      _p([1, a, a * a, a * a * a]),
      _p([1, 3 * a, 3 * a * a, 3 * a]),
      _p([1, 0, 0, a * a * a]),
      _p([1, -3 * a, 3 * a * a, a * a * a]),
    ],
    explanation: '(x+a)³＝x³+3ax²+3a²x+a³ に a＝${_n(a)} を入れる。',
  );
}

/// x²+(p+q)x+pq の因数分解
GenQ? _factorMonic(Random r) {
  var p = r.nonZero(-9, 9), q = r.nonZero(-9, 9);
  if (p == q || p == -q) return null;
  if (p > q) (p, q) = (q, p);
  String f(int a, int b) => '(${Fmt.linear(a)})(${Fmt.linear(b)})';
  return GenQ(
    prompt: '${_p([1, p + q, p * q])} を因数分解すると？',
    answer: f(p, q),
    wrong: [f(-p, -q), f(p, -q), f(-p, q), f(p + q, 1), f(p * q, 1)],
    explanation:
        '足して ${_n(p + q)}、かけて ${_n(p * q)} になる2数は ${_n(p)} と ${_n(q)}。',
  );
}

/// a²x²−b² の因数分解（平方の差）
GenQ? _factorSquares(Random r) {
  final a = r.range(1, 4), b = r.range(1, 9);
  if (gcd(a, b) != 1) return null;
  final ax = a == 1 ? 'x' : '${a}x';
  return GenQ(
    prompt: '${_p([a * a, 0, -b * b])} を因数分解すると？',
    answer: '($ax+$b)($ax−$b)',
    wrong: [
      '($ax−$b)²',
      '($ax+$b)²',
      '($ax+${b * b})($ax−1)',
      '(${ax}−$b)($ax−$b)'
    ],
    explanation: 'A²−B²＝(A+B)(A−B) で、A＝$ax、B＝$b。',
  );
}

/// (ax+p)(x+q) の形の因数分解
GenQ? _factorAdv(Random r) {
  final a = r.pick([2, 3, 5]);
  final p = r.nonZero(-7, 7), q = r.nonZero(-5, 5);
  if (gcd(a, p.abs()) != 1) return null;
  String f(int pp, int qq) => '(${_p([a, pp])})(${Fmt.linear(qq)})';
  final b = a * q + p;
  if (b == 0) return null;
  return GenQ(
    prompt: '${_p([a, b, p * q])} を因数分解すると？',
    answer: f(p, q),
    wrong: [f(-p, -q), f(q, p), f(p, -q), f(-p, q)],
    explanation: 'たすきがけ：$a×${_pn(q)}＋1×${_pn(p)}＝${_n(b)}',
  );
}

/// x^a・x^b など指数法則
GenQ? _monomial(Random r) {
  final a = r.range(2, 6), b = r.range(2, 6);
  final ca = r.range(1, 5), cb = r.range(1, 5);
  String m(int c, int e) => '${c == 1 ? '' : c}${Fmt.pow('x', e)}';
  return GenQ(
    prompt: '${m(ca, a)}×${m(cb, b)} を計算すると？',
    answer: m(ca * cb, a + b),
    wrong: [
      m(ca * cb, a * b),
      m(ca + cb, a + b),
      m(ca * cb, a + b + 1),
      m(ca + cb, a * b)
    ],
    explanation:
        '係数はかけ算、指数はたし算：x${Fmt.sup(a)}×x${Fmt.sup(b)}＝x${Fmt.sup(a + b)}',
  );
}

/// 1次不等式 ax+b > cx+d
GenQ? _ineq1(Random r) {
  final a = r.nonZero(-6, 6), c = r.nonZero(-6, 6);
  if (a == c) return null;
  final b = r.range(-9, 9), d = r.range(-9, 9);
  final strict = r.nextBool();
  final s = strict ? '>' : '≧';
  final k = Rat(d - b, a - c);
  final flip = a - c < 0;
  String sol(bool gt) =>
      'x${gt ? (strict ? '>' : '≧') : (strict ? '<' : '≦')}$k';
  String solv(bool gt, Rat v) =>
      'x${gt ? (strict ? '>' : '≧') : (strict ? '<' : '≦')}$v';
  return GenQ(
    prompt: '不等式 ${_p([a, b])}$s${_p([c, d])} を解くと？',
    answer: sol(!flip),
    wrong: [
      sol(flip),
      solv(!flip, -k),
      solv(flip, -k),
      solv(!flip, k + Rat(1))
    ],
    explanation: '${_n(a - c)}x$s${_n(d - b)}。'
        '${flip ? '負の数で割るので、不等号の向きが変わる。' : ''}',
  );
}

/// |x−a|=b
GenQ? _absEq(Random r) {
  final a = r.range(-6, 6), b = r.range(1, 8);
  String two(int x, int y) => 'x=${_n(min(x, y))}, ${_n(max(x, y))}';
  return GenQ(
    prompt: '方程式 |${Fmt.linear(-a)}|=$b を解くと？',
    answer: two(a - b, a + b),
    wrong: [
      two(-a - b, -a + b),
      'x=${_n(a + b)}',
      two(a - b, b - a),
      two(a, b)
    ],
    explanation: '${Fmt.linear(-a)}＝±$b より x＝${_n(a)}±$b',
  );
}

/// |x−a|<b
GenQ? _absIneq(Random r) {
  final a = r.range(-5, 5), b = r.range(1, 7);
  final lt = r.nextBool();
  final inside = '${_n(a - b)}<x<${_n(a + b)}';
  final outside = 'x<${_n(a - b)}, ${_n(a + b)}<x';
  return GenQ(
    prompt: '不等式 |${Fmt.linear(-a)}|${lt ? '<' : '>'}$b を解くと？',
    answer: lt ? inside : outside,
    wrong: [
      lt ? outside : inside,
      '${_n(-a - b)}<x<${_n(-a + b)}',
      'x<${_n(-a - b)}, ${_n(-a + b)}<x',
      'x<${_n(a + b)}',
    ],
    explanation: lt
        ? '−$b<${Fmt.linear(-a)}<$b より $inside'
        : '${Fmt.linear(-a)}<−$b または ${Fmt.linear(-a)}>$b',
  );
}

/// 絶対値の計算
GenQ? _absValue(Random r) {
  final a = r.nonZero(-20, 20), b = r.nonZero(-20, 20);
  return GenQ(
    prompt: '|${_n(a)}|+|${_n(b)}| の値は？',
    answer: _n(a.abs() + b.abs()),
    wrong: [
      _n(a + b),
      _n((a + b).abs()),
      _n(a.abs() - b.abs()),
      _n(-(a.abs() + b.abs()))
    ],
    explanation: '|${_n(a)}|＝${a.abs()}、|${_n(b)}|＝${b.abs()}',
  );
}

/// √ を簡単にする
GenQ? _sqrtSimplify(Random r) {
  final k = r.range(2, 7), m = r.pick([2, 3, 5, 6, 7, 10]);
  final nn = k * k * m;
  return GenQ(
    prompt: '√$nn を簡単にすると？',
    answer: Fmt.sqrt(nn),
    wrong: ['${k * k}√$m', '$m√$k', '${k + 1}√$m', '$k√${m + 1}'],
    explanation: '$nn＝$k²×$m より √$nn＝$k√$m',
  );
}

/// 1/(√a−√b) の有理化（a−b＝1）
GenQ? _rationalize(Random r) {
  final b = r.pick([2, 3, 5, 6, 7, 10]);
  final a = b + 1;
  if (Fmt.simplifySqrt(a).$1 != 1) return null;
  return GenQ(
    prompt: '1/(√$a−√$b) の分母を有理化すると？',
    answer: '√$a+√$b',
    wrong: ['√$a−√$b', '(√$a+√$b)/2', '√${a + b}', '−√$a−√$b'],
    explanation: '分母と分子に √$a+√$b をかけると、分母は $a−$b＝1。',
  );
}

// ---------------- 数学Ⅰ：2次関数 ----------------

/// y=a(x−p)²+q を展開した式の頂点
GenQ? _vertex(Random r) {
  final a = r.pick([1, 1, 1, -1, 2, -2, 3]);
  final p = r.range(-5, 5), q = r.range(-9, 9);
  String pt(int x, int y) => '(${_n(x)}, ${_n(y)})';
  return GenQ(
    prompt: '放物線 y=${_p([a, -2 * a * p, a * p * p + q])} の頂点の座標は？',
    answer: pt(p, q),
    wrong: [pt(-p, q), pt(p, -q), pt(-p, -q), pt(q, p)],
    explanation:
        '平方完成して y=${a == 1 ? '' : a == -1 ? '−' : _n(a)}${_sq('x', p)}${q >= 0 ? '+' : ''}${_n(q)}',
  );
}

/// 2次関数の最大値・最小値（定義域なし）
GenQ? _quadMinMax(Random r) {
  final a = r.pick([1, 1, 2, -1, -2]);
  final p = r.range(-5, 5), q = r.range(-9, 9);
  final word = a > 0 ? '最小値' : '最大値';
  return GenQ(
    prompt: '関数 y=${_p([a, -2 * a * p, a * p * p + q])} の$wordは？',
    answer: _n(q),
    wrong: [_n(-q), _n(p), _n(q + a), _n(a * p * p + q)],
    explanation:
        '頂点は (${_n(p)}, ${_n(q)})。${a > 0 ? '下に凸' : '上に凸'}なので、$wordは ${_n(q)}。',
  );
}

/// 判別式で実数解の個数
GenQ? _discriminantCount(Random r) {
  final a = r.pick([1, 1, 2, 3]);
  final b = r.range(-8, 8), c = r.range(-8, 8);
  final d = b * b - 4 * a * c;
  final ans = d > 0
      ? '2個'
      : d == 0
          ? '1個'
          : '0個';
  return GenQ(
    prompt: '2次方程式 ${_p([a, b, c])}=0 の異なる実数解の個数は？',
    answer: ans,
    wrong: ['2個', '1個', '0個', '3個'],
    explanation:
        '判別式 D＝${_pn(b)}²−4×$a×${_pn(c)}＝${_n(d)}${d > 0 ? '＞0' : d == 0 ? '＝0' : '＜0'}',
    category: QuestionCategory.thinking,
  );
}

/// (x−p)(x−q)=0 を展開した2次方程式
GenQ? _quadSolve(Random r) {
  var p = r.range(-8, 8), q = r.range(-8, 8);
  if (p == q || p == -q) return null;
  if (p > q) (p, q) = (q, p);
  String two(int x, int y) => 'x=${_n(min(x, y))}, ${_n(max(x, y))}';
  return GenQ(
    prompt: '2次方程式 ${_p([1, -(p + q), p * q])}=0 を解くと？',
    answer: two(p, q),
    wrong: [two(-p, -q), two(p, -q), two(-p, q), two(p + q, p * q)],
    explanation:
        '(${Fmt.linear(-p)})(${Fmt.linear(-q)})＝0 より x＝${_n(p)}, ${_n(q)}',
  );
}

/// (x−p)(x−q)<0 / >0
GenQ? _quadIneq(Random r) {
  var p = r.range(-7, 7), q = r.range(-7, 7);
  if (p == q || p == -q) return null;
  if (p > q) (p, q) = (q, p);
  final lt = r.nextBool();
  final inside = '${_n(p)}<x<${_n(q)}';
  final outside = 'x<${_n(p)}, ${_n(q)}<x';
  return GenQ(
    prompt: '2次不等式 ${_p([1, -(p + q), p * q])}${lt ? '<' : '>'}0 を解くと？',
    answer: lt ? inside : outside,
    wrong: [
      lt ? outside : inside,
      '${_n(-q)}<x<${_n(-p)}',
      'x<${_n(-q)}, ${_n(-p)}<x',
      'x<${_n(p)}',
    ],
    explanation:
        '${_p([1, -(p + q), p * q])}＝(${Fmt.linear(-p)})(${Fmt.linear(-q)})。'
        '${lt ? '2つの解の間' : '2つの解の外側'}。',
  );
}

// ---------------- 数学Ⅰ：データの分析 ----------------

List<int> _data(Random r, int n, {bool intMean = false}) {
  while (true) {
    final xs = [for (var i = 0; i < n; i++) r.range(1, 20)];
    if (!intMean || xs.reduce((a, b) => a + b) % n == 0) return xs;
  }
}

GenQ? _mean(Random r) {
  final n = r.pick([4, 5, 6]);
  final xs = _data(r, n, intMean: true);
  final s = xs.reduce((a, b) => a + b);
  final m = s ~/ n;
  return GenQ(
    prompt: 'データ ${xs.join(', ')} の平均値は？',
    answer: '$m',
    wrong: ['${m + 1}', '${m - 1}', '$s', '${m + 2}'],
    explanation: '合計 $s を個数 $n で割って $m。',
  );
}

GenQ? _median(Random r) {
  final n = r.pick([5, 7, 6, 8]);
  final xs = _data(r, n);
  final sorted = [...xs]..sort();
  final Rat med = n.isOdd
      ? Rat(sorted[n ~/ 2])
      : Rat(sorted[n ~/ 2 - 1] + sorted[n ~/ 2], 2);
  final mean = Rat(xs.reduce((a, b) => a + b), n);
  return GenQ(
    prompt: 'データ ${xs.join(', ')} の中央値は？',
    answer: '$med',
    wrong: [
      '${xs[n ~/ 2]}',
      '$mean',
      '${sorted.first}',
      '${sorted.last}',
      '${med + Rat(1)}'
    ],
    explanation:
        '小さい順に ${sorted.join(', ')}。${n.isOdd ? '真ん中の値' : '真ん中の2つの平均'}が中央値。',
  );
}

GenQ? _range(Random r) {
  final xs = _data(r, r.pick([5, 6, 7]));
  final mx = xs.reduce(max), mn = xs.reduce(min);
  return GenQ(
    prompt: 'データ ${xs.join(', ')} の範囲は？',
    answer: '${mx - mn}',
    wrong: ['$mx', '${mx + mn}', '${mx - mn + 1}', '$mn'],
    explanation: '範囲＝最大値−最小値＝$mx−$mn',
  );
}

/// 8個のデータの四分位範囲（前半4個・後半4個の中央値）
GenQ? _iqr(Random r) {
  final xs = _data(r, 8);
  final s = [...xs]..sort();
  final q1 = Rat(s[1] + s[2], 2), q3 = Rat(s[5] + s[6], 2);
  final iqr = q3 - q1;
  return GenQ(
    prompt: '8個のデータ ${xs.join(', ')} の四分位範囲は？',
    answer: '$iqr',
    wrong: [
      '${s.last - s.first}',
      '$q3',
      '${iqr + Rat(1)}',
      '${(q3 - q1) * Rat(1, 2)}'
    ],
    explanation: '小さい順に ${s.join(', ')}。Q₁＝$q1、Q₃＝$q3 なので Q₃−Q₁＝$iqr。',
  );
}

GenQ? _variance(Random r) {
  final n = r.pick([4, 5]);
  final xs = _data(r, n, intMean: true);
  final m = xs.reduce((a, b) => a + b) ~/ n;
  final ss = xs.fold(0, (t, x) => t + (x - m) * (x - m));
  final v = Rat(ss, n);
  final sdOk = v.isInt && sqrt(v.num).round() * sqrt(v.num).round() == v.num;
  final askSd = sdOk && r.nextBool();
  final ans = askSd ? '${sqrt(v.num).round()}' : '$v';
  return GenQ(
    prompt: 'データ ${xs.join(', ')} の${askSd ? '標準偏差' : '分散'}は？',
    answer: ans,
    wrong: askSd
        ? [
            '$v',
            '${sqrt(v.num).round() + 1}',
            '$m',
            '${sqrt(v.num).round() * 2}'
          ]
        : ['$ss', '${Rat(ss, n - 1)}', '${v + Rat(1)}', '$m'],
    explanation: '平均 $m。偏差の2乗の合計 $ss を $n で割って分散 $v'
        '${askSd ? '、その正の平方根' : ''}。',
  );
}

// ---------------- 数学Ⅰ：三角比 ----------------

const _sin = {
  0: '0', 30: '1/2', 45: '√2/2', 60: '√3/2', 90: '1', //
  120: '√3/2', 135: '√2/2', 150: '1/2', 180: '0',
};
const _cos = {
  0: '1', 30: '√3/2', 45: '√2/2', 60: '1/2', 90: '0', //
  120: '−1/2', 135: '−√2/2', 150: '−√3/2', 180: '−1',
};
const _tan = {
  0: '0', 30: '√3/3', 45: '1', 60: '√3', //
  120: '−√3', 135: '−1', 150: '−√3/3', 180: '0',
};
const _trigValues = [
  '0', '1/2', '√2/2', '√3/2', '1', '−1/2', '−√2/2', '−√3/2', '−1', //
  '√3', '√3/3', '−√3', '−√3/3',
];

GenQ? _trigValue(Random r) {
  final f = r.pick(['sin', 'cos', 'tan']);
  final table = f == 'sin'
      ? _sin
      : f == 'cos'
          ? _cos
          : _tan;
  final deg = r.pick(table.keys.toList());
  final ans = table[deg]!;
  return GenQ(
    prompt: '$f $deg° の値は？',
    answer: ans,
    wrong: [
      for (final v in [..._trigValues]..shuffle(r)) v
    ],
    explanation: '$f $deg°＝$ans',
  );
}

/// sin θ＝k（0°≦θ≦180°）を満たす θ
GenQ? _trigEquation(Random r) {
  final f = r.pick(['sin', 'cos']);
  final table = f == 'sin' ? _sin : _cos;
  final value = r.pick(table.values.toSet().toList());
  final degs = [
    for (final e in table.entries)
      if (e.value == value) e.key
  ]..sort();
  final ans = degs.map((d) => '$d°').join(', ');
  final others = <String>[
    for (final e in table.entries)
      if (e.value != value) '${e.key}°',
    for (final e in table.entries)
      if (e.value != value && e.key < 90) '${e.key}°, ${180 - e.key}°',
  ]..shuffle(r);
  return GenQ(
    prompt: '0°≦θ≦180° のとき、$f θ＝$value を満たす θ は？',
    answer: ans,
    wrong: others,
    explanation: '$f の値が $value になる角は $ans。',
  );
}

/// 三角形の面積 (1/2)bc sin A
GenQ? _triArea(Random r) {
  final b = r.range(2, 10), c = r.range(2, 10);
  final a = r.pick([30, 45, 60, 90, 120, 135, 150]);
  String area(int deg) {
    // (1/2)bc sinA
    switch (deg) {
      case 30 || 150:
        return '${Rat(b * c, 4)}';
      case 90:
        return '${Rat(b * c, 2)}';
      case 45 || 135:
        final q = Rat(b * c, 4);
        return q.den == 1
            ? '${q.num}√2'
            : '${q.num == 1 ? '' : q.num}√2/${q.den}';
      default:
        final q = Rat(b * c, 4);
        return q.den == 1
            ? '${q.num}√3'
            : '${q.num == 1 ? '' : q.num}√3/${q.den}';
    }
  }

  final ans = area(a);
  return GenQ(
    prompt: '△ABC で b=$b、c=$c、A=$a° のとき、面積は？',
    answer: ans,
    wrong: [
      for (final d in [30, 45, 60, 90]) area(d),
      '${b * c}',
      '${Rat(b * c, 2)}'
    ],
    explanation: '面積＝(1/2)bc sin A＝(1/2)×$b×$c×${_sin[a]}',
  );
}

/// 余弦定理（A＝60°、90°、120°）
GenQ? _cosineRule(Random r) {
  final b = r.range(2, 9), c = r.range(2, 9);
  final a = r.pick([60, 90, 120]);
  int sq(int deg) =>
      b * b +
      c * c -
      (deg == 60
          ? b * c
          : deg == 120
              ? -b * c
              : 0);
  final ans = Fmt.sqrt(sq(a));
  return GenQ(
    prompt: '△ABC で b=$b、c=$c、A=$a° のとき、a の値は？',
    answer: ans,
    wrong: [
      for (final d in [60, 90, 120])
        if (d != a) Fmt.sqrt(sq(d)),
      '${b + c}',
      Fmt.sqrt(b * b + c * c + 2 * b * c + 1),
    ],
    explanation: 'a²＝b²+c²−2bc cos A＝${sq(a)}',
  );
}

// ---------------- 数学Ⅱ：図形と方程式 ----------------

/// 点と直線の距離（√(a²+b²) が整数になる係数）
GenQ? _pointLine(Random r) {
  final (a, b) = r
      .pick([(3, 4), (4, 3), (5, 12), (12, 5), (6, 8), (8, 6), (1, 0), (0, 1)]);
  final sa = r.nextBool() ? a : -a, sb = r.nextBool() ? b : -b;
  final c = r.range(-10, 10);
  final x = r.range(-5, 5), y = r.range(-5, 5);
  final norm = sqrt(a * a + b * b).round();
  final d = Rat((sa * x + sb * y + c).abs(), norm);
  if (d.isZero) return null;
  // 式を組み立てる：ax+by+c=0
  final b2 = StringBuffer();
  void term(int coef, String v) {
    if (coef == 0) return;
    final body = coef.abs() == 1 && v.isNotEmpty ? v : '${coef.abs()}$v';
    b2.write(b2.isEmpty
        ? (coef < 0 ? '−$body' : body)
        : (coef < 0 ? '−$body' : '+$body'));
  }

  term(sa, 'x');
  term(sb, 'y');
  term(c, '');
  return GenQ(
    prompt: '点 (${_n(x)}, ${_n(y)}) と直線 ${b2.toString()}=0 の距離は？',
    answer: '$d',
    wrong: [
      '${Rat((sa * x + sb * y + c).abs())}',
      '${d + Rat(1)}',
      '${Rat((sa * x + sb * y - c).abs(), norm)}',
      '${Rat((sa * x + sb * y + c).abs(), norm * norm)}'
    ],
    explanation: '距離＝|ax₀+by₀+c|/√(a²+b²)＝${(sa * x + sb * y + c).abs()}/$norm',
  );
}

/// 2点間の距離
GenQ? _twoPoints(Random r) {
  final x1 = r.range(-5, 5), y1 = r.range(-5, 5);
  final x2 = r.range(-5, 5), y2 = r.range(-5, 5);
  final dx = x2 - x1, dy = y2 - y1;
  if (dx == 0 && dy == 0) return null;
  final d2 = dx * dx + dy * dy;
  return GenQ(
    prompt: '2点 (${_n(x1)}, ${_n(y1)})、(${_n(x2)}, ${_n(y2)}) の間の距離は？',
    answer: Fmt.sqrt(d2),
    wrong: [
      Fmt.sqrt(d2 + 1),
      '${dx.abs() + dy.abs()}',
      '$d2',
      Fmt.sqrt((dx + dy) * (dx + dy) + 1)
    ],
    explanation: '√(${_pn(dx)}²+${_pn(dy)}²)＝√$d2',
  );
}

/// 中点・重心
GenQ? _midpoint(Random r) {
  final x1 = r.range(-8, 8), y1 = r.range(-8, 8);
  final x2 = r.range(-8, 8), y2 = r.range(-8, 8);
  String pt(Rat a, Rat b) => '($a, $b)';
  final m = pt(Rat(x1 + x2, 2), Rat(y1 + y2, 2));
  return GenQ(
    prompt: '2点 (${_n(x1)}, ${_n(y1)})、(${_n(x2)}, ${_n(y2)}) を結ぶ線分の中点は？',
    answer: m,
    wrong: [
      pt(Rat(x2 - x1, 2), Rat(y2 - y1, 2)),
      pt(Rat(x1 + x2), Rat(y1 + y2)),
      pt(Rat(y1 + y2, 2), Rat(x1 + x2, 2)),
      pt(Rat(x1 - x2, 2), Rat(y1 - y2, 2)),
    ],
    explanation: '中点＝((x₁+x₂)/2, (y₁+y₂)/2)',
  );
}

GenQ? _centroid(Random r) {
  final xs = [for (var i = 0; i < 3; i++) r.range(-6, 9)];
  final ys = [for (var i = 0; i < 3; i++) r.range(-6, 9)];
  String pt(Rat a, Rat b) => '($a, $b)';
  final sx = xs.reduce((a, b) => a + b), sy = ys.reduce((a, b) => a + b);
  return GenQ(
    prompt:
        '3点 (${_n(xs[0])}, ${_n(ys[0])})、(${_n(xs[1])}, ${_n(ys[1])})、(${_n(xs[2])}, ${_n(ys[2])}) を頂点とする三角形の重心は？',
    answer: pt(Rat(sx, 3), Rat(sy, 3)),
    wrong: [
      pt(Rat(sx, 2), Rat(sy, 2)),
      pt(Rat(sx), Rat(sy)),
      pt(Rat(sy, 3), Rat(sx, 3)),
      pt(Rat(sx + 1, 3), Rat(sy, 3))
    ],
    explanation: '重心＝(3つの x 座標の和/3, 3つの y 座標の和/3)',
  );
}

/// x²+y²+Dx+Ey+F=0 の中心と半径
GenQ? _circle(Random r) {
  final a = r.range(-5, 5), b = r.range(-5, 5), rad = r.range(1, 6);
  final f = a * a + b * b - rad * rad;
  final sb = StringBuffer('x²+y²');
  void term(int c, String v) {
    if (c == 0) return;
    final body = c.abs() == 1 && v.isNotEmpty ? v : '${c.abs()}$v';
    sb.write(c < 0 ? '−$body' : '+$body');
  }

  term(-2 * a, 'x');
  term(-2 * b, 'y');
  term(f, '');
  final ans = '中心 (${_n(a)}, ${_n(b)})、半径 $rad';
  return GenQ(
    prompt: '円 ${sb.toString()}=0 の中心と半径は？',
    answer: ans,
    wrong: [
      '中心 (${_n(-a)}, ${_n(-b)})、半径 $rad',
      '中心 (${_n(a)}, ${_n(b)})、半径 ${rad * rad}',
      '中心 (${_n(-2 * a)}, ${_n(-2 * b)})、半径 $rad',
      '中心 (${_n(a)}, ${_n(b)})、半径 ${rad + 1}',
    ],
    explanation: '${_sq('x', a)}+${_sq('y', b)}＝${rad * rad} と変形する。',
  );
}

/// (x−a)²（a＝0 なら x²）
String _sq(String v, int a) => a == 0 ? '$v²' : '(${Fmt.linear(-a, v)})²';

// ---------------- 数学Ⅱ：指数・対数 ----------------

GenQ? _expValue(Random r) {
  final cases = [
    for (final (base, e) in [
      (2, 2),
      (2, 3),
      (2, 4),
      (2, 5),
      (3, 2),
      (3, 3),
      (5, 2),
      (10, 2),
      (10, 3),
      (4, 2)
    ])
      ('$base${Fmt.sup(-e)}', Rat(1, pow(base, e).toInt())),
    ('8^(2/3)', Rat(4)),
    ('27^(2/3)', Rat(9)),
    ('16^(3/4)', Rat(8)),
    ('4^(3/2)', Rat(8)),
    ('9^(3/2)', Rat(27)),
    ('32^(2/5)', Rat(4)),
    ('25^(1/2)', Rat(5)),
    ('81^(1/4)', Rat(3)),
    ('64^(1/3)', Rat(4)),
    ('8^(−1/3)', Rat(1, 2)),
    ('16^(−1/2)', Rat(1, 4)),
    ('27^(−2/3)', Rat(1, 9)),
  ];
  final (expr, v) = r.pick(cases);
  return GenQ(
    prompt: '$expr の値は？',
    answer: '$v',
    wrong: ['${-v}', '${Rat(1) / v}', '${v * Rat(2)}', '${v + Rat(1)}'],
    explanation: '$expr＝$v',
  );
}

GenQ? _expEquation(Random r) {
  final a = r.pick([2, 3, 5]);
  final k = r.range(-3, 5);
  final small = r.nextBool();
  final rhs = k >= 0 ? '${pow(a, k).toInt()}' : '1/${pow(a, -k).toInt()}';
  if (!small) {
    return GenQ(
      prompt: '方程式 $aˣ=$rhs を解くと？',
      answer: _xeq(Rat(k)),
      wrong: [
        _xeq(Rat(-k)),
        _xeq(Rat(k + 1)),
        _xeq(Rat(k - 1)),
        _xeq(Rat(k * 2))
      ],
      explanation: '$rhs＝$a${Fmt.sup(k)} より x＝${_n(k)}',
    );
  }
  final gt = r.nextBool();
  return GenQ(
    prompt: '不等式 (1/$a)ˣ${gt ? '>' : '<'}(1/$a)${Fmt.sup(k)} を解くと？',
    answer: 'x${gt ? '<' : '>'}${_n(k)}',
    wrong: [
      'x${gt ? '>' : '<'}${_n(k)}',
      'x${gt ? '<' : '>'}${_n(-k)}',
      'x${gt ? '>' : '<'}${_n(-k)}'
    ],
    explanation: '底 1/$a は1より小さいので、不等号の向きが変わる。',
  );
}

GenQ? _logValue(Random r) {
  final kind = r.nextInt(3);
  if (kind == 0) {
    final a = r.pick([2, 3, 5, 10]);
    final k = r.range(-2, 5);
    final x = k >= 0 ? '${pow(a, k).toInt()}' : '1/${pow(a, -k).toInt()}';
    return GenQ(
      prompt: 'log${_sub(a)} $x の値は？',
      answer: _n(k),
      wrong: [_n(-k), _n(k + 1), x, _n(k * 2 == k ? k + 2 : k * 2)],
      explanation: '$a${Fmt.sup(k)}＝$x より ${_n(k)}',
    );
  }
  if (kind == 1) {
    // log_{a^m} a^n ＝ n/m
    final a = r.pick([2, 3]);
    final m = r.range(2, 3), nn = r.range(1, 5);
    final base = pow(a, m).toInt(), x = pow(a, nn).toInt();
    final v = Rat(nn, m);
    return GenQ(
      prompt: 'log${_sub(base)} $x の値は？',
      answer: '$v',
      wrong: [
        '${Rat(m, nn)}',
        '${Rat(nn)}',
        '${Rat(x, base)}',
        '${v + Rat(1)}'
      ],
      explanation: '$base＝$a${Fmt.sup(m)}、$x＝$a${Fmt.sup(nn)} より $nn/$m',
    );
  }
  // log_a x + log_a y（xy ＝ a^k）
  final a = r.pick([2, 3]);
  final k = r.range(2, 5);
  final total = pow(a, k).toInt();
  final divs = [
    for (var d = 2; d < total; d++)
      if (total % d == 0 && d != total ~/ d) d
  ];
  if (divs.isEmpty) return null;
  final x = r.pick(divs);
  final y = total ~/ x;
  return GenQ(
    prompt: 'log${_sub(a)} $x+log${_sub(a)} $y の値は？',
    answer: _n(k),
    wrong: [_n(k + 1), _n(k - 1), '${x + y}', _n(total)],
    explanation: 'log${_sub(a)} $x+log${_sub(a)} $y＝log${_sub(a)} $total＝$k',
  );
}

String _sub(int v) => '$v'
    .split('')
    .map((c) => const {
          '0': '₀',
          '1': '₁',
          '2': '₂',
          '3': '₃',
          '4': '₄',
          '5': '₅',
          '6': '₆',
          '7': '₇',
          '8': '₈',
          '9': '₉'
        }[c]!)
    .join();

// ---------------- 数学Ⅱ：複素数と方程式 ----------------

String _cx(int a, int b) {
  if (b == 0) return _n(a);
  final bi = b == 1
      ? 'i'
      : b == -1
          ? '−i'
          : '${_n(b)}i';
  if (a == 0) return bi;
  return b > 0
      ? '${_n(a)}+${b == 1 ? 'i' : '${b}i'}'
      : '${_n(a)}−${b == -1 ? 'i' : '${-b}i'}';
}

GenQ? _iPower(Random r) {
  final nn = r.range(2, 60);
  const cycle = ['1', 'i', '−1', '−i'];
  return GenQ(
    prompt: 'i${Fmt.sup(nn)} を計算すると？',
    answer: cycle[nn % 4],
    wrong: cycle,
    explanation: 'i⁴＝1 なので、$nn を4で割った余り ${nn % 4} を見る。',
  );
}

GenQ? _cxMul(Random r) {
  final a = r.range(-5, 5), b = r.nonZero(-5, 5);
  final c = r.range(-5, 5), d = r.nonZero(-5, 5);
  final sq = r.nextInt(3) == 0;
  final (cc, dd) = sq ? (a, b) : (c, d);
  final re = a * cc - b * dd, im = a * dd + b * cc;
  return GenQ(
    prompt:
        sq ? '(${_cx(a, b)})² を計算すると？' : '(${_cx(a, b)})(${_cx(c, d)}) を計算すると？',
    answer: _cx(re, im),
    wrong: [
      _cx(a * cc + b * dd, im),
      _cx(re, -im),
      _cx(a * cc, b * dd),
      _cx(-re, im)
    ],
    explanation: 'i²＝−1 を使って、実部 ${_n(re)}、虚部 ${_n(im)}。',
  );
}

GenQ? _solutionKind(Random r) {
  final a = r.pick([1, 1, 2, 3]);
  final b = r.range(-8, 8), c = r.range(-8, 8);
  final d = b * b - 4 * a * c;
  return GenQ(
    prompt: '2次方程式 ${_p([a, b, c])}=0 の解の種類は？',
    answer: d > 0
        ? '異なる2つの実数解'
        : d == 0
            ? '重解'
            : '異なる2つの虚数解',
    wrong: ['異なる2つの実数解', '重解', '異なる2つの虚数解', '解をもたない'],
    explanation: '判別式 D＝${_n(d)}${d > 0 ? '＞0' : d == 0 ? '＝0' : '＜0'}',
    category: QuestionCategory.thinking,
  );
}

GenQ? _vieta(Random r) {
  final a = r.pick([1, 1, 2, 3]);
  final b = r.nonZero(-9, 9), c = r.nonZero(-9, 9);
  final sum = Rat(-b, a), prod = Rat(c, a);
  final kind = r.nextInt(3);
  final (label, v) = switch (kind) {
    0 => ('α+β', sum),
    1 => ('αβ', prod),
    _ => ('α²+β²', sum * sum - Rat(2) * prod),
  };
  return GenQ(
    prompt: '2次方程式 ${_p([a, b, c])}=0 の2つの解を α, β とするとき、$label の値は？',
    answer: '$v',
    wrong: [
      '${-v}',
      '${Rat(b, a)}',
      '${sum * sum + Rat(2) * prod}',
      '${Rat(-c, a)}',
      '${v + Rat(1)}'
    ],
    explanation: '解と係数の関係：α+β＝$sum、αβ＝$prod',
  );
}

/// 剰余の定理：P(x) を x−k で割った余り
GenQ? _remainder(Random r) {
  final c = [1, r.range(-5, 5), r.range(-6, 6), r.range(-9, 9)];
  final k = r.nonZero(-3, 3);
  int p(int x) => c[0] * x * x * x + c[1] * x * x + c[2] * x + c[3];
  return GenQ(
    prompt: 'P(x)=${_p(c)} を ${Fmt.linear(-k)} で割った余りは？',
    answer: _n(p(k)),
    wrong: [_n(p(-k)), _n(c[3]), _n(p(k) + 1), _n(p(k) - k)],
    explanation: '剰余の定理より、余りは P(${_n(k)})＝${_n(p(k))}',
  );
}

/// x²+bx+c を x−k で割った商と余り
GenQ? _division(Random r) {
  final b = r.range(-6, 6), c = r.range(-9, 9), k = r.nonZero(-4, 4);
  final q = b + k, rem = k * k + b * k + c;
  String ans(int qq, int rr) => '商 ${Fmt.linear(qq)}、余り ${_n(rr)}';
  return GenQ(
    prompt: '${_p([1, b, c])} を ${Fmt.linear(-k)} で割ったときの商と余りは？',
    answer: ans(q, rem),
    wrong: [
      ans(b - k, k * k - b * k + c),
      ans(q, c),
      ans(b, rem),
      ans(q, -rem)
    ],
    explanation: '商 ${Fmt.linear(q)}。余りは剰余の定理で P(${_n(k)})＝${_n(rem)}',
  );
}

int _choose(int n, int k) {
  if (k < 0 || k > n) return 0;
  var v = 1;
  for (var i = 0; i < k; i++) {
    v = v * (n - i) ~/ (i + 1);
  }
  return v;
}

/// (ax+b)ⁿ の xᵏ の係数
GenQ? _binomial(Random r) {
  final nn = r.range(3, 6), k = r.range(1, nn - 1);
  final a = r.pick([1, 2, -1, -2, 3]), b = r.pick([1, 2, -1, -2, 3]);
  final coef = _choose(nn, k) * pow(a, k).toInt() * pow(b, nn - k).toInt();
  if (coef == 0) return null;
  return GenQ(
    prompt: '(${_p([a, b])})${Fmt.sup(nn)} の展開式における ${Fmt.pow('x', k)} の係数は？',
    answer: _n(coef),
    wrong: [
      _n(-coef),
      _n(_choose(nn, k)),
      _n(_choose(nn, k) * pow(a, nn - k).toInt() * pow(b, k).toInt()),
      _n(coef * 2),
    ],
    explanation:
        '${nn}C$k×(${_n(a)})${Fmt.sup(k)}×(${_n(b)})${Fmt.sup(nn - k)}＝${_n(coef)}',
  );
}

/// x>0 のとき ax+b/x の最小値（相加平均と相乗平均）
GenQ? _amgm(Random r) {
  final a = r.range(1, 5), b = r.range(1, 30);
  final s = sqrt(a * b).round();
  if (s * s != a * b) return null;
  final ax = a == 1 ? 'x' : '${a}x';
  return GenQ(
    prompt: 'x>0 のとき、$ax+$b/x の最小値は？',
    answer: '${2 * s}',
    wrong: ['$s', '${a + b}', '${2 * s + 1}', '${a * b}'],
    explanation: '相加平均と相乗平均の関係より $ax+$b/x≧2√(${a * b})＝${2 * s}',
  );
}

// ---------------- 数学Ⅱ：三角関数 ----------------

GenQ? _synthMax(Random r) {
  final a = r.range(1, 6), b = r.range(1, 6);
  final s = a * a + b * b;
  final asn = a == 1 ? '' : '$a';
  final bcs = b == 1 ? '' : '$b';
  final mx = r.nextBool();
  return GenQ(
    prompt: 'y=${asn}sin θ+${bcs}cos θ の${mx ? '最大値' : '最小値'}は？',
    answer: mx ? Fmt.sqrt(s) : Fmt.sqrt(s, coef: -1),
    wrong: [
      '${a + b}',
      mx ? Fmt.sqrt(s, coef: -1) : Fmt.sqrt(s),
      '$s',
      '${-(a + b)}',
      Fmt.sqrt(s + 1)
    ],
    explanation: '合成すると √($a²+$b²)sin(θ+α)＝${Fmt.sqrt(s)}sin(θ+α)',
  );
}

String _piFrac(Rat q) {
  if (q.isZero) return '0';
  final top = q.num.abs() == 1 ? 'π' : '${q.num.abs()}π';
  final s = q.den == 1 ? top : '$top/${q.den}';
  return q.num < 0 ? '−$s' : s;
}

GenQ? _period(Random r) {
  final f = r.pick(['sin', 'cos', 'tan']);
  final k = r.range(1, 6);
  final per = f == 'tan' ? Rat(1, k) : Rat(2, k);
  final kx = k == 1 ? 'x' : '${k}x';
  return GenQ(
    prompt: 'y=$f $kx の周期は？（正で最小のもの）',
    answer: _piFrac(per),
    wrong: [
      _piFrac(per * Rat(2)),
      _piFrac(per * Rat(1, 2)),
      _piFrac(Rat(k)),
      _piFrac(Rat(2 * k))
    ],
    explanation: '$f x の周期は ${f == 'tan' ? 'π' : '2π'}。$kx なので $k で割る。',
  );
}

GenQ? _radian(Random r) {
  final deg = r.pick([
    30,
    45,
    60,
    90,
    120,
    135,
    150,
    180,
    210,
    225,
    240,
    270,
    300,
    315,
    330,
    360
  ]);
  final rad = Rat(deg, 180);
  final toRad = r.nextBool();
  if (toRad) {
    return GenQ(
      prompt: '$deg° を弧度法で表すと？',
      answer: _piFrac(rad),
      wrong: [
        _piFrac(rad * Rat(2)),
        _piFrac(Rat(180, deg)),
        _piFrac(rad + Rat(1, 6)),
        _piFrac(rad * Rat(1, 2))
      ],
      explanation: '180°＝π より $deg°＝${_piFrac(rad)}',
    );
  }
  return GenQ(
    prompt: '${_piFrac(rad)} は何度？',
    answer: '$deg°',
    wrong: [
      '${deg * 2}°',
      '${deg ~/ 2}°',
      '${360 - deg == deg ? deg + 30 : 360 - deg}°',
      '${deg + 30}°'
    ],
    explanation: 'π＝180° より ${_piFrac(rad)}＝$deg°',
  );
}

// ---------------- 数学Ⅱ：微分・積分 ----------------

GenQ? _diffCoef(Random r) {
  final c = [r.range(-2, 3), r.range(-4, 4), r.range(-6, 6), r.range(-9, 9)];
  if (c[0] == 0 && c[1] == 0) return null;
  final k = r.range(-3, 3);
  final d = 3 * c[0] * k * k + 2 * c[1] * k + c[2];
  final f = c[0] * k * k * k + c[1] * k * k + c[2] * k + c[3];
  return GenQ(
    prompt: 'f(x)=${_p(c)} のとき、f′(${_n(k)}) の値は？',
    answer: _n(d),
    wrong: [_n(f), _n(d + c[2]), _n(-d), _n(3 * c[0] * k + 2 * c[1] + c[2])],
    explanation: 'f′(x)＝${_p([3 * c[0], 2 * c[1], c[2]])} に x＝${_n(k)} を入れる。',
  );
}

GenQ? _tangent(Random r) {
  final b = r.range(-4, 4), c = r.range(-5, 5), k = r.range(-3, 3);
  final m = 2 * k + b, f = k * k + b * k + c;
  final n0 = f - m * k;
  String line(int mm, int nn) => 'y=${_p([mm, nn])}';
  return GenQ(
    prompt: '曲線 y=${_p([1, b, c])} 上の点 (${_n(k)}, ${_n(f)}) における接線の方程式は？',
    answer: line(m, n0),
    wrong: [line(m, f), line(-m, n0), line(m + 1, n0 - k), line(f, m)],
    explanation: 'y′＝${_p([
          2,
          b
        ])} より傾き ${_n(m)}。傾き ${_n(m)} で点 (${_n(k)}, ${_n(f)}) を通る直線。',
  );
}

Rat _intPoly(List<int> c, int a, int b) {
  // c は次数の高い順
  final deg = c.length - 1;
  var s = Rat(0);
  for (var i = 0; i < c.length; i++) {
    final e = deg - i;
    s = s + Rat(c[i] * (pow(b, e + 1).toInt() - pow(a, e + 1).toInt()), e + 1);
  }
  return s;
}

GenQ? _definite(Random r) {
  final c = [r.range(-3, 3), r.range(-4, 4), r.range(-5, 5)];
  if (c.every((v) => v == 0)) return null;
  final a = r.range(-2, 1), b = r.range(a + 1, 3);
  final v = _intPoly(c, a, b);
  final int1 = '∫${_lim(a)}${_up(b)} (${_p(c)}) dx';
  return GenQ(
    prompt: '$int1 の値は？',
    answer: '$v',
    wrong: [
      '${-v}',
      '${_intPoly(c, 0, b)}',
      '${v + Rat(1)}',
      '${_intPoly([0, ...c.sublist(0, 2)], a, b)}'
    ],
    explanation: '原始関数に上端・下端を入れて引く。',
  );
}

String _lim(int a) => '${a < 0 ? '₋' : ''}${_sub(a.abs())}';
String _up(int b) => Fmt.sup(b);

/// 放物線 y=(x−p)(x−q) と x 軸で囲まれた面積 (q−p)³/6
GenQ? _parabolaArea(Random r) {
  var p = r.range(-4, 4), q = r.range(-4, 5);
  if (p == q) return null;
  if (p > q) (p, q) = (q, p);
  final d = q - p;
  final v = Rat(d * d * d, 6);
  return GenQ(
    prompt: '放物線 y=${_p([1, -(p + q), p * q])} と x 軸で囲まれた部分の面積は？',
    answer: '$v',
    wrong: [
      '${Rat(d * d * d, 3)}',
      '${Rat(d * d, 2)}',
      '${Rat(d * d * d, 6) + Rat(1)}',
      '${Rat(d * d * d, 12)}'
    ],
    explanation: '∫ (x−α)(x−β) dx の公式より (${_n(q)}−(${_n(p)}))³/6＝$v',
  );
}

// ---------------- 数学Ⅲ ----------------

GenQ? _derivPower(Random r) => _deriv(r, r.nextInt(4));
GenQ? _derivPoly(Random r) => _deriv(r, 0);
GenQ? _derivTrig(Random r) => _deriv(r, 1);
GenQ? _derivExp(Random r) => _deriv(r, 2);
GenQ? _derivChain(Random r) => _deriv(r, 3);

GenQ? _deriv(Random r, int kind) {
  if (kind == 0) {
    final a = r.range(1, 6), nn = r.range(2, 9);
    final ax = a == 1 ? '' : '$a';
    final res = a * nn;
    String t(int c, int e) => '${c == 1 ? '' : c}${Fmt.pow('x', e)}';
    return GenQ(
      prompt: '($ax${Fmt.pow('x', nn)})′ は？',
      answer: t(res, nn - 1),
      wrong: [
        t(res, nn),
        t(a, nn - 1),
        t(res, nn + 1),
        t(nn, nn - 1) == t(res, nn - 1) ? t(res + 1, nn - 1) : t(nn, nn - 1)
      ],
      explanation: '(xⁿ)′＝nxⁿ⁻¹',
    );
  }
  if (kind == 1) {
    final k = r.range(2, 6);
    final f = r.pick(['sin', 'cos']);
    final ans = f == 'sin' ? '${k}cos ${k}x' : '−${k}sin ${k}x';
    return GenQ(
      prompt: '($f ${k}x)′ は？',
      answer: ans,
      wrong: [
        f == 'sin' ? 'cos ${k}x' : '−sin ${k}x',
        f == 'sin' ? '−${k}cos ${k}x' : '${k}sin ${k}x',
        f == 'sin' ? '${k}sin ${k}x' : '${k}cos ${k}x',
        f == 'sin' ? 'cos ${k}x/$k' : '−sin ${k}x/$k',
      ],
      explanation: '合成関数の微分：内側 ${k}x の微分 $k をかける。',
    );
  }
  if (kind == 2) {
    final k = r.range(2, 6);
    return GenQ(
      prompt: '(e^(${k}x))′ は？',
      answer: '${k}e^(${k}x)',
      wrong: ['e^(${k}x)', '${k}xe^(${k}x−1)', 'e^(${k}x)/$k', '${k}e^x'],
      explanation: '(e^(kx))′＝ke^(kx)',
    );
  }
  final a = r.range(2, 5), b = r.nonZero(-5, 5), nn = r.range(2, 5);
  final inner = _p([a, b]);
  final c = nn * a;
  return GenQ(
    prompt: '{($inner)${Fmt.sup(nn)}}′ は？',
    answer: '$c($inner)${Fmt.sup(nn - 1)}',
    wrong: [
      '$nn($inner)${Fmt.sup(nn - 1)}',
      '$c($inner)${Fmt.sup(nn)}',
      '$a($inner)${Fmt.sup(nn - 1)}',
      '${c + a}($inner)${Fmt.sup(nn - 1)}'
    ],
    explanation: '合成関数の微分：$nn($inner)${Fmt.sup(nn - 1)}×$a',
  );
}

GenQ? _integPower(Random r) {
  final kind = r.nextInt(3);
  if (kind == 0) {
    final nn = r.range(1, 7);
    final e = nn + 1;
    return GenQ(
      prompt: '∫${Fmt.pow('x', nn)} dx は？（C は積分定数）',
      answer: '${Fmt.pow('x', e)}/$e+C',
      wrong: [
        '${Fmt.pow('x', e)}+C',
        nn == 1 ? '1+C' : '${nn == 1 ? '' : nn}${Fmt.pow('x', nn - 1)}+C',
        '${Fmt.pow('x', e)}/$nn+C',
        '$e${Fmt.pow('x', e)}+C',
      ],
      explanation: '∫xⁿ dx＝xⁿ⁺¹/(n+1)+C',
    );
  }
  if (kind == 1) {
    final k = r.range(2, 6);
    return GenQ(
      prompt: '∫e^(${k}x) dx は？（C は積分定数）',
      answer: 'e^(${k}x)/$k+C',
      wrong: [
        '${k}e^(${k}x)+C',
        'e^(${k}x)+C',
        'e^(${k + 1}x)/${k + 1}+C',
        '−e^(${k}x)/$k+C'
      ],
      explanation: '∫e^(kx) dx＝e^(kx)/k+C',
    );
  }
  final k = r.range(2, 6);
  final f = r.pick(['sin', 'cos']);
  return GenQ(
    prompt: '∫$f ${k}x dx は？（C は積分定数）',
    answer: f == 'cos' ? 'sin ${k}x/$k+C' : '−cos ${k}x/$k+C',
    wrong: f == 'cos'
        ? [
            '−sin ${k}x/$k+C',
            '${k}sin ${k}x+C',
            'sin ${k}x+C',
            'cos ${k}x/$k+C'
          ]
        : [
            'cos ${k}x/$k+C',
            '−${k}cos ${k}x+C',
            '−cos ${k}x+C',
            'sin ${k}x/$k+C'
          ],
    explanation: f == 'cos'
        ? '(sin ${k}x)′＝${k}cos ${k}x より'
        : '(cos ${k}x)′＝−${k}sin ${k}x より',
  );
}

GenQ? _limitSin(Random r) {
  final a = r.range(1, 9), b = r.range(1, 9);
  final v = Rat(a, b);
  final ax = a == 1 ? 'x' : '${a}x';
  final bx = b == 1 ? 'x' : '${b}x';
  return GenQ(
    prompt: 'lim_{x→0} (sin $ax)/${b == 1 ? 'x' : '($bx)'} の値は？',
    answer: '$v',
    wrong: ['${Rat(b, a)}', '0', '1', '${Rat(a * b)}', '${v + Rat(1)}'],
    explanation: 'lim (sin $ax)/${a == 1 ? 'x' : '($ax)'}＝1 を使うと $v',
  );
}

GenQ? _geomSeries(Random r) {
  final a = r.range(1, 9);
  final k = r.range(2, 6);
  final neg = r.nextInt(3) == 0;
  final ratio = neg ? Rat(-1, k) : Rat(1, k);
  final sum = Rat(a) / (Rat(1) - ratio);
  return GenQ(
    prompt: '初項 $a、公比 $ratio の無限等比級数の和は？',
    answer: '$sum',
    wrong: [
      '${Rat(a) / (Rat(1) + ratio)}',
      '${Rat(a) * ratio}',
      '${Rat(a) / ratio}',
      '${sum + Rat(1)}'
    ],
    explanation: '|公比|<1 なので収束し、和＝初項/(1−公比)＝$sum',
  );
}

// ---------------- 数学A：整数 ----------------

GenQ? _gcdLcm(Random r) {
  final g = r.range(2, 12);
  var a = r.range(2, 12), b = r.range(2, 12);
  if (gcd(a, b) != 1 || a == b) return null;
  a *= g;
  b *= g;
  final isLcm = r.nextBool();
  final ans = isLcm ? lcm(a, b) : gcd(a, b);
  return GenQ(
    prompt: '$a と $b の${isLcm ? '最小公倍数' : '最大公約数'}は？',
    answer: '$ans',
    wrong: [
      '${isLcm ? gcd(a, b) : lcm(a, b)}',
      '${a * b}',
      '${ans * 2}',
      '${isLcm ? ans ~/ 2 : ans + g}'
    ],
    explanation: '最大公約数 ${gcd(a, b)}、最小公倍数＝$a×$b÷${gcd(a, b)}＝${lcm(a, b)}',
  );
}

GenQ? _divisorCount(Random r) {
  final nn = r.range(12, 360);
  var cnt = 0, sum = 0;
  for (var d = 1; d <= nn; d++) {
    if (nn % d == 0) {
      cnt++;
      sum += d;
    }
  }
  if (cnt < 4) return null;
  final askSum = r.nextInt(3) == 0;
  final ans = askSum ? sum : cnt;
  return GenQ(
    prompt: '$nn の正の約数の${askSum ? '総和' : '個数'}は？',
    answer: '$ans',
    wrong: [
      '${ans + 1}',
      '${ans - 1}',
      '${ans + 2}',
      '${askSum ? sum - nn : cnt * 2}'
    ],
    explanation: '素因数分解して、${askSum ? '(1+p+…)(1+q+…) の積' : '(指数+1) の積'}。',
  );
}

GenQ? _modPow(Random r) {
  final a = r.range(2, 9),
      nn = r.range(10, 100),
      m = r.pick([3, 4, 5, 6, 7, 9, 10, 11]);
  if (a % m == 0) return null;
  var v = 1;
  for (var i = 0; i < nn; i++) {
    v = v * a % m;
  }
  final asDigit = m == 10;
  return GenQ(
    prompt: asDigit
        ? '$a${Fmt.sup(nn)} の一の位の数は？'
        : '$a${Fmt.sup(nn)} を $m で割った余りは？',
    answer: '$v',
    wrong: [
      for (var i = 0; i < m; i++)
        if (i != v) '$i'
    ],
    explanation: '$a の累乗を $m で割った余りは周期的にくり返す。',
  );
}

String _toBase(int v, int base) {
  if (v == 0) return '0';
  final ds = <int>[];
  while (v > 0) {
    ds.add(v % base);
    v ~/= base;
  }
  return ds.reversed.join();
}

GenQ? _baseConv(Random r) {
  final base = r.pick([2, 2, 2, 3, 5, 8]);
  final v = r.range(5, base == 2 ? 63 : 200);
  final s = _toBase(v, base);
  if (r.nextBool()) {
    return GenQ(
      prompt: '$base 進法で $s（$base）と表される数を10進法で表すと？',
      answer: '$v',
      wrong: ['${v + 1}', '${v - 1}', s, '${v + base}', '${v * 2}'],
      explanation: '各位の数に $base の累乗をかけてたす。',
    );
  }
  return GenQ(
    prompt: '10進法の $v を $base 進法で表すと？',
    answer: '$s（$base）',
    wrong: [
      '${_toBase(v + 1, base)}（$base）',
      '${_toBase(v - 1, base)}（$base）',
      '${s.split('').reversed.join()}（$base）',
      '${_toBase(v + base, base)}（$base）',
    ],
    explanation: '$base で割った余りを下から並べる。',
  );
}

GenQ? _weekday(Random r) {
  const days = ['月', '火', '水', '木', '金', '土', '日'];
  final d = r.nextInt(7), nn = r.range(10, 400);
  final ans = days[(d + nn) % 7];
  return GenQ(
    prompt: '今日が${days[d]}曜日のとき、$nn日後は何曜日？',
    answer: '$ans曜日',
    wrong: [
      for (final x in days)
        if (x != ans) '$x曜日'
    ],
    explanation: '$nn を7で割った余りは ${nn % 7}。',
  );
}

/// ax+by=c を満たす整数の組
GenQ? _diophantine(Random r) {
  final a = r.range(2, 11), b = r.range(2, 11);
  if (gcd(a, b) != 1) return null;
  final x0 = r.range(-6, 6), y0 = r.range(-6, 6);
  final c = a * x0 + b * y0;
  String pair(int x, int y) => '(${_n(x)}, ${_n(y)})';
  final wrong = <String>[];
  for (final (dx, dy) in [
    (1, 0),
    (0, 1),
    (-1, 1),
    (1, -1),
    (0, -1),
    (2, -1),
    (1, 1)
  ]) {
    final x = x0 + dx, y = y0 + dy;
    if (a * x + b * y != c) wrong.add(pair(x, y));
  }
  return GenQ(
    prompt: '方程式 ${a}x+${b}y=${_n(c)} を満たす整数の組 (x, y) はどれ？',
    answer: pair(x0, y0),
    wrong: wrong,
    explanation: '$a×${_pn(x0)}+$b×${_pn(y0)}＝${_n(c)}',
  );
}

// ---------------- 数学A：場合の数と確率 ----------------

int _perm(int n, int k) {
  var v = 1;
  for (var i = 0; i < k; i++) {
    v *= n - i;
  }
  return v;
}

int _fact(int n) => n <= 1 ? 1 : n * _fact(n - 1);

GenQ? _permComb(Random r) {
  final nn = r.range(4, 10), k = r.range(2, min(4, nn - 1));
  final isP = r.nextBool();
  final ans = isP ? _perm(nn, k) : _choose(nn, k);
  return GenQ(
    prompt: '${_sub(nn)}${isP ? 'P' : 'C'}${_sub(k)} の値は？',
    answer: '$ans',
    wrong: [
      '${isP ? _choose(nn, k) : _perm(nn, k)}',
      '${nn * k}',
      '${ans + nn}',
      '${_fact(k)}'
    ],
    explanation: isP ? '$nn から始めて $k 個かける。' : '${_sub(nn)}P${_sub(k)}÷$k!',
  );
}

GenQ? _circular(Random r) => _countWords(r, 0);
GenQ? _paths(Random r) => _countWords(r, 1);
GenQ? _committee(Random r) => _countWords(r, 2);
GenQ? _officers(Random r) => _countWords(r, 3);

GenQ? _countWords(Random r, int kind) {
  if (kind == 0) {
    final nn = r.range(4, 8);
    return GenQ(
      prompt: '$nn人が円形に並ぶ方法は何通り？',
      answer: '${_fact(nn - 1)}',
      wrong: [
        '${_fact(nn)}',
        '${_fact(nn - 1) ~/ 2}',
        '${_fact(nn - 2)}',
        '${nn * nn}'
      ],
      explanation: '円順列は (n−1)!＝${nn - 1}!',
      category: QuestionCategory.thinking,
    );
  }
  if (kind == 1) {
    final a = r.range(2, 6), b = r.range(2, 5);
    return GenQ(
      prompt: '右に$a区画、上に$b区画進む最短経路は何通り？',
      answer: '${_choose(a + b, a)}',
      wrong: [
        '${a * b}',
        '${_perm(a + b, a)}',
        '${_choose(a + b, a) + 1}',
        '${a + b}'
      ],
      explanation: '右 $a 個と上 $b 個の並べ方：${_sub(a + b)}C${_sub(a)}',
      category: QuestionCategory.thinking,
    );
  }
  if (kind == 2) {
    final nn = r.range(5, 10), k = r.range(2, 4);
    return GenQ(
      prompt: '$nn人から$k人の委員を選ぶ方法は何通り？',
      answer: '${_choose(nn, k)}',
      wrong: [
        '${_perm(nn, k)}',
        '${nn * k}',
        '${_choose(nn, k - 1)}',
        '${_choose(nn, k) * 2}'
      ],
      explanation: '${_sub(nn)}C${_sub(k)}＝${_choose(nn, k)}',
      category: QuestionCategory.thinking,
    );
  }
  final nn = r.range(4, 9), k = r.range(2, 3);
  return GenQ(
    prompt: '$nn人から委員長と副委員長${k == 3 ? 'と書記' : ''}を1人ずつ選ぶ方法は何通り？',
    answer: '${_perm(nn, k)}',
    wrong: [
      '${_choose(nn, k)}',
      '${nn * k}',
      '${_perm(nn, k - 1)}',
      '${pow(nn, k).toInt()}'
    ],
    explanation: '役割が区別されるので順列：${_sub(nn)}P${_sub(k)}',
    category: QuestionCategory.thinking,
  );
}

GenQ? _diceProb(Random r) => _prob(r, r.nextInt(2));
GenQ? _independent(Random r) => _prob(r, 2);

GenQ? _prob(Random r, int kind) {
  if (kind == 0) {
    final s = r.range(2, 12);
    var c = 0;
    for (var a = 1; a <= 6; a++) {
      for (var b = 1; b <= 6; b++) {
        if (a + b == s) c++;
      }
    }
    final v = Rat(c, 36);
    return GenQ(
      prompt: '2個のさいころを投げるとき、出た目の和が $s になる確率は？',
      answer: '$v',
      wrong: [
        '${Rat(c + 1, 36)}',
        '${Rat(1, 6)}',
        '${Rat(c, 12)}',
        '${Rat(max(c - 1, 1) + 1, 18)}'
      ],
      explanation: '36通りのうち和が $s になるのは $c 通り。',
    );
  }
  if (kind == 1) {
    final nn = r.range(2, 5), k = r.range(0, nn);
    final v = Rat(_choose(nn, k), pow(2, nn).toInt());
    return GenQ(
      prompt: 'コインを$nn回投げるとき、表がちょうど$k回出る確率は？',
      answer: '$v',
      wrong: [
        '${Rat(k, nn)}',
        '${Rat(1, pow(2, nn).toInt())}',
        '${Rat(_choose(nn, k) + 1, pow(2, nn).toInt())}',
        '${Rat(1, 2)}'
      ],
      explanation: '${_sub(nn)}C${_sub(k)}×(1/2)${Fmt.sup(nn)}',
    );
  }
  final k = r.range(2, 4);
  final v = Rat(1, pow(6, k).toInt());
  return GenQ(
    prompt: 'さいころを$k回投げるとき、$k回とも6の目が出る確率は？',
    answer: '$v',
    wrong: [
      '${Rat(k, 6)}',
      '${Rat(1, 6 * k)}',
      '${Rat(1, 6)}',
      '${Rat(1, pow(6, k - 1).toInt())}'
    ],
    explanation: '独立な試行なので (1/6)${Fmt.sup(k)}',
  );
}

// ---------------- 数学B：数列 ----------------

GenQ? _arith(Random r) {
  final a = r.range(-10, 20), d = r.nonZero(-5, 6), nn = r.range(5, 30);
  if (r.nextBool()) {
    final an = a + (nn - 1) * d;
    return GenQ(
      prompt: '初項 ${_n(a)}、公差 ${_n(d)} の等差数列の第$nn項は？',
      answer: _n(an),
      wrong: [_n(a + nn * d), _n(an - d * 2), _n(a * nn), _n(an + 1)],
      explanation: 'aₙ＝a+(n−1)d＝${_n(a)}+${nn - 1}×${_pn(d)}',
    );
  }
  final s = nn * (2 * a + (nn - 1) * d) ~/ 2;
  return GenQ(
    prompt: '初項 ${_n(a)}、公差 ${_n(d)} の等差数列の、初項から第$nn項までの和は？',
    answer: _n(s),
    wrong: [
      _n(s + d),
      _n(nn * (2 * a + nn * d) ~/ 2),
      _n(a + (nn - 1) * d),
      _n(s - a)
    ],
    explanation: 'Sₙ＝n{2a+(n−1)d}/2',
  );
}

GenQ? _geom(Random r) {
  final a = r.range(1, 5) * (r.nextBool() ? 1 : -1),
      q = r.pick([2, 3, -2, -3]),
      nn = r.range(3, 8);
  final an = a * pow(q, nn - 1).toInt();
  if (r.nextBool()) {
    return GenQ(
      prompt: '初項 ${_n(a)}、公比 ${_n(q)} の等比数列の第$nn項は？',
      answer: _n(an),
      wrong: [
        _n(a * pow(q, nn).toInt()),
        _n(a * q * (nn - 1)),
        _n(-an),
        _n(a * pow(q, nn - 2).toInt())
      ],
      explanation: 'aₙ＝a·r${Fmt.sup(nn - 1)}',
    );
  }
  final s = a * (pow(q, nn).toInt() - 1) ~/ (q - 1);
  return GenQ(
    prompt: '初項 ${_n(a)}、公比 ${_n(q)} の等比数列の、初項から第$nn項までの和は？',
    answer: _n(s),
    wrong: [
      _n(an),
      _n(a * (pow(q, nn + 1).toInt() - 1) ~/ (q - 1)),
      _n(-s),
      _n(s + a)
    ],
    explanation: 'Sₙ＝a(rⁿ−1)/(r−1)',
  );
}

GenQ? _sigma(Random r) {
  final nn = r.range(5, 30);
  final kind = r.nextInt(3);
  final (expr, v, f) = switch (kind) {
    0 => ('k', nn * (nn + 1) ~/ 2, 'n(n+1)/2'),
    1 => ('k²', nn * (nn + 1) * (2 * nn + 1) ~/ 6, 'n(n+1)(2n+1)/6'),
    _ => ('k³', pow(nn * (nn + 1) ~/ 2, 2).toInt(), '{n(n+1)/2}²'),
  };
  return GenQ(
    prompt: 'Σ_{k=1}^{$nn} $expr の値は？',
    answer: '$v',
    wrong: ['${v + nn}', '${v - nn}', '${nn * nn}', '${v * 2}'],
    explanation: 'Σ$expr＝$f に n＝$nn',
  );
}

GenQ? _recurrence(Random r) {
  final a1 = r.range(-3, 5),
      p = r.pick([2, 3, -1, 2]),
      q = r.range(-4, 5),
      nn = r.range(3, 6);
  var v = a1;
  for (var i = 1; i < nn; i++) {
    v = p * v + q;
  }
  final pq = p == 1
      ? 'aₙ'
      : p == -1
          ? '−aₙ'
          : '${_n(p)}aₙ';
  return GenQ(
    prompt:
        'a₁=${_n(a1)}、aₙ₊₁=$pq${q > 0 ? '+$q' : q < 0 ? '−${-q}' : ''} で定められる数列の第$nn項は？',
    answer: _n(v),
    wrong: [_n(v + q), _n(p * v + q), _n(v - 1), _n(v ~/ (p == 0 ? 1 : p))],
    explanation: '順に計算していく。',
  );
}

// ---------------- 数学C：ベクトル・行列・複素数平面 ----------------

String _vec(List<int> v) => '(${v.map(_n).join(', ')})';

GenQ? _vec2(Random r) => _vecOps(r, 2, r.nextInt(3));
GenQ? _vec2Add(Random r) => _vecOps(r, 2, 0);
GenQ? _vec2Dot(Random r) => _vecOps(r, 2, 1);
GenQ? _vec3(Random r) => _vecOps(r, 3, r.nextInt(3));

GenQ? _vecOps(Random r, int dim, int kind) {
  final a = [for (var i = 0; i < dim; i++) r.range(-5, 5)];
  final b = [for (var i = 0; i < dim; i++) r.range(-5, 5)];
  if (kind == 0) {
    final s = r.range(2, 3);
    final res = [for (var i = 0; i < dim; i++) a[i] + s * b[i]];
    return GenQ(
      prompt: 'a=${_vec(a)}、b=${_vec(b)} のとき、a+${s}b は？',
      answer: _vec(res),
      wrong: [
        _vec([for (var i = 0; i < dim; i++) a[i] + b[i]]),
        _vec([for (var i = 0; i < dim; i++) s * a[i] + b[i]]),
        _vec([for (var i = 0; i < dim; i++) a[i] - s * b[i]]),
        _vec([for (var i = 0; i < dim; i++) res[i] + 1]),
      ],
      explanation: '成分ごとに計算する。',
    );
  }
  if (kind == 1) {
    final dot =
        [for (var i = 0; i < dim; i++) a[i] * b[i]].reduce((x, y) => x + y);
    return GenQ(
      prompt: 'a=${_vec(a)}、b=${_vec(b)} のとき、内積 a·b は？',
      answer: _n(dot),
      wrong: [
        _n(-dot),
        _n(dot + 1),
        _vec([for (var i = 0; i < dim; i++) a[i] * b[i]]),
        _n(a.reduce((x, y) => x + y) * b.reduce((x, y) => x + y))
      ],
      explanation: '同じ成分どうしをかけてたす。',
    );
  }
  final sq = a.fold(0, (t, x) => t + x * x);
  if (sq == 0) return null;
  return GenQ(
    prompt: 'ベクトル ${_vec(a)} の大きさは？',
    answer: Fmt.sqrt(sq),
    wrong: [
      Fmt.sqrt(sq + 1),
      '$sq',
      '${a.fold(0, (t, x) => t + x.abs())}',
      Fmt.sqrt(sq + 2)
    ],
    explanation: '√(成分の2乗の和)＝√$sq',
  );
}

GenQ? _matrix(Random r) {
  List<int> m() => [for (var i = 0; i < 4; i++) r.range(-4, 5)];
  String f(List<int> x) =>
      '[[${_n(x[0])}, ${_n(x[1])}], [${_n(x[2])}, ${_n(x[3])}]]';
  final a = m();
  if (r.nextBool()) {
    final det = a[0] * a[3] - a[1] * a[2];
    return GenQ(
      prompt: '行列 ${f(a)} の ad−bc の値は？',
      answer: _n(det),
      wrong: [
        _n(a[0] * a[3] + a[1] * a[2]),
        _n(-det),
        _n(a[0] * a[1] - a[2] * a[3]),
        _n(det + 1)
      ],
      explanation: '${_pn(a[0])}×${_pn(a[3])}−${_pn(a[1])}×${_pn(a[2])}',
    );
  }
  final b = m();
  final p = [
    a[0] * b[0] + a[1] * b[2], a[0] * b[1] + a[1] * b[3], //
    a[2] * b[0] + a[3] * b[2], a[2] * b[1] + a[3] * b[3],
  ];
  final q = [
    b[0] * a[0] + b[1] * a[2], b[0] * a[1] + b[1] * a[3], //
    b[2] * a[0] + b[3] * a[2], b[2] * a[1] + b[3] * a[3],
  ];
  return GenQ(
    prompt: '${f(a)}·${f(b)} を計算すると？',
    answer: f(p),
    wrong: [
      f(q),
      f([for (var i = 0; i < 4; i++) a[i] * b[i]]),
      f([p[0], p[2], p[1], p[3]]),
      f([p[0] + 1, p[1], p[2], p[3]])
    ],
    explanation: '(行)×(列) の和で各成分を求める。',
  );
}

GenQ? _cxAbs(Random r) {
  final a = r.range(-6, 6), b = r.nonZero(-6, 6);
  final kind = r.nextBool();
  if (kind) {
    return GenQ(
      prompt: '複素数 z=${_cx(a, b)} の絶対値 |z| は？',
      answer: Fmt.sqrt(a * a + b * b),
      wrong: [
        Fmt.sqrt(a * a + b * b + 1),
        '${a.abs() + b.abs()}',
        '${a * a + b * b}',
        Fmt.sqrt((a * a - b * b).abs() + 1)
      ],
      explanation: '|a+bi|＝√(a²+b²)',
    );
  }
  return GenQ(
    prompt: 'z=${_cx(a, b)} の共役な複素数は？',
    answer: _cx(a, -b),
    wrong: [_cx(-a, b), _cx(-a, -b), _cx(b, a), _cx(a, b + 1)],
    explanation: '虚部の符号を変える。',
  );
}

GenQ? _spaceSym(Random r) {
  final p = [r.range(-6, 6), r.range(-6, 6), r.range(-6, 6)];
  if (p.contains(0)) return null;
  final plane = r.pick(['xy 平面', 'yz 平面', 'zx 平面', '原点']);
  final res = switch (plane) {
    'xy 平面' => [p[0], p[1], -p[2]],
    'yz 平面' => [-p[0], p[1], p[2]],
    'zx 平面' => [p[0], -p[1], p[2]],
    _ => [-p[0], -p[1], -p[2]],
  };
  return GenQ(
    prompt: '点 ${_vec(p)} の$planeに関して対称な点は？',
    answer: _vec(res),
    wrong: [
      _vec([p[0], p[1], -p[2]]),
      _vec([-p[0], p[1], p[2]]),
      _vec([p[0], -p[1], p[2]]),
      _vec([-p[0], -p[1], -p[2]]),
      _vec([-p[0], -p[1], p[2]]),
    ],
    explanation:
        '$planeに関して対称：${plane == '原点' ? 'すべての座標の符号を変える' : '平面にない座標の符号を変える'}。',
    category: QuestionCategory.thinking,
  );
}

// ---------------- 数学A：図形 ----------------

GenQ? _polyhedron(Random r) {
  final solids = <(String, int, int, int)>[
    ('正四面体', 4, 6, 4), ('立方体', 8, 12, 6), ('正八面体', 6, 12, 8), //
    ('正十二面体', 20, 30, 12), ('正二十面体', 12, 30, 20),
    for (var n = 3; n <= 10; n++) ('$n角柱', 2 * n, 3 * n, n + 2),
    for (var n = 3; n <= 10; n++) ('$n角錐', n + 1, 2 * n, n + 1),
  ];
  final (name, v, e, f) = r.pick(solids);
  final ask = r.nextInt(3);
  final ans = [v, e, f][ask];
  final label = ['頂点', '辺', '面'][ask];
  return GenQ(
    prompt: '$nameの$labelの数は？',
    answer: '$ans',
    wrong: [
      '${ans + 1}',
      '${ans + 2}',
      '${ans - 1}',
      '${[v, e, f][(ask + 1) % 3]}',
      '${ans * 2}'
    ],
    explanation: '$name：頂点 $v、辺 $e、面 $f（$v−$e+$f＝2）',
    category: QuestionCategory.knowledge,
  );
}

GenQ? _powerPoint(Random r) {
  final pa = r.range(2, 9), pb = r.range(2, 12), pc = r.range(2, 9);
  final pd = Rat(pa * pb, pc);
  return GenQ(
    prompt: '円の2つの弦 AB、CD が点 P で交わる。PA=$pa、PB=$pb、PC=$pc のとき、PD は？',
    answer: '$pd',
    wrong: [
      '${Rat(pa * pc, pb)}',
      '${Rat(pb * pc, pa)}',
      '${pd + Rat(1)}',
      '${Rat(pa + pb - pc)}'
    ],
    explanation: '方べきの定理 PA·PB＝PC·PD より PD＝$pa×$pb÷$pc',
  );
}

GenQ? _bisector(Random r) {
  final ab = r.range(3, 10), ac = r.range(3, 10), bc = r.range(3, 12);
  if (ab + ac <= bc || ab + bc <= ac || ac + bc <= ab || ab == ac) return null;
  final bd = Rat(bc * ab, ab + ac);
  return GenQ(
    prompt: '△ABC で AB=$ab、AC=$ac、BC=$bc。∠A の二等分線と BC の交点を D とするとき、BD は？',
    answer: '$bd',
    wrong: [
      '${Rat(bc * ac, ab + ac)}',
      '${Rat(bc, 2)}',
      '${bd + Rat(1)}',
      '${Rat(ab * ac, bc)}'
    ],
    explanation: 'BD:DC＝AB:AC＝$ab:$ac より BD＝$bc×$ab/${ab + ac}',
  );
}

// ---------------- 数学B：統計 ----------------

GenQ? _binomDist(Random r) {
  final nn = r.pick([10, 20, 50, 100, 200, 400]);
  final p = Rat(r.range(1, 9), 10);
  final e = Rat(nn) * p;
  final v = e * (Rat(1) - p);
  final askVar = r.nextBool();
  return GenQ(
    prompt: '二項分布 B($nn, ${_dec(p)}) に従う確率変数 X の${askVar ? '分散' : '期待値'}は？',
    answer: _decOrFrac(askVar ? v : e),
    wrong: [
      _decOrFrac(askVar ? e : v),
      _decOrFrac(Rat(nn) * (Rat(1) - p)),
      _decOrFrac((askVar ? v : e) + Rat(1)),
      _decOrFrac(p)
    ],
    explanation: 'E(X)＝np＝${_decOrFrac(e)}、V(X)＝np(1−p)＝${_decOrFrac(v)}',
  );
}

GenQ? _linearRv(Random r) {
  final e = r.range(-5, 9),
      v = r.range(1, 9),
      a = r.nonZero(-4, 4),
      b = r.range(-6, 6);
  if (a == 1 || b == 0) return null;
  final ans = 'E(Y)=${_n(a * e + b)}、V(Y)=${a * a * v}';
  return GenQ(
    prompt: '確率変数 X の期待値が ${_n(e)}、分散が $v のとき、Y=${_p([
          a,
          b
        ]).replaceAll('x', 'X')} の期待値と分散は？',
    answer: ans,
    wrong: [
      'E(Y)=${_n(a * e + b)}、V(Y)=${a * v + b}',
      'E(Y)=${_n(a * e)}、V(Y)=${a * a * v}',
      'E(Y)=${_n(a * e + b)}、V(Y)=${a * v}',
      'E(Y)=${_n(e + b)}、V(Y)=${a * a * v}',
    ],
    explanation: 'E(aX+b)＝aE(X)+b、V(aX+b)＝a²V(X)',
  );
}

String _dec(Rat q) {
  // 分母が 10 の約数なら小数
  if (10 % q.den == 0) {
    final v = q.num * (10 ~/ q.den);
    final s = (v.abs() / 10).toStringAsFixed(1);
    return v < 0 ? '−$s' : s;
  }
  return '$q';
}

String _decOrFrac(Rat q) {
  if (q.isInt) return '$q';
  for (final d in [10, 100]) {
    if (d % q.den == 0) {
      final v = q.num * (d ~/ q.den);
      final s = (v.abs() / d).toStringAsFixed(d == 10 ? 1 : 2);
      return v < 0 ? '−$s' : s;
    }
  }
  return '$q';
}

/// 単元 → 作り方
final Map<String, List<Gen>> mathGens = {
  // 数学Ⅰ
  'math.m1.numexpr.poly': [_expand, _monomial],
  'math.m1.numexpr.poly.expand': [_expand, _cube],
  'math.m1.numexpr.poly.factor': [_factorMonic, _factorSquares],
  'math.m1.numexpr.poly.factor_adv': [_factorAdv],
  'math.m1.numexpr.ineq1': [_ineq1, _absIneq],
  'math.m1.numexpr.ineq1.solve': [_ineq1],
  'math.m1.numexpr.ineq1.property': [_ineq1],
  'math.m1.numexpr.ineq1.absineq': [_absEq, _absIneq],
  'math.m1.numexpr.real.absolute': [_absValue],
  'math.m1.numexpr.real.sqrt': [_sqrtSimplify, _rationalize],
  'math.m1.quad.graph.vertex': [_vertex],
  'math.m1.quad.maxmin.basic': [_quadMinMax, _vertex],
  'math.m1.quad.eqineq.discriminant': [_discriminantCount],
  'math.m1.quad.eqineq.equation': [_quadSolve],
  'math.m1.quad.eqineq.inequality': [_quadIneq],
  'math.m1.data.stats.center': [_mean, _median],
  'math.m1.data.stats.spread': [_range, _iqr],
  'math.m1.data.stats.variance': [_variance],
  'math.m1.trig.ratio.define': [_trigValue],
  'math.m1.trig.ratio.obtuse': [_trigValue, _trigEquation],
  'math.m1.trig.ratio.equation': [_trigEquation],
  'math.m1.trig.solve': [_cosineRule, _triArea],
  'math.m1.trig.solve.area': [_triArea],
  'math.m1.trig.solve.cosine': [_cosineRule],
  // 数学Ⅱ
  'math.m2.coord.lines.distance': [_pointLine, _twoPoints],
  'math.m2.coord.lines.point': [_midpoint, _centroid, _twoPoints],
  'math.m2.coord.circles.equation': [_circle],
  'math.m2.explog.exp': [_expValue],
  'math.m2.explog.exp.rational': [_expValue],
  'math.m2.explog.exp.equation': [_expEquation],
  'math.m2.explog.log': [_logValue],
  'math.m2.explog.log.base': [_logValue],
  'math.m2.explog.log.property': [_logValue],
  'math.m2.expr.complex': [_cxMul, _iPower],
  'math.m2.expr.complex.complex': [_iPower, _cxMul],
  'math.m2.expr.complex.discriminant': [_solutionKind],
  'math.m2.expr.complex.vieta': [_vieta],
  'math.m2.expr.complex.remainder': [_remainder],
  'math.m2.expr.proof': [_expand, _cube],
  'math.m2.expr.proof.binomial': [_binomial],
  'math.m2.expr.proof.division': [_division],
  'math.m2.expr.proof.inequality': [_amgm],
  'math.m2.trigfunc.addition.maxmin': [_synthMax],
  'math.m2.trigfunc.general.graph': [_period],
  'math.m2.trigfunc.general.radian': [_radian],
  'math.m2.calculus.diff.limit': [_diffCoef],
  'math.m2.calculus.diff.tangent': [_tangent],
  'math.m2.calculus.integ.definite': [_definite],
  'math.m2.calculus.integ.indefinite': [_definite],
  'math.m2.calculus.integ.area': [_parabolaArea],
  // 数学Ⅲ
  'math.m3.diff.derivative': [_derivPower],
  'math.m3.diff.derivative.chain': [_derivChain, _derivTrig, _derivExp],
  'math.m3.diff.derivative.trig': [_derivTrig],
  'math.m3.diff.derivative.explog': [_derivExp],
  'math.m3.diff.derivative.higher': [_derivPoly],
  'math.m3.integ.method': [_integPower],
  'math.m3.limit.func.function': [_limitSin],
  'math.m3.limit.func.trig': [_limitSin],
  'math.m3.limit.seq': [_geomSeries],
  'math.m3.limit.seq.series': [_geomSeries],
  // 数学A
  'math.ma.integer.divisor.divisor': [_gcdLcm, _divisorCount],
  'math.ma.integer.divisor.gcd': [_gcdLcm],
  'math.ma.integer.divisor.remainder': [_modPow],
  'math.ma.integer.divisor': [_diophantine, _gcdLcm],
  'math.ma.integer.euclid.diophantine': [_diophantine],
  'math.ma.integer.base.nary': [_baseConv],
  'math.ma.integer.base.activity': [_weekday],
  'math.ma.prob.count': [_permComb],
  'math.ma.prob.count.permutation': [_permComb, _officers],
  'math.ma.prob.count.combination': [_committee, _permComb],
  'math.ma.prob.count.circular': [_circular],
  'math.ma.prob.count.same': [_paths],
  'math.ma.prob.probability.basic': [_diceProb],
  'math.ma.prob.probability.independent': [_independent],
  'math.ma.geometry.construct.polyhedron': [_polyhedron],
  'math.ma.geometry.circle.power': [_powerPoint],
  'math.ma.geometry.triangle.bisector': [_bisector],
  // 数学B
  'math.mb.seq.arith': [_arith, _sigma],
  'math.mb.seq.arith.arithmetic': [_arith],
  'math.mb.seq.arith.geometric': [_geom],
  'math.mb.seq.sum.sigma': [_sigma],
  'math.mb.seq.recur': [_recurrence],
  'math.mb.stat.random.binomial': [_binomDist],
  'math.mb.stat.random.linear': [_linearRv],
  // 数学C
  'math.mc.vector.plane': [_vec2],
  'math.mc.vector.plane.operation': [_vec2Add],
  'math.mc.vector.plane.inner': [_vec2Dot],
  'math.mc.vector.space': [_vec3],
  'math.mc.vector.space.vector': [_vec3],
  'math.mc.vector.space.figure': [_spaceSym],
  'math.mc.express.express': [_matrix],
  'math.mc.express.express.matrix': [_matrix],
  'math.mc.curve.complex.plane': [_cxAbs],
};
