from synth import *

sizes = {}
def out(name, x, **kw):
    p, sz = write(name, x, **kw)
    sizes[name] = sz

def arps(tr, chords, pattern, octave_shift, inst, gain, beats_per_chord=4, step=0.5, dur=None):
    """和音を分散和音で弾く。pattern は和音の構成音の番号（-1 は休み）"""
    for ci, ch in enumerate(chords):
        base = ci * beats_per_chord
        for k, idx in enumerate(pattern):
            pos = base + k * step
            if pos >= base + beats_per_chord or idx < 0:
                continue
            notes = ch + [x + 12 for x in ch]
            f = midi(notes[idx % len(notes)] + octave_shift)
            tr.at(pos, inst(f, dur or step * tr.beat * 1.2), gain)

def melody(tr, notes, inst, gain=1.0, offset=0):
    """notes: [(拍, 音名, 長さ拍), ...]"""
    for pos, name, d in notes:
        if name is None:
            continue
        tr.at(offset + pos, inst(midi(n(name)), d * tr.beat), gain)

def drums(tr, bars, kick_beats, snare_beats, hat_step, hat_gain=1.0, open_hat=False):
    for b in range(bars):
        for k in kick_beats:
            tr.at(b * 4 + k, kick())
        for s in snare_beats:
            tr.at(b * 4 + s, snare())
        if hat_step:
            x = 0.0
            while x < 4:
                tr.at(b * 4 + x, hat(open_=open_hat and abs(x % 1 - 0.5) < 1e-6), hat_gain)
                x += hat_step

def basses(tr, roots, pattern, kind='round', gain=1.0, beats_per_chord=4):
    """pattern: [(拍, オクターブのずれ, 長さ拍), ...]"""
    for ci, r in enumerate(roots):
        for pos, octv, d in pattern:
            tr.at(ci * beats_per_chord + pos, bass(midi(r + 12 * octv), d * tr.beat, kind), gain)

# ================================================================ BGM

# ---- ホーム：C 長調・ピアノの分散和音とパッド
C4, A3, F3, G3 = n('C4'), n('A3'), n('F3'), n('G3')
prog = [chord(C4), chord(A3, 'min'), chord(F3), chord(G3)] * 2
tr = Track(96, 8)
arps(tr, prog, [0, 1, 2, 3, 2, 1, 0, 2], 0, piano, 0.9)
for i, ch in enumerate(prog):
    tr.at(i * 4, pad([midi(x) for x in ch], 4 * tr.beat), 1.0)
basses(tr, [c[0] - 12 for c in prog], [(0, 0, 2), (2, 0, 2)], gain=0.7)
melody(tr, [(16, 'E5', 1), (17, 'G5', 1), (18, 'A5', 2), (20, 'G5', 1), (21, 'E5', 1), (22, 'C5', 2),
            (24, 'D5', 1), (25, 'E5', 1), (26, 'F5', 2), (28, 'E5', 2), (30, 'D5', 2)], bell, 0.6)
out('bgm_home', tr.loop(), loop=True)

# ---- 国語：ピアノと弦、温かい（F 長調・ゆっくり）
F3, D3, Bb2, C3 = n('F3'), n('D3'), n('Bb2'), n('C3')
prog = [chord(F3), chord(D3, 'min'), chord(Bb2), chord(C3)] * 2
tr = Track(80, 8)
arps(tr, prog, [0, 2, 4, 2, 3, 2, 4, 2], 12, piano, 0.8)
for i, ch in enumerate(prog):
    tr.at(i * 4, strings([midi(x + 12) for x in ch], 4 * tr.beat), 1.3)
