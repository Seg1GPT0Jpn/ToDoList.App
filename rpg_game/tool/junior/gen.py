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

import math_e
import math_j


def worlds():
    out = []

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
                    key = q['p'] + (q['s'] or '')
                    if key in seen:
                        sys.exit(f'{w.id}/{r.id}: 問いが重複: {key}（{seen[key]} と {a.theme}）')
                    seen[key] = a.theme
    lib.write_lessons(ws)
    (lib.CUR / 'map.txt').write_text(
        '# 問題セット → 学習体系（tool/junior/gen.py が生成）\n' + '\n'.join(maps) + '\n',
        encoding='utf-8')
    print('合計', total, '問')
    if '--no-build' not in sys.argv:
        subprocess.run([sys.executable, 'build.py'], cwd=lib.CUR, check=True)
        subprocess.run([sys.executable, 'assign.py'], cwd=lib.CUR, check=True)


if __name__ == '__main__':
    main()
