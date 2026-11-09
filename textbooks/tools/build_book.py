#!/usr/bin/env python3
"""教科ごとに1冊の本（PDF）を組み立てる。

使い方:
    python3 textbooks/tools/build_book.py              # 5教科すべて
    python3 textbooks/tools/build_book.py 英語 理科     # 指定した教科だけ

出力: textbooks/books/
    英語.pdf / 理科.pdf / 社会.pdf / 国語.pdf  … 表紙・目次・本文・巻末解答
    算数数学.pdf（カラー）・算数数学_モノクロ.pdf … 表紙・目次・本文
    算数数学_解答解説_別冊.pdf                   … 算数・数学の解答・解説

本の作り:
    - 単元の並びは tools/book_manifest.py。まだ書かれていない単元は目次に「準備中」と出る。
    - 分野・学年が変わるところに1ページのタイトルページを入れる。単元ごとの改ページはしない。
    - 各単元ファイルの「解答」を含む最初の ## 見出しから後ろを解答として、巻末（算数・数学は別冊）へ移す。
    - ページ番号は、できあがった PDF に通し番号で入れる。目次のページ番号は、一度組んだ PDF から調べて入れる。
"""
import html
import io
import json
import pathlib
import re
import subprocess
import sys
import tempfile

from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from book_manifest import BOOK, iter_units  # noqa: E402
from build_pdf import font_links, md_fragment  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
OUT = ROOT / "books"
ANSWER_HEAD = re.compile(r"^## .*解答.*$", re.M)
LEVEL_NAMES = {"eigo": "小5〜中3", "sansu-sugaku": "小5〜中3", "rika": "中1〜中3", "shakai": "中1〜中3", "kokugo": "小5〜中3"}


def css_for(theme: str) -> str:
    css = (TOOLS / "print.css").read_text(encoding="utf-8")
    css += (TOOLS / ("math.css" if theme == "math" else "juku.css")).read_text(encoding="utf-8")
    return css + (TOOLS / "book.css").read_text(encoding="utf-8")


def head_links(theme: str) -> str:
    # 本では、文字の範囲ごとに分かれた Web フォント（fontsource）を使わず、システムの Noto CJK を使う。
    # （分かれたフォントだと PDF に何百個も埋めこまれて、ファイルが非常に大きくなるため）
    links = "\n".join(line for line in font_links().splitlines() if "fontsource" not in line)
    if theme != "math":  # 数式（KaTeX）は算数・数学だけ
        links = "\n".join(line for line in links.splitlines() if "katex" not in line.lower() and "renderMath" not in line)
    return links


def use_system_fonts(text: str) -> str:
    # 本では絵文字を外す（カラー絵文字は1文字ずつ画像フォントとして埋めこまれ、PDF が非常に大きくなるため）
    text = re.sub(r'<span class="emoji">[^<]*</span>\s*', "", text)
    # 日本語フォントは TrueType の IPAex（Noto CJK は OpenType/CFF のため、Chromium が1文字ずつ図形として
    # 埋めこみ、PDF がとても大きくなる）。IPAex がなければ Noto CJK を使う。
    text = text.replace('"Noto Sans JP"', '"IPAexGothic", "Noto Sans CJK JP"').replace("Noto Sans JP,", "IPAexGothic, Noto Sans CJK JP,")
    return text.replace('"Noto Serif JP"', '"IPAexMincho", "Noto Serif CJK JP"').replace("Noto Serif JP,", "IPAexMincho, Noto Serif CJK JP,")


def page(theme: str, body_class: str, inner: str, title: str) -> str:
    inner = use_system_fonts(inner)
    return (
        f'<!doctype html><html lang="ja"><head><meta charset="utf-8"><title>{html.escape(title)}</title>'
        f"{head_links(theme)}<style>{use_system_fonts(css_for(theme))}</style></head>"
        f'<body class="{body_class}">{inner}</body></html>'
    )


