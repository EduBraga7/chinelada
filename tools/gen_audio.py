"""Gera todos os efeitos sonoros e as músicas do jogo por síntese (numpy) — sem samples de terceiros.

Uso (Python embutido do Blender, que já traz numpy):
    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python tools/gen_audio.py -- audio

Escreve audio/sfx/*.wav (44,1 kHz mono) e audio/music/*.wav (32 kHz mono, loops perfeitos) e imprime
pico/RMS/duração e a diferença na emenda de cada loop (para conferir sem precisar ouvir).
"""
import os
import sys
import wave

import numpy as np

SR = 44100
MSR = 32000
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "audio"
rng = np.random.default_rng(20261102)


# --------------------------------------------------------------------------- utilidades

def tarr(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def decay(n, tau, sr=SR):
    return np.exp(-np.arange(n) / (tau * sr))


def sine(f, dur, sr=SR):
    return np.sin(2 * np.pi * f * tarr(dur, sr))


def sweep(f0, f1, dur, sr=SR):
    n = int(dur * sr)
    f = f0 * (f1 / f0) ** (np.arange(n) / max(n - 1, 1))
    return np.sin(2 * np.pi * np.cumsum(f) / sr)


def saw(f, dur, sr=SR, k=24):
    t = tarr(dur, sr)
    out = np.zeros_like(t)
    for h in range(1, k + 1):
        if f * h > sr * 0.45:
            break
        out += np.sin(2 * np.pi * f * h * t) / h
    return out * (2 / np.pi)


def square(f, dur, sr=SR, k=15):
    t = tarr(dur, sr)
    out = np.zeros_like(t)
    for h in range(1, k * 2, 2):
        if f * h > sr * 0.45:
            break
        out += np.sin(2 * np.pi * f * h * t) / h
    return out * (4 / np.pi) * 0.5


def noise(dur, sr=SR):
    return rng.uniform(-1.0, 1.0, int(dur * sr))


def fft_filter(x, kind, f1, f2=None, sr=SR, order=4):
    spec = np.fft.rfft(x)
    fr = np.fft.rfftfreq(len(x), 1.0 / sr)
    if kind == "lp":
        h = 1.0 / (1.0 + (fr / f1) ** order)
    elif kind == "hp":
        h = 1.0 / (1.0 + (f1 / np.maximum(fr, 1e-6)) ** order)
    else:  # bp
        h = (1.0 / (1.0 + (fr / f2) ** order)) * (1.0 / (1.0 + (f1 / np.maximum(fr, 1e-6)) ** order))
    return np.fft.irfft(spec * h, len(x))


def fades(x, a=0.002, r=0.01, sr=SR):
    x = x.copy()
    na, nr = int(a * sr), int(r * sr)
    if na > 0:
        x[:na] *= np.linspace(0, 1, na)
    if nr > 0:
        x[-nr:] *= np.linspace(1, 0, nr)
    return x


def mix(*parts, length=None):
    n = max(len(p[1]) + int(p[0] * SR) for p in parts) if length is None else int(length * SR)
    out = np.zeros(n)
    for start, x, gain in parts:
        i = int(start * SR)
        m = min(len(x), n - i)
        out[i:i + m] += x[:m] * gain
    return out


def normalize(x, peak=0.9):
    m = np.max(np.abs(x))
    return x if m < 1e-9 else x * (peak / m)


def softclip(x):
    return np.tanh(x * 1.1) / np.tanh(1.1)


def write_wav(path, x, sr):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = (np.clip(x, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def midi_f(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


NOTES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def nf(name):
    """'E5' -> Hz, 'F#4' -> Hz"""
    n = NOTES[name[0]]
    i = 1
    if name[1] == "#":
        n += 1
        i = 2
    elif name[1] == "b":
        n -= 1
        i = 2
    octv = int(name[i:])
    return midi_f(12 * (octv + 1) + n)


# --------------------------------------------------------------------------- instrumentos

def bell(f, dur=0.6, sr=SR, bright=1.0):
    t = tarr(dur, sr)
    return (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.35)
            + 0.5 * bright * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t / 0.15)
            + 0.25 * bright * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t / 0.07))


def marimba(f, dur=0.5, sr=SR):
    t = tarr(dur, sr)
    x = (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.22)
         + 0.45 * np.sin(2 * np.pi * f * 3.98 * t) * np.exp(-t / 0.05)
         + 0.12 * np.sin(2 * np.pi * f * 9.2 * t) * np.exp(-t / 0.025))
    x[:80] += (rng.uniform(-1, 1, 80) * np.linspace(0.25, 0, 80))
    return x


