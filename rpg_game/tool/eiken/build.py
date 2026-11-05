"""英検の扉：級ごとの単語帳（assets/words/eiken_<級>_NN.json）と RPG の問題（assets/questions/eiken/）を作る。

- 見出し語は levels.json（使用頻度の帯から選んだ語。wordfreq の頻度・lemminflect の原形で選んだ）
- 意味・例文は、つづ単（assets/words/tsuzutan_*.json）にあればそれを使い、なければ src/<級>.txt（自作）
- src/<級>.txt は「単語|意味|例文|訳」の1行1語
使い方: python3 tool/eiken/build.py
"""
import glob, json, pathlib, random, re, shutil, subprocess

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
LEVELS = [('pre2', '準2級', 'p2'), ('g2', '2級', 'g2'), ('pre1', '準1級', 'p1'), ('g1', '1級', 'g1')]
PER_LIST = 250

tz = {}
for p in sorted(glob.glob(str(ROOT / 'assets/words/tsuzutan_*.json'))):
    for w in json.load(open(p, encoding='utf-8'))['words']:
        tz.setdefault(w['term'].lower(), w)
order = json.load(open(HERE / 'levels.json'))

def own(level):
    f = HERE / 'src' / f'{level}.txt'
    out = {}
    if f.exists():
        for line in f.read_text(encoding='utf-8').splitlines():
            if not line.strip():
                continue
            term, meaning, ex, exja = line.split('|')
            out[term] = {'term': term, 'meaning': meaning, 'example': ex, 'exampleJa': exja}
    return out

def pos_of(meaning):
    m = re.match(r'\[(.)', meaning)
    return m.group(1) if m else '?'

def short(meaning):
    """4択に出す短い意味（品詞と①②を外し、最初の意味だけ）"""
    m = re.sub(r'\[[^\]]*\]\s*', '', meaning)
    m = re.split(r'\s*②', m)[0]
    m = re.sub(r'^①', '', m)
    m = re.split(r'\s*\[', m)[0]
    return m.strip()

words_dir = ROOT / 'assets/words'
q_dir = ROOT / 'assets/questions/eiken'
q_dir.mkdir(parents=True, exist_ok=True)
for old in glob.glob(str(words_dir / 'eiken_*.json')) + glob.glob(str(q_dir / '*.json')):
    pathlib.Path(old).unlink()
