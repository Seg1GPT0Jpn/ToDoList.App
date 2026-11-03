"""三大国家試験の世界の用語帳（assets/cards/kokka_*.json）を tool/kokka/cards/*.txt から作る。
書き方: 「@title 題名」「## 章の名前」「用語|意味|関連語,関連語|豆知識」
使い方: python3 tool/kokka/build_cards.py"""
import json, pathlib

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parents[1]
for src in sorted((HERE / 'cards').glob('*.txt')):
    deck_id = src.stem
    title, sections, terms = '', [], set()
    for no, line in enumerate(src.read_text(encoding='utf-8').splitlines(), 1):
        if not line.strip():
            continue
        if line.startswith('@title '):
            title = line[7:].strip()
        elif line.startswith('## '):
            sections.append({'name': line[3:].strip(), 'cards': []})
        else:
            parts = line.split('|')
            assert len(parts) == 4, f'{src.name}:{no}: {line}'
            t, m, rel, tr = (p.strip() for p in parts)
            assert t not in terms, f'{src.name}:{no}: 重複 {t}'
            terms.add(t)
            sections[-1]['cards'].append({'t': t, 'm': m, 'rel': [r for r in rel.split(',') if r], 'tr': tr})
    data = {'id': deck_id, 'worldId': 'kokka', 'title': title, 'origin': 'original', 'sections': sections}
    (ROOT / 'assets' / 'cards' / f'{deck_id}.json').write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(deck_id, title, len(terms), '枚')
