#!/usr/bin/env python3
"""単元ファイルの形式を機械的に検査する。

使い方: python3 textbooks/tools/check_units.py [教科キー …]
検査すること：
  - 1行目がマニフェストのタイトルと同じか
  - 解答の見出し（「解答」を含む ##）があるか
  - <div> の開きと閉じの数が合っているか、markdown="1" がついているか
  - 英・理・社・国で $ が使われていないか（数式あつかいになるため）
  - 本文と解答の大問番号（<span class="no">N</span>）がそろっているか
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from book_manifest import BOOK, iter_units  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent


def check(subject, u):
    f = ROOT / subject["key"] / u["file"]
    if not f.exists():
        return None
    t = f.read_text(encoding="utf-8")
    probs = []
    first = t.split("\n", 1)[0]
    if first.strip() != f"# {u['title']}":
        probs.append(f"1行目が違う: {first[:40]}")
    m = re.search(r"^## .*解答.*$", t, re.M)
    if not m:
        probs.append("解答の見出しがない")
    opens, closes = len(re.findall(r"<div\b", t)), len(re.findall(r"</div>", t))
    if opens != closes:
        probs.append(f"div の数が合わない（開き{opens}・閉じ{closes}）")
    for d in re.findall(r"<div class=\"(?:point|ex|memo|cols2|kaito|koushiki|rei|renshu|mokuhyo|history|box)\"[^>]*>", t):
        if 'markdown="1"' not in d:
            probs.append(f"markdown=\"1\" なし: {d[:40]}")
    if subject["theme"] != "math" and "$" in t:
        probs.append("$ が使われている")
    if m and subject["theme"] != "math":
        body, ans = t[: m.start()], t[m.end():]
        qb = re.findall(r'^#### <span class="no">(\d+)</span>', body, re.M)
        qa = re.findall(r'^#### <span class="no">(\d+)</span>', ans, re.M)
        if qb != qa:
            probs.append(f"大問番号が本文{len(qb)}・解答{len(qa)}でずれている")
    return probs


def main():
    want = sys.argv[1:]
    total = bad = 0
    for s in BOOK:
        if want and s["key"] not in want and s["name"] not in want:
            continue
        for _, u in iter_units(s):
            r = check(s, u)
            if r is None:
                continue
            total += 1
            if r:
                bad += 1
                print(f"✗ {s['key']}/{u['file']}: " + " ／ ".join(r))
    print(f"検査 {total} 本、問題あり {bad} 本")


if __name__ == "__main__":
    main()
