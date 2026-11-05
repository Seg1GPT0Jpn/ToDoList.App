"""化学基礎（酸と塩基・水素イオン濃度／中和と塩／化学の基本法則）の委員会セットを作る。

  cd rpg_game/tool/shonan_questions && python3 chem2_gen.py

水のイオン積 Kw=1.0×10⁻¹⁴ (mol/L)²（25℃）。計算の答えはすべてこのプログラムで求める。
問題文は教材を写さず、ここで新しく書いたもの。単元（"unit"）は問題ごとに決めて固定する。
"""
import json
import os
import random
from fractions import Fraction as F

QDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'questions', 'science')
K, C, T = 'knowledge', 'calculation', 'thinking'
DEF, PH, NEU, SALT = ('science.chemistry.change.acid.define', 'science.chemistry.change.acid.ph',
                      'science.chemistry.change.acid.neutral', 'science.chemistry.change.acid.salt')
EQ = 'science.chemistry.change.equation.write'
SUP = str.maketrans('0123456789-', '⁰¹²³⁴⁵⁶⁷⁸⁹⁻')
SUB = str.maketrans('0123456789', '₀₁₂₃₄₅₆₇₈₉')


def fm(s):
    return s.translate(SUB)


def e10(n, m='1.0'):
    return f'{m} × 10{str(n).translate(SUP)}'


def mL(x):
    x = F(x)
    return f'{float(x):g} mL' if (x * 100).denominator == 1 else f'{float(x):.1f} mL'


ACIDS = [('塩化水素', 'HCl', 1, '強'), ('硝酸', 'HNO3', 1, '強'), ('硫酸', 'H2SO4', 2, '強'),
         ('臭化水素', 'HBr', 1, '強'), ('ヨウ化水素', 'HI', 1, '強'), ('フッ化水素', 'HF', 1, '弱'),
         ('酢酸', 'CH3COOH', 1, '弱'), ('硫化水素', 'H2S', 2, '弱'), ('シュウ酸', '(COOH)2', 2, '弱'),
         ('リン酸', 'H3PO4', 3, '中程度の強さ（ふつう弱酸）')]
BASES = [('水酸化ナトリウム', 'NaOH', 1, '強'), ('水酸化カリウム', 'KOH', 1, '強'),
         ('水酸化カルシウム', 'Ca(OH)2', 2, '強'), ('水酸化バリウム', 'Ba(OH)2', 2, '強'),
         ('アンモニア', 'NH3', 1, '弱'), ('水酸化マグネシウム', 'Mg(OH)2', 2, '弱'),
         ('水酸化銅(Ⅱ)', 'Cu(OH)2', 2, '弱'), ('水酸化アルミニウム', 'Al(OH)3', 3, '弱')]


