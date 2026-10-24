"""つづりクエストの BGM・SE をプログラムで合成して MP3 に書き出す。

すべての音を同じ合成器・同じミックス方針で作ることで、音の世界観をそろえる。
外部の音源素材は使っていない。
"""
import os
import numpy as np
import lameenc

SR = 22050
OUT = '/home/user/ToDoList.App/rpg_game_app/assets/audio'
rng = np.random.default_rng(7)

# ---------------------------------------------------------------- 基本

def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)

NOTE = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4, 'F': 5,
        'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11}

def n(name):
    """'C4' → MIDI 番号"""
    if name[1] in '#b':
        p, o = name[:2], int(name[2:])
    else:
        p, o = name[:1], int(name[1:])
    return 12 * (o + 1) + NOTE[p]

def t_axis(dur):
    return np.arange(int(dur * SR)) / SR

def env(length, a=0.005, d=0.1, s=0.6, r=0.1, total=None):
    """ADSR（length 秒の音。最後に r 秒で消える）"""
    N = int(length * SR)
    e = np.ones(N) * s
    na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    if na > 0:
        e[:min(na, N)] = np.linspace(0, 1, na)[:min(na, N)]
    if nd > 0 and na < N:
        seg = min(nd, N - na)
        e[na:na + seg] = np.linspace(1, s, nd)[:seg]
    if nr > 0:
        nr = min(nr, N)
        e[-nr:] *= np.linspace(1, 0, nr)
    return e

def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):  # 短い音にだけ使う
        acc = (1 - a) * x[i] + a * acc
        y[i] = acc
    return y

def lp_fast(x, cutoff):
    """長い音向けの簡易ローパス（移動平均を2回）"""
    k = max(1, int(SR / cutoff / 2))
    ker = np.ones(k) / k
    return np.convolve(np.convolve(x, ker, 'same'), ker, 'same')

# ---------------------------------------------------------------- 楽器

def piano(f, dur):
    t = t_axis(dur + 0.6)
    tone = sum(np.sin(2 * np.pi * f * h * t) * (0.6 ** (h - 1)) * np.exp(-t * (1.5 + h * 0.9)) for h in range(1, 6))
    tone += 0.15 * np.sin(2 * np.pi * f * 2.001 * t) * np.exp(-t * 4)
    e = np.minimum(1, t / 0.004)
    rel = np.where(t > dur, np.exp(-(t - dur) * 12), 1.0)
    return tone * e * rel * 0.35

def epiano(f, dur):
    t = t_axis(dur + 0.4)
    mod = np.sin(2 * np.pi * f * t) * 1.2 * np.exp(-t * 3)
    tone = np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 2.5)
    rel = np.where(t > dur, np.exp(-(t - dur) * 10), 1.0)
    return tone * np.minimum(1, t / 0.003) * rel * 0.3

def pluck(f, dur):
    """カープラス＝ストロング（はじく弦）"""
    N = int((dur + 0.3) * SR)
    period = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, period)
    out = np.empty(N)
    for i in range(N):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.996
    return out * 0.35

def bell(f, dur):
    t = t_axis(dur + 1.2)
    mod = np.sin(2 * np.pi * f * 3.5 * t) * 2.0 * np.exp(-t * 2)
    tone = np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 1.6)
    return tone * np.minimum(1, t / 0.002) * 0.25

def saw(f, t, harmonics=12):
    return sum(np.sin(2 * np.pi * f * h * t) / h for h in range(1, harmonics + 1)) * 0.6

def square(f, t, harmonics=9):
    return sum(np.sin(2 * np.pi * f * h * t) / h for h in range(1, harmonics + 1, 2)) * 0.8

def lead(f, dur, kind='square'):
    t = t_axis(dur)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / 0.3)
    wave = square(f, t * vib, 7) if kind == 'square' else saw(f, t * vib, 8)
    return wave * env(dur, 0.01, 0.08, 0.7, 0.05) * 0.22

def pad(fs, dur):
    t = t_axis(dur)
    tone = np.zeros_like(t)
    for f in fs:
        for det in (-0.004, 0.0, 0.005):
            tone += saw(f * (1 + det), t, 6)
    tone = lp_fast(tone, 1800)
    return tone * env(dur, min(0.4, dur / 3), 0.2, 0.8, min(0.4, dur / 3)) * 0.05

