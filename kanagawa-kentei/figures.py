"""問題用の図（SVG）を作る部品。"""
import html
import json
import pathlib

_MAP = json.loads((pathlib.Path(__file__).parent / "data" / "kanagawa_map.json").read_text())

NAMES = {
    "14100": "横浜市", "14130": "川崎市", "14150": "相模原市", "14201": "横須賀市", "14203": "平塚市",
    "14204": "鎌倉市", "14205": "藤沢市", "14206": "小田原市", "14207": "茅ヶ崎市", "14208": "逗子市",
    "14210": "三浦市", "14211": "秦野市", "14212": "厚木市", "14213": "大和市", "14214": "伊勢原市",
    "14215": "海老名市", "14216": "座間市", "14217": "南足柄市", "14218": "綾瀬市", "14301": "葉山町",
    "14321": "寒川町", "14341": "大磯町", "14342": "二宮町", "14361": "中井町", "14362": "大井町",
    "14363": "松田町", "14364": "山北町", "14366": "開成町", "14382": "箱根町", "14383": "真鶴町",
    "14384": "湯河原町", "14401": "愛川町", "14402": "清川村",
}
CODE = {v: k for k, v in NAMES.items()}

INK = "#1b2b44"
SEA = "#e6eff6"

PATTERNS = """
<defs>
 <pattern id="hatch" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
  <rect width="7" height="7" fill="#fff"/><line x1="0" y1="0" x2="0" y2="7" stroke="#1b2b44" stroke-width="2.2"/></pattern>
 <pattern id="dots" width="8" height="8" patternUnits="userSpaceOnUse">
  <rect width="8" height="8" fill="#fff"/><circle cx="4" cy="4" r="1.6" fill="#1b2b44"/></pattern>
 <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
  <path d="M0,0L10,5L0,10z" fill="#1b2b44"/></marker>
</defs>"""


def e(t):
    return html.escape(str(t))


def kanagawa(fill=None, labels=None, markers=None, legend=None, width="100%", sea_labels=True, names=False):
    """神奈川県の市町村地図。
    fill: {市町村名: "dark"|"mid"|"light"|"hatch"|"dots"}
    labels: {市町村名: "A"} 丸囲みの記号を重心に置く
    markers: [(x, y, 記号, 説明)] 任意の位置に印
    legend: [(fill種別, 説明)]
    """
    fill = fill or {}
    labels = labels or {}
    fills = {"dark": "#1b2b44", "mid": "#7d8fa8", "light": "#c9d4e2", "hatch": "url(#hatch)", "dots": "url(#dots)"}
    W, H = _MAP["W"], _MAP["H"]
    out = [f'<svg viewBox="-10 -10 {W + 20} {H + 60}" width="{width}" xmlns="http://www.w3.org/2000/svg" '
           f'font-family="sans-serif">{PATTERNS}<rect x="-10" y="-10" width="{W + 20}" height="{H + 60}" fill="{SEA}"/>']
    for code, m in _MAP["m"].items():
        f = fills.get(fill.get(NAMES[code]), "#fbfaf6")
        out.append(f'<path d="{m["d"]}" fill="{f}" stroke="{INK}" stroke-width="0.9" stroke-linejoin="round"/>')
    for name, lab in labels.items():
        x, y = _MAP["m"][CODE[name]]["c"]
        out.append(f'<circle cx="{x}" cy="{y}" r="17" fill="#fff" stroke="{INK}" stroke-width="2"/>'
                   f'<text x="{x}" y="{y + 7}" text-anchor="middle" font-size="20" font-weight="bold" fill="{INK}">{e(lab)}</text>')
    if names:
        for name in names:
            x, y = _MAP["m"][CODE[name]]["c"]
            out.append(f'<text x="{x}" y="{y + 5}" text-anchor="middle" font-size="15" font-weight="bold" '
                       f'fill="{INK}" stroke="#fff" stroke-width="4" paint-order="stroke">{e(name)}</text>')
    for x, y, sym, note in markers or []:
        out.append(f'<g><circle cx="{x}" cy="{y}" r="9" fill="#c0392b" stroke="#fff" stroke-width="2.5"/>'
                   f'<text x="{x + 14}" y="{y - 8}" font-size="17" font-weight="bold" fill="{INK}" stroke="#fff" '
                   f'stroke-width="4" paint-order="stroke">{e(sym)}</text>'
                   + (f'<text x="{x + 14}" y="{y + 12}" font-size="13" fill="{INK}" stroke="#fff" stroke-width="4" '
                      f'paint-order="stroke">{e(note)}</text>' if note else "") + "</g>")
    if sea_labels:
        out.append(f'<text x="330" y="470" font-size="22" fill="#5b7895" letter-spacing="8">相 模 湾</text>'
                   f'<text x="735" y="330" font-size="18" fill="#5b7895" writing-mode="tb">東京湾</text>')
    # 方位記号と縮尺（おおよそ）
    out.append(f'<g transform="translate(40,30)"><path d="M0,-22L9,10L0,4L-9,10Z" fill="{INK}"/>'
               f'<text x="0" y="30" text-anchor="middle" font-size="15" font-weight="bold" fill="{INK}">N</text></g>')
    if legend:
        lx, ly = 20, H + 18
        for i, (k, t) in enumerate(legend):
            x = lx + i * 230
            out.append(f'<rect x="{x}" y="{ly}" width="26" height="18" fill="{fills[k]}" stroke="{INK}"/>'
                       f'<text x="{x + 34}" y="{ly + 15}" font-size="15" fill="{INK}">{e(t)}</text>')
    out.append("</svg>")
    return "".join(out)


