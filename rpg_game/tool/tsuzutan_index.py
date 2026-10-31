#!/usr/bin/env python3
"""assets/words/tsuzutan_*.json（つづ単の公開版）から lib/src/vocab/tsuzutan_lists.g.dart を作り直す。

  python3 rpg_game/tool/tsuzutan_index.py
"""
import glob
import json
import os

root = os.path.join(os.path.dirname(__file__), '..')
lines = [
    '// assets/words/tsuzutan_*.json から tool/tsuzutan_index.py で作った一覧。手で書きかえない。',
    "part of 'tsuzutan.dart';",
    '',
    'const _lists = <TsuzutanList>[',
]
for path in sorted(glob.glob(os.path.join(root, 'assets/words/tsuzutan_*.json'))):
    d = json.load(open(path, encoding='utf-8'))
    level = int(d['listId'].split('_')[1])
    w = d['words']
    lines.append(
        f"  TsuzutanList(id: '{d['listId']}', title: '{d['title']}', level: {level}, "
        f"count: {len(w)}, first: {json.dumps(w[0]['term'], ensure_ascii=False)}, "
        f"last: {json.dumps(w[-1]['term'], ensure_ascii=False)}),")
lines.append('];')
open(os.path.join(root, 'lib/src/vocab/tsuzutan_lists.g.dart'), 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print(len(lines) - 5, 'lists')
