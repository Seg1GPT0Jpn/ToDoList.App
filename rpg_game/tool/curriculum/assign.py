#!/usr/bin/env python3
"""問題ファイルの各問題に、学習体系の単元・小単元（"unit"）を書き込む。

使い方:  cd rpg_game/tool/curriculum && python3 assign.py [--check] [--report]
  --check   書き込まずに、振り分け結果だけを確かめる（CI 用）
  --report  小単元ごとの問題数を出す

map.txt の「問題セット → 範囲（とその範囲で手がかりがないときの単元）」をもとに、
範囲の中の小単元の手がかりの言葉（kw）と問題文・タグ・解説を照らし合わせて決める。
手で単元を決めたい問題には "unitLocked": true を書いておくと、その "unit" を変えない。
"""
import json
import os
import re
import shutil
import subprocess
import sys

from build import load_all

HERE = os.path.dirname(os.path.abspath(__file__))
QDIR = os.path.join(HERE, '..', '..', 'assets', 'questions')
ASCII_RE = re.compile(r'^[A-Za-z0-9 .\-+/\'~²³^_]+$')



def dart_format(paths):
    """生成した Dart を dart format で整える（dart がなければそのまま）。"""
    dart = shutil.which('dart')
    if dart:
        subprocess.run([dart, 'format', *paths], capture_output=True)

def load_map():
    """map.txt を読む。1行＝「セットID 範囲 [既定の単元|-] [種類:範囲:既定の単元 ...]」。

    「種類:…」は、その問題セットの中で問題の種類（category）が一致する問題だけ
    別の範囲から選ぶときに使う（例：英語の文法エリアに混ざる単語の意味の問題）。
    """
    m = {}
    with open(os.path.join(HERE, 'map.txt'), encoding='utf-8') as f:
        for no, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            if len(parts) < 2:
                sys.exit(f'map.txt:{no}: 「セットID 範囲 [既定の単元]」で書く')
            default = parts[2] if len(parts) >= 3 and parts[2] != '-' else None
            overrides = {}
            for p in parts[3:]:
                cat, scope, dflt = (p.split(':') + [''])[:3]
                if not cat or not scope:
                    sys.exit(f'map.txt:{no}: 種類:範囲:既定の単元 の形で書く: {p}')
                overrides[cat] = (scope, dflt or None)
            m[parts[0]] = (parts[1], default, overrides)
    return m


HIRAGANA_RE = re.compile(r'^[ぁ-ゖー]+$')
QUOTE_OPEN = '「『"“\''
QUOTE_CLOSE = '」』"”\''


def _quoted(kw, text):
    """「kw」のように、かぎかっこや引用符でくくられて出てくる回数。"""
    n = 0
    start = 0
    while True:
        i = text.find(kw, start)
        if i < 0:
            return n
        before = text[i - 1] if i > 0 else ''
        after = text[i + len(kw)] if i + len(kw) < len(text) else ''
        if before in QUOTE_OPEN or after in QUOTE_CLOSE:
            n += 1
        start = i + 1


def keyword_hits(kw, text):
    """手がかりの言葉が text に何回出てくるか。

    - 短い英単語（can・the・do など）やひらがな1〜2文字（き・ぬ・なり など）は、
      ふつうの文の中にいくらでも出てくるので、「」や引用符でくくられたときだけ数える
    - 英数字の言葉は単語の切れ目で数える
    """
    if not kw:
        return 0
    if (kw.isascii() and kw.isalpha() and kw.islower() and len(kw) <= 4) or \
            (HIRAGANA_RE.match(kw) and len(kw) <= 2):
        return _quoted(kw, text)
    if ASCII_RE.match(kw):
        if len(kw) <= 3 or kw.isalpha():
            pat = r'(?<![A-Za-z])' + re.escape(kw) + r'(?![A-Za-z])'
            return len(re.findall(pat, text))
    return text.count(kw)