def brass(f, dur, sr=SR, vib=5.0):
    t = tarr(dur, sr)
    vf = f * (1 + 0.006 * np.sin(2 * np.pi * vib * t))
    ph = 2 * np.pi * np.cumsum(vf) / sr
    x = sum(np.sin(h * ph) / h for h in range(1, 14) if f * h < sr * 0.45)
    env = np.minimum(1, t / 0.03) * np.exp(-t / (dur * 1.2))
    return fft_filter(x * env, "lp", 2600, sr=sr)


def accordion(freqs, dur, sr=SR):
    t = tarr(dur, sr)
    out = np.zeros_like(t)
    for f in freqs:
        for det in (0.9965, 1.0, 1.0038):
            out += saw(f * det, dur, sr, k=10)
    env = np.minimum(1, t / 0.008) * np.exp(-t / (dur * 0.55))
    return fft_filter(out * env, "lp", 3200, sr=sr) * 0.28


def bass(f, dur, sr=SR):
    t = tarr(dur, sr)
    x = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t / 0.1) + 0.25 * np.sin(2 * np.pi * f * 3 * t) * np.exp(-t / 0.06)
    return x * np.exp(-t / (dur * 0.55)) * np.minimum(1, t / 0.004)


def kick(sr=SR, dur=0.2):
    n = int(dur * sr)
    return sweep(130, 42, dur, sr) * decay(n, 0.07, sr) * 1.1


def zab_hi(sr=SR):
    t = tarr(0.09, sr)
    return (np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.03) + 0.4 * fft_filter(noise(0.09, sr), "bp", 900, 3000, sr)) * np.exp(-t / 0.04)


def shaker(sr=SR, accent=1.0):
    x = fft_filter(noise(0.05, sr), "hp", 6000, sr=sr)
    return x * decay(len(x), 0.012, sr) * 0.5 * accent


def tri(sr=SR):
    t = tarr(0.25, sr)
    return (np.sin(2 * np.pi * 3150 * t) + 0.7 * np.sin(2 * np.pi * 4720 * t) + 0.4 * np.sin(2 * np.pi * 6980 * t)) * np.exp(-t / 0.07) * 0.18


def snare(sr=SR):
    t = tarr(0.16, sr)
    return (np.sin(2 * np.pi * 210 * t) * np.exp(-t / 0.04) * 0.5 + fft_filter(noise(0.16, sr), "hp", 1200, sr=sr) * np.exp(-t / 0.05)) * 0.8


# --------------------------------------------------------------------------- efeitos