basses(tr, [c[0] - 12 for c in prog], [(0, 0, 4)], gain=0.6)
melody(tr, [(0, 'A5', 2), (2, 'C6', 2), (4, 'A5', 1.5), (5.5, 'G5', 0.5), (6, 'F5', 2), (8, 'G5', 3), (11, 'F5', 1),
            (12, 'E5', 2), (14, 'G5', 2), (16, 'A5', 2), (18, 'Bb5', 2), (20, 'A5', 2), (22, 'F5', 2),
            (24, 'G5', 1.5), (25.5, 'A5', 0.5), (26, 'G5', 2), (28, 'F5', 4)], piano, 0.7)
out('bgm_field_japanese', tr.loop(), loop=True)

# ---- 数学：電子的なアルペジオ、規則的（A 短調）
A2, D3, E3 = n('A2'), n('D3'), n('E3')
prog = [chord(A2, 'min'), chord(D3, 'min'), chord(F3), chord(E3)] * 2
tr = Track(112, 8)
arps(tr, prog, [0, 1, 2, 3, 4, 3, 2, 1], 12, epiano, 0.9, step=0.25)
basses(tr, [c[0] - 12 for c in prog], [(0, 0, 0.5), (1, 0, 0.5), (1.5, 1, 0.5), (2, 0, 0.5), (3, 0, 0.5), (3.5, 1, 0.5)], kind='synth', gain=0.8)
drums(tr, 8, [0, 2], [], 0.5, 0.7)
for b in range(8):
    tr.at(b * 4 + 3, clap(), 0.5)
melody(tr, [(16, 'E5', 1), (17, 'A5', 1), (18, 'C6', 1), (19, 'B5', 1), (20, 'A5', 2), (24, 'G5', 1), (25, 'F5', 1), (26, 'E5', 1), (27, 'D5', 1), (28, 'E5', 4)],
       lambda f, d: lead(f, d, 'square'), 0.6)
out('bgm_field_math', tr.loop(), loop=True)

# ---- 英語：軽快なプラック（D 長調）
D3, A2, B2, G2 = n('D3'), n('A2'), n('B2'), n('G2')
prog = [chord(D3), chord(A2), chord(B2, 'min'), chord(G2)] * 2
tr = Track(120, 8)
arps(tr, prog, [-1, 2, -1, 3, -1, 4, -1, 3], 12, pluck, 1.0)
basses(tr, [c[0] - 12 for c in prog], [(0, 0, 0.75), (1.5, 0, 0.5), (2, 1, 0.5), (3, 0, 0.75)], gain=0.8)
drums(tr, 8, [0, 2.5], [], 0.5, 0.6)
for b in range(8):
    tr.at(b * 4 + 1, clap(), 0.8)
    tr.at(b * 4 + 3, clap(), 0.8)
melody(tr, [(0, 'F#5', 1), (1, 'A5', 1), (2, 'B5', 1.5), (3.5, 'A5', 0.5), (4, 'E5', 2), (6, 'C#5', 2),
            (8, 'D5', 1), (9, 'F#5', 1), (10, 'B5', 2), (12, 'A5', 1), (13, 'G5', 1), (14, 'F#5', 2)], pluck, 0.9, offset=16)
out('bgm_field_english', tr.loop(), loop=True)

# ---- 理科：透明なベルと空間的なパッド（E 短調）
E3, C3, G3, D3 = n('E3'), n('C3'), n('G3'), n('D3')
prog = [chord(E3, 'min'), chord(C3, 'maj7'), chord(G3), chord(D3)] * 2
tr = Track(88, 8)
for i, ch in enumerate(prog):
    tr.at(i * 4, pad([midi(x + 12) for x in ch], 4 * tr.beat), 1.4)
arps(tr, prog, [0, -1, 2, -1, 4, -1, 3, 5], 24, bell, 0.8)
basses(tr, [c[0] - 12 for c in prog], [(0, 0, 4)], gain=0.5)
out('bgm_field_science', tr.loop(), loop=True)

