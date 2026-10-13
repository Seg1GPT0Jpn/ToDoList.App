"""化学基礎（物質量・濃度・化学反応式の量的関係）の委員会セットを作る。

  cd rpg_game/tool/shonan_questions && python3 chem_gen.py

原子量 H=1.0 C=12 N=14 O=16 Na=23 Mg=24 Al=27 S=32 Cl=35.5 K=39 Ca=40 Fe=56 Cu=64 Zn=65 Ag=108、
アボガドロ定数 6.0×10²³/mol、気体1molの体積（標準状態）22.4 L。答えはすべてこのプログラムで計算する。
"""
import math
import random
from fractions import Fraction as F

from common import chunks, make_set

R = random.Random(2026)
AW = {'H': F(1), 'C': F(12), 'N': F(14), 'O': F(16), 'Na': F(23), 'Mg': F(24), 'Al': F(27), 'S': F(32),
      'Cl': F(71, 2), 'K': F(39), 'Ca': F(40), 'Fe': F(56), 'Cu': F(64), 'Zn': F(65), 'Ag': F(108)}
NA = F(6, 1)  # ×10²³
V = F(224, 10)
SUBN = str.maketrans('0123456789', '₀₁₂₃₄₅₆₇₈₉')
NOTE = '（原子量 H=1.0, C=12, N=14, O=16, Na=23, Mg=24, Al=27, S=32, Cl=35.5, Ca=40 などを用いよ）'

# 化学式 → 組成
CPD = {
    'H2': {'H': 2}, 'O2': {'O': 2}, 'N2': {'N': 2}, 'Cl2': {'Cl': 2}, 'H2O': {'H': 2, 'O': 1},
    'CO2': {'C': 1, 'O': 2}, 'CH4': {'C': 1, 'H': 4}, 'NH3': {'N': 1, 'H': 3}, 'HCl': {'H': 1, 'Cl': 1},
    'NaCl': {'Na': 1, 'Cl': 1}, 'NaOH': {'Na': 1, 'O': 1, 'H': 1}, 'H2SO4': {'H': 2, 'S': 1, 'O': 4},
    'C2H6': {'C': 2, 'H': 6}, 'C3H8': {'C': 3, 'H': 8}, 'C2H5OH': {'C': 2, 'H': 6, 'O': 1},
    'CaCO3': {'Ca': 1, 'C': 1, 'O': 3}, 'MgO': {'Mg': 1, 'O': 1}, 'Al2O3': {'Al': 2, 'O': 3},
    'CuO': {'Cu': 1, 'O': 1}, 'Fe2O3': {'Fe': 2, 'O': 3}, 'C6H12O6': {'C': 6, 'H': 12, 'O': 6},
    'KCl': {'K': 1, 'Cl': 1}, 'CaCl2': {'Ca': 1, 'Cl': 2}, 'SO2': {'S': 1, 'O': 2}, 'NO2': {'N': 1, 'O': 2},
    'HNO3': {'H': 1, 'N': 1, 'O': 3}, 'CH3COOH': {'C': 2, 'H': 4, 'O': 2}, 'Na2CO3': {'Na': 2, 'C': 1, 'O': 3},
}
GAS = ['H2', 'O2', 'N2', 'CO2', 'CH4', 'NH3', 'HCl', 'C2H6', 'C3H8', 'Cl2', 'SO2', 'NO2']


def fm(f):
    return f.translate(SUBN)


def mw(f):
    return sum(AW[e] * n for e, n in CPD[f].items())


def sig(x, d=2):
    """有効数字 d 桁の文字列（大きい・小さい数は ×10ⁿ）"""
    x = float(x)
    if x == 0:
        return '0'
    e = math.floor(math.log10(abs(x)))
    if -2 <= e <= 3:
        s = f'{x:.{max(0, d - 1 - e)}f}'
        return s
    m = x / 10 ** e
    m = round(m, d - 1)
    if m >= 10:
        m, e = m / 10, e + 1
    sup = str(e).translate(str.maketrans('0123456789-', '⁰¹²³⁴⁵⁶⁷⁸⁹⁻'))
    return f'{m:.{d - 1}f} × 10{sup}'


