"""問題づくりの小さな道具（数の問題のまちがい選択肢など）。"""
import random
from fractions import Fraction as Fr

from lib import Q


def near(a, deltas=(1, -1, 2, -2, 10, -10, 3), lo=0):
    """正解 a に近い、まちがいの数を3つ。"""
    out = []
    for d in deltas:
        x = a + d
        if x >= lo and x != a and x not in out:
            out.append(x)
        if len(out) == 3:
            break
    return out


def fmt(x):
    """数を表示用の文字に（小数の余分な0を消す）。"""
    if isinstance(x, Fr):
        return frac(x)
    if isinstance(x, float):
        s = f'{x:.6f}'.rstrip('0').rstrip('.')
        return s if s != '-0' else '0'
    return str(x)


def frac(f):
    f = Fr(f)
    if f.denominator == 1:
        return str(f.numerator)
    return f'{f.numerator}/{f.denominator}'


def dnear(a, step):
    """小数の正解 a の近くのまちがい（step ずつずらす）。"""
    c = [round(a + step, 6), round(a - step, 6), round(a * 10, 6),
         round(a / 10, 6), round(a + 2 * step, 6)]
    out = []
    for x in c:
        if x > 0 and fmt(x) != fmt(a) and fmt(x) not in out:
            out.append(fmt(x))
    return out[:3]


def calc(p, a, e='', w=None, c='c', **kw):
    """計算の問題。w がなければ近い数で作る。"""
    if w is None:
        w = near(a) if isinstance(a, int) else []
    return Q(c, p, fmt(a), [fmt(x) for x in w], e, **kw)


def rng(seed):
    return random.Random(seed)


def uniq(gen, n, seed, exclude=()):
    """gen(r) で作った問題から、問いが重ならないように n 問とる。"""
    r = rng(seed)
    out, seen = [], set(exclude)
    tries = 0
    while len(out) < n:
        tries += 1
        assert tries < 5000, ('問題を作りきれない', seed)
        try:
            q = gen(r)
        except AssertionError:
            continue
        if q is None or q['p'] in seen:
            continue
        seen.add(q['p'])
        out.append(q)
    return out