# ---- 社会：五音音階の旋律と太鼓（D 短調）
D3 = n('D3')
tr = Track(92, 8)
for b in range(8):
    tr.at(b * 4, taiko(), 0.9)
    tr.at(b * 4 + 2.5, taiko(), 0.6)
    tr.at(b * 4 + 3, taiko(), 0.5)
    tr.at(b * 4, strings([midi(D3), midi(D3 + 7), midi(D3 + 12)], 4 * tr.beat), 1.1)
penta = ['D5', 'F5', 'G5', 'A5', 'C6', 'D6']
mel = [(0, 'A5', 1.5), (1.5, 'G5', 0.5), (2, 'F5', 1), (3, 'D5', 1), (4, 'F5', 2), (6, 'G5', 2),
       (8, 'A5', 1), (9, 'C6', 1), (10, 'D6', 2), (12, 'C6', 1), (13, 'A5', 1), (14, 'G5', 2),
       (16, 'F5', 1.5), (17.5, 'G5', 0.5), (18, 'A5', 2), (20, 'G5', 1), (21, 'F5', 1), (22, 'D5', 2),
       (24, 'F5', 1), (25, 'G5', 1), (26, 'A5', 1), (27, 'G5', 1), (28, 'D5', 4)]
melody(tr, mel, flute, 0.9)
for b in range(8):
    for k, nm in enumerate(['D4', 'A4', 'D5', 'A4']):
        tr.at(b * 4 + k, pluck(midi(n(nm)), tr.beat), 0.4)
out('bgm_field_social', tr.loop(), loop=True)

# ---- 情報：シンセとビート（G 短調）
G2, Eb2, Bb2, F2 = n('G2'), n('Eb2'), n('Bb2'), n('F2')
prog = [chord(G2, 'min'), chord(Eb2), chord(Bb2), chord(F2)] * 2
tr = Track(124, 8)
drums(tr, 8, [0, 1, 2, 3], [], 0.5, 0.0)
for b in range(8):
    for k in range(4):
        tr.at(b * 4 + k + 0.5, hat(), 1.0)
    tr.at(b * 4 + 1, clap(), 0.6)
    tr.at(b * 4 + 3, clap(), 0.6)
basses(tr, [c[0] for c in prog], [(i * 0.5, 0 if i % 2 == 0 else 1, 0.45) for i in range(8)], kind='synth', gain=0.9)
arps(tr, prog, [0, 1, 2, 4, 2, 1, 3, 5, 0, 1, 2, 4, 2, 1, 3, 5], 24, lambda f, d: lead(f, d, 'square'), 0.35, step=0.25)
out('bgm_field_information', tr.loop(), loop=True)

# ---- 通常バトル：4 パート（ピアノ・ベース・打楽器・ストリングス）
A3, F3, C4, G3 = n('A3'), n('F3'), n('C4'), n('G3')
prog = [chord(A3, 'min'), chord(F3), chord(C4), chord(G3)] * 2
BPM, BARS = 132, 8
# ピアノ：和音の刻みと旋律
tr = Track(BPM, BARS)
for i, ch in enumerate(prog):
    for k in (0, 1.5, 2, 3.5):
        for x in ch:
            tr.at(i * 4 + k, piano(midi(x), 0.4 * tr.beat), 0.55)
melody(tr, [(0, 'E5', 1), (1, 'A5', 1), (2, 'C6', 1.5), (3.5, 'B5', 0.5), (4, 'A5', 1), (5, 'F5', 1), (6, 'A5', 2),
            (8, 'G5', 1), (9, 'C6', 1), (10, 'E6', 1.5), (11.5, 'D6', 0.5), (12, 'B5', 2), (14, 'G5', 2),
            (16, 'A5', 0.5), (16.5, 'B5', 0.5), (17, 'C6', 1), (18, 'E6', 2), (20, 'D6', 1), (21, 'C6', 1), (22, 'A5', 2),
            (24, 'G5', 1), (25, 'A5', 1), (26, 'B5', 1), (27, 'D6', 1), (28, 'E6', 4)], piano, 1.0)