def bar_h(rows, unit="", maxv=None, ref=None, width=560, label_w=150, fmt="{:,}"):
    """横棒グラフ。rows=[(ラベル, 値, 強調?)]"""
    maxv = maxv or max(v for _, v, *_ in rows) * 1.1
    bh, gap = 26, 12
    pw = width - label_w - 70
    H = len(rows) * (bh + gap) + 34
    out = [f'<svg viewBox="0 0 {width} {H}" width="100%" xmlns="http://www.w3.org/2000/svg" font-family="sans-serif">']
    for i, (lab, v, *hl) in enumerate(rows):
        y = 10 + i * (bh + gap)
        w = pw * v / maxv
        col = "#1b2b44" if hl and hl[0] else "#8da0b8"
        out.append(f'<text x="{label_w - 8}" y="{y + 18}" text-anchor="end" font-size="14" fill="#1b2b44">{e(lab)}</text>'
                   f'<rect x="{label_w}" y="{y}" width="{w:.1f}" height="{bh}" fill="{col}" rx="2"/>'
                   f'<text x="{label_w + w + 6:.1f}" y="{y + 18}" font-size="14" font-weight="bold" fill="#1b2b44">{fmt.format(v)}{e(unit)}</text>')
    axis_y = H - 22
    out.append(f'<line x1="{label_w}" y1="4" x2="{label_w}" y2="{axis_y}" stroke="#1b2b44"/>')
    if ref is not None:
        x = label_w + pw * ref / maxv
        out.append(f'<line x1="{x:.1f}" y1="4" x2="{x:.1f}" y2="{axis_y}" stroke="#c0392b" stroke-dasharray="5 4" stroke-width="1.6"/>'
                   f'<text x="{x:.1f}" y="{H - 6}" text-anchor="middle" font-size="13" fill="#c0392b">{fmt.format(ref)}</text>')
    out.append("</svg>")
    return "".join(out)


def svg(w, h, body):
    return (f'<svg viewBox="0 0 {w} {h}" width="100%" xmlns="http://www.w3.org/2000/svg" font-family="sans-serif" '
            f'fill="none" stroke-linejoin="round">{PATTERNS}{body}</svg>')