def strings(fs, dur):
    t = t_axis(dur)
    tone = np.zeros_like(t)
    for f in fs:
        vib = 1 + 0.003 * np.sin(2 * np.pi * 5.2 * t + f)
        for det in (-0.003, 0.004):
            tone += saw(f * (1 + det), t * vib, 8)
    tone = lp_fast(tone, 2600)
    return tone * env(dur, min(0.25, dur / 3), 0.1, 0.85, min(0.25, dur / 3)) * 0.05

def flute(f, dur):
    t = t_axis(dur)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5 * t) * np.minimum(1, t / 0.25)
    tone = np.sin(2 * np.pi * f * t * vib) + 0.2 * np.sin(4 * np.pi * f * t * vib)
    breath = rng.normal(0, 0.03, len(t))
    return (tone + breath) * env(dur, 0.06, 0.1, 0.8, 0.08) * 0.22

def bass(f, dur, kind='round'):
    t = t_axis(dur)
    if kind == 'synth':
        tone = saw(f, t, 10)
        tone = lp_fast(tone, 900)
    else:
        tone = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)
    return tone * env(dur, 0.005, 0.1, 0.8, 0.04) * 0.35

def kick(dur=0.35):
    t = t_axis(dur)
    f = 50 + 110 * np.exp(-t * 30)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 9) * 0.9

def snare(dur=0.22):
    t = t_axis(dur)
    noise = rng.normal(0, 1, len(t))
    noise = noise - lp_fast(noise, 1500)
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25)
    return (noise * np.exp(-t * 18) * 0.35 + tone * 0.4) * 0.8

def hat(dur=0.06, open_=False):
    t = t_axis(0.25 if open_ else dur)
    noise = rng.normal(0, 1, len(t))
    noise = noise - lp_fast(noise, 6000)
    return noise * np.exp(-t * (10 if open_ else 60)) * 0.18

def clap(dur=0.2):
    t = t_axis(dur)
    noise = rng.normal(0, 1, len(t))
    noise = noise - lp_fast(noise, 1200)
    e = np.exp(-t * 20) + 0.6 * np.exp(-np.maximum(0, t - 0.012) * 30) * (t > 0.012)
    return noise * e * 0.25

def taiko(dur=0.6):
    t = t_axis(dur)
    f = 70 + 40 * np.exp(-t * 12)
    ph = 2 * np.pi * np.cumsum(f) / SR
    thump = np.sin(ph) * np.exp(-t * 6)
    skin = rng.normal(0, 1, len(t)) * np.exp(-t * 40) * 0.2
    return (thump + skin) * 0.8

# ---------------------------------------------------------------- 配置と書き出し

class Track:
    def __init__(self, bpm, bars, beats=4):
        self.bpm = bpm
        self.beat = 60 / bpm
        self.length = bars * beats * self.beat
        self.N = int(self.length * SR)
        self.buf = np.zeros(self.N + SR * 3)

    def at(self, beat_pos, sound, gain=1.0):
        i = int(beat_pos * self.beat * SR)
        self.buf[i:i + len(sound)] += sound[: max(0, len(self.buf) - i)] * gain

    def loop(self):
        """はみ出した余韻を頭に重ねて、つなぎ目なくループできるようにする"""
        out = self.buf[: self.N].copy()
        tail = self.buf[self.N:]
        k = min(len(tail), self.N)
        out[:k] += tail[:k]
        return out

def normalize(x, peak=0.85):
    m = np.max(np.abs(x)) or 1
    return x * (peak / m)

def write(name, x, loop=False, peak=0.85, kbps=64):
    os.makedirs(OUT, exist_ok=True)
    x = normalize(x, peak)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes()
    enc = lameenc.Encoder()
    enc.set_bit_rate(kbps)
    enc.set_in_sample_rate(SR)
    enc.set_channels(1)
    enc.set_quality(2)
    data = enc.encode(pcm) + enc.flush()
    path = f'{OUT}/{name}.mp3'
    with open(path, 'wb') as f:
        f.write(data)
    return path, len(data)

def chord(root, kind='maj'):
    iv = {'maj': [0, 4, 7], 'min': [0, 3, 7], 'sus': [0, 5, 7], 'maj7': [0, 4, 7, 11],
          'min7': [0, 3, 7, 10], 'dom7': [0, 4, 7, 10], 'dim': [0, 3, 6]}[kind]
    return [root + i for i in iv]
