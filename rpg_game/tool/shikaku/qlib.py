"""資格の塔の問題ファイルを書く共通部品。選択肢は問題 ID から決まる順に並べかえる（毎回同じ）。"""
import json, pathlib, random

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets' / 'questions' / 'shikaku'


def write_set(set_id, prefix, qs):
    """qs: [(unit, prompt, correct, [wrong×3], explanation, category)]"""
    OUT.mkdir(parents=True, exist_ok=True)
    out = []
    for i, (unit, prompt, correct, wrongs, ex, cat) in enumerate(qs, 1):
        qid = f'{prefix}_{i:03d}'
        assert len(wrongs) == 3, qid
        opts = [correct] + list(wrongs)
        assert len(set(opts)) == 4, qid
        # 正解の位置はかたよらないよう順番に（セットごとにずらす）、ほかの選択肢は並べかえる
        rnd = random.Random(qid)
        wrong = list(wrongs)
        rnd.shuffle(wrong)
        pos = (i + sum(map(ord, set_id))) % 4
        opts = wrong[:pos] + [correct] + wrong[pos:]
        out.append({
            'id': qid, 'unit': unit, 'unitLocked': True, 'category': cat,
            'prompt': prompt, 'choices': opts, 'answerIndex': opts.index(correct),
            'explanation': ex,
        })
    data = {'setId': set_id, 'worldId': 'shikaku', 'origin': 'original', 'version': 1, 'questions': out}
    (OUT / f'{set_id}.json').write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    return len(out)