def terrace():
    """相模川沿いの河岸段丘の模式断面図"""
    g = ('<path d="M10,60 L230,70 L250,150 L420,158 L440,230 L560,236 L575,262 L640,262 L655,236 L740,232 L740,300 L10,300 Z" '
         'fill="#efe7d6" stroke="#1b2b44" stroke-width="2"/>'
         '<path d="M575,262 L640,262 L640,262" stroke="#1b2b44"/>'
         '<path d="M578,250 Q607,244 637,250 L640,262 L575,262 Z" fill="#9cc3e0" stroke="#1b2b44"/>'
         '<text x="607" y="285" text-anchor="middle" font-size="15" fill="#1b2b44" stroke="none">相模川</text>'
         '<text x="110" y="50" font-size="15" fill="#1b2b44" stroke="none">上段の段丘面</text>'
         '<text x="300" y="140" font-size="15" fill="#1b2b44" stroke="none">下段の段丘面</text>'
         '<text x="470" y="222" font-size="15" fill="#1b2b44" stroke="none">川沿いの低地</text>'
         '<text x="250" y="105" font-size="13" fill="#1b2b44" stroke="none">段丘崖（がけ）</text>')
    pts = [(120, 66, "①"), (253, 140, "②"), (330, 154, "③"), (500, 233, "④")]
    for x, y, s in pts:
        g += (f'<circle cx="{x}" cy="{y}" r="13" fill="#fff" stroke="#c0392b" stroke-width="2.5"/>'
              f'<text x="{x}" y="{y + 6}" text-anchor="middle" font-size="16" font-weight="bold" fill="#c0392b" stroke="none">{s}</text>')
    g += ('<text x="10" y="20" font-size="13" fill="#1b2b44" stroke="none">西（台地側）</text>'
          '<text x="740" y="20" text-anchor="end" font-size="13" fill="#1b2b44" stroke="none">東</text>'
          '<text x="740" y="296" text-anchor="end" font-size="11" fill="#555" stroke="none">※高さを強調した模式図</text>')
    return svg(750, 305, g)


def sagami_trough():
    """関東大震災の震源とプレート境界（模式図）"""
    base = kanagawa(sea_labels=False, width="100%")
    # 地図の下にプレート境界を重ねるため、地図SVGの末尾に要素を差し込む
    extra = ('<path d="M300,470 Q420,540 560,590 Q680,630 800,650" stroke="#c0392b" stroke-width="4" stroke-dasharray="14 8" fill="none"/>'
             '<text x="420" y="660" font-size="16" fill="#c0392b">相模トラフ（プレート境界）</text>'
             '<g stroke="#1b2b44" stroke-width="4"><line x1="250" y1="510" x2="270" y2="530"/><line x1="270" y1="510" x2="250" y2="530"/></g>'
             '<text x="280" y="528" font-size="16" font-weight="bold" fill="#1b2b44">× 震源</text>'
             '<text x="380" y="450" font-size="22" fill="#5b7895" letter-spacing="8">相 模 湾</text>')
    base = base.replace(f'viewBox="-10 -10 {_MAP["W"] + 20} {_MAP["H"] + 60}"', f'viewBox="-10 -10 {_MAP["W"] + 20} {_MAP["H"] + 110}"')
    base = base.replace(f'width="{_MAP["W"] + 20}" height="{_MAP["H"] + 60}" fill="{SEA}"',
                        f'width="{_MAP["W"] + 20}" height="{_MAP["H"] + 110}" fill="{SEA}"')
    return base.replace("</svg>", extra + "</svg>")


def timeline(items, width=700):
    """縦の年表。items=[(年, できごと) または (None, 'A')]"""
    h = len(items) * 34 + 10
    g = f'<line x1="90" y1="10" x2="90" y2="{h - 10}" stroke="#1b2b44" stroke-width="3"/>'
    for i, (yr, ev) in enumerate(items):
        y = 26 + i * 34
        if yr is None:
            g += (f'<rect x="72" y="{y - 14}" width="36" height="26" rx="5" fill="#fff" stroke="#c0392b" stroke-width="2"/>'
                  f'<text x="90" y="{y + 5}" text-anchor="middle" font-size="16" font-weight="bold" fill="#c0392b" stroke="none">{e(ev)}</text>')
        else:
            g += (f'<circle cx="90" cy="{y}" r="7" fill="#1b2b44"/>'
                  f'<text x="70" y="{y + 5}" text-anchor="end" font-size="15" font-weight="bold" fill="#1b2b44" stroke="none">{yr}</text>'
                  f'<text x="110" y="{y + 5}" font-size="15" fill="#1b2b44" stroke="none">{e(ev)}</text>')
    return svg(width, h, g)


