"""三大国家試験の世界：問題ファイル（assets/questions/kokka/kokka_<ルート>_NN.json）を作る。
使い方: python3 tool/kokka/build_kokka.py"""
import pathlib, sys
HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / 'shikaku'))
from qlib import write_set, ROOT
import shiho, ishi, kaikei

ROUTES = [('shiho', 'sih', shiho.SETS), ('ishi', 'ish', ishi.SETS), ('kaikei', 'kai', kaikei.SETS)]
mp = ROOT / 'tool' / 'curriculum' / 'map.txt'
lines = [l for l in mp.read_text(encoding='utf-8').splitlines() if not l.startswith('kokka_')]
n = 0
for route, prefix, sets in ROUTES:
    for k, qs in enumerate(sets, 1):
        sid = f'kokka_{route}_{k:02d}'
        n += write_set(sid, f'{prefix}{k:02d}', qs, world='kokka')
        # 範囲：問題の単元に共通する部分（ボスはいくつかの単元にまたがるので分野になる）
        parts = [q[0].split('.')[:4] for q in qs]
        common = []
        for xs in zip(*parts):
            if len(set(xs)) > 1:
                break
            common.append(xs[0])
        line = f'{sid} ' + '.'.join(common)
        if len(common) < 4:  # 範囲が単元より広いときは、最初の問題の単元を既定にする
            line += ' ' + '.'.join(parts[0])
        lines.append(line)
mp.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(sum(len(s) for _, _, s in ROUTES), 'セット', n, '問')
