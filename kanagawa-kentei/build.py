"""神奈川県検定の 問題冊子・解答用紙・解答と解説 を HTML と PDF で出力する。

使い方: python3 build.py
写真は images/ に保存すると問題冊子に入る（無い場合は差し込み枠を表示）。
PDF 変換には Node.js 版 Playwright（render_pdf.js）を使う。
"""
import html
import json
import os
import pathlib
import subprocess

import figures as F
from questions import (BRONZE, EXAM_MINUTES, GOLD, ORG, SECTIONS, SILVER, SUBTITLE,
                       TITLE, UNIT_MIN_RATE)

ROOT = pathlib.Path(__file__).parent
MARU = "①②③④⑤⑥⑦⑧⑨"
KANA = "アイウエオ"

for s in SECTIONS:
    s["pts"] = sum(q["pts"] for q in s["questions"])
TOTAL = sum(s["pts"] for s in SECTIONS)
assert TOTAL == 100, TOTAL
NQ = sum(len(s["questions"]) for s in SECTIONS)
_cred = ROOT / "images" / "credits.json"
CREDITS = json.loads(_cred.read_text()) if _cred.exists() else {}


def e(t):
    return html.escape(str(t))


def n_choices(q):
    if "table" in q:
        return len(q["table"]["rows"])
    return len(q["choices"])