def _texts(q):
    main = ' '.join([q.get('prompt', ''), ' '.join(q.get('tags', []))])
    sub = ' '.join([q.get('explanation', '') or '', q.get('hint', '') or ''])
    return main, sub


def _kws(node):
    kws = [k.strip().replace('{bar}', '|')
           for k in node.attrs.get('kw', '').split(',') if k.strip()]
    if kws:
        return kws
    # 手がかりの言葉が書かれていなければ、名前を手がかりにする
    return [w for w in re.split(r'[（）()・、]', node.name) if len(w) >= 2]


def score(node, q):
    """問題 q が節 node にどれだけ当てはまるか（題名・タグは解説の3倍の重み）。

    問題文には英文そのもの（should・which など）が入るので、英字の言葉は
    問題文では「」でくくられたときだけ数え、解説ではふつうに数える。
    """
    main, sub = _texts(q)
    total = 0
    for k in _kws(node):
        hit_main = _quoted(k, main) if k.isascii() else keyword_hits(k, main)
        total += 3 * hit_main + keyword_hits(k, sub)
    return total


def leaves(node):
    if not node.children:
        yield node
    for c in node.children:
        yield from leaves(c)


def units(node):
    if node.level == 'unit':
        yield node
    elif node.level != 'sub':
        for c in node.children:
            yield from units(c)


def _best(nodes, q, default):
    best, best_s = None, 0.0
    for n in nodes:
        s = score(n, q)
        # 既定の単元の中なら少しだけ有利にする（同点のとき既定を選ぶ）
        if s > 0 and default is not None and \
                (n.id == default.id or n.id.startswith(default.id + '.')):
            s += 0.25
        if s > best_s:
            best, best_s = n, s
    return best


def choose(scope, default, q, ids):
    """範囲 scope の中から問題 q の小単元（決まらなければ単元）を選ぶ。

    戻り値：(ID, 手がかりで決まったか)
    """
    leaf = _best(list(leaves(scope)), q, default)
    if leaf is not None:
        return leaf.id, True
    # 小単元までは決まらない：単元の名前・手がかりで単元だけ決める
    unit = _best(list(units(scope)), q, default)
    if unit is not None:
        return unit.id, True
    if scope.level in ('unit', 'sub'):
        return scope.id, False
    return default.id, False


def _check_scope(set_id, scope_id, default_id, ids):
    if scope_id not in ids:
        sys.exit(f'{set_id}: 範囲 {scope_id} が学習体系にない')
    scope = ids[scope_id]
    if scope.level not in ('unit', 'sub') and not default_id:
        sys.exit(f'{set_id}: 範囲 {scope_id} が単元より広いときは既定の単元が必要')
    default = ids.get(default_id) if default_id else None
    if default_id and default is None:
        sys.exit(f'{set_id}: 既定の単元 {default_id} が学習体系にない')
    if default is not None and not (default.id == scope.id or
                                    default.id.startswith(scope.id + '.')):
        sys.exit(f'{set_id}: 既定の単元 {default_id} が範囲 {scope_id} の外')
    if default is not None and default.level not in ('unit', 'sub'):
        sys.exit(f'{set_id}: 既定は単元か小単元: {default_id}')
    return scope, default


INDEX = os.path.join(HERE, '..', '..', 'lib', 'src', 'curriculum', 'data',
                     'curriculum_index.dart')


