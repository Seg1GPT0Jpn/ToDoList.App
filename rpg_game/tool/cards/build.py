"""暗記カードの元テキスト（src/*.txt）から assets/cards/*.json を作る。

書式:
  @deck id|worldId|題名
  @sec 章の名前
  用語（よみ）|意味|関連語;関連語|豆知識
関連語を空にすると、同じ章の前後の用語を関連語にする。
使い方: cd rpg_game/tool/cards && python3 build.py
"""
import json, os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
out_dir = os.path.join(here, '..', '..', 'assets', 'cards')
total = 0
for name in sorted(os.listdir(os.path.join(here, 'src'))):
    if not name.endswith('.txt'):
        continue
    deck, secs, seen = None, [], set()
    for no, line in enumerate(open(os.path.join(here, 'src', name), encoding='utf-8'), 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('@deck '):
            i, w, t = line[6:].split('|')
            deck = {'id': i, 'worldId': w, 'title': t, 'origin': 'original'}
            continue
        if line.startswith('@sec '):
            secs.append({'name': line[5:].strip(), 'cards': []})
            continue
        p = line.split('|')
        if len(p) != 4 or not p[0] or not p[1]:
            sys.exit(f'{name}:{no}: 4列ではありません: {line}')
        t, m, rel, tr = (x.strip() for x in p)
        r = ''
        mm = re.match(r'^(.+?)（([ぁ-ゖー・]+)）$', t)
        if mm:
            t, r = mm.group(1), mm.group(2)
        if t in seen:
            sys.exit(f'{name}:{no}: 用語が重複: {t}')
        seen.add(t)
        c = {'t': t, 'm': m}
        if r:
            c['r'] = r
        if rel:
            c['rel'] = [x.strip() for x in re.split('[;；]', rel) if x.strip() and x.strip() != t]
        if not tr:
            sys.exit(f'{name}:{no}: 豆知識がありません: {t}')
        c['tr'] = tr
        secs[-1]['cards'].append(c)
    for s in secs:
        cs = s['cards']
        for i, c in enumerate(cs):
            if 'rel' not in c:
                c['rel'] = [x['t'] for x in (cs[max(0, i - 2):i] + cs[i + 1:i + 3])][:3]
    deck['sections'] = [s for s in secs if s['cards']]
    n = sum(len(s['cards']) for s in deck['sections'])
    total += n
    json.dump(deck, open(os.path.join(out_dir, deck['id'] + '.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, separators=(',', ':'))
    print(f"{deck['id']}: {n}枚 / {len(deck['sections'])}章")
print('合計', total)
