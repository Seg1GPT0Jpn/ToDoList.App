"""後期中間：学校の用語帳から、用語の4択の委員会セットを作る。

  cd rpg_game/tool/shonan_questions && python3 terms_gen.py <用語一覧のフォルダ>

用語一覧（kokyo.json・bio.json・chem.json・chiri.json・joho.json。VocabCard の JSON）は、
学校の用語帳（school-word-6〜10）と同じもの。平文の一覧はコミットしないので、手元のフォルダから読む。
「説明→用語」と「用語→説明」の両方を作り、まちがいの選択肢は同じ分野の用語から選ぶ。
最後に、curriculum/map.txt に書く行（セットID 範囲 既定の単元）を出す。
"""
import json
import os
import random
import sys

from common import make_set

K, T = 'knowledge', 'thinking'
CHUNK = 60  # 1セットの用語の数の上限（問題はその2倍）


def items_for(cards, pool, seed):
    rng = random.Random(seed)
    out = []
    for c in cards:
        same = [x for x in pool if x['g'] == c['g'] and x is not c]
        rest = [x for x in pool if x['g'] != c['g']]
        picks = rng.sample(same, min(3, len(same)))
        if len(picks) < 3:
            picks += rng.sample(rest, 3 - len(picks))
        out.append((K, f'{c["m"]}。これを何という？', c['t'], [x['t'] for x in picks], f'{c["t"]}：{c["m"]}。'))
        out.append((T, f'「{c["t"]}」の説明として正しいものは？', c['m'], [x['m'] for x in picks], f'{c["t"]}：{c["m"]}。'))
    return out


# (用語一覧, 世界, セットIDの前半, 科目, [(分野, 範囲, 既定の単元), ...])
PLAN = [
    ('chiri', 'social', 'social_shonan_104_geo', 'geography_general', [
        (['気候の基礎と大気の大循環', 'ケッペンの気候区分'], 'social.geo.nature.climate', 'social.geo.nature.climate'),
        (['気候に影響するしくみ', '植生と土壌'], 'social.geo.nature', 'social.geo.nature.soil'),
        (['衣食住', '宗教', '言語と民族'], 'social.geo.culture', 'social.geo.culture.religion'),
    ]),
    ('joho', 'information', 'information_shonan_104_info', 'information1', [
        (['情報デザイン', 'コンピュータのしくみ'], 'information.info', 'information.info.design.design'),
        (['論理回路', 'アルゴリズムとプログラム'], 'information.info', 'information.info.programming.program'),
    ]),
    ('kokyo', 'social', 'social_shonan_104_kokyo_terms', 'public_economy', [
        (['消費者問題'], 'social.pol.politics.law', 'social.pol.politics.law.consumer'),
        (['労働問題と雇用'], 'social.pol.politics.law', 'social.pol.politics.law.labor'),
        (['社会保障'], 'social.pol.economy.welfare', 'social.pol.economy.welfare.system'),
        (['国際経済'], 'social.pol.economy.global', 'social.pol.economy.global.trade'),
        (['国際経済体制と南北問題'], 'social.pol.economy.global', 'social.pol.economy.global.system'),
    ]),
    ('bio', 'science', 'science_shonan_104_bio_terms', 'biology_basic', [
        (['体液と循環', '腎臓と肝臓'], 'science.biology.body.homeostasis', 'science.biology.body.homeostasis.fluid'),
        (['神経系と自律神経', 'ホルモンと血糖・体温'], 'science.biology.body', 'science.biology.body.nerve.hormone'),
        (['免疫'], 'science.biology.body.immunity', 'science.biology.body.immunity.adaptive'),
        (['植生と遷移・バイオーム'], 'science.biology.ecology.vegetation', 'science.biology.ecology.vegetation.succession'),
    ]),
    ('chem', 'science', 'science_shonan_104_chem_terms', 'chemistry_basic', [
        (['物質量', '溶液の濃度'], 'science.chemistry.change.mole', 'science.chemistry.change.mole.mole'),
        (['化学変化と量的関係'], 'science.chemistry.change.equation', 'science.chemistry.change.equation.quantity'),
        (['酸と塩基'], 'science.chemistry.change.acid', 'science.chemistry.change.acid.define'),
    ]),
]


def main(src):
    lines = []
    for name, world, prefix, subject, parts in PLAN:
        cards = json.load(open(os.path.join(src, f'{name}.json'), encoding='utf-8'))
        i = 0
        for groups, rng, unit in parts:
            pool = [c for c in cards if c['g'] in groups]
            assert pool, groups
            n = -(-len(pool) // CHUNK)
            size = -(-len(pool) // n)
            for k in range(n):
                i += 1
                set_id = f'{prefix}_{i:02d}'
                make_set(set_id, world, items_for(pool[k * size:(k + 1) * size], pool, seed=i), [subject], seed=i)
                lines.append(f'{set_id} {rng} {unit}')
        print(prefix, i)
    print('\n'.join(lines))


if __name__ == '__main__':
    main(sys.argv[1])