def tokaido():
    """東海道の宿場（神奈川県内）"""
    st = ["品川", "川崎", "神奈川", "保土ヶ谷", "X", "藤沢", "平塚", "大磯", "小田原", "箱根", "三島"]
    g = '<line x1="30" y1="80" x2="680" y2="80" stroke="#1b2b44" stroke-width="5"/>'
    g += '<rect x="80" y="40" width="485" height="80" rx="10" fill="none" stroke="#7d8fa8" stroke-dasharray="6 4"/>'
    g += '<text x="322" y="140" text-anchor="middle" font-size="13" fill="#555" stroke="none">現在の神奈川県内の宿場</text>'
    for i, s in enumerate(st):
        x = 40 + i * 62
        red = s == "X"
        g += (f'<circle cx="{x}" cy="80" r="9" fill="{"#c0392b" if red else "#fff"}" stroke="#1b2b44" stroke-width="2"/>'
              f'<text x="{x}" y="{60 if i % 2 else 110}" text-anchor="middle" font-size="15" font-weight="bold" '
              f'fill="{"#c0392b" if red else "#1b2b44"}" stroke="none">{s}</text>')
    g += ('<text x="20" y="25" font-size="13" fill="#1b2b44" stroke="none">← 江戸（日本橋）</text>'
          '<text x="690" y="25" text-anchor="end" font-size="13" fill="#1b2b44" stroke="none">京都 →</text>'
          '<path d="M598,58 L612,44 L626,58" stroke="#c0392b" stroke-width="2.5"/>'
          '<text x="612" y="36" text-anchor="middle" font-size="13" fill="#c0392b" stroke="none">関所</text>')
    return svg(700, 150, g)


def yokohama_port():
    """開港期の横浜（模式図）"""
    g = ('<rect width="700" height="360" fill="#e6eff6"/>'
         '<path d="M0,0 H700 V70 Q560,80 470,60 Q380,40 300,70 Q200,110 0,100 Z" fill="#fbfaf6" stroke="#1b2b44" stroke-width="1.5"/>'
         '<path d="M0,360 V200 Q120,190 220,230 Q300,260 380,250 Q470,240 520,270 Q600,300 700,280 V360 Z" fill="#fbfaf6" stroke="#1b2b44" stroke-width="1.5"/>'
         '<path d="M40,95 Q200,105 300,62 Q400,30 470,50 Q560,72 690,62" stroke="#1b2b44" stroke-width="4" stroke-dasharray="1 0"/>'
         '<text x="560" y="45" font-size="15" font-weight="bold" fill="#1b2b44" stroke="none">東海道</text>'
         '<rect x="380" y="34" width="54" height="26" fill="#fff" stroke="#1b2b44"/>'
         '<text x="407" y="52" text-anchor="middle" font-size="13" fill="#1b2b44" stroke="none">神奈川宿</text>'
         '<rect x="340" y="250" width="150" height="70" fill="url(#dots)" stroke="#1b2b44" stroke-width="2"/>'
         '<text x="415" y="345" text-anchor="middle" font-size="14" fill="#1b2b44" stroke="none">横浜村（開港場・外国人居留地）</text>'
         '<path d="M330,250 V330 M500,250 V330" stroke="#5b8fc0" stroke-width="5"/>'
         '<text x="250" y="300" font-size="12" fill="#1b2b44" stroke="none">堀・川で区切る</text>'
         '<text x="280" y="160" font-size="20" fill="#5b7895" stroke="none" letter-spacing="6">入　江</text>'
         '<text x="690" y="352" text-anchor="end" font-size="11" fill="#555" stroke="none">※模式図</text>')
    return svg(700, 360, g)


