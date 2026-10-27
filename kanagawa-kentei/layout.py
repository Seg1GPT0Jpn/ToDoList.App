"""問題冊子の部品（特色検査風の組版）。questions.py と build.py から使う。"""
import html
import json
import pathlib

ROOT = pathlib.Path(__file__).parent
_cred = ROOT / "images" / "credits.json"
CREDITS = json.loads(_cred.read_text()) if _cred.exists() else {}
GSI = "地理院タイル（{}）を加工して作成"


def e(t):
    return html.escape(str(t))


def box(label, body, solid=False):
    """見出し（太字）＋破線（または実線）の枠"""
    cls = "box solid" if solid else "box"
    return (f'<div class="blk">' + (f'<div class="lbl">{label}</div>' if label else "") +
            f'<div class="{cls}">{body}</div></div>')


def talk(rows):
    """会話文の行。rows=[(話者, 発言HTML)]"""
    return "".join(f'<div class="tk"><span class="who">{w}</span><span class="say">{t}</span></div>' for w, t in rows)


def note(*lines):
    """枠の下につける注（＊）"""
    return '<div class="foot">' + "".join(f"<div>{l}</div>" for l in lines) + "</div>"


def svgfig(svg, cap, src=""):
    return (f'<figure><div class="fbox">{svg}</div><figcaption><b>{cap}</b>'
            + (f'<span class="src">{e(src)}</span>' if src else "") + "</figcaption></figure>")


def img(path, cap, src=None):
    if src is None:
        c = CREDITS.get(pathlib.Path(path).name)
        src = f'{c["artist"]}／{c["license"]}（Wikimedia Commons）' if c else ""
    return (f'<figure><div class="fbox"><img src="{e(path)}" alt=""></div><figcaption><b>{cap}</b>'
            + (f'<span class="src">{e(src)}</span>' if src else "") + "</figcaption></figure>")


def gmap(file, cap, layer="色別標高図・陰影起伏図"):
    return img("images/maps/" + file, cap, GSI.format(layer))


def row(*items, widths=None):
    """図や枠を左右に並べる（2段）"""
    ws = widths or [1] * len(items)
    return ('<div class="row">' + "".join(f'<div style="flex:{w} 1 0">{it}</div>' for it, w in zip(items, ws)) + "</div>")


def table(head, rows, cap=None, src=None, small=False):
    h = "".join(f"<th>{c}</th>" for c in head)
    b = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return (f'<div class="tblk">' + (f'<div class="lbl">{cap}</div>' if cap else "") +
            f'<table class="dt{" sm" if small else ""}"><tr>{h}</tr>{b}</table>' +
            (f'<div class="src">{e(src)}</div>' if src else "") + "</div>")


def tf(labels="あいう", marks=("正", "誤")):
    """3項目の組み合わせ（8通り）の選択肢"""
    a, b = marks
    out = []
    for x in (a, b):
        for y in (a, b):
            for z in (a, b):
                out.append("　".join(f"{l}：{v}" for l, v in zip(labels, (x, y, z))))
    return out


def stmts(items, labels="あいう"):
    return "".join(f'<div class="st"><span>{l}</span><span>{t}</span></div>' for l, t in zip(labels, items))