def acid_items():
    it = []
    a = lambda *x: it.append(x)
    a(DEF, K, 'アレニウスの定義で「酸」とは？', '水に溶けて電離し、水素イオン H⁺ を生じる物質',
      ['水に溶けて電離し、水酸化物イオン OH⁻ を生じる物質', '相手から H⁺ を受け取る物質', '電子を受け取る物質'], 'H⁺ は水中で H₂O と結びついて H₃O⁺ になっている。')
    a(DEF, K, 'アレニウスの定義で「塩基」とは？', '水に溶けて電離し、水酸化物イオン OH⁻ を生じる物質',
      ['水に溶けて電離し、水素イオン H⁺ を生じる物質', '相手に H⁺ を与える物質', '水に溶けない物質'], '例：NaOH → Na⁺ ＋ OH⁻')
    a(DEF, K, 'ブレンステッド・ローリーの定義で「酸」とは？', '反応する相手に H⁺ を与える物質',
      ['反応する相手から H⁺ を受け取る物質', '水に溶けて OH⁻ を生じる物質', '電子を与える物質'], '塩基は相手から H⁺ を受け取る物質。')
    a(DEF, K, 'ブレンステッド・ローリーの定義で「塩基」とは？', '反応する相手から H⁺ を受け取る物質',
      ['反応する相手に H⁺ を与える物質', '水に溶けて H⁺ を生じる物質', '電子を受け取る物質'], '水溶液でなくても使える定義。')
    a(DEF, K, '水溶液中で H⁺ が水分子と結びついてできるイオン H₃O⁺ を何という？', 'オキソニウムイオン',
      ['アンモニウムイオン', 'ヒドロキシドイオン', '水酸化物イオン'], 'H⁺ と H₂O は配位結合でつながる。')
    a(DEF, K, '塩基のうち、水によく溶けるものを何という？', 'アルカリ', ['オキソ酸', '塩', '酸化物'], 'NaOH・KOH・Ca(OH)₂ など。')
    for name, f, v, s in ACIDS:
        a(DEF, K, f'{name} {fm(f)} は何価の酸？', f'{v}価', [f'{x}価' for x in (1, 2, 3, 4) if x != v], '化学式の中で H⁺ になれる H の数が価数。')
    for name, f, v, s in BASES:
        a(DEF, K, f'{name} {fm(f)} は何価の塩基？', f'{v}価', [f'{x}価' for x in (1, 2, 3, 4) if x != v],
          'NH₃ は水と反応して OH⁻ を1個生じるので1価。' if f == 'NH3' else '化学式の中で OH⁻ になれる OH の数が価数。')
    a(DEF, K, '酢酸 CH₃COOH が1価の酸である理由は？', 'CH₃ の部分の H は電離しにくく、COOH の H だけが H⁺ になるから',
      ['分子に H が1個しかないから', '酸素を2個もつから', '水に溶けにくいから'], 'H の数＝価数とは限らない。')
    strong_a = [fm(f) for _, f, _, s in ACIDS if s == '強']
    weak_a = [fm(f) for _, f, _, s in ACIDS if s == '弱']
    strong_b = [fm(f) for _, f, _, s in BASES if s == '強']
    weak_b = [fm(f) for _, f, _, s in BASES if s == '弱']
    for x in strong_a:
        a(DEF, K, '次のうち、強酸はどれ？', x, random.Random(x).sample(weak_a, 3), '強酸：HCl・HBr・HI・HNO₃・H₂SO₄')
    for x in weak_a:
        a(DEF, K, '次のうち、弱酸はどれ？', x, random.Random(x).sample(strong_a, 3), '弱酸：HF・CH₃COOH・H₂S・(COOH)₂ など')
    for x in strong_b:
        a(DEF, K, '次のうち、強塩基はどれ？', x, random.Random(x).sample(weak_b, 3), '強塩基：NaOH・KOH・Ca(OH)₂・Ba(OH)₂')
    for x in weak_b:
        a(DEF, K, '次のうち、弱塩基はどれ？', x, random.Random(x).sample(strong_b, 3), '弱塩基：NH₃・Mg(OH)₂・Cu(OH)₂・Al(OH)₃')
    for eq, sp, role, why in [
        ('NH₃ ＋ H₂O ⇄ NH₄⁺ ＋ OH⁻', 'H₂O', '酸', 'H₂O が NH₃ に H⁺ を与えている。'),
        ('NH₃ ＋ H₂O ⇄ NH₄⁺ ＋ OH⁻', 'NH₃', '塩基', 'NH₃ が H₂O から H⁺ を受け取っている。'),
        ('CO₃²⁻ ＋ H₂O ⇄ HCO₃⁻ ＋ OH⁻', 'CO₃²⁻', '塩基', 'CO₃²⁻ が H₂O から H⁺ を受け取っている。'),
        ('HCl ＋ H₂O → H₃O⁺ ＋ Cl⁻', 'H₂O', '塩基', 'H₂O が HCl から H⁺ を受け取っている。'),
        ('HCl ＋ NH₃ → NH₄⁺ ＋ Cl⁻', 'NH₃', '塩基', 'NH₃ が HCl から H⁺ を受け取っている。'),
        ('HCl ＋ NH₃ → NH₄⁺ ＋ Cl⁻', 'HCl', '酸', 'HCl が NH₃ に H⁺ を与えている。'),
        ('CH₃COOH ＋ H₂O ⇄ CH₃COO⁻ ＋ H₃O⁺', 'H₂O', '塩基', 'H₂O が CH₃COOH から H⁺ を受け取っている。')]:
        a(DEF, T, f'反応 {eq} で、{sp} はブレンステッド・ローリーの定義で酸・塩基のどちら？', role,
          ['塩基' if role == '酸' else '酸', 'どちらでもない', '両方'], why + ' 水は相手によって酸にも塩基にもなる。')
    a(DEF, K, '電離度 α の説明として正しいものは？', '溶かした酸（塩基）のうち、電離したものの割合（0 < α ≦ 1）',
      ['水溶液の水素イオン濃度', '溶かした酸の質量', '酸の価数'], 'α がほぼ1のものが強酸（強塩基）。')
    a(DEF, K, '弱酸の水溶液をうすめる（希釈する）と、電離度はふつうどうなる？', '大きくなる', ['小さくなる', '変わらない', '0になる'], '濃度が小さいほど電離しやすくなる。')
    a(DEF, T, 'リン酸 H₃PO₄ は3価の酸だが、強酸ではない。このことから言えるのは？', '酸の強弱は価数ではなく、電離度の大小で決まる',
      ['価数が大きいほど強い酸である', '3価の酸はすべて弱酸である', '酸素を含む酸は弱酸である'], '強酸は電離度がほぼ1。')
    a(PH, K, '25℃での水のイオン積 Kw＝[H⁺][OH⁻] の値は？', e10(-14) + ' (mol/L)²', [e10(-7) + ' (mol/L)²', e10(-1) + ' (mol/L)²', e10(14) + ' (mol/L)²'],
      '水だけでなく、酸や塩基の水溶液でも成り立つ。')
    a(PH, K, '25℃で中性の水溶液の [H⁺] と pH の組み合わせは？', '[H⁺]＝' + e10(-7) + ' mol/L、pH＝7', ['[H⁺]＝' + e10(-14) + ' mol/L、pH＝14', '[H⁺]＝1.0 mol/L、pH＝0', '[H⁺]＝' + e10(-7) + ' mol/L、pH＝0'], '[H⁺]＝[OH⁻]＝1.0×10⁻⁷ mol/L')
    a(PH, K, '酸性が強くなるほど pH の値はどうなる？', '小さくなる', ['大きくなる', '7に近づく', '変わらない'], 'pH＝−log₁₀[H⁺]。')
    a(PH, K, 'pH を表す式は？', 'pH＝−log₁₀[H⁺]', ['pH＝log₁₀[H⁺]', 'pH＝−log₁₀[OH⁻]', 'pH＝[H⁺]×[OH⁻]'], '[H⁺]＝1.0×10⁻ᵃ mol/L なら pH＝a')
    a(PH, K, 'pH が1小さくなると、[H⁺] は何倍になる？', '10倍', ['2倍', '1/10倍', '100倍'], 'pH が1ちがうと [H⁺] は10倍ちがう。')
    # 計算：強酸
    for name, f, v in [('塩酸', 'HCl', 1), ('硝酸', 'HNO3', 1)]:
        for n in (1, 2, 3):
            a(PH, C, f'{e10(-n)} mol/L の{name}の pH は？（完全に電離する）', f'{n}', [str(x) for x in (n + 1, n - 1 if n > 1 else n + 2, 14 - n)],
              f'[H⁺]＝{e10(-n)} mol/L なので pH＝{n}')
    a(PH, C, '5.0 × 10⁻³ mol/L の硫酸の [H⁺] は？（完全に電離する）', e10(-2) + ' mol/L', ['5.0 × 10⁻³ mol/L', '2.5 × 10⁻³ mol/L', e10(-3) + ' mol/L'], '2価なので [H⁺]＝2×5.0×10⁻³＝1.0×10⁻² mol/L')
    a(PH, C, '5.0 × 10⁻³ mol/L の硫酸の pH は？（完全に電離する）', '2', ['3', '2.5', '12'], '[H⁺]＝1.0×10⁻² mol/L なので pH＝2')
    a(PH, C, '0.010 mol/L の硫酸の [H⁺] は？（完全に電離する）', '0.020 mol/L', ['0.010 mol/L', '0.0050 mol/L', '0.040 mol/L'], '2価なので2倍。')
    # 弱酸
    for c, al, h in [(F(1, 10), F(1, 100), 3), (F(1, 10), F(16, 1000), None), (F(5, 100), F(2, 100), 3), (F(1, 100), F(1, 10), 3), (F(1, 10), F(1, 1000), 4)]:
        hv = c * al
        if h is None:
            a(PH, C, f'{float(c):g} mol/L の酢酸水溶液（電離度 {float(al):g}）の [H⁺] は？', '1.6 × 10⁻³ mol/L',
              ['1.6 × 10⁻² mol/L', '0.10 mol/L', '1.6 × 10⁻⁴ mol/L'], '[H⁺]＝cα＝0.10×0.016＝1.6×10⁻³ mol/L')
        else:
            a(PH, C, f'{float(c):g} mol/L の酢酸水溶液（電離度 {float(al):g}）の pH は？', str(h),
              [str(x) for x in (h - 1, h + 1, 1)] if h != 2 else ['1', '3', '4'], f'[H⁺]＝cα＝{float(c):g}×{float(al):g}＝{e10(-h)} mol/L なので pH＝{h}')
    # 強塩基・弱塩基
    for n in (1, 2, 3):
        a(PH, C, f'{e10(-n)} mol/L の水酸化ナトリウム水溶液の pH は？', str(14 - n), [str(n), str(13 - n), str(15 - n) if n > 1 else '7'],
          f'[OH⁻]＝{e10(-n)}、[H⁺]＝Kw/[OH⁻]＝{e10(n - 14)} mol/L なので pH＝{14 - n}')
    a(PH, C, '5.0 × 10⁻³ mol/L の水酸化バリウム水溶液の pH は？（完全に電離する）', '12', ['2', '11', '13'], '2価なので [OH⁻]＝1.0×10⁻²、[H⁺]＝1.0×10⁻¹² mol/L')
    a(PH, C, '0.10 mol/L のアンモニア水（電離度 0.010）の pH は？', '11', ['3', '13', '12'], '[OH⁻]＝cα＝1.0×10⁻³、[H⁺]＝1.0×10⁻¹¹ mol/L')
    # 希釈
    for p, k in [(1, 1), (2, 2), (3, 2), (2, 1)]:
        a(PH, C, f'pH＝{p} の塩酸を水で {10 ** k} 倍にうすめた。pH は？', str(p + k), [str(p), str(p + k + 1), str(p - k) if p - k > 0 else str(p + 2 * k)],
          f'[H⁺] が 1/{10 ** k} になるので pH は {k} 大きくなる。')
    a(PH, T, 'pH＝5 の塩酸を水で1000倍にうすめた。pH はおよそいくつ？', '7に近い値（7より小さい）', ['8', '2', '5'], '酸をいくらうすめても塩基性にはならない。水の電離が無視できなくなる。')
    a(PH, C, '1.0 × 10⁻² mol/L の塩酸 1 mL に水を加えて 100 mL にすると pH は？', '4', ['2', '3', '6'], '100倍にうすまり [H⁺]＝1.0×10⁻⁴ mol/L')
    for p in (1, 3, 9, 12):
        a(PH, C, f'pH＝{p} の水溶液の [H⁺] は？', e10(-p) + ' mol/L', [e10(p - 14) + ' mol/L', e10(p) + ' mol/L', e10(-(p + 1)) + ' mol/L'], f'[H⁺]＝1.0×10⁻{p} mol/L（pH の数字が指数になる）')
    a(PH, C, 'pH＝9 の水溶液の [OH⁻] は？', e10(-5) + ' mol/L', [e10(-9) + ' mol/L', e10(-14) + ' mol/L', e10(-7) + ' mol/L'], '[H⁺]＝1.0×10⁻⁹、[OH⁻]＝Kw/[H⁺]＝1.0×10⁻⁵ mol/L')
    for eq, ans, w in [('HNO₃', 'HNO₃ → H⁺ ＋ NO₃⁻', ['HNO₃ → H⁺ ＋ NO₂⁻ ＋ O', 'HNO₃ → 3H⁺ ＋ NO₃³⁻', 'HNO₃ → H₂O ＋ NO₂']),
                       ('H₂SO₄（2段階をまとめて）', 'H₂SO₄ → 2H⁺ ＋ SO₄²⁻', ['H₂SO₄ → H⁺ ＋ SO₄⁻', 'H₂SO₄ → 2H⁺ ＋ S²⁻ ＋ 2O₂', 'H₂SO₄ → H₂O ＋ SO₃']),
                       ('Ca(OH)₂', 'Ca(OH)₂ → Ca²⁺ ＋ 2OH⁻', ['Ca(OH)₂ → Ca⁺ ＋ OH⁻', 'Ca(OH)₂ → Ca²⁺ ＋ 2O²⁻ ＋ 2H⁺', 'Ca(OH)₂ → CaO ＋ H₂O']),
                       ('CH₃COOH', 'CH₃COOH ⇄ CH₃COO⁻ ＋ H⁺', ['CH₃COOH → 4H⁺ ＋ C₂O₂⁴⁻', 'CH₃COOH ⇄ CH₃⁺ ＋ COOH⁻', 'CH₃COOH → CH₃CO⁺ ＋ OH⁻']),
                       ('NH₃（水との反応）', 'NH₃ ＋ H₂O ⇄ NH₄⁺ ＋ OH⁻', ['NH₃ → N³⁻ ＋ 3H⁺', 'NH₃ ＋ H₂O → NH₂⁻ ＋ H₃O⁺', 'NH₃ ⇄ NH₂ ＋ H'])]:
        a(DEF, K, f'{eq} の電離を表す式として正しいものは？', ans, w, '弱酸・弱塩基は ⇄ で表す。')
    return it


