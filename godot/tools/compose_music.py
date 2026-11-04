"""Procedural pentatonic music for 云海商盟 (finish plan, phase F).
Writes sea / town / battle / festival loops as ogg into assets/sfx/.
python3 tools/compose_music.py  (needs numpy + ffmpeg)"""
import numpy as np, subprocess, os, wave, random

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sfx")

def hz(midi): return 440.0 * 2 ** ((midi - 69) / 12)

def pluck(f, dur, amp=0.3, bright=0.6):
    """Karplus-Strong string: a guzheng / pipa-like pluck."""
    n = int(SR * dur)
    p = max(2, int(SR / f))
    buf = (np.random.rand(p) * 2 - 1) * amp
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = bright * 0.5 * (buf[i % p] + buf[(i + 1) % p]) + (1 - bright) * buf[i % p] * 0.996
    return out

def ks(f, dur, amp=0.3, decay=0.996):
    n = int(SR * dur); p = max(2, int(SR / f))
    buf = (np.random.rand(p) * 2 - 1) * amp
    out = np.empty(n)
    idx = 0
    # vectorised by period blocks
    while idx < n:
        m = min(p, n - idx)
        out[idx:idx + m] = buf[:m]
        nb = decay * 0.5 * (buf + np.roll(buf, -1))
        buf = nb
        idx += p
    return out

def flute(f, dur, amp=0.18):
    t = np.arange(int(SR * dur)) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 3, 0, 1)
    ph = 2 * np.pi * f * np.cumsum(vib) / SR
    s = np.sin(ph) + 0.25 * np.sin(2 * ph) + 0.08 * np.sin(3 * ph)
    s += 0.02 * (np.random.rand(len(t)) * 2 - 1)  # breath
    env = np.minimum(1, t / 0.06) * np.minimum(1, (dur - t) / 0.12).clip(0)
    return amp * s * env

def pad(f, dur, amp=0.07):
    t = np.arange(int(SR * dur)) / SR
    s = sum(np.sin(2 * np.pi * f * d * t) for d in (1, 1.003, 0.997, 2.001))
    env = np.minimum(1, t / 1.5) * np.minimum(1, (dur - t) / 1.5).clip(0)
    return amp * s * env / 4

def bell(f, dur, amp=0.15):
    t = np.arange(int(SR * dur)) / SR
    s = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t * 4) + 0.3 * np.sin(2 * np.pi * f * 5.4 * t) * np.exp(-t * 8)
    return amp * s * np.exp(-t * 2.2)

def drum(dur, amp=0.5, f0=90, noise=0.15):
    t = np.arange(int(SR * dur)) / SR
    f = f0 * (1 + 1.5 * np.exp(-t * 30))
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9) + noise * (np.random.rand(len(t)) * 2 - 1) * np.exp(-t * 40)
    return amp * s

def mix(track, sound, at):
    i = int(at * SR)
    e = min(len(track), i + len(sound))
    if i < len(track):
        track[i:e] += sound[:e - i]

SCALE = [0, 2, 4, 7, 9]  # gong-mode pentatonic

def note(root, deg):
    o, d = divmod(deg, 5)
    return root + 12 * o + SCALE[d]

def phrase(rng, length, start=2, span=(0, 9)):
    out = []; d = start
    for _ in range(length):
        d = max(span[0], min(span[1], d + rng.choice([-2, -1, -1, 1, 1, 2, 0])))
        out.append(d)
    out[-1] = rng.choice([0, 2, 5])
    return out

def compose(name, seed, bpm, bars, root, lead, beats_per_bar=4, drums=None, bells=False, minor=False):
    rng = random.Random(seed)
    np.random.seed(seed)
    beat = 60.0 / bpm
    total = bars * beats_per_bar * beat
    tr = np.zeros(int(SR * (total + 2)))
    r = root + (-3 if minor else 0)
    prog = [0, 3, 1, 4] if not minor else [0, 2, 3, 1]
    motif_a = phrase(rng, 8); motif_b = phrase(rng, 8, 4)
    for b in range(bars):
        t0 = b * beats_per_bar * beat
        chord = prog[(b // 2) % len(prog)]
        # pads + bass
        if b % 2 == 0:
            for d in (chord, chord + 2, chord + 4):
                mix(tr, pad(hz(note(r - 12, d)), beats_per_bar * beat * 2 + 0.5), t0)
        mix(tr, ks(hz(note(r - 24, chord)), beat * 2, 0.35, 0.997), t0)
        if beats_per_bar >= 4:
            mix(tr, ks(hz(note(r - 24, chord + 2)), beat * 2, 0.25, 0.997), t0 + 2 * beat)
        # arpeggio plucks
        for k in range(beats_per_bar * 2):
            if rng.random() < 0.8:
                d = chord + [0, 2, 4, 5, 4, 2, 0, 2][k % 8]
                mix(tr, ks(hz(note(r, d)), beat * 1.5, 0.12, 0.995), t0 + k * beat / 2)
        # lead melody: A A B A form
        motif = motif_b if (b // 2) % 4 == 2 else motif_a
        if b >= 2 and b < bars - 1:
            for k, d in enumerate(motif[(b % 2) * 4:(b % 2) * 4 + 4]):
                dur = beat * (1.5 if k == 3 else 1.0)
                f = hz(note(r + 12, d))
                if lead == "flute":
                    mix(tr, flute(f, dur * 0.95), t0 + k * beat)
                else:
                    mix(tr, ks(f, dur * 2, 0.2, 0.996), t0 + k * beat)
        if bells and b % 2 == 1:
            mix(tr, bell(hz(note(r + 24, rng.choice([0, 2, 4]))), 2.5), t0 + beat * rng.choice([0, 1, 2]))
        if drums:
            for k in range(beats_per_bar * 2):
                pat = drums[k % len(drums)]
                if pat == "D": mix(tr, drum(0.5, 0.55), t0 + k * beat / 2)
                elif pat == "d": mix(tr, drum(0.3, 0.3, 140), t0 + k * beat / 2)
                elif pat == "x": mix(tr, drum(0.08, 0.12, 900, 0.8), t0 + k * beat / 2)
    # wrap the tail into the start so the loop is seamless
    n = int(SR * total)
    tail = tr[n:]
    tr = tr[:n]
    tr[:len(tail)] += tail
    # light echo
    d = int(SR * beat * 0.75)
    echo = np.zeros_like(tr); echo[d:] = tr[:-d] * 0.25
    tr = tr + echo
    tr = tr / max(1e-6, np.max(np.abs(tr))) * 0.8
    pcm = (tr * 32767).astype(np.int16)
    wav = f"/tmp/{name}.wav"
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "2", os.path.join(OUT, f"music_{name}.ogg")], check=True)
    os.remove(wav)
    print(name, round(total, 1), "s")

compose("sea", 11, 72, 32, 62, "flute")
compose("town", 22, 104, 32, 64, "pluck", drums=["d", "x", "x", "x", "d", "x", "D", "x"])
compose("battle", 33, 132, 32, 57, "pluck", drums=["D", "x", "d", "D", "D", "x", "d", "x"], minor=True)
compose("festival", 44, 116, 32, 67, "flute", drums=["D", "x", "d", "x", "D", "d", "d", "x"], bells=True)
