# つづりクエストLight のアイコンを描く：python3 make_icon.py ../../rpg_game_app/assets/fonts/NotoSerifJP-Bold.ttf
# 出力（light_1024.png・light_fg_1024.png・light_maskable_1024.png）を web/icons と android の mipmap に縮小して置く
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
FONT = sys.argv[1]
S = 4  # supersample
N = 1024 * S
BG1, BG2 = (52, 190, 170), (28, 128, 140)
INK = (59, 38, 32)

def bg(size):
    im = Image.new('RGB', (size, size))
    d = ImageDraw.Draw(im)
    for y in range(size):
        t = y / size
        d.line([(0, y), (size, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(BG1, BG2)))
    return im

def art(scale=1.0):
    """透明な絵（中心に寄せる）。scale<1 でアダプティブアイコンの安全域に入れる"""
    im = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = N / 2
    def P(x, y):  # 1024 基準の座標を、中心から scale 倍して置く
        return (c + (x - 512) * S * scale, c + (y - 512) * S * scale)
    def R(v):
        return v * S * scale
    lw = int(R(14))
    # 光（軽さ）の輪
    d.ellipse([P(190, 120), P(834, 764)], fill=(255, 255, 255, 38))
    # 開いた本
    left = [P(150, 640), P(500, 690), P(500, 900), P(150, 850)]
    right = [P(524, 690), P(874, 640), P(874, 850), P(524, 900)]
    cover = [P(130, 660), P(512, 712), P(894, 660), P(894, 880), P(512, 932), P(130, 880)]
    d.polygon(cover, fill=(47, 93, 168), outline=INK, width=lw)
    d.polygon(left, fill=(255, 253, 246), outline=INK, width=lw)
    d.polygon(right, fill=(255, 253, 246), outline=INK, width=lw)
    for i in range(3):
        y = 735 + i * 45
        d.line([P(190, y - 5 + i * 0), P(460, y + 35)], fill=(200, 205, 214), width=int(R(10)))
        d.line([P(564, y + 35), P(834, y - 5)], fill=(200, 205, 214), width=int(R(10)))
    # どんぐり帽の主人公（顔だけ）
    d.ellipse([P(300, 360), P(724, 710)], fill=(251, 239, 220), outline=INK, width=lw)
    d.line([P(512, 300), P(540, 245)], fill=INK, width=int(R(28)))
    d.chord([P(262, 280), P(762, 640)], 180, 360, fill=(110, 70, 48), outline=INK, width=lw)
    d.line([P(266, 460), P(758, 460)], fill=INK, width=lw)
    d.ellipse([P(330, 330), P(400, 370)], fill=(150, 100, 72))
    d.ellipse([P(420, 500), P(462, 560)], fill=INK)
    d.ellipse([P(562, 500), P(604, 560)], fill=INK)
    d.ellipse([P(360, 560), P(420, 600)], fill=(245, 170, 165))
    d.ellipse([P(604, 560), P(664, 600)], fill=(245, 170, 165))
    # 羽根（Light＝軽い）
    # 羽根：葉の形を描いて、ななめに置く
    leaf = Image.new('RGBA', (int(R(150)), int(R(380))), (0, 0, 0, 0))
    ld = ImageDraw.Draw(leaf)
    ld.ellipse([0, 0, R(150) - 1, R(330)], fill=(255, 214, 92), outline=INK, width=lw)
    ld.line([(R(75), R(30)), (R(75), R(380))], fill=INK, width=int(R(10)))
    for i in range(4):
        y = R(90 + i * 55)
        ld.line([(R(75), y + R(30)), (R(30), y)], fill=INK, width=int(R(6)))
        ld.line([(R(75), y + R(30)), (R(120), y)], fill=INK, width=int(R(6)))
    leaf = leaf.rotate(-28, expand=True, resample=Image.BICUBIC)
    x, y = P(790, 330)
    im.alpha_composite(leaf, (int(x - leaf.width / 2), int(y - leaf.height / 2)))
    return im

def text(im, scale=1.0):
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, int(150 * S * scale))
    t = 'Light'
    w = d.textlength(t, font=f)
    x, y = N / 2 - w / 2, N / 2 + (40 - 512) * S * scale
    d.text((x, y), t, font=f, fill=(255, 255, 255), stroke_width=int(12 * S * scale), stroke_fill=INK)
    return im

full = bg(N).convert('RGBA')
full.alpha_composite(text(art(0.92), 0.92))
full = full.convert('RGB').resize((1024, 1024), Image.LANCZOS)
full.save('light_1024.png')
# アダプティブ・マスカブル用：安全域（中心66%）に入れる
fg = text(art(0.62), 0.62).resize((1024, 1024), Image.LANCZOS)
fg.save('light_fg_1024.png')
mask = bg(1024).convert('RGBA'); mask.alpha_composite(fg); mask.convert('RGB').save('light_maskable_1024.png')
