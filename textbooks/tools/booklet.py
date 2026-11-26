#!/usr/bin/env python3
"""定期テストの PDF から、印刷用の「冊子」セットを作る（build_tests.py から呼ばれる）。

1つのテスト PDF を3つに分ける（ページの中の見えない印 @@SHEET@@・@@ANS@@ で切れ目を見つける）：
  <名前>_1_問題冊子.pdf   … 表紙と問題を、両面印刷して二つ折りにすると冊子になる順に 2 ページずつ並べたもの（中とじ）
  <名前>_2_解答用紙.pdf   … 解答用紙（冊子にせず、1枚ずつ配って回収する）
  <名前>_3_解答解説.pdf   … 先生用の解答・解説

冊子の用紙と印刷のしかた：
  A4 縦のページ → A3 横に2ページ（左とじ）　　両面印刷「短辺とじ」で印刷して、まん中で二つ折り
  B5 縦のページ → B4 横に2ページ（左とじ）　　同上
  A3 縦のページ → A3 横に A4 の大きさに縮小して2ページ（左とじ）
  A4 横のページ（国語の縦書き）→ A3 縦に上下2ページ（上とじ）　　両面印刷「短辺とじ」、まん中で二つ折り
ページ数が4の倍数でないときは、最後に白紙を足す。問題が2ページ以下なら冊子にせず、そのまま出す。
"""
import subprocess
import sys

from pypdf import PageObject, PdfReader, PdfWriter, Transformation

MM = 72 / 25.4


def page_kinds(pdf: str):
    """各ページが 問題(Q)・解答用紙(S)・解答解説(A) のどれかを返す。"""
    n = len(PdfReader(pdf).pages)
    kinds, mode = [], "Q"
    for i in range(1, n + 1):
        t = subprocess.run(["pdftotext", "-f", str(i), "-l", str(i), pdf, "-"], capture_output=True, text=True).stdout
        if "@@ANS@@" in t:
            mode = "A"
        elif "@@SHEET@@" in t and mode != "A":
            mode = "S"
        kinds.append(mode)
    return kinds


def impose(pages, out: str):
    """中とじの順に2ページずつ並べる。"""
    w, h = float(pages[0].mediabox.width), float(pages[0].mediabox.height)
    landscape = w > h
    n = len(pages)
    while n % 4:
        n += 1
    blank = None

    def get(i):
        nonlocal blank
        if i < len(pages):
            return pages[i]
        if blank is None:
            blank = PageObject.create_blank_page(width=w, height=h)
        return blank

    if landscape:
        # 横長のページ（国語）：A3 縦に上下2ページ。上とじ（上の半分が「左とじ」の左にあたる）
        sw, sh = w, h * 2
        scale = 1.0
        cw, ch = w, h
    elif abs(w - 297 * MM) < 5 and abs(h - 420 * MM) < 5:
        # A3 縦（算数）：A4 の大きさに縮めて A3 横に2ページ
        sw, sh = 420 * MM, 297 * MM
        scale = (297 * MM) / h
        cw, ch = w * scale, h * scale
    else:
        sw, sh = w * 2, h
        scale = 1.0
        cw, ch = w, h

    writer = PdfWriter()
    for s in range(n // 4):
        sides = [(n - 1 - 2 * s, 2 * s), (2 * s + 1, n - 2 - 2 * s)]  # (左または上, 右または下)
        for first, second in sides:
            sheet = PageObject.create_blank_page(width=sw, height=sh)
            for slot, idx in ((0, first), (1, second)):
                if landscape:
                    tx, ty = 0, (sh / 2 if slot == 0 else 0)
                else:
                    tx = (sw / 2) * slot + (sw / 2 - cw) / 2
                    ty = (sh - ch) / 2
                sheet.merge_transformed_page(get(idx), Transformation().scale(scale).translate(tx, ty))
            writer.add_page(sheet)
    with open(out, "wb") as fh:
        writer.write(fh)


def save(pages, out: str):
    writer = PdfWriter()
    for p in pages:
        writer.add_page(p)
    with open(out, "wb") as fh:
        writer.write(fh)


def make(pdf: str, out_dir, name: str):
    out_dir.mkdir(parents=True, exist_ok=True)
    kinds = page_kinds(pdf)
    pages = PdfReader(pdf).pages
    q = [p for p, k in zip(pages, kinds) if k == "Q"]
    s = [p for p, k in zip(pages, kinds) if k == "S"]
    a = [p for p, k in zip(pages, kinds) if k == "A"]
    made = []
    if q:
        out = out_dir / f"{name}_1_問題冊子.pdf"
        (impose if len(q) > 2 else save)(q, str(out))
        made.append(out)
    if s:
        out = out_dir / f"{name}_2_解答用紙.pdf"
        save(s, str(out))
        made.append(out)
    if a:
        out = out_dir / f"{name}_3_解答解説.pdf"
        save(a, str(out))
        made.append(out)
    return made


if __name__ == "__main__":
    import pathlib
    for f in sys.argv[1:]:
        p = pathlib.Path(f)
        for m in make(str(p), p.parent / "冊子", p.stem):
            print("冊子:", m)