def write_index(counts, unit_sets, ids, check):
    """学習体系の節ごとの問題数と、単元・小単元 → 問題セットの対応を Dart に書き出す。"""
    totals = {}
    for unit, c in counts.items():
        parts = unit.split('.')
        for i in range(1, len(parts) + 1):
            k = '.'.join(parts[:i])
            totals[k] = totals.get(k, 0) + c
    order = list(ids)
    lines = ['// このファイルは tool/curriculum/assign.py が生成しています。手で直さないでください。',
             '',
             '/// 学習体系の節ごとの問題数（下の節の問題をふくむ。問題がない節は入れない）',
             'const curriculumQuestionCounts = <String, int>{']
    for k in order:
        if totals.get(k):
            lines.append(f"  '{k}': {totals[k]},")
    lines += ['};', '',
              '/// 単元・小単元に直接属する問題が入っている問題セット',
              'const curriculumUnitSets = <String, List<String>>{']
    for k in order:
        if k in unit_sets:
            sets = ', '.join(f"'{s}'" for s in sorted(unit_sets[k]))
            lines.append(f"  '{k}': [{sets}],")
    lines.append('};')
    out = '\n'.join(lines) + '\n'
    old = open(INDEX, encoding='utf-8').read() if os.path.exists(INDEX) else ''
    if old != out:
        # dart format で整形されていても、中身が同じなら作り直さない
        if re.sub(r'\s+', '', old) == re.sub(r'\s+', '', out):
            return
        if check:
            sys.exit('curriculum_index.dart が古い。assign.py を実行してください')
        with open(INDEX, 'w', encoding='utf-8') as f:
            f.write(out)
        dart_format([INDEX])


def main():
    check = '--check' in sys.argv
    report = '--report' in sys.argv
    _, ids = load_all()
    mapping = load_map()
    files = {}
    for world in sorted(os.listdir(QDIR)):
        d = os.path.join(QDIR, world)
        for fn in sorted(os.listdir(d)):
            if fn.endswith('.json'):
                files[fn[:-5]] = os.path.join(d, fn)
    missing = sorted(set(files) - set(mapping))
    if missing:
        sys.exit('map.txt にない問題セット: ' + ', '.join(missing))
    extra = sorted(set(mapping) - set(files))
    if extra:
        sys.exit('map.txt にあるがファイルがない: ' + ', '.join(extra))
    counts = {}
    unit_sets = {}
    total = matched = changed = 0
    for set_id, path in files.items():
        scope_id, default_id, overrides = mapping[set_id]
        base = _check_scope(set_id, scope_id, default_id, ids)
        by_cat = {c: _check_scope(set_id, s, d, ids)
                  for c, (s, d) in overrides.items()}
        with open(path, encoding='utf-8') as f:
            raw = f.read()
        data = json.loads(raw)
        new_questions = []
        for q in data['questions']:
            total += 1
            scope, default = by_cat.get(q.get('category'), base)
            old = q.get('unit')
            if q.get('unitLocked'):
                # 手で決めた単元（"unitLocked": true）はそのまま使う
                if old not in ids:
                    sys.exit(f'{set_id} {q["id"]}: 単元 {old} が学習体系にない')
                unit, hit = old, True
            else:
                unit, hit = choose(scope, default, q, ids)
            matched += hit
            counts[unit] = counts.get(unit, 0) + 1
            unit_sets.setdefault(unit, set()).add(set_id)
            if old != unit:
                changed += 1
            # "unit" は "id" のすぐ後ろに置く（どこに属する問題か一目で分かるように）
            nq = {}
            for k, v in q.items():
                if k == 'unit':
                    continue
                nq[k] = v
                if k == 'id':
                    nq['unit'] = unit
            new_questions.append(nq)
        data['questions'] = new_questions
        out = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
        if out != raw and not check:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(out)
    write_index(counts, unit_sets, ids, check)
    print(f'問題 {total} 問 / 手がかりで決まった {matched} 問'
          f'（{matched * 100 // max(total, 1)}%）/ 書きかえ {changed} 問')
    if check and changed:
        sys.exit('assign.py を実行して問題ファイルを更新してください')
    if not check:
        # アプリが読む、教科ごとのまとめファイルも作り直す
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            'bundle_questions',
            os.path.join(os.path.dirname(os.path.abspath(__file__)), '..',
                         'bundle_questions.py'))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.main()
    if report:
        for n in ids.values():
            if n.level == 'sub' or (n.level == 'unit'):
                c = counts.get(n.id, 0)
                print(f'{c:5d}  {n.id}  {n.name}')


if __name__ == '__main__':
    main()