def enoden():
    st = ["藤沢", "石上", "柳小路", "鵠沼", "湘南海岸公園", "江ノ島", "腰越", "鎌倉高校前", "七里ヶ浜",
          "稲村ヶ崎", "極楽寺", "長谷", "由比ヶ浜", "和田塚", "鎌倉"]
    g = '<path d="M25,40 L25,120 Q25,170 75,170 L650,170 Q690,170 690,130 L690,40" stroke="#1d7a52" stroke-width="7"/>'
    xs = []
    for i, s in enumerate(st):
        if i < 3:
            x, y = 25, 40 + i * 40
        elif i < 12:
            x, y = 75 + (i - 3) * 64, 170
        else:
            x, y = 690, 130 - (i - 12) * 45
        xs.append((x, y))
        g += f'<circle cx="{x}" cy="{y}" r="8" fill="#fff" stroke="#1b2b44" stroke-width="2.5"/>'
        if 3 <= i < 12:
            g += (f'<text x="{x}" y="{198 + (i % 2) * 20}" text-anchor="middle" font-size="13.5" font-weight="bold" '
                  f'fill="#1b2b44" stroke="none">{s}</text>')
        else:
            g += (f'<text x="{x + (16 if i < 3 else -16)}" y="{y + 5}" text-anchor="{"start" if i < 3 else "end"}" '
                  f'font-size="13.5" font-weight="bold" fill="#1b2b44" stroke="none">{s}</text>')
    g += ('<rect x="230" y="250" width="290" height="26" fill="#e6eff6"/>'
          '<text x="375" y="268" text-anchor="middle" font-size="14" fill="#5b7895" stroke="none">相模湾（海）</text>'
          '<text x="690" y="250" text-anchor="end" font-size="11" fill="#555" stroke="none">※駅の位置関係を示した模式図</text>')
    return svg(720, 285, g)


def hakone_route():
    st = [("箱根湯本", "登山電車"), ("強羅", "ケーブルカー"), ("早雲山", "ロープウェイ"),
          ("大涌谷・桃源台", "観光船（海賊船）"), ("元箱根港", None)]
    g = ""
    for i, (s, ride) in enumerate(st):
        x = 20 + i * 140
        g += (f'<rect x="{x}" y="20" width="118" height="44" rx="8" fill="#fff" stroke="#1b2b44" stroke-width="2"/>'
              f'<text x="{x + 59}" y="48" text-anchor="middle" font-size="14" font-weight="bold" fill="#1b2b44" stroke="none">{s}</text>')
        if ride:
            lab = "ア" if i < 3 else "イ"
            lab = ["ア", "イ", "ウ", "エ"][i]
            g += (f'<line x1="{x + 118}" y1="42" x2="{x + 140}" y2="42" stroke="#1b2b44" stroke-width="2" marker-end="url(#arr)"/>'
                  f'<rect x="{x + 104}" y="74" width="50" height="26" rx="13" fill="#1b2b44"/>'
                  f'<text x="{x + 129}" y="92" text-anchor="middle" font-size="14" font-weight="bold" fill="#fff" stroke="none">{lab}</text>')
    return svg(720, 110, g)


def hakone_profile():
    pts = [(0, 96, "箱根湯本"), (1.0, 165, "塔ノ沢"), (6.1, 436, "宮ノ下"), (8.9, 541, "強羅")]
    X = lambda km: 70 + km * 68
    Y = lambda m: 280 - m * 0.42
    g = '<line x1="70" y1="280" x2="690" y2="280" stroke="#1b2b44"/><line x1="70" y1="20" x2="70" y2="280" stroke="#1b2b44"/>'
    for m in (100, 200, 300, 400, 500, 600):
        g += (f'<line x1="66" y1="{Y(m)}" x2="690" y2="{Y(m)}" stroke="#ccd" stroke-dasharray="3 3"/>'
              f'<text x="60" y="{Y(m) + 5}" text-anchor="end" font-size="12" fill="#1b2b44" stroke="none">{m}</text>')
    for k in range(0, 10):
        g += f'<text x="{X(k)}" y="298" text-anchor="middle" font-size="12" fill="#1b2b44" stroke="none">{k}</text>'
    g += '<text x="690" y="316" text-anchor="end" font-size="12" fill="#1b2b44" stroke="none">箱根湯本からの距離（km）</text>'
    g += '<text x="12" y="14" font-size="12" fill="#1b2b44" stroke="none">標高（m）</text>'
    d = "M" + " L".join(f"{X(k)},{Y(m)}" for k, m, _ in pts)
    g += f'<path d="{d}" stroke="#1d7a52" stroke-width="4"/>'
    for k, m, s in pts:
        g += (f'<circle cx="{X(k)}" cy="{Y(m)}" r="6" fill="#fff" stroke="#1b2b44" stroke-width="2"/>'
              f'<text x="{X(k) + 8}" y="{Y(m) - 12}" font-size="13" font-weight="bold" fill="#1b2b44" stroke="none">{s}（{m}m）</text>')
    g += '<text x="690" y="20" text-anchor="end" font-size="11" fill="#555" stroke="none">※主な駅のみを結んだ模式的なグラフ</text>'
    return svg(700, 322, g)