def split_unit(text: str):
    m = ANSWER_HEAD.search(text)
    if not m:
        return text, ""
    return text[: m.start()], text[m.end():]


def set_title(body: str, title: str, marker: str) -> str:
    lines = body.split("\n")
    for i, line in enumerate(lines):
        if line.startswith("# "):
            lines[i] = f'# {title} <span class="mk">{marker}</span>'
            return "\n".join(lines)
    return f'# {title} <span class="mk">{marker}</span>\n\n' + body


def collect(subject):
    """単元を読み、本文・解答・目次用の情報を集める。"""
    units = []
    for i, (trail, u) in enumerate(iter_units(subject), 1):
        f = ROOT / subject["key"] / u["file"]
        item = {"trail": trail, "title": u["title"], "marker": f"@@U{i:03d}@@", "exists": f.exists()}
        if f.exists():
            body, ans = split_unit(f.read_text(encoding="utf-8"))
            item["body"] = set_title(body, u["title"], item["marker"])
            item["answers"] = ans.strip()
        units.append(item)
    return units


def short(title: str) -> str:
    """目次やタイトルページ用に、タイトルから「中1英語 」などの頭を落とす。"""
    t = title.replace("📚 ", "")
    return re.sub(r"^(小|中)\d(英語|理科|地理|歴史|公民|国語)\s*", "", t)


def titlepage(subject, trail, units):
    """trail（例：['物理','中学1年']）の分野・学年タイトルページ。"""
    depth = len(trail)
    inside = [u for u in units if u["trail"][:depth] == trail]
    rows = []
    if any(len(u["trail"]) > depth for u in inside):
        for sub in dict.fromkeys(u["trail"][depth] for u in inside):
            rows.append(f'<div class="tp-sub">{html.escape(sub)}</div><ol>')
            rows += [f"<li>{html.escape(short(u['title']))}</li>" for u in inside if u["trail"][depth] == sub]
            rows.append("</ol>")
    else:
        rows.append("<ol>" + "".join(f"<li>{html.escape(short(u['title']))}</li>" for u in inside) + "</ol>")
    trail_txt = "　›　".join(trail[:-1])
    return (
        f'<section class="titlepage"><div class="tp-subject">{html.escape(subject["name"])}</div>'
        + (f'<div class="tp-trail">{html.escape(trail_txt)}</div>' if trail_txt else "")
        + f'<div class="tp-title">{html.escape(trail[-1])}</div>{"".join(rows)}</section>'
    )


def body_html(subject, units):
    """本文：タイトルページ＋単元。"""
    out, prev = [], []
    for u in units:
        # trail が変わったところ（親から順に）にタイトルページ
        for d in range(len(u["trail"])):
            if prev[: d + 1] != u["trail"][: d + 1]:
                out.append(titlepage(subject, u["trail"][: d + 1], units))
        prev = u["trail"]
        if u["exists"]:
            out.append(f'<div class="unit">{md_fragment(u["body"])}</div>')
    return "\n".join(out)


def answers_html(subject, units, separate: bool):
    out = []
    if separate:
        out.append(
            f'<section class="cover"><div class="c-series">神奈川県公立高校入試対策　五教科テキスト</div>'
            f'<div class="c-title">{html.escape(subject["name"])}<br>解答・解説</div>'
            f'<div class="c-sub">別冊（{LEVEL_NAMES[subject["key"]]}）</div></section>'
        )
    else:
        out.append(
            f'<section class="titlepage"><div class="tp-subject">{html.escape(subject["name"])}</div>'
            f'<div class="tp-title">解答・解説</div><ol><li>本文の全単元の解答と解説を、単元の順にまとめています。</li>'
            f"<li>まちがえた問題は、解説の「なぜそうなるか」を読んでから、もう一度解き直しましょう。</li></ol></section>"
        )
    prev = None
    for u in units:
        if not u.get("answers"):
            continue
        part = "　›　".join(u["trail"])
        if part != prev:
            out.append(f'<div class="ans-part">{html.escape(part)}</div>')
            prev = part
        out.append(f'<div class="ans-unit">{html.escape(u["title"].replace("📚 ", ""))}</div>')
        out.append(f'<div class="ans">{md_fragment(u["answers"])}</div>')
    return "\n".join(out)


