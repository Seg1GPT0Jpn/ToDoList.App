"""授業の教材を検査して assets/lessons/<学校の科目>.json に書き出す。

  cd rpg_game/tool/lessons && python3 build.py

検査（足りない授業は書き出さない）：目標・説明3つ以上・まとめ・途中の問題・確認テスト3問以上、
選択肢の重複・正解の位置・解説の有無、授業IDの重複。単元が学習体系にあるかは Dart のテストで確かめる。
"""
import importlib
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'assets', 'lessons')
SUBJECTS = ['gendai_kokugo', 'gengo_bunka', 'math1', 'math_a', 'ec1', 'chemistry_basic', 'biology_basic', 'public_economy']


def check_q(q, where):
    assert q['q'].strip(), where
    assert len(q['c']) >= 2 and len(set(q['c'])) == len(q['c']), (where, q['c'])
    assert 0 <= q['a'] < len(q['c']), where
    assert q['e'].strip(), (where, '解説なし')


def check(lesson):
    w = lesson['id']
    assert lesson['goals'], w
    blocks = [s for s in lesson['steps'] if s['t'] != 'check']
    checks = [s for s in lesson['steps'] if s['t'] == 'check']
    assert len(blocks) >= 3, (w, '説明が3つ未満')
    assert any(s['t'] == 'summary' for s in blocks), (w, 'まとめなし')
    assert checks, (w, '途中の問題なし')
    assert len(lesson['quiz']) >= 3, (w, '確認テストが3問未満')
    for s in blocks:
        assert s['b'], (w, s['h'])
    for i, q in enumerate(checks + lesson['quiz']):
        check_q(q, f'{w} #{i}')
    assert lesson['reteach'], (w, '別の角度からの説明なし')


def main():
    os.makedirs(OUT, exist_ok=True)
    seen = set()
    total = 0
    for subject in SUBJECTS:
        try:
            mod = importlib.import_module(subject)
        except ModuleNotFoundError:
            continue
        lessons = mod.LESSONS
        for l in lessons:
            assert l['subjectId'] == subject, l['id']
            assert l['id'] not in seen, l['id']
            seen.add(l['id'])
            check(l)
        with open(os.path.join(OUT, f'{subject}.json'), 'w', encoding='utf-8') as f:
            json.dump(lessons, f, ensure_ascii=False, indent=1)
            f.write('\n')
        print(subject, len(lessons))
        total += len(lessons)
    print('total', total)


if __name__ == '__main__':
    main()