battle_len = tr.N
out('bgm_battle_piano', tr.loop(), loop=True)
tr = Track(BPM, BARS)
basses(tr, [c[0] - 24 for c in prog], [(i * 0.5, 1 if i in (3, 7) else 0, 0.45) for i in range(8)], kind='synth', gain=1.0)
out('bgm_battle_bass', tr.loop(), loop=True)
tr = Track(BPM, BARS)
drums(tr, BARS, [0, 2, 2.5], [1, 3], 0.5, 1.0)
out('bgm_battle_drums', tr.loop(), loop=True)
tr = Track(BPM, BARS)
for i, ch in enumerate(prog):
    tr.at(i * 4, strings([midi(x + 12) for x in ch], 4 * tr.beat), 1.3)
melody(tr, [(0, 'C5', 4), (4, 'A4', 4), (8, 'G4', 4), (12, 'B4', 4), (16, 'C5', 2), (18, 'E5', 2), (20, 'F5', 4), (24, 'E5', 2), (26, 'D5', 2), (28, 'B4', 4)],
       lambda f, d: strings([f], d), 2.0)
out('bgm_battle_strings', tr.loop(), loop=True)

# ---- ボス戦：4 パート（D 短調・速い）
D3, Bb2, G2, A2 = n('D3'), n('Bb2'), n('G2'), n('A2')
prog = [chord(D3, 'min'), chord(Bb2), chord(G2, 'min'), chord(A2)] * 2
BPM = 150
tr = Track(BPM, BARS)
for i, ch in enumerate(prog):
    for k in range(8):
        tr.at(i * 4 + k * 0.5, piano(midi(ch[k % 3] + 12), 0.45 * tr.beat), 0.5)
melody(tr, [(0, 'D5', 1), (1, 'F5', 1), (2, 'A5', 2), (4, 'Bb5', 1), (5, 'A5', 1), (6, 'F5', 2),
            (8, 'G5', 1), (9, 'Bb5', 1), (10, 'D6', 2), (12, 'C#6', 2), (14, 'A5', 2),
            (16, 'D6', 1), (17, 'C6', 1), (18, 'Bb5', 1), (19, 'A5', 1), (20, 'G5', 2), (22, 'F5', 2),
            (24, 'E5', 1), (25, 'F5', 1), (26, 'G5', 1), (27, 'A5', 1), (28, 'C#6', 2), (30, 'D6', 2)], piano, 1.0)
out('bgm_boss_piano', tr.loop(), loop=True)
tr = Track(BPM, BARS)
basses(tr, [c[0] - 12 for c in prog], [(i * 0.5, 0, 0.4) for i in range(8)], kind='synth', gain=1.0)
out('bgm_boss_bass', tr.loop(), loop=True)
tr = Track(BPM, BARS)
drums(tr, BARS, [0, 1, 2, 3], [1, 3], 0.25, 0.8)
for b in range(BARS):
    tr.at(b * 4, taiko(), 0.7)
out('bgm_boss_drums', tr.loop(), loop=True)
tr = Track(BPM, BARS)
for i, ch in enumerate(prog):
    for k in range(2):
        tr.at(i * 4 + k * 2, strings([midi(x + 12) for x in ch], 2 * tr.beat), 1.3)
melody(tr, [(0, 'A4', 4), (4, 'Bb4', 4), (8, 'D5', 4), (12, 'C#5', 4), (16, 'F5', 4), (20, 'D5', 4), (24, 'Bb4', 4), (28, 'A4', 4)],
       lambda f, d: strings([f], d), 2.0)
out('bgm_boss_strings', tr.loop(), loop=True)

# ================================================================ ジングル

def jingle(bpm, events, beats):
    tr = Track(bpm, 1, beats=beats)
    for pos, sound, g in events:
        tr.at(pos, sound, g)
    return tr.buf[: tr.N + int(0.8 * SR)]

