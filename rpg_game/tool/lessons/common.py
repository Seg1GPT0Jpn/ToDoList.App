"""授業の教材を書くための小さな道具。

授業はこのフォルダの <学校の科目>.py に書き、build.py で assets/lessons/<科目>.json にする。
本文・例題・問題はすべてここで新しく書いたもの（教科書や問題集の文章は写さない）。
"""
import hashlib


def B(kind, heading, body):
    """説明ブロック。kind: intro / explain / example / point / mistake / advanced / summary"""
    assert kind in ('intro', 'explain', 'example', 'point', 'mistake', 'advanced', 'summary'), kind
    return {'t': kind, 'h': heading, 'b': body.strip()}


def _shuffle(answer, wrong, seed):
    choices = [answer, *wrong]
    order = sorted(range(len(choices)), key=lambda i: hashlib.md5(f'{seed}|{i}|{choices[i]}'.encode()).hexdigest())
    shuffled = [choices[i] for i in order]
    return shuffled, shuffled.index(answer)


def Q(prompt, answer, wrong, explanation, hint='', reteach=''):
    """選択式の問題（正解を先に書く。選択肢の順番は問題文から決まった形でまぜる）"""
    choices, a = _shuffle(answer, list(wrong), prompt)
    q = {'q': prompt, 'c': choices, 'a': a, 'e': explanation}
    if hint:
        q['hint'] = hint
    if reteach:
        q['re'] = reteach
    return q


def C(prompt, answer, wrong, explanation, hint='', reteach=''):
    """授業の途中で解く問題"""
    return {'t': 'check', **Q(prompt, answer, wrong, explanation, hint, reteach)}


def L(subject, unit, title, goals, steps, quiz, pre=(), kw=(), reteach='', source='授業のために新しく書いたもの'):
    return {
        'id': f'les_{unit}', 'subjectId': subject, 'unitId': unit, 'title': title,
        'goals': list(goals), 'prerequisites': list(pre), 'keywords': list(kw),
        'steps': list(steps), 'quiz': list(quiz), 'reteach': reteach.strip(),
        'source': source, 'review': 'unreviewed', 'version': 1,
    }