index = []
for level, name, route in LEVELS:
    mine = own(level)
    entries = []
    for term in order[level]:
        w = mine.get(term) or tz.get(term)
        if w is None:
            continue
        entries.append({'term': term, 'meaning': w['meaning'], 'example': w.get('example', ''),
                        'exampleJa': w.get('exampleJa', '')})
    if not entries:
        continue
    entries.sort(key=lambda w: w['term'])
    chunks = [entries[i:i + PER_LIST] for i in range(0, len(entries), PER_LIST)]
    if len(chunks) > 1 and len(chunks[-1]) < 120:
        chunks[-2].extend(chunks.pop())
    for k, chunk in enumerate(chunks, 1):
        list_id = f'eiken_{route}_{k:02d}'
        title = f'英検{name} {k}'
        data = {'listId': list_id, 'title': title, 'origin': 'original',
                'words': [{'number': i + 1, **w} for i, w in enumerate(chunk)]}
        (words_dir / f'{list_id}.json').write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        index.append((list_id, title, route, len(chunk), chunk[0]['term'], chunk[-1]['term']))
        # RPG の問題：英語→意味の4択（ほかの選択肢は同じ級・同じ品詞の語の意味）
        pool = {}
        for w in entries:
            pool.setdefault(pos_of(w['meaning']), []).append(short(w['meaning']))
        qs = []
        for i, w in enumerate(chunk, 1):
            qid = f'ek{route}{k:02d}_{i:03d}'
            rnd = random.Random(qid)
            ans = short(w['meaning'])
            cands = [m for m in pool.get(pos_of(w['meaning']), []) if m != ans]
            if len(set(cands)) < 3:
                cands = [short(x['meaning']) for x in entries if short(x['meaning']) != ans]
            wrong = []
            for m in rnd.sample(cands, min(len(cands), 30)):
                if m not in wrong and m != ans:
                    wrong.append(m)
                if len(wrong) == 3:
                    break
            pos = (i + k) % 4
            opts = wrong[:pos] + [ans] + wrong[pos:]
            q = {'id': qid, 'unit': f'eiken.{route}.vocab.words.{"a" if w["term"] < "n" else "n"}', 'unitLocked': True,
                 'category': 'meaning', 'prompt': f'「{w["term"]}」の意味は？', 'choices': opts,
                 'answerIndex': pos, 'explanation': f'{w["term"]}：{w["meaning"]}'}
            if w['example']:
                q['explanation'] += f'　例：{w["example"]}（{w["exampleJa"]}）'
            qs.append(q)
        qset = {'setId': f'eiken_{route}_{k:02d}', 'worldId': 'eiken', 'origin': 'original', 'version': 1, 'questions': qs}
        (q_dir / f'eiken_{route}_{k:02d}.json').write_text(json.dumps(qset, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(name, len(entries), '語', len(chunks), '冊')

# Dart の一覧
lines = ['// tool/eiken/build.py で作った英検の単語帳の一覧。手で書きかえない。', "part of 'eiken.dart';", '', 'const _lists = <EikenList>[']
for list_id, title, route, n, first, last in index:
    lines.append(f"  EikenList(id: '{list_id}', title: '{title}', route: '{route}', count: {n}, "
                 f"first: {json.dumps(first)}, last: {json.dumps(last)}),")
lines.append('];')
(ROOT / 'lib/src/vocab/eiken_lists.g.dart').write_text('\n'.join(lines) + '\n', encoding='utf-8')
# RPG のルートとエリア（1冊＝1エリア。各級の最後はボス）
LOOKS = ['book', 'page', 'notebook', 'pencil', 'mechpencil', 'pen', 'marker', 'eraser', 'crayon', 'sticky',
         'clip', 'tape', 'scissors', 'stapler', 'ruler', 'binder', 'compass', 'calculator', 'sharpener', 'stubpencil']
PLACES = ['アルファベットの丘', '語源の森', 'スペルの小道', '発音の泉', '品詞の分かれ道', '例文の橋', '辞書の書庫',
          '派生語の谷', '同意語の湖', '反意語の崖', 'コロケーションの市場', '多義語の迷宮']
ROUTES = {'p2': ('準2級', 'up', 0xFF66BB6A), 'g2': ('2級', 'left', 0xFF42A5F5), 'p1': ('準1級', 'right', 0xFFAB47BC), 'g1': ('1級', 'down', 0xFFEF5350)}
BOSS = {'p2': ('準2級の門番', 'golem'), 'g2': ('2級の大賢者', 'knight'), 'p1': ('準1級の古竜', 'dragon'), 'g1': ('1級の語彙王', 'dragon')}
dl = ['// tool/eiken/build.py で作った英検の世界のルート。手で書きかえない。', "part of 'eiken.dart';", '',
      'const _routes = <RouteSpec>[']
for route, (name, direction, color) in ROUTES.items():
    lists = [x for x in index if x[2] == route]
    if not lists:
        continue
    dl.append(f"  RouteSpec(info: RouteInfo('{route}', '{name}', '{direction}'), timeLimitSeconds: 20, "
              "primary: QuestionCategory.meaning, secondary: QuestionCategory.meaning, armorCategory: QuestionCategory.meaning, areas: [")
    for k, (list_id, title, _, n, first, last) in enumerate(lists):
        boss = k == len(lists) - 1
        if boss:
            enemy, look = BOSS[route]
            desc = f'英検{name}の単語をすべて知る番人。'
            intro = f'英検{name}の単語、ここまで覚えてきたか？ 試してやろう！'
            defeat = 'その語彙力、本物だ…'
        else:
            enemy = f'{first[:1].upper()}〜{last[:1].upper()}のワードスライム' if k % 3 == 0 else (
                f'{first}の綴り虫' if k % 3 == 1 else f'{last}の影')
            look = LOOKS[(k * 3 + len(route)) % len(LOOKS)]
            desc = f'英検{name}の単語（{first} 〜 {last}）を食べて育った魔物。'
            intro = f'{first}…{last}…この単語、意味がわかるかな？'
            defeat = '意味…ぜんぶ…覚えられた…'
        place = PLACES[k % len(PLACES)]
        dl.append(f"    RouteArea(theme: '{title}（{first} 〜 {last}）', section: '英検{name}', place: '{place}', "
                  f"enemy: '{enemy}', look: '{look}', color: 0x{color:08X}, description: '{desc}', intro: '{intro}', "
                  f"defeat: '{defeat}'{', boss: true' if boss else ''}),")
    dl.append('  ]),')
dl.append('];')
(ROOT / 'lib/src/vocab/eiken_routes.g.dart').write_text('\n'.join(dl) + '\n', encoding='utf-8')
# 学習体系の対応表
mp = ROOT / 'tool/curriculum/map.txt'
rows = [l for l in mp.read_text(encoding='utf-8').splitlines() if not l.startswith('eiken_')]
for list_id, title, route, *_ in index:
    rows.append(f'{list_id} eiken.{route}.vocab.words')
mp.write_text('\n'.join(rows) + '\n', encoding='utf-8')

if shutil.which('dart'):
    subprocess.run(['dart', 'format', str(ROOT / 'lib/src/vocab/eiken_lists.g.dart'), str(ROOT / 'lib/src/vocab/eiken_routes.g.dart')], capture_output=True)