def g(x):
    """g・L・mol などの量。有限小数（小数第4位まで）ならそのまま、そうでなければ有効数字3桁"""
    x = F(x)
    for k in range(5):
        if (x * 10 ** k).denominator == 1:
            if abs(x) >= 100000 or (x != 0 and abs(x) < F(1, 1000)):
                return sig(x, 3)
            return f'{float(x):.{k}f}'
    return sig(x, 3)


def W(*vals):
    """誤答の候補（正解と同じ文字列は make_set が落とす）"""
    return list(vals)


C, K, T = 'calculation', 'knowledge', 'thinking'


def mole_items():
    out = []
    for f in CPD:
        M = mw(f)
        wrong_m = sum(AW[e] for e in CPD[f])  # 個数をかけ忘れ
        out.append((C, f'{fm(f)} の分子量（式量）は？{NOTE}', g(M), W(g(wrong_m), g(M + 1), g(M * 2), g(M - AW['H'])),
                    ' ＋ '.join(f'{g(AW[e])}×{n}' for e, n in CPD[f].items()) + f' ＝ {g(M)}。'))
    for _ in range(110):
        f = R.choice(list(CPD))
        M = mw(f)
        n = R.choice([F(1, 10), F(1, 4), F(1, 2), F(2), F(3), F(1, 5), F(3, 2), F(5)])
        m = M * n
        kind = R.randrange(3)
        if kind == 0:
            out.append((C, f'{fm(f)} {g(m)} g の物質量は何 mol か。{NOTE}', g(n), W(g(m * M), g(M / m), g(n * 2), g(n / 2)),
                        f'{fm(f)} のモル質量は {g(M)} g/mol。{g(m)}÷{g(M)}＝{g(n)} mol。'))
        elif kind == 1:
            out.append((C, f'{fm(f)} {g(n)} mol の質量は何 g か。{NOTE}', g(m), W(g(M / n), g(n), g(m * 2), g(m / 2)),
                        f'{g(M)} g/mol × {g(n)} mol ＝ {g(m)} g。'))
        else:
            out.append((C, f'{fm(f)} {g(m)} g に含まれる分子（粒子）の数は？（アボガドロ定数 6.0×10²³/mol）{NOTE}', sig(n * NA * 10 ** 23),
                        W(sig(n * NA * 10 ** 22), sig(m * NA * 10 ** 23), sig(n * 10 ** 23), sig(n * NA * 10 ** 23 * 2)),
                        f'{g(m)}÷{g(M)}＝{g(n)} mol。{g(n)}×6.0×10²³ 個。'))
    for _ in range(70):
        f = R.choice(GAS)
        M = mw(f)
        n = R.choice([F(1, 10), F(1, 4), F(1, 2), F(2), F(3), F(1, 5), F(3, 2)])
        kind = R.randrange(3)
        if kind == 0:
            out.append((C, f'標準状態で {fm(f)} {g(n * V)} L の物質量は何 mol か。', g(n), W(g(n * V * V), g(V / (n * V)), g(n * 2), g(n * M)),
                        f'{g(n * V)}÷22.4＝{g(n)} mol。'))
        elif kind == 1:
            out.append((C, f'{fm(f)} {g(n * M)} g は、標準状態で何 L か。{NOTE}', g(n * V), W(g(n * M * V), g(n), g(n * V * 2), g(V / n)),
                        f'{g(n * M)}÷{g(M)}＝{g(n)} mol、×22.4＝{g(n * V)} L。'))
        else:
            out.append((C, f'標準状態で {g(n * V)} L の {fm(f)} の質量は何 g か。{NOTE}', g(n * M), W(g(n * V * M), g(n), g(M), g(n * M / 2)),
                        f'{g(n * V)}÷22.4＝{g(n)} mol、×{g(M)}＝{g(n * M)} g。'))
    for _ in range(30):
        f = R.choice(['H2O', 'CO2', 'CH4', 'NH3', 'H2SO4', 'C2H5OH', 'C6H12O6', 'C3H8'])
        e = R.choice(list(CPD[f]))
        k = CPD[f][e]
        n = R.choice([F(1, 2), F(1), F(2), F(1, 4)])
        out.append((C, f'{fm(f)} {g(n)} mol に含まれる {e} 原子の数は？', sig(n * k * NA * 10 ** 23),
                    W(sig(n * NA * 10 ** 23), sig(n * k * 10 ** 23), sig(n * (k + 1) * NA * 10 ** 23)),
                    f'{fm(f)} 1分子に {e} 原子は {k} 個。{g(n)}×{k}×6.0×10²³。'))
    for f in ['H2O', 'CO2', 'O2', 'CH4', 'NH3', 'N2']:
        M = mw(f)
        out.append((C, f'{fm(f)} 分子1個の質量は何 g か。（アボガドロ定数 6.0×10²³/mol）', sig(M / NA / 10 ** 23),
                    W(sig(M * NA * 10 ** 23), sig(M / NA / 10 ** 22), sig(NA / M * 10 ** 23)), f'{g(M)} g を 6.0×10²³ 個で割る。'))
        out.append((C, f'標準状態での {fm(f)} の密度（1 L あたりの質量）は何 g/L か。{NOTE}', sig(M / V, 2),
                    W(sig(V / M, 2), sig(M * V, 2), sig(M / 22.4 * 2, 2)), f'{g(M)} g/mol ÷ 22.4 L/mol。'))
    for _ in range(4):
        d = R.choice([F(25, 14), F(5, 4), F(2), F(1, 1) * 125 / 112])
        M = d * V
        out.append((C, f'ある気体の標準状態での密度は {g(d)} g/L である。この気体のモル質量は何 g/mol か。', g(M),
                    W(g(d / V), g(V / d), g(M * 2)), f'{g(d)}×22.4＝{g(M)}。'))
    # 同位体と原子量
    for (m1, p1, m2, p2, el) in [(35, 75, 37, 25, '塩素'), (63, 69, 65, 31, '銅'), (10, 20, 11, 80, 'ホウ素'), (6, 8, 7, 92, 'リチウム'), (24, 80, 26, 20, '仮の元素X')]:
        aw = F(m1 * p1 + m2 * p2, 100)
        out.append((C, f'{el}の同位体は相対質量 {m1}（存在比 {p1}%）と {m2}（存在比 {p2}%）である。原子量は？（小数第1位まで）', f'{float(aw):.1f}',
                    W(f'{(m1 + m2) / 2:.1f}', f'{float(F(m1 * p2 + m2 * p1, 100)):.1f}', f'{float(aw) + 1:.1f}'), f'{m1}×{p1}/100＋{m2}×{p2}/100。'))
    out += [
        (K, '1 mol とは何個の粒子の集まりか。', '6.0×10²³ 個', ['22.4 個', '1.0×10²³ 個', '12 個'], 'アボガドロ定数 6.0×10²³/mol。'),
        (K, '標準状態（0℃, 1.013×10⁵ Pa）で気体 1 mol の体積は？', '22.4 L', ['24.8 L', '1 L', '6.0 L'], '気体の種類によらない。'),
        (K, '原子量の基準となる原子は？', '¹²C（質量数12の炭素原子）', ['¹H', '¹⁶O', '¹⁴N'], '¹²C の質量を 12 とした相対質量。'),
        (K, 'モル質量の単位は？', 'g/mol', ['mol/g', 'mol/L', 'g/L'], '数値は原子量・分子量・式量と同じ。'),
        (T, '同じ質量の H₂ と O₂ では、どちらの分子数が多い？', 'H₂（約16倍）', ['O₂（約16倍）', '同じ', 'H₂（約2倍）'], 'モル質量が 2 と 32。'),
        (T, '標準状態で同じ体積の CO₂ と CH₄ について正しいものは？', '分子の数が等しい', ['質量が等しい', '原子の数が等しい', '密度が等しい'], 'アボガドロの法則。'),
        (T, '標準状態で最も密度が大きい気体は？', 'CO₂', ['H₂', 'CH₄', 'N₂'], '密度＝モル質量÷22.4。CO₂は44。'),
    ]
    return out


