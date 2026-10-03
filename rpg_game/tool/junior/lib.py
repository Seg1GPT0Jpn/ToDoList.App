"""小中学生版（つづりクエスト for elementary and junior high school）の
ワールド・問題・学習体系をまとめて作る生成ツールの共通部分。

教科ごとのデータは <教科>.py に書き、gen.py がまとめて出力する。

  W = World('math', '数の国', '算数・数学', prefix='mat', ...)
  R = W.route('e1', '小1', 'left')
  R.area('たし算', 'かずとけいさん', [Q('c', '3 + 4 は？', '7', ['6', '8', '5'], '…'), ...])

出力するもの
- assets/questions/<world>/<world>_<route>_<kk>.json（1エリア1セット）
- lib/src/data/<world>_catalog.dart（ルート制ワールドの定義）
- lib/src/study/junior_lessons.dart（宿の授業。書いたエリアだけ）
- tool/curriculum/src/<world>.txt と tool/curriculum/map.txt（学習体系）
"""
import json
import pathlib
import random
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
QDIR = ROOT / 'assets' / 'questions'
DATA = ROOT / 'lib' / 'src' / 'data'
CUR = ROOT / 'tool' / 'curriculum'

CAT = dict(
    k='knowledge', c='calculation', t='thinking',
    m='meaning', u='usage', r='reading', p='partOfSpeech',
)

GRADE_TIME = {
    '小1': 45, '小2': 45, '小3': 40, '小4': 40, '小5': 35, '小6': 35,
    '中1': 30, '中2': 30, '中3': 30,
}

# 陸の魔物（海・空の魔物はそれぞれの学習モードで使う）
LOOKS = [
    'eraser', 'crayon', 'sticky', 'pencil', 'pen', 'ruler', 'triangle',
    'stapler', 'page', 'bat', 'slime', 'goblin', 'notebook', 'glue', 'tape',
    'clip', 'pushpin', 'brush', 'correction', 'calculator', 'stubpencil',
    'mechpencil', 'marker', 'protractor', 'compass', 'scissors', 'ghost',
    'pencilcase', 'sharpener', 'inkpot',
]
BOSS_LOOKS = ['golem', 'knight', 'binder', 'book', 'dragon']
SPECIES = dict(
    eraser='ケシゴムン', crayon='クレヨンぶんぶん', sticky='フセンチョウ',
    pencil='エンピツランサー', stubpencil='ちびエンピツ老兵', pen='ボールペン剣士',
    mechpencil='シャーペンロボ', marker='蛍光ペンウィザード', ruler='定規ナイト',
    triangle='三角定規シールダー', protractor='分度器メイジ',
    compass='コンパススパイダー', stapler='ホッチキスクラブ',
    scissors='ハサミビートル', binder='バインダートータス', page='プリント兵',
    ghost='ノートゴースト', book='魔導教科書', bat='しおりコウモリ',
    slime='のりスライム', goblin='クリップ小鬼', golem='ぶんちんゴーレム',
    knight='ペーパーナイト', dragon='万年筆ドラゴン', notebook='ノートン',
    pencilcase='フデバコング', glue='ノリノリスティック', tape='セロテープス',
    clip='クリップマン', pushpin='ガビョウニ', sharpener='ケズリドン',
    brush='フデマル', correction='シュウセイテープ', inkpot='インクボトル',
    calculator='デンタクン',
)
PREFIX = [
    'いたずら', 'うっかり', 'ねぼすけ', 'ひねくれ', 'おこりんぼ', 'ものしり',
    'まよいの', 'くいしんぼ', 'あわてんぼ', 'へそまがり', 'はずかしがり',
    'いばりんぼ', 'さみしがり', 'のんびり', 'せっかち', 'わすれんぼ',
]
COLORS = [
    0xFF3F7CC4, 0xFFE0483E, 0xFF4CAF50, 0xFFF4A300, 0xFF7E57C2, 0xFF26A69A,
    0xFFE91E63, 0xFF8D6E63, 0xFF5C6BC0, 0xFF43A047, 0xFFFF7043, 0xFF00897B,
    0xFF6D4C41, 0xFF3949AB, 0xFFD81B60, 0xFF7CB342,
]
PLACES = ['野原', '小道', '森', '丘', '川べり', '橋', 'どうくつ', '谷', '泉',
          'みずうみ', '花畑', '坂道', '岩場', '林', '村はずれ', '草原']