def sfx_all():
    s = {}
    # golpe seco (tok de madeira) — pitch muda em runtime
    t = tarr(0.09)
    s["hit"] = fades((np.sin(2 * np.pi * 820 * t) * np.exp(-t / 0.018) + 0.5 * np.sin(2 * np.pi * 1640 * t) * np.exp(-t / 0.008) + noise(0.09) * np.exp(-t / 0.004) * 0.35), 0.0005, 0.01)
    # crítico: tok + ting brilhante + pancada grave
    s["crit"] = mix((0, s["hit"], 0.8), (0.0, bell(1568, 0.35, bright=1.4), 0.5), (0.0, sweep(180, 70, 0.14) * decay(int(0.14 * SR), 0.05), 0.7))
    # inimigo derrotado: "poof" + estalo
    n = int(0.22 * SR)
    puff = fft_filter(noise(0.22), "lp", 2500) * decay(n, 0.07)
    s["kill"] = fades(mix((0, puff, 0.8), (0, sweep(520, 140, 0.12) * decay(int(0.12 * SR), 0.04), 0.9), (0.02, bell(880, 0.18), 0.25)))
    # moeda
    s["coin"] = fades(mix((0, bell(1319, 0.12, bright=0.8), 0.7), (0.05, bell(1760, 0.25, bright=0.8), 0.8)))
    # melhorar: arpejo subindo
    s["upgrade"] = fades(mix((0.0, marimba(nf("C5"), 0.3), 0.8), (0.06, marimba(nf("E5"), 0.3), 0.8), (0.12, marimba(nf("G5"), 0.35), 0.9), (0.18, bell(nf("C6"), 0.4), 0.5)))
    # negado: buzina grave curta
    s["deny"] = fades(square(110, 0.16) * decay(int(0.16 * SR), 0.09) * 0.8 + square(104, 0.16) * decay(int(0.16 * SR), 0.09) * 0.6)
    # recrutar: fanfarra pequena
    s["recruit"] = fades(mix((0.0, brass(nf("C5"), 0.18), 0.7), (0.15, brass(nf("G5"), 0.18), 0.7), (0.30, brass(nf("C6"), 0.5), 0.9), (0.30, bell(nf("C6"), 0.5), 0.3)))
    # fúria: subida + estrondo
    up = sweep(120, 900, 0.7) * np.linspace(0.1, 1, int(0.7 * SR))
    boom = sweep(160, 38, 0.5) * decay(int(0.5 * SR), 0.18)
    rush = fft_filter(noise(0.7), "bp", 300, 5000) * np.linspace(0.05, 0.8, int(0.7 * SR))
    s["fury"] = fades(mix((0, up, 0.45), (0, rush, 0.55), (0.62, boom, 1.0), (0.62, noise(0.35) * decay(int(0.35 * SR), 0.1), 0.35)), 0.005, 0.05)
    # skill da Neide: vupt + TÁ!
    n = int(0.45 * SR)
    whoosh = fft_filter(noise(0.45), "bp", 400, 3500) * np.sin(np.linspace(0, np.pi, n)) ** 1.5
    slap = fft_filter(noise(0.12), "hp", 800) * decay(int(0.12 * SR), 0.03) + sweep(300, 90, 0.12) * decay(int(0.12 * SR), 0.04)
    s["skill_neide"] = fades(mix((0, whoosh, 0.7), (0.36, slap, 1.0), (0.36, bell(1100, 0.2), 0.3)))
    # cura: sininhos suaves
    s["heal"] = fades(mix((0.0, bell(nf("E5"), 0.5, bright=0.6), 0.6), (0.09, bell(nf("G5"), 0.5, bright=0.6), 0.6), (0.18, bell(nf("B5"), 0.7, bright=0.6), 0.7)))
    # troca de aba / clique
    t = tarr(0.04)
    s["tab"] = fades(np.sin(2 * np.pi * 640 * t) * np.exp(-t / 0.012) * 0.8, 0.0005, 0.005)
    # fanfarra de vitória
    s["fanfare"] = fades(mix(
        (0.00, brass(nf("C5"), 0.16), 0.8), (0.14, brass(nf("E5"), 0.16), 0.8), (0.28, brass(nf("G5"), 0.16), 0.8),
        (0.42, brass(nf("C6"), 0.75), 1.0), (0.42, brass(nf("E6"), 0.75), 0.5), (0.42, brass(nf("G5"), 0.75), 0.5),
        (0.42, bell(nf("C7"), 0.8), 0.3)), 0.002, 0.08)
    # derrota: "uóóó" descendente
    fail = mix(
        (0.0, brass(nf("G4"), 0.28, vib=6), 0.8), (0.3, brass(nf("F#4"), 0.28, vib=6), 0.8),
        (0.6, brass(nf("F4"), 0.28, vib=6), 0.8), (0.9, brass(nf("E4"), 0.7, vib=7), 0.9))
    s["fail"] = fades(fail, 0.005, 0.1)
    # chefão: rosnado grave
    n = int(0.9 * SR)
    t = tarr(0.9)
    f = 95 * (0.55 ** (t / 0.9)) * (1 + 0.25 * np.sin(2 * np.pi * 14 * t))
    growl = np.sin(2 * np.pi * np.cumsum(f) / SR)
    growl += 0.6 * np.sign(growl) * 0.3
    growl = fft_filter(growl, "lp", 900) * np.minimum(1, t / 0.05) * np.exp(-t / 0.7)
    s["boss_roar"] = fades(mix((0, growl, 0.9), (0, fft_filter(noise(0.9), "lp", 700) * np.exp(-t / 0.5), 0.35)), 0.01, 0.1)
    # marmita: brilhos subindo
    s["marmita"] = fades(mix(*[(0.045 * i, bell(nf("C6") * (1.122 ** (i % 7)), 0.3, bright=1.1), 0.5) for i in range(10)]))
    # bênção: acorde angelical
    ch = mix(*[(0.0, sine(nf(n), 1.2) * np.sin(np.linspace(0, np.pi, int(1.2 * SR))) ** 0.6, 0.35) for n in ["C5", "E5", "G5", "C6"]])
    s["bless"] = fades(mix((0, ch, 1.0), (0.1, bell(nf("G6"), 0.9, bright=0.7), 0.3)), 0.01, 0.2)
    # papagaio: "ráá!"
    n = int(0.36 * SR)
    t = tarr(0.36)
    f = 520 + 600 * np.sin(np.pi * t / 0.36) ** 1.5 + 90 * np.sin(2 * np.pi * 28 * t)
    sq = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.5 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    s["parrot"] = fades(fft_filter(sq, "bp", 400, 4200) * np.sin(np.linspace(0, np.pi, n)) ** 0.5, 0.01, 0.04)
    # uma nota alegre para boss_down etc. (reserva)
    s["pop"] = fades(sweep(300, 900, 0.08) * decay(int(0.08 * SR), 0.03))
    return s


