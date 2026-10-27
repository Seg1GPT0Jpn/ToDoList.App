"""神奈川県検定の 問題冊子・解答用紙・解答と解説 を HTML と PDF で出力する。

使い方: python3 build.py
写真は images/p01.jpg 〜 p10.jpg に保存すると問題冊子に入る（無い場合は枠だけ表示）。
"""
import html
import os
import pathlib
import subprocess

from questions import (BRONZE, EXAM_MINUTES, GOLD, SECTIONS, SILVER, TITLE,
                       UNIT_MIN_RATE)

ROOT = pathlib.Path(__file__).parent
KANA = "アイウエオカキク"
MARU = "①②③④⑤⑥"
KANSUJI = "〇一二三四五六七八九"
FW = str.maketrans("0123456789", "０１２３４５６７８９")

for s in SECTIONS:
    s["pts"] = sum(q["pts"] for q in s["questions"])
TOTAL = sum(s["pts"] for s in SECTIONS)
assert TOTAL == 100, TOTAL


def e(t):
    return html.escape(str(t))


def unit_min(pts):
    # 60%以上 を満たす最小の得点
    return -(-pts * int(UNIT_MIN_RATE * 10) // 10)


CSS = """
@page { size: A4; margin: 18mm 18mm 20mm; }
* { box-sizing: border-box; }
body { font-family: "Yu Mincho", "YuMincho", "Hiragino Mincho ProN", "IPAMincho", "Noto Serif CJK JP", serif;
       font-size: 11pt; line-height: 2.0; color: #000; background: #fff; margin: 0; }
h1 { font-size: 22pt; text-align: center; margin: 0; letter-spacing: .1em; }
.page { page-break-after: always; }
.box { border: 1px solid #000; padding: 1px 6px; }
.label { border: 1px solid #000; padding: 0 4px; font-weight: bold; }
.right { text-align: right; }
.center { text-align: center; }
.small { font-size: 9pt; line-height: 1.6; }
.sec-title { font-weight: bold; font-size: 12.5pt; margin: 0 0 4mm; }
.q { margin: 0 0 6mm; page-break-inside: avoid; }
.q-head { font-weight: bold; }
.choices { display: grid; grid-template-columns: 1fr 1fr; gap: 0 8mm; margin: 1mm 0 1mm 4mm; }
.choices.wide { grid-template-columns: 1fr; }
.ansline { display: inline-block; min-width: 55mm; border-bottom: 1px solid #000; margin-left: 4mm; }
figure.photo { margin: 2mm 0 2mm; text-align: center; }
figure.photo img { max-width: 120mm; max-height: 68mm; border: 1px solid #000; }
.ph { width: 110mm; height: 62mm; margin: 0 auto; border: 1px dashed #000; display: flex;
      flex-direction: column; align-items: center; justify-content: center; font-size: 9pt; line-height: 1.6; }
figcaption { font-size: 9pt; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #000; padding: 1.5mm 2mm; vertical-align: middle; line-height: 1.5; }
th { background: #eee; font-weight: bold; }
"""

PH_JS = """
<script>
document.querySelectorAll('img[data-ph]').forEach(function (img) {
  function ph() {
    var d = document.createElement('div'); d.className = 'ph';
    d.innerHTML = img.getAttribute('data-ph');
    img.replaceWith(d);
  }
  if (img.complete && img.naturalWidth === 0) ph(); else img.onerror = ph;
});
</script>
"""


def doc(title, body):
    return (f'<!doctype html><html lang="ja"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width, initial-scale=1">'
            f'<title>{e(title)}</title><style>{CSS}</style></head><body>{body}{PH_JS}</body></html>')


def sec_label(i):
    return f"第{KANSUJI[i + 1]}問"


# ---------------- 問題冊子 ----------------
def booklet():
    out = [f"""
<div class="page">
  <div style="display:flex;justify-content:space-between" class="small">
    <span>神奈川県教育委員会</span><span class="box">試験時間 {EXAM_MINUTES} 分</span></div>
  <div class="center small" style="margin-top:2mm"><span class="box">試験開始の合図があるまで、問題冊子を開いてはいけません。</span></div>
  <div style="height:30mm"></div>
  <h1>{e(TITLE)}</h1>
  <p class="center" style="margin:2mm 0 0">― 神奈川を知る・神奈川を好きになる ―</p>
  <div style="height:25mm"></div>
  <p class="right">受検番号<span class="ansline"></span></p>
  <p class="right">氏　　名<span class="ansline"></span></p>
  <div style="height:12mm"></div>
  <p><b>注　意　事　項</b></p>
  <ol style="margin:0;padding-left:6mm">
    <li>問題は{sec_label(len(SECTIONS) - 1)}まであり、全{sum(len(s['questions']) for s in SECTIONS)}問・100点満点です。</li>
    <li>解答は、すべて別紙の解答用紙の決められた欄に記入しなさい。</li>
    <li>記号で答える問題は、ア・イ・ウ・エなどの記号で答えなさい。</li>
    <li>「完答」とある問題は、すべて正しい場合のみ得点となります。</li>
    <li>文字は解答欄からはみ出さないように、はっきり書きなさい。ひらがなで答えても正解とします。</li>
    <li>印刷が不明瞭なページや落丁に気づいた場合は、手を挙げて監督者に知らせなさい。</li>
    <li>終了の合図があったら、すぐに解答をやめなさい。</li>
    <li>この問題冊子は、試験終了後に持ち帰ってかまいません。</li>
  </ol>
</div>"""]
    for si, s in enumerate(SECTIONS):
        out.append('<div class="page">')
        out.append(f'<p class="sec-title">{sec_label(si)}　{e(s["name"])}（配点 {s["pts"]}）</p>')
        out.append(f'<p>{e(s["lead"])}</p>')
        for qi, q in enumerate(s["questions"]):
            out.append('<div class="q">')
            if "photo" in q:
                p = q["photo"]
                ph = (f'写真{qi + 1}（{e(p["desc"])}）<br>images/{e(p["file"])} を保存すると表示されます')
                out.append(f'<figure class="photo"><img src="images/{e(p["file"])}" alt="写真{qi + 1}" data-ph="{ph}">'
                           f'<figcaption>写真{qi + 1}</figcaption></figure>')
            out.append(f'<span class="q-head">問題{str(qi + 1).translate(FW)}</span>　{e(q["q"])}')
            if q["type"] == "match":
                out.append('<div class="choices wide">' + "".join(
                    f"<div>{MARU[i]} {e(x)}</div>" for i, x in enumerate(q["left"])) + "</div>")
                out.append('<div class="label" style="display:inline-block;margin-left:4mm">説明</div>')
            if q["type"] in ("mc", "order", "match"):
                wide = any(len(c) > 14 for c in q["choices"]) or q["type"] != "mc"
                out.append(f'<div class="choices{" wide" if wide else ""}">' + "".join(
                    f"<div>{KANA[i]}　{e(c)}</div>" for i, c in enumerate(q["choices"])) + "</div>")
            out.append("</div>")
        if si == len(SECTIONS) - 1:
            out.append('<p class="right">（これで、問題は終わりです。）</p>')
        out.append("</div>")
    return doc(f"{TITLE} 問題冊子", "".join(out))


# ---------------- 解答用紙 ----------------
def answer_sheet():
    out = [f"""
<div style="display:flex;justify-content:space-between;align-items:flex-end">
  <h1 style="font-size:16pt;text-align:left">{e(TITLE)}　解答用紙</h1>
  <span class="small">各大問の右の得点欄は採点者が記入</span></div>
<table style="margin:3mm 0 4mm"><tr>
  <th style="width:18%">受検番号</th><td style="width:32%"></td>
  <th style="width:12%">氏名</th><td></td></tr>
<tr><th>合計得点</th><td style="text-align:right;font-size:13pt">／100</td>
  <th>認定</th><td class="small">□ ゴールド　□ シルバー　□ ブロンズ　□ 参加賞</td></tr></table>"""]
    for si, s in enumerate(SECTIONS):
        out.append(f'<table style="margin-bottom:3mm;page-break-inside:avoid"><tr>'
                   f'<th colspan="2" style="text-align:left">{sec_label(si)}　{e(s["name"])}</th>'
                   f'<th style="width:24mm">得点</th></tr>')
        n = len(s["questions"])
        for qi, q in enumerate(s["questions"]):
            t = q["type"]
            if t == "order":
                cell = " → ".join(['<span style="display:inline-block;width:11mm;height:8mm;border:1px solid #000;vertical-align:middle"></span>'] * 5)
            elif t == "match":
                cell = "　".join(f'{MARU[i]}<span style="display:inline-block;width:11mm;height:8mm;border:1px solid #000;vertical-align:middle"></span>' for i in range(4))
            else:
                cell = ""
            h = "7.5mm" if t == "mc" else "10mm"
            out.append(f'<tr style="height:{h}"><td style="width:20mm" class="center">問題{str(qi + 1).translate(FW)}</td><td>{cell}</td>')
            if qi == 0:
                out.append(f'<td rowspan="{n}" style="text-align:right;vertical-align:bottom">／{s["pts"]}</td>')
            out.append("</tr>")
        out.append("</table>")
    return doc(f"{TITLE} 解答用紙", "".join(out))


# ---------------- 解答と解説 ----------------
def answer_key():
    out = [f'<h1 style="font-size:16pt">{e(TITLE)}　解答と解説</h1>',
           '<p class="center small">（採点者用・試験終了後に配布可）</p>']
    for si, s in enumerate(SECTIONS):
        out.append(f'<div style="page-break-inside:avoid"><p class="sec-title" style="margin-top:5mm">{sec_label(si)}　{e(s["name"])}（配点 {s["pts"]}）</p>')
        out.append('<table><tr><th style="width:16mm">問題</th><th style="width:16mm">配点</th>'
                   '<th style="width:48mm">正解</th><th>解説</th></tr>')
        for qi, q in enumerate(s["questions"]):
            ans = q["ans"]
            if q["type"] == "mc":
                ans = f'{ans}　{q["choices"][KANA.index(ans)]}'
            out.append(f'<tr><td class="center">{qi + 1}</td><td class="center">{q["pts"]}</td>'
                       f'<td><b>{e(ans)}</b></td><td class="small">{e(q["exp"])}</td></tr>')
        out.append("</table></div>")
    rows = "".join(f'<tr><td>{sec_label(i)} {e(s["name"])}</td><td class="center">{s["pts"]}</td>'
                   f'<td class="center">{unit_min(s["pts"])}点以上</td></tr>' for i, s in enumerate(SECTIONS))
    out.append(f"""
<div style="page-break-before:always"></div>
<p class="sec-title">認定基準</p>
<table><tr><th>認定</th><th>条件</th></tr>
<tr><td>神奈川知識ゴールド</td><td>{GOLD}点以上　かつ　すべての大問で得点率{int(UNIT_MIN_RATE * 100)}%以上（下表）</td></tr>
<tr><td>神奈川知識シルバー</td><td>{SILVER}点以上（ゴールドの条件を満たさない場合）</td></tr>
<tr><td>神奈川知識ブロンズ</td><td>{BRONZE}点以上</td></tr>
<tr><td>参加賞</td><td>{BRONZE}点未満</td></tr></table>
<p class="sec-title" style="margin-top:5mm">ゴールド認定に必要な各大問の得点</p>
<table><tr><th>大問</th><th>配点</th><th>必要な得点（60%以上）</th></tr>{rows}</table>
<p class="sec-title" style="margin-top:5mm">採点上の注意</p>
<ul class="small">
<li>記述問題は、ひらがな・カタカナで書かれていても内容が正しければ正解とする。</li>
<li>並べ替え・組み合わせ問題は完答のみ得点とし、部分点は与えない。</li>
</ul>""")
    photos = [(qi, q["photo"]) for qi, q in enumerate(SECTIONS[-1]["questions"])]
    prow = "".join(f'<tr><td class="center">写真{qi + 1}</td><td>{e(p["file"])}</td><td>{e(p["desc"])}</td>'
                   f'<td class="small" style="word-break:break-all">{e(p["url"])}</td></tr>' for qi, p in photos)
    out.append(f"""
<p class="sec-title" style="margin-top:5mm">写真素材一覧（第七問）</p>
<p class="small">出典：フリー素材「ぱくたそ」（https://www.pakutaso.com/）。無料・クレジット表記不要で商用利用可。ただし素材をそのまま商品として販売すること、他サイトでの再配布、画像への直接リンクは禁止。利用前に最新の利用規約を確認すること。</p>
<table><tr><th style="width:16mm">番号</th><th style="width:20mm">保存名</th><th style="width:55mm">内容</th><th>素材ページ</th></tr>{prow}</table>""")
    return doc(f"{TITLE} 解答と解説", "".join(out))


def main():
    files = {"01_問題冊子": booklet(), "02_解答用紙": answer_sheet(), "03_解答と解説": answer_key()}
    for name, content in files.items():
        (ROOT / f"{name}.html").write_text(content, encoding="utf-8")
    subprocess.run(["node", str(ROOT / "render_pdf.js")], check=False,
                   env={**os.environ, "NODE_PATH": subprocess.run(["npm", "root", "-g"], capture_output=True, text=True).stdout.strip()})


if __name__ == "__main__":
    main()