def solution_items():
    out = []
    for _ in range(45):
        solute = R.choice([5, 10, 15, 20, 25, 30, 40, 50])
        water = R.choice([45, 90, 85, 80, 75, 160, 150, 200, 190, 230])
        pct = F(solute * 100, solute + water)
        out.append((C, f'水 {water} g に溶質 {solute} g を溶かした水溶液の質量パーセント濃度は？', g(pct) + ' %',
                    W(g(F(solute * 100, water)) + ' %', g(F(solute, solute + water)) + ' %', g(pct * 2) + ' %'),
                    f'{solute}÷({solute}＋{water})×100＝{g(pct)} %。溶液の質量で割る。'))
    for _ in range(70):
        f = R.choice(['NaCl', 'NaOH', 'C6H12O6', 'HCl', 'H2SO4', 'KCl', 'CaCl2'])
        M = mw(f)
        n = R.choice([F(1, 10), F(1, 5), F(1, 2), F(1, 4), F(1, 20)])
        vol = R.choice([F(1, 4), F(1, 2), F(1), F(1, 5), F(2)])
        c = n / vol
        kind = R.randrange(3)
        if kind == 0:
            out.append((C, f'{fm(f)} {g(n * M)} g を水に溶かして {g(vol * 1000)} mL にした。モル濃度は何 mol/L か。{NOTE}', g(c),
                        W(g(n * M / vol), g(n), g(n * vol), g(c * 10)), f'{g(n * M)}÷{g(M)}＝{g(n)} mol、÷{g(vol)} L＝{g(c)} mol/L。'))
        elif kind == 1:
            out.append((C, f'{g(c)} mol/L の {fm(f)} 水溶液 {g(vol * 1000)} mL に含まれる溶質は何 mol か。', g(n),
                        W(g(c / vol), g(c * vol * 1000), g(c), g(n * 2)), f'{g(c)}×{g(vol)}＝{g(n)} mol。mL は L に直す。'))
        else:
            out.append((C, f'{g(c)} mol/L の {fm(f)} 水溶液を {g(vol * 1000)} mL つくるのに必要な {fm(f)} は何 g か。{NOTE}', g(n * M),
                        W(g(c * M), g(n), g(c * vol * 1000 * M), g(n * M * 2)), f'必要な物質量 {g(c)}×{g(vol)}＝{g(n)} mol、×{g(M)}＝{g(n * M)} g。'))
    for _ in range(30):
        c1 = R.choice([F(1), F(2), F(1, 2), F(6), F(3)])
        v1 = R.choice([10, 20, 25, 50, 100])
        k = R.choice([2, 4, 5, 10])
        v2 = v1 * k
        c2 = c1 / k
        out.append((C, f'{g(c1)} mol/L の水溶液 {v1} mL に水を加えて {v2} mL にした。モル濃度は何 mol/L か。', g(c2),
                    W(g(c1 * k), g(c1), g(c1 * v1 / 1000), g(c2 * 2)), f'溶質の物質量は変わらない：{g(c1)}×{v1}/1000 ÷ {v2}/1000。'))
    for (pct, d, f) in [(98, F(18, 10), 'H2SO4'), (36.5, F(12, 10), 'HCl'), (20, F(11, 10), 'NaOH'), (10, F(1), 'NaCl'), (63, F(14, 10), 'HNO3'), (40, F(12, 10), 'NaOH')]:
        M = mw(f)
        pct = F(pct).limit_denominator(10)
        c = 1000 * d * pct / 100 / M
        out.append((C, f'質量パーセント濃度 {g(pct)} %、密度 {g(d)} g/cm³ の {fm(f)} 水溶液のモル濃度は何 mol/L か。{NOTE}', g(c),
                    W(g(1000 * pct / 100 / M), g(1000 * d * pct / M), g(d * pct / 100 / M), g(c * 2)),
                    f'1 L（1000 cm³）の質量 {g(1000 * d)} g、溶質 {g(1000 * d * pct / 100)} g、÷{g(M)}＝{g(c)} mol/L。'))
    out += [
        (K, 'モル濃度の単位は？', 'mol/L', ['g/L', '%', 'mol/kg'], '溶液 1 L 中の溶質の物質量。'),
        (T, '0.10 mol/L の NaCl 水溶液を正確に 1 L つくる操作として正しいものは？', 'NaCl 0.10 mol を少量の水に溶かし、メスフラスコで全体を 1 L にする', ['NaCl 0.10 mol を水 1 L に溶かす', 'NaCl 5.85 g を水 1000 g に溶かす', 'NaCl 0.10 g を水に溶かして 1 L にする'], '溶液の体積を 1 L にする（水を 1 L 加えるのではない）。'),
        (K, '一定体積の溶液を正確につくるときに使う器具は？', 'メスフラスコ', ['ビーカー', '試験管', 'メスシリンダー'], '標線まで水を加える。'),
        (T, '水溶液を水でうすめても変わらないものは？', '溶質の物質量', ['モル濃度', '溶液の体積', '溶液の質量'], '希釈前後で溶質の量は同じ。'),
    ]
    return out