BOSS_PLACES = ['とりで', '城', '塔', '神殿']
INTRO = [
    '「{t}」、ちゃんとわかってるかな？ ためしてやる！',
    'ここを通りたければ「{t}」の問題に答えてみな！',
    '「{t}」でつまずかせてやるぞ〜！',
    'ふふふ、「{t}」はむずかしいぞ？',
    '「{t}」の力、見せてもらおうか！',
    'まちがえたら通さないよ！ テーマは「{t}」！',
]
DEFEAT = [
    'うう…よくわかってるね…',
    'まいった…もう通っていいよ…',
    'つ、つよい…勉強したんだね…',
    'くやしい〜！ 次はまけないぞ！',
    'すごい…ぜんぶ見ぬかれた…',
    'ぼくの負けだ…先へ進め…',
]
BOSS_INTRO = '{s}のまとめだ！ これまでに学んだことを、ぜんぶ出してみよ！'
BOSS_DEFEAT = '見事だ…{s}は、お前のものだ…'

_look_i = [0]
_boss_i = [0]


def Q(c, p, a, w, e='', s=None, **extra):
    """4択の問題。c=種類（k/c/t/m/u/r/p）、p=問い、a=正解、w=まちがいの選択肢、
    e=解説、s=問題の文（英文など）。"""
    a = str(a)
    w = [str(x) for x in w]
    seen = []
    for x in w:
        if x != a and x not in seen:
            seen.append(x)
    assert len(seen) >= 3, ('まちがいの選択肢が3つない', p, a, w)
    q = dict(c=c, p=p, a=a, w=seen[:3], e=e, s=s)
    q.update(extra)
    return q


def _num(s):
    m = re.fullmatch(r'(-?\d+(?:\.\d+)?)(?:/(\d+))?', s.replace(',', ''))
    if not m:
        return None
    return float(m[1]) / (int(m[2]) if m[2] else 1)


class Area:
    def __init__(self, route, theme, section, qs, boss, lesson, place):
        self.route = route
        self.theme = theme
        self.section = section
        self.qs = qs
        self.boss = boss
        self.lesson = lesson
        self.place = place


class Route:
    def __init__(self, world, rid, name, direction, grade, time, desc):
        self.world = world
        self.id = rid
        self.name = name
        self.direction = direction
        self.grade = grade
        self.time = time or GRADE_TIME.get(grade, 30)
        self.desc = desc
        self.areas = []

    def area(self, theme, section, qs, boss=False, lesson=None, place=None):
        need = 8 if boss else 10
        assert len(qs) >= need, (self.world.id, self.id, theme, len(qs))
        keys = [q['p'] + (q['s'] or '') + q['a'] for q in qs]
        dup = [k for k in keys if keys.count(k) > 1]
        assert not dup, (self.world.id, self.id, theme, dup)
        self.areas.append(Area(self, theme, section, qs, boss, lesson, place))
        assert len(self.areas) <= 20


class World:
    def __init__(self, wid, cls, name, subject, prefix, hub, sign, desc,
                 primary='knowledge', secondary='thinking', armor='knowledge',
                 ref=''):
        self.id = wid
        self.cls = cls
        self.name = name
        self.subject = subject
        self.prefix = prefix
        self.hub = hub
        self.sign = sign
        self.desc = desc
        self.primary = primary
        self.secondary = secondary
        self.armor = armor
        self.ref = ref
        self.routes = []

    def route(self, rid, name, direction, grade=None, time=None, desc=''):
        r = Route(self, rid, name, direction, grade or name, time, desc)
        self.routes.append(r)
        return r


def set_id(w, r, k):
    return f'{w.id}_{r.id}_{k:02d}'


def unit_id(w, r, k):
    return f'{w.id}.{r.id}.s{_section_no(r, k)}.a{k:02d}'


