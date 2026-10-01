#!/usr/bin/env python3
"""学習体系（カリキュラムの木）を src/*.txt から Dart のデータに変換する。

使い方:  cd rpg_game/tool/curriculum && python3 build.py
出力:    rpg_game/lib/src/curriculum/data/curriculum_<subject>.dart
         rpg_game/lib/src/curriculum/data/curriculum_all.dart

書き方は README.md を参照。
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'src')
OUT = os.path.join(HERE, '..', '..', 'lib', 'src', 'curriculum', 'data')

LEVELS = ['course', 'field', 'unit', 'sub']
DART_LEVEL = {
    'subject': 'subject',
    'course': 'course',
    'field': 'field',
    'unit': 'unit',
    'sub': 'subUnit',
}
DEFAULT_SOURCE = '文部科学省 高等学校学習指導要領（平成30年告示）'
DEFAULT_URL = 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm'
ID_RE = re.compile(r'^[a-z0-9_]+$')


class Node:
    def __init__(self, level, local, name, attrs, line):
        self.level = level
        self.local = local
        self.name = name
        self.attrs = attrs
        self.line = line
        self.children = []
        self.id = ''

    def all(self):
        yield self
        for c in self.children:
            yield from c.all()


def parse_attrs(parts, where):
    attrs = {}
    for p in parts:
        if '=' not in p:
            sys.exit(f'{where}: 属性は key=value で書く: {p}')
        k, v = p.split('=', 1)
        attrs[k.strip()] = v.strip()
    return attrs


def parse(path):
    """1ファイル（1教科）を読む。"""
    subject = None
    stack = []
    with open(path, encoding='utf-8') as f:
        for no, raw in enumerate(f, 1):
            where = f'{os.path.basename(path)}:{no}'
            line = raw.rstrip('\n')
            if not line.strip() or line.lstrip().startswith('#'):
                continue
            if line.startswith('@subject '):
                parts = line[len('@subject '):].split('|')
                if len(parts) < 3:
                    sys.exit(f'{where}: @subject id|名前|国の名前 が必要')
                subject = Node('subject', parts[0], parts[1],
                               parse_attrs(parts[3:], where), no)
                subject.attrs['game'] = parts[2]
                subject.id = parts[0]
                continue
            if subject is None:
                sys.exit(f'{where}: 先頭に @subject が必要')
            indent = len(line) - len(line.lstrip(' '))
            body = line.strip()
            kw, _, rest = body.partition(' ')
            if kw not in LEVELS:
                sys.exit(f'{where}: 行の種類は {LEVELS} のどれか: {kw}')
            depth = LEVELS.index(kw)
            if indent != depth * 2:
                sys.exit(f'{where}: {kw} の字下げは {depth * 2} 文字')
            parts = rest.split('|')
            if len(parts) < 2:
                sys.exit(f'{where}: id|名前 が必要')
            local, name = parts[0].strip(), parts[1].strip()
            if not ID_RE.match(local):
                sys.exit(f'{where}: id は英小文字・数字・_ だけ: {local}')
            node = Node(kw, local, name, parse_attrs(parts[2:], where), no)
            stack = stack[:depth]
            parent = stack[-1] if stack else subject
            if depth > 0 and len(stack) < depth:
                sys.exit(f'{where}: 親がない {kw}')
            node.id = f'{parent.id}.{local}'
            parent.children.append(node)
            stack.append(node)
    return subject


def validate(subjects):
    ids = {}
    for s in subjects:
        for n in s.all():
            if n.id in ids:
                sys.exit(f'ID が重複: {n.id}（{n.line}行目）')
            ids[n.id] = n
    for s in subjects:
        for n in s.all():
            for p in split_list(n.attrs.get('pre', '')):
                if p not in ids:
                    sys.exit(f'{n.id}: 前提 {p} が見つからない')
                if p == n.id or n.id.startswith(p + '.') or p.startswith(n.id + '.'):
                    sys.exit(f'{n.id}: 自分自身・親子を前提にできない: {p}')
            if n.level == 'unit' and not n.children:
                sys.exit(f'{n.id}: 単元には小単元が1つ以上必要')
            g = n.attrs.get('grade')
            if g and not re.match(r'^[1-3](-[1-3])?$', g):
                sys.exit(f'{n.id}: grade は 1 / 2 / 3 / 1-2 などで書く: {g}')
    # 前提の循環を調べる
    graph = {i: split_list(n.attrs.get('pre', '')) for i, n in ids.items()}
    state = {}

    def visit(i, path):
        if state.get(i) == 1:
            sys.exit('前提が循環している: ' + ' → '.join(path + [i]))
        if state.get(i) == 2:
            return
        state[i] = 1
        for p in graph[i]:
            visit(p, path + [i])
        state[i] = 2

    for i in graph:
        visit(i, [])
    return ids


def split_list(v):
    # 「|」は区切りに使うので、言葉の中では {bar} と書く
    return [x.strip().replace('{bar}', '|') for x in v.split(',') if x.strip()]


# 画面に出す教科の順（ゲームの国の順）
ORDER = ['english', 'science', 'social', 'japanese', 'math', 'information',
         'music']


def dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def emit(n, ind):
    pad = ' ' * ind
    a = n.attrs
    out = [f'{pad}CurriculumNode(']
    out.append(f'{pad}  id: {dart_str(n.id)},')
    out.append(f'{pad}  name: {dart_str(n.name)},')
    out.append(f'{pad}  level: CurriculumLevel.{DART_LEVEL[n.level]},')
    if a.get('game'):
        out.append(f'{pad}  gameName: {dart_str(a["game"])},')
    if a.get('desc'):
        out.append(f'{pad}  description: {dart_str(a["desc"])},')
    if a.get('ref'):
        out.append(f'{pad}  curriculumReference: {dart_str(a["ref"])},')
    if n.level == 'subject':
        out.append(f'{pad}  source: {dart_str(a.get("source", DEFAULT_SOURCE))},')
        out.append(f'{pad}  sourceUrl: {dart_str(a.get("url", DEFAULT_URL))},')
    elif a.get('source'):
        out.append(f'{pad}  source: {dart_str(a["source"])},')
        if a.get('url'):
            out.append(f'{pad}  sourceUrl: {dart_str(a["url"])},')
    if a.get('grade'):
        out.append(f'{pad}  grade: {dart_str(a["grade"])},')
    pre = split_list(a.get('pre', ''))
    if pre:
        out.append(f'{pad}  prerequisites: [{", ".join(dart_str(p) for p in pre)}],')
    kws = split_list(a.get('kw', ''))
    if kws:
        out.append(f'{pad}  keywords: [{", ".join(dart_str(k) for k in kws)}],')
    if n.children:
        out.append(f'{pad}  children: [')
        for c in n.children:
            out.extend(emit(c, ind + 4))
        out.append(f'{pad}  ],')
    out.append(f'{pad}),')
    return out


def load_all():
    files = sorted(f for f in os.listdir(SRC) if f.endswith('.txt'))
    subjects = [parse(os.path.join(SRC, f)) for f in files]
    subjects.sort(key=lambda s: ORDER.index(s.id) if s.id in ORDER else 99)
    ids = validate(subjects)
    return subjects, ids


def main():
    subjects, ids = load_all()
    os.makedirs(OUT, exist_ok=True)
    header = ('// このファイルは tool/curriculum/build.py が生成しています。'
              '手で直さず src/*.txt を直してください。\n')
    names = []
    for s in subjects:
        var = f'{s.id}Curriculum'
        names.append((s.id, var))
        lines = [header, "import '../curriculum.dart';", '',
                 f'const {var} =']
        body = emit(s, 0)
        body[-1] = body[-1].rstrip(',') + ';'
        lines.extend(body)
        with open(os.path.join(OUT, f'curriculum_{s.id}.dart'), 'w',
                  encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
    lines = [header, "import '../curriculum.dart';"]
    for sid, _ in names:
        lines.append(f"import 'curriculum_{sid}.dart';")
    lines += ['', '/// すべての教科の学習体系（画面に出す順）',
              'const allCurricula = <CurriculumNode>[']
    lines += [f'  {var},' for _, var in names]
    lines.append('];')
    with open(os.path.join(OUT, 'curriculum_all.dart'), 'w',
              encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    counts = {}
    for n in ids.values():
        counts[n.level] = counts.get(n.level, 0) + 1
    print('教科', counts.get('subject', 0), '科目', counts.get('course', 0),
          '分野', counts.get('field', 0), '単元', counts.get('unit', 0),
          '小単元', counts.get('sub', 0))


if __name__ == '__main__':
    main()