def shin_yokohama():
    g = ('<line x1="40" y1="70" x2="660" y2="70" stroke="#1b2b44" stroke-width="7"/>'
         '<line x1="200" y1="70" x2="250" y2="150" stroke="#7d8fa8" stroke-width="5"/>'
         '<text x="258" y="160" font-size="13" fill="#1b2b44" stroke="none">→ JR線へ直通</text>')
    for x, s in [(60, "西谷"), (200, "羽沢横浜国大"), (360, "新横浜"), (500, "新綱島"), (640, "日吉")]:
        g += (f'<circle cx="{x}" cy="70" r="10" fill="#fff" stroke="#1b2b44" stroke-width="3"/>'
              f'<text x="{x}" y="45" text-anchor="middle" font-size="15" font-weight="bold" fill="#1b2b44" stroke="none">{s}</text>')
    g += ('<text x="40" y="110" font-size="13" fill="#1b2b44" stroke="none">← 相鉄線方面</text>'
          '<text x="660" y="110" text-anchor="end" font-size="13" fill="#1b2b44" stroke="none">東急線方面 →</text>'
          '<rect x="330" y="88" width="60" height="22" rx="4" fill="#1b2b44"/>'
          '<text x="360" y="104" text-anchor="middle" font-size="12" fill="#fff" stroke="none">新幹線</text>')
    return svg(700, 175, g)


def switchback():
    g = ('<path d="M40,250 L330,190 L120,130 L420,70 L660,30" stroke="#1d7a52" stroke-width="5"/>'
         '<path d="M330,190 L380,180 M120,130 L70,140" stroke="#1d7a52" stroke-width="5" stroke-dasharray="6 4"/>'
         '<text x="40" y="275" font-size="13" fill="#1b2b44" stroke="none">下から登ってくる</text>'
         '<text x="660" y="22" text-anchor="end" font-size="13" fill="#1b2b44" stroke="none">上へ</text>'
         '<circle cx="330" cy="190" r="8" fill="#c0392b"/><circle cx="120" cy="130" r="8" fill="#c0392b"/>'
         '<text x="345" y="214" font-size="13" fill="#c0392b" stroke="none">ここで進む向きを変える</text>'
         '<text x="660" y="275" text-anchor="end" font-size="11" fill="#555" stroke="none">※しくみを示した模式図</text>')
    return svg(700, 285, g)


def expo_map():
    return kanagawa(fill={"横浜市": "light"}, names=["横浜市"],
                    markers=[(522, 196, "会場", "旧上瀬谷通信施設の跡地")],
                    legend=[("light", "横浜市")])


