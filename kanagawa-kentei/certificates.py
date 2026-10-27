"""認定証（ゴールド・シルバー・ブロンズ・参加賞）を A4 横向きで出力する。

使い方: python3 certificates.py
氏名・得点・日付・認定番号は空欄で出力し、手書きまたは印字で記入する。
"""
import os
import pathlib
import subprocess

import figures as F
from questions import BRONZE, GOLD, ORG, SECTIONS, SILVER, TITLE

TOTAL = sum(q["pts"] for s in SECTIONS for q in s["questions"])

ROOT = pathlib.Path(__file__).parent

KINDS = [
    {"key": "gold", "title": "神奈川知識ゴールド", "en": "GOLD", "doc": "認定証",
     "c1": "#8a6a12", "c2": "#d9b44a", "c3": "#f7e7b0",
     "cond": f"得点率{GOLD}％以上・全問で得点率60％以上",
     "body": f"あなたは{TITLE}において特に優秀な成績を収め、神奈川県の自然・歴史・産業・文化について"
             "深い知識と優れた思考力を有することが認められましたので、ここに「神奈川知識ゴールド」に認定します。"},
    {"key": "silver", "title": "神奈川知識シルバー", "en": "SILVER", "doc": "認定証",
     "c1": "#5d6670", "c2": "#b9c2cb", "c3": "#eef1f4",
     "cond": f"得点率{SILVER}％以上",
     "body": f"あなたは{TITLE}において優秀な成績を収め、神奈川県について豊かな知識を有することが"
             "認められましたので、ここに「神奈川知識シルバー」に認定します。"},
    {"key": "bronze", "title": "神奈川知識ブロンズ", "en": "BRONZE", "doc": "認定証",
     "c1": "#7a4520", "c2": "#c88a55", "c3": "#f5e2d0",
     "cond": f"得点率{BRONZE}％以上",
     "body": f"あなたは{TITLE}において良好な成績を収め、神奈川県についての基礎的な知識を有することが"
             "認められましたので、ここに「神奈川知識ブロンズ」に認定します。"},
    {"key": "entry", "title": "参加賞", "en": "PARTICIPATION", "doc": "参加証",
     "c1": "#1b2b44", "c2": "#4fa3ad", "c3": "#e3f1f3",
     "cond": "",
     "body": f"あなたは{TITLE}に挑戦し、神奈川県について学ぼうとする意欲を示されました。"
             "その努力をたたえ、ここに参加の記念として本証を贈ります。これからも神奈川の魅力を見つけてください。"},
]


def medal(k):
    """リボン付きのメダル（SVG）"""
    star = "M60,30 L67,48 L86,48 L71,60 L77,79 L60,67 L43,79 L49,60 L34,48 L53,48 Z"
    return f"""<svg viewBox="0 0 120 170" width="46mm">
<defs><radialGradient id="g{k['key']}" cx="40%" cy="35%" r="70%">
<stop offset="0" stop-color="{k['c3']}"/><stop offset=".55" stop-color="{k['c2']}"/><stop offset="1" stop-color="{k['c1']}"/></radialGradient></defs>
<path d="M38,95 L22,165 L42,152 L52,170 L60,110 Z" fill="{k['c1']}"/>
<path d="M82,95 L98,165 L78,152 L68,170 L60,110 Z" fill="{k['c1']}" opacity=".85"/>
<circle cx="60" cy="58" r="52" fill="url(#g{k['key']})" stroke="{k['c1']}" stroke-width="3"/>
<circle cx="60" cy="58" r="43" fill="none" stroke="{k['c3']}" stroke-width="1.5" stroke-dasharray="3 3"/>
<path d="{star}" fill="{k['c3']}" stroke="{k['c1']}" stroke-width="2"/>
<text x="60" y="97" text-anchor="middle" font-size="9" font-weight="bold" fill="{k['c1']}" font-family="sans-serif">{k['en'] if len(k['en']) < 8 else 'THANK YOU'}</text>
</svg>"""


SEAL = """<svg viewBox="0 0 100 100" width="25mm" class="seal">
<rect x="5" y="5" width="90" height="90" rx="5" fill="none" stroke="#c0392b" stroke-width="5"/>
<g fill="#c0392b" font-family="'Noto Serif CJK JP',serif" font-weight="900" font-size="25" text-anchor="middle">
<text x="73" y="34">神</text><text x="73" y="59">奈</text><text x="73" y="84">川</text>
<text x="50" y="34">県</text><text x="50" y="59">検</text><text x="50" y="84">定</text>
<text x="27" y="46">之</text><text x="27" y="74">印</text></g></svg>"""