def _section_no(r, k):
    secs = []
    for a in r.areas:
        if a.section not in secs:
            secs.append(a.section)
    return secs.index(r.areas[k - 1].section) + 1


def _dart(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n') + "'"


def _enemy(w, r, k, a):
    seed = sum(map(ord, w.id + r.id)) + k
    if a.boss:
        look = BOSS_LOOKS[_boss_i[0] % len(BOSS_LOOKS)]
        _boss_i[0] += 1
        name = f'{a.section}の番人・{SPECIES[look]}'
        intro = BOSS_INTRO.format(s=a.section)
        defeat = BOSS_DEFEAT.format(s=a.section)
        desc = f'{r.name}「{a.section}」を守るボス。これまでのエリアの問題をまとめて出してくる。'
    else:
        look = LOOKS[_look_i[0] % len(LOOKS)]
        _look_i[0] += 1
        name = PREFIX[seed % len(PREFIX)] + SPECIES[look]
        intro = INTRO[seed % len(INTRO)].format(t=a.theme)
        defeat = DEFEAT[(seed * 7) % len(DEFEAT)]
        desc = f'「{a.theme}」の問題で旅人をまどわせる{SPECIES[look]}のなかま。'
    color = COLORS[(seed * 5) % len(COLORS)]
    if a.place:
        place = a.place
    elif a.boss:
        place = f'{a.section}の{BOSS_PLACES[seed % len(BOSS_PLACES)]}'
    else:
        place = f'{a.theme}の{PLACES[seed % len(PLACES)]}'
    return dict(look=look, name=name, intro=intro, defeat=defeat, desc=desc,
                color=color, place=place)


def write_questions(w):
    out_dir = QDIR / w.id
    out_dir.mkdir(parents=True, exist_ok=True)
    for f in out_dir.glob('*.json'):
        f.unlink()
    total = 0
    for r in w.routes:
        for k, a in enumerate(r.areas, 1):
            sid = set_id(w, r, k)
            qs = []
            for n, q in enumerate(a.qs, 1):
                qid = f'{w.prefix}_{r.id}{k:02d}_{n:03d}'
                ch = [q['a']] + q['w']
                assert len(set(ch)) == 4, (qid, ch)
                o = ch[:]
                random.Random(qid).shuffle(o)
                if all(_num(x) is not None for x in ch):
                    o = sorted(ch, key=_num)
                d = dict(id=qid, unit=unit_id(w, r, k), unitLocked=True,
                         category=CAT[q['c']], prompt=q['p'])
                if q['s']:
                    d['sentence'] = q['s']
                d.update(choices=o, answerIndex=o.index(q['a']),
                         explanation=q['e'] or f'正解は「{q["a"]}」。')
                d['targetGrade'] = r.grade
                d['phase'] = 'basics' if r.grade.startswith('小') else 'teikiTest'
                for key in ('difficulty', 'thinkingLevel'):
                    if key in q:
                        d[key] = q[key]
                qs.append(d)
            total += len(qs)
            data = dict(setId=sid, worldId=w.id, origin='original', version=1,
                        questions=qs)
            (out_dir / f'{sid}.json').write_text(
                json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                encoding='utf-8')
    return total


def write_catalog(w):
    L = ['// このファイルは tool/junior/gen.py が問題データと同時に生成しています。',
         '// 手で直さず tool/junior/<教科>.py を直してください。',
         *(["import '../models/question.dart';"] if w.routes else []),
         "import '../models/stage.dart';",
         "import 'route_world.dart';",
         '',
         f'class {w.cls} {{',
         f'  const {w.cls}._();',
         '',
         f"  static const worldId = '{w.id}';",
         f'  static const name = {_dart(w.name)};',
         f'  static const subject = {_dart(w.subject)};',
         f'  static const hubName = {_dart(w.hub)};',
         f'  static const hubSign = {_dart(w.sign)};',
         f'  static const description = {_dart(w.desc)};',
         '',
         '  static const routes = <RouteSpec>[']
    for r in w.routes:
        L.append('    RouteSpec(')
        L.append(f"      info: RouteInfo('{r.id}', {_dart(r.name)}, '{r.direction}'),")
        L.append(f'      timeLimitSeconds: {r.time},')
        L.append(f'      primary: QuestionCategory.{w.primary},')
        L.append(f'      secondary: QuestionCategory.{w.secondary},')
        L.append(f'      armorCategory: QuestionCategory.{w.armor},')
        L.append('      areas: [')
        for k, a in enumerate(r.areas, 1):
            e = _enemy(w, r, k, a)
            L.append('        RouteArea(')
            L.append(f'          theme: {_dart(a.theme)},')
            L.append(f'          section: {_dart(a.section)},')
            L.append(f"          place: {_dart(e['place'])},")
            L.append(f"          enemy: {_dart(e['name'])},")
            L.append(f"          look: '{e['look']}',")
            L.append(f"          color: 0x{e['color']:08X},")
            L.append(f"          description: {_dart(e['desc'])},")
            L.append(f"          intro: {_dart(e['intro'])},")
            L.append(f"          defeat: {_dart(e['defeat'])},")
            if a.boss:
                L.append('          boss: true,')
            L.append('        ),')
        L.append('      ],')
        L.append('    ),')
    L += ['  ];', '',
          '  static final List<StageDef> stages =',
          '      RouteWorldBuilder.build(worldId, routes);',
          '}', '']
    (DATA / f'{w.id}_catalog.dart').write_text('\n'.join(L), encoding='utf-8')


def curriculum_text(w):
    L = [f'# {w.subject}の学習体系（tool/junior/gen.py が生成。手で直さない）',
         f'@subject {w.id}|{w.subject}|{w.name}|ref={w.ref}'
         '|source=文部科学省 小学校・中学校学習指導要領（平成29年告示）'
         '|url=https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm']
    for r in w.routes:
        desc = f'|desc={r.desc}' if r.desc else ''
        L.append(f'course {r.id}|{r.name}|grade={r.grade}|game={r.name}の道{desc}')
        done = set()
        prev_unit = None
        for k, a in enumerate(r.areas, 1):
            sno = _section_no(r, k)
            if sno not in done:
                done.add(sno)
                L.append(f'  field s{sno}|{a.section}')
            pre = f'|pre={prev_unit}' if prev_unit and not a.boss else ''
            name = a.theme.replace('|', '／')
            L.append(f'    unit a{k:02d}|{name}{pre}')
            L.append('      sub main|' + name)
            if not a.boss:
                prev_unit = unit_id(w, r, k).rsplit('.', 0)[0]
    return '\n'.join(L) + '\n'


def map_lines(w):
    out = []
    for r in w.routes:
        for k, _ in enumerate(r.areas, 1):
            out.append(f'{set_id(w, r, k)} {unit_id(w, r, k)}')
    return out


def write_lessons(worlds):
    L = ['// このファイルは tool/junior/gen.py が生成しています。',
         '// 手で直さず tool/junior/<教科>.py の lesson を直してください。',
         "import 'inn_lessons.dart';",
         '',
         '/// 宿の授業（小中学生版）。書いていないエリアは問題から自動で作る。',
         'class JuniorLessons {',
         '  const JuniorLessons._();',
         '',
         '  static const all = <InnLesson>[']
    for w in worlds:
        for r in w.routes:
            for k, a in enumerate(r.areas, 1):
                if not a.lesson:
                    continue
                L.append('    InnLesson(')
                L.append(f"      stageId: '{set_id(w, r, k)}',")
                L.append(f"      teacher: {_dart(r.name + 'の宿・つづり先生')},")
                L.append(f'      title: {_dart(a.theme)},')
                L.append('      points: [')
                for h, b, ex in a.lesson:
                    L.append(f'        LessonPoint({_dart(h)}, {_dart(b)}, {_dart(ex)}),')
                L.append('      ],')
                L.append('    ),')
    L += ['  ];', '}', '']
    (ROOT / 'lib' / 'src' / 'study' / 'junior_lessons.dart').write_text(
        '\n'.join(L), encoding='utf-8')
