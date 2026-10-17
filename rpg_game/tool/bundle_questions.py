#!/usr/bin/env python3
"""問題ファイル（assets/questions/<教科>/<セット>.json）を、教科ごとに1つの
ファイル（assets/question_bundles/<教科>.json）にまとめる。

アプリが読むのはまとめたファイルだけ（Web で公開できるファイル数を減らし、
読み込みの回数も減らすため）。問題を直したら、このスクリプトをもう一度動かす。
assign.py の最後でも自動で動く。テスト（question_bundle_test）が食いちがいを見つける。

使い方: python3 tool/bundle_questions.py
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1] / 'assets'
SRC = ROOT / 'questions'
OUT = ROOT / 'question_bundles'


def main():
    OUT.mkdir(exist_ok=True)
    worlds = sorted(p.name for p in SRC.iterdir() if p.is_dir())
    for w in worlds:
        sets = {}
        for f in sorted((SRC / w).glob('*.json')):
            data = json.loads(f.read_text(encoding='utf-8'))
            sets[f.stem] = data
        text = json.dumps(sets, ensure_ascii=False, separators=(',', ':'))
        (OUT / f'{w}.json').write_text(text + '\n', encoding='utf-8')
        print(f'{w}: {len(sets)} セット')
    # もう存在しない教科のまとめファイルを消す
    for f in OUT.glob('*.json'):
        if f.stem not in worlds:
            f.unlink()


if __name__ == '__main__':
    main()
