"""神奈川県検定の 問題冊子・解答用紙・解答と解説 を HTML と PDF で出力する（特色検査形式）。

使い方: python3 build.py
写真は fetch_images.py、地図は gsi_maps.py で images/ に用意しておく。
PDF 変換には Node.js 版 Playwright（render_pdf.js）を使う。
"""
import os
import pathlib
import re
import subprocess

from layout import CREDITS, e
from questions import (BRONZE, EXAM_MINUTES, GOLD, ORG, SECTIONS, SILVER, SUBTITLE, TITLE,
                       UNIT_MIN_RATE)

ROOT = pathlib.Path(__file__).parent
SUB = "アイウエオカキクケコ"

for s in SECTIONS:
    s["pts"] = sum(q["pts"] for q in s["questions"])
TOTAL = sum(s["pts"] for s in SECTIONS)
assert TOTAL == 100, TOTAL
NQ = sum(len(s["questions"]) for s in SECTIONS)
for s in SECTIONS:
    for q in s["questions"]:
        if q["kind"] == "mark":
            assert 1 <= q["ans"] <= len(q["choices"]), q["q"][:30]


def unit_min(pts):
    return -(-pts * int(UNIT_MIN_RATE * 10) // 10)


CSS = """
@page { size: A4; margin: 14mm 15mm 15mm; }
* { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { font-family: "Yu Mincho","YuMincho","Hiragino Mincho ProN","Noto Serif CJK JP","IPAMincho",serif;
       font-size: 10.3pt; line-height: 1.75; color: #000; background: #fff; margin: 0; }
b, .lbl, .who, .qh { font-family: "Hiragino Kaku Gothic ProN","Yu Gothic","Noto Sans CJK JP","IPAGothic",sans-serif; }
.page { page-break-after: always; }
/* 表紙 */
.cover { height: 265mm; display: flex; flex-direction: column; align-items: center; }
.cover .yr { margin-top: 18mm; font-size: 13pt; }
.cover h1 { font-size: 20pt; margin: 3mm 0 0; letter-spacing: .08em; text-align: center; line-height: 1.6; }
.cover .org { font-size: 12pt; letter-spacing: .2em; }
.cover .notice { width: 150mm; margin-top: 12mm; border: 1.5px solid #000; padding: 4mm 7mm; font-size: 10.5pt; line-height: 1.9; }
.cover .notice h3 { text-align: center; letter-spacing: .6em; margin: 0 0 2mm; font-size: 12pt; }
.cover .notice ol { margin: 0; padding-left: 6mm; }
.cover .id { margin-top: 12mm; display: flex; align-items: stretch; border: 1.5px solid #000; }
.cover .id .h { padding: 3mm 6mm; border-right: 1.5px solid #000; display: flex; align-items: center; font-weight: bold; }
.cover .id span { width: 12mm; height: 14mm; border-right: 1px solid #000; }
.cover .id span:last-child { border-right: 0; width: 10mm; text-align: center; line-height: 14mm; }
/* 問 */
.mon { margin: 0 0 3mm; }
.mon .qh { font-weight: bold; font-size: 11.5pt; margin-right: 2mm; }
.blk { margin: 2mm 0 3mm; page-break-inside: avoid; }
.lbl { font-weight: bold; font-size: 10.3pt; margin-bottom: .5mm; }
.box { border: 1.2px dashed #000; padding: 2mm 3.5mm; }
.box.solid { border-style: solid; }
.tk { display: grid; grid-template-columns: 18mm 1fr; }
.who { font-size: 10pt; }
.st { display: grid; grid-template-columns: 6mm 1fr; }
.foot { font-size: 9pt; margin: -1mm 0 3mm 2mm; }
.row { display: flex; gap: 4mm; align-items: flex-start; margin: 2mm 0 3mm; page-break-inside: avoid; }
.row > div { min-width: 0; }
.row .blk { margin: 0; }
figure { margin: 0; page-break-inside: avoid; }
.fbox { border: 1px solid #000; padding: 1.5mm; background: #fff; }
.fbox img { display: block; width: 100%; max-height: 70mm; object-fit: contain; }
.fbox svg { display: block; width: 100%; max-height: 74mm; }
figcaption { font-size: 9pt; text-align: center; margin-top: .5mm; line-height: 1.4; }
figcaption .src { display: block; font-size: 7pt; color: #333; text-align: right; }
.tblk { margin: 2mm 0 3mm; page-break-inside: avoid; }
table.dt { border-collapse: collapse; font-size: 9.6pt; margin: 0 auto; }
table.dt th, table.dt td { border: 1px solid #000; padding: .6mm 3mm; line-height: 1.45; text-align: center; }
table.dt.sm th, table.dt.sm td { font-size: 8.8pt; padding: .4mm 2mm; }
table.dt th { background: #f2f2f2; font-family: sans-serif; }
.tblk .src { font-size: 7pt; text-align: right; color: #333; }
.sq { margin: 4mm 0 5mm; page-break-inside: avoid; }
.sq .qt { display: grid; grid-template-columns: 9mm 1fr; }
.ch { display: grid; gap: .3mm 8mm; margin: 1.5mm 0 0 11mm; font-size: 10pt; }
.ch div { display: grid; grid-template-columns: 6mm 1fr; }
.pt { font-size: 8.5pt; }
.end { text-align: right; margin-top: 5mm; }
/* 解答用紙・解説 */
.sheet h1 { font-size: 15pt; margin: 0; }
.sheet .top { display: flex; justify-content: space-between; align-items: flex-end; border-bottom: 2px solid #000;
              padding-bottom: 1.5mm; margin-bottom: 3mm; }
.mk { border-collapse: collapse; width: 100%; margin-bottom: 3mm; font-family: sans-serif; font-size: 9pt; }
.mk th, .mk td { border: 1px solid #000; padding: 1mm 2mm; line-height: 1.45; vertical-align: middle; }
.mk th { background: #f2f2f2; }
.bub { display: inline-flex; width: 6.6mm; height: 4.8mm; border: 1px solid #000; border-radius: 50%; align-items: center;
       justify-content: center; font-size: 7.5pt; margin-right: 1.8mm; }
.grid { display: grid; grid-template-columns: repeat(15, 7.2mm); margin: 1mm 0 3mm; }
.grid span { height: 7.2mm; border: .6px solid #555; margin: 0 -.3px -.3px 0; position: relative; }
.grid span.m::after { content: attr(data-n); position: absolute; right: -.5mm; bottom: -3.4mm; font-size: 6pt; }
.score { width: 20mm; text-align: right; vertical-align: bottom !important; }
.key td { font-size: 8.8pt; }
"""


def doc(title, body):
    return (f'<!doctype html><html lang="ja"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width, initial-scale=1"><title>{e(title)}</title>'
            f'<style>{CSS}</style></head><body>{body}</body></html>')


def choices(q):
    cols = q.get("cols", 1)
    # 長い「X：…　Y：…」の選択肢は、Yを改行して揃える
    items = [re.sub(r"[\s　]*Y：", "<br>Y：", c) if len(c) > 40 else c for c in q["choices"]]
    return (f'<div class="ch" style="grid-template-columns:repeat({cols},1fr)">' + "".join(
        f"<div><span>{i + 1}.</span><span>{c}</span></div>" for i, c in enumerate(items)) + "</div>")


# ---------------- 問題冊子 ----------------
def booklet():
    out = [f"""
<div class="page cover">
  <div class="yr">令和8年度</div>
  <h1>{e(TITLE)}<br>{e(SUBTITLE)}</h1>
  <div class="org" style="margin-top:4mm">{e(ORG)}</div>
  <div class="notice">
    <h3>注意事項</h3>
    <ol>
      <li>開始の合図があるまで、この問題冊子を開いてはいけません。</li>
      <li>本検査の問題は、問1、問2、問3、問4の4問あり、2ページから印刷されています。</li>
      <li>検査時間は{EXAM_MINUTES}分です。</li>
      <li>問題用紙・解答用紙の印刷不鮮明や汚れに気づいた場合は、手を挙げて監督者に知らせなさい。</li>
      <li>計算や下書きは、問題冊子のあいているところを使いなさい。</li>
      <li>解答は、すべて解答用紙の決められた欄に記入しなさい。</li>
      <li>マークシート方式により解答する場合は、選んだ番号の〇の中を塗りつぶしなさい。</li>
      <li>記述式の問題は、1マスに1字ずつ書きなさい。句読点や記号も1字に数えます。</li>
      <li>資料中の図の多くは、内容をわかりやすくするために簡略化しています。</li>
      <li>終了の合図があったら、すぐに解答をやめなさい。</li>
    </ol>
  </div>
  <div class="id"><div class="h">受 検 番 号</div>{"<span></span>" * 4}<span>番</span></div>
  <div style="margin-top:6mm;display:flex;gap:3mm;align-items:flex-end;width:120mm"><b>氏名</b>
    <div style="flex:1;border-bottom:1px solid #000;height:9mm"></div></div>
</div>"""]
    for si, s in enumerate(SECTIONS):
        out.append('<div class="page">')
        out.append(f'<div class="mon"><span class="qh">問{si + 1}</span>{s["lead"]}</div>')
        out.extend(s["materials"])
        for qi, q in enumerate(s["questions"]):
            out.append('<div class="sq">')
            out.append(f'<div class="qt"><span>({SUB[qi]})</span><span>{q["q"]}'
                       f'<span class="pt">（{q["pts"]}点）</span></span></div>')
            out.extend(q.get("pre", []))
            if q["kind"] == "mark":
                out.append(choices(q))
            if si == len(SECTIONS) - 1 and qi == len(s["questions"]) - 1:
                out.append('<p class="end">（これで、問題は終わりです。）</p>')
            out.append("</div>")
        out.append("</div>")
    return doc(f"{TITLE} 問題冊子", "".join(out))


# ---------------- 解答用紙 ----------------
def grid(n):
    cells = [f'<span class="m" data-n="{i}"></span>' if i in (35, 45) else "<span></span>" for i in range(1, n + 1)]
    return '<div class="grid">' + "".join(cells) + "</div>"


def answer_sheet():
    out = [f"""<div class="sheet">
<div class="top"><div><div style="font-size:9pt">{e(ORG)}</div><h1>{e(TITLE)}　解答用紙</h1></div>
<div style="font-size:8.5pt;text-align:right;font-family:sans-serif">マーク例　良い例 <span class="bub" style="background:#000"></span>
悪い例 <span class="bub">✓</span><span class="bub">×</span></div></div>
<table class="mk"><tr><th style="width:20mm">受検番号</th><td style="width:50mm"></td><th style="width:14mm">氏名</th><td></td></tr>
<tr><th>合計得点</th><td style="text-align:right;font-size:12pt">／100</td><th>認定</th>
<td>□ ゴールド　□ シルバー　□ ブロンズ　□ 参加賞</td></tr></table>"""]
    for si, s in enumerate(SECTIONS):
        n = len(s["questions"])
        out.append(f'<table class="mk" style="page-break-inside:avoid"><tr><th colspan="2" style="text-align:left">'
                   f'問{si + 1}</th><th style="width:20mm">得点</th></tr>')
        for qi, q in enumerate(s["questions"]):
            if q["kind"] == "mark":
                cell = "".join(f'<span class="bub">{i + 1}</span>' for i in range(len(q["choices"])))
            else:
                cell = grid(q["chars"])
            out.append(f'<tr><td style="width:12mm;text-align:center">({SUB[qi]})</td><td>{cell}</td>')
            if qi == 0:
                out.append(f'<td rowspan="{n}" class="score">／{s["pts"]}</td>')
            out.append("</tr>")
        out.append("</table>")
    out.append("</div>")
    return doc(f"{TITLE} 解答用紙", "".join(out))


# ---------------- 解答と解説 ----------------
def answer_key():
    out = [f'<div class="sheet"><div class="top"><div><div style="font-size:9pt">{e(ORG)}</div>'
           f'<h1>{e(TITLE)}　正答・解説・出題のねらい</h1></div><div style="font-size:9pt">採点者用</div></div>']
    for si, s in enumerate(SECTIONS):
        out.append(f'<div style="page-break-inside:avoid"><p style="margin:3mm 0 1mm"><b>問{si + 1}　{e(s["name"])}'
                   f'（配点 {s["pts"]}点）</b></p>')
        out.append('<table class="mk key"><tr><th style="width:10mm">小問</th><th style="width:9mm">配点</th>'
                   '<th style="width:30mm">正答</th><th>解説</th><th style="width:42mm">出題のねらい</th></tr>')
        for qi, q in enumerate(s["questions"]):
            ans = str(q["ans"]) if q["kind"] == "mark" else q["ans"]
            size = "13pt" if q["kind"] == "mark" else "8.5pt"
            out.append(f'<tr><td style="text-align:center">({SUB[qi]})</td><td style="text-align:center">{q["pts"]}</td>'
                       f'<td><b style="font-size:{size}">{e(ans)}</b></td><td>{e(q["exp"])}</td><td>{e(q["intent"])}</td></tr>')
        out.append("</table></div>")
    rows = "".join(f'<tr><td>問{i + 1}　{e(s["name"])}</td><td style="text-align:center">{s["pts"]}</td>'
                   f'<td style="text-align:center">{unit_min(s["pts"])}点以上</td></tr>' for i, s in enumerate(SECTIONS))
    out.append(f"""
<div style="page-break-before:always"></div>
<p><b>認定基準</b></p>
<table class="mk"><tr><th style="width:42mm">認定</th><th>条件</th></tr>
<tr><td>神奈川知識ゴールド</td><td>{GOLD}点以上、かつ、すべての問で得点率{int(UNIT_MIN_RATE * 100)}％以上（下表）</td></tr>
<tr><td>神奈川知識シルバー</td><td>{SILVER}点以上（ゴールドの条件を満たさない場合を含む）</td></tr>
<tr><td>神奈川知識ブロンズ</td><td>{BRONZE}点以上</td></tr>
<tr><td>参加賞</td><td>{BRONZE}点未満</td></tr></table>
<table class="mk"><tr><th>問</th><th style="width:20mm">配点</th><th style="width:40mm">ゴールドに必要な得点</th></tr>{rows}</table>
<p><b>採点上の注意</b></p>
<ul style="margin-top:0;font-size:9.5pt">
<li>マーク式は各4点。正答の番号のみ得点とする。</li>
<li>記述式は各9点。解説欄の採点基準にしたがって部分点を与える。35字未満・45字超は2点減点、指定語句の欠落は1語につき2点減点、文末の指定違反は2点減点（0点未満にはしない）。</li>
</ul>""")
    used = []
    for si, s in enumerate(SECTIONS):
        html_all = "".join(s["materials"]) + "".join("".join(q.get("pre", [])) for q in s["questions"])
        for name, c in CREDITS.items():
            if f"images/{name}" in html_all:
                used.append((si, c))
    prow = "".join(f'<tr><td>問{si + 1}</td><td>{e(c["title"])}</td><td>{e(c["artist"])}</td><td>{e(c["license"])}</td>'
                   f'<td style="word-break:break-all;font-size:7pt">{e(c["page"])}</td></tr>' for si, c in used)
    out.append(f"""
<p><b>写真・図版の出典（Wikimedia Commons）</b></p>
<p style="font-size:8.5pt;margin:0 0 1mm">いずれもパブリックドメイン、CC0、またはCC BY／CC BY-SAで公開されているもの。CC BY／CC BY-SAの写真は、作者名とライセンスを表示して利用する（問題冊子の各写真の下にも表示）。</p>
<table class="mk"><tr><th style="width:10mm">問</th><th>ファイル名</th><th style="width:30mm">作者</th><th style="width:20mm">ライセンス</th><th style="width:55mm">ファイルページ</th></tr>{prow}</table>
<p><b>地図・統計の出典</b></p>
<ul style="margin-top:0;font-size:9pt">
<li>地図・空中写真：国土地理院「地理院タイル」（色別標高図・陰影起伏図・淡色地図・全国最新写真）を加工して作成</li>
<li>市町村界：国土地理院「地球地図日本」（jpn-atlas による TopoJSON 版）をもとに作成</li>
<li>1865年の輸出入品：石井孝『幕末貿易史の研究』（中学・高校教科書に掲載の数値）</li>
<li>昼夜間人口比率：総務省「令和2年国勢調査」、横浜市・神奈川県の公表資料</li>
<li>人口・世帯の増減率：神奈川県「令和7年国勢調査結果速報」、開成町の公表資料</li>
<li>箱根登山電車の標高・距離：箱根登山鉄道の公表資料ほか</li>
<li>問1の表1、問3(イ)の時刻設定は、この検査のために設定した模式的な値</li>
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
