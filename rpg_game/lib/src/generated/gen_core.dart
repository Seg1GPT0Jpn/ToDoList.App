import 'dart:math';

import '../models/question.dart';

/// 自動でつくる1問（答えは計算や表から出すので、まちがいが入らない）
class GenQ {
  const GenQ({
    required this.prompt,
    required this.answer,
    required this.wrong,
    required this.explanation,
    this.category = QuestionCategory.calculation,
  });

  final String prompt;
  final String answer;

  /// まちがいの候補（多めに渡してよい。正解と同じもの・重複は捨てる）
  final List<String> wrong;
  final String explanation;
  final QuestionCategory category;
}

/// 問題のつくり方。つくれなかったら null（別の乱数でやり直す）
typedef Gen = GenQ? Function(Random r);

/// 数・式の書き方（アプリの問題と同じ表記：マイナスは「−」、累乗は上付き）
abstract final class Fmt {
  static const _sup = {
    '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', //
    '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
  };

  /// 整数（負の数は「−」）
  static String n(int v) => v < 0 ? '−${-v}' : '$v';

  /// 上付きの数（2 → ²）
  static String sup(int e) => '$e'.split('').map((c) => _sup[c]!).join();

  /// 文字の累乗（x、x²…）。[e] が0なら空
  static String pow(String v, int e) => e == 0
      ? ''
      : e == 1
          ? v
          : '$v${sup(e)}';

  /// 多項式。[coef] は次数の高い順（[1, −3, 2] → x²−3x+2）
  static String poly(List<int> coef, [String v = 'x']) {
    final deg = coef.length - 1;
    final b = StringBuffer();
    for (var i = 0; i < coef.length; i++) {
      final c = coef[i];
      if (c == 0) continue;
      final e = deg - i;
      final abs = c.abs();
      final body = e == 0
          ? '$abs'
          : abs == 1
              ? pow(v, e)
              : '$abs${pow(v, e)}';
      if (b.isEmpty) {
        b.write(c < 0 ? '−$body' : body);
      } else {
        b.write(c < 0 ? '−$body' : '+$body');
      }
    }
    return b.isEmpty ? '0' : b.toString();
  }

  /// (x+a) の形（a=0 なら x）
  static String linear(int a, [String v = 'x']) =>
      a == 0 ? v : (a > 0 ? '$v+$a' : '$v−${-a}');

  /// 平方根を簡単にした形（12 → 2√3、9 → 3）
  static String sqrt(int nn, {int coef = 1}) {
    final (k, m) = simplifySqrt(nn);
    final c = coef * k;
    if (m == 1) return n(c);
    if (c == 1) return '√$m';
    if (c == -1) return '−√$m';
    return '${n(c)}√$m';
  }

  /// √nn = k√m（m は平方因数をもたない）
  static (int, int) simplifySqrt(int nn) {
    var k = 1, m = nn;
    for (var f = 2; f * f <= m; f++) {
      while (m % (f * f) == 0) {
        m ~/= f * f;
        k *= f;
      }
    }
    return (k, m);
  }
}

/// 分数（約分ずみ、分母は正）
class Rat {
  factory Rat(int num, [int den = 1]) {
    if (den == 0) throw ArgumentError('分母が0');
    if (den < 0) {
      num = -num;
      den = -den;
    }
    final g = _gcd(num.abs(), den);
    return Rat._(num ~/ g, den ~/ g);
  }
  const Rat._(this.num, this.den);

  final int num;
  final int den;

  static int _gcd(int a, int b) => b == 0 ? (a == 0 ? 1 : a) : _gcd(b, a % b);

  Rat operator +(Rat o) => Rat(num * o.den + o.num * den, den * o.den);
  Rat operator -(Rat o) => Rat(num * o.den - o.num * den, den * o.den);
  Rat operator *(Rat o) => Rat(num * o.num, den * o.den);
  Rat operator /(Rat o) => Rat(num * o.den, den * o.num);
  Rat operator -() => Rat(-num, den);

  bool get isInt => den == 1;
  bool get isZero => num == 0;

  @override
  bool operator ==(Object o) => o is Rat && o.num == num && o.den == den;
  @override
  int get hashCode => Object.hash(num, den);

  /// 3/4、−1/2、5 の形
  @override
  String toString() => den == 1 ? Fmt.n(num) : '${Fmt.n(num)}/$den';
}

int gcd(int a, int b) => b == 0 ? a.abs() : gcd(b, a % b);
int lcm(int a, int b) => a ~/ gcd(a, b) * b;

/// 乱数のおまけ
extension RandomPick on Random {
  /// [lo]〜[hi]（両端を含む）
  int range(int lo, int hi) => lo + nextInt(hi - lo + 1);

  /// 0 以外の [lo]〜[hi]
  int nonZero(int lo, int hi) {
    while (true) {
      final v = range(lo, hi);
      if (v != 0) return v;
    }
  }

  T pick<T>(List<T> xs) => xs[nextInt(xs.length)];
}

/// 環境によらず同じになるハッシュ（FNV-1a 32bit）。問題を毎回同じに作るため
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}