b = 60 / 140
out('jingle_victory', jingle(140, [
    (0, piano(midi(n('G4')), b * 0.5), 1), (0.5, piano(midi(n('C5')), b * 0.5), 1), (1, piano(midi(n('E5')), b * 0.5), 1),
    (1.5, piano(midi(n('G5')), b * 2.5), 1.1), (1.5, strings([midi(n('C4')), midi(n('E4')), midi(n('G4')), midi(n('C5'))], b * 2.5), 2.2),
    (1.5, bell(midi(n('C6')), b), 0.7)], 5))
out('jingle_defeat', jingle(90, [
    (0, piano(midi(n('E5')), 0.6), 1), (1, piano(midi(n('C5')), 0.6), 1), (2, piano(midi(n('A4')), 1.4), 1),
    (2, strings([midi(n('A3')), midi(n('C4')), midi(n('E4'))], 1.4), 2.0)], 4))
out('jingle_levelup', jingle(180, [
    (i * 0.25, bell(midi(n(x)), 0.3), 0.9) for i, x in enumerate(['C5', 'E5', 'G5', 'C6', 'E6', 'G6'])] + [
    (1.5, strings([midi(n('C5')), midi(n('E5')), midi(n('G5'))], 1.0), 2.0)], 4))
out('jingle_clear', jingle(160, [
    (0, pluck(midi(n('C5')), 0.3), 1), (0.5, pluck(midi(n('E5')), 0.3), 1), (1, pluck(midi(n('G5')), 0.3), 1),
    (1.5, bell(midi(n('C6')), 0.8), 1), (1.5, piano(midi(n('C5')), 0.8), 0.8)], 3))

# ================================================================ SE

def se(name, x, peak=0.8):
    out(name, x, peak=peak, kbps=48)

t = t_axis
def sweep(f0, f1, dur, wave=np.sin):
    tt = t(dur)
    f = f0 * (f1 / f0) ** (tt / dur)
    return wave(2 * np.pi * np.cumsum(f) / SR)

def noise(dur):
    return rng.normal(0, 1, int(dur * SR))

def fade(x, a=0.002):
    na = int(a * SR)
    x = x.copy()
    x[:na] *= np.linspace(0, 1, na)
    x[-na:] *= np.linspace(1, 0, na)
    return x

se('se_tap', fade(sweep(1200, 1500, 0.05) * np.exp(-t(0.05) * 60)))
se('se_cancel', fade(sweep(700, 450, 0.09) * np.exp(-t(0.09) * 30)))
se('se_correct', np.concatenate([bell(midi(n('E6')), 0.08)[: int(0.08 * SR)], bell(midi(n('B6')), 0.4)]))
se('se_wrong', fade(square(140, t(0.28), 5) * np.exp(-t(0.28) * 8) * 0.6 + square(133, t(0.28), 5) * np.exp(-t(0.28) * 8) * 0.4))
hit = noise(0.18)
hit = hit - lp_fast(hit, 1800)
se('se_attack', fade(hit * np.exp(-t(0.18) * 22) + sweep(900, 200, 0.18) * np.exp(-t(0.18) * 20) * 0.5))
se('se_critical', fade(hit * np.exp(-t(0.18) * 22) * 0.8 + bell(midi(n('A6')), 0.3)[: int(0.18 * SR)] * 0.6))
se('se_damage', fade(kick(0.3) * 0.9 + noise(0.3) * np.exp(-t(0.3) * 25) * 0.25))
se('se_heal', np.concatenate([bell(midi(n(x)), 0.06)[: int(0.06 * SR)] for x in ['C6', 'E6', 'G6']] + [bell(midi(n('C7')), 0.4)]))
se('se_chest', np.concatenate([pluck(midi(n(x)), 0.08)[: int(0.08 * SR)] for x in ['G5', 'C6', 'E6']] + [bell(midi(n('G6')), 0.6)]))
se('se_page', fade(lp_fast(noise(0.22), 3000) * np.sin(np.linspace(0, np.pi, int(0.22 * SR))) * 0.8))
se('se_achievement', sum(bell(midi(n(x)), 0.9) for x in ['C6', 'E6', 'G6']) / 2)
boss_hit = taiko(1.2) + sweep(60, 220, 1.2) * np.exp(-t(1.2) * 1.5) * 0.4
se('se_boss_appear', fade(boss_hit), peak=0.9)
se('se_boss_defeat', fade(taiko(1.0) * 0.8 + sum(bell(midi(n(x)), 0.8)[: int(1.0 * SR)] for x in ['D5', 'F#5', 'A5']) * 0.5))

