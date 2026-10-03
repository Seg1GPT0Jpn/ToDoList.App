#!/usr/bin/env python3
"""小中学生版のワールド・問題・学習体系をまとめて作る。

使い方:  python3 rpg_game/tool/junior/gen.py
そのあと python3 rpg_game/tool/curriculum/build.py と assign.py を動かす
（gen.py の最後で自動で動く）。
"""
import subprocess
import sys

import lib
from lib import World

import english
import japanese
import science
import social
import sea
import math_e
import math_j


# 定期テストの海の単元 → 英語の国の中1〜中3のエリア（学年, エリア番号）
SEA_AREA = {
    'sea_g1_01': (1, 1), 'sea_g1_02': (1, 4), 'sea_g1_03': (1, 3), 'sea_g1_04': (1, 6),
    'sea_g1_05': (1, 7), 'sea_g1_06': (1, 8), 'sea_g1_07': (1, 9), 'sea_g1_08': (1, 9),
    'sea_g2_01': (2, 1), 'sea_g2_02': (2, 2), 'sea_g2_03': (2, 3), 'sea_g2_04': (2, 4),
    'sea_g2_05': (2, 6), 'sea_g2_06': (2, 7), 'sea_g2_07': (2, 8), 'sea_g2_08': (2, 9),
    'sea_g3_01': (3, 1), 'sea_g3_02': (3, 3), 'sea_g3_03': (3, 6), 'sea_g3_04': (3, 7),
    'sea_g3_05': (3, 4), 'sea_g3_06': (3, 8), 'sea_g3_07': (3, 3),
}


def worlds():
    out = []

    W = World('english', 'EnglishCatalog', '英語の国', '英語', prefix='eng',
              hub='ことばの広場',
              sign='ここは英語の国の「ことばの広場」。左は小3・4、下は小5・小6、上は中1〜中3の道。'
                   '自分の学年の道から進もう。',
              desc='小3〜中3の英語。あいさつ・単語から、中学の文法・読み取りまで6つの道。',
              primary='meaning', secondary='usage', armor='usage',
              ref='小学校 外国語活動・外国語、中学校 外国語（英語）')
    english.build(W)
    out.append(W)

    W = World('math', 'MathCatalog', '数の国', '算数・数学', prefix='mat',
              hub='数の広場',
              sign='ここは数の国の「数の広場」。左は小1・小2、下は小3・小4、右は小5・小6、'
                   '上は中1〜中3の道。自分の学年の道から進もう。',
              desc='小1〜中3の算数・数学。計算・図形・関数・データの9つの道。',
              primary='calculation', secondary='thinking', armor='calculation',
              ref='小学校 算数・中学校 数学')
    math_e.build(W)
    math_j.build(W)
    out.append(W)

    W = World('japanese', 'JapaneseCatalog', '言の葉の国', '国語', prefix='jpn',
              hub='言の葉の広場',
              sign='ここは言の葉の国の「言の葉の広場」。左は小1・小2、下は小3・小4、右は小5・小6、'
                   '上は中1〜中3の道。漢字・言葉のきまり・古典・読解を、学年ごとに進もう。',
              desc='小1〜中3の国語。ひらがな・漢字から、文法・古典・読解まで9つの道。',
              primary='knowledge', secondary='thinking', armor='knowledge',
              ref='小学校 国語・中学校 国語')
    japanese.build(W)
    out.append(W)

    W = World('science', 'ScienceCatalog', '理の国', '理科', prefix='sci',
              hub='はじまりの実験広場',
              sign='ここは理の国の「はじまりの実験広場」。左は小3・小4、下は小5・小6、上は中1〜中3の道。'
                   '観察し、実験し、なぜそうなるかを考えよう。',
              desc='小3〜中3の理科。生き物・もの・エネルギー・地球の7つの道。',
              primary='knowledge', secondary='thinking', armor='knowledge',
              ref='小学校 理科・中学校 理科')
    science.build(W)
    out.append(W)

    W = World('social', 'SocialCatalog', '時と地の国', '社会', prefix='soc',
              hub='時の交差点',
              sign='ここは時と地の国の「時の交差点」。左は小3・小4、下は小5・小6、'
                   '上は中学の地理・歴史・公民の道。地図を読み、歴史をたどり、社会のしくみを考えよう。',
              desc='小3〜中3の社会。くらし・地理・歴史・公民の7つの道。',
              primary='knowledge', secondary='thinking', armor='knowledge',
              ref='小学校 社会・中学校 社会')
    social.build(W)
    out.append(W)

    # まだ問題を書いていない教科（準備中）
    for wid, cls, name, subject in [
        ('english', 'EnglishCatalog', '英語の国', '英語'),
        ('japanese', 'JapaneseCatalog', '言の葉の国', '国語'),
        ('science', 'ScienceCatalog', '理の国', '理科'),
        ('social', 'SocialCatalog', '時と地の国', '社会'),
    ]:
        if not any(w.id == wid for w in out):
            out.append(World(wid, cls, name, subject, prefix=wid[:3], hub='', sign='', desc=''))
    return out


def main():
    ws = worlds()
    maps = []
    total = 0
    for w in ws:
        if not w.routes:
            lib.write_catalog(w)
            continue
        n = lib.write_questions(w)
        lib.write_catalog(w)
        (lib.CUR / 'src').mkdir(exist_ok=True)
        (lib.CUR / 'src' / f'{w.id}.txt').write_text(lib.curriculum_text(w), encoding='utf-8')
        maps += lib.map_lines(w)
        areas = sum(len(r.areas) for r in w.routes)
        print(f'{w.name}: {len(w.routes)}ルート {areas}エリア {n}問')
        total += n
        # 同じルートで同じ問いを2度出していないか
        for r in w.routes:
            seen = {}
            for a in r.areas:
                for q in a.qs:
                    key = q['p'] + (q['s'] or '') + q['a']
                    if key in seen:
                        sys.exit(f'{w.id}/{r.id}: 問いが重複: {key}（{seen[key]} と {a.theme}）')
                    seen[key] = a.theme
    lib.write_lessons(ws)
    # 定期テストの海（英語）と単語帳
    eng = next(w for w in ws if w.id == 'english')
    n = sea.write()
    print(f'定期テストの海（英語）: {len(sea.UNITS)}単元 {n}問・単語帳 {len(sea.WORDS)}冊')
    for uid in sea.UNITS:
        g, k = SEA_AREA[uid]
        r = next(r for r in eng.routes if r.id == f'j{g}')
        maps.append(f'{uid} {lib.unit_id(eng, r, k)}')
    with open(lib.CUR / 'src' / 'english.txt', 'a', encoding='utf-8') as f:
        f.write('course vocab|中学の単語と熟語|grade=中1-3|game=単語の森\n'
                '  field words|単語と熟語\n'
                '    unit j1|中1の単語\n      sub meaning|意味\n'
                '    unit j2|中2の単語\n      sub meaning|意味\n'
                '    unit j3|中3の単語\n      sub meaning|意味\n'
                '    unit idiom|中学の熟語\n      sub idiom|意味\n')
    (lib.CUR / 'map.txt').write_text(
        '# 問題セット → 学習体系（tool/junior/gen.py が生成）\n' + '\n'.join(maps) + '\n',
        encoding='utf-8')
    print('合計', total, '問')
    if '--no-build' not in sys.argv:
        subprocess.run([sys.executable, 'build.py'], cwd=lib.CUR, check=True)
        subprocess.run([sys.executable, 'assign.py'], cwd=lib.CUR, check=True)


if __name__ == '__main__':
    main()