CSS = """
@page { size: A4 landscape; margin: 0; }
* { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { margin: 0; font-family: "Yu Mincho","Hiragino Mincho ProN","Noto Serif CJK JP",serif; color: #1a1a1a; }
.cert { width: 297mm; height: 210mm; padding: 9mm; page-break-after: always; position: relative; overflow: hidden; background: #fff; }
.frame { position: absolute; inset: 9mm; border: 2.5mm solid var(--c1); }
.frame::before { content: ""; position: absolute; inset: 2.2mm; border: .6mm solid var(--c2); }
.frame::after { content: ""; position: absolute; inset: 4mm; border: .3mm solid var(--c1); }
.corner { position: absolute; width: 22mm; height: 22mm; }
.wm { position: absolute; right: 18mm; bottom: 16mm; width: 120mm; opacity: .10; }
.inner { position: absolute; inset: 18mm 24mm; display: flex; flex-direction: column; }
.top { display: flex; justify-content: space-between; align-items: flex-start; font-size: 10.5pt; }
.head { text-align: center; margin-top: 2mm; }
.head .doc { font-size: 52pt; letter-spacing: .5em; font-weight: 900; margin-left: .5em; color: var(--c1); line-height: 1.1; }
.head .rank { display: inline-block; margin-top: 3mm; padding: 1.5mm 10mm; font-size: 18pt; font-weight: bold; letter-spacing: .25em;
  color: #fff; background: linear-gradient(90deg, var(--c1), var(--c2), var(--c1)); border-radius: 1.5mm; }
.mid { display: grid; grid-template-columns: 1fr 50mm; gap: 8mm; align-items: center; margin-top: 10mm; }
.name { font-size: 18pt; display: flex; align-items: flex-end; gap: 3mm; }
.name .line { flex: 1; border-bottom: .4mm solid #333; height: 12mm; }
.body { font-size: 15.5pt; line-height: 2.1; margin-top: 7mm; text-indent: 1em; }
.score { margin-top: 4mm; font-size: 13pt; display: flex; gap: 10mm; }
.score span.b { display: inline-block; min-width: 22mm; border-bottom: .3mm solid #333; }
.foot { margin-top: auto; display: flex; justify-content: space-between; align-items: flex-end; }
.date { font-size: 12.5pt; }
.issuer { text-align: right; font-size: 15pt; position: relative; padding-right: 31mm; }
.issuer .chief { font-size: 12pt; margin-top: 1mm; }
.seal { position: absolute; right: 0; top: -9mm; opacity: .9; }
.cond { font-size: 8.5pt; color: #555; margin-top: 1mm; }
"""


def corner(k, pos):
    rot = {"tl": 0, "tr": 90, "br": 180, "bl": 270}[pos]
    place = {"tl": "left:13mm;top:13mm", "tr": "right:13mm;top:13mm", "br": "right:13mm;bottom:13mm", "bl": "left:13mm;bottom:13mm"}[pos]
    return (f'<svg class="corner" style="{place};transform:rotate({rot}deg)" viewBox="0 0 60 60">'
            f'<path d="M2,58 V14 Q2,2 14,2 H58" fill="none" stroke="{k["c1"]}" stroke-width="3"/>'
            f'<path d="M10,58 V20 Q10,10 20,10 H58" fill="none" stroke="{k["c2"]}" stroke-width="1.5"/>'
            f'<circle cx="14" cy="14" r="5" fill="{k["c2"]}" stroke="{k["c1"]}" stroke-width="1.5"/></svg>')


def page(k, silhouette):
    score = ("" if k["key"] == "entry" else
             '<div class="score"><div>得点　<span class="b"></span>　点／' + str(TOTAL) + '点</div>'
             '<div>得点率　<span class="b"></span>　％</div></div>')
    return f"""
<div class="cert" style="--c1:{k['c1']};--c2:{k['c2']};--c3:{k['c3']}">
  <div class="frame"></div>
  {''.join(corner(k, p) for p in ('tl', 'tr', 'br', 'bl'))}
  <div class="wm">{silhouette}</div>
  <div class="inner">
    <div class="top"><div>第1回 神奈川県検定</div><div>{'認定番号' if k['key'] != 'entry' else '番号'}　第　　　　　　号</div></div>
    <div class="head"><div class="doc">{k['doc']}</div><div class="rank">{k['title']}</div></div>
    <div class="mid">
      <div>
        <div class="name"><div class="line"></div><div>殿</div></div>
        {score}
        <div class="body">{k['body']}</div>
      </div>
      <div style="text-align:center">{medal(k)}</div>
    </div>
    <div class="foot">
      <div class="date">令和　　年　　月　　日<div class="cond">{('認定基準：' + k['cond']) if k['cond'] else ''}</div></div>
      <div class="issuer">{ORG}<div class="chief">委員長　　　　　　　　　</div>{SEAL}</div>
    </div>
  </div>
</div>"""


def main():
    silhouette = F.kanagawa(fill={n: "dark" for n in F.CODE}, sea_labels=False).replace('fill="#e6eff6"', 'fill="none"')
    body = "".join(page(k, silhouette) for k in KINDS)
    html = (f'<!doctype html><html lang="ja"><head><meta charset="utf-8"><title>認定証</title>'
            f'<style>{CSS}</style></head><body>{body}</body></html>')
    (ROOT / "04_認定証.html").write_text(html, encoding="utf-8")
    npm_root = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True).stdout.strip()
    subprocess.run(["node", str(ROOT / "render_pdf.js"), "04_認定証"], check=False,
                   env={**os.environ, "NODE_PATH": npm_root})


if __name__ == "__main__":
    main()
