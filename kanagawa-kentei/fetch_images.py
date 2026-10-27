"""問題で使う写真を Wikimedia Commons から images/ にダウンロードし、
作者・ライセンスを images/credits.json に記録する。

使い方: python3 fetch_images.py
すでにあるファイルは取得しない。Commons API の利用ルールに従い、
説明つきの User-Agent を送り、アクセス制限（429）を受けたら待って再試行する。
"""
import json
import pathlib
import re
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).parent
IMG = ROOT / "images"
UA = {"User-Agent": "KanagawaKenteiBuilder/1.0 (educational quiz builder; low-volume)"}
WIDTH = 1280  # Wikimedia の標準サムネイル幅

# 保存名: Commons のファイル名
FILES = {
    "c_enoshima_air.jpg": "Aerial view of Enoshima from USAF UH-1N Huey.jpg",
    "c_owakudani.jpg": "Owakudani Valley near Owakudani Station.JPG",
    "c_kanto1923.jpg": "Motomachi and Yamashitacho after Great Kanto earthquake.JPG",
    "c_odawara.jpg": "Odawara Castle Keep Tower 20211201-1.jpg",
    "c_tsurugaoka.jpg": "Tsurugaoka Hachimangu 001.jpg",
    "c_hiroshige_hakone.jpg": "Hakone, gezicht op het meer Hakone, kosui zu (titel op object) De 53 stations van de Tokaido "
                              "(serietitel) Tokaido gojusan tsugi no uchi (serietitel op object), RP-P-1963-5.jpg",
    "c_sekisho.jpg": "Checkpoint @ Hakone Sekisho @ Hakone (10621234575).jpg",
    "c_sadahide.jpg": "「神名川横浜新開港圖」-“The Newly Opened Port of Yokohama in Kanagawa Prefecture” MET DP147960.jpg",
    "c_yamashita.jpg": "Yokohama Yamashita Park and Marine Tower.jpg",
    "c_hikawamaru.jpg": "20250103 Hikawa Maru 113538.jpg",
    "c_kawasaki.jpg": "Kanagawa Kawasaki night view xl.jpg",
    "c_yosegi.jpg": "Hakone Yosegi Zaiku display - Hakone Checkpoint Exhibition Hall - Hakone no Seki (barrier station) "
                    "- Hakone, Japan - DSC06051.jpg",
    "c_kamakurabori.jpg": "KamakuraBori.jpg",
    "c_koshigoe.jpg": "Enoshima Line street running near Koshigoe station.jpg",
    "c_kokomae.jpg": "Level crossing near the Kamakura-Kōkō-Mae Station 01.jpg",
    "c_daibutsu.jpg": "Kamakura Daibutsu 20170210.jpg",
    "c_nakamise.jpg": "Benzaiten Nakamise Street.jpg",
    "c_cosmoclock.jpg": "Cosmo Clock 21 at night 20211225.jpg",
    "c_hakone_torii.jpg": "Torii on Lake Ashi @ Hakone Shrine (13776878594).jpg",
    "c_tozan.jpg": "Hakone tozan railway 103 in Ohiradai.jpg",
    "c_yokohama1872.jpg": "Yokohama Station 1800s.jpg",
    "c_shintsunashima.jpg": "Shin-tsunashima Station Platform 20240406 01.jpg",
    "c_yokohama_east.jpg": "Yokohama Station East exit Taxi plaza.jpg",
    "c_asahina.jpg": "Asahina-Pass.jpg",
    "c_kamiseya.jpg": "US Navy 110828-N-VE260-735 An SH-60B Sea Hawk helicopter lands at Naval Support Facility Kamiseya "
                      "during the Yokohama Comprehensive Disaster Drill.jpg",
}


def get(url):
    for wait in (10, 30, 60, 120):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=90) as r:
                return r.read()
        except urllib.error.HTTPError as ex:
            if ex.code != 429:
                raise
            ra = ex.headers.get("Retry-After")
            w = int(ra) if ra and ra.isdigit() else wait
            print(f"  アクセス制限のため {w} 秒待機", flush=True)
            time.sleep(w)
    raise SystemExit("アクセス制限が続いたため中止しました")


def clean(t):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", t or "")).strip()


def main():
    IMG.mkdir(exist_ok=True)
    cpath = IMG / "credits.json"
    credits = json.loads(cpath.read_text()) if cpath.exists() else {}
    todo = {n: t for n, t in FILES.items() if not ((IMG / n).exists() and n in credits)}
    if not todo:
        return
    # 情報はまとめて1回のリクエストで取得する
    q = urllib.parse.urlencode({"action": "query", "titles": "|".join("File:" + t for t in todo.values()),
                                "prop": "imageinfo", "iiprop": "url|extmetadata", "iiurlwidth": WIDTH,
                                "format": "json", "iiextmetadatafilter": "LicenseShortName|Artist"})
    res = json.loads(get("https://commons.wikimedia.org/w/api.php?" + q))["query"]
    norm = {x["from"]: x["to"] for x in res.get("normalized", [])}
    pages = {p["title"]: p for p in res["pages"].values()}
    for name, title in todo.items():
        page = pages.get(norm.get("File:" + title, "File:" + title), {})
        if "imageinfo" not in page:
            print("見つからない:", title)
            continue
        ii = page["imageinfo"][0]
        m = ii.get("extmetadata", {})
        (IMG / name).write_bytes(get(ii.get("thumburl") or ii["url"]))
        credits[name] = {"title": title, "page": ii["descriptionurl"],
                         "artist": clean(m.get("Artist", {}).get("value")) or "作者不詳",
                         "license": clean(m.get("LicenseShortName", {}).get("value"))}
        cpath.write_text(json.dumps(credits, ensure_ascii=False, indent=1))
        print(name, "|", credits[name]["license"], "|", credits[name]["artist"][:40])
        time.sleep(2)


if __name__ == "__main__":
    main()