# 反応式：(反応物, 生成物) 係数つき
EQ = [
    ([(2, 'H2'), (1, 'O2')], [(2, 'H2O')], '水素の燃焼'),
    ([(1, 'CH4'), (2, 'O2')], [(1, 'CO2'), (2, 'H2O')], 'メタンの燃焼'),
    ([(1, 'C3H8'), (5, 'O2')], [(3, 'CO2'), (4, 'H2O')], 'プロパンの燃焼'),
    ([(2, 'C2H6'), (7, 'O2')], [(4, 'CO2'), (6, 'H2O')], 'エタンの燃焼'),
    ([(1, 'N2'), (3, 'H2')], [(2, 'NH3')], 'アンモニアの合成'),
    ([(1, 'CaCO3'), (2, 'HCl')], [(1, 'CaCl2'), (1, 'H2O'), (1, 'CO2')], '炭酸カルシウムと塩酸'),
    ([(1, 'C2H5OH'), (3, 'O2')], [(2, 'CO2'), (3, 'H2O')], 'エタノールの燃焼'),
    ([(1, 'C6H12O6'), (6, 'O2')], [(6, 'CO2'), (6, 'H2O')], 'グルコースの燃焼'),
    ([(1, 'HCl'), (1, 'NaOH')], [(1, 'NaCl'), (1, 'H2O')], '中和'),
    ([(1, 'H2SO4'), (2, 'NaOH')], [(1, 'Na2CO3' if False else 'H2O')], ''),
]
EQ = [e for e in EQ if e[2]]
CPD['Mg'] = {'Mg': 1}
CPD['Zn'] = {'Zn': 1}
CPD['ZnCl2'] = {'Zn': 1, 'Cl': 2}
CPD['MgCl2'] = {'Mg': 1, 'Cl': 2}
EQ += [
    ([(1, 'Zn'), (2, 'HCl')], [(1, 'ZnCl2'), (1, 'H2')], '亜鉛と塩酸'),
    ([(1, 'Mg'), (2, 'HCl')], [(1, 'MgCl2'), (1, 'H2')], 'マグネシウムと塩酸'),
    ([(2, 'Mg'), (1, 'O2')], [(2, 'MgO')], 'マグネシウムの燃焼'),
]


