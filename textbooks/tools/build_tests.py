#!/usr/bin/env python3
"""定期テスト（textbooks/tests/<テスト名>/<教科>.md）を PDF にする。

使い方: python3 textbooks/tools/build_tests.py [テスト名 …]
出力:   textbooks/books/テスト/<テスト名>_<教科>.pdf
各ファイルの「解答」を含む ## 見出しから後ろは、新しいページから始まる（先生用の解答・解説）。"""
import json
import re
import pathlib
import subprocess
import sys
import tempfile

from build_pdf import md_fragment, font_links
from build_book import use_system_fonts, compress
import booklet

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
OUT = ROOT / "books" / "テスト"


def genko(m):
    """<div class="genko" data-cols="20" data-rows="4"></div> を原稿用紙のマス目（20字ごとに字数の目印）にする。"""
    cols, rows = int(m.group(1)), int(m.group(2))
    trs = "".join("<tr>" + "<td></td>" * cols + f'<td class="mk">{(r + 1) * cols}</td></tr>' for r in range(rows))
    return f'<table class="genko">{trs}</table>'


# 教科 → body のクラス（test.css で用紙・書体・形式を切りかえる）
KIND = {"国語": "kokugo", "算数": "sansu", "理科": "rika", "社会": "shakai", "英語": "eigo"}


def label(test: str, stem: str) -> str:
    """ページ下の柱：「小5 2学期期末テスト　算数」"""
    return f"{stem.split('_', 1)[-1]}　{test.split('_', 1)[-1]}試験"


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    want = sys.argv[1:]
    css = "".join((TOOLS / n).read_text(encoding="utf-8") for n in ("print.css", "test.css"))
    hand = TOOLS / "node_modules/@fontsource/patrick-hand/400.css"
    links = font_links() + (f'<link rel="stylesheet" href="{hand.as_uri()}">' if hand.exists() else "")
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = pathlib.Path(tmpdir)
        jobs, outs = [], []
        for d in sorted(p for p in (ROOT / "tests").iterdir() if p.is_dir()):
            if want and d.name not in want:
                continue
            for f in sorted(d.glob("*.md")):
                subject = f.stem.split("_", 1)[-1]
                kind = KIND.get(subject, "")
                body = md_fragment(f.read_text(encoding="utf-8"))
                # ★ や ○ などの記号は残す（本では絵文字を消すが、テストでは記号として使う）
                body = re.sub(r'<span class="emoji">([^<]*)</span>', r"\1", body)
                body = re.sub(r'<div class="genko" data-cols="(\d+)" data-rows="(\d+)"></div>', genko, body)
                # 冊子づくり（booklet.py）のための見えない印：解答用紙・解答解説のはじまり
                body = re.sub(r'(<div class="(?:sheet|k-sheet)"[^>]*>)', r'\1<span class="pmk">@@SHEET@@</span>', body)
                body = body.replace('<h2 class="answers">', '<h2 class="answers"><span class="pmk">@@ANS@@</span>', 1)
                # 国語は「表紙・問題・解答用紙」を縦書きの文書（ページいっぱいに右から左へ流れる）、
                # 「解答・解説」を横書きの文書として別々に印刷し、あとでつなぐ
                parts = [(body, kind)]
                if kind == "kokugo" and '<h2 class="answers">' in body:
                    i = body.index('<h2 class="answers">')
                    parts = [(body[:i], "kokugo tate-doc"), (body[i:], "kokugo")]
                raws = []
                for n, (part, cls) in enumerate(parts):
                    root = ' class="tate-root"' if "tate-doc" in cls else ""
                    page = (f'<!doctype html><html lang="ja"{root}><head><meta charset="utf-8"><title>{d.name} {f.stem}</title>'
                            f"{links}<style>{use_system_fonts(css)}</style></head><body class=\"{cls}\">{use_system_fonts(part)}</body></html>")
                    h = tmp / f"{d.name}_{f.stem}_{n}.html"
                    h.write_text(page, encoding="utf-8")
                    raw = tmp / f"{d.name}_{f.stem}_{n}.pdf"
                    jobs.append({"html": str(h), "pdf": str(raw), "title": label(d.name, f.stem), "style": "test", "kind": kind})
                    raws.append(raw)
                outs.append((raws, OUT / f"{d.name}_{f.stem}.pdf"))
        job_file = tmp / "jobs.json"
        job_file.write_text(json.dumps(jobs, ensure_ascii=False), encoding="utf-8")
        subprocess.run(["node", str(TOOLS / "print_pdf.js"), str(job_file)], check=True)
        for raws, out in outs:
            raw = raws[0]
            if len(raws) > 1:
                raw = raws[0].with_suffix(".all.pdf")
                subprocess.run(["pdfunite", *map(str, raws), str(raw)], check=True)
            compress(str(raw), str(out))
            print("テスト:", out.relative_to(ROOT))
            for m in booklet.make(str(out), OUT / "冊子", out.stem):
                print("　冊子:", m.relative_to(ROOT))


if __name__ == "__main__":
    main()