# --------------------------------------------------------------------------- músicas

def add_wrap(buf, idx, x):
    n = len(buf)
    idx %= n
    end = idx + len(x)
    if end <= n:
        buf[idx:end] += x
    else:
        k = n - idx
        buf[idx:] += x[:k]
        rest = x[k:]
        buf[:len(rest)] += rest


def build_track(bpm, bars, chords, melody, kick_steps, hi_steps, tri_steps, stab_steps, bass_steps, snare_steps=(), swing=0.10, mel_gain=0.55, sr=MSR, drive=1.0):
    step = 60.0 / bpm / 4.0
    n = int(round(bars * 16 * step * sr))
    buf = np.zeros(n)
    kk, zz, sk, tt, sn = kick(sr), zab_hi(sr), shaker(sr), tri(sr), snare(sr)
    for b in range(bars):
        ch = chords[b % len(chords)]
        for st in range(16):
            tpos = (b * 16 + st) * step + (swing * step if st % 2 == 1 else 0.0)
            i = int(round(tpos * sr))
            if st in kick_steps:
                add_wrap(buf, i, kk * 0.9 * drive)
            if st in hi_steps:
                add_wrap(buf, i, zz * 0.5)
            if st in snare_steps:
                add_wrap(buf, i, sn * 0.55)
            if st in tri_steps:
                add_wrap(buf, i, tt)
            add_wrap(buf, i, sk * (1.0 if st % 4 else 0.6))
            if st in bass_steps:
                add_wrap(buf, i, bass(midi_f(ch["root"]), step * 3.2, sr) * 0.75)
            if st in stab_steps:
                add_wrap(buf, i, accordion([midi_f(m) for m in ch["chord"]], step * 2.2, sr) * 0.7)
    # melodia: lista de (passo_global, nome_da_nota, duração_em_passos)
    for gstep, name, dur in melody:
        tpos = gstep * step + (swing * step if gstep % 2 == 1 else 0.0)
        add_wrap(buf, int(round(tpos * sr)), marimba(nf(name), dur * step * 1.6, sr) * mel_gain)
    return buf


def music_main():
    # C – Am – F – G (2 compassos cada), baião leve
    ch = [
        {"root": 36, "chord": [60, 64, 67]}, {"root": 36, "chord": [60, 64, 67]},
        {"root": 33, "chord": [57, 60, 64]}, {"root": 33, "chord": [57, 60, 64]},
        {"root": 41, "chord": [57, 60, 65]}, {"root": 41, "chord": [57, 60, 65]},
        {"root": 43, "chord": [59, 62, 67]}, {"root": 43, "chord": [59, 62, 67]},
    ]
    m = []
    phrase_a = [(0, "E5", 2), (2, "G5", 2), (4, "A5", 3), (7, "G5", 1), (8, "E5", 2), (10, "D5", 2), (12, "C5", 4),
                (16, "E5", 2), (18, "E5", 1), (19, "G5", 2), (22, "A5", 2), (24, "C6", 3), (27, "A5", 1), (28, "G5", 4)]
    phrase_b = [(0, "A5", 2), (2, "G5", 2), (4, "E5", 3), (7, "D5", 1), (8, "C5", 2), (10, "D5", 2), (12, "E5", 4),
                (16, "G5", 2), (18, "A5", 2), (20, "G5", 2), (22, "E5", 2), (24, "D5", 3), (27, "E5", 1), (28, "C5", 4)]
    for g, nme, d in phrase_a:
        m.append((g, nme, d))
    for g, nme, d in phrase_b:
        m.append((g + 32, nme, d))
    # mesma ideia nos 4 compassos finais, uma oitava coerente
    for g, nme, d in phrase_a[:8]:
        m.append((g + 64, nme, d))
    for g, nme, d in phrase_b[:10]:
        m.append((g + 96, nme, d))
    return build_track(104, 8, ch, m, kick_steps={0, 6, 8, 14}, hi_steps={4, 12}, tri_steps={0, 2, 3, 6, 8, 10, 11, 14}, stab_steps={3, 7, 11, 15}, bass_steps={0, 6, 8, 14})


