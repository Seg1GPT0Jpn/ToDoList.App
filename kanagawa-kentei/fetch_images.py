"""問題で使う写真を Wikimedia Commons から images/ にダウンロードし、
作者・ライセンスを images/credits.json に記録する。

使い方: python3 fetch_images.py
Commons API のアクセス制限を避けるため、ファイル名から upload.wikimedia.org の
標準サイズ（幅1280px）のサムネイル URL を直接組み立てて取得する。
作者・ライセンスは各ファイルページで確認した内容を下の表に記載している。
"""
import hashlib
import json
import pathlib
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).parent
IMG = ROOT / "images"
UA = {"User-Agent": "KanagawaKenteiBuilder/1.0 (educational quiz builder; low-volume)"}
WIDTH = 1280  # Wikimedia の標準サムネイル幅

# 保存名: (Commons のファイル名, 作者, ライセンス)
FILES = {
    "c_enoshima_air.jpg": ("Aerial view of Enoshima from USAF UH-1N Huey.jpg", "Manuel Zamora", "Public domain"),
    "c_owakudani.jpg": ("Owakudani Valley near Owakudani Station.JPG", "そらみみ", "CC BY-SA 3.0"),
    "c_kanto1923.jpg": ("Motomachi and Yamashitacho after Great Kanto earthquake.JPG", "作者不詳", "Public domain"),
    "c_odawara.jpg": ("Odawara Castle Keep Tower 20211201-1.jpg", "Suicasmo", "CC BY-SA 4.0"),
    "c_tsurugaoka.jpg": ("Tsurugaoka Hachimangu 001.jpg", "Ocdp", "CC0"),
    "c_sekisho.jpg": ("Checkpoint @ Hakone Sekisho @ Hakone (10621234575).jpg", "Guilhem Vellut", "CC BY 2.0"),
    "c_sadahide.jpg": ("「神名川横浜新開港圖」-“The Newly Opened Port of Yokohama in Kanagawa Prefecture” MET DP147960.jpg",
                       "歌川貞秀（メトロポリタン美術館所蔵）", "CC0"),
    "c_yamashita.jpg": ("Yokohama Yamashita Park and Marine Tower.jpg", "Tokyo538", "CC0"),
    "c_hikawamaru.jpg": ("20250103 Hikawa Maru 113538.jpg", "Matthide127", "CC0"),
    "c_kawasaki.jpg": ("Kanagawa Kawasaki night view xl.jpg", "Yudai_photography", "CC BY 4.0"),
    "c_yosegi.jpg": ("Hakone Yosegi Zaiku display - Hakone Checkpoint Exhibition Hall - Hakone no Seki (barrier station) "
                     "- Hakone, Japan - DSC06051.jpg", "Daderot", "CC0"),
    "c_kamakurabori.jpg": ("KamakuraBori.jpg", "Pqks758", "CC BY-SA 3.0"),
    "c_koshigoe.jpg": ("Enoshima Line street running near Koshigoe station.jpg", "kitmasterbloke", "CC BY 2.0"),
    "c_kokomae.jpg": ("Level crossing near the Kamakura-Kōkō-Mae Station 02.jpg", "Dick Thomas Johnson", "CC BY 2.0"),
    "c_daibutsu.jpg": ("Kamakura Daibutsu 20170210.jpg", "Suicasmo", "CC BY-SA 4.0"),
    "c_nakamise.jpg": ("Benzaiten Nakamise Street.jpg", "Nandaro", "CC BY-SA 3.0"),
    "c_cosmoclock.jpg": ("Cosmo Clock 21 at night 20211225.jpg", "Suicasmo", "CC BY-SA 4.0"),
    "c_hakone_torii.jpg": ("Torii on Lake Ashi @ Hakone Shrine (13776878594).jpg", "Guilhem Vellut", "CC BY 2.0"),
    "c_tozan.jpg": ("Hakone tozan railway 103 in Ohiradai.jpg", "Kuroc622", "CC0"),
    "c_yokohama1872.jpg": ("Yokohama Station 1800s.jpg", "作者不詳", "Public domain"),
    "c_shintsunashima.jpg": ("Shin-tsunashima Station Platform 20240406 01.jpg", "Suikotei", "CC BY 4.0"),
    "c_yokohama_east.jpg": ("Yokohama Station East exit Taxi plaza.jpg", "Yoh-Plus", "CC BY 4.0"),
    "c_asahina.jpg": ("Asahina-Pass.jpg", "Tarourashima", "Public domain"),
    "c_katase.jpg": ("Katase Enoshima Station Building 2021-12.jpg", "Kirin7739", "CC BY-SA 4.0"),
    "c_umishibaura.jpg": ("JR Tsurumi Line Umi-Shibaura StationPlatform.jpg", "Mister0124", "CC BY-SA 4.0"),
    "c_kencho.jpg": ("The King’s Tower of the Kanagawa Prefectural Government Building.jpg", "Galactic Center Radio Arc", "CC0"),
    "c_redbrick.jpg": ("Yokohama Red Brick Warehouse 2.jpg", "Syced", "CC0"),
    "c_zenrinmon.jpg": ("Zenrinmon Gate.jpg", "Ymblanter", "CC BY-SA 4.0"),
    "c_kawasakidaishi.jpg": ("Kawasaki Daishi Main Hall.jpg", "ペン太", "CC BY 2.5"),
    "c_daiyuzan.jpg": ("Izuhakone-railway-Daiyuzan-line-Daiyuzan-station-building-20140310-142412.jpg", "LERK", "CC BY-SA 4.0"),
    "c_okawa.jpg": ("JR Tsurumi Line Ōkawa Station Platform.jpg", "Mister0124", "CC BY-SA 4.0"),
    "c_kokudo.jpg": ("Kokudo Station IMG 0035.jpg", "Dandy1022", "CC BY-SA 4.0"),
    "c_yaga.jpg": ("JR Gotemba Line Yaga Station building.jpg", "Mister0124", "CC BY-SA 4.0"),
    "c_odasakae.jpg": ("JR Nambu Line Odasakae Station Platform 1.jpg", "Mister0124", "CC BY-SA 4.0"),
    "c_kozukue.jpg": ("Kozukue Station.jpg", "Syced", "CC0"),
    "c_hakuraku.jpg": ("Tokyu Hakuraku sta 001.jpg", "東京特許許可局", "CC BY-SA 4.0"),
    "c_kanazawabunko.jpg": ("250429 Kanazawa-bunko Station 08.jpg", "Aspere", "CC0"),
    "c_ninomiya.jpg": ("Ninomiya Station Dec 20 2021 various.jpeg", "Nesnad", "CC BY 4.0"),
    "c_sobudaimae.jpg": ("Sobudai-Mae Station.jpg", "Oos", "CC BY-SA 3.0"),
    "c_nishiya.jpg": ("Nishiya Station 2.jpg", "Syced", "CC0"),
    "c_musashinakahara.jpg": ("Musashi-Nakahara-Sta-S.JPG", "Nyao148", "CC BY-SA 3.0"),
    "c_kamiseya.jpg": ("US Navy 110828-N-VE260-735 An SH-60B Sea Hawk helicopter lands at Naval Support Facility Kamiseya "
                       "during the Yokohama Comprehensive Disaster Drill.jpg", "U.S. Navy", "Public domain"),
}