def neutral_items():
    it = []
    a = lambda *x: it.append(x)
    a(NEU, K, '中和で、塩とともに生じるものは？', '水', ['水素', '酸素', '二酸化炭素'], '酸の H⁺ と塩基の OH⁻ から水ができる。')
    a(NEU, K, '中和の本質を表すイオン反応式は？', 'H⁺ ＋ OH⁻ → H₂O', ['Na⁺ ＋ Cl⁻ → NaCl', '2H⁺ ＋ O²⁻ → H₂O', 'H₂ ＋ O₂ → H₂O₂'], '')
    for acid, base, salt, eq in [('HCl', 'NaOH', 'NaCl', 'HCl ＋ NaOH → NaCl ＋ H₂O'), ('H₂SO₄', 'NaOH', 'Na₂SO₄', 'H₂SO₄ ＋ 2NaOH → Na₂SO₄ ＋ 2H₂O'),
                                 ('HNO₃', 'KOH', 'KNO₃', 'HNO₃ ＋ KOH → KNO₃ ＋ H₂O'), ('CH₃COOH', 'NaOH', 'CH₃COONa', 'CH₃COOH ＋ NaOH → CH₃COONa ＋ H₂O'),
                                 ('HCl', 'NH₃', 'NH₄Cl', 'HCl ＋ NH₃ → NH₄Cl'), ('H₂SO₄', 'Ca(OH)₂', 'CaSO₄', 'H₂SO₄ ＋ Ca(OH)₂ → CaSO₄ ＋ 2H₂O'),
                                 ('HCl', 'Ba(OH)₂', 'BaCl₂', '2HCl ＋ Ba(OH)₂ → BaCl₂ ＋ 2H₂O')]:
        others = ['NaCl', 'Na₂SO₄', 'KNO₃', 'CH₃COONa', 'NH₄Cl', 'CaSO₄', 'BaCl₂', 'NaHSO₄']
        a(NEU, K, f'{acid} と {base} の中和でできる塩は？', salt, random.Random(salt).sample([o for o in others if o != salt], 3), eq)
    a(NEU, K, '硫酸 H₂SO₄ 1 mol を過不足なく中和する水酸化ナトリウムは何 mol？', '2 mol', ['1 mol', '0.5 mol', '4 mol'], 'H₂SO₄ ＋ 2NaOH → Na₂SO₄ ＋ 2H₂O')
    for salt, kind in [('NaCl', '正塩'), ('Na₂SO₄', '正塩'), ('CH₃COONa', '正塩'), ('NH₄Cl', '正塩'), ('Na₂CO₃', '正塩'),
                       ('NaHSO₄', '酸性塩'), ('NaHCO₃', '酸性塩'), ('MgCl(OH)', '塩基性塩'), ('CuCl(OH)', '塩基性塩')]:
        a(SALT, K, f'{salt} は、化学式の形からどの塩に分類される？', kind, [k for k in ('正塩', '酸性塩', '塩基性塩', '複塩') if k != kind][:3],
          '酸の H が残る→酸性塩、塩基の OH が残る→塩基性塩、どちらも残らない→正塩。水溶液の性質（液性）とは別。')
    a(SALT, T, '酸性塩 NaHCO₃ の水溶液の液性は？', '弱い塩基性', ['酸性', '中性', '強い酸性'], '分類の名前（酸性塩）と液性は一致しない。')
    for salt, liq, why in [('NaCl', '中性', '強酸＋強塩基の塩'), ('Na₂SO₄', '中性', '強酸＋強塩基の塩'), ('KNO₃', '中性', '強酸＋強塩基の塩'),
                           ('CH₃COONa', '塩基性', '弱酸＋強塩基の塩。CH₃COO⁻ が水と反応して OH⁻ を生じる'), ('Na₂CO₃', '塩基性', '弱酸＋強塩基の塩'),
                           ('NH₄Cl', '酸性', '強酸＋弱塩基の塩。NH₄⁺ が水と反応して H₃O⁺ を生じる'), ('(NH₄)₂SO₄', '酸性', '強酸＋弱塩基の塩'),
                           ('NaHSO₄', '酸性', 'HSO₄⁻ が電離して H⁺ を生じる'), ('CuSO₄', '酸性', '強酸＋弱塩基の塩')]:
        a(SALT, K, f'{salt} の水溶液の液性は？', liq, [x for x in ('酸性', '中性', '塩基性', '両性') if x != liq][:3], why + '。')
    a(SALT, K, '弱酸と強塩基からできた塩の水溶液が塩基性を示すのは、何という反応のため？', '塩の加水分解', ['中和', '電気分解', '酸化'], '弱酸の陰イオンが水と反応して OH⁻ を生じる。')
    for ox, kind in [('CO₂', '酸性酸化物'), ('SO₂', '酸性酸化物'), ('SO₃', '酸性酸化物'), ('P₄O₁₀', '酸性酸化物'), ('NO₂', '酸性酸化物'),
                     ('Na₂O', '塩基性酸化物'), ('CaO', '塩基性酸化物'), ('MgO', '塩基性酸化物'), ('CuO', '塩基性酸化物'),
                     ('Al₂O₃', '両性酸化物'), ('ZnO', '両性酸化物')]:
        a(SALT, K, f'{ox} はどの酸化物に分類される？', kind, [x for x in ('酸性酸化物', '塩基性酸化物', '両性酸化物', '過酸化物') if x != kind][:3],
          '非金属元素の酸化物は多くが酸性酸化物、金属元素の酸化物は多くが塩基性酸化物。Al・Zn などは両性。')
    a(SALT, K, '二酸化炭素 CO₂ が水と反応してできる酸は？', '炭酸 H₂CO₃', ['塩酸 HCl', '酢酸 CH₃COOH', '硫酸 H₂SO₄'], 'CO₂ ＋ H₂O ⇄ H₂CO₃')
    a(SALT, K, '三酸化硫黄 SO₃ が水と反応してできる酸は？', '硫酸 H₂SO₄', ['亜硫酸 H₂SO₃', '硫化水素 H₂S', '硝酸 HNO₃'], 'SO₃ ＋ H₂O → H₂SO₄')
    a(SALT, K, '酸化カルシウム CaO が水と反応してできる物質は？', '水酸化カルシウム Ca(OH)₂', ['炭酸カルシウム CaCO₃', '塩化カルシウム CaCl₂', 'カルシウム Ca'], '塩基性酸化物は水と反応して塩基になる。')
    for x, yes in [('H₂SO₄', True), ('HNO₃', True), ('H₃PO₄', True), ('H₂CO₃', True), ('HCl', False), ('H₂S', False)]:
        a(SALT, K, f'{x} はオキソ酸（分子中に酸素原子を含む酸）か？', 'オキソ酸である' if yes else 'オキソ酸ではない',
          ['オキソ酸ではない' if yes else 'オキソ酸である', '塩基である', '塩である'], 'オキソ酸は酸性酸化物と水の反応などで生じる。')
    a(SALT, T, '酢酸ナトリウムに塩酸を加えると何が起こる？', '弱酸の酢酸が遊離する（CH₃COONa ＋ HCl → CH₃COOH ＋ NaCl）',
      ['強酸の塩酸が遊離する', '水素が発生する', '何も起こらない'], '弱酸の塩＋強酸 → 強酸の塩＋弱酸')
    a(SALT, T, '塩化アンモニウムに水酸化ナトリウムを加えて温めると発生する気体は？', 'アンモニア NH₃', ['塩化水素 HCl', '水素 H₂', '塩素 Cl₂'], '弱塩基の塩＋強塩基 → 強塩基の塩＋弱塩基（NH₄Cl ＋ NaOH → NaCl ＋ H₂O ＋ NH₃）')
    a(SALT, T, '炭酸カルシウムに塩酸を加えると発生する気体は？', '二酸化炭素 CO₂', ['水素 H₂', '酸素 O₂', '塩素 Cl₂'], 'CaCO₃ ＋ 2HCl → CaCl₂ ＋ H₂O ＋ CO₂（弱酸の遊離）')
    # 量的関係：a c V = b c' V'
    R = random.Random(7)
    cases = [('塩酸', 1, F(1, 10), 10, '水酸化ナトリウム水溶液', 1, F(1, 10)), ('硫酸', 2, F(5, 100), 10, '水酸化ナトリウム水溶液', 1, F(1, 10)),
             ('硫酸', 2, F(1, 10), 20, '水酸化ナトリウム水溶液', 1, F(2, 10)), ('塩酸', 1, F(2, 10), 15, '水酸化バリウム水溶液', 2, F(1, 10)),
             ('酢酸水溶液', 1, F(1, 10), 10, '水酸化ナトリウム水溶液', 1, F(5, 100)), ('硝酸', 1, F(1, 10), 25, '水酸化カルシウム水溶液', 2, F(5, 100)),
             ('シュウ酸水溶液', 2, F(5, 100), 10, '水酸化ナトリウム水溶液', 1, F(1, 10)), ('塩酸', 1, F(3, 10), 10, 'アンモニア水', 1, F(1, 10))]
    for an, av, ac, avol, bn, bv, bc in cases:
        vb = F(av) * ac * avol / (bv * bc)
        wr = [mL(vb * 2), mL(vb / 2), mL(F(avol) * ac / bc)]
        a(NEU, C, f'{float(ac):g} mol/L の{an} {avol} mL を中和するのに必要な {float(bc):g} mol/L の{bn}は何 mL？', mL(vb),
          [w for w in wr if w != mL(vb)] + [mL(vb + 5)], f'(酸の価数)×c×V＝(塩基の価数)×c\'×V\' より {av}×{float(ac):g}×{avol}＝{bv}×{float(bc):g}×V\'')
    for an, av, avol, bn, bv, bc, bvol in [('塩酸', 1, 10, '水酸化ナトリウム水溶液', 1, F(1, 10), 12), ('硫酸', 2, 10, '水酸化ナトリウム水溶液', 1, F(1, 10), 16),
                                           ('酢酸水溶液', 1, 10, '水酸化ナトリウム水溶液', 1, F(1, 10), 8), ('硫酸', 2, 20, '水酸化ナトリウム水溶液', 1, F(2, 10), 10)]:
        c = F(bv) * bc * bvol / (av * avol)
        ans = f'{float(c):.3f} mol/L'.replace('0.', '0.', 1)
        def fmt(x):
            return f'{float(x):.3g} mol/L'
        a(NEU, C, f'濃度のわからない{an} {avol} mL を {float(bc):g} mol/L の{bn}で滴定したら {bvol} mL で中和した。{an}の濃度は？', fmt(c),
          [fmt(c * 2), fmt(c / 2), fmt(c * F(av) * 3)], f'{av}×c×{avol}＝{bv}×{float(bc):g}×{bvol}')
    a(NEU, K, '一定体積の溶液を正確にはかり取る器具は？', 'ホールピペット', ['ビュレット', 'メスシリンダー', 'コニカルビーカー'], '中和滴定で酸（塩基）を正確にはかり取るのに使う。')
    a(NEU, K, '滴下した液体の体積をはかる器具は？', 'ビュレット', ['ホールピペット', 'メスフラスコ', '駒込ピペット'], 'コックを開いて少しずつ滴下する。')
    a(NEU, K, '正確な濃度の溶液を調製する（うすめる）ときに使う器具は？', 'メスフラスコ', ['ビュレット', 'ビーカー', '試験管'], '標線まで水を入れる。')
    a(NEU, K, '中和滴定で、内部が水でぬれたまま使ってよい器具の組み合わせは？', 'メスフラスコとコニカルビーカー', ['ホールピペットとビュレット', 'ビュレットとメスフラスコ', 'ホールピペットとコニカルビーカー'],
      '中の物質量が変わらないので水でぬれていてよい。')
    a(NEU, K, 'ホールピペットやビュレットを、これから入れる溶液で数回すすいでから使う操作を何という？', '共洗い', ['空洗い', '中和', '希釈'], '水でぬれたままだと溶液がうすまって濃度が変わるため。')
    a(NEU, K, 'フェノールフタレインの変色域と色の変化は？', 'pH 8.0〜9.8で、無色→赤色', ['pH 3.1〜4.4で、赤色→黄色', 'pH 6〜8で、黄色→青色', 'pH 1〜2で、無色→青色'], '塩基性側で変色する。')
    a(NEU, K, 'メチルオレンジの変色域と色の変化は？', 'pH 3.1〜4.4で、赤色→黄色', ['pH 8.0〜9.8で、無色→赤色', 'pH 6〜8で、黄色→青色', 'pH 11〜12で、赤色→無色'], '酸性側で変色する。')
    for pair, ind, why in [('酢酸水溶液を水酸化ナトリウム水溶液で滴定する', 'フェノールフタレイン', '中和点が塩基性側（弱酸＋強塩基）'),
                           ('アンモニア水を塩酸で滴定する', 'メチルオレンジ', '中和点が酸性側（強酸＋弱塩基）'),
                           ('塩酸を水酸化ナトリウム水溶液で滴定する', 'フェノールフタレイン・メチルオレンジのどちらでもよい', 'pH が大きく変化する範囲が広い（強酸＋強塩基）')]:
        a(NEU, T, f'{pair}とき、指示薬として適切なものは？', ind,
          [x for x in ('フェノールフタレイン', 'メチルオレンジ', 'フェノールフタレイン・メチルオレンジのどちらでもよい', 'どちらも使えない') if x != ind][:3], why + '。')
    for pair, liq in [('強酸と強塩基', '中性'), ('弱酸と強塩基', '塩基性'), ('強酸と弱塩基', '酸性')]:
        a(NEU, T, f'{pair}の中和点の水溶液の液性は？', liq, [x for x in ('酸性', '中性', '塩基性', '両性') if x != liq][:3], '生じた塩の加水分解による。')
    a(NEU, K, '加えた酸や塩基の体積と、混合水溶液の pH の関係を表すグラフを何という？', '中和滴定曲線', ['溶解度曲線', '状態図', '加熱曲線'], '中和点付近で pH が急に変化する。')
    a(NEU, T, '逆滴定とは？', '過剰の酸（塩基）と反応させ、残った酸（塩基）を別の塩基（酸）で滴定して、もとの量を求める方法',
      ['滴定をはじめからやり直すこと', '指示薬を2種類使う滴定', '塩基を酸で滴定すること'], '例：気体のアンモニアを過剰の硫酸に吸収させ、残った硫酸を NaOH で滴定する。')
    a(NEU, C, 'アンモニアを 0.050 mol/L の硫酸 20 mL にすべて吸収させ、残った硫酸を 0.10 mol/L の NaOH で中和したら 10 mL 必要だった。アンモニアは何 mol？', '1.0 × 10⁻³ mol',
      ['2.0 × 10⁻³ mol', '1.5 × 10⁻³ mol', '5.0 × 10⁻⁴ mol'], 'H⁺ の量＝2×0.050×0.020＝2.0×10⁻³ mol、OH⁻＝NH₃＋NaOH より NH₃＝2.0×10⁻³−0.10×0.010＝1.0×10⁻³ mol')
    a(NEU, T, '炭酸ナトリウム水溶液を塩酸で滴定すると、中和点が2回あらわれる。1回目（フェノールフタレインの変色）までに起こる反応は？', 'Na₂CO₃ ＋ HCl → NaHCO₃ ＋ NaCl',
      ['NaHCO₃ ＋ HCl → NaCl ＋ H₂O ＋ CO₂', 'Na₂CO₃ ＋ 2HCl → 2NaCl ＋ H₂O ＋ CO₂', 'NaCl ＋ H₂O → NaOH ＋ HCl'], '2回目（メチルオレンジの変色）までに NaHCO₃ ＋ HCl → NaCl ＋ H₂O ＋ CO₂')
    a(NEU, T, '炭酸ナトリウムの二段階滴定で、1回目の中和点までと、1回目から2回目までに要する塩酸の体積の関係は？', '等しい',
      ['1回目のほうが2倍多い', '2回目のほうが2倍多い', '関係はない'], 'どちらも Na₂CO₃ と同じ物質量の HCl が反応する。')
    return it


