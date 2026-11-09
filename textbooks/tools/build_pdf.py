#!/usr/bin/env python3
"""テキスト（Markdown）を A4 の PDF に変換する。

使い方:
    python3 textbooks/tools/build_pdf.py                 # textbooks/ 以下の全テキストを変換
    python3 textbooks/tools/build_pdf.py <ファイル.md> …  # 指定したファイルだけ変換

出力先: textbooks/pdf/<教科フォルダ>/<ファイル名>.pdf
  - 算数・数学（sansu-sugaku）は高校数学の教科書風のデザインで、
    カラー版 <名前>.pdf とモノクロ版 <名前>_モノクロ.pdf の2つを出す。
  - 英語・理科・社会・国語は塾テキスト風（tools/juku.css）のモノクロ版だけを出す。

準備（初回のみ）:
    pip install markdown
    cd textbooks/tools && npm install      # フォントと KaTeX（Playwright はグローバルのものも使える）
"""
import html
import json
import pathlib
import re
import subprocess
import sys
import tempfile

import markdown

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
NODE_MODULES = TOOLS / "node_modules"
SUBJECT_DIRS = ["sansu-sugaku", "kokugo", "eigo", "rika", "shakai"]

# 絵文字（👨‍🏫 のような合成絵文字を含む）を <span class="emoji"> で包む
EMOJI = re.compile(
    r"(?:[\U0001F300-\U0001FAFF☀-➿⭐✅]️?)"
    r"(?:‍[\U0001F300-\U0001FAFF☀-➿]️?)*"
)


def font_links() -> str:
    """ローカルにある Noto フォントと KaTeX を読みこむタグ。"""
    css = [
        "@fontsource/noto-serif-jp/400.css",
        "@fontsource/noto-serif-jp/700.css",
        "@fontsource/noto-sans-jp/400.css",
        "@fontsource/noto-sans-jp/700.css",
        "katex/dist/katex.min.css",
    ]
    tags = [f'<link rel="stylesheet" href="{(NODE_MODULES / c).as_uri()}">' for c in css if (NODE_MODULES / c).exists()]
    katex = NODE_MODULES / "katex/dist"
    if (katex / "katex.min.js").exists():
        tags.append(f'<script src="{(katex / "katex.min.js").as_uri()}"></script>')
        tags.append(f'<script src="{(katex / "contrib/auto-render.min.js").as_uri()}"></script>')
        tags.append(
            "<script>document.addEventListener('DOMContentLoaded',()=>{if(window.renderMathInElement)"
            "renderMathInElement(document.body,{delimiters:[{left:'$$',right:'$$',display:true},"
            "{left:'$',right:'$',display:false}],throwOnError:false});});</script>"
        )
    return "\n".join(tags)


def md_fragment(md_text: str) -> str:
    """Markdown を HTML の断片に変換する（数式の保護・絵文字の包み・解答見出しの印つけ）。"""
    # 数式 $...$ を markdown が崩さないように一時的に退避する
    maths = []

    def keep(m):
        maths.append(m.group(0))
        return f"\x00M{len(maths) - 1}\x00"

    md_text = re.sub(r"\$\$.+?\$\$|\$[^$\n]+?\$", keep, md_text, flags=re.S)
    body = markdown.markdown(md_text, extensions=["tables", "fenced_code", "md_in_html", "sane_lists", "nl2br"])
    body = re.sub(r"\x00M(\d+)\x00", lambda m: html.escape(maths[int(m.group(1))], quote=False), body)
    body = EMOJI.sub(lambda m: f'<span class="emoji">{m.group(0)}</span>', body)
    # 「解答」を含む大見出しから改ページして、切り離せるようにする
    return re.sub(r"<h2>(?=[^<]*(?:<span class=\"emoji\">[^<]*</span>)?[^<]*解答)", '<h2 class="answers">', body)


def to_html(md_text: str, title: str, css: str, body_class: str, extra: str) -> str:
    body = md_fragment(md_text)
    return (
        f'<!doctype html><html lang="ja"><head><meta charset="utf-8">'
        f"<title>{html.escape(title)}</title>{font_links()}<style>{css}</style></head>"
        f'<body class="{body_class}">{extra}{body}</body></html>'
    )


def jobs_for(f: pathlib.Path, tmp: pathlib.Path):
    rel = f.relative_to(ROOT)
    out_dir = ROOT / "pdf" / rel.parent
    out_dir.mkdir(parents=True, exist_ok=True)
    md_text = f.read_text(encoding="utf-8")
    base_css = (TOOLS / "print.css").read_text(encoding="utf-8")

    if rel.parts[0] == "sansu-sugaku":
        css = base_css + (TOOLS / "math.css").read_text(encoding="utf-8")
        # ファイル名「小5_割合」→ ツメ「小5 算数」、柱「小5｜割合」
        grade, _, unit = f.stem.partition("_")
        subject = "算数" if grade.startswith("小") else "数学"
        tsume = f'<div class="tsume">{html.escape(grade)} {subject}</div>'
        header = f"{grade}｜{unit}"
        variants = [("", f.stem + ".pdf"), ("mono", f.stem + "_モノクロ.pdf")]
        style = "math"
    else:
        # 英語・理科・社会・国語：塾テキスト風（モノクロ・ゴシック）
        css = base_css + (TOOLS / "juku.css").read_text(encoding="utf-8")
        tsume, header = "", f.stem
        variants = [("", f.stem + ".pdf")]
        style = "plain"

    for body_class, name in variants:
        page = tmp / f"{f.stem}{'_' + body_class if body_class else ''}.html"
        page.write_text(to_html(md_text, f.stem, css, body_class, tsume), encoding="utf-8")
        yield {"html": str(page), "pdf": str(out_dir / name), "title": html.escape(header), "style": style}


def main():
    if len(sys.argv) > 1:
        files = [pathlib.Path(a).resolve() for a in sys.argv[1:]]
    else:
        files = sorted(f for d in SUBJECT_DIRS for f in (ROOT / d).rglob("*.md"))

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = pathlib.Path(tmpdir)
        jobs = [j for f in files for j in jobs_for(f, tmp)]
        job_file = tmp / "jobs.json"
        job_file.write_text(json.dumps(jobs, ensure_ascii=False), encoding="utf-8")
        subprocess.run(["node", str(TOOLS / "print_pdf.js"), str(job_file)], check=True)


if __name__ == "__main__":
    main()
