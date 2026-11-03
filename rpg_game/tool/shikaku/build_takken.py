"""宅建の道：問題ファイル（assets/questions/shikaku/shikaku_takken_NN.json）を作る。
使い方: python3 tool/shikaku/build_takken.py"""
import pathlib, re, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from qlib import write_set, ROOT
import takken_kenri, takken_gyouhou, takken_seigen

SETS = takken_kenri.SETS + takken_gyouhou.SETS + takken_seigen.SETS
n = 0
for k, qs in enumerate(SETS, 1):
    n += write_set(f'shikaku_takken_{k:02d}', f'tkn{k:02d}', qs)
# 学習体系の対応表（map.txt）：セットの最初の問題の単元（単元レベル）
mp = ROOT / 'tool' / 'curriculum' / 'map.txt'
lines = [l for l in mp.read_text(encoding='utf-8').splitlines() if not l.startswith('shikaku_takken_')]
for k, qs in enumerate(SETS, 1):
    units = sorted({'.'.join(q[0].split('.')[:4]) for q in qs})
    lines.append(f'shikaku_takken_{k:02d} ' + ' '.join(units))
mp.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(len(SETS), 'セット', n, '問')
