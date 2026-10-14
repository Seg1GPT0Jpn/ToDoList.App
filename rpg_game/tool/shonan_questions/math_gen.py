"""数学Ⅰ（データの分析／数学Ⅱ 式と証明・複素数と方程式）と数学A（整数）の委員会セットを作る。

  cd rpg_game/tool/shonan_questions && python3 math_gen.py

答えはすべてこのプログラムで計算する（手で数値を書かない）。乱数の種を固定しているので毎回同じ問題になる。
"""
import math
import random
from fractions import Fraction as F
from statistics import median

from common import chunks, frac, make_set, num, sup

R = random.Random(104)


# ---------------- 多項式（係数は低次から） ----------------
def ptrim(p):
    p = [F(c) for c in p]
    while len(p) > 1 and p[-1] == 0:
        p.pop()
    return p


def pmul(a, b):
    out = [F(0)] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            out[i + j] += x * y
    return ptrim(out)


def pdiv(a, b):
    a, b = ptrim(a), ptrim(b)
    q = [F(0)] * max(1, len(a) - len(b) + 1)
    r = a[:]
    while len(r) >= len(b) and any(r):
        k = len(r) - len(b)
        c = r[-1] / b[-1]
        q[k] = c
        for i, y in enumerate(b):
            r[i + k] -= c * y
        r = ptrim(r[:-1]) if len(r) > 1 else [F(0)]
        if len(r) < len(b):
            break
    return ptrim(q), ptrim(r)


def peval(p, x):
    return sum(F(c) * F(x) ** i for i, c in enumerate(p))


def pstr(p, v='x'):
    p = ptrim(p)
    terms = []
    for i in range(len(p) - 1, -1, -1):
        c = p[i]
        if c == 0:
            continue
        mag = abs(c)
        cs = '' if (mag == 1 and i > 0) else frac(mag)
        var = '' if i == 0 else (v if i == 1 else f'{v}{sup(i)}')
        sign = '−' if c < 0 else '+'
        terms.append((sign, f'{cs}{var}'))
    if not terms:
        return '0'
    s = ('−' if terms[0][0] == '−' else '') + terms[0][1]
    for sign, t in terms[1:]:
        s += f' {sign} {t}'
    return s


# ---------------- 複素数 ----------------
def cstr(z):
    a, b = F(z[0]), F(z[1])
    if b == 0:
        return frac(a)
    bi = ('' if abs(b) == 1 else frac(abs(b))) + 'i'
    if a == 0:
        return ('−' if b < 0 else '') + bi
    return f"{frac(a)}{'−' if b < 0 else '+'}{bi}"


def cmul(z, w):
    return (z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0])


def cdiv(z, w):
    d = F(w[0] ** 2 + w[1] ** 2)
    n = cmul(z, (w[0], -w[1]))
    return (F(n[0]) / d, F(n[1]) / d)


K, T, C = 'knowledge', 'thinking', 'calculation'


def nz(lo, hi):
    while True:
        v = R.randint(lo, hi)
        if v:
            return v