def laws_items():
    it = []
    a = lambda *x: it.append(x)
    for law, who in [('質量保存の法則', 'ラボアジエ'), ('定比例の法則', 'プルースト'), ('倍数比例の法則', 'ドルトン'),
                     ('気体反応の法則', 'ゲーリュサック'), ('アボガドロの法則', 'アボガドロ')]:
        a(EQ, K, f'{law}を発見（提唱）した人物は？', who, [x for x in ('ラボアジエ', 'プルースト', 'ドルトン', 'ゲーリュサック', 'アボガドロ') if x != who][:3], '')
    for d, law in [('化学反応の前後で、物質の質量の総和は変わらない', '質量保存の法則'), ('化合物を構成する成分元素の質量比は、つねに一定である', '定比例の法則'),
                   ('2種類の元素からなる化合物が2種類以上あるとき、一方の元素の一定質量と結びつく他方の元素の質量は、簡単な整数比になる', '倍数比例の法則'),
                   ('気体どうしの反応では、反応・生成する気体の体積は、同温・同圧で簡単な整数比になる', '気体反応の法則'),
                   ('同温・同圧で同体積の気体には、気体の種類によらず同数の分子が含まれる', 'アボガドロの法則')]:
        a(EQ, K, f'次の内容を表す法則は？　{d}。', law, [x for x in ('質量保存の法則', '定比例の法則', '倍数比例の法則', '気体反応の法則', 'アボガドロの法則') if x != law][:3], '')
    a(EQ, T, '倍数比例の法則の例として正しい組み合わせは？', '一酸化炭素 CO と二酸化炭素 CO₂', ['水 H₂O と塩化水素 HCl', '酸素 O₂ と窒素 N₂', '塩化ナトリウム NaCl と塩化カリウム KCl'],
      '炭素 12 g と結びつく酸素は 16 g と 32 g で、1:2 の整数比。')
    a(EQ, T, '気体反応の法則を、原子説だけでは説明できなかったのを解決するために提唱されたのは？', 'アボガドロの分子説', ['ドルトンの原子説', 'ラボアジエの燃焼理論', 'メンデレーエフの周期表'],
      '水素2体積と酸素1体積から水蒸気2体積ができることを、分子を考えて説明した。')
    a(EQ, C, '2H₂ ＋ O₂ → 2H₂O（気体）で、水素 4.0 L が反応すると水蒸気は同温・同圧で何 L 生じる？', '4.0 L', ['2.0 L', '8.0 L', '6.0 L'], '体積比＝係数比＝2:1:2')
    for ex, kind in [('氷がとけて水になる', '物理変化'), ('ドライアイスが昇華する', '物理変化'), ('食塩が水に溶ける', '物理変化'), ('ヨウ素が昇華する', '物理変化'),
                     ('鉄がさびる', '化学変化'), ('水を電気分解する', '化学変化'), ('紙が燃える', '化学変化'), ('炭酸水素ナトリウムを加熱する', '化学変化')]:
        a(EQ, K, f'「{ex}」は物理変化・化学変化のどちら？', kind, ['化学変化' if kind == '物理変化' else '物理変化', '状態変化ではない物理変化', 'どちらでもない'],
          '構成粒子の組み合わせが変わって別の物質になるのが化学変化。')
    a(EQ, K, '反応に関係しないイオンを省いて書いた化学反応式を何という？', 'イオン反応式', ['電離式', '熱化学方程式', '構造式'], '両辺で電荷の総和も等しくする。')
    a(EQ, K, '硝酸銀水溶液に塩化ナトリウム水溶液を加えたときのイオン反応式は？', 'Ag⁺ ＋ Cl⁻ → AgCl', ['Na⁺ ＋ NO₃⁻ → NaNO₃', 'Ag ＋ Cl → AgCl₂', 'AgNO₃ ＋ NaCl → AgCl ＋ NaNO₃'],
      '白色の沈殿 AgCl ができる。Na⁺ と NO₃⁻ は反応に関係しない。')
    return it


