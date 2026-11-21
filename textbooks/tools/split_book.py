"""本の PDF を、チャットなどに送りやすい大きさ（1ファイル100ページ以下）に分ける。
使い方: python3 tools/split_book.py 英語.pdf 1-85:中1 86-148:中2前半 ...
出力は books/分割/<本の名前>_<n>_<ラベル>.pdf"""
import pathlib
import sys

from pypdf import PdfReader, PdfWriter

books = pathlib.Path(__file__).resolve().parent.parent / "books"
src = books / sys.argv[1]
out_dir = books / "分割"
out_dir.mkdir(exist_ok=True)
reader = PdfReader(src)
for n, spec in enumerate(sys.argv[2:], 1):
    rng, label = spec.split(":")
    a, b = (int(x) for x in rng.split("-"))
    w = PdfWriter()
    for i in range(a - 1, b):
        w.add_page(reader.pages[i])
    w.compress_identical_objects()
    out = out_dir / f"{src.stem}_{n}_{label}.pdf"
    with open(out, "wb") as fh:
        w.write(fh)
    print(out.name, b - a + 1, "ページ")