def music_boss():
    # Am – F – G – E, mais rápido e agressivo
    ch = [
        {"root": 33, "chord": [57, 60, 64]}, {"root": 33, "chord": [57, 60, 64]},
        {"root": 41, "chord": [57, 60, 65]}, {"root": 41, "chord": [57, 60, 65]},
        {"root": 43, "chord": [59, 62, 67]}, {"root": 43, "chord": [59, 62, 67]},
        {"root": 40, "chord": [56, 59, 64]}, {"root": 40, "chord": [56, 59, 64]},
    ]
    m = []
    pa = [(0, "A5", 1), (1, "A5", 1), (2, "C6", 2), (4, "B5", 2), (6, "A5", 2), (8, "E5", 1), (9, "E5", 1), (10, "G5", 2), (12, "A5", 4),
          (16, "C6", 2), (18, "A5", 2), (20, "G5", 2), (22, "E5", 2), (24, "D5", 2), (26, "E5", 2), (28, "A5", 4)]
    pb = [(0, "C6", 1), (1, "C6", 1), (2, "D6", 2), (4, "C6", 2), (6, "A5", 2), (8, "G5", 1), (9, "G5", 1), (10, "A5", 2), (12, "B5", 4),
          (16, "E6", 2), (18, "D6", 2), (20, "C6", 2), (22, "B5", 2), (24, "G#5", 2), (26, "B5", 2), (28, "E6", 4)]
    for g, nme, d in pa:
        m.append((g, nme, d))
    for g, nme, d in pb:
        m.append((g + 32, nme, d))
    for g, nme, d in pa:
        m.append((g + 64, nme, d))
    for g, nme, d in pb:
        m.append((g + 96, nme, d))
    return build_track(138, 8, ch, m, kick_steps={0, 4, 8, 12}, hi_steps={6, 14}, tri_steps={0, 2, 4, 6, 8, 10, 12, 14}, stab_steps={2, 6, 10, 14}, bass_steps={0, 2, 4, 6, 8, 10, 12, 14}, snare_steps={4, 12}, swing=0.05, mel_gain=0.5, drive=1.1)


# --------------------------------------------------------------------------- execução

def report(name, x, sr, loop=False):
    pk = float(np.max(np.abs(x)))
    rms = float(np.sqrt(np.mean(x ** 2)))
    dc = float(np.mean(x))
    extra = ""
    if loop:
        seam = float(abs(x[-1] - x[0]))
        extra = "  emenda=%.4f" % seam
    print("%-22s dur=%6.2fs  pico=%.3f  rms=%.3f  dc=%+.4f%s" % (name, len(x) / sr, pk, rms, dc, extra))
    bad = pk > 0.999 or rms < 0.005 or not np.isfinite(x).all()
    if bad:
        print("  !! PROBLEMA em", name)
    return not bad


def main():
    ok = True
    for name, x in sfx_all().items():
        x = softclip(normalize(x, 0.9))
        x = x - np.mean(x)
        write_wav(os.path.join(OUT, "sfx", name + ".wav"), x, SR)
        ok &= report("sfx/" + name, x, SR)
    for name, fn in (("music_main", music_main), ("music_boss", music_boss)):
        x = fn()
        x = softclip(normalize(x - np.mean(x), 0.85))
        write_wav(os.path.join(OUT, "music", name + ".wav"), x, MSR)
        ok &= report("music/" + name, x, MSR, loop=True)
    print("== audio:", "OK" if ok else "COM PROBLEMAS", "==")


main()
