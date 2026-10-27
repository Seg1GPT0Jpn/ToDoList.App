"""国土地理院の地理院タイルをつなぎ合わせ、問題用の地図画像を images/maps/ に作る。

使い方: python3 gsi_maps.py
出典表示：「地理院タイル（標準地図／色別標高図／陰影起伏図／全国最新写真）を加工して作成」
"""
import io
import math
import pathlib
import time
import urllib.request

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).parent
OUT = ROOT / "images" / "maps"
UA = {"User-Agent": "KanagawaKenteiBuilder/1.0 (educational quiz builder)"}
TILE = "https://cyberjapandata.gsi.go.jp/xyz/{layer}/{z}/{x}/{y}.{ext}"
EXT = {"std": "png", "pale": "png", "relief": "png", "hillshademap": "png", "seamlessphoto": "jpg"}
FONT = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
CACHE = {}


def xy(lat, lon, z):
    n = 2 ** z
    x = (lon + 180) / 360 * n
    y = (1 - math.log(math.tan(math.radians(lat)) + 1 / math.cos(math.radians(lat))) / math.pi) / 2 * n
    return x * 256, y * 256


def tile(layer, z, x, y):
    key = (layer, z, x, y)
    if key not in CACHE:
        url = TILE.format(layer=layer, z=z, x=x, y=y, ext=EXT[layer])
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                CACHE[key] = Image.open(io.BytesIO(r.read())).convert("RGBA")
        except urllib.error.HTTPError:
            CACHE[key] = Image.new("RGBA", (256, 256), (255, 255, 255, 0))
        time.sleep(0.05)
    return CACHE[key]


def base(layer, z, north, west, south, east, bg=(255, 255, 255, 255)):
    x0, y0 = xy(north, west, z)
    x1, y1 = xy(south, east, z)
    img = Image.new("RGBA", (int(x1 - x0), int(y1 - y0)), bg)
    for tx in range(int(x0 // 256), int(x1 // 256) + 1):
        for ty in range(int(y0 // 256), int(y1 // 256) + 1):
            t = tile(layer, z, tx, ty)
            img.paste(t, (int(tx * 256 - x0), int(ty * 256 - y0)), t)
    return img, (x0, y0, z)


def make(name, layers, z, bbox, labels=(), marks=(), scale_km=None):
    """layers: [(レイヤ名, 不透明度)]  labels: [(緯度, 経度, 文字, 大きさ)]  marks: [(緯度, 経度, 記号)]"""
    img = None
    for layer, alpha in layers:
        im, origin = base(layer, z, *bbox, bg=(255, 255, 255, 255) if img is None else (0, 0, 0, 0))
        if img is None:
            img = im
        else:
            im.putalpha(im.getchannel("A").point(lambda a: int(a * alpha)))
            img.alpha_composite(im)
    x0, y0, z = origin
    d = ImageDraw.Draw(img)

    def px(lat, lon):
        x, y = xy(lat, lon, z)
        return x - x0, y - y0

    for lat, lon, text, size in labels:
        f = ImageFont.truetype(FONT, size)
        x, y = px(lat, lon)
        d.text((x, y), text, font=f, fill=(20, 30, 50), anchor="mm", stroke_width=max(3, size // 6), stroke_fill="white")
    for lat, lon, sym in marks:
        x, y = px(lat, lon)
        f = ImageFont.truetype(FONT, 26)
        d.ellipse((x - 20, y - 20, x + 20, y + 20), fill="white", outline=(192, 57, 43), width=4)
        d.text((x, y - 1), sym, font=f, fill=(192, 57, 43), anchor="mm")
    if scale_km:
        lat = (bbox[0] + bbox[2]) / 2
        m_per_px = 156543.03 * math.cos(math.radians(lat)) / 2 ** z
        L = scale_km * 1000 / m_per_px
        W, H = img.size
        d.rectangle((W - L - 30, H - 50, W - 10, H - 10), fill=(255, 255, 255, 220))
        d.line((W - L - 20, H - 20, W - 20, H - 20), fill="black", width=5)
        f = ImageFont.truetype(FONT, 18)
        d.text((W - 20 - L / 2, H - 34), f"{scale_km}km", font=f, fill="black", anchor="mm")
    # 方位
    f = ImageFont.truetype(FONT, 22)
    d.polygon([(40, 18), (52, 54), (40, 46), (28, 54)], fill=(20, 30, 50))
    d.text((40, 70), "N", font=f, fill=(20, 30, 50), anchor="mm", stroke_width=3, stroke_fill="white")
    OUT.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(OUT / name, quality=88)
    print(name, img.size)


RELIEF = [("relief", 1), ("hillshademap", 0.45)]

MAPS = {
    # 鎌倉：三方を山に囲まれた地形
    "kamakura.jpg": dict(layers=RELIEF + [("pale", 0.25)], z=15, bbox=(35.342, 139.522, 35.300, 139.582),
                         labels=[(35.3262, 139.5566, "鶴岡八幡宮", 26), (35.3075, 139.5440, "由比ヶ浜", 26),
                                 (35.3030, 139.5650, "相 模 湾", 30)], scale_km=1),
    # 江の島：砂州で陸とつながる陸繋島
    "enoshima.jpg": dict(layers=[("seamlessphoto", 1)], z=16, bbox=(35.3125, 139.4700, 35.2955, 139.4935),
                         labels=[(35.2985, 139.4790, "江の島", 30), (35.3115, 139.4745, "片瀬西浜", 22),
                                 (35.3105, 139.4895, "片瀬東浜", 22)], marks=[(35.3040, 139.4820, "X")], scale_km=0.5),
    # 相模川沿いの河岸段丘
    "sagami_terrace.jpg": dict(layers=RELIEF, z=13, bbox=(35.620, 139.300, 35.470, 139.460),
                               labels=[(35.540, 139.340, "相模川", 26), (35.575, 139.410, "相模原台地", 28)], scale_km=2),
    # 箱根火山
    "hakone.jpg": dict(layers=RELIEF + [("pale", 0.2)], z=13, bbox=(35.300, 138.960, 35.150, 139.110),
                       labels=[(35.215, 139.000, "芦ノ湖", 26), (35.2445, 139.0205, "大涌谷", 22),
                               (35.2330, 139.0210, "神山", 22)], scale_km=2),
    # 横浜駅の移り変わり（標準地図）
    "yokohama_station.jpg": dict(layers=[("std", 1)], z=16, bbox=(35.4700, 139.6150, 35.4480, 139.6380),
                                 marks=[(35.4510, 139.6310, "1"), (35.4590, 139.6250, "2"), (35.4657, 139.6223, "3")],
                                 scale_km=0.5),
}


def main(names=None):
    for name, kw in MAPS.items():
        if names and name not in names:
            continue
        make(name, **kw)


if __name__ == "__main__":
    import sys
    main(sys.argv[1:] or None)