def eqstr(e):
    side = lambda xs: ' ＋ '.join(f'{"" if c == 1 else c}{fm(f)}' for c, f in xs)
    return f'{side(e[0])} → {side(e[1])}'


def reaction_items():
    out = []
    for e in EQ:
        # 係数を問う
        allc = e[0] + e[1]
        i = R.randrange(len(allc))
        c, f = allc[i]
        shown = [(('a' if j == i else cc), ff) for j, (cc, ff) in enumerate(allc)]
        nr = len(e[0])
        side = lambda xs: ' ＋ '.join(f'{"" if c_ == 1 else c_}{fm(f_)}' for c_, f_ in xs)
        out.append((C, f'次の化学反応式の係数 a は？（{e[2]}）\n{side(shown[:nr])} → {side(shown[nr:])}', str(c),
                    W(str(c + 1), str(max(1, c - 1)) if c > 1 else '3', str(c * 2)), f'両辺で各原子の数をそろえる：{eqstr(e)}。'))
    for _ in range(200):
        e = R.choice(EQ)
        (ca, fa) = R.choice(e[0])
        (cb, fb) = R.choice([x for x in e[0] + e[1] if x[1] != fa])
        Ma, Mb = mw(fa), mw(fb)
        n = R.choice([F(1, 10), F(1, 5), F(1, 2), F(1), F(2), F(1, 4), F(3, 2), F(3), F(2, 5)])
        nb = n * cb / ca
        if not clean(nb):
            continue
        kind = R.randrange(3)
        if kind == 0:
            out.append((C, f'{eqstr(e)} の反応で、{fm(fa)} {g(n * Ma)} g が完全に反応したとき、{fm(fb)} は何 mol 反応・生成するか。{NOTE}', g(nb),
                        W(g(n), g(n * ca / cb), g(nb * Mb), g(nb * 2)), f'{fm(fa)} {g(n)} mol。係数比 {ca}:{cb} より {g(nb)} mol。'))
        elif kind == 1:
            out.append((C, f'{eqstr(e)} の反応で、{fm(fa)} {g(n * Ma)} g が完全に反応したとき、{fm(fb)} は何 g 反応・生成するか。{NOTE}', g(nb * Mb),
                        W(g(n * Mb), g(n * ca / cb * Mb), g(n * Ma * cb / ca), g(nb)), f'{fm(fa)} {g(n)} mol → {fm(fb)} {g(nb)} mol → ×{g(Mb)} g/mol。'))
        elif fb in GAS:
            out.append((C, f'{eqstr(e)} の反応で、{fm(fa)} {g(n * Ma)} g が完全に反応したとき、{fm(fb)} は標準状態で何 L か。{NOTE}', g(nb * V),
                        W(g(n * V), g(n * ca / cb * V), g(nb * Mb), g(nb * V * 2)), f'{fm(fb)} {g(nb)} mol × 22.4 L/mol。'))
    # 気体の体積比（同温同圧）
    for e in EQ:
        gases = [x for x in e[0] + e[1] if x[1] in GAS]
        if len(gases) < 2:
            continue
        (ca, fa), (cb, fb) = gases[0], gases[-1]
        v = R.choice([2, 5, 10, 20])
        out.append((C, f'{eqstr(e)} で、同温・同圧のもとで {fm(fa)} {v} L が反応すると、{fm(fb)} は何 L 反応・生成するか。（H₂O は液体とする）'.replace('（H₂O は液体とする）', '' if 'H2O' not in (fa, fb) else '（H₂O は気体とする）'),
                    g(F(v * cb, ca)), W(g(v), g(F(v * ca, cb)), g(v * cb)), f'気体の体積比＝係数比 {ca}:{cb}。'))
    # 過不足
    for _ in range(40):
        e = R.choice([EQ[0], EQ[1], EQ[4], [(EQ[-1][0]), EQ[-1][1], EQ[-1][2]]])
        (ca, fa), (cb, fb) = e[0][0], e[0][1]
        na, nb = R.choice([F(1), F(2), F(3), F(1, 2)]), R.choice([F(1), F(2), F(3), F(1, 2), F(4)])
        need_b = na * cb / ca
        if need_b == nb:
            continue
        if need_b < nb:
            ans = f'{fm(fb)} が {g(nb - need_b)} mol 残る'
            wr = [f'{fm(fa)} が {g(na - nb * ca / cb)} mol 残る' if na - nb * ca / cb > 0 else f'{fm(fa)} が {g(nb - need_b)} mol 残る', f'{fm(fb)} が {g(nb)} mol 残る', 'どちらも残らない']
        else:
            left = na - nb * ca / cb
            ans = f'{fm(fa)} が {g(left)} mol 残る'
            wr = [f'{fm(fb)} が {g(left)} mol 残る', f'{fm(fa)} が {g(na)} mol 残る', 'どちらも残らない']
        out.append((T, f'{eqstr(e)} の反応で、{fm(fa)} {g(na)} mol と {fm(fb)} {g(nb)} mol を反応させた。反応後に残る物質とその量は？', ans, wr,
                    f'係数比 {ca}:{cb}。{fm(fa)} {g(na)} mol と反応する {fm(fb)} は {g(need_b)} mol。'))
    out += [
        (K, '化学反応式の係数の比が表すものは？', '反応する物質の物質量（粒子数）の比', ['質量の比', '密度の比', '原子量の比'], '気体なら同温同圧で体積比も等しい。'),
        (T, '化学反応式の係数の比が質量の比にならない理由は？', '物質ごとにモル質量がちがうから', ['反応で質量がなくなるから', '気体は質量がないから', '係数は体積だけを表すから'], '質量＝物質量×モル質量。'),
        (K, '化学反応の前後で、物質全体の質量の総和が変わらないという法則は？', '質量保存の法則', ['定比例の法則', '倍数比例の法則', 'アボガドロの法則'], 'ラボアジエ。'),
        (K, '同温・同圧で同体積の気体には、同数の分子が含まれるという法則は？', 'アボガドロの法則', ['質量保存の法則', '気体反応の法則', 'ボイルの法則'], '気体反応の法則（ゲーリュサック）を説明した。'),
        (K, '気体どうしの反応で、反応・生成する気体の体積は簡単な整数比になるという法則は？', '気体反応の法則', ['定比例の法則', 'アボガドロの法則', '倍数比例の法則'], 'ゲーリュサックが発見。'),
        (T, 'マグネシウムを燃やすと、燃やす前より質量が増える理由は？', '空気中の酸素と結びつくから', ['熱で膨張するから', '質量保存の法則が成り立たないから', '水蒸気が出ていくから'], '2Mg＋O₂→2MgO。'),
    ]
    return out