# 答えがわかってしまう駅名標などをぼかす範囲（画像の幅・高さに対する割合：左, 上, 右, 下）
BLUR = {
    "c_katase.jpg": [(0.62, 0.39, 0.85, 0.51)],
    "c_umishibaura.jpg": [(0.81, 0.36, 0.89, 0.82)],
    "c_daiyuzan.jpg": [(0.19, 0.41, 0.36, 0.50), (0.21, 0.50, 0.34, 0.56)],
    "c_okawa.jpg": [(0.73, 0.25, 0.79, 0.86)],
    "c_kokudo.jpg": [(0.42, 0.11, 0.53, 0.23), (0.82, 0.50, 0.96, 0.60), (0.47, 0.58, 0.53, 0.69), (0.52, 0.57, 0.58, 0.80)],
    "c_yaga.jpg": [(0.42, 0.56, 0.58, 0.66)],
    "c_odasakae.jpg": [(0.16, 0.32, 0.22, 0.76)],
    "c_kozukue.jpg": [(0.40, 0.73, 0.58, 0.81)],
    "c_kanazawabunko.jpg": [(0.12, 0.25, 0.19, 0.45)],
    "c_hakuraku.jpg": [(0.27, 0.25, 0.54, 0.37), (0.85, 0.09, 0.91, 0.27)],
    "c_sobudaimae.jpg": [(0.10, 0.35, 0.49, 0.47)],
    "c_musashinakahara.jpg": [(0.46, 0.48, 0.61, 0.60)],
}


def blur(name):
    from PIL import Image, ImageFilter
    path = IMG / name
    im = Image.open(path).convert("RGB")
    W, H = im.size
    for l, t, r, b in BLUR[name]:
        box = (int(l * W), int(t * H), int(r * W), int(b * H))
        im.paste(im.crop(box).filter(ImageFilter.GaussianBlur(14)), box)
    im.save(path, quality=90)


def urls(title):
    name = title.replace(" ", "_")
    h = hashlib.md5(name.encode()).hexdigest()
    q = urllib.parse.quote(name)
    base = f"https://upload.wikimedia.org/wikipedia/commons"
    # 原寸が1280pxより小さい画像はサムネイルが作られないので、原寸を取る
    return [f"{base}/thumb/{h[0]}/{h[:2]}/{q}/{WIDTH}px-{q}", f"{base}/{h[0]}/{h[:2]}/{q}"]


def get(url):
    for wait in (5, 20, 60):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=90) as r:
                return r.read()
        except urllib.error.HTTPError as ex:
            if ex.code != 429:
                raise
            time.sleep(wait)
    raise urllib.error.HTTPError(url, 429, "too many requests", None, None)


def main():
    IMG.mkdir(exist_ok=True)
    cpath = IMG / "credits.json"
    credits = json.loads(cpath.read_text()) if cpath.exists() else {}
    for name, (title, artist, lic) in FILES.items():
        credits[name] = {"title": title, "artist": artist, "license": lic,
                         "page": "https://commons.wikimedia.org/wiki/File:" + urllib.parse.quote(title.replace(" ", "_"))}
        if (IMG / name).exists():
            continue
        for u in urls(title):
            try:
                (IMG / name).write_bytes(get(u))
                if name in BLUR:
                    blur(name)
                print(name, "<-", "thumb" if "/thumb/" in u else "original", flush=True)
                break
            except urllib.error.HTTPError as ex:
                last = ex
        else:
            print("取得できない:", name, last)
        time.sleep(1)
    cpath.write_text(json.dumps(credits, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