def front_html(subject, units, pages):
    """表紙と目次。pages は marker → ページ番号。"""
    n_done = sum(u["exists"] for u in units)
    cover = (
        f'<section class="cover"><div class="c-series">神奈川県公立高校入試対策　五教科テキスト</div>'
        f'<div class="c-title">{html.escape(subject["name"])}</div>'
        f'<div class="c-sub">{LEVEL_NAMES[subject["key"]]}　全{len(units)}単元</div>'
        f'<div class="c-note">'
        + ("本冊：各単元の解説・例題・演習　／　解答・解説は別冊" if subject["answers"] == "separate"
           else "各単元の要点と演習　／　巻末に全単元の解答・解説")
        + (f"<br>（現在 {n_done}／{len(units)} 単元を収録）" if n_done < len(units) else "")
        + "</div></section>"
    )
    toc = ['<section class="toc"><h2>目次</h2>']
    prev = []
    for u in units:
        for d in range(len(u["trail"])):
            if prev[: d + 1] != u["trail"][: d + 1]:
                toc.append(f'<div class="t-part l{d + 1}">{html.escape(u["trail"][d])}</div>')
        if prev != u["trail"]:
            toc.append("<ul>")
        prev = u["trail"]
        pg = pages.get(u["marker"])
        cls = "" if u["exists"] else ' class="missing"'
        num = str(pg) if pg else ("準備中" if not u["exists"] else "")
        toc.append(
            f'<li{cls}><span class="t-name">{html.escape(u["title"].replace("📚 ", ""))}</span>'
            f'<span class="t-dots"></span><span class="t-page">{num}</span></li>'
        )
    if subject["answers"] == "back" and "@@ANS@@" in pages:
        toc.append(f'<div class="t-part l1">解答・解説</div><ul><li><span class="t-name">全単元の解答・解説</span>'
                   f'<span class="t-dots"></span><span class="t-page">{pages["@@ANS@@"]}</span></li></ul>')
    toc.append("</section>")
    return cover + "".join(toc)


def render(jobs):
    """jobs: [{"html": str, "pdf": str}] を Chromium で PDF にする（ページ番号なし）。"""
    with tempfile.TemporaryDirectory() as tmp:
        t = pathlib.Path(tmp)
        spec = []
        for i, j in enumerate(jobs):
            h = t / f"p{i}.html"
            h.write_text(j["html"], encoding="utf-8")
            spec.append({"html": str(h), "pdf": j["pdf"], "title": "", "style": "book"})
        jf = t / "jobs.json"
        jf.write_text(json.dumps(spec, ensure_ascii=False), encoding="utf-8")
        subprocess.run(["node", str(TOOLS / "print_pdf.js"), str(jf)], check=True)


def page_texts(pdf: str):
    txt = subprocess.run(["pdftotext", "-layout", pdf, "-"], capture_output=True, text=True, check=True).stdout
    return txt.split("\f")


def find_markers(pdf: str, markers):
    found = {}
    for i, t in enumerate(page_texts(pdf), 1):
        for mk in markers:
            if mk not in found and mk in t:
                found[mk] = i
    return found


def stamp(pdf_in: str, pdf_out: str, skip_first: int = 1, start: int = 1):
    """通しのページ番号を下中央に入れる（最初の skip_first ページ＝表紙には入れない）。"""
    reader = PdfReader(pdf_in)
    writer = PdfWriter()
    for i, pg in enumerate(reader.pages):
        if i >= skip_first:
            w, h = float(pg.mediabox.width), float(pg.mediabox.height)
            buf = io.BytesIO()
            c = canvas.Canvas(buf, pagesize=(w, h))
            c.setFont("Helvetica", 8.5)
            c.drawCentredString(w / 2, 18, f"- {start + i} -")
            c.save()
            buf.seek(0)
            pg.merge_page(PdfReader(buf).pages[0])
        writer.add_page(pg)
    raw = pdf_out + ".raw.pdf"
    with open(raw, "wb") as fh:
        writer.write(fh)
    compress(raw, pdf_out)