import re
UNIT = re.compile(r'何 (mol/L|g/mol|g/L|mol|g|L)')
NUMERIC = re.compile(r'^[0-9.]+( × 10[⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+)?$')


def with_units(items):
    out = []
    for cat, prompt, ans, wrong, exp in items:
        m = UNIT.search(prompt)
        if m:
            u = ' ' + m.group(1)
            fix = lambda v: v + u if NUMERIC.match(v) else v
            ans, wrong = fix(ans), [fix(w) for w in wrong]
        out.append((cat, prompt, ans, wrong, exp))
    return out


def clean(x):
    d = F(x).denominator
    while d % 2 == 0:
        d //= 2
    while d % 5 == 0:
        d //= 5
    return d == 1


def write(prefix, items, size, tags):
    items = with_units(items)
    R.shuffle(items)
    n = -(-len(items) // size)
    size = -(-len(items) // n)
    total = 0
    for i, part in enumerate(chunks(items, size), 1):
        total += make_set(f'{prefix}_{i:02d}', 'science', part, tags, seed=i)
    return total


if __name__ == '__main__':
    t = write('science_shonan_104_chem_mole', mole_items(), 45, ['chemistry_basic', 'mole'])
    t += write('science_shonan_104_chem_solution', solution_items(), 45, ['chemistry_basic', 'concentration'])
    t += write('science_shonan_104_chem_reaction', reaction_items(), 45, ['chemistry_basic', 'reaction'])
    print('total', t)