def unit_min(pts):
    return -(-pts * int(UNIT_MIN_RATE * 10) // 10)


CSS = """
@page { size: A4; margin: 16mm 15mm 16mm; }
:root { --ink:#1b2b44; --accent:#0f6d7a; --red:#c0392b; --pale:#eef3f8; --line:#9aa9bd; }
* { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { font-family: "Yu Mincho","YuMincho","Hiragino Mincho ProN","Noto Serif CJK JP","IPAMincho",serif;
       font-size: 10.5pt; line-height: 1.85; color: #111; background: #fff; margin: 0; }
.sans { font-family: "Hiragino Kaku Gothic ProN","Yu Gothic","Noto Sans CJK JP","IPAGothic",sans-serif; }
.page { page-break-after: always; }
u { text-decoration: none; border-bottom: 1.5px solid #111; }
/* 表紙 */
.cover { height: 263mm; display: flex; flex-direction: column; }
.cover .band { background: var(--ink); color: #fff; padding: 9mm 10mm 7mm; border-radius: 4mm 4mm 0 0; position: relative; overflow: hidden; }
.cover .band .org { font-size: 10pt; letter-spacing: .3em; opacity: .85; }
.cover .band h1 { font-size: 30pt; margin: 3mm 0 1mm; letter-spacing: .12em; font-weight: 900; }
.cover .band .sub { font-size: 13pt; letter-spacing: .5em; }
.cover .band .wave { position: absolute; right: -4mm; bottom: -2mm; width: 80mm; opacity: .25; }
.cover .stripe { height: 3mm; background: repeating-linear-gradient(90deg, var(--accent) 0 12mm, #4fa3ad 12mm 24mm); }
.cover .mid { display: grid; grid-template-columns: 1fr 1fr; gap: 6mm; margin: 6mm 0 4mm; align-items: center; }
.cover .map svg { width: 100%; }
.info { width: 100%; border-collapse: collapse; font-size: 10.5pt; }
.info th, .info td { border: 1px solid var(--ink); padding: 2mm 3mm; }
.info th { background: var(--pale); width: 30mm; text-align: left; }
.notice { border: 1.5px solid var(--ink); border-radius: 3mm; padding: 3mm 6mm 2mm; font-size: 9.8pt; line-height: 1.7; }
.notice h3 { margin: 0 0 1mm; font-size: 11pt; letter-spacing: .4em; text-align: center; }
.notice ol { margin: 0; padding-left: 5mm; }
.idbox { display: flex; align-items: center; gap: 3mm; margin-top: 5mm; }
.idbox .cells { display: flex; }
.idbox .cells span { width: 10mm; height: 12mm; border: 1.5px solid var(--ink); margin-left: -1.5px; }
.start { margin-top: auto; text-align: center; font-weight: bold; border: 2px solid var(--red); color: var(--red);
         padding: 2mm; border-radius: 2mm; }
/* 大問 */
.sec-head { display: flex; align-items: stretch; margin-bottom: 3mm; border-radius: 2.5mm; overflow: hidden; border: 1.5px solid var(--ink); }
.sec-head .no { background: var(--ink); color: #fff; padding: 1.5mm 5mm; font-size: 14pt; font-weight: 900; letter-spacing: .1em; }
.sec-head .ttl { flex: 1; padding: 1.5mm 4mm; font-size: 13pt; font-weight: bold; background: var(--pale); }
.sec-head .pts { padding: 1.5mm 4mm; font-size: 10pt; align-self: center; }
.intro { margin: 0 0 3mm; }
.talk { border: 1px solid var(--line); border-radius: 2.5mm; padding: 2mm 4mm; margin: 0 0 4mm; background: #fbfcfe; }
.talk .row { display: grid; grid-template-columns: 26mm 1fr; gap: 2mm; }
.talk .who { font-weight: bold; color: var(--accent); }
/* 小問 */
.q { margin: 0 0 6mm; page-break-inside: avoid; }
.q-text { margin: 1mm 0 2mm; }
.tag { display: inline-block; background: var(--ink); color: #fff; font-weight: bold; padding: 0 2.5mm; border-radius: 1.5mm;
       margin-right: 2mm; font-size: 10pt; }
.pt { font-size: 8.5pt; color: #444; margin-left: 1mm; }
.figs { display: flex; gap: 4mm; justify-content: center; align-items: flex-start; flex-wrap: wrap; margin: 1mm 0 2mm; }
figure { margin: 0; flex: 1 1 0; min-width: 45mm; max-width: 118mm; }
figure .box svg { display: block; max-height: 78mm; }
figure .cap { font-size: 9pt; font-weight: bold; margin-bottom: .8mm; }
figure .box { border: 1px solid var(--line); border-radius: 2mm; padding: 2mm; background: #fff; }
figure .src { font-size: 7.5pt; color: #555; text-align: right; line-height: 1.4; margin-top: .6mm; }
figure img { display: block; max-width: 100%; max-height: 66mm; margin: 0 auto; border-radius: 1mm; }
.ph { height: 52mm; border: 1.5px dashed var(--line); border-radius: 2mm; background: repeating-linear-gradient(45deg,#f5f7fa 0 6px,#fff 6px 12px);
      display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; font-size: 8.5pt;
      line-height: 1.5; color: #333; padding: 2mm; }
.ph b { font-size: 9.5pt; }
.note { border: 1px solid var(--ink); border-left: 2.5mm solid var(--accent); padding: 1.5mm 4mm; margin: 1mm 0 2mm;
        font-size: 9.6pt; line-height: 1.7; background: #fbfcfe; }
.note .src { font-size: 7.5pt; color: #555; }
.stmts { border: 1px solid var(--line); border-radius: 2mm; padding: 1.5mm 4mm; margin: 1.5mm 0; }
.stmt { display: grid; grid-template-columns: 7mm 1fr; }
.choices { display: grid; grid-template-columns: 1fr; gap: .5mm 6mm; margin: 1mm 0 0 2mm; }
.choices.c2 { grid-template-columns: 1fr 1fr; } .choices.c3 { grid-template-columns: 1fr 1fr 1fr; }
.choices.c4 { grid-template-columns: repeat(4,1fr); }
.choice { display: grid; grid-template-columns: 6mm 1fr; }
table.combo { border-collapse: collapse; margin: 1.5mm auto 0; font-size: 9.6pt; }
table.combo th, table.combo td { border: 1px solid var(--ink); padding: .6mm 2.4mm; text-align: center; line-height: 1.5; }
table.combo th { background: var(--pale); }
.end { text-align: right; margin-top: 6mm; }
/* 解答用紙 */
.sheet h1 { font-size: 15pt; margin: 0; }
.sheet .top { display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 3px solid var(--ink); padding-bottom: 1.5mm; margin-bottom: 3mm; }
.mk { border-collapse: collapse; width: 100%; margin-bottom: 2.5mm; font-family: sans-serif; font-size: 9pt; }
.mk th, .mk td { border: 1px solid var(--ink); padding: .8mm 2mm; line-height: 1.4; }
.mk th { background: var(--pale); }
.bub { display: inline-flex; width: 6.4mm; height: 4.6mm; border: 1px solid #c0392b; border-radius: 50%; align-items: center;
       justify-content: center; font-size: 7pt; color: #c0392b; margin-right: 1.6mm; }
.grid { display: grid; grid-template-columns: repeat(20, 6.5mm); }
.grid span { height: 6.5mm; border: .6px solid #555; margin: 0 -.3px -.3px 0; }
.score { width: 22mm; text-align: right; vertical-align: bottom; font-size: 9pt; }
/* 解答と解説 */
.key td, .key th { font-size: 9pt; }
"""

PH_JS = """
<script>
document.querySelectorAll('img[data-ph]').forEach(function (img) {
  function ph() { var d = document.createElement('div'); d.className = 'ph'; d.innerHTML = img.getAttribute('data-ph'); img.replaceWith(d); }
  if (img.complete && img.naturalWidth === 0) ph(); else img.onerror = ph;
});
</script>
"""

CAMERA = ('<svg width="28" height="22" viewBox="0 0 28 22"><rect x="1" y="5" width="26" height="16" rx="3" fill="none" '
          'stroke="#1b2b44" stroke-width="2"/><circle cx="14" cy="13" r="5" fill="none" stroke="#1b2b44" stroke-width="2"/>'
          '<rect x="9" y="1" width="10" height="5" rx="1" fill="#1b2b44"/></svg>')


def doc(title, body):
    return (f'<!doctype html><html lang="ja"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width, initial-scale=1"><title>{e(title)}</title>'
            f'<style>{CSS}</style></head><body>{body}{PH_JS}</body></html>')


def render_fig(f):
    kind = f[0]
    if kind == "note":
        return f'<div class="note" style="flex-basis:100%">{f[1]}</div>'
    if kind == "svg":
        _, svg, cap, src = f
        return (f'<figure><div class="cap sans">{e(cap)}</div><div class="box">{svg}</div>'
                + (f'<div class="src sans">{e(src)}</div>' if src else "") + "</figure>")
    _, path, cap, src = f
    if src is None:
        c = CREDITS.get(pathlib.Path(path).name)
        src = f'{c["artist"]}／{c["license"]}（Wikimedia Commons）' if c else "出典未取得"
    ph = f'{CAMERA}<b>{e(cap)}</b>{e(path)} が見つかりません'
    return (f'<figure><div class="cap sans">{e(cap)}</div><div class="box"><img src="{e(path)}" alt="{e(cap)}" '
            f'data-ph="{e(ph)}"></div><div class="src sans">{e(src)}</div></figure>')


def render_choices(q):
    if "table" in q:
        t = q["table"]
        rows = len(t["rows"])
        head = "<tr><th></th>" + "".join(f"<th>{MARU[i]}</th>" for i in range(rows)) + "</tr>"
        body = "".join("<tr><th>" + e(h) + "</th>" + "".join(f"<td>{e(r[j])}</td>" for r in t["rows"]) + "</tr>"
                       for j, h in enumerate(t["head"]))
        return f'<table class="combo sans">{head}{body}</table>'
    cols = q.get("cols", 1)
    return (f'<div class="choices c{cols}">' + "".join(
        f'<div class="choice"><span>{MARU[i]}</span><span>{e(c)}</span></div>' for i, c in enumerate(q["choices"])) + "</div>")


def kana_head(i):
    return f"大問{i + 1}"


# ---------------- 問題冊子 ----------------
def booklet():
    silhouette = F.kanagawa(fill={n: "light" for n in F.CODE}, sea_labels=True)
    out = [f"""
<div class="page cover">
  <div class="band">
    <div class="org sans">{e(ORG)}</div>
    <h1>{e(TITLE)}</h1>
    <div class="sub">{e(SUBTITLE)}</div>
    <svg class="wave" viewBox="0 0 200 80"><path d="M0,60 Q25,20 50,50 T100,45 T150,40 T200,30 V80 H0Z" fill="#fff"/>
      <path d="M0,70 Q30,45 60,62 T120,58 T200,50 V80 H0Z" fill="#9fd3da"/></svg>
  </div>
  <div class="stripe"></div>
  <div class="mid">
    <div class="map">{silhouette}</div>
    <table class="info sans">
      <tr><th>試験時間</th><td>{EXAM_MINUTES}分</td></tr>
      <tr><th>問題数</th><td>大問{len(SECTIONS)}題・全{NQ}問</td></tr>
      <tr><th>配点</th><td>100点満点</td></tr>
      <tr><th>解答方法</th><td>マーク式・記述式<br>（別紙の解答用紙に記入）</td></tr>
      <tr><th>認定</th><td>ゴールド／シルバー／ブロンズ</td></tr>
    </table>
  </div>
  <div class="notice">
    <h3 class="sans">注意事項</h3>
    <ol>
      <li>試験開始の合図があるまで、この問題冊子を開いてはいけません。</li>
      <li>問題は大問1から大問{len(SECTIONS)}まであり、2ページから印刷されています。</li>
      <li>解答はすべて別紙の解答用紙に記入しなさい。マーク式の問題は、選んだ番号の〇を塗りつぶしなさい。</li>
      <li>記述式の問題は、1マスに1字ずつ書きなさい。句読点も1字に数えます。</li>
      <li>問題中の図・地図の多くは、内容をわかりやすくするために簡略化した模式図です。</li>
      <li>写真・図・資料をよく見て、そこから読み取れることをもとに考えなさい。</li>
      <li>印刷の不鮮明、ページの落丁・乱丁に気づいた場合は、手を挙げて監督者に知らせなさい。</li>
      <li>試験終了後、問題冊子は持ち帰ってかまいません。</li>
    </ol>
  </div>
  <div class="idbox sans"><b>受検番号</b><div class="cells">{"<span></span>" * 6}</div>
    <b style="margin-left:8mm">氏名</b><div style="flex:1;border-bottom:1.5px solid #1b2b44;height:10mm"></div></div>
  <div style="height:5mm"></div>
  <div class="start sans">試験開始の合図があるまで、問題冊子を開いてはいけません。</div>
</div>"""]
    for si, s in enumerate(SECTIONS):
        out.append('<div class="page">')
        out.append(f'<div class="sec-head sans"><div class="no">{kana_head(si)}</div><div class="ttl">{e(s["name"])}</div>'
                   f'<div class="pts">（配点 {s["pts"]}点）</div></div>')
        out.append(f'<p class="intro">{s["intro"]}</p>')
        if s.get("talk"):
            out.append('<div class="talk">' + "".join(
                f'<div class="row"><span class="who sans">{e(w)}</span><span>{t}</span></div>' for w, t in s["talk"]) + "</div>")
        for qi, q in enumerate(s["questions"]):
            out.append('<div class="q">')
            out.append('<div class="figs">' + "".join(render_fig(f) for f in q["figs"]) + "</div>")
            out.append(f'<div class="q-text"><span class="tag sans">問{qi + 1}</span>{q["q"]}<span class="pt sans">（{q["pts"]}点）</span></div>')
            if "stmts" in q:
                out.append('<div class="stmts">' + "".join(
                    f'<div class="stmt"><span>{KANA[i]}</span><span>{e(t)}</span></div>' for i, t in enumerate(q["stmts"])) + "</div>")
            if q["kind"] == "mark":
                out.append(render_choices(q))
            out.append("</div>")
        if si == len(SECTIONS) - 1:
            out.append('<p class="end">（これで、問題は終わりです。）</p>')
        out.append("</div>")
    return doc(f"{TITLE} 問題冊子", "".join(out))


# ---------------- 解答用紙 ----------------
def answer_sheet():
    out = [f"""<div class="sheet">
<div class="top"><div><div class="sans" style="font-size:9pt">{e(ORG)}</div><h1 class="sans">{e(TITLE)}　解答用紙</h1></div>
<div class="sans" style="font-size:8.5pt;text-align:right">マーク例　良い例 <span class="bub" style="background:#111;border-color:#111"></span>
悪い例 <span class="bub">✓</span><span class="bub">×</span></div></div>
<table class="mk sans"><tr><th style="width:20mm">受検番号</th><td style="width:55mm"></td><th style="width:14mm">氏名</th><td></td></tr>
<tr><th>合計得点</th><td style="text-align:right;font-size:12pt">／100</td><th>認定</th>
<td>□ ゴールド　□ シルバー　□ ブロンズ　□ 参加賞</td></tr></table>"""]
    for si, s in enumerate(SECTIONS):
        n = len(s["questions"])
        out.append(f'<table class="mk sans" style="page-break-inside:avoid"><tr><th colspan="2" style="text-align:left">'
                   f'{kana_head(si)}　{e(s["name"])}</th><th style="width:22mm">得点</th></tr>')
        for qi, q in enumerate(s["questions"]):
            if q["kind"] == "mark":
                cell = "".join(f'<span class="bub">{i + 1}</span>' for i in range(n_choices(q)))
            else:
                rows = -(-q["chars"] // 20)
                cell = '<div class="grid" style="margin:1mm 0">' + "<span></span>" * (rows * 20) + "</div>"
            out.append(f'<tr><td style="width:14mm;text-align:center">問{qi + 1}</td><td>{cell}</td>')
            if qi == 0:
                out.append(f'<td rowspan="{n}" class="score">／{s["pts"]}</td>')
            out.append("</tr>")
        out.append("</table>")
    out.append("</div>")
    return doc(f"{TITLE} 解答用紙", "".join(out))


# ---------------- 解答と解説 ----------------
def answer_key():
    out = [f'<div class="sheet"><div class="top"><div><div class="sans" style="font-size:9pt">{e(ORG)}</div>'
           f'<h1 class="sans">{e(TITLE)}　解答と解説</h1></div><div class="sans" style="font-size:9pt">採点者用</div></div>']
    for si, s in enumerate(SECTIONS):
        out.append(f'<div style="page-break-inside:avoid"><div class="sec-head sans" style="margin-top:3mm">'
                   f'<div class="no">{kana_head(si)}</div><div class="ttl">{e(s["name"])}</div>'
                   f'<div class="pts">（配点 {s["pts"]}点）</div></div>')
        out.append('<table class="mk key"><tr><th style="width:12mm">問</th><th style="width:11mm">配点</th>'
                   '<th style="width:34mm">正解</th><th>解説</th></tr>')
        for qi, q in enumerate(s["questions"]):
            ans = MARU[q["ans"] - 1] if q["kind"] == "mark" else q["ans"]
            out.append(f'<tr><td class="sans" style="text-align:center">{qi + 1}</td><td class="sans" style="text-align:center">{q["pts"]}</td>'
                       f'<td><b style="font-size:{"13pt" if q["kind"] == "mark" else "9pt"}">{e(ans)}</b></td><td>{e(q["exp"])}</td></tr>')
        out.append("</table></div>")
    rows = "".join(f'<tr><td>{kana_head(i)}　{e(s["name"])}</td><td style="text-align:center">{s["pts"]}</td>'
                   f'<td style="text-align:center">{unit_min(s["pts"])}点以上</td></tr>' for i, s in enumerate(SECTIONS))
    out.append(f"""
<div style="page-break-before:always"></div>
<div class="sec-head sans"><div class="no">認定</div><div class="ttl">認定基準</div></div>
<table class="mk"><tr><th style="width:42mm">認定</th><th>条件</th></tr>
<tr><td>神奈川知識ゴールド</td><td>{GOLD}点以上、かつ、すべての大問で得点率{int(UNIT_MIN_RATE * 100)}％以上（下表）</td></tr>
<tr><td>神奈川知識シルバー</td><td>{SILVER}点以上（ゴールドの条件を満たさない場合を含む）</td></tr>
<tr><td>神奈川知識ブロンズ</td><td>{BRONZE}点以上</td></tr>
<tr><td>参加賞</td><td>{BRONZE}点未満</td></tr></table>
<table class="mk"><tr><th>大問</th><th style="width:20mm">配点</th><th style="width:40mm">ゴールドに必要な得点</th></tr>{rows}</table>
<div class="sec-head sans" style="margin-top:4mm"><div class="no">採点</div><div class="ttl">採点上の注意</div></div>
<ul style="margin-top:0">
<li>マーク式は各3点。正解の番号のみ得点とする。</li>
<li>記述式は各5点。解説欄の採点基準にしたがって部分点を与える。字数を超えたものは0点とする。</li>
</ul>""")
    photos = [(si, qi, f) for si, s in enumerate(SECTIONS) for qi, q in enumerate(s["questions"])
              for f in q["figs"] if f[0] == "img" and f[3] is None]
    prow = ""
    for si, qi, f in photos:
        c = CREDITS.get(pathlib.Path(f[1]).name, {})
        prow += (f'<tr><td>{kana_head(si)} 問{qi + 1}</td><td>{e(f[2])}</td><td>{e(c.get("artist", ""))}</td>'
                 f'<td>{e(c.get("license", ""))}</td><td style="word-break:break-all;font-size:7.5pt">{e(c.get("page", ""))}</td></tr>')
    out.append(f"""
<div class="sec-head sans" style="margin-top:4mm"><div class="no">写真</div><div class="ttl">写真の出典（Wikimedia Commons）</div></div>
<p style="font-size:9pt;margin:0 0 2mm">いずれもパブリックドメイン、CC0、またはクリエイティブ・コモンズ（CC BY／CC BY-SA）のもとで公開されている写真・作品。
CC BY／CC BY-SA の写真は、作者名とライセンスを表示して利用する（問題冊子の各写真の下にも表示している）。</p>
<table class="mk"><tr><th style="width:20mm">使う問題</th><th style="width:48mm">写真</th><th style="width:34mm">作者</th><th style="width:20mm">ライセンス</th><th>ファイルページ</th></tr>{prow}</table>
<div class="sec-head sans" style="margin-top:4mm"><div class="no">出典</div><div class="ttl">地図・統計の出典</div></div>
<ul style="margin-top:0;font-size:9pt">
<li>地図・空中写真：国土地理院「地理院タイル」（色別標高図・陰影起伏図・淡色地図・標準地図・全国最新写真）を加工して作成</li>
<li>市町村界：国土地理院「地球地図日本」（jpn-atlas による TopoJSON 版）をもとに作成</li>
<li>横浜港の輸出額：横浜税関「横浜港 貿易概況（2024年分 速報）」</li>
<li>昼夜間人口比率：総務省「令和2年国勢調査」、横浜市・神奈川県の公表資料</li>
<li>人口・世帯の増減率：神奈川県「令和7年国勢調査結果速報」、開成町の公表資料</li>
<li>箱根登山電車の標高・距離：箱根登山鉄道の公表資料ほか</li>
</ul></div>""")
    return doc(f"{TITLE} 解答と解説", "".join(out))


def main():
    files = {"01_問題冊子": booklet(), "02_解答用紙": answer_sheet(), "03_解答と解説": answer_key()}
    for name, content in files.items():
        (ROOT / f"{name}.html").write_text(content, encoding="utf-8")
    npm_root = subprocess.run(["npm", "root", "-g"], capture_output=True, text=True).stdout.strip()
    subprocess.run(["node", str(ROOT / "render_pdf.js")], check=False, env={**os.environ, "NODE_PATH": npm_root})


if __name__ == "__main__":
    main()
