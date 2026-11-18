"""地理総合・情報Ⅰ（後期中間）：用語の4択の委員会セットを作る。

  cd rpg_game/tool/shonan_questions && python3 terms_gen.py <用語一覧のフォルダ>

用語一覧（chiri.json・joho.json。VocabCard の JSON）は、学校の用語帳（school-word-8・9）と同じもの。
平文の一覧はコミットしないので、手元のフォルダから読む。
「説明→用語」と「用語→説明」の両方を作り、まちがいの選択肢は同じ分野の用語から選ぶ。
"""
import json
import os
import random
import sys

from common import make_set

K, T = 'knowledge', 'thinking'


def items_for(cards, seed):
    rng = random.Random(seed)
    by_group = {}
    for c in cards:
        by_group.setdefault(c['g'], []).append(c)
    out = []
    for c in cards:
        same = [x for x in by_group[c['g']] if x is not c]
        rest = [x for x in cards if x['g'] != c['g']]
        pool = rng.sample(same, min(3, len(same)))
        if len(pool) < 3:
            pool += rng.sample(rest, 3 - len(pool))
        out.append((K, f'{c["m"]}。これを何という？', c['t'], [x['t'] for x in pool], f'{c["t"]}：{c["m"]}。'))
        out.append((T, f'「{c["t"]}」の説明として正しいものは？', c['m'], [x['m'] for x in pool], f'{c["t"]}：{c["m"]}。'))
    return out


def main(src):
    plan = [
        ('chiri', 'social', 'social_shonan_104_geo', ['geography_general'], [
            ['気候の基礎と大気の大循環', 'ケッペンの気候区分'],
            ['気候に影響するしくみ', '植生と土壌'],
            ['衣食住', '宗教', '言語と民族'],
        ]),
        ('joho', 'information', 'information_shonan_104_info', ['information1'], [
            ['情報デザイン', 'コンピュータのしくみ'],
            ['論理回路', 'アルゴリズムとプログラム'],
        ]),
    ]
    for name, world, prefix, tags, parts in plan:
        cards = json.load(open(os.path.join(src, f'{name}.json'), encoding='utf-8'))
        for i, groups in enumerate(parts, 1):
            sel = [c for c in cards if c['g'] in groups]
            assert sel, groups
            make_set(f'{prefix}_{i:02d}', world, items_for(sel, seed=i), tags, seed=i)


if __name__ == '__main__':
    main(sys.argv[1])