def terrace_layers():
    """相模川沿いの河岸段丘：地層と地下水面（模式断面図）"""
    surf = "M20,60 L230,62 L252,150 L430,156 L452,228 L600,234 L612,252 L688,252 L700,226 L770,222"
    g = (f'<path d="{surf} L770,330 L20,330 Z" fill="#e8e1d2" stroke="none"/>'
         # ローム層（斜線）・段丘礫層（点）
         '<path d="M20,60 L230,62 L236,86 L20,84 Z M252,150 L430,156 L436,176 L256,172 Z" fill="url(#hatch)" stroke="#1b2b44"/>'
         '<path d="M20,84 L236,86 L246,130 L20,128 Z M256,172 L436,176 L444,204 L262,200 Z M452,228 L600,234 L604,246 L455,242 Z" '
         'fill="url(#dots)" stroke="#1b2b44"/>'
         f'<path d="{surf}" fill="none" stroke="#1b2b44" stroke-width="2.5"/>'
         '<path d="M612,252 Q650,240 688,252 Z" fill="#9cc3e0" stroke="#1b2b44"/>'
         # 地下水面
         '<path d="M20,150 L240,152 L262,151 M262,190 L440,196 L458,229 M458,236 L606,244" stroke="#1d5fa8" stroke-width="2.5" '
         'stroke-dasharray="9 5" fill="none"/>'
         '<text x="650" y="275" text-anchor="middle" font-size="14" fill="#1b2b44" stroke="none">相模川</text>')
    for x, y, s in [(120, 60, "P"), (340, 156, "Q"), (462, 229, "R"), (540, 233, "S")]:
        g += (f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y - 26}" stroke="#c0392b" stroke-width="2"/>'
              f'<circle cx="{x}" cy="{y - 36}" r="12" fill="#fff" stroke="#c0392b" stroke-width="2.5"/>'
              f'<text x="{x}" y="{y - 31}" text-anchor="middle" font-size="15" font-weight="bold" fill="#c0392b" stroke="none">{s}</text>')
    g += ('<g font-size="12.5" fill="#1b2b44" stroke="none">'
          '<rect x="22" y="290" width="22" height="13" fill="url(#hatch)" stroke="#1b2b44"/><text x="50" y="301">関東ローム層（火山灰）</text>'
          '<rect x="210" y="290" width="22" height="13" fill="url(#dots)" stroke="#1b2b44"/><text x="238" y="301">段丘礫層（砂・れき）</text>'
          '<line x1="400" y1="297" x2="430" y2="297" stroke="#1d5fa8" stroke-width="2.5" stroke-dasharray="9 5"/>'
          '<text x="436" y="301">地下水面</text>'
          '<text x="22" y="322">西（台地）</text><text x="760" y="322" text-anchor="end">東 ／ ※高さを強調した模式図</text></g>')
    return svg(780, 330, g)


def silk_road():
    """八王子から横浜へ生糸が運ばれた道（模式図）"""
    g = ('<rect width="700" height="300" fill="#fff"/>'
         '<path d="M560,300 Q600,250 700,240 V300 Z" fill="#e6eff6"/>'
         '<text x="640" y="285" font-size="14" fill="#5b7895" stroke="none">横浜港</text>'
         '<path d="M80,60 Q200,120 300,150 Q420,190 600,250" stroke="#8a6d3b" stroke-width="4" stroke-dasharray="2 6" '
         'stroke-linecap="round"/>'
         '<path d="M80,70 Q190,150 310,175 Q450,205 560,230 L600,250" stroke="#1b2b44" stroke-width="4"/>'
         '<g font-size="14" font-weight="bold" fill="#1b2b44" stroke="none">'
         '<circle cx="80" cy="64" r="9" fill="#fff" stroke="#1b2b44" stroke-width="3"/><text x="40" y="40">八王子</text>'
         '<circle cx="300" cy="158" r="8" fill="#fff" stroke="#1b2b44" stroke-width="3"/><text x="250" y="130">原町田</text>'
         '<circle cx="560" cy="232" r="8" fill="#fff" stroke="#1b2b44" stroke-width="3"/><text x="500" y="210">東神奈川</text>'
         '<circle cx="602" cy="252" r="9" fill="#c0392b" stroke="#fff" stroke-width="2"/><text x="612" y="248">横浜</text></g>'
         '<g font-size="12.5" fill="#1b2b44" stroke="none">'
         '<line x1="30" y1="250" x2="70" y2="250" stroke="#8a6d3b" stroke-width="4" stroke-dasharray="2 6" stroke-linecap="round"/>'
         '<text x="78" y="255">江戸時代末から生糸を運んだ道（「絹の道」）</text>'
         '<line x1="30" y1="275" x2="70" y2="275" stroke="#1b2b44" stroke-width="4"/>'
         '<text x="78" y="280">1908年に開通した横浜鉄道（現在のJR横浜線）</text>'
         '<text x="690" y="20" text-anchor="end">※模式図</text>'
         '<text x="40" y="100">（周辺は養蚕地帯）</text></g>')
    return svg(700, 300, g)