# ================= データの分析 =================
def data_items():
    out = []
    for _ in range(14):
        n = R.choice([5, 6, 7, 8, 9])
        xs = [R.randint(2, 20) for _ in range(n)]
        while sum(xs) % n:
            xs[R.randrange(n)] += 1
        m = sum(xs) // n
        s = ', '.join(map(str, xs))
        med = median(xs)
        out.append((C, f'次のデータの平均値を求めよ。 {s}', num(m),
                    [num(F(sum(xs), n - 1).limit_denominator() if sum(xs) % (n - 1) == 0 else m + 1), num(F(med)), num(m - 1), num(m + 2)],
                    f'合計 {sum(xs)} ÷ 個数 {n} ＝ {m}。'))
        srt = sorted(xs)
        out.append((C, f'次のデータの中央値を求めよ。 {s}', num(F(med).limit_denominator()),
                    [num(m) if m != med else num(F(med) + 1), num(F(xs[n // 2])), num(F(srt[n // 2 - 1])), num(F(med) + F(1, 2))],
                    f'小さい順に並べると {", ".join(map(str, srt))}。{"真ん中の値" if n % 2 else "真ん中の2つの平均"}が中央値。'))
        out.append((C, f'次のデータの範囲を求めよ。 {s}', num(max(xs) - min(xs)),
                    [num(max(xs)), num(max(xs) - min(xs) + 1), num(m), num(srt[-2] - srt[1])],
                    f'範囲＝最大値 {max(xs)} − 最小値 {min(xs)}。'))
    # 四分位数・四分位範囲（奇数個は中央値を除いて前半・後半に分ける）
    for _ in range(10):
        n = R.choice([7, 8, 9, 10, 11])
        xs = sorted(R.sample(range(1, 40), n))
        h = n // 2
        lo, hi = xs[:h], xs[n - h:]
        q1, q3 = F(median(lo)).limit_denominator(), F(median(hi)).limit_denominator()
        s = ', '.join(map(str, xs))
        out.append((C, f'次のデータの第1四分位数を求めよ。 {s}', frac(q1),
                    [frac(q3), frac(F(median(xs)).limit_denominator()), frac(F(xs[h // 2 + 1])), frac(q1 + 1)],
                    f'前半 {", ".join(map(str, lo))} の中央値が第1四分位数。'))
        out.append((C, f'次のデータの四分位範囲を求めよ。 {s}', frac(q3 - q1),
                    [frac(max(xs) - min(xs)), frac((q3 - q1) / 2), frac(q3), frac(q3 - q1 + 1)],
                    f'Q₁＝{frac(q1)}、Q₃＝{frac(q3)} なので Q₃−Q₁＝{frac(q3 - q1)}。'))
        out.append((C, f'次のデータの第3四分位数を求めよ。 {s}', frac(q3),
                    [frac(q1), frac(F(xs[-1])), frac(q3 + 1), frac(F(median(xs)).limit_denominator())],
                    f'後半 {", ".join(map(str, hi))} の中央値が第3四分位数。'))
    # 分散・標準偏差（平均が整数になるデータ）
    for _ in range(18):
        n = R.choice([4, 5, 6])
        while True:
            xs = [R.randint(1, 12) for _ in range(n)]
            if sum(xs) % n == 0:
                break
        m = sum(xs) // n
        var = F(sum((x - m) ** 2 for x in xs), n)
        s = ', '.join(map(str, xs))
        out.append((C, f'次のデータの分散を求めよ。 {s}', frac(var),
                    [frac(F(sum((x - m) ** 2 for x in xs), n - 1)), frac(F(sum(abs(x - m) for x in xs), n)), frac(var + 1), frac(F(sum(x * x for x in xs), n))],
                    f'平均 {m}。偏差の2乗の平均＝{sum((x - m) ** 2 for x in xs)}÷{n}＝{frac(var)}。'))
        if var.denominator == 1 and math.isqrt(int(var)) ** 2 == int(var):
            sd = math.isqrt(int(var))
            out.append((C, f'次のデータの標準偏差を求めよ。 {s}', num(sd),
                        [num(int(var)), num(sd + 1), num(F(sd, 2)) if sd % 2 == 0 else num(sd + 2), num(sd * 2)],
                        f'分散 {int(var)} の正の平方根が標準偏差。'))
    for _ in range(8):
        n = R.choice([5, 10, 20])
        m = R.randint(3, 15)
        sq = m * m + R.choice([4, 9, 16, 25])
        out.append((C, f'変量 x のデータの大きさが {n}、平均値が {m}、x² の平均値が {sq} のとき、x の分散は？', num(sq - m * m),
                    [num(sq - m), num(sq + m * m), num(math.isqrt(sq - m * m)), num(sq)],
                    f'分散＝(x²の平均)−(xの平均)²＝{sq}−{m * m}＝{sq - m * m}。'))
    # 変量の変換
    for _ in range(12):
        a, b = R.choice([2, 3, -2, 5, 10, -3]), R.randint(-20, 30)
        m, v = R.randint(2, 30), R.choice([4, 9, 16, 25, 36])
        sd = math.isqrt(v)
        bs = f'+ {b}' if b >= 0 else f'− {-b}'
        out.append((C, f'変量 x の平均値が {m}、分散が {v} である。y ＝ {a}x {bs} のとき、y の平均値は？', num(a * m + b),
                    [num(a * m), num(m + b), num(a * (m + b)), num(a * m - b)], f'平均は ax＋b と同じように変わる：{a}×{m}{bs.replace(" ", "")}。'))
        out.append((C, f'変量 x の平均値が {m}、分散が {v} である。y ＝ {a}x {bs} のとき、y の分散は？', num(a * a * v),
                    [num(a * v), num(a * a * v + b), num(abs(a) * v), num(v)], f'分散は a² 倍（b には影響されない）：{a * a}×{v}。'))
        out.append((C, f'変量 x の標準偏差が {sd} である。y ＝ {a}x {bs} のとき、y の標準偏差は？', num(abs(a) * sd),
                    [num(a * a * sd), num(abs(a) * sd + b) if b else num(abs(a) * sd + 1), num(sd), num(a * sd) if a < 0 else num(sd + b + 2)],
                    f'標準偏差は |a| 倍：|{a}|×{sd}。'))
    # 共分散・相関係数
    pairs = [
        ([1, 2, 3, 4, 5], [2, 4, 5, 4, 5]),
        ([2, 4, 6, 8], [3, 7, 5, 9]),
        ([1, 3, 5, 7, 9], [10, 8, 6, 4, 2]),
        ([3, 5, 7, 9, 11], [6, 4, 8, 10, 12]),
        ([1, 2, 3, 4, 5], [5, 3, 4, 2, 1]),
        ([2, 3, 5, 6], [4, 4, 8, 8]),
    ]
    for xs, ys in pairs:
        n = len(xs)
        mx, my = F(sum(xs), n), F(sum(ys), n)
        cov = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / n
        vx = sum((x - mx) ** 2 for x in xs) / n
        vy = sum((y - my) ** 2 for y in ys) / n
        r = float(cov) / math.sqrt(float(vx) * float(vy))
        tbl = '、'.join(f'({x},{y})' for x, y in zip(xs, ys))
        out.append((C, f'2つの変量 (x, y) のデータ {tbl} の共分散は？', frac(cov),
                    [frac(cov * n / (n - 1)), frac(-cov), frac(cov + 1), frac(vx)], f'偏差の積の平均。x の平均 {frac(mx)}、y の平均 {frac(my)}。'))
        out.append((C, f'2つの変量 (x, y) のデータ {tbl} の相関係数に最も近いものは？', f'{r:.2f}',
                    [f'{-r:.2f}', f'{min(1.0, abs(r) + 0.3) * (1 if r > 0 else -1):.2f}' if abs(r) < 0.69 else f'{r * 0.5:.2f}', '0.00', f'{float(cov):.2f}' if abs(float(cov) - r) > 0.05 else '1.20'],
                    f'r＝共分散÷(xの標準偏差×yの標準偏差)＝{frac(cov)}÷√({frac(vx)}×{frac(vy)})。'))
    for _ in range(10):
        sx, sy = R.choice([2, 3, 4, 5]), R.choice([2, 3, 4, 5, 6])
        r = R.choice([F(1, 2), F(-1, 2), F(3, 5), F(-4, 5), F(1, 4), F(3, 4)])
        cov = r * sx * sy
        out.append((C, f'x の標準偏差が {sx}、y の標準偏差が {sy}、共分散が {frac(cov)} のとき、相関係数は？', frac(r),
                    [frac(cov / (sx + sy)), frac(cov * sx * sy) if abs(cov * sx * sy) != abs(r) else frac(-r), frac(-r), frac(cov / (sx * sx * sy * sy)) if cov / (sx * sx * sy * sy) != r else '1'],
                    f'r＝{frac(cov)}÷({sx}×{sy})＝{frac(r)}。'))
    # 外れ値
    for _ in range(6):
        q1, q3 = R.randint(10, 30), 0
        q3 = q1 + R.choice([8, 10, 12, 20])
        iqr = q3 - q1
        lo, hi = F(q1) - F(3, 2) * iqr, F(q3) + F(3, 2) * iqr
        out.append((C, f'第1四分位数が {q1}、第3四分位数が {q3} のデータで、「Q₃＋1.5×(四分位範囲) 以上」を外れ値とするとき、外れ値とされる値の下限は？',
                    frac(hi), [frac(q3 + iqr), frac(lo), frac(F(q3) + F(3, 2) * q3), frac(hi + iqr)], f'IQR＝{iqr}、{q3}＋1.5×{iqr}＝{frac(hi)}。'))
    out += [
        (K, '中央値と同じ値になるのは？', '第2四分位数', ['第1四分位数', '第3四分位数', '平均値'], 'データを二等分する値。'),
        (K, '箱ひげ図の箱の長さが表すものは？', '四分位範囲', ['範囲', '標準偏差', '平均値'], '箱は Q₁ から Q₃ まで。'),
        (K, 'データの最頻値とは？', '最も個数の多い値', ['真ん中の値', '平均の値', '最大と最小の平均'], 'モードともいう。'),
        (K, '分散の正の平方根を何という？', '標準偏差', ['四分位範囲', '共分散', '相関係数'], '単位がもとのデータと同じになる。'),
        (K, '相関係数 r のとりうる値の範囲は？', '−1 ≦ r ≦ 1', ['0 ≦ r ≦ 1', '−∞ ＜ r ＜ ∞', '0 ≦ r ≦ 100'], '1 に近いほど強い正の相関。'),
        (T, '相関係数が −0.9 の2つの変量の関係として正しいものは？', '一方が増えると他方は減る傾向が強い', ['一方が増えると他方も増える傾向が強い', 'ほとんど関係がない', '因果関係がある'], '強い負の相関。相関は因果を意味しない。'),
        (T, 'ある町でアイスの売上と水難事故の件数に強い正の相関があった。最も適切な解釈は？', '気温という別の要因が両方に影響している可能性がある', ['アイスを食べると水難事故が起きる', '水難事故がアイスの売上を増やす', '相関係数が誤っている'], '相関があっても因果関係とは限らない（第三の変数）。'),
        (T, '平均値が中央値よりかなり大きいデータの分布として考えられるものは？', '大きい方に極端な値があり、右に裾が長い', ['左に裾が長い', '左右対称', 'すべて同じ値'], '外れ値の影響を平均値は受けやすい。'),
        (T, '外れ値の影響を受けにくい代表値は？', '中央値', ['平均値', '範囲', '分散'], '並べたときの順番だけで決まる。'),
        (T, 'すべてのデータに 5 を足すと、分散はどうなる？', '変わらない', ['5 増える', '25 増える', '5 倍になる'], '散らばり方は変わらない。'),
        (T, 'すべてのデータを 3 倍すると、標準偏差はどうなる？', '3 倍になる', ['9 倍になる', '変わらない', '3 増える'], '分散は 9 倍、標準偏差は 3 倍。'),
        (T, '仮説検定で「コインに偏りがない」と仮定し、その仮定のもとで観測した結果が起こる確率が 5% 未満だった。正しい判断は？', '仮定は正しくなかったと判断する（偏りがあると考える）', ['仮定が正しいと証明された', '何も判断できない', '確率が5%なので偏りはない'], '基準（有意水準）より小さければ仮説を棄却する。'),
        (K, '仮説検定で、正しいかどうか判断したい主張に反する仮定を何という？', '帰無仮説', ['対立仮説', '有意水準', '標本'], '帰無仮説を立てて、それが起こりにくいかを調べる。'),
        (T, '2つのクラスのテストの平均点が同じでも、標準偏差が大きいクラスについて言えることは？', '点数のばらつきが大きい', ['平均点が実は高い', '最高点が必ず高い', '人数が多い'], '標準偏差は散らばりの大きさ。'),
        (T, '箱ひげ図で、箱の中の線（中央値）が箱の左端に近いとき言えることは？', 'Q₁ から中央値までの間にデータが密集している', ['データが右に偏っていない', '平均値が中央値より小さい', '四分位範囲が0'], '同じ25%のデータが狭い範囲に入っている。'),
        (T, '散布図で点が右上がりの直線の近くに集まっている。相関係数として最も近いものは？', '0.9', ['−0.9', '0', '−0.3'], '強い正の相関。'),
    ]
    return out


# ================= 式と証明 =================
def proof_items():
    out = []
    # 二項定理の係数
    for _ in range(26):
        n = R.randint(4, 7)
        a, b = R.choice([1, 2, 3, -1, -2]), R.choice([1, 2, 3, -1, -2, -3])
        k = R.randint(1, n - 1)
        c = math.comb(n, k) * a ** k * b ** (n - k)
        if a == 1:
            ax = 'x'
        elif a == -1:
            ax = '−x'
        else:
            ax = f'{a}x'.replace('-', '−')
        bs = f'+ {b}' if b > 0 else f'− {-b}'
        out.append((C, f'({ax} {bs})^{n} の展開式における x{sup(k)} の係数は？'.replace('^' + str(n), sup(n)), num(c),
                    [num(math.comb(n, k)), num(-c), num(math.comb(n, k) * a ** k * b), num(math.comb(n, k - 1) * a ** k * b ** (n - k))],
                    f'一般項は {n}C{k}·({ax}){sup(k)}·({num(b)}){sup(n - k)}。{n}C{k}＝{math.comb(n, k)} なので {math.comb(n, k)}×{num(a ** k)}×{num(b ** (n - k))}＝{num(c)}。'))
    for n in range(3, 9):
        out.append((C, f'二項係数の和 {n}C0＋{n}C1＋…＋{n}C{n} の値は？', num(2 ** n), [num(n * n), num(2 ** n - 1), num(2 ** (n - 1))], f'(1＋1)^{n}＝2^{n}。'.replace('^' + str(n), sup(n))))
    # 3乗の展開・因数分解
    for _ in range(10):
        a = R.randint(1, 4)
        out.append((C, f'(x＋{a})³ を展開すると？', pstr([a ** 3, 3 * a * a, 3 * a, 1]),
                    [pstr([a ** 3, 0, 0, 1]), pstr([a ** 3, a * a, a, 1]), pstr([a ** 3, 3 * a, 3 * a * a, 1])], f'(a＋b)³＝a³＋3a²b＋3ab²＋b³ に a→x, b→{a} を入れて x³＋3·{a}x²＋3·{a}²x＋{a}³＝{pstr([a ** 3, 3 * a * a, 3 * a, 1])}。'))
        out.append((C, f'x³ − {a ** 3} を因数分解すると？', f'(x − {a})(x² ＋ {a}x ＋ {a * a})'.replace(' 1x', ' x'),
                    [f'(x − {a})(x² − {a}x ＋ {a * a})'.replace(' 1x', ' x'), f'(x − {a})³', f'(x ＋ {a})(x² − {a}x ＋ {a * a})'.replace(' 1x', ' x')], f'{a ** 3}＝{a}³ なので a³−b³＝(a−b)(a²＋ab＋b²) を使う（2つめのかっこの真ん中は＋）。'))
    # 整式の割り算
    for _ in range(26):
        q = [R.randint(-4, 4), R.randint(-4, 4), 1] if R.random() < .6 else [R.randint(-4, 4), nz(-3, 3)]
        dv = [nz(-4, 4), 1]
        r = [R.randint(-6, 6)]
        p = [x + y for x, y in zip(pmul(q, dv) + [0] * 3, r + [0] * 5)]
        p = ptrim(p)
        qq, rr = pdiv(p, dv)
        assert pmul(qq, dv)[0] + rr[0] == p[0]
        wrong_q = qq[:]
        wrong_q[0] += 1
        out.append((C, f'{pstr(p)} を {pstr(dv)} で割ったときの商と余りは？', f'商 {pstr(qq)}、余り {pstr(rr)}',
                    [f'商 {pstr(wrong_q)}、余り {pstr([rr[0] - dv[0]])}', f'商 {pstr(qq)}、余り {pstr([-rr[0] + 1])}' if rr[0] != F(1, 2) else '余りなし', f'商 {pstr(pmul(qq, [-1]))}、余り {pstr(rr)}'],
                    f'{pstr(p)}＝({pstr(dv)})({pstr(qq)})＋{pstr(rr)}。'))
    # 恒等式
    for _ in range(14):
        a, b, c = nz(-3, 4), R.randint(-5, 5), R.randint(-5, 5)
        h = nz(-3, 3)
        # a(x−h)²＋b(x−h)＋c を展開
        poly = ptrim([a * h * h - b * h + c, -2 * a * h + b, a])
        hs = f'x − {h}' if h > 0 else f'x ＋ {-h}'
        out.append((C, f'{pstr(poly)} ＝ a({hs})² ＋ b({hs}) ＋ c が x についての恒等式となるとき、c の値は？', num(c),
                    [num(b), num(peval(poly, 0)), num(c + h), num(-c)], f'x＝{h} を代入すると c＝{num(peval(poly, h))}。'))
    # 相加平均・相乗平均
    for k in [4, 9, 16, 25, 36, 49, 64, 81, 100]:
        out.append((C, f'x ＞ 0 のとき、x ＋ {k}/x の最小値は？', num(2 * math.isqrt(k)),
                    [num(math.isqrt(k)), num(k), num(2 * k), num(k + 1)], f'相加平均≧相乗平均より x＋{k}/x ≧ 2√{k}＝{2 * math.isqrt(k)}。等号は x＝{math.isqrt(k)}。'))
    out += [
        (K, '恒等式とは？', '文字にどんな値を代入しても成り立つ等式', ['特定の値のときだけ成り立つ等式', '解が1つだけの方程式', '不等号を含む式'], '係数比較法や数値代入法で係数を決める。'),
        (K, '相加平均と相乗平均の関係として正しいのは？（a＞0, b＞0）', '(a＋b)/2 ≧ √(ab)', ['(a＋b)/2 ≦ √(ab)', 'a＋b ≧ ab', '(a＋b)/2 ＝ √(ab)'], '等号は a＝b のとき。'),
        (K, '整式 A を B で割った商を Q、余りを R とするとき成り立つ式は？', 'A ＝ BQ ＋ R（R の次数＜B の次数）', ['A ＝ BR ＋ Q', 'A ＝ B ＋ QR', 'B ＝ AQ ＋ R'], '余りの次数は割る式より低い。'),
        (T, 'a ＞ 0, b ＞ 0 のとき「a/b ＋ b/a ≧ 2」を証明する方法として最も適切なものは？', '相加平均≧相乗平均を使う', ['a＝b を代入する', '両辺に 0 をかける', '具体的な数を1つ代入する'], 'a/b・b/a＝1 なので相乗平均は1。'),
        (T, '不等式 A ≧ B を証明するときの基本的な方針は？', 'A − B ≧ 0 を示す', ['A＝B を示す', 'A と B に同じ数を代入する', 'A − B ≦ 0 を示す'], '差をとって平方完成などで0以上を示す。'),
        (T, 'x² − 2x ＋ 3 ＞ 0 がすべての実数 x で成り立つ理由は？', '(x − 1)² ＋ 2 ＞ 0 だから', ['x ＞ 0 だから', '判別式が正だから', 'x＝1 で成り立つから'], '平方完成で実数の2乗≧0を使う。'),
        (K, '(a＋b)³ の展開式として正しいのは？', 'a³＋3a²b＋3ab²＋b³', ['a³＋b³', 'a³＋a²b＋ab²＋b³', 'a³＋3ab＋b³'], '3乗の展開公式。'),
        (K, 'a³＋b³ を因数分解すると？', '(a＋b)(a²−ab＋b²)', ['(a＋b)(a²＋ab＋b²)', '(a＋b)³', '(a−b)(a²＋ab＋b²)'], '符号に注意。'),
        (C, 'a＋b＝1 のとき、a²＋b ＝ b²＋a を示すために b を消去すると a² ＋ (1−a) は？', 'a² − a ＋ 1', ['a² ＋ a ＋ 1', 'a² − a − 1', 'a² ＋ 1'], '条件式で1文字消去して両辺を比べる。'),
        (C, '1/(x−1) − 1/(x＋1) を計算すると？', '2/(x²−1)', ['2x/(x²−1)', '−2/(x²−1)', '0'], '通分：{(x＋1)−(x−1)}/(x²−1)。'),
    ]
    return out


# ================= 複素数と方程式 =================
def complex_items():
    out = []
    for _ in range(20):
        z = (nz(-5, 5), nz(-5, 5))
        w = (nz(-4, 4), nz(-4, 4))
        p = cmul(z, w)
        out.append((C, f'({cstr(z)})({cstr(w)}) を計算すると？', cstr(p),
                    [cstr((z[0] * w[0] + z[1] * w[1], p[1])), cstr((p[0], -p[1])), cstr((z[0] * w[0], z[1] * w[1]))], f'展開すると {num(z[0] * w[0])}＋({num(z[0] * w[1])})i＋({num(z[1] * w[0])})i＋({num(z[1] * w[1])})i²。i²＝−1 より 実部 {num(z[0] * w[0])}−({num(z[1] * w[1])})＝{num(p[0])}、虚部 {num(z[0] * w[1] + z[1] * w[0])}。'))
        s = (z[0] - w[0], z[1] - w[1])
        out.append((C, f'({cstr(z)}) − ({cstr(w)}) を計算すると？', cstr(s),
                    [cstr((z[0] + w[0], z[1] + w[1])), cstr((z[0] - w[0], z[1] + w[1])), cstr((z[0] + w[0], z[1] - w[1]))], f'実部 {num(z[0])}−({num(w[0])})＝{num(s[0])}、虚部 {num(z[1])}−({num(w[1])})＝{num(s[1])}。'))
    for _ in range(14):
        z = (nz(-6, 6), nz(-6, 6))
        w = R.choice([(1, 1), (1, -1), (2, 1), (1, 2), (3, -1), (2, -1)])
        q = cdiv(z, w)
        out.append((C, f'({cstr(z)}) ÷ ({cstr(w)}) を計算すると？', cstr(q),
                    [cstr((q[0], -q[1])), cstr((q[1], q[0])), cstr(cdiv(z, (w[0], -w[1])))], f'分母と分子に共役な複素数 {cstr((w[0], -w[1]))} をかける。分母は {w[0]}²＋({num(w[1])})²＝{w[0] ** 2 + w[1] ** 2}、分子は ({cstr(z)})({cstr((w[0], -w[1]))})＝{cstr(cmul(z, (w[0], -w[1])))}。これを {w[0] ** 2 + w[1] ** 2} で割る。'))
    for k in range(3, 23, 2):
        v = [(1, 0), (0, 1), (-1, 0), (0, -1)][k % 4]
        out.append((C, f'i^{k} を計算すると？'.replace('^' + str(k), sup(k)), cstr(v), [cstr(x) for x in [(1, 0), (0, 1), (-1, 0), (0, -1)] if x != v], f'i⁴＝1。{k}＝4×{k // 4}＋{k % 4}。'))
    for _ in range(10):
        a, b = nz(-5, 5), nz(-5, 5)
        z = (a, b)
        out.append((C, f'({cstr(z)})² を計算すると？', cstr(cmul(z, z)),
                    [cstr((a * a + b * b, 2 * a * b)), cstr((a * a, b * b)), cstr((a * a - b * b, -2 * a * b))], f'(a＋bi)²＝a²−b²＋2abi より 実部 ({num(a)})²−({num(b)})²＝{num(a * a - b * b)}、虚部 2×({num(a)})×({num(b)})＝{num(2 * a * b)}。'))
    # 判別式
    for _ in range(18):
        a, b, c = nz(1, 3), R.randint(-8, 8), R.randint(-6, 9)
        d = b * b - 4 * a * c
        kind = '異なる2つの実数解' if d > 0 else ('重解' if d == 0 else '異なる2つの虚数解')
        out.append((C, f'2次方程式 {pstr([c, b, a])} ＝ 0 の解の種類は？', kind,
                    [k for k in ['異なる2つの実数解', '重解', '異なる2つの虚数解', '解なし'] if k != kind], f'判別式 D＝({num(b)})²−4×{a}×({num(c)})＝{num(d)}。'))
    # 解と係数の関係
    for _ in range(18):
        a, b, c = nz(1, 3), nz(-9, 9), nz(-9, 9)
        s, p = F(-b, a), F(c, a)
        eq = f'2次方程式 {pstr([c, b, a])} ＝ 0 の2つの解を α, β とするとき'
        q = R.randrange(4)
        if q == 0:
            out.append((C, f'{eq}、α＋β の値は？', frac(s), [frac(-s), frac(p), frac(F(b, a) * 2 if b else 1)], f'α＋β＝−b/a＝{frac(s)}。'))
        elif q == 1:
            out.append((C, f'{eq}、α²＋β² の値は？', frac(s * s - 2 * p), [frac(s * s + 2 * p), frac(s * s), frac(s * s - p)], f'α²＋β²＝(α＋β)²−2αβ＝{frac(s)}²−2×{frac(p)}。'))
        elif q == 2:
            out.append((C, f'{eq}、1/α＋1/β の値は？', frac(s / p), [frac(p / s) if s else '0', frac(-s / p), frac(s * p)], f'(α＋β)/(αβ)＝{frac(s)}÷{frac(p)}。'))
        else:
            out.append((C, f'{eq}、(α−β)² の値は？', frac(s * s - 4 * p), [frac(s * s + 4 * p), frac(s * s - 2 * p), frac(4 * p - s * s)], f'α＋β＝{frac(s)}、αβ＝{frac(p)}。(α−β)²＝(α＋β)²−4αβ＝({frac(s)})²−4×({frac(p)})＝{frac(s * s - 4 * p)}。'))
    for _ in range(8):
        r1, r2 = nz(-6, 6), nz(-6, 6)
        out.append((C, f'{r1} と {r2} を解にもつ2次方程式（x² の係数1）は？', f'{pstr([r1 * r2, -(r1 + r2), 1])} ＝ 0',
                    [f'{pstr([r1 * r2, r1 + r2, 1])} ＝ 0', f'{pstr([-r1 * r2, -(r1 + r2), 1])} ＝ 0', f'{pstr([r1 + r2, -r1 * r2, 1])} ＝ 0'], f'和 {r1}＋({r2})＝{r1 + r2}、積 {r1}×({r2})＝{r1 * r2}。x²−(和)x＋(積)＝0 に入れる。'))
    # 剰余の定理・因数定理
    for _ in range(20):
        p = [R.randint(-6, 6), R.randint(-5, 5), R.randint(-4, 4), nz(-2, 3)]
        a = nz(-3, 3)
        rem = peval(p, a)
        dv = f'x − {a}' if a > 0 else f'x ＋ {-a}'
        out.append((C, f'P(x) ＝ {pstr(p)} を {dv} で割ったときの余りは？', frac(rem),
                    [frac(peval(p, -a)), frac(-rem), frac(p[0])], f'剰余の定理：余りは P({a})＝{frac(rem)}。'))
    for _ in range(10):
        a = nz(-3, 3)
        b, c = R.randint(-4, 4), R.randint(-5, 5)
        # P(x)＝x³＋bx²＋cx＋k が x−a で割り切れる k
        k = -(a ** 3 + b * a * a + c * a)
        dv = f'x − {a}' if a > 0 else f'x ＋ {-a}'
        out.append((C, f'{pstr([0, c, b, 1])} ＋ k が {dv} で割り切れるとき、k の値は？', num(k),
                    [num(-k), num(k + a), num(a ** 3 + b * a * a + c * a + 1)], f'因数定理：P({a})＝({a})³＋{b}×({a})²＋{c}×({a})＋k＝{a ** 3 + b * a * a + c * a}＋k＝0 より k＝{num(k)}。'))
    for _ in range(8):
        a, b = R.sample([-3, -2, -1, 1, 2, 3], 2)
        ra = R.randint(-6, 6)
        rb = ra - (a - b) * R.randint(-3, 3)
        p_ = F(ra - rb, a - b)
        q_ = F(ra) - p_ * a
        da, db = pstr([-a, 1]), pstr([-b, 1])
        out.append((C, f'整式 P(x) を {da} で割ると余り {num(ra)}、{db} で割ると余り {num(rb)} である。P(x) を ({da})({db}) で割った余りは？',
                    pstr([q_, p_]), [pstr([p_, q_]), pstr([q_ + 1, p_]), pstr([-q_, p_])], f'余りを px＋q とおくと、剰余の定理より {num(a)}p＋q＝{num(ra)}、{num(b)}p＋q＝{num(rb)}。'))
    # 複素数の相等
    for _ in range(8):
        x, y = nz(-5, 5), nz(-5, 5)
        out.append((C, f'(x＋y) ＋ (x−y)i ＝ {cstr((x + y, x - y))} を満たす実数 x, y は？', f'x＝{num(x)}, y＝{num(y)}',
                    [f'x＝{num(y)}, y＝{num(x)}', f'x＝{num(-x)}, y＝{num(y)}', f'x＝{num(x)}, y＝{num(-y)}'], f'実部・虚部を比べて x＋y＝{num(x + y)}、x−y＝{num(x - y)}。'))
    out += [
        (K, '虚数単位 i の性質は？', 'i² ＝ −1', ['i² ＝ 1', 'i ＝ −1', 'i² ＝ 0'], '2乗して −1 になる数。'),
        (K, '複素数 a＋bi の共役な複素数は？', 'a − bi', ['−a＋bi', 'b＋ai', '−a−bi'], '虚部の符号を変える。'),
        (K, '√(−4) を i を使って表すと？', '2i', ['−2', '4i', '−2i'], '√(−a)＝√a i（a＞0）。'),
        (C, '√(−2)×√(−8) の値は？', '−4', ['4', '4i', '−4i'], '√2 i×2√2 i＝4i²＝−4。√16 としないこと。'),
        (K, '2次方程式 ax²＋bx＋c＝0 の判別式 D が負のとき、解は？', '異なる2つの虚数解', ['重解', '異なる2つの実数解', '解はない'], '複素数の範囲では必ず解がある。'),
        (K, '1の3乗根のうち虚数のものを ω とすると成り立つ式は？', 'ω²＋ω＋1＝0', ['ω²−ω＋1＝0', 'ω＋1＝0', 'ω²＝1'], 'x³−1＝(x−1)(x²＋x＋1)。'),
        (C, 'ω を1の虚数の3乗根とするとき、ω³ の値は？', '1', ['−1', 'ω', '0'], 'ω は x³＝1 の解。'),
        (C, 'ω を1の虚数の3乗根とするとき、ω¹⁰⁰ ＋ ω⁵⁰ ＋ 1 の値は？', '0', ['3', '1', '−1'], 'ω¹⁰⁰＝ω、ω⁵⁰＝ω² なので ω＋ω²＋1＝0。'),
        (K, '因数定理の内容は？', 'P(a)＝0 ⇔ P(x) は x−a で割り切れる', ['P(a)＝0 ⇔ P(x) は x＋a で割り切れる', 'P(0)＝0 ⇔ P(x)＝0', 'P(a)＝a ⇔ 余りは a'], '高次方程式の因数分解に使う。'),
        (C, '3次方程式 x³ − 6x² ＋ 11x − 6 ＝ 0 の解は？', 'x＝1, 2, 3', ['x＝−1, −2, −3', 'x＝1, −2, 3', 'x＝2, 3, 6'], 'x＝1 を代入すると0。(x−1)(x−2)(x−3)＝0。'),
        (C, '方程式 x³ ＝ 8 の実数解は？', 'x＝2', ['x＝−2', 'x＝±2', 'x＝8/3'], 'x³−8＝(x−2)(x²＋2x＋4)＝0。残りは虚数解。'),
        (C, '方程式 x⁴ − 5x² ＋ 4 ＝ 0 の解は？', 'x＝±1, ±2', ['x＝1, 4', 'x＝±1, ±4', 'x＝±2'], 'x²＝t とおくと t²−5t＋4＝0、t＝1, 4。'),
        (T, '2次方程式 x² ＋ kx ＋ 4 ＝ 0 が虚数解をもつ k の範囲は？', '−4 ＜ k ＜ 4', ['k ＜ −4, 4 ＜ k', 'k ＝ ±4', 'k ＞ 4'], 'D＝k²−16＜0。'),
        (T, '2次方程式 x² − 2x ＋ m ＝ 0 が重解をもつとき、m の値と重解は？', 'm＝1、重解 x＝1', ['m＝−1、重解 x＝1', 'm＝4、重解 x＝2', 'm＝1、重解 x＝−1'], 'D/4＝1−m＝0。'),
        (T, '実数係数の3次方程式が 1＋2i を解にもつとき、必ず解になるものは？', '1−2i', ['−1＋2i', '−1−2i', '2＋i'], '実数係数なら共役な複素数も解。'),
    ]
    return out


# ================= 数学A 整数 =================
def divisors(n):
    return [d for d in range(1, n + 1) if n % d == 0]


def factor(n):
    f, d = {}, 2
    while d * d <= n:
        while n % d == 0:
            f[d] = f.get(d, 0) + 1
            n //= d
        d += 1
    if n > 1:
        f[n] = f.get(n, 0) + 1
    return f


def fstr(f):
    return '×'.join(f'{p}{sup(e) if e > 1 else ""}' for p, e in sorted(f.items()))


def to_base(n, b):
    s = ''
    while n:
        s = str(n % b) + s
        n //= b
    return s or '0'


def integer_items():
    out = []
    for _ in range(22):
        n = R.choice([12, 18, 24, 36, 40, 48, 60, 72, 84, 90, 96, 100, 108, 120, 144, 150, 168, 180, 200, 210, 216, 240, 252, 288, 300, 360, 420, 500, 504, 540])
        f = factor(n)
        nd = len(divisors(n))
        out.append((C, f'{n} を素因数分解すると？', fstr(f),
                    [fstr({**f, min(f): f[min(f)] + 1}), fstr({k: v for k, v in f.items() if k != max(f)} | {max(f) + 2: 1}) if max(f) + 2 not in (4, 6, 8, 9, 10) else fstr({**f, 2: f.get(2, 0) + 2}), '×'.join(str(p) for p in sorted(f))],
                    f'{n}＝{fstr(f)}。'))
        out.append((C, f'{n} の正の約数の個数は？', num(nd),
                    [num(math.prod(f.values())), num(sum(f.values())), num(nd + 2), num(nd - 1)],
                    f'{fstr(f)} より ' + '×'.join(f'({e}＋1)' for e in f.values()) + f'＝{nd}。'))
        out.append((C, f'{n} の正の約数の総和は？', num(sum(divisors(n))),
                    [num(sum(divisors(n)) - n), num(sum(divisors(n)) + 1), num(2 * n)], f'{fstr(f)} より ' + '×'.join('(' + '＋'.join(str(p ** i) for i in range(e + 1)) + ')' for p, e in sorted(f.items())) + f'＝{sum(divisors(n))}。'))
    for _ in range(24):
        g = R.choice([2, 3, 4, 5, 6, 7, 8, 9, 12, 14, 15, 18])
        a, b = g * R.randint(2, 15), g * R.randint(2, 15)
        if a == b:
            continue
        G, L = math.gcd(a, b), a * b // math.gcd(a, b)
        out.append((C, f'{a} と {b} の最大公約数は？', num(G), [num(L), num(G * 2), num(min(a, b) - max(a, b) % min(a, b)) if G != min(a, b) - max(a, b) % min(a, b) else num(G + 1), num(G // 2) if G > 2 else num(G + 3)],
                    f'{a}＝{fstr(factor(a))}、{b}＝{fstr(factor(b))}。共通の素因数を小さいほうの指数でかけて {G}。'))
        out.append((C, f'{a} と {b} の最小公倍数は？', num(L), [num(a * b), num(G), num(L * 2), num(L // 2) if L % 2 == 0 and L // 2 not in (a, b) else num(L + G)], f'最小公倍数＝{a}×{b}÷最大公約数{G}＝{L}。'))
    for _ in range(14):
        a, b = R.randint(100, 999), R.randint(30, 400)
        if a % b == 0:
            continue
        x, y, steps = a, b, []
        while y:
            steps.append(f'{x}＝{y}×{x // y}＋{x % y}')
            x, y = y, x % y
        out.append((C, f'ユークリッドの互除法を使って、{a} と {b} の最大公約数を求めよ。', num(x), [num(x * 2), num(b % x + x) if x > 1 else num(3), num(a % b), num(x + 1)],
                    '／'.join(steps) + f'。最後の割る数 {x} が答え。'))
    # 1次不定方程式
    for _ in range(20):
        a, b = R.choice([(3, 5), (5, 7), (7, 3), (4, 9), (5, 8), (7, 11), (3, 8), (11, 4), (9, 7), (13, 5), (6, 11), (8, 15)])
        c = R.choice([1, 1, 2, 3])
        # 1つの解
        for x0 in sorted(range(-20, 21), key=abs):
            if (c - a * x0) % b == 0:
                y0 = (c - a * x0) // b
                break
        out.append((C, f'方程式 {a}x ＋ {b}y ＝ {c} の整数解をすべて求めよ（k は整数）。', f'x＝{b}k＋{x0}, y＝−{a}k＋{y0}'.replace('＋-', '−'),
                    [f'x＝{a}k＋{x0}, y＝−{b}k＋{y0}'.replace('＋-', '−'), f'x＝{b}k＋{x0}, y＝{a}k＋{y0}'.replace('＋-', '−'), f'x＝{b}k＋{y0}, y＝−{a}k＋{x0}'.replace('＋-', '−')],
                    f'1つの解 (x, y)＝({num(x0)}, {num(y0)}) を見つけ、差をとって {a}(x−({num(x0)}))＝−{b}(y−({num(y0)}))。{a} と {b} は互いに素なので x−({num(x0)}) は {b} の倍数。'))
    # 余り
    for _ in range(14):
        a, n, m = R.randint(2, 9), R.randint(10, 60), R.choice([3, 4, 5, 7, 9, 10, 11])
        out.append((C, f'{a}{sup(n)} を {m} で割った余りは？', num(pow(a, n, m)), [num((pow(a, n, m) + 1) % m), num((a * n) % m), num(pow(a, n - 1, m)), num((pow(a, n, m) + 2) % m)],
                    f'{a} の累乗を {m} で割った余りの周期を調べる（合同式でもよい）。'))
    for _ in range(10):
        m = R.choice([3, 4, 5, 7])
        r1, r2 = R.randint(1, m - 1), R.randint(1, m - 1)
        out.append((C, f'整数 a, b を {m} で割った余りがそれぞれ {r1}, {r2} のとき、ab を {m} で割った余りは？', num(r1 * r2 % m),
                    [num((r1 + r2) % m), num(r1 * r2), num((r1 * r2 + 1) % m)], f'余りどうしをかけて {r1 * r2} を {m} で割った余り。'))
        out.append((C, f'整数 a, b を {m} で割った余りがそれぞれ {r1}, {r2} のとき、a＋b を {m} で割った余りは？', num((r1 + r2) % m),
                    [num(r1 * r2 % m), num(r1 + r2), num((r1 + r2 + 1) % m)], f'{r1}＋{r2}＝{r1 + r2} を {m} で割った余り。'))
    # n 進法
    for _ in range(22):
        b = R.choice([2, 2, 3, 5, 4, 8])
        n = R.randint(10, 200)
        s = to_base(n, b)
        out.append((C, f'10進数の {n} を {b}進法で表すと？', f'{s}（{b}）',
                    [f'{s[::-1]}（{b}）' if s[::-1] != s else f'{to_base(n + 1, b)}（{b}）', f'{to_base(n - 1, b)}（{b}）', f'{to_base(n + b, b)}（{b}）'], f'{n} を {b} で割り続けると、余りは下から順に ' + '、'.join(reversed(list(s))) + f'。下から並べて {s}（{b}）。'))
        out.append((C, f'{b}進法で {s}（{b}）と表される数を10進法で表すと？', num(n),
                    [num(int(s[::-1], b)) if s[::-1] != s else num(n + 1), num(n + b), num(int(s) if int(s) != n else n - 1)], '＋'.join(f'{d}×{b}{sup(len(s) - 1 - i)}' for i, d in enumerate(s) if d != '0') + f'＝{n}。'))
    for _ in range(6):
        x, y = R.randint(5, 40), R.randint(5, 40)
        out.append((C, f'2進法の計算 {to_base(x, 2)}（2）＋{to_base(y, 2)}（2）の結果を2進法で表すと？', f'{to_base(x + y, 2)}（2）',
                    [f'{to_base(x + y + 1, 2)}（2）', f'{to_base(abs(x - y) or 1, 2)}（2）', f'{to_base(x + y - 1, 2)}（2）'], f'10進法で {x}＋{y}＝{x + y}。'))
    for n, p in [(10, 2), (20, 5), (25, 5), (30, 2), (50, 5), (100, 5), (12, 3), (40, 2)]:
        e = sum(n // p ** k for k in range(1, 8))
        out.append((C, f'{n}! を素因数分解したとき、素因数 {p} の個数は？', num(e), [num(n // p), num(e + 1), num(e - 1)], f'{n}÷{p}, {n}÷{p}², … の商を足す。'))
    out += [
        (K, '2つの整数の最大公約数が1であるとき、2数は何であるという？', '互いに素', ['素数', '倍数', '公倍数'], 'ax＋by＝1 が整数解をもつ条件にも関係する。'),
        (K, 'ユークリッドの互除法のもとになる性質は？', 'a を b で割った余りを r とすると、a と b の最大公約数は b と r の最大公約数に等しい', ['a と b の最大公約数は a＋b に等しい', 'a×b は最小公倍数に等しい', '素数は2で割り切れない'], '割り算をくり返して最大公約数を求める。'),
        (K, '2つの自然数 a, b の最大公約数を G、最小公倍数を L とするとき成り立つ式は？', 'ab ＝ GL', ['a＋b ＝ G＋L', 'ab ＝ G＋L', 'L ＝ G²'], 'a＝Ga′、b＝Gb′、L＝Ga′b′。'),
        (T, '連続する2つの整数の積が必ず2の倍数になる理由は？', 'どちらか一方は必ず偶数だから', ['どちらも奇数だから', '和が奇数だから', '2で割った余りが1だから'], '余りで分類（偶奇）して考える。'),
        (T, '連続する3つの整数の積が必ず6の倍数になる理由は？', '2の倍数と3の倍数を必ず含むから', ['3つとも奇数だから', '和が3の倍数だから', '6を必ず含むから'], '2と3は互いに素。'),
        (T, 'n² を 3 で割った余りとして、あり得ないものは？', '2', ['0', '1', '0 または 1'], 'n＝3k, 3k±1 で場合分けすると余りは0か1。'),
        (T, '方程式 xy ＝ 6 を満たす正の整数の組 (x, y) の個数は？', '4組', ['2組', '3組', '6組'], '(1,6),(2,3),(3,2),(6,1)。'),
        (T, '方程式 (x−1)(y−2) ＝ 3 を満たす正の整数の組 (x, y) は？', '(2, 5), (4, 3)', ['(1, 3), (3, 1)', '(2, 5) のみ', '(4, 5), (2, 3)'], 'x−1≧0、y−2≧−1 から積が3となる組を調べる。'),
        (T, '7で割ると3余り、5で割ると2余る最小の自然数は？', '17', ['12', '22', '27'], '7k＋3＝5l＋2 の最小解。'),
        (K, '2進法で 1 0 0 0（2）は10進法でいくつ？', '8', ['4', '1000', '16'], '2³＝8。'),
        (T, '10進法で3桁の数は、2進法で表すと最大で何桁？', '10桁', ['9桁', '11桁', '3桁'], '999＜2¹⁰＝1024 なので10桁。'),
        (K, '素数とは？', '1とその数自身以外に正の約数をもたない2以上の整数', ['奇数のこと', '約数が3個ある数', '2で割り切れない数'], '2は唯一の偶数の素数。'),
        (T, '√(56n) が自然数となる最小の自然数 n は？', '14', ['2', '7', '56'], '56＝2³×7。指数をすべて偶数にするには 2×7＝14。'),
        (T, '1から100までの整数のうち、3でも5でも割り切れない数の個数は？', '53', ['47', '60', '33'], '100−(33＋20−6)＝53。'),
    ]
    return out


def write(prefix, items, size, tags):
    R.shuffle(items)
    total = 0
    n = -(-len(items) // size)
    size = -(-len(items) // n)
    for i, part in enumerate(chunks(items, size), 1):
        total += make_set(f'{prefix}_{i:02d}', 'math', part, tags, seed=i)
    return total


if __name__ == '__main__':
    t = 0
    t += write('math_shonan_104_m1_data', data_items(), 50, ['math1', 'data'])
    t += write('math_shonan_104_m1_proof', proof_items(), 50, ['math1', 'm2-proof'])
    t += write('math_shonan_104_m1_complex', complex_items(), 50, ['math1', 'm2-complex'])
    t += write('math_shonan_104_ma_integer', integer_items(), 50, ['math_a', 'integer'])
    print('total', t)