def write(prefix, items, size, tags, seed):
    rng = random.Random(seed)
    rng.shuffle(items)
    seen, total = set(), 0
    n = -(-len(items) // size)
    size = -(-len(items) // n)
    for k in range(n):
        part = items[k * size:(k + 1) * size]
        sid = f'{prefix}_{k + 1:02d}'
        qs = []
        for unit, cat, prompt, ans, wrong, exp in part:
            key = (prompt, ans)
            if key in seen:
                continue
            seen.add(key)
            ch = [ans] + [w for w in dict.fromkeys(wrong) if w != ans][:3]
            if len(ch) < 4:
                continue
            rng.shuffle(ch)
            qs.append({'id': f'{sid}_{len(qs) + 1:03d}', 'unit': unit, 'unitLocked': True, 'category': cat,
                       'prompt': prompt, 'choices': ch, 'answerIndex': ch.index(ans), 'explanation': exp or f'答え：{ans}',
                       'targetGrade': '1', 'phase': 'teikiTest', 'tags': ['shonan-hs-104', 'kouki-kimatsu', *tags]})
        with open(os.path.join(QDIR, sid + '.json'), 'w', encoding='utf-8') as f:
            json.dump({'setId': sid, 'worldId': 'science', 'origin': 'original', 'version': 1, 'questions': qs}, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print(sid, len(qs))
        total += len(qs)
    return total


if __name__ == '__main__':
    t = write('science_shonan_104_chem_acid', acid_items(), 45, ['chemistry_basic', 'acid'], 1)
    t += write('science_shonan_104_chem_neutral', neutral_items(), 45, ['chemistry_basic', 'neutral'], 2)
    t += write('science_shonan_104_chem_laws', laws_items(), 45, ['chemistry_basic', 'laws'], 3)
    print('total', t)