# 敵の種族ごとの SE
se('se_rub', fade(lp_fast(noise(0.25), 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 28 * t(0.25))) * np.exp(-t(0.25) * 6)))
se('se_scribble', fade(lp_fast(noise(0.3), 2500) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 14 * t(0.3)))) * np.exp(-t(0.3) * 5)))
se('se_flap', fade(np.concatenate([lp_fast(noise(0.06), 1200) * np.exp(-t(0.06) * 40)] * 3)))
se('se_scratch', fade((noise(0.2) - lp_fast(noise(0.2), 2000)) * np.exp(-t(0.2) * 14)))
click = np.zeros(int(0.08 * SR)); click[:120] = rng.normal(0, 1, 120) * np.exp(-np.arange(120) / 20)
se('se_click', fade(click + sweep(3000, 2000, 0.08) * np.exp(-t(0.08) * 80) * 0.5))
se('se_magic', sum(sweep(midi(n(x)), midi(n(x)) * 1.5, 0.45) * np.exp(-t(0.45) * 4) for x in ['C6', 'E6']) * 0.5)
se('se_slash', fade(sweep(2500, 600, 0.16, lambda p: np.sin(p)) * 0.3 + (noise(0.16) - lp_fast(noise(0.16), 3000)) * np.exp(-t(0.16) * 18)))
se('se_block', fade(sum(np.sin(2 * np.pi * f * t(0.25)) for f in [520, 780, 1300]) * np.exp(-t(0.25) * 18) * 0.4))
st = np.zeros(int(0.12 * SR)); st[:200] = rng.normal(0, 1, 200) * np.exp(-np.arange(200) / 30)
se('se_staple', fade(st + np.sin(2 * np.pi * 1800 * t(0.12)) * np.exp(-t(0.12) * 60) * 0.4))
se('se_snip', fade(np.concatenate([(noise(0.05) - lp_fast(noise(0.05), 3000)) * np.exp(-t(0.05) * 50), np.zeros(1500), (noise(0.05) - lp_fast(noise(0.05), 3000)) * np.exp(-t(0.05) * 50)])))
se('se_snap', fade(kick(0.15) * 0.4 + np.sin(2 * np.pi * 900 * t(0.15)) * np.exp(-t(0.15) * 45) * 0.6))
se('se_ghost', fade(sweep(500, 300, 0.7) * (0.6 + 0.4 * np.sin(2 * np.pi * 6 * t(0.7))) * env(0.7, 0.15, 0.1, 0.8, 0.3) * 0.6))
se('se_squish', fade(sweep(300, 90, 0.25) * np.exp(-t(0.25) * 10)))
se('se_thud', fade(kick(0.4) + lp_fast(noise(0.4), 300) * np.exp(-t(0.4) * 12) * 0.5))
se('se_roar', fade(lp_fast(noise(0.9), 700) * env(0.9, 0.08, 0.2, 0.7, 0.3) + sweep(110, 70, 0.9, lambda p: np.sign(np.sin(p))) * env(0.9, 0.08, 0.2, 0.6, 0.3) * 0.3))

total = sum(sizes.values())
print(len(sizes), 'files', round(total / 1024), 'KB')
for k, v in sorted(sizes.items()):
    print(f'  {k}: {v // 1024} KB')
