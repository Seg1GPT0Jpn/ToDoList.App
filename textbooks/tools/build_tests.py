#!/usr/bin/env python3
"""定期テスト（textbooks/tests/<テスト名>/<教科>.md）を PDF にする。

使い方: python3 textbooks/tools/build_tests.py [テスト名 …]
出力:   textbooks/books/テスト/<テスト名>_<教科>.pdf
各ファイルの「解答」を含む ## 見出しから後ろは、新しいページから始まる（先生用の解答・解説）。"""
import json
import pathlib
import subprocess
import sys
import tempfile

from build_pdf import md_fragment, font_links
from build_book import use_system_fonts, compress

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
OUT = ROOT / "books" / "テスト"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    want = sys.argv[1:]
    css = "".join((TOOLS / n).read_text(encoding="utf-8") for n in ("print.css", "juku.css", "test.css"))
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = pathlib.Path(tmpdir)
        jobs, outs = [], []
        for d in sorted(p for p in (ROOT / "tests").iterdir() if p.is_dir()):
            if want and d.name not in want:
                continue
            for f in sorted(d.glob("*.md")):
                body = md_fragment(f.read_text(encoding="utf-8"))
                page = (f'<!doctype html><html lang="ja"><head><meta charset="utf-8"><title>{d.name} {f.stem}</title>'
                        f"{font_links()}<style>{use_system_fonts(css)}</style></head><body>{use_system_fonts(body)}</body></html>")
                h = tmp / f"{d.name}_{f.stem}.html"
                h.write_text(page, encoding="utf-8")
                raw = tmp / f"{d.name}_{f.stem}.pdf"
                jobs.append({"html": str(h), "pdf": str(raw), "title": f"{d.name} {f.stem}", "style": "book"})
                outs.append((raw, OUT / f"{d.name}_{f.stem}.pdf"))
        job_file = tmp / "jobs.json"
        job_file.write_text(json.dumps(jobs, ensure_ascii=False), encoding="utf-8")
        subprocess.run(["node", str(TOOLS / "print_pdf.js"), str(job_file)], check=True)
        for raw, out in outs:
            compress(str(raw), str(out))
            print("テスト:", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