def compress(src: str, dst: str):
    """ghostscript があれば、フォントをまとめ直して PDF を小さくする（なければそのまま）。"""
    import os
    import shutil
    if shutil.which("gs"):
        r = subprocess.run(["gs", "-q", "-dNOPAUSE", "-dBATCH", "-dSAFER", "-sDEVICE=pdfwrite",
                            "-dCompatibilityLevel=1.6", "-dPDFSETTINGS=/printer", f"-sOutputFile={dst}", src])
        if r.returncode == 0:
            os.remove(src)
            return
    os.replace(src, dst)


def merge(parts, out):
    subprocess.run(["pdfunite", *parts, out], check=True)


def build_subject(subject):
    theme = subject["theme"]
    units = collect(subject)
    name = subject["name"].replace("・", "")
    OUT.mkdir(exist_ok=True)
    separate = subject["answers"] == "separate"
    variants = [("math", name), ("math mono", f"{name}_モノクロ")] if theme == "math" else [("", name)]

    with tempfile.TemporaryDirectory() as tmp:
        t = pathlib.Path(tmp)
        main_html = body_html(subject, units)
        ans = answers_html(subject, units, separate)
        if not separate:
            main_html += '\n<div class="mk">@@ANS@@</div>\n' + ans

        for body_class, outname in variants:
            content_pdf = str(t / f"{outname}_content.pdf")
            render([{"html": page(theme, body_class, main_html, subject["name"]), "pdf": content_pdf}])
            markers = [u["marker"] for u in units if u["exists"]] + ["@@ANS@@"]
            # 1回目の目次（ページ数を知るため）
            front_pdf = str(t / f"{outname}_front.pdf")
            render([{"html": page(theme, body_class, front_html(subject, units, {}), subject["name"]), "pdf": front_pdf}])
            n_front = len(PdfReader(front_pdf).pages)
            rel = find_markers(content_pdf, markers)
            pages = {k: v + n_front for k, v in rel.items()}
            render([{"html": page(theme, body_class, front_html(subject, units, pages), subject["name"]), "pdf": front_pdf}])
            if len(PdfReader(front_pdf).pages) != n_front:  # 目次の長さが変わったら、もう一度
                n_front = len(PdfReader(front_pdf).pages)
                pages = {k: v + n_front for k, v in rel.items()}
                render([{"html": page(theme, body_class, front_html(subject, units, pages), subject["name"]), "pdf": front_pdf}])
            merged = str(t / f"{outname}_merged.pdf")
            merge([front_pdf, content_pdf], merged)
            stamp(merged, str(OUT / f"{outname}.pdf"))
            print(f"本: books/{outname}.pdf（{len(PdfReader(str(OUT / f'{outname}.pdf')).pages)}ページ）")

        if separate:
            ans_pdf = str(t / "answers.pdf")
            render([{"html": page(theme, "math", ans, subject["name"] + " 解答"), "pdf": ans_pdf}])
            out = OUT / f"{name}_解答解説_別冊.pdf"
            stamp(ans_pdf, str(out))
            print(f"別冊: books/{out.name}（{len(PdfReader(str(out)).pages)}ページ）")

    done = sum(u["exists"] for u in units)
    print(f"{subject['name']}: {done}/{len(units)} 単元を収録")


def main():
    want = sys.argv[1:]
    for s in BOOK:
        if not want or s["name"] in want or s["name"].replace("・", "") in want or s["key"] in want:
            build_subject(s)


if __name__ == "__main__":
    main()
