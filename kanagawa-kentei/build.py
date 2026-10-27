"""神奈川県検定の 問題冊子・解答用紙・解答と解説 を HTML と PDF で出力する（特色検査形式）。

使い方: python3 build.py
写真は fetch_images.py、地図は gsi_maps.py で images/ に用意しておく。
PDF 変換には Node.js 版 Playwright（render_pdf.js）を使う。
"""
import os
import pathlib
import re
import subprocess

import figures as F
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
/* 表紙（第2版のデザイン） */
:root { --ink:#1b2b44; --accent:#0f6d7a; --red:#c0392b; --pale:#eef3f8; }
.sans { font-family: "Hiragino Kaku Gothic ProN","Yu Gothic","Noto Sans CJK JP","IPAGothic",sans-serif; }
.cover { height: 263mm; display: flex; flex-direction: column; }
.cover .band { background: var(--ink); color: #fff; padding: 9mm 10mm 7mm; border-radius: 4mm 4mm 0 0; position: relative; overflow: hidden; }
.cover .band .org { font-size: 10pt; letter-spacing: .3em; opacity: .85; }
.cover .band h1 { font-size: 30pt; margin: 3mm 0 1mm; letter-spacing: .12em; font-weight: 900; }
.cover .band .sub { font-size: 13pt; letter-spacing: .3em; }
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
/* 問5（写真と問いを左右に並べる） */
.side { display: grid; grid-template-columns: 62mm 1fr; gap: 4mm; align-items: start; }
.side .fbox img { max-height: 46mm; }
.side .ch { margin-left: 9mm; }
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
    silhouette = F.kanagawa(fill={n: "light" for n in F.CODE}, sea_labels=True)
    nums = "、".join(f"問{i + 1}" for i in range(len(SECTIONS)))
    out = [f"""
<div class="page cover">
  <div class="band">
    <div class="org sans">{e(ORG)}</div>
    <h1 class="sans">{e(TITLE)}</h1>
    <div class="sub sans">{e(SUBTITLE)}</div>
    <svg class="wave" viewBox="0 0 200 80"><path d="M0,60 Q25,20 50,50 T100,45 T150,40 T200,30 V80 H0Z" fill="#fff"/>
      <path d="M0,70 Q30,45 60,62 T120,58 T200,50 V80 H0Z" fill="#9fd3da"/></svg>
  </div>
  <div class="stripe"></div>
  <div class="mid">
    <div class="map">{silhouette}</div>
    <table class="info sans">
      <tr><th>検査時間</th><td>{EXAM_MINUTES}分</td></tr>
      <tr><th>問題数</th><td>問1〜問{len(SECTIONS)}・全{NQ}問</td></tr>
      <tr><th>配点</th><td>100点満点</td></tr>
      <tr><th>解答方法</th><td>マーク式・記述式<br>（別紙の解答用紙に記入）</td></tr>
      <tr><th>認定</th><td>ゴールド／シルバー／ブロンズ</td></tr>
    </table>
  </div>
  <div class="notice">
    <h3 class="sans">注意事項</h3>
    <ol>
      <li>開始の合図があるまで、この問題冊子を開いてはいけません。</li>
      <li>本検査の問題は、{nums}の{len(SECTIONS)}問あり、2ページから印刷されています。</li>
      <li>解答は、すべて解答用紙の決められた欄に記入しなさい。マークシート方式の問題は、選んだ番号の〇の中を塗りつぶしなさい。</li>
      <li>記述式の問題は、1マスに1字ずつ書きなさい。句読点や記号も1字に数えます。</li>
      <li>資料中の図の多くは、内容をわかりやすくするために簡略化しています。</li>
      <li>計算や下書きは、問題冊子のあいているところを使いなさい。</li>
      <li>印刷の不鮮明、ページの落丁・乱丁に気づいた場合は、手を挙げて監督者に知らせなさい。</li>
      <li>終了の合図があったら、すぐに解答をやめなさい。問題冊子は持ち帰ってかまいません。</li>
    </ol>
  </div>
  <div class="idbox sans"><b>受検番号</b><div class="cells">{"<span></span>" * 6}</div>
    <b style="margin-left:8mm">氏名</b><div style="flex:1;border-bottom:1.5px solid #1b2b44;height:10mm"></div></div>
  <div style="height:5mm"></div>
  <div class="start sans">試験開始の合図があるまで、問題冊子を開いてはいけません。</div>
</div>"""]
    for si, s in enumerate(SECTIONS):
        out.append('<div class="page">')
        out.append(f'<div class="mon"><span class="qh">問{si + 1}</span>{s["lead"]}</div>')
        out.extend(s["materials"])
        for qi, q in enumerate(s["questions"]):
            out.append('<div class="sq">')
            qt = (f'<div class="qt"><span>({SUB[qi]})</span><span>{q["q"]}'
                  f'<span class="pt">（{q["pts"]}点）</span></span></div>')
            if q.get("side"):
                out.append(f'<div class="side"><div>{"".join(q["pre"])}</div><div>{qt}{choices(q)}</div></div>')
            else:
                out.append(qt)
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
<li>マーク式は問1〜問4が各3点、問5が各2点。正答の番号のみ得点とする。</li>
<li>記述式は各8点。解説欄の採点基準にしたがって部分点を与える。35字未満・45字超は2点減点、指定語句の欠落は1語につき2点減点、文末の指定違反は2点減点（0点未満にはしない）。</li>
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
