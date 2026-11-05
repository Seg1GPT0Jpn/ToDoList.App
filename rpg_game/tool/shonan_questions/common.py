"""湘南高校104回生の委員会セットを作るための共通部分。

各問は (category, prompt, 正解, [誤答...], 解説)。誤答が正解と同じになったものや重複は落とし、
4択にそろわない問題は捨てる（作り直しはジェネレータ側で数を多めに作って吸収する）。
"""
import json
import os
import random
from fractions import Fraction

QDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'questions')
SUP = str.maketrans('0123456789-', '⁰¹²³⁴⁵⁶⁷⁸⁹⁻')


def sup(n):
    return str(n).translate(SUP)


def frac(x):
    """分数を「3/4」「−2」のように書く"""
    x = Fraction(x)
    s = str(abs(x.numerator)) if x.denominator == 1 else f'{abs(x.numerator)}/{x.denominator}'
    return ('−' if x < 0 else '') + s


def num(x, digits=None):
    """数を表示する（整数はそのまま、小数は digits 桁で丸める）"""
    if isinstance(x, Fraction) and x.denominator == 1:
        x = int(x)
    if isinstance(x, int):
        return ('−' if x < 0 else '') + str(abs(x))
    if isinstance(x, Fraction):
        d = x.denominator
        while d % 2 == 0:
            d //= 2
        while d % 5 == 0:
            d //= 5
        if d != 1:
            return frac(x)
        x = float(x)
    if digits is not None:
        s = f'{abs(x):.{digits}f}'
    else:
        s = f'{abs(x):g}'
    return ('−' if x < 0 else '') + s


def make_set(set_id, world, items, tags, seed=0):
    rng = random.Random(seed)
    qs = []
    seen_prompts = set()
    for cat, prompt, ans, wrong, exp in items:
        if prompt in seen_prompts:
            continue
        choices = [ans]
        for w in wrong:
            if w not in choices:
                choices.append(w)
        if len(choices) < 4:
            continue
        choices = choices[:4]
        rng.shuffle(choices)
        seen_prompts.add(prompt)
        qs.append({
            'id': f'{set_id}_{len(qs) + 1:03d}',
            'category': cat,
            'prompt': prompt,
            'choices': choices,
            'answerIndex': choices.index(ans),
            'explanation': exp,
            'targetGrade': '1',
            'phase': 'teikiTest',
            'tags': ['shonan-hs-104', 'kouki-chukan', *tags],
        })
    path = os.path.join(QDIR, world, f'{set_id}.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump({'setId': set_id, 'worldId': world, 'origin': 'original', 'version': 1, 'questions': qs},
                  f, ensure_ascii=False, indent=2)
    print(set_id, len(qs))
    return len(qs)


def chunks(items, size):
    return [items[i:i + size] for i in range(0, len(items), size)]
